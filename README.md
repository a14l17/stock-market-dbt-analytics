

tracking 3 S&P equities + 2 commodity futures 
predicted return vs actual return
tracked weekly

structure 
├── yahoo_finance_ds.py              # Data ingestion: Yahoo Finance → BigQuery
├── dbt_project.yml                  # dbt config: materializations, paths
│
├── models/
│   ├── staging/
│   │   ├── sources.yml              # raw source tables
│   │   ├── stg_yahoo_prices.sql     # clean + standardize raw data
│   │   └── stg_yahoo_prices.yml     # tests for staging model
│   │
│   ├── intermediate/
│   │   ├── int_daily_returns.sql    # daily return calculations
│   │   ├── int_rolling_stats.sql    # 12-week rolling signals (uses macros)
│   │   └── int_basket_selection.sql # weekly scoring + top pick selection
│   │
│   └── marts/
│       ├── fct_basket_performance.sql   # output: predicted vs actual
│       └── fct_basket_performance.yml   # tests for mart model
│
├── macros/
│   └── rolling_stats.sql            # rolling_avg, rolling_stddev, rolling_pos_pct
│
└── tests/
    ├── assert_max_equity_picks_per_week.sql
    ├── assert_max_commodity_picks_per_week.sql
    └── assert_prediction_error_within_bounds.sql