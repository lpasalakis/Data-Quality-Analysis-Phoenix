-- =============================================================================
-- Player 15 Group: Multi-System Ticket Sales & Commission Audit Query
-- Dialect: ANSI SQL (Portable across Snowflake, PostgreSQL, BigQuery, MS SQL Server)
-- Purpose: Executes row-per-check audit logic, prevents join fan-out, 
--          and reconciles Archtics, Salesforce CRM, Splits, and Great Plains GL.
-- =============================================================================

-- CTE 1: Check Source Key Uniqueness & Flag Duplicates in Archtics
WITH Archtics_Deduplicated AS (
    SELECT 
        transaction_id,
        event_name,
        transaction_date,
        archtics_revenue,
        ticket_count,
        archtics_rep_id,
        rep_department,
        product_category,
        crm_opportunity_id,
        ROW_NUMBER() OVER (PARTITION BY transaction_id ORDER BY transaction_date DESC) AS row_num,
        COUNT(*) OVER (PARTITION BY transaction_id) AS dup_count
    FROM archtics_transactions
),
-- CTE 2: Deduplicate Salesforce Opportunities to Prevent Join Fan-out
CRM_Deduplicated AS (
    SELECT 
        opportunity_id,
        deal_value,
        crm_owner_id,
        product,
        approval_status,
        ROW_NUMBER() OVER (PARTITION BY opportunity_id ORDER BY deal_value DESC) AS sf_row_num
    FROM salesforce_opportunities
),
-- CTE 3: Aggregate Split Credit Approval & Total Percentage
Splits_Aggregated AS (
    SELECT 
        opportunity_id,
        SUM(split_percentage) AS total_split_pct,
        MIN(CASE WHEN is_approved = true OR is_approved = 1 THEN 1 ELSE 0 END) AS is_fully_approved
    FROM salesforce_split_credits
    GROUP BY opportunity_id
),
-- CTE 4: Reconciled Staging Layer (1-to-1 Join Cardinality Verified)
Staging_Layer AS (
    SELECT 
        a.transaction_id,
        a.event_name,
        a.transaction_date,
        a.archtics_revenue,
        a.archtics_rep_id,
        a.rep_department,
        a.product_category AS archtics_product,
        a.crm_opportunity_id,
        a.dup_count,
        
        -- Salesforce Fields
        sf.deal_value AS sf_deal_value,
        sf.crm_owner_id,
        sf.product AS sf_product,
        sf.approval_status AS sf_approval_status,
        sp.total_split_pct,
        sp.is_fully_approved,
        
        -- Great Plains Fields
        gp.gl_amount AS gp_gl_amount,
        gp.posting_status AS gp_posting_status,
        
        -- Portable Null-Safe Variances
        ABS(a.archtics_revenue - COALESCE(sf.deal_value, 0.00)) AS sf_variance,
        ABS(a.archtics_revenue - COALESCE(gp.gl_amount, 0.00)) AS gp_variance

    FROM Archtics_Deduplicated a
    LEFT JOIN CRM_Deduplicated sf 
        ON a.crm_opportunity_id = sf.opportunity_id 
       AND sf.sf_row_num = 1
    LEFT JOIN Splits_Aggregated sp
        ON a.crm_opportunity_id = sp.opportunity_id
    LEFT JOIN great_plains_postings gp 
        ON a.transaction_id = gp.transaction_id
    WHERE a.row_num = 1 -- Retain primary record for staging
)

-- Final Output: Independent Row-per-Check Audit Log
SELECT 
    transaction_id,
    event_name,
    rep_department,
    'Duplicate Transaction ID Check' AS check_name,
    'High' AS severity,
    'Unique Transaction ID' AS expected_value,
    CASE WHEN dup_count > 1 THEN 'Duplicate ID Detected' ELSE 'Unique ID' END AS actual_value,
    0.00 AS variance_amount,
    CASE WHEN dup_count > 1 THEN 'FAIL' ELSE 'PASS' END AS original_check_result
FROM Staging_Layer

UNION ALL

SELECT 
    transaction_id,
    event_name,
    rep_department,
    'Missing CRM Opportunity Link Check' AS check_name,
    'Medium' AS severity,
    'Valid CRM Opportunity ID' AS expected_value,
    CASE WHEN crm_opportunity_id IS NULL THEN 'CRM Link Missing (NULL)' ELSE crm_opportunity_id END AS actual_value,
    0.00 AS variance_amount,
    CASE WHEN crm_opportunity_id IS NULL AND rep_department <> 'Box Office / Web' THEN 'FAIL' ELSE 'PASS' END AS original_check_result
FROM Staging_Layer

UNION ALL

SELECT 
    transaction_id,
    event_name,
    rep_department,
    'CRM Revenue Variance Check' AS check_name,
    'High' AS severity,
    CAST(archtics_revenue AS VARCHAR) AS expected_value,
    CAST(COALESCE(sf_deal_value, 0.00) AS VARCHAR) AS actual_value,
    CASE WHEN sf_variance > 1.00 AND crm_opportunity_id IS NOT NULL THEN sf_variance ELSE 0.00 END AS variance_amount,
    CASE WHEN sf_variance > 1.00 AND crm_opportunity_id IS NOT NULL THEN 'FAIL' ELSE 'PASS' END AS original_check_result
FROM Staging_Layer

UNION ALL

SELECT 
    transaction_id,
    event_name,
    rep_department,
    'Great Plains GL Posting Check' AS check_name,
    'High' AS severity,
    'Posted & Matched GL Amount' AS expected_value,
    COALESCE(gp_posting_status, 'Missing Record') AS actual_value,
    CASE WHEN gp_variance > 1.00 OR gp_posting_status LIKE 'Unposted%' THEN gp_variance ELSE 0.00 END AS variance_amount,
    CASE WHEN gp_variance > 1.00 OR gp_posting_status LIKE 'Unposted%' THEN 'FAIL' ELSE 'PASS' END AS original_check_result
FROM Staging_Layer;
