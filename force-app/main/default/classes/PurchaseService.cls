/**
 * Service class responsible for creating Purchase and PurchaseLine records during checkout.
 */
public with sharing class PurchaseService {
  public class PurchaseServiceException extends Exception {
  }

  /**
   * Creates a Purchase__c with its child PurchaseLine__c records in a single transaction.
   * @param accountId Account linked to the purchase
   * @param cartItems List of items in the cart with amount and unit cost
   * @return Id of the created Purchase__c
   * @throws PurchaseServiceException if cartItems is empty, null, or contains invalid lines
   */
  public static Id createPurchase(
    Id accountId,
    List<ItemPurchaseController.CartItemDTO> cartItems
  ) {
    if (cartItems == null || cartItems.isEmpty()) {
      throw new PurchaseServiceException('Cart cannot be empty.');
    }

    Purchase__c purchase = new Purchase__c(
      ClientId__c = accountId,
      TotalItems__c = 0,
      GrandTotal__c = 0
    );
    insert as user purchase;

    List<PurchaseLine__c> lines = new List<PurchaseLine__c>();
    for (ItemPurchaseController.CartItemDTO cartItem : cartItems) {
      validateCartItem(cartItem);
      lines.add(
        new PurchaseLine__c(
          PurchaseId__c = purchase.Id,
          ItemId__c = cartItem.itemId,
          Amount__c = cartItem.amount,
          UnitCost__c = cartItem.unitCost
        )
      );
    }
    insert as user lines;

    return purchase.Id;
  }

  private static void validateCartItem(
    ItemPurchaseController.CartItemDTO cartItem
  ) {
    if (cartItem == null || cartItem.itemId == null) {
      throw new PurchaseServiceException('Cart item is missing an Item Id.');
    }
    if (cartItem.amount == null || cartItem.amount <= 0) {
      throw new PurchaseServiceException(
        'Cart item quantity must be positive.'
      );
    }
    if (cartItem.unitCost == null || cartItem.unitCost < 0) {
      throw new PurchaseServiceException('Cart item unit cost is invalid.');
    }
  }
}
