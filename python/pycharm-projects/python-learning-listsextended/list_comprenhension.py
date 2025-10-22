
#list comprenhension has the format below
#new_list = [new_item for item in list]
#you can use lists, ranges, strings

list = [1,2,3]
new_list = [n+1 for n in list]
print(new_list)


name = "DANIEL"
new_name_list = [n for n in name]
print(new_name_list)


new_range_list = [n + 1 for n in range(1,5)]
print(new_range_list)

#conditional list comprenhension
#new_list = [new_item for item in list if test]

names =["Alex","Beth","Caroline","Dave","Eleanor"]

short_names = [n for n in names if len(n)   <= 4 ]

print(short_names)