/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 02-16-2023
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/

@isTest
public class Batch_ContractHealthStatus_Test 
{
    @testSetup
    private static void testSetup()
    {
    }
    @isTest private static void testMethod001()
    {
        Account acc = new Account ();
        acc = TestFactory.initializeAccount('ContractAccount');
        insert acc;
        Contact con = (Contact) TestFactory.createSObject(new Contact(AccountId = acc.Id));
        insert con;
        Opportunity oppty = (Opportunity)
            TestFactory.createSObject(new Opportunity(AccountId = acc.Id, 
                                                      Type = 'Trial',
                                                      Name = 'Returning Oppty 001',
                                                      StageName = 'Proposal',
                                                      Shipping_Contact__c = con.Id, 
                                                      Price_Book_Name__c = 'Standard',
                                                      Selected_Payment_Type__c = 'Direct Annual'));
        Insert oppty;
        Contract contract = new Contract(
                AccountId = acc.Id,
                StartDate = Date.today(),
                EndDate = Date.today().adddays(100),
                ContractTerm = 12,Deactivated__c = true
        );
        insert contract; 
        system.debug('contract.EndDate = '+contract.EndDate);
        test.startTest();
        Batch_ContractHealthStatus bc  =new Batch_ContractHealthStatus();
        bc.execute(null);
        test.stopTest();
        
    }
     @isTest private static void testMethod002()
    {
        Account acc = new Account ();
        acc = TestFactory.initializeAccount('ContractAccount');
        insert acc;
        Contact con = (Contact) TestFactory.createSObject(new Contact(AccountId = acc.Id));
        insert con;
        Opportunity oppty = (Opportunity)
            TestFactory.createSObject(new Opportunity(AccountId = acc.Id, 
                                                      Type = 'Trial',
                                                      Name = 'Returning Oppty 001',
                                                      StageName = 'Proposal',
                                                      Renewal_ACV__c = 100,
                                                      Shipping_Contact__c = con.Id, 
                                                      Price_Book_Name__c = 'Standard',
                                                      Selected_Payment_Type__c = 'Direct Annual'));
        Insert oppty;
        Contract contract = new Contract(
                AccountId = acc.Id,
            SBQQ__Opportunity__c = oppty.id,
                StartDate = Date.today(),
                EndDate = Date.today().adddays(100),
                ContractTerm = 12
        );
        insert contract; 
        system.debug('contract.EndDate = '+contract.EndDate);
        test.startTest();
        Batch_ContractHealthStatus bc  =new Batch_ContractHealthStatus();
        bc.execute(null);
        test.stopTest();
        
    }
    @isTest private static void testMethod003()
    {
        Account acc = new Account ();
        acc = TestFactory.initializeAccount('ContractAccount');
        acc.Active_Devices__c = 5;
        insert acc;
        Contact con = (Contact) TestFactory.createSObject(new Contact(AccountId = acc.Id));
        insert con;
        Opportunity oppty = (Opportunity)
            TestFactory.createSObject(new Opportunity(AccountId = acc.Id, 
                                                      Type = 'Trial',
                                                      Name = 'Returning Oppty 001',
                                                      StageName = 'Proposal',
                                                      Renewal_ACV__c = 100,
                                                      Shipping_Contact__c = con.Id, 
                                                      Price_Book_Name__c = 'Standard',
                                                      Selected_Payment_Type__c = 'Direct Annual'));
        Insert oppty;
        Contract contract = new Contract(
                AccountId = acc.Id,
            SBQQ__Opportunity__c = oppty.id,
                StartDate = Date.today(),
                EndDate = Date.today().adddays(100),
                ContractTerm = 12
        );
        insert contract; 
        system.debug('contract.EndDate = '+contract.EndDate);
        test.startTest();
        Batch_ContractHealthStatus bc  =new Batch_ContractHealthStatus();
        bc.execute(null);
        test.stopTest();
        
    }
     @isTest private static void testMethod004()
    {
        Account acc = new Account ();
        acc = TestFactory.initializeAccount('ContractAccount');
        acc.Active_Devices__c = 0;
        insert acc;
        Contact con = (Contact) TestFactory.createSObject(new Contact(AccountId = acc.Id));
        insert con;
        Opportunity oppty = (Opportunity)
            TestFactory.createSObject(new Opportunity(AccountId = acc.Id, 
                                                      Type = 'Trial',
                                                      Name = 'Returning Oppty 001',
                                                      StageName = 'Proposal',
                                                      Renewal_ACV__c = 100,
                                                      Shipping_Contact__c = con.Id, 
                                                      Price_Book_Name__c = 'Standard',
                                                      Selected_Payment_Type__c = 'Direct Annual'));
        Insert oppty;
        Contract contract = new Contract(
                AccountId = acc.Id,
            SBQQ__Opportunity__c = oppty.id,
                StartDate = Date.today(),
                EndDate = Date.today().adddays(100),
                ContractTerm = 12
        );
        insert contract; 
        system.debug('contract.EndDate = '+contract.EndDate);
        test.startTest();
        Batch_ContractHealthStatus bc  =new Batch_ContractHealthStatus();
        bc.execute(null);
        test.stopTest();
        
    }    
     @isTest private static void testMethod005()
    {
        Account acc = new Account ();
        acc = TestFactory.initializeAccount('ContractAccount');        
        insert acc;
        acc.Active_Devices__c = 0;
        update acc;
        Contact con = (Contact) TestFactory.createSObject(new Contact(AccountId = acc.Id));
        insert con;
        Opportunity oppty = (Opportunity)
            TestFactory.createSObject(new Opportunity(AccountId = acc.Id, 
                                                      Type = 'Trial',
                                                      Name = 'Returning Oppty 001',
                                                      StageName = 'Proposal',
                                                      Renewal_ACV__c = 100,
                                                      Shipping_Contact__c = con.Id, 
                                                      Price_Book_Name__c = 'Standard',
                                                      Selected_Payment_Type__c = 'Direct Annual'));
        list<opportunity> opptyList = new list<opportunity>();
        opptyList.add( oppty);
        Insert opptyList;
        test.startTest();
        Batch_ContractHealthStatus bc  =new Batch_ContractHealthStatus();
        bc.updateRenewalOpportunities(opptyList);
        test.stopTest();
        
    }
    @isTest private static void testMethod006()
    {
        
        //Create Parent Group
        Group grp = new Group();
        grp.name = 'CPQ System Notification';
        grp.Type = 'Regular'; 
        Insert grp; 
 
        //Create Group Member
        GroupMember grpMem1 = new GroupMember();
        grpMem1.UserOrGroupId = UserInfo.getUserId();
        grpMem1.GroupId = grp.Id;
        Insert grpMem1;
        test.startTest();
        Batch_ContractHealthStatus bc  =new Batch_ContractHealthStatus();
        bc.emailErrors('Test');
        test.stopTest();
        
    }
    @isTest private static void testMethod007()
    {
        Account acc = new Account ();
        acc = TestFactory.initializeAccount('ContractAccount');
        insert acc;
        acc.Active_Devices__c = 0;
        acc.Customer_ARR__c = 400.00;
        
        update acc;
        
        Contact con = (Contact) TestFactory.createSObject(new Contact(AccountId = acc.Id));
        insert con;
        Opportunity oppty = (Opportunity)
            TestFactory.createSObject(new Opportunity(AccountId = acc.Id, 
                                                      Type = 'Trial',
                                                      Name = 'Returning Oppty 001',
                                                      StageName = 'Proposal',
                                                      Renewal_ACV__c = 100,
                                                      Shipping_Contact__c = con.Id, 
                                                      Price_Book_Name__c = 'Standard',
                                                      Selected_Payment_Type__c = 'Direct Annual'));
        Insert oppty;
        Contract contract = new Contract(
                AccountId = acc.Id,
            SBQQ__Opportunity__c = oppty.id,
                StartDate = Date.today(),
                EndDate = Date.today().adddays(100),
                ContractTerm = 12
        );
        insert contract; 
        system.debug('contract.EndDate = '+contract.EndDate);
        test.startTest();
        Batch_ContractHealthStatus bc  =new Batch_ContractHealthStatus();
        bc.execute(null);
        test.stopTest();
        
    }
    @isTest private static void testMethod008()
    {
        Account acc = new Account ();
        acc = TestFactory.initializeAccount('ContractAccount');
        insert acc;
        Contact con = (Contact) TestFactory.createSObject(new Contact(AccountId = acc.Id));
        insert con;
        Opportunity oppty = (Opportunity)
            TestFactory.createSObject(new Opportunity(AccountId = acc.Id, 
                                                      Type = 'Trial',
                                                      Name = 'Returning Oppty 001',
                                                      StageName = 'Proposal',
                                                      Shipping_Contact__c = con.Id, 
                                                      Price_Book_Name__c = 'Standard',
                                                      Selected_Payment_Type__c = 'Direct Annual'));
        Insert oppty;
        Contract contract = new Contract(
                AccountId = acc.Id,
                StartDate = Date.today(),
                EndDate = Date.today().adddays(100),
                ContractTerm = 12,Deactivated__c = true
        );
        insert contract; 

        Product2 prod = new Product2(Name= 'HW-VG33', ProductCode = 'HW-VG33', Family = 'Test',Product_Status__c ='EOL');
        insert prod;

        Id pricebookId = Test.getStandardPricebookId();
        PricebookEntry pb = new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = prod.Id, UnitPrice = 100, IsActive = true);
        insert pb;

        list<SBQQ__Subscription__c> subList = new List<SBQQ__Subscription__c>();
        SBQQ__Subscription__c sub1 = new SBQQ__Subscription__c(
            SBQQ__Quantity__c = 1,
            SBQQ__RenewalPrice__c = 100,
            SBQQ__CustomerPrice__c = 100,
            SBQQ__Contract__c = contract.id,
            SBQQ__Account__c = acc.id,
            SBQQ__Product__c = prod.id

        );
        subList.add(sub1);
        SBQQ__Subscription__c sub2 = new SBQQ__Subscription__c(
            SBQQ__Quantity__c = 1,
            SBQQ__RenewalPrice__c = 100,
            SBQQ__CustomerPrice__c = 100,
            SBQQ__Contract__c = contract.id,
            SBQQ__Account__c = acc.id,
            SBQQ__Product__c = prod.id

        );
        subList.add(sub2);
        insert subList;
        system.debug('contract.EndDate = '+contract.EndDate);
        test.startTest();
        Batch_ContractHealthStatus bc  =new Batch_ContractHealthStatus();
        bc.execute(null);
        test.stopTest();        
    }
    @isTest private static void testMethod009()
    {
        Account acc = new Account ();
        acc = TestFactory.initializeAccount('ContractAccount');
        insert acc;
        acc.Active_Devices__c = 1;
        update acc;
        Contact con = (Contact) TestFactory.createSObject(new Contact(AccountId = acc.Id));
        insert con;
        Opportunity oppty = (Opportunity)
            TestFactory.createSObject(new Opportunity(AccountId = acc.Id, 
                                                      Type = 'Trial',
                                                      Name = 'Returning Oppty 001',
                                                      StageName = 'Proposal',
                                                      Shipping_Contact__c = con.Id, 
                                                      Price_Book_Name__c = 'Standard',
                                                      Selected_Payment_Type__c = 'Direct Annual'));
        Insert oppty;
        Contract contract = new Contract(
                AccountId = acc.Id,
                StartDate = Date.today(),
                EndDate = Date.today().adddays(100),
                ContractTerm = 12,Deactivated__c = true
        );
        insert contract; 

        Product2 prod = new Product2(Name= 'HW-VG33', ProductCode = 'HW-VG33', Family = 'Test',Product_Status__c ='EOL');
        insert prod;

        Id pricebookId = Test.getStandardPricebookId();
        PricebookEntry pb = new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = prod.Id, UnitPrice = 100, IsActive = true);
        insert pb;

        list<SBQQ__Subscription__c> subList = new List<SBQQ__Subscription__c>();
        SBQQ__Subscription__c sub1 = new SBQQ__Subscription__c(
            SBQQ__Quantity__c = 1,
            SBQQ__RenewalPrice__c = 100,
            SBQQ__CustomerPrice__c = 100,
            SBQQ__Contract__c = contract.id,
            SBQQ__Account__c = acc.id,
            SBQQ__Product__c = prod.id

        );
        subList.add(sub1);
        SBQQ__Subscription__c sub2 = new SBQQ__Subscription__c(
            SBQQ__Quantity__c = 1,
            SBQQ__RenewalPrice__c = 100,
            SBQQ__CustomerPrice__c = 100,
            SBQQ__Contract__c = contract.id,
            SBQQ__Account__c = acc.id,
            SBQQ__Product__c = prod.id

        );
        subList.add(sub2);
        insert subList;
        system.debug('contract.EndDate = '+contract.EndDate);
        test.startTest();
        Batch_ContractHealthStatus bc  =new Batch_ContractHealthStatus();
        bc.execute(null);
        test.stopTest();        
    }
    
}