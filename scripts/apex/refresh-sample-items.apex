Map<String, List<String>> itemValuesByName = new Map<String, List<String>>{
    '4K Monitor' => new List<String>{ 'Computers', 'Displays' },
    'Apple MacBook Pro' => new List<String>{ 'Computers', 'Electronics' },
    'Coffee Machine' => new List<String>{ 'Appliances', 'Kitchen' },
    'Office Chair' => new List<String>{ 'Furniture', 'Office' },
    'Standing Desk' => new List<String>{ 'Furniture', 'Office' },
    'Wireless Headphones' => new List<String>{ 'Accessories', 'Electronics' }
};

List<Item__c> itemsToUpdate = new List<Item__c>();
for (Item__c item : [
    SELECT Id, Name, Type__c, Family__c
    FROM Item__c
    WHERE Name IN :itemValuesByName.keySet()
]) {
    List<String> values = itemValuesByName.get(item.Name);
    item.Type__c = values[0];
    item.Family__c = values[1];
    itemsToUpdate.add(item);
}

if (!itemsToUpdate.isEmpty()) {
    update itemsToUpdate;
}
