##Le risorse UNICHE per account: esistono una volta sola, qualunque sia il
##numero di progetti. Tutto cio' che e' "di un progetto" (ruolo CI, trust,
##permessi) sta invece nel modulo project-ci-role, un'istanza per repo.

##bucket condiviso per lo state Terraform di tutti i progetti dell'account.
##Convenzione delle key: <progetto>/envs/<ambiente>/terraform.tfstate
##(design-risk usa ancora la key storica envs/dev/terraform.tfstate)
resource "aws_s3_bucket" "tfstate" {
  bucket = var.tfstate_bucket_name
}

resource "aws_s3_bucket_versioning" "tfstate" {
  bucket = aws_s3_bucket.tfstate.id
  versioning_configuration { status = "Enabled" }
}

resource "aws_s3_bucket_public_access_block" "tfstate" {
  bucket                  = aws_s3_bucket.tfstate.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

##GitHub come identity provider dell'account: AWS accetta i token OIDC
##firmati da GitHub Actions. UNO solo per account e per URL — e' il motivo
##per cui questa risorsa non puo' stare nei bootstrap dei singoli progetti
resource "aws_iam_openid_connect_provider" "github" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"]
}
