import pandas


data = pandas.read_csv("weather_data.csv")


#Prints the whole table
print(data)

print(type(data)) # dataframe object: your table

#Prints a column
print(data["temp"])

print(type(data["temp"]))  #series object: it is a list

#create data dictionary from csv
data_dict = data.to_dict()
print(data_dict)

#get list from series (column)

temp_list = data["temp"].to_list()
print(temp_list)

#average temperature

avg_temp = data["temp"].mean()
print(avg_temp)

#max value

max_temp = data["temp"].max()
print(max_temp)

#Get data in row of dataframe, How to filter dataframe

print(data[data["day"] == "Monday"])


#get the row by fulter and then get a specific column from it
monday = data[data.day == "Monday"]
print(monday.condition)




