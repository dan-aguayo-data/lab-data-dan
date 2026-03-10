resource "local_file" "pet-dynamic" {
    filename = "pet-dynamic.txt"
    content = "My favourite pet is ${random_pet.my-pet.id}"
}

resource "local_file" "pet-not-dynamic" {
    filename = var.filename
    content = var.content
}

resource "random_pet" "my-pet" { #logical operator, only returning ephemeral output
    prefix = var.prefix
    separator = var.separator
    length = var.length
}