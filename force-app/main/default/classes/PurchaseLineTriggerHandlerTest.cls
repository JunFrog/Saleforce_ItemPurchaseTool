@IsTest
private class PurchaseLineTriggerHandlerTest {
  @TestSetup
  static void setup() {
    Account acc = new Account(Name = 'Trigger Test Account');
    insert acc;

    Purchase__c purchase = new Purchase__c(
      ClientId__c = acc.Id,
      TotalItems__c = 0,
      GrandTotal__c = 0
    );
    insert purchase;

    Item__c item = new Item__c(
      Name = 'Trigger Test Item',
      Type__c = 'Computers',
      Family__c = 'Electronics',
      Price__c = 10.00
    );
    insert item;

    System.runAs(new User(Id = UserInfo.getUserId())) {
      ItemPurchaseTestAccess.assign(UserInfo.getUserId());
    }
  }

  @IsTest
  static void testInsertLines_calculatesRollups() {
    Purchase__c purchase = [SELECT Id FROM Purchase__c LIMIT 1];
    Item__c item = [SELECT Id FROM Item__c LIMIT 1];

    PurchaseLine__c line1 = new PurchaseLine__c(
      PurchaseId__c = purchase.Id,
      ItemId__c = item.Id,
      Amount__c = 2,
      UnitCost__c = 10.00
    );
    PurchaseLine__c line2 = new PurchaseLine__c(
      PurchaseId__c = purchase.Id,
      ItemId__c = item.Id,
      Amount__c = 3,
      UnitCost__c = 5.00
    );

    Test.startTest();
    insert new List<PurchaseLine__c>{ line1, line2 };
    Test.stopTest();

    Purchase__c updated = [
      SELECT TotalItems__c, GrandTotal__c
      FROM Purchase__c
      WHERE Id = :purchase.Id
    ];
    System.assertEquals(5, updated.TotalItems__c);
    System.assertEquals(35.00, updated.GrandTotal__c);
  }

  @IsTest
  static void testUpdateLine_recalculatesRollups() {
    Purchase__c purchase = [SELECT Id FROM Purchase__c LIMIT 1];
    Item__c item = [SELECT Id FROM Item__c LIMIT 1];

    PurchaseLine__c line = new PurchaseLine__c(
      PurchaseId__c = purchase.Id,
      ItemId__c = item.Id,
      Amount__c = 2,
      UnitCost__c = 10.00
    );
    insert line;

    Test.startTest();
    line.Amount__c = 5;
    update line;
    Test.stopTest();

    Purchase__c updated = [
      SELECT TotalItems__c, GrandTotal__c
      FROM Purchase__c
      WHERE Id = :purchase.Id
    ];
    System.assertEquals(5, updated.TotalItems__c);
    System.assertEquals(50.00, updated.GrandTotal__c);
  }

  @IsTest
  static void testDeleteLine_resetsRollups() {
    Purchase__c purchase = [SELECT Id FROM Purchase__c LIMIT 1];
    Item__c item = [SELECT Id FROM Item__c LIMIT 1];

    PurchaseLine__c line = new PurchaseLine__c(
      PurchaseId__c = purchase.Id,
      ItemId__c = item.Id,
      Amount__c = 2,
      UnitCost__c = 10.00
    );
    insert line;

    Test.startTest();
    delete line;
    Test.stopTest();

    Purchase__c updated = [
      SELECT TotalItems__c, GrandTotal__c
      FROM Purchase__c
      WHERE Id = :purchase.Id
    ];
    System.assertEquals(0, updated.TotalItems__c);
    System.assertEquals(0, updated.GrandTotal__c);
  }

  @IsTest
  static void testUndeleteLines_recalculatesRollups() {
    Purchase__c purchase = [SELECT Id FROM Purchase__c LIMIT 1];
    Item__c item = [SELECT Id FROM Item__c LIMIT 1];

    PurchaseLine__c line = new PurchaseLine__c(
      PurchaseId__c = purchase.Id,
      ItemId__c = item.Id,
      Amount__c = 4,
      UnitCost__c = 5.00
    );
    insert line;
    delete line;

    Test.startTest();
    undelete line;
    Test.stopTest();

    Purchase__c updated = [
      SELECT TotalItems__c, GrandTotal__c
      FROM Purchase__c
      WHERE Id = :purchase.Id
    ];
    System.assertEquals(4, updated.TotalItems__c);
    System.assertEquals(20.00, updated.GrandTotal__c);
  }

  @IsTest
  static void testInsertLinesWithNullAmount_handledGracefully() {
    Purchase__c purchase = [SELECT Id FROM Purchase__c LIMIT 1];
    Item__c item = [SELECT Id FROM Item__c LIMIT 1];

    PurchaseLine__c line = new PurchaseLine__c(
      PurchaseId__c = purchase.Id,
      ItemId__c = item.Id,
      Amount__c = null,
      UnitCost__c = null
    );

    Test.startTest();
    insert line;
    Test.stopTest();

    Purchase__c updated = [
      SELECT TotalItems__c, GrandTotal__c
      FROM Purchase__c
      WHERE Id = :purchase.Id
    ];
    System.assertEquals(0, updated.TotalItems__c);
    System.assertEquals(0, updated.GrandTotal__c);
  }
}
