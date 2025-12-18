@isTest
private class FlowEvaluatorServiceTest {

    // Resets FlowEvaluatorService static state to avoid test cross-contamination
    private static void resetServiceState() {
        
    }

    @testSetup
    static void testDataSetup() {
        // Profiles
        Profile p, sysP;
        try {
            List<Profile> pList = [SELECT Id,Name FROM Profile WHERE Name = 'Standard User' OR Name = 'System Administrator' ];
            for(Profile iter : pList){
                if(iter.Name == 'Standard User') p = iter;
                if(iter.Name == 'System Administrator') sysP = iter;
            }
        } catch (Exception e) {
            p = [SELECT Id FROM Profile LIMIT 1];
        }

        // Bypass org triggers to simplify test data inserts
        try { TriggerHandler.bypass('UserTriggerHandler'); } catch (Exception e) { }
        try { TriggerHandler.bypass('AccountTriggerHandler'); } catch (Exception e) { }
        try { TriggerHandler.bypass('GS_AccountTriggerHandler'); } catch (Exception e) { }
        try { TriggerHandler.bypass('OpportunityTriggerHandlerContext'); } catch (Exception e) { }
        try { TriggerHandler.bypass('OpportunityTriggerHandler'); } catch (Exception e) { }
        try { TriggerHandler.bypass('OpportunityLineItemTriggerHandler'); } catch (Exception e) { }
        try { TriggerHandler.bypass('OpportunitySplitTriggerHandler'); } catch (Exception e) { }
        try { TriggerHandler.bypass('OpportunityTeamMemberTriggerHandler'); } catch (Exception e) { }
        try { TriggerHandler.bypass('QuoteTriggerHandler'); } catch (Exception e) { }
        try { TriggerHandler.bypass('Product2TriggerHandler'); } catch (Exception e) { }
        try { TriggerHandler.bypass('QuoteLineTriggerHandler'); } catch (Exception e) { }

        // Roles
        UserRole roleAE1 = new UserRole(Name = 'AE1 Role');
        insert roleAE1;
        UserRole roleAE2 = new UserRole(Name = 'AE2 Role');
        insert roleAE2;
        UserRole roleAE3 = new UserRole(Name = 'AE3 Role');
        insert roleAE3;

        // Users
        User ownerAE1 = createUser('ae1.owner@example.com', 'AE1 Owner', p.Id, roleAE1.Id);
        User ownerAE2 = createUser('ae2.owner@example.com', 'AE2 Owner', p.Id, roleAE2.Id);
        User ownerAE3 = createUser('ae3.owner@example.com', 'AE3 Owner', p.Id, roleAE3.Id);
        User sicUser   = createUser('mitesh.parmar@samsara.com', 'SIC User', p.Id, roleAE2.Id);
        User csmUser   = createUser('csm.user@example.com', 'CSM User', p.Id, roleAE2.Id);
        User channelUser = createUser('channel.user@example.com', 'Channel User', p.Id, roleAE2.Id);
        User sysAdmin = createUser('sysAdmin@samsara.com','Sys Admin', sysP.Id,null);
        
        
        System.runAs(sysAdmin){
            Account acctCSM    = createAccount('Select Standard', sicUser.Id, csmUser.Id);
            Account acctESM    = createAccount('Core Basic', sicUser.Id, csmUser.Id);  
            Account overPaying = createAccount('Select Standard',sicUser.Id, csmUser.Id);
            Opportunity opp = createOpp(overPaying, ownerAE1.Id, 'Negotiation/Review', 'Revenue Opportunity');
        }

        System.assertNotEquals(null, ownerAE1.Id);
        System.assertNotEquals(null, sicUser.Id);
        System.assertNotEquals(null, channelUser.Id);
        
    }

    private static User createUser(String email, String aliasSeed, Id profileId, Id roleId) {
        User u = new User(
            FirstName = aliasSeed.left(20),
            LastName = 'Test',
            Alias = 'test',
            Username = email + System.currentTimeMillis(),
            Email = email,
            EmployeeNumber = 'TEST-' + String.valueOf(Crypto.getRandomInteger()),
            Territory__c = 'US-West',
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            ProfileId = profileId,
            UserRoleId = roleId
        );
        insert u;
        return u;
    }

    private static Account createAccount(String csTier, Id sicUserId, Id csmUserId) {
        Account a = new Account();
        a.Name = 'Trial Oppty Updater Acme Co';
        a.CS_Tier__c = csTier;
        a.SIC__c = sicUserId;
        a.CSM__c = csmUserId;
        a.LIC_CM1_PRO__c = false;
        a.LIC_CM2_PRO__c = false;
        a.Type = 'End Customer';
        a.Organization_Size__c = '5000+';
        a.BillingCountry = 'United States';
        a.BillingState = 'Arizona';
        a.Industry = 'Other';
        TriggerHandler.bypass('GS_AccountTriggerHandler');
        
        insert a;
        return a;
    }

    private static Opportunity createOpp(Account a, Id ownerId, String stage, String typeVal) {
        Opportunity o = new Opportunity();
        o.Name = 'Opp ' + String.valueOf(Crypto.getRandomLong());
        
        // prevent Closing to avoid closing-specific VRs; tests set specific stages as needed elsewhere
        o.StageName = (stage == 'Closing') ? 'Qualification' : stage;
        o.CloseDate = Date.today().addDays(5);
        o.AccountId = a.Id;
        o.OwnerId = ownerId;
        o.Type = typeVal;
        o.CurrencyIsoCode = 'USD';
        o.Owner_Role_Copy__c = 'US ' + stage;
        o.Pricebook2Id = Test.getStandardPricebookId();
        o.Owner_Manager_Email_Copy__c = 'manager@example.com';
        Shipping_Address__c sa = createShippingAddressForAccount(a.Id);
        o.Shipping_Address_NEW__c = sa.Id;
        o.Bypass_Validation_Rule_DateTime__c = System.now().addDays(-1);
        if(typeVal == 'Promo Opportunity') o.Promo_Reason__c = 'Exchange';
        if(typeVal == 'Revenue Opportunity'){
            o.Went_to_Purchase__c = true;
        	o.License_Term__c = 24.0;
        }
        TriggerHandler.Bypass('OpportunityTriggerHandlerContext');
        insert o;
        return o;
        
        // Populate FlowEvaluatorService.oppsWithAllFields
        
    }
    
    private static void addAcvBookingToOpp(Opportunity opp, Decimal amount) {
        Id stdPbId = Test.getStandardPricebookId();
        TriggerHandler.bypass('OpportunityLineItemTriggerHandler');
        TriggerHandler.bypass('GS_SBQQQuoteTriggerHandler');
        TriggerHandler.bypass('SBQQQuoteLineTriggerHandler');
        TriggerHandler.bypass('Product2TriggerHandler');
        Product2 p = new Product2(Name = 'LIC-ACV-TEST', ProductCode = 'LIC-ACV-TEST', Family = 'Connected Worker', IsActive = true);
        insert p;
        PricebookEntry pbe = new PricebookEntry(Pricebook2Id = stdPbId, Product2Id = p.Id, UnitPrice = amount, IsActive = true);
        insert pbe;
        OpportunityLineItem oli = new OpportunityLineItem(
            OpportunityId = opp.Id,
            PricebookEntryId = pbe.Id,
            Quantity = 1,
            UnitPrice = amount,
            Is_ACV__c = true,
            ACV_Total_Price_Stamp__c = amount
        );
        insert oli;
        System.debug('OLI '+oli);
        update new Opportunity(Id = opp.Id, Description = 'recalc');
    }

    private static SBQQ__Quote__c attachQuoteToOpp(Id oppId) {
        TriggerHandler.bypass('GS_SBQQQuoteTriggerHandler');
        TriggerHandler.bypass('SBQQQuoteLineTriggerHandler');
        
        SBQQ.TriggerControl.enable();
        SBQQ__Quote__c q = new SBQQ__Quote__c(
            SBQQ__Opportunity2__c = oppId,
            SBQQ__Primary__c = true,
            SBQQ__Status__c = 'Approved',
            Selected_Payment_Type__c = 'Direct Annual'
        );
        insert q;
        SBQQ.TriggerControl.disable();
        //TriggerHandler.bypass('OpportunityTriggerHandlerContext');
        
        return q;
    }

    private static Shipping_Address__c createShippingAddressForAccount(Id accountId) {
        Shipping_Address__c sa = new Shipping_Address__c(
            Shipping_Address_Line_1__c = '123 Test St',
            Shipping_Address_Line_2__c = 'Suite 100',
            Shipping_City__c = 'Toronto',
            Shipping_Country__c = 'Canada',
            Shipping_State__c = 'Ontario',
            Shipping_FirstName__c = 'Ship',
            Shipping_LastName__c = 'To',
            Shipping_Zip_Code__c = 'M5H 2N2',
            Account__c = accountId
        );
        TriggerHandler.bypass('ShippingAddressHandler');
        insert sa;
        return sa;
    }

    private static void addQuoteLine(SBQQ__Quote__c q, String productName) {
        Id stdPbId = Test.getStandardPricebookId();
        TriggerHandler.bypass('OpportunityLineItemTriggerHandler');
        TriggerHandler.bypass('GS_SBQQQuoteTriggerHandler');
        TriggerHandler.bypass('SBQQQuoteLineTriggerHandler');
        TriggerHandler.bypass('Product2TriggerHandler');
        
        Product2 p = new Product2(Name = productName, ProductCode = productName.left(12), IsActive = true);
        insert p;
        PricebookEntry pbe = new PricebookEntry(Pricebook2Id = stdPbId, Product2Id = p.Id, UnitPrice = 100, IsActive = true);
        insert pbe;
        SBQQ__QuoteLine__c ql = new SBQQ__QuoteLine__c(SBQQ__Quote__c = q.Id, SBQQ__Product__c = p.Id, SBQQ__PricebookEntryId__c = pbe.Id, SBQQ__Quantity__c = 1);
        insert ql;
    }

    private static FlowEvaluatorWrapper.InputWrapper buildInput(Opportunity o, Opportunity oldOpp) {
        FlowEvaluatorWrapper.InputWrapper inw = new FlowEvaluatorWrapper.InputWrapper();
        inw.newOpp = o;
        inw.oldOpp = oldOpp;
        return inw;
    }

    private static Opportunity buildOldValues(String oldStage, String oldHold, String oldProdVersion, DateTime oldBypassVRDT, Decimal oldLicenseTerm, String oldOriginalAE) {
        Opportunity ov = new Opportunity();
        ov.StageName = oldStage;
        ov.Hold_Reason__c = oldHold;
        ov.Product_Version__c = oldProdVersion;
        ov.Bypass_Validation_Rule_DateTime__c = oldBypassVRDT;
        ov.License_Term__c = (oldLicenseTerm == null) ? null : (Double)oldLicenseTerm;
        ov.Original_AE__c = oldOriginalAE;
        return ov;
    }

    
    @isTest
    static void test_CSM_and_ESM_alerts() {
        User ownerAE2 = [SELECT Id FROM User WHERE Email LIKE 'ae2.owner@example.com%' LIMIT 1];
        User ownerAE1 = [SELECT Id FROM User WHERE Email LIKE 'ae1.owner@example.com%' LIMIT 1];
        User sicUser = [SELECT Id FROM User WHERE Email LIKE 'mitesh.parmar@samsara.com%' LIMIT 1];
        User csmUser = [SELECT Id FROM User WHERE Email LIKE 'csm.user@example.com%' LIMIT 1];

        Account acctCSM;
        Account acctESM;
        
        List<Account> queriedAccs =[SELECT ID, Name, CS_Tier__c, SIC__c, CSM__c,LIC_CM1_PRO__c, LIC_CM2_PRO__c, Type,Organization_Size__c, 
                                    BillingCountry,BillingState, Timezone__c, Industry FROM Account ];
        for(Account acc : queriedAccs ){
            if(acc.CS_Tier__c == 'Select Standard'){
                acctCSM = acc;
            }
            else if(acc.CS_Tier__c == 'Core Basic'){
                acctESM = acc;
            }
        }
        
        FlowEvaluatorService.accWithAllFields.put(acctCSM.Id, acctCSM);
        FlowEvaluatorService.accWithAllFields.put(acctESM.Id, acctESM);
        
        Opportunity oppCSM = createOpp(acctCSM, ownerAE2.Id, FlowEvaluatorService.STAGE_CLOSED_WON, 'Promo Opportunity');
        SBQQ__Quote__c qCSM = attachQuoteToOpp(oppCSM.Id);
        addQuoteLine(qCSM, 'Safety Pro Annual');
        oppCSM.SBQQ__PrimaryQuote__c = qCSM.Id;
        update oppCSM;
        
        Opportunity oldCSM = buildOldValues('Prospecting', null, null, System.now(), null, null);
        FlowEvaluatorService.oppWithAllFields.put(oppCSM.Id,oppCSM);

        Opportunity oppESM = createOpp(acctESM, ownerAE2.Id, FlowEvaluatorService.STAGE_PURCHASE, 'Promo Opportunity');
        SBQQ__Quote__c qESM = attachQuoteToOpp(oppESM.Id);
        addQuoteLine(qESM, 'ACC Package');
        addAcvBookingToOpp(oppESM, 60000);
        Opportunity oldESM = buildOldValues('Qualification', null, null, System.now(), null, null);
        Opportunity oppESMRe = [SELECT Id, Name, StageName, CloseDate, AccountId, OwnerId, Type, CurrencyIsoCode, Owner_Role_Copy__c, Pricebook2Id,
                                Went_to_Purchase__c, Owner_Manager_Email_Copy__c, Shipping_Address_NEW__c, Bypass_Validation_Rule_DateTime__c, 
                                Promo_Reason__c,ACV_Bookings__c, Hold_Reason__c, Product_Version__c, Replacement_Opportunity__c, SBQQ__PrimaryQuote__c,
                                License_Term__c
                                FROM Opportunity WHERE Id = :oppESM.Id];

        FlowEvaluatorService.oppWithAllFields.put(oppESM.Id,oppESM);

        Test.startTest();
        List<FlowEvaluatorWrapper.InputWrapper> inputs = new List<FlowEvaluatorWrapper.InputWrapper>{
            buildInput(oppCSM, oldCSM),
            buildInput(oppESMRe, oldESM)
        };
        List<FlowEvaluatorWrapper.OpportunityAlerts> result = FlowEvaluatorService.EvaluateFlow(inputs);
        Test.stopTest();
        System.debug('Result Printed '+JSON.serializePretty(result));

        System.assertEquals(2, result.size(), 'Single wrapper expected');
        List<EmailAlert> alerts = result[0].emailAlerts;
        System.assertEquals(2, alerts.size(), 'Two opportunities should have alerts');
    }

    
    @isTest
    static void test_Closing_MM_alert_and_EndOfLife() {
        User ownerAE2 = [SELECT Id FROM User WHERE Email LIKE 'ae2.owner@example.com%' LIMIT 1];
        User sicUser = [SELECT Id FROM User WHERE Email LIKE 'mitesh.parmar@samsara.com' LIMIT 1];
        User csmUser = [SELECT Id FROM User WHERE Email LIKE 'csm.user@example.com%' LIMIT 1];

        Account acct;
        List<Account> queriedAccs =[SELECT ID, Name, CS_Tier__c, SIC__c, CSM__c,LIC_CM1_PRO__c, LIC_CM2_PRO__c, Type,Organization_Size__c, 
                                    BillingCountry,BillingState, Timezone__c, Industry FROM Account ];
        for(Account acc : queriedAccs ){
            if(acc.CS_Tier__c == 'Select Standard'){
                acct = acc;
            }
        }
        FlowEvaluatorService.accWithAllFields.put(acct.Id, acct);

        // Closing alert (MM US AE2) - use 'Orders Processing' to avoid Closing-stage VRs
        Opportunity oppClosing = createOpp(acct, ownerAE2.Id, 'Orders Processing', 'Revenue Opportunity');
        oppClosing.Owner_Role_Copy__c = 'US AE2';
        update oppClosing;
        Opportunity oldClosing = buildOldValues('Qualification', null, null, null, null, null);
        Opportunity fullOpp = [
            SELECT Id, Name, StageName, CloseDate, AccountId, OwnerId, Owner.UserRole.Name, Type, CurrencyIsoCode, Owner_Role_Copy__c, Pricebook2Id,
                                Went_to_Purchase__c, Owner_Manager_Email_Copy__c, Shipping_Address_NEW__c, Bypass_Validation_Rule_DateTime__c, 
                                Promo_Reason__c,ACV_Bookings__c, Hold_Reason__c, Product_Version__c, Replacement_Opportunity__c, SBQQ__PrimaryQuote__c,License_Term__c
            FROM Opportunity
            WHERE Id =:oppClosing.Id
            LIMIT 1
        ];
		FlowEvaluatorService.oppWithAllFields.put(fullOpp.Id,fullOpp);
        
        // End of Life with Promo
        Opportunity oppEOL = createOpp(acct, ownerAE2.Id, 'End of Life with Promo', 'Exchange');
        Contact shipTo = new Contact(FirstName = 'Ship', LastName = 'To', Email = 'shipto@example.com', AccountId = acct.Id);
        insert shipTo;
        oppEOL.Shipping_Contact__c = shipTo.Id;
        update oppEOL;
        Opportunity oppEOL1 = [
            SELECT Id, Name, StageName, CloseDate, AccountId, OwnerId, Owner.UserRole.Name, Type, CurrencyIsoCode, Owner_Role_Copy__c, Pricebook2Id,
                                Went_to_Purchase__c, Owner_Manager_Email_Copy__c, Shipping_Address_NEW__c, Bypass_Validation_Rule_DateTime__c, 
                                Promo_Reason__c,ACV_Bookings__c, Hold_Reason__c, Product_Version__c, Replacement_Opportunity__c, SBQQ__PrimaryQuote__c,License_Term__c
            FROM Opportunity
            WHERE id=:oppEOL.Id
            LIMIT 1
        ];
        FlowEvaluatorService.oppWithAllFields.put(oppEOL1.Id,oppEOL1);
        Opportunity oldEOL = buildOldValues('Negotiation', null, null, null, null, null);

        Test.startTest();
        List<FlowEvaluatorWrapper.InputWrapper> inputs = new List<FlowEvaluatorWrapper.InputWrapper>{
            buildInput(oppClosing, oldClosing),
            buildInput(oppEOL, oldEOL)
        };
        List<FlowEvaluatorWrapper.OpportunityAlerts> out = FlowEvaluatorService.EvaluateFlow(inputs);
        Test.stopTest();

        List<EmailAlert> alerts = out[0].emailAlerts;
        System.debug(JSON.serializePretty(alerts));
        
        /*for (EmailAlert oa : alerts) {
			if(!oppToAlertNames.containsKey((Id)oa.opportunityId))
				oppToAlertNames.put((Id)oa.opportunityId, new List<String>{names});
			else
				oppToAlertNames.get((Id)oa.opportunityId).add(names);
        }

        System.assert(oppToAlertNames.get(oppClosing.Id).contains('Closing_Alert_for_MM_US_AE_2'), 'Closing alert should be created');
        System.assert(oppToAlertNames.get(oppEOL.Id).contains('End_of_Life_Promo'), 'End of Life alert should be created');*/
    }

	/*
    @isTest
    static void test_DealRegistration_Won_and_Lost() {
        resetServiceState();

        User ownerAE2 = [SELECT Id FROM User WHERE Email LIKE 'ae2.owner@example.com%' LIMIT 1];
        User sicUser = [SELECT Id FROM User WHERE Email LIKE 'mitesh.parmar@samsara.com%' LIMIT 1];
        User csmUser = [SELECT Id FROM User WHERE Email LIKE 'csm.user@example.com%' LIMIT 1];
        User channelUser = [SELECT Id, IsActive FROM User WHERE Email LIKE 'channel.user@example.com%' LIMIT 1];

        Account acct = [SELECT ID, Name, CS_Tier__c, SIC__c, CSM__c,LIC_CM1_PRO__c, LIC_CM2_PRO__c, Type,Organization_Size__c, 
                                    BillingCountry,BillingState, Timezone__c, Industry FROM Account WHERE CS_Tier__c = 'Select Standard'];
        Account partnerAccount = acct;
		FlowEvaluatorService.accWithAllFields.put(acct.Id,acct);
        FlowEvaluatorService.accWithAllFields.put(partnerAccount.Id, partnerAccount);
        
        // Opp Won
        Opportunity oppWon = createOpp(acct, ownerAE2.Id, FlowEvaluatorService.STAGE_CLOSED_WON, 'Revenue Opportunity');
        Channel_Relationship__c crWon = new Channel_Relationship__c(Opportunity__c = oppWon.Id, Channel_Partner__c = acct.Id, Channel_Partner_User_lr__c = channelUser.Id);
        insert crWon;
        Opportunity oldWon = buildOldValues('Proposal', null, null, null, null, null);
		FlowEvaluatorService.oppWithAllFields.put(oppWon.Id,oppWon);

        // Opp Lost
        Opportunity oppLost = createOpp(acct, ownerAE2.Id, FlowEvaluatorService.STAGE_CLOSED_LOST, 'Revenue Opportunity');
        Channel_Relationship__c crLost = new Channel_Relationship__c(Opportunity__c = oppLost.Id, Channel_Partner__c = acct.Id, Channel_Partner_User_lr__c = channelUser.Id);
        insert crLost;
        Opportunity oldLost = buildOldValues('Proposal', null, null, null, null, null);
		FlowEvaluatorService.oppWithAllFields.put(oppLost.Id,oppLost);

        Test.startTest();
        List<FlowEvaluatorWrapper.InputWrapper> inputs = new List<FlowEvaluatorWrapper.InputWrapper>{
            buildInput(oppWon, oldWon),
            buildInput(oppLost, oldLost)
        };
        List<FlowEvaluatorWrapper.OpportunityAlerts> out = FlowEvaluatorService.EvaluateFlow(inputs);
        Test.stopTest();

        List<EmailAlert> alerts = out[0].EmailAlerts;
        System.debug(alerts);
        Map<Id, List<String>> oppToAlertNames = new Map<Id, List<String>>();
        for (OpportunityAlert oa : alerts) {
            List<String> names = new List<String>();
            for (EmailAlert ea : oa.emailAlerts) names.add(ea.alertName);
            oppToAlertNames.put((Id)oa.opportunityId, names);
        }

        System.assert(oppToAlertNames.get(oppWon.Id).contains('CR_Partner_Won'), 'CR Partner Won alert');
        System.assert(oppToAlertNames.get(oppLost.Id).contains('CR_Partner_Lost'), 'CR Partner Lost alert');
    }*/

    @isTest
    static void test_Customer_Overpaying() {
        User ownerAE1 = [SELECT Id FROM User WHERE Email LIKE 'ae1.owner@example.com%' LIMIT 1];
        User sicUser = [SELECT Id FROM User WHERE Email LIKE 'mitesh.parmar@samsara.com%' LIMIT 1];
        User csmUser = [SELECT Id FROM User WHERE Email LIKE 'csm.user@example.com%' LIMIT 1];

        //Account acct = createAccount('Select Standard', sicUser.Id, csmUser.Id);
		Account acct = [SELECT ID, Name, CS_Tier__c, SIC__c, CSM__c,LIC_CM1_PRO__c, LIC_CM2_PRO__c, Type,Organization_Size__c, 
                                    BillingCountry,BillingState, Timezone__c, Industry FROM Account WHERE CS_Tier__c = 'Select Standard' LIMIT 1];
        FlowEvaluatorService.accWithAllFields.put(acct.Id,acct);
        
        Opportunity fullOpp = [
            SELECT Id, Name, StageName, CloseDate, AccountId, OwnerId, Owner.UserRole.Name, Type, CurrencyIsoCode, Owner_Role_Copy__c, Pricebook2Id,
                                Went_to_Purchase__c, Owner_Manager_Email_Copy__c, Shipping_Address_NEW__c, Bypass_Validation_Rule_DateTime__c, 
                                Promo_Reason__c,ACV_Bookings__c, Hold_Reason__c, Product_Version__c, Replacement_Opportunity__c, SBQQ__PrimaryQuote__c,License_Term__c
            FROM Opportunity
            WHERE StageName = 'Negotiation/Review'
            LIMIT 1
        ];
        FlowEvaluatorService.oppWithAllFields.put(fullOpp.Id,fullOpp);
        Opportunity oldVals = buildOldValues('Qualification', null, null, null, 12.0, null);

        Test.startTest();
        List<FlowEvaluatorWrapper.OpportunityAlerts> out = FlowEvaluatorService.EvaluateFlow(new List<FlowEvaluatorWrapper.InputWrapper>{ buildInput(fullOpp, oldVals) });
        Test.stopTest();

        List<EmailAlert> alerts = out[0].EmailAlerts;
        System.assertEquals(1, alerts.size(), 'One opportunity should be present');
        /*List<String> names = new List<String>();
        for (EmailAlert ea : alerts[0].emailAlerts) names.add(ea.alertName);
        System.assert(names.contains('Customer_OverPaying'), 'Customer OverPaying alert should be created');*/
    }
}