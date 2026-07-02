Account account = [
    SELECT Id
    FROM Account
    WHERE Name = 'Edge Communications'
    LIMIT 1
];

Item__c item = [
    SELECT Id, Price__c
    FROM Item__c
    WHERE Name = '4K Monitor'
    LIMIT 1
];

ItemPurchaseController.CartItemDTO cartItem = new ItemPurchaseController.CartItemDTO();
cartItem.itemId = item.Id;
cartItem.amount = 1;
cartItem.unitCost = item.Price__c;

Id purchaseId = ItemPurchaseController.checkout(
    account.Id,
    new List<ItemPurchaseController.CartItemDTO>{ cartItem }
);

Purchase__c purchase = [
    SELECT Id, ClientId__c, TotalItems__c, GrandTotal__c
    FROM Purchase__c
    WHERE Id = :purchaseId
];

System.debug('SMOKE_PURCHASE_ID=' + purchase.Id);
System.debug('SMOKE_TOTAL_ITEMS=' + purchase.TotalItems__c);
System.debug('SMOKE_GRAND_TOTAL=' + purchase.GrandTotal__c);
