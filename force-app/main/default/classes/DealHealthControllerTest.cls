@isTest
public class DealHealthControllerTest {
    
    @TestSetup
    static void makeData(){

        //Standard Pricebook
        Id pricebookId = Test.getStandardPricebookId();
        
        //Create Products
        List<Product2> products = new List<Product2>();
        Product2 vg33 = new Product2(Name= 'HW-VG33', ProductCode = 'HW-VG33', Family = 'Test', Product_Tag__c = 'VG');
        products.add(vg33);
        Product2 vgLicense = new Product2(Name= 'LIC-VG-36MO', ProductCode = 'LIC-VG-36MO', Family = 'Test', Product_Tag__c = 'CM1');
        products.add(vgLicense);  
        Product2 insuranceSUBSIDY = new Product2(Name= 'CM1-SUBSIDY', ProductCode = 'CM1-SUBSIDY', Family = 'Test', Product_Tag__c = 'CM2');
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

        Account acc = (Account) TestFactory.createSObject(new Account(Industry = 'Retail Trade', 
                                                                        Approved_Payment_Type__c = 'Direct Monthly',
                                                                        Total_parent_child_ARR__c = 100,
                                                                        Global_Geography__c = 'Central'));
        insert acc;
        Contact con = (Contact) TestFactory.createSObject(new Contact(AccountId = acc.Id, Email = 'test@test.com'));
        insert con;

        Test.startTest();
        Opportunity opp = (Opportunity)TestFactory.createSObject(new Opportunity(AccountId = acc.Id,
                                                                                    Type = 'Revenue Opportunity',
                                                                                    Name = 'Opp Testers 2 Inc',
                                                                                    StageName = 'Decision',
                                                                                    Shipping_Contact__c = con.Id,
                                                                                    Price_Book_Name__c = 'Standard',
                                                                                    Selected_Payment_Type__c = 'Direct Monthly'));
        insert opp;

        SBQQ__Quote__c quote = new SBQQ__Quote__c (SBQQ__Account__c = acc.Id, 
                                                    SBQQ__Opportunity2__c = opp.Id,
                                                    Original_License_Term__c = 25,
                                                    Selected_Payment_Type__c = 'Direct Monthly',
                                                    SBQQ__PriceBook__c  = pricebookId);
        insert quote;

        list<SBQQ__QuoteLine__c> quoteLines = new list<SBQQ__QuoteLine__c> ();

        for(PricebookEntry pbEntry : pricebookEntries){
            quoteLines.add(new SBQQ__QuoteLine__c(SBQQ__Quote__c = quote.Id, SBQQ__PricebookEntryId__c = pbEntry.Id, SBQQ__Quantity__c  = 5, 
                                SBQQ__Discount__c = 55, SBQQ__Product__c = pbEntry.Product2Id, accountLookupTest__c = acc.Id, ACV_Total_Price_Stamp__c = 500));
        }

        insert quoteLines;

        Test.stopTest();

        Deal_Health_Data__c dhd1 = new Deal_Health_Data__c(Industry_Tagging_CoE__c = 'Transportation',
                                        License_term_buckets__c = '<=3 years',
                                        One_Time_Discount_Mapping__c = 'Exclude',
                                        Product_Importance_Tagging__c = 'Mixed - PnP',
                                        Region_Tagging_CoE__c = 'US',
                                        Renewal_Flag_CoE__c = 'First Purchase',
                                        Revenue_Band__c = 'Revenue Band 1',
                                        Selected_Payment_Type__c = 'Upfront Payments',
                                        Q1__c = 5.55,
                                        Q2__c = 18.26,
                                        Q3__c = 30,
                                        Green_Zone__c = '<=6%');

        Deal_Health_Data__c dhd2 = new Deal_Health_Data__c(Industry_Tagging_CoE__c = 'Transportation',
                                        License_term_buckets__c = '<=3 years',
                                        One_Time_Discount_Mapping__c = 'Exclude',
                                        Product_Importance_Tagging__c = 'Mixed - PnP',
                                        Region_Tagging_CoE__c = 'US',
                                        Renewal_Flag_CoE__c = 'First Purchase',
                                        Revenue_Band__c = 'Revenue Band 1',
                                        Selected_Payment_Type__c = 'Direct Monthly',
                                        Q1__c = 5.55,
                                        Q2__c = 18.26,
                                        Q3__c = 30,
                                        Green_Zone__c = '<=6%');

        insert new List<Deal_Health_Data__c>{dhd1,dhd2};
    }

    @isTest 
    static void updateQuoteDealHealthTest(){
        SBQQ__Quote__c quote =  [SELECT Id FROM SBQQ__Quote__c LIMIT 1];
        Deal_Health_Data__c dhdRec =  [SELECT Id, Green_Zone__c FROM Deal_Health_Data__c LIMIT 1];

        Test.startTest();
        String result = DealHealthController.updateQuoteDealHealth((String) quote.Id);
        Test.stopTest();

        Assert.isTrue(result == dhdRec.Green_Zone__c+'_Red');
    }
}