@isTest
public class TestData {
    // public static void setupAccounts() {

    // }
    public class ProductsAndPriceBooks {
        public Map<String, Product2> products = new Map<String, Product2>();
        public Map<String, PricebookEntry> pricebookEntries = new Map<String, PricebookEntry>();
    }
    /**
    * @author Groundswell - Henry Zhao - henry@gscloudsolutions.com
    * @date 2020-12-09
    *
    * @description Creates test products and pricebook entries for a specified set of product criteria
     *
     * @return An ProductsAndPriceBooks object that contains a map of products and pricebook
     * entries, mapped by their shortened ProductCode
    */
    @IsTest
    public static ProductsAndPriceBooks createProductsAndPricebookEntries() {
        Map<String, Product2> products = new Map<String, Product2>{
                'vg33' => (Product2) TestFactory.createSObject(new Product2(Name = 'HW-VG33', ProductCode = 'HW-VG33', Family = 'Test')),
                'em11' => (Product2) TestFactory.createSObject(new Product2(Name = 'HW-EM11', ProductCode = 'HW-EM11', Family = 'Test')),
                'vgLicense' => (Product2) TestFactory.createSObject(new Product2(Name = 'LIC-VG-36MO', ProductCode = 'LIC-VG-36MO', Family = 'Test')),
                'emLicense' => (Product2) TestFactory.createSObject(new Product2(Name = 'LIC-EM-36MO', ProductCode = 'LIC-EM-36MO', Family = 'Test')),
                'marketingKit' => (Product2) TestFactory.createSObject(new Product2(Name = 'KIT', ProductCode = 'MK-KT', Family = 'Test'))
        };
        insert products.values();

        Map<String, PricebookEntry> pricebookEntries = new Map<String, PricebookEntry>{
                'vg33' => (PricebookEntry) TestFactory.createSObject(new PricebookEntry(Product2Id = products.get('vg33').Id, UnitPrice = 10000)),
                'em11' => (PricebookEntry) TestFactory.createSObject(new PricebookEntry(Product2Id = products.get('em11').Id, UnitPrice = 10000)),
                'vgLicense' => (PricebookEntry) TestFactory.createSObject(new PricebookEntry(Product2Id = products.get('vgLicense').Id, UnitPrice = 10000)),
                'emLicense' => (PricebookEntry) TestFactory.createSObject(new PricebookEntry(Product2Id = products.get('emLicense').Id, UnitPrice = 10000)),
                'marketingKit' => (PricebookEntry) TestFactory.createSObject(new PricebookEntry(Product2Id = products.get('marketingKit').Id, UnitPrice = 0))
        };
        insert pricebookEntries.values();

        ProductsAndPriceBooks ret = new ProductsAndPriceBooks();
        ret.products = products;
        ret.pricebookEntries = pricebookEntries;
        return ret;
    }

    public static void setupProductsAndPricebooks() {
        // First insert the Standard and Express Pricebooks

        Pricebook2 standardPricebook = new Pricebook2(
                Id = Test.getStandardPricebookId(),
                IsActive = true
        );

        update standardPricebook;

        List<Pricebook2> pbs = new List<Pricebook2>{
                (Pricebook2) TestFactory.createSObject(new Pricebook2(Name = 'Samsara Standard')),
                (Pricebook2) TestFactory.createSObject(new Pricebook2(Name = 'Samsara Express'))
        };
        insert pbs;

        // Next, insert Products
        Product2 freeTrialProduct = (Product2) TestFactory.createSObject(new Product2(Name = 'Standard Free Trial', ProductCode = 'FREE-TRIAL-KIT'));
        Product2 welcomeProduct = (Product2) TestFactory.createSObject(new Product2(Name = 'Standard Welcome Kit', ProductCode = 'WELCOME-KIT'));
        Product2 expressWelcome = (Product2) TestFactory.createSObject(new Product2(Name = 'Express Welcome Kit', ProductCode = 'EXPRESS-WELCOME-KIT'));

        insert freeTrialProduct;
        insert welcomeProduct;
        insert expressWelcome;

        // Finally, add Products to Pricebooks by inserting PricebookEntry records
        List<PricebookEntry> pbes = new List<PricebookEntry>{
                (PricebookEntry) TestFactory.createSObject(new PricebookEntry(Pricebook2Id = standardPricebook.Id, Product2Id = expressWelcome.Id)),
                (PricebookEntry) TestFactory.createSObject(new PricebookEntry(Pricebook2Id = standardPricebook.Id, Product2Id = freeTrialProduct.Id)),
                (PricebookEntry) TestFactory.createSObject(new PricebookEntry(Pricebook2Id = standardPricebook.Id, Product2Id = welcomeProduct.Id)),
                (PricebookEntry) TestFactory.createSObject(new PricebookEntry(Pricebook2Id = pbs[1].Id, Product2Id = expressWelcome.Id)),
                (PricebookEntry) TestFactory.createSObject(new PricebookEntry(Pricebook2Id = pbs[0].Id, Product2Id = freeTrialProduct.Id)),
                (PricebookEntry) TestFactory.createSObject(new PricebookEntry(Pricebook2Id = pbs[0].Id, Product2Id = welcomeProduct.Id))
        };
        insert pbes;

        // Now, add some generic products to the pricebook to crowd it up some
        Product2[] prodList = (Product2[]) TestFactory.createSObjectList(new Product2(), 400);
        insert prodList;

        List<PricebookEntry> pbesGeneric = new List<PricebookEntry>();


        for (Integer i = 0; i < 400; i++) {
            if (i <= 201) {
                pbesGeneric.add((PricebookEntry) TestFactory.createSObject(new PricebookEntry(Pricebook2Id = standardPricebook.Id, Product2Id = prodList[i].Id)));
                pbesGeneric.add((PricebookEntry) TestFactory.createSObject(new PricebookEntry(Pricebook2Id = pbs[0].Id, Product2Id = prodList[i].Id)));
            } else {
                pbesGeneric.add((PricebookEntry) TestFactory.createSObject(new PricebookEntry(Pricebook2Id = standardPricebook.Id, Product2Id = prodList[i].Id)));
                pbesGeneric.add((PricebookEntry) TestFactory.createSObject(new PricebookEntry(Pricebook2Id = pbs[1].Id, Product2Id = prodList[i].Id)));
            }
        }
        insert pbesGeneric;
    }
    
    public static void setupControlCenterData() {
        insert new Flex_Control_Center_Config__c (
        	Active__c = true,
            User_Profile__c = 'System Administrator',
            Segment__c='Enterprise;Management',
            Geo_Location__c='United States',
            Max_Active_Contracts__c=3,
            Renewal_Prob_Threshold__c=40,
            Min_Contract_End_Days__c=90
        );
    }
}