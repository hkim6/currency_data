-- This query finds which currency is the biggest winner and loser each month (most gain and most loss with respect to EUR)
-- extract year and month from the rate_date column
with previous_rates as (
    select 
        base_currency_symbol,
        currency_symbol,
        rate_date, 
        exchange_rate,
        EXTRACT(YEAR from rate_date::timestamp) as yr,
        EXTRACT(MONTH from rate_date::timestamp) as mth
    from exchange_rates
    where rate_date > '2025-01-01'
    order by rate_date asc
),
-- create a new column that specifies the first and last exchange rate for each month (done more easily than previous query)
previous_rates_rows as (
    select distinct
        base_currency_symbol,
        currency_symbol,
        mth,
        yr,
        first_value(exchange_rate) over (partition by currency_symbol, mth, yr order by rate_date asc) as starting_rate,
        first_value(exchange_rate) over (partition by currency_symbol, mth, yr order by rate_date desc) as ending_rate
    from previous_rates
),
-- create a new column that calculates the percent change for each month
percent_changes as (
    select 
        *,
        ((ending_rate - starting_rate) / starting_rate) * 100 as percent_change
    from previous_rates_rows
    where starting_rate is not null
),
-- Ranks the percent changes in descending order for winners and ascending order for losers
winners as (
    select 
        *,
        rank() over (partition by mth, yr order by percent_change desc) as rank
    from percent_changes
),
losers as (
    select 
        *,
        rank() over (partition by mth, yr order by percent_change asc) as rank
    from percent_changes
)
select 
    w.mth,
    w.yr,
    w.currency_symbol as winnder_symbol,
    w.percent_change as winner_percent_change,
    l.currency_symbol as loser_symbol,
    l.percent_change as loser_percent_change
from currency_metadata c
join winners w
on c.currency_symbol = w.currency_symbol
join losers l 
on w.mth = l.mth and w.yr = l.yr
where w.rank = 1
and l.rank = 1;