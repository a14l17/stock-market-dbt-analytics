

  create or replace view `dbt-demo-project-485817`.`dbt_dev`.`int_daily_returns`
  OPTIONS()
  as -- CONTRACT ROLL EXCLUSION:
-- Futures roll dates are excluded here. A 3% jump because a contract
-- expired is not a real return — including it would corrupt rolling stats.

with prices as (

    select
          symbol
        , asset_type
        , trading_date
        , close_price
        , is_contract_roll
    from `dbt-demo-project-485817`.`dbt_dev`.`stg_yahoo_prices`

),

with_prior_close as (

    select
          *
        , lag(close_price) over (
            partition by symbol
            order by trading_date
          )                       as prior_close
        , lag(trading_date) over (
            partition by symbol
            order by trading_date
          )                       as prior_trading_date

    from prices

),

returns as (

    select
          symbol
        , asset_type
        , trading_date
        , close_price
        , prior_close
        , prior_trading_date

        -- Simple return: used in scoring output and final table (easy to interpret)
        , round(
            (close_price - prior_close) / nullif(prior_close, 0),
            6
          )                       as daily_return

        -- Log return: better for rolling stats (time-additive, more normally distributed)
        , round(
            ln(close_price / nullif(prior_close, 0)),
            6
          )                       as log_return

        , is_contract_roll

    from with_prior_close
    where prior_close is not null
      and is_contract_roll = false

)

select * from returns;

