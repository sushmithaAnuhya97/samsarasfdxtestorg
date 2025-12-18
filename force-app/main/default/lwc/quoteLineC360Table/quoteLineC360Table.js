import { LightningElement, api, wire } from 'lwc';
import getQuoteLines from '@salesforce/apex/QuoteLineC360Controller.getQuoteLines';
import { FlowNavigationNextEvent, FlowNavigationBackEvent } from 'lightning/flowSupport';

export default class QuoteLineC360Table extends LightningElement {
    @api quoteId;
    @api host;
    quoteLines = [];
    error;
    showSpinner = true;

    get showFooter()
    {
        return this.host == 'Quote Approval' && !( this.quoteLines && this.quoteLines.length == 0 ) && !this.showSpinner;
    }

    // Fetch quote lines from Apex when quoteId changes
    @wire(getQuoteLines, { quoteId: '$quoteId' })
    wiredQuoteLines({ error, data }) {
        if (data) {
            this.showSpinner = false;
            this.quoteLines = data;
            if( this.quoteLines && this.quoteLines.length == 0 && this.host == 'Quote Approval')
            {
                this.dispatchEvent(new FlowNavigationNextEvent());
            }
        } 
        else if (error) {
            this.error = error;
            this.showSpinner = false;
            this.quoteLines = [];
        }
    }

    // True if there is data to display
    get hasData() {
        return this.quoteLines && this.quoteLines.length > 0;
    }

    // Quote lines that require approval
    get requiresApproval() {
        return this.quoteLines;
    }

    handleNext() 
    {
        this.dispatchEvent(new FlowNavigationNextEvent());
    }

    handlePrevious()
    {
        this.dispatchEvent(new FlowNavigationBackEvent());
    }    
}