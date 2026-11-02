-- Player 15 Group: Archtics vs Salesforce Commission Audit Query
SELECT 
    a.transaction_id,
    a.event_name,
    a.event_date,
    a.archtics_gross_amount,
    sf.opportunity_id,
    sf.crm_amount,
    a.sales_rep_id AS archtics_rep,
    sf.owner_id AS crm_rep,
    (a.archtics_gross_amount - ISNULL(sf.crm_amount, 0)) AS revenue_variance,
    CASE 
        WHEN sf.opportunity_id IS NULL THEN 'Missing CRM Opportunity'
        WHEN a.sales_rep_id <> sf.owner_id THEN 'Rep Attribution Mismatch'
        WHEN a.archtics_gross_amount <> sf.crm_amount THEN 'Revenue Discrepancy'
        ELSE 'Clean Match'
    END AS audit_flag
FROM Archtics_Sales_Staging a
LEFT JOIN Salesforce_Opportunities sf 
    ON a.archtics_transaction_id = sf.archtics_id
WHERE a.event_date BETWEEN '2026-11-01' AND '2026-11-30'
ORDER BY audit_flag DESC, a.event_date ASC;
