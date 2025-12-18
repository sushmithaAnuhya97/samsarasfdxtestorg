import onStartMigrationJob from "@salesforce/apex/LWCBringgMigrationActions.onStartMigrationJob";
import getJobs from "@salesforce/apex/LWCBringgMigrationActions.getJobs";
import getPreferences from "@salesforce/apex/LWCBringgMigrationActions.getPreferences";
import migrateUPSPreferences from "@salesforce/apex/LWCBringgMigrationActions.migrateUPSPreferences";
import getCustomFieldsOfSinglePackage from "@salesforce/apex/LWCBringgMigrationActions.getCustomFieldsOfSinglePackage";
import getCustomFieldsOfMultiPackage from "@salesforce/apex/LWCBringgMigrationActions.getCustomFieldsOfMultiPackage";
import { refreshApex } from "@salesforce/apex";
import { LightningElement, track, api, wire } from "lwc";
import { ShowToastEvent } from "lightning/platformShowToastEvent";

export default class BringgSetting extends LightningElement {
  errors = [];
  @track canCreateJob = false;
  @track migratePreferences = false;
  @track preferenceApiName = "zkfedex__ShipmatePreference__c";
  @track preferenceName = "FedEx Preference";

  @track migrationJob = {
    carrier: "FedEx",
    includeFiles: true,
    includePackages: true,
    saveErrors: true,
    toPreferenceId: null
  };
  hasRendered = false;

  lookupColumns = [
    { value: "Name", label: "Name" },
    { value: "zkmulti__CarrierAccountDescription__c", label: "Description" }
  ];

  lookupColumns2 = [
    { value: "Name", label: "Name" },
    { value: "zkfedex__FedExAccountNumber__c", label: "Account Number" }
  ];

  fieldValue = "Id";
  fieldName = "Name";

  wireJobData;
  wiredGetPreferenceData;
  @track jobDetails;
  @track upsPreferences;
  @api title = "Custom Field Mapping";
  columns = [
    {
      label: "From Single Carrier",
      apiName: "fieldApiNameFrom",
      options: [
        {
          label: "Campaign__c",
          value: "Campaign__c"
        }
      ]
    },
    {
      label: "To Multi Carrier",
      apiName: "fieldApiNameTo",
      options: [
        {
          label: "Campaign__c",
          value: "Campaign__c"
        }
      ]
    }
  ];
  @track columnsJobDetails = [
    {
      label: "Migration Job",
      fieldName: "nameUrl",
      type: "url",
      typeAttributes: { label: { fieldName: "description" }, target: "_blank" },
      sortable: true
    },
    {
      label: "Carrier",
      fieldName: "carrier",
      type: "text"
    },
    {
      label: "Satus",
      fieldName: "jobStatus",
      type: "text"
    },
    {
      label: "Total Job Items",
      fieldName: "totalJobItems",
      type: "Number"
    },
    {
      label: "Items Processed",
      fieldName: "jobItemsProcessed",
      type: "Number"
    },
    {
      label: "Number Of Errors",
      fieldName: "numberOfErrors",
      type: "Number"
    },
    {
      label: "Extended Status",
      fieldName: "extendedStatus",
      type: "text"
    }
  ];

  @track columnsPreferences = [
    {
      label: "Preference Name",
      fieldName: "Name",
      type: "text",
      typeAttributes: { label: { fieldName: "Name" }, target: "_blank" },
      sortable: true
    },
    {
      label: "Account Number",
      fieldName: "zkups__UPSAccountNumber__c",
      type: "text"
    }
  ];

  @track rows = [];
  intervalEvent;

  @wire(getJobs, {})
  wiredGetJobs(result) {
    console.log("wiredGetJobs");
    this.wireJobData = result;
    this.jobDetails = result.data;
    if (!this.intervalEvent) {
      this.intervalEvent = setInterval(() => {
        refreshApex(this.wireJobData);
      }, 5000);
    }
  }

  @wire(getPreferences, {})
  wiredGetPreference(result) {
    console.log("wiredGetPreference", result);
    this.wiredGetPreferenceData = result;
    this.upsPreferences = result.data;
  }

  updateSelectedText() {
    const elements = this.template
      .querySelector('[data-id="preferenceIds"]')
      .getSelectedRows();
    if (elements.length) {
      const prids = [];
      elements.forEach((element) => {
        prids.push(element.Id);
      });

      console.log("prids", prids);

      migrateUPSPreferences({
        upsPreferenceIds: prids
      })
        .then((result) => {
          this.dispatchEvent(
            new ShowToastEvent({
              title: "Success",
              message: "Preferences created",
              variant: "success"
            })
          );
        })
        .catch((error) => {
          console.log(error);
          this.dispatchEvent(
            new ShowToastEvent({
              title: "Error preferences create",
              message: error.body.message,
              variant: "error"
            })
          );
        });
    }
  }

  renderedCallback() {
    if (this.hasRendered) {
      return;
    }
    this.hasRendered = true;
    this.doGetCustomFieldsOfSinglePackage(this.preferenceApiName);
    this.doGetCustomFieldsOfMultiPackage();
  }

  doGetCustomFieldsOfSinglePackage(objectName) {
    let shipmentObjectName = "zkups__UPSShipment__c";
    if (objectName === "zkfedex__ShipmatePreference__c") {
      shipmentObjectName = "zkfedex__Shipment__c";
    }
    getCustomFieldsOfSinglePackage({
      objectName: shipmentObjectName
    })
      .then((result) => {
        console.log("result", result);
        this.columns[0].options = result;
      })
      .catch((error) => {
        console.log(error);
        this.dispatchEvent(
          new ShowToastEvent({
            title: "Error Migration Job",
            message: error.body.message,
            variant: "error"
          })
        );
      });
  }

  doGetCustomFieldsOfMultiPackage() {
    getCustomFieldsOfMultiPackage({})
      .then((result) => {
        console.log("result", result);
        this.columns[1].options = result;
      })
      .catch((error) => {
        console.log(error);
        this.dispatchEvent(
          new ShowToastEvent({
            title: "Error Migration Job",
            message: error.body.message,
            variant: "error"
          })
        );
      });
  }

  onCreateJob() {
    this.canCreateJob = true;
  }
  onMigratePreferences() {
    this.migratePreferences = true;
  }

  onCancel() {
    this.migrationJob = {
      includeFiles: true,
      includePackages: true,
      saveErrors: true,
      carrier: "FedEx"
    };
    this.setPreferenceInfo();
    this.canCreateJob = false;
    refreshApex(this.wireJobData);
  }

  createUUID() {
    var dt = new Date().getTime();
    var uuid = "xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx".replace(
      /[xy]/g,
      function (c) {
        var r = (dt + Math.random() * 16) % 16 | 0;
        dt = Math.floor(dt / 16);
        return (c === "x" ? r : (r & 0x3) | 0x8).toString(16);
      }
    );
    return uuid;
  }

  @api
  retrieveRecords() {
    let rows = Array.from(this.template.querySelectorAll("tr.inputRows"));
    let records = rows.map((row) => {
      let cells = Array.from(row.querySelectorAll("c-input-table-cell"));
      return cells.reduce((record, cell) => {
        let inputVal = cell.inputValue();
        record[inputVal.field] = inputVal.value;
        return record;
      }, {});
    });

    return records;
  }

  removeRow(event) {
    this.rows.splice(event.target.value, 1);
  }

  addRow() {
    this.rows.push({ uuid: this.createUUID() });
  }

  onStart() {
    if (this.migrationJob.toPreferenceId && this.migrationJob.description) {
      this.migrationJob.fieldMapping = this.retrieveRecords();
      onStartMigrationJob({
        settingsJson: JSON.stringify(this.migrationJob)
      })
        .then((result) => {
          this.rows = [];
          this.onCancel();

          this.dispatchEvent(
            new ShowToastEvent({
              title: "Success",
              message: "Migration Job Started",
              variant: "success"
            })
          );
          refreshApex(this.wireJobData);
        })
        .catch((error) => {
          console.log(error);
          this.dispatchEvent(
            new ShowToastEvent({
              title: "Error Migration Job",
              message: error.body.message,
              variant: "error"
            })
          );
        });
    }
  }

  handleChangeSaveErrors(event) {
    this.migrationJob.saveErrors = event.target.value;
  }

  handleChangeToPreferenceId(event) {
    this.migrationJob.toPreferenceId = event.detail.value;
  }

  handleChangeFromPreferenceId(event) {
    this.migrationJob.fromPreferenceId = event.detail.value;
  }

  handleChangeQuery(event) {
    this.migrationJob.query = event.target.value;
  }
  handleChangeIncludeFiles(event) {
    this.migrationJob.includeFiles = event.target.value;
  }

  handleChangeIncludePackages(event) {
    this.migrationJob.includePackages = event.target.value;
  }

  handleChangeDescription(event) {
    this.migrationJob.description = event.target.value;
  }

  handleChangeCarrier(event) {
    this.migrationJob.carrier = event.target.value;

    this.setPreferenceInfo();
  }

  setPreferenceInfo() {
    this.rows = [];
    if (this.migrationJob.carrier === "FedEx") {
      this.preferenceApiName = "zkfedex__ShipmatePreference__c";
      this.preferenceName = "FedEx Preference";
      this.lookupColumns2 = [
        { value: "Name", label: "Name" },
        { value: "zkfedex__FedExAccountNumber__c", label: "Account Number" }
      ];
      this.doGetCustomFieldsOfSinglePackage(this.preferenceApiName);
    } else if (this.migrationJob.carrier === "UPS") {
      this.preferenceApiName = "zkups__UPSShipmatePreference__c";
      this.preferenceName = "UPS Preference";
      this.lookupColumns2 = [
        { value: "Name", label: "Name" },
        { value: "zkups__UPSAccountNumber__c", label: "Account Number" }
      ];
      this.doGetCustomFieldsOfSinglePackage(this.preferenceApiName);
    } else {
      this.preferenceApiName = null;
      this.preferenceName = null;
      this.lookupColumns2 = [];
    }
  }
}