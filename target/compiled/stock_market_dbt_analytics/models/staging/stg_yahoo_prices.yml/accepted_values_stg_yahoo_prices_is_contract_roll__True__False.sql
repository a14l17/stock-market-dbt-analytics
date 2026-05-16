
    
    

with all_values as (

    select
        is_contract_roll as value_field,
        count(*) as n_records

    from `dbt-demo-project-485817`.`dbt_dev`.`stg_yahoo_prices`
    group by is_contract_roll

)

select *
from all_values
where value_field not in (
    'True','False'
)


