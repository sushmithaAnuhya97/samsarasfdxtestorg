import { LightningElement, api, wire } from "lwc";
import { NavigationMixin } from "lightning/navigation";
import { encodeDefaultFieldValues } from "lightning/pageReferenceUtils";

import { CloseActionScreenEvent } from 'lightning/actions';

import { getRecord, getFieldValue } from "lightning/uiRecordApi";

import ACCOUNT_NAME from "@salesforce/schema/Opportunity.Account.Name";
import ACCOUNT_ID from "@salesforce/schema/Opportunity.Account.Id";
import OPPORTUNITY_NAME from "@salesforce/schema/Opportunity.Name";
import OPPORTUNITY_ID from "@salesforce/schema/Opportunity.Id";
import OPPORTUNITY_OWNER_EMAIL from "@salesforce/schema/Opportunity.Owner.Email";
import OPPORTUNITY_OWNER_ROLE from "@salesforce/schema/Opportunity.Owner_Role_Copy__c";

import ID from '@salesforce/user/Id';
import USER_NAME from '@salesforce/schema/User.Name';
import USER_EMAIL from '@salesforce/schema/User.Email';

import DEAL_DESK_SALES from '@salesforce/label/c.Deal_Desk_Sales';
import DEAL_DESK_MAJORS from '@salesforce/label/c.Deal_Desk_Majors';
import DEAL_DESK_TEMPLATE from '@salesforce/label/c.Deal_Desk_Request_Template';

const OPPORTUNITY_FIELDS = [ACCOUNT_ID, ACCOUNT_NAME, OPPORTUNITY_NAME, OPPORTUNITY_ID, OPPORTUNITY_OWNER_EMAIL, OPPORTUNITY_OWNER_ROLE];
const USER_FIELDS = [ USER_NAME, USER_EMAIL];

export default class EmailComposer extends NavigationMixin(LightningElement) {

    @api recordId;

    userId = ID;

    opportunity;
    user;
    errors;

    @wire(getRecord, { recordId: "$recordId", fields : OPPORTUNITY_FIELDS})
    wiredOpportunity({ error, data }) {
        if (error) {
            console.log("getRecord error: ", error);
        } 
        else if (data) {
            this.opportunity = data;
            if(this.user) {
                this.setEmail();
            }       
        }
    }

    @wire(getRecord, { recordId: "$userId", fields : USER_FIELDS})
    wiredUser({ error, data }) {
        if (error) {
            console.log("getRecord error: ", error);
        } 
        else if (data) {
            this.user = data;
            if(this.opportunity) {
                this.setEmail();
            } 
        }
    }

    get toaddress() {
        if(this.opportunity) {
            let ownerRole = getFieldValue(this.opportunity, OPPORTUNITY_OWNER_ROLE);
            return (ownerRole.includes('STR') || ownerRole.includes('SLED')) ? DEAL_DESK_MAJORS : ((ownerRole.includes('MM') || ownerRole.includes('COR')) ? DEAL_DESK_SALES : '');
        }
        return '';
    }

    // Display the email composer with predefined values,
    setEmail() {
        let accountId = getFieldValue(this.opportunity, ACCOUNT_ID);
        let accountName = getFieldValue(this.opportunity, ACCOUNT_NAME);
        let opportunityId = getFieldValue(this.opportunity, OPPORTUNITY_ID);
        let opportunityName = getFieldValue(this.opportunity, OPPORTUNITY_NAME);
        let requesterName = getFieldValue(this.user, USER_NAME);
        let requesterEmail = getFieldValue(this.user, USER_EMAIL);

        let accountUrl = window.location.origin + '/' + accountId;
        let opportunityUrl = window.location.origin + '/' + opportunityId;
        let inject = (str, obj) => str.replace(/{(.*?)}/g, (x,g)=> obj[g]);

        var pageRef = {
            type: "standard__quickAction",
            attributes: {
                apiName: "Global.SendEmail",
            },
            state: {
                recordId: this.recordId,
                defaultFieldValues: encodeDefaultFieldValues({
                    Subject: `Upgrade Request - ${accountName} - ${opportunityName}`,
                    ToAddress: this.toaddress,
                    FromAddress: getFieldValue(this.opportunity, OPPORTUNITY_OWNER_EMAIL),
                    BccAddress: '',
                    HtmlBody: inject(DEAL_DESK_TEMPLATE, {0: accountUrl, 1: accountName, 2: opportunityUrl, 3 : opportunityName, 4 : requesterName, 5: requesterEmail} )
                }),
            },
        };
        this[NavigationMixin.Navigate](pageRef);
        this.dispatchEvent(new CloseActionScreenEvent());
    }
}