
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select prediction_error
from `dbt-demo-project-485817`.`dbt_dev`.`fct_basket_performance`
where prediction_error is null



  
  
      
    ) dbt_internal_test