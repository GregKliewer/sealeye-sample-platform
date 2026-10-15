# file-bucket

Somewhere for an app to keep files it writes and reads back: uploads, exports,
generated documents. Private and encrypted.

## When to use it

For an app that stores files, not for a website: `static-site` is the only module that
serves files to the public. Every bucket at Juniper Mutual is private, and this module
does not take an input that would change that.

## Stages

From staging up every change to a file is kept, so an overwritten or deleted file can
be brought back. Below staging only the latest copy is kept.

## Inputs

| Name | What it is | Default |
|---|---|---|
| `name` | The app's name | required |
| `stage` | dev, sit, uat, staging, perf or prod | required |
