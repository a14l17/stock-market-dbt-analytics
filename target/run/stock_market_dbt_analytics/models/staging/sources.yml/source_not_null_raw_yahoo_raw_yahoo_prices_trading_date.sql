
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select trading_date
from `dbt-demo-project-485817`.`raw_yahoo`.`raw_yahoo_prices`
where trading_date is null



  
  
      
    ) dbt_internal_test