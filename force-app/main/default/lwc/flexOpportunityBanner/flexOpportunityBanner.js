import { LightningElement, api, wire } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import { NavigationMixin } from 'lightning/navigation';
import HAS_NON_STANDARD_TERMS_FIELD from '@salesforce/schema/Opportunity.Flex_Has_Non_Standard_Terms__c';
import NAME_FIELD from '@salesforce/schema/Opportunity.Name';

export default class FlexOpportunityBanner extends NavigationMixin(LightningElement) {
    @api recordId; // Auto-populated when added to Opportunity record page

    @wire(getRecord, { recordId: '$recordId', fields: [HAS_NON_STANDARD_TERMS_FIELD, NAME_FIELD] })
    opportunity;

    get showBanner() {
        return this.opportunity?.data ? getFieldValue(this.opportunity.data, HAS_NON_STANDARD_TERMS_FIELD) : false;
    }

    get opportunityName() {
        return this.opportunity?.data ? getFieldValue(this.opportunity.data, NAME_FIELD) : '';
    }
    handleNext() {
        const wizardComp = {
            componentDef: "c:flexContractOpportunityList",
            attributes: {
                upgradedOpportunityId: this.recordId,
                upgradedOpportunityName: this.opportunityName
            }
            
        }
        const url = '/one/one.app#' + btoa(JSON.stringify(wizardComp));
        window.open(url, '_blank'); 
    }
}