# Changelog: postgres-cluster

Released as `postgres-cluster/v<version>` tags. A major version changes what the module takes or gives; read its entry before moving an app to it.

## 1.1.0

- The app signs in with its own identity (IAM database authentication), as a user of its
  own, to a database of its own, both named after the app and made by a one-time setup
  function inside the private network when the cluster is made, as `postgres` does from
  1.2. Offers `access_policy_arn`, the right to sign in, beside `address`,
  `reader_address`, `port`, `database_name` and `database_user`. Takes the platform's
  `permissions_boundary_arn` for the setup function. Nothing is replaced: an existing
  cluster gains its user and database on the next apply.

## 1.0.0

- The module as the platform team first published it.
