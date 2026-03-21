
##pulling daily data from yahoo finance##

##import necessary libraries##
import os
import sys
import yfinance as yf
import pandas as pd
from google.cloud import bigquery
from datetime import datetime
from dotenv import load_dotenv


## Load environment variables from .env bc bad behaviour to hardcode smh
load_dotenv()

##bigquery connection setup##
##we set values in a separate .env file no hardcoding thats bad behaviour##
PROJECT_ID = os.environ.get("GCP_PROJECT_ID")
DATASET_ID = os.environ.get("BQ_DATASET_ID", "raw_yahoo")
TABLE_ID   = os.environ.get("BQ_TABLE_ID",   "raw_yahoo_prices")

#tells us if we did something wrong with the setup
def validate_env():
    """Fail fast if required environment variables are missing."""
    if not PROJECT_ID:
        raise EnvironmentError(
            "GCP_PROJECT_ID is not set.\n"
            "Run: cp .env.example .env  then fill in your project ID."
        )
    if not os.environ.get("GOOGLE_APPLICATION_CREDENTIALS"):
        raise EnvironmentError(
            "GOOGLE_APPLICATION_CREDENTIALS is not set.\n"
            "Set this to the path of your GCP service account key JSON file."
        )

## ---- TICKER UNIVERSE ----
## S&P 500 majors (equities)
EQUITY_SYMBOLS = [
    "AAPL",   # Apple
    "MSFT",   # Microsoft
    "GOOGL",  # Alphabet
    "AMZN",   # Amazon
    "NVDA",   # Nvidia
    "META",   # Meta
    "JPM",    # JPMorgan
    "JNJ",    # Johnson & Johnson
    "V",      # Visa
    "UNH",    # UnitedHealth
]
 
## Commodity futures (Yahoo Finance continuous contract format)
## These auto-roll to the nearest active contract.
## Artificial price jumps at roll dates are flagged in stg_yahoo_prices.sql.
FUTURES_SYMBOLS = [
    "GC=F",   # Gold futures
    "SI=F",   # Silver futures
    "CL=F",   # Crude Oil (WTI) futures
    "UX=F",   # Uranium futures (thin liquidity — expect some gaps)
    "NG=F",   # Natural Gas futures
]

ALL_SYMBOLS = EQUITY_SYMBOLS + FUTURES_SYMBOLS

def fetch_yahoo_prices(symbols, start_date, end_date):
    """
    Download daily OHLCV for all symbols from Yahoo Finance.
    Returns a flat DataFrame with one row per symbol per trading day.
 
    Notes:
    - auto_adjust=False keeps unadjusted prices. Adjusted prices correct
      for splits/dividends which distorts historical return calculations. Want to look at it wo splits/div impact
    - Futures may have gaps on equity holidays and vice versa — missing
      close prices are skipped rather than filled. Might return to this whether I want the rows in there 
      regardless of empty values or not
    """
    df = yf.download(
        tickers     = symbols,
        start       = start_date,
        end         = end_date,
        auto_adjust = False,
        group_by    = "ticker"
    )
 
    rows = []
 
    for symbol in symbols:
        try:
            symbol_df = df[symbol].reset_index()
        except KeyError:
            print(f"WARNING: No data returned for {symbol} — skipping")
            continue
 
        for _, r in symbol_df.iterrows():
            if pd.isnull(r.get("Close")):
                continue
 
            rows.append({
                "symbol":              symbol,
                "trading_date":        r["Date"].date(),
                "open":                float(r["Open"])      if pd.notnull(r.get("Open"))      else None,
                "high":                float(r["High"])      if pd.notnull(r.get("High"))      else None,
                "low":                 float(r["Low"])       if pd.notnull(r.get("Low"))       else None,
                "close":               float(r["Close"])     if pd.notnull(r.get("Close"))     else None,
                "adj_close":           float(r["Adj Close"]) if pd.notnull(r.get("Adj Close")) else None,
                "volume":              int(r["Volume"])      if pd.notnull(r.get("Volume"))    else None,
                "currency":            "USD",
                "source":              "yahoo_finance",
                "ingestion_timestamp": datetime.utcnow()
            })
 
    return pd.DataFrame(rows)
 
 
def load_to_bigquery(df):
    """
    Append DataFrame rows to the BigQuery raw table.
 
    Uses WRITE_APPEND so re-running ingestion for the same date range
    won't lose data — duplicates are handled in stg_yahoo_prices.sql
    via a deduplication step (latest ingestion_timestamp wins).
    """
    client    = bigquery.Client(project=PROJECT_ID)
    table_ref = f"{PROJECT_ID}.{DATASET_ID}.{TABLE_ID}"
 
    job_config = bigquery.LoadJobConfig(
        write_disposition = "WRITE_APPEND"
    )
 
    job = client.load_table_from_dataframe(df, table_ref, job_config=job_config)
    job.result()
    print(f"Loaded {job.output_rows} rows into {table_ref}")
 
 
if __name__ == "__main__":
 
    validate_env()
 
    if len(sys.argv) < 3:
        print("Usage:   python3 yahoo_finance_ds.py <START_DATE> <END_DATE>")
        print("Example: python3 yahoo_finance_ds.py 2022-01-01 2025-01-01")
        sys.exit(1)
 
    start_date = sys.argv[1]
    end_date   = sys.argv[2]
 
    print(f"Fetching {len(ALL_SYMBOLS)} symbols from {start_date} to {end_date}...")
    print(f"  Equities: {EQUITY_SYMBOLS}")
    print(f"  Futures:  {FUTURES_SYMBOLS}")
 
    df = fetch_yahoo_prices(
        symbols    = ALL_SYMBOLS,
        start_date = start_date,
        end_date   = end_date
    )
 
    print(f"\nRows fetched: {len(df)}")
    print(df.groupby("symbol").size().to_string())
 
    load_to_bigquery(df)
