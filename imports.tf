##ADOZIONE DELL'ESISTENTE (una tantum): le risorse sotto vivono gia'
##sull'account, create dal bootstrap storico di design-risk. Questi blocchi
##dicono a Terraform di IMPORTARLE nello state invece di ricrearle: il primo
##`terraform plan` mostrera' "N to import", nessun destroy, e la CI di
##design-risk non subisce interruzioni.
##Dopo il primo apply riuscito questo file si puo' eliminare.

import {
  to = aws_s3_bucket.tfstate
  id = "tfstate-820329008292-side-project"
}

import {
  to = aws_s3_bucket_versioning.tfstate
  id = "tfstate-820329008292-side-project"
}

import {
  to = aws_s3_bucket_public_access_block.tfstate
  id = "tfstate-820329008292-side-project"
}

import {
  to = aws_iam_openid_connect_provider.github
  id = "arn:aws:iam::820329008292:oidc-provider/token.actions.githubusercontent.com"
}

import {
  to = module.design_risk.aws_iam_role.github_ci
  id = "github-actions-ci"
}

import {
  to = module.design_risk.aws_iam_role_policy_attachment.ci_permissions
  id = "github-actions-ci/arn:aws:iam::aws:policy/PowerUserAccess"
}

import {
  to = module.design_risk.aws_iam_role_policy.ci_iam_scoped
  id = "github-actions-ci:iam-scoped-digitalrisk"
}

##il ruolo di questa stessa pipeline: creato dal seed via design-risk,
##adottato qui al primo apply — da allora questo repo si autogoverna
import {
  to = aws_iam_role.bootstrap_ci
  id = "digitalrisk-bootstrap-ci"
}

import {
  to = aws_iam_role_policy.bootstrap_ci_permissions
  id = "digitalrisk-bootstrap-ci:bootstrap-permissions"
}
