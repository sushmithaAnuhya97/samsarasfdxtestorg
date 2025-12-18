import { LightningElement, wire } from 'lwc'; // Import core modules for LWC.
import { ShowToastEvent } from 'lightning/platformShowToastEvent'; // Import for showing toast messages.
import { getRecord, updateRecord } from 'lightning/uiRecordApi'; // Import to get and update records using Lightning UI API.
import { CloseActionScreenEvent } from 'lightning/actions'; // Import to close the quick action screen.
import { CurrentPageReference } from 'lightning/navigation'; // Import to access the current page reference and state.
import RECALCULATE_QUOTE_FIELD from '@salesforce/schema/SBQQ__Quote__c.Recalculate_Quote__c'; // Import the field Recalculate_Quote__c from Quote object schema.
import Recalculate_Quote_Toast from '@salesforce/label/c.Recalculate_Quote_Toast_Message'; // Import custom label for recalculate success message.
import Recalculate_Quote_Warning_Toast_Message from '@salesforce/label/c.Recalculate_Quote_Warning_Toast_Message'; // Import custom label for warning toast message.
import {IsConsoleNavigation, getFocusedTabInfo, refreshTab} from 'lightning/platformWorkspaceApi';
import { NavigationMixin } from "lightning/navigation";
import { loadStyle } from 'lightning/platformResourceLoader';
import hideClose from '@salesforce/resourceUrl/LWCQALit';
// Developed by Riyaz Shaik
const fields = [RECALCULATE_QUOTE_FIELD]; // Define fields array to be used for fetching quote data.

export default class recalculateQuoteCMPRefresh extends NavigationMixin(LightningElement) {
    recordId; // Holds the current recordId of the Quote.
    recalProcessed = false; // Flag to avoid processing recalculation multiple times.
    isLoading = true; // Flag to track loading status for showing spinners if needed.
    toastMsg = Recalculate_Quote_Toast; // Stores the success toast message.
    warningToastMsg = Recalculate_Quote_Warning_Toast_Message; // Stores the warning toast message.

    @wire(IsConsoleNavigation) isConsoleNavigation;

    // Wire adapter to get the current page reference and extract recordId from URL parameters.
    @wire(CurrentPageReference)
    getStateParameters(currentPageReference) {
        if (currentPageReference) {
            this.recordId = currentPageReference.state.recordId; // Retrieve recordId from URL.
        }
    }

    // Wire service to fetch Quote record data using the recordId and specified fields.
    @wire(getRecord, { recordId: '$recordId', fields })     
    quote({ error, data }) {
        if (data) {
            this.handleRecalculate(data); // If data is returned successfully, call the handleRecalculate function.
        } else if (error) {
            console.log('Toast from wire error');
            this.showToast('Error', 'Error fetching the quote: ' + (error.body?.message || 'Unknown error'), 'error'); // Show error toast in case of failure.
            this.closeQuickAction(); // Close the quick action if an error occurs.
        }
    }

    connectedCallback(){
        loadStyle(this, hideClose);
    }
    
    // Function to handle the recalculation logic based on fetched Quote data.
    handleRecalculate(quoteData) {
        if (quoteData && !this.recalProcessed) { // Ensure this block is processed only once.
            this.recalProcessed = true;
            const recalculateQuote = quoteData.fields.Recalculate_Quote__c.value; // Get the value of the Recalculate_Quote__c field.
            if (recalculateQuote) {
                this.showToast('Warning', this.warningToastMsg, 'warning'); // If Recalculate_Quote__c is true, show a warning toast.
                this.closeQuickAction(); // Close the quick action without updating.
                return;
            } 
            this.updateQuote(); // Proceed to update the Quote if Recalculate_Quote__c is not true.
        }
    }

    // Function to update the Quote by setting the Recalculate_Quote__c field to true.
    updateQuote() {
        const fields = {
            Id: this.recordId, // Include the recordId of the current quote.
            [RECALCULATE_QUOTE_FIELD.fieldApiName]: true // Set Recalculate_Quote__c field to true.
        };

        const recordInput = { fields }; // Prepare the record input object for update.

        updateRecord(recordInput)
            .then(() => {
                this.showToast('Info', this.toastMsg, 'info'); // Show success toast after updating.
                this.isLoading = false; // Mark as not loading after the update completes.
                this.refreshQuoteRecPage();
                this.closeQuickAction(); // Close the quick action after the update.
            })
            .catch(error => {
                this.showToast('Error', 'Error updating the quote: ' + (error.body?.message || 'Unknown error'), 'error'); // Show error toast if update fails.
                this.isLoading = false; // Mark as not loading even if an error occurs.
                this.closeQuickAction(); // Close the quick action even if an error occurs.
            });
    }

    refreshQuoteRecPage(){
        return this.isConsoleNavigation ? this.consoleRefresh(): this.standardRefresh() ;
    }

    async consoleRefresh(){
        const { tabId } = await getFocusedTabInfo();
        await refreshTab(tabId, {
            includeAllSubtabs: true
        });
    }

    standardRefresh(){
        //For now, navigating to this page
        this[NavigationMixin.Navigate]({
            type: "standard__recordPage",
            attributes: {
              recordId: this.recordId,
              objectApiName: "CPQ__Quote__c", // objectApiName is optional
              actionName: "view",
            }
          },true);
    }

    // Helper function to show toast messages.
    showToast(title, message, variant) {
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,
        });
        this.dispatchEvent(event); // Dispatch the toast event to show the message on the UI.
    }

    // Helper function to close the quick action window.
    closeQuickAction() {
        this.dispatchEvent(new CloseActionScreenEvent()); // Dispatch the event to close the quick action screen.
    }
}