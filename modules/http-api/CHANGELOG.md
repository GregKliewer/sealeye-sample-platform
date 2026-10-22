# Changelog: http-api

Released as `http-api/v<version>` tags. A major version changes what the module takes or gives; read its entry before moving an app to it.

## 1.2.3

- Outputs `log_group`, where everything the app prints is kept, so the front door can
  read it back to the developer. Nothing it takes changes.

## 1.2.2

- The function gets thirty seconds a request and twice the memory the platform gives
  by default, so an app's first request, which opens its connections and makes its
  tables, is not cut off at three. Nothing it takes or gives changes.

## 1.2.1

- `secret_arns` says it is never a database's master password. Nothing else changes.

## 1.2.0

- Takes `subnet_ids` and `security_group_ids`, to run in the private network when the app
  uses a database. Empty, as before, the app runs outside the network and nothing
  changes.

## 1.1.0

- Takes `policy_arns`, what the app may read and write as each data module offers it, and `secret_arns`, the secrets it may read while it runs.

## 1.0.0

- The module as the platform team first published it.
