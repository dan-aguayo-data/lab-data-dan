# built-in
import os
import csv
import glob
import pathlib

# installed
from jinja2 import Template

# Environment
SOURCE = "ORACLE"  # MSCM, CRM
ENVIRONMENT = "PROD"  # PROD, DEV
TABLE_DDL_FILENAME = "TABLE_DDL.csv"
TABLE_PK_FILENAME = "TABLE_PK.csv"
BASE_PATH = "ORACLE/"  # base path for the filename path in the dbt model


# Helpers
def load_csv(csv_location: str):
    # helper function to load csv's into dictionaries
    with open(csv_location, "r") as csv_file:
        csv_reader = csv.DictReader(csv_file, delimiter=",", quotechar='"')
        lines = [line for line in csv_reader]
        return lines


def map_column(column_name: str, data_type: str):
    """
    A helper function to map columns to snowflake

    Args:
        column_name (str): The name of the column for verbose errors
        data_type (str): The name input data type

    """
    data_type = data_type.lower()
    if data_type in ["bigint", "integer", "double", "time"]:
        return data_type
    elif data_type.startswith("varchar") or data_type.startswith("char") or data_type.startswith("long_varchar"):
        return "string"
    elif data_type == "clob":
        return "string"
    elif data_type.startswith("number"):
        return "bigint"
    elif data_type.startswith("float"):
        return "float"
    elif data_type.startswith("date"):
        return "DATE"
    elif data_type.startswith("timestamp"):
        return "TIMESTAMP_NTZ"
    elif data_type.startswith("blob"):
        return "BINARY"
    else:
        raise ValueError(f"column: {column_name} with data type {data_type} not handled by map_column function")


def get_primary_keys(table_name, table_data):
    """Returns the primary keys from the table name
            Note: if the table name ends with _A the function will attempt to remove the suffix
            and get the keys from the base table.
    Args:
        table_name (str): the table name
        table_data (dict): the data data in the format specified above

    Returns:
        list: the primary keys for the table
    """
    if table_data[table_name]["primary_keys"] == [] and table_name.endswith("_A"):
        if table_name[:-2] in table_data:
            return table_data[table_name[:-2]]["primary_keys"]
    return table_data[table_name]["primary_keys"]


def incremental_key_merge(table_name):
    """if a table name ends with _A we do an incremental key merge on the raw columns"""
    return table_name


def main():
    # build up the table data structure
    table_data = {}
    file_path = pathlib.Path(__file__).parent.resolve()
    for row in load_csv(f"{file_path}/source_csv/{SOURCE}/{TABLE_DDL_FILENAME}"):
        if not row["TABLE_NAME"] in table_data:
            table_data[row["TABLE_NAME"]] = {"columns": [], "primary_keys": []}
        table_data[row["TABLE_NAME"]]["columns"].append(
            {
                "name": row["COLUMN_NAME"],
                "id": row["COLUMN_ID"],
                "nullable": row["NULLABLE"],
                "data_type": row["DATA_TYPE"],
            }
        )
    print(f'hello: {table_data}')
    for row in load_csv(f"{file_path}/source_csv/{SOURCE}/{TABLE_PK_FILENAME}"):
        table_data[row["TABLE_NAME"]]["primary_keys"].append(row["PRIMARY_KEY"])

    # Iterate through each Jinja2 template
    for template in glob.glob(f"{file_path}/templates/*"):
        template_name = os.path.basename(template)

        # output files to the /out folder and create the appropriate directories
        output_path = f"{file_path}/out/{template_name.replace('.sql', '')}/"
        pathlib.Path(output_path).mkdir(parents=True, exist_ok=True)

        # Iterate through the tables for the given template
        for table_name, table_info in table_data.items():
            # Naming conventions for output file
            file_naming_conventions = {
                "LANDING_TEMPLATE.sql": f"LANDING_ORACLE_{table_name}.sql",
                "RAW_TEMPLATE.sql": f"ORACLE_{table_name}.sql",
                "SOURCE_TEMPLATE.yml": "source_new.yml",
            }
            # Render the jinja tempalte and create the file
            with open(template, "r") as temp, open(
                f"{output_path}/{file_naming_conventions[template_name]}", "w+"
            ) as out:
                out.write(
                    Template(temp.read()).render(
                        SOURCE=SOURCE,
                        ENVIRONMENT=ENVIRONMENT,
                        BASE_PATH=BASE_PATH,
                        TABLE_NAME=table_name,
                        TABLE_INFO=table_info,
                        MAP_COLUMN=map_column,
                        TABLE_DATA=table_data,
                        PRIMARY_KEYS=get_primary_keys(table_name, table_data),
                        INCREMENTAL_KEY_MERGE=incremental_key_merge(table_name),
                        LEN=len,
                    )
                )


if __name__ == "__main__":
    main()
