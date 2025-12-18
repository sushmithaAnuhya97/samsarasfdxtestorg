@isTest
private class HelperTestClass {
    @isTest
    static void helperTest() {
        Date startDate = date.parse('04/02/2020');
        Date endDate = date.parse('04/08/2020');

        Integer businessDays = HelperClass.calculateWorkingDays(startDate, endDate);

        system.assertEquals(4, businessDays);
    }
    
    @isTest
    static void getGlobalTest(){
        Global_Variable__mdt globalVar = [SELECT Id, Label, DeveloperName, Value__c FROM Global_Variable__mdt][0];
        
        Test.startTest();
        String retrievedValue = HelperClass.getGlobalValue(globalVar.DeveloperName);
        Test.stopTest();
        
        system.assertEquals(globalVar.Value__c, retrievedValue);
    }
}