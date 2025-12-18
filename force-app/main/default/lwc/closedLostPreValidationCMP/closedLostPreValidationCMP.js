import { LightningElement, api, wire} from 'lwc';
import { getRelatedListRecords } from 'lightning/uiRelatedListApi';
import { FlowNavigationNextEvent } from 'lightning/flowSupport';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import hasValidationExemption from '@salesforce/customPermission/Validation_Rule_Exemption';
import Renewal_reason_required from '@salesforce/label/c.Renewal_reason_required';
import Fill_the_Renewal_reason from '@salesforce/label/c.Fill_the_Renewal_reason';
import Industrial_opportunity from '@salesforce/label/c.Industrial_opportunity';
import Closed_lost_reason from '@salesforce/label/c.Closed_lost_reason';
import Closed_lost_reason_for_revenew_opportunities from '@salesforce/label/c.Closed_lost_reason_for_revenew_opportunities';
import Reason_for_industrial_oppportunities from '@salesforce/label/c.Reason_for_industrial_oppportunities';
import Industrial_close_lost_reason from '@salesforce/label/c.Industrial_close_lost_reason';
import Fill_industrial_closed_lost_reason_detail from '@salesforce/label/c.Fill_industrial_closed_lost_reason_detail';
import Fill_industrial_closed_lost_reason from '@salesforce/label/c.Fill_industrial_closed_lost_reason';
import Trial_return_status from '@salesforce/label/c.Trial_return_status';
import Update_trail_opportunity_status from '@salesforce/label/c.Update_trail_opportunity_status';

export default class closedLostPreValidationCMP extends LightningElement {
    @api opportunityRecord;
    @api userProfileRecord;


    errorDetails = [];
    warningDetails = [];
    hasErrors = false;
    hasWarnings = false;
    isLoading = false;
    trialDataLoaded = false;
    trialOpportunities = []; 
    readyToRender = false;

    @api
    get backButtonInvoked() {
        return this._backButtonInvoked;
    }
    

       @wire(getRelatedListRecords, {
        parentRecordId: '$opportunityRecord.Id',
        relatedListId: 'Opportunities__r',
        fields: [
            'Opportunity.Id',
            'Opportunity.Type',
            'Opportunity.Trial_Status__c',
            'Opportunity.TrialResolutionOppty__c'
        ]
    })
    wiredTrials({ data, error }) {
        if (data) {
             console.log('Raw related records:', data.records); 
            this.trialOpportunities = data.records
                .filter(rec =>
                    rec.fields.Type?.value === 'Free Trial Opportunity' &&
                    rec.fields.TrialResolutionOppty__c?.value === this.opportunityRecord.Id
                )
                .map(rec => ({
                    Id: rec.fields.Id.value,
                    Trial_Status__c: rec.fields.Trial_Status__c?.value
                    
                }));
                 console.log('Filtered trials:', this.trialOpportunities); 
          
        } else if (error) {
            console.error('Error fetching related trial opportunities:', error);
            this.showToast('Error loading trial opportunities', 'error');
        }
         this.trialDataLoaded = true;
         this.runValidationIfReady();
    }

   
    validateRecords() {       
        const validationRules = [
           {
                // Rule 1: Closed Lost + Renewal + missing Closed Lost Renewal Reason
                condition:
                    this.userProfileRecord?.Name !== 'System Administrator' &&
                    !hasValidationExemption &&
                    (this.opportunityRecord?.Renewal__c === true || 
                     this.opportunityRecord?.SBQQ__RenewedContract__c != null) &&
                    (!this.opportunityRecord?.Closed_Lost_Renewal_Reason__c ||
                     !this.opportunityRecord?.Closed_Lost_Renewal_Sub_reason__c ||
                     !this.opportunityRecord?.Closed_Lost_Reason_Detail__c),
                errorMessage: Renewal_reason_required,
                nextStep: Fill_the_Renewal_reason
            },           
            {
                // Rule 2: Industrial RT + missing Industrial Closed Lost Reason
                condition:
                    !hasValidationExemption &&                                   
                    this.opportunityRecord?.Type === 'Revenue Opportunity' &&
                    !this.opportunityRecord?.Industrial_Closed_Lost_Reason__c &&
                    this.opportunityRecord?.RecordTypeId === Industrial_opportunity,
                errorMessage: Reason_for_industrial_oppportunities,
                nextStep: Fill_industrial_closed_lost_reason
            },
            {
                // Rule 3: Industrial RT + missing Industrial Closed Lost Reason Detail
                condition:
                    !hasValidationExemption &&              
                    this.opportunityRecord?.Type === 'Revenue Opportunity' &&
                    !this.opportunityRecord?.Industrial_Closed_Lost_Reason_Detail__c &&
                    this.opportunityRecord?.RecordTypeId === Industrial_opportunity,
                errorMessage: Industrial_close_lost_reason,
                nextStep: Fill_industrial_closed_lost_reason_detail
            },
              {
                // Rule 4: Trial status is Not Shipped while trying to close
                condition:
                    (this.opportunityRecord?.Type === 'Revenue Opportunity' ||
                     this.opportunityRecord?.Type === 'Revenue Opportunity - Bill Only') &&                 
                    
                    this.trialOpportunities?.some(
                        trial => trial?.Trial_Status__c === 'Open'
                    ),
                errorMessage:
                    Trial_return_status,
                nextStep: Update_trail_opportunity_status
            }
           
        
        ];

        // Handle errors based on validation rules
        this.errorDetails = validationRules
            .filter(rule => {                
                return rule.condition;
            })
            .map(rule => ({
                errorMessage: rule.errorMessage,
                nextStep: rule.nextStep
            }));

        this.hasErrors = this.errorDetails.length > 0;
        
        // Check for warnings after validating for errors
        this.checkForWarnings();

        // If no errors AND no warnings, automatically navigate to next step
        if (this.errorDetails.length === 0 && this.warningDetails.length === 0) {
            this.handleNext();
        }
    }

    showToast(message, variant) {
        const toastEvent = new ShowToastEvent({
            title: 'Validation Error',
            message: message,
            variant: variant,          
        });
        this.dispatchEvent(toastEvent); 
    }

    // Navigate to the next step if no rule satisfies
    handleNext() {
        if (this.hasErrors) {
            this.showToast('Please resolve all validation issues before proceeding', 'error');
            return;
        }
        
        const navigateNextEvent = new FlowNavigationNextEvent();
        this.dispatchEvent(navigateNextEvent);
    }

    //handleback to record page 
    handleBack() {
        this._backButtonInvoked = true;
        this.dispatchEvent(new FlowNavigationNextEvent());
    }
    runValidationIfReady() {
    if (this.opportunityRecord && this.trialDataLoaded) {
        this.validateRecords();
        if (this.errorDetails.length > 0 || this.warningDetails.length > 0) {
            this.readyToRender = true;
        }
    }
   }

    checkForWarnings() {
        const warnings = [];
        this.warningDetails = warnings;
        this.hasWarnings = warnings.length > 0;
        console.log('Final warningDetails:', this.warningDetails);
    }
}