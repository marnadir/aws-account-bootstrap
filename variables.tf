##Le variabili dell'account: un posto solo per i valori che oggi erano
##sparsi nei file. NOTA: il blocco backend (backend.tf) non puo' usare
##variabili — limite di Terraform — e resta l'unico coi valori letterali.

variable "aws_region" {
  description = "Regione di riferimento dell'account"
  type        = string
  default     = "eu-central-1"
}

variable "aws_account_id" {
  description = "ID dell'account AWS"
  type        = string
  default     = "820329008292"
}

variable "tfstate_bucket_name" {
  description = "Bucket S3 dello state Terraform di tutti i progetti (deve coincidere col backend.tf)"
  type        = string
  default     = "tfstate-820329008292-side-project"
}

variable "github_owner" {
  description = "Owner GitHub dei repository"
  type        = string
  default     = "marnadir"
}

variable "github_owner_id" {
  description = "ID numerico immutabile dell'owner GitHub"
  type        = string
  default     = "44031384"
}

##il repo di QUESTO bootstrap. E' una lista per gestire i rename senza
##lockout: durante la transizione la trust accetta vecchio e nuovo nome
##(l'ID immutabile resta lo stesso), poi il vecchio si toglie
variable "self_repo_names" {
  description = "Nomi accettati per il repo del bootstrap (lista per la transizione dei rename)"
  type        = list(string)
  default     = ["account-bootstrap", "aws-account-bootstrap"]
}

variable "self_repo_id" {
  description = "ID numerico immutabile del repo del bootstrap"
  type        = string
  default     = "1360274383"
}
