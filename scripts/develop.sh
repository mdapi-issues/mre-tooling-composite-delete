#!/usr/bin/env bash

set -eo pipefail
set -x

sf org create scratch -f config/project-scratch-def.json --alias mre-composite-delete --set-default
