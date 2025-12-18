/**
 * Created by Suman Kundu on 2021-09-21.
 */
@isTest
private class GS_OpportunityLineItemTest {

    @testSetup static void setupData(){
        insert new Global_Automation_Settings__c(Allow_Handler_Selection__c = true);
    }
    @isTest static void Unique_Shipping_AddressesInsertUpdateDelete() {
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
        insert oLiList;
        Decimal rollupACV = 0.0;
        for(OpportunityLineItem obj : [Select ACV_Total_Price_Bookings__c from OpportunityLineItem]){
            if(obj.ACV_Total_Price_Bookings__c != null)
                rollupACV += obj.ACV_Total_Price_Bookings__c;
        }

        List<Async_Request__c> asyncRequests = [SELECT Id, Name, Type__c, Error_Msg__c, Params__c, Options__c, Retry_Counter__c FROM Async_Request__c];
        GS_OpportunityLineItemServiceAsync asyncIns = new GS_OpportunityLineItemServiceAsync();
        for (Async_Request__c asyncRequest : asyncRequests) {
            System.debug('***AsyncRequest Type> '+asyncRequest.Type__c);
            if (asyncRequest.Type__c == asyncIns.getRequestType()) {
                asyncIns.execute(asyncRequest);
            }
        }

        thisOpp = [SELECT Id, Unique_Shipping_Addresses__c, Sites_ACV_Bookings__c FROM Opportunity WHERE Name LIKE 'Active_Growth_Campaigns_Count%'];
        system.assertEquals(thisOpp.Unique_Shipping_Addresses__c, 2);
        system.assertEquals(thisOpp.Sites_ACV_Bookings__c, rollupACV);

        test.startTest();
        List<OpportunityLineItem> oLiList1 = new List<OpportunityLineItem>();
        for (OpportunityLineItem tOli : oLiList) {
            tOli.Ship_To__c = shippingAddress1.Id;
            tOli.Quantity = 11;
            oLiList1.add(tOli);
        }

        update oLiList1;
        rollupACV = 0.0;
        for(OpportunityLineItem obj : [Select ACV_Total_Price_Bookings__c from OpportunityLineItem]){
            rollupACV += obj.ACV_Total_Price_Bookings__c;
        }
        /*thisOpp = [SELECT Id, Unique_Shipping_Addresses__c, Sites_ACV_Bookings__c FROM Opportunity WHERE Name LIKE 'Active_Growth_Campaigns_Count%'];
        system.assertEquals(thisOpp.Unique_Shipping_Addresses__c, 1);
        system.assertEquals(thisOpp.Sites_ACV_Bookings__c, rollupACV);*/

        delete oLiList1;

        /*thisOpp = [SELECT Id, Unique_Shipping_Addresses__c, Sites_ACV_Bookings__c FROM Opportunity WHERE Name LIKE 'Active_Growth_Campaigns_Count%'];
        system.assertEquals(thisOpp.Unique_Shipping_Addresses__c, null);
        system.assertEquals(thisOpp.Sites_ACV_Bookings__c, 1);*/

        test.stopTest();

    }

    @isTest static void Unique_Shipping_AddressesUndelete() {
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
        insert oLiList;
        //thisOpp = [SELECT Id, Unique_Shipping_Addresses__c FROM Opportunity WHERE Name LIKE 'Active_Growth_Campaigns_Count%'];
        //system.assertEquals(thisOpp.Unique_Shipping_Addresses__c, 2);

        test.startTest();

        delete thisOpp;

        Opportunity[] savedopps = [SELECT Id, Unique_Shipping_Addresses__c FROM Opportunity WHERE Name LIKE 'Active_Growth_Campaigns_Count%' ALL ROWS];
        undelete savedopps;
        /*List<Async_Request__c> asyncRequests = [SELECT Id, Name, Type__c, Error_Msg__c, Params__c, Options__c, Retry_Counter__c FROM Async_Request__c];
        GS_OpportunityLineItemServiceAsync asyncIns = new GS_OpportunityLineItemServiceAsync();
        for (Async_Request__c asyncRequest : asyncRequests) {
            System.debug('***AsyncRequest Type> '+asyncRequest.Type__c);
            if (asyncRequest.Type__c == asyncIns.getRequestType()) {
                asyncIns.execute(asyncRequest);
            }
        }
        system.assertEquals(savedopps[0].Unique_Shipping_Addresses__c, 2);*/

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
        insert products;
        List<PricebookEntry> pricebookEntries = new List<PricebookEntry>();
        PricebookEntry vg33PB = new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = vg33.Id, UnitPrice = 10000, IsActive = true);
        pricebookEntries.add(vg33PB);
        insert pricebookEntries;

    }

    static private Shipping_Address__c createSHippingAddress(String tName) {
        return new Shipping_Address__c(
                Shipping_Address_Line_1__c = 'Address1', Shipping_Address_Line_2__c = 'Address2',
                Shipping_City__c = 'TestCity', Shipping_Country__c = 'United States',
                Shipping_State__c = 'New York', Shipping_FirstName__c = tName,
                Shipping_LastName__c = 'LastName', Shipping_Zip_Code__c = '12345');
    }

}