import { LightningElement, wire, api } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation'
import getLogoUrlFromAccount from '@salesforce/apex/PCommunityCustomerLogoController.getLogoUrlFromAccount';

export default class PCommunityCustomerLogo extends LightningElement {
    logoUrl;

    @api contactEmailQueryParameter;
    @api maxWidth;
    @api maxHeight;
    @api alignCenter;

    @wire(CurrentPageReference) currentPageReference;

    async connectedCallback(){
        try{
            if (this.contactEmailQueryParameter && this.currentPageReference.state && this.currentPageReference.state[this.contactEmailQueryParameter]){
                this.logoUrl = await getLogoUrlFromAccount({partnerReferralEmail: this.currentPageReference.state[this.contactEmailQueryParameter]});
            }
        }catch(e){
            console.log(e);
        }
    }

    get hasLogoUrl(){
        return !!this.logoUrl;
    }
    
    get styleAttribute() {
        let styleStr = '';
        if (this.maxHeight && this.maxHeight > 0) styleStr += 'max-height: '+this.maxHeight+'px';
        if (this.maxWidth  && this.maxWidth  > 0) styleStr += (styleStr.length > 0 ? ';' : '')+'max-width: '+this.maxWidth+'px';
        return styleStr;
    }

    get divStyleAttribute(){
        return (this.alignCenter ? 'text-align: center;' : '');
    }
}