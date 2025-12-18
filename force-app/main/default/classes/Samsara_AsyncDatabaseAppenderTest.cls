/**
 * Created by vikasmishra on 2021-08-31.
 */
@IsTest
private  class Samsara_AsyncDatabaseAppenderTest {

    @IsTest
    static void testAsyncDatabaseAppenderSuccess() {
        gslib_LoggerService.COMMONS_LOGGER_CONFIG = 'Samsara_AsyncDatabaseAppenderTest.CommonsLoggerConfigTest';
        gslib_IModuleLogger classLogger = gslib_LoggerService.getModuleLogger('Demo');
        gslib_ILogger logger = classLogger.getLogger('Demo');
        gslib_LoggerService.thisLoggerConfig = new CommonsLoggerConfigAsyncAppenderTest().getLoggerConfig();
        logger.log(gslib_LogLevel.Warning, 'Testing this');
        logger.logWarning('Test');
        logger.logWarning(gslib_LogSeverity.Major, 'Test');
        logger.logWarning(gslib_LogSeverity.Major, 'test', new Account());
        System.assert(
                !gslib_LoggerService.appenderMapForDispatch.isEmpty(),
                'Should set appender based Supplied Module'
        );
        Test.startTest();
        logger.dispatch();
        System.assert(
                !gslib_LoggerService.appenderMapForDispatch.isEmpty(),
                'Dispatch should be called'
        );
        System.assert(
                gslib_LoggerService.thisLoggerConfig.cacheEnabled,
                'Should set cache from inner class'
        );
        System.assert(
                gslib_LoggerService.thisLoggerConfig.cacheFlushThreshold == 51428800,
                'Should set cacheFlushThreshold from inner class'
        );
        System.assert(
                !gslib_LoggerService.thisLoggerConfig.rootLoggerList.isEmpty(),
                'Should set rootLoggerList from inner class'
        );
        Test.stopTest();
    }

    @IsTest
    static void testDatabaseAppenderSuccess() {
        gslib_LoggerService.COMMONS_LOGGER_CONFIG = 'Samsara_AsyncDatabaseAppenderTest.CommonsLoggerConfigTest2';
        gslib_IModuleLogger classLogger = gslib_LoggerService.getModuleLogger('Demo');
        gslib_ILogger logger = classLogger.getLogger('Demo');
        gslib_LoggerService.thisLoggerConfig = new CommonsLoggerConfigSyncDatabaseTest2().getLoggerConfig();
        logger.log(gslib_LogLevel.Warning, 'Testing this');
        logger.logWarning('Test');
        logger.logWarning(gslib_LogSeverity.Major, 'Test');
        logger.logWarning(gslib_LogSeverity.Major, 'test', new Account());
        System.assert(
                !gslib_LoggerService.appenderMapForDispatch.isEmpty(),
                'Should set appender based Supplied Module'
        );
        Test.startTest();
        logger.dispatch();
        System.assert(
                !gslib_LoggerService.appenderMapForDispatch.isEmpty(),
                'Dispatch should be called'
        );
        System.assert(
                gslib_LoggerService.thisLoggerConfig.cacheEnabled,
                'Should set cache from inner class'
        );
        System.assert(
                gslib_LoggerService.thisLoggerConfig.cacheFlushThreshold == 51428800,
                'Should set cacheFlushThreshold from inner class'
        );
        System.assert(
                !gslib_LoggerService.thisLoggerConfig.rootLoggerList.isEmpty(),
                'Should set rootLoggerList from inner class'
        );

        Test.stopTest();
    }

    @IsTest
    static void testSystemAppenderSuccess() {
        gslib_LoggerService.COMMONS_LOGGER_CONFIG = 'Samsara_AsyncDatabaseAppenderTest.CommonsLoggerConfigTestSystemAppender';
        gslib_IModuleLogger classLogger = gslib_LoggerService.getModuleLogger('Demo');
        gslib_ILogger logger = classLogger.getLogger('Demo');
        gslib_LoggerService.thisLoggerConfig = new CommonsLoggerConfigTestSystemAppender().getLoggerConfig();
        logger.log(gslib_LogLevel.Warning, 'Testing this');
        logger.logInfo('Test');
        logger.logError(gslib_LogSeverity.Major, 'Test');
        logger.logWarning(gslib_LogSeverity.Major, 'test', new Account());
        logger.logDebug( 'test', new Account());
        logger.logTrace('Trace');
        System.assert(
                !gslib_LoggerService.appenderMapForDispatch.isEmpty(),
                'Should set appender based Supplied Module'
        );
        Test.startTest();
        logger.dispatch();
        System.assert(
                !gslib_LoggerService.appenderMapForDispatch.isEmpty(),
                'Dispatch should be called'
        );
        System.assert(
                gslib_LoggerService.thisLoggerConfig.cacheEnabled,
                'Should set cache from inner class'
        );
        System.assert(
                gslib_LoggerService.thisLoggerConfig.cacheFlushThreshold == 51428800,
                'Should set cacheFlushThreshold from inner class'
        );
        System.assert(
                !gslib_LoggerService.thisLoggerConfig.rootLoggerList.isEmpty(),
                'Should set rootLoggerList from inner class'
        );

        Test.stopTest();
    }

    public class CommonsLoggerConfigAsyncAppenderTest implements gslib_ICommonsLoggerConfig {
        private  Integer CACHE_FLUSH_HEAP_THRESHOLD = 51428800;//52428800
        private  Boolean ENABLE_CACHE = true;
        public gslib_LoggerService.LoggerConfig getLoggerConfig() {
            gslib_LoggerService.LoggerConfigItem loggerConfigItem = new gslib_LoggerService.LoggerConfigItem('Samsara_AsyncDatabaseAppender', gslib_LogLevel.Trace);
            gslib_LoggerService.LoggerConfig loggerConfig = new gslib_LoggerService.LoggerConfig();
            loggerConfig.loggerAppenderMap.put('Demo.Demo', new List<gslib_LoggerService.LoggerConfigItem>{
                    loggerConfigItem
            });
            loggerConfig.rootLoggerList = new List<gslib_LoggerService.LoggerConfigItem>{
                    new gslib_LoggerService.LoggerConfigItem(
                            'Samsara_AsyncDatabaseAppender',
                            gslib_LogLevel.Trace
                    )
            };
            loggerConfig.cacheEnabled =  ENABLE_CACHE;
            loggerConfig.cacheFlushThreshold = CACHE_FLUSH_HEAP_THRESHOLD;
            return loggerConfig;
        }
    }


    public class CommonsLoggerConfigSyncDatabaseTest2 implements gslib_ICommonsLoggerConfig {
        private  Integer CACHE_FLUSH_HEAP_THRESHOLD = 51428800;//52428800
        private  Boolean ENABLE_CACHE = true;
        public gslib_LoggerService.LoggerConfig getLoggerConfig() {
            gslib_LoggerService.LoggerConfigItem loggerConfigItem = new gslib_LoggerService.LoggerConfigItem('Samsara_DatabaseAppender', gslib_LogLevel.Trace);
            gslib_LoggerService.LoggerConfig loggerConfig = new gslib_LoggerService.LoggerConfig();
            loggerConfig.loggerAppenderMap.put('Demo.Demo', new List<gslib_LoggerService.LoggerConfigItem>{
                    loggerConfigItem
            });
            loggerConfig.rootLoggerList = new List<gslib_LoggerService.LoggerConfigItem>{
                    new gslib_LoggerService.LoggerConfigItem(
                            'Samsara_DatabaseAppender',
                            gslib_LogLevel.Trace
                    )
            };
            loggerConfig.cacheEnabled =  ENABLE_CACHE;
            loggerConfig.cacheFlushThreshold = CACHE_FLUSH_HEAP_THRESHOLD;
            return loggerConfig;
        }
    }

    public class CommonsLoggerConfigTestSystemAppender implements gslib_ICommonsLoggerConfig {
        private  Integer CACHE_FLUSH_HEAP_THRESHOLD = 51428800;//52428800
        private  Boolean ENABLE_CACHE = true;
        public gslib_LoggerService.LoggerConfig getLoggerConfig() {
            gslib_LoggerService.LoggerConfigItem loggerConfigItem = new gslib_LoggerService.LoggerConfigItem('gslib_SystemAppender', gslib_LogLevel.Trace);
            gslib_LoggerService.LoggerConfig loggerConfig = new gslib_LoggerService.LoggerConfig();
            loggerConfig.loggerAppenderMap.put('Demo.Demo', new List<gslib_LoggerService.LoggerConfigItem>{
                    loggerConfigItem
            });
            loggerConfig.rootLoggerList = new List<gslib_LoggerService.LoggerConfigItem>{
                    new gslib_LoggerService.LoggerConfigItem(
                            'gslib_SystemAppender',
                            gslib_LogLevel.Trace
                    )
            };
            loggerConfig.cacheEnabled =  ENABLE_CACHE;
            loggerConfig.cacheFlushThreshold = CACHE_FLUSH_HEAP_THRESHOLD;
            return loggerConfig;
        }
    }
    @IsTest
    static void testSamsaraWrapperLoggerSuccess() {
        gslib_LoggerService.COMMONS_LOGGER_CONFIG = 'Samsara_AsyncDatabaseAppenderTest.CommonsLoggerConfigTest';
        gslib_IModuleLogger classLogger = gslib_LoggerService.getModuleLogger('Demo');
        gslib_ILogger logger = classLogger.getLogger('Demo');
        SamsaraLoggerService thisWrapperService = new SamsaraLoggerService();
        thisWrapperService.setModule('Demo');
        thisWrapperService.setSubModule('Demo');
        gslib_LoggerService.thisLoggerConfig = new CommonsLoggerConfigAsyncAppenderTest().getLoggerConfig();
        thisWrapperService.logger.log(gslib_LogLevel.Warning, 'Testing this');
        thisWrapperService.logger.logWarning('Test');
        thisWrapperService.logger.logWarning(gslib_LogSeverity.Major, 'Test');
        thisWrapperService.logger.logWarning(gslib_LogSeverity.Major, 'test', new Account());
        System.assert(
                !gslib_LoggerService.appenderMapForDispatch.isEmpty(),
                'Should set appender based Supplied Module'
        );
        Test.startTest();
        ProfilingUtility.startRecording('Test', ProfilingUtility.Resource.CPU_TIME);
        ProfilingUtility.startRecording('Test', ProfilingUtility.Resource.AGGREGATE_QUERIES);
        ProfilingUtility.startRecording('Test', ProfilingUtility.Resource.ASYNC_CALLS);
        ProfilingUtility.startRecording('Test', ProfilingUtility.Resource.DML_STATEMENTS);
        ProfilingUtility.startRecording('Test', ProfilingUtility.Resource.CALLOUTS);
        ProfilingUtility.startRecording('Test', ProfilingUtility.Resource.HEAP_SIZE);
        ProfilingUtility.startRecording('Test', ProfilingUtility.Resource.MOBILE_PUSH_CALLS);
        ProfilingUtility.startRecording('Test', ProfilingUtility.Resource.QUERY_LOCATOR_ROWS);
        ProfilingUtility.startRecording('Test', ProfilingUtility.Resource.QUEUEABLE_JOBS);
        ProfilingUtility.startRecording('Test', ProfilingUtility.Resource.QUERY_ROWS);
        ProfilingUtility.startRecording('Test', ProfilingUtility.Resource.QUERIES);
        ProfilingUtility.startRecording('Test', ProfilingUtility.Resource.SOSL_QUERIES);

        logger.dispatch();
        System.assert(
                !gslib_LoggerService.appenderMapForDispatch.isEmpty(),
                'Dispatch should be called'
        );
        System.assert(
                gslib_LoggerService.thisLoggerConfig.cacheEnabled,
                'Should set cache from inner class'
        );
        System.assert(
                gslib_LoggerService.thisLoggerConfig.cacheFlushThreshold == 51428800,
                'Should set cacheFlushThreshold from inner class'
        );
        System.assert(
                !gslib_LoggerService.thisLoggerConfig.rootLoggerList.isEmpty(),
                'Should set rootLoggerList from inner class'
        );
        ProfilingUtility.stopRecording('Test', ProfilingUtility.Resource.CPU_TIME);
        Test.stopTest();
    }

    @IsTest
    static void testSamsaraWrapperLoggerNOModuleSuccess() {
        gslib_LoggerService.COMMONS_LOGGER_CONFIG = 'Samsara_AsyncDatabaseAppenderTest.CommonsLoggerConfigTest';
        gslib_IModuleLogger classLogger = gslib_LoggerService.getModuleLogger('Demo');
        gslib_ILogger logger = classLogger.getLogger('Demo');
        SamsaraLoggerService thisWrapperService = new SamsaraLoggerService();
        thisWrapperService.setSubModule('Demo');
        gslib_LoggerService.thisLoggerConfig = new CommonsLoggerConfigAsyncAppenderTest().getLoggerConfig();
        thisWrapperService.logger.log(gslib_LogLevel.Warning, 'Testing this');
        thisWrapperService.logger.logWarning('Test');
        thisWrapperService.logger.logWarning(gslib_LogSeverity.Major, 'Test');
        thisWrapperService.logger.logWarning(gslib_LogSeverity.Major, 'test', new Account());
        System.assert(
                !gslib_LoggerService.appenderMapForDispatch.isEmpty(),
                'Should set appender based Supplied Module'
        );
        Test.startTest();
        ProfilingUtility.startRecording('Test', ProfilingUtility.Resource.CPU_TIME);
        logger.dispatch();
        System.assert(
                !gslib_LoggerService.appenderMapForDispatch.isEmpty(),
                'Dispatch should be called'
        );
        System.assert(
                gslib_LoggerService.thisLoggerConfig.cacheEnabled,
                'Should set cache from inner class'
        );
        System.assert(
                gslib_LoggerService.thisLoggerConfig.cacheFlushThreshold == 51428800,
                'Should set cacheFlushThreshold from inner class'
        );
        System.assert(
                !gslib_LoggerService.thisLoggerConfig.rootLoggerList.isEmpty(),
                'Should set rootLoggerList from inner class'
        );
        ProfilingUtility.stopRecording('Test', ProfilingUtility.Resource.CPU_TIME);
        Test.stopTest();
    }
}