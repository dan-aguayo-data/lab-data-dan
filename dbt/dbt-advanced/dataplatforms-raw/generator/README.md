# Inputs:

    * the table DDL csv with the following columns OWNER,TABLE_NAME,COLUMN_ID,COLUMN_NAME,DATA_TYPE,NULLABLE
    * the table primary key csv with the following columns OWNER,TABLE_NAME,PRIMARY_KEY

# Folder Structure:

```
    ├── generator.py             - the python script
    ├── requirements.txt         - the python requirements
    ├── source_csv/
    │   ├── <source 1>
    │   └── <source 2>
    │       ├── TABLE_PK.csv     - the table DDL file
    │       └── TABLE_DDL.csv    - the table primary key file
    ├── templates - the jinja templates
    │   ├── template_1.sql
    │   └── template_2.sql
    ├── out
    │   ├── <template_1> 
    │   └── <template_2> 
    │       ├── output_1.sql     - the output files
    └──     ...

```

# Approach:

    1.
        Build out the following data structure in the variable table_data'
        ```
        {
            "<table_name>": {
                "columns": [
                    {

                        "id": <column_id>,
                        "name": <column_name>,
                        "nullable": <nullable>,
                        "data_type": <data_type
                    }
                    ...
                ]
                "primary_keys": [
                    "key_name"
                    ...
                ]
            }
            ...
        }
        ```
    2. loop through each template and render the file for every table using Jinja templates
            * attempts to map the column with the function map_column (only supporting oracle to snowflake)
                the function will need updating over time and may need to handle edge cases.
            * if a table name ends with _A there will be some dynamic handling including creating an incremental
                merge file with the primary keys and also attempt to get the keys fom the base table (without _A).

# How to run:
    1. in the generator folder install requirements (pip3 install -r requirements.txt)
    2. python3 generator.py - the script should take a few seconds and output the files to out/
        note: you can tweak enviroment variables such as prod/dev environment, input files and source