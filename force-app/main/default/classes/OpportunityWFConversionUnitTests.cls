/**
 * Class by : Flávio Contini
 * This class was designed to NOT have a TestSetup method and no DMLs whatsoever, as to unit test each function in the OpportunityWorkflowConversion class
 * This is to avoid even higher testing time.
 */
@IsTest
public class OpportunityWFConversionUnitTests {

    private Opportunity newOpportunity;
    private Opportunity oldOpportunity;
    private Opportunity completeOpportunity;
    private Account accountOpportunity;

    private static OpportunityWFConversionUnitTests self;
    
    private static void initialize(){
        self = new OpportunityWFConversionUnitTests();
    }

    public OpportunityWFConversionUnitTests(){
        // Due to Null pointer on OpportunityHelper, prevent helper from executing. It is not mandatory for this test.
        OpportunityTriggerHandler.maxRuns = 0;
        this.newOpportunity = (Opportunity) TestFactory.createSObject(
            new Opportunity(
                Id = TestFactory.getFakeId(Opportunity.getSObjectType())
            ),
            false
        );

        // Setting up data
        this.newOpportunity.OwnerId         = UserInfo.getUserId();
        this.newOpportunity.Name            = 'Test Opportunity';
        this.newOpportunity.Amount          = 10000;
        this.newOpportunity.License_Term__c = 12;
        this.newOpportunity.Type            = 'Revenue Opportunity';
        this.newOpportunity.CloseDate       = System.today().addDays(30);
        this.newOpportunity.StageName       = 'Qualified';
        this.newOpportunity.Configuration_Segment__c = 'Express';
        this.newOpportunity.Returning_Opportunity__c = TestFactory.getFakeId(Opportunity.getSObjectType());
        
        this.accountOpportunity = (Account) TestFactory.createSObject(
            new Account(
                Id = TestFactory.getFakeId(Account.getSObjectType()),
                Name = 'Fake account'
            ),
            false
        );

        this.newOpportunity.AccountId = this.accountOpportunity.Id;

        Pricebook2 pb = new Pricebook2(Id = Test.getStandardPricebookId(), Name = 'Standard Pricebook');
        this.newOpportunity.Pricebook2Id = pb.Id;

        this.oldOpportunity                                  = this.newOpportunity.clone();

        this.completeOpportunity                             = this.newOpportunity.clone();
        this.completeOpportunity.Owner                       = [SELECT Id, Name, Profile.Name, ProfileId, UserRoleId, UserRole.Name, Level__c FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
        this.completeOpportunity.Returning_Opportunity__r    = this.newOpportunity.clone();
        this.completeOpportunity.Returning_Opportunity__c    = TestFactory.getFakeId(Opportunity.getSObjectType());
        this.completeOpportunity.Returning_Opportunity__r.Id = this.completeOpportunity.Returning_Opportunity__c;
        this.completeOpportunity.Pricebook2                  = pb;
        this.completeOpportunity.Account                     = this.accountOpportunity;
        
    }

    @isTest
    public static void testFor_renewalCredit(){
        initialize();

        // Setup - Test #1
        self.newOpportunity.Amount = 12000;
        self.newOpportunity.Renewal_Credit_Amount__c = 12000;
        self.newOpportunity.Selected_Payment_Type__c = 'Direct Monthly';

        self.oldOpportunity.Amount = 12000;
        self.oldOpportunity.Renewal_Credit_Amount__c = 0;
        self.oldOpportunity.Selected_Payment_Type__c = 'Upfront Payments';

        OpportunityWorkflowConversion.renewalCredit(self.newOpportunity, self.oldOpportunity);
        System.assertEquals(999, self.newOpportunity.Renewal_Credit_Amount__c);

        // Setup - Test #2
        self.newOpportunity.Configuration_Segment__c = 'Non-express';
        self.newOpportunity.Amount = 24000;
        self.newOpportunity.Renewal_Credit_Amount__c = 2000;
        self.newOpportunity.Selected_Payment_Type__c = 'Direct Annual';

        self.oldOpportunity.Amount = 0;
        self.oldOpportunity.Renewal_Credit_Amount__c = 0;
        self.oldOpportunity.Selected_Payment_Type__c = 'Upfront Payments';

        OpportunityWorkflowConversion.renewalCredit(self.newOpportunity, self.oldOpportunity);
        System.assertEquals(1999, self.newOpportunity.Renewal_Credit_Amount__c);
    }
    
    
    @isTest
    public static void testFor_updatePushToNetsuiteCounter(){
        initialize();

        // Setup
        self.newOpportunity.Push_to_Mulesoft__c = true;
        self.newOpportunity.Push_to_Netsuite_Counter__c = 7;
        
        self.oldOpportunity.Push_to_Mulesoft__c = false;

        OpportunityWorkflowConversion.updatePushToNetsuiteCounter(self.newOpportunity, self.oldOpportunity);
        System.assertEquals(8, self.newOpportunity.Push_to_Netsuite_Counter__c);
    }
    
    @isTest
    public static void testFor_licenseTermUpdateForOtherRebateTypeAndDelinquentOpp(){
        initialize();

        // Test #1
        self.newOpportunity.License_Term__c = 12;
        self.newOpportunity.Type = 'Rebate';
        self.newOpportunity.Rebate_Type__c = 'Not Delinquent';
        self.completeOpportunity.Returning_Opportunity__r.License_Term__c = 24;

        OpportunityWorkflowConversion.licenseTermUpdateForOtherRebateTypeAndDelinquentOpp(self.newOpportunity, self.completeOpportunity);
        System.assertEquals(24, self.newOpportunity.License_Term__c);

        // Test #2
        self.newOpportunity.License_Term__c = 12;
        self.newOpportunity.Rebate_Type__c  = 'Delinquent';
        self.completeOpportunity.Returning_Opportunity__r.License_End_Date__c = self.newOpportunity.CloseDate.addMonths(24);

        OpportunityWorkflowConversion.licenseTermUpdateForOtherRebateTypeAndDelinquentOpp(self.newOpportunity, self.completeOpportunity);
        // Flooring to account for leap day decimals
        System.assertEquals(24.00, Math.floor(self.newOpportunity.License_Term__c));
    }
    
    @isTest
    public static void testFor_financeSegmentStamp(){
        initialize();

        self.oldOpportunity.StageName = 'Incubate';

        self.newOpportunity.CloseDate = Date.newInstance(2019, 01, 01);
        self.newOpportunity.Owner_Role_Copy__c = 'Industrial';
        Opportunity opp = (Opportunity) setFieldArbitrarily(self.newOpportunity, new Map<String, String>{'Segment__c' => '"Industrial"', 'Finance_Segment__c' => '"ADR"'}, Opportunity.class);

        // DEPENDS ON: Owner Role Copy
        OpportunityWorkflowConversion.financeSegmentStamp(opp, self.oldOpportunity);
        System.assertEquals('Industrial', opp.Finance_Segment_Stamp__c);

        opp.CloseDate = System.today();

        OpportunityWorkflowConversion.financeSegmentStamp(opp, self.oldOpportunity);
        System.assertEquals('SMB', opp.Finance_Segment_Stamp__c);

        opp = (Opportunity) replaceFieldArbitrarily(opp, new Map<String, String>{'Finance_Segment__c' => 'ANY'}, Opportunity.class);
        OpportunityWorkflowConversion.financeSegmentStamp(opp, self.oldOpportunity);
        System.assertEquals('ANY', opp.Finance_Segment_Stamp__c);
    }
    
    @isTest
    public static void testFor_updateShippingCost(){
        initialize();

        Account acc = (Account) TestFactory.createSObject(new Account(), true);
        Shipping_Address__c ship = (Shipping_Address__c) TestFactory.createSObject(new Shipping_Address__c(
            Account__c = acc.Id,
            Shipping_Country__c = 'United Kingdom',
            Shipping_State__c = ''
        ), true);

        self.newOpportunity.Type = 'Revenue Opportunity - Bill Only';
        self.newOpportunity.Shipping_Method__c = 'Ground';
        self.newOpportunity.Shipping_Account_Type__c = 'Not UPS';
        self.newOpportunity.Probability = 70;

        self.newOpportunity.Shipping_Country__c = 'United Kingdom';

        // Fixing references for insert
        self.newOpportunity.AccountId = acc.Id;
        self.newOpportunity.Returning_Opportunity__c = null;
        self.newOpportunity.Id = null;
        self.newOpportunity.Shipping_Address_NEW__c = ship.Id;

        insert self.newOpportunity;

        // Create Opp Products
        Product2 product = (Product2) TestFactory.createSObject(new Product2(Dimensions_cm3__c = 250), true);
        PricebookEntry entry = (PricebookEntry) TestFactory.createSObject(new PricebookEntry(Pricebook2Id = Test.getStandardPricebookId(), Product2Id = product.Id, UnitPrice = 250), true);

        OpportunityLineItem item = (OpportunityLineItem) TestFactory.createSObject(
            new OpportunityLineItem(
                OpportunityId = self.newOpportunity.Id,
                Total_Dimensions_Copy__c = 250,
                Quantity = 4,
                Product2Id = product.Id,
                PricebookEntryId = entry.Id
            ), true
        );
        
        Opportunity opp = [SELECT Id, Name, Shipping_Address_NEW__r.Shipping_Country__c, Shipping_Address_NEW__r.Shipping_State__c, Shipping_Address_NEW__c, Freight_Cost__c, Shipping_Method__c, Total_Product_Dimensions__c, Shipping_Zone__c, Shipping_Country__c, Shipping_and_Handling_Manual__c, Total_Weight_oz__c, AccountId, Type, Probability, Shipping_Account_Type__c FROM Opportunity WHERE Id = :self.newOpportunity.Id];

        opp.Shipping_Method__c = 'UK Standard';
        OpportunityWorkflowConversion.updateShippingCost(opp);
        System.assertEquals(20, opp.Freight_Cost__c);
        
        opp.Shipping_Method__c = 'UK Express';
        OpportunityWorkflowConversion.updateShippingCost(opp);
        System.assertEquals(35, opp.Freight_Cost__c);

        opp = (Opportunity) replaceFieldArbitrarily(opp, new Map<String, String>{'Shipping_Zone__c' => 'Ireland'}, Opportunity.class);
        opp.Shipping_Method__c = 'UK Standard';
        OpportunityWorkflowConversion.updateShippingCost(opp);
        System.assertEquals(45, opp.Freight_Cost__c);

        opp.Shipping_Method__c = 'UK Express';
        OpportunityWorkflowConversion.updateShippingCost(opp);
        System.assertEquals(60, opp.Freight_Cost__c);

        opp = (Opportunity) replaceFieldArbitrarily(opp, new Map<String, String>{'Shipping_Zone__c' => 'Belgium'}, Opportunity.class);
        opp.Shipping_Method__c = 'UK Standard';
        OpportunityWorkflowConversion.updateShippingCost(opp);
        System.assertEquals(20, opp.Freight_Cost__c);

        opp.Shipping_Method__c = 'UK Express';
        OpportunityWorkflowConversion.updateShippingCost(opp);
        System.assertEquals(75, opp.Freight_Cost__c);

        opp = (Opportunity) replaceFieldArbitrarily(opp, new Map<String, String>{'Shipping_Zone__c' => 'Austria'}, Opportunity.class);
        opp.Shipping_Method__c = 'UK Express';
        OpportunityWorkflowConversion.updateShippingCost(opp);
        System.assertEquals(99999.99, opp.Freight_Cost__c);

        opp = (Opportunity) replaceFieldArbitrarily(opp, new Map<String, String>{'Shipping_Zone__c' => 'West'}, Opportunity.class);
        opp.Shipping_Method__c = 'Ground';
        OpportunityWorkflowConversion.updateShippingCost(opp);
        System.assertEquals(30, opp.Freight_Cost__c);

        opp.Shipping_Method__c = '3 Day Select';
        OpportunityWorkflowConversion.updateShippingCost(opp);
        System.assertEquals(54, opp.Freight_Cost__c);

        opp.Shipping_Method__c = 'Next Day Air';
        OpportunityWorkflowConversion.updateShippingCost(opp);
        System.assertEquals(236, opp.Freight_Cost__c);

        opp = (Opportunity) replaceFieldArbitrarily(opp, new Map<String, String>{'Shipping_Zone__c' => 'Central'}, Opportunity.class);
        opp.Shipping_Method__c = 'Ground';
        OpportunityWorkflowConversion.updateShippingCost(opp);
        System.assertEquals(35, opp.Freight_Cost__c);

        opp.Shipping_Method__c = '3 Day Select';
        OpportunityWorkflowConversion.updateShippingCost(opp);
        System.assertEquals(102, opp.Freight_Cost__c);

        opp.Shipping_Method__c = 'Next Day Air';
        OpportunityWorkflowConversion.updateShippingCost(opp);
        System.assertEquals(299, opp.Freight_Cost__c);

        opp = (Opportunity) replaceFieldArbitrarily(opp, new Map<String, String>{'Shipping_Zone__c' => 'East'}, Opportunity.class);
        opp.Shipping_Method__c = 'Ground';
        OpportunityWorkflowConversion.updateShippingCost(opp);
        System.assertEquals(40, opp.Freight_Cost__c);

        opp.Shipping_Method__c = '3 Day Select';
        OpportunityWorkflowConversion.updateShippingCost(opp);
        System.assertEquals(114, opp.Freight_Cost__c);

        opp.Shipping_Method__c = 'Next Day Air';
        OpportunityWorkflowConversion.updateShippingCost(opp);
        System.assertEquals(306, opp.Freight_Cost__c);

        opp = (Opportunity) replaceFieldArbitrarily(opp, new Map<String, String>{'Shipping_Zone__c' => 'Mexico'}, Opportunity.class);
        opp.Shipping_Method__c = 'MX Standard';
        OpportunityWorkflowConversion.updateShippingCost(opp);
        opp.Shipping_Method__c = 'MX Express';
        OpportunityWorkflowConversion.updateShippingCost(opp);
    }
    
    @isTest
    public static void testFor_updateShippingCostCanadaAndFrance(){
        initialize();

        Account acc = (Account) TestFactory.createSObject(new Account(), true);
        Shipping_Address__c ship = (Shipping_Address__c) TestFactory.createSObject(new Shipping_Address__c(
            Account__c = acc.Id,
            Shipping_Country__c = 'France',
            Shipping_State__c = '',
            Shipping_Zip_Code__c='97456'
        ), true);

        self.newOpportunity.Type = 'Revenue Opportunity - Bill Only';
        self.newOpportunity.Shipping_Method__c = 'Ground';
        self.newOpportunity.Shipping_Account_Type__c = 'Not UPS';
        self.newOpportunity.Probability = 70;

        self.newOpportunity.Shipping_Country__c = 'France';

        // Fixing references for insert
        self.newOpportunity.AccountId = acc.Id;
        self.newOpportunity.Returning_Opportunity__c = null;
        self.newOpportunity.Id = null;
        self.newOpportunity.Shipping_Address_NEW__c = ship.Id;

        insert self.newOpportunity;

        // Create Opp Products
        Product2 product = (Product2) TestFactory.createSObject(new Product2(Dimensions_cm3__c = 250), true);
        PricebookEntry entry = (PricebookEntry) TestFactory.createSObject(new PricebookEntry(Pricebook2Id = Test.getStandardPricebookId(), Product2Id = product.Id, UnitPrice = 250), true);

        OpportunityLineItem item = (OpportunityLineItem) TestFactory.createSObject(
            new OpportunityLineItem(
                OpportunityId = self.newOpportunity.Id,
                Total_Dimensions_Copy__c = 50,
                Quantity = 1,
                Product2Id = product.Id,
                PricebookEntryId = entry.Id
            ), true
        );
        
        Opportunity opp = [SELECT Id, Name, Shipping_Address_NEW__r.Shipping_Country__c, Shipping_Address_NEW__r.Shipping_State__c, Shipping_Address_NEW__c, Freight_Cost__c, Shipping_Method__c, Total_Product_Dimensions__c, Shipping_Zone__c, Shipping_Country__c, Shipping_and_Handling_Manual__c, Total_Weight_oz__c, AccountId, Type, Probability, Shipping_Account_Type__c FROM Opportunity WHERE Id = :self.newOpportunity.Id];

        opp = (Opportunity) replaceFieldArbitrarily(opp, new Map<String, String>{'Shipping_Zone__c' => 'Mid-east'}, Opportunity.class);
        opp.Shipping_Method__c = 'Ground';
        OpportunityWorkflowConversion.updateShippingCostCanadaAndFrance(opp);
        System.assertEquals(88, opp.Freight_Cost__c);

        opp = (Opportunity) replaceFieldArbitrarily(opp, new Map<String, String>{'Shipping_Zone__c' => 'West'}, Opportunity.class);
        opp.Shipping_Method__c = 'Ground';
        OpportunityWorkflowConversion.updateShippingCostCanadaAndFrance(opp);
        System.assertEquals(72, opp.Freight_Cost__c);

        opp = (Opportunity) replaceFieldArbitrarily(opp, new Map<String, String>{'Shipping_Zone__c' => 'Spain'}, Opportunity.class);
        opp.Shipping_Method__c = 'UK Standard';
        OpportunityWorkflowConversion.updateShippingCostCanadaAndFrance(opp);
        System.assertEquals(25, opp.Freight_Cost__c);

        opp.Shipping_Method__c = 'UK Express';
        OpportunityWorkflowConversion.updateShippingCostCanadaAndFrance(opp);
        System.assertEquals(99999.99, opp.Freight_Cost__c);

        opp = (Opportunity) replaceFieldArbitrarily(opp, new Map<String, String>{'Shipping_Zone__c' => 'France'}, Opportunity.class);
        opp.Shipping_Method__c = 'UK Standard';
        OpportunityWorkflowConversion.updateShippingCostCanadaAndFrance(opp);
        System.assertEquals(25, opp.Freight_Cost__c);

        opp.Shipping_Method__c = 'UK Express';
        OpportunityWorkflowConversion.updateShippingCostCanadaAndFrance(opp);
        System.assertEquals(55, opp.Freight_Cost__c);

        opp = (Opportunity) replaceFieldArbitrarily(opp, new Map<String, String>{'Shipping_Zone__c' => 'Mid-east'}, Opportunity.class);
        opp.Shipping_Method__c = '3 Day Select';
        OpportunityWorkflowConversion.updateShippingCostCanadaAndFrance(opp);
        System.assertEquals(153, opp.Freight_Cost__c);

        opp.Shipping_Method__c = 'Worldwide Expedited';
        OpportunityWorkflowConversion.updateShippingCostCanadaAndFrance(opp);
        System.assertEquals(75, opp.Freight_Cost__c);

        opp = (Opportunity) replaceFieldArbitrarily(opp, new Map<String, String>{'Shipping_Zone__c' => 'Territory'}, Opportunity.class);
        opp.Shipping_Method__c = 'Ground';
        OpportunityWorkflowConversion.updateShippingCostCanadaAndFrance(opp);
        System.assertEquals(92, opp.Freight_Cost__c);

        opp.Shipping_Method__c = '3 Day Select';
        OpportunityWorkflowConversion.updateShippingCostCanadaAndFrance(opp);
        System.assertEquals(153, opp.Freight_Cost__c);

        opp.Shipping_Method__c = 'Worldwide Expedited';
        OpportunityWorkflowConversion.updateShippingCostCanadaAndFrance(opp);
        System.assertEquals(82, opp.Freight_Cost__c);

        opp = (Opportunity) replaceFieldArbitrarily(opp, new Map<String, String>{'Shipping_Zone__c' => 'East'}, Opportunity.class);
        opp.Shipping_Method__c = 'Ground';
        OpportunityWorkflowConversion.updateShippingCostCanadaAndFrance(opp);
        System.assertEquals(45, opp.Freight_Cost__c);

        opp.Shipping_Method__c = '3 Day Select';
        OpportunityWorkflowConversion.updateShippingCostCanadaAndFrance(opp);
        System.assertEquals(130, opp.Freight_Cost__c);

        opp.Shipping_Method__c = 'Worldwide Expedited';
        OpportunityWorkflowConversion.updateShippingCostCanadaAndFrance(opp);
        System.assertEquals(82, opp.Freight_Cost__c);

        opp = (Opportunity) replaceFieldArbitrarily(opp, new Map<String, String>{'Shipping_Zone__c' => 'West'}, Opportunity.class);
        opp.Shipping_Method__c = '3 Day Select';
        OpportunityWorkflowConversion.updateShippingCostCanadaAndFrance(opp);
        System.assertEquals(130, opp.Freight_Cost__c);

        opp.Shipping_Method__c = 'Worldwide Expedited';
        OpportunityWorkflowConversion.updateShippingCostCanadaAndFrance(opp);
        System.assertEquals(52, opp.Freight_Cost__c);

        opp = (Opportunity) replaceFieldArbitrarily(opp, new Map<String, String>{'Shipping_Zone__c' => 'Mid-west'}, Opportunity.class);
        opp.Shipping_Method__c = 'Ground';
        OpportunityWorkflowConversion.updateShippingCostCanadaAndFrance(opp);
        System.assertEquals(73, opp.Freight_Cost__c);

        opp.Shipping_Method__c = '3 Day Select';
        OpportunityWorkflowConversion.updateShippingCostCanadaAndFrance(opp);
        System.assertEquals(130, opp.Freight_Cost__c);

        opp.Shipping_Method__c = 'Worldwide Expedited';
        OpportunityWorkflowConversion.updateShippingCostCanadaAndFrance(opp);
        System.assertEquals(60, opp.Freight_Cost__c);
    }
    
    @isTest
    public static void testFor_setPriceBookName(){
        initialize();

        self.newOpportunity.Price_Book_Name__c = 'Random Pricebook';
        self.oldOpportunity.Id = null;
        
        OpportunityWorkflowConversion.setPriceBookName(self.newOpportunity, self.oldOpportunity, self.completeOpportunity);
        System.assertEquals(self.completeOpportunity.Pricebook2.Name, self.newOpportunity.Price_Book_Name__c);
    }
    
    /*@isTest
    public static void testFor_copyOwnerRole(){
        initialize();
        
        // Test #1
        self.newOpportunity.Owner_Role_Copy__c = null;
        self.newOpportunity.Rebate_Type__c = 'Delinquent';
        self.newOpportunity.Type = 'Rebate';
        self.completeOpportunity.Returning_Opportunity__r.Owner_Role_Copy__c = 'Test Data';

        OpportunityWorkflowConversion.copyOwnerRole(self.newOpportunity,null, self.completeOpportunity, self.completeOpportunity.Owner);
        System.assertEquals('Test Data', self.newOpportunity.Owner_Role_Copy__c);

        // Test #2
        self.newOpportunity.Returning_Opportunity__c = null;

        OpportunityWorkflowConversion.copyOwnerRole(self.newOpportunity,self.oldOpportunity, self.completeOpportunity, self.completeOpportunity.Owner);
        System.assertNotEquals(self.completeOpportunity.Owner.UserRole.Name, self.newOpportunity.Owner_Role_Copy__c);

    }*/
    
    @isTest
    public static void testFor_closingAlertforRepsManager(){
        initialize();

        // Test #1
        self.newOpportunity.StageName = 'Closing';
        self.newOpportunity.Owner_Manager_Email_Copy__c = 'Something';
        self.newOpportunity.Type = 'Promo Opportunity';

        User u = new User(
            Id = UserInfo.getUserId(),
            Manager = new User(
                Id = TestFactory.getFakeId(User.getSObjectType()),
                Email = 'manager@samsara.com'
            )
        );

        OpportunityWorkflowConversion.closingAlertforRepsManager(self.newOpportunity, self.oldOpportunity, self.completeOpportunity, u);
        System.assertEquals('manager@samsara.com', self.newOpportunity.Owner_Manager_Email_Copy__c);

        // Test #2
        self.newOpportunity.Owner_Manager_Email_Copy__c = '';
        self.newOpportunity.Type = 'Rebate';

        self.completeOpportunity.Returning_Opportunity__r.Owner_Manager_Email_Copy__c = 'another.manager@samsara.com';

        OpportunityWorkflowConversion.closingAlertforRepsManager(self.newOpportunity, self.oldOpportunity, self.completeOpportunity, u);
        System.assertEquals('another.manager@samsara.com', self.newOpportunity.Owner_Manager_Email_Copy__c);

        // Test #3
        self.newOpportunity.Owner_Manager_Email_Copy__c = 'Something unrelated';
        self.newOpportunity.Type = 'Another Type';

        OpportunityWorkflowConversion.closingAlertforRepsManager(self.newOpportunity, self.oldOpportunity, self.completeOpportunity, u);
        System.assertEquals('', self.newOpportunity.Owner_Manager_Email_Copy__c);

    }
    
    @isTest
    public static void testFor_matchBlendedToApprovedDiscretionaryDiscount(){
        initialize();

        self.newOpportunity.SBQQ__PrimaryQuote__c = TestFactory.getFakeId(SBQQ__Quote__c.getSObjectType());
        self.newOpportunity.Discount_Approval_Status__c = 'Approved';
        self.newOpportunity.Blended_Discount_CPQ__c = 0.994;
        
        List<FormulaRecalcResult> results = Formula.recalculateFormulas(new List<Opportunity>{self.newOpportunity});
        Decimal discount = (Decimal) results[0].getSObject().get('Blended_Discount__c');

        OpportunityWorkflowConversion.matchBlendedToApprovedDiscretionaryDiscount(self.newOpportunity, self.oldOpportunity);
        System.assertEquals(1.09, self.newOpportunity.Approved_Discount__c); // This value will actually be floored because the field has only two decimals.
    }
    
    @isTest
    public static void testFor_addDefaultExpiringDiscountDate(){
        initialize();

        self.newOpportunity.Probability = 80;
        self.newOpportunity.Discount_Approval_Status__c = 'Approved';
        self.newOpportunity.Checkout_Discount_Expiration_Date_Time__c = null;
        Opportunity newOpp = (Opportunity) setFieldArbitrarily(
            self.newOpportunity,
            new Map<String, String>{
                'CreatedDate' => '"'+System.now().formatGmt('yyyy-MM-dd\'T\'HH:mm:ss.SSSZ')+'"'
            },
            Opportunity.class
        );

        self.completeOpportunity.Owner.Level__c = 'AE 1';

        OpportunityWorkflowConversion.addDefaultExpiringDiscountDate(newOpp, self.oldOpportunity, self.completeOpportunity.Owner);
        if (newOpp.Checkout_Discount_Expiration_Date_Time__c != null)
            System.assertEquals(System.now().addDays(5).day(), newOpp.Checkout_Discount_Expiration_Date_Time__c.day());
        else System.assert(false, 'No value set for Checkout Discount Expiration Date');
    }
    
    @isTest
    public static void testFor_opportunityToAccountRollupWorkflow(){
        //initialize();
        String baseOppStructureJSON = '{"attributes":{"type":"Opportunity","url":"/services/data/v55.0/sobjects/Opportunity/006000000000004AAA"},"Id":"006000000000004AAA","ExpectedRevenue": 2500}';

        Opportunity newOpp = (Opportunity) JSON.deserialize(
            baseOppStructureJSON,
            Opportunity.class
        );
        newOpp.Amount = 1000;
        newOpp.License_Term_Credit_Amount_Custom__c = 5000;

        Opportunity oldOpp = newOpp.clone();
        oldOpp.Id = newOpp.Id;
        oldOpp.License_Term_Credit_Amount_Custom__c = 100;
        
        OpportunityWorkflowConversion.opportunityToAccountRollupWorkflow(newOpp,oldOpp);
        System.assertEquals(1000, newOpp.Amount_Number__c);
        System.assertEquals(2500, newOpp.Expected_Revenue_Number__c);
        System.assertEquals(5000, newOpp.License_Credit_Amount_Number__c);
    }
	@isTest
    public static void test_stampResponsiblePartyEmail(){
        String baseOppStructureJSON = 
            '{"attributes":{"type":"Opportunity","url":"/services/data/v55.0/sobjects/Opportunity/006000000000004AAA"},"Id":"006000000000004AAA","ExpectedRevenue": 2500,"Rebate_Type__c":"License Term Credit", "License_Credit_Subreason__c":"VG - connectivity issues"}';

        Opportunity newOpp = (Opportunity) JSON.deserialize(
            baseOppStructureJSON,
            Opportunity.class
        );
        newOpp.Amount = 1000;
        newOpp.License_Term_Credit_Amount_Custom__c = 5000;

        Opportunity oldOpp = newOpp.clone();
        oldOpp.Id = newOpp.Id;
        oldOpp.License_Credit_Subreason__c = 'AG - low battery replacement';
        oldOpp.License_Term_Credit_Amount_Custom__c = 100;
        Test.startTest();
       	OpportunityWorkflowConversion.stampResponsiblePartyEmail(newOpp, oldOpp);
        Test.stopTest();
    }
    @isTest
    public static void test_referralPayoutAmtUncappedFleet(){
        String baseOppStructureJSON = '{"attributes":{"type":"Opportunity","url":"/services/data/v55.0/sobjects/Opportunity/006000000000004AAA"},"Id":"006000000000004AAA","ExpectedRevenue": 2500, "Owner_Role_Copy__c":"test"}';
		Account acc = (Account) TestFactory.createSObject(new Account(), true);
        Opportunity newOpp = (Opportunity) JSON.deserialize(
            baseOppStructureJSON,
            Opportunity.class
        );
        newOpp.Amount = 1000;
        newOpp.License_Term_Credit_Amount_Custom__c = 5000;
        newOpp.Uncapped_Partner_Referral_Payout_Amount__c = true;
		newOpp.Partner_Referral_Payout_Amount_V2__c = 0;
		newOpp.Referral_Partner__c = acc.Id;
        
        
        Opportunity oldOpp = newOpp.clone();
        oldOpp.Id = null; //newOpp.Id;
        //oldOpp.License_Term_Credit_Amount_Custom__c = 100;
        
        Test.startTest();
       	OpportunityWorkflowConversion.referralPayoutAmtUncappedFleet(newOpp, oldOpp);
        Test.stopTest();
    }
    @isTest
    public static void test_stampTrialCompletionDate(){
        String baseOppStructureJSON = '{"attributes":{"type":"Opportunity","url":"/services/data/v55.0/sobjects/Opportunity/006000000000004AAA"},"Id":"006000000000004AAA","ExpectedRevenue": 2500}';

        Opportunity newOpp = (Opportunity) JSON.deserialize(
            baseOppStructureJSON,
            Opportunity.class
        );
        //newOpp.Amount = 1000;
		newOpp.Trial_Completion_Date__c = System.today();
        newOpp.Trial_Status__c = 'Purchased';
        
        Opportunity oldOpp = newOpp.clone();
        oldOpp.Id = newOpp.Id;
        oldOpp.Trial_Status__c = 'Test';
        Test.startTest();
       	OpportunityWorkflowConversion.stampTrialCompletionDate(newOpp, oldOpp);
        Test.stopTest();
    }
    @isTest
    public static void test_freeTrialReturnDateUpdate(){
        String baseOppStructureJSON = '{"attributes":{"type":"Opportunity","url":"/services/data/v55.0/sobjects/Opportunity/006000000000004AAA"},"Id":"006000000000004AAA","ExpectedRevenue": 2500}';

        Opportunity newOpp = (Opportunity) JSON.deserialize(
            baseOppStructureJSON,
            Opportunity.class
        );
        //newOpp.Amount = 1000;
		newOpp.Trial_Completion_Date__c = System.today();
        newOpp.Trial_Status__c = 'Return In Process';
        newOpp.Type = 'Free Trial Opportunity';
        newOpp.Deactivate__c = true;
        newOpp.RecordTypeId = '0121a000000eOkY';
        newOpp.CloseDate = System.today();
        newOpp.Trial_Period__c = 30;
        
        Opportunity oldOpp = newOpp.clone();
        oldOpp.Id = newOpp.Id;
        oldOpp.Trial_Status__c = 'Test';
        Test.startTest();
       	OpportunityWorkflowConversion.freeTrialReturnDateUpdate(newOpp, oldOpp);
        Test.stopTest();
    }
   /* @isTest --Deprecating AccountFields - GTMS-12857 - July6
    public static void testFor_updateProductDiscountsOnAccount(){
        initialize();

        DMLWrapper.intializeUnitOfWork(new List<Schema.SObjectType>{Account.getSObjectType()});

        self.newOpportunity.Express_Selected_Discount__c = 10;
        self.newOpportunity.Type = 'Revenue Opportunity';
        self.newOpportunity.StageName = 'Closed Won';
        self.newOpportunity.Configuration_Segment__c = 'Express';
        
        Opportunity newOpp = (Opportunity) setFieldArbitrarily(
            self.newOpportunity,
            new Map<String, String>{
                'AG2_License_Count__c' => '10'
            },
            Opportunity.class
        );

        OpportunityWorkflowConversion.updateProductDiscountsOnAccount(newOpp, self.accountOpportunity);

        // For coverage
        newOpp = (Opportunity) setFieldArbitrarily(
            self.newOpportunity,
            new Map<String, String>{
                'VG_License_Count__c' => '11',
                'CM1_License_Count__c' => '12',
                'CM2_License_Count__c' => '13',
                'AG2_License_Count__c' => '14',
                'AG4_License_Count__c' => '15'
            },
            Opportunity.class
        );

        OpportunityWorkflowConversion.updateProductDiscountsOnAccount(newOpp, self.accountOpportunity);
        System.assertEquals(10, self.accountOpportunity.VG_Selected_Discount__c);
        System.assertEquals(10, self.accountOpportunity.CM1_Selected_Discount__c);
        System.assertEquals(10, self.accountOpportunity.CM2_Selected_Discount__c);
        System.assertEquals(10, self.accountOpportunity.AG4_Selected_Discount__c);
    }*/

    // Simply appends fields to the JSON before deserializing it. You must provide the quotation marks if your variable type needs it, and no lists are supported.
    public static SObject setFieldArbitrarily(SObject obj, Map<String, String> valueList, System.Type deserializeType){
        String serializedRecord = JSON.serialize(obj).removeEnd('}');
        for (String field : valueList.keySet()){
            serializedRecord += ',"'+field+'":'+valueList.get(field);
        }

        return (SObject) JSON.deserialize(serializedRecord+'}', deserializeType);
    }

    // This method is expected to be used only for strings, so no other types are supported
    public static SObject replaceFieldArbitrarily(SObject obj, Map<String, String> valueList, System.Type deserializeType){
        String serializedRecord = JSON.serialize(obj);
        for (String field : valueList.keySet()){
            serializedRecord = serializedRecord.replaceAll('"'+field+'"\\s*:\\s*"[^"]+"', '"'+field+'":"'+valueList.get(field)+'"');
        }

        System.debug(serializedRecord);
        return (SObject) JSON.deserialize(serializedRecord, deserializeType);
    }
}