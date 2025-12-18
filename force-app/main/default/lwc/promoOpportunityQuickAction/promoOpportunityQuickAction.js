import { LightningElement, api, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import {CurrentPageReference} from 'lightning/navigation';

import createPromoOpportunities from '@salesforce/apex/GS_OpportunityReturnProcessServiceAsync.createPromoOpportunities';


export default class PromoOpportunityQuickAction extends LightningElement {

    recordId;

    connectedCallback() {
        if(this.recordId != '' && this.recordId != undefined && this.recordId != null){
            this.handleCreatePromo();
        }
        this.showModal = true;
        // this.showToast({
        //     title: 'Record ID',
        //     message: `Current Record ID: ${this.recordId}`,
        //     variant: 'info'
        // });
    }

    @wire(CurrentPageReference)
    getStateParameters(currentPageReference) {
        if (currentPageReference) {
            console.log('recordId FROM WIRE', currentPageReference.state.recordId);
            this.recordId = currentPageReference.state.recordId;
        }
    }

    handleCreatePromo(){
        if (!this.recordId) {
            this.showToast({
                title: 'Error',
                message: 'No record ID available to create promo opportunity',
                variant: 'error'
            });
            return;
        }

        // Convert recordId to the format expected by the Apex method
        const filteredOpportunitiesIds = [this.recordId];
        const triggeredOppsIds = [this.recordId];
        
        createPromoOpportunities({ 
            filteredOpportunitiesIds: filteredOpportunitiesIds, 
            triggeredOppsIds: triggeredOppsIds, 
            oppMapTest: null,
            isLWC: true 
        })
        .then(result => {
            this.showToast({
                title: 'Success',
                message: 'Promo opportunity created successfully',
                variant: 'success'
            });
        })
        .catch(error => {
            console.error('Error creating promo opportunity:', error);
            this.showToast({
                title: 'Error',
                message: 'Failed to create promo opportunity: ' + (error.body?.message || error.message || 'Unknown error'),
                variant: 'error'
            });
        });
    }

    /**
     * Generic method to show a toast notification.
     * @param {Object} options - Toast options.
     * @param {string} options.title - The title of the toast.
     * @param {string} options.message - The message to display.
     * @param {string} [options.variant='info'] - The variant of the toast (info, success, warning, error).
     * @param {string} [options.mode='dismissable'] - The mode of the toast (dismissable, pester, sticky).
     */
    showToast({ title, message, variant = 'info', mode = 'dismissable' }) {
        const evt = new ShowToastEvent({
            title,
            message,
            variant,
            mode
        });
        this.dispatchEvent(evt);
    }
}