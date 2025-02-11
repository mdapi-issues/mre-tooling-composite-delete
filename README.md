# MRE Tooling Composite Delete

> Minimal example demonstrating a bug in the Tooling Composite API where deleting Tooling API records fails.

[![Actions Status](https://github.com/mdapi-issues/mre-tooling-composite-delete/actions/workflows/default.yml/badge.svg?branch=main)](https://github.com/mdapi-issues/mre-tooling-composite-delete/actions?query=branch:main)

> [!IMPORTANT]
> A green status badge indicates that the issue was successfully reproduced.
>
> A red status badge means the issue was fixed or the pipeline failed for another reason.

It is not possible to delete multiple records of [Tooling API Objects](https://developer.salesforce.com/docs/atlas.en-us.api_tooling.meta/api_tooling/reference_objects_list.htm) (e.g. `Flow`, `SourceMember`,...) via `/services/data/v62.0/tooling/composite/sobjects` although this is documented here:

https://developer.salesforce.com/docs/atlas.en-us.api_tooling.meta/api_tooling/tooling_resources_composite_sobjects_collections_delete.htm

Error:

```json
{
  "errorCode": "NOT_FOUND",
  "message": "The requested resource does not exist"
}
```

![Delete Flow Error](https://github.com/user-attachments/assets/d52bc263-ffe5-4c1f-96be-fd7f08c459fb)

For regular SObjects (e.g. `Account`, `Contact`,...) this process works fine using `/services/data/v62.0/composite/sobjects`:

> [!NOTE]
> Mind the slightly different endpoint for Tooling API vs REST API:

```diff
-/services/data/v62.0/tooling/composite/sobjects
+/services/data/v62.0/composite/sobjects
```

https://developer.salesforce.com/docs/atlas.en-us.api_rest.meta/api_rest/resources_composite_sobjects_collections_delete.htm

## Reproduction

Create two SourceMember Tooling API records and attempt to delete them in a composite request:

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
