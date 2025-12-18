import { LightningElement, api } from 'lwc';
import isUserSubscribedCall from '@salesforce/apex/FeatureRequestsHelper.isUserSubscribed';

export default class FeatureRequestDetailsLwc extends LightningElement {
    @api recordId;
    isUserSubscribed = false;
    actionToBeTaken = 'CHECK';
    showProcessing = false;
    connectedCallback() {
        this.handlePageLoad();
        
    } 

    handlePageLoad() {
        this.showProcessing = true;
        this.callApexHandler();
    }
    performSubscribe() {
        this.showProcessing = true;
        this.actionToBeTaken = 'SUBSCRIBE';
        this.callApexHandler();
    }
    performUnsubscribe() {
        this.showProcessing = true;
        this.actionToBeTaken = 'UNSUBSCRIBE';
        this.callApexHandler();
    }
    callApexHandler() {
        isUserSubscribedCall({recordId : this.recordId, action: this.actionToBeTaken})
        .then(result => {
            console.log('result ' + result);
            this.isUserSubscribed = result;
            this.showProcessing = false;

        }) .catch(error => {
            console.log(error);
            this.error = error;
            this.showProcessing = false;
        }); 
    }

}