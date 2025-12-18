import { LightningElement, api, wire } from 'lwc';
import { getRecord, updateRecord } from 'lightning/uiRecordApi';
import { getRelatedListRecords } from 'lightning/uiRelatedListApi';
import { NavigationMixin } from 'lightning/navigation';
import { IsConsoleNavigation, openSubtab, getFocusedTabInfo } from 'lightning/platformWorkspaceApi';
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { CloseActionScreenEvent } from 'lightning/actions';
import CONTACT_AMENDED_CONTRACT_NUMBER from '@salesforce/schema/Contact.Amended_Contract_Number__c';

const CONTRACT_FIELDS = ['Contract.AccountId', 'Contract.ContractNumber', 'Contract.Account.Name'];

export default class ContractAmendNavigationCMP extends NavigationMixin(LightningElement) {

    @api recordId;
    accountId;
    accountName;
    contractNumber;
    contacts = [];
    spinner = true;
    selectedContactId;

    columns = [
        { label: 'Full Name', fieldName: 'contactIdForURL', type: 'url', typeAttributes: { label: { fieldName: 'Name' }, target: '_blank', tooltip: { fieldName: "Name" } } },
        { label: 'Email', fieldName: 'Email', type: 'text' },
        { label: 'Phone', fieldName: 'Phone', type: 'phone' }
    ];

    @wire(IsConsoleNavigation) isConsoleNavigation;

    @wire(getRecord, { recordId: '$recordId', fields: CONTRACT_FIELDS })
    wiredContract({ error, data }) {
        if (data) {
            this.accountId = data.fields.AccountId.value;
            this.contractNumber = data.fields.ContractNumber.value;
            this.accountName = data.fields.Account.displayValue;
        } else if (error) {
            this.showToast('Error', 'Error loading Contract details.', 'error');
            this.spinner = false;
            console.error('Error loading contract:', error);
        }
    }

    @wire(getRelatedListRecords, {
        parentRecordId: '$accountId',
        relatedListId: 'Contacts',
        fields: ['Contact.Id', 'Contact.Name', 'Contact.Email', 'Contact.Phone'],
        pageSize: 1999,
        page: 1
    })
    wiredContacts({ error, data }) {
        if (data && data.records) {
            this.spinner = false;
            this.contacts = data.records.map(record => ({
                Id: record.fields.Id.value,
                Name: record.fields.Name.value,
                Email: record.fields.Email.value,
                Phone: record.fields.Phone.value,
                contactIdForURL: '/' + record.fields.Id.value
            }));
        } else if (error) {
            this.showToast('Error', 'Error loading Contacts.', 'error');
            this.spinner = false;
            this.contacts = [];
            console.error('Error loading contacts:', error);
        } else if (data && !data.records) {
            this.spinner = false;
            this.contacts = [];
        }
    }

    get showContactData() {
        return !this.spinner && this.contacts && this.contacts.length > 0;
    }

    get hasContacts() {
        return this.contacts && this.contacts.length > 0;
    }

    get noContactsFound() {
        return !this.spinner && this.contacts && this.contacts.length === 0;
    }

    get hideCheckboxColumn() {
        return false;
    }

    async handleAmendContract() {
        const selectedContactId = this.selectedContactId || this.template.querySelector('c-create-oppty-generic-data-table')?.selectedRecordInTable;
        const noContacts = this.contacts && this.contacts.length === 0;
        if (!selectedContactId && !noContacts) {
            this.showToast('No Contact Selected', 'Please select a Contact to proceed with contract amendment', 'warning');
            return;
        }

        this.spinner = true;

        // Only attempt to update a contact if one is selected. If there are no
        // contacts, skip the update and proceed directly to navigation.
        if (selectedContactId) {
            try {
                await this.updateContactAmendedContractNumber(selectedContactId);
            } catch (error) {
                console.error('Contact update failed:', error);
                this.spinner = false;
                
                // Show error toast with the actual error message
                const errorMessage = error.message || 'An error occurred while updating the contact.';
                this.showToast('Update Failed', errorMessage, 'error');
                return;
            }
        }

        // Navigate to amendment page after successful contact update or when no contacts exist
        this.closeQuickAction();
        const amendUrl = `/apex/SBQQ__AmendContract?id=${this.recordId}`;
        
        if (this.isConsoleNavigation) {
            getFocusedTabInfo()
                .then((tabInfo) => {
                    return openSubtab(tabInfo.isSubtab ? tabInfo.parentTabId : tabInfo.tabId, {
                        url: amendUrl,
                        focus: true,
                        label: 'Amend Contract'
                    });
                })
                .catch((error) => {
                    console.error('Navigation error:', error);
                    this.spinner = false;
                    this.showToast('Error', 'Failed to open amend page. Please try again.', 'error');
                });
        } else {
            try {
                this.doNavigateToAmend(this.recordId);
            } catch (err) {
                console.error('Navigation error:', err);
                this.spinner = false;
                this.showToast('Error', 'Failed to open amend page. Please try again.', 'error');
            }
        }
    }

    closeQuickAction() {
        try {
            this.dispatchEvent(new CloseActionScreenEvent());
        } catch (error) {
            // Silently fail if not in Quick Action context
        }
    }

    doNavigateToAmend(contractId) {
        this[NavigationMixin.GenerateUrl]({
            type: 'standard__webPage',
            attributes: {
                url: `/apex/SBQQ__AmendContract?id=${contractId}`
            }
        }, true).then(url => {
            window.open(url, "_self");
        }).catch(error => {
            console.error('URL generation error:', error);
            this.showToast('Error', 'Failed to generate amend URL. Please try again.', 'error');
        });
    }

    handleRowSelection(event) {
        const detail = event && event.detail ? event.detail : {};
        let selectedId = null;

        if (detail.selectedRecordId) {
            selectedId = detail.selectedRecordId;
        } else if (Array.isArray(detail.selectedRows) && detail.selectedRows.length > 0) {
            const firstRow = detail.selectedRows[0];
            selectedId = firstRow?.Id || firstRow?.id || firstRow?.recordId || null;
        }

        this.selectedContactId = selectedId || null;
    }

    handleCreateContact() {
        if (!this.accountId) {
            this.showToast('Error', 'Account information not available', 'error');
            return;
        }

        this[NavigationMixin.GenerateUrl]({
            type: 'standard__objectPage',
            attributes: {
                objectApiName: 'Contact',
                actionName: 'new'
            },
            state: {
                defaultFieldValues: `AccountId=${this.accountId}`,
                useRecordTypeCheck: 1
            }
        }).then(url => {
            if (this.isConsoleNavigation) {
                getFocusedTabInfo()
                    .then((tabInfo) => {
                        return openSubtab(tabInfo.isSubtab ? tabInfo.parentTabId : tabInfo.tabId, {
                            url: url,
                            focus: true,
                            label: 'New Contact'
                        });
                    })
                    .catch((error) => {
                        console.error('Error opening subtab:', error);
                        this.showToast('Error', 
                            'Failed to open new contact page. Please try again.', 
                            'error');
                    });
            } else {
                window.open(url, '_blank');
            }
        }).catch(error => {
            console.error('Navigation error:', error);
            this.showToast('Error', 'Failed to navigate to new contact page.', 'error');
        });
    }

    async updateContactAmendedContractNumber(contactId) {
        if (!this.contractNumber) {
            throw new Error('Contract number not available');
        }

        try {
            // Update the contact with the contract number using Salesforce Update API
            const fields = {};
            fields.Id = contactId;
            fields[CONTACT_AMENDED_CONTRACT_NUMBER.fieldApiName] = this.contractNumber;
            
            const recordInput = { fields };
            
            await updateRecord(recordInput);
            
            console.log('Contact updated successfully with contract number');
        } catch (error) {
            console.error('Contact update error:', error);
            
            // Extract meaningful error message
            let errorMessage = 'An error occurred while updating the contact.';
            
            if (error.body) {
                // Check for validation errors
                if (error.body.output && error.body.output.errors && error.body.output.errors.length > 0) {
                    errorMessage = error.body.output.errors[0].message;
                } else if (error.body.message) {
                    errorMessage = error.body.message;
                }
                
                // Check for field-specific errors
                if (error.body.output && error.body.output.fieldErrors) {
                    const fieldErrors = Object.values(error.body.output.fieldErrors);
                    if (fieldErrors.length > 0 && fieldErrors[0].length > 0) {
                        errorMessage = fieldErrors[0][0].message;
                    }
                }
            } else if (error.message) {
                errorMessage = error.message;
            }
            
            throw new Error(errorMessage);
        }
    }

    handleBack() {
        try {
            this.dispatchEvent(new CloseActionScreenEvent());
        } catch (error) {
            this.dispatchEvent(new CustomEvent('back'));
        }
    }

    handleNavigateToAccount() {
        if (!this.accountId) {
            this.showToast('Error', 'Account information not available', 'error');
            return;
        }

        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.accountId,
                objectApiName: 'Account',
                actionName: 'view'
            }
        });
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