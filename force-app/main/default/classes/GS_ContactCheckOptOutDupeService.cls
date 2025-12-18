/**
* Created By : Groundswell - Tanuj Tyagi
* @Date August 24, 2021
*
* @description : This class will be responsible to Check OptOut Contact Duplicate Operations
* SFA-14
*
**/
public class GS_ContactCheckOptOutDupeService {
    public void checkForOptOutDupes(List<Contact> newContactList, Map<Id, Contact> oldContactMap) {
        DiagnosticsInstrumentation.push('ContactHelper.checkForOptOutDupes');
        // First, make sets of all the emails and phones we need to check agains
        Map<String, List<Contact>> emailsMap = new Map<String, List<Contact>>();
        Map<String, List<Contact>> phonesMap = new Map<String, List<Contact>>();
        Boolean changeToOptOut = false;
        
        for(Contact c : newContactList) {
            if(oldContactMap != null){
                Contact oldContact = oldContactMap.get(c.Id);
                changeToOptOut = ((!oldContact.Phone_Opt_Out__c && c.Phone_Opt_Out__c)
                                  || (!oldContact.HasOptedOutOfEmail && c.HasOptedOutOfEmail)
                                  || (!oldContact.Sales_Email_Opt_Out__c && c.Sales_Email_Opt_Out__c)) ? true: false;
            }
            
            if(!changeToOptOut){
                if(c.Email != NULL) {
                    if(!emailsMap.containsKey(c.Email)) {
                        List<Contact> cList = new List<Contact>();
                        cList.add(c);
                        emailsMap.put(c.Email, cList);
                    } else {
                        emailsMap.get(c.Email).add(c);
                    }
                }
                if(c.Phone != NULL) {
                    if(!phonesMap.containsKey(c.Phone)) {
                        List<Contact> cList = new List<Contact>();
                        cList.add(c);
                        phonesMap.put(c.Phone, cList);
                    } else {
                        phonesMap.get(c.Phone).add(c);
                    }
                }
                if(c.MobilePhone != NULL) {
                    if(!phonesMap.containsKey(c.MobilePhone)) {
                        List<Contact> cList = new List<Contact>();
                        cList.add(c);
                        phonesMap.put(c.MobilePhone, cList);
                    } else {
                        phonesMap.get(c.MobilePhone).add(c);
                    }
                }
            }
        }
        try{
            // Select all opted-out ppl
            //TODO - add limit here for how many records can be queried 
            if(!emailsMap.isEmpty() || !phonesMap.isEmpty()){
                for(Contact optout : new GS_ContactSelector(true).checkFatalError().getContactsToCheckDupesByIds(phonesMap.keySet(), emailsMap.keySet())) {
                                          // Throw exception if anything was found
                                          if(emailsMap.containsKey(optout.Opt_Out_Email_Copy__c)) {
                                              //TODO - use size parameter to avoid for loop
                                              for(Contact c : emailsMap.get(optout.Opt_Out_Email_Copy__c)) {
                                                  c.addError('Unable to create/update contact because their Email matches another contact in our "Do Not Contact" list.');
                                              }
                                          }
                                          if(phonesMap.containsKey(optout.Opt_Out_Mobile_Phone__c)) {
                                              //TODO - use size parameter to avoid for loop
                                              for(Contact c : phonesMap.get(optout.Opt_Out_Mobile_Phone__c)) {
                                                  c.addError('Unable to create/update contact because their Mobile Phone matches another contact in our "Do Not Contact" list.');
                                              }
                                          }
                                          if(phonesMap.containsKey(optout.Opt_Out_Phone__c)) {
                                              //TODO - use size parameter to avoid for loop
                                              for(Contact c : phonesMap.get(optout.Opt_Out_Phone__c)) {
                                                  c.addError('Unable to create/update contact because their Phone matches another contact in our "Do Not Contact" list.');
                                              }
                                          }
                                      }
            }
        } catch(Exception e){
            System.debug('There was an error: ' + e);
        }
        DiagnosticsInstrumentation.pop();
    }
}