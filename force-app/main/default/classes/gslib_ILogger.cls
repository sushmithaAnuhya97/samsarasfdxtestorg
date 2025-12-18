/**
 * Created by vikasmishra on 2021-02-08.
 */

public interface gslib_ILogger {

    void log(gslib_LogLevel logLevel, String message);
    void log(gslib_LogLevel logLevel, String message, Object obj);
    void log(gslib_LogLevel logLevel, gslib_LogSeverity severity, String message);
    void log(gslib_LogLevel logLevel, gslib_LogSeverity severity, String message, Object obj);

    void logTrace(String message);
    void logTrace(String message, Object obj);

    void logDebug(String message);
    void logDebug(String message, Object obj);

    void logInfo(String message);
    void logInfo(String message, Object obj);

    void logWarning(String message);
    void logWarning(String message, Object obj);
    void logWarning(gslib_LogSeverity severity, String message);
    void logWarning(gslib_LogSeverity severity, String message, Object obj);

    void logError(String message);
    void logError(String message, Object obj);
    void logError(gslib_LogSeverity severity, String message);
    void logError(gslib_LogSeverity severity, String message, Object obj);
    void dispatch();
}