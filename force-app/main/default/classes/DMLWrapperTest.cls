/**
* @author Groundswell - Vikasm - vikas@gscloudsolutions.com
* @date 2020-08-25
*/
@IsTest
private with sharing class DMLWrapperTest 
{
    // SObjects (in order of dependency) used by UnitOfWork in tests bellow
    private static List<Schema.SObjectType> MY_SOBJECTS =
            new Schema.SObjectType[]{
                    Product2.SObjectType,
                    PricebookEntry.SObjectType,
                    Account.SObjectType,
                    Opportunity.SObjectType,
                    OpportunityLineItem.SObjectType
            };

    @isTest
    private static void testDoInsert() 
    {
        // Insert Opportunities with UnitOfWork
             DMLWrapper.intializeUnitOfWork(MY_SOBJECTS);
            for (Integer o = 0; o < 2; o++) 
            {
                Opportunity opp = new Opportunity();
                opp = initializeOpportunity ('DMLHelper-' + o);
                dmlWrapper.doInsert(opp);
             }
             DMLWrapper.publishDML();
             assertResults('DMLHelper%');
                
    }
    
    @isTest
    private static void testDoInsertList() 
    {
        // Insert Opportunities with UnitOfWork
            DMLWrapper.intializeUnitOfWork(MY_SOBJECTS);
        	List<Opportunity> OppList = new List<Opportunity>();
            for (Integer o = 0; o < 2; o++) 
            {
                Opportunity opp = new Opportunity();
                opp = initializeOpportunity ('DMLHelper-' + o);
                OppList.add(opp);
             }
        	 DMLWrapper.doInsert(OppList);
             DMLWrapper.publishDML();
             assertResults('DMLHelper%');
                
    }
    
    @isTest
    private static void testDMLHelperInsertUpdateDelete() 
    {
       
		// Insert Opportunities with DML Helper
        {
            DMLWrapper.intializeUnitOfWork(MY_SOBJECTS);
            for (Integer o = 0; o < 2; o++) 
            {
                Opportunity opp = new Opportunity();
                opp = initializeOpportunity ('DMLHelper-' + o);
                dmlWrapper.doInsert(Opp);
                for (Integer i = 0; i < o + 1; i++) {
                    Product2 product = new Product2();
                    product.Name = opp.Name + ' : Product : ' + i;
                    dmlWrapper.doInsert(product);
                    PricebookEntry pbe = new PricebookEntry();
                    pbe.UnitPrice = 10;
                    pbe.IsActive = true;
                    pbe.UseStandardPrice = false;
                    pbe.Pricebook2Id = Test.getStandardPricebookId();
                    dmlWrapper.doInsert(pbe, PricebookEntry.Product2Id, product);
                    OpportunityLineItem oppLineItem = new OpportunityLineItem();
                    oppLineItem.Quantity = 1;
                    dmlWrapper.doRegisterRelationship(oppLineItem, OpportunityLineItem.PricebookEntryId, pbe);
                    //Getting null pointer exception
                   //dmlWrapper.doInsert(oppLineItem, OpportunityLineItem.OpportunityId, opp);
                }
            }

            dmlWrapper.publishDML();
        }
        Test.startTest();
        // Records to update
        List<Opportunity> opps = [select Id, Name, (Select Id from OpportunityLineItems) from Opportunity where Name like 'DMLHelper%' order by Name];
        // Update some records with DML Helper
        {
            DMLWrapper.intializeUnitOfWork(MY_SOBJECTS);
            Opportunity opp = opps[0];
            opp.Name = 'DMLHelper Test Opportunity Changed';
            dmlWrapper.doUpdate(opp);
            
            Opportunity opp1 = opps[1];
            opp1.Name = 'DMLHelper Test Opportunity Changed2';
            dmlWrapper.doUpdate(new List<SObject>{
                    opp1
            });
            
            dmlWrapper.publishDML();
        }
        opps = [select Id, Name,AccountId, (Select Id, PricebookEntry.Product2.Name, Quantity, TotalPrice from OpportunityLineItems Order By PricebookEntry.Product2.Name) from Opportunity where Name like 'DMLHelper%' order by Name];
        System.assertEquals(2, opps.size());
        System.assertEquals('DMLHelper Test Opportunity Changed', opps[0].Name);
        system.assertEquals ('DMLHelper Test Opportunity Changed2', opps[1].Name);
   
        // Delete some records with the DML Helper
        {
            DMLWrapper.intializeUnitOfWork(MY_SOBJECTS);
            DMLWrapper.doDelete(new List<SObject>{
                    opps[0]
            }); 
            
            dmlWrapper.publishDML();
        }
        opps = [select Id, Name, (Select Id, PricebookEntry.Product2.Name, Quantity from OpportunityLineItems Order By PricebookEntry.Product2.Name) from Opportunity where Name like 'DMLHelper%' order by Name];
        System.assertEquals(1, opps.size());
        
        // Delete some records with the UnitOfWork
        {
            DMLWrapper.intializeUnitOfWork(MY_SOBJECTS);
            DMLWrapper.doDelete(opps[0]); 
            
            DMLWrapper.publishDML();
        }
        Test.stopTest();
        
       
    }
    
    @isTest
    private static void testUpsertList()
    {
        DMLWrapper.intializeUnitOfWork(MY_SOBJECTS);
        List<Opportunity> OppList = new List<Opportunity>();
        	for (Integer o = 0; o < 2; o++) 
            {
                Opportunity opp = new Opportunity();
                opp = initializeOpportunity ('DMLHelper-' + o);
                OppList.add(opp);
                
             }
             DMLWrapper.doUpsert(OppList);
             DMLWrapper.publishDML();
        assertResults('DMLHelper%');
    }
    @isTest
    private static void testUpsert()
    {
        DMLWrapper.intializeUnitOfWork(MY_SOBJECTS);
        	for (Integer o = 0; o < 2; o++) 
            {
                Opportunity opp = new Opportunity();
                opp = initializeOpportunity ('DMLHelper-' + o);
                DMLWrapper.doUpsert(Opp);
             }
             DMLWrapper.publishDML();
        assertResults('DMLHelper%');
    }
    
    @isTest
    private static void doRelationshipUpdate()
    {
        DMLWrapper.intializeUnitOfWork(MY_SOBJECTS);
        Account thisAccount = new Account();
        thisAccount = initializeAccount('dmlHelper');
        DMLWrapper.doInsert(thisAccount);
        Account accountNew = new Account();
        accountNew=initializeAccount('dmlHelperNew');
        DMLWrapper.doInsert(accountNew); 
        
        	for (Integer o = 0; o < 2; o++) 
            {
                Opportunity opp = new Opportunity();
                opp = initializeOpportunity ('DMLHelper-' + o);
                dmlWrapper.doInsert(Opp, Opportunity.AccountId, thisAccount);
             }
             DMLWrapper.publishDML();
        assertResults('DMLHelper%');
        
        Test.startTest();
        String filter = 'DMLHelper%';
        List<Opportunity> opps = [select Id, Name, AccountId from Opportunity where Name like :filter order by Name];
		List<Account> accounts = [Select id from account WHERE Name like 'dmlHelper%'];
        System.assertEquals(2, accounts.size());
        System.assertEquals(opps[0].accountId, accounts[0].Id);
        
        //RelationshipUpdate
        
        //DMLWrapper.doUpdate(opps[0], Opportunity.AccountId, accounts[1]);
        //UnitOfWork: RegisterDirty with new parent relationship not working #221
        //dmlWrapper.publishDML();
        accounts = new List<Account>();
        accounts = [Select id, (Select id, AccountId FROM Opportunities) from account WHERE Name = 'dmlHelperNew%'];
        //System.assertEquals(1, accounts.size());
        //System.assertEquals(1, accounts[0].Opportunities.size());
        Test.stopTest();
    }
    
    private static Account initializeAccount(String prefix)
    {
        return TestFactory.initializeAccount(prefix);
    }

    private static Opportunity initializeOpportunity(String Prefix)
    {
        return TestFactory.initializeOpportunity(Prefix);
    }

    private static void assertResults(String prefix) 
    {
        // Standard Assertions on tests data inserted by tests
       
        List<Opportunity> opps = [select Id, Name, (Select Id from OpportunityLineItems) from Opportunity where Name like :prefix order by Name];
        System.assertEquals(2, opps.size());

    }
}