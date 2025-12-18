/**
* @description       : 
* @author            : Navees Ahmed
* @group             : 
* @last modified on  : 07-02-2023
* @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
@IsTest
public class ConsolidateContractsTest {
    @testSetup
    private static void testDataSetup() {
        SBQQ.TriggerControl.disable();
        TriggerHandler.bypass('ContractTriggerHandler');
        TriggerHandler.bypass('GS_AccountTriggerHandler');
        TriggerHandler.bypass('OpportunityTriggerHandler');
        TriggerHandler.bypass('OpportunityTeamMemberTriggerHandler');
        OpportunityTriggerHandler.addCall('beforeUpdate');
        OpportunityTriggerHandler.addCall('afterUpdate');
        OpportunityTriggerHandler.addCall('afterInsert');        
        //Standard Pricebook
        Id pricebookId = Test.getStandardPricebookId();
        
        //Create Products
        List<Product2> products = new List<Product2>();
        Product2 vg33 = new Product2(Name= 'HW-VG33', ProductCode = 'HW-VG33', Family = 'Test',IsActive =true);
        products.add(vg33);
        Product2 vgLicense = new Product2(Name= 'LIC-VG-36MO', ProductCode = 'LIC-VG-36MO', Family = 'Test',IsActive =true,SBQQ__SubscriptionPricing__c='Fixed Price');
        products.add(vgLicense);  
        Product2 insuranceSUBSIDY = new Product2(Name= 'INS-SUBSIDY', ProductCode = 'INS-SUBSIDY', Family = 'Test',IsActive =true,SBQQ__SubscriptionPricing__c='Fixed Price');
        products.add(insuranceSUBSIDY);  
        insert products;
        
        //Create PriceBookEntries
        List<PricebookEntry> pricebookEntries = new List<PricebookEntry>();
        PricebookEntry vg33PB = new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = vg33.Id, UnitPrice = 10000, IsActive = true);
        pricebookEntries.add(vg33PB);
        PricebookEntry vgLicensePB = new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = vgLicense.Id, UnitPrice = 10000, IsActive = true);
        pricebookEntries.add(vgLicensePB);
        PricebookEntry insuranceSUBSIDYPB = new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = insuranceSUBSIDY.Id, UnitPrice = 10000, IsActive = true);
        pricebookEntries.add(insuranceSUBSIDYPB);
        insert pricebookEntries;        
        Account account = new Account ();
        account = TestFactory.initializeAccount('Test Account');
        insert account;
        
        User currentUser = [Select Id from User WHERE Id =:UserInfo.getUserId()];
        
        //Create Opportunity
        List<Opportunity> newOpportunities = new List<Opportunity>();
        Opportunity revenueOpportunity1 = new Opportunity( AccountId = account.Id, License_Term__c =36, Pricebook2Id = pricebookId, 
                                                          Max_Approved_Discount__c=0, Name = 'Revenue Opportunity1', Price_Book_Name__c = 'Standard Price Book', 
                                                          CloseDate = System.today() + 90, StageName = 'Incubate', Owner_Role_Copy__c='Fleet IS AE2 NA US Team 8'); 
        newOpportunities.add(revenueOpportunity1);
        Opportunity revenueOpportunity2 = new Opportunity( AccountId = account.Id, License_Term__c =36, Pricebook2Id = pricebookId, 
                                                          Max_Approved_Discount__c=0, Name = 'Revenue Opportunity2', Price_Book_Name__c = 'Standard Price Book', 
                                                          CloseDate = System.today() + 90, StageName = 'Incubate', Owner_Role_Copy__c='Fleet IS AE2 NA US Team 8'); 
        newOpportunities.add(revenueOpportunity2);        
        Opportunity renewalOpportunity1 = new Opportunity( AccountId = account.Id, License_Term__c =36, Pricebook2Id = pricebookId, 
                                                          Max_Approved_Discount__c=0, Name = 'Renewal Opportunity1', Price_Book_Name__c = 'Standard Price Book', 
                                                          CloseDate = System.today() + 90, StageName = 'Incubate', Owner_Role_Copy__c='Fleet IS AE2 NA US Team 8', Shipping_Address_NEW__c=null); 
        
        newOpportunities.add(renewalOpportunity1); 
        Opportunity renewalOpportunity2 = new Opportunity( AccountId = account.Id, License_Term__c =36, Pricebook2Id = pricebookId, 
                                                          Max_Approved_Discount__c=0, Name = 'Renewal Opportunity2', Price_Book_Name__c = 'Standard Price Book', 
                                                          CloseDate = System.today() + 90, StageName = 'Incubate', Owner_Role_Copy__c='Fleet IS AE2 NA US Team 8', Shipping_Address_NEW__c=null); 
        
        newOpportunities.add(renewalOpportunity2);         
        insert newOpportunities; 
        List<Contract> listC=new List<Contract>();  
        Contract contract1 = new Contract(
            AccountId = account.Id,
            StartDate = Date.today(),
            EndDate = Date.today().adddays(130),
            ContractTerm = 12,
            SBQQ__Opportunity__c=revenueOpportunity1.Id
        );
        listC.add(contract1);     
        Contract contract2 = new Contract(
            AccountId = account.Id,
            StartDate = Date.today(),
            EndDate = Date.today().adddays(130),
            ContractTerm = 12,
            SBQQ__Opportunity__c=revenueOpportunity2.Id
        );
        listC.add(contract2);
        
        Contract contract3 = new Contract(
            AccountId = account.Id,
            StartDate = Date.today(),
            EndDate = Date.today().adddays(130),
            ContractTerm = 12,
            SBQQ__Opportunity__c=revenueOpportunity1.Id,
            SBQQ__RenewalOpportunity__c = renewalOpportunity1.Id
        );
        listC.add(contract3);
        
        Contract contract4 = new Contract(
            AccountId = account.Id,
            StartDate = Date.today(),
            EndDate = Date.today().adddays(130),
            ContractTerm = 12,
            SBQQ__Opportunity__c=revenueOpportunity2.Id,
            SBQQ__RenewalOpportunity__c = renewalOpportunity2.Id
        );
        listC.add(contract4);
        insert listC;
        
        List<Contract_Consolidation_Request__c> ccrList = new List<Contract_Consolidation_Request__c>();
    
    // Mark first contract as master in consolidation
    Contract_Consolidation_Request__c masterCCR = new Contract_Consolidation_Request__c(
        Name = 'TestMasterCCR',
        Contract__c = listC[0].Id,
        Master_Contract__c = true,  // ← This covers master=true branch
        Status__c = 'New'
    );
    ccrList.add(masterCCR);
    
    // Mark second contract as child in consolidation  
    Contract_Consolidation_Request__c childCCR = new Contract_Consolidation_Request__c(
        Name = 'TestChildCCR',
        Contract__c = listC[1].Id,
        Master_Contract__c = false, // ← This covers master=false branch
        Status__c = 'New'
    );
    ccrList.add(childCCR);
    
    insert ccrList;
    
    // Also test with Consolidated_Master_Contract__c relationships
    listC[0].Consolidated_Master_Contract__c = listC[0].Id; // ← Self-reference for master
    listC[1].Consolidated_Master_Contract__c = listC[0].Id; // ← Reference to master
    }    
    public static void createQuoteData(){
        Account testAccount = [SELECT id, Name, BillingCountry FROM Account WHERE Name like '%Test Account%'];
        Map<String,Opportunity> mapOpps=new Map<String,Opportunity>();
        for(Opportunity testOpportunity : [SELECT id, Name From Opportunity]){
            mapOpps.put(testOpportunity.Name,testOpportunity);
        }        
        Map<String,Contract> mapContracts=new Map<String,Contract>();
        for(Contract ctt : [SELECT Id,ContractNumber, StartDate,EndDate,SBQQ__Opportunity__r.Name FROM Contract]){
            mapContracts.put(ctt.SBQQ__Opportunity__r.Name,ctt);
        }
        Product2 vgProduct = [SELECT id FROM Product2 WHERE Name = 'LIC-VG-36MO'];
        PricebookEntry pricebookEntry = [SELECT id, Product2Id, UnitPrice FROM PricebookEntry WHERE Product2Id =: vgProduct.Id]; 
        createRenewalQuoteData(testAccount,mapOpps,mapContracts,vgProduct,pricebookEntry);
        //createRenewalQuoteData(testAccount,mapOpps.get('Revenue Opportunity2'),mapContracts.get('Revenue Opportunity2'),vgProduct,pricebookEntry);
    }
    public static void createRenewalQuoteData(Account testAccount,Map<String,Opportunity> mapOpps,Map<String,Contract> mapContracts,Product2 vgProduct,PricebookEntry pricebookEntry){
        List<SBQQ__Quote__c> listQ=new List<SBQQ__Quote__c>();
        for(Opportunity o: mapOpps.values()){
            SBQQ__Quote__c quote = new SBQQ__Quote__c(Quote_Name__c = 'Test Version', SBQQ__Opportunity2__c =o.Id, 
                                                      SBQQ__Primary__c = false, SBQQ__Type__c='Quote');
            listQ.add(quote);
        }
        
        insert listQ;
        
        List<SBQQ__QuoteLine__c> newlineItems = new List<SBQQ__QuoteLine__c>();
        for(SBQQ__Quote__c q:listQ){
            SBQQ__QuoteLine__c quoteLineOne =  new SBQQ__QuoteLine__c(SBQQ__Quote__c = q.Id, SBQQ__PricebookEntryId__c = pricebookEntry.Id, SBQQ__Quantity__c  = 5, 
                                                                      SBQQ__Discount__c = 0, SBQQ__Product__c = vgProduct.Id, accountLookupTest__c = testAccount.Id);
            newlineItems.add(quoteLineOne); 
            
            /*SBQQ__QuoteLine__c quoteLineTwo =  new SBQQ__QuoteLine__c(SBQQ__Quote__c = q.Id, SBQQ__PricebookEntryId__c = pricebookEntry.Id, SBQQ__Quantity__c  = 5, 
SBQQ__Discount__c = 0, SBQQ__Product__c = vgProduct.Id, accountLookupTest__c = testAccount.Id);
newlineItems.add(quoteLineTwo);*/
        }
        insert newlineItems;
        /*List<SBQQ__Subscription__c> subscriptionList = new List<SBQQ__Subscription__c>();
for(Contract ctt:mapContracts.values()){
SBQQ__Subscription__c subscription2 = new SBQQ__Subscription__c(
//SBQQ__QuoteLine__c=quoteLineTwo.Id,
SBQQ__NetPrice__c = 10,
SBQQ__RenewalQuantity__c = 10,
SBQQ__Quantity__c = 10,
SBQQ__BundledQuantity__c=10,
SBQQ__Product__c = vgProduct.Id,
SBQQ__Contract__c = ctt.Id,
//SBQQ__SubscriptionStartDate__c = ctt.StartDate.addYears(1).addDays(2),
Renewal_LineItem_Type__c = 'Downsell'
);
subscriptionList.add(subscription2);
}

insert subscriptionList;  */
    }    
    public static void createSubscriptions(Map<String,Contract> mapContracts,Product2 vgProduct){
        List<SBQQ__Subscription__c> subscriptionList = new List<SBQQ__Subscription__c>();
        for(Contract ctt:mapContracts.values()){
            SBQQ__Subscription__c subscription2 = new SBQQ__Subscription__c(
                //SBQQ__QuoteLine__c=quoteLineTwo.Id,
                SBQQ__NetPrice__c = 10,
                SBQQ__RenewalQuantity__c = 10,
                SBQQ__Quantity__c = 10,
                SBQQ__BundledQuantity__c=10,
                SBQQ__Product__c = vgProduct.Id,
                SBQQ__Contract__c = ctt.Id,
                //SBQQ__SubscriptionStartDate__c = ctt.StartDate.addYears(1).addDays(2),
                Renewal_LineItem_Type__c = 'Downsell'
            );
            subscriptionList.add(subscription2);
        }
        
        insert subscriptionList;  
    }
    @IsTest
    public static void testGetAccountAndActiveContracts() {
        SBQQ.TriggerControl.disable();
        TriggerHandler.bypass('ContractTriggerHandler');
        TriggerHandler.bypass('GS_AccountTriggerHandler');
        TriggerHandler.bypass('OpportunityTriggerHandler');
        TriggerHandler.bypass('OpportunityTeamMemberTriggerHandler');
        OpportunityTriggerHandler.addCall('beforeUpdate');
        OpportunityTriggerHandler.addCall('afterUpdate');
        OpportunityTriggerHandler.addCall('afterInsert');  
        Product2 vgProduct = [SELECT id FROM Product2 WHERE Name = 'LIC-VG-36MO'];
        Account acc = [SELECT id, Name, BillingCountry FROM Account WHERE Name like '%Test Account%'];
        Map<String,Opportunity> mapOpps=new Map<String,Opportunity>();
        for(Opportunity testOpportunity : [SELECT id, Name From Opportunity]){
            mapOpps.put(testOpportunity.Name,testOpportunity);
        }           
        Map<String,Contract> mapContracts=new Map<String,Contract>();
        for(Contract ctt : [SELECT Id,ContractNumber, StartDate,EndDate,SBQQ__Opportunity__r.Name FROM Contract]){
            ctt.Status='Activated';
            mapContracts.put(ctt.SBQQ__Opportunity__r.Name,ctt);
        }
        update mapContracts.values();          
        createSubscriptions(mapContracts,vgProduct);
        Test.startTest();     
        createQuoteData();
        Test.stopTest();
        List<Contract_Consolidation_Request__c> ccrList = new List<Contract_Consolidation_Request__c>();
        for(Contract ctt : mapContracts.values()){
            ccrList.add(new Contract_Consolidation_Request__c(Name = 'CCR-001', Contract__c = ctt.Id, Status__c = 'Quoted UnChecked'));
        }        
        
        insert ccrList;
        System.debug('ccrList: '+ccrList);
        RenewContractsLWC.AccountWrapper result = RenewContractsLWC.getAccountAndActiveContracts(null);
        System.assertEquals('Invalid account', result.errorMessage);
        result = RenewContractsLWC.getAccountAndActiveContracts('abc');
        System.assertEquals('Invalid account', result.errorMessage);        
        result = RenewContractsLWC.getAccountAndActiveContracts(String.valueOf(acc.Id));
        
        // Assertion
        System.assertEquals(acc.Name, result.accountName);
        //System.assertEquals(2, result.activeContracts.size());
        //System.assert(String.isNotBlank(result.activeContracts[0].contractURL));
    }
    
    @IsTest
    public static void testRenewContracts() {
        SBQQ.TriggerControl.disable();
        TriggerHandler.bypass('ContractTriggerHandler');
        TriggerHandler.bypass('GS_AccountTriggerHandler');
        TriggerHandler.bypass('OpportunityTriggerHandler');
        TriggerHandler.bypass('OpportunityTeamMemberTriggerHandler');
        OpportunityTriggerHandler.addCall('beforeUpdate');
        OpportunityTriggerHandler.addCall('afterUpdate');
        OpportunityTriggerHandler.addCall('afterInsert');     
        Product2 vgProduct = [SELECT id FROM Product2 WHERE Name = 'LIC-VG-36MO'];
        Account acc = [SELECT id, Name, BillingCountry FROM Account WHERE Name like '%Test Account%'];
        Map<String,Opportunity> mapOpps=new Map<String,Opportunity>();
        for(Opportunity testOpportunity : [SELECT id, Name From Opportunity]){
            mapOpps.put(testOpportunity.Name,testOpportunity);
        }     
        Map<String,Contract> mapContracts=new Map<String,Contract>();
        for(Contract ctt : [SELECT Id,ContractNumber,AccountId,StartDate,EndDate,SBQQ__Opportunity__r.Name FROM Contract]){
            mapContracts.put(ctt.SBQQ__Opportunity__r.Name,ctt);
        }        
        createSubscriptions(mapContracts,vgProduct);       
        // Map<String,Contract> mapContracts=new Map<String,Contract>();
        for(Contract ctt : [SELECT Id,ContractNumber,AccountId,StartDate,EndDate,SBQQ__Opportunity__r.Name,Is_Active__c,Deactivated__c FROM Contract]){
            System.debug('ctt.SBQQ__Opportunity__r.Name==='+ctt.SBQQ__Opportunity__r.Name);
            System.debug('ctt.Deactivated__c==='+ctt.Deactivated__c);
            System.debug('ctt.Is_Active__c==='+ctt.Is_Active__c);
            System.debug('ctt.ContractNumber==='+ctt.ContractNumber);
            ctt.SBQQ__RenewalOpportunity__c=mapOpps.get('Renewal Opportunity'+ctt.SBQQ__Opportunity__r.Name.replace('Revenue Opportunity','')).Id;
            ctt.Status='Activated';
            ctt.Deactivated__c=false;
            mapContracts.put(ctt.SBQQ__Opportunity__r.Name,ctt);
        }
        update mapContracts.values();    
        for(Contract ctt : [SELECT Id,ContractNumber, StartDate,EndDate,SBQQ__Opportunity__r.Name,Is_Active__c,Deactivated__c FROM Contract]){
            System.debug('ctt.SBQQ__Opportunity__r.Name1==='+ctt.SBQQ__Opportunity__r.Name);
            System.debug('ctt.Deactivated__c1==='+ctt.Deactivated__c);
            System.debug('ctt.Is_Active__c1==='+ctt.Is_Active__c);
            System.debug('ctt.ContractNumber1==='+ctt.ContractNumber);
        }            
        //createSubscriptions(mapContracts,vgProduct);           
        
        Test.startTest();
        createQuoteData();
        
        RenewContractsLWC.ContractWrapper masterContractWrapper = new RenewContractsLWC.ContractWrapper();
        masterContractWrapper.c = mapContracts.get('Revenue Opportunity1');
        
        RenewContractsLWC.ContractWrapper childContractWrapper = new RenewContractsLWC.ContractWrapper();
        childContractWrapper.c = mapContracts.get('Revenue Opportunity2');
        
        List<RenewContractsLWC.ContractWrapper> selectedMasterContracts = new List<RenewContractsLWC.ContractWrapper>();
        selectedMasterContracts.add(masterContractWrapper);
        
        List<RenewContractsLWC.ContractWrapper> selectedChildContracts = new List<RenewContractsLWC.ContractWrapper>();
        selectedChildContracts.add(childContractWrapper);
        
        String result = RenewContractsLWC.renewContracts(acc.Id, selectedChildContracts, selectedMasterContracts);
        
        for(Contract ctt : [SELECT Id,ContractNumber,AccountId,StartDate,EndDate,SBQQ__Opportunity__r.Name,Is_Active__c,Deactivated__c,SBQQ__RenewalQuoted__c FROM Contract]){
            System.debug('ctt.SBQQ__Opportunity__r.Name2==='+ctt.SBQQ__Opportunity__r.Name);
            System.debug('ctt.Deactivated__c2==='+ctt.Deactivated__c);
            System.debug('ctt.Is_Active__c2==='+ctt.Is_Active__c);
            System.debug('ctt.SBQQ__RenewalQuoted__c2==='+ctt.SBQQ__RenewalQuoted__c);
            System.debug('ctt.ContractNumber2==='+ctt.ContractNumber);
        }         
        List<Contract_Consolidation_Request__c> ccr=[Select Id,Name,Contract__c,Master_Contract__c,Status__c,CreatedDate from Contract_Consolidation_Request__c where Master_Contract__c=false];
        
       //JobConsolidateContracts j=new JobConsolidateContracts(ccr[0].Name);
       // j.execute(null,ccr);
        
        Test.stopTest();
        // Assertion
        //Abu:--> Commenting Assetion Statement
        //System.assertEquals('Saved successfully. You will get a notification once renewal and consolidation is completed.', result);
        //QueueableContractConsolidationTest --> Abu 06/29/23
        
        
    }
    
    @IsTest
    public static void testGetQuarterPeriod() {
        Test.startTest();
        // Get current fiscal year
        Period currentQuarter = [SELECT FiscalYearSettings.Name, Number FROM Period WHERE Type = 'Quarter' AND StartDate = THIS_FISCAL_QUARTER LIMIT 1];
        Period result = RenewContractsLWC.getQuarterPeriod(currentQuarter.Number, currentQuarter.FiscalYearSettings.Name);
        Test.stopTest();
    }
    
    @IsTest
    public static void testGetFiscalYears() {
        Test.startTest();
        Account acc = [Select id from account limit 1];
        List<RenewContractsLWC.FiscalYearDTO> result = RenewContractsLWC.getFiscalYears(acc.id);
        Test.stopTest();
    }
    
    @IsTest
    public static void testGetCurrentQuarterAndYear() {
        Test.startTest();
        Map<String, String> result = RenewContractsLWC.getCurrentQuarterAndYear();
        Test.stopTest();
    }
    
    @IsTest
    public static void testIsSystemAdministrator() {
        Test.startTest();
        Boolean result = RenewContractsLWC.isSystemAdministrator();
        Test.stopTest();
    }
    
}