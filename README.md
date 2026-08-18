# Stock Market Analytics with dbt

A rules-based weekly basket selection model built with dbt and BigQuery.
Selects the top 3 S&P 500 equities and top 2 commodity futures each week
based on a 12-week rolling score, then tracks predicted vs actual performance.

---

## What this project does

Each week the model:
1. Scores every asset on 3 signals over the prior 12 weeks
2. Selects top 3 equities + top 2 commodity futures
3. Predicts next week's return based on momentum
4. Records actual return and measures prediction error

---

## Tech stack

- **dbt Core** — data transformation and modelling
- **BigQuery** — data warehouse
- **Python** — data ingestion from Yahoo Finance
- **GCP** — cloud infrastructure

---

## Data pipeline

```
Yahoo Finance API
      ↓
yahoo_finance_ds.py              # ingestion script
      ↓
raw_yahoo.raw_yahoo_prices       # BigQuery source table
      ↓
stg_yahoo_prices                 # staging: clean, dedupe, flag contract rolls
      ↓
int_daily_returns                # intermediate: daily return calculations
int_rolling_stats                # intermediate: 12-week rolling signals
int_basket_selection             # intermediate: weekly scoring and selection
      ↓
fct_basket_performance           # mart: predicted vs actual performance
```

---

## Asset universe

**Equities:** AAPL, MSFT, GOOGL, AMZN, NVDA, META, JPM, JNJ, V, UNH

**Commodity futures:**

| Ticker | Commodity |
|---|---|
| GC=F | Gold |
| SI=F | Silver |
| CL=F | Crude Oil (WTI) |
| UX=F | Uranium |
| NG=F | Natural Gas |

---

## Scoring model

Assets scored weekly on 3 signals over a 12-week (60 trading day) lookback:

| Signal | Description | Weight |
|---|---|---|
| Consistency | % of days with positive return | 40% |
| Volatility safety | 1 − normalised stddev of returns | 35% |
| Momentum | Average daily return | 25% |

Signals are normalised to 0-1 within asset type — equities and futures are scored
separately so structural volatility differences between asset classes don't distort rankings.

---

## Setup

### Prerequisites
- Python 3.11+
- dbt-bigquery
- GCP project with BigQuery and billing enabled

### Installation

```bash
git clone https://github.com/a14l17/stock-market-dbt-analytics
cd stock-market-dbt-analytics
pip install -r requirements.txt
dbt deps
```

### Configure environment

```bash
cp .env.example .env
# fill in GCP_PROJECT_ID and GOOGLE_APPLICATION_CREDENTIALS
cp profiles.yml.example ~/.dbt/profiles.yml
# fill in your GCP project details
```

### Ingest data

```bash
python3 yahoo_finance_ds.py <period begin(yyyy-mm-dd)> <period ending(yyyy-mm-dd)>
```

### Run dbt

```bash
dbt run      # build all models
dbt test     # validate data quality
```

---

## Key findings

- Gold (`GC=F`) consistently scores highest in the commodity basket, reflecting its
  safe haven status during volatile macro conditions
- Directional accuracy is ~50% — consistent with the limitations of a naive momentum model
- The model fails on sudden news-driven events (e.g. UNH dropped 25% in April 2025
  following a DOJ investigation — unpredictable from momentum alone)
- Momentum signal consistently over-predicts returns in volatile macro environments

---

## Security

- No credentials or project IDs are hardcoded anywhere in this repo
- All environment-specific values are loaded from `.env` (excluded via `.gitignore`)
- See `.env.example` for required variables
- Never commit your `.env` file or GCP service account JSON key