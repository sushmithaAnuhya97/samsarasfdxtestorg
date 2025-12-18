import { LightningElement, api, wire } from 'lwc';
import { FlowAttributeChangeEvent } from 'lightning/flowSupport';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import ACCOUNT_NAME from '@salesforce/schema/Account.Name';
import ACCOUNT_OWNER_NAME from '@salesforce/schema/Account.Owner.Name';

export default class DuplicateAccountLookup extends LightningElement {
    _value;
    @api get value() { return this._value; }
    set value(v) { this._value = v; }

    @api fieldLabel = 'Duplicate Account Id';
    @api introText;

    // Keep wire in case you want to log/debug, but the HTML now uses lightning-record-view-form

    handleLookupChange(event) {
        const accId = (event.detail && (event.detail.value || event.detail.recordId)) || (event.target && event.target.value);
        this.value = accId;
        this.dispatchEvent(new FlowAttributeChangeEvent('value', this.value));
    }

    handleIdInputChange(event) {
        const raw = (event && event.target && event.target.value) ? String(event.target.value).trim() : '';
        let parsed = raw;
        try {
            const urlMatch = raw.match(/\b(001[A-Za-z0-9]{12,15})\b/);
            if (urlMatch && urlMatch[1]) {
                parsed = urlMatch[1];
            }
        } catch (e) { /* noop */ }
        this.value = parsed;
        this.dispatchEvent(new FlowAttributeChangeEvent('value', this.value));
    }

    @api
    validate() {
        const isValid = !!this.value;
        return { isValid, errorMessage: isValid ? null : 'Please select a Duplicate Account.' };
    }
}