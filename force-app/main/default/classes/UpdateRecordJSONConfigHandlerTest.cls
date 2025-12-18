@IsTest
public class UpdateRecordJSONConfigHandlerTest {
    @testSetup static void setup() {
        Schema.DescribeSObjectResult sObjDesc = Actions__c.sObjectType.getDescribe();
        Map<String, Schema.RecordTypeInfo> recTypes = sObjDesc.getRecordTypeInfosByDeveloperName();
        System.debug('>>>>>> recordTypes : '+recTypes);
        Actions__c action = new Actions__c(RecordTypeId=recTypes.get('Welcome_Mat').getRecordTypeId(),
                                                                           Name='Test Welcome Mat',
                                                                           Object__c='Home',
                                                                           Page_Type__c='Home');
        insert action;
    }
    public static testmethod void testUpdateJsonConfig(){
        Actions__c action = [select Id,Name,Record_Update_Criteria__c from Actions__c limit 1];
        System.assertEquals(null, action.Record_Update_Criteria__c,'1:Criteria Config JSON is not null');
        Record_Criteria__c criteria = new Record_Criteria__c(Field_Name__c='Test',
                                                                                             Field_Value__c='Test',
                                                                                             Action__c=action.Id);
        insert criteria;
        action = [select Id,Name,Record_Update_Criteria__c from Actions__c limit 1];
        //System.assert(action.Record_Update_Criteria__c!=null, '2:Criteria Config JSON JSON is null');
        String expectJson = '[{"fieldValue":"Test","fieldName":"Test"}]';
        //System.assertEquals(expectJson,action.Record_Update_Criteria__c, '3:Criteria Config JSON not matching');
    }
    
    public static testmethod void testUpdateJsonConfigMultiple(){
        Actions__c action = [select Id,Name,Record_Update_Criteria__c from Actions__c limit 1];
        System.assertEquals(null, action.Record_Update_Criteria__c,'4:Criteria Config JSON is not null');
        Record_Criteria__c criteria = new Record_Criteria__c(Field_Name__c='Test',
                                                                                             Field_Value__c='Test',
                                                                                             Action__c=action.Id);
        insert criteria;
        criteria = new Record_Criteria__c(Field_Name__c='Test2',
                                                          Field_Value__c='Test2',
                                                          Action__c=action.Id);
        insert criteria;
        action = [select Id,Name,Record_Update_Criteria__c from Actions__c limit 1];
        //System.assert(action.Record_Update_Criteria__c!=null, '5:Criteria Config JSON is null');
        String expectJson = '[{"fieldValue":"Test","fieldName":"Test"},{"fieldValue":"Test2","fieldName":"Test2"}]';
        system.debug('6: JSON =  '+action.Record_Update_Criteria__c);
        //System.assertEquals(expectJson,action.Record_Update_Criteria__c, '6:Criteria Config JSON not matching');
    }
    
    public static testmethod void testUpdateJsonConfigDelete(){
        Actions__c action = [select Id,Name,Record_Update_Criteria__c from Actions__c limit 1];
        System.assertEquals(null, action.Record_Update_Criteria__c,'4:Criteria Config JSON is not null');
        Record_Criteria__c criteria = new Record_Criteria__c(Field_Name__c='Test',
                                                                                             Field_Value__c='Test',
                                                                                             Action__c=action.Id);
        insert criteria;
        criteria = new Record_Criteria__c(Field_Name__c='Test2',
                                                          Field_Value__c='Test2',
                                                          Action__c=action.Id);
        insert criteria;
        action = [select Id,Name,Record_Update_Criteria__c from Actions__c limit 1];
        //System.assert(action.Record_Update_Criteria__c!=null, '5:Criteria Config JSON is null');
        String expectJson = '[{"fieldValue":"Test","fieldName":"Test"},{"fieldValue":"Test2","fieldName":"Test2"}]';
        system.debug('6: JSON =  '+action.Record_Update_Criteria__c);
        //System.assertEquals(expectJson,action.Record_Update_Criteria__c, '6:Criteria JSON not matching');

        delete criteria;
        action = [select Id,Name,Record_Update_Criteria__c from Actions__c limit 1];
        expectJson = '[{"fieldValue":"Test","fieldName":"Test"}]';
        system.debug('7: JSON =  '+action.Record_Update_Criteria__c);
        //System.assertEquals(expectJson,action.Record_Update_Criteria__c, '7:Delete Criteria Config JSON not matching');

    }
}