# custom-domain

Puts an app behind a name Juniper Mutual owns, such as `rates.junipermutual.example`,
with a certificate that renews itself.

## When to use it

Only for an app that must be reached at a name of the organization's own: anything
public facing that customers type or bookmark. Internal tools and anything below
staging use the address the platform generates; there is no need to ask for one.

The name must be in a zone the platform team manages. Ask for the zone's id in the
platform channel. For a `static-site`, the content network's certificate is the
platform team's own and this module is not used.

## Stages

Any stage may have a name, but only `prod` may use the bare product name. Lower stages
put the stage first: `staging.rates.junipermutual.example`.

## Inputs

| Name | What it is | Default |
|---|---|---|
| `name` | The app's name | required |
| `stage` | dev, sit, uat, staging, perf or prod | required |
| `domain_name` | The full name to answer on | required |
| `zone_id` | The zone that name is in | required |
| `target_domain_name` | The address the name points at | required |
| `target_zone_id` | That address's own zone | required |
