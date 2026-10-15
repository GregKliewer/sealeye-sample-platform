# document-table

A table of documents, each found by its key, that scales by itself and costs by the
request. Encrypted.

## When to use it

For an app that stores records by key rather than in related tables: sessions,
profiles, the state of a long-running job. Look for a document database client in the
app's dependencies. An app whose code uses SQL needs a relational database instead.

## Stages

From staging up the table can be restored to any point in the last five weeks and is
protected against deletion. Below staging it is neither.

## Inputs

| Name | What it is | Default |
|---|---|---|
| `name` | The app's name | required |
| `stage` | dev, sit, uat, staging, perf or prod | required |
| `key` | The attribute each document is found by | `id` |
