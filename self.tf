##Il ruolo che la pipeline di QUESTO repo assume via OIDC.
##
##Uovo-e-gallina risolto per delega: la prima creazione la fa la pipeline
##di design-risk (seed temporaneo in envs/dev — il nome digitalrisk-* e'
##il vincolo del suo scoping IAM, ed e' il prezzo del seed). Al primo
##apply di questa pipeline il ruolo viene IMPORTATO qui (vedi imports.tf)
##e da quel momento questo repo si autogoverna; il seed in design-risk va
##poi rimosso con un blocco `removed` (mai destroy).

data "aws_iam_policy_document" "bootstrap_trust" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn]
    }
    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }
    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      ##entrambi i formati del sub per ogni nome accettato (la lista
      ##gestisce i rename del repo senza lockout della pipeline)
      values = flatten([
        for name in var.self_repo_names : [
          "repo:${var.github_owner}/${name}:*",
          "repo:${var.github_owner}@${var.github_owner_id}/${name}@${var.self_repo_id}:*",
        ]
      ])
    }
  }
}

resource "aws_iam_role" "bootstrap_ci" {
  name               = "digitalrisk-bootstrap-ci"
  assume_role_policy = data.aws_iam_policy_document.bootstrap_trust.json
}

##permessi minimi del mestiere di questo repo: lo state bucket, i ruoli CI
##dei progetti (github-actions-*), il provider OIDC, e se' stesso
data "aws_iam_policy_document" "bootstrap_permissions" {
  statement {
    actions = ["s3:*"]
    resources = [
      aws_s3_bucket.tfstate.arn,
      "${aws_s3_bucket.tfstate.arn}/*",
    ]
  }

  statement {
    actions = [
      "iam:CreateRole",
      "iam:DeleteRole",
      "iam:GetRole",
      "iam:TagRole",
      "iam:UntagRole",
      "iam:UpdateAssumeRolePolicy",
      "iam:AttachRolePolicy",
      "iam:DetachRolePolicy",
      "iam:PutRolePolicy",
      "iam:DeleteRolePolicy",
      "iam:GetRolePolicy",
      "iam:ListRolePolicies",
      "iam:ListAttachedRolePolicies",
      "iam:ListInstanceProfilesForRole",
      "iam:PassRole",
    ]
    resources = [
      "arn:aws:iam::*:role/github-actions-*",
      "arn:aws:iam::*:role/digitalrisk-bootstrap-ci",
    ]
  }

  statement {
    actions = [
      "iam:GetOpenIDConnectProvider",
      "iam:CreateOpenIDConnectProvider",
      "iam:DeleteOpenIDConnectProvider",
      "iam:UpdateOpenIDConnectProviderThumbprint",
      "iam:AddClientIDToOpenIDConnectProvider",
      "iam:RemoveClientIDFromOpenIDConnectProvider",
      "iam:TagOpenIDConnectProvider",
      "iam:UntagOpenIDConnectProvider",
    ]
    resources = [aws_iam_openid_connect_provider.github.arn]
  }
}

resource "aws_iam_role_policy" "bootstrap_ci_permissions" {
  name   = "bootstrap-permissions"
  role   = aws_iam_role.bootstrap_ci.name
  policy = data.aws_iam_policy_document.bootstrap_permissions.json
}
