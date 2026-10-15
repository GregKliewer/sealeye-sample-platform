# cache-redis

> **Deprecated, March 2025. Do not use for new apps.** It stays only so the apps that
> already use it keep working until they move. The platform team is replacing it, and
> until there is a replacement there is no cache module for new apps. Ask in the
> platform channel before you plan around a cache.

A Redis cache in front of something slower.

## Why it is deprecated

It is pinned to an engine version past its end of support, and its encryption settings
do not meet the current standard. Changing them in place would replace every existing
cache, so it is frozen as it is.

## Inputs

| Name | What it is | Default |
|---|---|---|
| `name` | The app's name | required |
| `stage` | dev, sit, uat, staging, perf or prod | required |
| `subnet_group_name` | The stage's cache subnet group | required |
| `security_group_ids` | Who may connect | required |
