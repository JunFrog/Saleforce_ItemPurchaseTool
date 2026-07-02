/**
 * Handler for PurchaseLineTrigger. Recalculates TotalItems and GrandTotal
 * on the parent Purchase__c whenever purchase lines are inserted, updated, deleted, or undeleted.
 */
public with sharing class PurchaseLineTriggerHandler {
  /**
   * Entry point called by PurchaseLineTrigger.
   * @param newLines Trigger.new (null on delete)
   * @param oldLines Trigger.old (null on insert/undelete)
   * @param newMap Trigger.newMap
   * @param oldMap Trigger.oldMap
   * @param operationType Trigger.operationType
   */
  public static void handle(
    List<PurchaseLine__c> newLines,
    List<PurchaseLine__c> oldLines,
    Map<Id, PurchaseLine__c> newMap,
    Map<Id, PurchaseLine__c> oldMap,
    System.TriggerOperation operationType
  ) {
    Set<Id> purchaseIds = collectPurchaseIds(newLines, oldLines);
    if (purchaseIds.isEmpty()) {
      return;
    }
    recalculatePurchases(purchaseIds);
  }

  private static Set<Id> collectPurchaseIds(
    List<PurchaseLine__c> newLines,
    List<PurchaseLine__c> oldLines
  ) {
    Set<Id> ids = new Set<Id>();
    if (newLines != null) {
      for (PurchaseLine__c line : newLines) {
        if (line.PurchaseId__c != null) {
          ids.add(line.PurchaseId__c);
        }
      }
    }
    if (oldLines != null) {
      for (PurchaseLine__c line : oldLines) {
        if (line.PurchaseId__c != null) {
          ids.add(line.PurchaseId__c);
        }
      }
    }
    return ids;
  }

  private static void recalculatePurchases(Set<Id> purchaseIds) {
    List<PurchaseLine__c> allLines = [
      SELECT PurchaseId__c, Amount__c, UnitCost__c
      FROM PurchaseLine__c
      WHERE PurchaseId__c IN :purchaseIds
    ];

    Map<Id, Decimal> countByPurchase = new Map<Id, Decimal>();
    Map<Id, Decimal> totalByPurchase = new Map<Id, Decimal>();
    for (Id pid : purchaseIds) {
      countByPurchase.put(pid, 0);
      totalByPurchase.put(pid, 0);
    }
    for (PurchaseLine__c line : allLines) {
      Id pid = line.PurchaseId__c;
      Decimal amt = line.Amount__c != null ? line.Amount__c : 0;
      Decimal cost = line.UnitCost__c != null ? line.UnitCost__c : 0;
      countByPurchase.put(pid, countByPurchase.get(pid) + amt);
      totalByPurchase.put(pid, totalByPurchase.get(pid) + (amt * cost));
    }

    List<Purchase__c> purchasesToUpdate = new List<Purchase__c>();
    for (Id purchaseId : purchaseIds) {
      purchasesToUpdate.add(
        new Purchase__c(
          Id = purchaseId,
          TotalItems__c = countByPurchase.get(purchaseId),
          GrandTotal__c = totalByPurchase.get(purchaseId)
        )
      );
    }

    if (!purchasesToUpdate.isEmpty()) {
      update purchasesToUpdate;
    }
  }
}
