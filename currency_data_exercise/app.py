import boto3
import csv
import traceback
import psycopg2
from sql_utils import get_db_connection, check_ddl
import io
from datetime import datetime


def lambda_handler(event, context):
    conn = get_db_connection()
    cur = conn.cursor()
    try:
        with open("lambda_query.sql") as f:
            query = f.read()
            query = query.split(";")
            for i, q in enumerate(query):
                if q.strip():
                    cur.execute(q + ";")
                    columns = [desc[0] for desc in cur.description]
                    if check_ddl(q):
                        conn.commit()
                    results = cur.fetchall()

                    csv_buffer = io.StringIO()
                    writer = csv.writer(csv_buffer)
                    writer.writerow(columns)
                    writer.writerows(results)
        print(f"Query executed successfully.")
    except (Exception, psycopg2.DatabaseError) as e:
        print(f"Error executing query from file: {e}")
        print(traceback.format_exc())
        return {"statusCode": 500, "body": "Error executing query"}
    finally:
        if cur:
            cur.close()
    s3 = boto3.client("s3", region_name="us-east-2")
    bucket_name = f"the-bucket-currency-data"
    cur_time = datetime.now().isoformat()

    s3.put_object(
        Bucket=bucket_name,
        Key=f"{cur_time.split('T')[0]}.csv",
        Body=csv_buffer.getvalue(),
    )
    return {"statusCode": 200, "body": "Done"}
