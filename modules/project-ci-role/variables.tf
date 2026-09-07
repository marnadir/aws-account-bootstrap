variable "github_repo" {
  description = "Repository GitHub nel formato owner/name (output di `gh repo view`)"
  type        = string
}

##ID numerici immutabili (gh api repos/<owner>/<name> → .owner.id e .id):
##GitHub li include nel claim sub del token OIDC (repo:owner@ID/name@ID:...)
##e sopravvivono al rename del repo — proteggono anche da un omonimo
##ricreato da terzi dopo una cancellazione
variable "github_owner_id" {
  description = "ID numerico immutabile dell'owner GitHub"
  type        = string
}

variable "github_repo_id" {
  description = "ID numerico immutabile del repository GitHub"
  type        = string
}

variable "resource_prefix" {
  description = "Prefisso delle risorse del progetto (es. digitalrisk): le azioni IAM della CI sono concesse SOLO sui ruoli <prefix>-*"
  type        = string
}

variable "role_name" {
  description = "Nome del ruolo CI. Convenzione: github-actions-ci-<progetto>; design-risk conserva il nome storico github-actions-ci"
  type        = string
}

variable "oidc_provider_arn" {
  description = "ARN del provider OIDC GitHub dell'account (creato in account.tf, unico per account)"
  type        = string
}
