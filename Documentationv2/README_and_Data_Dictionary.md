# Player 15 Group: Data Quality & Commission Reconciliation Project (v3)

**Target Role:** Data Quality Analyst – Strategy & Analytics / Commission Administration  
**Organization Scope:** Player 15 Group (Phoenix Suns, Phoenix Mercury, Valley Suns, Mortgage Matchup Center)  
**Notice:** *This repository uses synthetic, fictional data created solely for technical demonstration purposes. It does not contain proprietary Phoenix Suns or Player 15 Group records. Commission rates, approval thresholds, and schedules are illustrative.*

---

## 1. Executive Summary & Architecture
This project implements an automated, multi-system data quality pipeline that reconciles ticket sales transactions between **Ticketmaster Archtics**, **Salesforce CRM**, **Salesforce Split Credits**, and **Microsoft Dynamics Great Plains (GP)**.

### Core Enhancements in v3:
1. **Row-per-Check Audit Architecture**: Evaluates 7 independent quality checks per transaction (2,100 total checks across 300 synthetic records) so multiple issues per transaction are never hidden.
2. **Reconciled Status Fields**: Separates `original_check_result` (PASS/FAIL), `investigation_status` (Investigating/Closed), `approval_status` (Pending/Approved), and `posting_resolution_status` (Posted/Unposted/Resolved).
3. **Traceable Resolution Audit Log**: Connects flags to stable issue IDs (`ISSUE-2026-xxx`), supporting evidence, reviewer sign-offs, and clear before-and-after values.
4. **ANSI SQL & Join Cardinality Rules**: Features deduplication CTEs and null-safe comparisons to prevent join fan-out and false matches.
5. **Reproducible Test Script**: Includes `tests/validate_kpis.py` to independently verify data integrity and KPI totals.

---

## 2. Directory Structure

```text
Player15Group_DataQuality_Project_v3/
├── data/
│   ├── archtics_transactions.csv       # Synthetic Archtics ticketing sales staging
│   ├── salesforce_opportunities.csv    # Synthetic CRM pipeline deal records
│   ├── salesforce_split_credits.csv    # Synthetic CRM sales credit allocations
│   ├── great_plains_postings.csv       # Synthetic GL revenue postings
│   ├── qa_results.csv                  # Granular row-per-check automated audit results
│   └── resolution_log.csv              # Traceable audit trail of exception reviews
├── scripts/
│   └── reconciliation_audit.sql        # Executable ANSI SQL query with 7 independent checks
├── tableau/
│   ├── tableau_summary_kpis.csv        # Pre-calculated KPI summary metrics
│   └── tableau_dashboard_blueprint.md  # Detailed Tableau specification guide
├── tests/
│   └── validate_kpis.py                # Runnable Python test script to validate outputs
└── documentation/
    └── README_and_Data_Dictionary.md   # Project documentation & schema definitions
```

---

## 3. Data Quality Checks Executed

1. **Duplicate Transaction ID Check**: Flags duplicated transaction records in staging.
2. **Missing CRM Opportunity Link Check**: Flags non-web transactions missing a valid CRM link.
3. **CRM Revenue Variance Check**: Flags discrepancies > $1.00 between Archtics net revenue and CRM deal value.
4. **Great Plains GL Posting Check**: Flags unposted revenue or GL posting mismatches > $1.00.
5. **Sales Rep Attribution Check**: Flags mismatches between Archtics rep ID and CRM owner ID.
6. **Product Category Mapping Check**: Flags product classification mismatches between Archtics and CRM.
7. **Split Credit & Approval Check**: Validates that rep splits sum to 100% and have manager approval.

---

## 4. Execution & Verification Instructions

To reproduce the analysis and validate the dataset:

```bash
cd Player15Group_DataQuality_Project_v3/tests
python validate_kpis.py
```

Expected Output:
* Total Unique Transactions: 300
* Total Validation Checks Executed: 2,100
* Clean Transactions Passing All Checks: 255 (85.00% Pass Rate)
* Total Flagged Variance: $21,400.00
