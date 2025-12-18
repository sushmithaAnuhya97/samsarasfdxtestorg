trigger ManuallyAssignToRoundRobin on Contact (after update) {
     User pool = [select Id from User where Name = 'SFDC Pool'];
     
     for(Contact c: Trigger.new){
         if(c.Send_to_Round_Robin__c == 'Routed') {
            return;
         }
         
         System.debug('Starting Manually Assign to Round Robin trigger....');
         // need to handle when event lead is already owned by someone, return this field to ''.
         System.debug(c.OwnerId);
         
         if(c.Send_to_Round_Robin__c == 'Cold call' && c.OwnerId == pool.Id && (Trigger.oldMap.get( c.Id ).Send_to_Round_Robin__c != Trigger.newMap.get( c.Id ).Send_to_Round_Robin__c)) {
             
             List<Account> accounts = [SELECT Name, Id, BillingCountry, Organization_Size__c, Number_of_Vehicles__c, Canada_Geography__c, Global_Geography__c, Enterprise_Assignment__c from Account WHERE Id =: c.accountid LIMIT 1];
         
             System.debug('Registered as newly set to cold call');
             List<User> users = New List<User>();
             System.debug('1');
             if(c.Account.Number_of_Vehicles__c <= 20) {
                 users = [SELECT Name, Id FROM User WHERE IsActive = True AND Enable_Cold_Call_Leads__c = True AND Geography__c =: c.Geography__c AND UserRole.Name LIKE '%SMB%' ORDER BY Last_Cold_Call_Transfer_Date__c LIMIT 1];
                 System.debug('2');
             }
             else {
                 users = [SELECT Name, Id FROM User WHERE IsActive = True AND Enable_Cold_Call_Leads__c = True AND Geography__c =: c.Geography__c AND UserRole.Name LIKE '%MM%' ORDER BY Last_Cold_Call_Transfer_Date__c LIMIT 1];                 
                 System.debug('3');                 
             }
             if(users.size() > 0) {

                accounts[0].ownerid = users[0].id;
                users[0].Last_Cold_Call_Transfer_Date__c  = System.now();
                update users[0];
                update accounts[0];
                Contact copyOfC = new Contact(ID=c.id);
                copyOfC.Send_to_Round_Robin__c = 'Routed'; // change to '' after fire is put out      
                copyOfC.ownerid = users[0].id;        
                update copyOfC;
                // Find all contacts associated with the accounts and change their ownership
                //List<Contact> associatedContacts = [SELECT Name, Id FROM Contact WHERE AccountId =: c.AccountId];
                //for(Contact associatedContact: associatedContacts) {
                //    associatedContact.ownerid = users[0].id;
                //}
                //update associatedContacts;
             }
             else {
                 User Priscilla = [SELECT Id FROM User WHERE Name = 'Priscilla Liu'];
                 Contact copyOfC = new Contact(ID=c.id);
                 copyOfC.Send_to_Round_Robin__c = 'Routed'; // change to '' after fire is put out       
                 copyOfC.ownerid = Priscilla.Id;
                 accounts[0].ownerid = Priscilla.Id;        
                 update copyOfC;
                 update accounts[0];
             }
         }
         else if((c.Send_to_Round_Robin__c == 'Events' || c.Send_to_Round_Robin__c == 'Events - Red' || c.Send_to_Round_Robin__c == 'Events - Blue') && c.OwnerId == pool.Id && (Trigger.oldMap.get( c.Id ).Send_to_Round_Robin__c != Trigger.newMap.get( c.Id ).Send_to_Round_Robin__c)) {
            
            List<Account> accounts = [SELECT Name, Id, BillingCountry, Organization_Size__c, Number_of_Vehicles__c, Canada_Geography__c, Global_Geography__c, Enterprise_Assignment__c from Account WHERE Id =: c.accountid LIMIT 1];
         
            String event_team='';
            if(c.Send_to_Round_Robin__c=='Events - Red'){
                event_team='Team Red';
            }
            else if(c.Send_to_Round_Robin__c=='Events - Blue'){
                event_team='Team Blue';
            }
            
            System.debug('Registered as newly set to events');
             List<User> users = New List<User>();
             List<String> eurCountries = new List<String>();
                eurCountries.add('United Kingdom');
                eurCountries.add('Ireland');
                eurCountries.add('France');
                eurCountries.add('Germany');
                eurCountries.add('Spain');
                eurCountries.add('Italy');
                eurCountries.add('Netherlands');
                eurCountries.add('Belgium');
                eurCountries.add('Switzerland');
             
             // only send subb 20 vehicle events thru this logic if they are Mexico, UK, France or Germany
             if((accounts[0].Number_of_Vehicles__c <= 20) && (accounts[0].BillingCountry == 'Mexico' || 
                        accounts[0].BillingCountry == 'United Kingdom' || accounts[0].BillingCountry == 'France' || accounts[0].BillingCountry == 'Germany')){
                 if(accounts[0].BillingCountry=='Mexico'){
                    users = [SELECT Name, Id FROM User WHERE Role_Start_Date__c < LAST_N_DAYS:30 AND IsActive = True AND UserRole.Name LIKE '%MM%' AND UserRole.Name LIKE '%MX%' AND UserRole.Name LIKE '%ADR%' ORDER BY Last_Event_Transfer_Date__c LIMIT 1];
                 }
                 if(accounts[0].BillingCountry=='United Kingdom'){
                     users = [SELECT Name, Id FROM User WHERE Role_Start_Date__c < LAST_N_DAYS:30 AND IsActive = True AND Entity__c='Samsara UK' AND UserRole.Name LIKE '%UK%'  AND UserRole.Name LIKE '%MM%' AND UserRole.Name LIKE '%ADR%' ORDER BY Last_Event_Transfer_Date__c LIMIT 1];                 
                 }
                 if(accounts[0].BillingCountry=='France'){
                  users = [SELECT Name, Id FROM User WHERE Role_Start_Date__c < LAST_N_DAYS:30 AND IsActive = True AND Entity__c='Samsara UK' AND UserRole.Name LIKE '%FR%' AND UserRole.Name LIKE '%MM%' AND UserRole.Name LIKE '%ADR%' ORDER BY Last_Event_Transfer_Date__c LIMIT 1];                 
                 }
                 if(accounts[0].BillingCountry=='Germany'){
                  users = [SELECT Name, Id FROM User WHERE Role_Start_Date__c < LAST_N_DAYS:30 AND IsActive = True AND Entity__c='Samsara UK' AND UserRole.Name LIKE '%DE%' AND UserRole.Name LIKE '%MM%' AND UserRole.Name LIKE '%ADR%' ORDER BY Last_Event_Transfer_Date__c LIMIT 1];                 
                 }
             }
             // enterprise logic for event round robin
             // as of 4/24/19 we're just sending ent leads to respective sales ops members
             else if (accounts[0].Number_of_Vehicles__c > 20 && 
                        ((accounts[0].Organization_Size__c == '1000 - 4999' || accounts[0].Organization_Size__c == '5000+') ||
                            (accounts[0].Enterprise_Assignment__c != null))){
                
                if(eurCountries.contains(accounts[0].BillingCountry)){
                    // if the country is a european country send to mackenzie
                    users = [select Id from User where Name = 'Mackenzie Ring' LIMIT 1];    
                }
                else {
                    // otherwise send to mikey 
                    users = [select Id from User where Name = 'Mikey Hlebasko' LIMIT 1];
                }
             }
             else {    
                    users = [SELECT Name, Id FROM User WHERE Role_Start_Date__c < LAST_N_DAYS:30 AND IsActive = True AND Geography__c =: c.Geography__c AND UserRole.Name LIKE '%MM%' AND UserRole.Name LIKE '%ADR%' ORDER BY Last_Event_Transfer_Date__c LIMIT 1];                 
                    if(accounts[0].BillingCountry=='Canada'){
                     users = [SELECT Name, Id FROM User WHERE Role_Start_Date__c < LAST_N_DAYS:30 AND IsActive = True AND Geography__c =: accounts[0].Global_Geography__c AND UserRole.Name LIKE '%MM%' AND UserRole.Name LIKE '%ADR%' ORDER BY Last_Event_Transfer_Date__c LIMIT 1];                 
                    }
                    if(accounts[0].BillingCountry=='Mexico'){
                     users = [SELECT Name, Id FROM User WHERE Role_Start_Date__c < LAST_N_DAYS:30 AND IsActive = True AND UserRole.Name LIKE '%MM%' AND UserRole.Name LIKE '%MX%' AND UserRole.Name LIKE '%ADR%' ORDER BY Last_Event_Transfer_Date__c LIMIT 1];                 
                    }
                    if(accounts[0].BillingCountry=='United Kingdom'){
                     users = [SELECT Name, Id FROM User WHERE Role_Start_Date__c < LAST_N_DAYS:30 AND IsActive = True AND Entity__c='Samsara UK' AND UserRole.Name LIKE '%UK%'  AND UserRole.Name LIKE '%MM%' AND UserRole.Name LIKE '%ADR%' ORDER BY Last_Event_Transfer_Date__c LIMIT 1];                 
                    }
                    if(accounts[0].BillingCountry=='France'){
                     users = [SELECT Name, Id FROM User WHERE Role_Start_Date__c < LAST_N_DAYS:30 AND IsActive = True AND Entity__c='Samsara UK' AND UserRole.Name LIKE '%FR%' AND UserRole.Name LIKE '%MM%' AND UserRole.Name LIKE '%ADR%' ORDER BY Last_Event_Transfer_Date__c LIMIT 1];                 
                    }
                    if(accounts[0].BillingCountry=='Germany'){
                     users = [SELECT Name, Id FROM User WHERE Role_Start_Date__c < LAST_N_DAYS:30 AND IsActive = True AND Entity__c='Samsara UK' AND UserRole.Name LIKE '%DE%' AND UserRole.Name LIKE '%MM%' AND UserRole.Name LIKE '%ADR%' ORDER BY Last_Event_Transfer_Date__c LIMIT 1];                 
                    }
             }
             if(users.size() > 0) {
                System.debug('7');               
                accounts[0].ownerid = users[0].id;
                users[0].Last_Event_Transfer_Date__c  = System.now();
                update users[0];
                update accounts[0];
                Contact copyOfC = new Contact(ID=c.id);
                copyOfC.Send_to_Round_Robin__c = 'Routed'; // change to '' after fire is put out
                copyOfC.ownerid = users[0].id;        
                update copyOfC; 
             }
             else {
                 System.debug('8');               
                 User Rachel = [select Id from User where Name = 'Danielle Durante' LIMIT 1];
                 System.debug('9');                                
                 Contact copyOfC = new Contact(ID=c.id);
                 System.debug('10');                                
                 copyOfC.Send_to_Round_Robin__c = 'Routed'; // change to '' after fire is put out
                 System.debug('11');                                          
                 copyOfC.ownerid = Rachel.Id;
                 System.debug('12');                                
                 System.debug('13');                                
                 accounts[0].ownerid = Rachel.Id;        
                 update copyOfC;
                 update accounts[0];
             }
         }
     }
}