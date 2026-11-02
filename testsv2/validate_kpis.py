import pandas as pd

def run_kpi_validation():
    df_qa = pd.read_csv("../data/qa_results.csv")
    df_arch = pd.read_csv("../data/archtics_transactions.csv")
    
    # 1. Source row count vs QA transaction count check
    raw_tx_count = df_arch['transaction_id'].nunique()
    qa_tx_count = df_qa['transaction_id'].nunique()
    assert raw_tx_count == qa_tx_count, f"Mismatch: Raw {raw_tx_count} vs QA {qa_tx_count}"
    
    # 2. Check total checks per transaction equals exactly 7
    checks_per_tx = df_qa.groupby('transaction_id')['check_name'].count()
    assert (checks_per_tx == 7).all(), "Some transactions do not have exactly 7 QA checks!"
    
    # 3. Recalculate Pass Rate
    tx_pass = df_qa.groupby('transaction_id')['original_check_result'].apply(lambda x: (x == 'PASS').all())
    pass_rate = (tx_pass.sum() / len(tx_pass)) * 100
    
    print("KPI VALIDATION PASSED:")
    print(f"  - Total Transactions: {qa_tx_count}")
    print(f"  - Clean Transactions Passing All Checks: {tx_pass.sum()}")
    print(f"  - Transaction Pass Rate: {pass_rate:.2f}%")
    print(f"  - Total Checks Run: {len(df_qa)}")
    print(f"  - Flagged Variance: ${df_qa['variance_amount'].sum():,.2f}")

if __name__ == '__main__':
    run_kpi_validation()
