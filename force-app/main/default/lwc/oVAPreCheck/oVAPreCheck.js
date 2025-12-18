import { LightningElement, track, api } from 'lwc';
import showBannerDetails from '@salesforce/apex/OrderValidationBannerClass.showBannerDetails';
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import validationAssistantHelpURL from '@salesforce/label/c.ValidationAssistantHelpURL';

const columns = [
    { label: 'Kickback Reason', fieldName: 'KickbackReason' },
    { label: 'Kickback Resolution', fieldName: 'KickbackResolution' },
    
];

const data = [
    {
        id: 'a8O8L00000002DOUAY',
        KickbackReason: 'KickbackReason',
        KickbackResolution: 'KickbackResolution',
        
    },
];

export default class OVAPreCheck extends LightningElement {
    @api recordId;
    data =[];
    columns = columns;
    validationsFired = false;
    ovaDocusignexists = false;
    showProcessing = false;
    showToast = false;
    connectedCallback() {
        this.LoadBannerDetails();
    }

    LoadBannerDetails () {
        this.showProcessing = true;
        //console.log('RODRIGO  ' + this.recordId);
        showBannerDetails({recordId : this.recordId})
        .then(result => {
            //console.log('RODRIGO  ' + JSON.stringify(result));
            this.data = result.ovaKickBackList;
            console.log('RODRIGO ' + JSON.stringify(result.ovaKickBackList));
            if(this.data.length > 0)
                this.validationsFired = true;
            else
                this.validationsFired = false;
            //this.validationsFired = true;
            this.ovaDocusignexists = result.ovaDocusignexists;
            this.showProcessing = false;

            if(this.showToast === true){
                const evt = new ShowToastEvent({
                    title: 'Info',
                    message: 'Reloaded. Please see the Validation Assistant component for updated results',
                    variant: 'info',
                });
                this.dispatchEvent(evt);

                this.showToast = false;
            }
        })
        .catch(error => {
            //this.loading = false;
            //this.apsErrorMessage = error.body.message;
            window.console.error("Error on getBundleProducts " + error);
            this.showProcessing = false;
        });
    }

    ReRunValidations(){
        this.LoadBannerDetails ();
        console.log('RODRIGO ShowToastEvent');
        this.showToast = true;
        console.log('dispatched...');
    }

    handleClickHelp() {
        var url = validationAssistantHelpURL;
        window.open(url, "_blank");
    }  
    
}