
from airflow import DAG
from airflow.models import Variable
from airflow.operators.python_operator import PythonOperator
from datetime import datetime, timedelta
import subprocess
from airflow.operators.slack_operator import SlackAPIPostOperator
import os

default_args = {
    'owner': 'airflowerism',
    'start_date': datetime(2023, 6, 1),
}

dag = DAG('data_pipeline',
          default_args=default_args,
          catchup=False)

current_folder = os.path.dirname(__file__)

def send_slack_notification(task_name, success=True, **kwargs):
    token = Variable.get('slack_token')
    channel = '#data_pipeline'
    message = "Task: {} executed successfully".format(task_name) if success else "Task: {} encountered an error".format(task_name)
    slack_http_id = 'slack_data_pipeline'

    slack_operator = SlackAPIPostOperator(
        task_id='slack_notification_task',
        http_conn_id=slack_http_id,
        token=token,
        channel=channel,
        text=message,
        dag=dag
    )
    return slack_operator.execute(context=kwargs)

def execute_ruby_code(ruby_file, input_data=None, task_name=None):
    try:
        if input_data is None:
            process = subprocess.Popen(['ruby', ruby_file], stdout=subprocess.PIPE, stderr=subprocess.PIPE)
            stdout, stderr = process.communicate()
        else:
            process = subprocess.Popen(['ruby', ruby_file], stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
            stdout, stderr = process.communicate(input=input_data.encode('utf-8'))

        if process.returncode == 0:
            result = stdout.decode('utf-8')
            return result
        else:
            error_message = stderr.decode('utf-8')
            raise Exception("Error executing task {}: {}".format(task_name, error_message))
    except Exception as e:
        send_slack_notification(task_name, success=False)
        raise e

def fetch_data_from_api(**kwargs):
    fetch_data_path = os.path.join(current_folder, 'ruby_scripts', 'fetch_data.rb')
    fetched_data = execute_ruby_code(ruby_file=fetch_data_path, input_data=None, task_name='fetch_data_from_api')
    send_slack_notification('fetch_data_from_api', success=True, **kwargs)
    return fetched_data

fetch_data_task = PythonOperator(
    task_id='fetch_data_from_api',
    python_callable=fetch_data_from_api,
    provide_context=True,
    dag=dag
)

def check_conn(**kwargs):
    test_db_path = os.path.join(current_folder, 'ruby_scripts', 'test_db.rb')
    execute_ruby_code(test_db_path, None, task_name='check_db_connection')
    send_slack_notification('check_db_connection', success=True, **kwargs)

check_conn_task = PythonOperator(task_id='check_db_connection', python_callable=check_conn, provide_context=True, dag=dag)

def store_data_to_db(ruby_script, task_name, **kwargs):
    fetched_data = kwargs['ti'].xcom_pull(task_ids='fetch_data_from_api')
    execute_ruby_code(ruby_script, fetched_data, task_name=task_name)
    send_slack_notification(task_name, success=True, **kwargs)
    return task_name

intraday_data_path = os.path.join(current_folder, 'ruby_scripts', 'store_intraday.rb')
store_intraday_task = PythonOperator(
    task_id='store_intraday_task',
    python_callable=store_data_to_db,
    op_args=[intraday_data_path, 'store_intraday_to_db'],
    provide_context=True,
    dag=dag
)

daily_data_path = os.path.join(current_folder, 'ruby_scripts', 'store_daily.rb')
store_daily_task = PythonOperator(
    task_id='store_daily_task',
    python_callable=store_data_to_db,
    op_args=[daily_data_path, 'store_daily_to_db'],
    provide_context=True,
    dag=dag
)

weekly_data_path = os.path.join(current_folder, 'ruby_scripts', 'store_weekly.rb')
store_weekly_task = PythonOperator(
    task_id='store_weekly_task',
    python_callable=store_data_to_db,
    op_args=[weekly_data_path, 'store_weekly_to_db'],
    provide_context=True,
    dag=dag
)

monthly_data_path = os.path.join(current_folder, 'ruby_scripts', 'store_monthly.rb')
store_monthly_task = PythonOperator(
    task_id='store_monthly_task',
    python_callable=store_data_to_db,
    op_args=[monthly_data_path, 'store_monthly_to_db'],
    provide_context=True,
    dag=dag
)

def send_success_notification(task_name, **kwargs):
    token = Variable.get('slack_token')
    channel = '#data_pipeline'
    message = "{} task has been successfully executed".format(task_name)
    slack_http_id = 'slack_data_pipeline'

    slack_operator = SlackAPIPostOperator(
        task_id='slack_success_notification_task',
        http_conn_id=slack_http_id,
        token=token,
        channel=channel,
        text=message,
        dag=dag
    )
    return slack_operator.execute(context=kwargs)

send_success_notification_task = PythonOperator(
    task_id='send_success_notification',
    python_callable=send_success_notification,
    op_args=['send_success_notification'],
    provide_context=True,
    dag=dag
)
"""
fetch_data_task >> check_conn_task

check_conn_task >> store_intraday_task
check_conn_task >> store_daily_task
check_conn_task >> store_weekly_task
check_conn_task >> store_monthly_task

store_intraday_task >> send_success_notification_task
store_daily_task >> send_success_notification_task
store_weekly_task >> send_success_notification_task
store_monthly_task >> send_success_notification_task
"""


fetch_data_task >> check_conn_task
check_conn_task >> [
        store_intraday_task,
        store_daily_task,
        store_weekly_task,
        store_monthly_task
]

[ 
store_intraday_task,
store_daily_task,
store_weekly_task,
store_monthly_task
] >> send_success_notification_task
