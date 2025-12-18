/* 
* Class Created:  01/19/24 
* 01/19/24 Joshna - (Mercury Project) Test class for Customer360TriggerHandler
*/ 
@isTest(seeAllData=false)
private class Customer360TriggerHandlerTests {
    
    @testSetup 
    private static void testDataSetUp(){
        List<Account> aList = new List<Account>();
        for(Integer i=1;i<2;i++){
            aList.add((Account) TestFactory.createSObject(new Account(Name='Test Cust360 '+i, Organization_Size__c = '1 - 99', Industry = 'Other')));
        }
        insert aList;
        
        List<Customer_360__c> cs360List = new List<Customer_360__c>();
        for(Account objacc :aList){
            Customer_360__c cs360 = new Customer_360__c();
            cs360.Account__c = objacc.id;
            cs360.Name  = objacc.Name;
            cs360.LIC_AG2_Discount__c = 10;
            cs360.LIC_DM11_Discount__c = 10;
            cs360.LIC_CM1_Discount__c =20;
            cs360.LIC_AG4_Discount__c=20;
            cs360.LIC_AG2_ENT_MUP__c = 100;
            cs360.LIC_AG4_ENT_MUP__c =200;
            cs360.LIC_CM1_ENT_MUP__c =300;
            cs360.BigCommerce_Id__c = '1234';
            cs360List.add(cs360);
        }
        insert cs360List;
    }
    
    @isTest 
    private static void testCustomer360TriggerHandler() {
        List<Customer_360__c> updateCs360List = new List<Customer_360__c>();
        Test.startTest();
        List<Customer_360__c> lstCust360 = [SELECT Id, Account__c, LIC_AG2_Discount__c, LIC_DM11_Discount__c,LIC_CM1_Discount__c,LIC_AG4_Discount__c,LIC_AG2_ENT_MUP__c,
                                            LIC_AG4_ENT_MUP__c, LIC_CM1_ENT_MUP__c FROM Customer_360__c WHERE Name like 'Test Cust360%'];
        for(Customer_360__c cs360Obj : lstCust360){
            Cs360Obj.LIC_AG2_Discount__c  = 30;
            Cs360Obj.LIC_DM11_Discount__c  = 30;
            Cs360Obj.LIC_CM1_Discount__c  = 30;
            Cs360Obj.LIC_AG4_Discount__c  = 30;
            Cs360Obj.LIC_AG2_ENT_MUP__c  = 500;
            Cs360Obj.LIC_AG4_ENT_MUP__c  = 500;
            Cs360Obj.LIC_CM1_ENT_MUP__c  = 500;
            Cs360Obj.Push_to_Webstore__c=true;
            updateCs360List.add(cs360Obj);
        }
        update updateCs360List;      
        
        Test.stopTest();
    }
    
    @isTest 
    private static void testCustomer360TriggerHandlerRunaAsAutonimousUser() {
        User user = [Select Id, Name from User where Name = 'Automated Process' Limit 1];
        System.runAs(user){
            List<Customer_360__c> updateCs360List = new List<Customer_360__c>();
            List<Customer_360__c> lstCust360 = [SELECT Id, Account__c, LIC_AG2_Discount__c, LIC_DM11_Discount__c,LIC_CM1_Discount__c,LIC_AG4_Discount__c,LIC_AG2_ENT_MUP__c,
                                                LIC_AG4_ENT_MUP__c, LIC_CM1_ENT_MUP__c FROM Customer_360__c WHERE Name like 'Test Cust360%'];
            Integer i=0;
            for(Customer_360__c cs360Obj : lstCust360){
                Cs360Obj.LIC_AG2_Discount__c  = 30;
                Cs360Obj.LIC_DM11_Discount__c  = 30;
                Cs360Obj.LIC_CM1_Discount__c  = 30;
                Cs360Obj.LIC_AG4_Discount__c  = 30;
                Cs360Obj.LIC_AG2_ENT_MUP__c  = 500;
                Cs360Obj.LIC_AG4_ENT_MUP__c  = 500;
                Cs360Obj.LIC_CM1_ENT_MUP__c  = 500;
                Cs360Obj.Push_to_Webstore__c=true;
                Cs360Obj.BigCommerce_Id__c='54321'+(++i);
                updateCs360List.add(cs360Obj);
            }
            update updateCs360List;  
        }
    }
    
    @isTest
    private static void testDeleteCus360(){
        Customer_360__c Cust360rec = [SELECT Id, Account__c, LIC_AG2_Discount__c, LIC_DM11_Discount__c,LIC_CM1_Discount__c, LIC_AG4_Discount__c,LIC_AG2_ENT_MUP__c,LIC_AG4_ENT_MUP__c, LIC_CM1_ENT_MUP__c FROM Customer_360__c WHERE Name like 'Test Cust360%' LIMIT 1];
        
        Test.startTest();
        delete Cust360rec;     
        Test.stopTest();
    }
    
    @isTest 
    private static void testPublishPlatformWSEvent() { 
        new Customer360TriggerHelper().publishPlatformWSEvent(new Map<Id, Customer_360_Event__e>());   
    }
    
    @isTest 
    private static void testPublishPlatformEventInsert() { 
        new Customer360TriggerHelper().publishPlatformEventInsert(new List<Customer_360__c>());   
        new Customer360TriggerHelper().publishPlatformEventBeforeUpdate(new Map<Id,Customer_360__c>(),new List<Customer_360__c>());
        new Customer360TriggerHelper().publishPlatformEventAfterUpdate(new Map<Id,Customer_360__c>(),new List<Customer_360__c>());
    }
    
    @isTest
    private static void testisRecordModifiedByMulesoft(){
        User user = [Select Id, Name from User where Name = 'Automated Process' Limit 1];
        
        Customer_360__c newRecord = new Customer_360__c(Push_to_Webstore__c=false);
        
        system.runAs(user){
            Customer360TriggerHelper.isRecordModifiedByMulesoft(newRecord,null);
        }
        
    }
}