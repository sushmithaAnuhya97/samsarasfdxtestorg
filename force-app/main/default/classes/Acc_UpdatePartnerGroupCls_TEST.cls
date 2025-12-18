/**********************************************************************
Name: Acc_UpdatePartnerGroupCls_TEST
-----------------------------------------------------------------------
Purpose: This class will contain methods for Acc_UpdatePartnerGroupCls test coverage                                                         
-----------------------------------------------------------------------
History  

VERSION     AUTHOR               DATE               DETAIL                       
1.0        Vijaychandra        2023-NOV-03        INITIAL DEVELOPMENT

***********************************************************************/ 

@IsTest
public class Acc_UpdatePartnerGroupCls_TEST {
	@TestSetup
    public static void setup(){
        User objProfileAE3 = [select Id, IsActive, Profile.Name from User where IsActive = true and Profile.Name = 'Samsara Sales - NA US AE3' order by Id limit 1];
        User objProfileADR = [select Id, IsActive, Profile.Name from User where IsActive = true and Profile.Name = 'Samsara ADRs' order by Id limit 1];
        String partnerId = Schema.getGlobalDescribe().get('Account').getDescribe().getRecordTypeInfosByName().get('Partner').getRecordTypeId();
        User objRoleENT = [select Id, IsActive, UserRole.Name from User where IsActive = true and UserRole.Name like '%Fleet ENT%' limit 1];
        Profile pf = [SELECT Id,Name FROM Profile WHERE name = 'Samsara Partner Community Login License Admin'];
        Id roleId = [SELECT Id,Name FROM UserRole WHERE Name = 'Millennium Technologies Partner User'].Id;
        Book_Of_Business__c book2 = new Book_Of_Business__c(Name='Book Two', AE__c=objProfileAE3.Id, ADR__c=objProfileADR.Id, Active__c=true);
        Account account5 = new Account (Name = 'Test Account RODRIGO USA - Partner', Organization_Size__c = '5000+', BillingCountry = 'United States', 
                                        RecordTypeId=partnerId,Partner_Type__c='Insurance', Program_Type__c='Premium Discount',Books_Of_Business__c = book2.Id,
                                        BillingStateCode='TX', Industry = 'Other', OwnerId=objRoleENT.Id, Account_Lifetime_ACV__c=40000, 
                                        CSM_Initial_onboarding_completed_Time__c = datetime.now());
        Database.DMLOptions dml = new Database.DMLOptions(); 
        dml.DuplicateRuleHeader.AllowSave = true;
        Database.SaveResult sr = Database.insert(account5, dml);
        //insert account5;
        
        Contact con = new Contact();
        con.Firstname = 'Partner';
        con.LastName = 'Test';
        con.Email = 'partnerTest@samsara.com';
        con.AccountId = account5.Id;
        insert con;
        
        Account account6 = new Account (Name = 'Test Account2 - Partner', Organization_Size__c = '5000+', BillingCountry = 'United States', 
                                        RecordTypeId=partnerId,Partner_Type__c='Insurance', Program_Type__c='Paid Referral;Resale',Books_Of_Business__c = book2.Id,
                                        BillingStateCode='TX', Industry = 'Other', OwnerId=objRoleENT.Id, Account_Lifetime_ACV__c=40000,Partner_Description__c = 'Insurance Carrier',
                                        ServicesIntegration_Program_Type__c = 'Installation', CSM_Initial_onboarding_completed_Time__c = datetime.now());
        Database.DMLOptions dml2 = new Database.DMLOptions(); 
        dml2.DuplicateRuleHeader.AllowSave = true;
        Database.SaveResult sr2 = Database.insert(account6, dml2);
        
        Contact con2 = new Contact();
        con2.Firstname = 'Partner2';
        con2.LastName = 'Test2';
        con2.Email = 'partner2Test2@samsara.com';
        con2.AccountId = account6.Id;
        insert con2;
        
        String orgId=UserInfo.getOrganizationId(); 
        String dateString=String.valueof(Datetime.now()).replace(' ','').replace(':','').replace('-',''); 
        
        Integer RandomId=Integer.valueOf(Math.rint(Math.random()*1000000)); 
        String uniqueName=orgId+RandomId; 
        
        User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        System.runAs(thisUser){
            User uu=new User(firstname = 'Test AE3 Role', 
                         lastName = 'Test AE3 Role', 
                         email = uniqueName + '@test' + orgId + '.org', 
                         Username = uniqueName + 'AE3@test' + orgId + '.org', 
                         EmailEncodingKey = 'ISO-8859-1', 
                         Alias = uniqueName.substring(18, 23), 
                         TimeZoneSidKey = 'America/Los_Angeles', 
                         LocaleSidKey = 'en_US', 
                         LanguageLocaleKey = 'en_US', 
                         ProfileId = pf.Id, 
                         //UserRoleId = roleId,
                        contactid = con.Id,
                         isActive=true);
            
        	User uu2=new User(firstname = 'Test2 AE3 Role', 
                         lastName = 'Test2 AE3 Role', 
                         email = 'testuser2@samsara.com', 
                         Username = 'testuser2@samsara.com.org', 
                         EmailEncodingKey = 'ISO-8859-1', 
                         Alias = 'tUser2', 
                         TimeZoneSidKey = 'America/Los_Angeles', 
                         LocaleSidKey = 'en_US', 
                         LanguageLocaleKey = 'en_US', 
                         ProfileId = pf.Id, 
                         //UserRoleId = roleId,
                        contactid = con2.Id,
                         isActive=true);
            
        	insert uu2;
        }
        
        
    }
    
    @IsTest
    static void updatePartnerGroupFuture_TEST(){
        
        Test.starttest();
       
        Account Acc = [SELECT Id,Program_Type__c,Partner_Description__c,ServicesIntegration_Program_Type__c,isPartner FROM Account WHERE Name ='Test Account RODRIGO USA - Partner' LIMIT 1];
        
        Acc.Program_Type__c = 'Paid Referral';
        Acc.Partner_Description__c = 'Insurance Carrier';
        Acc.ServicesIntegration_Program_Type__c = 'Installation';
        
        update acc;
        
        Acc_UpdatePartnerGroupCls.updatePartnerGroupFuture(new Set<Id>{Acc.Id});
        
        
		Test.stopTest();
		        
    }
    
    @IsTest
    static void updatePartnerGroupTEST(){
        
        Test.starttest();
       	Map<Id,Account> oldAccMap = new Map<Id,Account>();
        Account Acc = [SELECT Id,RecordTypeId,Program_Type__c,Partner_Description__c,ServicesIntegration_Program_Type__c,isPartner FROM Account WHERE Name ='Test Account RODRIGO USA - Partner' LIMIT 1];
        oldAccMap.put(Acc.id, Acc);
        Acc.Program_Type__c = 'Premium Discount';
        Acc.Partner_Description__c = 'Broker';
        Acc.ServicesIntegration_Program_Type__c = 'Consulting';
        
        //update acc;
        
        Map<Id,Account> newAccMap = new Map<Id,Account>();
        newAccMap.put(Acc.id, Acc);
        Acc_UpdatePartnerGroupCls.updatePartnerGroup(oldAccMap,newAccMap);
        
        
		Test.stopTest();
		        
    }
    
    @IsTest
    static void test1(){
        Test.starttest();
       Map<Id,Account> oldAccMap = new Map<Id,Account>();
        Account Acc = [SELECT Id,Program_Type__c,Partner_Description__c,RecordTypeId, ServicesIntegration_Program_Type__c,isPartner FROM Account WHERE Name ='Test Account2 - Partner' LIMIT 1];
        oldAccMap.put(Acc.id, Acc);
        Acc.Program_Type__c = 'Resale';
        Acc.Partner_Description__c = 'Insurance Carrier';
        Acc.ServicesIntegration_Program_Type__c = 'Installation';
        
        //update acc;
        Map<Id,Account> newAccMap = new Map<Id,Account>();
        newAccMap.put(Acc.id, Acc);
        Acc_UpdatePartnerGroupCls.updatePartnerGroup(oldAccMap,newAccMap);
       
        
		Test.stopTest();
    }
    
    @IsTest
    static void test2(){
        Test.starttest();
       
        Account Acc = [SELECT Id,Program_Type__c,Partner_Description__c,ServicesIntegration_Program_Type__c,isPartner FROM Account WHERE Name ='Test Account2 - Partner' LIMIT 1];
        
        Acc.Program_Type__c = 'Premium Discount';
        Acc.Partner_Description__c = 'Consultant';
        Acc.ServicesIntegration_Program_Type__c = 'Consulting';
        
        update acc;
        
        Acc_UpdatePartnerGroupCls.updatePartnerGroupFuture(new Set<Id>{Acc.Id});
       
        
		Test.stopTest();
    }
}