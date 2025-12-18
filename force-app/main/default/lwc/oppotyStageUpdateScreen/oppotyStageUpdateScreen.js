import { LightningElement, api, track, wire } from 'lwc';
import BIGDEAL_IMAGE from '@salesforce/resourceUrl/BigDealClosing';
import STANDARD_IMAGE from '@salesforce/resourceUrl/ClosingOpportunity';
import updateOpportunity from '@salesforce/apex/SubmitToClosingController.updateOpportunity';
import { FlowNavigationNextEvent, FlowNavigationBackEvent, FlowNavigationFinishEvent } from 'lightning/flowSupport';
import sendFreeTrialEmail from '@salesforce/apex/SubmitToClosingController.sendFreeTrialEmail';
import { getRecord } from 'lightning/uiRecordApi';
import FREE_TRIAL_PURCHASE_FIELD from '@salesforce/schema/Opportunity.Free_Trial_Purchase__c';

const FREE_TRIAL_RETURN_EMAIL_TRIGGER_VALUES = ['Partial Buy', 'No Purchase'];
export default class OppotyStageUpdateScreen extends LightningElement {
    @api opportunity;
    @api availableActions = [];

    @track showSpinner = false;
    @track showBigDealForm = false;
    @track showCongrats = false;
    @track errorMessage = '';
    @track winStory = '';
    @track thankYou = '';
    @track showEmailPreview = false;
    @track stageUpdated = false;
    @track showNotification = false;
    @track notificationMessage = '';
    @track notificationIcon = '';
    @track notificationIconVariant = '';
    @track notificationClass = '';
    @track freeTrialPurchaseValue;
    @track userFriendlyErrorMessage = '';
    
    bigDealImageUrl = BIGDEAL_IMAGE;
    standardImageUrl = STANDARD_IMAGE;
    notificationTimeout;
    freeTrialReturnEmailTrigValues = FREE_TRIAL_RETURN_EMAIL_TRIGGER_VALUES;

    @wire(getRecord, { recordId: '$opportunity.Id', fields: [FREE_TRIAL_PURCHASE_FIELD] })
    wiredOpportunity({ error, data }) {
        if (data) {
            this.freeTrialPurchaseValue = data.fields.Free_Trial_Purchase__c.value;
        } else if (error) {
            this.freeTrialPurchaseValue = undefined;
        }
    }

    get showSubmitButton() {
        return !this.showCongrats && !this.showBigDealForm;
    }

    get isBigDeal() {
        return this.opportunity && this.opportunity.Big_Deal_Alert__c === true;
    }

    @api get virtualBellWinStory() {
        return this.winStory;
    }
    @api get virtualBellThankYou2() {
        return this.thankYou;
    }

    get opportunityUrl() {
        return this.opportunity && this.opportunity.Id ? `https://samsara--uat.my.salesforce.com/${this.opportunity.Id}` : '';
    }

    get showBigDealEmailPreview() {
        return this.isBigDeal && this.winStory.trim() && this.thankYou.trim();
    }

    get nextButtonLabel() {
        return this.availableActions && this.availableActions.includes('NEXT') ? 'Next' : 'Finish';
    }

    connectedCallback() {
        console.log('LWC connectedCallback: opportunity:', this.opportunity);
        if (!this.isBigDeal) {
            console.log('Not a big deal, calling updateStageForStandardDeal');
            this.updateStageForStandardDeal();
        }
    }

    async handleSendFreeTrialEmail() {

        /*  Replaced 'Full Buy' with 'Partial Buy'( refer freeTrialReturnEmailTrigValues ) 
            as part of GTMS-28385 - Hitesh Garg - 26th June, 2025 
        */
        if ( this.freeTrialReturnEmailTrigValues.includes( this.freeTrialPurchaseValue ) ) {
            try {
                await sendFreeTrialEmail({ opportunityId: this.opportunity.Id });
                this.showCustomNotification('success', 'Free Trial Email sent successfully');
            } catch (emailError) {
                this.showCustomNotification('error', 'Failed to send Free Trial Email: ' + (emailError.body?.message || emailError.message));
            }
        }
    }

    async updateStageForStandardDeal() {
        this.showSpinner = true;
        try {
            let fields = { StageName: 'Closing' };
            
            // Update the stage now
            try {
                await updateOpportunity({ opportunityId: this.opportunity.Id, fields: fields });
                
                console.log('updateOpportunity success for StageName=Closing');
                this.stageUpdated = true;
                this.showCongrats = true;
                this.showCustomNotification('success', 'Opportunity stage updated to Closing');
                
                // Send Free Trial Email if needed
                await this.handleSendFreeTrialEmail();
            } catch (error) {
                console.error('Error updating opportunity stage:', error);                
                const fullErrorMsg = error.body?.message || error.message;
                this.errorMessage = fullErrorMsg;
                const lastErrorIndex = fullErrorMsg.lastIndexOf('Error:');
                if (lastErrorIndex !== -1) {
                    this.userFriendlyErrorMessage = fullErrorMsg.substring(lastErrorIndex);
                } else {
                    this.userFriendlyErrorMessage = fullErrorMsg;
                }
                // Trigger shake animation on error alert
                setTimeout(() => {
                    const errorBox = this.template.querySelector('.error-alert');
                    if (errorBox) {
                        errorBox.classList.remove('shake');
                        void errorBox.offsetWidth;
                        errorBox.classList.add('shake');
                    }
                }, 0);
                this.showCustomNotification('error', this.errorMessage);
            }
        } catch (error) {
            console.error('Error in updateStageForStandardDeal:', error);
            const fullErrorMsg = error.body?.message || error.message;
            this.errorMessage = fullErrorMsg;
            const lastErrorIndex2 = this.errorMessage.lastIndexOf('Error:');
            if (lastErrorIndex2 !== -1) {
                this.userFriendlyErrorMessage = this.errorMessage.substring(lastErrorIndex2);
            } else {
                this.userFriendlyErrorMessage = this.errorMessage;
            }
            // Trigger shake animation on error alert
            setTimeout(() => {
                const errorBox = this.template.querySelector('.error-alert');
                if (errorBox) {
                    errorBox.classList.remove('shake');
                    void errorBox.offsetWidth;
                    errorBox.classList.add('shake');
                }
            }, 0);
            this.showCustomNotification('error', this.errorMessage);
        }
        this.showSpinner = false;
    }

    async handleConfirmEmailPreview() {
        this.showSpinner = true;
        console.log('handleConfirmEmailPreview called. isBigDeal:', this.isBigDeal, 'opportunity:', this.opportunity?.Id);
            
            try {
                if (this.isBigDeal) {
                    console.log('Updating win story and thank you fields for big deal');
                    // Define fields to update
                    const bigDealFields = {
                        Virtual_Bell_Thank_You_2__c: this.thankYou,
                        Virtual_Bell_Win_Story__c: this.winStory,
                        StageName: 'Closing'
                    };
                    
                    await updateOpportunity({
                        opportunityId: this.opportunity.Id,
                        fields: bigDealFields
                    });
                    
                    console.log('updateOpportunity success for win story and thank you');
                    this.stageUpdated = true;
                    this.showCongrats = true;
                    this.showEmailPreview = false;
                    this.showCustomNotification('success', 'Big deal updated successfully');
                } 
            } catch (error) {
                console.error('Error updating opportunity:', error);
                this.showCustomNotification('error', 'Failed to update opportunity');
            } finally {
                await this.handleSendFreeTrialEmail();
                this.showSpinner = false;
        }
    }

    showCustomNotification(type, message) {
        // Clear any existing timeout
        if (this.notificationTimeout) {
            clearTimeout(this.notificationTimeout);
        }

        // Set notification properties based on type
        switch (type) {
            case 'success':
                this.notificationIcon = 'utility:success';
                this.notificationIconVariant = 'success';
                this.notificationClass = 'custom-notification notification-success';
                break;
            case 'error':
                this.notificationIcon = 'utility:error';
                this.notificationIconVariant = 'error';
                this.notificationClass = 'custom-notification notification-error';
                break;
            case 'warning':
                this.notificationIcon = 'utility:warning';
                this.notificationIconVariant = 'warning';
                this.notificationClass = 'custom-notification notification-warning';
                break;
            case 'info':
                this.notificationIcon = 'utility:info';
                this.notificationIconVariant = 'info';
                this.notificationClass = 'custom-notification notification-info';
                break;
        }

        this.notificationMessage = message;
        this.showNotification = true;

        // Auto-hide after 3 seconds
        this.notificationTimeout = setTimeout(() => {
            this.closeNotification();
        }, 3000);
    }

    closeNotification() {
        const notification = this.template.querySelector('.custom-notification');
        if (notification) {
            notification.classList.add('notification-exit');
            setTimeout(() => {
                this.showNotification = false;
            }, 300);
        } else {
            this.showNotification = false;
        }
    }


    handleInputChange(event) {
        this[event.target.name] = event.target.value;
    }

    handleBackToEdit() {
        this.showEmailPreview = false;
    }
    

    handleNext() {
        if (this.availableActions.find(action => action === 'NEXT')) {
            const navigateNextEvent = new FlowNavigationNextEvent();
            this.dispatchEvent(navigateNextEvent);
        } else{
            const navigateFinishEvent = new FlowNavigationFinishEvent();
            this.dispatchEvent(navigateFinishEvent);
        }
    }

    handleBack() {
        if (this.availableActions.find(action => action === 'BACK')) {
            const navigateBackEvent = new FlowNavigationBackEvent();
            this.dispatchEvent(navigateBackEvent);
        }
    }

}