import { LightningElement, api, wire, track } from 'lwc';
import { getRecord, getFieldValue, updateRecord } from 'lightning/uiRecordApi';
import getAccountExtension from '@salesforce/apex/AccountExtensionHelper.getAccountExtension';
import ACCOUNT_NAME_FIELD from '@salesforce/schema/Account.Name';

export default class PartnerAccountMoreInfoLwc extends LightningElement {
    @api recordId; 
    @track extensionRecordId;
    @track accountData;
    @track extensionData;
    @track isLoading = true;
    @track error;
    @track editMode = false;
    @wire(getRecord, { recordId: '$recordId', fields: [ACCOUNT_NAME_FIELD] })
    wiredAccount({ error, data }) {
        if (data) {
            this.accountData = data;
            this.error = undefined;
            this.loadExtensionData();
        } else if (error) {
            this.error = error;
            this.accountData = undefined;
            this.isLoading = false;
            console.log('RODRIGO wiredAccount ' + error);
        }
    }

    loadExtensionData() {
        getAccountExtension({ accountId: this.recordId })
            .then(result => {
                if (result) {
                    this.extensionData = result;
                    this.extensionRecordId = result.Id;
                    console.log('RODRIGO getAccountExtension ' + this.extensionRecordId);
                    this.isLoading = false;
                } else {
                    // No extension record exists yet
                    this.extensionData = { Account__c: this.recordId };
                }
                
            })
            .catch(error => {
                this.error = error;
                this.isLoading = false;
                console.log('RODRIGO getAccountExtension ' + error);
            });
    }
    handleEdit() {
        this.editMode = true;
    }
    handleSuccess() {
        this.editMode = false;
    }
}