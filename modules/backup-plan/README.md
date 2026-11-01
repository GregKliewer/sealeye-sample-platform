# backup-plan

A copy of everything an app keeps, once a day, into the stage's backup vault, which the
platform team keeps apart from the app.

## When to use it

**From staging up, beside every app that keeps a relational database.** It is not
something an app asks for: an app that goes to staging or prod with a database and no
backup plan is stopped at the change review, because a database's own backups go with
the database if it is ever deleted, and the vault's do not. Add it to the stage's root
module, beside `postgres-cluster`; nothing else changes.

Below staging it is allowed but not needed: `postgres` keeps a week of its own backups,
and dev, sit and uat data can be made again.

## What it copies

Everything the library's modules made for the app at that stage, found by the labels
every module sets (`juniper:app`, `juniper:stage`): the database, and any document
table or file bucket beside it. An app never lists its resources here.

## Stages

- staging and perf: each day's copy is kept for five weeks.
- prod: each day's copy is kept for a year.

## Inputs

| Name | What it is | Default |
|---|---|---|
| `name` | The app's name | required |
| `stage` | dev, sit, uat, staging, perf or prod | required |
| `vault_name` | The stage's backup vault, which the platform team keeps | required |
| `backup_role_arn` | The role the backup service acts as in this stage | required |
| `tags` | Extra labels on everything it makes | `{}` |

## Outputs

| Name | What it is |
|---|---|
| `plan_id` | The backup plan, for the change review's record |
| `keep_days` | How long each day's copy is kept at this stage |
