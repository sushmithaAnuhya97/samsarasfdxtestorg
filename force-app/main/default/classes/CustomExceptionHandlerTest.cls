/**
* Created By : Rodrigo Carpio
* @Date April 28, 2022
*
* @description : This is the test class for CustomExceptionHandler
*
* Modification History:
* Date			Author				Story/Defect			Description
* 2022-04-28	Rodrigo Carpio		GTMS-6830 				Initial draft to be able to raise exception from flow
**/
@isTest public class CustomExceptionHandlerTest {
    @isTest static void throwCustomExceptionTest() {
        Test.startTest();
        CustomExceptionHandler excHandler = new CustomExceptionHandler();
        List<CustomExceptionHandler.Inputs> excHandlerInputLst = new List<CustomExceptionHandler.Inputs>();
        CustomExceptionHandler.Inputs excHandlerInput = new CustomExceptionHandler.Inputs();
        excHandlerInput.message = 'INPUT - Initial draft to be able to raise exception from flow';
        excHandlerInputLst.add(excHandlerInput);
        try {
            CustomExceptionHandler.throwCustomException(excHandlerInputLst);
        }
        Catch(exception e)
        {
            System.assert(e.getMessage().contains('INPUT - Initial draft to be able to raise exception from flow'), + e.getMessage());
        }
        Test.stopTest();
    }
    
    @isTest static void throwCustomExceptionTest2() {
        Test.startTest();
        CustomExceptionHandler excHandler = new CustomExceptionHandler();
        try {
            CustomExceptionHandler.throwCustomException('STRING - Initial draft to be able to raise exception from flow');
        }
        Catch(exception e)
        {
            System.assert(e.getMessage().contains('STRING - Initial draft to be able to raise exception from flow'), + e.getMessage());
        }
        Test.stopTest();
    }
}