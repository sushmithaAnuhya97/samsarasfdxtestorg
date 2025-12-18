/**
 * Created by vikasmishra on 2021-02-08.
 */
//TODO: caching

public interface gslib_ILoggerAppender {

    void log(gslib_Log log, Object obj); // Developer need to cache the logs to perform DMLS or fire platform event or make Https if necessary
    void dispatch();
}