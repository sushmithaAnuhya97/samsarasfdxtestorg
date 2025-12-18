import { LightningElement, api } from 'lwc';

export default class createOpptyGenericDataTable extends LightningElement {

    @api allowedRecords;
    @api selectedRecord; //default selection, if any
    @api columns;
    @api noDataMsgAfterFilter;
    @api utilityButtonLabel;
    @api objectName;
    @api scopedMessage;
    @api tableData;
    @api hyperLink;
    @api followupText;
    @api tableTitle; //Data that displays on top of the count in the component. If not provided, considers - objectName and the data.

    searchPhrase;
    pageSize = 5;
    currentPage = 1;
    rowId;
    _selectedRecord;
    
    connectedCallback(){
        if(!this.selectedRecord && this.allowedRecords?.length !== 1) return;
        this._selectedRecord = this.selectedRecord ? this.selectedRecord : this.allowedRecords[0].Id;
    }

    renderedCallback(){
        if(this.dataToDisplay.find(rec => rec.Id === this._selectedRecord) && this._selectedRecord){
            this.template.querySelector('lightning-datatable').selectedRows = [this._selectedRecord];
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
        //this.manageSelected();
    }
    
    handlePreviouspage(){
        this.currentPage--;
        //this.manageSelected();
    }

    handleSearchKeyChange(event) {
        this.currentPage = 1;
        this.searchPhrase = event.target.value.toLowerCase();
        //this.manageSelected();

    }

    handleRowSelection(event){
        if(event.detail?.selectedRows?.length > 0){

            
            if(this._selectedRecord === event.detail.selectedRows[0].Id) return;
            
            this._selectedRecord = event.detail.selectedRows[0].Id;
        } 
    }
    
    // manageSelected(){
    //     if(this.dataToDisplay.find(rec => rec.Id === this._selectedRecord) && this._selectedRecord){
    //         this.template.querySelector('lightning-datatable').selectedRows = [this._selectedRecord];
    //     }
    // }
    
    handleUtilityClick(){
        this.dispatchEvent(new CustomEvent('utilityclick'));
    }
}