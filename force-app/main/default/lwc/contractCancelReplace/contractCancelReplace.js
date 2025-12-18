import { LightningElement, track, wire, api } from 'lwc';
import getEligibleContracts from '@salesforce/apex/Flex_ControlCenterHelper.getEligibleContracts';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';
import TIME_ZONE from '@salesforce/i18n/timeZone';

export default class ContractCancelReplace extends NavigationMixin(LightningElement) {
    @api contractIds = [];
    @track isChildComponentVisible = false;
    isChildComponentVisible001 = false;
    @track contracts = [];
    @track nonEligibleContracts = [];
    @track controlCenterConfig = {};
    @track selectedContracts = [];
    @track isContinueDisabled = true;
    @track showNonEligibleContracts = false;
    @track greaterThanMaxEligibleContract = false;
    eligibleContractLabel;
    ineligibleContractLabel;
    userProfile = '';
    @track isWarningExpanded = true;

    columns = [
        { 
            label: 'Contract Number', 
            fieldName: 'ContractUrl',
            type: 'url',
            typeAttributes: {
                label: { fieldName: 'ContractNumber' },
                target: '_blank'
            },
            headerAttributes: {
                style: 'border-left: 2px solid #000000'
            },
            actions: [], 
            hideDefaultActions: true
        },
        { 
            label: 'Renewal ACV', 
            fieldName: 'Contract_Renewable_ACV__c', 
            type: 'currency', 
            typeAttributes: { 
                currencyCode: { fieldName: 'CurrencyIsoCode' },
                currencyDisplayAs: "code"
            },
            cellAttributes: {
                alignment: 'left'
            },
            actions: [], 
            hideDefaultActions: true 
        },
        { label: 'Start Date', fieldName: 'StartDate', type: 'date',
            typeAttributes: { 
                year: "numeric", 
                month: "short",  
                day: "numeric", 
                timeZone: "UTC"  
            }, 
            actions: [], hideDefaultActions: true},
        { label: 'End Date', fieldName: 'EndDate', type: 'date', 
            typeAttributes: { 
                year: "numeric", 
                month: "short",  
                day: "numeric", 
                timeZone: "UTC"  
            }, 
            actions: [], hideDefaultActions: true },
        { label: 'Status', fieldName: 'Status', type : 'text', actions: [], hideDefaultActions: true}
    ];

	// Define columns for lightning-datatable
	ineligibleContractColumns = [
		{ 
            label: 'Contract Number', 
            fieldName: 'ContractUrl',
            type: 'url',
            typeAttributes: {
                label: { fieldName: 'ContractNumber' },
                target: '_blank'
            }, 
            hideDefaultActions: true
        },
        { 
            label: 'Renewal ACV', 
            fieldName: 'ContractRenewableACV', 
            type: 'currency', 
            typeAttributes: { 
                currencyCode: { fieldName: 'CurrencyIsoCode' },
                currencyDisplayAs: "code"
            },
            cellAttributes: {
                alignment: 'left'
            },
            actions: [], 
            hideDefaultActions: true 
        },
		{ label: 'Start Date', fieldName: 'StartDate', type: 'date',
            typeAttributes: { 
                year: "numeric", 
                month: "short",  
                day: "numeric", 
                timeZone: "UTC"  
            }, 
            hideDefaultActions: true },
		{ label: 'End Date', fieldName: 'EndDate', type: 'date',
            typeAttributes: { 
                year: "numeric", 
                month: "short",  
                day: "numeric", 
                timeZone: "UTC"  
            }, 
            hideDefaultActions: true },
		{ label: 'Status', fieldName: 'Status', type: 'text', hideDefaultActions: true },
		//{ label: 'Renewal Opportunity Probability Stage', fieldName: 'RenewalOpportunityProbability', type: 'text' },
		//{ label: 'Finance Partner?', fieldName: 'FinancePartner', type: 'text', actions: [], hideDefaultActions: true },
		//{ label: 'Partner Reseller?', fieldName: 'Reseller', type: 'text', actions: [], hideDefaultActions: true },
        { label: 'Reason for Ineligibility', fieldName: 'FailureReason', type: 'customHtml',
            cellAttributes: { 
                tooltip: { fieldName: 'FailureReason' }, // Enables tooltip on hover
                class: 'slds-cell-wrap',
                alignment: 'left'                
            },
            wrapText: true,
            typeAttributes: {
                linkify: true
            }
         }
	];

    @api accountId; 

    connectedCallback() {
        console.log('these are contract id+++++++++'+this.selectedContracts);
        console.log('Account ID:', this.accountId);
  
    }
    renderedCallback() {
        this.dispatchEvent(new CustomEvent('load'));
        console.log('thise are contract id+++++++++'+this.selectedContracts);
        // Pre-select rows if contractIds has values
        if (this.contractIds && this.contractIds.length > 0) {
            const datatable = this.template.querySelector('lightning-datatable');
            if (datatable) {
                datatable.selectedRows = this.contractIds;
            }
        }
    }
    
    @wire(getEligibleContracts, { accountId: '$accountId' })
    wiredContracts({ error, data }) {
        if (data) {
            console.log('Contracts fetched successfully:', data);
            this.contracts = data.contracts.map(contract => {
                return {
                    ...contract,
                    ContractUrl: `/${contract.Id}`,
                    Status: this.transformStatus(contract.Status)
                };
            });
            this.controlCenterConfig = data.config;
            this.nonEligibleContracts = data.nonEligibleActiveContracts.map(contract => {
                return {
                    ...contract,
                    ContractUrl: `/${contract.Id}`,
                    RenewalOpportunityProbability: contract.RenewalOpportunityProbability,
                    FinancePartner: contract.FinancePartner,
                    Reseller: contract.Reseller,
                    FailureReason: contract.FailureReason,
                    Status: this.transformStatus(contract.Status)
                };
            });
            this.eligibleContractLabel = `Available for Upgrade (${this.contracts.length})`;
            this.ineligibleContractLabel = `Ineligible for Upgrade (${this.nonEligibleContracts.length})`; 
            this.greaterThanMaxEligibleContract = this.contracts.length > this.controlCenterConfig.Max_Eligible_Contracts__c;
            this.showNonEligibleContracts = this.nonEligibleContracts.length > 0;
            // Pre-select rows after data is loaded if contractIds has values
            if (this.contractIds && this.contractIds.length > 0) {
                const datatable = this.template.querySelector('lightning-datatable');
                if (datatable) {
                    datatable.selectedRows = this.contractIds;
                }
            }
        } else if (error) {
            console.error('Error fetching contracts:', error);
            this.showToast('Error', 'Unable to fetch contracts.', 'error');
        }
    }

    transformStatus(status) {
        if (status === 'Activated') return 'Active';
        if (status === 'Deactivated') return 'Inactive';
        return status;
    }

    handleRowSelection(event) {
        let controlCenterConfig = this.controlCenterConfig;
        const selectEvent = new CustomEvent('select', {
            detail: {
                selectedRows : this.template.querySelector('lightning-datatable').getSelectedRows(),
                selectedConfig : controlCenterConfig
            }
        });
       this.dispatchEvent(selectEvent);
    
    } 

   

    showToast(title, message, variant) {
        console.log('Showing toast:', { title, message, variant });
        try {
            const toastEvent = new ShowToastEvent({
                title: title,
                message: message,
                variant: variant
            });
            this.dispatchEvent(toastEvent);
        } catch (error) {
            console.error('Error in showToast:', error);
        }
    }

    handleWarningToggle() {
        this.isWarningExpanded = !this.isWarningExpanded;
    }
}