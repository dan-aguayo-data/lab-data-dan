
#when you open file in write mode and it doesn't exist, it will create it by default

file_name = 'new_file_sample.txt'


#open method default is read only...

with open(file_name, mode ="w") as file:  #close files automatically
    file.write("new text")  #this will delete the previous conent
