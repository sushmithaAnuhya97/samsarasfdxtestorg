import { LightningElement , track , api , wire } from 'lwc';
import checkPermission from '@salesforce/apex/FlexContractConsolidation.checkPermission';

export default class FlexAdminOverrideCard extends LightningElement {
    @api contractIds;
    @track jsonData
    @track hasError;
    @track textAreaClass;
    hasPermission = false;
    
    @wire(checkPermission)
    wiredPermission({ error, data }) {
        if (data !== undefined) {
            this.hasPermission = data;
        } else if (error) {
            console.error('Error checking permission:', error);
            this.hasPermission = false;
        }
    }

    handleJsonDataChange(event){
        this.jsonData = event.target.value;
        const customEvent = new CustomEvent('overridecontractids', {
            detail: { overrideContractIds: this.jsonData }
        });
        this.dispatchEvent(customEvent);   
    }
    connectedCallback(){
        console.log('TTMM jsonData',this.jsonData);
        console.log('TTMM contractIds',JSON.parse(JSON.stringify(this.contractIds)));
        this.jsonData = this.contractIds.map(id => id.trim()).join(',');
    }
}