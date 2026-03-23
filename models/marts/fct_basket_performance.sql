-- Predicted vs actual weekly return per selected asset.
--
-- INCREMENTAL MATERIALIZATION:
--   Once a week is complete (selection made + actual return observed), that record
--   never changes. Incremental means: first run builds everything, subsequent runs
--   only process weeks newer than the latest already in the table.
--
--   The {{ is_incremental() }} block is only included in compiled SQL when the
--   target table already exists. On first run it is ignored entirely.

{{ config(
    materialized     = 'incremental',
    unique_key       = 'selection_id',
    on_schema_change = 'sync_all_columns'
) }}


with basket as (

    select * from {{ ref('int_basket_selection') }}

    {% if is_incremental() %}
    where week_start > (
        select max(week_start) from {{ this }}
    )
    {% endif %}

),

actual_weekly_returns as (

    select
          symbol
        , date_trunc(trading_date, week(monday))    as week_start
        , sum(daily_return)                         as actual_weekly_return
        , count(*)                                  as actual_trading_days

    from {{ ref('int_daily_returns') }}
    group by 1, 2

),

joined as (

    select
          {{ dbt_utils.generate_surrogate_key(['b.symbol', 'b.week_start']) }}
                                                    as selection_id

        , b.symbol
        , b.asset_type
        , b.basket_name

        , b.week_start                              as selection_week_start
        , b.week_end_date                           as selection_week_end
        , date_add(b.week_start, interval 1 week)   as prediction_week_start

        , b.rank_within_type                        as selection_rank
        , b.composite_score
        , b.momentum_score
        , b.volatility_score
        , b.consistency_score
        , b.momentum
        , b.volatility
        , b.consistency

        , b.predicted_weekly_return
        , a.actual_weekly_return
        , a.actual_trading_days

        -- How wrong were we?
        -- Positive = overpredicted. Negative = underpredicted.
        , round(
            b.predicted_weekly_return - a.actual_weekly_return,
            6
          )                                         as prediction_error

        -- Did we at least get the direction right?
        , case
            when b.predicted_weekly_return >= 0 and a.actual_weekly_return >= 0 then true
            when b.predicted_weekly_return <  0 and a.actual_weekly_return <  0 then true
            else false
          end                                       as direction_correct

        , abs(round(
            b.predicted_weekly_return - a.actual_weekly_return,
            6
          ))                                        as abs_prediction_error

        , current_timestamp()                       as dbt_updated_at

    from basket b
    left join actual_weekly_returns a
        on  b.symbol = a.symbol
        and date_add(b.week_start, interval 1 week) = a.week_start

),

complete_weeks_only as (

    -- Exclude weeks where actual data hasn't arrived yet (future weeks)
    select *
    from joined
    where actual_weekly_return is not null

)

select * from complete_weeks_only