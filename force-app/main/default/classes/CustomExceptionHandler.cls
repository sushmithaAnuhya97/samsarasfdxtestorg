/**
* Created By : Rodrigo Carpio
* @Date April 28, 2022
*
* @description : This class will be responsible for raising the exception for the message that was passed
*
* Modification History:
* Date			Author				Story/Defect			Description
* 2022-04-28	Rodrigo Carpio		GTMS-6830 				Initial draft to be able to raise exception from flow
**/
public with sharing class CustomExceptionHandler {
	public class CustomException extends Exception {}
    
    @InvocableMethod(label='Throw Custom Exception')
    public static void throwCustomException(Inputs[] input){
        throw createCustomException(input[0].message);
    }
    
    public static void throwCustomException(String errorMessage){
        throw createCustomException(errorMessage);
    }
    
    public class Inputs{
        @InvocableVariable(label='Error message')
        public string message;
    }  

    static CustomException createCustomException(String message) {
        CustomException ex = new CustomException(message);
        ex.setMessage(message);
        return ex;
    }
}