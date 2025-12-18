import { LightningElement, api, track, wire } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import getB360Analysis from '@salesforce/apex/B360FlagAnalysisController.getB360Analysis';

const FIELDS = ['Opportunity.Id'];

export default class B360FlagAnalysis extends LightningElement {
    @api recordId;
    @track analysisResult;
    @track error;
    @track isLoading = true;

    // Wire the record to get the opportunity ID
    @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
    wiredRecord({ error, data }) {
        if (data) {
            this.loadAnalysis();
        } else if (error) {
            this.error = 'Error loading opportunity: ' + error.body.message;
            this.isLoading = false;
        }
    }

    // Load B360 analysis
    loadAnalysis() {
        this.isLoading = true;
        this.error = null;
        
        getB360Analysis({ opportunityId: this.recordId })
            .then(result => {
                this.analysisResult = result;
                this.isLoading = false;
            })
            .catch(error => {
                this.error = 'Error analyzing B360 flag: ' + error.body.message;
                this.isLoading = false;
            });
    }

    // Refresh analysis
    refreshAnalysis() {
        this.loadAnalysis();
    }

    // Computed properties
    get flagStatus() {
        if (!this.analysisResult) return '';
        return this.analysisResult.currentFlagValue ? 'TRUE' : 'FALSE';
    }

    get flagClass() {
        if (!this.analysisResult) return '';
        return this.analysisResult.currentFlagValue ? 'slds-text-color_success' : 'slds-text-color_error';
    }

    get flagIcon() {
        if (!this.analysisResult) return 'utility:check';
        return this.analysisResult.currentFlagValue ? 'utility:check' : 'utility:close';
    }

    get flagVariant() {
        if (!this.analysisResult) return 'success';
        return this.analysisResult.currentFlagValue ? 'success' : 'error';
    }

    get eligibilityStatus() {
        if (!this.analysisResult) return '';
        return this.analysisResult.isEligible ? 'YES' : 'NO';
    }

    get eligibilityClass() {
        if (!this.analysisResult) return '';
        return this.analysisResult.isEligible ? 'slds-text-color_success' : 'slds-text-color_error';
    }

    get hasOpportunityKey() {
        return this.analysisResult && this.analysisResult.opportunityKey && 
               Object.keys(this.analysisResult.opportunityKey).length > 0;
    }

    get opportunityKeyList() {
        if (!this.hasOpportunityKey) return [];
        return Object.keys(this.analysisResult.opportunityKey).map(key => ({
            key: key,
            value: this.analysisResult.opportunityKey[key]
        }));
    }

    get hasRuleInfo() {
        return this.analysisResult && (
            this.analysisResult.segmentRoleKey || 
            (this.analysisResult.applicableRules && this.analysisResult.applicableRules.length > 0) ||
            this.analysisResult.isOriginalB360Oppty
        );
    }

    get applicableRulesText() {
        if (!this.analysisResult || !this.analysisResult.applicableRules) return 'None';
        return this.analysisResult.applicableRules.join(', ');
    }

    get formattedTimestamp() {
        if (!this.analysisResult || !this.analysisResult.analysisTimestamp) return '';
        return new Date(this.analysisResult.analysisTimestamp).toLocaleString();
    }
}