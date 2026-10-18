# work-queue

A queue between an app and the work it hands off, with a second queue that catches
any message that fails too often, so nothing is lost and nothing loops forever.

## When to use it

For an app that hands work to something else to do later, or does work it was handed:
look for a queue client in the dependencies, or a worker that reads messages. A stream
of events that many readers each see in order is not a queue, and this library has no
module for one yet.

## Stages

Messages wait four days below staging and two weeks from staging up.

## Inputs

| Name | What it is | Default |
|---|---|---|
| `name` | The app's name | required |
| `stage` | dev, sit, uat, staging, perf or prod | required |
| `max_receives` | Tries before a message goes to the failed queue | `5` |

## Using it from an app

Pass `access_policy_arn` in the app module's `policy_arns`, and what the app looks it up by in its `environment` (see `http-api`'s README). Each data module offers a narrower policy beside it.
