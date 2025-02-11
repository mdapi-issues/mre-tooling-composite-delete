# mre-tooling-composite-delete

> Minimal working example to demonstrate a bug in the Tooling Composite API where deleting Tooling API records does not work.

[![Actions Status](https://github.com/mdapi-issues/mre-tooling-composite-delete/actions/workflows/default.yml/badge.svg?branch=main)](https://github.com/mdapi-issues/mre-tooling-composite-delete/actions?query=branch:main)

> [!IMPORTANT]
> A green status badge means the issue was successfully reproduced.
>
> A red status badge means the issue was fixed or the pipeline failed for another reason.

It's not possible to delete multiple Tooling API records although it is documented here:

https://developer.salesforce.com/docs/atlas.en-us.api_tooling.meta/api_tooling/tooling_resources_composite_sobjects_collections_delete.htm

Error:

```json
{
  "errorCode": "NOT_FOUND",
  "message": "The requested resource does not exist"
}
```

![Delete Flow Error](https://github.com/user-attachments/assets/d52bc263-ffe5-4c1f-96be-fd7f08c459fb)

For regular SObjects, this works just fine.

https://developer.salesforce.com/docs/atlas.en-us.api_rest.meta/api_rest/resources_composite_sobjects_collections_delete.htm

## Reproduction

Create two SourceMember Tooling API records and try to delete them in a composite request:

```shell
sf data record create --use-tooling-api --sobject SourceMember --values "MemberType='FakeType' MemberName='Fake1'"
sf data record create --use-tooling-api --sobject SourceMember --values "MemberType='FakeType' MemberName='Fake2'"
idsCommaSeparated="$(sf data query --use-tooling-api --query "SELECT Id FROM SourceMember WHERE MemberType='FakeType'" --result-format csv | tail -n +2 | paste -sd "," -)"
sf api request rest --method DELETE --body "formdata" "/services/data/v62.0/tooling/composite/sobjects?allOrNone=true&ids=${idsCommaSeparated}"
```

Output:

```shell
[
  {
    "errorCode": "NOT_FOUND",
    "message": "The requested resource does not exist"
  }
]
```

## Workaround

Delete records sequentially:

```shell
while read -r id; do
    sf data record delete --use-tooling-api --sobject SourceMember --record-id "${id}"
done < <(sf data query --use-tooling-api --query "SELECT Id FROM SourceMember WHERE MemberType='FakeType'" --result-format csv | tail -n +2)
```

Output:

```shell
Querying Data... done
Successfully deleted record: 0MZS8000009P5CEOA0.
Deleting Record... Success
Successfully deleted record: 0MZS8000009PBHdOAO.
Deleting Record... Success
```

## References

- https://github.com/hardisgroupcom/sfdx-hardis/issues/662
- https://github.com/jsforce/jsforce/issues/1571
