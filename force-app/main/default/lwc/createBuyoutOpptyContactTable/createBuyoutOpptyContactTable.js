import { LightningElement, api, wire } from 'lwc';
import { getRelatedListRecords } from 'lightning/uiRelatedListApi';
import { getRecord } from 'lightning/uiRecordApi';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { FlowNavigationBackEvent, FlowNavigationNextEvent } from 'lightning/flowSupport';
import { IsConsoleNavigation, EnclosingTabId, openSubtab, getFocusedTabInfo } from 'lightning/platformWorkspaceApi';

//------------------------------Labels------------------------------
import Display_Contact_Search_Empty_Error from '@salesforce/label/c.Create_Addon_Oppty_Display_Contact_Search_Empty_Error';
import Contact_Display_Message from '@salesforce/label/c.Create_Addon_Oppty_Contact_Display_Message';
import Contact_Display_Empty_Error from '@salesforce/label/c.Create_Addon_Oppty_Contact_Display_Empty_Error';

export default class CreateBuyoutOpptyContactTable extends NavigationMixin(LightningElement) {
    // Labels for displaying messages
    label = {
        Display_Contact_Search_Empty_Error,
        Contact_Display_Message,
        Contact_Display_Empty_Error
    };

    // Public properties exposed to the LWC component
    @api accountId; // The Account ID to fetch related contacts
    @api relatedContactId; // The specific related contact ID on the Opportunity
    @api selectedContactId; // The selected contact ID from the list
    _createContactInvoked = false; // Internal flag to track if the create contact process was invoked
    spinner = true; // Spinner to show loading state
    @api availableActions = []; // Actions available in the flow (e.g., NEXT, BACK)
    contacts = []; // List of contacts related to the Account
    filterContacts=[];
    relatedContact; // The specific related contact object
    selectedRowId; // The ID of the selected contact row in the data table
    matchedContact = false;
    ContactTofetchId;
    // Table columns definition
    columns = [
        { label: 'Full Name', fieldName: 'contactIdForURL', type: 'url', typeAttributes: { label: { fieldName: 'Name' }, target: '_blank', tooltip: { fieldName: 'Name' } } },
        { label: 'Email', fieldName: 'Email', type: 'text' }
    ];

    // Public getter for the create contact invoked flag
    @api 
    get createContactInvoked() {
        return this._createContactInvoked; 
    }

    // Getter to determine if contact data should be displayed
    get showConData() {
        return !this.spinner && this.filterContacts.length > 0;
    }

    // Wire adapters for console navigation information
    @wire(IsConsoleNavigation) isConsoleNavigation; // Checks if the application is in console mode
    @wire(EnclosingTabId) enclosingTabId; // Retrieves the enclosing tab ID

   // Wire method to fetch related contacts for the Account
   @wire(getRelatedListRecords, {
    parentRecordId: '$accountId',
    relatedListId: 'Contacts',
    fields: ['Contact.Id', 'Contact.Name', 'Contact.Email'],
    pageSize: 1999
    })
wiredAccountContacts({ error, data }) {
    if (data) {
        
        this.contacts = data.records.map(record => ({
            Id: record.fields.Id.value,
            Name: record.fields.Name.value,
            Email: record.fields.Email.value,
            contactIdForURL: `/${record.fields.Id.value}`
        }));

        // Check if the related contact exists in the account contacts
        this.matchedContact = this.contacts.some(contact => contact.Id === this.relatedContactId);
        if (this.matchedContact) {
            this.selectedRowId = this.relatedContactId;
        }
        else if(this.relatedContactId){
            this.ContactTofetchId=this.relatedContactId;
        }
        this.processData();
    } else if (error) {
        console.error('Error fetching Account contacts:', error);
    }

}

@wire(getRecord, {
    recordId: '$ContactTofetchId',//ContactTofetchId
    fields: ['Contact.Id', 'Contact.Name', 'Contact.Email']
})
wiredRelatedContact({ error, data }) {
    if (data) {
            
            this.relatedContact = {
                Id: data.fields.Id.value,
                Name: data.fields.Name.value,
                Email: data.fields.Email.value,
                contactIdForURL: `/${data.fields.Id.value}`
            };
            this.selectedRowId = this.relatedContact.Id;
            this.processData();
        }
        else if (error) {
        console.error('Error fetching Related contact:', error);
    }
    
}

processData() {
    if (this.selectedRowId ===this.relatedContactId) {
        console.log('inside If-->');

        if (this.relatedContact && !this.contacts.some(contact => contact.Id === this.relatedContact.Id)) {
            this.filterContacts = [this.relatedContact, ...this.contacts];
        } else {
            this.filterContacts = this.contacts;
        }
        if (this.selectedRowId) {
            this.sortContacts();
        }
        this.spinner = false; // Hide the spinner once all data is processed
    }
}

    // Sorts the contacts list to bring the selected contact to the top
    sortContacts() {
        this.filterContacts.sort((a, b) => {
            if (a.Id === this.selectedRowId) return -1; // Move the selected contact to the top
            if (b.Id === this.selectedRowId) return 1;
            return 0;
        });
    }

    // Handles the logic for creating a new contact
    handleCreateContact() {
        this._createContactInvoked = true; // Set the create contact flag to true
        const navigateNextEvent = new FlowNavigationNextEvent();
        this.dispatchEvent(navigateNextEvent); // Navigate to the next step in the flow

        // Generate the URL for creating a new Contact record
        this[NavigationMixin.GenerateUrl]({
            type: 'standard__objectPage',
            attributes: {
                objectApiName: 'Contact',
                actionName: 'new'
            },
            state: {
                defaultFieldValues: `AccountId=${this.accountId}`, // Prefill the AccountId field
                useRecordTypeCheck: 1
            }
        }, true).then(url => {
            if (this.isConsoleNavigation) {
                // If in console mode, open the new contact in a subtab
                getFocusedTabInfo().then((tabInfo) => {
                    openSubtab(tabInfo.isSubtab ? tabInfo.parentTabId : tabInfo.tabId, {
                        url: url,
                        focus: true,
                        label: 'Create Contact'
                    });
                })
                .catch(error => {
                    console.log(`Error Occured-->${error}`);
                    this.showToast('Error',
                        'Failed to load the resource, please try again. If the issue persists, contact your system admin and provide the necessary details',
                        'error',
                        'dismissable');
                });
            } else {
                window.open(url, "_blank"); // Open the new contact in a new browser tab if not in console mode
            }
        });
    }

    // Handles the logic for the "Next" button in the flow
    handleNext() {
        const recId = this.template.querySelector('c-create-oppty-generic-data-table')?.selectedRecordInTable;
        this.selectedContactId = recId; // Set the selected contact ID
        if(this.selectedContactId){
            if (this.availableActions.find((action) => action === "NEXT")) {
                const navigateNextEvent = new FlowNavigationNextEvent();
                this.dispatchEvent(navigateNextEvent); // Navigate to the next step in the flow
            }
        }else{
            this.showToast('Error',
                'You cannot proceed without selecting a buyout contact.',
                'error',
                'dismissable');
        }
        
    }

    // Handles the logic for the "Back" button in the flow
    handleBack() {
        if (this.availableActions.find((action) => action === "BACK")) {
            const navigateBackEvent = new FlowNavigationBackEvent();
            this.dispatchEvent(navigateBackEvent);
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