# logs-and-alarms

Keeps an app's logs and raises an alarm when it starts logging errors.

## When to use it

For every app, at every stage. There is no app at Juniper Mutual without logs and
alarms, and nobody should have to ask for them.

## Stages

Logs are kept for a week below staging and for a year from staging up.

## Where alarms go

This matters more than anything else in this module, and the module cannot check it for
you:

- **In dev, sit and uat**, send alarms to your own team's channel topic. Nobody else
  should be woken by a test environment.
- **From staging up, every app's alarms go to the on-call topic, `oncall-pager`**, and
  nowhere else. An app that goes to staging still alarming to a team channel will be
  stopped at the change review before production, because staging is where on-call
  learns how the app fails.

## Inputs

| Name | What it is | Default |
|---|---|---|
| `name` | The app's name | required |
| `stage` | dev, sit, uat, staging, perf or prod | required |
| `alarm_topic_arn` | Where alarms go (see above) | required |
| `error_pattern` | What an error line looks like | `ERROR` |
