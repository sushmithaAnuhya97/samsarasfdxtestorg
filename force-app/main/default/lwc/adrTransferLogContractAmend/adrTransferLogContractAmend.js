import { LightningElement, api, track, wire } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import ACCOUNT_LATEST_ACTIVE_CONTRACT from '@salesforce/schema/Account.Latest_Active_Contract__c';
import { FlowNavigationNextEvent,FlowNavigationBackEvent  } from 'lightning/flowSupport';

import Display_Message_1 from '@salesforce/label/c.Create_Addon_Oppty_Display_Message_1';
import Display_Message_URL_2 from '@salesforce/label/c.Create_Addon_Oppty_Display_Message_URL_2';
import Display_Message_3 from '@salesforce/label/c.Create_Addon_Oppty_Display_Message_3';
import Display_Empty_Error from '@salesforce/label/c.Create_Addon_Oppty_Display_Empty_Error';
import Display_Search_Empty_Error from '@salesforce/label/c.Create_Addon_Oppty_Display_Search_Empty_Error';

export default class AdrTransferLogContractAmend extends LightningElement {

    // Toast properties
    @track showToast = false;
    @track toastType = 'error';
    @track toastTitle = 'Error';
    @track statusMsg = '';

    // Columns for the datatable
    columns = [
        { label: 'Opportunity Name', fieldName: 'Opportunity_Name__c', type: 'text', cellAttributes: {
            class: { fieldName: 'CellColor' }
        }},
        { label: 'Contract Number', fieldName: 'contractIdForURL', type: 'url', 
            typeAttributes: { 
                label: { fieldName: 'Name' }, 
                target: '_blank',
                tooltip: { fieldName: "Name" }
            },
            cellAttributes: { 
                class: { fieldName: 'CellColor' }
            }
        },
        { label: 'Contract Start Date', fieldName: 'StartDate', type: 'date', cellAttributes: {
            class: { fieldName: 'CellColor' }
        }},
        { label: 'Contract End Date', fieldName: 'EndDate', type: 'date', cellAttributes: {
            class: { fieldName: 'CellColor' }
        }},
        { label: 'Contract Term', fieldName: 'ContractTerm', type: 'text', cellAttributes: {
            class: { fieldName: 'CellColor' }
        }}
    ];
    
    @api selectedContractId;
    @api outputSelectedContractId;
    @track selectedRows = [];
    @track spinner = true; // Start with spinner true
    @track selectedRowId;
    @track accountDataLoaded = false;
    @track contractDataLoaded = false;
    @track filteredContracts = [];
    _contractRecords;
    _latestContractId;
    _accountId;
    
    @api
    set contractRecords(value) {
        this._contractRecords = value;
        this.contractDataLoaded = true;
        this.processContracts();
    }
    
    get contractRecords() {
        return this._contractRecords || [];
    }

    @api
    set latestContractId(value) {
        this._latestContractId = value;
        if (value) {
            this.selectedRowId = value;
            this.processContracts();
        }
    }
    
    get latestContractId() {
        return this._latestContractId;
    }

    @api
    set accountId(value) {
        this._accountId = value;
    }
    
    get accountId() {
        return this._accountId;
    }

    label = {
        Display_Message_1,
        Display_Message_URL_2,
        Display_Message_3,
        Display_Empty_Error,
        Display_Search_Empty_Error
    };
     // Public method to force re-render and set selection
     @api
     forceSelection(contractId) {
         if (contractId) {
             this.selectedRowId = contractId;
             
             // Force re-render by updating the data
             if (this.filteredContracts.length > 0) {
                 this.filteredContracts = [...this.filteredContracts];
             }
             
             this.processContracts();
             
             // Try multiple times to set selection
             setTimeout(() => {
                 this.setDatatableSelection();
             }, 50);
             
             setTimeout(() => {
                 this.setDatatableSelection();
             }, 200);
             
             setTimeout(() => {
                 this.setDatatableSelection();
             }, 500);
         }
     }

      // Public method to manually set selection
    @api
    setManualSelection(contractId) {
        if (contractId) {
            this.selectedRowId = contractId;
            this.processContracts();
            this.setDatatableSelection();
        }
    }

    // Public method to get current selection
    @api
    getCurrentSelection() {
        return this.selectedRowId;
    }

    // Public method to refresh the datatable
    @api
    refreshDatatable() {
        this.setDatatableSelection();
    }

    // Handler for when user selects a different contract
    handleRowSelection(event) {
        if (event.detail && event.detail.selectedRows && event.detail.selectedRows.length > 0) {
            this.selectedRowId = event.detail.selectedRows[0];
        }
    }

    // Get the currently selected record from the datatable
    getSelectedRecordFromDatatable() {
        const datatable = this.template.querySelector('c-create-oppty-generic-data-table-u-r-l');
        if (datatable && datatable.selectedRecordInTable) {
            const selectedId = datatable.selectedRecordInTable;
            return selectedId;
        }
        return null;
    }


    connectedCallback() {
        // If latestContractId is provided from Flow, use it as the selected row
        if (this.latestContractId) {
            this.selectedRowId = this.latestContractId;
        }
    }

    // Wire to get Latest_Active_Contract__c from Account
    @wire(getRecord, { recordId: '$accountId', fields: [ACCOUNT_LATEST_ACTIVE_CONTRACT] })
    wiredAccount({ error, data }) {
        if (error) {
            return;
        }
        if (data && data.fields && data.fields.Latest_Active_Contract__c && data.fields.Latest_Active_Contract__c.value) {
            this.selectedRowId = data.fields.Latest_Active_Contract__c.value;
            this.accountDataLoaded = true;
            this.processContracts();
        } else {
            this.accountDataLoaded = true;
            this.processContracts();
        }
    }

    // Process contracts when both data sources are loaded
    processContracts() {
        if (!this.contractDataLoaded || !this.accountDataLoaded) {
            return;
        }

        // Transform contract records
        this.filteredContracts = this.contractRecords.map(contract => ({
            Id: contract.Id,
            Opportunity_Name__c: contract.Opportunity_Name__c, 
            Name: contract.ContractNumber,
            StartDate: contract.StartDate,
            EndDate: contract.EndDate,
            ContractTerm: contract.ContractTerm, 
            Status: contract.Status,
            contractIdForURL: '/' + contract.Id,
            CellColor: contract.Id === this.selectedRowId ? 'slds-text-color_success' : ' '
        }));
        
        // Check if selected contract exists in the list
        const selectedContract = this.filteredContracts.find(contract => contract.Id === this.selectedRowId);
        
        // Sort if we have a selected row
        if (this.selectedRowId) {
            this.sortContracts();
        }
        
        // Set spinner to false only when all data is processed
        this.spinner = false;
        
        // Try to set datatable selection
        this.setDatatableSelection();
    }

    // Sort contracts with selected contract at the top
    sortContracts() {
        this.filteredContracts.sort((a, b) => {
            if (a.Id === this.selectedRowId) return -1;
            if (b.Id === this.selectedRowId) return 1;
            return 0;
        });
    }

    // Method to manually set datatable selection
    setDatatableSelection() {
        if (this.selectedRowId && this.template) {
            setTimeout(() => {
                const datatable = this.template.querySelector('c-create-oppty-generic-data-table-u-r-l');
                if (datatable && datatable.setSelection) {
                    datatable.setSelection(this.selectedRowId);
                }
            }, 100);
        }
    }

   
    // Navigation methods
    handleBack() {
        this.dispatchEvent(new FlowNavigationBackEvent());
    }

    handleNext() {
        // Get the currently selected record from the datatable
        const selectedContractId = this.getSelectedRecordFromDatatable();
        
        if (selectedContractId) {
            // Set the output variables before navigating
            this.selectedContractId = selectedContractId;
            this.outputSelectedContractId = selectedContractId;
            this.dispatchEvent(new FlowNavigationNextEvent());
        } else {
            // Show error toast when no contract is selected
            this.showErrorToast('Please select a Contract for Amendment');
        }
    }

    // Method to show error toast
    showErrorToast(message) {
        this.toastType = 'error';
        this.toastTitle = 'Error';
        this.statusMsg = message;
        this.showToast = true;
        
        // Auto-hide toast after 5 seconds
        setTimeout(() => {
            this.showToast = false;
        }, 5000);
    }

    // Method to hide toast
    hideToast() {
        this.showToast = false;
    }

}