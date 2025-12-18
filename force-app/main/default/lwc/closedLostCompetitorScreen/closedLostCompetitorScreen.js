import { LightningElement, wire, track,api } from 'lwc';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import { getPicklistValues } from 'lightning/uiObjectInfoApi';
import closedLostObj from '@salesforce/schema/Closed_Deal_Insights__c';
import US_COMPETITOR_FIELD from '@salesforce/schema/Closed_Deal_Insights__c.US_Competitors__c';
import CAN_COMPETITOR_FIELD from '@salesforce/schema/Closed_Deal_Insights__c.CAN_Competitors__c';
import MX_COMPETITOR_FIELD from '@salesforce/schema/Closed_Deal_Insights__c.MX_Competitors__c';
import EMEA_COMPETITOR_FIELD from '@salesforce/schema/Closed_Deal_Insights__c.EMEA_Competitors__c';
import { FlowNavigationNextEvent, FlowNavigationBackEvent } from 'lightning/flowSupport';
import reason from '@salesforce/schema/Closed_Deal_Insights__c.Closed_Lost_Reason__c';
import subReason from '@salesforce/schema/Closed_Deal_Insights__c.Closed_Lost_Sub_Reason__c';
import followupField from '@salesforce/schema/Closed_Deal_Insights__c.Follow_Up_Timeframe__c';
export default class ClosedLostCompetitorScreen extends LightningElement {
@api competitorsParticipated;
@api billingCountry ;
@api selectedPicklistValue;
@track showError=false;
@track showErrorParticipated=false;
@track otherValue='';
@track subReasonRequired=true;
@track showOtherTextbox = false;
@track picklistValuesCompetitor = [];
@track selectedCheckboxValues = [];
@track picklistOptions = [];
@track recordTypeId;
@track isLoading = true;
@track lostReason=[];
@track lostSubReason=[];
@api selectedReason;
@api selectedSubReason;
@track picklistValues = {};
@track subTypeOptions = [];
@track reasonPicklistData;
@track subReasonPicklistData;
@track subReasonTextArea = '';
@track isSubReasonTextAreaMandatory = false;
@track showSubReasonTextAreaError = false;
@track showReasonError = false;
@track showSubReasonError = false;
@track followupValue = '';
@track followupOptions = [];
@api FollowUpTimeFrame;
@api Reason;
@api SubReason;
@api Notes;
@api OpportunityType;
@api isWebstore;
@api RenewalContract;
@api autoRenewal;
@track showCompetitor=false;
@track showSubReason=false; 
@track reasonSubreason=false;
// to hide subreason
hideSubReason=['Expansion Upsell/Addon','Other',"I don't know"];

connectedCallback() {
    if(this.isWebstore=='true' || this.RenewalContract!=null || this.autoRenewal==true||this.OpportunityType!='Revenue Opportunity'){
    this.showCompetitor=true;
    this.reasonSubreason=false
    this.Reason='Other';
    }
    else{
        this.reasonSubreason=true;
    }
    console.log('subreason');
    console.log(this.reasonSubreason);
    // Restore "Other - [value]" selection when component is connected
    if (this.selectedPicklistValue && typeof this.selectedPicklistValue === 'string' && this.selectedPicklistValue.startsWith('Other -')) {
        const otherValue = this.selectedPicklistValue.replace('Other - ', '');
        this.otherValue = otherValue;
        this.showOtherTextbox = true;
        if (!this.selectedCheckboxValues.includes('Other')) {
            this.selectedCheckboxValues.push('Other');
        }
    }
    // Also check if the selected value is the otherValue directly
    else if (this.selectedPicklistValue && this.otherValue && this.selectedPicklistValue === this.otherValue) {
        this.showOtherTextbox = true;
        if (!this.selectedCheckboxValues.includes('Other')) {
            this.selectedCheckboxValues.push('Other');
        }
    }
}

// getter for fieldApiName
get competitorFieldApiName() {
    if(this.billingCountry === 'US') return US_COMPETITOR_FIELD;
    if(this.billingCountry === 'CA') return CAN_COMPETITOR_FIELD;
    if(this.billingCountry === 'MX') return MX_COMPETITOR_FIELD;
    else return EMEA_COMPETITOR_FIELD;
    
}

@wire(getObjectInfo, { objectApiName: closedLostObj })
wiredObjectInfo({ data, error }) {
    if (data) {
        this.recordTypeId = data.defaultRecordTypeId;
        //console.log('recordtype', this.recordTypeId);
    } else if (error) {
        //console.error('Error getting object info:', error);
    }
}
@wire(getPicklistValues, { fieldApiName: reason, recordTypeId: '$recordTypeId' })
wiredReason({error,data}){
    if (data) {
       this.lostReason = data.values;
        // Store the controlling field data
        this.reasonPicklistData = data;
        //console.log('reasonPicklistData:', this.reasonPicklistData);
    } else if (error) {
        console.error('Error loading reason picklist values:', error);
    }
}
@wire(getPicklistValues, { fieldApiName: followupField, recordTypeId: '$recordTypeId' })
wiredFollowup({error,data}){
    if (data) {
       this.followupOptions = data.values;
           
       // Set first value as default
       if (!this.followupValue && this.followupOptions.length > 0) {
           this.followupValue = this.followupOptions[0].value;
           this.FollowUpTimeFrame=this.followupValue;
       }
    } else if (error) {
        console.error('Error loading followup picklist values:', error);
    }
}
@wire(getPicklistValues, { fieldApiName: subReason, recordTypeId: '$recordTypeId' })
wiredSubReason({error,data}){
    if (data) {
        this.lostSubReason = data.values;
        this.subReasonPicklistData = data;
        // Check if each option has validFor array
        this.subReasonPicklistData.values.forEach((option, index) => {
            });
    } else if (error) {
        console.error('Error loading subreason picklist values:', error);
    }
}
@wire(getPicklistValues, { fieldApiName: '$competitorFieldApiName', recordTypeId: '$recordTypeId' })
wiredPicklistValues({ error, data }) {
    if (data) {
        this.isLoading = true;
        this.picklistValuesCompetitor = data.values.map(opt => ({
            ...opt,
             checked: this.selectedCheckboxValues.includes(opt.value)
        }));
        

        // Initialize selected values if we have them
        if (this.competitorsParticipated) {
            const values = this.competitorsParticipated.split(';');
            // Check if the last value is not in the picklist (it's an "Other" value)
            const lastValue = values[values.length - 1];
            const isOtherValue = !this.picklistValuesCompetitor.some(opt => opt.value === lastValue);
            
            if (isOtherValue) {
                this.otherValue = lastValue;
                this.showOtherTextbox = true;
                // Remove the "Other" value from the array
                values.pop();
            }
            
            this.selectedCheckboxValues = values;
            this.updatePicklistOptions();
        }

        // Restore selectedPicklistValue if it starts with "Other -"
        if (this.selectedPicklistValue && typeof this.selectedPicklistValue === 'string' && this.selectedPicklistValue.startsWith('Other -')) {
            const otherValue = this.selectedPicklistValue.replace('Other - ', '');
            this.otherValue = otherValue;
            this.showOtherTextbox = true;
            if (!this.selectedCheckboxValues.includes('Other')) {
                this.selectedCheckboxValues.push('Other');
            }
            // Update checkbox states first
            this.picklistValuesCompetitor = this.picklistValuesCompetitor.map(opt => ({
                ...opt,
                checked: this.selectedCheckboxValues.includes(opt.value)
            }));
            this.updatePicklistOptions();
            // Ensure the selectedPicklistValue remains as the actual value
            this.selectedPicklistValue = otherValue;
        }
        // Also check if the selected value is the otherValue directly
        else if (this.selectedPicklistValue && this.otherValue && this.selectedPicklistValue === this.otherValue) {
            this.showOtherTextbox = true;
            if (!this.selectedCheckboxValues.includes('Other')) {
                this.selectedCheckboxValues.push('Other');
            }
            // Update checkbox states first
            this.picklistValuesCompetitor = this.picklistValuesCompetitor.map(opt => ({
                ...opt,
                checked: this.selectedCheckboxValues.includes(opt.value)
            }));
            this.updatePicklistOptions();
        }

        // Use setTimeout to ensure the DOM is updated
        setTimeout(() => {
            this.isLoading = false;
        }, 0);
    } else if (error) {
        this.isLoading = false;
        // console.error('Error loading picklist values:', error);
    }
}

handleCheckboxChange(event) {
    const value = event.target.value;
    const checked = event.target.checked;

    if (checked) {
            this.showErrorParticipated=false;
        this.selectedCheckboxValues = [...this.selectedCheckboxValues, value];
    } else {
        this.selectedCheckboxValues = this.selectedCheckboxValues.filter(v => v !== value);
    }
        this.showOtherTextbox = this.selectedCheckboxValues.includes('Other');
        if(this.showOtherTextbox==false)
        {
        this.otherValue='';
        }
    this.updatePicklistOptions();
}
handleOtherInputChange(event) {
    this.otherValue = event.target.value;
    this.showError = false;
    this.updatePicklistOptions();
}
updatePicklistOptions() {
    // Update checkbox states
    this.picklistValuesCompetitor = this.picklistValuesCompetitor.map(opt => ({
        ...opt,
        checked: this.selectedCheckboxValues.includes(opt.value)
    }));

    this.picklistOptions = this.picklistValuesCompetitor
        .filter(opt => this.selectedCheckboxValues.includes(opt.value))
        .map(opt => {
            if (opt.value === 'Other' && this.otherValue.trim()) {
                return {
                    label: this.otherValue,
                    value: this.otherValue
                };
            }
            return {
                label: opt.label,
                value: opt.value
            };
        });

    // Add the "other" value to picklist options if it exists
    if (this.showOtherTextbox && this.otherValue.trim()) {
        // Remove any existing "Other" option since we've already added it above
        this.picklistOptions = this.picklistOptions.filter(opt => opt.value !== 'Other');
    }

    // Reset selected picklist value if it was unselected
    if (!this.selectedCheckboxValues.includes(this.selectedPicklistValue) && 
        this.selectedPicklistValue !== this.otherValue &&
        !(this.selectedPicklistValue && typeof this.selectedPicklistValue === 'string' && this.selectedPicklistValue.startsWith('Other -'))) {
        this.selectedPicklistValue = '';
    }
    // Use setTimeout to ensure the DOM is updated
    setTimeout(() => {
        this.isLoading = false;
    }, 0);
}

handlePicklistChange(event) {
    const selectedValue = event.detail.value;
    // If the selected value matches the otherValue, it means "Other" was selected
    if (this.otherValue && selectedValue === this.otherValue) {
        this.selectedPicklistValue = this.otherValue;
    } else {
        this.selectedPicklistValue = selectedValue;
    }
}
handleBack() {
    // Save current state before navigating back
    if(this.otherValue!=''){
        this.competitorsParticipated = this.selectedCheckboxValues.join(';') + ';' + this.otherValue;
    }
    else {
        this.competitorsParticipated = this.selectedCheckboxValues.join(';');  
    }
    this.dispatchEvent(new FlowNavigationBackEvent());
}
handleNext(){
    // Validate reason is selected
    if(this.reasonSubreason&&!this.Reason  ) {
        this.showReasonError = true;
        return;
    }
    
    // Validate subreason is selected
    if(this.reasonSubreason &&!this.SubReason && !this.hideSubReason.includes(this.selectedReason)) {
        this.showSubReasonError = true;
        return;
    }
    if(this.reasonSubreason&& this.selectedReason=='Expansion Upsell/Addon'){
        this.competitorsParticipated=null;
        this.selectedPicklistValue=null;
        this.SubReason=null;
        this.dispatchEvent(new FlowNavigationNextEvent()); 
    }
    else{
    if(this.selectedCheckboxValues.length==0 )
    {
        this.showErrorParticipated=true;
    }
    else if(this.showOtherTextbox && !this.otherValue.trim()) {
        this.showError = true;
    }
    else if((this.isSubReasonTextAreaMandatory && !this.subReasonTextArea.trim())) {
        // Show error if text area is mandatory but empty
        this.showSubReasonTextAreaError = true;
        return;
    }
    else {
        
        if(this.otherValue!=''){
            this.competitorsParticipated = this.selectedCheckboxValues.join(';') + ';' + this.otherValue;
        }
        else {
            this.competitorsParticipated = this.selectedCheckboxValues.join(';');  
        }
    
        //console.log('competitorsparticipated'+this.competitorsParticipated);
        //console.log('selectedPicklistValue'+this.selectedPicklistValue);
        this.dispatchEvent(new FlowNavigationNextEvent()); 
    }
}
}
handleTypeChange(event) {
    this.selectedReason = event.detail.value;
    this.selectedSubReason = null;
    this.showReasonError = false;
    this.showSubReasonError = false;
    this.SubReason=null;
    this.isSubReasonTextAreaMandatory=false;

    // Check if the required data is available
    if (!this.subReasonPicklistData || 
        !this.subReasonPicklistData.values ||
        !this.reasonPicklistData ||
        !this.reasonPicklistData.values) {
        console.error('Picklist data is not available');
        this.subTypeOptions = [];
        return;
    }

    // Reset subreason options if no reason is selected
    if (!this.selectedReason) {
        this.subTypeOptions = [];
        return;
    }

    // Find the index of the selected controlling value
    const controllerValueIndex = this.reasonPicklistData.values.findIndex(
        item => item.value === this.selectedReason
    );

    if (controllerValueIndex === -1) {
        console.error('Selected reason not found in controlling values');
        this.subTypeOptions = [];
        return;
    }

    // Filter dependent values based on the controlling field's index
    this.subTypeOptions = this.subReasonPicklistData.values.filter(option => {
        // Check if this option is valid for the selected controlling value
        return option.validFor && option.validFor.includes(controllerValueIndex);
    });
    this.Reason=this.selectedReason;
    if(this.selectedReason=='Other'){
    this.isSubReasonTextAreaMandatory = true;
    }
    //starts here to hide subreason
    if(this.hideSubReason.includes(this.selectedReason)){
        this.showSubReason=false;
        this.subReasonRequired=false;
    }
    else{
        this.showSubReason=true;
        this.subReasonRequired=true;
    } 
    // to hide competitor
    if(this.selectedReason=='Expansion Upsell/Addon'){
        this.showCompetitor=false;
    }
    else{
       this.showCompetitor=true;
        
    }
    
}

handleSubTypeChange(event) {
    this.selectedSubReason = event.detail.value;
    this.isSubReasonTextAreaMandatory = false;
    if(this.selectedSubReason=='Other'){
    this.isSubReasonTextAreaMandatory = true;
    }
    this.showSubReasonTextAreaError = false;
    this.showSubReasonError = false;
    if (this.isSubReasonTextAreaMandatory) {
        this.subReasonTextArea = ''; // Clear text area if it's mandatory
    }
    this.SubReason=this.selectedSubReason;
    
}

handleSubReasonTextAreaChange(event) {
        this.subReasonTextArea = event.target.value;
        this.showSubReasonTextAreaError = false;
        this.Notes=this.subReasonTextArea;
    }

handleFollowUpChange(event) {
        this.followupValue = event.detail.value;
        this.FollowUpTimeFrame=this.followupValue;
    }
}