# Tableau Dashboard Blueprint & Technical Specification (v3)

**Dashboard Name:** Player 15 Group – Ticket Sales & Commission Data Quality Control  
**Target Audience:** Strategy & Analytics Leadership, VP of Ticket Sales, Finance & Payroll  
**Data Sources:** `qa_results.csv`, `archtics_transactions.csv`, `tableau_summary_kpis.csv`

---

## 1. Executive Summary KPIs (Top Banner Cards)

| KPI Card Title | Field Alignment / Formula | Metric Type | Synthetic Baseline Output |
| :--- | :--- | :--- | :--- |
| **Total Reviewed Transactions** | `COUNTD([transaction_id])` | Transaction Denominator | **300 Transactions** |
| **Transaction Pass Rate (%)** | `SUM(IF [tx_all_pass] THEN 1 ELSE 0 END) / COUNTD([transaction_id])` | Strict Compliance Benchmark | **85.00%** (255 / 300) |
| **Check-Level Pass Rate (%)** | `SUM(IF [original_check_result] = 'PASS' THEN 1 ELSE 0 END) / COUNT([qa_id])` | Granular Quality Benchmark | **97.38%** (2,045 / 2,100) |
| **Flagged Revenue Variance** | `SUM([variance_amount])` | Audit Review Queue | **$21,400.00** |
| **Open Exception Items** | `SUM(IF [posting_resolution_status] != 'Resolved' THEN 1 ELSE 0 END)` | Action Queue | **45 Items** |

---

## 2. Recommended Dashboard Layout

```
┌─────────────────────────────────────────────────────────────────────────────────┐
│                           EXECUTIVE SUMMARY KPI CARDS                           │
│  [300 Reviewed Tx]  │  [85.0% Pass Rate]  │  [$21.4k Flagged]  │  [45 Open Items]   │
└─────────────────────────────────────────────────────────────────────────────────┘
┌─────────────────────────────────────────┬───────────────────────────────────────┐
│ VISUAL 1: Exceptions by Type & Severity │ VISUAL 2: Flagged Variance by Event   │
│ (Bar Chart of Check Name stacked by     │ (Bar Chart of Event Name vs Variance  │
│  Severity: High, Medium, Low)           │  Amount in $)                         │
└─────────────────────────────────────────┴───────────────────────────────────────┘
┌─────────────────────────────────────────────────────────────────────────────────┐
│ VISUAL 3: Interactive Audit Review Queue & Exception Detail Table               │
│ Columns: Tx ID | Event | Department | Check Name | Expected vs Actual | Status │
└─────────────────────────────────────────────────────────────────────────────────┘
```

---

## 3. Step-by-Step Tableau Setup
1. Connect Tableau to `qa_results.csv` and `archtics_transactions.csv` (Join on `transaction_id`).
2. Verify field names match exactly: `transaction_id`, `event_name`, `rep_department`, `check_name`, `severity`, `original_check_result`, `investigation_status`, `posting_resolution_status`.
3. Create calculated measure `[Flagged Variance Sum]`: `SUM([variance_amount])`.
4. Create calculated dimension `[Transaction Pass Status]`: `FIXED [transaction_id]: MIN(IF [original_check_result] = 'FAIL' THEN 0 ELSE 1 END)`.
5. Drag `[Transaction Pass Status]` to canvas to create the headline pass rate pie chart.
