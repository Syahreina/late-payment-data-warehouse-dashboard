from datetime import datetime, timedelta
import os

from airflow import DAG
from airflow.operators.python import PythonOperator
from airflow.providers.postgres.hooks.postgres import PostgresHook


CONN_ID = "postgres_local"
TARGET_TABLE = "gold.dq_monitoring"

DAG_FOLDER = os.path.dirname(os.path.realpath(__file__))
SQL_PATH = os.path.abspath(os.path.join(DAG_FOLDER, "..", "sql", "data_quality"))
SQL_FILE = os.path.join(SQL_PATH, "dq_monitoring.sql")


default_args = {
    "owner": "airflow",
    "depends_on_past": False,
    "retries": 1,
    "retry_delay": timedelta(minutes=5),
}


def run_dq_monitoring(**_) -> None:
    # Read the data-quality SQL file
    with open(SQL_FILE, "r") as f:
        dq_sql = f.read()

    conn = PostgresHook(postgres_conn_id=CONN_ID).get_conn()
    try:
        with conn.cursor() as cur:
            # Clear previous results so each run stores one current validation result set
            cur.execute(f"TRUNCATE TABLE {TARGET_TABLE} RESTART IDENTITY")
            # Execute data-quality rules and load the results
            cur.execute(dq_sql)
            # Validate the number of stored results
            cur.execute(f"SELECT COUNT(*) FROM {TARGET_TABLE}")
            n = cur.fetchone()[0]
        conn.commit()
        print(f"[dq_monitoring] OK - {n} data-quality results loaded into {TARGET_TABLE}")
    except Exception:
        conn.rollback()
        raise
    finally:
        conn.close()


with DAG(
    dag_id="gold_dq_monitoring",
    description="Run data-quality checks and load the results into gold.dq_monitoring.",
    default_args=default_args,
    start_date=datetime(2026, 7, 1),
    schedule_interval=None,
    catchup=False,
    tags=[],
) as dag:

    run_gold_dq_monitoring = PythonOperator(
        task_id="run_gold_dq_monitoring",
        python_callable=run_dq_monitoring,
    )