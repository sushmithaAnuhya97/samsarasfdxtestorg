import { LightningElement, api, wire } from 'lwc';
import getAmendmentOpportunities from '@salesforce/apex/flex_OpenAmendmentOpportunityController.getAmendmentOpportunities';

export default class FlexOpenAmendmentOpportunity extends LightningElement {
    //contractId = '800WG00000BErpJYAT'; // This will be passed dynamically or set from a parent component
    @api contractIds;
    //@api contractIds = [];
    opportunities = []; // Store the fetched opportunities
    isLoading = false;

    // Define the columns with clickable opportunity name
    columns = [
        {
            label: 'Opportunity Name',
            fieldName: 'recordLink', // Custom field that contains the URL
            type: 'url',
            typeAttributes: {
                label: { fieldName: 'Name' },
                target: '_blank',   // Opens the record in a new tab
            }, hideDefaultActions: true
        },
        { 
            label: 'Contract Number', 
            fieldName: 'contractLink',
            type: 'url',
            typeAttributes: {
                label: { fieldName: 'contractNumber' },
                target: '_blank'
            },
            hideDefaultActions: true 
        },
        { 
            label: 'Owner', 
            fieldName: 'ownerName', 
            hideDefaultActions: true 
        },
        { label: 'Stage', fieldName: 'StageName', hideDefaultActions: true },
        { label: 'Close Date', fieldName: 'CloseDate', type: 'date', hideDefaultActions: true },
        { label: 'Amount', fieldName: 'Amount', type: 'currency', hideDefaultActions: true },
        { label: 'ACV Bookings', fieldName: 'ACV_Bookings_SOT__c', type: 'currency', hideDefaultActions: true },
    ];

    // Fetch the opportunities based on the contractId
    @wire(getAmendmentOpportunities, { lstContractIds: '$contractIds' })
    wiredOpportunities({ error, data }) {
        if (data) {
            console.log('these are contract ids------@#@#@###->'+this.contractIds);
            console.log('these are data------@#@#@###->'+JSON.stringify(data));
            this.opportunities = data.map(opportunity => {
                return {
                    ...opportunity,
                    recordLink: `/lightning/r/Opportunity/${opportunity.Id}/view`,  // Dynamic link to the Opportunity record page
                    contractLink: `/lightning/r/Contract/${opportunity.SBQQ__AmendedContract__c}/view`, // Dynamic link to the Contract record page
                    ownerName: opportunity.Owner?.Name,
                    contractNumber: opportunity.SBQQ__AmendedContract__r?.ContractNumber
                };
            });
            this.isLoading = false;
        } else if (error) {
            console.error('Error fetching opportunities: ', error);
            this.isLoading = false;
        }
    }

    // Show loading indicator when data is being fetched
    get showSpinner() {
        return this.isLoading;
    }

    connectedCallback() {
                    console.log('these are contract ids------@#@#@###->'+this.selectedContracts);

        this.isLoading = true;
    }
}