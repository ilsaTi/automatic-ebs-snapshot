# account information
variable "props" {
    type = map(string)
    default = {
        region = "us-east-1"
        account_id="886774924794"
    }
} 

# deployment tags; more tags could be added in the mapping
variable "tags" {
    type = map(string)
    default = {
        IaC = "Terraform"

    }
}

# environment variables used to tag the snapshot
variable "parameters" {
    type = map(string)
    default = {
        tag_key = "Achive"
        tag_value = "automatic"
    }
}

# schedule
variable "schedule" {
    type = map(string)
    default = {
        start = "cron(0 10 ? * SUN *)"
    }

}

