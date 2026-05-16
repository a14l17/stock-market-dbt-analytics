
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select asset_type
from `dbt-demo-project-485817`.`dbt_dev`.`fct_basket_performance`
where asset_type is null



  
  
      
    ) dbt_internal_test