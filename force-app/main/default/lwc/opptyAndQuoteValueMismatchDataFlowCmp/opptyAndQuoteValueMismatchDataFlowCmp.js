import { LightningElement, api, wire, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { FlowNavigationNextEvent, FlowNavigationFinishEvent } from 'lightning/flowSupport';
import WARNINGLABEL from '@salesforce/label/c.Submit_to_Closing_Warning_Message';
import ERRORLABEL from '@salesforce/label/c.Submit_to_Closing_Error_Message';
export default class OpptyAndQuoteValueMismatchDataFlowCmp extends NavigationMixin(LightningElement) {
    submitToClosingWarningLabel =WARNINGLABEL;
    submitToClosingErrorLabel = ERRORLABEL;
    @api recordId;
    @api availableActions = [];
    @api isWarning;
    buttonLabel = 'Continue';
    _displayValues = '';
    @api
    get displayMessage() {
        return this._displayValues;
    }
    set displayMessage(msgValue) {
        this._displayValues = msgValue;
        this.parsedValues = msgValue
        ? msgValue.split(';')
                    .map(value => value.trim())
                    .filter(value => value !== '')
        : [];
    }
    parsedValues = [];
    connectedCallback() {
        if (this.isWarning) {
            this.buttonLabel = 'Continue';
        } else {
            this.buttonLabel = 'Go Back to Opportunity';
        }
    }
    handleGoNext() {
        if (this.availableActions.find((action) => action === 'NEXT')) {
            this.dispatchEvent(new FlowNavigationNextEvent());
        } else if (this.availableActions.find((action) => action === 'FINISH')) {
            this.dispatchEvent(new FlowNavigationFinishEvent());
        }
    }

    handleBack() {
        window.open(`${window.location.origin}\\${this.recordId}`, '_self');
    }
}