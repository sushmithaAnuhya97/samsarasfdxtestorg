/* 
 * Class Created: 03/18/20 Agamani - (GTMS-562)
 * Class:AccountUpdateBatch
 */  
@isTest
private class AccountUpdateBatchTest {
@testSetup
    private static void testData()
    {
          
        //Adding Multiple accounts
        try{
            
            Account acc = new Account();
            acc.name='Acc1';
            acc.Organization_Size__c='1 - 99';
            acc.Industry='Agriculture';
            acc.BillingState='California';
            acc.ShippingState='California';
            insert acc;
            Account acc1 = new Account();
            acc1.name='Acc2';
            acc1.Organization_Size__c='1 - 99';
            acc1.Industry='Agriculture';
            acc1.BillingState='California';
            acc1.ShippingState='California';
            insert acc1;
            
            Account acc2 = new Account();
            acc2.name='Acc3';
            acc2.Organization_Size__c='1 - 99';
            acc2.Industry='Agriculture';
            acc2.BillingState='California';
            acc2.ShippingState='California';
            insert acc2;
        }catch (exception e){
                system.debug('Account insert Error: ' + e.getMessage());}
            
        Account a=[Select id,name from account where name='Acc1'];
        Account a1=[Select id,name from account where name='Acc2'];
        Account a2=[Select id,name from account where name='Acc3'];
        TriggerHandler.bypass('OpportunityTriggerHandler');
        Opportunity subsidyOpp = (Opportunity) TestFactory.createSObject(new Opportunity(
            Type = 'Rebate',
            RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Return Opportunity').getRecordTypeId(),
            Name = 'Subsidy',
            AccountId = a.Id,
            Configuration_Segment__c = 'Non Express',
            StageName = 'Qualified',
            CloseDate = System.today(),
            Probability = 100,
            Rebate_Type__c = 'Subsidy',
            Amount = -1,
            Shipping_Country__c = 'United States'
        ));
        insert subsidyOpp;
        //Adding Multiple Contracts
        try{
            Opportunity opportunityOne = (Opportunity) TestFactory.createSObject(new Opportunity(AccountId = a.Id, 
                                                                                                Type = 'Revenue Opportunity',
                                                                                                Name = 'Opp Testers 5 Inc',
                                                                                                StageName = 'Decision',
                                                                                                //Shipping_Contact__c = contactOne.Id, 
                                                                                                Price_Book_Name__c = 'Standard',
                                                                                                Configuration_Segment__c = 'Non Express',
                                                                                                SBQQ__Renewal__c = TRUE,
                                                                                                License_Term_CPQ__c = 36, Rebate_Amount__c=1,
                                                                                                Selected_Payment_Type__c = 'Direct Annual'));
            insert opportunityOne;
            Opportunity opportunityTwo = (Opportunity) TestFactory.createSObject(new Opportunity(AccountId = a.Id, 
                                                                                                Type = 'Revenue Opportunity',
                                                                                                Name = 'Opp Testers 2 Inc',
                                                                                                StageName = 'Decision',
                                                                                                //Shipping_Contact__c = contactTwo.Id, 
                                                                                                Price_Book_Name__c = 'Standard',
                                                                                                SBQQ__Renewal__c = TRUE,
                                                                                                License_Term_CPQ__c = 36, Rebate_Amount__c=1,
                                                                                                Selected_Payment_Type__c = 'Direct Annual'));
            insert opportunityTwo;
            List<Contract> lst = new List<Contract>();
            Contract c= new contract();
            c.name='con1';
            c.AccountId=a.id;
            c.StartDate=system.today();
            c.EndDate=system.today().adddays(30);
            c.Status='Draft';
            c.ContractTerm=1;
            c.CurrencyIsoCode='USD';
            //c.SBQQ__RenewalOpportunity__c = opportunityOne.Id;
            lst.add(c);
            //insert c;
            Contract c1= new contract();
            c1.name='con2';
            c1.AccountId=a.id;
            c1.StartDate=system.today();
            c1.EndDate=system.today().adddays(30);
            c1.Status='Draft';
            c1.ContractTerm=1;
            c1.CurrencyIsoCode='USD';
            //c1.SBQQ__RenewalOpportunity__c = opportunityTwo.Id;
            lst.add(c1);
            //insert c1;
            Contract c2= new contract();
            c2.name='con3';
            c2.AccountId=a1.id;
            c2.StartDate=system.today();
            c2.EndDate=system.today().adddays(30);
            c2.Status='Draft';
            c2.ContractTerm=1;
            c2.CurrencyIsoCode='USD';
            lst.add(c2);
            //insert c2;
            Contract c3= new contract();
            c3.name='con4';
            c3.AccountId=a1.id;
            c3.StartDate=system.today();
            c3.EndDate=system.today().adddays(30);
            c3.Status='Draft';
            c3.ContractTerm=1;
            c3.CurrencyIsoCode='USD';
            lst.add(c3);
            insert lst;
            
            Product2 prod = new Product2(Name= 'HW-VG33', ProductCode = 'HW-VG33', Family = 'Test');
            insert prod;

            Id pricebookId = Test.getStandardPricebookId();
            PricebookEntry pb = new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = prod.Id, UnitPrice = 100, IsActive = true);
            insert pb;

            list<SBQQ__Subscription__c> subList = new List<SBQQ__Subscription__c>();
            SBQQ__Subscription__c sub1 = new SBQQ__Subscription__c(
                SBQQ__Quantity__c = 1,
                SBQQ__RenewalPrice__c = 100,
                SBQQ__CustomerPrice__c = 100,
                SBQQ__Contract__c = c.id,
                SBQQ__Account__c = a.id,
                SBQQ__Product__c = prod.id

            );
            subList.add(sub1);
            insert subList;
            lst[0].Status = 'Activated';
            lst[0].Deactivated__c = false;
            
            lst[1].Status = 'Activated';
            lst[1].Deactivated__c = false;
            
            lst[2].Status = 'Activated';
            update lst;
            lst[0].SBQQ__RenewalOpportunity__c = opportunityOne.Id;
            lst[1].SBQQ__RenewalOpportunity__c = opportunityTwo.Id;
            update lst;

        }catch (exception e){
            system.debug('Contract insert Error: ' + e.getMessage());}
        
    }
         
	//Testing for one account with one contract record.
    private static testmethod void testMethod1()
    {   TriggerHandler.bypass('OpportunityTriggerHandler');
        Test.startTest();
        List<Id> accountId = new List<Id>();
        Account acc=[select id from account where name='Acc1'];
        accountid.add(acc.id);
        
		Id batchJobId = Database.executeBatch(new AccountUpdateBatch(accountId), 20);
        Test.stopTest();
    }
    
    //testing for multiple account with multiple contract records
    private static testmethod void testMethod2()
    {
        TriggerHandler.bypass('OpportunityTriggerHandler');
        Test.startTest();
        List<Id> accountId = new List<Id>();
        list<account>acc=[select id from account where name in ('Acc2','Acc3')];
        for(account a:acc)
        {
            accountid.add(a.id);
        }
  		Id batchJobId = Database.executeBatch(new AccountUpdateBatch(accountId), 20);
        Test.stopTest();
    }
    
}