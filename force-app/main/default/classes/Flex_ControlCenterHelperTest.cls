@IsTest
public class Flex_ControlCenterHelperTest {
    @testSetup
    static void setupMethod(){
        TestData.setupControlCenterData();
        //bypassTriggers();
        // Standard Pricebook
        Id pricebookId = Test.getStandardPricebookId();
        
        // Create Product
        List<Product2> productList = new List<Product2>();
        Product2 vgLicense = new Product2(
            Name= 'LIC-VG-36MO', 
            ProductCode = 'LIC-VG-36MO', 
            Family = 'Test', 
            IsActive = true, 
            SBQQ__SubscriptionPricing__c = 'Fixed Price'
        );
        productList.add(vgLicense);  
        insert productList;

        // Create PriceBookEntries
        List<PricebookEntry> pricebookEntriesList = new List<PricebookEntry>();
        PricebookEntry vg33PB = new PricebookEntry(
            Pricebook2Id = pricebookId, 
            Product2Id = productList[0].Id, 
            UnitPrice = 10000, 
            IsActive = true
        );
        pricebookEntriesList.add(vg33PB);
        insert pricebookEntriesList;

        
        Account testAccount = new Account(Name='Acc1',Organization_Size__c = '1 - 99',Industry='Banking',BillingState='California',
                                          ShippingState='California',Approved_Payment_Type__c = 'Direct Monthly', BillingCountry = 'United States',
                                          IF_Response_Date__c=Date.today().addDays(-90),IF_Submitter_Email__c='testUser@Samsara.com',
                                          Geographic_Region__c='US'
                                         );
        insert testAccount;
        
        Account testAccount2 = new Account(Name='Acc2',Organization_Size__c = '1 - 99',
                                           Industry='Banking',BillingState='California',
                                           ShippingState='California',Approved_Payment_Type__c = 'Direct Monthly',
                                           BillingCountry = 'United States',
                                           IF_Response_Date__c=Date.today().addDays(-90),IF_Submitter_Email__c='testUser@Samsara.com',
                                           Geographic_Region__c='US'
                                         );
        insert testAccount2;

        // Create Opportunity
        List<Opportunity> newOppsList = new List<Opportunity>();
        Opportunity revenueOpportunity1 = new Opportunity(
            AccountId = testAccount.Id, 
            License_Term__c = 36, 
            Pricebook2Id = pricebookId, 
            Max_Approved_Discount__c = 0, 
            Name = 'Revenue Opportunity1', 
            Price_Book_Name__c = 'Standard Price Book', 
            CloseDate = System.today() + 90, 
            StageName = 'Incubate', 
            Owner_Role_Copy__c = 'Fleet IS AE2 NA US Team 8',
            Selected_Payment_Type__c = 'Direct Annual'
        ); 
        newOppsList.add(revenueOpportunity1);
        insert newOppsList;
        
        Opportunity renewalOpportunity = new Opportunity(
            AccountId = testAccount.Id, 
            License_Term__c = 36, 
            Pricebook2Id = pricebookId, 
            Max_Approved_Discount__c = 0, 
            Name = 'Renewal Opportunity1', 
            Price_Book_Name__c = 'Standard Price Book', 
            CloseDate = System.today() + 90, 
            Stagename = 'Proposal',
            Owner_Role_Copy__c = 'Fleet IS AE2 NA US Team 8',
            Selected_Payment_Type__c = 'Direct Annual'
        ); 
        
        insert renewalOpportunity;

        // Create a RecordType for Contract
        RecordType contractRecordType = [SELECT Id FROM RecordType WHERE DeveloperName = 'Standard_Contract' LIMIT 1];

        // Create Contracts
        List<Contract> contractList = new List<Contract>(); 
        /*Contract contract1 = new Contract(
            AccountId = testAccount.Id,
            StartDate = Date.today(),
            EndDate = Date.today().addDays(130),
            ContractTerm = 12,
            RecordTypeId = contractRecordType.Id,
            Deactivated__c = true,
            SBQQ__Opportunity__c = revenueOpportunity1.Id
            //SBQQ__Quote__c = quoteList[0].Id
        );
        contractList.add(contract1);
        
        Contract contract2 = new Contract(
            AccountId = testAccount2.Id,
            StartDate = Date.today(),
            EndDate = Date.today().addDays(130),
            ContractTerm = 12,
            RecordTypeId = contractRecordType.Id,
            Deactivated__c = true,
            SBQQ__Opportunity__c = revenueOpportunity1.Id
        );
        contractList.add(contract2); */

        Contract contract3 = new Contract(
            AccountId = testAccount.Id,
            StartDate = Date.today(),
            EndDate = Date.today().addDays(130),
            ContractTerm = 12,
            netsuite_conn__Reseller__c = testAccount2.Id,
            //Finance_Partner_Account__c = testAccount2.Id,
            Contract_C_R_In_Progress__c = TRUE,
            RecordTypeId = contractRecordType.Id,
            Deactivated__c = true,
            SBQQ__Opportunity__c = revenueOpportunity1.Id
        );
        contractList.add(contract3);
        
        /*Contract contract4 = new Contract(
            AccountId = testAccount.Id,
            StartDate = Date.today(),
            EndDate = Date.today().addDays(60),
            ContractTerm = 12,
            RecordTypeId = contractRecordType.Id,
            Deactivated__c = true,
            SBQQ__Opportunity__c = revenueOpportunity1.Id
        );
        contractList.add(contract4);*/
        
        Contract contract5 = new Contract(
            AccountId = testAccount.Id,
            StartDate = Date.today(),
            EndDate = Date.today().addDays(130),
            ContractTerm = 12,
            RecordTypeId = contractRecordType.Id,
            Deactivated__c = TRUE,
            SBQQ__Opportunity__c = revenueOpportunity1.Id,
            Contract_C_R_In_Progress__c = TRUE
        );
        contractList.add(contract5);
        
        
        insert contractList;

        // Create Subscriptions
        List<SBQQ__Subscription__c> subList = new List<SBQQ__Subscription__c>();
        
        List<Contract> contractList1 = new List<Contract>([SELECT Id, AccountId FROM Contract
                                                            WHERE Account.Name IN ('Acc1','Acc2')]);
        for(Contract con : contractList1) {
            SBQQ__Subscription__c sub1 = new SBQQ__Subscription__c(
                SBQQ__Quantity__c = 1,
                SBQQ__CustomerPrice__c = 100,
                SBQQ__Contract__c = con.id,
                SBQQ__Account__c = con.Accountid,
                SBQQ__Product__c = productList[0].Id
            );
            subList.add(sub1);
        }
        system.debug('subList size'+subList.size());
        insert subList;

        // Activate Contracts
        List<Contract> contractsToUpdate = [SELECT Id, Is_Active__c, Status, Deactivated__c
                                            FROM Contract WHERE Account.Name IN ('Acc1','Acc2')];
        for(Contract cont : contractsToUpdate) {
           cont.Status = 'Activated';
        }
        system.debug('contractsToUpdate size---'+contractsToUpdate.size());
        update contractsToUpdate;
        
    }
    
    
    @IsTest
    public static void testIneligibleContract(){
        Test.startTest();
            Account acc1 = [select id, BillingCountry, Segment__c from account where name = 'Acc1' limit 1];
            System.debug('Segment__c--'+acc1.Segment__c);
            System.debug('BillingCountry----'+acc1.BillingCountry);
            Flex_ControlCenterHelper.getEligibleContracts(acc1.id);  
        Test.stopTest();
    }
    
      @IsTest
    public static void testEligibleContract(){
        Test.startTest();
            Account acc2 = [select id, BillingCountry, Segment__c from account where name = 'Acc2' limit 1];
            System.debug('Segment__c--'+acc2.Segment__c);
            Flex_ControlCenterHelper.getEligibleContracts(acc2.id);  
        Test.stopTest();
    }
}