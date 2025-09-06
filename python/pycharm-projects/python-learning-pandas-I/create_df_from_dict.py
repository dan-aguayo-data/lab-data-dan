import pandas

#Create a dataframe from scratch

data_dict = {
    "students": ["Amy", "James", "Angela"],
    "scores": [76,56,65]
}


df = pandas.DataFrame(data_dict)  #initialize class dataframe

print(df)

#save into csv file
df.to_csv("test_new_data_from_dic.csv")