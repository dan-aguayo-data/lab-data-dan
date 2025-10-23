
import random
#syntax for dict comprenhension

#new_dict = {new_key:new_value for (key,value) in dict.items() if test}

names =["Alex","Beth","Caroline","Dave","Eleanor"]


student_scores = {name:random.randint(1,100) for name in names}

print(student_scores)

passed_students = {student:grade for (student,grade) in student_scores.items() if grade > 70}

print(passed_students)