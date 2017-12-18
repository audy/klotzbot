#!/bin/bash

set -euo pipefail

docker run \
  --env-file environment.env \
  audy/klotzbot
