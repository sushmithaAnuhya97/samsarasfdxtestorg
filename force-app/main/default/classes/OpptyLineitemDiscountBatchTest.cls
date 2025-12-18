@isTest
private class OpptyLineitemDiscountBatchTest {
		Static Account testAccount;
     @testSetup static void setup() {
     
        Account acc = new Account ();
        acc = TestFactory.initializeAccount('Active_Growth_Campaigns_Count');
        acc.Book_Of_Business__c = 'Core';
        insert acc;
        
        Customer_360__c cs = new Customer_360__c ();
        cs.Account__c = acc.Id;
        cs.SOT__c = true;
        Insert cs;
         
        Contract cont = new Contract(
            AccountId = acc.Id,
            StartDate = System.today(),
            EndDate   = System.today().addDays(30),
            ContractTerm = 1,
            Status = 'Draft'
        );
        insert cont;
         
        cont.Status = 'Activated';
        update cont;
         
        Id pricebookId = Test.getStandardPricebookId();
        addProducts(pricebookId);
         PricebookEntry  licATfm = getPricebookEntry(pricebookId, 'LIC-AT-TAG');
         PricebookEntry  vgLd = getPricebookEntry(pricebookId, 'LIC-VG-LD');
        PricebookEntry vg33 = getPricebookEntry(pricebookId, 'LIC-AG4');
        PricebookEntry cmBest = getPricebookEntry(pricebookId, 'LIC-CM-S-ESS-PLTFM-PREM');
         PricebookEntry cmDBest = getPricebookEntry(pricebookId, 'LIC-CM-D-ESS-PLTFM-PREM');
         PricebookEntry vgBest = getPricebookEntry(pricebookId, 'LIC-VG-PUBSEC-PLTFM-ESS');
         PricebookEntry vgBasic = getPricebookEntry(pricebookId, 'LIC-VG-BASIC');
         PricebookEntry vgENT = getPricebookEntry(pricebookId, 'LIC-VG-ENT');
         PricebookEntry vgPro = getPricebookEntry(pricebookId, 'LIC-VG-PRO');
         PricebookEntry licCM1 = getPricebookEntry(pricebookId, 'LIC-CM1-PRO');
         PricebookEntry licCM11 = getPricebookEntry(pricebookId, 'LIC-CM1-PRO');
         PricebookEntry licCM2 = getPricebookEntry(pricebookId, 'LIC-CM2-PRO');
         PricebookEntry  licPltfm = getPricebookEntry(pricebookId, 'LIC-PLTFM-PRO');
         PricebookEntry  licReefer = getPricebookEntry(pricebookId, 'LIC-AG-PWR-REEFER-PLTFM-ESS');
         PricebookEntry  licReeferKit = getPricebookEntry(pricebookId, 'LIC-AG-PWR-REEFER-KIT-PLTFM-ESS');
         PricebookEntry  licTrlrEss = getPricebookEntry(pricebookId, 'LIC-TRLR-ESS');
         PricebookEntry  licTrlrPrem= getPricebookEntry(pricebookId, 'LIC-TRLR-PREM');
         PricebookEntry  licTrlrPremKit = getPricebookEntry(pricebookId, 'LIC-TRLR-PREM-KIT');
        PricebookEntry  licEiSec = getPricebookEntry(pricebookId, 'LIC-EI-SEC');
         /* Edit on OEM Related changes commented  24th, Sep 2024 - Abu - GTMS-22195 */
          PricebookEntry  licOEMEquipment = getPricebookEntry(pricebookId, 'LIC-OEM-EQUIPMENT-ADDON');
         PricebookEntry  licOEMFord = getPricebookEntry(pricebookId, 'LIC-OEM-FORD-ADDON');
         PricebookEntry  licOEMGm = getPricebookEntry(pricebookId, 'LIC-OEM-GM-ADDON');
         PricebookEntry  licOEMNvi = getPricebookEntry(pricebookId, 'LIC-OEM-NVI-ADDON');
         PricebookEntry  licOEMStlla = getPricebookEntry(pricebookId, 'LIC-OEM-STLLA-ADDON');
         // FORMS and Training SKU's
         PricebookEntry  licFORMSEss = getPricebookEntry(pricebookId, 'LIC-FORMS-ESS');
         PricebookEntry  licFORMSPrem = getPricebookEntry(pricebookId, 'LIC-FORMS-PREM');
         PricebookEntry  licMEMENT = getPricebookEntry(pricebookId, 'LIC-MEM-ENT');
         PricebookEntry  licTraining = getPricebookEntry(pricebookId, 'LIC-TRAINING');
         PricebookEntry  licTrainingEss = getPricebookEntry(pricebookId, 'LIC-TRAINING-PLTFM-ESS');
         PricebookEntry  licTrainingPrem = getPricebookEntry(pricebookId, 'LIC-TRAINING-PLTFM-PREM');
         /* Edit End OEM Related changes commented  24th, Sep 2024 - Abu - GTMS-22195 */

        Test.StartTest();
        Opportunity thisOpp = new Opportunity();
        thisOpp = TestFactory.initializeOpportunity ('Active_Growth_Campaigns_Count');
        thisOpp.Type = 'Revenue Opportunity' ;
        thisOpp.StageName = 'Closed Won';
        thisopp.Went_to_Closed_Won_Date__c = system.today() -1;
        thisOpp.AccountId = acc.Id;
        thisopp.CloseDate =system.today() - 1;
        thisopp.amount= 10;
        //Start: GTMS-22362,22907 fix for code coverage issue --- OCT 3 2024 - Abu 
        TriggerHandler.bypass('OpportunityTriggerHandler');
          TriggerHandler.bypass('GS_OpportunityTriggerHandler');
        TriggerHandler.bypass('OpportunityTriggerHandlerContext');
        //End: GTMS-22362,22907 fix for code coverage issue --- OCT 3 2024 - Abu 
        insert thisOpp;
        
        system.debug('The opp value is ' + thisOpp);
         //Start: GTMS-22362,22907 fix for code coverage issue --- OCT 3 2024 - Abu
        TriggerHandler.clearBypass('OpportunityTriggerHandler');
         //End: GTMS-22362,22907 fix for code coverage issue --- OCT 3 2024 - Abu 
        
        List<OpportunityLineItem> oLiList = new List<OpportunityLineItem>();
        OpportunityLineItem oli = new OpportunityLineItem(OpportunityId = thisOpp.Id, Quantity = 10,
                PriceBookEntryId = vg33.Id,UnitPrice = vg33.UnitPrice, Account__c = acc.Id);
        oLiList.add(oli);
       	OpportunityLineItem oli1 = new OpportunityLineItem(OpportunityId = thisOpp.Id, Quantity = 10,
                PriceBookEntryId = cmBest.Id,UnitPrice = cmBest.UnitPrice, Account__c = acc.Id);
        oLiList.add(oli1);
         OpportunityLineItem oli11 = new OpportunityLineItem(OpportunityId = thisOpp.Id, Quantity = 10,
                PriceBookEntryId = cmDBest.Id,UnitPrice = cmDBest.UnitPrice, Account__c = acc.Id);
        oLiList.add(oli11);
        OpportunityLineItem oli2 = new OpportunityLineItem(OpportunityId = thisOpp.Id, Quantity = 10,
                PriceBookEntryId = vgBest.Id,UnitPrice = vgBest.UnitPrice, Account__c = acc.Id);
        oLiList.add(oli2);
        OpportunityLineItem oli3 = new OpportunityLineItem(OpportunityId = thisOpp.Id, Quantity = 10,
                PriceBookEntryId = vgBasic.Id,UnitPrice = vgBasic.UnitPrice, Account__c = acc.Id);
        oLiList.add(oli3);
        OpportunityLineItem oli4 = new OpportunityLineItem(OpportunityId = thisOpp.Id, Quantity = 10,
                PriceBookEntryId = vgENT.Id,UnitPrice = vgENT.UnitPrice, Account__c = acc.Id);
         oLiList.add(oli4);
        OpportunityLineItem oli5 = new OpportunityLineItem(OpportunityId = thisOpp.Id, Quantity = 10,
                PriceBookEntryId = vgPro.Id,UnitPrice = vgPro.UnitPrice, Account__c = acc.Id);
         oLiList.add(oli5);
        OpportunityLineItem oli6 = new OpportunityLineItem(OpportunityId = thisOpp.Id, Quantity = 10,
                PriceBookEntryId = licCM1.Id,UnitPrice = licCM1.UnitPrice, Account__c = acc.Id);
         oLiList.add(oli6);
         OpportunityLineItem oli7 = new OpportunityLineItem(OpportunityId = thisOpp.Id, Quantity = 10,
                PriceBookEntryId = licCM2.Id,UnitPrice = licCM2.UnitPrice, Account__c = acc.Id);
         oLiList.add(oli7);
         OpportunityLineItem oli8 = new OpportunityLineItem(OpportunityId = thisOpp.Id, Quantity = 10,
                PriceBookEntryId = licPltfm.Id,UnitPrice = licPltfm.UnitPrice, Account__c = acc.Id);
        oLiList.add(oli8);
        OpportunityLineItem oli9 = new OpportunityLineItem(OpportunityId = thisOpp.Id, Quantity = 10,
                PriceBookEntryId = licCM11.Id,UnitPrice = licCM1.UnitPrice, Account__c = acc.Id);
         oLiList.add(oli9); 
         OpportunityLineItem oli10 = new OpportunityLineItem(OpportunityId = thisOpp.Id, Quantity = 10,
                PriceBookEntryId = licATfm.Id,UnitPrice = licATfm.UnitPrice, Account__c = acc.Id);
         oLiList.add(oli10); 
         OpportunityLineItem oli12 = new OpportunityLineItem(OpportunityId = thisOpp.Id, Quantity = 10,
                PriceBookEntryId = licReefer.Id,UnitPrice = licReefer.UnitPrice, Account__c = acc.Id);
         oLiList.add(oli12); 
         OpportunityLineItem oli13 = new OpportunityLineItem(OpportunityId = thisOpp.Id, Quantity = 10,
                PriceBookEntryId = licReeferKit.Id,UnitPrice = licReeferKit.UnitPrice, Account__c = acc.Id);
         oLiList.add(oli13); 
         OpportunityLineItem oli14 = new OpportunityLineItem(OpportunityId = thisOpp.Id, Quantity = 10,
                PriceBookEntryId = licTrlrEss.Id,UnitPrice = licTrlrEss.UnitPrice, Account__c = acc.Id);
         oLiList.add(oli14); 
         OpportunityLineItem oli15 = new OpportunityLineItem(OpportunityId = thisOpp.Id, Quantity = 10,
                PriceBookEntryId = licTrlrPrem.Id,UnitPrice = licTrlrPrem.UnitPrice, Account__c = acc.Id);
         oLiList.add(oli15); 
         OpportunityLineItem oli16 = new OpportunityLineItem(OpportunityId = thisOpp.Id, Quantity = 10,
                PriceBookEntryId = licTrlrPremKit.Id,UnitPrice = licTrlrPremKit.UnitPrice, Account__c = acc.Id);
         oLiList.add(oli16);  
        OpportunityLineItem oli17 = new OpportunityLineItem(OpportunityId = thisOpp.Id, Quantity = 10,
                                                            PriceBookEntryId = licEiSec.Id,UnitPrice = licEiSec.UnitPrice, Account__c = acc.Id);
        oLiList.add(oli17); 
         /* Edit on OEM Related changes commented  24th, Sep 2024 - Abu - GTMS-22195 */
         OpportunityLineItem oli22 = new OpportunityLineItem(OpportunityId = thisOpp.Id, Quantity = 10,
                PriceBookEntryId = licOEMEquipment.Id,UnitPrice = licOEMEquipment.UnitPrice, Account__c = acc.Id);
         oLiList.add(oli22); 
         OpportunityLineItem oli18 = new OpportunityLineItem(OpportunityId = thisOpp.Id, Quantity = 10,
                PriceBookEntryId = licOEMFord.Id,UnitPrice = licOEMFord.UnitPrice, Account__c = acc.Id);
         oLiList.add(oli18); 
         OpportunityLineItem oli19 = new OpportunityLineItem(OpportunityId = thisOpp.Id, Quantity = 10,
                PriceBookEntryId = licOEMGm.Id,UnitPrice = licOEMGm.UnitPrice, Account__c = acc.Id);
         oLiList.add(oli19); 
         OpportunityLineItem oli20 = new OpportunityLineItem(OpportunityId = thisOpp.Id, Quantity = 10,
                PriceBookEntryId = licOEMNvi.Id,UnitPrice = licOEMNvi.UnitPrice, Account__c = acc.Id);
         oLiList.add(oli20); 
         OpportunityLineItem oli21 = new OpportunityLineItem(OpportunityId = thisOpp.Id, Quantity = 10,
                PriceBookEntryId = licOEMStlla.Id,UnitPrice = licOEMStlla.UnitPrice, Account__c = acc.Id);
         oLiList.add(oli21);
         // FORMS and Training SKU'S
         OpportunityLineItem oli23 = new OpportunityLineItem(OpportunityId = thisOpp.Id, Quantity = 10,
                PriceBookEntryId = licFORMSEss.Id,UnitPrice = licFORMSEss.UnitPrice, Account__c = acc.Id);
         oLiList.add(oli23);
         OpportunityLineItem oli24 = new OpportunityLineItem(OpportunityId = thisOpp.Id, Quantity = 10,
                PriceBookEntryId = licFORMSPrem.Id,UnitPrice = licFORMSPrem.UnitPrice, Account__c = acc.Id);
         oLiList.add(oli24);
         OpportunityLineItem oli25 = new OpportunityLineItem(OpportunityId = thisOpp.Id, Quantity = 10,
                PriceBookEntryId = licMEMENT.Id,UnitPrice = licMEMENT.UnitPrice, Account__c = acc.Id);
         oLiList.add(oli25);
         OpportunityLineItem oli26 = new OpportunityLineItem(OpportunityId = thisOpp.Id, Quantity = 10,
                PriceBookEntryId = licTraining.Id,UnitPrice = licTraining.UnitPrice, Account__c = acc.Id);
         oLiList.add(oli26);
         OpportunityLineItem oli27 = new OpportunityLineItem(OpportunityId = thisOpp.Id, Quantity = 10,
                PriceBookEntryId = licTrainingEss.Id,UnitPrice = licTrainingEss.UnitPrice, Account__c = acc.Id);
         oLiList.add(oli27);
         OpportunityLineItem oli28 = new OpportunityLineItem(OpportunityId = thisOpp.Id, Quantity = 10,
                PriceBookEntryId = licTrainingPrem.Id,UnitPrice = licTrainingPrem.UnitPrice, Account__c = acc.Id);
         oLiList.add(oli28);
         OpportunityLineItem oli29 = new OpportunityLineItem(OpportunityId = thisOpp.Id, Quantity = 10,
                PriceBookEntryId = vgLd.Id,UnitPrice = vgLd.UnitPrice, Account__c = acc.Id);
         oLiList.add(oli29);
         /* Edit End OEM Related changes commented  24th, Sep 2024 - Abu - GTMS-22195 */
        insert oLiList;         
         TriggerHandler.clearbypass('OpportunityTriggerHandler');
          TriggerHandler.clearbypass('GS_OpportunityTriggerHandler');
        TriggerHandler.clearbypass('OpportunityTriggerHandlerContext');
         // Create account
        List<Account> newAccount = new List<Account>();
        Account account = new Account (Name = 'Test Account', Organization_Size__c = '5000+', BillingCountry = 'Canada', Industry = 'Other');
        newAccount.add(account);                 
        insert newAccount;
         
         // Create Contact
        List<Contact> newContacts = new List<Contact>();
        Contact contact = new Contact (FirstName = 'User', LastName = 'Tester', Email = 'test@test.com', AccountId=account.Id);
        newContacts.add(contact);
         
         //Create Shipping Address
         List<Shipping_Address__c> shippingAddresses = new  List<Shipping_Address__c>();
         Shipping_Address__c shipToOne = new Shipping_Address__c(Account__c = account.Id, Shipping_Contact__c = contact.Id, Shipping_Address_Line_1__c = '444 Deharo St'
                                                              , Shipping_City__c = 'San Francisco', Shipping_State__c = 'California', Shipping_Country__c ='United States'
                                                              , Shipping_Zip_Code__c = '95054', Name = 'Ship To One');
         shippingAddresses.add(shipToOne);   
         
         Shipping_Address__c shipToFour = new Shipping_Address__c(Account__c = account.Id, Shipping_Contact__c = contact.Id, Shipping_Address_Line_1__c = '1 Parliment St'
                                                                  , Shipping_Address_Line_2__c= 'XYZ'
                                                                  , Shipping_City__c = 'London'
                                                                  , Shipping_Country__c ='United Kingdom'
                                                                  , Shipping_Zip_Code__c = 'SW1A2JR', Name = 'Ship To Four');
         shippingAddresses.add(shipToFour);
         insert shippingAddresses;
         
        Test.stopTest();
     
     }
    @isTest static void testpositivieusecase() {
        Account acc = new Account ();
        acc = TestFactory.initializeAccount('Active_Growth_Campaigns_Count');
        
        insert acc;
      
        Test.StartTest();
        
        Id pricebookId = Test.getStandardPricebookId();
        addProducts(pricebookId);
        PricebookEntry vg33 = getPricebookEntry(pricebookId, 'LIC-AG4');
        

        Opportunity thisOpp = new Opportunity();
        thisOpp = TestFactory.initializeOpportunity ('Active_Growth_Campaigns_Count');
        thisOpp.Type = 'Revenue Opportunity' ;
        thisOpp.StageName = 'Closed Won';
        thisopp.Went_to_Closed_Lost_Date__c = system.today()-1;
        thisOpp.AccountId = acc.Id;
        //Start: GTMS-22362,22907 fix for code coverage issue --- OCT 3 2024 - Abu
        TriggerHandler.bypass('OpportunityTriggerHandler');
          TriggerHandler.bypass('GS_OpportunityTriggerHandler');
        TriggerHandler.bypass('OpportunityTriggerHandlerContext');
        
        //End: GTMS-22362,22907 fix for code coverage issue --- OCT 3 2024 - Abu
        insert thisOpp;
        system.debug('The opp value is ' + thisOpp);
        //Start: GTMS-22362,22907 fix for code coverage issue --- OCT 3 2024 - Abu
        TriggerHandler.clearBypass('OpportunityTriggerHandler');
         TriggerHandler.clearBypass('GS_OpportunityTriggerHandler');
        TriggerHandler.clearBypass('OpportunityTriggerHandlerContext');
        //End: GTMS-22362,22907 fix for code coverage issue --- OCT 3 2024 - Abu    
        List<OpportunityLineItem> oLiList = new List<OpportunityLineItem>();
        OpportunityLineItem oli = new OpportunityLineItem(OpportunityId = thisOpp.Id, Quantity = 10,
                PriceBookEntryId = vg33.Id,UnitPrice = vg33.UnitPrice, Account__c = acc.Id);
        oLiList.add(oli);
       
        insert oLiList;
          OpptyLineitemDiscountBatchSchedular o = new OpptyLineitemDiscountBatchSchedular ();
          String sch = '0 0 2 * * ?';
          system.schedule('Test status Check', sch, o );
         String q = null;
          OpptyLineitemDiscountBatch db = new OpptyLineitemDiscountBatch(q);
          db.ProcessProdCode('TEST-TEST-TEST');
          Test.stopTest();
       }
     static private void addProducts(Id pricebookId) {

        List<Product2> products = new List<Product2>();
        Product2 vg33 = new Product2(Name = 'LIC-AG4', ProductCode = 'LIC-AG4', Family = 'Test');
        Product2 vgLd = new Product2(Name = 'LIC-VG-LD', ProductCode = 'LIC-VG-LD', Family = 'Test');
        Product2 cmBest = new Product2(Name = 'LIC-CM-S-ESS-PLTFM-ESS', ProductCode = 'LIC-CM-S-ESS-PLTFM-PREM', Family = 'Test', License_Type__c = 'Tier');
         Product2 cmDBest = new Product2(Name = 'LIC-CM-D-ESS-PLTFM-ESS', ProductCode = 'LIC-CM-D-ESS-PLTFM-PREM', Family = 'Test', License_Type__c = 'Tier');
        Product2 vgBest = new Product2(Name = 'LIC-VG-PUBSEC-PLTFM-ESS', ProductCode = 'LIC-VG-PUBSEC-PLTFM-ESS', Family = 'Test', License_Type__c = 'FY26 Tier');
        Product2 vgBasic = new Product2(Name = 'LIC-VG-BASIC', ProductCode = 'LIC-VG-BASIC', Family = 'Test', License_Type__c = 'FY26 Tier');
        Product2 vgENT = new Product2(Name = 'LIC-VG-ENT', ProductCode = 'LIC-VG-ENT', Family = 'Test');
        Product2 vgPro = new Product2(Name = 'LIC-VG-PRO', ProductCode = 'LIC-VG-PRO', Family = 'Test');
        Product2 licCM1 = new Product2(Name = 'LIC-CM1-PRO', ProductCode = 'LIC-CM1-PRO', Family = 'Test');
        Product2 licCM2 = new Product2(Name = 'LIC-CM2-PRO', ProductCode = 'LIC-CM2-PRO', Family = 'Test');
        Product2 licpltfm = new Product2(Name = 'LIC-PLTFM-PRO', ProductCode = 'LIC-PLTFM-PRO', Family = 'Test');

        Product2 licatfm = new Product2(Name = 'LIC-AT-TAG', ProductCode = 'LIC-AT-TAG', Family = 'Test');
        Product2 licReefer = new Product2(Name = 'LIC-AG-PWR-REEFER-PLTFM-ESS', ProductCode ='LIC-AG-PWR-REEFER-PLTFM-ESS', Family = 'Test');
        Product2 licReeferKit = new Product2(Name = 'LIC-AG-PWR-REEFER-KIT-PLTFM-ESS', ProductCode = 'LIC-AG-PWR-REEFER-KIT-PLTFM-ESS', Family = 'Test');
        Product2 licTrlrEss = new Product2(Name = 'LIC-TRLR-ESS', ProductCode = 'LIC-TRLR-ESS', Family = 'Test');
        Product2 licTrlrPrem = new Product2(Name = 'LIC-TRLR-PREM', ProductCode = 'LIC-TRLR-PREM', Family = 'Test');
        Product2 licTrlrPremKit = new Product2(Name = 'LIC-TRLR-PREM-KIT', ProductCode = 'LIC-TRLR-PREM-KIT', Family = 'Test');
        Product2 licEiSec = new Product2(Name = 'LIC-EI-SEC', ProductCode = 'LIC-EI-SEC', Family = 'Test');
        /* Edit on OEM Related changes commented  24th, Sep 2024 - Abu - GTMS-22195 */
        Product2 licOEMEquipment = new Product2(Name = 'LIC-OEM-EQUIPMENT-ADDON', ProductCode = 'LIC-OEM-EQUIPMENT-ADDON', Family = 'Test');
        Product2 licOEMFord = new Product2(Name = 'LIC-OEM-FORD-ADDON', ProductCode = 'LIC-OEM-FORD-ADDON', Family = 'Test');
        Product2 licOEMGm = new Product2(Name = 'LIC-OEM-GM-ADDON', ProductCode = 'LIC-OEM-GM-ADDON', Family = 'Test');
        Product2 licOEMNvi = new Product2(Name = 'LIC-OEM-NVI-ADDON', ProductCode = 'LIC-OEM-NVI-ADDON', Family = 'Test');
        Product2 licOEMStlla = new Product2(Name = 'LIC-OEM-STLLA-ADDON', ProductCode = 'LIC-OEM-STLLA-ADDON', Family = 'Test');
        // Forms and Training SKU'S
        Product2 licFormsEss = new Product2(Name = 'LIC-FORMS-ESS', ProductCode = 'LIC-FORMS-ESS', Family = 'Test');
        Product2 licFORMSPrem = new Product2(Name = 'LIC-FORMS-PREM', ProductCode = 'LIC-FORMS-PREM', Family = 'Test');
        Product2 licMEMEnt = new Product2(Name = 'LIC-MEM-ENT', ProductCode = 'LIC-MEM-ENT', Family = 'Test');
        Product2 licTraining = new Product2(Name = 'LIC-TRAINING', ProductCode = 'LIC-TRAINING', Family = 'Test');
        Product2 licTrainingEss = new Product2(Name = 'LIC-TRAINING-PLTFM-ESS', ProductCode = 'LIC-TRAINING-PLTFM-ESS', Family = 'Test', License_Type__c = 'Tier');
        Product2 licTrainingPrem = new Product2(Name = 'LIC-TRAINING-PLTFM-PREM', ProductCode = 'LIC-TRAINING-PLTFM-PREM', Family = 'Test', License_Type__c = 'FY26 Tier');
        /* Edit End OEM Related changes commented  24th, Sep 2024 - Abu - GTMS-22195 */
        products.add(vg33);
        products.add(vgLd);
        products.add(cmBest);
         products.add(cmDBest);
        products.add(vgBest);
        products.add(vgBasic);
        products.add(vgENT);
         products.add(vgPro);
         products.add(licCM1);
         products.add(licCM2);
         products.add(licpltfm);
         products.add(licatfm);
        products.add(licReefer);
        products.add(licReeferKit);
        products.add(licTrlrEss);
        products.add(licTrlrPrem);
        products.add(licTrlrPremKit);
        products.add(licEiSec);
         /* Edit on OEM Related changes commented  24th, Sep 2024 - Abu - GTMS-22195 */
        products.add(licOEMEquipment);
        products.add(licOEMFord);
        products.add(licOEMGm);
        products.add(licOEMNvi);
        products.add(licOEMStlla);
        // FORMS and Training SKU'S
        products.add(licFormsEss);
        products.add(licFORMSPrem);
        products.add(licMEMEnt);
        products.add(licTraining);
        products.add(licTrainingEss);
        products.add(licTrainingPrem); 
         /* Edit End OEM Related changes commented  24th, Sep 2024 - Abu - GTMS-22195 */
        insert products;
        List<PricebookEntry> pricebookEntries = new List<PricebookEntry>();
        PricebookEntry vg33PB = new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = vg33.Id, UnitPrice = 10000, IsActive = true);
        PricebookEntry vgLdPB = new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = vgLd.Id, UnitPrice = 10000, IsActive = true);
        PricebookEntry cmBestPBE = new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = cmBest.Id, UnitPrice = 10000, IsActive = true);
         PricebookEntry cmDBestPBE = new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = cmDBest.Id, UnitPrice = 10000, IsActive = true);
        PricebookEntry vgBestPBE = new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = vgBest.Id, UnitPrice = 10000, IsActive = true);
        PricebookEntry vgBasicPBE = new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = vgBasic.Id, UnitPrice = 10000, IsActive = true);
        PricebookEntry vgENTPBE = new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = vgENT.Id, UnitPrice = 10000, IsActive = true);
         PricebookEntry vgProPBE = new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = vgPro.Id, UnitPrice = 10000, IsActive = true);
         PricebookEntry vgLicM1PBE = new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = licCM1.Id, UnitPrice = 10000, IsActive = true);
         PricebookEntry vgLicM2PBE = new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = licCM2.Id, UnitPrice = 10000, IsActive = true);
         PricebookEntry vgPltfmPBE = new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = licpltfm.Id, UnitPrice = 10000, IsActive = true);

         PricebookEntry vgAtPBE = new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = licatfm.Id, UnitPrice = 10000, IsActive = true);
        PricebookEntry licReeferPBE = new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = licReefer.Id, UnitPrice = 10000, IsActive = true);
        PricebookEntry licReeferKitPBE = new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = licReeferKit.Id, UnitPrice = 10000, IsActive = true);
        PricebookEntry licTrlrEssPBE = new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = licTrlrEss.Id, UnitPrice = 10000, IsActive = true);
        PricebookEntry licTrlrPremPBE = new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = licTrlrPrem.Id, UnitPrice = 10000, IsActive = true);
        PricebookEntry licTrlrPremKitPBE = new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = licTrlrPremKit.Id, UnitPrice = 10000, IsActive = true);
        PricebookEntry licEiSecPBE = new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = licEiSec.Id, UnitPrice = 10000, IsActive = true);
        /* Edit on OEM Related changes commented  24th, Sep 2024 - Abu - GTMS-22195 */
        PricebookEntry licOEMEquipmentPBE = new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = licOEMEquipment.Id, UnitPrice = 10000, IsActive = true);
        PricebookEntry licOEMFordPBE = new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = licOEMFord.Id, UnitPrice = 10000, IsActive = true);
        PricebookEntry licOEMGmPBE = new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = licOEMGm.Id, UnitPrice = 10000, IsActive = true);
        PricebookEntry licOEMNviPBE = new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = licOEMNvi.Id, UnitPrice = 10000, IsActive = true);
        PricebookEntry licOEMStllaPBE = new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = licOEMStlla.Id, UnitPrice = 10000, IsActive = true);
        // FORMS and Training SKU's
        PricebookEntry licFormsEssPBE = new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = licFormsEss.Id, UnitPrice = 10000, IsActive = true);
        PricebookEntry licFORMSPremPBE = new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = licFORMSPrem.Id, UnitPrice = 10000, IsActive = true);
        PricebookEntry licMEMEntPBE = new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = licMEMEnt.Id, UnitPrice = 10000, IsActive = true);
        PricebookEntry licTrainingPBE = new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = licTraining.Id, UnitPrice = 10000, IsActive = true);
        PricebookEntry licTrainingEssPBE = new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = licTrainingEss.Id, UnitPrice = 10000, IsActive = true);
        PricebookEntry licTrainingPremPBE = new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = licTrainingPrem.Id, UnitPrice = 10000, IsActive = true);
        /* Edit End OEM Related changes commented  24th, Sep 2024 - Abu - GTMS-22195 */
        pricebookEntries.add(vg33PB);
        pricebookEntries.add(vgLdPB);
        pricebookEntries.add(cmBestPBE);
         pricebookEntries.add(cmDBestPBE);
        pricebookEntries.add(vgBestPBE);
        pricebookEntries.add(vgBasicPBE);
        pricebookEntries.add(vgENTPBE);
        pricebookEntries.add(vgProPBE);
        pricebookEntries.add(vgLicM1PBE);  
        pricebookEntries.add(vgLicM2PBE);
        pricebookEntries.add(vgPltfmPBE);
        pricebookEntries.add(vgAtPBE); 
        pricebookEntries.add(licReeferPBE); 
        pricebookEntries.add(licReeferKitPBE); 
        pricebookEntries.add(licTrlrEssPBE); 
        pricebookEntries.add(licTrlrPremPBE); 
        pricebookEntries.add(licTrlrPremKitPBE);
        pricebookEntries.add(licEiSecPBE); 
         /* Edit on OEM Related changes commented  24th, Sep 2024 - Abu - GTMS-22195 */
        pricebookEntries.add(licOEMEquipmentPBE); 
        pricebookEntries.add(licOEMFordPBE); 
        pricebookEntries.add(licOEMGmPBE); 
        pricebookEntries.add(licOEMNviPBE); 
        pricebookEntries.add(licOEMStllaPBE);
        // FORMS and Training SKU's
        pricebookEntries.add(licFormsEssPBE); 
        pricebookEntries.add(licFORMSPremPBE); 
        pricebookEntries.add(licMEMEntPBE); 
        pricebookEntries.add(licTrainingPBE); 
        pricebookEntries.add(licTrainingEssPBE);
        pricebookEntries.add(licTrainingPremPBE); 
         /* Edit End OEM Related changes commented  24th, Sep 2024 - Abu - GTMS-22195 */
        insert pricebookEntries;

    }
     static private PricebookEntry getPricebookEntry(Id pricebookId, String productCode) {
        PricebookEntry entry = [Select Id, UnitPrice, Pricebook2Id, ProductCode from PricebookEntry where ProductCode = :productCode and Pricebook2Id = :pricebookId LIMIT 1];
        return entry;
    } 
    @isTest static void testpositivieusecase2() {
       /* Account acc = new Account ();
        acc = TestFactory.initializeAccount('Active_Growth_Campaigns_Count');
        insert acc;
        Test.StartTest();
        Customer_360__c cs = new Customer_360__c ();
        cs.Account__c = acc.Id;
        Insert cs;
        
        Id pricebookId = Test.getStandardPricebookId();
        addProducts(pricebookId);
        PricebookEntry vg33 = getPricebookEntry(pricebookId, 'LIC-AG4');
        


        Opportunity thisOpp = new Opportunity();
        thisOpp = TestFactory.initializeOpportunity ('Active_Growth_Campaigns_Count');
        thisOpp.Type = 'Revenue Opportunity' ;
        thisOpp.StageName = 'Closed Won';
        thisopp.Went_to_Closed_Lost_Date__c = system.today();
        thisOpp.AccountId = acc.Id;
        
        insert thisOpp;
        
        List<OpportunityLineItem> oLiList = new List<OpportunityLineItem>();
        OpportunityLineItem oli = new OpportunityLineItem(OpportunityId = thisOpp.Id, Quantity = 10,
                PriceBookEntryId = vg33.Id,UnitPrice = vg33.UnitPrice, Account__c = acc.Id);
        oLiList.add(oli);
       
        
        insert oLiList;*/
        

          //OpptyLineitemDiscountBatch op = new OpptyLineitemDiscountBatch ();
          //database.executeBatch(Op,1);
         List<account> newAccount = [Select id from account];
         Contract cont = new Contract(
            AccountId = newAccount[0].Id,
            StartDate = System.today(),
            EndDate   = System.today().addDays(30),
            ContractTerm = 1,
            Status = 'Draft'
        );
        insert cont;
        cont.Status = 'Activated';
        update cont;
         Product2 pltformProLicense = [select id, name from Product2 where Name = 'LIC-PLTFM-PRO' limit 1];
        list<SBQQ__Subscription__c> subList = new List<SBQQ__Subscription__c>();
        SBQQ__Subscription__c sub1 = new SBQQ__Subscription__c(
            SBQQ__Quantity__c = 1,
            SBQQ__RenewalPrice__c = 100,
            SBQQ__CustomerPrice__c = 100,
            SBQQ__Contract__c = cont.id,
            SBQQ__Account__c = newAccount[0].id,
            SBQQ__Product__c = pltformProLicense.id

        );
        SBQQ__Subscription__c sub2 = new SBQQ__Subscription__c(
            SBQQ__Quantity__c = 1,
            SBQQ__RenewalPrice__c = 100,
            SBQQ__CustomerPrice__c = 100,
            SBQQ__Contract__c = cont.id,
            SBQQ__Account__c = newAccount[0].id,
            SBQQ__Product__c = pltformProLicense.id

        );
        subList.add(sub1);
        subList.add(sub2);
        insert subList;
         Test.startTest();
        List<Account> accountList = [SELECT Id FROM Account FOR UPDATE];
         OpptyLineitemDiscountBatchSchedular op = new OpptyLineitemDiscountBatchSchedular ();
         String sch = '0 0 2 * * ?';
         system.schedule('Test status Check', sch, op );
        
         Test.stopTest();
        
       }
    
   @isTest static void testpositivieusecase3() {
       Customer_360__c cs = [select id, Account__c from Customer_360__c limit 1];
         cs.Account__c = null;
         update cs;
         Test.startTest();
         OpptyLineitemDiscountBatchSchedular op = new OpptyLineitemDiscountBatchSchedular ();
         String sch = '0 0 2 * * ?';
         system.schedule('Test status Check', sch, op );
         Test.stopTest();
        
       }
    @isTest static void testpositivieusecase4() {       
         Test.startTest();
         List<Account> accountList = [SELECT Id FROM Account FOR UPDATE];
         OpptyLineitemDiscountBatchSchedular op = new OpptyLineitemDiscountBatchSchedular ();
         String sch = '0 0 2 * * ?';
         system.schedule('Test status Check', sch, op );
         Test.stopTest();
        
       }
    
    @isTest static void testAmendmentScenario() {
        Test.startTest();
        testAccount = [SELECT id, Name, BillingCountry FROM Account WHERE Name='Test Account'];  
        
        Opportunity testOpportunity = new Opportunity();
        testOpportunity = TestFactory.initializeOpportunity ('Active_Growth_Campaigns_Count');
        testOpportunity.Type = 'Revenue Opportunity' ;
        testOpportunity.StageName = 'Closed Won';
        testOpportunity.Went_to_Closed_Lost_Date__c = system.today()-1;
        testOpportunity.AccountId = testAccount.Id;
        TriggerHandler.bypass('OpportunityTriggerHandler');
          TriggerHandler.bypass('GS_OpportunityTriggerHandler');
        TriggerHandler.bypass('OpportunityTriggerHandlerContext');
        TriggerHandler.bypass('GS_SBQQQuoteTriggerHandler');
        insert testOpportunity;
        
        Contract testContract = [SELECT Id FROM Contract LIMIT 1];
        testOpportunity.Owner_Role_Copy__c = 'AE3';
        testOpportunity.SBQQ__AmendedContract__c = testContract.id;
        update testOpportunity;
       
        Product2 vgProduct = [SELECT id FROM Product2 WHERE ProductCode = 'LIC-VG-LD'];
        PricebookEntry pricebookEntry = [SELECT id, Product2Id, UnitPrice FROM PricebookEntry WHERE Product2Id =: vgProduct.Id]; 
        Shipping_Address__c shippingAddress = [SELECT id FROM Shipping_Address__c Where Name='Ship To One'];
        Shipping_Address__c shippingAddressTwo = [SELECT id FROM Shipping_Address__c Where Name='Ship To Four'];
        
        Customer_360__c c360 = new Customer_360__c(LIC_AG2_Discount__c=1,LIC_AG4_Discount__c=1,LIC_CM1_Discount__c=1,LIC_CM2_Discount__c=1,
                                                   LIC_CRGO_Discount__c=1,LIC_DM11_Discount__c=1,LIC_VG_Discount__c=1,LIC_AG4P_Discount__c=1,
                                                   LIC_EM_Discount__c=1,Account__c=testAccount.Id);
        insert c360;
        
        SBQQ__Quote__c quote = new SBQQ__Quote__c(Quote_Name__c = 'Test Version', SBQQ__Opportunity2__c =testOpportunity.Id, 
                                                  SBQQ__Primary__c = false, Shipping_Address_NEW__c = shippingAddress.Id, SBQQ__Type__c='Amendment');
        insert quote;
        
        quote.SBQQ__Primary__c = false;
        update quote; 
        
        List<SBQQ__QuoteLine__c> newlineItems = new List<SBQQ__QuoteLine__c>();
        SBQQ__QuoteLine__c quoteLineOne =  new SBQQ__QuoteLine__c(SBQQ__Quote__c = quote.Id, SBQQ__PricebookEntryId__c = pricebookEntry.Id, SBQQ__Quantity__c  = 5, 
                                                                  SBQQ__Discount__c = 0, SBQQ__Product__c = vgProduct.Id, accountLookupTest__c = testAccount.Id);
        newlineItems.add(quoteLineOne); 
        
        SBQQ__QuoteLine__c quoteLineTwo =  new SBQQ__QuoteLine__c(SBQQ__Quote__c = quote.Id, SBQQ__PricebookEntryId__c = pricebookEntry.Id, SBQQ__Quantity__c  = 5, 
                                                                  SBQQ__Discount__c = 0, SBQQ__Product__c = vgProduct.Id, accountLookupTest__c = testAccount.Id, Ship_To__c = shippingAddressTwo.Id);
        newlineItems.add(quoteLineTwo);
        
        SBQQ__QuoteLine__c quoteLineThree =  new SBQQ__QuoteLine__c(SBQQ__Quote__c = quote.Id, SBQQ__PricebookEntryId__c = pricebookEntry.Id, SBQQ__Quantity__c  = 5, 
                                                                    SBQQ__Discount__c = 10, SBQQ__Product__c = vgProduct.Id, accountLookupTest__c = testAccount.Id, Ship_To__c = shippingAddressTwo.Id);
        newlineItems.add(quoteLineThree);
        
        insert newlineItems;
        
        TriggerHandler.clearbypass('OpportunityTriggerHandler');
          TriggerHandler.clearbypass('GS_OpportunityTriggerHandler');
        TriggerHandler.clearbypass('OpportunityTriggerHandlerContext');
        TriggerHandler.clearbypass('GS_SBQQQuoteTriggerHandler');
        List<Account> accountList = [SELECT Id FROM Account FOR UPDATE];
         OpptyLineitemDiscountBatchSchedular op = new OpptyLineitemDiscountBatchSchedular ();
         String sch = '0 0 2 * * ?';
         system.schedule('Test status Check', sch, op );
        
         Test.stopTest();
    }

    @isTest static void c360CreatorTest(){
      Test.startTest();
       Account acc = [SELECT Id, ownerId FROM Account LIMIT 1];

       Opportunity testOpportunity = [SELECT Id From Opportunity where AccountId = :acc.Id];
        
       SBQQ__Quote__c quote = new SBQQ__Quote__c(Quote_Name__c = 'Test Version', SBQQ__Opportunity2__c =testOpportunity.Id, 
                                                  SBQQ__Primary__c = false);
       SBQQ.TriggerControl.disable();
       TriggerHandler.bypass('GS_SBQQQuoteTriggerHandler');
         TriggerHandler.bypass('OpportunityTriggerHandler');
          TriggerHandler.bypass('GS_OpportunityTriggerHandler');
        TriggerHandler.bypass('OpportunityTriggerHandlerContext');
       insert quote;
       
       testOpportunity.SBQQ__PrimaryQuote__c = quote.Id;
        
       update testOpportunity;
       SBQQ.TriggerControl.enable();
       TriggerHandler.clearAllBypasses();
       

       insert new Automation_Settings__c(Name = 'C360 Director Ids', Data__c = (String) acc.ownerId, disabled__c = true);

      
       Database.executeBatch(new C360CreatorBatch());
       Test.stopTest();

       list<Log__c> logRec = new List<Log__c>([SELECT Id, ExceptionMessage__c, StackTrace__c, Exception_Type__c FROM Log__c ORDER BY Createddate desc LIMIT 1]);

       if(logRec.size() > 0){

              System.debug('Exception MSG-->'+logRec[0]?.ExceptionMessage__c);
              System.debug('StackTrace__c-->'+logRec[0]?.StackTrace__c);
              System.debug('Exception_Type__c-->'+logRec[0]?.Exception_Type__c);
       }
    }
    
    @isTest static void getLogTest()
    {
        test.startTest();
        new OpptyLineitemDiscountBatch().getLog('test','test','test','test','test','test');
        test.stopTest();
    }

    /*@isTest static void testNonAmendmentScenario() {
        Test.startTest();
        
        // Get the opportunity and line items from setup
        Opportunity opp = [SELECT Id, StageName, AccountId FROM Opportunity WHERE StageName = 'Closed Won' LIMIT 1];
        List<OpportunityLineItem> oliList = [SELECT Id, OpportunityId, ProductCode, Quantity, UnitPrice, Account__c 
                                             FROM OpportunityLineItem 
                                             WHERE OpportunityId = :opp.Id];
        
        // Update line items with quote line details for non-amendment scenario
        for(OpportunityLineItem oli : oliList) {
            oli.SBQQ__QuoteLine__r = new SBQQ__QuoteLine__c(SBQQ__Discount__c = 15);
        }
        update oliList;
        
        // Run the batch
        OpptyLineitemDiscountBatchSchedular o = new OpptyLineitemDiscountBatchSchedular();
        String sch = '0 0 2 * * ?';
        system.schedule('Test Non-Amendment Check', sch, o);
        
        Test.stopTest();
        
        // Verify results
        Customer_360__c cust360 = [SELECT Id, LIC_AG4_Discount__c, LIC_AG4_ENT_MUP__c 
                                   FROM Customer_360__c 
                                   WHERE Account__c = :opp.AccountId 
                                   LIMIT 1];
        System.assertNotEquals(null, cust360, 'Customer 360 record should be created');
        System.assertEquals(15, cust360.LIC_AG4_Discount__c, 'Discount should be set from quote line');
        System.assertEquals(150, cust360.LIC_AG4_ENT_MUP__c, 'MUP should be set from line item');
    }*/
    
/*@isTest
  public static void testStep2() {
    OpptyLineitemDiscountBatch.testCoverage();
  }*/
    }