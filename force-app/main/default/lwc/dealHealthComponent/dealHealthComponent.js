import { LightningElement, api, wire } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import updateQuoteDealHealth from '@salesforce/apex/DealHealthController.updateQuoteDealHealth';
import RECOMMENDED_DISCOUNT from '@salesforce/schema/SBQQ__Quote__c.Recommended_Discount__c'; 
import DEAL_HEALTH from '@salesforce/schema/SBQQ__Quote__c.Deal_Health__c'; 
import { FlowNavigationNextEvent } from 'lightning/flowSupport';
import DealHealthErrorNote from '@salesforce/label/c.DealHealth_Error_Note';
import DealHealthErrorOption from '@salesforce/label/c.DealHealth_Error_Option_To_Proceed';
import DealHealthErrorPreText from '@salesforce/label/c.DealHealth_Error_Pretext';
import { gql, graphql } from 'lightning/uiGraphQLApi';
import DealHealthPilotUserIds from '@salesforce/label/c.Deal_Health_pilot_user_role_Id';
import Id from "@salesforce/user/Id";

const quoteFields = [RECOMMENDED_DISCOUNT, DEAL_HEALTH];

export default class DealHealthComponent extends LightningElement {
    @api recordId; //id from record page    
    @api quoteIdFromFlow; // id from flow when this component is called inside of Quote Approval
    @api availableActions = []; // navigation buttons for flow 

    dealHealtErrNote = DealHealthErrorNote;
    dealHealthErrOption = DealHealthErrorOption;
    dealHealthErrPreText = DealHealthErrorPreText;
    dealHealthPilotUserIds = DealHealthPilotUserIds;
    
    _recommendedDiscount;
    disabledInCustomSettings = false;
    _dealHealth;
    _backButtonInvoked = false;
    dealHealthBarClass;
    processingComplete = false;
    dealHealthText = '';


    userRoleId;
    userId = Id;


    @api get dealHealth() {
        return this._dealHealth;
    }
    
    @api get recommendedDiscount() {
        return this._recommendedDiscount;
    }

    @api 
    get backButtonInvoked() {
        return this._backButtonInvoked; 
    }

    get quoteId() {
        return this.quoteIdFromFlow ? this.quoteIdFromFlow : this.recordId ? this.recordId : '';
    }

    get isLoading() {
        return !this.processingComplete;
    }

    get hideComp() {
        return (this.recordId && this.processingComplete && !this._dealHealth) || (this.disabledInCustomSettings);
    }

    get showComp() {
        return !this.hideComp;
    }

    get showRecommendedDiscount() {
        return this._recommendedDiscount ? true : false;
    }

    get hostedFromFlow() {
        return this.quoteIdFromFlow;
    }

    get discountRowClass(){ //adds padding bottom when hosted on lightning record page
        return `recommended-discount-row${this.hostedFromFlow ? '': '-with-padding'}`;
    }

    get queryData(){
		return {
			userId: this.userId,
		};
	}

    @wire(graphql, {
        query: gql`
          query DealHealthAutomation ($userId: ID!) {
            uiapi {
              query {
                Automation_Settings__c (where:{Name:{eq:"Deal Health"}}) {
                  edges {
                    node {
                    Disabled__c {
                        value
                      }
                    }
                  }
                }
				User (where:{Id:{eq:$userId}}) {
                  edges {
                    node {
                    UserRoleId {
                        value
                      }
                    }
                  }
                }
              }
            }
          }
        `,
        variables: '$queryData'
      })
      graphqlQueryResult({ data, errors }) {
        if (data) {
            const results = data.uiapi.query.Automation_Settings__c.edges.map((edge) => edge.node);
            const userData = data.uiapi.query.User.edges.map((edge) => edge.node);
            this.userRoleId = userData[0].UserRoleId.value;
          if(results.length > 0 && userData.length>0 ) {
                this.disabledInCustomSettings = results[0]?.Disabled__c.value && !this.dealHealthPilotUserIds.includes(this.userRoleId);
            }
            }else if(errors){  
            console.log(errors);
        }
      }

    @wire(getRecord, { recordId: '$quoteId', fields: quoteFields })
    wiredQuote({ error, data }) {
        if (data) {
            if (this.hostedFromFlow) {
                this.invokeApexDealHealth();
            } else {
                this._dealHealth = data.fields.Deal_Health__c.value;
                if (this._dealHealth !== 'Green' && this._dealHealth) {
                    this._recommendedDiscount = data.fields.Recommended_Discount__c.value;
                }
                this.updateDealHealthBarClass();
                this.processingComplete = true;
            }
        } else if (error) {
            
            this.processingComplete = true;
           // this.showToast('Error', `Error fetching quote data`, 'error');
        }
    }

    invokeApexDealHealth() {
        updateQuoteDealHealth({ quoteId: this.quoteId })
            .then(result => {
                this._dealHealth = result.split('_')[1];
                if (this._dealHealth !== 'Green') {
                    this._recommendedDiscount = result.split('_')[0];
                }
                this.updateDealHealthBarClass();
            })
            .catch(error => {
                this.processingComplete = true;
                this._dealHealth = 'Unknown';
                this.handleNext();
               // this.showToast('Error', `Error Calculating Discount Health: ${this.errorMessage}`, 'error');
            });
    }

    updateDealHealthBarClass() {
        if (!this._dealHealth) {
            this.processingComplete = true;
            return;
        }
        switch (this._dealHealth) {
            case 'Green':
                this.dealHealthBarClass = 'green';
                break;
            case 'Yellow':
                this.dealHealthBarClass = 'yellow';
                break;
            case 'Orange':
                this.dealHealthBarClass = 'orange';
                break;
            case 'Red':
                this.dealHealthBarClass = 'red-dark';
                break;
            case 'Unknown':
                this.dealHealthBarClass = 'grey';
                this.dealHealthText = 'Unknown';
                break;
            default:
                console.error('Error', 'Unable to calculate Discount Health', 'error');
        }
        this.processingComplete = true;
    }

    handleNext() {
        this.dispatchEvent(new FlowNavigationNextEvent());
    }

    handleBack() { //back is handled by flow based on _backButtonInvoked variable.
        this._backButtonInvoked = true;
        this.dispatchEvent(new FlowNavigationNextEvent());
    }

    showToast(title, message, variant) {
        this.dispatchEvent(
            new ShowToastEvent({
                title: title,
                message: message,
                variant: variant
            })
        );
    }
}