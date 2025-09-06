import csv

#print data
with open("weather_data.csv") as data_fie:
    data = csv.reader(data_fie)
    print(data)
    for row in data:
        print(row)

#get temperatures
with open("weather_data.csv") as data_fie:
    data = csv.reader(data_fie)
    temperatures = []
    print(data)
    for row in data:
        if row[1] != "temp":
            temperatures.append(int(row[1]))
    print(temperatures)