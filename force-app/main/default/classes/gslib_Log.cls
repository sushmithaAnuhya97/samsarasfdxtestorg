/**
 * Created by vikasmishra on 2021-02-08.
 */

public with sharing class gslib_Log {

    public String className ;
    public String contextUser;
    public String message; // Stringify the object if wanted to pass
    public String method;
    public String sessionKey;
    public gslib_LogLevel logLevel;
    public gslib_LogSeverity severity;
    public String stackTrace;
    public Datetime timeStamp;
    public String type;

}