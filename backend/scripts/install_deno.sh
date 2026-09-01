#!/usr/bin/env bash
set -e
DENO_VERSION="2.9.6"
curl -fsSL -o /tmp/deno.zip \
  "https://github.com/denoland/deno/releases/download/v${DENO_VERSION}/deno-x86_64-unknown-linux-gnu.zip"
python -c "import zipfile; zipfile.ZipFile('/tmp/deno.zip').extractall('bin')"
chmod +x bin/deno
./bin/deno --version
