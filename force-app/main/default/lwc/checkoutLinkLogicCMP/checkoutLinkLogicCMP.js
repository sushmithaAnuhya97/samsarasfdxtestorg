import { LightningElement, api, wire } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import OPPTY_CHECKOUT_MSG from '@salesforce/label/c.Oppty_Checkout_Msg';
import OPPTY_CHECKOUT_WARNING_MSG from '@salesforce/label/c.Oppty_CloseDate_Warning_Msg';

// Define the fields to retrieve from the Opportunity record, including related fields
const FIELDS = [
    'Opportunity.Selected_Payment_Type__c',
    'Opportunity.License_Term__c',
    'Opportunity.SBQQ__PrimaryQuote__c',
    'Opportunity.SBQQ__PrimaryQuote__r.SBQQ__Type__c',
    'Opportunity.Blended_Discount__c',
    'Opportunity.Amount',
    'Opportunity.Concatenated_Shipping_Address__c',
    'Opportunity.Shipping_Contact__c',
    'Opportunity.Shipping_Contact__r.Name', 
    'Opportunity.CloseDate',
    'Opportunity.Checkout_Agreement_Link__c',
    'Opportunity.CurrencyIsoCode'
];

export default class CheckoutLinkLogicCMP extends LightningElement {
    @api recordId;
    
    isLoading = true;  // Property to track loading state
    popupMessage = '';
    currentUrl = '';
    iconName = 'utility:copy';
    altText = 'Copy to Clipboard';
    formattedAddress;
    opportunityData;
    label = {
        opptyCheckoutWarningMsg: OPPTY_CHECKOUT_WARNING_MSG
    };

    @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
    opportunityRecord({ error, data }) {
        if (data) {
            console.log('data-->',data);
            this.opportunityData = data;
            this.isLoading = false;  // Set loading to false when data is available
            // Handle data processing here...
        } else if (error) {
            this.isLoading = false;  // Set loading to false if there's an error
            console.error(error);  // Handle the error
        }
    }

    get opportunityMsg() {
        if (this.opportunityData) {
            let template = OPPTY_CHECKOUT_MSG;
            template = template.replace('{Selected_Payment_Type}', this.opportunityData.fields.Selected_Payment_Type__c.value || '');
            template = template.replace('{License_Term}', this.opportunityData.fields.License_Term__c.value || '');
            template = template.replace('{Amount}', this.opportunityData.fields.Amount.value || '');
            template = template.replace('{Discount_Rate}', this.opportunityData.fields.Blended_Discount__c.value || '');
            template = template.replace('{Currency}', this.opportunityData.fields.CurrencyIsoCode.value || '');

            const shippingAddress = this.opportunityData.fields.Concatenated_Shipping_Address__c.value || '';
            let formattedText = shippingAddress.replace(/(<br\s*\/?>)+/gi, ', ');
            template = template.replace('{Shipping_Address_Concatenated}', formattedText);

            const shippingContactName = this.opportunityData.fields.Shipping_Contact__r.value?.fields.Name.value || '';
            template = template.replace('{Shipping_Contact_Full_Name}', shippingContactName);

            const sbqq_Type = this.opportunityData.fields.SBQQ__PrimaryQuote__r.value?.fields.SBQQ__Type__c.value || '';
            template = template.replace('{Type_Of_Deal}', sbqq_Type);

            this.currentUrl = this.opportunityData.fields.Checkout_Agreement_Link__c.value || '';
            console.log('template-->',template);
            return template;
        }
        return 'The Opportunity information could not be loaded. Please contact your system administrator for assistance.';
    }

    get isOpptyNotTodayWarningMsg() {
        if (this.opportunityData) {
            const opptyCloseDate = this.opportunityData.fields.CloseDate.value;
            const today = new Date().toISOString().split('T')[0];
            return opptyCloseDate !== today;
        }
        return false;
    }

    get CurrentURLisNotEmpty() {
        return this.currentUrl;
    }

    showPopup(message) {
        this.popupMessage = message;
        const popup = this.template.querySelector('[data-id="popup"]');
        popup.classList.add('show');
        setTimeout(() => {
            popup.classList.remove('show');
            this.iconName = 'utility:copy';
            this.altText = 'Copy to Clipboard';
        }, 2000);
    }

    copyUrlToClipboard() {
        if (navigator.clipboard && window.isSecureContext) {
            navigator.clipboard.writeText(this.currentUrl).then(() => {
                this.iconName = 'utility:check';
                this.altText = 'Text Copied';
                this.showPopup('URL copied to clipboard!');
            }).catch(err => {
                console.error('Failed to copy text: ', err);
                this.showPopup('Failed to copy URL.');
            });
        } else {
            const textArea = document.createElement('textarea');
            textArea.value = this.currentUrl;
            textArea.style.position = 'fixed';
            textArea.style.opacity = '0';
            document.body.appendChild(textArea);
            textArea.focus();
            textArea.select();

            try {
                const successful = document.execCommand('copy');
                if (successful) {
                    this.iconName = 'utility:check';
                    this.altText = 'Text Copied';
                    this.showPopup('URL copied to clipboard!');
                } else {
                    this.showPopup('Failed to copy URL.');
                }
            } catch (err) {
                console.error('Fallback: Oops, unable to copy', err);
                this.showPopup('Failed to copy URL.');
            }

            document.body.removeChild(textArea);
        }
    }
}