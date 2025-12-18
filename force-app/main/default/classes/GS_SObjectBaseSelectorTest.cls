@isTest(SeeAllData=false)
public class GS_SObjectBaseSelectorTest {
    
    
    @isTest static void checkLimit() {
        
        Test.startTest();
        new GS_SObjectBaseSelector(true).validateFatalError();
        new GS_SObjectBaseSelector(false).validateFatalError();
        Test.stopTest();
        
    }

}