-- ============================================================
-- LENDING CLUB — CREDIT RISK & CAMPAIGN ANALYTICS
-- SQL Query Library
-- Author: Hiral Sarkar
-- DB: Works with SQLite / PostgreSQL / BigQuery (minor syntax tweaks)
-- Table: lending_club (import cleaned_lending_club.csv)
-- ============================================================


-- ============================================================
-- SECTION 1: DATA VALIDATION & PROFILING
-- ============================================================

-- 1.1 Row count and basic profile
SELECT
    COUNT(*)                          AS total_records,
    COUNT(DISTINCT addr_state)        AS states_covered,
    COUNT(DISTINCT grade)             AS credit_grades,
    COUNT(DISTINCT purpose)           AS loan_purposes,
    MIN(loan_amnt)                    AS min_loan,
    MAX(loan_amnt)                    AS max_loan,
    ROUND(AVG(loan_amnt), 2)          AS avg_loan,
    ROUND(AVG(int_rate), 2)           AS avg_int_rate,
    SUM(is_default)                   AS total_defaults,
    ROUND(AVG(is_default) * 100, 2)   AS default_rate_pct
FROM lending_club;


-- 1.2 Null check on key columns
SELECT
    SUM(CASE WHEN loan_amnt     IS NULL THEN 1 ELSE 0 END) AS null_loan_amnt,
    SUM(CASE WHEN int_rate      IS NULL THEN 1 ELSE 0 END) AS null_int_rate,
    SUM(CASE WHEN grade         IS NULL THEN 1 ELSE 0 END) AS null_grade,
    SUM(CASE WHEN annual_inc    IS NULL THEN 1 ELSE 0 END) AS null_annual_inc,
    SUM(CASE WHEN dti           IS NULL THEN 1 ELSE 0 END) AS null_dti,
    SUM(CASE WHEN loan_status   IS NULL THEN 1 ELSE 0 END) AS null_loan_status,
    SUM(CASE WHEN fico_score    IS NULL THEN 1 ELSE 0 END) AS null_fico
FROM lending_club;


-- ============================================================
-- SECTION 2: PORTFOLIO OVERVIEW
-- ============================================================

-- 2.1 Portfolio KPIs by grade
SELECT
    grade,
    risk_segment,
    COUNT(*)                                     AS loan_count,
    ROUND(SUM(loan_amnt), 0)                     AS total_exposure,
    ROUND(AVG(loan_amnt), 0)                     AS avg_loan_size,
    ROUND(AVG(int_rate), 2)                      AS avg_int_rate,
    ROUND(AVG(dti), 2)                           AS avg_dti,
    ROUND(AVG(fico_score), 0)                    AS avg_fico,
    SUM(is_default)                              AS defaults,
    ROUND(AVG(is_default) * 100, 2)              AS default_rate_pct,
    SUM(is_chargeoff)                            AS chargeoffs,
    ROUND(AVG(is_chargeoff) * 100, 2)            AS chargeoff_rate_pct,
    ROUND(SUM(el_proxy), 0)                      AS expected_loss
FROM lending_club
GROUP BY grade, risk_segment
ORDER BY grade;


-- 2.2 Loan status distribution
SELECT
    loan_status,
    COUNT(*)                                     AS count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) AS pct_of_portfolio,
    ROUND(SUM(loan_amnt), 0)                     AS total_exposure
FROM lending_club
GROUP BY loan_status
ORDER BY count DESC;


-- 2.3 Portfolio by purpose
SELECT
    purpose,
    COUNT(*)                             AS loan_count,
    ROUND(SUM(loan_amnt), 0)             AS total_exposure,
    ROUND(AVG(int_rate), 2)              AS avg_int_rate,
    ROUND(AVG(is_default) * 100, 2)      AS default_rate_pct
FROM lending_club
GROUP BY purpose
ORDER BY loan_count DESC;


-- ============================================================
-- SECTION 3: RISK SEGMENTATION
-- ============================================================

-- 3.1 Default rate by income band and grade
SELECT
    income_band,
    grade,
    COUNT(*)                                 AS loan_count,
    ROUND(AVG(is_default) * 100, 2)          AS default_rate_pct,
    ROUND(AVG(int_rate), 2)                  AS avg_int_rate,
    ROUND(AVG(dti), 2)                       AS avg_dti
FROM lending_club
WHERE income_band IS NOT NULL
GROUP BY income_band, grade
ORDER BY income_band, grade;


-- 3.2 FICO band performance
SELECT
    fico_band,
    COUNT(*)                                 AS loan_count,
    ROUND(AVG(loan_amnt), 0)                 AS avg_loan,
    ROUND(AVG(int_rate), 2)                  AS avg_int_rate,
    ROUND(AVG(is_default) * 100, 2)          AS default_rate_pct,
    ROUND(AVG(dti), 2)                       AS avg_dti,
    SUM(watchlist_flag)                      AS watchlist_accounts
FROM lending_club
WHERE fico_band IS NOT NULL
GROUP BY fico_band
ORDER BY fico_band;


-- 3.3 DTI risk banding
SELECT
    dti_band,
    COUNT(*)                                 AS loan_count,
    ROUND(AVG(is_default) * 100, 2)          AS default_rate_pct,
    ROUND(AVG(int_rate), 2)                  AS avg_int_rate,
    ROUND(AVG(fico_score), 0)                AS avg_fico
FROM lending_club
WHERE dti_band IS NOT NULL
GROUP BY dti_band
ORDER BY dti_band;


-- ============================================================
-- SECTION 4: EARLY WARNING & WATCHLIST
-- ============================================================

-- 4.1 Watchlist accounts summary
SELECT
    grade,
    risk_segment,
    COUNT(*)                                     AS total_accounts,
    SUM(watchlist_flag)                          AS watchlist_count,
    ROUND(AVG(watchlist_flag) * 100, 2)          AS watchlist_rate_pct,
    ROUND(SUM(CASE WHEN watchlist_flag = 1 THEN loan_amnt ELSE 0 END), 0)
                                                 AS watchlist_exposure
FROM lending_club
GROUP BY grade, risk_segment
ORDER BY watchlist_rate_pct DESC;


-- 4.2 High-risk accounts: multiple stress signals
SELECT
    grade,
    sub_grade,
    loan_amnt,
    int_rate,
    dti,
    revol_util,
    delinq_2yrs,
    fico_score,
    loan_status,
    annual_inc,
    addr_state,
    risk_segment,
    watchlist_flag
FROM lending_club
WHERE
    delinq_2yrs > 0
    AND dti > 30
    AND revol_util > 75
    AND grade IN ('D', 'E', 'F', 'G')
ORDER BY dti DESC, int_rate DESC
LIMIT 500;


-- 4.3 Accounts with high payment burden (payment-to-income stress)
SELECT
    grade,
    income_band,
    COUNT(*)                                     AS loan_count,
    ROUND(AVG(payment_to_income) * 100, 2)       AS avg_payment_to_income_pct,
    ROUND(AVG(is_default) * 100, 2)              AS default_rate_pct,
    SUM(watchlist_flag)                          AS watchlist_count
FROM lending_club
WHERE payment_to_income > 0.20     -- >20% of annual income going to loan repayment
GROUP BY grade, income_band
ORDER BY avg_payment_to_income_pct DESC;


-- ============================================================
-- SECTION 5: CHARGE-OFF ANALYSIS
-- ============================================================

-- 5.1 Charge-off rate by grade and term
SELECT
    grade,
    term,
    COUNT(*)                                     AS loan_count,
    SUM(is_chargeoff)                            AS chargeoffs,
    ROUND(AVG(is_chargeoff) * 100, 2)            AS chargeoff_rate_pct,
    ROUND(SUM(el_proxy), 0)                      AS total_expected_loss,
    ROUND(AVG(lgd_proxy) * 100, 2)               AS avg_lgd_pct,
    ROUND(AVG(recovery_rate) * 100, 2)           AS avg_recovery_rate_pct
FROM lending_club
GROUP BY grade, term
ORDER BY grade, term;


-- 5.2 Charge-offs by state (geographic risk)
SELECT
    addr_state,
    COUNT(*)                                     AS loan_count,
    SUM(is_chargeoff)                            AS chargeoffs,
    ROUND(AVG(is_chargeoff) * 100, 2)            AS chargeoff_rate_pct,
    ROUND(SUM(loan_amnt), 0)                     AS total_exposure,
    ROUND(SUM(el_proxy), 0)                      AS expected_loss
FROM lending_club
GROUP BY addr_state
HAVING loan_count >= 100
ORDER BY chargeoff_rate_pct DESC
LIMIT 20;


-- 5.3 Recovery analysis on charged-off accounts
SELECT
    grade,
    COUNT(*)                                     AS chargeoff_count,
    ROUND(AVG(loan_amnt), 0)                     AS avg_original_loan,
    ROUND(AVG(total_pymnt), 0)                   AS avg_total_recovered,
    ROUND(AVG(recoveries), 0)                    AS avg_post_chargeoff_recoveries,
    ROUND(AVG(recovery_rate) * 100, 2)           AS avg_recovery_rate_pct,
    ROUND(AVG(lgd_proxy) * 100, 2)               AS avg_lgd_pct
FROM lending_club
WHERE is_chargeoff = 1
GROUP BY grade
ORDER BY grade;


-- ============================================================
-- SECTION 6: CAMPAIGN ANALYTICS (CUSTOMER TARGETING)
-- ============================================================

-- 6.1 Campaign response rate by segment
SELECT
    risk_segment,
    income_band,
    COUNT(*)                                     AS total_customers,
    SUM(campaign_response)                       AS responders,
    ROUND(AVG(campaign_response) * 100, 2)       AS response_rate_pct,
    SUM(high_value_customer)                     AS high_value_count,
    ROUND(AVG(high_value_customer) * 100, 2)     AS high_value_rate_pct
FROM lending_club
WHERE income_band IS NOT NULL
GROUP BY risk_segment, income_band
ORDER BY response_rate_pct DESC;


-- 6.2 Best-performing campaign segments (low risk + high response)
SELECT
    grade,
    risk_segment,
    income_band,
    fico_band,
    COUNT(*)                                     AS segment_size,
    ROUND(AVG(campaign_response) * 100, 2)       AS response_rate_pct,
    ROUND(AVG(is_default) * 100, 2)              AS default_rate_pct,
    ROUND(AVG(loan_amnt), 0)                     AS avg_loan_size,
    ROUND(AVG(int_rate), 2)                      AS avg_int_rate,
    ROUND(AVG(annual_inc), 0)                    AS avg_income
FROM lending_club
WHERE grade IN ('A', 'B', 'C')
    AND income_band IS NOT NULL
    AND fico_band IS NOT NULL
GROUP BY grade, risk_segment, income_band, fico_band
HAVING segment_size >= 50
ORDER BY response_rate_pct DESC, default_rate_pct ASC
LIMIT 20;


-- 6.3 Monthly loan issuance trend (campaign volume over time)
SELECT
    STRFTIME('%Y-%m', issue_d)                   AS issue_month,
    COUNT(*)                                     AS loans_issued,
    ROUND(SUM(loan_amnt), 0)                     AS total_amount,
    ROUND(AVG(int_rate), 2)                      AS avg_rate,
    ROUND(AVG(is_default) * 100, 2)              AS vintage_default_rate
FROM lending_club
WHERE issue_d IS NOT NULL
GROUP BY issue_month
ORDER BY issue_month;


-- ============================================================
-- SECTION 7: WINDOW FUNCTIONS — ADVANCED ANALYTICS
-- ============================================================

-- 7.1 Running cumulative exposure by grade
SELECT
    grade,
    issue_d,
    loan_amnt,
    SUM(loan_amnt) OVER (
        PARTITION BY grade ORDER BY issue_d
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    )                                            AS cumulative_exposure,
    COUNT(*) OVER (
        PARTITION BY grade ORDER BY issue_d
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    )                                            AS running_loan_count
FROM lending_club
WHERE issue_d IS NOT NULL
ORDER BY grade, issue_d;


-- 7.2 Default rate rank by state
SELECT
    addr_state,
    COUNT(*)                                     AS loan_count,
    ROUND(AVG(is_default) * 100, 2)              AS default_rate_pct,
    RANK() OVER (ORDER BY AVG(is_default) DESC)  AS risk_rank,
    NTILE(4) OVER (ORDER BY AVG(is_default) DESC) AS risk_quartile
FROM lending_club
GROUP BY addr_state
HAVING loan_count >= 50
ORDER BY default_rate_pct DESC;


-- 7.3 Borrower percentile scoring within grade
SELECT
    id,
    grade,
    fico_score,
    dti,
    annual_inc,
    loan_amnt,
    is_default,
    PERCENT_RANK() OVER (PARTITION BY grade ORDER BY fico_score DESC)  AS fico_percentile_in_grade,
    PERCENT_RANK() OVER (PARTITION BY grade ORDER BY dti ASC)          AS dti_percentile_in_grade,
    PERCENT_RANK() OVER (PARTITION BY grade ORDER BY annual_inc DESC)  AS income_percentile_in_grade
FROM lending_club
ORDER BY grade, fico_percentile_in_grade;


-- ============================================================
-- SECTION 8: DATA QUALITY VALIDATION CHECKS
-- ============================================================

-- 8.1 Duplicate check
SELECT
    id,
    COUNT(*) AS frequency
FROM lending_club
GROUP BY id
HAVING frequency > 1
ORDER BY frequency DESC;


-- 8.2 Outlier detection — extreme values
SELECT 'loan_amnt'  AS field, COUNT(*) AS outlier_count FROM lending_club WHERE loan_amnt > 40000
UNION ALL
SELECT 'annual_inc',          COUNT(*) FROM lending_club WHERE annual_inc > 500000
UNION ALL
SELECT 'dti',                 COUNT(*) FROM lending_club WHERE dti > 50
UNION ALL
SELECT 'int_rate',            COUNT(*) FROM lending_club WHERE int_rate > 30
UNION ALL
SELECT 'revol_util',          COUNT(*) FROM lending_club WHERE revol_util > 100;


-- 8.3 Validate segment coverage
SELECT
    risk_segment,
    COUNT(*)                                         AS record_count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) AS pct
FROM lending_club
GROUP BY risk_segment
ORDER BY record_count DESC;
