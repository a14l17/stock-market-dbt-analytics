-- tests/assert_prediction_error_within_bounds.sql
-- Flag rows where prediction error exceeds 25% in a single week. Arbitrary cut off can look into this later
-- Likely indicates bad source data rather than a genuine prediction failure.

select
      selection_id
    , symbol
    , selection_week_start
    , predicted_weekly_return
    , actual_weekly_return
    , abs_prediction_error
from {{ ref('fct_basket_performance') }}
where abs_prediction_error > 0.25