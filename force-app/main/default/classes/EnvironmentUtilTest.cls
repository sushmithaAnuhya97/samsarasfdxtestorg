@isTest
private class EnvironmentUtilTest {
    
    @isTest
    static void testNamedCredentialSelection() {
        // Get actual sandbox status from org
        Boolean isSandboxOrg = [SELECT IsSandbox FROM Organization].IsSandbox;
        
        String expectedCredential = isSandboxOrg ? 'WorkatoIntegration_Sandbox' : 'WorkatoIntegration_Prod';
        
        Test.startTest();
        String actualCredential = EnvironmentUtil.getNamedCredential();
        Test.stopTest();
        
        // Assert the named credential matches the actual environment
        System.assertEquals(expectedCredential, actualCredential,
            'Named credential should match the current environment type');
        
        // Assert sandbox detection matches actual environment
        System.assertEquals(isSandboxOrg, EnvironmentUtil.isSandbox(),
            'Sandbox detection should match Organization.IsSandbox');
    }
}