
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select basket_name
from `dbt-demo-project-485817`.`dbt_dev`.`fct_basket_performance`
where basket_name is null



  
  
      
    ) dbt_internal_test