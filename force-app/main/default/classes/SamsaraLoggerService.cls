/**
 * Created by vikasmishra on 2021-08-19.
 */

public with sharing class SamsaraLoggerService {
    gslib_IModuleLogger thisModuleLogger;
    public  gslib_ILogger logger ;
    public SamsaraLoggerService (){
        thisModuleLogger = gslib_LoggerService.getModuleLogger();
        logger = thisModuleLogger.getLogger();
    }

    public SamsaraLoggerService setModule(String module){
        thisModuleLogger = gslib_LoggerService.getModuleLogger(module);
        logger = thisModuleLogger.getLogger();
        return this;
    }

    public SamsaraLoggerService setSubModule(String subModule){
        if(thisModuleLogger != null){
            logger = thisModuleLogger.getLogger('subModule');
        }
        else{
            System.debug('No sub module defined===>'+ 'It will enable the root logger automatically');
            thisModuleLogger = gslib_LoggerService.getModuleLogger();
            logger = thisModuleLogger.getLogger();
        }
        
        return this;
    }

}