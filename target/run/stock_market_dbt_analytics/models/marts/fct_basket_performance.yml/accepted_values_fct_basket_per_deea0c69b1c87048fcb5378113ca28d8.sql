
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    

with all_values as (

    select
        direction_correct as value_field,
        count(*) as n_records

    from `dbt-demo-project-485817`.`dbt_dev`.`fct_basket_performance`
    group by direction_correct

)

select *
from all_values
where value_field not in (
    'True','False'
)



  
  
      
    ) dbt_internal_test