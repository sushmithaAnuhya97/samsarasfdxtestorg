import { LightningElement, track, api } from 'lwc';
import { FlowNavigationNextEvent, FlowNavigationBackEvent } from 'lightning/flowSupport';
import US_Competitors from '@salesforce/label/c.US_Competitors';
import MX_Competitors from '@salesforce/label/c.MX_Competitors';
import CA_Competitors from '@salesforce/label/c.CA_Competitors';
import EMEA_Competitors from '@salesforce/label/c.EMEA_Competitors';

export default class QuoteIncumbentScreen extends LightningElement {
    // INPUT properties from Flow
    @api whoAreTheMainIncumbentsOnThisDeal;     // Main incumbents field
    @api incumbentOtherText;                    // Other text field
    @api billingCountry;                        // Account billing country name
    @api billingCountryCode;                    // Account billing country code (preferred)
    @api recordId;                              // Quote record ID (optional)
    
    // INTERNAL tracking properties
    @track showError = false;
    @track showOtherTextbox = false;
    @track otherValue = '';
    @track selectedCheckboxValues = [];
    @track competitorOptions = [];
    @track isLoading = false;

    // competitor data getter
    get competitorData() {
        try {
            return {
                'US': US_Competitors ? US_Competitors.split(';') : [],
                'MX': MX_Competitors ? MX_Competitors.split(';') : [],
                'CA': CA_Competitors ? CA_Competitors.split(';') : [],
                'EMEA': EMEA_Competitors ? EMEA_Competitors.split(';') : []
            };
        } catch (error) {
            console.error('Error loading competitor data:', error);
            return { 'US': [], 'MX': [], 'CA': [], 'EMEA': [] };
        }
    }

    connectedCallback() {
        try {
            console.log('QuoteIncumbentScreen: Component initialized');
            
            this.setCompetitorOptions();
            this.initializeFromStoredValues();
        } catch (error) {
            console.error('Error initializing component:', error);
            this.showError = true;
        }
    }

    setCompetitorOptions() {
        const region = this.getRegionFromBillingCountry();
        const competitors = this.competitorData[region] || this.competitorData['US'];
        
        this.competitorOptions = competitors.map(competitor => ({
            label: competitor,
            value: competitor,
            checked: false
        }));
        
        console.log(`Loaded ${competitors.length} competitors for region: ${region}`);
    }

    getRegionFromBillingCountry() {
        const country = this.billingCountryCode || this.billingCountry;
        
        if (!country) return 'US';
        
        // Checking country codes
        if (country === 'US') return 'US';
        if (country === 'MX') return 'MX';
        if (country === 'CA') return 'CA';
        
        // Then country names
        if (this.billingCountry) {
            const countryName = this.billingCountry.toLowerCase();
            if (countryName.includes('united states') || countryName.includes('usa')) return 'US';
            if (countryName.includes('mexico')) return 'MX';
            if (countryName.includes('canada')) return 'CA';
        }
        
        return 'EMEA';
    }

    initializeFromStoredValues() {
        try {
            // Initialize with empty state
            this.selectedCheckboxValues = [];
            this.otherValue = '';
            this.showOtherTextbox = false;
            
            // Check if Other was selected by looking at incumbentOtherText field
            if (this.incumbentOtherText && this.incumbentOtherText.trim()) {
                // Check if it's legacy format with "Other:" prefix
                if (this.incumbentOtherText.startsWith('Other:')) {
                    this.otherValue = this.incumbentOtherText.substring(6).trim();
                } else {
                    // New format - incumbentOtherText contains the pure other text
                    this.otherValue = this.incumbentOtherText.trim();
                }
                this.selectedCheckboxValues.push('Other - Please specify');
                this.showOtherTextbox = true;
            }
            
            // Get all available competitor values for comparison
            const allCompetitors = [];
            Object.values(this.competitorData).forEach(regionCompetitors => {
                allCompetitors.push(...regionCompetitors);
            });
            
            // Parse main incumbents data
            if (this.whoAreTheMainIncumbentsOnThisDeal) {
                const values = this.whoAreTheMainIncumbentsOnThisDeal.split(';');
                
                values.forEach(value => {
                    const trimmedValue = value.trim();
                    if (trimmedValue) {
                        // Check if this value is a known competitor
                        if (allCompetitors.includes(trimmedValue)) {
                            // It's a regular competitor
                            if (!this.selectedCheckboxValues.includes(trimmedValue)) {
                                this.selectedCheckboxValues.push(trimmedValue);
                            }
                        } else {
                            // It's likely the other text value - but we already handled that above
                            // Skip adding it to selectedCheckboxValues as it's already handled by Other logic
                        }
                    }
                });
            }
            
            this.updateCheckboxStates();
        } catch (error) {
            console.error('Error parsing stored values:', error);
            // Reset to safe state
            this.selectedCheckboxValues = [];
            this.otherValue = '';
            this.showOtherTextbox = false;
        }
    }

    updateCheckboxStates() {
        this.competitorOptions = this.competitorOptions.map(opt => ({
            ...opt,
            checked: this.selectedCheckboxValues.includes(opt.value)
        }));
    }

    handleCheckboxChange(event) {
        try {
            const value = event.target.value;
            const checked = event.target.checked;

            if (checked) {
                this.selectedCheckboxValues = [...this.selectedCheckboxValues, value];
            } else {
                this.selectedCheckboxValues = this.selectedCheckboxValues.filter(v => v !== value);
            }

            this.showOtherTextbox = this.selectedCheckboxValues.includes('Other - Please specify');
            if (!this.showOtherTextbox) {
                this.otherValue = '';
            }
            
            this.updateCheckboxStates();
            this.showError = false;
        } catch (error) {
            console.error('Error handling checkbox change:', error);
            this.showError = true;
        }
    }

    handleOtherInputChange(event) {
        try {
            this.otherValue = event.target.value;
            this.showError = false;
        } catch (error) {
            console.error('Error handling other input change:', error);
            this.showError = true;
        }
    }

    handleNext() {
        try {
            // Validate at least one competitor is selected
            if (!this.selectedCheckboxValues.length) {
                console.log('Validation Error: No competitors selected');
                this.showError = true;
                return;
            }

            // Validate "Other" text input
            if (this.showOtherTextbox && !this.otherValue.trim()) {
                console.log('Validation Error: Other selected but no text entered');
                this.showError = true;
                return;
            }

            // Update both Flow variables
            this.updateFlowVariables();
            
            console.log('Navigation: Proceeding to next step');
            this.dispatchEvent(new FlowNavigationNextEvent());
        } catch (error) {
            console.error('Error in handleNext:', error);
            this.showError = true;
        }
    }

    handleBack() {
        try {
            // Save current state to Flow variables before navigating back
            this.updateFlowVariables();
            this.dispatchEvent(new FlowNavigationBackEvent());
        } catch (error) {
            console.error('Error in handleBack:', error);
            // Still allow navigation back even if state save fails
            this.dispatchEvent(new FlowNavigationBackEvent());
        }
    }

    updateFlowVariables() {
        try {
            // Update the main incumbents field with all selections
            this.whoAreTheMainIncumbentsOnThisDeal = this.buildMainIncumbentsString();
            
            // Update the other text field (or empty if not selected)
            this.incumbentOtherText = this.showOtherTextbox && this.otherValue.trim() ? this.otherValue.trim() : '';
            
            console.log('Updated Flow variables:', {
                mainIncumbents: this.whoAreTheMainIncumbentsOnThisDeal,
                otherValue: this.incumbentOtherText
            });
        } catch (error) {
            console.error('Error updating Flow variables:', error);
        }
    }
    
    buildMainIncumbentsString() {
        try {
            let outputValues = [];
            
            this.selectedCheckboxValues.forEach(value => {
                if (value === 'Other - Please specify') {
                    // Include the actual other text value instead of the label
                    if (this.otherValue && this.otherValue.trim()) {
                        outputValues.push(this.otherValue.trim());
                    }
                } else {
                    // Include regular competitor selections
                    outputValues.push(value);
                }
            });
            
            return outputValues.join(';');
        } catch (error) {
            console.error('Error building main incumbents string:', error);
            return '';
        }
    }

    get hasCompetitorOptions() {
        return this.competitorOptions && this.competitorOptions.length > 0;
    }
}