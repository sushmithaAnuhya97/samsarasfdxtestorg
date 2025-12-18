/**
 * Created by vikasmishra on 2021-03-30.
 */

@IsTest
private class gslib_LoggerService_Tests {

    @IsTest
    static void testConfiguration() {
        gslib_LoggerService.COMMONS_LOGGER_CONFIG = 'gslib_LoggerService_Tests.CommonsLoggerConfigTest';
        gslib_IModuleLogger classLogger = gslib_LoggerService.getModuleLogger('Demo');
        gslib_ILogger logger = classLogger.getLogger('Demo');
        gslib_LoggerService.thisLoggerConfig = new CommonsLoggerConfigTest().getLoggerConfig();
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
        System.assert(
                !gslib_LoggerService.thisLoggerConfig.loggerAppenderMap.isEmpty(),
                'Should set rootLoggerList from inner class'
        );
        
    }

    @IsTest
    static void testRootConfiguration() {
        gslib_LoggerService.COMMONS_LOGGER_CONFIG = 'RandomRootTest';
        gslib_IModuleLogger classLogger = gslib_LoggerService.getModuleLogger('Demo');
        gslib_ILogger logger = classLogger.getLogger('Demo');
        gslib_LoggerService.getConfigurationInformation();
        System.assert(
                !gslib_LoggerService.thisLoggerConfig.rootLoggerList.isEmpty(),
                'Should set rootLoggerList from inner class'
        );
        System.assert(
                gslib_LoggerService.thisLoggerConfig.loggerAppenderMap.isEmpty(),
                'Should set rootLoggerList from inner class'
        );
        System.debug('Configuration ++++' + gslib_LoggerService.thisLoggerConfig);
    }

    @IsTest
    static void testRootConfiguration2() {
        gslib_LoggerService.COMMONS_LOGGER_CONFIG = 'gslib_LoggerService_Tests.CommonsLoggerConfigTest2';
        gslib_IModuleLogger classLogger = gslib_LoggerService.getModuleLogger();
        gslib_ILogger logger = classLogger.getLogger();
        gslib_LoggerService.getConfigurationInformation();
        System.assert(
                !gslib_LoggerService.thisLoggerConfig.rootLoggerList.isEmpty(),
                'Should set rootLoggerList from inner class'
        );
    }

    @IsTest
    static void testLogWarning() {
        gslib_IModuleLogger classLogger = gslib_LoggerService.getModuleLogger('Demo');
        gslib_ILogger logger = classLogger.getLogger('Demo');
        gslib_LoggerService.thisLoggerConfig = new CommonsLoggerConfigTest().getLoggerConfig();
        logger.log(gslib_LogLevel.Warning, 'Testing this');
        logger.logWarning('Test');
        logger.logWarning(gslib_LogSeverity.Major, 'Test');
        logger.logWarning(gslib_LogSeverity.Major, 'test', new Account());
        System.assert(
                !gslib_LoggerService.appenderMapForDispatch.isEmpty(),
                'Should set appender based Supplied Module'
        );
    }

    @IsTest
    static void testLogTrace() {
        gslib_IModuleLogger classLogger = gslib_LoggerService.getModuleLogger('Demo');
        gslib_ILogger logger = classLogger.getLogger('Demo');
        gslib_LoggerService.thisLoggerConfig = new CommonsLoggerConfigTest().getLoggerConfig();
        logger.log(gslib_LogLevel.Trace, 'Testing this');
        logger.logTrace('Test');
        logger.logTrace('Testing', new List<Account>());
        System.assert(
                ((gslib_LoggerService_Tests.DemoAppender)gslib_LoggerService.appenderMapForDispatch.get('gslib_LoggerService_Tests.DemoAppender')).logList.size() == 3,
                'Should set log based on Supplied Module'
        );
        System.assert(
                ((gslib_LoggerService_Tests.DemoAppender)gslib_LoggerService.appenderMapForDispatch.get('gslib_LoggerService_Tests.DemoAppender')).logList[0].logLevel == gslib_LogLevel.Trace,
                'Should equal to trace'
        );
    }

    @IsTest
    static void testLogDebug() {
        gslib_IModuleLogger classLogger = gslib_LoggerService.getModuleLogger('Demo');
        gslib_ILogger logger = classLogger.getLogger('Demo');
        gslib_LoggerService.thisLoggerConfig = new CommonsLoggerConfigTest().getLoggerConfig();
        logger.log(gslib_LogLevel.Debug, 'Testing this');
        logger.logDebug('Test');
        logger.logDebug('Testing', new List<Account>());
        System.assert(
                ((gslib_LoggerService_Tests.DemoAppender)gslib_LoggerService.appenderMapForDispatch.get('gslib_LoggerService_Tests.DemoAppender')).logList.size() == 3,
                'Should set log based on Supplied Module'
        );
        System.assert(
                ((gslib_LoggerService_Tests.DemoAppender)gslib_LoggerService.appenderMapForDispatch.get('gslib_LoggerService_Tests.DemoAppender')).logList[0].logLevel == gslib_LogLevel.Debug,
                'Should equal to debug'
        );
    }

    @IsTest
    static void testLogWarning2() {
        gslib_IModuleLogger classLogger = gslib_LoggerService.getModuleLogger('Demo');
        gslib_ILogger logger = classLogger.getLogger('Demo');
        gslib_LoggerService.thisLoggerConfig = new CommonsLoggerConfigTest().getLoggerConfig();
        logger.log(gslib_LogLevel.Warning, 'Testing this');
        logger.logWarning('Test');
        logger.logWarning('Testing', new List<Account>());
        System.assert(
                ((gslib_LoggerService_Tests.DemoAppender)gslib_LoggerService.appenderMapForDispatch.get('gslib_LoggerService_Tests.DemoAppender')).logList.size() == 3,
                'Should set log based on Supplied Module'
        );
        System.assert(
                ((gslib_LoggerService_Tests.DemoAppender)gslib_LoggerService.appenderMapForDispatch.get('gslib_LoggerService_Tests.DemoAppender')).logList[0].logLevel == gslib_LogLevel.Warning,
                'Should equal to Warning'
        );
    }

    @IsTest
    static void testLogInfo() {
        gslib_IModuleLogger classLogger = gslib_LoggerService.getModuleLogger('Demo');
        gslib_ILogger logger = classLogger.getLogger('Demo');
        gslib_LoggerService.thisLoggerConfig = new CommonsLoggerConfigTest().getLoggerConfig();
        logger.log(gslib_LogLevel.Info, 'Testing this');
        logger.logInfo('Test');
        logger.logInfo('Testing', new List<Account>());
        System.assert(
                ((gslib_LoggerService_Tests.DemoAppender)gslib_LoggerService.appenderMapForDispatch.get('gslib_LoggerService_Tests.DemoAppender')).logList.size() == 3,
                'Should set log based on Supplied Module'
        );
        System.assert(
                ((gslib_LoggerService_Tests.DemoAppender)gslib_LoggerService.appenderMapForDispatch.get('gslib_LoggerService_Tests.DemoAppender')).logList[0].logLevel == gslib_LogLevel.Info,
                'Should equal to Info'
        );
    }

    @IsTest
    static void testLogError() {
        gslib_IModuleLogger classLogger = gslib_LoggerService.getModuleLogger('Demo');
        gslib_ILogger logger = classLogger.getLogger('Demo');
        gslib_LoggerService.thisLoggerConfig = new CommonsLoggerConfigTest().getLoggerConfig();
        logger.log(gslib_LogLevel.Error, 'Testing this');
        logger.logError('Test');
        logger.logError('Testing', new List<Account>());
        System.assert(
                ((gslib_LoggerService_Tests.DemoAppender)gslib_LoggerService.appenderMapForDispatch.get('gslib_LoggerService_Tests.DemoAppender')).logList.size() == 3,
                'Should set log based on Supplied Module'
        );
        System.assert(
                ((gslib_LoggerService_Tests.DemoAppender)gslib_LoggerService.appenderMapForDispatch.get('gslib_LoggerService_Tests.DemoAppender')).logList[0].logLevel == gslib_LogLevel.Error,
                'Should equal to Error'
        );
    }

    @IsTest
    static void testLogWarningDispatch() {
        gslib_IModuleLogger classLogger = gslib_LoggerService.getModuleLogger('Demo');
        gslib_ILogger logger = classLogger.getLogger('Demo');
        gslib_LoggerService.thisLoggerConfig = new CommonsLoggerConfigTest().getLoggerConfig();
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
                ((gslib_LoggerService_Tests.DemoAppender)gslib_LoggerService.appenderMapForDispatch.get('gslib_LoggerService_Tests.DemoAppender')).dispatchCalled,
                'Dispatch should be called'
        );
        Test.stopTest();
    }

    @IsTest
    static void testLogTraceWithDispatch() {
        gslib_IModuleLogger classLogger = gslib_LoggerService.getModuleLogger('Demo');
        gslib_ILogger logger = classLogger.getLogger('Demo');
        gslib_LoggerService.thisLoggerConfig = new CommonsLoggerConfigTest().getLoggerConfig();
        logger.log(gslib_LogLevel.Trace, 'Testing this');
        logger.logTrace('Test');
        logger.logTrace('Testing', new List<Account>());
        System.assert(
                ((gslib_LoggerService_Tests.DemoAppender)gslib_LoggerService.appenderMapForDispatch.get('gslib_LoggerService_Tests.DemoAppender')).logList.size() == 3,
                'Should set log based on Supplied Module'
        );
        System.assert(
                ((gslib_LoggerService_Tests.DemoAppender)gslib_LoggerService.appenderMapForDispatch.get('gslib_LoggerService_Tests.DemoAppender')).logList[0].logLevel == gslib_LogLevel.Trace,
                'Should equal to trace'
        );
        Test.startTest();
        logger.dispatch();
        System.assert(
                ((gslib_LoggerService_Tests.DemoAppender)gslib_LoggerService.appenderMapForDispatch.get('gslib_LoggerService_Tests.DemoAppender')).dispatchCalled,
                'Dispatch should be called'
        );
        Test.stopTest();
    }

    @IsTest
    static void testLogDebugWithDispatch() {
        gslib_IModuleLogger classLogger = gslib_LoggerService.getModuleLogger('Demo');
        gslib_ILogger logger = classLogger.getLogger('Demo');
        gslib_LoggerService.thisLoggerConfig = new CommonsLoggerConfigTest().getLoggerConfig();
        logger.log(gslib_LogLevel.Debug, 'Testing this');
        logger.logDebug('Test');
        logger.logDebug('Testing', new List<Account>());
        System.assert(
                ((gslib_LoggerService_Tests.DemoAppender)gslib_LoggerService.appenderMapForDispatch.get('gslib_LoggerService_Tests.DemoAppender')).logList.size() == 3,
                'Should set log based on Supplied Module'
        );
        System.assert(
                ((gslib_LoggerService_Tests.DemoAppender)gslib_LoggerService.appenderMapForDispatch.get('gslib_LoggerService_Tests.DemoAppender')).logList[0].logLevel == gslib_LogLevel.Debug,
                'Should equal to debug'
        );
        Test.startTest();
        logger.dispatch();
        System.assert(
                ((gslib_LoggerService_Tests.DemoAppender)gslib_LoggerService.appenderMapForDispatch.get('gslib_LoggerService_Tests.DemoAppender')).dispatchCalled,
                'Dispatch should be called'
        );
        Test.stopTest();
    }

    @IsTest
    static void testLogWarning2WithDispatch() {
        gslib_IModuleLogger classLogger = gslib_LoggerService.getModuleLogger('Demo');
        gslib_ILogger logger = classLogger.getLogger('Demo');
        gslib_LoggerService.thisLoggerConfig = new CommonsLoggerConfigTest().getLoggerConfig();
        logger.log(gslib_LogLevel.Warning, 'Testing this');
        logger.logWarning('Test');
        logger.logWarning('Testing', new List<Account>());
        System.assert(
                ((gslib_LoggerService_Tests.DemoAppender)gslib_LoggerService.appenderMapForDispatch.get('gslib_LoggerService_Tests.DemoAppender')).logList.size() == 3,
                'Should set log based on Supplied Module'
        );
        System.assert(
                ((gslib_LoggerService_Tests.DemoAppender)gslib_LoggerService.appenderMapForDispatch.get('gslib_LoggerService_Tests.DemoAppender')).logList[0].logLevel == gslib_LogLevel.Warning,
                'Should equal to Warning'
        );
        Test.startTest();
        logger.dispatch();
        System.assert(
                ((gslib_LoggerService_Tests.DemoAppender)gslib_LoggerService.appenderMapForDispatch.get('gslib_LoggerService_Tests.DemoAppender')).dispatchCalled,
                'Dispatch should be called'
        );
        Test.stopTest();
    }

    @IsTest
    static void testLogInfoWithDispatch() {
        gslib_IModuleLogger classLogger = gslib_LoggerService.getModuleLogger('Demo');
        gslib_ILogger logger = classLogger.getLogger('Demo');
        gslib_LoggerService.thisLoggerConfig = new CommonsLoggerConfigTest().getLoggerConfig();
        logger.log(gslib_LogLevel.Info, 'Testing this');
        logger.logInfo('Test');
        logger.logInfo('Testing', new List<Account>());
        System.assert(
                ((gslib_LoggerService_Tests.DemoAppender)gslib_LoggerService.appenderMapForDispatch.get('gslib_LoggerService_Tests.DemoAppender')).logList.size() == 3,
                'Should set log based on Supplied Module'
        );
        System.assert(
                ((gslib_LoggerService_Tests.DemoAppender)gslib_LoggerService.appenderMapForDispatch.get('gslib_LoggerService_Tests.DemoAppender')).logList[0].logLevel == gslib_LogLevel.Info,
                'Should equal to Info'
        );
        Test.startTest();
        logger.dispatch();
        System.assert(
                ((gslib_LoggerService_Tests.DemoAppender)gslib_LoggerService.appenderMapForDispatch.get('gslib_LoggerService_Tests.DemoAppender')).dispatchCalled,
                'Dispatch should be called'
        );
        Test.stopTest();
    }

    @IsTest
    static void testLogErrorWithDispatch() {
        gslib_IModuleLogger classLogger = gslib_LoggerService.getModuleLogger('Demo');
        gslib_ILogger logger = classLogger.getLogger('Demo');
        gslib_LoggerService.thisLoggerConfig = new CommonsLoggerConfigTest().getLoggerConfig();
        logger.log(gslib_LogLevel.Error, 'Testing this');
        logger.logError('Test');
        logger.logError('Testing', new List<Account>());
        System.assert(
                ((gslib_LoggerService_Tests.DemoAppender)gslib_LoggerService.appenderMapForDispatch.get('gslib_LoggerService_Tests.DemoAppender')).logList.size() == 3,
                'Should set log based on Supplied Module'
        );
        System.assert(
                ((gslib_LoggerService_Tests.DemoAppender)gslib_LoggerService.appenderMapForDispatch.get('gslib_LoggerService_Tests.DemoAppender')).logList[0].logLevel == gslib_LogLevel.Error,
                'Should equal to Error'
        );
        Test.startTest();
        logger.dispatch();
        System.assert(
                ((gslib_LoggerService_Tests.DemoAppender)gslib_LoggerService.appenderMapForDispatch.get('gslib_LoggerService_Tests.DemoAppender')).dispatchCalled,
                'Dispatch should be called'
        );
        Test.stopTest();
    }

    public class CommonsLoggerConfigTest implements gslib_ICommonsLoggerConfig {
        private  Integer CACHE_FLUSH_HEAP_THRESHOLD = 51428800;//52428800
        private  Boolean ENABLE_CACHE = true;
        public gslib_LoggerService.LoggerConfig getLoggerConfig() {
            gslib_LoggerService.LoggerConfigItem loggerConfigItem = new gslib_LoggerService.LoggerConfigItem('gslib_LoggerService_Tests.DemoAppender', gslib_LogLevel.Trace);
            gslib_LoggerService.LoggerConfig loggerConfig = new gslib_LoggerService.LoggerConfig();
            loggerConfig.loggerAppenderMap.put('Demo.Demo', new List<gslib_LoggerService.LoggerConfigItem>{
                loggerConfigItem
            });
            loggerConfig.rootLoggerList = new List<gslib_LoggerService.LoggerConfigItem>{
                    new gslib_LoggerService.LoggerConfigItem(
                            'gslib_LoggerService_Tests.DemoAppender',
                            gslib_LogLevel.Trace
                    )
            };
            loggerConfig.cacheEnabled =  ENABLE_CACHE;
            loggerConfig.cacheFlushThreshold = CACHE_FLUSH_HEAP_THRESHOLD;
            return loggerConfig;
        }
    }

    public class CommonsLoggerConfigTest2 implements gslib_ICommonsLoggerConfig {
        private  Integer CACHE_FLUSH_HEAP_THRESHOLD = 51428800;//52428800
        private  Boolean ENABLE_CACHE = true;
        public gslib_LoggerService.LoggerConfig getLoggerConfig() {
            gslib_LoggerService.LoggerConfigItem loggerConfigItem = new gslib_LoggerService.LoggerConfigItem('gslib_LoggerService_Tests.DemoAppender', gslib_LogLevel.Trace);
            gslib_LoggerService.LoggerConfig loggerConfig = new gslib_LoggerService.LoggerConfig();
            loggerConfig.cacheEnabled =  ENABLE_CACHE;
            loggerConfig.cacheFlushThreshold = CACHE_FLUSH_HEAP_THRESHOLD;
            return loggerConfig;
        }
    }

    public class DemoAppender implements gslib_ILoggerAppender {
        public List<gslib_Log> logList = new List<gslib_Log>();
        public Boolean dispatchCalled = false;
        public Boolean logCalled = false;
        public void log(gslib_Log log, Object obj) {
            logList.add(log);
            System.debug('log====>' + log);
            logCalled = true;
        }
        public void dispatch() {
            dispatchCalled = true;
        }
    }
}