import { LightningElement, api, wire } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import FUTURE_FREE_MONTHS_AMOUNT_FIELD from '@salesforce/schema/SBQQ__Quote__c.Future_Free_Months_Amount__c';
import TOTAL_LICENSE_PRICE_FIELD from '@salesforce/schema/SBQQ__Quote__c.Total_License_Price__c';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { Logger } from 'c/lwcLogger';
import checkForConflicts from '@salesforce/apex/RebateLogicHandler.checkForConflicts';
import getRebateDetails from '@salesforce/apex/RebateLogicHandler.getRebateDetails';
import createUpdateRebateLines from '@salesforce/apex/RebateLogicHandler.createUpdateRebateLines';
import trackJob from '@salesforce/apex/RebateLogicHandler.trackJob';
import dealComponentAssistantHelpURL from '@salesforce/label/c.DealComponemtAssistantHelpURL';
import { getObjectInfo, getPicklistValues  } from "lightning/uiObjectInfoApi";
import BUYOUT_INCUMBENT_FIELD from "@salesforce/schema/SBQQ__Quote__c.Buyout_Incumbent_Provider__c";
import QUOTE_OBJECT from '@salesforce/schema/SBQQ__Quote__c'; 


const FIELDS = [
    FUTURE_FREE_MONTHS_AMOUNT_FIELD,
    TOTAL_LICENSE_PRICE_FIELD

];

export default class RebateComponent extends LightningElement {
    @api recordId;
    showSpinner=true;

    // CPQ Quote fields
    competitorBuyout;
    installationCosts;
    freeMonths;
    freeMonthsValue;
    isInstallationReimbursable;
    lastCalculatedOn;
    ongoingSyncCheckRun=false;
    showRebateDetails=false;
    showRebateSyncError=false;
    showRebateSyncErrorText='';
    saveButtonLabel='Save';
    isMultiline=false;
    quoteObject;
    oneTimeDiscount;

    //visibility control
    disabled=false;
    disableComponent=false;
    shouldTrackJob=false;
    showMultiline=true;
    doNotShowLDS=false;
    disabledInstallationReimbursable=true;
    showOneTimeDiscount=false;

    isMonth = false;
    isMonthValue = true;

    radioGroupValue = 'Months';

    multiSelectOptions;
    multiSelectedValues = [];
    dualValue = '';
    showDual = false;
    disabledDual = true;

    get options() {
        return [
            { label: 'Months', value: 'Months' },
            { label: 'Amount', value: 'Amount' },
        ];
    }
        
    get isInstallationReimbursableOptions() {
        return [
            { label: '--None--', value: '' },
            { label: 'Yes', value: 'Yes' },
            { label: 'No', value: 'No' },
        ];
    }

    connectedCallback(){
        Logger.setComponent(this)
            .setRecordId(this.recordId)
            .initializeUncaughtErrorHandler();
        //this.getRebateDetails();
    }

    defaultRecordTypeId;

    @wire(getObjectInfo, { objectApiName: QUOTE_OBJECT })
    wiredObjectInfo({ error, data }) {
        if (data) {
            this.defaultRecordTypeId = data.defaultRecordTypeId;
        }
    }

    @wire(getPicklistValues, { recordTypeId: '$defaultRecordTypeId', fieldApiName: BUYOUT_INCUMBENT_FIELD })
    multiSelectPicklistValues({ error, data }) {
        if (data) {
            this.multiSelectOptions = data.values.map(picklist => ({
                label: picklist.label,
                value: picklist.value
            }));
        }
    }

    @wire(getRecord, {recordId: '$recordId',fields: FIELDS})
    wiredQuote({data, error}){
        
        if(data){
            
            this.getRebateDetails();
            if(this.quoteObject && data.fields.Future_Free_Months_Amount__c.value){
                this.quoteObject.futureFreeMonthsAmount = data.fields.Future_Free_Months_Amount__c.value;
            }
           // this.checkForRebateSync();
        }else if(error){
            this._log('error', 'wiredQuote', error);
            this._insertLogs();
            this.disableAll();
            this.showRebateSyncError=true;
            this.showRebateSyncErrorText='Component failed to load. Please refresh the page.';
            this.showSpinner=false;

        }
    }

    disableAll(){
        this.disabled=true;
        this.disabledDual = true;
        this.disableComponent=true;
        this.disabledInstallationReimbursable = true;
        this.isMonth = true;
        this.isMonthValue = true;
    }

    getRebateDetails(){
        this.showSpinner=true;
        getRebateDetails({quoteId: this.recordId}).then(result => {
            this.showSpinner=false;

            if(result.newDCArchitecture){
                this.checkForRebateSync();
            }
            if(result.errorMessage){
                this.showRebateSyncError=true;
                this.showRebateSyncErrorText=result.errorMessage;
                this.disableAll();
            }
            if(result.disableDC){
                this.disableAll();
                this.showRebateSyncError=true;
                this.showRebateSyncErrorText=result.disableDCReason;
            }
            this.quoteObject = result;
            this.competitorBuyout = result.competitorBuyoutAmount;

            if(this.competitorBuyout){  
                this.disabledDual = false;
            }

            if(result.buyoutIncumbentProvider) {
                this.multiSelectedValues = result.buyoutIncumbentProvider.split(";");
                this.dualValue = result.buyoutIncumbentProvider.replaceAll(';', ',') ;
            }

            this.installationCosts = result.totalEstimatedInstallationCosts;
            this.isInstallationReimbursable = result.isInstallationReimbursable;
            this.oneTimeDiscount = result.oneTimeDiscount;
            this.isMultiline = result.isDCMultiline;
            this.freeMonths = result.futureFreeMonths;
            this.freeMonthsValue = result.futureFreeMonthsAmount;
            this.radioGroupValue = result.futureFreeServiceType;
            this.isMonth = result.futureFreeServiceType != 'Months';
            this.isMonthValue = result.futureFreeServiceType != 'Amount';
            this.disabledInstallationReimbursable = !this.installationCosts;
            this.showOneTimeDiscount = result.isDealDeskUser;
            this.enableDisableButton();
            this.showMultiline=result.isSuperUser;
        }).catch(error => {
            this.showSpinner=false;
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: error.body.message,
                    variant: 'error'
                })
            );
            this._log('error', 'getRebateDetails', error);
            this._insertLogs();
            this.disabled=true;
            this.disabledDual = true;
            this.disableComponent=true;
            this.disabledInstallationReimbursable = true;
            this.showOneTimeDiscount = false;
            this.isMonth = true;
            this.isMonthValue = true;
        });
    }

    // Handle input changes
    handleCompetitorBuyoutChange(event) {
        this.competitorBuyout = event.target.value;

        if(!this.competitorBuyout){  
            this.showDual = false;
            this.disabledDual = true;
            this.multiSelectedValues = [];
            this.dualValue = '';
        } else {
            this.showDual = this.multiSelectedValues.length == 0 ? true : false;
            this.disabledDual = false;
        }
    }

    handleInstallationCostsChange(event) {
        this.installationCosts = event.target.value;
        if(!this.installationCosts){
            this.isInstallationReimbursable = '';
            this.disabledInstallationReimbursable = true;
        }else{
            this.disabledInstallationReimbursable = false;
        }
    }

    handleFreeMonthsChange(event) {
        this.freeMonths = event.target.value;
    }

    handleFreeMonthsValueChange(event) {
        this.freeMonthsValue = event.target.value;
    }

    handleInstallationReimbursableChange(event) {
        this.isInstallationReimbursable = event.detail.value;
    }

    handleIsMultilineChange(event) {
        this.isMultiline = event.target.checked;
    }

    handleOneTimeDiscountChange(event) {
        this.oneTimeDiscount = event.target.value;
    }

    checkForRebateSync() {
        if(this.ongoingSyncCheckRun){
            return;
        }
        this.ongoingSyncCheckRun=true;
        checkForConflicts({ quoteId: this.recordId }).then(result => {
            //console.log('checkForConflicts-', result);
            if (result) {
                this.disabled=true;
                this.disabledDual = true;
                this.isMonth = true;
                this.isMonthValue = true;
                this.showRebateSyncError=true;
                this.showRebateSyncErrorText='Quote was edited, Please refresh Deal Component Calculations.';
                this.saveButtonLabel='Recalculate';
                this.disabledInstallationReimbursable = true;
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Warning',
                        message: 'The rebate amounts are out of sync with the quote lines. Please recalculate the quote.',
                        variant: 'warning'
                    })
                );
                this.ongoingSyncCheckRun=false;
            }else{
                //this.showRebateSyncError=false;
                this.saveButtonLabel='Save';
                this.ongoingSyncCheckRun=false;
            }
            this.enableDisableButton();
        })
            .catch(error => {
                this._log('error', 'checkForRebateSync', error);
                this._insertLogs();
            }
            );
    }

    enableDisableButton(){
                //when there is conflict
        if(this.showRebateSyncError && this.saveButtonLabel=='Recalculate'){
            this.disableComponent=false;
        }
               //Irrespective of conflict
        if(this.quoteObject && 
                (this.quoteObject.quoteStatus === 'Approved' || this.quoteObject.quoteStatus === 'In Review') &&
                (this.quoteObject.opportunityStage !== 'Closed Won' && this.quoteObject.opportunityStage !== 'Closed Lost')){
                    this.disabled = true;
                    this.disabledDual = true;
                    this.disabledInstallationReimbursable = true;
                    this.saveButtonLabel = 'Recalculate';
                    this.disableComponent = false; // Enable recalculate button
                    this.isMonth = true;
                    this.isMonthValue = true;
        }
        if(this.quoteObject.opportunityStage === 'Closed Won' || this.quoteObject.opportunityStage === 'Closed Lost'){
            this.disableAll();
        }
    }

    setJobTracking(){
        if(this.shouldTrackJob){
            this.interval = setInterval(() => {
                this.trackJob();
              }, 5000);
        }
        else{
            clearInterval(this.interval);
        }
    }

    trackJob(){
        //this.showProcessing=true;
        trackJob({quoteId: this.recordId}).then(result => {
            if(result.Status=='Completed'){
                this.shouldTrackJob=false;
                this.setJobTracking();
                this.showSpinner=false;
                window.location.reload();
                
            }else if(result.Status=='Failed'){
                this.shouldTrackJob=false;
                this.setJobTracking();
                this.showRebateSyncError=true;
                this.showRebateSyncErrorText='Unable to sync the rebate amounts with the quote lines. Please contact your administrator.';
                //this.showProcessing=false;
                this.showSpinner=false;
                this._log('error', 'trackJob', 'BuyoutQuoteLineQueueable Job failed---');
                this._insertLogs();
            }
            this.ongoingSyncCheckRun=false;

        }).catch(error => {
            this._log('error', 'trackJob', error);
            this._insertLogs();
            this.ongoingSyncCheckRun=false;
        });
    }

    handleSave(){
        
        if(this.saveButtonLabel=='Save'){

            /*
            Validations to check if the user has entered the correct values for the fields.
            */
            if (!this.validateInstallationCosts()) {
                return;
            }
            
            if(!this.validateBuyoutAmount()){
                return;
            }
            
            if(!this.validateFutureFreeMonths()){
                return;
            }

            if(!this.validateOneTimeDiscount()){
                return;
            }

            if(!this.validateOtherChanges()){
                return;
            }

            const successMessage = this._buildSuccessMessage(); 

            this.freeMonths = !this.isMonth ? this.freeMonths : 0 ;
            this.freeMonthsValue = !this.isMonthValue ? this.freeMonthsValue : 0;

            var fieldValues = {
                'Competitor_Buyout_Amount__c': this.competitorBuyout,
                'Total_Estimated_Installation_Costs__c': this.installationCosts,
                'Is_Installation_Reimbursable__c': this.isInstallationReimbursable,
                'Bypass_Multiline__c': this.isMultiline,
                'Number_of_months_of_Free_service__c': this.freeMonths,
                'perMonthlicenseAmount': this.quoteObject.perMonthlicenseAmount,
                'OTD_Amt__c': this.oneTimeDiscount,
                'Future_Free_Months_Amount__c': this.freeMonthsValue,
                'Future_Free_Service_Type__c': this.radioGroupValue,
                'Buyout_Incumbent_Provider__c': this.dualValue.replaceAll(',', ';')
            }

            this.showSpinner=true;
            this.ongoingSyncCheckRun=true;
            
            createUpdateRebateLines({quoteId: this.recordId, fieldValues: JSON.stringify(fieldValues), operation: 'upsert'})
            .then(result => {
                //this.showSpinner=false;
                this.shouldTrackJob=true;
                this.setJobTracking();

                this._log('info', 'handleSave', 'User clicked Save button');
                this._log('info', 'handleSave', successMessage);
                this._insertLogs();

            }).catch(error => {
                this._log('error', 'handleSave', error);
                this._insertLogs();
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        message: error.body.message,
                        variant: 'error'
                    })
                );
                this.showSpinner=false;
                this.ongoingSyncCheckRun=false;
            });
        }else if(this.saveButtonLabel=='Recalculate'){
            this.showSpinner=true;
            this.ongoingSyncCheckRun=true;
            createUpdateRebateLines({quoteId: this.recordId, fieldValues : null , operation: 'recalculate'})
            .then(result => {
                this.shouldTrackJob=true;
                this.setJobTracking();

                this._log('info', 'handleSave', 'User clicked Recalculate button');
                this._insertLogs();
            }).catch(error => {
                this._log('error', 'handleSave', error);
                this._insertLogs();
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        message: error.body.message,
                        variant: 'error'
                    })
                );
                this.showSpinner=false;
                this.ongoingSyncCheckRun=false;
            });
        }
    }

    /**
     * @description Builds a success message detailing changed values by accessing component properties.
     * @returns {string} The constructed success message.
     */
    _buildSuccessMessage() {
        // --- Access properties directly using 'this' ---
        const priorValues = {
            competitorBuyout: this.quoteObject?.competitorBuyoutAmount ?? 'N/A',
            installationCosts: this.quoteObject?.totalEstimatedInstallationCosts ?? 'N/A',
            isInstallationReimbursable: this.quoteObject?.isInstallationReimbursable ?? 'N/A',
            isMultiline: this.quoteObject?.isDCMultiline ?? 'N/A',
            freeMonths: this.quoteObject?.futureFreeMonths ?? 'N/A',
            oneTimeDiscount: this.quoteObject?.oneTimeDiscount ?? 'N/A',
            futureFreeMonthsAmount: this.quoteObject?.futureFreeMonthsAmount ?? 'N/A',
            buyoutIncumbentProvide: this.quoteObject?.buyoutIncumbentProvider ?? 'N/A'
        };
        const newValues = {
             competitorBuyout: this.competitorBuyout ?? 'N/A',
             installationCosts: this.installationCosts ?? 'N/A',
             isInstallationReimbursable: this.isInstallationReimbursable ?? 'N/A',
             isMultiline: this.isMultiline ?? 'N/A',
             freeMonths: this.freeMonths ?? 'N/A',
             oneTimeDiscount: this.oneTimeDiscount ?? 'N/A',
             futureFreeMonthsAmount: this.freeMonthsValue ?? 'N/A',
             buyoutIncumbentProvide: this.dualValue ?? 'N/A'
        };

        let successMessage = 'Rebate amounts saved. Changes: ';
        let changes = [];
        
        if (priorValues.competitorBuyout !== newValues.competitorBuyout) {
            changes.push(`Competitor Buyout (${priorValues.competitorBuyout} -> ${newValues.competitorBuyout})`);
        }
         if (priorValues.installationCosts !== newValues.installationCosts) {
            changes.push(`Installation Cost (${priorValues.installationCosts} -> ${newValues.installationCosts})`);
        }
        if (priorValues.isInstallationReimbursable !== newValues.isInstallationReimbursable) {
            changes.push(`Installation Reimbursable (${priorValues.isInstallationReimbursable} -> ${newValues.isInstallationReimbursable})`);
        }
         if (priorValues.isMultiline !== newValues.isMultiline) {
            changes.push(`Is DC Multiline (${priorValues.isMultiline} -> ${newValues.isMultiline})`);
        }
         if (priorValues.freeMonths !== newValues.freeMonths) {
            changes.push(`Free Months (${priorValues.freeMonths} -> ${newValues.freeMonths})`);
        }
        if (priorValues.oneTimeDiscount !== newValues.oneTimeDiscount) {
            changes.push(`One Time Discount (${priorValues.oneTimeDiscount} -> ${newValues.oneTimeDiscount})`);
        }
        if (priorValues.futureFreeMonthsAmount !== newValues.futureFreeMonthsAmount) {
            changes.push(`Free Months Amount (${priorValues.futureFreeMonthsAmount} -> ${newValues.futureFreeMonthsAmount})`);
        }
        if (priorValues.buyoutIncumbentProvide !== newValues.buyoutIncumbentProvide) {
            changes.push(`Buyout Incumbent Provider (${priorValues.buyoutIncumbentProvide} -> ${newValues.buyoutIncumbentProvide})`);
        }

        if (changes.length > 0) {
            successMessage += changes.join(', ');
        } else {
            successMessage = 'Rebate amounts saved. No changes detected.';
        }
        return successMessage;
    }

    /**
     * @description Centralized logging helper. Sets level, method, and message/error.
     * @param {string} level - 'info' or 'error'.
     * @param {string} methodName - Name of the calling method.
     * @param {string|Error} messageOrError - The message string or Error object to log.
     */
    _log(level, methodName, messageOrError) {
        if (level === 'info') {
            Logger.atInfo()
                .setMethod(methodName)
                .setExceptionOrMessage(messageOrError);
        } else {
            Logger.atError()
                .setMethod(methodName)
                .setExceptionOrMessage(messageOrError);
        }
    }

    /**
     * @description Sets common log properties and inserts the logs.
     */
    _insertLogs() {
        Logger.setFunctionalityType('Rebates');    
        Logger.insertMasterLogs();
    }

    validateInstallationCosts() {
        let hasError = false;
        let errorMessage = '';

        if (this.installationCosts && this.installationCosts < 0) {
            hasError = true;
            errorMessage = 'Total Estimated Installation Costs must be a positive amount.';
        } else if (this.quoteObject && this.installationCosts  && this.quoteObject.totalEstimatedInstallationCosts !== this.installationCosts) {
            if (this.isInstallationReimbursable && !this.installationCosts ) {
                hasError = true;
                errorMessage = 'The Total Installation Costs field cannot be blank.';
            } else if (this.installationCosts && !this.isInstallationReimbursable) {
                hasError = true; 
                errorMessage = 'Please select a value for "Is Installation Reimbursable".';
            } else if (this.quoteObject.opportunityType !== 'Revenue Opportunity') {
                hasError = true;
                errorMessage = 'The Total Installation Costs field cannot be entered for Opportunities that are not of type Revenue.';
            } else if (this.quoteObject.opportunityProbability >= 95) {
                hasError = true;
                errorMessage = 'Updates to "Total Estimated Installation Costs" are not permitted. This value is locked once the Opportunity reaches the "Closing" stage or later.';
            }else if(!this.quoteObject.isInstallationCostProductAvailable){
                hasError = true;
                errorMessage = 'The Samsara installation costs product is not available in the selected pricebook and currency. Please contact your administrator.';
            }
        }

        if (hasError) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: errorMessage,
                    variant: 'error'
                })
            );
            return false;
        }
        return true;
    }


    validateBuyoutAmount() {
        let hasError = false;
        let errorMessage = '';

        if (this.quoteObject && this.quoteObject.competitorBuyoutAmount !== this.competitorBuyout) {
            if (this.competitorBuyout && this.competitorBuyout < 0) {
                hasError = true;
                errorMessage = 'The Buyout Amount must be a positive amount.';
            } else if (this.competitorBuyout && this.quoteObject) {
                if (this.quoteObject.opportunityType !== 'Revenue Opportunity') {
                    hasError = true;
                    errorMessage = 'The Buyout Amount field can only be entered for Revenue Opportunities.';
                } else if (this.quoteObject.opportunityProbability >= 95) {
                    hasError = true;
                    errorMessage = 'The Buyout Amount field cannot be entered for Opportunities that are in the Closing stage or later.';
                } else if (this.quoteObject.rebateOpp) {
                    hasError = true;
                    errorMessage = 'The Buyout Amount cannot be entered when there is a related opportunity with Type Rebate against the parent Revenue Opportunity.';
                } else if (!this.quoteObject.isBuyoutProductAvailable) {
                    hasError = true;
                    errorMessage = 'The Samsara buyout product is not available in the selected pricebook and currency. Please contact your administrator.';
                } 
            }
        }

        if (this.quoteObject && this.competitorBuyout && this.competitorBuyout > 0 && this.multiSelectedValues.length == 0) {
            hasError = true;
            errorMessage = 'The Buyout Incumbent Provider field cannot be blank.'
        }

        if (hasError) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: errorMessage,
                    variant: 'error'
                })
            );
            return false;
        }
        return true;
    }

    validateFutureFreeMonths() {
        let hasError = true;
        
        if (this.quoteObject && this.freeMonths && this.quoteObject.futureFreeMonths !== this.freeMonths) {
            hasError =  this.validateFutureFreeMonthsAmount(this.freeMonths, true);
        } else if (this.quoteObject && this.freeMonthsValue
                     && this.quoteObject.futureFreeMonthsAmount !== this.freeMonthsValue) {
            hasError = this.validateFutureFreeMonthsAmount(this.freeMonthsValue, false);
        }
        
        return hasError;
    }
    validateFutureFreeMonthsAmount(monthAmt, isFreeMonths) {
        let hasError = false;
        let errorMessage = '';
        const regex = /^[+-]?([0-9]*\.[0-9]+|[0-9]+\.?)$/; 
        
        if (monthAmt && monthAmt < 0) {
            hasError = true;
            errorMessage = 'The Future Free Months / Amount must be a positive amount.';
        } 
        else if (monthAmt && !regex.test(monthAmt)) {
            hasError = true;
            errorMessage = 'The Future Free Months / Amount must be a Integer.';
        } 
        else if (this.quoteObject) {
            if (this.quoteObject.opportunityType !== 'Revenue Opportunity') {
                hasError = true;
                errorMessage = 'Future Free Months / Amount cannot be entered for Opportunities that are not of type Revenue.';
            } else if (this.quoteObject.opportunityProbability >= 95) {
                hasError = true;
                errorMessage = 'The Future Free Months / Amount field cannot be entered for Opportunities that are in the Closing stage or later.';
            } else if (!this.quoteObject.isFutureFreeMonthsProductAvailable) {
                hasError = true;
                errorMessage = 'The Future Free Months / Amount product is not available in the selected pricebook and currency. Please contact your administrator.';
            } else if(isFreeMonths && Number(this.freeMonths) > Number(this.quoteObject.licenseTerm)){
                hasError = true;
                errorMessage = 'The Number of Months of Free Service may not exceed the License Term. Please update the Number of Months of Free Service.';
            }else if(this.quoteObject.totalLicensePrice<=0){
                hasError = true;
                errorMessage = 'Hardware only opportunities are not eligible for free month credits. Please add at least one license product to the quote first.';
            }else if(!isFreeMonths && Number(this.freeMonthsValue) > Number(this.quoteObject.totalLicensePrice)){
                hasError = true;
                errorMessage = 'The Free Service Amount may not exceed the License Term. Please update the Free Service Amount.';
            }
        }
        if (hasError) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: errorMessage,
                    variant: 'error'
                })
            );
            return false;
        }
        return true;
    }

    validateOneTimeDiscount(){
        let hasError = false;
        let errorMessage = '';

        if (this.quoteObject && this.quoteObject.oneTimeDiscount !== this.oneTimeDiscount) {
            if (this.oneTimeDiscount && this.oneTimeDiscount < 0) {
                hasError = true;
                errorMessage = 'The One Time Discount must be a positive amount.';
            }
            else if (this.oneTimeDiscount && this.quoteObject) {
                if (this.quoteObject.opportunityType !== 'Revenue Opportunity') {
                    hasError = true;
                    errorMessage = 'One Time Discount cannot be entered for Opportunities that are not of type Revenue';
                }
                else if (this.quoteObject.opportunityProbability >= 95) {
                    hasError = true;
                    errorMessage = 'The One Time Discount field cannot be entered for Opportunities that are in the Closing stage or later.';
                }
                else if (!this.quoteObject.isOTDProductAvailable) {
                    hasError = true;
                    errorMessage = 'The One Time Discount product is not available in the selected pricebook and currency. Please contact your administrator.';
                }
            }
        }

        if (hasError) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: errorMessage,
                    variant: 'error'
                })
            );
            return false;
        }
        return true;
    }

    validateOtherChanges(){
        let hasError = false;
        let errorMessage = '';
        if (this.quoteObject &&  (this.installationCosts || this.competitorBuyout)){
            let sumOfBuyouts = (this.installationCosts?Number(this.installationCosts):0) + (this.competitorBuyout?Number(this.competitorBuyout):0);
            if(this.quoteObject.netAmount < sumOfBuyouts){
                hasError = true;
                errorMessage = 'The combined value of the Competitor Buyout and Installation Costs is greater than the total Quote amount. Please review and adjust the values.';
            }   
        }
        if (hasError) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: errorMessage,
                    variant: 'error'
                })
            );
            return false;
        }
        return true;
    }

    handleClickHelp() {
        var url = dealComponentAssistantHelpURL;
        window.open(url, "_blank");
    }  

    handleChange(event) {

        this.freeMonths = 0;
        this.freeMonthsValue = 0;
        this.radioGroupValue = event.detail.value;
        this.isMonth = event.detail.value != 'Months';
        this.isMonthValue = event.detail.value != 'Amount';
    }


    multiSelecthandleChange( event ) {
           
        const selectedOptionsList = event.detail.value;
        this.multiSelectedValues = selectedOptionsList;
        this.dualValue = selectedOptionsList.toString();
    }

    closeDual( event ) {
        this.showDual = false;
    }

    editDualhandler( event ) {
        if(!this.competitorBuyout){
            this.showDual = false;
        } else {
            this.showDual = true;
        }
    }
}