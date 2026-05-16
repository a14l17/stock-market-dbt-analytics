{{ config(severity='warn') }}
--if the abs_prediction_error exceeds threshold, we raise a warning instead of a fail for test due to black swan events
-- tests/assert_prediction_error_within_bounds.sql
-- Flag rows where prediction error exceeds 25% in a single week.

select
      selection_id
    , symbol
    , selection_week_start
    , predicted_weekly_return
    , actual_weekly_return
    , abs_prediction_error
from {{ ref('fct_basket_performance') }}
where abs_prediction_error > 0.25