import { ShowToastEvent } from "lightning/platformShowToastEvent";
import publish from "@salesforce/apex/Logger.publish";

const ERROR_TOAST_VARIANT = "error";
const UNHANDLED_ERROR_MESSAGE =
  "An unexpected error has occurred. Our team has logged this issue and is diligently working on a solution as quickly as possible. \nWe apologize for any inconvenience this may have caused.";
const UNKNOWN_CLASS = "UnknownClass";

class LoggerJs {
  className;
  component;
  method;
  message;
  recordId;
  severity;
  functionalityType;
  functionalitySubType;
  LEVEL = {
    NONE: "NONE",
    ERROR: "ERROR",
    WARN: "WARN",
    INFO: "INFO",
    DEBUG: "DEBUG",
    FINE: "FINE",
    FINER: "FINER",
    FINEST: "FINEST"
  };
  masterLogs = [];
  lineNumber;
  startTimeMillis;

  constructor() {
    this.className = "";
    this.component = "";
    this.method = "";
    this.message = "";
    this.recordId = "";
    this.severity = this.LEVEL.ERROR;
    this.functionalityType = "";
    this.functionalitySubType = "";
    this.masterLogs = [];
    this.startTimeMillis = null;
  }

  /**
   * Method to set component instance
   */
  setComponent(component) {
    this.component = component;
    return this;
  }

  /**
   * Method to set method name
   */
  setMethod(methodName) {
    this.method = methodName;
    return this;
  }

  /**
   * Method to set record id
   */
  setRecordId(recordId) {
    this.recordId = recordId;
    return this;
  }

  /**
   * Method to set class name
   */
  setClassName(className) {
    this.className = className;
    return this;
  }

  /**
   * Method to set line number
   */
  setLineNumber(lineNumber) {
    this.lineNumber = lineNumber;
    return this;
  }

  /**
   * Method to log uncaught errors
   */
  initializeUncaughtErrorHandler() {
    this._fetchAndSetRecordId();
    window.onerror = function(message, source, lineno, colno, error) {
      alert('onerror called');
      console.log('Global error handler caught an error:');
      this.severity = this.LEVEL.ERROR;
      this._fetchAndSetClassName();
      this.message = error.stack;
      this._createLogRecord();
      this._displayToast(
        this.LEVEL.ERROR,
        UNHANDLED_ERROR_MESSAGE + '\n"Error: ' + error.message + '"',
        ERROR_TOAST_VARIANT
      );
      return true;
    };
  }

  /**
   * Method to insert master logs
   */
  insertMasterLogs() {
    try{
    if (this.masterLogs != null && this.masterLogs.length > 0) {
      if (this.startTimeMillis == null) {
        this.startTimeMillis = System.currentTimeMillis();
      }
      publish({ 
        logRecords: this.masterLogs,
        recordId: this.recordId,
        functionalityType: this.functionalityType,
        functionalitySubType: this.functionalitySubType,
        startTimeMillis: this.startTimeMillis 
      })
        .then(() => {
          this.masterLogs = [];
          this.startTimeMillis = null; // Reset start time after successful publish
        })
        .catch(error => {
          console.error('Error publishing logs:', error);
        });
    }
    } catch(error) {
      console.error('Error inserting master logs:', error);
    }
  }

  atError() {
    this._setSeverity(this.LEVEL.ERROR);
    return this;
  }

  atWarn() {
    this._setSeverity(this.LEVEL.WARN);
    return this;
  }

  atInfo() {
    this._setSeverity(this.LEVEL.INFO);
    return this;
  }

  atDebug() {
    this._setSeverity(this.LEVEL.DEBUG);
    return this;
  }

  atFine() {
    this._setSeverity(this.LEVEL.FINE);
    return this;
  }

  atFiner() {
    this._setSeverity(this.LEVEL.FINER);
    return this;
  }

  atFinest() {
    this._setSeverity(this.LEVEL.FINEST);
    return this;
  }

  /**
   * Method to capture exception details from an error instance or a string message
   */
  setExceptionOrMessage(input) {
    if (!input) return this;

    // Initialize start time when first log is being created
    if (!this.startTimeMillis) {
      this.startTimeMillis = Date.now();
    }

    if (typeof input === 'string') {
      // Handle string message
      this.message = input;
    }else if (input instanceof Error) {
      // Handle Error object
      this.message = input.message || 'Unknown error message';
      this.stackTrace = input.stack || 'No stack trace available';

      // Attempt to extract the method name and line number from the stack trace
      const stackLines = this.stackTrace.split('\n');
      if (stackLines.length > 1) {
        const functionNameMatch = stackLines[1].match(/at (\S+)/);
        this.method = functionNameMatch ? functionNameMatch[1] : 'Unknown method';

        const lineNumberMatch = stackLines[1].match(/:(\d+):\d+/);
        this.lineNumber = lineNumberMatch ? lineNumberMatch[1] : 'Unknown line number';
      } else {
        this.method = 'Unknown method';
        this.lineNumber = 'Unknown line number';
      }
    }else if(typeof input === 'object') {
      this.message = JSON.stringify(input);
    } 

    // Fetch and set additional details
    this._fetchAndSetRecordId();
    this._fetchAndSetClassName();
    this._createLogRecord();

    return this;
  }

  /**
   * Method to validate logLevel param passed
   */
    _validateLogLevel() {
      const logLevelValues = Object.values(this.LEVEL);
      if (!this.logLevel && !logLevelValues.includes(this.logLevel)) {
        this.logLevel = this.LEVEL.ERROR;
      }
    }

  /**
   * Method to set functionality type
   */
  setFunctionalityType(functionalityType) {
    this.functionalityType = functionalityType;
    return this;
  }

  /**
   * Method to set functionality sub type
   */
  setFunctionalitySubType(functionalitySubType) {
    this.functionalitySubType = functionalitySubType;
    return this;
  }

  /**
   * Method to create log record
   */
  _createLogRecord() {
    let logRec;
    this._validateLogLevel();
    logRec = {
      sobjectType: "SamsaraLogEntries__c",
      sourceApiName__c: this.className,
      SourceMetadataType__c: 'Aura/LWC',
      Exception_Type__c : this.severity === this.LEVEL.ERROR ? 'Javascript Error' : '',
      Level__c: this.severity,
      Method__c: this.method,
      Message__c: this.message,
      RecordId__c: this.recordId,
      Stack_Trace__c : this.stackTrace,
      Line_Number__c : this.lineNumber
    };
    this.masterLogs.push(logRec);

    // Clear the values after creating the log record
    this.className = '';
    this.method = '';
    this.message = '';
    this.stackTrace = '';
    this.lineNumber = '';
    this.functionalityType = '';
    this.functionalitySubType = '';
  }

  /**
   * Method to set severity
   */
  _setSeverity(severityLevel) {
    this.severity = severityLevel;
    return this;
  }

  /**
   * Method to fetch record id
   */
  _fetchAndSetRecordId() {
    if (!this.recordId && this.component?.template?.host?.recordId) {
      this.recordId = this.component.template.host.recordId;
    }
  }

   /**
   * Method to display toast message
   */
   _displayToast(title, message, variant) {
    this.component.dispatchEvent(
      new ShowToastEvent({
        title: title,
        message: message,
        variant: variant,
        mode: variant === ERROR_TOAST_VARIANT ? "sticky" : "dismissible"
      })
    );
  }

  /**
   * Method to fetch class name
   */
  _fetchAndSetClassName() {
    if (this.className) {
      return;
    }
    if (this.component?.constructor?.name) {
      this.className = this.component.constructor.name
    } else {
      this.className = UNKNOWN_CLASS;
    }
  }
}

export const Logger = new LoggerJs();