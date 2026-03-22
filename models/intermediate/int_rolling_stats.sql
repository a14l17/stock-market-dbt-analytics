-- Compute the 3 scoring signals per asset per day using a
--          12-week (60 trading days) lookback window.
--
-- SIGNALS:
--   momentum    = rolling avg daily return      (higher = better)
--   volatility  = rolling stddev of returns     (lower = safer)
--   consistency = % of days with positive return (higher = steadier)
--
-- NORMALIZATION:
--   Signals are normalized to 0-1 WITHIN asset_type per trading date.
--   Equities and futures have structurally different return distributions
--   so we compare like with like — equities vs equities, futures vs futures.
--
-- MINIMUM DATA GATE:
--   Rows with fewer than 60 days in window are excluded to avoid
--   unstable rolling stats early in the history.

{% set lookback_days     = 60 %}
{% set min_days_required = 45 %}

with daily_returns as (

    select
          symbol
        , asset_type
        , trading_date
        , daily_return
    from {{ ref('int_daily_returns') }}

),

-- defining momentum, volatility and consistency
rolling_calcs as (

    select
          symbol
        , asset_type
        , trading_date
        , daily_return
        , {{ rolling_avg('daily_return', lookback_days) }}        as momentum
        , {{ rolling_stddev('daily_return', lookback_days) }}     as volatility
        , {{ rolling_pos_pct('daily_return', lookback_days) }}    as consistency
        , {{ rolling_row_count('daily_return', lookback_days) }}  as days_in_window

    from daily_returns

),

-- minimum number of days at the start, arbitarily chose 75% of the 60 day rolling period, thinking it should be stable enough
filtered as (

    select *
    from rolling_calcs
    where days_in_window >= {{ min_days_required }}

),

-- normalising our three scorers to be on the same scale
normalized as (

    select
          symbol
        , asset_type
        , trading_date
        , momentum
        , volatility
        , consistency
        , days_in_window

        -- Normalize momentum: higher is better (0 = worst in group, 1 = best)
        , (momentum - min(momentum) over (partition by trading_date, asset_type))
          / nullif(
              max(momentum) over (partition by trading_date, asset_type)
              - min(momentum) over (partition by trading_date, asset_type),
            0)                                                    as momentum_score

        -- Normalize volatility: lower is safer so invert the normalization
        , 1 - (
              (volatility - min(volatility) over (partition by trading_date, asset_type))
              / nullif(
                  max(volatility) over (partition by trading_date, asset_type)
                  - min(volatility) over (partition by trading_date, asset_type),
                0)
          )                                                       as volatility_score

        -- Normalize consistency: higher is better
        , (consistency - min(consistency) over (partition by trading_date, asset_type))
          / nullif(
              max(consistency) over (partition by trading_date, asset_type)
              - min(consistency) over (partition by trading_date, asset_type),
            0)                                                    as consistency_score

    from filtered

)

select * from normalized