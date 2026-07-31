from datetime import datetime
import os
from airflow import DAG
from airflow.providers.common.sql.operators.sql import SQLExecuteQueryOperator

DAG_FOLDER = os.path.dirname(os.path.realpath(__file__))

SQL_PATH = os.path.abspath(os.path.join(DAG_FOLDER, "..", "sql", "silver"))

with DAG(
    dag_id="insert_bronze_to_silver_pipeline",
    start_date=datetime(2026, 1, 1),
    schedule_interval=None,
    catchup=False,
        template_searchpath=[SQL_PATH], 
) as dag:


    # Merge fact_agreement
    merge_fact_agreement = SQLExecuteQueryOperator(
        task_id="merge_fact_agreement",
        conn_id="postgres_local",
        sql="fact_agreement.sql",
    )
    # Merge fact_installment
    merge_fact_installment = SQLExecuteQueryOperator(
        task_id="merge_fact_installment",
        conn_id="postgres_local",
        sql="fact_installment.sql",
    )
    # Merge dim_customer
    merge_dim_customer = SQLExecuteQueryOperator(
        task_id="merge_dim_customer",
        conn_id="postgres_local",
        sql="dim_customer.sql",
    )
 
    merge_fact_agreement >> merge_fact_installment >> merge_dim_customer
