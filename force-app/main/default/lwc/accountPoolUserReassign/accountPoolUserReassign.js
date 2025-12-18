import { LightningElement, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';
import { getRecordNotifyChange } from 'lightning/uiRecordApi';
import checkEligibility from '@salesforce/apex/AccountPoolReassignController.checkEligibility';
import reassignFromPool from '@salesforce/apex/AccountPoolReassignController.reassignFromPool';

export default class AccountPoolUserReassign extends LightningElement {
    _recordId;
    isWorking = false;
    showPopup = false;

    @api
    get recordId() {
        return this._recordId;
    }
    set recordId(value) {
        const shouldInitialize = !this._recordId && value;
        this._recordId = value;
        if (shouldInitialize) {
            this.initialize();
        }
    }

    async initialize() {
        this.isWorking = true;
        try {
            const res = await checkEligibility({ recordId: this.recordId });
            if (res && res.error) {
                this.closeWithError(res.error);
                return;
            }
            this.showPopup = true;
        } catch (e) {
            this.closeWithError(e?.body?.message || e?.message || 'Unexpected error');
        } finally {
            this.isWorking = false;
        }
    }

    async handleConfirm() {
        if (this.isWorking) return;
        this.isWorking = true;
        try {
            const response = await reassignFromPool({ recordIds: [this.recordId] });
            const messages = response?.messages || [];
            if (messages.length > 0) {
                this.closeWithError(messages.join('\n'));
                return;
            }
            this.closeWithSuccess('Reassigned Successfully.');
        } catch (e) {
            this.closeWithError(e?.body?.message || e?.message || 'Unexpected error');
        } finally {
            this.isWorking = false;
        }
    }

    handleCancel() {
        this.close();
    }

    close() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }

    closeWithError(message) {
        this.dispatchEvent(new ShowToastEvent({ title: 'Error', message, variant: 'error' }));
        this.close();
    }

    closeWithSuccess(message) {
        this.dispatchEvent(new ShowToastEvent({ title: 'Success', message, variant: 'success' }));
        try {
            getRecordNotifyChange([{ recordId: this.recordId }]);
        } catch (ignore) {}
        this.close();
    }
}