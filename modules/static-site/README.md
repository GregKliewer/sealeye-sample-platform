# static-site

Serves a website's files (HTML, CSS, images, scripts) to the public over HTTPS, from a
private bucket behind the content network. Nothing runs on a server.

## When to use it

For a site that is only files: a marketing page, documentation, or the built output of a
front end whose data comes from an API elsewhere. If anything has to run when a request
arrives, this is the wrong module: use `http-api` or `container-service`.

This is the only module allowed to serve files to the public. Every other bucket at
Juniper Mutual is private (see `file-bucket`).

## Stages

In dev, sit and uat the site is served from the cheapest set of edge locations. From
staging up it is served from every location, as production is.

## Inputs

| Name | What it is | Default |
|---|---|---|
| `name` | The app's name | required |
| `stage` | dev, sit, uat, staging, perf or prod | required |
| `index_document` | The page visitors land on | `index.html` |
| `tags` | Extra tags | `{}` |

## Outputs

`bucket_name` (upload the site's files here) and `url` (the site's address).
