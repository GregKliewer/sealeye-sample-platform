# internal-entry

A front door that only Juniper Mutual's own network can reach. Apps inside the
organization call the app through it; nothing on the internet can.

## When to use it

For an app that must not be reachable from the public internet: back-office tools,
services other apps call, anything handling member data that has no business being
public. Put it in front of a `container-service`.

## Stages

Every stage uses the stage's own private subnets and its own certificate. From staging
up the door is protected against accidental deletion.

## Inputs

| Name | What it is | Default |
|---|---|---|
| `name` | The app's name | required |
| `stage` | dev, sit, uat, staging, perf or prod | required |
| `vpc_id` | The stage's network | required |
| `subnet_ids` | The stage's private subnets | required |
| `security_group_ids` | Who may call it | required |
| `certificate_arn` | The stage's internal certificate | required |
| `target_port` | The port the app listens on | `8080` |
