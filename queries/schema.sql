CREATE TABLE IF NOT EXISTS currency_metadata (
    currecy_symbol VARCHAR(3) NOT NULL UNIQUE,
    currency_name VARCHAR(200) NOT NULL UNIQUE
);

CREATE TABLE IF NOT EXISTS exchange_rates (
    base_currecy_symbol VARCHAR(3) NOT NULL,
    currency_symbol VARCHAR(3) NOT NULL,
    rate_date DATE NOT NULL UNIQUE,
    exchange_rate REAL NOT NULL
);