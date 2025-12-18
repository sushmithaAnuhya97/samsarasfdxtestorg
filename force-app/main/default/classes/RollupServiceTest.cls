/**
 * @author Groundswell - Vikasm - vikas@gscloudsolutions.com
 * @date 2020-09-14
 * @lastModified 2020-09-14
 */
@isTest
private with sharing class RollupServiceTest 
{
    @isTest 
    static void averageSumMaxMinTest()
    {
        Account acc = new Account ();
        acc = TestFactory.initializeAccount('averageSumMaxMinTest');
        insert acc;

        Contact Con = new Contact();
        con = TestFactory.initializeContact('averageSumMaxMinTest');
        insert con;
        
        List<opportunity> oppList = new List<opportunity>();
        Opportunity thisOpp = new Opportunity();
        thisOpp = TestFactory.initializeOpportunity ('averageSumMaxMinTest');
        thisOpp.AccountId = acc.Id;
        thisOpp.StageName = 'Qualified';
        thisOpp.Amount = 10000;
        oppList.add(thisOpp);
        Opportunity thisOpp2 = new Opportunity();
        thisOpp2 = TestFactory.initializeOpportunity ('averageSumMaxMinTest');
        thisOpp2.AccountId = acc.Id;
        thisOpp2.StageName = 'Qualified';
        thisOpp2.Amount = 5000;
        oppList.add(thisOpp2);
        Opportunity thisOpp3 = new Opportunity();
        thisOpp3 = TestFactory.initializeOpportunity ('averageSumMaxMinTest');
        thisOpp3.AccountId = acc.Id;
        thisOpp3.StageName = 'Qualified';
        thisOpp3.Amount = 3000;
        oppList.add(thisOpp3);
        insert oppList;

        Decimal Sum = RollupService.Sum(oppList, 'Amount');
        Decimal average = RollupService.average(oppList, 'Amount');
        Decimal max = RollupService.max(oppList, 'Amount');
        Decimal min = RollupService.min(oppList, 'Amount');

        system.assertEquals(Sum, 18000);
        system.assertEquals(average, 6000);
        system.assertEquals(Max, 10000);
        system.assertEquals(min, 3000);

    }

    @isTest 
    static void FirstLastTest()
    {
        Account acc = new Account ();
        acc = TestFactory.initializeAccount('FirstLastTest');
        insert acc;

        Contact Con = new Contact();
        con = TestFactory.initializeContact('FirstLastTest');
        insert con;
        
        List<opportunity> oppList = new List<opportunity>();
        Opportunity thisOpp = new Opportunity();
        thisOpp = TestFactory.initializeOpportunity ('FirstLastTest');
        thisOpp.AccountId = acc.Id;
        thisOpp.StageName = 'Qualified';
        thisOpp.Amount = 10000;
        oppList.add(thisOpp);
        insert thisOpp;
        Opportunity thisOpp2 = new Opportunity();
        thisOpp2 = TestFactory.initializeOpportunity ('FirstLastTest2');
        thisOpp2.AccountId = acc.Id;
        thisOpp2.StageName = 'Qualified';
        thisOpp2.Amount = 5000;
        oppList.add(thisOpp2);
        insert thisOpp2;

       
       Test.startTest();
       
       oppList = [SELECT ID, CreatedDate FROM Opportunity WHERE NAME Like 'FirstLastTest%' ORDER By CreatedDate asc];
       Opportunity firstOpp = (opportunity) RollupService.First(oppList, 'CreatedDate');
       Opportunity lastOpp = (opportunity) RollupService.Last(oppList, 'CreatedDate');
       system.assertEquals(firstOpp.Id, oppList[0].Id);
       system.assertEquals(lastOpp.Id, oppList[1].Id);

       Test.stopTest();

       

    }
}