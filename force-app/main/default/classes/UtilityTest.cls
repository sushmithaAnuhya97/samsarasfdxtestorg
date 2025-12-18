@IsTest
public class UtilityTest {
    @IsTest
    static void testGetCustomLabelByDeveloperNameForFlow() {
        String developerName = 'Profile_System_Administrator';
        String customLabel = AutomationUtility.getCustomLabelByDeveloperNameFromFlow(new list<String>{developerName})[0];
        System.assertNotEquals(null, customLabel, 'Custom label should not be null');
    }

    @IsTest
    static void testGetCustomLabelByDeveloperNameForCMP() {
        String developerName = 'Profile_System_Administrator';
        String customLabel = AutomationUtility.getCustomLabelByDeveloperNameForCMP(developerName);
        System.assertNotEquals(null, customLabel, 'Custom label should not be null');
    }

    @IsTest
    static void testGetCustomLabelByDeveloperName() {
        String developerName = 'Profile_System_Administrator';
        String customLabel = Utility.getCustomLabelByDeveloperName(developerName);
        System.assertNotEquals(null, customLabel, 'Custom label should not be null');
    }

    @isTest
    static void testOrgWideAddress(){
        string address = [SELECT Id, Address FROM OrgWideEmailAddress LIMIT 1].Address;
        OrgWideEmailAddress add = Utility.getOrgWideEmailAddressBasedOnAddress(address);
    }

    @isTest
    static void testHasPermission()
    {
        Utility.getOrgWideEmailAddressBasedOnAddress( 'Validation_Rule_Exemption' );
    }

    @isTest
    static void testareValidationsSkippedAtCustomSettings()
    {
        Utility.areValidationsSkippedAtCustomSettings( userInfo.getUserId() );
    }
}