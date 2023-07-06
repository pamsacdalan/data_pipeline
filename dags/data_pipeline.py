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

def connect_to_slack(message, task_name=None, **kwargs):
    """
    Connects to Slack and posts a message to a specified channel using the SlackAPIPostOperator.
    
    """
    channel = '#data_pipeline'
    slack_http_id = 'slack_data_pipeline'
    token = Variable.get('slack_token')

    slack_operator = SlackAPIPostOperator(
        task_id='slack_success_notification_task_{}'.format(task_name),
        http_conn_id=slack_http_id,
        token=token,
        channel=channel,
        text=message,
        dag=dag
    )
    return slack_operator.execute(context=kwargs)

def send_slack_notification(task_name, success=True, **kwargs):
    """
    Sends a Slack notification indicating whether a task was executed successfully or encountered an error.
    
    """
    message = "Task: {} executed successfully".format(task_name) if success else "Task: {} encountered an error".format(task_name)
    connect_to_slack(message=message, task_name=task_name)

def execute_ruby_code(ruby_file, input_data=None, task_name=None):
    """
    Executes a Ruby code file and returns the result or raises an exception if an error occurs.
    
    """
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
    """
    Fetches data from an API using a Ruby script and returns the fetched data.
    
    """
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


# Will check connection to database
def check_conn(**kwargs):
    """
    Checks the connection to a database using a Ruby script.
    
    """
    test_db_path = os.path.join(current_folder, 'ruby_scripts', 'test_db.rb')
    execute_ruby_code(test_db_path, None, task_name='check_db_connection')
    send_slack_notification('check_db_connection', success=True, **kwargs)

check_conn_task = PythonOperator(task_id='check_db_connection', python_callable=check_conn, provide_context=True, dag=dag)


# Will store data to database
intraday_data_path = os.path.join(current_folder, 'ruby_scripts', 'store_intraday.rb')
daily_data_path = os.path.join(current_folder, 'ruby_scripts', 'store_daily.rb')
weekly_data_path = os.path.join(current_folder, 'ruby_scripts', 'store_weekly.rb')
monthly_data_path = os.path.join(current_folder, 'ruby_scripts', 'store_monthly.rb')

store_db_dict = {
				'store_intraday_task':[intraday_data_path, 'store_intraday_to_db'],
				'store_daily_task':[daily_data_path, 'store_daily_to_db'],
				'store_weekly_task':[weekly_data_path, 'store_weekly_to_db'],
				'store_monthly_task':[monthly_data_path, 'store_monthly_to_db']
				}

def store_data_to_db(ruby_script, task_name, **kwargs):
    """
    Stores data to a database using a Ruby script.
    
    """
    fetched_data = kwargs['ti'].xcom_pull(task_ids='fetch_data_from_api')
    execute_ruby_code(ruby_script, fetched_data, task_name=task_name)
    send_slack_notification(task_name, success=True, **kwargs)
    return task_name

for task_name, params in store_db_dict.items():
	task = PythonOperator(
					task_id=task_name,
					python_callable=store_data_to_db,
					op_args=params,
					provide_context=True,
					dag=dag
							)
	store_db_dict[task_name] = task


# Will add new computed columns to Database
intraday_new_col_path = os.path.join(current_folder, 'ruby_scripts', 'add_columns_intraday.rb')
daily_new_col_path = os.path.join(current_folder, 'ruby_scripts', 'add_columns_daily.rb')
weekly_new_col_path = os.path.join(current_folder, 'ruby_scripts', 'add_columns_weekly.rb')
monthly_new_col_path = os.path.join(current_folder, 'ruby_scripts', 'add_columns_monthly.rb')

add_cols_dict = {
				'add_computed_intraday_cols_task':[intraday_new_col_path, 'add_computed_intraday_columns_to_table'],
				'add_computed_daily_cols_task':[daily_new_col_path, 'add_computed_daily_columns_to_table'],
				'add_computed_weekly_cols_task':[weekly_new_col_path, 'add_computed_weekly_columns_to_table'],
				'add_computed_monthly_cols_task':[monthly_new_col_path, 'add_computed_monthly_columns_to_table']
				}

def add_computed_columns_to_table(ruby_script, task_name, **kwargs):
    """
    Adds new computed columns to a database table using a Ruby script.
    
    """
    execute_ruby_code(ruby_script, task_name=task_name)
    send_slack_notification(task_name, success=True, **kwargs)
    return task_name

for task_name, params in add_cols_dict.items():
	task = PythonOperator(
					task_id=task_name,
					python_callable=add_computed_columns_to_table,
					op_args=params,
					provide_context=True,
					dag=dag
							)
	add_cols_dict[task_name] = task

# Will send notification to Slack App
def send_success_notification(task_name, **kwargs):
    """
    Sends a success notification to a Slack App.
    
    """
    sched = task_name.split('_')[0]
    message = "{} data stored successfully".format(sched.title())
    connect_to_slack(message=message, task_name=task_name)


send_notif_dict = {}
task_id_list = ['intraday_success_notification', 'daily_success_notification', 'weekly_success_notification', 'monthly_success_notification']
for task_id in task_id_list:
    task = PythonOperator(
        task_id=task_id,
        python_callable=send_success_notification,
        op_args=[task_id],
        dag=dag
    )
    send_notif_dict[task_id] = task


fetch_data_task >> check_conn_task

check_conn_task >> store_db_dict['store_intraday_task'] >> add_cols_dict['add_computed_intraday_cols_task'] >> send_notif_dict['intraday_success_notification']

check_conn_task >> store_db_dict['store_daily_task'] >> add_cols_dict['add_computed_daily_cols_task'] >> send_notif_dict['daily_success_notification']

check_conn_task >> store_db_dict['store_weekly_task'] >> add_cols_dict['add_computed_weekly_cols_task'] >> send_notif_dict['weekly_success_notification']

check_conn_task >> store_db_dict['store_monthly_task'] >> add_cols_dict['add_computed_monthly_cols_task'] >> send_notif_dict['monthly_success_notification']
