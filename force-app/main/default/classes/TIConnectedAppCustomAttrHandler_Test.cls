/**********************************************************************
Name: TIConnectedAppCustomAttrHandler_Test
=======================================================================
Purpose: This will handle the coverage for TIConnectedAppCustomAttrHandler                                                       
=======================================================================
History  

VERSION     AUTHOR               DATE               DETAIL                       
1.0        Rodrigo Carpio        2023-Jul-17        INITIAL DEVELOPMENT FOR GTMS-14389

***********************************************************************/ 
@isTest(SeeAllData=true)
private class TIConnectedAppCustomAttrHandler_Test {
	
	@isTest
    static void customAttributes_test() {
        Map<String,String> formulaDefinedAttributes = new Map<String,String>();
        TIConnectedAppCustomAttrHandler connApp = new TIConnectedAppCustomAttrHandler();
        List<User> userList = [SELECT Id, UserType, IsPortalEnabled, IsActive, ContactId,Email FROM User 
                               WHERE IsActive = True AND (UserType = 'PowerPartner' OR UserType = 'CspLitePortal')  and contactid!=null LIMIT 1 ];
        connApp.customAttributes(userList[0].Id, null, formulaDefinedAttributes, null);
    }
}