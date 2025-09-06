from airflow.decorators import dag, task
from datetime import datetime
import random


@dag(
    start_date=datetime(2023,1,1),
    schedule='@daily',
    catchup=False,
    tags=['random_number']
)    
  
def check_random_number():
    @task
    def generate_random_number():
        number = random.randint(1, 100)
        print(f"Generated random number: {number}")   
  

    @task
    def check_even_odd(variable_task_a):
        result = "even" if variable_task_a % 2 == 0 else "odd"
        print(f"The number {variable_task_a} is {result}.")
 
    check_even_odd(generate_random_number())

dag = check_random_number()
 