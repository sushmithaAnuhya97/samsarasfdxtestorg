/**
 * Created by vikasmishra on 2021-06-24.
 */
@IsTest
private  class LeadConversionServiceTest {
    @IsTest
    static void leadConversionWithEmptyList() {
        LeadConversionService thisLC = new LeadConversionService();
        LeadSelectorMock leadSelector = new LeadSelectorMock();
        LeadDMLHelperMock leadDMLHelper = new LeadDMLHelperMock();
        LeadConversionService.leadSelector = leadSelector;
        LeadConversionService.leadDMLHelper = leadDMLHelper;
        thisLC.setIdToLeadMap(
                new Map<Id, Lead>(new List<Lead>{new Lead(Id = LeadConversionServiceTest.generateId(Lead.SObjectType,101) )})
        ).processIncomingLeads()
                .doConversion()
                .collectConversionErrors(new List<Lead>());
        System.assert(leadDMLHelper.methodCalled, 'DML Helper has been called');
        System.assert(leadSelector.methodCalled, 'Query has been performed');

    }

    @IsTest
    static void shouldDOLeadConversion() {
        LeadConversionService thisLC = new LeadConversionService();
        LeadSelectorMock leadSelector = new LeadSelectorMock();
        LeadDMLHelperMock leadDMLHelper = new LeadDMLHelperMock();
        LeadConversionService.leadSelector = leadSelector;
        LeadConversionService.leadDMLHelper = leadDMLHelper;
        thisLC.setIdToLeadMap(
                new Map<Id, Lead>(new List<Lead>{new Lead(Id = LeadConversionServiceTest.generateId(Lead.SObjectType,101) )})
        ).processIncomingLeads()
                .doConversion()
                .collectConversionErrors(new List<Lead>());
        System.assert(leadDMLHelper.methodCalled, 'DML Helper has been called');
        System.assert(leadSelector.methodCalled, 'Query has been performed');
    }

    @IsTest
    static void shouldFailLeadConversion() {
        LeadConversionService thisLC = new LeadConversionService();
        LeadConversionService.leadSelector = new LeadSelectorMock();
        LeadConversionService.leadDMLHelper = new LeadDMLHelperMockFail();
        thisLC.setIdToLeadMap(
                new Map<Id, Lead>(new List<Lead>{new Lead(Id = LeadConversionServiceTest.generateId(Lead.SObjectType,101) )})
        ).processIncomingLeads()
                .doConversion()
                .collectConversionErrors(new List<Lead>()).rollbackChanges(thisLC.getConvertedLead());
        System.assert(thisLC.getConvertedLead().isEmpty(), 'Should failed to return');
    }

    @IsTest
    static void testLeadSelector(){
        LeadConversionService.LeadSelector thisLCSelector = new LeadConversionService.LeadSelector();
        System.assert(thisLCSelector.getLeadsByIds(new Set<Id>()).isEmpty(), 'Should return empty list');
    }

    @IsTest
    static void testLeadDMLHelper(){
        LeadConversionService.LeadDmlHelper thisLCDmlHelper = new LeadConversionService.LeadDmlHelper();
        System.assert(thisLCDmlHelper.updateObjects(new List<Lead>(), false).isEmpty(), 'Should return empty list');
        System.assert(thisLCDmlHelper.convertLead(new List<Database.LeadConvert>(), false).isEmpty(), 'Should return empty list');
    }


    public class LeadSelectorMock implements LeadConversionService.ISelector{
        public Boolean methodCalled = false;
        public List<Lead> leadList = new List<Lead>();
        public List<Lead> getLeadsByIds (Set<Id> ids){
            methodCalled = true;
            leadList = new List<Lead>{
                    new Lead(Status = 'Pending Verification',
                            Id = LeadConversionServiceTest.generateId(Lead.SObjectType,101),
                            RecordTypeId = LeadConversionService.getRecordTypeId(
                                    'Lead',
                                    'Partner_Application'
                            )
                    )
            };
            return leadList;
        }
}

    public class LeadDMLHelperMock implements LeadConversionService.IDMLHelper{
        public Boolean methodCalled = false;

        public List<Database.SaveResult> updateObjects (List<Lead> leadList, Boolean allOrNothing){
            methodCalled = true;
            Database.SaveResult sr = (Database.SaveResult)
                    JSON.deserialize('{"success":true,"id":"'+LeadConversionServiceTest.generateId(Lead.SObjectType,101) + '"}', Database.SaveResult.class);
            return new List<Database.SaveResult>{sr};
        }
        public List<Database.LeadConvertResult> convertLead(List<Database.LeadConvert> toLeadConvertList, Boolean allOrNothing){
            methodCalled = true;
            return  (List<Database.LeadConvertResult>) JSON.deserialize(
                    '[{"accountid":"' +
                            LeadConversionServiceTest.generateId(Account.SObjectType,101) +
                            '","contactid":"' +
                            LeadConversionServiceTest.generateId(Contact.SObjectType,101) +
                            '","leadid":"' +
                            LeadConversionServiceTest.generateId(Lead.SObjectType,101) +
                            '","success":true,"errors":[]}]', List<Database.LeadConvertResult>.class);
        }
    }

    public class LeadDMLHelperMockFail implements LeadConversionService.IDMLHelper{
        public Boolean methodCalled = false;

        public List<Database.SaveResult> updateObjects (List<Lead> leadList, Boolean allOrNothing){
            methodCalled = true;
            Database.SaveResult sr = (Database.SaveResult)
                    JSON.deserialize('{"success":true,"id":"'+LeadConversionServiceTest.generateId(Lead.SObjectType,101) + '"}', Database.SaveResult.class);
            return new List<Database.SaveResult>{sr};
        }
        public List<Database.LeadConvertResult> convertLead(List<Database.LeadConvert> toLeadConvertList, Boolean allOrNothing){
            methodCalled = true;
            return  (List<Database.LeadConvertResult>) JSON.deserialize(
                    '[{"accountid":"' +
                            LeadConversionServiceTest.generateId(Account.SObjectType,101) +
                            '","contactid":"' +
                            LeadConversionServiceTest.generateId(Contact.SObjectType,101) +
                            '","leadid":"' +
                            LeadConversionServiceTest.generateId(Lead.SObjectType,101) +
                            '","success":false,"errors":[]}]', List<Database.LeadConvertResult>.class);
        }
    }


    public static Id generateId(SObjectType sobjectType, Integer sequenceNum) {
        String keyPrefix = sobjectType.getDescribe().getKeyPrefix();
        return Id.valueOf(keyPrefix + String.valueOf(sequenceNum).leftPad(12, '0'));
    }

}