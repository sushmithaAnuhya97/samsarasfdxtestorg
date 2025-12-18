import { LightningElement,api,wire } from 'lwc';
import { getRelatedListRecords } from 'lightning/uiRelatedListApi';
import { NavigationMixin } from 'lightning/navigation';
import {  IsConsoleNavigation, EnclosingTabId, openSubtab, getFocusedTabInfo} from 'lightning/platformWorkspaceApi';
import { ShowToastEvent } from "lightning/platformShowToastEvent";

//------------------------------Labels------------------------------
import Display_Contact_Search_Empty_Error from '@salesforce/label/c.Create_Addon_Oppty_Display_Contact_Search_Empty_Error';
import Contact_Display_Message from '@salesforce/label/c.Create_Addon_Oppty_Contact_Display_Message';
import Contact_Display_Empty_Error from '@salesforce/label/c.Create_Addon_Oppty_Contact_Display_Empty_Error';

export default class ContactRelatedDataTableOfAccCMP extends NavigationMixin(LightningElement)  {

    label = {
        Display_Contact_Search_Empty_Error,
        Contact_Display_Message,
        Contact_Display_Empty_Error
    };

    @api recordId;
    isInitialized = false;
    spinner=true;
    contacts = [];

    columns = [
        { label: 'Full Name', fieldName: 'contactIdForURL', type: 'url', typeAttributes: { label: { fieldName: 'Name' }, target: '_blank', tooltip: { fieldName: "Name" }, } },
        { label: 'Email', fieldName: 'Email', type: 'text' }
    ];

    connectedCallback() {
        this.isInitialized = true;
    }
    
    get showConData(){
        return !this.spinner && this.contacts.length > 0;
    }

    @wire(IsConsoleNavigation) isConsoleNavigation;
    @wire(EnclosingTabId) enclosingTabId;

    @wire(getRelatedListRecords, {
        parentRecordId: '$recordId',
        relatedListId: 'Contacts',
        fields: ['Contact.Id', 'Contact.Name', 'Contact.Email'],
        pageSize: 1999,
        page: 1
    })wiredContacts({ error, data }) {
        if (data) {
            this.spinner = false;
            this.contacts = data.records.map(record => ({
                Id: record.fields.Id.value,
                Name: record.fields.Name.value,
                Email: record.fields.Email.value,
                contactIdForURL: '/' + record.fields.Id.value
            }));
        } else if (error) {
            this.showToast('Error', 'Error loading Contacts.', 'error');
            this.spinner = false;
        }
    }

    handleNavigateToVF() {
        const recId = this.template.querySelector('c-create-oppty-generic-data-table')?.selectedRecordInTable;
        if (recId) {
            this.dispatchEvent(new CustomEvent('close'));
            if (this.isConsoleNavigation) { //Navigation in Console App
                getFocusedTabInfo()
                    .then((tabInfo) => {
                        return openSubtab(tabInfo.isSubtab ? tabInfo.parentTabId : tabInfo.tabId, {
                            url: `/apex/Contact_to_Opportunity?id=${recId}`,
                            focus: true,
                            label: 'Create Contact'
                        });
                    });
            } else {
                try{
                    this.doNavigateToSelected(recId); //Navigation in Standard App
                }catch(err){
                    console.log(`Navigation Failure-->${err}`);
                    this.doNavigateToSelected(recId);
                }
            }
        }else {
            this.showToast('No Contact selected', 'Please select a Contact', 'error');
        }
    }
    
   doNavigateToSelected(recId) {
        // this[NavigationMixin.Navigate]({
        //     type: 'standard__webPage',
        //     attributes: {
        //         url: `/apex/Contact_to_Opportunity?id=${recId}`
        //     }
        // }, true);
        this[NavigationMixin.GenerateUrl]({
            type: 'standard__webPage',
            attributes: {
                url: `/apex/Contact_to_Opportunity?id=${recId}`
            }  
        }, true).then(url => {
            console.log('url-->'+url);
            window.open(url, "_self");
        })


    }
    
    handleBack() {
        this.dispatchEvent(new CustomEvent('back'));
    }

    handleCreateContact() { //Implement Workspace API
        this[NavigationMixin.GenerateUrl]({
            type: 'standard__objectPage',
            attributes: {
                objectApiName: 'Contact',
                actionName: 'new'
            },state: {
            defaultFieldValues: `AccountId=${this.recordId}`,
            useRecordTypeCheck: 1
        }
        }, true).then(url => {
            if(this.isConsoleNavigation){
                getFocusedTabInfo().then((tabInfo)=>{
                    openSubtab(tabInfo.isSubtab ? tabInfo.parentTabId : tabInfo.tabId,{
                    url:url,
                    focus: true,
                    label: 'Create Contact'
                    })
                })
                .catch((error=>{
                    console.log(`Error Occured-->${error}`);
                    this.showToast('Error',
                        'Failed to load the resource, please try again. If the issue persists, contact your system admin and provide the necessary details',
                        'error',
                        'dismissable');
                }))
            }else{
                window.open(url, "_blank");
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