import { LightningElement, api, wire, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import updateACVValues from '@salesforce/apex/UpdateSplitACVValuesController.updateACVValues';

export default class UpdateSplitACVValues extends LightningElement {
    @api recordId
    @track isLoading= false;

    @api
    invoke() {
        this.isLoading = true;
        updateACVValues({ recordId: this.recordId })
            .then((result) => {
                this.showToast('Success', 'Split New ACV & Split Renewal ACV are being updated. Please refresh the page in a few minutes.', 'success');
            })
            .catch((error) => {
                this.showToast('Error', error.body.message, 'error');
            })
            .finally(() => {
                this.isLoading = false;
            });
    }

    showToast(title, message, variant) {
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,
        });
        this.dispatchEvent(event);
    }
}