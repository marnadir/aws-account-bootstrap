# aws-account-bootstrap

The "account platform" for AWS account `820329008292`, managed **entirely
through the pipeline**: the resources that exist once per account, and the
CI identity of every project, in a single place.

- `account.tf` — the S3 bucket for Terraform state and the GitHub OIDC
  identity provider (one per account: the reason this repository exists).
- `modules/project-ci-role/` — the CI role of a project: OIDC trust bound
  to its repository (by name **and** immutable ID), PowerUser plus IAM
  actions restricted to the project's resource prefix.
- `projects.tf` — one module instance per project.
- `self.tf` — the role this repository's own pipeline assumes
  (`digitalrisk-bootstrap-ci`), with the minimum permissions for its job.
- `variables.tf` — account-wide constants in one place (the `backend`
  block is the only exception: Terraform does not allow variables there).
- `.github/workflows/terraform.yml` — plan on pull requests, apply on
  merge to main.

Remote state: same bucket, key `account-bootstrap/terraform.tfstate`.

## How it works

GitHub Actions authenticates to AWS via **OIDC — no static credentials
anywhere**. Each workflow run presents a short-lived token signed by
GitHub; AWS verifies the issuer and checks the token's `sub` claim against
the role's trust policy, which is pinned to a specific repository — by
name *and* by immutable numeric ID. The ID survives repository renames and
prevents trust hijacking through the recreation of a deleted repository
under the same name.

Each project gets **its own role**: separate boundaries, surgical
revocation, contained blast radius. Removing a project's `module` block
disarms that repository entirely.

## Adding a project

1. Get the repository's immutable ID:
   `gh api repos/<owner>/<repo> --jq .id`
2. Copy the template block in `projects.tf` and fill in: repo, repo ID,
   `resource_prefix` (the AWS resource prefix of the project),
   `role_name` (`github-actions-ci-<project>`).
3. Open a PR → review the plan → merge → apply. The
   `<project>_ci_role_arn` output goes into the new repository's
   workflows (`AWS_ROLE_ARN` env).
4. Terraform backend of the new project: same bucket, key
   `<project>/envs/<environment>/terraform.tfstate`.

## Removing a project

Delete the `module` block from `projects.tf` → PR → merge: the role is
destroyed and that repository can no longer assume anything. The bucket
and the OIDC provider stay (other projects use them).

## How this repository bootstrapped itself

A pipeline that manages IAM needs a role to assume — which did not exist
on its first run. The chicken-and-egg was resolved by delegation, with no
local `terraform apply` at any point:

1. **Seed** — the already-active pipeline of the first project
   (`design-risk`) created `digitalrisk-bootstrap-ci` through a regular,
   temporary PR (the `digitalrisk-` prefix is the constraint of that
   pipeline's IAM scoping).
2. **Adoption** — the first apply of *this* repository assumed the
   newly-born role and **imported** every pre-existing resource (state
   bucket, OIDC provider, the first project's CI role, and the seed role
   itself): 9 imports, 0 destroyed, zero downtime for the existing CI.
3. **Cleanup** — the seed definition in design-risk was replaced with
   `removed` blocks (`destroy = false`): its state forgot the role
   without touching it. Ownership moved here; this repository has
   self-governed ever since.

## Conventions

- One role per project, never shared.
- The `sub` claim includes immutable IDs: trust survives repository
  renames (update `github_repo` with the new name anyway) and cannot be
  hijacked by recreating a deleted repository with the same name.
- Repository renames of *this* repo are done in two steps to avoid
  locking the pipeline out of its own role: first a PR that adds the new
  name to `self_repo_names` (trust accepts both), then the rename, then a
  PR that drops the old name.
- `design-risk` keeps its historical role name (`github-actions-ci`) and
  state key (`envs/dev/terraform.tfstate`).
