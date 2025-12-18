import { LightningElement, api, wire, track } from 'lwc';
import fetchOpportunitiesForUpgradedOpportunity from '@salesforce/apex/FlexContractOpportunityController.fetchOpportunitiesForUpgradedOpportunity';

export default class FlexContractOpportunityList extends LightningElement {

    @api upgradedOpportunityId;
    @api upgradedOpportunityName;
    @track exceptions = [];
    @track error;
    @track accountName = '';
    @track contractId;

    @wire(fetchOpportunitiesForUpgradedOpportunity, { opportunityId: '$upgradedOpportunityId' })
    wiredOpportunities({ error, data }) {
        console.log('Opportunity ID:', this.upgradedOpportunityId);

        if (data) {
            console.log('Data received:', JSON.stringify(data));

            this.exceptions = data.map(opp => {
                const prioritizedExceptions = [
                    'Payment Terms Opportunity only exception', 
                    'Payment Type Opportunity only Exception', 
                    'Custom Schedule', 
                    'Stub Payment'
                ];
             // Ensure the following fields always appear first in the Reasons column (if applicable):
                // 1. Payment Terms Opportunity only exception  
                // 2. Payment Type Opportunity only Exception  
                // 3. Custom Schedule  
                // 4. Stub Payment 
                const exceptionsArray = Object.values(opp.exceptions || {})
                    .sort((a, b) => {
                        const aIndex = prioritizedExceptions.indexOf(a.label);
                        const bIndex = prioritizedExceptions.indexOf(b.label);
                        if (aIndex === -1 && bIndex === -1) return 0;
                        if (aIndex === -1) return 1;
                        if (bIndex === -1) return -1;
                        return aIndex - bIndex;
                    })
                    //.map(value => ({ label: `• ${value.label}`, value: value.value })); // Array of label-value pairs
                    .map(value => ({ 
                        label: `• ${value.label}`,
                        value: typeof value.value === 'boolean' 
                            ? (value.value ? 'True' : 'False')  // Convert boolean to capitalized string
                            : value.value.charAt(0).toUpperCase() + value.value.slice(1) // Capitalizing first letter if string
                    }));

                return {
                    opportunityId: opp.opportunityId,
                    opportunityName: opp.opportunityName,
                    opportunityUrl: `/lightning/r/Opportunity/${opp.opportunityId}/view`,
                    opportunityOwner: opp.opportunityOwnerName,
                    opportunityOwnerUrl: `/lightning/r/User/${opp.opportunityOwnerId}/view`,
                    accountName: opp.accountName,
                    contractId: opp.contractId,
                    contractNumber: opp.contractNumber,
                    contractUrl: `/lightning/r/Contract/${opp.contractId}/view`,
                    exceptionsArray: exceptionsArray 
                };
            });
            // The table is ordered by Contract Number DESC
            this.exceptions.sort((a, b) => {
                if (a.contractNumber < b.contractNumber) return 1;
                if (a.contractNumber > b.contractNumber) return -1;
                return 0;
            });

        } else if (error) {
            console.error('Error fetching exceptions:', JSON.stringify(error));
            this.error = error;
            this.exceptions = [];
        }
    }
}