/**
 * Created by vikasmishra on 2021-02-08.
 */

public interface gslib_IModuleLogger {

    gslib_ILogger getLogger(String moduleName);
    gslib_ILogger getLogger();
}