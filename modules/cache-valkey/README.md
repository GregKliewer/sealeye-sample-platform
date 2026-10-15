# cache-valkey

A Valkey cache in front of something slower. Encrypted at rest and in transit.

The platform team is trying it with the payments and lending teams, who moved off
`cache-redis` to it in the summer.

## Inputs

| Name | What it is | Default |
|---|---|---|
| `name` | The app's name | required |
| `stage` | dev, sit, uat, staging, perf or prod | required |
| `subnet_group_name` | The stage's cache subnet group | required |
| `security_group_ids` | Who may connect | required |
| `tags` | Tags beside the module's own | `{}` |
