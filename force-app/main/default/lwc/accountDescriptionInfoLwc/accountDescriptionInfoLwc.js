import { LightningElement, api, track } from 'lwc';

export default class AccountDescriptionInfoLwc extends LightningElement {
    @api recordId;
    @track showEdit = false;

    performEdit() {
        this.showEdit = true;
    }

    hideEdit() {
        this.showEdit = false;
    }
}