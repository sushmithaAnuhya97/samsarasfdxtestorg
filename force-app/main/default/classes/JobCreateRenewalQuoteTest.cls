@isTest(SeeAllData=false)
public with sharing class JobCreateRenewalQuoteTest {
    
    @testSetup
    private static void testDataSetup() {

        insert new Global_Automation_Settings__c(Allow_Handler_Selection__c = true);
        //Standard Pricebook
        Id pricebookId = Test.getStandardPricebookId();
       
         Pricebook2 standardPricebook = new Pricebook2(
            Id = Test.getStandardPricebookId(),
            Name = 'Standard Price Book',
            IsActive = true
        );
        Update standardPricebook;
        
        //Create Products
        List<Product2> products = new List<Product2>();
        Product2 vg33 = new Product2(Name= 'HW-VG33', ProductCode = 'HW-VG33', Family = 'Test');
        products.add(vg33);
       /* Product2 vgLicense = new Product2(Name= 'LIC-VG-36MO', ProductCode = 'LIC-VG-36MO', Family = 'Test');
        products.add(vgLicense);  
        Product2 insuranceSUBSIDY = new Product2(Name= 'INS-SUBSIDY', ProductCode = 'INS-SUBSIDY', Family = 'Test');
        products.add(insuranceSUBSIDY); */ 
        insert products;
        
        //Create PriceBookEntries
        List<PricebookEntry> pricebookEntries = new List<PricebookEntry>();
        PricebookEntry vg33PB = new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = vg33.Id, UnitPrice = 10000, IsActive = true);
        pricebookEntries.add(vg33PB);
        /*PricebookEntry vgLicensePB = new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = vgLicense.Id, UnitPrice = 10000, IsActive = true);
        pricebookEntries.add(vgLicensePB);
        PricebookEntry insuranceSUBSIDYPB = new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = insuranceSUBSIDY.Id, UnitPrice = 10000, IsActive = true);
        pricebookEntries.add(insuranceSUBSIDYPB);*/
        insert pricebookEntries;        
        Account account = new Account ();
        account = TestFactory.initializeAccount('Test Account');
        insert account;
        List<Contract> contracts = new List<Contract>();
        Contract contract = new Contract(
                AccountId = account.Id,
                StartDate = Date.today(),
                EndDate =Date.today().addMonths(12),
                ContractTerm = 12
        );
        contracts.add(contract);
        Contract contract2 = new Contract(
                AccountId = account.Id,
                StartDate = Date.today(),
                EndDate =Date.today().addMonths(24),
                ContractTerm = 24
        );
        contracts.add(contract2);
        insert contracts;
        List<Opportunity> lstOps = new List<opportunity>();
        Opportunity revenueOpportunity = new Opportunity( AccountId = account.Id, License_Term__c =12, Pricebook2Id = pricebookId, 
                                                         Max_Approved_Discount__c=0, Name = 'Revenue Opportunity1', 
                                                         Price_Book_Name__c = 'Standard Price Book', StageName = 'Qualified',
                                                         CloseDate = Date.today(),  
                                                         License_End_Date__c = Date.today().addMonths(12), 
                                                         Owner_Role_Copy__c='Fleet IS AE2 NA US Team 8');
        lstOps.add(revenueOpportunity);
        
        Opportunity revenueOpportunity2 = new Opportunity( AccountId = account.Id, License_Term__c =12, Pricebook2Id = pricebookId, 
                                                         Max_Approved_Discount__c=0, Name = 'Revenue Opportunity2', 
                                                         Price_Book_Name__c = 'Standard Price Book', StageName = 'Qualified',
                                                         CloseDate = Date.today(), 
                                                         License_End_Date__c = Date.today().addMonths(24),
                                                         Owner_Role_Copy__c='Fleet IS AE2 NA US Team 8');
        lstOps.add(revenueOpportunity2);
        insert lstOps; 

        contracts[0].SBQQ__RenewalOpportunity__c = revenueOpportunity.id;
        contracts[1].SBQQ__RenewalOpportunity__c = revenueOpportunity2.id;
        contracts[0].SBQQ__RenewalTerm__c = 12;
        contracts[1].SBQQ__RenewalTerm__c = 12;

        update contracts;
        account.Latest_Active_Contract__c=contracts[1].Id;
        update account;
    }
    /*@IsTest
    private static void testSuccessfulUpdate(){
               
        String chron = '0 1 * * * ?';
        Test.startTest();
            JobRenewalCoTerm myClass = new JobRenewalCoTerm(); 
            system.schedule('Test Sched', chron, myClass);
        
            //database.executebatch(new JobClickpathCoTerming(),2);
        Test.stopTest();
    }  
    @IsTest
    private static void testContractExpiringSoon(){
        Account account=[Select Id,Latest_Active_Contract__c From Account limit 1];
        Contract latestActiveContract=new Contract(Id=account.Latest_Active_Contract__c,EndDate=Date.today().addDays(15));
        update latestActiveContract;
        String chron = '0 1 * * * ?';
        Test.startTest();
            JobRenewalCoTerm myClass = new JobRenewalCoTerm(); 
            system.schedule('Test Sched', chron, myClass);
        
            //database.executebatch(new JobClickpathCoTerming(),2);
        Test.stopTest();
    }      
    */
    
     @IsTest
    private static void testContract(){
        contract con =[Select Id,SBQQ__RenewalOpportunity__c from contract where SBQQ__RenewalOpportunity__c != null limit 1];
        if(con.SBQQ__RenewalOpportunity__c != null) {
            opportunity opp = new Opportunity();
            opp.Id = con.SBQQ__RenewalOpportunity__c;
            opp.SBQQ__RenewedContract__c = con.Id;
            opp.Selected_Payment_Type__c = 'Upfront Payments';
           new JobCreateRenewalQuote().byPassTriggers();
            con.SBQQ__Opportunity__c = con.SBQQ__RenewalOpportunity__c;
            con.Adjusted_RenewalOpp_EndDate__c = Date.Today();
            update con;
            update opp;
            
        }
      
        Test.startTest();
           
        database.executebatch(new JobCreateRenewalQuote(1,new Set<string>{con?.Id}),2);
        JobCreateRenewalQuote myClass = new JobCreateRenewalQuote(); 
        String chron = '0 1 * * * ?';
            system.schedule('Test Sched', chron, myClass);
        Test.stopTest();
    } 
    
    
    @IsTest
    private static void testContract1(){
        contract con =[Select Id,SBQQ__RenewalOpportunity__c from contract limit 1];
        if(con.SBQQ__RenewalOpportunity__c != null) {
            opportunity opp = new Opportunity();
            opp.Id = con.SBQQ__RenewalOpportunity__c;
            opp.SBQQ__RenewedContract__c = con.Id;
            opp.Selected_Payment_Type__c = 'Direct Annual';
           new JobCreateRenewalQuote().byPassTriggers();
            con.SBQQ__Opportunity__c = con.SBQQ__RenewalOpportunity__c;
               con.Adjusted_RenewalOpp_EndDate__c = Date.Today();
            update con;
            update opp;
            
        }
      
        Test.startTest();
           
        database.executebatch(new JobCreateRenewalQuote(1,new Set<string>{con?.Id}),2);
        JobCreateRenewalQuote myClass = new JobCreateRenewalQuote(); 
        String chron = '0 1 * * * ?';
            system.schedule('Test Sched', chron, myClass);
        Test.stopTest();
    } 
    
    
}