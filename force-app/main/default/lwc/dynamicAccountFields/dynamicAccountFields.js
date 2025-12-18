import { LightningElement, api, track, wire } from 'lwc';
import getFieldsForReason from '@salesforce/apex/AccountFieldSetProvider.getFieldsForReason';
import getReasonText from '@salesforce/apex/AccountFieldSetProvider.getReasonText';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import { getRecord } from 'lightning/uiRecordApi';
import ACCOUNT_OBJECT from '@salesforce/schema/Account';

export default class DynamicAccountFields extends LightningElement {
    @api recordId;
    @api submissionReason;
    @api showDebug = false;

    @track fieldApiNames = [];
    @track error;
    @track invalidFields = [];
    isLoading = true;
    introText;

    objectInfo;
    @track editableFieldApiNames = [];
    @track readOnlyFieldApiNames = [];
    recordData;
    savedValues = {};
    _wiredChangeHandlers = false;
    storageKey;
    @api value; 

    @wire(getObjectInfo, { objectApiName: ACCOUNT_OBJECT })
    wiredObjectInfo({ data, error }) {
        if (data) {
            this.objectInfo = data;
            if (!this.isLoading && this.fieldApiNames && this.fieldApiNames.length >= 0) {
                this.fieldApiNames = this.filterValidFields(this.fieldApiNames);
                this.splitEditableVsReadonly();
            }
        } else if (error) {
            this.objectInfo = undefined;
        }
    }

    get wiredFields() {
        const names = this.fieldApiNames || [];
        return names.map(n => `Account.${n}`);
    }

    @wire(getRecord, { recordId: '$recordId', fields: '$wiredFields' })
    wiredRecord({ data, error }) {
        if (data) {
            this.recordData = data;
            if (Object.keys(this.savedValues).length === 0) {
                try {
                    // Try load from session storage first
                    this.loadFromSession();
                    if (Object.keys(this.savedValues).length === 0) {
                        const init = {};
                        (this.fieldApiNames || []).forEach(name => {
                            const node = data.fields && data.fields[name];
                            if (node) {
                                init[name] = node.value;
                            }
                        });
                        this.savedValues = init;
                        this.saveToSession();
                        try { this.value = JSON.stringify(this.savedValues); } catch (e) { /* noop */ }
                    }
                    if (Object.keys(this.savedValues).length > 0 && !this.value) {
                        try { this.value = JSON.stringify(this.savedValues); } catch (e) { /* noop */ }
                    }
                } catch (e) {
                }
            }
        } else if (error) {
            this.recordData = undefined;
        }
    }

    get hasFields() {
        return this.fieldApiNames && this.fieldApiNames.length > 0;
    }

    get showNoFields() {
        return !this.isLoading && !this.hasFields && !this.error;
    }

    connectedCallback() {
        this.storageKey = `dynamicAccountFields:${this.recordId || ''}:${this.submissionReason || ''}`;
        this.loadFieldList();
        this.loadFromSession();
        if (Object.keys(this.savedValues || {}).length > 0 && !this.value) {
            try { this.value = JSON.stringify(this.savedValues); } catch (e) { /* noop */ }
        }
    }

    async loadFieldList() {
        this.isLoading = true;
        this.error = undefined;
        try {
            // Fetch ordered per-field configs and intro text from CMDT via Apex (in parallel)
            const [rows, text] = await Promise.all([
                getFieldsForReason({ submissionReason: this.submissionReason }),
                getReasonText({ submissionReason: this.submissionReason })
            ]);
            this.introText = text || '';
            let list = (rows || [])
                .map(r => r && r.apiName)
                .filter(Boolean);
            // Expand composite address pseudo-fields for UI rendering
            list = list.flatMap(fieldName => {
                if (fieldName === 'BillingAddress') {
                    return ['BillingStreet', 'BillingCity', 'BillingState', 'BillingPostalCode', 'BillingCountry'];
                }
                if (fieldName === 'ShippingAddress') {
                    return ['ShippingStreet', 'ShippingCity', 'ShippingState', 'ShippingPostalCode', 'ShippingCountry'];
                }
                return [fieldName];
            });
            this.fieldApiNames = this.filterValidFields(list);
            this.splitEditableVsReadonly();
        } catch (e) {
            this.error = (e && e.body && e.body.message) || e.message || 'Unknown error';
            this.fieldApiNames = [];
        } finally {
            this.isLoading = false;
        }
    }

    filterValidFields(list) {
        if (!this.objectInfo || !this.objectInfo.fields) {
            return list;
        }
        const available = this.objectInfo.fields;
        const valid = [];
        const invalid = [];
        list.forEach(name => {
            if (available[name]) {
                valid.push(name);
            } else {
                invalid.push(name);
            }
        });
        this.invalidFields = invalid;
        return valid;
    }

    splitEditableVsReadonly() {
        if (!this.objectInfo || !this.objectInfo.fields) {
            this.editableFieldApiNames = this.fieldApiNames;
            this.readOnlyFieldApiNames = [];
            return;
        }
        const available = this.objectInfo.fields;
        const editable = [];
        const readonly = [];
        this.fieldApiNames.forEach(name => {
            const def = available[name];
            if (def && def.updateable) {
                editable.push(name);
            } else {
                readonly.push(name);
            }
        });
        this.editableFieldApiNames = editable;
        this.readOnlyFieldApiNames = readonly;
    }

    @api
    validate() {
        let allValid = true;
        const missingEditable = [];
        const inputs = this.template.querySelectorAll('lightning-input-field');
        if (inputs && inputs.length) {
            inputs.forEach(inp => {
                const value = inp && 'value' in inp ? inp.value : undefined;
                const required = !!inp.required;
                const isMissing = required && (value === null || value === undefined || (typeof value === 'string' && value.trim() === ''));
                if (typeof inp.reportValidity === 'function') {
                    inp.reportValidity();
                }
                if (isMissing) {
                    const fname = inp.fieldName || (inp.dataset && inp.dataset.field);
                    if (fname) {
                        missingEditable.push(fname);
                    }
                }
            });
        }

        const missingReadonly = [];
        if (this.recordData && this.readOnlyFieldApiNames && this.readOnlyFieldApiNames.length) {
            this.readOnlyFieldApiNames.forEach(name => {
                const fieldNode = this.recordData.fields && this.recordData.fields[name];
                const value = fieldNode ? fieldNode.value : undefined;
                const isMissing = value === null || value === undefined || (typeof value === 'string' && value.trim() === '');
                if (isMissing) {
                    missingReadonly.push(name);
                }
            });
        }

        const missing = [...missingEditable, ...missingReadonly];
        if (missing.length) {
            allValid = false;
            this.error = `Missing required values for: ${missing.join(', ')}`;
        } else {
            this.error = undefined;
        }

        return { isValid: allValid, errorMessage: this.error };
    }

    handleSubmit(event) {
        const result = this.validate();
        if (!result.isValid) {
            event.preventDefault();
        }
    }

    renderedCallback() {
        const inputs = this.template.querySelectorAll('lightning-input-field');
        if (inputs && inputs.length) {
            if (!this._wiredChangeHandlers) {
                inputs.forEach(inp => {
                    inp.addEventListener('change', this.handleFieldChange.bind(this));
                });
                this._wiredChangeHandlers = true;
            }

            inputs.forEach(inp => {
                const fname = inp.fieldName || (inp.dataset && inp.dataset.field);
                if (!fname) {
                    return;
                }
                if (this.savedValues.hasOwnProperty(fname)) {
                    try {
                        inp.value = this.savedValues[fname];
                    } catch (e) {
                    }
                }
            });
        }
    }

    handleFieldChange(event) {
        const fieldName = event.target.fieldName || (event.target.dataset && event.target.dataset.field);
        const value = (event.detail && typeof event.detail.value !== 'undefined') ? event.detail.value : event.target && ('value' in event.target) ? event.target.value : undefined;
        if (fieldName) {
            this.savedValues[fieldName] = value;
            this.saveToSession();
            try {
                this.value = JSON.stringify(this.savedValues);
            } catch (e) {
            }
        }
    }

    handleSuccess() {}
    handleError() {}

    loadFromSession() {
        if (!this.storageKey) {
            return;
        }
        try {
            const raw = window.sessionStorage && window.sessionStorage.getItem(this.storageKey);
            if (raw) {
                const parsed = JSON.parse(raw);
                if (parsed && typeof parsed === 'object') {
                    this.savedValues = parsed;
                    try { this.value = JSON.stringify(this.savedValues); } catch (e) { /* noop */ }
                }
            }
        } catch (e) {
        }
    }

    saveToSession() {
        if (!this.storageKey) {
            return;
        }
        try {
            if (window.sessionStorage) {
                window.sessionStorage.setItem(this.storageKey, JSON.stringify(this.savedValues || {}));
            }
        } catch (e) {
        }
    }
}