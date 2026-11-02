# Executive Summary & Technical Guide: Ticket Sales & Commission Audit

**Target Organization:** Player 15 Group (Phoenix Suns, Phoenix Mercury, Valley Suns)  
**Role Scope:** Data Quality Analyst – Strategy & Analytics / Commission Administration  
**Primary Systems:** Ticketmaster Archtics, Salesforce CRM, Microsoft Dynamics Great Plains (GP), Tableau  

---

## 1. Project Overview & Business Value
During high-volume ticketing windows (such as seasonal launches, theme nights, and premium matchup single-game sales), transaction discrepancies occur across systems due to manual CRM opportunity tagging, split rep attributions, refund processing delays, and mismatched promo code categories.

This project establishes a standardized **End-to-End Commission & Data Audit Pipeline** that programmatically ingests sales data from **Ticketmaster Archtics**, matches it against **Salesforce CRM Opportunities**, reconciles revenue postings in **Great Plains (GP)**, and flags commission discrepancies for leadership review prior to monthly payroll submissions.

---

## 2. Key Data Quality Metrics & Dashboard Logic

### Core KPIs & Formulas
* **Reconciliation Accuracy Rate (%)**:
  `Accuracy Rate = (Total Verified Transactions / Total Archtics Transactions) * 100`

* **Net Commissionable Revenue**:
  `Commissionable Rev = Archtics Gross Rev - Refunds/Chargebacks - House Sales - Non-Commissionable Fees`

* **Variance Amount ($)**:
  `Variance = |Archtics Rev - Salesforce CRM Opportunity Value|`

### Standardized Exception Categories for Tableau Tracking
1. **Unlinked Opportunity**: Transaction exists in Archtics but has no matching Opportunity ID in Salesforce.
2. **Attribution Mismatch**: Sales Rep listed in Archtics does not match owner in Salesforce CRM.
3. **GL Deferred Mismatch**: Payment processed in Archtics but unposted in Great Plains.
4. **Category Misclassification**: Group sale misclassified as Full Season Plan (impacts commission % tiers).

---

## 3. Cross-Functional Escalation & Payroll Control Process

1. **Daily Sweep (T+1)**: Automated script flags all transactions with `revenue_variance <> 0` or `audit_flag <> 'Clean Match'`.
2. **Weekly Department Review**: Partner with Box Office and Ticket Sales Managers to resolve attribution and split-commission requests.
3. **Monthly Audit Lock (Day -3 to Payroll)**:
   - Freeze commissionable tables.
   - Obtain formal sign-off from VP of Sales and Director of Finance.
   - Log all manual override notes and approval timestamps in audit log storage for annual controls testing.
4. **Payroll File Generation**: Export clean, reconciled CSV file direct to People & Culture / Payroll for monthly payout.
