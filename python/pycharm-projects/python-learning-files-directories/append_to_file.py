
file_name = 'test.txt'


#open method default is read only...

with open(file_name, mode ="a") as file:  #close files automatically
    file.write("\nnew text")  #this will delete the previous conent


