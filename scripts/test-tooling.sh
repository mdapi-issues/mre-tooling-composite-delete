#!/usr/bin/env bash

set -eo pipefail

trap cleanupSequentially ERR

getIds() {
    sf data query \
        --use-tooling-api \
        --query "SELECT Id FROM SourceMember WHERE MemberType='FakeType'" \
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
            --sobject SourceMember \
            --record-id "${id}"
        done < <(echo "${ids}")
    fi
}

sf data record create --use-tooling-api --sobject SourceMember --values "MemberType='FakeType' MemberName='Fake1'"
sf data record create --use-tooling-api --sobject SourceMember --values "MemberType='FakeType' MemberName='Fake2'"

ids="$(getIds)"
idsCommaSeparated="$(echo "${ids}" | paste -sd "," -)" # comma join ids

set -x
sf api request rest --method DELETE --include --body "formdata" "/services/data/v63.0/tooling/composite/sobjects?allOrNone=true&ids=${idsCommaSeparated}"
