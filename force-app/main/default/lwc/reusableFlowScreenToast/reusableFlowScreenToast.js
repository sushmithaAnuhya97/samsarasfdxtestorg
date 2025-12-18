import { LightningElement, api } from 'lwc';

export default class ReusableFlowScreenToast extends LightningElement {
    @api type; // 'info', 'success', 'warning', or 'error'
    @api title;
    @api message;

    get notificationClass() {
        return `slds-scoped-notification slds-media slds-media_center slds-theme_${this.type}`;
    }

    get iconContainerClass() {
        return `slds-icon_container slds-icon-utility-${this.type}`;
    }

    get iconName() {
        return `utility:${this.type}`;
    }

    get iconVariant() {
        return this.type === 'success' ? 'inverse' : ''; 
    }
}