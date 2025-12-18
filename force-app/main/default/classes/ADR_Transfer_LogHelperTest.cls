/**
 * @author Groundswell - Vikasm - vikas@gscloudsolutions.com
 * @date 2020-08-25
 * @lastModified 2020-08-26
 */
@isTest
private with sharing class ADR_Transfer_LogHelperTest 
{
    @TestSetup
    private static void setup() 
    {
        Account acc = new Account ();
        acc = TestFactory.initializeAccount('ADR_Transfer_LogTrigger');
        insert acc;

        Contact Con = new Contact();
        con = TestFactory.initializeContact('ADR_Transfer_LogTrigger');
        insert con;
        
        Opportunity opp = new Opportunity();
        opp = TestFactory.initializeOpportunity ('ADR_Transfer_LogTrigger');
        insert opp;

    }

    @isTest
    private static void rollupAdrOnOpportunityTest()
    {
        List<Account> accounts = [SELECT id FROM Account WHERE Name LIKE 'ADR_Transfer_LogTrigger%'];
        List<Contact> contacts = [SELECT id FROM Contact WHERE FirstName LIKE 'ADR_Transfer_LogTrigger%'];
        List<opportunity> opportunities = [SELECT ID FROM Opportunity WHERE Name LIKE 'ADR_Transfer_LogTrigger%'];

        Test.startTest();
        ADR_Transfer_Log__c adr = new ADR_Transfer_Log__c();
        adr.Account__c = accounts[0].Id;
        adr.Contact__c = contacts[0].Id;
        adr.Opportunity__c = opportunities[0].Id;
        adr.ADR_Transfer_Status__c = 'Demo Scheduled';
        insert adr;
        opportunities = [SELECT ID, ADR_Transfer__c FROM Opportunity WHERE Name LIKE 'ADR_Transfer_LogTrigger%'];
        System.assertEquals(opportunities[0].ADR_Transfer__c, adr.Id);


        Test.stopTest();
    }

    @isTest
    private static void rollupAdrOnOpportunityUpdateTest()
    {
        List<Account> accounts = [SELECT id FROM Account WHERE Name LIKE 'ADR_Transfer_LogTrigger%'];
        List<Contact> contacts = [SELECT id FROM Contact WHERE FirstName LIKE 'ADR_Transfer_LogTrigger%'];
        List<opportunity> opportunities = [SELECT ID FROM Opportunity WHERE Name LIKE 'ADR_Transfer_LogTrigger%'];

       
        ADR_Transfer_Log__c adr = new ADR_Transfer_Log__c();
        adr.Account__c = accounts[0].Id;
        adr.Contact__c = contacts[0].Id;
        adr.Opportunity__c = opportunities[0].Id;
        adr.ADR_Transfer_Status__c = 'Demo Scheduled';
        insert adr;
        opportunities = [SELECT ID, ADR_Transfer__c FROM Opportunity WHERE Name LIKE 'ADR_Transfer_LogTrigger%'];
        System.assertEquals(opportunities[0].ADR_Transfer__c, adr.Id);

        Test.startTest();
        Opportunity opp = new Opportunity();
        opp = TestFactory.initializeOpportunity ('ADR_Transfer_LogTrigger2');
        insert opp;
        adr.Opportunity__c = opp.Id;
        update adr; 

        opportunities = [SELECT ID, ADR_Transfer__c FROM Opportunity WHERE Name LIKE 'ADR_Transfer_LogTrigger%' order by CreatedDate asc];
        //System.assertEquals(opportunities[0].ADR_Transfer__c, null);
        //System.assertEquals(opportunities[1].ADR_Transfer__c, adr.Id);
        Test.stopTest();
    }
}