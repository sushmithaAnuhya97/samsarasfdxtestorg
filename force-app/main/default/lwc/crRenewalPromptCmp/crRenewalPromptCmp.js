import { LightningElement, api, wire } from 'lwc';
import { NavigationMixin } from "lightning/navigation";
import { getRecord } from 'lightning/uiRecordApi';
import MAX_DEAL_REG_DISCOUNT_FIELD from '@salesforce/schema/Opportunity.MAX_Deal_Reg_Discount__c';
import ISCLOSED_FIELD from '@salesforce/schema/Opportunity.IsClosed';

export default class CrRenewalPromptCmp extends NavigationMixin(LightningElement) {
    @api recordId;
    isShowModal = false;
    maxDealRegDiscount;
    isClosed;

    @wire(getRecord, { recordId: '$recordId', fields: [MAX_DEAL_REG_DISCOUNT_FIELD, ISCLOSED_FIELD] })
    opportunityRecord({ error, data }) {
        if (data) {
            this.maxDealRegDiscount = data.fields.MAX_Deal_Reg_Discount__c.value;
            this.isClosed = data.fields.IsClosed.value;
            this.evaluateModalVisibility();
        } else if (error) {
            console.error('Error retrieving opportunity record', error);
        }
    }

    evaluateModalVisibility() {
        // Hide modal if MAX_Deal_Reg_Discount__c > 0 and StageName is not "Closed Won" or "Closed Lost"
        if (this.maxDealRegDiscount > 0 && this.isClosed !== true) {
            this.isShowModal = true;
        }
    }

    get inputVariables() {
        return [{
            name: "recordId",
            type: "String",
            value: this.recordId
        }]
    }

    navigateToRecord(recordId) {
        this[NavigationMixin.Navigate]({
          type: "standard__recordPage",
          attributes: {
            recordId: recordId,
            actionName: "view",
          },
        });
    }
    
    handleStatusChange(event) {
        if (event.detail.status === "FINISHED") {
            this.hideModalBox();
            this.navigateToRecord(this.recordId);
        }
    }

    hideModalBox() {
        this.isShowModal = false;
    }
}