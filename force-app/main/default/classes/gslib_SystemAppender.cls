/**
 * Created by vikasmishra on 2021-02-09.
 */

public with sharing class gslib_SystemAppender implements gslib_ILoggerAppender {

    public void log(gslib_Log thisLog, Object obj) {
        System.debug(getLoggingLevel(thisLog.logLevel), thisLog.message);
    }

    public void dispatch() {

    }

    /**
     * @description Maps the Logger LogLevel to System.LoggingLevel.
     * @param level The log level to be mapped.
     * @return The mapped System.LoggingLevel.
     */
    private System.LoggingLevel getLoggingLevel(gslib_LogLevel level) {
        if (level == gslib_LogLevel.Error) {
            return System.LoggingLevel.ERROR;
        }
        if (level == gslib_LogLevel.Warning) {
            return System.LoggingLevel.WARN;
        }
        if (level == gslib_LogLevel.Info) {
            return System.LoggingLevel.INFO;
        }
        if (level == gslib_LogLevel.Debug) {
            return System.LoggingLevel.DEBUG;
        }
        if (level == gslib_LogLevel.Trace) {
            return System.LoggingLevel.FINE;
        }
        return System.LoggingLevel.NONE;
    }


}