@IsTest(SeeAllData=false)
public class ContractRenewalQueueableTest {
    
    @testSetup
    static void setupTestData() {
        // To bypass triggers
        bypass();
        Id pricebookId = Test.getStandardPricebookId();
        
        // Create Products
        List<Product2> products = new List<Product2>();
        Product2 testpro1 = new Product2(Name= 'LIC-VG-ENT', ProductCode = 'LIC-VG-ENT', Family = 'Telematics', CPQ_Enabled_Product__c = true, CurrencyIsoCode = 'USD');
        products.add(testpro1);
        Product2 testpro2 = new Product2(Name= 'LIC-VG-ENT-PLTFM-PREM', ProductCode = 'LIC-VG-ENT-PLTFM-PREM', Family = 'Telematics', CPQ_Enabled_Product__c = true, CurrencyIsoCode = 'USD');
        products.add(testpro2);  
        Product2 testpro3 = new Product2(Name= 'LIC-CM1-ENT', ProductCode = 'LIC-CM1-ENT', Family = 'Safety', CPQ_Enabled_Product__c = true, CurrencyIsoCode = 'USD');
        products.add(testpro3);
        Product2 testpro4 = new Product2(Name= 'LIC-CM-S-PREM-PLTFM-PREM', ProductCode = 'LIC-CM-S-PREM-PLTFM-PREM', Family = 'Safety', CPQ_Enabled_Product__c = true, CurrencyIsoCode = 'USD');
        products.add(testpro4);
        Product2 testpro5 = new Product2(Name= 'LIC-CM2-ENT', ProductCode = 'LIC-CM2-ENT', Family = 'Telematics', CPQ_Enabled_Product__c = true, CurrencyIsoCode = 'USD');
        products.add(testpro5);
        Product2 testpro6 = new Product2(Name= 'LIC-CM-D-PREM-PLTFM-PREM', ProductCode = 'LIC-CM-D-PREM-PLTFM-PREM', Family = 'Safety', CPQ_Enabled_Product__c = true, CurrencyIsoCode = 'USD');
        products.add(testpro6);
        Product2 testpro7 = new Product2(Name= 'LIC-CM1-PRO', ProductCode = 'LIC-CM1-PRO', Family = 'Safety', CPQ_Enabled_Product__c = true, CurrencyIsoCode = 'USD');
        products.add(testpro7);
        Product2 testpro8 = new Product2(Name= 'LIC-CM2-PRO', ProductCode = 'LIC-CM2-PRO', Family = 'Safety', CPQ_Enabled_Product__c = true, CurrencyIsoCode = 'USD');
        products.add(testpro8);
        Product2 testpro9 = new Product2(Name= 'LIC-TRLR-ESS', ProductCode = 'LIC-TRLR-ESS', Family = 'STCE', CPQ_Enabled_Product__c = true, CurrencyIsoCode = 'USD');
        products.add(testpro9);
        Product2 testpro10 = new Product2(Name= 'LIC-TRLR-ESS-PLTFM-PREM', ProductCode = 'LIC-TRLR-ESS-PLTFM-PREM', Family = 'STCE', CPQ_Enabled_Product__c = true, CurrencyIsoCode = 'USD');
        products.add(testpro10);
        Product2 testpro11 = new Product2(Name= 'LIC-CM-S-ENT-PLTFM-PREM', ProductCode = 'LIC-CM-S-ENT-PLTFM-PREM', Family = 'Safety', CPQ_Enabled_Product__c = true, CurrencyIsoCode = 'USD');
        products.add(testpro11);
        Product2 testpro12 = new Product2(Name= 'LIC-CM-D-ENT-PLTFM-PREM', ProductCode = 'LIC-CM-D-ENT-PLTFM-PREM', Family = 'Safety', CPQ_Enabled_Product__c = true, CurrencyIsoCode = 'USD');
        products.add(testpro12);
        insert products;
        
        // Create Pricebook Entries
        List<PricebookEntry> pricebookEntries = new List<PricebookEntry>();
        PricebookEntry testPB1 = new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = testpro1.Id, UnitPrice = 120, IsActive = true, CurrencyIsoCode = 'USD');
        pricebookEntries.add(testPB1);
        PricebookEntry testPB2 = new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = testpro2.Id, UnitPrice = 120, IsActive = true, CurrencyIsoCode = 'USD');
        pricebookEntries.add(testPB2);
        PricebookEntry testPB3 = new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = testpro3.Id, UnitPrice = 120, IsActive = true, CurrencyIsoCode = 'USD');
        pricebookEntries.add(testPB3);
        PricebookEntry testPB4 = new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = testpro4.Id, UnitPrice = 120, IsActive = true, CurrencyIsoCode = 'USD');
        pricebookEntries.add(testPB4);
        PricebookEntry testPB5 = new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = testpro5.Id, UnitPrice = 120, IsActive = true, CurrencyIsoCode = 'USD');
        pricebookEntries.add(testPB5);
        PricebookEntry testPB6 = new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = testpro6.Id, UnitPrice = 120, IsActive = true, CurrencyIsoCode = 'USD');
        pricebookEntries.add(testPB6);
        PricebookEntry testPB7 = new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = testpro7.Id, UnitPrice = 120, IsActive = true, CurrencyIsoCode = 'USD');
        pricebookEntries.add(testPB7);
        PricebookEntry testPB8 = new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = testpro8.Id, UnitPrice = 120, IsActive = true, CurrencyIsoCode = 'USD');
        pricebookEntries.add(testPB8);
        PricebookEntry testPB9 = new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = testpro9.Id, UnitPrice = 120, IsActive = true, CurrencyIsoCode = 'USD');
        pricebookEntries.add(testPB9);
        PricebookEntry testPB10 = new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = testpro10.Id, UnitPrice = 120, IsActive = true, CurrencyIsoCode = 'USD');
        pricebookEntries.add(testPB10);
        PricebookEntry testPB11 = new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = testpro11.Id, UnitPrice = 120, IsActive = true, CurrencyIsoCode = 'USD');
        pricebookEntries.add(testPB11);
        PricebookEntry testPB12 = new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = testpro12.Id, UnitPrice = 120, IsActive = true, CurrencyIsoCode = 'USD');
        pricebookEntries.add(testPB12);
        insert pricebookEntries;
        
        // Create Accounts
        List<Account> accounts = new List<Account>();
        Account acc = new Account(Name = 'Test Account', Organization_Size__c='1 - 99', BillingCountry='United States', BillingState='New York', CurrencyIsoCode = 'USD');
        accounts.add(acc);
        Account acc1 = new Account(Name = 'Test Account1', Organization_Size__c='1 - 99', BillingCountry='United States', BillingState='New York', CurrencyIsoCode = 'USD');
        accounts.add(acc1);
        insert accounts;
        //Create Opportunity
        List<Opportunity> renewaloppties = new List<Opportunity>();
        Opportunity renewalopp = new Opportunity(Name = 'RenewalOpportunity', AccountId = acc.Id, StageName = 'Prospecting', CloseDate = Date.today(), CurrencyIsoCode = 'USD');
        renewaloppties.add(renewalopp);
        Opportunity renewalopp1 = new Opportunity(Name = 'RenewalOpportunity1', AccountId = acc.Id, StageName = 'Prospecting', CloseDate = Date.today(), CurrencyIsoCode = 'USD');
        renewaloppties.add(renewalopp1);
        Opportunity renewalopp2 = new Opportunity(Name = 'RenewalOpportunity2', AccountId = acc1.Id, StageName = 'Prospecting', CloseDate = Date.today(), CurrencyIsoCode = 'USD');
        renewaloppties.add(renewalopp2);
        Opportunity renewalopp3 = new Opportunity(Name = 'RenewalOpportunity3', AccountId = acc1.Id, StageName = 'Prospecting', CloseDate = Date.today(), CurrencyIsoCode = 'USD');
        renewaloppties.add(renewalopp3);
        insert renewaloppties;
        
        //Create Contract
        List<Contract> Contracts = new List<Contract>();
        Contract con = new Contract(AccountId = acc.Id, Status = 'Draft', P_P_Renewals__c= false, StartDate = Date.today(), ContractTerm = 36, SBQQ__RenewalOpportunity__c = renewalopp.Id, CurrencyIsoCode = 'USD');
        Contracts.add(con);
        Contract con1 = new Contract(AccountId = acc.Id, Status = 'Draft', P_P_Renewals__c= false, StartDate = Date.today(), ContractTerm = 36, SBQQ__RenewalOpportunity__c = renewalopp1.Id, CurrencyIsoCode = 'USD');
        Contracts.add(con1);
        Contract con2 = new Contract(AccountId = acc1.Id, Status = 'Draft', P_P_Renewals__c= false, StartDate = Date.today(), ContractTerm = 36, SBQQ__RenewalOpportunity__c = renewalopp2.Id, CurrencyIsoCode = 'USD');
        Contracts.add(con2);
        Contract con3 = new Contract(AccountId = acc1.Id, Status = 'Draft', P_P_Renewals__c= false, StartDate = Date.today(), ContractTerm = 36, SBQQ__RenewalOpportunity__c = renewalopp3.Id, CurrencyIsoCode = 'USD');
        Contracts.add(con3);
        insert Contracts;
        
        
        // Create Product Mapping
        List<Product_Mapping__c> ProductMapping = new List<Product_Mapping__c>();
        Product_Mapping__c pm = new Product_Mapping__c(Legacy_Product__c =testpro1.Id ,Replacement_Product__c =testpro2.Id,Active__c = true,Delete_Product__c=false, Action__c = 'Replace');
        ProductMapping.add(pm);
        Product_Mapping__c pm2 = new Product_Mapping__c(Legacy_Product__c =testpro7.Id ,Replacement_Product__c =testpro11.Id, Dependent_Product__c=testpro3.Id,Active__c = true,Delete_Product__c=true, Action__c = 'Replace');
        ProductMapping.add(pm2);
        Product_Mapping__c pm3 = new Product_Mapping__c(Legacy_Product__c =testpro3.Id ,Replacement_Product__c =testpro4.Id,Active__c = true,Delete_Product__c=false, Action__c = 'Replace');
        ProductMapping.add(pm3);
        Product_Mapping__c pm4 = new Product_Mapping__c(Legacy_Product__c =testpro9.Id ,Replacement_Product__c =testpro10.Id,Active__c = true,Delete_Product__c=false, Action__c = 'Replace');
        ProductMapping.add(pm4);
        Product_Mapping__c pm5 = new Product_Mapping__c(Legacy_Product__c =testpro8.Id ,Replacement_Product__c =testpro12.Id, Dependent_Product__c=testpro5.Id,Active__c = true,Delete_Product__c=true, Action__c = 'Replace');
        ProductMapping.add(pm5);
        Product_Mapping__c pm6 = new Product_Mapping__c(Legacy_Product__c =testpro5.Id ,Replacement_Product__c =testpro6.Id,Active__c = true,Delete_Product__c=false, Action__c = 'Replace');
        ProductMapping.add(pm6);
        Product_Mapping__c pm7 = new Product_Mapping__c(Legacy_Product__c =testpro1.Id ,Replacement_Product__c =testpro5.Id,Active__c = true,Delete_Product__c=false, Action__c = 'Add',Free_Pricing__c = '100% Discount');
        ProductMapping.add(pm7);
        insert ProductMapping;
        
        //Create Quote
        List<SBQQ__Quote__c> quotes = new List<SBQQ__Quote__c>();
        SBQQ__Quote__c quote = new SBQQ__Quote__c(SBQQ__Opportunity2__c = renewalopp.Id, SBQQ__Account__c = acc.Id,SBQQ__Primary__c= true, CurrencyIsoCode = 'USD');
        quotes.add(quote);
        SBQQ__Quote__c quote1 = new SBQQ__Quote__c(SBQQ__Opportunity2__c = renewalopp1.Id, SBQQ__Account__c = acc.Id,SBQQ__Primary__c= true, CurrencyIsoCode = 'USD');
        quotes.add(quote1);
        SBQQ__Quote__c quote2 = new SBQQ__Quote__c(SBQQ__Opportunity2__c = renewalopp2.Id, SBQQ__Account__c = acc1.Id,SBQQ__Primary__c= true, CurrencyIsoCode = 'USD');
        quotes.add(quote2);
        SBQQ__Quote__c quote3 = new SBQQ__Quote__c(SBQQ__Opportunity2__c = renewalopp3.Id, SBQQ__Account__c = acc1.Id,SBQQ__Primary__c= true, CurrencyIsoCode = 'USD');
        quotes.add(quote3);
        insert quotes;
        //Create QuoteLine
        List<SBQQ__QuoteLine__c> quotelines = new List<SBQQ__QuoteLine__c>();
        SBQQ__QuoteLine__c quoteLine = new SBQQ__QuoteLine__c(SBQQ__Quote__c = quote.Id, SBQQ__Product__c = testpro1.Id,SBQQ__ListPrice__c=120, Product_Code_Copy__c = 'LIC-VG-ENT');
        quotelines.add(quoteLine);
        SBQQ__QuoteLine__c quoteLine3 = new SBQQ__QuoteLine__c(SBQQ__Quote__c = quote1.Id, SBQQ__Product__c = testpro3.Id,SBQQ__ListPrice__c=120, Product_Code_Copy__c = 'LIC-CM1-ENT');
        quotelines.add(quoteLine3);
        SBQQ__QuoteLine__c quoteLine5 = new SBQQ__QuoteLine__c(SBQQ__Quote__c = quote1.Id, SBQQ__Product__c = testpro7.Id,SBQQ__ListPrice__c=120, Product_Code_Copy__c = 'LIC-CM1-PRO');
        quotelines.add(quoteLine5);
        SBQQ__QuoteLine__c quoteLine7 = new SBQQ__QuoteLine__c(SBQQ__Quote__c = quote2.Id, SBQQ__Product__c = testpro5.Id,SBQQ__ListPrice__c=120, Product_Code_Copy__c = 'LIC-CM2-ENT');
        quotelines.add(quoteLine7);
        SBQQ__QuoteLine__c quoteLine8 = new SBQQ__QuoteLine__c(SBQQ__Quote__c = quote2.Id, SBQQ__Product__c = testpro8.Id,SBQQ__ListPrice__c=120, Product_Code_Copy__c = 'LIC-CM2-PRO');
        quotelines.add(quoteLine8);
        SBQQ__QuoteLine__c quoteLine9 = new SBQQ__QuoteLine__c(SBQQ__Quote__c = quote3.Id, SBQQ__Product__c = testpro9.Id,SBQQ__ListPrice__c=120, Product_Code_Copy__c = 'LIC-TRLR-ESS');
        quotelines.add(quoteLine9);
        Test.startTest();
        	insert quotelines;
        Test.stopTest();
        
    }

    public static void bypass() {
        SBQQ.TriggerControl.disable();
        TriggerHandler.bypass('ContractTriggerHandler');
        TriggerHandler.bypass('AccountTriggerHandler');
        TriggerHandler.bypass('OpportunityTriggerHandler');
        TriggerHandler.bypass('OpportunityTeamMemberTriggerHandler');
        OpportunityTriggerHandler.addCall('beforeUpdate');
        OpportunityTriggerHandler.addCall('afterUpdate');
        OpportunityTriggerHandler.addCall('afterInsert');
    }

    @isTest
    public static void testContractRenewalQueueableNewAction() {
        bypass();
        List<Contract> conList = new List<Contract>();
        Test.startTest();
        //insert quotelines;
        for(Contract cc: [SELECT ID,P_P_Renewals__c,SBQQ__RenewalOpportunity__c FROM Contract]){
           Contract con4 = new Contract();
           con4.Id = cc.Id;
           con4.P_P_Renewals__c = true;
           conList.add(con4); 
        }
        update conList;
        ContractRenewalQueueable queueableJob = new ContractRenewalQueueable('New',conList,NULL,NULL,NULL,NULL,NULL);
        System.enqueueJob(queueableJob);
        Test.stopTest();
    }
	@isTest
    public static void testContractRenewalQueueableRecalculateAction() {
        bypass();
        String vgTier;
        String vgTierPC;
        String cm1Tier;
        String cm1TierPC;
        String cm2Tier;
        String cm2TierPC;
        String trlrTier;
        String trlrTierPC;
        
        // Retrieve setup data
       // Account acc = [SELECT Id FROM Account LIMIT 1];
        List<Contract> conList = new List<Contract>();
        for(Contract cc: [SELECT ID,P_P_Renewals__c FROM Contract]){
           Contract con = new Contract();
           con.Id = cc.Id;
           con.P_P_Renewals__c = true;
           conList.add(con);
        }
        for(Product2 pp: [SELECT ID,ProductCode FROM Product2 WHERE ProductCode IN ('LIC-VG-ENT-PLTFM-PREM','LIC-CM-S-PREM-PLTFM-PREM','LIC-CM-D-PREM-PLTFM-PREM','LIC-TRLR-ESS-PLTFM-PREM')]){
            if(pp.ProductCode == 'LIC-VG-ENT-PLTFM-PREM'){
               vgTier =  pp.Id;
               vgTierPC = pp.ProductCode;
            }
            if(pp.ProductCode == 'LIC-CM-S-PREM-PLTFM-PREM'){
               cm1Tier =  pp.Id;
               cm1TierPC = pp.ProductCode;
            }
            if(pp.ProductCode == 'LIC-CM-D-PREM-PLTFM-PREM'){
               cm2Tier =  pp.Id;
               cm2TierPC = pp.ProductCode;
            }
            if(pp.ProductCode == 'LIC-TRLR-ESS-PLTFM-PREM'){
               trlrTier =  pp.Id;
               trlrTierPC = pp.ProductCode;
            }
        }
        List<SBQQ__Quote__c> quoteLstdis = [SELECT ID FROM SBQQ__Quote__c];
        List<SBQQ__QuoteLine__c> qlList = new List<SBQQ__QuoteLine__c>();
        List<SBQQ__QuoteLine__c> delQlList = new List<SBQQ__QuoteLine__c>();
        List<Id> quoteIdList = new List<Id>();
        List<SBQQ__Quote__c> qteLst = [SELECT ID FROM SBQQ__Quote__c];
        for(SBQQ__Quote__c quoteRec: qteLst){
          quoteIdList.add(quoteRec.Id);  
        }
        List<Id> qteList = new List<Id>();
        for(SBQQ__QuoteLine__c ql: [SELECT ID,SBQQ__Product__c,Product_Code_Copy__c FROM SBQQ__QuoteLine__c]){
            SBQQ__QuoteLine__c qlRec = new SBQQ__QuoteLine__c();
            if(ql.Product_Code_Copy__c == 'LIC-VG-ENT'){
                qlRec.id = ql.id;
               	qlRec.SBQQ__Product__c = vgTier;
                qlRec.Product_Code_Copy__c = vgTierPC;
                qlList.add(qlRec);
                qteList.add(ql.Id);
            }
            if(ql.Product_Code_Copy__c == 'LIC-CM1-ENT'){
                qlRec.id = ql.id;
               	qlRec.SBQQ__Product__c = cm1Tier;
                qlRec.Product_Code_Copy__c = cm1TierPC;
                qlList.add(qlRec);
                qteList.add(ql.Id);
            }
            if(ql.Product_Code_Copy__c == 'LIC-CM2-ENT'){
                qlRec.id = ql.id;
               	qlRec.SBQQ__Product__c = cm2Tier;
                qlRec.Product_Code_Copy__c = cm2TierPC;
                qlList.add(qlRec);
                qteList.add(ql.Id);
            }
            if(ql.Product_Code_Copy__c == 'LIC-TRLR-ESS'){
                qlRec.id = ql.id;
               	qlRec.SBQQ__Product__c = trlrTier;
                qlRec.Product_Code_Copy__c = trlrTierPC;
                qlList.add(qlRec);
                qteList.add(ql.Id);
            }
            if(ql.Product_Code_Copy__c == 'LIC-CM1-PRO'){
              delQlList.add(ql);  
            }
            if(ql.Product_Code_Copy__c == 'LIC-CM2-PRO'){
              delQlList.add(ql);  
            }
        }
        Map<String,String> pmRepleg = new Map<String,String>();
        for(Product_Mapping__c pmm: [SELECT ID,Replacement_Product__r.ProductCode,Legacy_Product__r.ProductCode FROM Product_Mapping__c]){
            pmRepleg.put(pmm.Replacement_Product__r.ProductCode,pmm.Legacy_Product__r.ProductCode);
        }
        Test.startTest();
        update conList;
		delete delQllist;
		update qlList;      
        ContractRenewalBatch batchJob = new ContractRenewalBatch(qlList,quoteIdList);
        Database.executeBatch(batchJob);
        
        Test.stopTest();
    }
    @isTest
    public static void testContractRenewalQueueableRefreshAction(){
    	bypass();
        List<Id> quoteIdList = new List<Id>();
        for(SBQQ__Quote__c quoteRec: [SELECT ID FROM SBQQ__Quote__c]){
          quoteIdList.add(quoteRec.Id);  
        }
        Test.startTest();
        //update conList;
        ContractRenewalQueueable queueableJob = new ContractRenewalQueueable('RefreshPrice',Null,quoteIdList,NULL,NULL,NULL,NULL);
        System.enqueueJob(queueableJob);
        
        Test.stopTest();
        
    }
    @isTest
    public static void testContractRenewalQueueableDiscountAction(){
    	bypass();
        List<Id> quoteIdList = new List<Id>();
        List<Id> quoteRecordId = new List<Id>();
        List<SBQQ__QuoteLine__c> strDiscount = [SELECT ID,Monthly_Unit_Price__c,SBQQ__ListPrice__c,SBQQ__ProductCode__c FROM SBQQ__QuoteLine__c];
        Map<String,Decimal> mupqlLst = new Map<String,Decimal>();
        for(SBQQ__Quote__c quoteRec: [SELECT ID FROM SBQQ__Quote__c]){
          quoteIdList.add(quoteRec.Id);  
        }
        for(SBQQ__QuoteLine__c sql: strDiscount){
           quoteRecordId.add(sql.Id);
           String strid = sql.Id+'-'+sql.SBQQ__ProductCode__c;
           mupqlLst.put(sql.Id,sql.Monthly_Unit_Price__c);
        }
        Map<String,String> pmRepleg = new Map<String,String>();
        for(Product_Mapping__c pmmm: [SELECT ID,Legacy_Product__r.ProductCode,Dependent_Product__r.ProductCode,Replacement_Product__r.ProductCode FROM product_Mapping__c]){
            pmRepleg.put(pmmm.Replacement_Product__r.ProductCode,pmmm.Legacy_Product__r.ProductCode);
        }
        Test.startTest();
        //update conList;
       ContractRenewalQueueable queueableJob = new ContractRenewalQueueable('Discounting',Null,quoteIdList,quoteRecordId,mupqlLst,pmRepleg,NULL);
        System.enqueueJob(queueableJob);
        Test.stopTest();
       
                
    }
    @isTest
    public static void testContractRenewalrecalculateAction(){
    	bypass();
        List<Id> quoteIdList = new List<Id>();
        for(SBQQ__Quote__c quoteRec: [SELECT ID,Recalculate_Quote__c FROM SBQQ__Quote__c]){
          quoteIdList.add(quoteRec.Id);  
        }
        Test.startTest();
        //update conList;
        ContractRenewalQueueable queueableJob = new ContractRenewalQueueable('Recalculate',Null,quoteIdList,Null,Null,Null,NULL);
        System.enqueueJob(queueableJob);
        Test.stopTest();      
    }
}