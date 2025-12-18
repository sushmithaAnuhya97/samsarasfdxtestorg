import { LightningElement, api, track, wire } from 'lwc';
import { CloseActionScreenEvent } from 'lightning/actions';
import getProductList from '@salesforce/apex/FreeTrialDecisionsHandler.getProductList';
import createOpportunity from '@salesforce/apex/FreeTrialDecisionsHandler.createOpportunity';
//import modal from "@salesforce/resourceUrl/sldsfreetrialmodalcontainer";
//import { loadStyle } from "lightning/platformResourceLoader";
const columns = [
    //{ label: 'Quote', fieldName: 'quote' },
    
    { label: 'Trial Opportunity Name', fieldName: 'opptyName' },
    //{ label: 'Product', fieldName: 'productName' },
    { label: 'Product Code', fieldName: 'productCode' },
    { label: 'Serial Number', fieldName: 'serialNumber', editable: true },
    { label: 'Trial Quantity', fieldName: 'trialQuantity'},
    { label: 'Buying Quantity', fieldName: 'buyingQuantity', editable: true},
    { label: 'Remaining Quantiy', fieldName: 'remainingQuantity'},
]
const columnsFull = [
    //{ label: 'Quote', fieldName: 'quote' },
    { label: 'Trial Opportunity Name', fieldName: 'opptyName' },
    //{ label: 'Product', fieldName: 'productName' },
    { label: 'Product Code', fieldName: 'productCode' },
    { label: 'Trial Quantity', fieldName: 'trialQuantity'},
    //{ label: 'Buying Quantity', fieldName: 'buyingQuantity'},
    //{ label: 'Remaining Quantiy', fieldName: 'remainingQuantity'},
]
const data = [
    {
        Id: 'a8O8L00000002DJUAY',
        Product: '14-pin Caterpillar cable',
        Quantity : 1,
        ActualQty : 1,
    },
    {
        Id: 'a8O8L00000002DOUAY',
        Product: '1500 Amp Current Transformer',
        Quantity : 5,
        ActualQty : 5,
    },
];
export default class FreeTrialContractDecision extends LightningElement {
    @api recordId;
    @api contractId = "";
    @api freeTrialDecision;
    @api productInfo;
    @api serialNumberInfo;
    //@api opportunityType;
    @track accountId;
    @track opportunityId;
    @track decisionModeValue;
    @track decisionModeOptions;
    @track disableProcessButton;
    @track showProductTable;
    @track showBuyOption;
    @track showMainSection;
    @track showFinalMessage;
    @track saveProductDraftValues;
    @track selectedProducts = [];
    @track isProcessing = false;
    @track createdOpportunityId;
    @track opportunityRecordURL;
    @track showNoBuyMessage;
    @track showFullTable = false;
    @track showPartialTable = false;
    productColumns = columns;
    productColumnsFull = columnsFull;
    saveDraftValues;
    errors;
    //productData = data;
    connectedCallback() {
        this.handlePageLoad();
        this.loadProductList();
        //loadStyle(this, modal);
    } 
    handleProductSave () {

    }
    handleRowAction() {

    }
    handlePageLoad() {
        this.decisionModeOptions = [];
        this.decisionModeOptions.push({
            label: 'Full Buy',
            value: 'FullBuy',
            selected: false                    
        });

        this.decisionModeOptions.push({
            label: 'Partial Buy',
            value: 'PartialBuy',
            selected: false                    
        });

        this.decisionModeOptions.push({
            label: 'No Buy',
            value: 'NoBuy',
            selected: false                    
        });

        this.decisionModeOptions.push({
            label: 'Extension',
            value: 'Extension',
            selected: false                    
        });
        this.disableProcessButton = true;
        this.showProductTable = true;
        this.showBuyOption = false;
        this.showFinalMessage = false;
        if (this.freeTrialDecision == 'Partial Buy')
        this.showPartialTable = true;
        else
        this.showFullTable = true;
        this.showMainSection = true;
        this.showNoBuyMessage = false;
        //console.log('RODRIGO handlePageLoad this.recordId ' + this.recordId);
        console.log('RODRIGO handlePageLoad this.contractId ' + this.contractId);
        this.recordId = this.contractId;
    } 

    /*@wire(getProductList, {contractId: '$recordId'}) 
    wired(error, data) {
        console.log('RODRIGO wired this.recordId ' + JSON.stringify(data));
        if (data) {
            this.productData = data.productList;
        }
    }
    */
    handleCellChange(event) {
        
        this.saveDraftValues = event.detail.draftValues;
        var rowErrorMessages = [];
        var rowErrorFieldNames = [];
        var rowsError = {};
        rowErrorMessages.push('Buying quantity cannot be more than Trial quantity!');
        rowErrorFieldNames.push('buyingQuantity');
        console.log('RODRIGO handleCellChange ' + this.saveDraftValues);
        rowsError[this.saveDraftValues[0].Id] = {
            messages: rowErrorMessages,
            fieldNames: rowErrorFieldNames,
            title: 'Error found.'
        };
        let localData = this.productData;
        for (let x = 0; x < localData.length; x++) {
            let localQty = null;
            localQty = localData[x].trialQuantity;
            //console.log('RODRIGO handleCellChange ' + this.saveDraftValues[0].buyingQuantity);
            //console.log('RODRIGO handleCellChange ' + this.saveDraftValues[0].Id);
            if (this.saveDraftValues[0].Id == localData[x].Id && this.saveDraftValues[0].buyingQuantity > localQty ) {
                this.errors = {
                    rows: rowsError
                }    
                break;       
            }
            else {
                this.errors = {};      // when error should not show
            }
        }

    }

    loadProductList () {
        //console.log('RODRIGO loadProductList ' + this.contractId);
        //console.log('RODRIGO loadProductList ' + this.freeTrialDecision);
        this.isProcessing = true;
        getProductList({contractId : this.contractId, freeTrialDecision : this.freeTrialDecision}) 
        .then(result => {
            //console.log('RODRIGO loadProductList this.recordId ' + JSON.stringify(result.productList));
            this.productData = result.productList;
            this.accountId = result.accountId;
            this.isProcessing = false;
            //this.closeQuickAction();
            //this.opportunityId = result.opportunityId;
        })
        .catch(error => {
                //this.loading = false;
                //this.apsErrorMessage = error.body.message;
                window.console.error("Error on loadProductList " + error);
        });
    }

    // new function to build string regardless of selected products.
    buildProductInfoString(){
        this.productInfo = null;
        this.serialNumberInfo = "";
        for (let i = 0; i < this.productData.length; i++) {
            if ( (this.productInfo == "" || this.productInfo == null || this.productInfo == undefined) 
                && this.productData[i].buyingQuantity != undefined && this.productData[i].buyingQuantity != null && this.productData[i].buyingQuantity != '')
                this.productInfo = this.productData[i].Id + "|" + this.productData[i].buyingQuantity;
            else if (this.productData[i].buyingQuantity != undefined && this.productData[i].buyingQuantity != null && this.productData[i].buyingQuantity != '')
                this.productInfo = this.productInfo +";"+this.productData[i].Id + "|" + this.productData[i].buyingQuantity;
            
            if (this.productData[i].serialNumber != undefined && this.productData[i].serialNumber != null && this.productData[i].serialNumber != '')
                this.serialNumberInfo = this.serialNumberInfo +this.productData[i].serialNumber+ ",";
            //this.serialNumberInfo = this.serialNumberInfo + "::"+selectedRows[i].Id +"|"+selectedRows[i].serialNumber;
            //this.selectedProductIds.push(selectedRows[i].Id);
        }
    }

    getSelectedProduct (event){
        const selectedRows = event.detail.selectedRows;
        this.selectedProducts = [];
        this.productInfo = null;
        this.serialNumberInfo = "";
        //this.selectedProductIds = [];
        //alert(selectedRows);
        // Display that fieldName of the selected rows
        for (let i = 0; i < selectedRows.length; i++) {
            //window.console.log('getSelectedProduct selectedRows[i] ' + JSON.stringify(selectedRows[i]));
            //alert(selectedRows[i].Id + ' You selected: ' + selectedRows[i].Name);
            this.selectedProducts.push({
                productCode: selectedRows[i].productCode,
                productName: selectedRows[i].productName,
                Id: selectedRows[i].Id,
                buyingQuantity: selectedRows[i].buyingQuantity,
                trialQuantity : selectedRows[i].trialQuantity
            });
            if ( (this.productInfo == "" || this.productInfo == null || this.productInfo == undefined) 
                && selectedRows[i].buyingQuantity != undefined && selectedRows[i].buyingQuantity != null && selectedRows[i].buyingQuantity != '')
                this.productInfo = selectedRows[i].Id + "|" + selectedRows[i].buyingQuantity;
            else if (selectedRows[i].buyingQuantity != undefined && selectedRows[i].buyingQuantity != null && selectedRows[i].buyingQuantity != '')
                this.productInfo = this.productInfo +";"+selectedRows[i].Id + "|" + selectedRows[i].buyingQuantity;
            
            if (selectedRows[i].serialNumber != undefined && selectedRows[i].serialNumber != null && selectedRows[i].serialNumber != '')
                this.serialNumberInfo = this.serialNumberInfo +selectedRows[i].serialNumber+ ",";
            //this.serialNumberInfo = this.serialNumberInfo + "::"+selectedRows[i].Id +"|"+selectedRows[i].serialNumber;
            //this.selectedProductIds.push(selectedRows[i].Id);
        }

        /*if (this.productInfo === null || this.productInfo === undefined || this.productInfo === "")
            this.opportunityType = "Free Trial Return";
        else
            this.opportunityType = "Revenue Opportunity";*/
        //this.selectProducts = this.selectedProducts;
        //window.console.log('getSelectedProduct ' + JSON.stringify(this.serialNumberInfo));
    }
    handleProductSave (event) {
        let localData = this.productData;
        let tempData = [];
        this.saveProductDraftValues = event.detail.draftValues;
        let remainingQty = 0;
        
        this.productInfo="";
        this.serialNumberInfo = "";
        // handles the updating of the value in the array
        for (let x = 0; x < localData.length; x++) {
            window.console.log('localData ' + JSON.stringify(localData));
            // check if product id is in draft value
            let localQty = null;
            let localDiscount = null;
            let idFound = false;
            let localSerialNumber = null;
            for (let i = 0; i < this.saveProductDraftValues.length; i++) {
                //console.log('localData[x].Id ' + localData[x].Id);
                //c/accountDataValidationInfoLwcconsole.log('this.saveProductDraftValues[i].Id ' + this.saveProductDraftValues[i].Id);
                if (localData[x].Id ===this.saveProductDraftValues[i].Id) {
                    idFound=true;
                    //localQty = this.saveHWCDraftValues[i].Quantity;
                    //localDiscount = this.saveHWCDraftValues[i].Discount;
                    //console.log('this.saveProductDraftValues[i].buyingQuantity ' + this.saveProductDraftValues[i].buyingQuantity);
                    if (this.saveProductDraftValues[i].buyingQuantity != undefined)
                        localQty = this.saveProductDraftValues[i].buyingQuantity;
                    if (this.saveProductDraftValues[i].serialNumber != undefined)
                        localSerialNumber = this.saveProductDraftValues[i].serialNumber;
                }
                
            }

            if (localSerialNumber === null)
                localSerialNumber = localData[x].serialNumber;

            remainingQty = localData[x].remainingQuantity;
            if (idFound === false) {
                localQty = localData[x].buyingQuantity;
            }
            
            if (idFound=== true) {
                let trialQty = localData[x].trialQuantity;
                if (localQty === null)
                    localQty = localData[x].buyingQuantity;
                if (localQty>trialQty) {
                    alert('Buying quantity cannot be more than Trial quantity!');
                    return;

                }
                    
                remainingQty = trialQty - localQty;
            }   
            //console.log('localQty ' + localQty);
            tempData.push({
                opptyName: localData[x].opptyName,
                    productCode: localData[x].productCode,
                    productName: localData[x].productName,
                    Id: localData[x].Id,
                    buyingQuantity: localQty,
                    trialQuantity : localData[x].trialQuantity,
                    remainingQuantity : remainingQty,
                    serialNumber: localSerialNumber
            })
            //window.console.log('tempData ' + JSON.stringify(tempData));
            
        }
        
        
        this.selectedProducts = [];
        this.saveProductDraftValues=[];
        event.target.draftValues = null;
        this.productData = tempData;
        this.buildProductInfoString();
    }
    handleDecisionMode(event) {
        let locOption = '';
        locOption =this.template.querySelector('[data-id="displayDecision"]').value;
        if (locOption != '' && locOption != undefined)
        this.disableProcessButton = false;
        else
        this.disableProcessButton = true;
        this.decisionModeValue = locOption;
    }
    handleProcessButton () {
        this.showMainSection = true;
        this.showBuyOption = false;
        this.showExtension = false;
        this.showFullTable = false;
        this.showProductTable = false;
        this.showPartialTable = false;
        if (this.decisionModeValue==='Extension') {
            this.showExtension = true;
            
        }
        else if (this.decisionModeValue==='NoBuy') {
            this.showFullTable = true;
            this.showProductTable = true;
        }
        else {
            this.showNoBuyMessage = false;
            this.showProductTable = true;
            if (this.decisionModeValue==='FullBuy') {
                this.showPartialTable = false;
                this.showFullTable = true;
            }
            else if (this.decisionModeValue==='PartialBuy') {
                this.showPartialTable = true;
                this.showFullTable = false;
            }
        }
            
    }
    handlePreviousButton () {
        this.showMainSection = false;
        this.showBuyOption = true;
        this.showProductTable = false;
        this.showNoBuyMessage = false;
    }
    handleCreate(){
        this.isProcessing = true;
        console.log('handleCreate');
        let ftInfoDetail = [];
        let productListLoc = [];
        if (this.decisionModeValue==='FullBuy')
            productListLoc = this.productData;
        else if (this.decisionModeValue==='PartialBuy')
            productListLoc = this.selectedProducts;
        ftInfoDetail.push({
            productList: productListLoc,
            contractId: this.recordId,
            accountId: this.accountId,
            opportunityId: this.opportunityId,
        });
        
        
        createOpportunity({infoFTDetails:ftInfoDetail})
        .then(result => {
            window.console.log("handleCreate " + result);
            this.opportunityRecordURL = result;
            this.isProcessing = false;
            this.showFinalMessage = true;
            this.showProductTable = false;
            this.showNoBuyMessage = false;
            this.showMainSection = false;
        //this.dispatchEvent(new CloseActionScreenEvent());
            this.closeQuickAction();
        })
        .catch(error => {
                //this.loading = false;
                //this.apsErrorMessage = error.body.message;
                window.console.error("Error on handleCreate " + error);
        });
    }
    closeQuickAction() {
        const closeQA = new CustomEvent('close');
        this.dispatchEvent(closeQA);
      }
}