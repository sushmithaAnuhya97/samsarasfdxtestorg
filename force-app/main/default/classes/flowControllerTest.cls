@isTest

private class flowControllerTest {
    
    @testSetup
    private static void testData(){
        system.debug('I was here');
          
        Account acc = new Account();
        acc.name='Acc1';
        acc.Organization_Size__c='1 - 99';
        acc.Industry='Agriculture';
        acc.BillingState='California';
        acc.ShippingState='California';
        acc.Approved_Payment_Type__c = 'Direct Monthly';
        insert acc;
        Account a=[Select id,name from account where name='Acc1'];
        
        Opportunity testOppty = new Opportunity();

        testOppty.Can_Create__c = true;
        testOppty.ForecastCategoryName = 'Forecast';
        testOppty.Shipping_Method__c = 'Will Call';
        
        testOppty.Shipping_Email_Sent_bypassed__c = false;
        testOppty.Shipping_Country__c = 'Canada';
        

        testOppty.Name = 'TestAccountTest';
        testOppty.AccountId = a.Id;
        testOppty.Amount = 1000000;
        testOppty.CloseDate = Date.today();
        testOppty.ACV_Commissionable_Dollars_Copy__c = 0;
        testOppty.Internal_Finance__c = 'Approved';
        testOppty.Internal_Financing_Response_Timestamp__c = Datetime.now();
        testOppty.LeadSource = 'Other';
        testOppty.Lead_Source_Encoded__c = 2019072519;
        testOppty.netsuite_conn__Order_Type__c = 'Contract - New';
        testOppty.Owner_Role_Copy__c = 'Management';
        testOppty.Selected_Payment_Type__c = 'Upfront Payments';
        testOppty.Shipping_Address_New_Concatenated__c = ',';
        testOppty.StageName = 'Closed Won';
        //testOppty.Unique_Flow_Identifier__c = '00663000009NaJIAA0';
       insert testOppty;
       system.debug('Oppertunity created');
        
    }
    
   //test with incorrect id
    private static testMethod void testCaseOne(){
        Test.startTest();
        system.debug('Within Test 1');
        PageReference pageRef = Page.AcceptanceFlow ; 
        Test.setCurrentPageReference(pageRef);
        // Put Id into the current page Parameters
        Opportunity testOppty = [SELECT Id, Unique_Flow_Identifier__c FROM Opportunity WHERE Name='TestAccountTest'];
        //system.debug('ID ='+ pageRef.getParameters().get('Id'));
        //pageRef.getParameters().put('Id', testOppty.id);
        testOppty.Unique_Flow_Identifier__c =testOppty.id;
        update testOppty;
        ApexPages.currentPage().getParameters().put('id','helloworld');
        system.debug('ID ='+ ApexPages.currentPage().getParameters().get('Id'));
        ApexPages.StandardController sc = new ApexPages.standardController(testOppty);
        //flowController testController3 = new flowController(sc);
        flowController testController3 = new flowController();
        testController3.flowController1();
        //object valURL = testController3.returnURL();
        Test.stopTest();
        
    }
    
    //test with correct id
    private static testMethod void TestCaseTwo()
    {
        Test.startTest();
        system.debug('Within Test 2');
        PageReference pageRef = Page.AcceptanceFlow ; 
        Test.setCurrentPageReference(pageRef);
        // Put Id into the current page Parameters
        Opportunity testOppty = [SELECT Id, Unique_Flow_Identifier__c FROM Opportunity WHERE Name='TestAccountTest'];
        //system.debug('ID ='+ pageRef.getParameters().get('Id'));
        //pageRef.getParameters().put('Id', testOppty.id);
        testOppty.Unique_Flow_Identifier__c =testOppty.id;
        update testOppty;
        ApexPages.currentPage().getParameters().put('id',testOppty.id);
        system.debug('ID ='+ ApexPages.currentPage().getParameters().get('Id'));
        //ApexPages.StandardController sc = new ApexPages.standardController(testOppty);
        //flowController testController3 = new flowController(sc);
        flowController testController3 = new flowController();
        //object valURL = testController3.returnURL();
        Test.stopTest();
    }
    
    private static testMethod void TestCaseThree()
    {
        Test.startTest();
        system.debug('Within Test 3');
        PageReference pageRef = Page.AcceptanceFlow ; 
        Test.setCurrentPageReference(pageRef);
        // Put Id into the current page Parameters
        Opportunity testOppty = [SELECT Id, Unique_Flow_Identifier__c FROM Opportunity WHERE Name='TestAccountTest'];
        system.debug('ID ='+ pageRef.getParameters().get('Id'));
        pageRef.getParameters().put('Id', testOppty.id);
        testOppty.Unique_Flow_Identifier__c =testOppty.id;
        update testOppty;
        ApexPages.currentPage().getParameters().put('id','');
        system.debug('ID ='+ ApexPages.currentPage().getParameters().get('Id'));
        //ApexPages.StandardController sc = new ApexPages.standardController(testOppty);
        //flowController testController3 = new flowController(sc);
        flowController testController3 = new flowController();
        //object valURL = testController3.returnURL();
        Test.stopTest();
    }

    private static testMethod void TestCaseFour()
    {
        Test.startTest();
        system.debug('Within Test 4');
        PageReference pageRef = Page.AcceptanceFlow ; 
        Test.setCurrentPageReference(pageRef);
        // Put Id into the current page Parameters
        Opportunity testOppty = [SELECT Id, Unique_Flow_Identifier__c FROM Opportunity WHERE Name='TestAccountTest'];
        system.debug('ID ='+ pageRef.getParameters().get('Id'));
        pageRef.getParameters().put('Id', testOppty.id);
        testOppty.Unique_Flow_Identifier__c =testOppty.id;
        update testOppty;
        ApexPages.currentPage().getParameters().put('id',null);
        system.debug('ID ='+ ApexPages.currentPage().getParameters().get('Id'));
        //ApexPages.StandardController sc = new ApexPages.standardController(testOppty);
        //flowController testController3 = new flowController(sc);
        flowController testController3 = new flowController();
        //object valURL = testController3.returnURL();
        Test.stopTest();
    }
  /*  //Split this method into two
 
     static testMethod void testAllCases() {


//Divide this into 2 methods
//MEthod One
       //test with incorrect id
       Test.startTest();
       PageReference pageRef = Page.AcceptanceFlow ; 

       pageRef.getParameters().put('Id', 'testincorrectId');

       Test.setCurrentPageReference(pageRef);

       flowController testController2 = new flowController();
        //Test.stopTest(); 

        

       //test with correct id
       // MEthod 2
        //Test.startTest();
       pageRef = Page.AcceptanceFlow; 
       Opportunity testOppty = [SELECT Id FROM Opportunity WHERE Name='TestAccountTest'];
       pageRef.getParameters().put('Id', testOppty.id);

       Test.setCurrentPageReference(pageRef);

       flowController testController3 = new flowController();
        Test.stopTest(); 

    }*/
}