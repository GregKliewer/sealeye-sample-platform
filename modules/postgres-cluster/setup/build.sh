#!/usr/bin/env sh
# Builds setup.zip, the package the postgres-cluster module's one-time setup function runs:
# the function's code with its one dependency bundled in, and the platform's
# certificate bundle, which the function checks the database's certificate against.
#
# The build is the same bytes whenever its inputs are the same, so the library's own
# check can rebuild it and compare. Run it from anywhere; commit setup.zip with any
# change to src/.
set -eu
cd "$(dirname "$0")"

npm ci --no-audit --no-fund --loglevel=error
mkdir -p build
curl -fsSL https://truststore.pki.rds.amazonaws.com/global/global-bundle.pem -o build/rds-ca.pem
npx esbuild src/index.js --bundle --platform=node --target=node20 --format=cjs \
  --external:pg-native '--external:@aws-sdk/*' --outfile=build/index.js --log-level=warning

# One zip whatever the clock, the file modes or the machine: stored, not compressed,
# so no compressor's version is in the bytes.
python3 - <<'PY'
import zipfile
with zipfile.ZipFile("setup.zip", "w", zipfile.ZIP_STORED) as z:
    for name in ("index.js", "rds-ca.pem"):
        info = zipfile.ZipInfo(name, date_time=(2020, 1, 1, 0, 0, 0))
        info.external_attr = 0o644 << 16
        with open("build/" + name, "rb") as f:
            z.writestr(info, f.read())
PY
echo "setup.zip: $(wc -c < setup.zip | tr -d ' ') bytes"
