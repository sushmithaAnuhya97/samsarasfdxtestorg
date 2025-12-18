import { LightningElement, api, wire } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import ORGANIZATION_LIMITS_FIELD from '@salesforce/schema/SamsaraLog__c.OrganizationLimits__c';
import TRANSACTION_LIMITS_FIELD from '@salesforce/schema/SamsaraLog__c.TransactionLimits__c';


export default class LogOrganizationLimits extends LightningElement {
  @api recordId;
  @api fieldName;
  @api objectType;

  isLoaded = false;
  isValidLimitsJson;
  limitsLeft = [];
  limitsRight = [];

  @wire(getRecord, {
    recordId: '$recordId',
    fields: '$dynamicFields'
  })
  async wiredGetLog({ error, data }) {
    if (data) {
      if (!this.fieldName) {
        console.error('Field name is not set.');
        this.isValidLimitsJson = false;
        this.isLoaded = true;
        return;
      }

      let limitsJson;
      try {
        limitsJson = getFieldValue(data, this.fieldName);
      } catch (err) {
        console.error('Error retrieving field value:', err);
        this.isValidLimitsJson = false;
        this.isLoaded = true;
        return;
      }

      if (!limitsJson) {
        console.error(`Field ${this.fieldName} does not exist in the data.`);
        this.isValidLimitsJson = false;
        this.isLoaded = true;
        return;
      }

      this._processLimits(limitsJson);
    } else if (error) {
      console.error('Error retrieving record:', error);
      this.isValidLimitsJson = false;
      this.isLoaded = true;
    }
  }

  get dynamicFields() {
    if (this.objectType === 'SamsaraLog__c') {
      return [ORGANIZATION_LIMITS_FIELD, TRANSACTION_LIMITS_FIELD];
    } else if (this.objectType === 'SamsaraLogEntries__c') {
      return [
        'SamsaraLogEntries__c.TransactionLimits__c'
      ];
    }
    return [];
  }

  _processLimits(limitsJson) {
    if (!limitsJson) {
      this.isValidLimitsJson = false;
      this.isLoaded = true;
      return;
    }

    let limits;
    try {
      limits = JSON.parse(limitsJson);
    } catch (error) {
      this.limitsJson = limitsJson;
      this.isValidLimitsJson = false;
      this.isLoaded = true;
      return;
    }

    limits.forEach(limit => {
      let percentUsed = limit.Max === 0 ? null : ((limit.Used / limit.Max) * 100).toFixed(2);
      if (percentUsed?.endsWith('.00')) {
        percentUsed = percentUsed.slice(0, -3);
      }
      const percentUsedFormatted = limit.Max === 0 ? 'None Available' : percentUsed + '%';

      let percentUsedIcon = '✅';
      if (limit.Max === 0 || percentUsed >= 90) {
        percentUsedIcon = '⛔';
      } else if (percentUsed >= 80) {
        percentUsedIcon = '⚠️';
      }

      limit.Text = `${percentUsedIcon} ${percentUsedFormatted} (${limit.Used} / ${limit.Max})`;
    });

    const halfLimitsLength = Math.ceil(limits.length / 2);
    this.limitsLeft = limits.slice(0, halfLimitsLength);
    this.limitsRight = limits.slice(halfLimitsLength);
    this.isValidLimitsJson = true;
    this.isLoaded = true;
  }
}