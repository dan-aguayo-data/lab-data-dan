import pandas


student_dict = {
    "student": ["Angela","James","Lily"],
    "score": [56,76,98]
}

student_df = pandas.DataFrame(student_dict)

print(student_df)

#loop through df ... not efficient below

for (key,value) in student_df.items():
    print(value)

#loop through the rows instead

for (index,row) in student_df.iterrows():
    print(row.student)

for (index,row) in student_df.iterrows():
    if row.student == "Angela":
        print(row)