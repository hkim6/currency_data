import requests
import boto3
import json
import pandas as pd
import click
from typing import List, Optional
from sql_utils import get_db_connection


@click.group()
def cli():
    pass


def get_api_key() -> str:
    # Get fixer API key from AWS Secrets Manager
    secret_client = boto3.session.Session().client(
        service_name="secretsmanager", region_name="us-east-2"
    )
    secret = secret_client.get_secret_value(SecretId="fixer_api_creds")
    api_key = json.loads(secret.get("SecretString", {})).get("fixer_api_key")

    return api_key


def get_currencies() -> List[str]:
    api_key = get_api_key()
    url = f"https://data.fixer.io/api/symbols?access_key={api_key}"

    response = requests.get(url)
    if response.status_code != 200:
        print(f"Error fetching data: {response.status_code}")
        return []
    data = response.json()
    symbols = data.get("symbols")
    if not symbols:
        print("No symbols found.")
        return []

    return (
        pd.DataFrame.from_dict(symbols, orient="index")
        .reset_index()
        .rename(columns={"index": "currency_symbol", 0: "currency_name"})
    )


def get_currency_data(
    start_date: str = "2022-01-01", end_date: str = "2022-03-01"
) -> Optional[pd.DataFrame]:
    api_key = get_api_key()

    url = f"https://data.fixer.io/api/timeseries?access_key={api_key}"
    querystring = {
        "base": "USD",
        "symbols": "CAD",
        "start_date": start_date,
        "end_date": end_date,
    }
    response = requests.get(url, params=querystring)

    if response.status_code != 200:
        print(f"Error fetching data: {response.status_code}")
        return None

    data = response.json()
    rates = data.get("rates")
    if not rates:
        print("No data found for the given date range.")
        return None

    records = [
        {"rate_date": date, "base_currecy_symbol": "USD", "currency_symbol": currency, "exchange_rate": rate}
        for date, currencies in rates.items()
        for currency, rate in currencies.items()
    ]

    df = pd.DataFrame.from_dict(records, orient="index")

    return df


def get_data_from_csv(file_path: str) -> pd.DataFrame:
    df = pd.read_csv(file_path)
    df.rename(
        columns={
            "currency": "currency_symbol",
            "base_currency": "base_currency_symbol",
            "date": "rate_date",
        },
        inplace=True,
    )
    return df[["currency_symbol", "base_currency_symbol", "rate_date", "exchange_rate"]]


def save_to_postgres(
    df: pd.DataFrame, table_name: str, engine: str = "psycopg2"
) -> None:
    engine = get_db_connection(engine)
    df.to_sql(table_name, engine, if_exists="replace", index=False)
    print(f"Data saved to PostgreSQL table {table_name}")


@cli.command("ingest_symbols")
@click.option(
    "--table_name", default="currency_metadata", help="Table name to save the symbols"
)
def main_symbols(table_name: str = "currency_metadata") -> None:
    # Get the currency symbols from the API
    df = get_currencies()
    if df is not None:
        save_to_postgres(df, table_name, engine="sqlalchemy")
    else:
        print("No data to save.")


@cli.command("ingest_api")
@click.option(
    "--symbols",
    default=["EUR", "GBP", "JPY"],
    help="Currency symbols to fetch data for",
)
@click.option("--start-date", default="2022-01-01", help="Start date for fetching data")
@click.option("--end-date", default="2022-03-01", help="End date for fetching data")
@click.option(
    "--table-name", default="exchange_rates", help="Table name to save the data"
)
def main_api(
    start_date: str = "2022-01-01",
    end_date: str = "2022-03-01",
    table_name: str = "exchange_rates",
) -> None:
    df = get_currency_data(start_date, end_date)
    if df is not None:
        save_to_postgres(df, table_name, engine="sqlalchemy")
    else:
        print("No data to save.")


@cli.command("ingest_csv")
@click.argument("file-path")
@click.option(
    "--table-name", default="exchange_rates", help="Table name to save the data"
)
def main_csv(file_path: str, table_name: str = "exchange_rates") -> None:
    # Get the data from the CSV file
    df = get_data_from_csv(file_path)
    if df is not None:
        save_to_postgres(df, table_name, engine="sqlalchemy")
    else:
        print("No data to save.")


if __name__ == "__main__":
    cli()
