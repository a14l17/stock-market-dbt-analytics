-- PURPOSE: Clean and standardize raw Yahoo Finance data.
-- FUTURES-SPECIFIC HANDLING:
--   a) Asset type: tagged as 'equity' or 'futures' for downstream separation
--   b) Contract rolls: price jumps >3% day-over-day on futures are flagged
--      (not dropped) so downstream models can handle them explicitly

with source as (

    select * from {{ source('raw_yahoo', 'raw_yahoo_prices') }}

),

cleaned as (

    select
          symbol
        , case
            when symbol like '%=F' then 'futures'
            else 'equity'
          end                                             as asset_type
        , cast(trading_date as date)                      as trading_date
        , cast(open as numeric)                           as open_price
        , cast(high as numeric)                           as high_price
        , cast(low as numeric)                            as low_price
        , cast(close as numeric)                          as close_price
        , cast(adj_close as numeric)                      as adj_close_price
        , cast(volume as int64)                           as volume
        , source                                          as data_source
        , cast(ingestion_timestamp as timestamp)          as ingested_at

    from source
    where close is not null
      and trading_date is not null

),

deduplicated as (
    -- if the same symbol/date was ingested more than once, keep the latest
    select *
    from cleaned
    qualify row_number() over (
        partition by symbol, trading_date
        order by ingested_at desc
    ) = 1
),

with_contract_roll_flag as (

    -- Flag futures rows where the day-over-day price change exceeds 3%.
    -- These are likely contract roll events, not real market moves.
    -- Flagged rows are excluded from return calculations in int_daily_returns.
    select
          *
        , case
            when asset_type = 'futures'
                and abs(
                    close_price - lag(close_price) over (
                        partition by symbol order by trading_date
                    )
                ) / nullif(
                    lag(close_price) over (
                        partition by symbol order by trading_date
                    ), 0
                ) > 0.03
            then true
            else false
          end                                             as is_contract_roll
    from deduplicated

)

select * from with_contract_roll_flag