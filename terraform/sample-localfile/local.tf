resource "local_file" "pet" {
	filename = "C:\\Users\\DanielAguayo\\OneDrive - Circular Economy Systems\\Desktop\\pets.txt"
	content = "We love pets!"
	file_permission ="0700"
}