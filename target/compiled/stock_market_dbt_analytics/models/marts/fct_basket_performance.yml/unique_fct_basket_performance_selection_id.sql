
    
    

with dbt_test__target as (

  select selection_id as unique_field
  from `dbt-demo-project-485817`.`dbt_dev`.`fct_basket_performance`
  where selection_id is not null

)

select
    unique_field,
    count(*) as n_records

from dbt_test__target
group by unique_field
having count(*) > 1


