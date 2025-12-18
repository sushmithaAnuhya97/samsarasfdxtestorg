import { LightningElement, api} from 'lwc';
import getQuoteLinesByQuoteId from '@salesforce/apex/QuoteLineController.getQuoteLinesByQuoteId';

export default class MultiCamAlertMessage extends LightningElement {
    @api recordId; 
    showAlert = false;
    showError = false;
    
    alertMessage = 'AI Multi-cam only works with VG55 or VG54. Please add VG55 or VG54 to this quote or confirm the customer has a prior VG55/54 purchase.';
    errorMessage = '';

    connectedCallback() {
        this.checkForAlert();
    }

    async checkForAlert() {
        if (this.recordId) {
            try {
                const response = await getQuoteLinesByQuoteId({ quoteId: this.recordId });
                this.showAlert = response.showAlert || false;
                this.showError = false;
                this.errorMessage = '';
            } catch (error) {
                this.showAlert = false;
                this.showError = true;
                this.errorMessage = 'We were not able to validate your quote as expected. If AI Multi Cam is included, a VG55 or VG54 is required for functionality. Please add VG55 or VG54 to this quote or confirm the customer has a prior VG55/54 purchase.';
            }
        }
    }
}