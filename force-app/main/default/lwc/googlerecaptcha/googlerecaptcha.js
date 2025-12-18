/**
* Created by vikasmishra on 2021-06-07.
*/
import {LightningElement, api, track} from 'lwc';
import verifyRecaptcha from '@salesforce/apex/GoogleReCaptchaController.verifyCaptcha';
import { FlowAttributeChangeEvent, FlowNavigationNextEvent, FlowNavigationBackEvent } from 'lightning/flowSupport';
export default class Googlerecaptcha extends LightningElement {

    @api recaptchaResponse
    @track mandatorySubmit
    @api availableActions = [];

    connectedCallback() {
        this.template.addEventListener('beforeunload', this.beforeUnloadHandler);
        let Component = this;
        document.addEventListener("grecaptchaVerified", function(e) {
            Component.recaptchaResponse = e.detail.response;
        });

        document.addEventListener("grecaptchaExpired", function(e) {
            alert('expired');
        });

    }

    renderedCallback() {
        let divElement = this.template.querySelector('div.recaptchaCheckbox');
        let payload = { element: divElement, badge: 'bottomright' };
        document.dispatchEvent(new CustomEvent("grecaptchaRender", { "detail": payload }));
    }

    beforeUnloadHandler(event) {
        event.returnValue = "Are you sure you want to leave? All changes will be lost!";
    }

    handleGoNext() {
        this.mandatorySubmit = undefined;
        verifyRecaptcha({recaptchaResponse: this.recaptchaResponse})
            .then(result => {
                // check if NEXT is allowed on this screen
                if (this.availableActions.find(action => action === 'NEXT') && result ) {
                    // navigate to the next screen
                    const navigateNextEvent = new FlowNavigationNextEvent();
                    this.dispatchEvent(navigateNextEvent);
                }
                else{
                    this.mandatorySubmit = 'Please Fill Mandatory Values';
                }
            })
            .catch(error => {
                console.log(error);
            });

    }

    handleGoPrevious() {
        // check if NEXT is allowed on this screen
        if (this.availableActions.find(action => action === 'BACK')) {
            // navigate to the next screen
            const navigateBackEvent = new FlowNavigationBackEvent();
            this.dispatchEvent(navigateBackEvent);
        }
    }
}