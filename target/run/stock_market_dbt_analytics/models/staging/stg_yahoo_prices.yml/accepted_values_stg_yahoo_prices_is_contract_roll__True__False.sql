
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    

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



  
  
      
    ) dbt_internal_test