import pandas


df_squirrel = pandas.read_csv("Central_Park_Squirrel_Census_2018.csv")   #starts data frame

print(df_squirrel)

gray_filter = df_squirrel[df_squirrel["Primary Fur Color"] == "Gray"]

print(gray_filter)

total_gray_squirrels = len(df_squirrel[df_squirrel["Primary Fur Color"] == "Gray"])
total_red_squirrels = len(df_squirrel[df_squirrel["Primary Fur Color"] == "Cinnamon"])
total_black_squirrels = len(df_squirrel[df_squirrel["Primary Fur Color"] == "Black"])

print(total_gray_squirrels)
print(total_red_squirrels)
print(total_black_squirrels)


data_dict = {
   "Fur Colour": ["Gray","Cinammon","Blank"],
    "Count":[total_gray_squirrels,total_red_squirrels,total_black_squirrels]

}

df_squirrel_count = pandas.DataFrame(data_dict)
df_squirrel_count.to_csv("squirrel_count.csv")
