-- tests/assert_max_commodity_picks_per_week.sql
-- Assert no week has more than 2 commodity picks.

select
      selection_week_start
    , basket_name
    , count(*) as pick_count
from {{ ref('fct_basket_performance') }}
where basket_name = 'commodity_basket'
group by 1, 2
having count(*) > 2