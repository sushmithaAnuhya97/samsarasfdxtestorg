import { LightningElement, api, wire, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { FlowNavigationNextEvent, FlowNavigationFinishEvent } from 'lightning/flowSupport';

export default class OpptyAndQuoteValueMatchDataFlowCmp extends NavigationMixin(LightningElement) {

    @api recordId;
    @api availableActions = [];
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