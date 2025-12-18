import { LightningElement, api, track } from 'lwc';

export default class CreateOpptyGenericDataTableURL extends LightningElement {

    @api columns;
    @api noDataMsgAfterFilter;
    @api utilityButtonLabel;
    @api objectName;
    @api scopedMessage;
    @api tableData;
    @api hyperLink;
    @api followupText;
    @api tableTitle; //Data that displays on top of the count in the component. If not provided, considers - objectName and the data.

    @track searchPhrase;
    @track pageSize = 5;
    @track currentPage = 1;
    @track rowId;
    @track _selectedRecord;
    @track _allowedRecords = [];
    @track _selectedRecordSet = false;
    
    connectedCallback(){
        if(!this.selectedRecord && this.allowedRecords?.length !== 1) return;
        this._selectedRecord = this.selectedRecord ? this.selectedRecord : this.allowedRecords[0].Id;
        this._selectedRecordSet = true;
    }

    // Setter for selectedRecord to handle dynamic updates
    @api
    set selectedRecord(value) {
        if (value && value !== this._selectedRecord) {
            this._selectedRecord = value;
            this._selectedRecordSet = true;
            this.setDatatableSelection();
        }
    }
    
    get selectedRecord() {
        return this._selectedRecord;
    }

    // Setter for allowedRecords to handle dynamic updates
    @api
    set allowedRecords(value) {
        this._allowedRecords = value || [];
        if (this._selectedRecordSet && this._selectedRecord) {
            // If we have a selected record and new data, try to set selection
            setTimeout(() => {
                this.setDatatableSelection();
            }, 100);
        }
    }
    
    get allowedRecords() {
        return this._allowedRecords;
    }

    renderedCallback(){
        if(this.dataToDisplay.find(rec => rec.Id === this._selectedRecord) && this._selectedRecord){
            this.template.querySelector('lightning-datatable').selectedRows = [this._selectedRecord];
        }
    }

    // Public method to set selection
    @api
    setSelection(recordId) {
        if (recordId) {
            this._selectedRecord = recordId;
            this._selectedRecordSet = true;
            this.setDatatableSelection();
        }
    }

    // Method to set datatable selection
    setDatatableSelection() {
        if (this._selectedRecord && this.template) {
            setTimeout(() => {
                const lightningDatatable = this.template.querySelector('lightning-datatable');
                if (lightningDatatable) {
                    lightningDatatable.selectedRows = [this._selectedRecord];
                }
            }, 50);
        }
    }

    @api get selectedRecordInTable(){
        return this._selectedRecord;
    }

    get filteredRecords(){
        return !this.searchPhrase ? this.allowedRecords: this.allowedRecords.filter(rec => rec.Name.toLowerCase().includes(this.searchPhrase));
    }

    get tableInfoToDisplay(){
        return this.tableTitle? this.tableTitle : this.objectName?`${this.objectName} data Related to Account`:'';
    }

    //Returns a boolean which decides if data must be displayed on top of the count section.
    get displayInfo(){
        return this.tableTitle && this.objectName;
    }

    get dataToDisplay(){
        return this.filteredRecords.slice((this.currentPage-1)*this.pageSize, this.currentPage*this.pageSize);
    }

    get noDataAfterFilter(){
        return this.filteredRecords.length === 0 && this.searchPhrase;
    }

    get hasDataAfterFilter(){
        return this.filteredRecords.length !== 0;
    }

    get recordsRetrieved(){
        return this.allowedRecords;
    }

    get isNextDisabled(){
        return this.filteredRecords.length <= this.currentPage*this.pageSize;
    }
    
    get isPreviousDisabled(){
        return this.currentPage === 1;
    }

    get pagination() {
        return `${this.currentPage} / ${Math.ceil(this.filteredRecords.length / this.pageSize)|| 1}`;
    }

    get dataTableRecCountInfo(){
        return `Showing ${this.filteredRecords.length} of ${this.allowedRecords.length} ${this.objectName} records`;
    }

    get showScopedMessage(){
        return this.scopedMessage;
    }

    get tableMessage(){
        return this.tableData? this.tableData :`Please select a ${this.objectName} from the below list`;
    }

    get showUtilityButton(){
        return this.utilityButtonLabel ? true : false;
    }

    get linkExist(){
        return this.hyperLink;
    }

    handleNextpage(){
        this.currentPage++;
        // Try to maintain selection after page change
        if (this._selectedRecord) {
            setTimeout(() => {
                this.setDatatableSelection();
            }, 100);
        }
    }
    
    handlePreviouspage(){
        this.currentPage--;
        // Try to maintain selection after page change
        if (this._selectedRecord) {
            setTimeout(() => {
                this.setDatatableSelection();
            }, 100);
        }
    }

    handleSearchKeyChange(event) {
        this.currentPage = 1;
        this.searchPhrase = event.target.value.toLowerCase();
        // Try to maintain selection after search
        if (this._selectedRecord) {
            setTimeout(() => {
                this.setDatatableSelection();
            }, 100);
        }
    }

    handleRowSelection(event){
        if(event.detail?.selectedRows?.length > 0){
            if(this._selectedRecord === event.detail.selectedRows[0].Id) return;
            this._selectedRecord = event.detail.selectedRows[0].Id;
        } 
    }
    
    handleUtilityClick(){
        this.dispatchEvent(new CustomEvent('utilityclick'));
    }
}