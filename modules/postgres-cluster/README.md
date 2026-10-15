# postgres-cluster

A PostgreSQL cluster: a writer and, from staging up, a reader in another zone, so the
database survives losing a zone. Encrypted, in the private network, with the password
made and kept by the platform.

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
