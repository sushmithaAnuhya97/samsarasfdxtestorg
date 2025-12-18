import { LightningElement, api, wire } from 'lwc';
import { getRelatedListRecords } from 'lightning/uiRelatedListApi';
import { getRecord } from 'lightning/uiRecordApi';
import { FlowNavigationNextEvent, FlowNavigationBackEvent } from 'lightning/flowSupport';
import OPPORTUNITY_NAME from '@salesforce/schema/Opportunity.Name';

export default class ContactSelectionForADRTransfer extends LightningElement {

    @api recordId; // Account ID
    @api opportunityId; // Opportunity ID from flow
    @api selectedContactId; // Output variable for flow
    spinner = true;
    contacts = [];
    opportunityName = '';
    showToast = false;
    toastType = 'info';
    toastTitle = '';
    statusMsg = '';

    columnsContacts = [
        { label: 'Full Name', fieldName: 'contactIdForURL', type: 'url', 
            typeAttributes: { label: { fieldName: 'Name' }, target: '_blank', tooltip: { fieldName: "Name" } }
        },
        { label: 'Email', fieldName: 'Email', type: 'text' },
        { label: 'Phone', fieldName: 'Phone', type: 'text' },
    ];

    @wire(getRecord, { 
        recordId: '$opportunityId', 
        fields: [OPPORTUNITY_NAME] 
    })
    wiredOpportunity({ error, data }) {
        if (data && this.opportunityId) {
            console.log('Opportunity data retrieved:', JSON.stringify(data, null, 2));
            this.opportunityName = data.fields.Name.value;
            console.log('Opportunity Name:', this.opportunityName);
        } else if (error && this.opportunityId) {
            console.error('Error loading opportunity:', JSON.stringify(error, null, 2));
        }
    }

    @wire(getRelatedListRecords, {
        parentRecordId: '$recordId',
        relatedListId: 'Contacts',
        fields: ['Contact.Id', 'Contact.Name', 'Contact.Email', 'Contact.Phone'],
        pageSize: 1999,
        page: 1
    })wiredContacts({ error, data }) {
        if (data) {
            console.log('Contacts data retrieved:', JSON.stringify(data, null, 2));
            console.log('Account ID:', this.recordId);
            console.log('Opportunity ID:', this.opportunityId);
            this.spinner = false;
            this.contacts = data.records.map(record => ({
                Id: record.fields.Id.value,
                Name: record.fields.Name.value,
                Email: record.fields.Email.value,
                Phone: record.fields.Phone.value,
                contactIdForURL: '/' + record.fields.Id.value
            }));
            console.log('Processed contacts:', JSON.stringify(this.contacts, null, 2));
        } else if (error) {
            console.error('Error loading contacts:', JSON.stringify(error, null, 2));
            this.showCustomToast('Error', 'Error loading contacts', 'error');
            this.spinner = false;
        }
    }

    get showContactData(){
        return !this.spinner && this.contacts.length > 0;
    }

    handleContactSelection() {
        const selectedRecord = this.template.querySelector('c-create-oppty-generic-data-table')?.selectedRecordInTable;
        console.log('Selected record from component:', selectedRecord);
        console.log('Available contacts:', JSON.stringify(this.contacts, null, 2));
        console.log('Opportunity ID from flow:', this.opportunityId);
        
        if (selectedRecord) {
            this.selectedContactId = selectedRecord;
            console.log('Selected contact ID:', this.selectedContactId);
            
            const selectedContactDetails = this.contacts.find(contact => contact.Id === this.selectedContactId);
            console.log('Selected contact details:', JSON.stringify(selectedContactDetails, null, 2));
            console.log('Flow data - Opportunity ID:', this.opportunityId, 'Contact ID:', this.selectedContactId);
            
            // Navigate to next flow screen
            this.dispatchEvent(new FlowNavigationNextEvent());
        } else {
            this.showCustomToast('No Contact selected', 'Please select a Contact', 'error');
        }
    }

    handleBack() {
        this.dispatchEvent(new FlowNavigationBackEvent());
        }

    showCustomToast(title, message, type) {
        this.toastTitle = title || 'Notification';
        this.statusMsg = message || '';
        this.toastType = type || 'info';
        this.showToast = true;
        
        // Auto-hide toast after 5 seconds
        setTimeout(() => {
            this.showToast = false;
        }, 2000);
    }
}