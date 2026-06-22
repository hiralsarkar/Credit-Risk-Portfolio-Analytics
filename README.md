# Lending Club — Credit Risk & Campaign Analytics
## Complete Power BI Project Package

**Author:** Hiral Sarkar | MSc Global Financial Markets | PG Data Science & AI

### [🔗 Live Interactive Dashboard →](https://hiralsarkar.github.io/Credit-Risk-Portfolio-Analytics/dashboard_mockup.html)

> Dark-theme analytics dashboard - KPI cards, choropleth risk map, 9 interactive charts, watchlist table. No install required, runs in any browser.

---

## Project Structure

```
lending_club_powerbi/
│
├── notebooks/
│   └── 01_eda_and_prep.ipynb       ← Run this FIRST
│
├── sql/
│   └── lending_club_queries.sql    ← 30+ analytical queries
│
├── dax/
│   └── dax_measures.dax            ← 50+ DAX measures (paste into Power BI)
│
├── powerquery/
│   └── transform.pq                ← Power Query M script
│
└── dashboard_mockup.html           ← Interactive dashboard preview
```

---

## Step-by-Step Setup

### Step 1 - Run the EDA Notebook
```bash
pip install pandas numpy matplotlib seaborn jupyter
jupyter notebook notebooks/01_eda_and_prep.ipynb
```
Run all cells top to bottom (Run → Run All Cells).
**Outputs:**
- `cleaned_lending_club.csv` - main import file for Power BI
- `segment_summary.csv` - grade-level summary
- `state_summary.csv` - geographic risk summary

Update `DATA_PATH` in the script to point to your downloaded Lending Club file.

---

### Step 2 - Load into Power BI

1. Open **Power BI Desktop** → **Get Data** → **Text/CSV**
2. Select `cleaned_lending_club.csv`
3. Click **Transform Data** (don't load directly)
4. In Power Query Editor → **Advanced Editor**
5. Replace the content with `powerquery/transform.pq`
6. Update the file path in the `Source` step
7. Click **Close & Apply**

---

### Step 3 - Create Date Table

In Power BI → **Table view** → **New table**, paste:
```dax
DateTable =
ADDCOLUMNS(
    CALENDAR(DATE(2007,1,1), DATE(2020,12,31)),
    "Year",        YEAR([Date]),
    "Month Num",   MONTH([Date]),
    "Month Name",  FORMAT([Date], "MMM"),
    "Quarter",     "Q" & QUARTER([Date]),
    "Year-Month",  FORMAT([Date], "YYYY-MM")
)
```
Then in **Model view**, drag `DateTable[Date]` → `lending_club[issue_d]`.

---

### Step 4 - Add DAX Measures

1. Create a blank table: **Enter data** → name it `_Measures`
2. Open `dax/dax_measures.dax`
3. For each measure block, click the table → **New measure** → paste formula
4. Organise into Display Folders matching the section headers

Key measures to add first:
- Total Loans
- Default Rate %
- Chargeoff Rate %
- Watchlist Accounts
- Total Exposure
- Portfolio Health Score

---

### Step 5 - Build Dashboard Pages

#### Page 1: Executive Summary
| Visual | Fields |
|--------|--------|
| KPI Cards (6) | Total Loans, Exposure, Default Rate %, Chargeoff Rate %, Watchlist, Campaign Response |
| Bar Chart | Default Rate % by Grade |
| Line + Bar combo | Loans Issued + Default Rate % over time |
| Donut | Loan Outcome distribution |

#### Page 2: Risk Segmentation
| Visual | Fields |
|--------|--------|
| Clustered Bar | Default Rate % by Income Band + Grade |
| Horizontal Bar | Default Rate % by FICO Band |
| Stacked Bar | Chargeoff Rate % vs Recovery Rate % by Grade |
| Treemap | Total Exposure by Risk Segment |

#### Page 3: Campaign Analytics
| Visual | Fields |
|--------|--------|
| Bubble Chart | Purpose vs Loan Count vs Default Rate |
| Bar | Campaign Response Rate % by Segment |
| Matrix | Grade × Income Band × Default Rate % |
| KPI Card | High Value Customer % |

#### Page 4: Watchlist / Early Warning
| Visual | Fields |
|--------|--------|
| Table | Watchlist accounts with conditional formatting |
| Gauge | Watchlist Rate % vs threshold |
| Map | Default Rate % by State (addr_state) |
| KPI | Portfolio at Risk (PAR) |

---

### Step 6 — SQL Queries (Optional — for BigQuery/Postgres)

Import `cleaned_lending_club.csv` into your DB as table `lending_club`, then run queries from `sql/lending_club_queries.sql`.

Sections covered:
1. Data validation & profiling
2. Portfolio overview KPIs
3. Risk segmentation (grade, FICO, income, DTI)
4. Early warning & watchlist
5. Charge-off analysis
6. Campaign analytics
7. Window functions (running totals, rankings, percentiles)
8. Data quality checks

---

## Key Metrics Explained

| Metric | Definition | Source Column |
|--------|-----------|---------------|
| Default Rate | % of loans in default/late/chargeoff | `is_default` |
| Chargeoff Rate | % of loans fully charged off | `is_chargeoff` |
| LGD Proxy | 1 - (total_pymnt / funded_amnt) | `lgd_proxy` |
| EL Proxy | is_default × LGD × funded_amnt | `el_proxy` |
| Watchlist | DTI>30 OR util>80% OR delinq>0 OR rate>20% | `watchlist_flag` |
| Campaign Response | Grade A/B/C borrowers | `campaign_response` |
| PAR | % exposure in late/default/chargeoff | DAX measure |

---

## Resume Talking Points

- **100,000+ records** cleaned, transformed, and modelled end-to-end
- **EDA** surfaced risk drivers: grade, FICO, DTI, income, utilisation
- **Customer segmentation** by risk profile (Prime → Deep Subprime), income band, FICO band, geography
- **Power BI dashboard** with KPI cards, drill-through, and conditional formatting
- **DAX measures**: 50+ measures including period-over-period, risk-adjusted return, portfolio health score
- **Power Query**: automated transformation pipeline, reduced manual prep by 70%
- **SQL**: window functions (RANK, PERCENT_RANK, SUM OVER), CTEs, aggregations across pipeline stages
- **Early warning system**: watchlist flagging with multi-signal logic
- **Campaign analytics**: response rate modelling by segment, high-value customer identification

---

*Built to demonstrate CRO-level systems thinking for AI Model Risk Management roles.*
