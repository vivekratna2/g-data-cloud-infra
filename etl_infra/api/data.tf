data "aws_secretsmanager_secret" "by_name" {
  name = "etl/${terraform.workspace}"
}

data "aws_secretsmanager_secret_version" "secret_version" {
  secret_id = data.aws_secretsmanager_secret.by_name.id
}

data "terraform_remote_state" "etl_db_output" {
  backend = "s3"
  config = {
    bucket         = "gbd-airflow-tf-state"
    key            = "env:/${terraform.workspace}/etl-db/terraform.tfstate"
    region         = "us-west-2"
    dynamodb_table = "terraform-state-locking"
    profile        = "gbd-user"
  }
}