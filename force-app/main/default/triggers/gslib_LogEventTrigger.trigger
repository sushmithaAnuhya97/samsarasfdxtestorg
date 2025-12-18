trigger gslib_LogEventTrigger on gslib_Log__e (after insert) {
    new gslib_LogTriggerHandler().run();
}