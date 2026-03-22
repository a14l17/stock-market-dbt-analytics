-- Score every asset at each week-end and select the basket.
-- Top 3 equities + top 2 futures, ranked independently.
--
-- COMPOSITE SCORE WEIGHTS:
--   consistency: 40% — steady gains prioritised over big swings
--   volatility:  35% — safety is second priority
--   momentum:    25% — direction matters but weighted least
--
-- PREDICTED RETURN:
--   predicted_weekly_return = momentum × 5 trading days
--   This is intentionally naive. fct_basket_performance measures how wrong it is.

with rolling_stats as (

    select * from {{ ref('int_rolling_stats') }}

),

week_ends as (

    -- Last trading day of each ISO week (Mon-Sun) per symbol
    select
          symbol
        , asset_type
        , date_trunc(trading_date, week(monday))    as week_start
        , max(trading_date)                         as week_end_date

    from rolling_stats
    group by 1, 2, 3

),

week_end_scores as (

    select
          w.symbol
        , w.asset_type
        , w.week_start
        , w.week_end_date
        , r.momentum
        , r.volatility
        , r.consistency
        , r.momentum_score
        , r.volatility_score
        , r.consistency_score

        , round(
            (0.25 * r.momentum_score)
            + (0.35 * r.volatility_score)
            + (0.40 * r.consistency_score),
            6
          )                                         as composite_score

        , round(r.momentum * 5, 6)                  as predicted_weekly_return

    from week_ends w
    inner join rolling_stats r
        on  w.symbol       = r.symbol
        and w.week_end_date = r.trading_date

),

ranked as (

    select
          *
        , row_number() over (
            partition by week_start, asset_type
            order by composite_score desc
          )                                         as rank_within_type

    from week_end_scores

),

basket as (

    select
          *
        , true                                      as is_selected
        , case
            when asset_type = 'equity'  then 'equity_basket'
            when asset_type = 'futures' then 'commodity_basket'
          end                                       as basket_name

    from ranked
    where (asset_type = 'equity'  and rank_within_type <= 3)
       or (asset_type = 'futures' and rank_within_type <= 2)

)

select * from basket