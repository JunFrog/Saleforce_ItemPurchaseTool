# Item Purchase Tool

Salesforce DX implementation of the Item Purchase Tool test task.

## What Is Included

- Custom objects: `Item__c`, `Purchase__c`, `PurchaseLine__c`
- Custom user field: `User.IsManager__c`
- LWC one-page purchase tool with Account header, search, filters, item tiles, details modal, cart modal, checkout, and manager-only item creation
- Apex controller, services, trigger, and unit tests
- Account custom button `Item Purchase Tool` that opens the tool in a new browser tab and passes the Account Id
- Named Credential `Unsplash` and custom label `Unsplash_Access_Key`
- Permission set `ItemPurchaseToolAccess`
- Manifest for classic unmanaged package composition: `manifest/package.xml`

## Deploy

Authorize an org if needed:

```bash
sf org login web --alias nam
```

Deploy all metadata and run tests:

```bash
sf project deploy start --source-dir force-app --target-org nam --test-level RunLocalTests
```

Check the latest deploy:

```bash
sf project deploy report --target-org nam --use-most-recent
```

## Access Setup

Assign the permission set:

```bash
sf org assign permset --target-org nam --name ItemPurchaseToolAccess
```

Set the current user as manager if the Create Item button should be visible:

```bash
sf apex run --target-org nam --file scripts/apex/set-current-user-manager.apex
```

If that script is not present, run this anonymous Apex:

```apex
User u = new User(Id = UserInfo.getUserId(), IsManager__c = true);
update u;
```

## Open Correctly

The expected flow is from an Account record:

```bash
sf org open --target-org nam --path "/lightning/o/Account/list?filterName=Recent"
```

Open any Account, then click `Item Purchase Tool` in the Account page actions. Salesforce opens:

```text
/lightning/n/ItemPurchaseTool?c__recordId=<ACCOUNT_ID>
```

Direct test URL example:

```bash
sf org open --target-org nam --path "/lightning/n/ItemPurchaseTool?c__recordId=001fj00001Kvxc5AAB"
```

## Unsplash

The Named Credential points to:

```text
https://api.unsplash.com
```

To make manager-created items receive a live image URL:

1. Create an Unsplash developer app.
2. Copy its Access Key.
3. In Salesforce Setup, open Custom Labels.
4. Replace `Unsplash_Access_Key` value with the real key.

Without a real key, item creation still works, but `Image__c` may be blank if Unsplash rejects the callout.

## Classic Unmanaged Package

The project has `manifest/package.xml` with the components that belong in the package.

Classic unmanaged packages must be created in Salesforce Setup first. After creating the package in Setup, use the generated package id with the CLI:

```bash
sf package1 version create --package-id 033xxxxxxxxxxxx --name "Item Purchase Tool" --target-org nam
```

Omit `--managed-released` to upload an unmanaged package version.

## Verify

Run Apex tests:

```bash
sf apex run test --target-org nam --test-level RunLocalTests --result-format human --code-coverage --wait 10
```

Run LWC lint:

```bash
npm run lint
```
