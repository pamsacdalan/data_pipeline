# Project: Financial Data Aggregation and Analysis Pipeline

Description:
Build a data pipeline using Ruby and Airflow to aggregate and analyze financial data points from multiple
sources. The pipeline should fetch data, process it, and generate meaningful insights. The project will
involve extracting data from various APIs or data providers, performing data transformations and
calculations, and visualizing the results

Requirements:
1. Data Extraction:
- Use Ruby to fetch financial data from multiple sources, such as stock prices, currency exchange rates, or
economic indicators. Consider utilizing APIs or libraries specific to these data sources.

2. Data Processing:
- Implement data processing and transformation tasks in Ruby to clean and structure the raw data. Apply
necessary calculations or aggregations to derive meaningful insights.

3. Data Storage:
- Choose a suitable data storage solution, such as a relational database or a data warehouse, to store the
processed financial data. Ensure data integrity and efficient querying capabilities.

4. Airflow Integration:
- Set up an Airflow DAG to schedule and orchestrate the data pipeline. Define tasks for data extraction,
processing, and storage, ensuring proper dependencies and data flow.

5. Error Handling and Monitoring:
- Implement error handling mechanisms within the pipeline to handle data extraction failures or processing
errors. Configure Airflow to send notifications or alerts in case of pipeline failures.

6. Visualization and Reporting:
- Utilize Ruby libraries or frameworks to create visualizations and reports based on the processed financial
data. Present key insights, trends, or performance metrics in a user-friendly manner.

7. Performance Optimization:
- Optimize the pipeline for performance by considering efficient data processing techniques, caching
mechanisms, and parallel processing where applicable.

8. Security and Data Privacy:
- Ensure the pipeline adheres to security best practices, especially when dealing with sensitive financial
data. Implement appropriate measures to protect data privacy and confidentiality.

Deliverables:
- A functional data pipeline built using Ruby and Airflow that fetches, processes, and stores financial data.
- Visualizations and reports that provide meaningful insights from the processed data.
- Documentation explaining the pipeline's architecture, components, and usage instructions.


#User Manual

Prerequisite:
User's machine must have the following programs installed:
1. Ubuntu CLI
2. Ruby
3. Apache Airflow
4. Ruby on Rails

Gem Installation
1. open ubuntu cli
2. navigate to /dags/ruby_scripts
3. install gem using the code: bundle install
4. navigate to /dashboard
5. install gem using the code: bundle install

To access Dashboard:
1. run server using the code: rails server
2. open web browser and go to localhost:3000

To access Airflow Webserver:
1. open ubuntu cli
2. activate the virtual environment where your airflow is installed
3. run airflow webserver and scheduler