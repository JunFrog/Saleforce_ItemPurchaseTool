/**
 * AuraEnabled controller for the Item Purchase Tool LWC.
 * Handles item retrieval, picklist options, checkout, and Unsplash image lookup.
 */
public with sharing class ItemPurchaseController {
  /**
   * Returns Account header data (Name, AccountNumber, Industry) for display on the page.
   * @param accountId The Id of the Account record
   * @return AccountHeaderDTO with account details
   */
  @AuraEnabled(cacheable=true)
  public static AccountHeaderDTO getAccountHeader(Id accountId) {
    try {
      Account acc = [
        SELECT Id, Name, AccountNumber, Industry
        FROM Account
        WHERE Id = :accountId
        WITH USER_MODE
        LIMIT 1
      ];
      return new AccountHeaderDTO(acc);
    } catch (Exception e) {
      throw new AuraHandledException(
        'Unable to load account: ' + e.getMessage()
      );
    }
  }

  /**
   * Returns filtered list of Items based on search term, type and family filters.
   * @param searchTerm Text to match against Name and Description
   * @param typeFilter Selected Type picklist value (empty = all)
   * @param familyFilter Selected Family picklist value (empty = all)
   * @return List of ItemDTO
   */
  @AuraEnabled(cacheable=true)
  public static List<ItemDTO> getItems(
    String searchTerm,
    String typeFilter,
    String familyFilter
  ) {
    try {
      String query = 'SELECT Id, Name, Description__c, Type__c, Family__c, Image__c, Price__c FROM Item__c';
      List<String> conditions = new List<String>();
      if (!String.isBlank(typeFilter)) {
        conditions.add('Type__c = :typeFilter');
      }
      if (!String.isBlank(familyFilter)) {
        conditions.add('Family__c = :familyFilter');
      }
      if (!conditions.isEmpty()) {
        query += ' WHERE ' + String.join(conditions, ' AND ');
      }
      query += ' WITH USER_MODE ORDER BY Name';
      List<Item__c> items = Database.query(query);
      List<ItemDTO> result = new List<ItemDTO>();
      String normalizedSearch = String.isBlank(searchTerm)
        ? null
        : searchTerm.toLowerCase();
      for (Item__c item : items) {
        if (matchesSearch(item, normalizedSearch)) {
          result.add(new ItemDTO(item));
        }
      }
      return result;
    } catch (Exception e) {
      throw new AuraHandledException('Unable to load items: ' + e.getMessage());
    }
  }

  private static Boolean matchesSearch(Item__c item, String normalizedSearch) {
    if (String.isBlank(normalizedSearch)) {
      return true;
    }
    String itemName = item.Name == null ? '' : item.Name.toLowerCase();
    String description = item.Description__c == null
      ? ''
      : item.Description__c.toLowerCase();
    return itemName.contains(normalizedSearch) ||
      description.contains(normalizedSearch);
  }

  /**
   * Returns picklist values for Item Type and Family fields.
   * @return PicklistOptionsDTO containing type and family values
   */
  @AuraEnabled(cacheable=true)
  public static PicklistOptionsDTO getPicklistOptions() {
    try {
      List<String> typeValues = new List<String>();
      List<String> familyValues = new List<String>();
      Schema.DescribeFieldResult typeField = Item__c.Type__c.getDescribe();
      for (Schema.PicklistEntry entry : typeField.getPicklistValues()) {
        if (entry.isActive()) {
          typeValues.add(entry.getLabel());
        }
      }
      Schema.DescribeFieldResult familyField = Item__c.Family__c.getDescribe();
      for (Schema.PicklistEntry entry : familyField.getPicklistValues()) {
        if (entry.isActive()) {
          familyValues.add(entry.getLabel());
        }
      }
      return new PicklistOptionsDTO(typeValues, familyValues);
    } catch (Exception e) {
      throw new AuraHandledException(
        'Unable to load picklist options: ' + e.getMessage()
      );
    }
  }

  /**
   * Returns whether the running user has IsManager__c = true.
   * @return true if the current user is a manager
   */
  @AuraEnabled(cacheable=true)
  public static Boolean isCurrentUserManager() {
    try {
      User u = [
        SELECT IsManager__c
        FROM User
        WHERE Id = :UserInfo.getUserId()
        WITH USER_MODE
        LIMIT 1
      ];
      return u.IsManager__c == true;
    } catch (Exception e) {
      throw new AuraHandledException(
        'Unable to check manager status: ' + e.getMessage()
      );
    }
  }

  /**
   * Creates a Purchase with Purchase Lines from the cart and returns the new Purchase Id.
   * @param accountId The Account Id to link the purchase to
   * @param cartItems JSON-serialized list of CartItemDTO
   * @return Id of the newly created Purchase__c record
   */
  @AuraEnabled
  public static Id checkout(Id accountId, List<CartItemDTO> cartItems) {
    try {
      return PurchaseService.createPurchase(accountId, cartItems);
    } catch (PurchaseService.PurchaseServiceException e) {
      throw new AuraHandledException(e.getMessage());
    } catch (Exception e) {
      throw new AuraHandledException('Checkout failed: ' + e.getMessage());
    }
  }

  /**
   * Creates a new Item record; manager-only action. Fetches image from Unsplash via named credential.
   * @param itemName Name of the item
   * @param description Description
   * @param typeValue Type picklist value
   * @param familyValue Family picklist value
   * @param price Unit price
   * @return Id of the created Item__c
   */
  @AuraEnabled
  public static Id createItem(
    String itemName,
    String description,
    String typeValue,
    String familyValue,
    Decimal price
  ) {
    try {
      if (!isCurrentUserManager()) {
        throw new AuraHandledException(
          'You do not have permission to create items.'
        );
      }
      String imageUrl = UnsplashService.getImageUrl(itemName);
      Item__c newItem = new Item__c(
        Name = itemName,
        Description__c = description,
        Type__c = typeValue,
        Family__c = familyValue,
        Price__c = price,
        Image__c = imageUrl
      );
      insert as user newItem;
      return newItem.Id;
    } catch (AuraHandledException e) {
      throw e;
    } catch (Exception e) {
      throw new AuraHandledException(
        'Failed to create item: ' + e.getMessage()
      );
    }
  }

  // Inner DTOs

  /** DTO for Account header display */
  public class AccountHeaderDTO {
    @AuraEnabled
    public String name;
    @AuraEnabled
    public String accountNumber;
    @AuraEnabled
    public String industry;

    public AccountHeaderDTO(Account acc) {
      this.name = acc.Name;
      this.accountNumber = acc.AccountNumber;
      this.industry = acc.Industry;
    }
  }

  /** DTO for Item catalog tiles */
  public class ItemDTO {
    @AuraEnabled
    public Id itemId;
    @AuraEnabled
    public String name;
    @AuraEnabled
    public String description;
    @AuraEnabled
    public String itemType;
    @AuraEnabled
    public String family;
    @AuraEnabled
    public String imageUrl;
    @AuraEnabled
    public Decimal price;

    public ItemDTO(Item__c item) {
      this.itemId = item.Id;
      this.name = item.Name;
      this.description = item.Description__c;
      this.itemType = item.Type__c;
      this.family = item.Family__c;
      this.imageUrl = item.Image__c;
      this.price = item.Price__c;
    }
  }

  /** DTO for picklist options */
  public class PicklistOptionsDTO {
    @AuraEnabled
    public List<String> typeValues;
    @AuraEnabled
    public List<String> familyValues;

    public PicklistOptionsDTO(
      List<String> typeValues,
      List<String> familyValues
    ) {
      this.typeValues = typeValues;
      this.familyValues = familyValues;
    }
  }

  /** DTO for a cart item passed in from LWC during checkout */
  public class CartItemDTO {
    @AuraEnabled
    public Id itemId { get; set; }
    @AuraEnabled
    public Integer amount { get; set; }
    @AuraEnabled
    public Decimal unitCost { get; set; }
  }
}
