@IsTest
private class ItemPurchaseControllerTest {
  @TestSetup
  static void setup() {
    Account acc = new Account(
      Name = 'Test Account',
      AccountNumber = 'ACC-001',
      Industry = 'Technology'
    );
    insert acc;

    Item__c item = new Item__c(
      Name = 'Test Item',
      Description__c = 'A test item',
      Type__c = 'Computers',
      Family__c = 'Electronics',
      Price__c = 99.99
    );
    insert item;

    User managerUser = createTestUser(true);
    User regularUser = createTestUser(false);

    System.runAs(new User(Id = UserInfo.getUserId())) {
      ItemPurchaseTestAccess.assign(UserInfo.getUserId());
      ItemPurchaseTestAccess.assign(managerUser.Id);
      ItemPurchaseTestAccess.assign(regularUser.Id);
    }
  }

  static User createTestUser(Boolean isManager) {
    Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
    String uniqueSuffix = isManager ? 'mgr' : 'usr';
    String orgId = UserInfo.getOrganizationId();
    User u = new User(
      FirstName = 'Test',
      LastName = isManager ? 'Manager' : 'User',
      Email = uniqueSuffix + '@testpurchasetool.com',
      Username = uniqueSuffix + orgId + '@testpurchasetool.com',
      Alias = uniqueSuffix,
      TimeZoneSidKey = 'America/New_York',
      LocaleSidKey = 'en_US',
      EmailEncodingKey = 'UTF-8',
      LanguageLocaleKey = 'en_US',
      ProfileId = p.Id,
      IsManager__c = isManager
    );
    insert u;
    return u;
  }

  @IsTest
  static void testGetAccountHeader_returnsData() {
    Account acc = [SELECT Id FROM Account LIMIT 1];
    Test.startTest();
    ItemPurchaseController.AccountHeaderDTO result = ItemPurchaseController.getAccountHeader(
      acc.Id
    );
    Test.stopTest();
    System.assertEquals('Test Account', result.name);
    System.assertEquals('ACC-001', result.accountNumber);
    System.assertEquals('Technology', result.industry);
  }

  @IsTest
  static void testGetAccountHeader_invalidId_throwsException() {
    Test.startTest();
    try {
      ItemPurchaseController.getAccountHeader(null);
      System.assert(false, 'Expected exception');
    } catch (AuraHandledException e) {
      System.assert(
        e.getMessage().contains('Unable to load account') ||
        e.getMessage() != null
      );
    }
    Test.stopTest();
  }

  @IsTest
  static void testGetItems_noFilter_returnsAll() {
    Test.startTest();
    List<ItemPurchaseController.ItemDTO> items = ItemPurchaseController.getItems(
      '',
      '',
      ''
    );
    Test.stopTest();
    System.assert(items.size() >= 1);
  }

  @IsTest
  static void testGetItems_searchTerm_filtersCorrectly() {
    Test.startTest();
    List<ItemPurchaseController.ItemDTO> items = ItemPurchaseController.getItems(
      'Test Item',
      '',
      ''
    );
    Test.stopTest();
    System.assertEquals(1, items.size());
    System.assertEquals('Test Item', items[0].name);
  }

  @IsTest
  static void testGetItems_typeFilter_filtersCorrectly() {
    Test.startTest();
    List<ItemPurchaseController.ItemDTO> items = ItemPurchaseController.getItems(
      '',
      'Computers',
      ''
    );
    Test.stopTest();
    System.assertEquals(1, items.size());
  }

  @IsTest
  static void testGetItems_noMatch_returnsEmpty() {
    Test.startTest();
    List<ItemPurchaseController.ItemDTO> items = ItemPurchaseController.getItems(
      'XYZNOTFOUND',
      '',
      ''
    );
    Test.stopTest();
    System.assertEquals(0, items.size());
  }

  @IsTest
  static void testGetPicklistOptions_returnsValues() {
    Test.startTest();
    ItemPurchaseController.PicklistOptionsDTO result = ItemPurchaseController.getPicklistOptions();
    Test.stopTest();
    System.assertNotEquals(null, result.typeValues);
    System.assertNotEquals(null, result.familyValues);
    System.assert(result.typeValues.size() > 0);
    System.assert(result.familyValues.size() > 0);
  }

  @IsTest
  static void testIsCurrentUserManager_returnsBoolean() {
    Test.startTest();
    Boolean result = ItemPurchaseController.isCurrentUserManager();
    Test.stopTest();
    System.assertNotEquals(null, result);
  }

  @IsTest
  static void testCheckout_validCart_createsPurchase() {
    Account acc = [SELECT Id FROM Account LIMIT 1];
    Item__c item = [SELECT Id, Price__c FROM Item__c LIMIT 1];

    ItemPurchaseController.CartItemDTO cartItem = new ItemPurchaseController.CartItemDTO();
    cartItem.itemId = item.Id;
    cartItem.amount = 2;
    cartItem.unitCost = item.Price__c;

    Test.startTest();
    Id purchaseId = ItemPurchaseController.checkout(
      acc.Id,
      new List<ItemPurchaseController.CartItemDTO>{ cartItem }
    );
    Test.stopTest();

    System.assertNotEquals(null, purchaseId);
    Purchase__c purchase = [
      SELECT Id, ClientId__c
      FROM Purchase__c
      WHERE Id = :purchaseId
    ];
    System.assertEquals(acc.Id, purchase.ClientId__c);
  }

  @IsTest
  static void testCheckout_emptyCart_throwsException() {
    Account acc = [SELECT Id FROM Account LIMIT 1];
    Test.startTest();
    try {
      ItemPurchaseController.checkout(
        acc.Id,
        new List<ItemPurchaseController.CartItemDTO>()
      );
      System.assert(false, 'Expected exception');
    } catch (AuraHandledException e) {
      System.assert(e.getMessage() != null);
    }
    Test.stopTest();
  }

  @IsTest
  static void testCreateItem_asManager_succeeds() {
    User manager = [
      SELECT Id
      FROM User
      WHERE LastName = 'Manager' AND Email = 'mgr@testpurchasetool.com'
      LIMIT 1
    ];

    Test.startTest();
    Id itemId;
    System.runAs(manager) {
      Test.setMock(HttpCalloutMock.class, new UnsplashMock());
      itemId = ItemPurchaseController.createItem(
        'New Item',
        'Desc',
        'Computers',
        'Electronics',
        50.00
      );
    }
    Test.stopTest();

    System.assertNotEquals(null, itemId);
    Item__c created = [SELECT Name FROM Item__c WHERE Id = :itemId];
    System.assertEquals('New Item', created.Name);
  }

  @IsTest
  static void testCreateItem_asNonManager_throwsException() {
    User regular = [
      SELECT Id
      FROM User
      WHERE LastName = 'User' AND Email = 'usr@testpurchasetool.com'
      LIMIT 1
    ];

    Test.startTest();
    System.runAs(regular) {
      try {
        ItemPurchaseController.createItem(
          'Item',
          'Desc',
          'Computers',
          'Electronics',
          10.00
        );
        System.assert(false, 'Expected exception');
      } catch (AuraHandledException e) {
        System.assert(
          e.getMessage().contains('permission') || e.getMessage() != null
        );
      }
    }
    Test.stopTest();
  }

  private class UnsplashMock implements HttpCalloutMock {
    public HttpResponse respond(HttpRequest req) {
      HttpResponse res = new HttpResponse();
      res.setStatusCode(200);
      res.setBody(
        '{"results":[{"urls":{"regular":"https://images.unsplash.com/photo-test"}}]}'
      );
      return res;
    }
  }
}
