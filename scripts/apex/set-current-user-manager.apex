User currentUser = new User(
    Id = UserInfo.getUserId(),
    IsManager__c = true
);
update currentUser;
