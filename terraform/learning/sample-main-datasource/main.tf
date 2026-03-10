resource "local_file" "pet" {
    filename = "pets.txt"
    content = data.local_file.dogs.content
}

data "local_file" "dogs" {
    filename = "dogs.txt"
}

