#!/usr/bin/env bash

set -eo pipefail

trap cleanupSequentially ERR

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

while read -r payload; do
    set -x
    result="$(echo "${payload}" | sf api request rest --method POST --body - "/services/data/v63.0/tooling/composite/" )"
    set +x
    failed="$(node -pe 'JSON.parse(fs.readFileSync(0, "utf8")).compositeResponse.some(r => r.httpStatusCode >= 400)' < <(echo "${result}"))"
    if [[ "${failed}" == "true" ]]; then
        echo "Failed to delete records using Composite API."
        exit 1
    fi
done < <(echo "${ids}" | ./scripts/get-composite-payloads.mjs)
