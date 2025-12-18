@IsTest
public class UpdateSplitACVValuesControllerTest {
    @TestSetup
    static void setupTestData() {
        Opportunity testOpportunity = new Opportunity(
            Name = 'Test Opportunity',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30)
        );
        insert testOpportunity;
    }

    @IsTest
    static void testUpdateACVValues_Success() {
        Test.startTest();
        Opportunity testOpportunity = [SELECT Id FROM Opportunity LIMIT 1];
        
       
        String result = UpdateSplitACVValuesController.updateACVValues(testOpportunity.Id);
        Test.stopTest();
        
    }
    
    @IsTest
    static void testUpdateACVValues_Failure() {
         Test.startTest();
        
        try{
       
        String result = UpdateSplitACVValuesController.updateACVValues(null);
        } catch (Exception e){
            
        }
        Test.stopTest();
        
    }

    
}