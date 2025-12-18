/**
 * @group Logger
 * @description Exposes an InvocableMethod to log errors from flow
 */
public without sharing class FlowErrorLogger {
  /**
   * @description Create log during Flow execution
   */
  @InvocableMethod(
    category='Logger'
    label='Save Log'
    description='Saves any log entries that have been generated'
  )
  public static void logError() {
    Logger.insertMasterLogs();
  }
}