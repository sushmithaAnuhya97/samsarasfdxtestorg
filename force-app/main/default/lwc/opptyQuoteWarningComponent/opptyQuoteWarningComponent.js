import { LightningElement, api, track, wire } from 'lwc';
import { getRecord, getFieldValue, updateRecord } from 'lightning/uiRecordApi';
import OPPTY_FIELD from '@salesforce/schema/Opportunity.Opportunity_Tracking__c';
import QUOTE_FIELD from '@salesforce/schema/SBQQ__Quote__c.Quote_Tracking__c';
import URL from '@salesforce/label/c.OpptyQuoteURL';
import WARNINGLABLE from '@salesforce/label/c.Warning_Pick_list_Label';
import WARNINGLABLEMSG from '@salesforce/label/c.Waring_message';
import WARNINGQUOTELABLEMSG from '@salesforce/label/c.Waring_message_Quote';
import CHECKOUTOPPTY from '@salesforce/label/c.CheckOut_Oppty_Label';
import CHECKOUTQUOTE from '@salesforce/label/c.CheckOut_Quote_Label';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
export default class OpptyQuoteWarningComponent extends LightningElement {
    @api recordId;
    @api objectApiName;
    @track selectedValues = [];
    showSpinner = false;
    showData = false;
    MessageCount;
    picklistValues;
    HelpTextUrl=URL;
    warningLable = WARNINGLABLE;
    checkOutLabel;
    warningMessageLable;
    LabelChange;

    get fields() {
        if (this.objectApiName === 'Opportunity') {
            this.checkOutLabel = CHECKOUTOPPTY;
            this.warningMessageLable =WARNINGLABLEMSG;
            this.LabelChange = false;
            return [OPPTY_FIELD];
        } else if (this.objectApiName === 'SBQQ__Quote__c') {
            this.checkOutLabel = CHECKOUTQUOTE;
            this.warningMessageLable =WARNINGQUOTELABLEMSG;
            this.LabelChange = true;
            return [QUOTE_FIELD];
        }
        // }
        return [];
    }

    @wire(getRecord, { recordId: '$recordId', fields: '$fields' })
    wiredRecord({ error, data }) {
        if (data) {
            const fieldValue = getFieldValue(data, this.fields[0]);
            if (fieldValue) {
                this.picklistValues = fieldValue.split(';');
                const selectedValue = this.picklistValues
                .filter(value => value.startsWith(this.warningLable))
                .map(value => value.replace(this.warningLable, '').trim() + ' changed');
            this.selectedValues = selectedValue;
                if (this.selectedValues.length > 0) {
                    this.MessageCount = this.selectedValues.length;
                    this.showData = true;
                      
                } else {
                    this.showData = false;
                }
            } else {
                this.selectedValues = [];
                this.showData = false;
            }
        } else if (error) {
            this.selectedValues = [];
            this.showData = false;
        }
    }

    handleClose() {
        this.showSpinner = true;    
        const fields = {};
        let selectedWarningValues = this.picklistValues.filter(value => !value.startsWith(this.warningLable));
        //let alldata=[...this.selectedWarningValues,...this.selectedValues];       

    if (this.objectApiName === 'Opportunity') {
        fields[OPPTY_FIELD.fieldApiName] = selectedWarningValues.length>0?selectedWarningValues.join(';'):null
    } else if (this.objectApiName === 'SBQQ__Quote__c') {
        fields[QUOTE_FIELD.fieldApiName] =selectedWarningValues.length>0? selectedWarningValues.join(';'):null 
    }

        const recordInput = { fields: { Id: this.recordId, ...fields } };
        
        updateRecord(recordInput).then(() => {
            this.showSpinner = false;
            this.showData = false;     
            //this.showToastMsg('Success','Tracking values cleared successfully','success');
        })
        .catch(error => {
            this.showToastMsg('Error','Error clearing field values','error');
        }).finally(() => {
            
            
        });
    }
    handleNavigate(){
        window.open(this.HelpTextUrl,'_blank');
    }

    showToastMsg(titleData, msg, variantType){

        this.dispatchEvent(
            new ShowToastEvent({
                title: titleData,
                message: msg,
                variant: variantType
            })
        );
    }
}