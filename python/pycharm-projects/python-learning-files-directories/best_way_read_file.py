
file_name = 'test.txt'

with open(file_name) as file:  #close files automatically
    contents = file.read()
    print(contents)