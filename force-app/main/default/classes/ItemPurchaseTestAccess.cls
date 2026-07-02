@IsTest
public class ItemPurchaseTestAccess {
  public static void assign(Id userId) {
    PermissionSet access = [
      SELECT Id
      FROM PermissionSet
      WHERE Name = 'ItemPurchaseToolAccess'
      LIMIT 1
    ];

    List<PermissionSetAssignment> existingAssignments = [
      SELECT Id
      FROM PermissionSetAssignment
      WHERE AssigneeId = :userId AND PermissionSetId = :access.Id
      LIMIT 1
    ];
    if (existingAssignments.isEmpty()) {
      insert new PermissionSetAssignment(
        AssigneeId = userId,
        PermissionSetId = access.Id
      );
    }
  }
}
