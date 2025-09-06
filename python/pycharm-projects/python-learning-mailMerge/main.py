PLACEHOLDER = "[name]"


names_file_path = './Input/Names/invited_names.txt'
letters_file_path = './Input/Letters/starting_letter.txt'
with open(names_file_path) as names_file:
    names = names_file.readlines()


with open(letters_file_path) as letters:
    letters_content = letters.read()
    for name in names:
        stripped_name = name.strip()
        new_letter = letters_content.replace(PLACEHOLDER,stripped_name)
        new_file_path = f"./Output/ReadyToSend/letter_for{stripped_name}.docx"
        with open(new_file_path, "w") as new_files:
            new_files.write(new_letter)

