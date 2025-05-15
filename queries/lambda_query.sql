-- Create a new column with the previous day's exchange rate
with previous_rates as (
    select 
        base_currency_symbol,
        currency_symbol,
        rate_date, 
        exchange_rate, 
        lag(exchange_rate) over (partition by currency_symbol order by rate_date) as previous_rate
    from exchange_rates
    order by rate_date asc
),
-- Create a new column that specifies whether the exchange rate has increased or not from the previous day
-- Using the new column from the previous CTE
increases as (
    select 
        *, 
        CASE 
            WHEN exchange_rate > previous_rate THEN 1
            ELSE 0
        END as rate_change
    from previous_rates
    where rate_date::timestamp > CURRENT_TIMESTAMP - interval '1 day'
),
-- Create a new column that contains a running sum that incremennts when the exchange_rate didn't change
previous_changes as (
    select 
        base_currency_symbol,
        currency_symbol,
        exchange_rate,
        rate_date, 
        rate_change,
        sum(case when rate_change = 0 then 1 else 0 end) over (order by rate_date) as previous_change
    from increases
),
-- Partition by the sum column to get windows on the streaks and filter out non positive changes
-- Use row_number() to get the streak number
streaks as (
    select 
        *,
        row_number() over (partition by previous_change order by rate_date) as streak
    from previous_changes
    where rate_change = 1
),
-- Get the max streak and max and min exchange rate for each streak for each window that will be used to calculate the averages
-- Can just get max and min exchange rate for each streak since these are streaks of positive changes
streaks_metrics as (
    select 
        *,
        max(streak) over (partition by previous_change) as max_streak,
        max(exchange_rate) over (partition by previous_change) as max_rate,
        min(exchange_rate) over (partition by previous_change) as min_rate
    from streaks
    where streak > 1
),
streaks_avgs as (
    select 
        currency_symbol, 
        avg(max_streak) as avg_cons_pos_days, 
        avg((max_rate-min_rate/min_rate)*100) as avg_cons_perc_change,
        rank() over (order by avg(max_streak)  desc) as avg_cons_pos_days_rank,
        rank() over (order by avg((max_rate-min_rate/min_rate)*100) desc) as avg_cons_perc_change_rank
    from streaks_metrics
    group by base_currency_symbol, currency_symbol
)
select * from streaks_avgs
where avg_cons_pos_days_rank < 6 
or avg_cons_perc_change_rank < 6
order by avg_cons_pos_days_rank, avg_cons_perc_change_rank asc;
