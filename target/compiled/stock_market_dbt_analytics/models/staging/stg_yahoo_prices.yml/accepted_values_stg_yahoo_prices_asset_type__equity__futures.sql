
    
    

with all_values as (

    select
        asset_type as value_field,
        count(*) as n_records

    from `dbt-demo-project-485817`.`dbt_dev`.`stg_yahoo_prices`
    group by asset_type

)

select *
from all_values
where value_field not in (
    'equity','futures'
)


