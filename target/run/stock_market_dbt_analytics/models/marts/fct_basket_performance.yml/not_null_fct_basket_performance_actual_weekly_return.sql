
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select actual_weekly_return
from `dbt-demo-project-485817`.`dbt_dev`.`fct_basket_performance`
where actual_weekly_return is null



  
  
      
    ) dbt_internal_test