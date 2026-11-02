-- =============================================================================
-- Player 15 Group: Multi-System Ticket Sales & Commission Audit Query
-- Systems Reconciled: Ticketmaster Archtics, Salesforce CRM, MS Dynamics Great Plains
-- Author: Data Quality Analyst
-- Description: Identifies revenue variances, missing CRM links, GL posting delays,
--              rep attribution errors, and invalid split credits.
-- =============================================================================

WITH Deduplicated_SF AS (
    -- Avoid duplicate rows if multiple CRM opps link to one transaction
    SELECT 
        opportunity_id,
        deal_value,
        crm_owner_id,
        product,
        approval_status,
        split_credit_pct,
        ROW_NUMBER() OVER (PARTITION BY opportunity_id ORDER BY deal_value DESC) AS rn
    FROM salesforce_opportunities
),
Reconciliation_Staging AS (
    SELECT 
        a.transaction_id,
        a.event_name,
        a.transaction_date,
        a.archtics_revenue,
        a.archtics_rep_id,
        a.product_category AS archtics_product,
        a.crm_opportunity_id,
        
        -- Salesforce Fields (Handling Missing Links)
        sf.deal_value AS sf_deal_value,
        sf.crm_owner_id,
        sf.product AS sf_product,
        sf.approval_status AS sf_approval_status,
        sf.split_credit_pct,
        
        -- Great Plains Fields (Handling Missing GL Postings)
        gp.gl_amount AS gp_gl_amount,
        gp.posting_status AS gp_posting_status,
        
        -- Variance Calculations (Using Variance Tolerance Threshold of $1.00)
        ABS(a.archtics_revenue - ISNULL(sf.deal_value, 0)) AS archtics_sf_variance,
        ABS(a.archtics_revenue - ISNULL(gp.gl_amount, 0)) AS archtics_gp_variance

    FROM archtics_transactions a
    LEFT JOIN Deduplicated_SF sf 
        ON a.crm_opportunity_id = sf.opportunity_id 
       AND sf.rn = 1
    LEFT JOIN great_plains_postings gp 
        ON a.transaction_id = gp.transaction_id
)
SELECT 
    transaction_id,
    event_name,
    transaction_date,
    archtics_revenue,
    sf_deal_value,
    gp_gl_amount,
    archtics_sf_variance,
    archtics_gp_variance,
    archtics_rep_id,
    crm_owner_id,
    
    -- Automated Data Quality Audit Flag Logic
    CASE 
        WHEN crm_opportunity_id IS NULL THEN 'FLAG: Missing CRM Opportunity Link'
        WHEN gp_gl_amount IS NULL OR gp_posting_status LIKE 'Unposted%' THEN 'FLAG: Missing or Unposted GL Record'
        WHEN archtics_sf_variance > 1.00 THEN 'FLAG: Archtics vs CRM Revenue Mismatch'
        WHEN archtics_gp_variance > 1.00 THEN 'FLAG: Archtics vs Great Plains GL Revenue Mismatch'
        WHEN ISNULL(archtics_rep_id, '') <> ISNULL(crm_owner_id, '') THEN 'FLAG: Sales Rep Attribution Mismatch'
        WHEN split_credit_pct = 'Unassigned Split' OR sf_approval_status LIKE 'Pending%' THEN 'FLAG: Invalid Split or Missing Approval'
        WHEN archtics_product <> sf_product THEN 'FLAG: Product Category Mismatch'
        ELSE 'PASS: Fully Reconciled'
    END AS audit_status_flag

FROM Reconciliation_Staging
ORDER BY 
    CASE WHEN audit_status_flag LIKE 'FLAG%' THEN 1 ELSE 2 END,
    transaction_date ASC;
