resource "local_file" "pet" {
    filename = var.filename
    content = var.content
}

resource "random_pet" "my-pet" { #logical operator, only returning ephemeral output
    prefix = var.prefix
    separator = var.separator
    length = var.length
}