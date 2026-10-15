# Juniper Mutual platform library

> **Made up.** Juniper Mutual is a fictional credit union. This repository is a test
> library for [seaLeye](https://github.com/GregKliewer/sealeye): the modules are real
> Terraform, but no organization runs them. Nothing here holds a real secret.

The modules Juniper Mutual's platform team trusts, and the pipeline every app is built
and promoted with. App teams build from these and nothing else.

## Modules

| Module | For |
|---|---|
| `static-site` | A website that is only files, served to the public |
| `custom-domain` | An app at a name Juniper Mutual owns |
| `http-api` | An app that answers requests and can start fresh for each one |
| `container-service` | An app that has to stay running |
| `internal-entry` | A front door only Juniper Mutual's network can reach |
| `postgres` | A relational database, below staging |
| `postgres-cluster` | A relational database, from staging up |
| `document-table` | Documents found by key |
| `work-queue` | Work handed off to be done later |
| `file-bucket` | Files an app keeps, always private |
| `secrets` | Secrets an app reads while it runs |
| `logs-and-alarms` | Every app's logs and alarms |
| `cache-redis` | **Deprecated**: not for new apps |

Each module's README says when to use it, what changes from stage to stage, and its
inputs. Read them: some rules are written only there.

There is nothing yet for a stream of events, for signing in an app's own users, or for
work that runs on a schedule. Ask in the platform channel.

## The path to production

Every module takes a `stage`: dev, sit, uat, staging, perf or prod. From staging up, an
environment is held to production's rules: more copies, more backups, protection
against deletion, and alarms to on-call.

An app's package is built once (`.github/workflows/app-build.yml`) and the same package,
by its checksum, is promoted one stage at a time (`.github/workflows/app-promote.yml`):

1. **dev**: built by the developer.
2. **sit**, then **uat**: promoted by the team.
3. **staging**: needs a platform team approval.
4. **prod**: needs a platform team approval and an approved change ticket.

**perf** is not on the path. It is built from what is in staging, for a load test, and
nothing is promoted from it.

Each stage has its own root module and its own state, in the stage's own account.

## Checks

`.github/workflows/module-check.yml` checks that every module is formatted and valid
Terraform, on every push.
