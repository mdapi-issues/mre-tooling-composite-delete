#!/usr/bin/env bash

set -eo pipefail

trap cleanupSequentially EXIT

getIds() {
    sf data query \
        --use-tooling-api \
        --query "SELECT Id FROM Flow WHERE Status IN ('Draft', 'Obsolete', 'InvalidDraft')" \
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
            --use-tooling-api \
            --sobject Flow \
            --record-id "${id}"
        done < <(echo "${ids}")
    fi
}

sf project deploy start --source-dir force-app

ids="$(getIds)"
idsCommaSeparated="$(echo "${ids}" | paste -sd "," -)" # comma join ids

set -x
result="$(sf api request rest --method DELETE --body "formdata" "/services/data/v62.0/composite/sobjects?allOrNone=true&ids=${idsCommaSeparated}")"
set +x
failed="$(node -pe 'JSON.parse(fs.readFileSync(0, "utf8")).some(r => !r.success)' < <(echo "${result}"))"
if [[ "${failed}" == "true" ]]; then
    echo "Failed to delete records using Composite API."
    exit 1
fi
