# secrets

A place for the secrets an app reads while it runs: keys to other services, tokens,
anything that must not be in code or in a plan. The module makes the place; the values
are put in by the team, by hand or from their own vault, and never pass through
Terraform.

## When to use it

For an app that reads a key, a token or a password from its environment. A database's
own password is made and kept by the database modules: do not add it here.

## Stages

A deleted secret can be brought back for thirty days from staging up. Below staging it
goes at once.

## Inputs

| Name | What it is | Default |
|---|---|---|
| `name` | The app's name | required |
| `stage` | dev, sit, uat, staging, perf or prod | required |
| `secret_names` | The names of the secrets the app reads | required |
