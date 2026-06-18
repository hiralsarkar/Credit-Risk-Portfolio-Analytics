// ============================================================
// LENDING CLUB — POWER QUERY (M LANGUAGE) TRANSFORMATION SCRIPT
// Author: Hiral Sarkar
//
// HOW TO USE:
// 1. Power BI Desktop → Get Data → Text/CSV → select cleaned_lending_club.csv
// 2. In Transform Data (Power Query Editor) → Advanced Editor
// 3. Replace the content with this script
// 4. Update Source path to match your file location
// ============================================================

let

    // ─────────────────────────────────────────────────────────
    // STEP 1: LOAD SOURCE FILE
    // ─────────────────────────────────────────────────────────
    Source = Csv.Document(
        File.Contents("C:\YourPath\cleaned_lending_club.csv"),  // <-- UPDATE PATH
        [
            Delimiter     = ",",
            Columns       = null,
            Encoding      = 65001,   // UTF-8
            QuoteStyle    = QuoteStyle.None
        ]
    ),

    // Promote first row to headers
    PromoteHeaders = Table.PromoteHeaders(Source, [PromoteAllScalars = true]),


    // ─────────────────────────────────────────────────────────
    // STEP 2: DATA TYPE ASSIGNMENTS
    // ─────────────────────────────────────────────────────────
    SetTypes = Table.TransformColumnTypes(
        PromoteHeaders,
        {
            // Numeric fields
            {"loan_amnt",             type number},
            {"funded_amnt",           type number},
            {"int_rate",              type number},
            {"installment",           type number},
            {"annual_inc",            type number},
            {"dti",                   type number},
            {"fico_score",            type number},
            {"revol_bal",             type number},
            {"revol_util",            type number},
            {"total_pymnt",           type number},
            {"total_rec_prncp",       type number},
            {"total_rec_int",         type number},
            {"recoveries",            type number},
            {"lgd_proxy",             type number},
            {"recovery_rate",         type number},
            {"el_proxy",              type number},
            {"payment_to_income",     type number},
            {"credit_history_months", type number},
            {"delinq_2yrs",           type number},
            {"open_acc",              type number},
            {"total_acc",             type number},
            {"term_months",           type number},
            {"emp_years",             type number},

            // Integer / flag fields
            {"is_default",            Int64.Type},
            {"is_chargeoff",          Int64.Type},
            {"is_current",            Int64.Type},
            {"is_fully_paid",         Int64.Type},
            {"watchlist_flag",        Int64.Type},
            {"campaign_response",     Int64.Type},
            {"high_value_customer",   Int64.Type},

            // Date fields
            {"issue_d",               type date},
            {"last_pymnt_d",          type date},
            {"earliest_cr_line",      type date},

            // Text / categorical fields
            {"grade",                 type text},
            {"sub_grade",             type text},
            {"purpose",               type text},
            {"loan_status",           type text},
            {"home_ownership",        type text},
            {"addr_state",            type text},
            {"risk_segment",          type text},
            {"income_band",           type text},
            {"fico_band",             type text},
            {"dti_band",              type text},
            {"loan_size_band",        type text},
            {"term",                  type text}
        }
    ),


    // ─────────────────────────────────────────────────────────
    // STEP 3: REMOVE UNNECESSARY COLUMNS
    // (Keep only what Power BI needs — reduces model size)
    // ─────────────────────────────────────────────────────────
    KeepColumns = Table.SelectColumns(
        SetTypes,
        {
            "loan_amnt", "funded_amnt", "int_rate", "installment",
            "grade", "sub_grade", "purpose", "loan_status", "term", "term_months",
            "annual_inc", "dti", "delinq_2yrs", "fico_score",
            "open_acc", "total_acc", "revol_bal", "revol_util",
            "total_pymnt", "total_rec_prncp", "total_rec_int", "recoveries",
            "emp_years", "home_ownership", "addr_state",
            "issue_d", "last_pymnt_d", "earliest_cr_line",
            "is_default", "is_chargeoff", "is_current", "is_fully_paid",
            "lgd_proxy", "recovery_rate", "el_proxy",
            "risk_segment", "income_band", "fico_band", "dti_band", "loan_size_band",
            "watchlist_flag", "campaign_response", "high_value_customer",
            "payment_to_income", "credit_history_months"
        }
    ),


    // ─────────────────────────────────────────────────────────
    // STEP 4: CLEAN TEXT FIELDS
    // ─────────────────────────────────────────────────────────
    TrimText = Table.TransformColumns(
        KeepColumns,
        {
            {"grade",        Text.Trim},
            {"purpose",      Text.Trim},
            {"loan_status",  Text.Trim},
            {"addr_state",   Text.Trim},
            {"risk_segment", Text.Trim},
            {"income_band",  Text.Trim},
            {"fico_band",    Text.Trim}
        }
    ),

    // Standardise loan status capitalisation
    StandardiseStatus = Table.ReplaceValue(
        TrimText,
        each [loan_status],
        each Text.Proper([loan_status]),
        Replacer.ReplaceValue,
        {"loan_status"}
    ),


    // ─────────────────────────────────────────────────────────
    // STEP 5: ADD CALCULATED COLUMNS IN POWER QUERY
    // (Pre-calculations that don't need DAX slicing)
    // ─────────────────────────────────────────────────────────

    // Loan issue year and month for time intelligence
    AddIssueYear = Table.AddColumn(
        StandardiseStatus,
        "Issue Year",
        each if [issue_d] <> null then Date.Year([issue_d]) else null,
        Int64.Type
    ),

    AddIssueMonth = Table.AddColumn(
        AddIssueYear,
        "Issue Month",
        each if [issue_d] <> null then Date.Month([issue_d]) else null,
        Int64.Type
    ),

    AddIssueYearMonth = Table.AddColumn(
        AddIssueMonth,
        "Issue Year-Month",
        each if [issue_d] <> null
            then Text.From(Date.Year([issue_d])) & "-" &
                 Text.PadStart(Text.From(Date.Month([issue_d])), 2, "0")
            else null,
        type text
    ),

    // Loan loss label for visuals
    AddLossLabel = Table.AddColumn(
        AddIssueYearMonth,
        "Loan Outcome",
        each if [is_chargeoff] = 1 then "Charged Off"
             else if [is_default] = 1 then "Default"
             else if [is_fully_paid] = 1 then "Fully Paid"
             else if [is_current] = 1 then "Current"
             else "Other",
        type text
    ),

    // Risk tier simplified for visuals
    AddRiskTier = Table.AddColumn(
        AddLossLabel,
        "Risk Tier",
        each if [grade] = "A" or [grade] = "B" then "Low Risk"
             else if [grade] = "C" or [grade] = "D" then "Medium Risk"
             else "High Risk",
        type text
    ),

    // Watchlist label
    AddWatchlistLabel = Table.AddColumn(
        AddRiskTier,
        "Watchlist Status",
        each if [watchlist_flag] = 1 then "Watchlist" else "Normal",
        type text
    ),

    // Interest rate band
    AddIntRateBand = Table.AddColumn(
        AddWatchlistLabel,
        "Interest Rate Band",
        each if [int_rate] < 8 then "< 8%"
             else if [int_rate] < 12 then "8–12%"
             else if [int_rate] < 17 then "12–17%"
             else if [int_rate] < 22 then "17–22%"
             else "> 22%",
        type text
    ),


    // ─────────────────────────────────────────────────────────
    // STEP 6: HANDLE NULLS IN CRITICAL COLUMNS
    // ─────────────────────────────────────────────────────────
    FillNullGrade = Table.ReplaceValue(
        AddIntRateBand, null, "Unknown", Replacer.ReplaceValue, {"grade"}
    ),

    FillNullSegment = Table.ReplaceValue(
        FillNullGrade, null, "Unknown", Replacer.ReplaceValue,
        {"risk_segment", "income_band", "fico_band", "dti_band", "loan_size_band"}
    ),

    FillNullState = Table.ReplaceValue(
        FillNullSegment, null, "Unknown", Replacer.ReplaceValue, {"addr_state"}
    ),

    FillNullPurpose = Table.ReplaceValue(
        FillNullState, null, "Other", Replacer.ReplaceValue, {"purpose"}
    ),


    // ─────────────────────────────────────────────────────────
    // STEP 7: REMOVE OBVIOUS OUTLIERS
    // ─────────────────────────────────────────────────────────
    RemoveOutliers = Table.SelectRows(
        FillNullPurpose,
        each
            [annual_inc]  <> null and [annual_inc] < 2000000 and
            [loan_amnt]   <> null and [loan_amnt]  > 0 and
            [int_rate]    <> null and [int_rate]   > 0 and [int_rate] < 35
    ),


    // ─────────────────────────────────────────────────────────
    // STEP 8: SORT FOR PERFORMANCE
    // ─────────────────────────────────────────────────────────
    SortByDate = Table.Sort(
        RemoveOutliers,
        {{"issue_d", Order.Ascending}}
    ),


    // ─────────────────────────────────────────────────────────
    // FINAL: RENAME TABLE
    // ─────────────────────────────────────────────────────────
    FinalTable = Table.RenameColumns(
        SortByDate,
        {}  // no further renames needed — column names already clean
    )

in
    FinalTable


// ─────────────────────────────────────────────────────────────
// RECOMMENDED POWER QUERY SETTINGS
// ─────────────────────────────────────────────────────────────
// After loading:
// 1. File → Options → Query reduction → Add Apply button to each slicer
// 2. Model view → set all segment columns as "Don't summarize"
// 3. Mark DateTable[Date] as the Date Table
// 4. Disable auto-date/time (reduces model bloat)
//    File → Options → Data Load → uncheck "Auto date/time for new files"
// ─────────────────────────────────────────────────────────────
