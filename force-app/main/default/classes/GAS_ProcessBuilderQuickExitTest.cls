@isTest
public class GAS_ProcessBuilderQuickExitTest {
	
    @isTest
    public static void testProcessBuilderQuickExit(){
        // testing success of a void method without logic
        Boolean isSuccess = true;
        try {
            GAS_ProcessBuilderQuickExit.processBuilderQuickExit();
        } catch(Exception e) {
            isSuccess = false;
        }

        System.assert(isSuccess, 'Expecting processBuilderQuickExit() to execute successfully');
    }
}