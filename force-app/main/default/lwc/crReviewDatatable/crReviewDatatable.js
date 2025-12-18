import { LightningElement, api, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class CrReviewDatatable extends NavigationMixin(LightningElement) {
    @api channelRelationships = [];
    
    @track tableData = [];
    @api recordIdList = [];
    @api recordsList = [];
    @api unSelectedRows = []; //List of unSelected records to be updated
    @api selectedRows = []; //List of selected records to be updated
    
    // Validation fields that need to be checked
    validationFields = ['Key_Customer_Insight__c', 'Samsara_Recommendation__c', 'Sales_Cycle_Investment__c', 'Executive_Introduction__c'];
    
    @api
    get channelRelationshipRecords() {
        return this.channelRelationships;
    }
    
    set channelRelationshipRecords(value) {
        if (value) {
            this.channelRelationships = value;
            this.prepareTableData();
        }
    }

    // New method to sync changes back to original data
    syncChangesToOriginalData() {
        if (this.channelRelationships && this.tableData) {
            this.channelRelationships = this.channelRelationships.map(originalRecord => {
                const updatedRecord = this.tableData.find(tableRecord => tableRecord.Id === originalRecord.Id);
                if (updatedRecord) {
                    // Merge the changes back to original record
                    return {
                        ...originalRecord,
                        ...updatedRecord,
                        // Remove UI-specific properties that shouldn't persist
                        nameUrl: undefined,
                        partnerUrl: undefined
                    };
                }
                return originalRecord;
            });
        }
    }
    
    // Flow validation method - automatically called by the flow before navigation
    @api
    validate() {
        // Sync changes back to original data before validation
        this.syncChangesToOriginalData();
        
        const invalidRecords = [];
        
        // Validate each selected record
        for (const record of this.selectedRows) {
            const trueFieldCount = this.validationFields.filter(field => record[field] === true).length;
            
            if (trueFieldCount < 2) {
                invalidRecords.push({
                    recordName: record.Name,
                    recordId: record.Id,
                    trueFieldCount: trueFieldCount
                });
            }
        }
        
        if (invalidRecords.length > 0) {
            const errorMessage = this.buildValidationErrorMessage(invalidRecords);
            
            // Show toast message for better user experience
            this.showToast('Validation Error', errorMessage, 'error');
            
            return {
                isValid: false,
                errorMessage: errorMessage
            };
        }
        
        // All validations passed
        return { isValid: true };
    }
    
    buildValidationErrorMessage(invalidRecords) {
        let message = 'The following selected records do not meet the validation criteria. Each record must have at least 2 of the following fields set to true: Key Customer Insight, Samsara Recommendation, Sales Cycle Investment, Executive Introduction.\n\n';
        
        invalidRecords.forEach(record => {
            message += `• ${record.recordName} - Only ${record.trueFieldCount} field(s) are true\n`;
        });
        
        return message;
    }
    
    showToast(title, message, variant) {
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,
            mode: 'dismissible'
        });
        this.dispatchEvent(event);
    }
    
    prepareTableData() {
        if (this.channelRelationships && this.channelRelationships.length > 0) {
            this.tableData = this.channelRelationships.map(record => {
                return {
                    ...record,
                    // Preserve existing approveCheckbox state if it exists, otherwise default to false
                    approveCheckbox: record.approveCheckbox || false,
                    nameUrl: this.generateRecordUrl(record.Id),
                    partnerUrl: record.Channel_Partner__c ? this.generateRecordUrl(record.Channel_Partner__c) : ''
                };
            });
            
            // Rebuild selectedRows based on current approveCheckbox states
            this.selectedRows = this.tableData.filter(row => row.approveCheckbox);
            this.unSelectedRows = this.tableData.filter(row => !row.approveCheckbox);
            this.recordIdList = this.selectedRows.map(row => row.Id);
        }
    }
    
    generateRecordUrl(recordId) {
        return '/' + recordId;
    }
    
    handleCheckboxChange(event) {
        const recordId = event.target.dataset.id;
        const checked = event.target.checked;
        
        const tableRows = [...this.tableData];
        const rowIndex = tableRows.findIndex(row => row.Id === recordId);
        if (rowIndex !== -1) {
            tableRows[rowIndex].approveCheckbox = checked;
            this.tableData = tableRows;
            
            // Update selectedRows and unSelectedRows
            this.selectedRows = this.tableData.filter(row => row.approveCheckbox);
            this.unSelectedRows = this.tableData.filter(row => !row.approveCheckbox);
            
            // Update recordIdList for flow output
            this.recordIdList = this.selectedRows.map(row => row.Id);
            
            // Sync changes back to original data immediately
            this.syncChangesToOriginalData();
        }
    }
    
    handleFieldChange(event) {
        const recordId = event.target.dataset.id;
        const field = event.target.dataset.field;
        const checked = event.target.checked;
        
        const tableRows = [...this.tableData];
        const rowIndex = tableRows.findIndex(row => row.Id === recordId);
        if (rowIndex !== -1) {
            tableRows[rowIndex][field] = checked;
            this.tableData = tableRows;
            
            // Update selectedRows to maintain consistency
            this.selectedRows = this.tableData.filter(row => row.approveCheckbox);
            
            // Sync changes back to original data immediately
            this.syncChangesToOriginalData();
        }
    }
    
    navigateToRecord(event) {
        const recordId = event.currentTarget.dataset.id;
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: recordId,
                actionName: 'view'
            }
        });
    }
}