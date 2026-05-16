
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select close_price
from `dbt-demo-project-485817`.`dbt_dev`.`stg_yahoo_prices`
where close_price is null



  
  
      
    ) dbt_internal_test