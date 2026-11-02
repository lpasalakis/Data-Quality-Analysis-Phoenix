# Tableau Dashboard Blueprint & Specification Guide

**Dashboard Name:** Player 15 Group – Ticket Sales & Commission Data Quality Control  
**Target Audience:** Strategy & Analytics Leadership, VP of Ticket Sales, Finance & Payroll  
**Data Sources:** `archtics_transactions.csv`, `salesforce_opportunities.csv`, `great_plains_postings.csv`, `qa_results.csv`, `resolution_log.csv`

---

## 1. Executive Summary KPIs (Top Banner Cards)

| KPI Card Title | Calculation / Formula | Target / Benchmark | Synthetic Dataset Output |
| :--- | :--- | :--- | :--- |
| **Total Reviewed Transactions** | `COUNTD([transaction_id])` | 100% Coverage | **7 Transactions** |
| **Pass Rate (%)** | `SUM(IF [audit_status_flag] = 'PASS: Fully Reconciled' THEN 1 ELSE 0 END) / COUNTD([transaction_id])` | > 95.0% | **28.57%** (2 / 7) |
| **Total Revenue Variance** | `SUM([archtics_sf_variance]) + SUM([archtics_gp_variance])` | $0.00 | **$13,400.00** |
| **Open Exception Items** | `SUM(IF [review_status] = 'Investigating' THEN 1 ELSE 0 END)` | 0 Prior to Payroll | **1 Item** (TX-8802) |

---

## 2. Recommended Visualizations & Layout Layout

### Section A: Executive Overview Grid (Top Half)
1. **Donut Chart – Audit Pass/Fail Status**:
   - **Dimension:** `audit_status_flag`
   - **Measure:** `COUNTD([transaction_id])`
   - **Colors:** Green (#2E7D32) for Pass, Amber (#F57C00) for Pending GL, Red (#C62828) for Discrepancies.

2. **Bar Chart – Variance ($) by Event / Theme Night**:
   - **X-Axis:** `event_name`
   - **Y-Axis:** `SUM([variance_amount])`
   - **Highlight:** Nov 7 (Rockets) $5,000 variance and Nov 4 (Trail Blazers) $8,400 GL variance.

### Section B: Exception Deep Dive & Department Breakdown (Bottom Half)
3. **Horizontal Bar Chart – Exceptions by Type & Department**:
   - **Rows:** `check_name`
   - **Columns:** `COUNT([transaction_id])`
   - **Color Stack:** `rep_department` (Group Sales, Premium, Inside Sales, Partnerships).

4. **Detailed Audit Exception Table (Interactive Filter)**:
   - **Columns:** `transaction_id`, `event_name`, `check_name`, `variance_amount`, `review_status`, `resolution_note`, `approval_reference`.
   - **Filter Actions:** Clicking any exception type in the bar chart filters the granular table dynamically.

---

## 3. Step-by-Step Tableau Re-creation Instructions
1. Import `qa_results.csv` and `archtics_transactions.csv` into Tableau Desktop.
2. Join `archtics_transactions` to `qa_results` on `transaction_id`.
3. Create calculated field `[Is_Passing]`: `IF [review_status] = 'Resolved' AND [variance_amount] = 0 THEN 1 ELSE 0 END`.
4. Drag `[Is_Passing]` to Marks card and format as Percentage for the headline gauge.
5. Publish to Tableau Server / Online with automated daily refresh following T+1 Archtics batch updates.
