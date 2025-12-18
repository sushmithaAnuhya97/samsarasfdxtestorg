/**
 * Created by vikasmishra on 2021-02-08.
 */

public without sharing class gslib_LoggerService implements gslib_ILogger, gslib_IModuleLogger {

    private static final String CLASSNAME = gslib_LoggerService.class.getName();
    private static final Pattern STACK_LINE = Pattern.compile('^(?:Class\\.)?([^.]+)\\.?([^\\.\\:]+)?[\\.\\:]?([^\\.\\:]*): line (\\d+), column (\\d+)$');
    private static final String ORG_NAMESPACE = [SELECT NamespacePrefix FROM Organization].NamespacePrefix;
    @TestVisible
    private gslib_Log thisLog = new gslib_Log();

    public static gslib_IModuleLogger getModuleLogger() {
        return getModuleLogger('');
    }

    public static gslib_IModuleLogger getModuleLogger(String moduleName) {
        return new gslib_LoggerService(moduleName);
    }

    /**
     * @return gslib_ILogger
     */
    public gslib_ILogger getLogger() {
        return getLogger('');
    }
    /**
     * @param moduleKey :
     *
     * @return gslib_ILogger
     */
    public gslib_ILogger getLogger(String moduleKey) {
        gslib_LoggerService thisModuleLogger = new gslib_LoggerService(this.moduleName, moduleKey);
        //thisModuleLogger.generateLocation();
        return thisModuleLogger;
    }

    // Developer has to create this class implementing gslib_ICommonsLoggerConfig
    // if not exist we will call system appender
    @TestVisible
    private static String COMMONS_LOGGER_CONFIG = 'CommonsLoggerConfig';
    @TestVisible
    private String moduleName ;
    @TestVisible
    private String moduleKey;

    /**
     * @param thisModuleName:
     */
    private gslib_LoggerService(String thisModuleName) {
        this.moduleName = thisModuleName;
    }
    /**
     * @param thisModuleName:
     * @param thisModuleKey:
     */
    private gslib_LoggerService(String thisModuleName, String thisModuleKey) {
        this.moduleName = thisModuleName;
        this.moduleKey = thisModuleKey;
    }

    private gslib_LoggerService() {

    }
    /**
     *
     */
    @TestVisible
    private static gslib_LoggerService.LoggerConfig thisLoggerConfig ;

    @TestVisible
    private static Map<String, gslib_ILoggerAppender> appenderMapForDispatch = new Map<String, gslib_ILoggerAppender>();


    static {
        getConfigurationInformation();
    }
    /**
     *
     */
    @TestVisible
    private static void getConfigurationInformation() {
        Type thisType = Type.forName(COMMONS_LOGGER_CONFIG);
        if (thisType == null) {
            thisLoggerConfig = new LoggerConfig();
            thisLoggerConfig.rootLoggerList.add(gslib_LoggerService.createLoggerConfigItem('gslib_SystemAppender', gslib_LogLevel.Trace));
            return;
        }
        gslib_ICommonsLoggerConfig thisCommonConfig = (gslib_ICommonsLoggerConfig) thisType.newInstance();
        thisLoggerConfig = thisCommonConfig.getLoggerConfig();
        if(thisLoggerConfig.rootLoggerList.isEmpty()){
            thisLoggerConfig.rootLoggerList.add(
                    gslib_LoggerService.createLoggerConfigItem(
                            'gslib_SystemAppender',
                            gslib_LogLevel.Trace
                    )
            );
        }

    }

    /**
     * @description : This method will be used to call dispatch method from configured Appender
     */
    public void dispatch() {
        dispatchAllAppender();
    }

    /**
     * @description : Supporting method to invoke gslib_ILoggerAppender.dispatch()
     */
    private void dispatchAllAppender() {
        for (gslib_ILoggerAppender thisAppender : appenderMapForDispatch.values()) {
            thisAppender.dispatch();
        }
    }
    /* public gslib_ILogger getLogger(String methodName) {
     return null;
 }*/
    /**
     * @param logLevel:
     * @param message:
     */
    public void log(gslib_LogLevel logLevel, String message) {
        log(logLevel, message, null);
    }
    /**
     * @param logLevel:
     * @param message:
     * @param obj:
     */
    public void log(gslib_LogLevel logLevel, String message, Object obj) {
        log(logLevel, null, message, obj);
    }
    /**
     * @param logLevel:
     * @param severity:
     * @param message:
     */
    public void log(gslib_LogLevel logLevel, gslib_LogSeverity severity, String message) {
        log(logLevel, severity, message, null);
    }
    /**
     * @param logLevel:
     * @param severity:
     * @param message:
     * @param obj:
     */
    public void log(gslib_LogLevel logLevel, gslib_LogSeverity severity, String message, Object obj) {
        thisLog = setLogInstance(logLevel, severity, message);
        if(thisLoggerConfig.cacheEnabled &&  thisLoggerConfig.cacheFlushThreshold < Limits.getHeapSize()){
            this.autoFlush();
        }
        if (!thisLoggerConfig.loggerAppenderMap.isEmpty()) {
            if (thisLoggerConfig.loggerAppenderMap.containsKey(this.moduleName + '.' + this.moduleKey)) {
                log(thisLog, obj, thisLoggerConfig.loggerAppenderMap.get(this.moduleName + '.' + this.moduleKey));
            } else if (String.isBlank(this.moduleKey) && thisLoggerConfig.loggerAppenderMap.containsKey(this.moduleName)) {
                log(thisLog, obj, thisLoggerConfig.loggerAppenderMap.get(this.moduleName));

            }
            else{
                log(thisLog, obj, thisLoggerConfig.rootLoggerList);
            }
        } else if (!thisLoggerConfig.rootLoggerList.isEmpty()) {
            log(thisLog, obj, thisLoggerConfig.rootLoggerList);
        }

    }

    private void autoFlush() {
        this.dispatchAllAppender();
    }

    private void log(gslib_Log thisLog, Object thisObj, List<LoggerConfigItem> listLogConfigItem) {
        for (LoggerConfigItem thisItem : listLogConfigItem) {
            logToAppender(thisLog, thisObj, thisItem);
        }
    }

    private void generateLocation() {
        thisLog = new gslib_Log();
        List<String> stacktrace = new DmlException().getStackTraceString().split('\n');

        for(String line : stacktrace) {
            Matcher matcher = STACK_LINE.matcher(line);

            if(matcher.find() && !line.startsWith('Class.' + CLASSNAME + '.')) {
                Boolean hasNamespace = String.isNotBlank(matcher.group(3));
                if(hasNamespace) {
                    thisLog.className = (matcher.group(1).equals(ORG_NAMESPACE)) ? matcher.group(2) : matcher.group(1) + '.' + matcher.group(2);
                    thisLog.method = prettyMethod(matcher.group(3));
                }
                else {
                    thisLog.className = matcher.group(1);
                    thisLog.method = prettyMethod(matcher.group(2));
                }
                return;
            }
        }
    }

    private static String prettyMethod(String method) {
        String result = (method == null) ? 'anonymous' : method;
        return (result.contains('init')) ? 'ctor' : result;
    }

    private gslib_Log setLogInstance(gslib_LogLevel logLevel, gslib_LogSeverity severity, String message) {
        this.generateLocation();
        thisLog.logLevel = logLevel != null ? logLevel : gslib_LogLevel.Trace;
        thisLog.severity = severity;
        thisLog.message = message;
        thisLog.contextUser = UserInfo.getUserId();
        // Automated User, it does not have session ID and Email Address
        thisLog.sessionKey = UserInfo.getSessionId() == null ?'Automated User' :EncodingUtil.base64Encode(Blob.valueOf(UserInfo.getSessionId()));
        thisLog.timeStamp = System.now();
        thisLog.type = logLevel != null ? logLevel.name() : gslib_LogLevel.Trace.name();
        return thisLog;

    }

    /**
     * @param gslibLog:
     * @param thisObj;
     * @param thisConfigItem:
     */
    private void logToAppender(gslib_Log gslibLog, Object thisObj, LoggerConfigItem thisConfigItem) {

        if(!appenderMapForDispatch.containsKey(thisConfigItem.appenderClassName)){
            Type thisType = Type.forName(thisConfigItem.appenderClassName);
            if (thisType != null) {
                gslib_ILoggerAppender thisAppender = (gslib_ILoggerAppender) thisType.newInstance();
                appenderMapForDispatch.put(thisConfigItem.appenderClassName, thisAppender);
            }
        }


        if (thisConfigItem.logLevel.ordinal() <= gslibLog.logLevel.ordinal()) {
            if(appenderMapForDispatch.containsKey(thisConfigItem.appenderClassName)){
                appenderMapForDispatch.get(thisConfigItem.appenderClassName).log(gslibLog, thisObj);
            }

        }


    }

    /**
 * @param message:
 */
    public void logTrace(String message) {
        logTrace(message, null);
    }
    /**
     * @param message:
     * @param obj:
     */
    public void logTrace(String message, Object obj) {
        log(gslib_LogLevel.Trace, null, message, obj);
    }
    /**
     * @param message:
     */
    public void logDebug(String message) {
        logDebug(message, null);
    }
    /**
     * @param message:
     * @param obj:
     */
    public void logDebug(String message, Object obj) {
        log(gslib_LogLevel.Debug, null, message, obj);
    }
    /**
     * @param message:
     */
    public void logInfo(String message) {
        logInfo(message, null);
    }
    /**
     * @param message:
     * @param obj:
     */
    public void logInfo(String message, Object obj) {
        log(gslib_LogLevel.Info, null, message, obj);
    }
    /**
     * @param message:
     */
    public void logWarning(String message) {
        logWarning(null, message, null);
    }
    /**
     * @param message:
     * @param obj:
     */
    public void logWarning(String message, Object obj) {
        logWarning(null, message, obj);
    }
    /**
     * @param severity:
     * @param message:
     */
    public void logWarning(gslib_LogSeverity severity, String message) {
        logWarning(severity, message, null);
    }
    /**
     * @param severity:
     * @param message:
     * @param obj:
     */
    public void logWarning(gslib_LogSeverity severity, String message, Object obj) {
        log(gslib_LogLevel.Warning, severity, message, obj);
    }
    /**
     * @param message:
     */
    public void logError(String message) {
        logError(null, message, null);
    }
    /**
     * @param message:
     * @param obj:
     */
    public void logError(String message, Object obj) {
        logError(null, message, obj);
    }
    /**
     * @param severity:
     * @param message:
     */
    public void logError(gslib_LogSeverity severity, String message) {
        logError(severity, message, null);
    }
    /**
     * @param severity:
     * @param message:
     * @param obj:
     */
    public void logError(gslib_LogSeverity severity, String message, Object obj) {
        log(gslib_LogLevel.Error, severity, message, obj);
    }

    /**
     * @param className:
     *@param loglevel:
     * @return:
     */
    private static LoggerConfigItem createLoggerConfigItem(String className, gslib_LogLevel loglevel) {
        LoggerConfigItem thisConfig = new LoggerConfigItem(className, loglevel);
        return thisConfig;
    }

    /**
     *
     */
    public class LoggerConfig {

        public List<LoggerConfigItem> rootLoggerList { get; set; }

        public Map<String, List<LoggerConfigItem>> loggerAppenderMap { get; set; }
        public Boolean cacheEnabled { get; set; }
        public Integer cacheFlushThreshold { get; set; }

        public LoggerConfig() {
            rootLoggerList = new List<LoggerConfigItem>();
            loggerAppenderMap = new Map<String, List<LoggerConfigItem>>();
            cacheEnabled = false;
            cacheFlushThreshold = 0;
        }

    }
    /**
     *
     */
    public class LoggerConfigItem {
        public String appenderClassName { get; private set; }
        public gslib_LogLevel logLevel { get; private set; }

        public LoggerConfigItem(String thisAppenderClassName, gslib_LogLevel thisLogLevel) {
            this.appenderClassName = thisAppenderClassName;
            this.logLevel = thisLogLevel;
        }

    }
}