[README_and_Data_Dictionary.md](https://github.com/user-attachments/files/34251827/README_and_Data_Dictionary.md)
# Player 15 Group: Data Quality & Commission Reconciliation Project

**Target Role:** Data Quality Analyst – Strategy & Analytics / Commission Administration  
**Organization Scope:** Player 15 Group (Phoenix Suns, Phoenix Mercury, Valley Suns, Mortgage Matchup Center)  
**Notice:** *This repository uses synthetic, fictional data created solely for technical demonstration purposes. It does not contain proprietary Phoenix Suns or Player 15 Group records. Commission rates, approval thresholds, and schedules are illustrative.*

---

## 1. Project Overview & Business Context
In professional sports and entertainment operations, ticket sales revenue and partnership commissions flow across multiple disparate enterprise systems:
* **Ticketmaster Archtics**: Primary ticketing ledger (source of truth for manifest inventory, barcodes, and raw ticket revenue).
* **Salesforce CRM**: Deal pipeline, sales rep credit assignments, split percentages, and contractual terms.
* **Microsoft Dynamics Great Plains (GP)**: General Ledger (GL) financial accounting and revenue recognition.

When high-volume sales windows occur (e.g., single-game launches, theme nights), discrepancies emerge from manual CRM entry errors, unbilled add-ons, missing rep split attributes, or batch posting delays. This project provides an **Automated Data Quality & Audit Pipeline** to detect, track, investigate, and remediate discrepancies prior to monthly payroll lock.

---

## 2. Directory Structure & File Inventory

```text
Player15Group_DataQuality_Project_v2/
├── data/
│   ├── archtics_transactions.csv       # Raw synthetic Archtics sales staging dataset
│   ├── salesforce_opportunities.csv    # Raw synthetic CRM pipeline & deal attributes
│   ├── great_plains_postings.csv       # Raw synthetic GL postings & status from Finance
│   ├── qa_results.csv                  # Automated exception detection report
│   └── resolution_log.csv              # Full audit trail of exception investigations & approvals
├── scripts/
│   └── reconciliation_audit.sql        # Executable SQL query handling 3-way joins & variance checks
├── tableau/
│   ├── tableau_summary_kpis.csv        # Aggregated KPI dataset for dashboard visualization
│   └── tableau_dashboard_blueprint.md  # Detailed technical specifications to build Tableau dashboard
└── documentation/
    └── README_and_Data_Dictionary.md   # Complete project documentation & schema definitions
```

---

## 3. Data Dictionary & Table Schemas

### A. `archtics_transactions.csv`
* Primary Key: `transaction_id`
* Schema:
  - `transaction_id` (String): Unique Archtics ticket sale identifier (e.g., `TX-8801`).
  - `event_name` (String): Event description / theme night.
  - `transaction_date` (Date): Date sale was processed (`YYYY-MM-DD`).
  - `archtics_revenue` (Decimal): Net ticket sales revenue ($).
  - `ticket_count` (Integer): Number of tickets attached to transaction.
  - `archtics_rep_id` (String): Sales representative ID in Archtics.
  - `product_category` (String): Sales category (e.g., Group Sales, Premium Suites, Inside Sales).
  - `crm_opportunity_id` (String, Nullable): Foreign key to Salesforce CRM.

### B. `salesforce_opportunities.csv`
* Primary Key: `opportunity_id`
* Schema:
  - `opportunity_id` (String): Salesforce Opportunity ID (`OPP-9001`).
  - `deal_value` (Decimal): Total contractual deal value recorded by sales rep ($).
  - `crm_owner_id` (String): Sales representative ID owning the CRM opportunity.
  - `product` (String): Product classification logged in CRM.
  - `approval_status` (String): Approval state (`Approved`, `Pending Manager Sign-off`).
  - `split_credit_pct` (String): Credit split allocation (`100%`, `50/50`, `Unassigned Split`).

### C. `great_plains_postings.csv`
* Foreign Key: `transaction_id`
* Schema:
  - `transaction_id` (String): Link to Archtics transaction ID.
  - `gl_amount` (Decimal): Revenue posted in GL ledger ($).
  - `posting_date` (Date, Nullable): Date batch posted to GL.
  - `gl_account` (String): General ledger account string.
  - `posting_status` (String): GL state (`Posted`, `Unposted - Batch Delay`).

### D. `qa_results.csv`
* Schema:
  - `transaction_id` (String): Record identifier.
  - `check_name` (String): Validation check executed.
  - `expected_value` (String): Expected benchmark or value.
  - `actual_value` (String): Observed system value.
  - `variance_amount` (Decimal): Absolute numerical variance ($).
  - `review_status` (String): Audit status (`Investigating`, `Resolved`).
  - `resolution_note` (String): Summary of root cause and remediation.
  - `approval_reference` (String): Audit approval sign-off code.

---

## 4. SQL Setup & Execution Instructions

### Prerequisites
The provided SQL query (`scripts/reconciliation_audit.sql`) is written in ANSI SQL standard (compatible with PostgreSQL, MS SQL Server, Snowflake, and BigQuery).

### How to Run
1. Load `archtics_transactions`, `salesforce_opportunities`, and `great_plains_postings` into your SQL database staging schema.
2. Ensure indexes are applied on `archtics_transactions.transaction_id`, `archtics_transactions.crm_opportunity_id`, and `salesforce_opportunities.opportunity_id`.
3. Execute `scripts/reconciliation_audit.sql`.
4. **Key Logic Built into Query**:
   - **Deduplication CTE**: Uses `ROW_NUMBER()` on `salesforce_opportunities` to prevent standard 1-to-many join fan-out errors.
   - **Null Handling**: Uses `ISNULL()` / `COALESCE()` to catch unlinked CRM records and unposted GL entries without dropping rows.
   - **Variance Tolerance**: Applies a `$1.00` threshold to filter out harmless fractional rounding differences.

---

## 5. Investigation & Remediation Workflow

An automated flag is treated as a **request for investigation**, not an automatic error overwrite. All changes follow strict internal controls:

```
[System Audit Script] ──> [Flag Generated in qa_results.csv]
                                   │
                                   ▼
                   [Analyst Reviews Raw Source Evidence]
                                   │
                                   ▼
             [Cross-Department Consultation (Sales/Finance/BO)]
                                   │
                                   ▼
                    [Manager Approval & Sign-Off]
                                   │
                                   ▼
           [Log in resolution_log.csv & Submit Clean File to Payroll]
```
