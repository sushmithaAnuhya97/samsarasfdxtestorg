@isTest
private class CSRecordHelperTests {
     
    //@TestSetup
   // static void testData(){
    @isTest static void testRecordSync2(){
       system.debug('testRecordSync2 is called');
        Test.StartTest();
        List<Account> aList = new List<Account>();
        //Contact con= [SELECT Id FROM Contact LIMIT 1];
        aList.add((Account) TestFactory.createSObject(new Account(Name='Blah1', Website='test.test', CSM_First_30d_Stage__c = 'Pending Intro',
                      Key_Value_Points__c = 'Dispatch and Routing',Upsell_Opportunity_Products__c = 'AG46', AE_to_CSM_handoff_notes__c = 'Testing a phase',
                      Preparedness_Rating__c = '3',Self_install_or_Vendor__c = '3rd Party Installer', Feature_commits_CSM__c ='Testing', Pain_Points_Objections_during_the_trial__c = 'testing',
                           CS_POC_Email_Address__c ='Test@gmail.com', CS_POC_First_Name__c= 'TestName', CSM_Status__c= 'Onboarding',Sentiment_Root_Cause__c='Customer service',
                           CSM_Health_Rating__c = 'Red', CSM_Health_Trend__c= 'Steady',Did_they_Trial__c = true)));
        if(aList.size() > 0) {
            insert aList;
        }  
            
        Contact contact = (Contact) TestFactory.createSObject(new Contact(AccountId = aList.get(0).Id, Email = 'test@test.com'));
        insert contact;
        CS_Record__c csRecord = new CS_Record__c(Account__c = aList.get(0).id,Key_Value_Points__c = 'Driver Productivity',Upsell_Opportunity_Products__c = 'VG34',
          Self_install_or_Vendor__c = 'Self Install',CSM_Status__c = 'Onboarding',Preparedness_Rating__c = '1',Feature_commits_CSM__c = 'Commited',
          Pain_Points_Objections_during_the_trial__c = 'May Be',CS_POC_First_Name__c = 'I am the Test',CS_POC_Email_Address__c = 'test@test.com');   
        insert csRecord;
        Set<Id> AcctId = new Set<Id>();
        AcctId.add(aList.get(0).Id);
        UpdateRecordsForCS.updateRecords(AcctId);
        Test.stopTest();
    }
    
    @isTest static void testRecordSync(){
       system.debug('testRecordSync is called');
       /*Set<Id> actset = new Set<Id> ();
       List<Account> actlst = new List<Account>();
       actlst = [Select Id, Name From Account Where Id NOT IN (Select Account__c From CS_Record__c) LIMIT 1];
       actset.add(actlst.get(0).Id);
       UpdateRecordsForCS.updateRecords(actset);*/
       List<Account> aList = new List<Account>();
       aList.add((Account) TestFactory.createSObject(new Account(Name='Blah1', Website='test.test', CSM_First_30d_Stage__c = 'Pending Intro',
                      Key_Value_Points__c = 'Dispatch and Routing',Upsell_Opportunity_Products__c = 'AG46', AE_to_CSM_handoff_notes__c = 'Testing a phase',
                      Preparedness_Rating__c = '3',Self_install_or_Vendor__c = '3rd Party Installer', Feature_commits_CSM__c ='Testing', Pain_Points_Objections_during_the_trial__c = 'testing',
                           CS_POC_Email_Address__c ='Test@gmail.com', CS_POC_First_Name__c= 'TestName', CSM_Status__c= 'Onboarding',Sentiment_Root_Cause__c='Customer service',
                           CSM_Health_Rating__c = 'Red', CSM_Health_Trend__c= 'Steady',Did_they_Trial__c = true,SAM_Number_Undecorated__c='C4G5EZW')));
        if(aList.size() > 0) {
            insert aList;
        }
        Contact contact = (Contact) TestFactory.createSObject(new Contact(AccountId = aList.get(0).Id, Email = 'test@test.com'));
        insert contact;
        Opportunity opportunityOne = (Opportunity)
            TestFactory.createSObject(new Opportunity(AccountId = aList.get(0).Id,
                                                      Name = 'Opp Testers 1 Inc',
                                                      RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Trial').getRecordTypeId(),
                                                      Shipping_Contact__c = contact.Id, 
                                                      Selected_Payment_Type__c = 'Direct Annual',
                                                      Price_Book_Name__c = 'Standard',
                                                      Send_Invoice__c = false,
                                                      StageName = 'Closed Won',
                                                      Type = 'Revenue Opportunity - Bill Only',
                                                      Amount = 10));
        insert opportunityOne;
        aList[0].Pre_Sale_IC__c = UserInfo.getUserId();
        aList[0].SIC__c = UserInfo.getUserId();
        aList[0].Key_Stakeholder_for_CSM__c = contact.Id;
        update aList;
        Set<Id> AcctId = new Set<Id>();
        AcctId.add(aList.get(0).Id);   
        Test.startTest();
        UpdateRecordsForCS.updateRecords(AcctId);
        Test.stopTest();
        
    }
    
    @isTest static void testRecordSync3(){
        Test.startTest();
        List<Account> aList = new List<Account>();

        aList.add((Account) TestFactory.createSObject(new Account(Name='Blah1', Website='test.test', CSM_First_30d_Stage__c = 'Pending Intro',
                      Key_Value_Points__c = 'Dispatch and Routing',Upsell_Opportunity_Products__c = 'AG46', AE_to_CSM_handoff_notes__c = 'Testing a phase',
                      Preparedness_Rating__c = '3',Self_install_or_Vendor__c = '3rd Party Installer', Feature_commits_CSM__c ='Testing', Pain_Points_Objections_during_the_trial__c = 'testing',
                           CS_POC_Email_Address__c ='Test@gmail.com', CS_POC_First_Name__c= 'TestName', CSM_Status__c= 'Onboarding',Sentiment_Root_Cause__c='Customer service',
                           CSM_Health_Rating__c = 'Red', CSM_Health_Trend__c= 'Steady',Did_they_Trial__c = true)));
        if(aList.size() > 0) {
            insert aList;
        } 
        Contact contact1 = (Contact) TestFactory.createSObject(new Contact(AccountId = aList.get(0).Id, Email = 'test@test.com'));
        insert contact1;
        Set<Id> AcctId = new Set<Id>();
        AcctId.add(aList.get(0).Id);
        //CS_Record__c updatedRecord = null;
        UpdateRecordsForCS.updateRecords(AcctId);
         Test.stopTest();
        CS_Record__c csRecord = [SELECT Id FROM CS_Record__c LIMIT 1];
        Contact contact= [SELECT Id FROM Contact LIMIT 1];
        
        csRecord.Key_Stakeholder_for_CSM__c = contact.Id;
        csRecord.Key_Value_Points__c = 'Driver Productivity';
        csRecord.Upsell_Opportunity_Products__c = 'VG55';
        csRecord.AE_to_CSM_handoff_notes__c = 'Handoff Sucessful';
        csRecord.Preparedness_Rating__c = '1';
        csRecord.Self_install_or_Vendor__c = 'Self Install';
        csRecord.Did_they_Trial__c = true;
        csRecord.Feature_commits_CSM__c = 'Commited';
        csRecord.Pain_Points_Objections_during_the_trial__c = 'May Be';
        csRecord.CS_POC_Email_Address__c = 'test@test.com';
        csRecord.CS_POC_First_Name__c = 'I am the Test';
        csRecord.CSM_Status__c = 'Onboarding';
        csRecord.Sentiment_Root_Cause__c = 'Product fit';
        csRecord.CSM_Health_Rating__c = 'Yellow';
        csRecord.CSM_Health_Trend__c = 'Improving';
        csRecord.Go_to_Green_Plan__c = 'Planned as Perfect';
        csRecord.Sentiment_Root_Cause__c = 'Business changes';
        csRecord.CS_Sentiment_Sub_reason__c = 'Loss of champion';
        csRecord.Churn_Risk_Reason__c = 'Risk';
        csRecord.Upsell_Opportunity_Reason__c = 'Lets to do';
        csRecord.CSM_Health_Notes__c ='test';
        update csRecord;
        
    }
}