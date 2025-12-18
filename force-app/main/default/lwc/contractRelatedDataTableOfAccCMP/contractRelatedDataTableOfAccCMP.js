import { LightningElement, api, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getRelatedListRecords } from 'lightning/uiRelatedListApi';
import { getRecord } from 'lightning/uiRecordApi';
import { IsConsoleNavigation, EnclosingTabId, openSubtab, getFocusedTabInfo} from 'lightning/platformWorkspaceApi';
import { NavigationMixin } from 'lightning/navigation';
import ACCOUNT_LATEST_ACTIVE_CONTRACT from '@salesforce/schema/Account.Latest_Active_Contract__c';
import { updateRecord } from 'lightning/uiRecordApi';

//-------------------Labels-----------------------------//
import Display_Message_1 from '@salesforce/label/c.Create_Addon_Oppty_Display_Message_1';
import Display_Message_URL_2 from '@salesforce/label/c.Create_Addon_Oppty_Display_Message_URL_2';
import Display_Message_3 from '@salesforce/label/c.Create_Addon_Oppty_Display_Message_3';
import Display_Empty_Error from '@salesforce/label/c.Create_Addon_Oppty_Display_Empty_Error';
import Display_Search_Empty_Error from '@salesforce/label/c.Create_Addon_Oppty_Display_Search_Empty_Error';

export default class ContractRelatedDataTableOfAccCMP extends NavigationMixin(LightningElement) {

    @api recordId; // Account ID
    selectedRowId;
    selectedContractId;
    selectedContactId;
    spinner = true;
    contactUpdateSpinner = false;
    accountDataLoaded = false;
    contractDataLoaded = false;
    contactDataLoaded = false;
    currentPage = 1;
    pageSize = 1999;
    filterCriteria = `{and:[{Status:{eq:Activated}},{EndDate:{gte:{literal:TODAY}}}]}`;
    contracts = [];
    filteredContracts = [];
    contacts = [];
    filteredContacts = [];
    showContactSelection = false;
    selectedContractNumber = '';
    
    // Performance optimization: Track loading states and timing
    isLoadingContracts = false;
    isLoadingContacts = false;
    loadStartTime = 0;
    
    label = {
        Display_Message_1,
        Display_Message_URL_2,
        Display_Message_3,
        Display_Empty_Error,
        Display_Search_Empty_Error
    };

    columnsContracts = [
        { label: 'Contract Number', fieldName: 'contractIdForURL', type: 'url', 
            typeAttributes: { label: { fieldName: 'Name' }, target: '_blank',tooltip: { fieldName: "Name" }, },
            cellAttributes:{ 
                class:{fieldName:'CellColor'} }},

        { label: 'Contract Start Date', fieldName: 'StartDate', type: 'date',cellAttributes:{
            class:{fieldName:'CellColor'} 
        } },
        { label: 'Contract End Date', fieldName: 'EndDate', type: 'date',cellAttributes:{
            class:{fieldName:'CellColor'} 
        } }
    ];

    columnsContacts = [
        { label: 'Full Name', fieldName: 'contactIdForURL', type: 'url', typeAttributes: { label: { fieldName: 'Name' }, target: '_blank', tooltip: { fieldName: "Name" }, } },
        { label: 'Email', fieldName: 'Email', type: 'text' }
    ];

    @wire(IsConsoleNavigation) isConsoleNavigation;
    @wire(EnclosingTabId) enclosingTabId;

    connectedCallback() {
        this.loadStartTime = performance.now();
        console.log('Component loading started at:', this.loadStartTime);
        
        // Add timeout to prevent infinite spinner
        setTimeout(() => {
            if (this.spinner) {
                console.warn('Component loading timeout - forcing spinner to stop');
                this.spinner = false;
                this.accountDataLoaded = true;
                this.contractDataLoaded = true;
                this.contactDataLoaded = true;
            }
        }, 10000); // 10 second timeout
    }

    @wire(getRecord, { recordId: '$recordId', fields: [ACCOUNT_LATEST_ACTIVE_CONTRACT] })
    wiredAccount({ error, data }) {
        if (data) {
            this.selectedRowId = data.fields.Latest_Active_Contract__c.value;
            this.accountDataLoaded = true;
            console.log('Account data loaded in:', performance.now() - this.loadStartTime, 'ms');
            this.checkAndProcessData();
        } else if (error) {
            this.accountDataLoaded = true; // Mark as loaded even on error to prevent infinite spinner
            this.spinner = false;
            console.error('Account loading error:', error);
            this.showToast('Error', 'Error loading account', 'error');
        }
    }

    @wire(getRelatedListRecords, {
        parentRecordId: '$recordId',
        relatedListId: 'Contracts',
        fields: ['Contract.Id', 'Contract.ContractNumber', 'Contract.StartDate', 'Contract.EndDate', 'Contract.Status'],
        pageSize: '$pageSize',
        page: '$currentPage',
        where: '$filterCriteria'
    })wiredContracts({ error, data }) {
        this.isLoadingContracts = false;
        if (error) {
            this.contractDataLoaded = true; // Mark as loaded even on error
            this.spinner = false;
            console.error('Contract loading error:', error);
            this.showToast('Error', 'Error loading contracts', 'error');
        }
        else if (data) {
            this.contractDataLoaded = true;
            this.contracts = data;
            console.log('Contracts loaded in:', performance.now() - this.loadStartTime, 'ms');
            console.log('Contract count:', data.records?.length || 0);
            this.checkAndProcessData();
        } 
    }

    @wire(getRelatedListRecords, {
        parentRecordId: '$recordId',
        relatedListId: 'Contacts',
        fields: ['Contact.Id', 'Contact.Name', 'Contact.Email'],
        pageSize: 1999,
        page: 1
    })wiredContacts({ error, data }) {
        this.isLoadingContacts = false;
        if (data) {
            this.contactDataLoaded = true;
            // Optimized data processing
            this.contacts = data.records.map(record => ({
                Id: record.fields.Id.value,
                Name: record.fields.Name.value,
                Email: record.fields.Email.value,
                contactIdForURL: '/' + record.fields.Id.value
            }));
            this.filteredContacts = this.contacts;
            console.log('Contacts loaded in:', performance.now() - this.loadStartTime, 'ms');
            console.log('Contact count:', this.filteredContacts.length);
            this.checkAndProcessData();
        } else if (error) {
            this.contactDataLoaded = true; // Mark as loaded even on error
            console.error('Error loading contacts:', error);
            this.showToast('Error', 'Error loading Contacts.', 'error');
            this.checkAndProcessData();
        }
    }

    get showContractData(){
        const shouldShow = !this.spinner && this.filteredContracts.length > 0 && !this.showContactSelection;
        console.log('showContractData:', shouldShow, {
            spinner: this.spinner,
            filteredContractsLength: this.filteredContracts.length,
            showContactSelection: this.showContactSelection
        });
        return shouldShow;
    }

    get showContactData(){
        const shouldShow = this.showContactSelection && this.filteredContacts.length > 0;
        console.log('showContactData:', shouldShow, {
            showContactSelection: this.showContactSelection,
            filteredContactsLength: this.filteredContacts.length
        });
        return shouldShow;
    }

    get showContactSelectionNoData(){
        const shouldShow = this.showContactSelection && this.filteredContacts.length === 0;
        console.log('showContactSelectionNoData:', shouldShow, {
            showContactSelection: this.showContactSelection,
            filteredContactsLength: this.filteredContacts.length
        });
        return shouldShow;
    }

    get isContactUpdateSpinnerActive() {
        return this.contactUpdateSpinner;
    }

    // New method to check if all data is loaded and process accordingly
    checkAndProcessData() {
        // Check if all required data is loaded
        if (this.accountDataLoaded && this.contractDataLoaded && this.contactDataLoaded) {
            this.processContracts();
        }
    }

    // Optimized data processing with better error handling
    processContracts() {
        try {
            const processStartTime = performance.now();
            
            // Process contracts in chunks for better performance
            this.filteredContracts = this.contracts.records.map(record => ({
                Id: record.fields.Id.value,
                Name: record.fields.ContractNumber.value,
                StartDate: record.fields.StartDate.value,
                EndDate: record.fields.EndDate.value,
                Status: record.fields.Status.value,
                contractIdForURL: '/' + record.fields.Id.value,
                CellColor: record.fields.Id.value === this.selectedRowId ? 'slds-text-color_success' : ' '
            }));
            
            if(this.selectedRowId) this.sortContracts();
            
            const totalLoadTime = performance.now() - this.loadStartTime;
            const processTime = performance.now() - processStartTime;
            
            console.log('Contract processing completed in:', processTime, 'ms');
            console.log('Total component load time:', totalLoadTime, 'ms');
            console.log('Filtered contracts count:', this.filteredContracts.length);
            
            // Always turn off spinner after processing, regardless of data count
            this.spinner = false;
        } catch (error) {
            console.error('Error processing contracts:', error);
            this.spinner = false;
            this.showToast('Error', 'Error processing contract data', 'error');
        }
    }

    sortContracts() {
        this.filteredContracts.sort((a, b) => {
            if (a.Id === this.selectedRowId) return -1;
            if (b.Id === this.selectedRowId) return 1;
            return 0;
        });
    }

    handleContractNext() {
        const recId = this.template.querySelector('c-create-oppty-generic-data-table')?.selectedRecordInTable;
        console.log('Selected contract ID:', recId);
        if (recId) {
            this.selectedContractId = recId;
            // Find the selected contract to get its contract number
            const selectedContract = this.filteredContracts.find(contract => contract.Id === recId);
            if (selectedContract) {
                this.selectedContractNumber = selectedContract.Name;
                console.log('Selected contract number:', this.selectedContractNumber);
            }
            this.showContactSelection = true;
            console.log('showContactSelection set to true');
            console.log('Current filteredContacts:', this.filteredContacts);
        } else {
            this.showToast('No Contract selected', 'Please select a Contract', 'error');
        }
    }

    handleContactNext() {
        const recId = this.template.querySelector('c-create-oppty-generic-data-table')?.selectedRecordInTable;
        if (recId) {
            this.selectedContactId = recId;
            this.handleNavigateToContractVF();
        } else {
            this.showToast('No Contact selected', 'Please select a Contact', 'error');
        }
    }

    async handleNavigateToContractVF() { 
        if (this.selectedContractId && this.selectedContactId) {
            try {
                // Show spinner during contact update
                this.contactUpdateSpinner = true;
                
                // Update the contact with the contract number using Salesforce Update API
                const fields = {};
                fields.Id = this.selectedContactId;
                fields.Amended_Contract_Number__c = this.selectedContractNumber;
                
                const recordInput = { fields };
                
                await updateRecord(recordInput);
                
                // Hide spinner after successful update
                this.contactUpdateSpinner = false;
                
                this.dispatchEvent(new CustomEvent('close'));
                const url = `/apex/SBQQ__AmendContract?id=${this.selectedContractId}&contactId=${this.selectedContactId}&contractNumber=${this.selectedContractNumber}`;
                if (this.isConsoleNavigation) {
                    getFocusedTabInfo()
                        .then((tabInfo) => {
                            return openSubtab(tabInfo.isSubtab ? tabInfo.parentTabId : tabInfo.tabId, {
                                url: url,
                                focus: true,
                                label: 'Amend Contract'
                            });
                        })

                } else {
                    this[NavigationMixin.GenerateUrl]({
                        type: 'standard__webPage',
                        attributes: {
                            url: url
                        }  
                    }, true).then(url => {
                        window.open(url, "_self");
                    })
                }
            } catch (error) {
                // Hide spinner on error
                this.contactUpdateSpinner = false;
                console.error('Error updating contact:', error);
                this.showToast('Error', 'Failed to update contact with contract number', 'error');
            }
        } else {
            this.showToast('Error', 'Please select both Contract and Contact', 'error');
        }
    }

    handleBack() {
        if (this.showContactSelection) {
            this.showContactSelection = false;
            this.selectedContactId = null;
        } else {
            this.dispatchEvent(new CustomEvent('back'));
        }
    }

    showToast(title, message, variant, mode) {
        this.dispatchEvent(
            new ShowToastEvent({
                title: title || 'Notification',
                message: message || '',
                variant: variant || 'info',
                mode: mode || 'dismissable',
            })
        );
    }
}