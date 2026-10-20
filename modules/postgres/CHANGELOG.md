# Changelog: postgres

Released as `postgres/v<version>` tags. A major version changes what the module takes or gives; read its entry before moving an app to it.

## 1.2.1

- The default `instance_class` is `db.t4g.small`: signing in with the app's own identity
  takes a few hundred megabytes of memory on the database, which the smallest size
  cannot spare. A database already standing is resized in place on its next apply.

## 1.2.0

- The app signs in with its own identity (IAM database authentication), as a user of its
  own, to a database of its own, both named after the app and made by a one-time setup
  function inside the private network when the database is made. Offers
  `access_policy_arn`, the right to sign in, beside `address`, `port`, `database_name`
  and `database_user`; `database_user` is now the app's user, not the master user.
  Takes the platform's `permissions_boundary_arn` for the setup function. Nothing is
  replaced: an existing database gains its user and database on the next apply.

## 1.1.0

- Outputs the `port` and the `database_user` the app connects with, beside its `address` and `password_secret_arn`.

## 1.0.0

- The module as the platform team first published it.
