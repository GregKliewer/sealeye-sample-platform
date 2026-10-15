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
