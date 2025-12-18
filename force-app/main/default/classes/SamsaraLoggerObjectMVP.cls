/**
 * Created by vikasmishra on 2021-09-02.
 */

public with sharing class SamsaraLoggerObjectMVP {
    public Object exceptionObject;
    public Object MVP;

    public SamsaraLoggerObjectMVP (){

    }
    public SamsaraLoggerObjectMVP(Object exceptionObject, Object MVP){
        this.exceptionObject = exceptionObject;
        this.MVP = MVP;
    }
}