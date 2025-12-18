let RUNNING = false;

import { LightningElement, api, track } from 'lwc';
import createOLIPromobutton from '@salesforce/apex/CreatePromoOLIController.createOLIPromobutton';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class PromoOLIButton extends LightningElement {
    @api recordId;
    @track isLoading = false; // spinner state

    @api
    async invoke() {
        if (RUNNING) return;
        RUNNING = true;
        this.isLoading = true; // show spinner

        try {
            if (!this.recordId) {
                this.toast('Error', 'No Opportunity Id found.', 'error');
                return;
            }
            const result = await createOLIPromobutton({ OppId: this.recordId });
            const variant = this.variantFor(result);
            const title = variant === 'success' ? 'Success' : variant === 'info' ? 'Info' : 'Warning';
            this.toast(title, result || 'Done', variant);
        } catch (e) {
            this.toast('Error', e?.body?.message || e?.message || 'Unexpected error', 'error');
        } finally {
            RUNNING = false;
            this.isLoading = false; // hide spinner
        }
    }

    variantFor(msg = '') {
  const m = (msg || '').toLowerCase();

  // Info cases
  if (
    m.includes('disabled') ||                              
    m.includes('already promo product is linked') ||       
    m.includes('dont have access') ||                   
    m.includes('does not meet the criteria') ||          
    m.includes('criteria mismatch') ||
    m.includes('no opportunitylineitem')
  ) {
    return 'info';
  }

  // Success cases
  if (m.includes('success') || m.includes('created')) {
    return 'success';
  }
}
    toast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant, mode: 'dismissable' }));
    }
}