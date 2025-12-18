import { LightningElement, api, wire, track } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import retryBillingProration from '@salesforce/apex/BillingProrationAmountController.retryBillingProration';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';
import getPrefixErrorMessage from '@salesforce/apex/BillingProrationAmountController.getPrefixErrorMessage';
import getSuffixErrorMessage from '@salesforce/apex/BillingProrationAmountController.getSuffixErrorMessage';
import getPaymentTypeMismatchWarning from '@salesforce/apex/BillingProrationAmountController.getPaymentTypeMismatchWarning';
import billingProrationAPIError from './billingProrationAPIError.html';
import billingProrationAPIBanner from './billingProrationAPIBanner.html';

const FIELDS = [
    'SBQQ__Quote__c.API_Error_msg__c',
    'SBQQ__Quote__c.SBQQ__MasterContract__c',
    'SBQQ__Quote__c.Selected_Payment_Type__c',
    'SBQQ__Quote__c.SBQQ__Account__c',
    'SBQQ__Quote__c.SBQQ__Opportunity2__c'
];
const ACCOUNT_FIELDS = ['Account.B360_Payment_Type__c'];
const OPP_FIELDS = ['Opportunity.Billing_360_Transaction__c'];

export default class BillingProrationAPIBanner extends LightningElement {

    @api recordId;
    @api errorInQuoteGeneration;
    @api showErrorHeading = false;
    errorMessage;
    prefixError;
    suffixError;
    showBanner = false;
    @track isLinkClicked = false;
    @track linkClass = '';
    mismatchWarning;
    accountId;
    opportunityId;
    quoteSelectedPaymentType;
    quoteHasMasterContract = false;
    isBilling360 = false;

    @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
    wiredQuote({ error, data }) {
        if (data) {
            this.errorMessage = data.fields.API_Error_msg__c.value;
            // this.errorMessage = `"${data.fields.API_Error_msg__c.value}."`;
            console.log('errorMessage: ' + this.errorMessage);
            console.log('errorMessage: ' + typeof this.errorMessage);
            
            // Show banner only if there is an error message
            this.showBanner = this.errorMessage ? true : false;
            this.errorMessage = this.errorMessage ? `"${this.errorMessage}."` : '';
            this.accountId = data.fields.SBQQ__Account__c && data.fields.SBQQ__Account__c.value ? data.fields.SBQQ__Account__c.value : '';
            this.opportunityId = data.fields.SBQQ__Opportunity2__c && data.fields.SBQQ__Opportunity2__c.value ? data.fields.SBQQ__Opportunity2__c.value : '';
            this.quoteSelectedPaymentType = data.fields.Selected_Payment_Type__c && data.fields.Selected_Payment_Type__c.value ? data.fields.Selected_Payment_Type__c.value : '';
            this.quoteHasMasterContract = data.fields.SBQQ__MasterContract__c && data.fields.SBQQ__MasterContract__c.value ? true : false;
            if (this.showBanner) {
                getPrefixErrorMessage({ })
                    .then(result => {
                        this.prefixError = result;
                    })
                    .catch(error => {                      
                });
                getSuffixErrorMessage({ })
                    .then(result => {
                        this.suffixError = result;
                         return getPaymentTypeMismatchWarning();
                    })
                    .then((warning) => {
                        // Gate conditions: master contract present, Billing 360 flag true, and payment type mismatch
                        if (this.quoteHasMasterContract && this.isBilling360 && this.isPaymentTypeMismatch) {
                            this.mismatchWarning = warning;
                        } else {
                            this.mismatchWarning = undefined;
                        }
                    })
                    .catch(error => {                      
                });
                
            }
        } 
    }
     @wire(getRecord, { recordId: '$accountId', fields: ACCOUNT_FIELDS })
    wiredAccount({ error, data }) {
        if (data) {
            this.accountPaymentType = data.fields.B360_Payment_Type__c && data.fields.B360_Payment_Type__c.value ? data.fields.B360_Payment_Type__c.value : undefined;
        }
    }
    // Fetch Opportunity Billing 360 flag
    @wire(getRecord, { recordId: '$opportunityId', fields: OPP_FIELDS })
    wiredOpp({ error, data }) {
        if (data) {
            this.isBilling360 = data.fields.Billing_360_Transaction__c && data.fields.Billing_360_Transaction__c.value ? true : false;
        }
    }
    get isPaymentTypeMismatch() {
        return this.quoteSelectedPaymentType && this.accountPaymentType && this.quoteSelectedPaymentType !== this.accountPaymentType;
    }
    render() {
        return this.errorInQuoteGeneration ? billingProrationAPIError : billingProrationAPIBanner;
    }

    handleRetry() {
        retryBillingProration({ quoteId: this.recordId })
            .then(() => {
                this.showToast('Success', 'The Billing Proration Service has been reinitiated.', 'success');
                //return refreshApex(this.wiredQuote);
            })
            .catch(error => {
                this.showToast('Error', error.body.message, 'error');
        });
        if (!this.isLinkClicked) {
            //preventDefault(); // Prevent default link behavior
            this.isLinkClicked = true;
            this.linkClass = 'disabled-link';
        }
        if (!this.errorInQuoteGeneration) {
            setTimeout(() => {
            window.location.reload(); // Refreshes page after 8 seconds
            }, 8000); 
        } else {
            window.location.assign('/' + this.recordId); // navigate to quote record page if error coming from QUote Generation
        }
    }

    showToast(title, message, variant) {
        this.dispatchEvent(
            new ShowToastEvent({
                title: title,
                message: message,
                variant: variant
            })
        );
    }
}