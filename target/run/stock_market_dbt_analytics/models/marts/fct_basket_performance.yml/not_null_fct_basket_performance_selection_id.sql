
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select selection_id
from `dbt-demo-project-485817`.`dbt_dev`.`fct_basket_performance`
where selection_id is null



  
  
      
    ) dbt_internal_test