import subprocess
import json

def execute_ruby_code(ruby_file, input_data=None):
    if input_data is None:
        process = subprocess.Popen(['ruby', ruby_file], stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    else:
        process = subprocess.Popen(['ruby', ruby_file], stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        process.communicate(input=input_data.encode('utf-8'))

    stdout, stderr = process.communicate()

    if process.returncode == 0:
        result = stdout.decode('utf-8')
        return result
    else:
        error_message = stderr.decode('utf-8')
        raise Exception('Error executing Ruby code: ' + error_message)

def fetch_data_from_api():
    # Write the Ruby code to a separate file
    result = execute_ruby_code('fetch_data.rb', None)
    # parsed_result = json.loads(result)
    return result
    
def store_data_to_db():
    # Get data to store in the database
    data = fetch_data_from_api()

    # Pass the data to the Ruby script using execute_ruby_code
    execute_ruby_code('store_data.rb', data)
    # parsed_result = json.loads(result)
    print("INSERT SUCCESS")

store_data_to_db()

