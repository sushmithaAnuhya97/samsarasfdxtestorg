import { LightningElement,api,wire } from 'lwc';
import { getRelatedListRecords } from 'lightning/uiRelatedListApi';
import { NavigationMixin } from 'lightning/navigation';
import { IsConsoleNavigation, EnclosingTabId, openSubtab, getFocusedTabInfo} from 'lightning/platformWorkspaceApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

import displayInfo from '@salesforce/label/c.Create_Opty_From_Account_Free_Trail_Information';
import noDataMessage from '@salesforce/label/c.Create_Free_Trail_Oppty_Display_Empty_Error';

export default class OpptyRelatedDataTableOfAccCMP extends NavigationMixin(LightningElement)  {
    
    @api recordId;
    displayInfo = displayInfo;
    noDataMessage = noDataMessage;
    currentPage = 1;
    pageSize = 1999;
    filterCriteria = `{and:[{Type:{eq:Revenue Opportunity}},{Probability:{lte:90}}]}`;
    //opptys variables
    spinner=true;
    filteredopptys = [];
    columns = [
        { label: 'Opportunity Name', fieldName: 'opptyIdForURL', type: 'url', typeAttributes: { label: { fieldName: 'Name' }, target: '_blank',tooltip: { fieldName: "Name" } } },
        { label: 'Stage', fieldName: 'Stage', type: 'text' },
        { label: 'Close Date', fieldName: 'closeDate', type: 'date' }
    ];
    
    //console apps navigation-->to know in which appliaction component is opened
    @wire(IsConsoleNavigation) isConsoleNavigation;
    @wire(EnclosingTabId) enclosingTabId;
    
    // Wire method for opptys
    @wire(getRelatedListRecords, {
        parentRecordId: '$recordId',
        relatedListId: 'Opportunities',
        fields: ['Opportunity.Id', 'Opportunity.Name', 'Opportunity.StageName','Opportunity.CloseDate', 'Opportunity.Type', 'Opportunity.Probability'],
        where:'$filterCriteria',
        pageSize: '$pageSize',
        page: '$currentPage'
    })wiredopptys({ error, data }) {
        this.spinner=true;
        if (data) {
            this.spinner=false;
            this.filteredopptys = data.records.map(record => ({ //.filter(rec => (rec.fields.Type.value === 'Revenue Opportunity' && rec.fields.Probability.value <= 90))
                Id: record.fields.Id.value,
                Name: record.fields.Name.value,
                Stage: record.fields.StageName.value,
                closeDate: record.fields.CloseDate.value,
                opptyIdForURL: '/' + record.fields.Id.value
            }));

        } else if (error) {
            console.log(`Failure retrieving Opty data-->${error}`);
            this.spinner=false;
            this.showToast('Error', 'Error loading Opportunities', 'error');
        }
    }

    get showOpptyData(){
        return !this.spinner && this.filteredopptys.length > 0;
    }

    handleBack() {
        this.dispatchEvent(new CustomEvent('back'));
    }

    handleNavigateToFlow() {
        const recId = this.template.querySelector('c-create-oppty-generic-data-table')?.selectedRecordInTable;
        if (recId) {
            this.dispatchEvent(new CustomEvent('close'));
            const url = `/flow/Create_Free_Trial?OpportunityId=${recId}`;
            if (this.isConsoleNavigation) {
                getFocusedTabInfo()
                    .then((tabInfo) => {
                        return openSubtab(tabInfo.isSubtab ? tabInfo.parentTabId : tabInfo.tabId, {
                            url: url,
                            focus: true,
                            label: 'Create Free Trial'
                        });
                    });
            } else {
                this[NavigationMixin.GenerateUrl]({
                    type: 'standard__webPage',
                    attributes: {
                        url: url
                    }  
                }, true).then(url => {
                    window.open(url, "_self");
                })
                // this[NavigationMixin.Navigate]({
                //     type: 'standard__webPage',
                //     attributes: {
                //         url: url
                //     }
                // }, true);
            }
        } else {
            this.showToast('No Opportunity selected', 'Please select an Opportunity', 'error');
        }
    }
    
    showToast(title, message, variant, mode) {
        this.dispatchEvent(
            new ShowToastEvent({
                title: title || 'Notification',
                message: message || '',
                variant: variant || 'info',
                mode: mode || 'dismissable',
            })
        );
    }
}