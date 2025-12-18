@isTest
private class CaseTriggerTest {

    @TestSetup
    static void makeData(){
        //Need this to bypass the error from another trigger
        insert new Hardcoded_Id__c (Name = 'Samsara Account' , Id__c = '0011P00000tsGOmQAM ');
        
        //Create Partner Account
        RecordType accountPartnerRT = [Select Id from RecordType Where SObjectType = 'Account' and Name = 'Partner' LIMIT 1]; 
        Account partnerAccount = new Account(Name='Partner Account', Organization_Size__c='1 - 99', BillingCountry='Belgium', BillingCountryCode = 'BE', RecordTypeId = accountPartnerRT.Id);
        insert partnerAccount;
        
        //Emable as Partner
        partnerAccount.IsPartner = true;
        update partnerAccount;

        //Create Partner Contact
        String orgId = UserInfo.getOrganizationId();
        RecordType contactPartnerRT = [Select Id from RecordType Where SObjectType = 'Contact' and Name = 'Partner' LIMIT 1]; 
        Contact partnerContact = new Contact(FirstName = 'Partner', LastName = 'Contact', AccountId = partnerAccount.Id, Email = 'partner@test.com'+orgId);
        insert partnerContact;
        
    }
    
    @isTest 
    static void partnerCaseCreationTest() {
        //Create case for Partner
        Id partnerSupportRTId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Partner Support').getRecordTypeId();
        Account partnerAcc = [Select Id from Account where RecordType.Name = 'Partner'];
        Contact partnerCon = [Select Id from Contact where AccountId =: partnerAcc.Id ];
        Case partnerCase = new Case();
        partnerCase.RecordTypeId = partnerSupportRTId;
        partnerCase.AccountId = partnerAcc.id;
        partnerCase.ContactId = partnerCon.id;
        partnerCase.Subject = 'Test partner support assignment rule';
        insert partnerCase;
        
        //No logic to assert. If the case is inserted without errors, then this test should pass
    }
    
    static void caseHelper_unit() {
        //Helper afterInsert should only process Partner Support case types
        Id partnerSupportRTId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Partner Support').getRecordTypeId();
        Id otherRTId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('CS Request Log').getRecordTypeId();
        List<Case> casesInserted = new List<Case>();
        
        Case partnerCase = new Case();
        partnerCase.RecordTypeId = partnerSupportRTId;
        partnerCase.Id = generateId(Case.SObjectType,101);
        casesInserted.add(partnerCase);

        Case otherCase = new Case();
        otherCase.RecordTypeId = otherRTId;
        otherCase.Id = generateId(Case.SObjectType,102);
        casesInserted.add(otherCase);
        
        CaseHelper.executeAssignmentRuleForPartnerSupport(casesInserted);
        System.assertEquals(CaseHelper.casesToUpdate.size(), 1);
        System.assertEquals(CaseHelper.casesToUpdate.get(0).Id, partnerCase.Id);
    }
    
    private static Id generateId(SObjectType sobjectType, Integer sequenceNum) {
        String keyPrefix = sobjectType.getDescribe().getKeyPrefix();
        return Id.valueOf(keyPrefix + String.valueOf(sequenceNum).leftPad(12, '0'));
    }
    
}