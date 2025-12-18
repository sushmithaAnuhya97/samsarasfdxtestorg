@IsTest
public without sharing class ContractUpdateServiceAsyncTest {

    @TestSetup
    static void setup(){        
        Account acc = (Account) TestFactory.createSObject(new Account(Name = 'Testers 6 Inc',
                                BillingState='California',
                                BillingCountry = 'United States',
                                Organization_Size__c = '100 - 499',
                                Approved_Payment_Type__c = 'Direct Monthly',
                                Industry = 'Other'));

        insert acc;

        Opportunity amendOpp = (Opportunity) TestFactory.createSObject(new Opportunity());
        amendOpp.Name = 'Amendment Oppty';
        amendOpp.AccountId = acc.Id;
        amendOpp.CloseDate = Date.today() + 90;
        //amendOpp.ContractId = newContract.Id;
        //amendOpp.SBQQ__AmendedContract__c = newContract.Id;
        amendOpp.StageName = 'Qualify';
        insert amendOpp;

        Contract con = new Contract();
        con.AccountId = acc.Id;
        con.SBQQ__Opportunity__c = amendOpp.Id;
        con.StartDate = Date.today();
        con.EndDate = Date.today() + 365;
        insert con;
    }
    
    static ContractUpdateServiceAsync asyncRef;

    @IsTest
    public static void updateContractDatesTest(){
        initialize();

        asyncRef.execute(new Async_Request__c(
            Params__c = [SELECT Id FROM Opportunity LIMIT 1].Id+';',
            Options__c = JSON.serialize(new ContractUpdateServiceAsync.Options(
                'Update Dates'
            ))
        ));
    }

    @IsTest
    public static void updateContractDatesTest_amendedCoverage(){
        initialize();
        Opportunity opp = [SELECT Id, SBQQ__AmendedContract__c FROM Opportunity LIMIT 1];
        opp.SBQQ__AmendedContract__c = [SELECT Id FROM Contract LIMIT 1].Id;
        update opp;

        asyncRef.execute(new Async_Request__c(
            Params__c = [SELECT Id FROM Opportunity LIMIT 1].Id+';',
            Options__c = JSON.serialize(new ContractUpdateServiceAsync.Options(
                'Update Dates'
            ))
        ));
    }

    private static void initialize(){
        asyncRef = new ContractUpdateServiceAsync();
        asyncRef.shouldPublishDML = false;
    }
}