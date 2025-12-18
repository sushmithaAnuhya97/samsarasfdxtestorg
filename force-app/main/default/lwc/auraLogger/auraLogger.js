import { LightningElement, api } from "lwc";
import { Logger } from "c/lwcLogger";

export default class AuraLogger extends LightningElement {
  @api recordId;
  @api functionalityType;
  @api functionalitySubType;
  isReadyEventFired = false;

  /**
   * Logger for Aura Component
   * Once this logger component is loaded, it will return onready event
   * in the main Aura component, init method needs to be called onready event.
   */
  renderedCallback() {
    if (!this.isReadyEventFired) {
      this.handleUncaughtErrors();
      this.dispatchEvent(new CustomEvent("ready"));
      this.isReadyEventFired = true;
    }
  }

  /**
   * Overloaded method to log the caught methods in Aura Component with functionality type and subtype
   */
  @api logError(methodName, message, component, severity = Logger.LEVEL.ERROR) {
    let className = '';
    try {
        if (component) {
            className = component.getType().replace('c:', '');
        }
    } catch(error) {
        console.error('Error getting component name:', error);
    }

    try {
      // Initialize start time if this is the first log
      if (!Logger.startTimeMillis) {
        Logger.startTimeMillis = Date.now();
      }
        const logger = this._getLoggerWithSeverity(severity);
        
        logger
            .setComponent(this)
            .setRecordId(this.recordId)
            .setClassName(className)
            .setMethod(methodName)
            .setExceptionOrMessage(message);
    } catch(error) {
        console.error('Error in logging:', error);
    }
  }

  /**
   * Private method to get logger instance with appropriate severity
   */
  _getLoggerWithSeverity(severity) {
    try {
      switch(severity?.toUpperCase()) {
        case "ERROR": return Logger.atError();
        case "WARN": return Logger.atWarn();
        case "INFO": return Logger.atInfo();
        case "DEBUG": return Logger.atDebug();
        case "FINE": return Logger.atFine();
        case "FINER": return Logger.atFiner();
        case "FINEST": return Logger.atFinest();
        default: 
          console.warn(`Invalid severity level: ${severity}. Defaulting to ERROR`);
          return Logger.atError();
      }
    } catch(error) {
      console.error('Error in _getLoggerWithSeverity:', error);
      return Logger.atError();
    }
  }

  /**
   * Method to insert master logs
   */
  @api insertMasterLogs() {
    try {
      if (Logger.masterLogs && Logger.masterLogs.length > 0) {
        Logger.insertMasterLogs();
      } else {
        console.warn('No logs to insert');
      }
    } catch(error) {
      console.error('Error in insertMasterLogs:', error);
      // Try to log the error itself
      this.logError('insertMasterLogs', error, null, 'ERROR');
    }
  }

  /**
   * Method to call the main Logger.js file method handleUncaughtException
   */
  handleUncaughtErrors() {
    Logger.setRecordId(this.recordId)
      .initializeUncaughtErrorHandler();
  }

  /**
   * Method to set functionality type
   */
  @api setFunctionalityType(functionalityType) {
    this.functionalityType = functionalityType;
  }

  /**
   * Method to set functionality sub type
   */
  @api setFunctionalitySubType(functionalitySubType) {
    this.functionalitySubType = functionalitySubType;
  }
}