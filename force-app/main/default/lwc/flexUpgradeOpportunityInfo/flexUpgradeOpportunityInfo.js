import { LightningElement, api, wire, track } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import CONTROL_CENTER_OBJECT from '@salesforce/schema/Flex_Control_Center_Config__c';
import getContractInfo from '@salesforce/apex/FlexUpgradeOpportunityInfo.getContractInfo';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class FlexUpgradeOpportunityInfo extends LightningElement {
    @track startDate;
    @track endDate;
    @track termMonths = 36;
    @track isRebook ;
    @track error = '';
    @track originalTermMonths;
    @track originalEndDate;
    @track configRecord;
    @track termMonthsText;
    @track showTermFieldProps;
    @track cachedTermMonths;
    @track userSelectedTermMonths;
    @track bookingType = '';
    @track quoteStartDate;  
    @api currentStep;
    @api cachedStartDate;
    @api  cachedBookingType;
    @api isStepFour;
    @api isStepTwo;
    @api configData;
    @api showOppInfo;
    @api configId;
    @api contractIds;
    @api userSelectedTerm;
    isExpanded = true;
    isOppUpgradeExpanded = false;
    isReplacementOppExpanded = true;

    @wire(getRecord, { 
        recordId: '$configId',
        fields: [
            'Flex_Control_Center_Config__c.Enable_Cancel_Book__c',
            'Flex_Control_Center_Config__c.Enable_Cancel_Rebook__c',
            'Flex_Control_Center_Config__c.Enable_Term_Overwrite__c',
            'Flex_Control_Center_Config__c.Bypass_SKU_Hierarchy_Validation__c'
        ]
    })
    configRecords({data, error}) {
        if (data) {
            this.configRecord = data;
            const enableBook = this.configRecord.fields.Enable_Cancel_Book__c.value;
            const enableRebook = this.configRecord.fields.Enable_Cancel_Rebook__c.value;
            if (!enableBook && !enableRebook) {
                this.isRebook = true;
            } else if (enableBook && enableRebook) {
                this.isRebook = true;
            }
            else if (!enableBook && enableRebook) {
                this.isRebook = true;
            }

            if (this.cachedBookingType !== undefined) {
                this.isRebook = this.cachedBookingType;
            }           
            this.bookingType = this.isRebook ? 'Rebook (Keep Same End Date)' : 'Book (Set New Term Length)';
        } else if (error) {
            console.error('Error loading config record:', error);
            this.configRecord = undefined;
        }
    }

    @wire(getContractInfo, { contractIds: '$contractIds' })
    wiredContractTerms({ error, data }) {
        if (data && data.length > 0) {
            let latestEndDate = null;
            let latestContract = null;
            const contractDates = data.map(contract => ({
                contract: contract,
                endDate: new Date(contract.EndDate + 'T00:00:00')
            }));
            contractDates.sort((a, b) => b.endDate - a.endDate);
            latestEndDate = contractDates[0].endDate;
            latestContract = contractDates[0].contract;
            const today = new Date();
            if(this.isRebook && latestEndDate){
                this.endDate = this.formatDate(latestEndDate);
                this.originalEndDate = this.endDate;
            }
            if (this.isRebook) {
                let newDate = new Date(this.startDate + 'T00:00:00');
                newDate.setDate(newDate.getDate() + 15);
                this.quoteStartDate = this.formatDate(newDate);
            } else {
                this.quoteStartDate = this.startDate;
            }

            this.originalTermMonths = this.termMonths;
            this.dispatchConfigEvent();
        } else if (error) {
            this.error = 'Error retrieving contract terms';
            console.error('Error:', error);
        }
    }

    setOriginalEndDate() {
        if (!this.originalEndDate) {
            const startDate = new Date(this.startDate);
            let endDate = new Date(startDate);
            endDate.setMonth(endDate.getMonth() + parseInt(this.termMonths));
            this.originalEndDate = this.formatDate(endDate);
        }
    }

    connectedCallback() {
        this.startDate = this.cachedStartDate ? this.cachedStartDate : this.formatDate(new Date());
        this.isRebook = this.cachedBookingType !== undefined ? this.cachedBookingType : true;
        this.bookingType = this.isRebook ? 'Rebook' : 'Book';
        if (this.isRebook) {
            let newDate = new Date(this.startDate + 'T00:00:00');
            newDate.setDate(newDate.getDate() + 15);
            this.quoteStartDate = this.formatDate(newDate);
        } else {
            this.quoteStartDate = this.startDate;
        }
        if (this.cachedTermMonths) {
            this.termMonths = this.cachedTermMonths;
        } else if (this.userSelectedTerm) {
            this.termMonths = this.userSelectedTerm;
            this.cachedTermMonths = this.userSelectedTerm; // Cache the value
        }
        if (this.termMonths) {
            this.calculateEndDate();
        }
        if (this.configData) {
            this.configData = {
                ...this.configData,
                termMonths: this.termMonths
            };
        }
    }
    renderedCallback() {
        this.showTermFieldProps = this.showTermFieldFxn();
        if (this.configData && this.configData.termMonths && this.configData.termMonths !== this.termMonths) {
            this.termMonths = this.configData.termMonths;
            this.cachedTermMonths = this.configData.termMonths;
        }
    } 

    get formatedQuoteStartDate (){
        return this.quoteStartDate? this.formatDateForConfirmationPage(this.configData.quoteStartDate + 'T00:00:00'):'';
    }
    get formatedStartDate (){
        return this.startDate? this.formatDateForConfirmationPage(this.configData.startDate + 'T00:00:00'):'';
    }
    get formatedEndDate (){
        // if( this.configData && this.configData.isRebook){
        //     this.termMonthsText =  this.calculateMonthDifference(this.configData.quoteStartDate + 'T00:00:00', this.configData.endDate + 'T00:00:00');
        // }else{
        //     this.termMonthsText =  this.configData.termMonths;
        // }
        return this.endDate? this.formatDateForConfirmationPage(this.configData.endDate + 'T00:00:00'):'';
    }
    get formatedTermMonths (){
        if( this.configData && this.configData.isRebook){
            return this.calculateMonthDifference(this.configData.quoteStartDate + 'T00:00:00', this.configData.endDate + 'T00:00:00');
        }else{
            return this.configData.termMonths;
        }
    }
        get bookingTypeLabel(){
        return this.configData.isRebook ? 'Rebook' : 'Book';
    }
    get showBookingToggle() {
        return this.configRecord?.fields?.Enable_Cancel_Book__c?.value && this.configRecord?.fields?.Enable_Cancel_Rebook__c?.value;
    }
    get showTermField() {
      return this.configRecord?.fields?.Enable_Cancel_Book__c?.value && this.configRecord?.fields?.Enable_Term_Overwrite__c?.value && !this.isRebook; 
    }
    get termOptions() {
        return [
            { label: '2 Months', value: 2 },
            { label: '12 Months', value: 12 },
            { label: '36 Months', value: 36 },
            { label: '60 Months', value: 60 }
        ];
    }
    get iconName() {
        return this.isExpanded ? 'utility:chevrondown' : 'utility:chevronright';
    }
    get upgradeOppIconName() {
        return this.isOppUpgradeExpanded ? 'utility:chevrondown' : 'utility:chevronright';
    }

    formatDateForConfirmationPage(date){
        const options = { year: 'numeric', month: 'short', day: 'numeric' };
        return new Date(date).toLocaleDateString('en-US', options);
    }

    calculateMonthDifference(startDate, endDate) {
        const start = new Date(startDate);
        const end = new Date(endDate);
        const yearsDifference = end.getFullYear() - start.getFullYear();
        const monthsDifference = end.getMonth() - start.getMonth();
        const daysDifference = end.getDate() - start.getDate();
        let totalMonths = yearsDifference * 12 + monthsDifference;
        if (daysDifference > 0) {
            totalMonths += 1;
        }
        return totalMonths;
    }

    showTermFieldFxn(){
        return this.configRecord?.fields?.Enable_Cancel_Book__c?.value && this.configRecord?.fields?.Enable_Term_Overwrite__c?.value && !this.isRebook; 
    }

    validateDates() {
        if (!this.startDate || !this.endDate) {
            return false;
        }
        const start = new Date(this.startDate + 'T00:00:00');
        const end = new Date(this.endDate + 'T00:00:00');
        if (start > end) {
            this.dispatchEvent(new CustomEvent('dateerror', { 
                detail: true
            }));
            return false;
        } else {
            this.dispatchEvent(new CustomEvent('dateerror', {
                detail: false 
            }));
        }
        this.error = '';
        return true;
    }

    showToast(title, message, variant) {
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant
        });
        this.dispatchEvent(event);
    }

    handleBookingToggle(event) {
        this.isRebook = event.target.checked;
        this.bookingType = this.isRebook ? 'Rebook' : 'Book';
        const rebookEvent = new CustomEvent('rebookchange', {
            detail: { bookingType: this.isRebook }
        });
        this.dispatchEvent(rebookEvent);
        if (this.isRebook) {
            this.setOriginalEndDate();
            this.endDate = this.originalEndDate;
            let newDate = new Date(this.startDate + 'T00:00:00');
            newDate.setDate(newDate.getDate() + 15);
            this.quoteStartDate = this.formatDate(newDate);
        } 
        else{
            this.quoteStartDate = this.startDate;
            this.calculateEndDate();
        }
        if (this.validateDates()) {
            this.dispatchConfigEvent();
        }
    }

    handleStartDateChange(event) {
        this.startDate = event.detail.value;
        const startDateEvent = new CustomEvent('datachange', {
            detail: { startDate: this.startDate }
        });
        this.dispatchEvent(startDateEvent);
        if (this.startDate == null || this.startDate === '') {
            this.dispatchEvent(new CustomEvent('dateempty', { detail: true }));
        } else {
            this.dispatchEvent(new CustomEvent('dateempty', { detail: false }));
        }
        if (this.isRebook) {
            let newDate = new Date(this.startDate + 'T00:00:00');
            newDate.setDate(newDate.getDate() + 15);
            this.quoteStartDate = this.formatDate(newDate);
        } else {
            this.quoteStartDate = this.startDate;
        }
        this.calculateEndDate();
        if (this.validateDates()) {
            this.dispatchConfigEvent();
        }
    }
    handleTermChange(event) {
        const value = event.target.value;
        if (value.includes('.')) {
            this.error = 'Decimal values are not allowed for Term';
            return;
        }
        const termValue = parseInt(value);
        this.termMonths = termValue;
        this.cachedTermMonths = termValue; // Cache the term value when it changes
        
        // Update configData if it exists
        if (this.configData) {
            this.configData = {
                ...this.configData,
                termMonths: termValue
            };
        }
        
        if (!this.isRebook && this.startDate) {
            this.quoteStartDate = this.startDate;
        }
        this.calculateEndDate();
        this.dispatchConfigEvent();         
    }

    calculateEndDate() {
        if (this.isRebook) {
            this.setOriginalEndDate();
            this.endDate = this.originalEndDate;
            return;
        }
        if (!this.startDate || !this.termMonths) return;
        const startDate = new Date(this.startDate);
        let endDate = new Date(this.startDate + 'T00:00:00');
        endDate.setDate(endDate.getDate() - 1);    
        endDate.setMonth(endDate.getMonth() + parseInt(this.termMonths));
        endDate.setDate(endDate.getDate());
        this.endDate = this.formatDate(endDate);        
    }

    formatDate(date) {
        const year = date.getFullYear();
        const month = String(date.getMonth() + 1).padStart(2, '0');
        const day = String(date.getDate()).padStart(2, '0');
        return `${year}-${month}-${day}`;
    }

    dispatchConfigEvent() {
        const configDetails = {
            isRebook: this.isRebook,
            startDate: this.startDate,
            endDate: this.endDate,
            quoteStartDate: this.quoteStartDate,
            termMonths: this.termMonths,
            configRecord: this.configRecord,
            error: this.error,
            bookingType: this.bookingType
        };

        this.dispatchEvent(new CustomEvent('configchange', {
            detail: configDetails
        }));
    }

    handleSectionToggle(){
        this.isExpanded = !this.isExpanded;
    }

    handleOppUpgradeSectionToggle(){
        this.isOppUpgradeExpanded = !this.isOppUpgradeExpanded;
    }

    handleReplacementOppToggle() {
        this.isReplacementOppExpanded = !this.isReplacementOppExpanded;
    }
}