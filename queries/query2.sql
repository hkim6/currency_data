-- This query calculates the percent change across each week in the year and averages this change across the years for a specific currency.
-- The resulting table ranks which weeks most consistent see an increase in exchange rate and the average percent change that week.
with currency_dates as (
    select 
        base_currency_symbol,
        currency_symbol,
        rate_date,
        EXTRACT(YEAR from rate_date::timestamp) as yr,
        EXTRACT(WEEK from rate_date::timestamp) as wk,
        exchange_rate
    from exchange_rates
),
-- create a new column that specified the week of each year by row_number
week_rows as (
    select 
        *,
        row_number() over (partition by base_currency_symbol, currency_symbol, wk, yr order by rate_date asc) as rn
    from currency_dates
),
-- get the first and last exchange rate for each week
week_metrics as (
    select 
        *,
        max(rn) over (partition by base_currency_symbol, currency_symbol, wk, yr) as max_rn,
        min(rn) over (partition by base_currency_symbol, currency_symbol, wk, yr) as min_rn
    from week_rows
),
-- isolate only to the first and last exchange rate for each week
mins_maxes as (
    select
        *
    from week_metrics
    where rn = max_rn
    or rn = min_rn
),
-- align the first and last exchange rate for each week by creating a new column alongside the max rate that is the min rate
previous_rates as (
    select 
        *,
        lag(exchange_rate) over (partition by base_currency_symbol, currency_symbol, wk, yr order by rate_date asc) as starting_rate
    from mins_maxes
    order by rate_date asc
),
-- create a new column that calculates the percent change for each week
percent_changes as (
    select 
        *,
        ((exchange_rate - starting_rate) / starting_rate) * 100 as percent_change
    from previous_rates
    where starting_rate is not null
    and rate_date > '2022-01-01'
),
-- create a new column that specifies the average percent change for each week across years
avg_percent_changes as (
    select 
        currency_symbol,
        wk,
        avg(percent_change) as avg_percent_change
    from percent_changes
    group by currency_symbol, wk
),
-- create a CTE that counts the number of weeks with a positive percent change for each week
num_pos_weeks as (
    select 
        currency_symbol,
        wk,
        sum(case when percent_change >= 0 then 1 else 0 end) as pos_count
    from percent_changes
    group by currency_symbol, wk
),
-- create a CTE that counts the number of weeks with a negative percent change for each week
num_neg_weeks as (
    select 
        currency_symbol,
        wk,
        sum(case when percent_change < 0 then 1 else 0 end) as neg_count
    from percent_changes
    group by currency_symbol, wk
)
select 
    avg.currency_symbol, 
    avg.wk, 
    avg_percent_change,
    pos_count,
    neg_count
from avg_percent_changes avg
join num_pos_weeks pos on avg.currency_symbol = pos.currency_symbol and avg.wk = pos.wk
join num_neg_weeks neg on avg.currency_symbol = neg.currency_symbol and avg.wk = neg.wk
where avg.currency_symbol = 'USD'
order by wk asc;