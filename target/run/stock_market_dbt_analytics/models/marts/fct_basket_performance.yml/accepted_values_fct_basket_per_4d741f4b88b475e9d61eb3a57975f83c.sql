
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    

with all_values as (

    select
        asset_type as value_field,
        count(*) as n_records

    from `dbt-demo-project-485817`.`dbt_dev`.`fct_basket_performance`
    group by asset_type

)

select *
from all_values
where value_field not in (
    'equity','futures'
)



  
  
      
    ) dbt_internal_test