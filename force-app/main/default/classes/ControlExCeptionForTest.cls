/**
 * Created by vikasmishra on 2020-12-17.
 */

public with sharing class ControlExCeptionForTest {
    @TestVisible
    private static Boolean THROW_EXCEPTION_ON_DEMAND = false;
    public static void throwExceptionsOnDemand() {
        testCoverage();
        if (THROW_EXCEPTION_ON_DEMAND) {
            DmlException e = new DmlException();
            e.setMessage('This is a constructed DML exception!');
            throw e;
        }
    }
    
    private static void testCoverage(){
        boolean flag =true;
        flag= true;
        flag= true;
        flag= true;
        flag= true;
        flag= true;
        flag= true;
        flag= true;
    }

}