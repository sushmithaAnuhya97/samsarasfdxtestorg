import { LightningElement, api, wire ,track} from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import getContractDetails from '@salesforce/apex/FlexSelectedContractDetails.getContractDetails';

export default class FlexSelectedContractDetails extends NavigationMixin(LightningElement) {
    @api contractIds = [];
    showSelectionControls = true;
    showReplacementControls = true;    
    contracts = [];
    isExpanded = false;
    @track totalContracts 
    columns = [
        { 
            label: 'Contract Number',
            fieldName: 'contractUrl',
            type: 'url',
            typeAttributes: {
                label: { fieldName: 'ContractNumber' },
                target: '_blank'
            }, hideDefaultActions: true
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
        { 
            label: 'Start Date', 
            fieldName: 'StartDate',
            typeAttributes: { 
                year: "numeric", 
                month: "short",  
                day: "numeric", 
                timeZone: "UTC"  
            }, 
            type: 'date', hideDefaultActions: true
        },
        { 
            label: 'End Date', 
            fieldName: 'EndDate',
            typeAttributes: { 
                year: "numeric", 
                month: "short",  
                day: "numeric", 
                timeZone: "UTC"  
            }, 
            type: 'date', hideDefaultActions: true
        },
        { 
            label: 'Status', 
            fieldName: 'Status', 
            type: 'text',
            hideDefaultActions: true
        }
    ];

    @wire(getContractDetails, { contractIds: '$contractIds' })
    wiredContracts({ error, data }) {
        if (data) {
            this.contracts = data.map(contract => ({
                ...contract,
                contractUrl: `/${contract.Id}`
            }));

            this.totalContracts = this.contracts?this.contracts.length : NaN;
        } else if (error) {
            console.error('Error fetching contracts:', error);
        }
    }

    handleSectionToggle() {
        this.isExpanded = !this.isExpanded;
    }

    get iconName() {
        return this.isExpanded ? 'utility:chevrondown' : 'utility:chevronright';
    }
}