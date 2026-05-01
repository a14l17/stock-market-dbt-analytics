-- macros/rolling_stats.sql
-- Reusable macros for rolling window calculations.

{% macro rolling_avg(column, days) %}
    avg({{ column }}) over (
        partition by symbol
        order by trading_date
        rows between {{ days - 1 }} preceding and current row
    )
{% endmacro %}


{% macro rolling_stddev(column, days) %}
    stddev({{ column }}) over (
        partition by symbol
        order by trading_date
        rows between {{ days - 1 }} preceding and current row
    )
{% endmacro %}


-- % of days in window where value was positive
-- Used for consistency: steady daily gains score higher than volatile spikes
{% macro rolling_pos_pct(column, days) %}
    avg(case when {{ column }} > 0 then 1.0 else 0.0 end) over (
        partition by symbol
        order by trading_date
        rows between {{ days - 1 }} preceding and current row
    )
{% endmacro %}


-- Count of non-null rows in window
-- Used to gate scoring: require minimum data before producing a score
{% macro rolling_row_count(column, days) %}
    count({{ column }}) over (
        partition by symbol
        order by trading_date
        rows between {{ days - 1 }} preceding and current row
    )
{% endmacro %}