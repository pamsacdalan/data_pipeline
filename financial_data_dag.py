#transfer code to WSL dags folder: cp financial_data_dag.py /home/bvillamil/airflow/dags



from datetime import datetime, timedelta
from airflow import DAG
from airflow.operators.bash_operator import BashOperator
from airflow.operators.python_operator import PythonOperator
import requests

default_args = {
    'owner': 'bapvillamil',
    'start_date': datetime(2023, 6, 21),
#    'retries': 3,
#    'retry_delay': timedelta(minutes=5)
}

dag = DAG('FinancialDataPipeline_DAG', 
          default_args=default_args, 
          schedule_interval='0 0 * * *')



def send_slack_message(message):
    webhook_url = "https://hooks.slack.com/services/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"
    payload = {'text': message}
    response = requests.post(webhook_url, json=payload)
    if response.status_code != 200:
        raise ValueError('Error sending Slack message: {}'.format(response.text))


def create_slack_message(**context):
            message = 'Your inventory is running low! Please restocks immediately.'
            send_slack_message(message)

slack_task = PythonOperator(
    task_id='create_slack_message',
    python_callable=create_slack_message,
    provide_context=True,
    dag=dag
)

fetch_data_task = BashOperator(
    task_id='fetch_data',
    bash_command='ruby /mnt/c/Users/BVILLAMIL/Desktop/rails/financial_data_pipeline/data_extraction.rb',
    dag=dag
)

fetch_data_task
slack_task