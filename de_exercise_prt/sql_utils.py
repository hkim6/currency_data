import boto3
import json
import traceback
import psycopg2
import click
import sqlalchemy
import csv
from tabulate import tabulate


DDL_KEYWORDS = ("CREATE", "ALTER", "DROP", "TRUNCATE", "RENAME")


def check_ddl(query: str) -> bool:
    """
    Check if the SQL statement is a DDL command.
    """
    first_word = query.strip().split()[0].upper()
    return first_word in DDL_KEYWORDS


def get_db_connection(engine: str = "psycopg2") -> dict:
    secret_client = boto3.session.Session().client(
        service_name="secretsmanager", region_name="us-east-2"
    )
    secret = secret_client.get_secret_value(SecretId="currency_db_creds")
    secrets = json.loads(secret.get("SecretString", {}))
    db_user = secrets.get("username")
    db_pass = secrets.get("password")
    db_host = secrets.get("host")
    db_port = secrets.get("port")
    db_name = secrets.get("dbname")

    if engine == "sqlalchemy":
        engine = sqlalchemy.create_engine(
            f"postgresql+psycopg2://{db_user}:{db_pass}@{db_host}:{db_port}/{db_name}",
            connect_args={"sslmode": "require"},
        )
    else:
        engine = psycopg2.connect(
            dbname=db_name,
            user=db_user,
            password=db_pass,
            host=db_host,
            port=db_port,
            sslmode="require",
        )

    return engine


@click.group()
def cli():
    pass


@cli.command("run-query")
@click.argument("query")
def run_query(query: str) -> None:
    engine = get_db_connection()
    with engine.connect() as connection:
        result = connection.execute(query)
        for row in result:
            print(row)


@cli.command("run-query-from-file")
@click.argument("file")
@click.option("--show-output", is_flag=True, help="Show output of the query")
@click.option(
    "--export-csv",
    is_flag=True,
    help="Export the output to a CSV file",
)
def run_query_from_file(
    file: str, show_output: bool = False, export_csv: bool = False
) -> None:
    conn = get_db_connection()
    cur = conn.cursor()
    try:
        with open(file) as f:
            query = f.read()
            query = query.split(";")
            no_queries = len(query) - 1
            for i, q in enumerate(query):
                if q.strip():
                    cur.execute(q + ";")
                    columns = [desc[0] for desc in cur.description]
                    if check_ddl(q):
                        conn.commit()
                    if show_output:
                        results = cur.fetchall()
                        print(tabulate(results, headers=columns, tablefmt="grid"))
                    # only export the reults of last query
                    if export_csv and i == no_queries - 1:
                        with open("output.csv", "w", newline="") as f:
                            writer = csv.writer(f)
                            writer.writerow(columns)
                            writer.writerows(results)
        print(f"Query executed successfully.")
    except (Exception, psycopg2.DatabaseError) as e:
        print(f"Error executing query from file: {e}")
        print(traceback.format_exc())
    finally:
        if cur:
            cur.close()


if __name__ == "__main__":
    cli()
