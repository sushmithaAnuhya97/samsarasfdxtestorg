// Built as part of the Jira# GTMS-21628, GTMS-21629, GTMS-21630.
// 	Description: This is the parent component which hosts the below 3 functionalities:
// 	    >> GTMS-21628 "New Business" Opportunity Creation Flow
// 	    >> GTMS-21629 "Add-On" Opportunity Creation Flow 
// 	    >> GTMS-21630 "Free Trial" Opportunity Creation Flow
// All these components have the base component - 
import { LightningElement, api, wire, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';
import { CloseActionScreenEvent } from 'lightning/actions';
import getEligibleContracts from '@salesforce/apex/Flex_ControlCenterHelper.getEligibleContracts';
import getMidContractHelpText from '@salesforce/apex/Flex_ControlCenterHelper.getMidContractHelpText';

export default class CreateOpportunityTypesInAccountCMP extends NavigationMixin(LightningElement) {
    @api recordId; // Account ID

    isStepOne = true;
    selectedType = '';
    midContractHelpText = '';

    @track
    recordTypeOptions = [];

    async connectedCallback() {
        try {
            // First get the help text
            const helpTextResult = await getMidContractHelpText();
            if (helpTextResult) {
                this.midContractHelpText = helpTextResult;
            }

            // Then get eligible contracts
            const contractsResult = await getEligibleContracts({ accountId: this.recordId });
            if (contractsResult) {
                if (
                    contractsResult &&
                    ((contractsResult.contracts && contractsResult.contracts.length > 0) ||
                        (contractsResult.nonEligibleActiveContracts && contractsResult.nonEligibleActiveContracts.length > 0))
                ) {
                    this.recordTypeOptions = [
                        { label: 'New Business', value: 'New Business' },
                        { label: 'Add-on', value: 'Add-on' },
                        { label: 'Free Trial', value: 'Free Trial' },
                        { label: 'Mid-Contract Changes (C&R)', value: 'Mid-Contract Changes (C&R)', helpText: this.midContractHelpText }
                    ];
                } else {
                    this.recordTypeOptions = [
                        { label: 'New Business', value: 'New Business' },
                        { label: 'Add-on', value: 'Add-on' },
                        { label: 'Free Trial', value: 'Free Trial' }
                    ];
                }
            }
        } catch (error) {
            console.error('Error in connectedCallback:', error);
        }
    }

    get isContactsTableVisible() {
        return !this.isStepOne && this.selectedType === 'New Business';
    }
    get isContractsTableVisible() {
        return !this.isStepOne && this.selectedType === 'Add-on';
    }
    get isOpportunityTableVisible() {
        return !this.isStepOne && this.selectedType === 'Free Trial';
    }
    get isNextButtonDisabled() {
        return !this.selectedType;
    }

    handleNext() {
        if (this.selectedType) {
            this.isStepOne = false;
            if (this.selectedType == 'Mid-Contract Changes (C&R)') {
                const wizardComp = {
                    componentDef: "c:flexWizard",
                    attributes: {
                        accountId: this.recordId
                    }
                }
                this[NavigationMixin.Navigate]({
                    type: 'standard__webPage',
                    attributes: {
                        url: '/one/one.app#' + btoa(JSON.stringify(wizardComp))
                    }
                })
                setTimeout(() => {
                    this.handleClose();
                }, 2000);
            }
        } else {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: 'Please select an opportunity type',
                    variant: 'error',
                }),
            );
        }
    }

    handleBack() {
        this.isStepOne = true;
    }

    handleClose() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }

    handleRecordTypeChange(event) {
        this.selectedType = event.target.value;
    }
}