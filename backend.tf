##state remoto nel bucket che questo stesso repo gestisce (il bucket esiste
##gia', creato dal bootstrap storico: nessun uovo-e-gallina residuo)
terraform {
  backend "s3" {
    bucket       = "tfstate-820329008292-side-project"
    key          = "account-bootstrap/terraform.tfstate"
    region       = "eu-central-1"
    encrypt      = true
    use_lockfile = true
  }
}
