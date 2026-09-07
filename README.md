# account-bootstrap

La "piattaforma dell'account" AWS (820329008292), gestita **interamente via
pipeline**: le risorse che esistono una volta sola per account e le identità
CI di ogni progetto, in un posto solo.

- `account.tf` — bucket S3 dello state Terraform + provider OIDC GitHub
  (unico per account: è il motivo per cui questo repo esiste).
- `modules/project-ci-role/` — il ruolo CI di un progetto: trust OIDC legata
  al suo repo (nome **e** ID immutabili), PowerUser + IAM ristretto al
  prefisso delle sue risorse.
- `projects.tf` — un'istanza del modulo per progetto.
- `self.tf` — il ruolo che la pipeline di *questo* repo assume
  (`digitalrisk-bootstrap-ci`), coi permessi minimi del suo mestiere.
- `.github/workflows/terraform.yml` — plan sulle PR, apply al merge.
- `imports.tf` — una tantum: adotta le risorse già esistenti sull'account
  senza ricrearle (eliminare dopo il primo apply riuscito).

State remoto: stesso bucket, key `account-bootstrap/terraform.tfstate`.

## Bootstrap del bootstrap (una tantum, tutto via pipeline)

La pipeline assume `digitalrisk-bootstrap-ci`… che alla prima esecuzione non
esiste. Lo crea **la pipeline di design-risk** (l'unico ruolo già attivo
sull'account; il prefisso `digitalrisk-` del nome è il vincolo del suo
scoping IAM). Ordine:

1. **Seed** — in `design-risk`, mergiare la PR che aggiunge
   `infra/terraform/envs/dev/bootstrap_ci_seed.tf` (definizione temporanea
   del ruolo): la sua pipeline lo applica e il ruolo nasce.
2. **Adozione** — mergiare la prima PR di *questo* repo: la pipeline parte,
   assume il ruolo appena nato e l'apply **importa** tutto l'esistente
   (bucket, provider OIDC, ruolo di design-risk, sé stesso): atteso
   "9 to import, 0 to destroy". Da qui questo repo si autogoverna.
3. **Pulizia** — eliminare `imports.tf` qui; in design-risk sostituire il
   seed con un blocco `removed` (dimentica senza distruggere: il ruolo ora
   appartiene a questo repo):

   ```hcl
   removed {
     from = aws_iam_role.bootstrap_ci_seed
     lifecycle { destroy = false }
   }
   removed {
     from = aws_iam_role_policy.bootstrap_ci_seed
     lifecycle { destroy = false }
   }
   ```

## Aggiungere un progetto

1. `gh api repos/marnadir/<repo> --jq .id` per l'ID immutabile.
2. Copiare il blocco template in `projects.tf`: repo, repo_id,
   `resource_prefix` (prefisso delle risorse AWS del progetto),
   `role_name` = `github-actions-ci-<progetto>`.
3. PR → plan in review → merge → apply. L'output `<progetto>_ci_role_arn`
   va nei workflow del repo nuovo (env `AWS_ROLE_ARN`).
4. Backend del progetto nuovo: stesso bucket, key
   `<progetto>/envs/<ambiente>/terraform.tfstate`.

## Rimuovere un progetto

Eliminare il blocco `module` da `projects.tf` → PR → merge: il ruolo sparisce
e quel repo non può più assumere nulla. Bucket e provider OIDC restano.

## Convenzioni

- Un ruolo per progetto, mai condiviso: revoca chirurgica, blast radius
  contenuto.
- Il claim `sub` include gli ID immutabili: la trust sopravvive al rename
  del repo (aggiornare comunque `github_repo` col nome nuovo) e non è
  dirottabile ricreando un repo omonimo.
- `design-risk` conserva il nome storico `github-actions-ci` e la key
  storica `envs/dev/terraform.tfstate`.
- Dopo l'adozione, la cartella `bootstrap/` dentro design-risk è cimelio:
  va ritirata (mai con `terraform destroy`).
