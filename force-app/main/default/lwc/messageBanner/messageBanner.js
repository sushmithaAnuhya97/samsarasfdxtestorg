import { LightningElement, api } from 'lwc';

export default class MessageBanner extends LightningElement {
    @api variation; //base, warning, error, offline
    @api message;

    get isAlertBaseLite(){
        return this.variation === 'baseLite';
    }
    get isAlertInfo(){
        return this.variation === 'info';
    }
    get isWarning(){
        return this.variation === 'warning';
    }    
    
    get alertDivClass(){
        switch(this.variation){
            case "base":
                return "slds-notify slds-notify_alert"
            case "warning":
                //return "slds-notify slds-notify_alert slds-alert_warning"
                return "slds-scoped-notification slds-media slds-media_center slds-theme_warning"
            case "error":
                return "slds-notify slds-notify_alert slds-alert_error"
            case "offline":
                return "slds-notify slds-notify_alert slds-alert_offline"
            case "baseLite":
                return "slds-scoped-notification slds-media slds-media_center slds-scoped-notification_light"
            case "info":
                return "slds-scoped-notification slds-media slds-align_absolute-center slds-theme_info"
        }
    }
}