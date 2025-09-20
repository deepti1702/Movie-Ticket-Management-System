import pyodbc
import pandas as pd

# Replace with your actual connection details
conn_str = "DRIVER={ODBC Driver 17 for SQL Server};SERVER=xxx;DATABASE=xxx;UID=xxx;PWD=xxx"


# Create a connection object
def get_connection():
    return pyodbc.connect(conn_str)

# Function to run SELECT queries and return DataFrame
def run_query(query, params=None):
    conn = get_connection()
    df = pd.read_sql(query, conn, params=params)
    conn.close()
    return df

# Function to execute INSERT/UPDATE/DELETE/EXEC queries
def execute_query(query, params=None):
    conn = get_connection()
    cursor = conn.cursor()
    cursor.execute(query, params or [])
    conn.commit()
    conn.close()