
module "us_payroll" {
    source = "../mods/app"
    app_region = "ap-southeast-2"
    ami = "ami-075924b436aa32cd4"
   # bucket = "" variable bucket will use default if not provided
}