# http-api

Runs an app's code when a request arrives, behind an HTTPS address, and costs nothing
while nobody is calling it.

## When to use it

For an app that answers HTTP requests and can start fresh for each one: a REST API, a
webhook receiver, a small service with a health route. Look for a web framework in the
app's dependencies or a `listen` call.

If the app holds a connection open, reads a stream or a queue in a loop, or warms
something up when it starts, it cannot start fresh for each request: use
`container-service`.

Every function at Juniper Mutual carries the platform's permissions boundary. Pass it
as `permissions_boundary_arn`; the platform team publishes it in the platform channel.

## Stages

Logs are kept for a week in dev, sit and uat, and for a year from staging up.

## Inputs

| Name | What it is | Default |
|---|---|---|
| `name` | The app's name | required |
| `stage` | dev, sit, uat, staging, perf or prod | required |
| `package_path` | The zipped app | required |
| `handler` | The function the platform calls | `index.handler` |
| `environment` | Settings the app reads, names to values | `{}` |
| `permissions_boundary_arn` | The platform's permissions boundary | required |
| `policy_arns` | What the app may read and write: each data module's `access_policy_arn` | `[]` |
| `secret_arns` | Secrets the app may read while it runs | `[]` |
| `subnet_ids` | The stage's private subnets, only when the app uses a database | `[]` |
| `security_group_ids` | The stage's apps security group, given with `subnet_ids` | `[]` |

## Using a table, bucket or queue

Every data module in this library offers what an app needs to use it as an output,
`access_policy_arn` (and a narrower one beside it, such as `read_only_policy_arn`). Pass
it in `policy_arns`, and pass what the app looks the resource up by (`table_name`,
`bucket_name`, `queue_url`) in `environment`, under the name the app reads:

```hcl
module "orders" {
  source = "../document-table"
  name   = "orders"
  stage  = "dev"
}

module "api" {
  source                   = "../http-api"
  name                     = "orders"
  stage                    = "dev"
  package_path             = "app.zip"
  permissions_boundary_arn = var.permissions_boundary_arn
  policy_arns              = [module.orders.access_policy_arn]
  environment              = { ORDERS_TABLE = module.orders.table_name }
}
```

Never write a policy for an app by hand: if a module does not offer what the app needs,
ask in the platform channel.

## Using a database

A database lives in the private network, so an app that uses one joins that network: pass
the stage's private subnets as `subnet_ids` and the stage's apps security group as
`security_group_ids`, both published in the platform channel. Every database admits the
apps group. Leave both empty for an app that uses no database: outside the network the
app starts faster and needs nothing from it.

The database offers the rest the same way as a table does: its `access_policy_arn` in
`policy_arns`, and its `address`, `port`, `database_name` and `database_user` in
`environment`. The app signs in with its own identity; `postgres`'s README shows how.
Never pass a database's `password_secret_arn` to an app.
