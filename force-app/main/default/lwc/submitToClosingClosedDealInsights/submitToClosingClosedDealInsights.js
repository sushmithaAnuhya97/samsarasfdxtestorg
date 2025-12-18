import { LightningElement, wire, track,api } from 'lwc';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import { getPicklistValues } from 'lightning/uiObjectInfoApi';
import closedLostObj from '@salesforce/schema/Closed_Deal_Insights__c';
import US_COMPETITOR_FIELD from '@salesforce/schema/Closed_Deal_Insights__c.US_Competitors__c';
import CAN_COMPETITOR_FIELD from '@salesforce/schema/Closed_Deal_Insights__c.CAN_Competitors__c';
import MX_COMPETITOR_FIELD from '@salesforce/schema/Closed_Deal_Insights__c.MX_Competitors__c';
import EMEA_COMPETITOR_FIELD from '@salesforce/schema/Closed_Deal_Insights__c.EMEA_Competitors__c';
import reason from '@salesforce/schema/Closed_Deal_Insights__c.Closed_Won_Reason__c';
import subReason from '@salesforce/schema/Closed_Deal_Insights__c.Closed_Won_Sub_Reason__c';
import { FlowNavigationNextEvent, FlowNavigationBackEvent } from 'lightning/flowSupport';
export default class submitToClosingClosedDealInsights extends LightningElement {
@api competitorsParticipated;
@api billingCountry ;
@api selectedPicklistValue;
@api availableActions = [];
@track showError=false;
@track showErrorParticipated=false;
@track showErrorCompetitorReplaced=false;
@track otherValue='';
@track showOtherTextbox = false;
@api competitorReplaced = false;
@track picklistValuesCompetitor = [];
@api selectedSubReason;
@track selectedCheckboxValues = [];
@track picklistOptions = [];
@api reason;
@api subReason;
@track recordTypeId;
@track isLoading = true;
@api Upsell;
@api AmendedContract;
@api showCompetitor=false;
@track subReasonTextArea = '';

@api Notes;
@track wonReason=[];
@track wonSubReason=[];

@api showSubReason=false; 
@api selectedReason;
@track picklistValues = {};
@track subTypeOptions = [];
@track reasonPicklistData;
@track subReasonPicklistData;
@track subReasonTextArea = '';
@track isSubReasonTextAreaMandatory = false;
@track showSubReasonTextAreaError = false;
@track showReasonError = false;
@track showSubReasonError = false;
hideSubReason=['Expansion Upsell/Addon','Other',"I don't know"];

// Getter to check if Previous button should be shown
get showPreviousButton() {
    return this.availableActions.includes('BACK');
}

// Method to validate and sync the competitorReplaced state
validateCompetitorReplacedState() {
    // Only reset competitorReplaced if we're certain the user hasn't made a valid selection
    // Don't reset during component initialization when picklist options might not be loaded yet
    if (this.competitorReplaced && !this.selectedPicklistValue && this.picklistOptions && this.picklistOptions.length > 0) {
        // Only reset if picklist options are available but no selection was made
        this.competitorReplaced = false;
        this.showErrorCompetitorReplaced = false;
    }
}

connectedCallback() {
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
    
    // Note: validateCompetitorReplacedState() will be called after picklist data is loaded
}

// getter for fieldApiName
get competitorFieldApiName() {
    if(this.billingCountry === 'US') return US_COMPETITOR_FIELD;
    if(this.billingCountry === 'CA') return CAN_COMPETITOR_FIELD;
    if(this.billingCountry === 'MX') return MX_COMPETITOR_FIELD;
    else return EMEA_COMPETITOR_FIELD;
    
}
@wire(getPicklistValues, { fieldApiName: reason, recordTypeId: '$recordTypeId' })
wiredReason({error,data}){
if (data) {
    this.wonReason = data.values;
    // Store the controlling field data
    this.reasonPicklistData = data;
    this.selectedReason=this.reason;
    this.subReasonTextArea = this.Notes;
    if(this.reason){
        if(this.reason=='Other'){
  this.isSubReasonTextAreaMandatory=true;
        }
       if(this.AmendedContract==false ||(this.AmendedContract==true && this.Upsell==true && this.selectedReason=='Expansion Upsell/Addon')){
    //console.log(this.AmendedContract+''+this.Upsell+this.selectedReason);
       this.showCompetitor=true;
}
    }
    //console.log('reasonPicklistData:', this.reasonPicklistData);
} else if (error) {
    console.error('Error loading reason picklist values:', error);
}
}
@wire(getPicklistValues, { fieldApiName: subReason, recordTypeId: '$recordTypeId' })
wiredSubReason({error,data}){
if (data) {
    this.wonSubReason = data.values;
    this.subReasonPicklistData = data;
    if(this.subReason){
    this.showSubReason=true;
    this.selectedSubReason=this.subReason; 
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
     if(this.subReason=='Other'){// make notes  as mandatory
        this.isSubReasonTextAreaMandatory=true;
    }
    }
    // Check if each option has validFor array
    this.subReasonPicklistData.values.forEach((option, index) => {
        });
} else if (error) {
    console.error('Error loading subreason picklist values:', error);
}
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

@wire(getPicklistValues, { fieldApiName: '$competitorFieldApiName', recordTypeId: '$recordTypeId' })
wiredPicklistValues({ error, data }) {
    if (data) {
        this.isLoading = true;
        
        
        this.picklistValuesCompetitor = [
            ...data.values.map(opt => ({
                ...opt,
                checked: this.selectedCheckboxValues.includes(opt.value)
            }))
        ];
        

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

        // Validate and sync the competitorReplaced state after data is loaded
        // Use setTimeout to ensure DOM updates are complete before validation
       
            this.validateCompetitorReplacedState();
      
        
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

handleCompetitorReplacedChange(event) {
    this.competitorReplaced = event.target.checked;
    // Reset error state and selected value when checkbox is unchecked
    if (!this.competitorReplaced) {
        this.showErrorCompetitorReplaced = false;
        this.selectedPicklistValue = '';
    }
    // If checkbox is checked but no value is selected, ensure it can only be checked if user makes a selection
    else if (this.competitorReplaced && !this.selectedPicklistValue) {
        // User checked the box but hasn't selected a value yet - this is fine, they can do it later
        this.showErrorCompetitorReplaced = false;
    }
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
            if (opt.value === 'Other' && this.otherValue && this.otherValue.trim()) {
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
    if (this.showOtherTextbox && this.otherValue && this.otherValue.trim()) {
        // Remove any existing "Other" option since we've already added it above
        this.picklistOptions = this.picklistOptions.filter(opt => opt.value !== 'Other');
    }

    // Reset selected picklist value if it was unselected
    if (!this.selectedCheckboxValues.includes(this.selectedPicklistValue) && 
        this.selectedPicklistValue !== this.otherValue &&
        !(this.selectedPicklistValue && typeof this.selectedPicklistValue === 'string' && this.selectedPicklistValue.startsWith('Other -'))) {
        this.selectedPicklistValue = '';
    }
    // Validate and sync the competitorReplaced state
    this.validateCompetitorReplacedState();
    
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
    // Reset error state when a value is selected
    this.showErrorCompetitorReplaced = false;
}
    handleBack() {
    // Save current state before navigating back
    if(this.otherValue!=''){
        this.competitorsParticipated = this.selectedCheckboxValues.join(';') + ';' + this.otherValue;
    }
    else {
        this.competitorsParticipated = this.selectedCheckboxValues.join(';');  
    }
    
    // Validate and sync the competitorReplaced state before navigation
    this.validateCompetitorReplacedState();
    
        // Check if BACK navigation is available before attempting to navigate
    if (!this.availableActions.includes('BACK')) {
        console.warn('BACK navigation is not available in this flow context');
        return;
    }
    this.dispatchEvent(new FlowNavigationBackEvent());
}
handleNext(){
// Validate reason is selected
if(!this.reason) {
    this.showReasonError = true;
    return;
}

// Validate subreason is selected
if(!this.subReason && !this.hideSubReason.includes(this.selectedReason)) {
    this.showSubReasonError = true;
    return;
}
if((this.isSubReasonTextAreaMandatory  && (!this.subReasonTextArea || !this.subReasonTextArea.trim()))) {
    // Show error if text area is mandatory but empty
    this.showSubReasonTextAreaError = true;
    return;
}
if(this.showCompetitor==true){//competitor validation
if(this.selectedCheckboxValues.length==0)
    {
        this.showErrorParticipated=true;
        return;
    }
if(this.showOtherTextbox  && (!this.otherValue || !this.otherValue.trim())) {
        this.showError = true;
        return;
    }
if(this.competitorReplaced && !this.selectedPicklistValue) {
        this.showErrorCompetitorReplaced = true;
        return;
    }
}
if(this.showCompetitor==false) // if no competitor 
{
    this.selectedPicklistValue=null;
    this.competitorsParticipated=null;
    this.dispatchEvent(new FlowNavigationNextEvent());
}
else {
        if(this.otherValue!=''){
            this.competitorsParticipated = this.selectedCheckboxValues.join(';') + ';' + this.otherValue;
        }
        else {
            this.competitorsParticipated = this.selectedCheckboxValues.join(';');  
        }
        this.dispatchEvent(new FlowNavigationNextEvent()); 
    }


}
handleSubReasonTextAreaChange(event) {
    this.subReasonTextArea = event.target.value;
    this.showSubReasonTextAreaError = false;
    this.Notes=this.subReasonTextArea;
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
this.subReason=this.selectedSubReason;

} 
handleTypeChange(event) {
this.selectedReason = event.detail.value;
this.selectedSubReason = null;
this.showReasonError = false;
this.showSubReasonError = false;
this.subReason=null;
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
this.reason=this.selectedReason;
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
if(this.AmendedContract==false ||(this.AmendedContract==true && this.Upsell==true && this.selectedReason=='Expansion Upsell/Addon')){
    //console.log(this.AmendedContract+''+this.Upsell+this.selectedReason);
    this.showCompetitor=true;
}
else{
    this.showCompetitor=false;
}

}
}