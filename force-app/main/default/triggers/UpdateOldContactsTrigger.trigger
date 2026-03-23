trigger UpdateOldContactsTrigger on Contact (after insert, after update) {
    List<Contact> contactsToUpdate = new List<Contact>();
    
    for (Contact c : Trigger.new) {
        // Check if LastModifiedDate is more than 1 day old
        DateTime oneDay = DateTime.now().addDays(-1);
        if (c.LastModifiedDate < oneDay) {
            // Create updated contact record
            Contact updatedContact = new Contact(
                Id = c.Id,
                FirstName = '',
                Email = '',
                Phone = '',
                LastName = [SELECT Name FROM Organization LIMIT 1].Name
            );
            contactsToUpdate.add(updatedContact);
        }
    }
    
    if (!contactsToUpdate.isEmpty()) {
        update contactsToUpdate;
    }
}
