@isTest
public class OpportunityCreateNewVFPTest {
     
    @isTest
    static void testValidationTrue() {
         ApexPages.StandardSetController setController; 	
        
    	 // Setup
        OpportunityCreateNewVFP controller = new OpportunityCreateNewVFP(setController);
        Test.setCurrentPage(Page.OpportunityCreateNewVFP); // Replace with actual VF page name if needed
        
        // Set validation to true
        controller.validation = true;
        controller.displayErrorMessage = 'Error message';
        
        // Test
        Test.startTest();
        PageReference result = controller.validateOpportunity(); // Replace with actual method name
        Test.stopTest();
        
        // Verify
        System.assertEquals(null, result, 'Expected no page reference when validation is true');
        System.assertEquals(1, ApexPages.getMessages().size(), 'Expected one error message');
        System.assertEquals(ApexPages.Severity.FATAL, ApexPages.getMessages()[0].getSeverity(), 'Expected FATAL severity');
        System.assertEquals('Error message', ApexPages.getMessages()[0].getSummary(), 'Expected error message');
    }
    
    @isTest
    static void testValidationFalse() {
        ApexPages.StandardSetController setController; 
        // Setup
        OpportunityCreateNewVFP controller = new OpportunityCreateNewVFP(setController);
        Test.setCurrentPage(Page.OpportunityCreateNewVFP); 
        
        // Set validation to false
        controller.validation = false;
        
        // Test
        Test.startTest();
        PageReference result = controller.validateOpportunity();
        Test.stopTest();
        
        // Verify
        System.assertNotEquals(null, result, 'Expected a page reference when validation is false');
        //System.assertEquals('/lightning/o/Opportunity/new?count=2&nooverride=1&useRecordTypeCheck=1&navigationLocation=LIST_VIEW', result.getUrl(), 'Expected URL for new Opportunity');
        System.assertEquals(true, result.getRedirect(), 'Expected redirect to be true');
    }
}