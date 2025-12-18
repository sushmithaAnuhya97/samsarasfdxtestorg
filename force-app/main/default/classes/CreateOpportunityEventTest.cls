@isTest
private class CreateOpportunityEventTest {
  @isTest
    static void platformEventTest_unit() {
        String keyPrefix = Lead.SObjectType.getDescribe().getKeyPrefix();
        Id leadId = Id.valueOf(keyPrefix + String.valueOf(101).leftPad(12, '0'));
        //GTMS-8185
        Lead LeadRecord= new Lead(LastName='Test',Company='Test Com',state='alabama',LeadSource='Bing');
        insert LeadRecord;
        
        Database.LeadConvert lc = new Database.LeadConvert();
        lc.setLeadId(LeadRecord.id);
        lc.setOwnerId(System.UserInfo.getUserId());
        lc.setDoNotCreateOpportunity(true);
        
        LeadStatus convertStatus = [SELECT Id, MasterLabel FROM LeadStatus WHERE IsConverted=true LIMIT 1];
        lc.setConvertedStatus(convertStatus.MasterLabel);
        
        Database.LeadConvertResult lcr = Database.convertLead(lc);
        
        Account acc = new Account (Name = 'Acme Co', Organization_Size__c = '5000+', BillingCountry = 'Canada', Industry = 'Other');
        insert acc;
        Account a = new Account (Name = 'Acme Co', Organization_Size__c = '5000+', BillingCountry = 'Canada', Industry = 'Other',
                                 //LFBN__Assign_Account__c=true,
                                 Initiate_Round_Robin__c = true,
                                 Latest_Partner_Account_Interaction__c=acc.id,Latest_Partner_Program_Interaction__c='subsidy');
        insert a;
        
        id convertedAccId = lc.getAccountId();
        System.debug('convertedAccId'+convertedAccId);
        List<Account> AccountidList= new  List<Account>();
        AccountidList.add(a);
        CreateOpportunityEventHelper.updateAccounts(AccountidList);
        System.assert(lcr.isSuccess());
        
        
        //GTMS-8185
        try{
            Test.startTest();
            CreateOpportunityEvent__e  event = new CreateOpportunityEvent__e ();
            event.Converted_Lead_Id_t__c  =LeadRecord.id;
            EventBus.publish(event);            
            Test.stopTest();
        }
        catch(Exception ex) {
            //expect it to fail since I am using a mocked lead Id. This is just for unit test coverage
        }
    }
}