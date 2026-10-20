# postgres

A PostgreSQL database for one app: a single instance, encrypted, in the private
network. The app gets a database of its own and signs in as its own user with its own
identity: no password, ever, in the app's hands. The master password is made and kept by
the platform, and read once, by the platform's own setup, when the database is made.

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
| `instance_class` | The instance size; the smallest has too little memory for signing in | `db.t4g.small` |
| `permissions_boundary_arn` | The platform's permissions boundary, for the setup function | `null` |
| `master_password` | Leave unset: the platform makes and keeps it | `null` |

`master_password` is only for restoring an old snapshot by hand. Never commit one. With
it set there is no kept password for the setup to read, so no app database or user is
made: connect as the master user, by hand, and make them.

## How an app signs in

The module makes a database and a user named after the app (`orders_api` and
`orders_api_app` for an app called `orders-api`), and gives the user the database. The
user has no password: the app signs in with its own identity (IAM database
authentication), which the platform turns on for every database. What the app needs is
offered as outputs, the way every data module in this library offers it:

| Output | What it is |
|---|---|
| `access_policy_arn` | The right to sign in as the app's user: pass it in the app's `policy_arns` |
| `address`, `port` | Where to connect |
| `database_name` | The app's database |
| `database_user` | The user it connects as |
| `password_secret_arn` | The master password, kept by the platform. For restoring by hand, never for an app |

The app's module has to be in the private network to reach the database: `http-api` and
`container-service` take the stage's private subnets and the apps security group, which
every database admits. In the app, make a token from its own credentials each time it
connects (the token is good for fifteen minutes) and connect over TLS:

```js
import { Signer } from "@aws-sdk/rds-signer";
import pg from "pg";

const signer = new Signer({
  hostname: process.env.DATABASE_HOST,
  port: Number(process.env.DATABASE_PORT),
  username: process.env.DATABASE_USER,
});
const client = new pg.Client({
  host: process.env.DATABASE_HOST,
  port: Number(process.env.DATABASE_PORT),
  database: process.env.DATABASE_NAME,
  user: process.env.DATABASE_USER,
  password: await signer.getAuthToken(),
  ssl: { ca: platformCertificates, rejectUnauthorized: true },
});
```

`platformCertificates` is the platform's certificate bundle, which the platform channel
publishes; the connection is checked against it, never just encrypted.

## The one-time setup

When the database is made, the module runs a small function of its own, inside the
private network, that signs in as the master user with the kept password, makes the
app's user with `rds_iam`, and makes the app's database owned by that user. It runs
once; running it again changes nothing. It is the only thing that ever reads the master
password. Its code is in `setup/`, built into `setup/setup.zip` by `setup/build.sh`;
the library's own check rebuilds the package and compares it, so the package is never
stale.

The function reaches the kept password through the stage's private endpoint for secrets,
and the database through a group of its own that the database admits, so no platform
group is changed by an app's environment.
