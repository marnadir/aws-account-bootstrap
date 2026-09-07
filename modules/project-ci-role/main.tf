##Il ruolo CI di UN progetto: trust legata al suo repo GitHub via OIDC,
##permessi PowerUser + IAM ristretto al prefisso delle sue risorse.
##Un'istanza di questo modulo per progetto: confini separati, revoca
##chirurgica (si rimuove il blocco module e il progetto e' disarmato).

data "aws_iam_policy_document" "github_trust" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    principals {
      type        = "Federated"
      identifiers = [var.oidc_provider_arn]
    }
    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }
    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      ##entrambi i formati del sub: storico (repo:owner/name:*) e con gli
      ##ID immutabili (repo:owner@ID/name@ID:*) usato da GitHub
      values = [
        "repo:${var.github_repo}:*",
        "repo:${split("/", var.github_repo)[0]}@${var.github_owner_id}/${split("/", var.github_repo)[1]}@${var.github_repo_id}:*",
      ]
    }
  }
}

resource "aws_iam_role" "github_ci" {
  name               = var.role_name
  assume_role_policy = data.aws_iam_policy_document.github_trust.json
}

resource "aws_iam_role_policy_attachment" "ci_permissions" {
  role       = aws_iam_role.github_ci.name
  policy_arn = "arn:aws:iam::aws:policy/PowerUserAccess"
}

##PowerUserAccess esclude IAM, ma Terraform deve creare i ruoli di
##esecuzione delle lambda del progetto: azioni IAM concesse SOLO sui
##ruoli col prefisso del progetto
data "aws_iam_policy_document" "ci_iam_scoped" {
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
    resources = ["arn:aws:iam::*:role/${var.resource_prefix}-*"]
  }
}

resource "aws_iam_role_policy" "ci_iam_scoped" {
  name   = "iam-scoped-${var.resource_prefix}"
  role   = aws_iam_role.github_ci.name
  policy = data.aws_iam_policy_document.ci_iam_scoped.json
}
