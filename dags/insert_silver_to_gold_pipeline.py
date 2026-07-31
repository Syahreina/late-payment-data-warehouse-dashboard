from datetime import datetime
import os

from airflow import DAG
from airflow.providers.common.sql.operators.sql import SQLExecuteQueryOperator


DAG_FOLDER = os.path.dirname(os.path.realpath(__file__))
SQL_PATH = os.path.abspath(os.path.join(DAG_FOLDER, "..", "sql", "gold"))


with DAG(
    dag_id="insert_silver_to_gold_pipeline",
    start_date=datetime(2026, 1, 1),
    schedule_interval=None,
    catchup=False,
    template_searchpath=[SQL_PATH],
) as dag:

    load_dm_latecalculation = SQLExecuteQueryOperator(
        task_id="load_dm_latecalculation",
        conn_id="postgres_local",
        sql="dm_latecalculation.sql",
    )

