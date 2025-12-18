/* 
01/26/2022 Lavanya (GTMS-5742)  - Added conditions to check if the Account is owned by Fleet AEs or SFDC Pool User
* May-31-2023 Siddharth (GTMS-12786): Prevent Contact Status field from being changed if it is in 'Inactive - No Longer There'
*/
public class GS_ContactHotTransferByFlow {
    
    @InvocableMethod(label='Hot Transfer Contact' description='Updates the Owner to the new value at "Hot Transfer To", then also updates the related Account to the same new Owner. This also creates an "ADR Transfer Log" record.')
    public static List<ResultOutputs>  getContactForHotTransfer(List<ContactInputs> contactInputs){
        
        ContactInputs contactInput = contactInputs[0];
        
        SamsaraLoggerService thisSamsaraLoggerService = new SamsaraLoggerService();
        // If the Hot Transfer Field has changed, then update the ADR Transfer fields and change the owner.
        Map<Id,Contact> contactById = new Map<Id,Contact>();
        Map<Id, Contact> contactToUpdateById = new Map<Id, Contact>();
        Map<Id, Account> accountToUpdateById = new Map<Id, Account>();
        List<ADR_Transfer_Log__c> newAdrTransferLogs = new List<ADR_Transfer_Log__c>();
        List<CampaignMember> newCampaignMembers = new List<CampaignMember>();
        List<ResultOutputs> results = new List<ResultOutputs>();
        Set<Id> contactRecordsIds = new Set<Id>();
        Map<Id, User> transferredUser = new Map<Id, User>();
        Set<Id> userIds = new Set<Id>();
   

        
        ResultOutputs resultOutput = new ResultOutputs();
        List<Schema.SObjectType> MY_SOBJECTS = new List<Schema.SObjectType>{
            Account.SObjectType,
            Contact.SObjectType,
            ADR_Transfer_Log__c.SObjectType
        };
            
        try{
            contactRecordsIds.add(contactInput.contactId);
            userIds.add(contactInput.hotTransferTo);
            userIds.add(UserInfo.getUserId());
            contactById = new Map<Id,Contact>(new GS_ContactSelector(true).checkFatalError().getContactDetailsByIds(contactRecordsIds));
            transferredUser = new GS_UserSelector(true).checkFatalError().getUserMapByIds(userIds);
            
            DMLWrapper.intializeUnitOfWork(MY_SOBJECTS);
            
            for(Contact thisContact: contactById.values()){
                
                if (!contactById.containsKey(thisContact.Id)) {
                    continue;
                }
                
                Contact contactDetails = contactById.get(thisContact.Id);
                String ownerRole = contactDetails.Account.Owner_Role__c;
                
                Boolean accountOwnedByADR = (ownerRole.contains(Label.Fleet_IS_AE) || ownerRole.contains(label.Fleet_ENT_AE) || contactDetails.Account.OwnerId == Label.SFDC_Pool_User_ID)?false:true;                                              
                
                if(contactDetails.Account.Original_Owner_for_Recycling_Campaign__c==null){
                    
                    ADR_Transfer_Log__c adrTransfer = new ADR_Transfer_Log__c();
                    adrTransfer.ADR_Transfer_By__c = UserInfo.getUserId();
                    adrTransfer.ADR_Transfer_Date__c = System.Now();
                    adrTransfer.ADR_Demo_Date__c = System.Now();
                    adrTransfer.ADR_Role_Copy__c = transferredUser.get(UserInfo.getUserId()).UserRole.Name;  //GTMS-6189
                    adrTransfer.ADR_Transfer_Status__c = 'Demo Scheduled';
                    adrTransfer.Contact__c = contactDetails.Id;
                    adrTransfer.Account__c = contactDetails.AccountId;
                    adrTransfer.AE_Demo_Transfer_To__c = contactInput.hotTransferTo;
                    adrTransfer.Hot_Transfer__c = True;
                    // GTMS-29330
                    adrTransfer.Meeting_Origination__c = contactInput.meetingOrigination;
                    adrTransfer.Booking_Method__c = contactInput.bookingMethod;
                    String transferCopy = contactDetails.Account.Enterprise_Experiments__c == null ? 'Standard' : contactDetails.Account.Enterprise_Experiments__c;
                    adrTransfer.Transfer_Type_At_Transfer_Copy__c = transferCopy;
                    List <ADR_Transfer_Log__c> existingADRTransfers = contactDetails.ADR_Transfer_Logs__r;
                    if (existingADRTransfers.size() == 0) {
                        newAdrTransferLogs.add(adrTransfer);
                    }
                    if (!contactToUpdateById.containsKey(contactDetails.Id)) contactToUpdateById.put(contactDetails.Id, contactDetails);
                    if(accountOwnedByADR){  
                        contactToUpdateById.get(contactDetails.Id).OwnerId =  contactInput.hotTransferTo;
                    }
                    //GTMS-12786
                    if( contactToUpdateById.get(contactDetails.Id).Status__c!='Inactive - No Longer There')
                    {
                        contactToUpdateById.get(contactDetails.Id).Status__c = 'Demo Scheduled';
                    }
                    
                    contactToUpdateById.get(contactDetails.Id).Hot_Transfer_To__c = contactInput.hotTransferTo;
                    
                    if (contactDetails.AccountId != null) {
                        if (!accountToUpdateById.containsKey(contactDetails.AccountId)) accountToUpdateById.put(contactDetails.AccountId, new Account(Id = contactDetails.AccountId));
                        //GTMS-6005: Update Sites Specialist field only if the Hot Transfer To user has role "Sites_IS_AE2"
                        if(transferredUser.get(contactInput.hotTransferTo).UserRole.Name.Contains(label.Sites_IS_AE2)){
                            accountToUpdateById.get(contactDetails.AccountId).Sites_Specialist__c = contactInput.hotTransferTo;
                        }
                        if(accountOwnedByADR){ 
                            accountToUpdateById.get(contactDetails.AccountId).OwnerId = contactInput.hotTransferTo;
                        }
                        
                    }
                }
                else{
                    //TODO - review why this isn't being triggered
                    CalloutException k = new CalloutException();
                    k.setMessage('You cannot hot transfer this account. It must be a scheduled demo with '+contactDetails.Account.Original_Owner_for_Recycling_Campaign__r.Name+'. Please use the standard transfer process.');
                    throw k;
                }
                
            }
            
            
            if(!contactToUpdateById.isEmpty()) {
                DMLWrapper.doUpdate(contactToUpdateById.values());
            }
            if(!accountToUpdateById.isEmpty()){
                DMLWrapper.doUpdate(accountToUpdateById.values());
            }
            if(!newAdrTransferLogs.isEmpty()) {
                DMLWrapper.doInsert(newAdrTransferLogs);
            }
            
            DMLWrapper.publishDML();
            
            resultOutput.message = 'Contact transferred to '+transferredUser.get(contactInput.hotTransferTo).Name;
            resultOutput.isSuccess = true;
            results.add(resultOutput);
            return results;
        }catch(Exception ex){
            resultOutput.message = ex.getMessage().contains('FIELD_CUSTOM_VALIDATION_EXCEPTION') ?
                                    ex.getMessage().split('FIELD_CUSTOM_VALIDATION_EXCEPTION,')[1].replace(': []','').trim():
                                    ex.getMessage();
            resultOutput.isSuccess = false;
            results.add(resultOutput);
            thisSamsaraLoggerService.logger.logError(
                'Error in Contact Hot Transfer::',
                new SamsaraLoggerObjectMVP(
                    ex, contactById.values()
                )
            );
            throw ex;
        }
        finally {
            thisSamsaraLoggerService.logger.dispatch();
            return results;
        }
        
    }
    
    //Input details which goes from flow to apex
    public class ContactInputs{
        @InvocableVariable
        public String contactId;
        
        @InvocableVariable
        public String hotTransferTo;

        @InvocableVariable
        public String meetingOrigination;
        
        @InvocableVariable
        public String bookingMethod;
    }
    
    //output details which goes from apex to flow
    public class ResultOutputs{
        @InvocableVariable
        public String message;
        
        @InvocableVariable
        public Boolean isSuccess;
    }
    
}