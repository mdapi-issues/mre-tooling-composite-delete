#!/usr/bin/env bash

set -eo pipefail

trap cleanupSequentially EXIT

getIds() {
    sf data query \
        --query "SELECT Id FROM Account WHERE Name LIKE 'Test Composite Delete %'" \
        --result-format csv \
    | tail -n +2 # skip CSV header
}

cleanupSequentially() {
    set +x
    ids="$(getIds)"
    numberOfIds="$(echo "${ids}" | awk 'NF' | wc -l | bc)"
    echo "Found "${numberOfIds}" records."
    if [[ "${ids}" != "" && "${DRY_RUN}" != "true" ]]; then
        while read -r id; do
            sf data record delete \
            --sobject Account \
            --record-id "${id}"
        done < <(echo "${ids}")
    fi
}

sf data record create --sobject Account --values "Name='Test Composite Delete 1'"
sf data record create --sobject Account --values "Name='Test Composite Delete 2'"

ids="$(getIds)"
idsCommaSeparated="$(echo "${ids}" | paste -sd "," -)" # comma join ids

set -x
sf api request rest --method DELETE --include --body "formdata" "/services/data/v62.0/composite/sobjects?allOrNone=true&ids=${idsCommaSeparated}"
