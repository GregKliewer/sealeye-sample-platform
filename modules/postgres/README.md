# postgres

A PostgreSQL database for one app: a single instance, encrypted, in the private
network. Its password is made and kept by the platform; the app reads it at start-up.

## When to use it

**Below staging only: dev, sit and uat.** It is one instance in one zone, kept cheap on
purpose, with a day of backups and no protection against being deleted.

From staging up, every relational database is a `postgres-cluster`. The two take the
same inputs, so moving an app from one to the other on the way to production is a change
of module, not of app. A plan for staging, perf or prod that names this module will be
turned back in review.

## Stages

The same everywhere it is allowed: one instance, one day of backups.

## Inputs

| Name | What it is | Default |
|---|---|---|
| `name` | The app's name | required |
| `stage` | dev, sit or uat | required |
| `subnet_group_name` | The stage's database subnet group | required |
| `security_group_ids` | Who may connect | required |
| `instance_class` | The instance size | `db.t4g.micro` |
| `master_password` | Leave unset: the platform makes and keeps it | `null` |

`master_password` is only for restoring an old snapshot by hand. Never commit one.
