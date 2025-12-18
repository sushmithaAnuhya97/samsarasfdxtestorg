@isTest
private class BillingAddressPicklistUtilTest {
    
    @isTest
    static void testGetBillingCountryCode() {
        Test.startTest();
        // First call should initialize the map
        System.assertEquals('US', BillingAddressPicklistUtil.getBillingCountryCode('United States'), 'Should match exact country name');
        
        // Test case insensitivity
        System.assertEquals('US', BillingAddressPicklistUtil.getBillingCountryCode('UNITED STATES'), 'Should match uppercase');
        System.assertEquals('US', BillingAddressPicklistUtil.getBillingCountryCode('united states'), 'Should match lowercase');
        
        // Test whitespace handling
        System.assertEquals('US', BillingAddressPicklistUtil.getBillingCountryCode('  United States  '), 'Should handle whitespace');
        System.assertEquals('US', BillingAddressPicklistUtil.getBillingCountryCode('\tUnited States\n'), 'Should handle special whitespace');
        
        // Test invalid inputs
        System.assertEquals(null, BillingAddressPicklistUtil.getBillingCountryCode(null), 'Should return null for null input');
        System.assertEquals(null, BillingAddressPicklistUtil.getBillingCountryCode(''), 'Should return null for empty string');
        System.assertEquals(null, BillingAddressPicklistUtil.getBillingCountryCode('   '), 'Should return null for whitespace');
        System.assertEquals(null, BillingAddressPicklistUtil.getBillingCountryCode('Invalid Country'), 'Should return null for invalid country');
        Test.stopTest();
    }
    
    @isTest
    static void testGetBillingStateCode() {
        Test.startTest();
        // First call should initialize the map
        System.assertEquals('CA', BillingAddressPicklistUtil.getBillingStateCode('California'), 'Should match exact state name');
        
        // Test case insensitivity
        System.assertEquals('CA', BillingAddressPicklistUtil.getBillingStateCode('CALIFORNIA'), 'Should match uppercase');
        System.assertEquals('CA', BillingAddressPicklistUtil.getBillingStateCode('california'), 'Should match lowercase');
        
        // Test whitespace handling
        System.assertEquals('CA', BillingAddressPicklistUtil.getBillingStateCode('  California  '), 'Should handle whitespace');
        System.assertEquals('CA', BillingAddressPicklistUtil.getBillingStateCode('\tCalifornia\n'), 'Should handle special whitespace');
        
        // Test invalid inputs
        System.assertEquals(null, BillingAddressPicklistUtil.getBillingStateCode(null), 'Should return null for null input');
        System.assertEquals(null, BillingAddressPicklistUtil.getBillingStateCode(''), 'Should return null for empty string');
        System.assertEquals(null, BillingAddressPicklistUtil.getBillingStateCode('   '), 'Should return null for whitespace');
        System.assertEquals(null, BillingAddressPicklistUtil.getBillingStateCode('Invalid State'), 'Should return null for invalid state');
        Test.stopTest();
    }
    
    @isTest
    static void testMapCaching() {
        Test.startTest();
        // First calls - should initialize maps
        String countryCode1 = BillingAddressPicklistUtil.getBillingCountryCode('United States');
        String stateCode1 = BillingAddressPicklistUtil.getBillingStateCode('California');
        
        // Second calls - should use cached maps
        String countryCode2 = BillingAddressPicklistUtil.getBillingCountryCode('United States');
        String stateCode2 = BillingAddressPicklistUtil.getBillingStateCode('California');
        
        // Verify results are consistent
        System.assertEquals(countryCode1, countryCode2, 'Cached country code should match');
        System.assertEquals(stateCode1, stateCode2, 'Cached state code should match');
        System.assertEquals('US', countryCode1, 'Should return correct country code');
        System.assertEquals('CA', stateCode1, 'Should return correct state code');
        Test.stopTest();
    }
}