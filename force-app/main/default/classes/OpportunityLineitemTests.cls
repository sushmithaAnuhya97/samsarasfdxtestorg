/**
 * Created by vikasmishra on 2020-11-12.
 */
@isTest
private class OpportunityLineitemTests {

    static final string TRAIL_OPPTY_NAME = 'TrialOpty For Test 1';

    @isTest static void Unique_Shipping_AddressesInsertUpdateDelete() {
        bypass();
        Account acc = new Account ();
        acc = TestFactory.initializeAccount('Active_Growth_Campaigns_Count');
        insert acc;
        List<Shipping_Address__c> shipList = new List<Shipping_Address__c>();
        Shipping_Address__c shippingAddress = createSHippingAddress('First1');
        shippingAddress.Account__c = acc.Id;
        shipList.add(shippingAddress);

        Shipping_Address__c shippingAddress1 = createSHippingAddress('First2');
        shippingAddress1.Account__c = acc.Id;
        shipList.add(shippingAddress1);

        insert shipList;
        Id pricebookId = Test.getStandardPricebookId();
        addProducts(pricebookId);
        PricebookEntry vg33 = getPricebookEntry(pricebookId, 'LIC-VG33');

        Opportunity thisOpp = new Opportunity();
        thisOpp = TestFactory.initializeOpportunity ('Active_Growth_Campaigns_Count');
        thisOpp.Type = 'Revenue Opportunity' ;
        thisOpp.StageName = 'Qualified';
        thisOpp.AccountId = acc.Id;
        insert thisOpp;
        List<OpportunityLineItem> oLiList = new List<OpportunityLineItem>();
        OpportunityLineItem oli = new OpportunityLineItem(OpportunityId = thisOpp.Id, Quantity = 10,
                PriceBookEntryId = vg33.Id, Ship_To__c = shippingAddress.Id,
                UnitPrice = vg33.UnitPrice, Account__c = acc.Id, Ship_From_Location__c='VCK');
        oLiList.add(oli);
        OpportunityLineItem oli1 = new OpportunityLineItem(OpportunityId = thisOpp.Id, Quantity = 10,
                PriceBookEntryId = vg33.Id, Ship_To__c = shippingAddress1.Id,
                UnitPrice = vg33.UnitPrice, Account__c = acc.Id, Ship_From_Location__c='Samsara UK');
        oLiList.add(oli1);

        // Use default handler mapping during test
        GS_TriggerHandlerRunnerConfig.oppNewTrigger = true;
        insert oLiList;

        test.startTest();
        // Ensure flag within test context, too
        GS_TriggerHandlerRunnerConfig.oppNewTrigger = true;

        List<OpportunityLineItem> oLiList1 = new List<OpportunityLineItem>();
        for (OpportunityLineItem tOli : oLiList) {
            tOli.Ship_To__c = shippingAddress1.Id;
            tOli.Quantity = 11;
            oLiList1.add(tOli);
        }
        update oLiList1;
        delete oLiList1;
        test.stopTest();
    }
    
   @isTest static void Unique_Shipping_AddressesInsertUpdateDelete1() {
       bypass(); 
       Account acc = new Account ();
        acc = TestFactory.initializeAccount('Active_Growth_Campaigns_Count');
        test.startTest();

        // Ensure default handler mapping during test
        GS_TriggerHandlerRunnerConfig.oppNewTrigger = true;

        insert acc;
        List<Shipping_Address__c> shipList = new List<Shipping_Address__c>();
        Shipping_Address__c shippingAddress = createSHippingAddress('First1');
        shippingAddress.Account__c = acc.Id;
        shipList.add(shippingAddress);

        Shipping_Address__c shippingAddress1 = createSHippingAddress('First2');
        shippingAddress1.Account__c = acc.Id;
        shipList.add(shippingAddress1);

        insert shipList;
        Id pricebookId = Test.getStandardPricebookId();
        addProducts(pricebookId);
        PricebookEntry CM1Pro = getPricebookEntry(pricebookId, 'LIC-CM1-PRO');
        PricebookEntry CM2Pro = getPricebookEntry(pricebookId, 'LIC-CM2-PRO');
        PricebookEntry VGPro = getPricebookEntry(pricebookId, 'LIC-VG-PRO');
        PricebookEntry pltfPro = getPricebookEntry(pricebookId, 'LIC-PLTFM-PRO');

        Opportunity thisOpp = new Opportunity();
        thisOpp = TestFactory.initializeOpportunity ('Active_Growth_Campaigns_Count');
        thisOpp.Type = 'Revenue Opportunity' ;
        thisOpp.StageName = 'Qualified';
        thisOpp.AccountId = acc.Id;
        insert thisOpp;
        
        
        Opportunity thisOpp2 = new Opportunity();
        thisOpp2 = TestFactory.initializeOpportunity ('Active_Growth_Campaigns_Count');
        thisOpp2.Type = 'Revenue Opportunity' ;
        thisOpp2.StageName = 'Qualified';
        thisOpp2.AccountId = acc.Id;
        insert thisOpp2;
        List<OpportunityLineItem> oLiList = new List<OpportunityLineItem>();
        OpportunityLineItem oli1 = new OpportunityLineItem(OpportunityId = thisOpp.Id, Quantity = 10,
                PriceBookEntryId = CM1Pro.Id, Ship_To__c = shippingAddress.Id,
                UnitPrice = CM1Pro.UnitPrice, Account__c = acc.Id, Ship_From_Location__c='VCK');
        oLiList.add(oli1);
		OpportunityLineItem oli2 = new OpportunityLineItem(OpportunityId = thisOpp.Id, Quantity = 10,
                PriceBookEntryId = CM2Pro.Id, Ship_To__c = shippingAddress1.Id,
                UnitPrice = CM2Pro.UnitPrice, Account__c = acc.Id, Ship_From_Location__c='Samsara UK');
        oLiList.add(oli2);
        OpportunityLineItem oli3 = new OpportunityLineItem(OpportunityId = thisOpp.Id, Quantity = 10,
                PriceBookEntryId = VGPro.Id, Ship_To__c = shippingAddress1.Id,
                UnitPrice = VGPro.UnitPrice, Account__c = acc.Id, Ship_From_Location__c='Samsara UK');
        oLiList.add(oli3);
        OpportunityLineItem oli4 = new OpportunityLineItem(OpportunityId = thisOpp.Id, Quantity = 10,
                PriceBookEntryId = pltfPro.Id, Ship_To__c = shippingAddress1.Id,
                UnitPrice = pltfPro.UnitPrice, Account__c = acc.Id, Ship_From_Location__c='Samsara UK');
        oLiList.add(oli4);
        insert oLiList;
        
         List<OpportunityLineItem> oLiList2 = new List<OpportunityLineItem>();
        OpportunityLineItem oli5 = new OpportunityLineItem(OpportunityId = thisOpp2.Id, Quantity = 10,
                PriceBookEntryId = CM1Pro.Id, Ship_To__c = shippingAddress.Id,
                UnitPrice = CM1Pro.UnitPrice, Account__c = acc.Id, Ship_From_Location__c='VCK');
        oLiList2.add(oli5);
        OpportunityLineItem oli6 = new OpportunityLineItem(OpportunityId = thisOpp2.Id, Quantity = 10,
                PriceBookEntryId = CM2Pro.Id, Ship_To__c = shippingAddress1.Id,
                UnitPrice = CM2Pro.UnitPrice, Account__c = acc.Id, Ship_From_Location__c='Samsara UK');
        oLiList2.add(oli6);
        OpportunityLineItem oli7 = new OpportunityLineItem(OpportunityId = thisOpp2.Id, Quantity = 10,
                PriceBookEntryId = VGPro.Id, Ship_To__c = shippingAddress1.Id,
                UnitPrice = VGPro.UnitPrice, Account__c = acc.Id, Ship_From_Location__c='Samsara UK');
        oLiList2.add(oli7);
        OpportunityLineItem oli8 = new OpportunityLineItem(OpportunityId = thisOpp2.Id, Quantity = 10,
                PriceBookEntryId = pltfPro.Id, Ship_To__c = shippingAddress1.Id,
                UnitPrice = pltfPro.UnitPrice, Account__c = acc.Id, Ship_From_Location__c='Samsara UK');
        oLiList2.add(oli8);
        insert oLiList2;
       // NS renewal price branch
	if (pltfPro != null) {
		OpportunityLineItem nsLine = new OpportunityLineItem(
			OpportunityId = thisOpp.Id, PricebookEntryId = pltfPro.Id, Quantity = 1, UnitPrice = pltfPro.UnitPrice, Created_From_NS__c = true, License_Term_Copy__c = 6
		);
		OpportunityLineItemHelper.salesPriceUpdateForRenewalLines(new List<OpportunityLineItem>{ nsLine });
	}

	// CR events (read-only field only queried)
	List<OpportunityLineItem> some = [
		SELECT Id, OpportunityId, ProductCode, Opportunity_Type__c
		FROM OpportunityLineItem
		WHERE OpportunityId IN :new Set<Id>{ thisOpp.Id, thisOpp2.Id }
		LIMIT 5
	];
	if (!some.isEmpty()) {
		Map<Id, OpportunityLineItem> m = new Map<Id, OpportunityLineItem>(some);
		OpportunityLineItemHelper.createOrVoidChannelRelationship(m, false);
		OpportunityLineItemHelper.createOrVoidChannelRelationship(m, true);
	}

        test.stopTest();

    }


    @isTest static void Unique_Shipping_AddressesUndelete() {
        bypass();
        Account acc = new Account ();
        acc = TestFactory.initializeAccount('Active_Growth_Campaigns_Count');
        insert acc;
        List<Shipping_Address__c> shipList = new List<Shipping_Address__c>();
        Shipping_Address__c shippingAddress = createSHippingAddress('First1');
        shippingAddress.Account__c = acc.Id;
        shipList.add(shippingAddress);

        Shipping_Address__c shippingAddress1 = createSHippingAddress('First2');
        shippingAddress1.Account__c = acc.Id;
        shipList.add(shippingAddress1);

        insert shipList;
        Id pricebookId = Test.getStandardPricebookId();
        addProducts(pricebookId);
        PricebookEntry vg33 = getPricebookEntry(pricebookId, 'LIC-VG33');

        Opportunity thisOpp = new Opportunity();
        thisOpp = TestFactory.initializeOpportunity ('Active_Growth_Campaigns_Count');
        thisOpp.Type = 'Revenue Opportunity' ;
        thisOpp.StageName = 'Qualified';
        thisOpp.AccountId = acc.Id;
        insert thisOpp;
        List<OpportunityLineItem> oLiList = new List<OpportunityLineItem>();
        OpportunityLineItem oli = new OpportunityLineItem(OpportunityId = thisOpp.Id, Quantity = 10,
                PriceBookEntryId = vg33.Id, Ship_To__c = shippingAddress.Id,
                UnitPrice = vg33.UnitPrice, Account__c = acc.Id);
        oLiList.add(oli);
        OpportunityLineItem oli1 = new OpportunityLineItem(OpportunityId = thisOpp.Id, Quantity = 10,
                PriceBookEntryId = vg33.Id, Ship_To__c = shippingAddress1.Id,
                UnitPrice = vg33.UnitPrice, Account__c = acc.Id);
        oLiList.add(oli1);

        // Ensure default handler mapping during test
        GS_TriggerHandlerRunnerConfig.oppNewTrigger = true;
        insert oLiList;

        test.startTest();
        // Ensure flag within test context, too
        GS_TriggerHandlerRunnerConfig.oppNewTrigger = true;

        delete thisOpp;
        test.stopTest();

    }

    static private PricebookEntry getPricebookEntry(Id pricebookId, String productCode) {
        PricebookEntry entry = [Select Id, UnitPrice, Pricebook2Id, ProductCode from PricebookEntry where ProductCode = :productCode and Pricebook2Id = :pricebookId LIMIT 1];
        return entry;
    }

    static private void addProducts(Id pricebookId) {

        List<Product2> products = new List<Product2>();
        Product2 vg33 = new Product2(Name = 'LIC-VG33', ProductCode = 'LIC-VG33', Family = 'Connected Worker');
        products.add(vg33);
        Product2 cm1 = new Product2(Name = 'LIC-CM1-PRO', ProductCode = 'LIC-CM1-PRO', Family = 'Connected Worker');
        products.add(cm1);
        Product2 cm2 = new Product2(Name = 'LIC-CM2-PRO', ProductCode = 'LIC-CM2-PRO', Family = 'Connected Worker');
        products.add(cm2);
        Product2 plftm = new Product2(Name = 'LIC-PLTFM-PRO', ProductCode = 'LIC-PLTFM-PRO', Family = 'Connected Worker');
        products.add(plftm);
        Product2 vgPro = new Product2(Name = 'LIC-VG-PRO', ProductCode = 'LIC-VG-PRO', Family = 'Connected Worker');
        products.add(vgPro);
        insert products;
        List<PricebookEntry> pricebookEntries = new List<PricebookEntry>();
        PricebookEntry vg33PB = new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = vg33.Id, UnitPrice = 10000, IsActive = true);
        pricebookEntries.add(vg33PB);
        PricebookEntry cm1PB = new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = cm1.Id, UnitPrice = 10000, IsActive = true);
        pricebookEntries.add(cm1PB);
        PricebookEntry cm2PB = new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = cm2.Id, UnitPrice = 10000, IsActive = true);
        pricebookEntries.add(cm2PB);
        PricebookEntry plfmPB = new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = plftm.Id, UnitPrice = 10000, IsActive = true);
        pricebookEntries.add(plfmPB);
        PricebookEntry vgPB = new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = vgPro.Id, UnitPrice = 10000, IsActive = true);
        pricebookEntries.add(vgPB);                              
        insert pricebookEntries;

     }

    static private Shipping_Address__c createSHippingAddress(String tName) {
        return new Shipping_Address__c(
                Shipping_Address_Line_1__c = 'Address1', Shipping_Address_Line_2__c = 'Address2',
                Shipping_City__c = 'TestCity', Shipping_Country__c = 'United States',
                Shipping_State__c = 'New York', Shipping_FirstName__c = tName,
                Shipping_LastName__c = 'LastName', Shipping_Zip_Code__c = '12345');
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
    
    @testSetup
    static void setupTestData() {
         bypass();
         User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        Id pricebookId = Test.getStandardPricebookId();
        List<Product2> products = new List<Product2>();
        Product2 testpro1 = new Product2(Name= 'LIC-MEM-ENT', ProductCode = 'LIC-MEM-ENT', Family = 'Emerging Products', CPQ_Enabled_Product__c = true, CurrencyIsoCode = 'USD');
        Product2 testproHardware = new Product2( Name= 'AG45 Unpowered Asset Tracker'
                                                    , ProductCode = 'HW-AG45'
                                                    , Family = 'Smart Trailers & Connected Equipment'
                                                    , CPQ_Enabled_Product__c = false
                                                    , Compatible_Licenses__c = 'LIC-AG4-ENT'
                                                    , Product_Type__c = 'Hardware'
                                                    , CurrencyIsoCode = 'USD');
        Product2 testproHardware2 = new Product2( Name= 'HW-CM25-I'
                                                    , ProductCode = 'HW-AG45'
                                                    , Family = 'Smart Trailers & Connected Equipment'
                                                    , CPQ_Enabled_Product__c = false
                                                    , Compatible_Licenses__c = 'LIC-AG4-ENT'
                                                    , Product_Type__c = 'Hardware'
                                                    , CurrencyIsoCode = 'USD');
        products.add(testpro1);
        products.add(testproHardware);
        products.add(testproHardware2);
        
        insert products;
        
        List<PricebookEntry> pricebookEntries = new List<PricebookEntry>();
        PricebookEntry testPB1 = new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = testpro1.Id, UnitPrice = 120, IsActive = true, CurrencyIsoCode = 'USD');
        pricebookEntries.add(testPB1);
        PricebookEntry testPB2 = new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = testpro1.Id, UnitPrice = 120, IsActive = true, CurrencyIsoCode = 'GBP');
        pricebookEntries.add(testPB2);
        PricebookEntry testHW = new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = testproHardware.Id, UnitPrice = 100, IsActive = true, CurrencyIsoCode = 'USD');
        pricebookEntries.add(testHW);
        PricebookEntry testHW2 = new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = testproHardware2.Id, UnitPrice = 100, IsActive = true, CurrencyIsoCode = 'USD');
        pricebookEntries.add(testHW2);
        
        insert pricebookEntries;
        
        List<Account> accounts = new List<Account>();
        Account acc = new Account(Name = 'Test Account', Organization_Size__c='1 - 99', BillingCountry='United States', BillingState='New York', CurrencyIsoCode = 'USD');
        accounts.add(acc);
        Account acc1 = new Account(Name = 'Test Account1', Organization_Size__c='1 - 99', BillingCountry='United Kingdom',  CurrencyIsoCode = 'GBP');
        accounts.add(acc1);
        insert accounts;
        List<Opportunity> revenueoppties = new List<Opportunity>();
        Opportunity revenueopp = new Opportunity(Name = 'RevenueOpportunity', AccountId = acc.Id,Type='Revenue Opportunity', StageName = 'Closed Won',OwnerId = thisUser.Id,Owner_Role_Copy__c = 'COR Fleet IS AE3 NA US Team 50', CloseDate = Date.today(), CurrencyIsoCode = 'USD');
        revenueoppties.add(revenueopp);
        Opportunity revenueopp1 = new Opportunity(Name = 'RevenueOpportunity1', AccountId = acc.Id,Type='Revenue Opportunity', StageName = 'Closed Won',OwnerId = thisUser.Id,Owner_Role_Copy__c = 'MM Fleet IS AE2 NA US Team 16', CloseDate = Date.today(), CurrencyIsoCode = 'USD');
        revenueoppties.add(revenueopp1);
        Opportunity revenueopp2 = new Opportunity(Name = 'RevenueOpportunity2', AccountId = acc1.Id,Type='Revenue Opportunity', StageName = 'Closed Won',OwnerId = thisUser.Id, CloseDate = Date.today(), CurrencyIsoCode = 'GBP');
        Opportunity revenueopp3 = new Opportunity(Name = 'RevenueOpportunity2', AccountId = acc1.Id,Type='Revenue Opportunity', StageName = 'Closed Won',OwnerId = thisUser.Id, CloseDate = Date.today().addDays(90), CurrencyIsoCode = 'GBP');
        revenueoppties.add(revenueopp2);  
        revenueoppties.add(revenueopp3);  
        insert revenueoppties;
        Test.startTest();
        	List<Opportunity> remorseRefundOpp = new List<Opportunity>();
            Opportunity remorseOpp = new Opportunity(Name = 'RemorseOpportunity', AccountId = acc.Id,Type='Remorse Refund', StageName = 'Return Created',OwnerId = thisUser.Id,Owner_Role_Copy__c = 'COR Fleet IS AE3 NA US Team 50',Returning_Opportunity__c=revenueopp.Id ,CloseDate = Date.today(),CurrencyIsoCode = 'USD');
        remorseRefundOpp.add(remorseOpp);
        Opportunity remorseOpp1 = new Opportunity(Name = 'RemorseOpportunity1', AccountId = acc.Id,Type='Remorse Refund', StageName = 'Return Created',OwnerId = thisUser.Id,Owner_Role_Copy__c = 'MM Fleet IS AE2 NA US Team 16',Returning_Opportunity__c=revenueopp1.Id ,CloseDate = Date.today(),CurrencyIsoCode = 'USD');
        remorseRefundOpp.add(remorseOpp1);
        Opportunity remorseOpp2 = new Opportunity(Name = 'RemorseOpportunity2', AccountId = acc1.Id,Type='Remorse Refund', StageName = 'Return Created',OwnerId = thisUser.Id,Returning_Opportunity__c=revenueopp2.Id ,CloseDate = Date.today(),CurrencyIsoCode = 'GBP');
        remorseRefundOpp.add(remorseOpp2);
        
        Opportunity trialOpp = new Opportunity(Name = TRAIL_OPPTY_NAME, 
                                                AccountId = acc1.Id,
                                                Type= 'Free Trial Opportunity', 
                                                StageName = 'Return Created',
                                                OwnerId = thisUser.Id,
                                                TrialResolutionOppty__c = revenueopp3.Id,
                                                CloseDate = Date.today().addDays(30),
                                                CurrencyIsoCode = 'USD');
        
        remorseRefundOpp.add( trialOpp );

        insert remorseRefundOpp;

        OpportunityLineItem opLine1 = new OpportunityLineItem ( OpportunityId = trialOpp.Id
                                        , Quantity = 10
                                        , PriceBookEntryId = testHW.Id
                                        , UnitPrice = testHW.UnitPrice );

        OpportunityLineItem opline2 = new OpportunityLineItem ( OpportunityId = trialOpp.Id
                                        , Quantity = 10
                                        , PriceBookEntryId = testHW2.Id
                                        , UnitPrice = testHW2.UnitPrice );

        insert new List<OpportunityLineItem>{ opLine1, opLine2 };

        Test.stopTest();
    }

/*@isTest
    static void updateOppoOwnerforRemorseRefundTest(){
        test.startTest();
        	//List<Account> accList = [SELECT ID,Name,CurrencyISOCode FROM Account];
        List<Product2> prodList = [SELECT ID,Name,ProductCode FROM Product2];
        List<Opportunity> oppList  = [SELECT ID,CurrencyISOCode,Owner_Role_Copy__c,OwnerId FROM Opportunity WHERE Type = 'Remorse Refund'];
        Set<Id> oppoSet = new Set<Id>();
        for(Opportunity o: oppList){
            oppoSet.add(o.Id);
        }
        List<PricebookEntry> pbeList = [SELECT ID, Product2Id,CurrencyIsoCode  FROM PricebookEntry];
        String usdPBEID;
        String gbpPBEID;
        for(PricebookEntry pbe: pbeList){
            if(pbe.CurrencyISOCODE == 'GBP'){
                gbpPBEID = pbe.Id;
            }if(pbe.CurrencyISOCODE == 'USD'){
                usdPBEID = pbe.Id;
            }
        }
        List<OpportunityLineItem> oppLIList = new List<OpportunityLineItem>();
        OpportunityLineItem oppLi = new OpportunityLineItem(OpportunityId = oppList[0].Id,PriceBookEntryId=usdPBEID,Quantity = -5);
        oppLIList.add(oppLi);
        OpportunityLineItem oppLi1 = new OpportunityLineItem(OpportunityId = oppList[1].Id,PriceBookEntryId=usdPBEID,Quantity = -3);
        oppLIList.add(oppLi1);
        OpportunityLineItem oppLi2 = new OpportunityLineItem(OpportunityId = oppList[2].Id,PriceBookEntryId=gbpPBEID,Quantity = -1);
        oppLIList.add(oppLi2);
        insert oppLIList;
        OpportunityLineItemHelper olih = new OpportunityLineItemHelper();
        olih.updateOppoOwnerforRemorseRefundOpp(oppLIList,oppoSet);
        test.stopTest();
    }*/
}