// Dev : Riyaz Shaik
// User story :GTMS-26638
import { LightningElement, api, track, wire } from 'lwc';
import previewApproval from '@salesforce/apex/PreviewApprovalController.previewApproval';
import { getRecord } from 'lightning/uiRecordApi';
import QUOTE_NAME from '@salesforce/schema/SBQQ__Quote__c.Name';
import { FlowNavigationNextEvent } from 'lightning/flowSupport';
import myResource from '@salesforce/resourceUrl/NoDataFound';
export default class PreviewApprovalCustomLwcCmp extends LightningElement {
    @track approvalData = [];
    @track isLoading = true;
    _quoteId;
    quoteName;
    renderFlow = false; 
    noDataFoundImage = myResource;

    @api
    get QuoteId() {
        return this._quoteId;
    }
    set QuoteId(value) {
        console.log('QuoteId set to:', value);
        if (value) {
            this._quoteId = value;
            this.fetchApprovalData();
        }
    }

    @api 
    get SubmitButtonClicked() {
        return this.renderFlow; 
    }

    get hasData() {
        console.log('hasData check:', this.approvalData);
        return this.approvalData && this.approvalData.length > 0;
    }

    @wire(getRecord, { recordId: '$_quoteId', fields: [QUOTE_NAME] })
    wiredQuote({ error, data }) {
        if (data) {
            console.log('Quote data:', data);
            this.quoteName = data.fields.Name.value;
        } else if (error) {
            console.error('Error fetching Quote Name:', error);
        }
    }

    fetchApprovalData() {
        console.log('Fetching approval data for quote:', this._quoteId);
        const COLOR_CLASSES = ["step-green", "step-orange", "step-blue"];
    
        this.isLoading = true;
        previewApproval({ quoteId: this._quoteId })
            .then(result => {
                console.log('Raw approval data:', result);
                this.approvalData = result.map(chain => {
                    console.log('Processing chain:', chain);
                    // Check if this is a Product Approval chain
                    const isProductApproval = chain.chainName && chain.chainName.includes('Product Approval');
                    
                    return {
                        ...chain,
                        isProductApproval: isProductApproval,
                        approvalRuleDetailsList: chain.approvalRuleDetailsList.map((rule, index) => {
                            console.log('Processing rule:', rule);
                            const uniqueFields = new Set();
                            const uniqueFieldLabels = new Set();
                            const uniqueTriggerFields = rule.triggerFields ? rule.triggerFields.filter(field => {
                                const fieldIdentifier = `${field.fieldLabel}-${field.fieldValue}`;
                                if (field.fieldLabel && !uniqueFieldLabels.has(field.fieldLabel)) {
                                    uniqueFields.add(fieldIdentifier);
                                    uniqueFieldLabels.add(field.fieldLabel);
                                    return true;
                                }
                                return false;
                            }) : [];

                            return {
                                ...rule,
                                ruleClass: COLOR_CLASSES[index % COLOR_CLASSES.length],
                                approverDetailsList: rule.approverDetailsList ? rule.approverDetailsList.map(approver => ({
                                    ...approver,
                                    initials: approver.approverName ? approver.approverName.charAt(0).toUpperCase() : ''
                                })) : [],
                                triggerFields: uniqueTriggerFields,
                                formattedTriggerFields: this.formatTriggerFields(uniqueTriggerFields)
                            };
                        }),
                        isExpanded: true,
                        expandIcon: 'utility:chevronup',
                    };
                });
                console.log('Processed approval data:', this.approvalData);
                this.isLoading = false;
            })
            .catch(error => {
                this.isLoading = false;
                console.error('Error in previewApproval:', error);
            });
    }

    formatTriggerFields(triggerFields) {
        if (!triggerFields) return [];
        
        const formattedFields = triggerFields.map(field => {
            const formatted = {
                ...field,
                fieldLabel: field.fieldLabel || field.fieldName?.replace('SBQQ__', '').replace('__c', '').split('_').join(' '),
                displayValue: field.aggregateFunction 
                    ? `${field.aggregateFunction} (${field.filterCondition})`
                    : this.getDisplayValue(field)
            };
            return formatted;
        });
        return formattedFields;
    }

    getDisplayValue(field) {
        if (field.fieldLabel == null && field.fieldLabel == undefined && !field.isChanged) {
            return `No Change since Recall`;
        }
        else if ((field.previousValue === null || field.previousValue === undefined) && !field.isChanged) {
            return `${field.fieldValue}`;
        }
        else if (field.previousValue !== null && field.previousValue !== undefined && field.isChanged) {
            return `${field.previousValue} → ${field.fieldValue}`;
        }
        return field.fieldValue;
    }

    toggleExpand(event) {
        const chainId = event.currentTarget.dataset.id;
        this.approvalData = this.approvalData.map(chain => ({
            ...chain,
            isExpanded: chain.chainId === chainId ? !chain.isExpanded : chain.isExpanded,
            expandIcon: chain.chainId === chainId 
                ? (!chain.isExpanded ? 'utility:chevronup' : 'utility:chevrondown')
                : chain.expandIcon
        }));
    }

    handleSubmit() {
        this.renderFlow = true;
        this.dispatchEvent(new FlowNavigationNextEvent());
    }

    handleReturn() {
        this.renderFlow = false;
        this.dispatchEvent(new FlowNavigationNextEvent());
    }
}