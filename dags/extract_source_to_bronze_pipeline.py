import io
from datetime import datetime

from airflow import DAG
from airflow.operators.python import PythonOperator
from airflow.providers.postgres.hooks.postgres import PostgresHook

SOURCE_CONN_ID = "supabase_source"
TARGET_CONN_ID = "postgres_local"
TARGET_SCHEMA = "bronze"
TABLES = ["cust", "agrmnt", "inst_schdl", "ref_office"]
COPY_OPTS = "WITH (FORMAT csv, NULL '')"
TZ = "UTC"


def extract_load_table(table: str, **_) -> None:
    src = PostgresHook(postgres_conn_id=SOURCE_CONN_ID).get_conn()
    tgt = PostgresHook(postgres_conn_id=TARGET_CONN_ID).get_conn()
    buf = io.StringIO()
    try:
        with src.cursor() as scur:
            scur.execute(f"SET TIME ZONE '{TZ}'")
            scur.copy_expert(f"COPY (SELECT * FROM public.{table}) TO STDOUT {COPY_OPTS}", buf)
        buf.seek(0)

        with tgt.cursor() as tcur:
            tcur.execute(f"SET TIME ZONE '{TZ}'")
            tcur.execute(f"TRUNCATE TABLE {TARGET_SCHEMA}.{table}")
            tcur.copy_expert(f"COPY {TARGET_SCHEMA}.{table} FROM STDIN {COPY_OPTS}", buf)
        tgt.commit()

        with src.cursor() as scur, tgt.cursor() as tcur:
            scur.execute(f"SELECT count(*) FROM public.{table}")
            src_n = scur.fetchone()[0]
            tcur.execute(f"SELECT count(*) FROM {TARGET_SCHEMA}.{table}")
            tgt_n = tcur.fetchone()[0]
        if src_n != tgt_n:
            raise ValueError(f"[{table}] count mismatch: source={src_n} bronze={tgt_n}")
        print(f"[{table}] OK - {tgt_n} records loaded into {TARGET_SCHEMA}.{table}")
    except Exception:
        tgt.rollback()
        raise
    finally:
        buf.close()
        src.close()
        tgt.close()


with DAG(
    dag_id="extract_source_to_bronze_pipeline",
    start_date=datetime(2026, 1, 1),
    schedule_interval=None,
    catchup=False,
) as dag:

    for tbl in TABLES:
        PythonOperator(
            task_id=f"extract_{tbl}",
            python_callable=extract_load_table,
            op_kwargs={"table": tbl},
        )
