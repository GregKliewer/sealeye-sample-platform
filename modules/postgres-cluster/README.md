# postgres-cluster

A PostgreSQL cluster: a writer and, from staging up, a reader in another zone, so the
database survives losing a zone. Encrypted, in the private network, with the password
made and kept by the platform.

## How the app signs in

As `postgres` does: with its own identity, never a password. When the cluster is made, a
one-time setup function inside the private network signs in as the master user, with the
password the platform keeps, and makes the app a database and a user of its own, both
named after the app. The module offers `access_policy_arn`, the right to sign in as that
user, which the app's module attaches to the app's role (its `policy_arns` input). The
setup function is the only thing that ever reads the master password.

## When to use it

**For staging, perf and prod, always.** Every relational database from staging up is
one of these. Below staging, use `postgres`: it takes the same inputs and costs a
fraction as much, so an app's plan names `postgres` in dev and `postgres-cluster` from
staging on.

## Stages

- dev, sit, uat (allowed, but use `postgres`): one instance, a week of backups.
- staging, perf, prod: two instances in two zones, five weeks of backups, protected
  against deletion, and a final snapshot if it is ever removed.

## Inputs

| Name | What it is | Default |
|---|---|---|
| `name` | The app's name | required |
| `stage` | dev, sit, uat, staging, perf or prod | required |
| `subnet_group_name` | The stage's database subnet group | required |
| `security_group_ids` | Who may connect | required |
| `instance_class` | The instance size | `db.r6g.large` |
| `permissions_boundary_arn` | The platform's permissions boundary, carried by the setup function | none |

## Outputs

| Name | What it is |
|---|---|
| `address` | Where the app writes |
| `reader_address` | Where the app may read |
| `port` | The port the app connects on |
| `database_name` | The app's own database |
| `database_user` | The user the app signs in as |
| `access_policy_arn` | The right to sign in as that user; pass it in the app's `policy_arns` |
| `password_secret_arn` | Where the platform keeps the master password; for restoring by hand, never for the app |
