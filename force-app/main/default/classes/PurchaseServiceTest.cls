@IsTest
private class PurchaseServiceTest {
  @TestSetup
  static void setup() {
    Account acc = new Account(Name = 'Service Test Account');
    insert acc;

    Item__c item = new Item__c(
      Name = 'Service Test Item',
      Type__c = 'Computers',
      Family__c = 'Electronics',
      Price__c = 25.00
    );
    insert item;

    System.runAs(new User(Id = UserInfo.getUserId())) {
      ItemPurchaseTestAccess.assign(UserInfo.getUserId());
    }
  }

  @IsTest
  static void testCreatePurchase_validCart_createsPurchaseAndLines() {
    Account acc = [SELECT Id FROM Account LIMIT 1];
    Item__c item = [SELECT Id FROM Item__c LIMIT 1];

    ItemPurchaseController.CartItemDTO dto = new ItemPurchaseController.CartItemDTO();
    dto.itemId = item.Id;
    dto.amount = 3;
    dto.unitCost = 25.00;

    Test.startTest();
    Id purchaseId = PurchaseService.createPurchase(
      acc.Id,
      new List<ItemPurchaseController.CartItemDTO>{ dto }
    );
    Test.stopTest();

    System.assertNotEquals(null, purchaseId);

    List<PurchaseLine__c> lines = [
      SELECT Id
      FROM PurchaseLine__c
      WHERE PurchaseId__c = :purchaseId
    ];
    System.assertEquals(1, lines.size());

    Purchase__c purchase = [
      SELECT TotalItems__c, GrandTotal__c
      FROM Purchase__c
      WHERE Id = :purchaseId
    ];
    System.assertEquals(3, purchase.TotalItems__c);
    System.assertEquals(75.00, purchase.GrandTotal__c);
  }

  @IsTest
  static void testCreatePurchase_emptyCart_throwsException() {
    Account acc = [SELECT Id FROM Account LIMIT 1];

    Test.startTest();
    try {
      PurchaseService.createPurchase(
        acc.Id,
        new List<ItemPurchaseController.CartItemDTO>()
      );
      System.assert(false, 'Expected PurchaseServiceException');
    } catch (PurchaseService.PurchaseServiceException e) {
      System.assertEquals('Cart cannot be empty.', e.getMessage());
    }
    Test.stopTest();
  }

  @IsTest
  static void testCreatePurchase_nullCart_throwsException() {
    Account acc = [SELECT Id FROM Account LIMIT 1];

    Test.startTest();
    try {
      PurchaseService.createPurchase(acc.Id, null);
      System.assert(false, 'Expected PurchaseServiceException');
    } catch (PurchaseService.PurchaseServiceException e) {
      System.assertEquals('Cart cannot be empty.', e.getMessage());
    }
    Test.stopTest();
  }

  @IsTest
  static void testCreatePurchase_missingItem_throwsException() {
    Account acc = [SELECT Id FROM Account LIMIT 1];

    ItemPurchaseController.CartItemDTO dto = new ItemPurchaseController.CartItemDTO();
    dto.amount = 1;
    dto.unitCost = 10.00;

    Test.startTest();
    try {
      PurchaseService.createPurchase(
        acc.Id,
        new List<ItemPurchaseController.CartItemDTO>{ dto }
      );
      System.assert(false, 'Expected PurchaseServiceException');
    } catch (PurchaseService.PurchaseServiceException e) {
      System.assertEquals('Cart item is missing an Item Id.', e.getMessage());
    }
    Test.stopTest();
  }

  @IsTest
  static void testCreatePurchase_multipleLines_allCreated() {
    Account acc = [SELECT Id FROM Account LIMIT 1];
    Item__c item = [SELECT Id FROM Item__c LIMIT 1];

    List<ItemPurchaseController.CartItemDTO> cartItems = new List<ItemPurchaseController.CartItemDTO>();
    for (Integer i = 0; i < 5; i++) {
      ItemPurchaseController.CartItemDTO dto = new ItemPurchaseController.CartItemDTO();
      dto.itemId = item.Id;
      dto.amount = i + 1;
      dto.unitCost = 10.00;
      cartItems.add(dto);
    }

    Test.startTest();
    Id purchaseId = PurchaseService.createPurchase(acc.Id, cartItems);
    Test.stopTest();

    List<PurchaseLine__c> lines = [
      SELECT Id
      FROM PurchaseLine__c
      WHERE PurchaseId__c = :purchaseId
    ];
    System.assertEquals(5, lines.size());

    Purchase__c purchase = [
      SELECT TotalItems__c, GrandTotal__c
      FROM Purchase__c
      WHERE Id = :purchaseId
    ];
    System.assertEquals(15, purchase.TotalItems__c);
    System.assertEquals(150.00, purchase.GrandTotal__c);
  }
}
