trigger AssignInboundLeadExistingContact on Task (after insert) {
    // for(Task t: Trigger.new){ // trigger assigns to a rep when contact already exists
    //     if(t.Subject != null && (t.Subject.indexOf('Submitted Form') != -1 || t.Subject.indexOf('Clicked') != -1))
    //     {
    //         // if the customer fills out a form, change the source
    //         String sourceFromForm = '';
    //         if (t.Subject.indexOf('Submitted Form') != -1){
    //             String sub = t.Description;
    //             sourceFromForm = sub.substringBetween('Lead Source: ', '\n');
    //         }
            
    //         List<Contact> c = [SELECT Id, Inbound_Form_Message__c, OwnerId, Owner.Name, AccountId, Source__c, Customer_Referral_Email__c FROM Contact WHERE Id = :t.WhoId];
    //         if (c.size()>0){
    //             List<Account> a = [SELECT BillingCountry, Id, OwnerId, Owner.Name, Geography__c, Organization_Size__c, BillingPostalCode, BillingState, Number_of_Vehicles__c, (Select Id, OwnerId From Contacts) FROM Account WHERE Id = :c[0].AccountId];
    //             if (a.size() > 0){
    //                 // if the source is List Import, change to new form source & regardless of the source, if a deal reg lead comes in change the source to deal reg
    //                 if ((c[0].Source__c == 'List Import (no prior engagement)' || sourceFromForm == 'Partner referral' || sourceFromForm == 'Deal Reg Form')  && !String.isBlank(sourceFromForm) && t.Subject.indexOf('Submitted Form') != -1){
    //                     c[0].Source__c = sourceFromForm;
    //                     update c[0];
    //                 }
    //                 if ( c[0].Owner.Name == 'SFDC Pool'){
    //                     try{
                        
    //                         if(c[0].Source__c=='MVF' || t.Subject.indexOf('Clicked') != -1){
    //                             assignRoundRobinContact.setADRInboundRoundRobin(); 
    //                         }
    //                         else{
    //                             // set the round robin
    //                             assignRoundRobinContact.setRoundRobinContact(a[0].BillingCountry, a[0].Geography__c, 'Inbound', a[0].Number_of_Vehicles__c, c[0].Source__c, false, a[0].Organization_Size__c, a[0].BillingPostalCode, a[0].BillingState, c[0].Customer_Referral_Email__c, a[0].Id, c[0].Inbound_Form_Message__c);
    //                         }
                            
    //                         // user needs to be assigned before creation
    //                         System.debug('User Id coming from rounrobin: '+assignRoundRobinContact.selected_user.Id);
                            
    //                         // change the owner of the account
    //                         a[0].OwnerId = assignRoundRobinContact.selected_user.Id;
                            
                            
                            
    //                         // prevent automatic email from triggering when changing owner
    //                         Database.DMLOptions dlo = new Database.DMLOptions();
    //                         dlo.EmailHeader.triggerUserEmail = false;
    //                         dlo.EmailHeader.triggerOtherEmail = false;
    //                         dlo.EmailHeader.triggerAutoResponseEmail = false;
    //                         Database.update(a[0], dlo);
                            
    //                         assignRoundRobinContact.UpdateRoundRobinDate('Inbound');
                            
    //                         // change the owner of the associated contacts
    //                         /*
    //                         List<Contact> lstOfContactToBeUpdated = new List<Contact>();
    //                         for (Contact contact : a[0].Contacts)
    //                         {
    //                              contact.OwnerId = assignRoundRobinContact.selected_user.Id;
    //                              lstOfContactToBeUpdated.add(contact);
    //                         }
    //                         update lstOfContactToBeUpdated;
    //                         */
    //                         // update user
                            
                            
    //                         // send email
                            
    //                         User toUser = [select Id, Email, FirstName, Last_Inbound_Transfer_Date__c,Last_Inbound_Transfer_Id__c, Last_Partner_Transfer_Date__c, Last_Partner_Transfer_Id__c from User where Id=:assignRoundRobinContact.selected_user.Id limit 1];
                           
    //                         EmailTemplate templateId = [Select id from EmailTemplate where name = 'Free Trial Request Form Alert'];
    //                         List<Messaging.SingleEmailMessage> allmsg = new List<Messaging.SingleEmailMessage>();
    //                         Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
    //                         OrgWideEmailAddress[] owea = [select Id from OrgWideEmailAddress where Address = 'sfdc-robot@samsara.com'];
    //                         if ( owea.size() > 0 ) {
    //                             mail.setOrgWideEmailAddressId(owea.get(0).Id);
    //                         }
    //                         mail.setTemplateID(templateId.Id); 
    //                         mail.setTargetObjectId(c[0].Id);
    //                         mail.setTreatTargetObjectAsRecipient(false);
    //                         String[] toAddresses = new String[] {toUser.Email, 'lead-alerts@samsara.com'};
    //                         mail.setToAddresses(toAddresses);
    //                         mail.setSaveAsActivity(false);
    //                         allmsg.add(mail);
    //                         Messaging.sendEmail(allmsg,false);                    
    //                     }catch(exception e){ // en case any of these are null, return exception to check error
    //                         System.debug(e.getMessage());
    //                         throw e;
    //                     }
    //                 }
    //             }
    //         }
    //     }
    // }

}