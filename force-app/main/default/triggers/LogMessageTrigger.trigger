trigger LogMessageTrigger on Log_Message__e(after insert) {
  LoggerUtils.write(Trigger.New);
}