##Un blocco per progetto. Aggiungere un progetto = copiare un blocco,
##cambiare i quattro valori, `terraform apply`, mettere l'output role_arn
##nei workflow del repo nuovo. Rimuovere il blocco = disarmare il progetto.

module "design_risk" {
  source = "./modules/project-ci-role"

  github_repo     = "marnadir/design-risk"
  github_owner_id = "44031384"
  github_repo_id  = "1303979814"
  resource_prefix = "digitalrisk"
  ##nome storico (pre-modulo): i workflow del repo lo referenziano gia'
  role_name = "github-actions-ci"

  oidc_provider_arn = aws_iam_openid_connect_provider.github.arn
}

output "design_risk_ci_role_arn" {
  value = module.design_risk.role_arn
}

##template per il prossimo progetto:
##module "nome_progetto" {
##  source            = "./modules/project-ci-role"
##  github_repo       = "marnadir/<repo>"
##  github_owner_id   = "44031384"                # stesso owner
##  github_repo_id    = "<gh api repos/marnadir/<repo> --jq .id>"
##  resource_prefix   = "<prefisso>"
##  role_name         = "github-actions-ci-<progetto>"
##  oidc_provider_arn = aws_iam_openid_connect_provider.github.arn
##}
