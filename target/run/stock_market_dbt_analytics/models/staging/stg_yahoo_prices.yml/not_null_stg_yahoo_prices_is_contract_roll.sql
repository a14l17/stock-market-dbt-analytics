
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select is_contract_roll
from `dbt-demo-project-485817`.`dbt_dev`.`stg_yahoo_prices`
where is_contract_roll is null



  
  
      
    ) dbt_internal_test