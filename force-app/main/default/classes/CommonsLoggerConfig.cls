/**
 * Created by vikasmishra on 2021-05-06.
 * TODO: Need ton decide on heap threshold
 */

public with sharing class CommonsLoggerConfig implements gslib_ICommonsLoggerConfig{
    private static  Map<String, gslib_LogLevel> LOG_LEVEL_BY_VALUES;
    private static final Integer CACHE_FLUSH_HEAP_THRESHOLD = 51428800;//52428800
    private static final Boolean ENABLE_CACHE = true;
    private static final String ROOT_LOGGER_LABEL = 'RootLogger';
    @TestVisible
    private static ISelector thisCommonsLoggerConfigSelector = new CommonsLoggerConfigSelector();
    @TestVisible static IService thisLoggerMetaDataService = new LoggerConfigurationService();
    static {
        setGslib_LogLevel();
    }

    /**
     * @return: gslib_LoggerService.LoggerConfig for the Logging framework with the desired configuration
     */
    public gslib_LoggerService.LoggerConfig getLoggerConfig() {

        gslib_LoggerService.LoggerConfig loggerConfig = new gslib_LoggerService.LoggerConfig();
        loggerConfig.cacheEnabled =  ENABLE_CACHE;
        loggerConfig.cacheFlushThreshold = CACHE_FLUSH_HEAP_THRESHOLD;
        loggerConfig.loggerAppenderMap = thisLoggerMetaDataService.processLoggerConfigItem();
        loggerConfig.rootLoggerList = thisLoggerMetaDataService.getRootLoggerConfig();
        return loggerConfig;
    }

    private static void setGslib_LogLevel(){
        LOG_LEVEL_BY_VALUES = new  Map<String, gslib_LogLevel>();
        for (gslib_LogLevel enumValue : gslib_LogLevel.values())
        {
            LOG_LEVEL_BY_VALUES.put(String.valueOf(enumValue), enumValue);
        }
    }

    public class LoggerConfigurationService implements IService{

        public Map<String, List<gslib_LoggerService.LoggerConfigItem>> processLoggerConfigItem(){
            Map<String, List<gslib_LoggerService.LoggerConfigItem>> loggerConfigItemMap =
                    new Map<String, List<gslib_LoggerService.LoggerConfigItem>>();
            for(Commons_Logger_Config__mdt commonsLoggerConfig : thisCommonsLoggerConfigSelector.getAllCommonsLoggerConfig()){

                if(!loggerConfigItemMap.containsKey(commonsLoggerConfig.Label)){
                    loggerConfigItemMap.put(commonsLoggerConfig.Label, new List<gslib_LoggerService.LoggerConfigItem>());
                }
                loggerConfigItemMap.get(commonsLoggerConfig.Label)
                        .add(
                        new gslib_LoggerService.LoggerConfigItem(
                                commonsLoggerConfig.Appender_Name__c,
                                LOG_LEVEL_BY_VALUES.get(commonsLoggerConfig.Log_Level__c)
                        )
                );
            }
            return loggerConfigItemMap;
        }

        public List<gslib_LoggerService.LoggerConfigItem> getRootLoggerConfig(){
            Commons_Logger_Config__mdt commonsLoggerConfig =
                    thisCommonsLoggerConfigSelector.getCommonsLoggerConfigByDeveloperName(ROOT_LOGGER_LABEL) ;
            return new List<gslib_LoggerService.LoggerConfigItem>{
                    new gslib_LoggerService.LoggerConfigItem(
                            commonsLoggerConfig.Appender_Name__c,
                            LOG_LEVEL_BY_VALUES.get(commonsLoggerConfig.Log_Level__c)
                    )
            };
        }
    }

    public class CommonsLoggerConfigSelector implements ISelector{

        public List<Commons_Logger_Config__mdt> getAllCommonsLoggerConfig(){
            return Commons_Logger_Config__mdt.getAll().values();
        }

        public Commons_Logger_Config__mdt getCommonsLoggerConfigByDeveloperName(String developerName){
            return Commons_Logger_Config__mdt.getInstance(developerName);
        }

    }



    public interface IService{
         Map<String, List<gslib_LoggerService.LoggerConfigItem>> processLoggerConfigItem();
        List<gslib_LoggerService.LoggerConfigItem> getRootLoggerConfig();
    }

    public interface ISelector{
        List<Commons_Logger_Config__mdt> getAllCommonsLoggerConfig();
        Commons_Logger_Config__mdt getCommonsLoggerConfigByDeveloperName(String developerName);
    }
}