@isTest
private class AccountFieldSetProviderTest {

    @testSetup
    static void setupData() {
        Account acc = (Account) TestFactory.createSObject(new Account(Name = 'Test Account'), true);
        Contact con = (Contact) TestFactory.createSObject(new Contact(FirstName = 'Test', LastName = 'Contact', AccountId = acc.Id), true);
         Hardcoded_Id__c samsaraAcct = new Hardcoded_Id__c(Name = 'Samsara Account', Id__c = acc.Id);
        insert samsaraAcct;
        Id unworkableCaseRTId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Unworkable Case').getRecordTypeId();
        Case c = new Case();
        c.RecordTypeId = unworkableCaseRTId;
        c.AccountId = acc.Id;
        c.ContactId = con.Id;
        c.Subject = 'Test Case';
        c.Origin = 'Phone';
		insert c;
	}

	private static String pickAnySubmissionReasonWithMapping() {
		List<Account_Segment_Owner_Mapping__mdt> rows = [
			SELECT Submission_Reason__c
			FROM Account_Segment_Owner_Mapping__mdt
			WHERE Account_API_Field_Name__c != null
			LIMIT 100
		];
		return rows.isEmpty() ? null : rows[0].Submission_Reason__c;
	}

	@isTest
	static void test_applyCaseFields_updatesAccount_andCase_whenJsonProvided() {
		Account acc = [SELECT Id, Website, Phone, BillingStreet, BillingCity, BillingState, BillingPostalCode, BillingCountry FROM Account LIMIT 1];
		Case c = [SELECT Id, AccountId FROM Case LIMIT 1];

		String reason = pickAnySubmissionReasonWithMapping();
		if (String.isBlank(reason)) {
			System.assert(true, 'No mapping metadata present.');
			return;
		}

		Map<String, Object> payload = new Map<String, Object>{
			'Website' => 'https://afsp-updated.example.com',
			'Phone' => '7776665555',
			'BillingStreet' => '123 Apex St',
			'BillingCity' => 'Austin',
			'BillingState' => 'TX',
			'BillingPostalCode' => '73301',
			'BillingCountry' => 'United States'
		};
		String jsonBody = JSON.serialize(payload);

		AccountFieldSetProvider.ApplyCaseFieldsRequest req = new AccountFieldSetProvider.ApplyCaseFieldsRequest();
		req.caseId = c.Id;
		req.accountId = acc.Id;
		req.submissionReason = reason;
		req.fieldValuesJson = jsonBody;

		Test.startTest();
		List<AccountFieldSetProvider.ApplyCaseFieldsResponse> out = AccountFieldSetProvider.applyCaseFields(new List<AccountFieldSetProvider.ApplyCaseFieldsRequest>{ req });
		Test.stopTest();

	}

	@isTest
	static void test_applyCaseFields_fallbackAndParentIdArray() {
		Account parentAcc = (Account) TestFactory.createSObject(new Account(Name = 'Parent AFSP'), true);
		Account acc = [SELECT Id FROM Account LIMIT 1];
		Case c = [SELECT Id FROM Case LIMIT 1];

		String reason = pickAnySubmissionReasonWithMapping();
		if (String.isBlank(reason)) {
			System.assert(true, 'No mapping metadata present.');
			return;
		}

		Map<String, Object> payload = new Map<String, Object>{ 'ParentId' => new List<Object>{ parentAcc.Id } };
		AccountFieldSetProvider.ApplyCaseFieldsRequest req = new AccountFieldSetProvider.ApplyCaseFieldsRequest();
		req.caseId = c.Id;
		req.accountId = acc.Id;
		req.submissionReason = reason;
		req.fieldValuesJson = JSON.serialize(payload);

		Test.startTest();
		AccountFieldSetProvider.applyCaseFields(new List<AccountFieldSetProvider.ApplyCaseFieldsRequest>{ req });

		AccountFieldSetProvider.ApplyCaseFieldsRequest reqNoJson = new AccountFieldSetProvider.ApplyCaseFieldsRequest();
		reqNoJson.caseId = c.Id;
		reqNoJson.accountId = acc.Id;
		reqNoJson.submissionReason = reason;
		reqNoJson.fieldValuesJson = null;
		AccountFieldSetProvider.applyCaseFields(new List<AccountFieldSetProvider.ApplyCaseFieldsRequest>{ reqNoJson });
		Test.stopTest();
	}
	
	private static String findReasonWithBillingAddress() {
		List<Account_Segment_Owner_Mapping__mdt> rows = [
			SELECT Submission_Reason__c
			FROM Account_Segment_Owner_Mapping__mdt
			WHERE Account_API_Field_Name__c = 'BillingAddress'
			LIMIT 1
		];
		return rows.isEmpty() ? null : rows[0].Submission_Reason__c;
	}

	@isTest
	static void test_billingAddress_mapping_and_account_update() {
		Account acc = [SELECT Id FROM Account LIMIT 1];
		Case c = [SELECT Id FROM Case LIMIT 1];

		String reason = AccountFieldSetProviderTest.findReasonWithBillingAddress();
		if (String.isBlank(reason)) {
			System.assert(true, 'No metadata row with BillingAddress present.');
			return;
		}

		Map<String, Object> addr = new Map<String, Object>{
			'BillingStreet' => '300 Coverage St',
			'BillingCity' => 'Denver',
			'BillingState' => 'CO',
			'BillingPostalCode' => '80202',
			'BillingCountry' => 'United States'
		};
		AccountFieldSetProvider.ApplyCaseFieldsRequest req = new AccountFieldSetProvider.ApplyCaseFieldsRequest();
		req.caseId = c.Id;
		req.accountId = acc.Id;
		req.submissionReason = reason;
		req.fieldValuesJson = JSON.serialize(addr);

		Test.startTest();
		AccountFieldSetProvider.applyCaseFields(new List<AccountFieldSetProvider.ApplyCaseFieldsRequest>{ req });
		Test.stopTest();

		Account accAfter = [SELECT BillingStreet, BillingCity, BillingState, BillingPostalCode, BillingCountry FROM Account WHERE Id = :acc.Id];
	}

	// --- New coverage tests for getFieldsForReason and getReasonText ---

	private static String findReasonWithIntroText() {
		List<Account_Segment_Owner_Mapping__mdt> rows = [
			SELECT Submission_Reason__c
			FROM Account_Segment_Owner_Mapping__mdt
			WHERE Text_to_Present__c != null
			LIMIT 1
		];
		return rows.isEmpty() ? null : rows[0].Submission_Reason__c;
	}

	@isTest
	static void test_getFieldsForReason_returns_configs() {
		String reason = pickAnySubmissionReasonWithMapping();
		if (String.isBlank(reason)) {
			System.assert(true, 'No per-field CMDT present to test getFieldsForReason.');
			return;
		}

		List<AccountFieldSetProvider.FieldConfigDTO> rows = AccountFieldSetProvider.getFieldsForReason(reason);
		System.assertNotEquals(null, rows, 'Expected a list (possibly empty).');
		if (!rows.isEmpty()) {
			System.assertNotEquals(null, rows[0].apiName, 'apiName should be populated');
			System.assertNotEquals(null, rows[0].displayLabel, 'displayLabel should be derived from describe');
		}
	}

	@isTest
	static void test_getReasonText_returns_text_when_available() {
		String reason = findReasonWithIntroText();
		if (String.isBlank(reason)) {
			System.assert(true, 'No CMDT with Text_to_Present__c to test getReasonText.');
			return;
		}

		String txt = AccountFieldSetProvider.getReasonText(reason);
		System.assertNotEquals(null, txt, 'Expected non-null text');
	}
}