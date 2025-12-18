@IsTest(isParallel=false)
private class ItemsToApproveQuoteServiceTest {

  @TestSetup
  static void setupData() {
    Profile testProfile = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1];

    User testUser = new User(
      Alias = 'test',
      Email = 'testUser1@test.com',
      EmailEncodingKey = 'UTF-8',
      LastName = 'TestLastName',
      LanguageLocaleKey = 'en_US',
      LocaleSidKey = 'en_US',
      ProfileId = testProfile.Id,
      TimeZoneSidKey = 'America/Los_Angeles',
      UserName = 'userEmail4306@test.com',
      EmployeeNumber = '12345'
    );
    insert testUser;

    Group testGroup = new Group(Name = 'testGroup');
    insert testGroup;

    GroupMember testMember = new GroupMember(
      GroupId = testGroup.Id,
      UserOrGroupId = testUser.Id
    );
    insert testMember;

  }

  // Reuse data from ItemsToApproveQuoteControllerTest @TestSetup
  private static User getSetupUser() {
    return [SELECT Id, UserName FROM User WHERE UserName = 'userEmail4306@test.com' LIMIT 1];
  }

  private static Group getSetupGroup() {
    return [SELECT Id, Name FROM Group WHERE Name = 'testGroup' LIMIT 1];
  }

  // Ensure an Approval Rule exists targeting SBQQ__Quote__c (mirrors controller test)
  private static Id getOrCreateApprovalRuleId() {
    List<SBAA__ApprovalRule__c> rules = [
      SELECT Id FROM SBAA__ApprovalRule__c WHERE SBAA__TargetObject__c = 'SBQQ__Quote__c' LIMIT 1
    ];
    if (!rules.isEmpty()) {
      return rules[0].Id;
    }
    SBAA__ApprovalRule__c rule = new SBAA__ApprovalRule__c(
      Name = 'Test Service Approval Rule',
      SBAA__TargetObject__c = 'SBQQ__Quote__c'
    );
    insert rule;
    return rule.Id;
  }

  // Creates a new Account, Opportunity, and SBQQ__Quote__c; returns all
  private static Map<String, SObject> createCoreData(String nameSeed) {
    Map<String, SObject> outMap = new Map<String, SObject>();

    Account acc = new Account(
      Name = 'Acct ' + nameSeed,
      BillingStateCode = 'MT',
      BillingCountryCode = 'US',
      Organization_Size__c = '1 - 99'
    );
    insert acc;
    outMap.put('Account', acc);

    Opportunity opp = new Opportunity(
      Name = 'Opp ' + nameSeed,
      StageName = 'Prospecting',
      CloseDate = System.today().addDays(30),
      AccountId = acc.Id
    );
    insert opp;
    outMap.put('Opportunity', opp);

    SBQQ__Quote__c quote = new SBQQ__Quote__c(
      SBQQ__Account__c = acc.Id,
      SBQQ__Opportunity2__c = opp.Id,
      SBQQ__StartDate__c = Date.today(),
      SBQQ__EndDate__c = Date.today().addYears(1)
    );
    insert quote;
    outMap.put('Quote', quote);

    return outMap;
  }

  // Group is provided by setup; helper retained for symmetry if needed later
  private static Group getExistingGroup() { return getSetupGroup(); }

  // Inserts one or more SBAA__Approval__c rows with provided parameters
  private static List<SObject> createApprovalsForQuote(Id quoteId,
                                                       String status,
                                                       String assignedToStr,
                                                       String assignedGroupStr,
                                                       Integer howMany,
                                                       String nameSeed) {
    List<SObject> rows = new List<SObject>();
    Id ruleId = getOrCreateApprovalRuleId();
    for (Integer i = 0; i < howMany; i++) {
      Schema.SObjectType apprType = Schema.getGlobalDescribe().get('SBAA__Approval__c');
      SObject ap = apprType != null ? apprType.newSObject(null, true) : null;
      if (ap == null) {
        System.assert(false, 'Expected object SBAA__Approval__c to exist in this org.');
      }
      ap.put('Quote__c', quoteId);
      ap.put('SBAA__Status__c', status);
      ap.put('SBAA__RecordField__c', 'Quote__c');
      ap.put('SBAA__ApprovalStep__c', 10);
      ap.put('SBAA__Rule__c', ruleId);
      if (assignedToStr != null) ap.put('SBAA__AssignedTo__c', assignedToStr);
      if (assignedGroupStr != null) ap.put('SBAA__AssignedGroupId__c', assignedGroupStr);
      insert ap;
      rows.add(ap);
    }
    return rows;
  }

  @IsTest
  static void testFetchApprovals_BasicAndDedupe() {
    User runAsUser = getSetupUser();
    System.runAs(runAsUser) {
      Map<String, SObject> data = createCoreData('A');
      Id quoteId = (Id)data.get('Quote').get('Id');

      // Two pending approvals for same quote to exercise dedupe by most recent CreatedDate
      List<SObject> approvals = createApprovalsForQuote(
        quoteId,
        'Requested',
        String.valueOf(UserInfo.getUserId()),
        null,
        2,
        'A'
      );

      // Make the second one newest
      Test.setCreatedDate((Id)approvals[0].get('Id'), System.now().addDays(-1));
      Test.setCreatedDate((Id)approvals[1].get('Id'), System.now());

      // Also add an Approved record for latest approver name
      Schema.SObjectType apprType2 = Schema.getGlobalDescribe().get('SBAA__Approval__c');
      SObject appr = apprType2 != null ? apprType2.newSObject(null, true) : null;
      Id ruleId = getOrCreateApprovalRuleId();
      appr.put('Quote__c', quoteId);
      appr.put('SBAA__Status__c', 'Approved');
      appr.put('SBAA__RecordField__c', 'Quote__c');
      appr.put('SBAA__ApprovalStep__c', 10);
      appr.put('SBAA__Rule__c', ruleId);
      appr.put('SBAA__ApprovedBy__c', runAsUser.Id);
      insert appr;

      Test.startTest();
      ItemsToApproveQuoteService.PagedResult res = ItemsToApproveQuoteService.fetchApprovals(50, 1, 'CreatedDate', 'DESC', null);
      Test.stopTest();

      System.assertEquals(1, res.items.size(), 'Should return one row per Quote after dedupe');
      ItemsToApproveQuoteService.ApprovalItem row = res.items[0];
      System.assertEquals(quoteId, row.quoteId, 'Row should reference the expected quote');
      System.assertNotEquals(null, row.mostRecentApprover, 'Latest approver name should be filled in');
      System.assertEquals(1, res.totalRecords, 'Total distinct quotes should count distinct eligible quotes');
      // Note: totalRecords is based on aggregate COUNT_DISTINCT with the same filters
    }
  }

  @IsTest
  static void testFetchApprovals_SearchAndPagination() {
    User runAsUser = getSetupUser();
    System.runAs(runAsUser) {
      // Create two quotes with distinct Opportunities to filter by search
      Account acc = new Account(Name = 'NoSearchAcct', BillingStateCode = 'MT', BillingCountryCode = 'US', Organization_Size__c = '1 - 99');
      insert acc;
      Opportunity oppA = new Opportunity(Name = 'OnlyA', StageName = 'Prospecting', CloseDate = System.today().addDays(45), AccountId = acc.Id);
      Opportunity oppB = new Opportunity(Name = 'OnlyB', StageName = 'Prospecting', CloseDate = System.today().addDays(50), AccountId = acc.Id);
      insert new List<Opportunity>{ oppA, oppB };

      SBQQ__Quote__c qA = new SBQQ__Quote__c(SBQQ__Account__c = acc.Id, SBQQ__Opportunity2__c = oppA.Id, SBQQ__StartDate__c = Date.today(), SBQQ__EndDate__c = Date.today().addYears(1));
      SBQQ__Quote__c qB = new SBQQ__Quote__c(SBQQ__Account__c = acc.Id, SBQQ__Opportunity2__c = oppB.Id, SBQQ__StartDate__c = Date.today(), SBQQ__EndDate__c = Date.today().addYears(1));
      insert new List<SBQQ__Quote__c>{ qA, qB };

      createApprovalsForQuote(qA.Id, 'Requested', String.valueOf(UserInfo.getUserId()), null, 1, 'B1');
      createApprovalsForQuote(qB.Id, 'Requested', String.valueOf(UserInfo.getUserId()), null, 1, 'B2');

      // Add a third quote which should be excluded because Quote status is Approved
      SBQQ__Quote__c qC = new SBQQ__Quote__c(SBQQ__Account__c = acc.Id, SBQQ__Opportunity2__c = oppB.Id, SBQQ__StartDate__c = Date.today(), SBQQ__EndDate__c = Date.today().addYears(1), SBQQ__Status__c = 'Approved');
      insert qC;
      createApprovalsForQuote(qC.Id, 'Requested', String.valueOf(UserInfo.getUserId()), null, 1, 'B3');

      Test.startTest();
      // Search by Opportunity name to match only qA
      ItemsToApproveQuoteService.PagedResult page1 = ItemsToApproveQuoteService.fetchApprovals(1, 1, 'CreatedDate', 'DESC', 'OnlyA');
      ItemsToApproveQuoteService.PagedResult page2 = ItemsToApproveQuoteService.fetchApprovals(1, 2, 'CreatedDate', 'DESC', 'OnlyA');
      Test.stopTest();

      System.assertEquals(1, page1.items.size(), 'Page size 1 should return one row');
      // Because the service paginates before deduping by Quote, duplicates may spill into page 2.
      // Validate that both pages combined still reference a single distinct Quote for the search.
      Set<Id> uniqueQuotes = new Set<Id>();
      for (ItemsToApproveQuoteService.ApprovalItem it : page1.items) uniqueQuotes.add(it.quoteId);
      for (ItemsToApproveQuoteService.ApprovalItem it : page2.items) uniqueQuotes.add(it.quoteId);
      System.assertEquals(1, uniqueQuotes.size(), 'Search should match a single distinct quote across pages');
    }
  }

  @IsTest
  static void testFetchApprovals_GroupAssignment_15Char() {
    User runAsUser = getSetupUser();
    System.runAs(runAsUser) {
      Map<String, SObject> data = createCoreData('C');
      Id quoteId = (Id)data.get('Quote').get('Id');
      Group g = getExistingGroup();

      // Store 15-char group Id in AssignedGroupId field to exercise ID-format logic
      String groupId15 = String.valueOf(g.Id).substring(0, 15);
      createApprovalsForQuote(quoteId, 'Requested', null, groupId15, 1, 'C');

      Test.startTest();
      ItemsToApproveQuoteService.PagedResult res = ItemsToApproveQuoteService.fetchApprovals(10, 1, 'Quote__r.Name', 'ASC', null);
      Test.stopTest();

      System.assertEquals(1, res.items.size(), 'Group-assigned approval (15-char) should be included');
      System.assertEquals(1, res.totalRecords, 'Total distinct quotes should be 1');
    }
  }

  @IsTest
  static void testFetchApprovals_ExclusionsAndDefaults() {
    User runAsUser = getSetupUser();
    System.runAs(runAsUser) {
      // Quote with Rejected status should exclude approvals on it
      Map<String, SObject> data = createCoreData('D');
      SObject q = data.get('Quote');
      q.put('SBQQ__Status__c', 'Rejected');
      update q;
      createApprovalsForQuote((Id)q.get('Id'), 'Requested', String.valueOf(UserInfo.getUserId()), null, 1, 'D');

      Test.startTest();
      // Use invalid sort to hit allow-list fallback and default page params
      ItemsToApproveQuoteService.PagedResult res = ItemsToApproveQuoteService.fetchApprovals(null, null, 'Invalid_Field__c', 'down', null);
      Test.stopTest();

      // Only orphan (no Quote) and rejected Quote approvals exist -> both excluded; expect 0
      System.assertEquals(0, res.items.size(), 'No eligible approvals should be returned');
      System.assertEquals(0, res.totalRecords, 'Total distinct quotes should be 0');
    }
  }

  @IsTest
  static void testQuoteRulePairLogic_AndSortingMethods() {
    User runAsUser = getSetupUser();
    System.runAs(runAsUser) {
      // Create two accounts with different segments to test sorting by nested fields
      Account acc1 = new Account(
        Name = 'Alpha Account', 
        BillingStateCode = 'CA', 
        BillingCountryCode = 'US', 
        Organization_Size__c = '1 - 99',
        Customer_ARR_Netsuite__c = 50000
      );
      Account acc2 = new Account(
        Name = 'Beta Account', 
        BillingStateCode = 'NY', 
        BillingCountryCode = 'US', 
        Organization_Size__c = '100 - 499',
        Customer_ARR_Netsuite__c = 10000
      );
      insert new List<Account>{ acc1, acc2 };

      // Create opportunities with different close dates and ACV values
      Opportunity opp1 = new Opportunity(
        Name = 'Opp Alpha', 
        StageName = 'Prospecting', 
        CloseDate = System.today().addDays(10), 
        AccountId = acc1.Id
      );
      Opportunity opp2 = new Opportunity(
        Name = 'Opp Beta', 
        StageName = 'Qualification', 
        CloseDate = System.today().addDays(20), 
        AccountId = acc2.Id
      );
      insert new List<Opportunity>{ opp1, opp2 };

      // Create quotes
      SBQQ__Quote__c quote1 = new SBQQ__Quote__c(
        SBQQ__Account__c = acc1.Id, 
        SBQQ__Opportunity2__c = opp1.Id, 
        SBQQ__StartDate__c = Date.today(), 
        SBQQ__EndDate__c = Date.today().addYears(1)
      );
      SBQQ__Quote__c quote2 = new SBQQ__Quote__c(
        SBQQ__Account__c = acc2.Id, 
        SBQQ__Opportunity2__c = opp2.Id, 
        SBQQ__StartDate__c = Date.today(), 
        SBQQ__EndDate__c = Date.today().addYears(1)
      );
      insert new List<SBQQ__Quote__c>{ quote1, quote2 };

      // Get/create two different approval rules to test Quote+Rule pair logic
      Id ruleId1 = getOrCreateApprovalRuleId();
      SBAA__ApprovalRule__c rule2 = new SBAA__ApprovalRule__c(
        Name = 'Test Service Approval Rule 2',
        SBAA__TargetObject__c = 'SBQQ__Quote__c'
      );
      insert rule2;
      Id ruleId2 = rule2.Id;

      // ===== SCENARIO 1: Quote1 + Rule1 - Multiple approvals with different statuses =====
      // Create 3 approvals for Quote1+Rule1: Approved (oldest), Rejected (middle), Requested (newest)
      // Expected: Should show the approval because newest is 'Requested'
      
      Schema.SObjectType apprType = Schema.getGlobalDescribe().get('SBAA__Approval__c');
      
      SObject ap1_old = apprType.newSObject(null, true);
      ap1_old.put('Quote__c', quote1.Id);
      ap1_old.put('SBAA__Status__c', 'Approved');
      ap1_old.put('SBAA__RecordField__c', 'Quote__c');
      ap1_old.put('SBAA__ApprovalStep__c', 10);
      ap1_old.put('SBAA__Rule__c', ruleId1);
      ap1_old.put('SBAA__AssignedTo__c', String.valueOf(UserInfo.getUserId()));
      insert ap1_old;
      Test.setCreatedDate((Id)ap1_old.get('Id'), System.now().addDays(-5));

      SObject ap1_middle = apprType.newSObject(null, true);
      ap1_middle.put('Quote__c', quote1.Id);
      ap1_middle.put('SBAA__Status__c', 'Rejected');
      ap1_middle.put('SBAA__RecordField__c', 'Quote__c');
      ap1_middle.put('SBAA__ApprovalStep__c', 10);
      ap1_middle.put('SBAA__Rule__c', ruleId1);
      ap1_middle.put('SBAA__AssignedTo__c', String.valueOf(UserInfo.getUserId()));
      insert ap1_middle;
      Test.setCreatedDate((Id)ap1_middle.get('Id'), System.now().addDays(-3));

      SObject ap1_newest = apprType.newSObject(null, true);
      ap1_newest.put('Quote__c', quote1.Id);
      ap1_newest.put('SBAA__Status__c', 'Requested');
      ap1_newest.put('SBAA__RecordField__c', 'Quote__c');
      ap1_newest.put('SBAA__ApprovalStep__c', 10);
      ap1_newest.put('SBAA__Rule__c', ruleId1);
      ap1_newest.put('SBAA__AssignedTo__c', String.valueOf(UserInfo.getUserId()));
      insert ap1_newest;
      Test.setCreatedDate((Id)ap1_newest.get('Id'), System.now().addDays(-1));

      // ===== SCENARIO 2: Quote1 + Rule2 - Multiple approvals where newest is NOT 'Requested' =====
      // Create 2 approvals for Quote1+Rule2: Requested (old), Approved (newest)
      // Expected: Should NOT show because newest is 'Approved', not 'Requested'
      
      SObject ap2_old = apprType.newSObject(null, true);
      ap2_old.put('Quote__c', quote1.Id);
      ap2_old.put('SBAA__Status__c', 'Requested');
      ap2_old.put('SBAA__RecordField__c', 'Quote__c');
      ap2_old.put('SBAA__ApprovalStep__c', 10);
      ap2_old.put('SBAA__Rule__c', ruleId2);
      ap2_old.put('SBAA__AssignedTo__c', String.valueOf(UserInfo.getUserId()));
      insert ap2_old;
      Test.setCreatedDate((Id)ap2_old.get('Id'), System.now().addDays(-4));

      SObject ap2_newest = apprType.newSObject(null, true);
      ap2_newest.put('Quote__c', quote1.Id);
      ap2_newest.put('SBAA__Status__c', 'Approved');
      ap2_newest.put('SBAA__RecordField__c', 'Quote__c');
      ap2_newest.put('SBAA__ApprovalStep__c', 10);
      ap2_newest.put('SBAA__Rule__c', ruleId2);
      ap2_newest.put('SBAA__AssignedTo__c', String.valueOf(UserInfo.getUserId()));
      insert ap2_newest;
      Test.setCreatedDate((Id)ap2_newest.get('Id'), System.now().addHours(-2));

      // ===== SCENARIO 3: Quote2 + Rule1 - Single 'Requested' approval =====
      // Expected: Should show
      
      SObject ap3 = apprType.newSObject(null, true);
      ap3.put('Quote__c', quote2.Id);
      ap3.put('SBAA__Status__c', 'Requested');
      ap3.put('SBAA__RecordField__c', 'Quote__c');
      ap3.put('SBAA__ApprovalStep__c', 10);
      ap3.put('SBAA__Rule__c', ruleId1);
      ap3.put('SBAA__AssignedTo__c', String.valueOf(UserInfo.getUserId()));
      insert ap3;
      Test.setCreatedDate((Id)ap3.get('Id'), System.now().addHours(-6));

      Test.startTest();
      
      // Test 1: Verify Quote+Rule pair logic with default sort (CreatedDate DESC)
      ItemsToApproveQuoteService.PagedResult resultDefault = ItemsToApproveQuoteService.fetchApprovals(50, 1, 'CreatedDate', 'DESC', null);
      
      // Test 2: Test sorting by Account name (ASC) - exercises getFieldValue with nested path
      ItemsToApproveQuoteService.PagedResult resultAccountNameAsc = ItemsToApproveQuoteService.fetchApprovals(50, 1, 'Quote__r.SBQQ__Account__r.Name', 'ASC', null);
      
      // Test 3: Test sorting by Opportunity Close Date (DESC) - exercises Date comparison
      ItemsToApproveQuoteService.PagedResult resultCloseDateDesc = ItemsToApproveQuoteService.fetchApprovals(50, 1, 'Quote__r.SBQQ__Opportunity2__r.CloseDate', 'DESC', null);
      
      // Test 4: Test sorting by Customer ARR (ASC) - exercises Decimal comparison
      ItemsToApproveQuoteService.PagedResult resultARRAsc = ItemsToApproveQuoteService.fetchApprovals(50, 1, 'Quote__r.SBQQ__Account__r.Customer_ARR_Netsuite__c', 'ASC', null);
      
      Test.stopTest();

      // ===== ASSERTIONS =====
      
      // Should only return 2 approvals: Quote1+Rule1 (newest='Requested') and Quote2+Rule1 (only='Requested')
      // Quote1+Rule2 should be excluded because newest='Approved'
      System.assertEquals(2, resultDefault.totalRecords, 'Should have 2 distinct Quote+Rule pairs with newest=Requested');
      System.assertEquals(2, resultDefault.items.size(), 'Should return 2 approval items');
      
      // Verify that Quote1+Rule1 and Quote2+Rule1 are present
      Set<Id> returnedQuoteIds = new Set<Id>();
      for (ItemsToApproveQuoteService.ApprovalItem item : resultDefault.items) {
        returnedQuoteIds.add(item.quoteId);
      }
      System.assert(returnedQuoteIds.contains(quote1.Id), 'Quote1 should be in results (Rule1 pair)');
      System.assert(returnedQuoteIds.contains(quote2.Id), 'Quote2 should be in results (Rule1 pair)');
      
      // Verify the correct approval record is returned for Quote1 (should be ap1_newest)
      ItemsToApproveQuoteService.ApprovalItem quote1Item;
      for (ItemsToApproveQuoteService.ApprovalItem item : resultDefault.items) {
        if (item.quoteId == quote1.Id) {
          quote1Item = item;
          break;
        }
      }
      System.assertNotEquals(null, quote1Item, 'Should find item for Quote1');
      System.assertEquals((Id)ap1_newest.get('Id'), quote1Item.recordId, 'Should return the newest Requested approval for Quote1+Rule1');
      
      // Test sorting by Account Name ASC - Alpha should come before Beta
      System.assertEquals(2, resultAccountNameAsc.items.size(), 'Account name sort should return 2 items');
      System.assertEquals('Alpha Account', resultAccountNameAsc.items[0].accountName, 'First item should be Alpha Account (ASC sort)');
      System.assertEquals('Beta Account', resultAccountNameAsc.items[1].accountName, 'Second item should be Beta Account (ASC sort)');
      
      // Test sorting by Close Date DESC - later date (opp2, day 20) should come first
      System.assertEquals(2, resultCloseDateDesc.items.size(), 'Close date sort should return 2 items');
      System.assertEquals(opp2.Id, resultCloseDateDesc.items[0].opportunityId, 'First item should have later close date (DESC sort)');
      System.assertEquals(opp1.Id, resultCloseDateDesc.items[1].opportunityId, 'Second item should have earlier close date (DESC sort)');
      
      // Test sorting by ARR ASC - smaller value (10000) should come first
      System.assertEquals(2, resultARRAsc.items.size(), 'ARR sort should return 2 items');
      System.assertEquals(10000, resultARRAsc.items[0].accountCustomerARR, 'First item should have lower ARR (ASC sort)');
      System.assertEquals(50000, resultARRAsc.items[1].accountCustomerARR, 'Second item should have higher ARR (ASC sort)');
    }
  }
}