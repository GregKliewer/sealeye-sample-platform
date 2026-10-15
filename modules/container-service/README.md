# container-service

Runs an app that has to stay up: one that reads a stream or a queue in a loop, holds
connections open, or takes a while to warm up. It runs as containers on the shared
cluster, in the private network.

## When to use it

For anything that cannot start fresh for each request. A consumer that also answers a
health check is still a continuously running service, not an HTTP API. If the app only
answers requests, `http-api` is cheaper and simpler.

To be reached from other apps inside Juniper Mutual, put `internal-entry` in front of
it. Nothing here is reachable from the internet.

## Stages

Dev, sit and uat run one copy. From staging up the service runs three copies, spread
across zones, and logs are kept for a year.

## Inputs

| Name | What it is | Default |
|---|---|---|
| `name` | The app's name | required |
| `stage` | dev, sit, uat, staging, perf or prod | required |
| `image` | The container image, built once by the pipeline | required |
| `container_port` | The port the app listens on | `8080` |
| `cluster_arn` | The shared cluster for this stage | required |
| `subnet_ids` | The stage's private subnets | required |
| `security_group_ids` | Who may reach it | required |
| `execution_role_arn` | The platform's execution role | required |
