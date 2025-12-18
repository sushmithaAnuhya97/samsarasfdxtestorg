import { LightningElement,track, wire} from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';
import getOpportunitiesInProcessing from '@salesforce/apex/RetriggerOrderAutomationOpptyController.getOpportunitiesInProcessing';
import processOpportunityProducts from '@salesforce/apex/RetriggerOrderAutomationOpptyController.processOpportunityProducts';
export default class RetriggerOrderAutomationForOrderProcessing extends LightningElement {
    @track opportunities = [];
    @track selectedOpportunities = [];
    @track isLoading = true;
    @track isSelected = false;
    noRecords = false;
    @track sortBy = '';
    @track sortDirection = 'asc';
        draggedColIndex = null;
        
    @track columns = [
        
        { label: 'Order Admin', fieldName: 'orderAdminName', type: 'text', sortable: true,
            wrapText: false,
            initialWidth: 150 
        },
        { label: 'ACV Bookings (Converted)', fieldName: 'ACV_Bookings_SOT__c', type: 'currency', sortable: true,
            wrapText: false,
            initialWidth: 200},
        { label: 'Order Number', fieldName: 'Order_Number__c', type: 'text',sortable: true,
            wrapText: false,
            initialWidth: 150 },
        { label: 'Account Name', fieldName: 'accountName', type: 'text',sortable: true,
            wrapText: false,
            initialWidth: 180 },
        { label: 'Opportunity Name', 
            fieldName: 'opportunityUrl',
            type: 'url',
            typeAttributes: {
                label: { fieldName: 'Name' },
                target: '_blank'
            },
            sortable: true,
            wrapText: false,
            initialWidth: 190},
        { label: 'Shipping Zone', fieldName: 'Shipping_Zone__c' , type: 'text', sortable: true,
            wrapText: false,
            initialWidth: 150 },
        { label: 'Unique Shipping Addresses', fieldName: 'Unique_Shipping_Addresses__c', type: 'text',sortable: true,
            wrapText: false,
            initialWidth: 200},
        { label: 'Type', fieldName: 'Type' , type: 'text',sortable: true,
            wrapText: false,
            initialWidth: 150},
        { label: 'Segment', fieldName: 'Segment__c', type: 'text',sortable: true,
            wrapText: false,
            initialWidth: 150},
        { label: 'Free Trial Purchase', fieldName: 'Free_Trial_Purchase__c', type: 'text',sortable: true,
            wrapText: false,
            initialWidth: 180},
        { label: 'Shipping Method', fieldName: 'Shipping_Method__c', type: 'text',sortable: true,
            wrapText: false,
            initialWidth: 150  },
        { label: 'Orders Processing Date', fieldName: 'Went_to_Orders_Processing_Date__c', type: 'text',sortable: true,
            wrapText: false,
            initialWidth: 180},
        { label: 'Internal RFO Notes', fieldName: 'Internal_RFO_Notes__c', type: 'text',sortable: true,
            wrapText: false,
            initialWidth: 180},
        { label: 'Hold Reason', fieldName: 'Hold_Reason__c', type: 'text',sortable: true,
            wrapText: false,
            initialWidth: 180},
        { label: 'Order Ops Notes', fieldName: 'Order_Ops_Notes__c', type: 'text',sortable: true,
            wrapText: false,
            initialWidth: 180 },
        { label: 'Automation Notes', fieldName: 'Automation_Notes__c', type: 'text', sortable: true,
            wrapText: false,
            initialWidth: 150 
        },
        { label: 'Shipping Country', fieldName: 'Shipping_Country__c', type: 'text', sortable: true,
            wrapText: false,
            initialWidth: 150
        },
        { label: 'Estimated Ship Date', fieldName: 'Estimated_Ship_Date__c', type: 'text',sortable: true,
            wrapText: false,
            initialWidth: 180},
        { label: 'Amount', fieldName: 'Amount', type: 'currency',sortable: true,
            wrapText: false,
            initialWidth: 150},
        { label: 'Owner', fieldName: 'ownerName', type: 'text',sortable: true,
            wrapText: false,
            initialWidth: 180},
        { label: 'Close Date', fieldName: 'CloseDate', type: 'date',sortable: true,
            wrapText: false,
            initialWidth: 150
        }
    ];

     // Load opportunities in Processing stage
    @wire(getOpportunitiesInProcessing)
    wiredOpportunities({ error, data }) {
        this.isLoading = true;
        if (data) {
            if (data.length === 0) {
                this.noRecords = true;
            } else {
                this.noRecords = false;
                this.opportunities = data.map(opp => ({
                    ...opp,
                    ownerName: opp.Owner?.Name,
                    accountName: opp.Account?.Name,
                    orderAdminName: opp.Order_Admin__r?.Name,
                    opportunityUrl: `/${opp.Id}` // Adding URL for the opportunity
                }));
                this.error = undefined;
            }
            this.isLoading = false;          
        } else if (error) {
            this.error = error;
            this.opportunities = [];
            this.isLoading = false;
        }
    }

   
    handleRowSelection(event) {
        this.selectedOpportunities = event.detail.selectedRows;
        console.log('Selected rows: ',  this.selectedOpportunities);
    }

    async handleProcessSelected() {
        if (this.selectedOpportunities.length === 0) {
            this.showToast('Warning', 'Please select opportunities to process', 'warning');
            return;
        }

        try {
            const selectedIds = this.selectedOpportunities.map(opp => opp.Id);
            console.log('Selected rowsids: ',  selectedIds);
            this.isSelected = true;
            this.showToast('Success', 'Processing started successfully', 'success');
            this.selectedOpportunities = [];
            await processOpportunityProducts({ opportunityIds: selectedIds });                      
        } catch (error) {
            this.showToast('Error', error.message, 'error');
        } 
    }

    showToast(title, message, variant) {
        const evt = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant
        });
        this.dispatchEvent(evt);
    }

     // Handling column sorting
    handleSort(event) {
        const { fieldName: sortedBy, sortDirection } = event.detail;
        this.sortBy = sortedBy;
        this.sortDirection = sortDirection;
        this.sortData(sortedBy, sortDirection);
    }

    sortData(fieldName, direction) {
        let parseData = JSON.parse(JSON.stringify(this.opportunities));
        let keyValue = (a) => a[fieldName] ? a[fieldName] : '';

        parseData.sort((x, y) => {
            let xVal = keyValue(x);
            let yVal = keyValue(y);

            return direction === 'asc'
                ? (xVal > yVal ? 1 : -1)
                : (xVal < yVal ? 1 : -1);
        });

        this.opportunities = parseData;
    }

   handleColDragStart(event) {
    this.draggedColIndex = Number(event.currentTarget.dataset.index);
    event.dataTransfer.effectAllowed = 'move';
}
handleColDragOver(event) {
    event.preventDefault();
    event.dataTransfer.dropEffect = 'move';
}
handleColDrop(event) {
    event.preventDefault();
    const targetIdx = Number(event.currentTarget.dataset.index);
    const fromIdx = this.draggedColIndex;
    if (fromIdx !== null && fromIdx !== targetIdx) {
        let newCols = [...this.columns];
        const [removed] = newCols.splice(fromIdx, 1);
        newCols.splice(targetIdx, 0, removed);
        this.columns = newCols;
    }
    this.draggedColIndex = null;
}
   
}