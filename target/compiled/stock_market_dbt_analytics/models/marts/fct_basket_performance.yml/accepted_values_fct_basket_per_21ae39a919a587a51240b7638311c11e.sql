
    
    

with all_values as (

    select
        basket_name as value_field,
        count(*) as n_records

    from `dbt-demo-project-485817`.`dbt_dev`.`fct_basket_performance`
    group by basket_name

)

select *
from all_values
where value_field not in (
    'equity_basket','commodity_basket'
)


