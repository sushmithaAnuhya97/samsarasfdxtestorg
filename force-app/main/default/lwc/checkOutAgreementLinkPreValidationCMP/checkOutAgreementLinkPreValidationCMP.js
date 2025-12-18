import { LightningElement, api } from 'lwc';
import { FlowNavigationNextEvent } from 'lightning/flowSupport';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import Probability_check from '@salesforce/label/c.Probability_check';
import Update_Probability from '@salesforce/label/c.Update_Probability';
import Reseller_check from '@salesforce/label/c.Reseller_check';
import Reseller_Empty from '@salesforce/label/c.Reseller_Empty';
import Amount_greater_than_zero from '@salesforce/label/c.Amount_greater_than_zero';
import Update_Amount from '@salesforce/label/c.Update_Amount';
import Renewal_validation from '@salesforce/label/c.Renewal_validation';
import clickpath_gainsight_update from '@salesforce/label/c.clickpath_gainsight_update';
import payment_type_for_AE1  from '@salesforce/label/c.payment_type_for_AE1';
import Update_payment_type_for_AE1 from '@salesforce/label/c.Update_payment_type_for_AE1';
import Tax_validation from '@salesforce/label/c.Tax_validation';
import Tax_information_is_correct from '@salesforce/label/c.Tax_information_is_correct';
import select_payment_type_check from '@salesforce/label/c.select_payment_type_check';
import Select_payment_type_update from '@salesforce/label/c.Select_payment_type_update';
import Currency_mismatch from '@salesforce/label/c.Currency_mismatch';
import Update_currencyisocode from '@salesforce/label/c.Update_currencyisocode';
import Payment_terms_validation from '@salesforce/label/c.Payment_terms_validation';
import Review_payment_terms from '@salesforce/label/c.Review_payment_terms';
import Billin_firstname_check from '@salesforce/label/c.Billin_firstname_check';
import Update_Billing_first_name from '@salesforce/label/c.Update_Billing_first_name';
import Billing_last_name_check from '@salesforce/label/c.Billing_last_name_check';
import Update_Billing_Last_name from '@salesforce/label/c.Update_Billing_Last_name';
import Billing_email_check from '@salesforce/label/c.Billing_email_check';
import Update_Billing_email from '@salesforce/label/c.Update_Billing_email';
import Billing_phone_is_blank from '@salesforce/label/c.Billing_phone_is_blank';
import Update_billing_phone from '@salesforce/label/c.Update_billing_phone';
import Billing_street_check from '@salesforce/label/c.Billing_street_check';
import Update_Billing_street from '@salesforce/label/c.Update_Billing_street';
import Billing_city_check from '@salesforce/label/c.Billing_city_check';
import Update_Billing_city from '@salesforce/label/c.Update_Billing_city';
import Billing_postal_code_check from '@salesforce/label/c.Billing_postal_code_check';
import Update_billing_postal_code from '@salesforce/label/c.Update_billing_postal_code';
import Non_express_segment from '@salesforce/label/c.Non_express_segment';
import Configuration_segment_update from '@salesforce/label/c.Configuration_segment_update';
import Shipping_and_Handling_amount_check from '@salesforce/label/c.Shipping_and_Handling_amount_check';
import Update_shipping_handling from '@salesforce/label/c.Update_shipping_handling';
import Country_Configuration from '@salesforce/label/c.Country_Configuration';
import Validate_country_information from '@salesforce/label/c.Validate_country_information';
import Switzerland_country_config from '@salesforce/label/c.Switzerland_country_config';
import Update_switzerland_config from '@salesforce/label/c.Update_switzerland_config';
import Shipping_address_check from '@salesforce/label/c.Shipping_address_check';
import SHipping_address_update from '@salesforce/label/c.SHipping_address_update';


export default class CheckOutAgreementLinkPreValidationCMP extends LightningElement {

    @api opportunityRecord;
    @api accountRecord;
    @api quoteRecord;
    @api contractRecord;
    @api shippingAddress;
    

    validationHeadline = 'Checkout Link Validation';
    errorDetails;
    opportunity;
    account;
    quote;
    contract;
    shippingAddress;
 

    connectedCallback() {
        try {
            this.validateRecords();
        } catch (error) {
            console.error("Error in connectedCallback:", error);
            this.showToast('Error validating records', 'error');
        }
    }

    validateRecords() {
        const validationRules = [
            // Basic Opportunity Validations
            {
                condition: this.opportunityRecord?.Probability < 50,
                errorMessage: Probability_check,
                nextStep: Update_Probability
            },
            {
                condition: !this.isBlank(this.opportunityRecord?.Reseller__c),
                errorMessage: Reseller_check,
                nextStep: Reseller_Empty
            },  
            {
                //Opportunity Amount validation
                condition: this.opportunityRecord?.Amount <= 0,
                errorMessage: Amount_greater_than_zero,
                nextStep: Update_Amount
            },         
            // Renewal Validations
            {
                condition: !(
                    (this.opportunityRecord?.Renewal__c &&
                        this.isClickpathOrAutoRenewal() &&
                        this.hasValidGainsightAudit()) ||
                    (!this.opportunityRecord?.Renewal__c &&
                        this.opportunityRecord?.Sub_Type__c !== 'Clickpath')
                ),
                errorMessage: Renewal_validation,
                nextStep: clickpath_gainsight_update
            },          

            // Payment Type Validations
            {
                condition: this.isInvalidPaymentTypeForAE1(),
                errorMessage: payment_type_for_AE1,
                nextStep: Update_payment_type_for_AE1
            },

            // Quote and Tax Validations
            {
                condition: !this.isValidQuoteAndTax(),
                errorMessage: Tax_validation,
                nextStep: Tax_information_is_correct
            },
            //select payment type
            {
                condition: this.isBlank(this.opportunityRecord?.Selected_Payment_Type__c),
                errorMessage: select_payment_type_check,
                nextStep: Select_payment_type_update
            },
            //Currency iso code
            {
                condition: this.opportunityRecord?.CurrencyIsoCode !== this.accountRecord?.CurrencyIsoCode,
                errorMessage: Currency_mismatch,
                nextStep: Update_currencyisocode
            },
            //Payment terms
            {
                condition: this.opportunityRecord?.Payment_Terms__c !== 'Due in advance',                        
                errorMessage: Payment_terms_validation,
                nextStep: Review_payment_terms
            },
            //shippin address
            {
                condition: this.isBlank(this.opportunityRecord?.Shipping_Address_NEW__c),                        
                errorMessage: Shipping_address_check,
                nextStep: SHipping_address_update
            },

            // Billing info 
            {
                condition: this.isBlank(this.accountRecord?.Billing_First_Name__c),               
                errorMessage: Billin_firstname_check,
                nextStep: Update_Billing_first_name
            },
            {
                condition: this.isBlank(this.accountRecord?.Billing_Last_Name__c),              
                errorMessage: Billing_last_name_check,
                nextStep: Update_Billing_Last_name
            },
            {
                condition: this.isBlank(this.accountRecord?.Billing_Email__c),              
                errorMessage: Billing_email_check,
                nextStep: Update_Billing_email
            },
            {
                condition: this.isBlank(this.accountRecord?.Billing_Phone__c),             
                errorMessage: Billing_phone_is_blank,
                nextStep: Update_billing_phone
            },
            {
                condition: this.isBlank(this.accountRecord?.BillingStreet),                
                errorMessage: Billing_street_check,
                nextStep: Update_Billing_street
            },
            {
                condition: this.isBlank(this.accountRecord?.BillingCity),                
                errorMessage: Billing_city_check,
                nextStep: Update_Billing_city
            },
            {
                condition: this.isBlank(this.accountRecord?.BillingPostalCode),              
                errorMessage: Billing_postal_code_check,
                nextStep: Update_billing_postal_code
            },
           
            {
                condition: this.opportunityRecord?.Configuration_Segment__c !== 'Non Express',              
                errorMessage: Non_express_segment,
                nextStep: Configuration_segment_update
            },         
         
            // Shipping Validations
            {
                condition: (this.isBlank(this.opportunityRecord?.Shipping_and_Handling_Amount__c) &&
                           this.opportunityRecord?.Freight_Cost__c == 99999.99 &&
                           this.isBlank(this.opportunityRecord?.Shipping_and_Handling_Manual__c)),
                errorMessage: Shipping_and_Handling_amount_check,
                nextStep: Update_shipping_handling
            },

            // Country-Specific Validations
            {
                condition: !this.isValidCountryConfiguration(),
                errorMessage: Country_Configuration,
                nextStep: Validate_country_information
            },

            // Switzerland-Specific Validations
            {
                condition: !this.isSwitzerlandconfig(),
                errorMessage: Switzerland_country_config,
                nextStep: Update_switzerland_config
            }      
        
        ];
        this.errorDetails = validationRules
            //.filter(rule => rule.condition)
            .filter(rule => {                
                return rule.condition;
            })
            .map(rule => ({
                errorMessage: rule.errorMessage,
                nextStep: rule.nextStep
            }));

        if (this.errorDetails.length === 0) {
            this.handleNext();
        }
    }
    showToast(message, variant) {
        const toastEvent = new ShowToastEvent({
            title: 'Validation Error',
            message: message,
            variant: variant,
        });
        this.dispatchEvent(toastEvent);
    }

    handleNext() {
        this.dispatchEvent(new FlowNavigationNextEvent());
    } 


    // Helper Methods
    isBlank(value) {
        return value === undefined || value === null || value === '';
    }

    isClickpathOrAutoRenewal() {
        return (this.opportunityRecord?.Sub_Type__c === 'Clickpath' ||
            this.contractRecord?.Auto_Renewal__c);
    }

    hasValidGainsightAudit() {
        return this.opportunityRecord?.Gainsight_Audit_Status__c === 'Success' ||
            this.opportunityRecord?.Gainsight_Audit_Override__c;
    }

    isInvalidPaymentTypeForAE1() {
        const isAE1 = this.opportunityRecord?.Owner_Segment__c === 'AE1';
        const paymentType = this.opportunityRecord?.Selected_Payment_Type__c;
        return isAE1 && (paymentType === 'Direct Semi-Annual' || paymentType === 'Direct Quarterly');
    }

    isValidQuoteAndTax() {
        const hasValidQuote = this.quoteRecord?.SBQQ__Status__c == 'Approved' &&
            this.opportunityRecord?.Sales_Tax_Amount__c >= 0;
        const hasValidAE1Tax = this.opportunityRecord?.Owner_Role_Copy__c?.includes('AE1') &&
            this.opportunityRecord?.Total_Sales_Tax__c >= 0;
        return hasValidQuote || hasValidAE1Tax;
    }
    isSwitzerlandconfig() {
        const opp = this.opportunityRecord;
        const quote = this.quoteRecord;
    
        const isSwitzerland = this.shippingAddress?.Shipping_Country__c !== "Switzerland";
        const hasLicenseDue = opp?.Total_License_Due__c > 0;
        const hasShippingContact = !this.isBlank(opp?.Shipping_Contact__c);
        const isQuoteApproved = quote?.SBQQ__Status__c === "Approved" && !this.isBlank(quote);
        const isValidRenewal = this.isBlank(quote) && opp?.Renewal__c === true;
    
        return isSwitzerland && hasLicenseDue && hasShippingContact && (isQuoteApproved || isValidRenewal);
    } 

   
    isValidCountryConfiguration() {
        const account = this.accountRecord;
        const validNACountries = ['United States', 'Canada', 'Mexico'];
        const validEUCountries = [
            'United Kingdom', 'France', 'Belgium', 'Germany', 'Netherlands',
            'Ireland', 'Austria', 'Italy', 'Luxembourg', 'Switzerland'
        ];

        // North American validation
        const isValidNA = !this.isBlank(account?.BillingState) &&
            validNACountries.includes(account?.BillingCountry);
            console.log('isValidNA' , isValidNA);

        // European validation
        const isValidEU = this.isBlank(account?.BillingState) &&
        ['GBP', 'EUR'].includes(account?.CurrencyIsoCode) &&
            validEUCountries.includes(account?.BillingCountry);
            console.log('isValidEU' , isValidEU);
        return isValidNA || isValidEU;
    } 

 

}