import { LightningElement, api } from 'lwc';
import { FlowNavigationNextEvent } from 'lightning/flowSupport';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import hasValidationExemption from '@salesforce/customPermission/Validation_Rule_Exemption';
import hasTaxerrorExemption from '@salesforce/customPermission/Override_Tax_Error_VRExempt';
import AUTOMATED_PROCESS_USER_ID from '@salesforce/label/c.Automated_Process_UserId';
import Primary_quote from '@salesforce/label/c.Primary_quote';
import Tax_calculation from '@salesforce/label/c.Tax_calculation';
import Update_quote_approved from '@salesforce/label/c.Update_quote_approved';
import Update_Refresh from '@salesforce/label/c.Update_Refresh';
import Cable_collection from '@salesforce/label/c.Cable_collection';
import cable_collection_completion from '@salesforce/label/c.cable_collection_completion';
import Fill_serial_numbers from '@salesforce/label/c.Fill_serial_numbers';
import Update_serial_number from '@salesforce/label/c.Update_serial_number';
import Generate_trial_agreement_link from '@salesforce/label/c.Generate_trial_agreement_link';
import Trial_agreement_link_fields from '@salesforce/label/c.Trial_agreement_link_fields';
import Key_points_on_Account_to_move_deal from '@salesforce/label/c.Key_points_on_Account_to_move_deal';
import CS_POC_details from '@salesforce/label/c.CS_POC_details';
import Co_termed_opportunity from '@salesforce/label/c.Co_termed_opportunity';
import Closedate_update from '@salesforce/label/c.Closedate_update';
import Opportunity_move_to_Ready_to_ship from '@salesforce/label/c.Opportunity_move_to_Ready_to_ship';
import Details_fill from '@salesforce/label/c.Details_fill';
import System_Admin_API_Profile from '@salesforce/label/c.System_Admin_API_Profile';
import Profile_System_Administrator from '@salesforce/label/c.Profile_System_Administrator';
import Sales_ops_profile from '@salesforce/label/c.Sales_ops_profile';
import Order_Operations_Admin from '@salesforce/label/c.Order_Operations_Admin';
import Return_Opportunity from '@salesforce/label/c.Return_Opportunity';
import Validations_headline from '@salesforce/label/c.Validations_headline';
import System_admin_api_profileid from '@salesforce/label/c.System_admin_api_profileid';
import sync_primary_quote from '@salesforce/label/c.sync_primary_quote';
import primary_quote_verify from '@salesforce/label/c.primary_quote_verify';
import buyout_amount_mismatch from '@salesforce/label/c.buyout_amount_mismatch';
import Map_buyout_amount from '@salesforce/label/c.Map_buyout_amount';
import Map_license_term from '@salesforce/label/c.Map_license_term';
import Licese_term_mismatch from '@salesforce/label/c.Licese_term_mismatch';
import subsidy_amount_mismatch from '@salesforce/label/c.subsidy_amount_mismatch';
import Map_subsidy_amount from '@salesforce/label/c.Map_subsidy_amount';
import Quote_Recalculate_Only from '@salesforce/label/c.Quote_Recalculate_Only';
import Generate_New_DocuSign from '@salesforce/label/c.Generate_New_DocuSign';
import Oppty_Quote_Amount_Mismatch from '@salesforce/label/c.Oppty_Quote_Amount_Mismatch';
import Oppty_Quote_Payment_Terms_Mismatch from '@salesforce/label/c.Oppty_Quote_Payment_Terms_Mismatch';
import payment_terms_mismatch from '@salesforce/label/c.payment_terms_mismatch';
import Recalculate_Quote from '@salesforce/label/c.Recalculate_Quote';
import New_Docusign from '@salesforce/label/c.New_Docusign';
import Amount_mismatch from '@salesforce/label/c.Amount_mismatch';
import Validating_error_message from '@salesforce/label/c.Validating_error_message';
import OpptyStageName from '@salesforce/label/c.Oppty_Stage_Name';
import OpptyStageNameValidation from '@salesforce/label/c.Oppty_Stage_Name_validation';
import OpptyStageNameValidationNextStep from '@salesforce/label/c.Oppty_stage_name_next_step';
import buyoutDocValidation from '@salesforce/label/c.Buyout_Document_Validation';


export default class SubmitToClosingPreValidationCMP extends LightningElement {
    @api opportunityRecord;
    @api accountRecord;
    @api quoteRecord;
    @api loggedInUser;
    @api contactRecord;
    @api shippingRecord;
    @api opptyOwnerRecord;
    @api userRoleRecord;
    @api userProfileRecord;

    opportunity;
    account;
    quote;
    user;
    validationHeadline = Validations_headline;
    errorDetails;
    _backButtonInvoked = false;  
    stageValidation= false;
    

    @api
    get backButtonInvoked() {
        return this._backButtonInvoked;
    }


    connectedCallback() {
        try {
            this.validateRecords();
        } catch (error) {
            
            console.error("Error in connectedCallback:", error);
            this.showToast(Validating_error_message, 'error');
        }
    }

    validateRecords() {

        const hasValidationExemptionPermission = hasValidationExemption;
        const hasTaxerrorExemptionPermission = hasTaxerrorExemption;
        const trimQuoteRecalculateOnly = Quote_Recalculate_Only?.replace(/;$/, '');
        const trimGenerateNewDocuSign = Generate_New_DocuSign?.replace(/;$/, '');
        const trimOpptyQuoteAmountMismatch = Oppty_Quote_Amount_Mismatch?.replace(/;$/, '');     
        const pstDateParts = new Date().toLocaleDateString('en-US', { timeZone: 'America/Los_Angeles' }).split('/');
        const formattedPSTDate = `${pstDateParts[2]}-${pstDateParts[0].padStart(2, '0')}-${pstDateParts[1].padStart(2, '0')}`;

        //Added to restrict Submit to closing button process if Stage name is beyond Closing stage [GTMS-26875 Dev-Riyaz Shaik]
        const stageList = OpptyStageName.split(',')
        const stageName = this.opportunityRecord?.StageName;
            if(stageList.includes(stageName)){
                this.stageValidation = true;
            }

        // console.log('hasTaxerrorExemptionPermission', hasTaxerrorExemptionPermission);
        // console.log('hasValidationExemptionPermission', hasValidationExemptionPermission);
        // console.log('Logged In User:', JSON.stringify(this.loggedInUser));
        //console.log('opptyowner:', JSON.stringify(this.opptyOwnerRecord));
        // console.log('userprofile:', JSON.stringify(this.userProfileRecord));
        //console.log('userRoleRecord:', JSON.stringify(this.userRoleRecord));
        // console.log('opportunityRecord:', JSON.stringify(this.opportunityRecord));
        //console.log('accountRecord:', JSON.stringify(this.accountRecord));
        //console.log('quoteRecord:', JSON.stringify(this.quoteRecord));
        // console.log('date', new Date().toISOString().split('T')[0]);
        //console.log('hasValidationExemption', hasValidationExemption);
        // console.log('hasTaxerrorExemption', hasTaxerrorExemption);
         //console.log('pstdate', formattedPSTDate);

        const isConditionMet =
            (
                (this.quoteRecord?.SBQQ__Uncalculated__c || this.quoteRecord?.Show_Docusign_Disclaimer__c) &&
                (
                    this.opportunityRecord?.Type === 'Revenue Opportunity' &&
                    !this.opportunityRecord?.SBQQ__Renewal__c &&
                    !this.opportunityRecord?.Custom_Schedule__c &&
                    this.opportunityRecord?.Owner_Segment__c !== 'AE1' &&
                    this.opportunityRecord?.Owner_Role_Copy__c &&
                    !this.opportunityRecord?.Owner_Role_Copy__c.includes('SLED') &&
                    this.opportunityRecord?.Owner_Manager_Role_Copy__c &&
                    !this.opportunityRecord?.Owner_Manager_Role_Copy__c.includes('SLED') &&
                    (
                        (this.opportunityRecord?.Finance_Segment__c === 'Enterprise' &&
                            this.opportunityRecord?.Is_Webstore_Upsell_Opportunity__c) ||
                        this.opportunityRecord?.Finance_Segment__c === 'Mid Market'
                    ) &&
                    this.opportunityRecord?.Payment_Type__c !== 'Reseller' &&
                    this.opportunityRecord?.Payment_Type__c !== 'Finance Partner' &&
                    !this.opportunityRecord?.Name.includes('InventorySplit') &&
                    this.opportunityRecord?.Selected_Payment_Type__c !== 'Direct Quarterly' &&
                    !this.opportunityRecord?.Buyout_Opportunity__c &&
                    !this.opportunityRecord?.Subsidy_Opportunity__c &&
                    (
                        (['EUR', 'GBP'].includes(this.opportunityRecord?.CurrencyIsoCode) &&
                            this.opportunityRecord?.VAT_Validation_Status__c === 'Confirmed') ||
                        true
                    ) &&
                    (
                        (this.opportunityRecord?.Payment_Terms__c === 'Due in Advance' &&
                            this.opportunityRecord?.Initial_Payment_Terms__c === 'Due in Advance') ||
                        (this.opportunityRecord?.Payment_Terms__c.includes('Net') &&
                            this.opportunityRecord?.Initial_Payment_Terms__c.includes('Net'))
                    )
                )
            ) ||
            (this.opportunityRecord?.Amount !== this.quoteRecord?.SBQQ__NetAmount__c) ||
            (
                (!this.opportunityRecord?.Payment_Terms__c ||
                    !this.opportunityRecord?.Initial_Payment_Terms__c ||
                    (
                        this.opportunityRecord?.Payment_Terms__c !== this.accountRecord?.Payment_Terms__c &&
                        !this.opportunityRecord?.Payment_Terms_Opportunity_only_exception__c &&
                        !this.opportunityRecord?.Finance_Partner__c &&
                        !this.opportunityRecord?.Reseller__c
                    )) &&
                this.opportunityRecord?.Type === 'Revenue Opportunity' &&
                this.opportunityRecord?.RecordTypeId === '0121a000000ARoFAAW' &&
                this.accountRecord?.Segment__c !== 'AE1'
            );

        const validationRules = [
                        {
                //Added to restrict Submit to closing button process if Stage name is beyond Closing stage [GTMS-26875 Dev-Riyaz Shaik]
                condition: this.stageValidation,
                errorMessage: OpptyStageNameValidation,
                nextStep: OpptyStageNameValidationNextStep
            },
            {
                // Rule 1 - Primary quote is not approved, please get the quote approved to move this opportunity into closing.
                condition: this.opportunityRecord?.CPQ_Opportunity__c === true &&
                    this.opportunityRecord?.Probability >= 0.95 &&
                    this.quoteRecord?.SBQQ__Status__c !== 'Approved' &&
                    !hasValidationExemptionPermission,
                errorMessage: Primary_quote,
                nextStep: Update_quote_approved
            },
            //Rule 2 :Since this is a co-termed opportunity, the close date must equal today’s date.
            {
                condition: (this.opportunityRecord?.CloseDate || '') !== formattedPSTDate &&
                    (this.opportunityRecord?.CurrencyIsoCode || '') !== 'EUR' &&
                    (this.opportunityRecord?.CurrencyIsoCode || '') !== 'GBP' &&
                    (this.opportunityRecord?.Type || '') === 'Revenue Opportunity' &&                   
                     Boolean(this.opportunityRecord?.SBQQ__AmendedContract__c) &&
                    !Boolean(this.opportunityRecord?.Adjust_License_Start_Date__c) &&
                    (this.loggedInUser?.ProfileId || '') !== Profile_System_Administrator &&
                    (this.userProfileRecord?.Name || '') !== System_Admin_API_Profile,
                errorMessage: Co_termed_opportunity,
                nextStep: Closedate_update
            },

            {
                // Rule 3 - Quote is pending Tax calculation. Please wait for a minute and refresh the page.
                condition:
                    // this.opportunityRecord.StageName !== 'Closing' ||
                    (this.quoteRecord?.Tax_Calculation_Status__c === 'Refresh') &&
                    (this.opportunityRecord?.Type === 'Revenue Opportunity') &&
                    !(hasTaxerrorExemptionPermission ||
                        this.loggedInUser?.ProfileId === Profile_System_Administrator ||
                        this.userProfileRecord?.Name === System_Admin_API_Profile) &&
                    !(this.opptyOwnerRecord?.FirstName === 'Samsara' &&
                        this.opptyOwnerRecord?.LastName === 'Small Fleets'),

                errorMessage: Tax_calculation,
                nextStep: Update_Refresh
            },
            // Rule 4:  The cable selection tool must be completed for first purchases. If this is an add on order, please use the Cable Selection Link, or check the Alternative Cable Selection box to confirm that you completed cable selection with another method

            {
                condition: this.opportunityRecord?.Alternative_Cable_Selection__c !== true &&
                    !this.opportunityRecord?.Cable_Selection_Method__c &&
                    this.opportunityRecord?.VG_unit_count__c > 0 &&
                    //(this.opportunityRecord?.StageName === 'Closing' || this.opportunityRecord?.StageName === 'Orders Processing') &&
                    (this.loggedInUser?.Region__c === 'North America') &&
                    (this.loggedInUser?.Business_Unit__c === 'Fleet') &&
                    (this.userRoleRecord?.Name?.includes('AE1') ||
                        this.userRoleRecord?.Name?.includes('AE2') ||
                        this.userRoleRecord?.Name?.includes('AE3')) &&
                    (this.opportunityRecord?.Type === 'Revenue Opportunity' ||
                        this.opportunityRecord?.Type === 'Free Trial Opportunity') &&
                    !this.opportunityRecord?.Name?.includes('Webstore'),
                errorMessage: Cable_collection,
                nextStep: cable_collection_completion
            },

            //Rule 5 :  Please fill out the fields CS POC First Name, CS POC Email and Key Value Points on the Account prior to moving this deal

            {
                condition: this.loggedInUser?.ProfileId !== Profile_System_Administrator &&
                    this.userProfileRecord?.Name !== System_admin_api_profileid &&
                    this.userProfileRecord?.Name !== Sales_ops_profile &&
                    this.opportunityRecord?.First_Purchase__c &&
                    this.opportunityRecord?.Probability >= 0.95 &&
                    this.opportunityRecord?.Type === 'Revenue Opportunity' &&
                    (!this.opportunityRecord?.Owner_Role_Copy__c?.includes('EMEA') ||
                        !this.opportunityRecord?.Owner_Role_Copy__c?.includes('MX')) &&
                    ((this.opportunityRecord?.Owner_Role_Copy__c?.includes('AE1') ||
                        this.opportunityRecord?.Owner_Role_Copy__c?.includes('AE2') ||
                        this.opportunityRecord?.Owner_Role_Copy__c?.includes('AE3')) ||
                        (this.opportunityRecord?.ACV_Bookings_SOT__c > 100000.00 &&
                            (this.opportunityRecord?.Owner_Role_Copy__c?.includes('ENT') ||
                                this.opportunityRecord?.Owner_Role_Copy__c?.includes('Major') ||
                                this.opportunityRecord?.Owner_Role_Copy__c?.includes('Enterprise')))) &&
                    !this.opportunityRecord?.Is_Webstore_Upsell_Opportunity__c &&
                    (!this.accountRecord?.CS_POC_First_Name__c ||
                        !this.accountRecord?.CS_POC_Email_Address__c ||
                        !this.accountRecord?.Key_Value_Points__c),
                errorMessage: Key_points_on_Account_to_move_deal,
                nextStep: CS_POC_details
            },

            //Rule 6 : Please remember to generate a Trial Agreement Link so the customer can validate the details. To get the link, remember to fill the required fields: period, start date, primary contact (with email), at least one goal and planned installation date
            {
                condition: this.opportunityRecord?.Type === 'Free Trial Opportunity' &&
                    //this.opportunityRecord?.StageNameHasChanged &&
                    (
                        !this.opportunityRecord?.Trial_Period__c ||
                        !this.opportunityRecord?.Trial_Start_Date_new__c ||
                        !this.opportunityRecord?.Trial_Primary_Contact__c ||
                        (!this.opportunityRecord?.Trial_Goal_1__c &&
                            !this.opportunityRecord?.Trial_Goal_2__c &&
                            !this.opportunityRecord?.Trial_Goal_3__c) ||
                        !this.opportunityRecord?.Planned_Trial_Installation_Date__c ||
                        !this.contactRecord?.Email
                    ) &&
                    this.opportunityRecord?.Cable_Send_Only__c === false &&
                    !hasValidationExemptionPermission,
                errorMessage: Generate_trial_agreement_link,
                nextStep: Trial_agreement_link_fields
            },

            // Rule 7 :  Please fill serial numbers prior to moving this deal to the closing stage.
            {
                condition: this.loggedInUser?.Id !== AUTOMATED_PROCESS_USER_ID &&
                    !this.opportunityRecord?.FT_Conversion_Serial_No__c &&
                    this.opportunityRecord?.Free_Trial_Purchase__c === 'Partial Buy' &&
                    // this.opportunityRecord?.StageName === 'Closing' &&
                    this.opportunityRecord?.Type === 'Revenue Opportunity' &&
                    this.userProfileRecord?.Name?.includes('Sales') &&
                    this.opportunityRecord?.Original_FT_Oppty_Line_Item_SF_Ids__c,
                errorMessage: Fill_serial_numbers,
                nextStep: Update_serial_number
            },

            //Rule 8 :  The following information must be completed prior to moving an opportunity into Ready to Ship or Closed Won
            {
                condition: !(
                    hasValidationExemptionPermission ||
                    this.userProfileRecord?.Name?.includes("Finance") ||
                    this.userProfileRecord?.Name === Order_Operations_Admin ||
                    this.userProfileRecord?.Name === Profile_System_Administrator ||
                    this.loggedInUser?.Id === AUTOMATED_PROCESS_USER_ID
                ) &&
                    this.opportunityRecord?.RecordTypeId !== Return_Opportunity &&                   
                    (
                        !this.shippingRecord?.Shipping_FirstName__c ||
                        !this.shippingRecord?.Shipping_LastName__c ||
                        !this.shippingRecord?.Shipping_Email__c ||
                        !this.shippingRecord?.Shipping_Contact__c ||
                        !this.shippingRecord?.Shipping_Address_Line_1__c ||
                        !this.shippingRecord?.Shipping_City__c ||
                        (this.shippingRecord?.Shipping_State__c === "" &&
                            (
                                this.shippingRecord?.Shipping_Country__c === 'United States' ||
                                this.shippingRecord?.Shipping_Country__c === 'Canada'
                            )
                        ) ||
                        !this.shippingRecord?.Shipping_Zip_Code__c ||
                        !this.shippingRecord?.Shipping_Country__c ||
                        this.opportunityRecord?.Product_Count__c < 1
                    ),
                errorMessage: Opportunity_move_to_Ready_to_ship,
                nextStep: Details_fill
            },

            // Rule 9:  Primary quote is not synced on opportunity
            {
                condition: !this.quoteRecord,
                errorMessage: primary_quote_verify,
                nextStep: sync_primary_quote
            },

            // Rule 10:  Opportunity and Quote buyout amount value mismatch
            {
                condition: Boolean(this.opportunityRecord?.Buyout_Opportunity__c &&
                    ((this.opportunityRecord?.Buyout_Amount__c ?? 0) * -1) !== (this.quoteRecord?.Buyout_Amount__c ?? 0)),
                errorMessage: buyout_amount_mismatch,
                nextStep: Map_buyout_amount
            },

            // Rule 11 : Opportunity and Quote subsidy amount value mismatch
            {
                condition: Boolean(
                    this.opportunityRecord?.Subsidy_Opportunity__c &&
                    ((this.opportunityRecord?.Subsidy_Amount__c ?? 0) * -1) !== (this.quoteRecord?.Subsidy_Amount__c ?? 0)
                ),
                errorMessage: subsidy_amount_mismatch,
                nextStep: Map_subsidy_amount
            },



            // Rule 12 : Opportunity and Quote license term value mismatch
            {
                condition: this.quoteRecord?.License_Term__c &&
                    this.opportunityRecord?.License_Term__c !==
                    (isNaN(parseFloat(this.quoteRecord?.License_Term__c)) ? NaN : parseFloat(this.quoteRecord?.License_Term__c)),
                errorMessage: Licese_term_mismatch,
                nextStep: Map_license_term
            },
            // Rule 13: Quote recalculation needed
            isConditionMet && {
                condition: this.quoteRecord?.SBQQ__Uncalculated__c,
                errorMessage: trimQuoteRecalculateOnly,
                nextStep: Recalculate_Quote
            },
            // Rule 14: DocuSign generation required
            isConditionMet && {
                condition: this.quoteRecord?.Show_Docusign_Disclaimer__c,
                errorMessage: trimGenerateNewDocuSign,
                nextStep: New_Docusign
            },

            // Rule 15: Opportunity and Quote amount mismatch
            isConditionMet && {
                condition: this.opportunityRecord?.Amount !== this.quoteRecord?.SBQQ__NetAmount__c,
                errorMessage: trimOpptyQuoteAmountMismatch,
                nextStep: Amount_mismatch
            },
            // Rule 16: Payment terms mismatch
            isConditionMet && {
                condition: (
                    (this.accountRecord?.Segment__c !== 'AE1' &&
                        !this.opportunityRecord?.Payment_Terms__c)

                    ||

                    (this.accountRecord?.Segment__c !== 'AE1' &&
                        this.opportunityRecord?.Payment_Terms__c !== this.accountRecord?.Payment_Terms__c &&
                        !this.opportunityRecord?.Reseller__c &&
                        !this.opportunityRecord?.Finance_Partner__c &&
                        !this.opportunityRecord?.Payment_Terms_Opportunity_only_exception__c)
                ),
                errorMessage: Oppty_Quote_Payment_Terms_Mismatch,

                nextStep: payment_terms_mismatch
            },
            // Rule 18: Validate Rebate Buyout Document Approved
            {
                condition: (
                    this.quoteRecord?.Competitor_Buyout_Amount__c!== null && 
                    this.quoteRecord?.Competitor_Buyout_Amount__c !== 0 &&
                    this.opportunityRecord?.Buyout_Stage__c !== 'Approved' &&
                    this.opportunityRecord?.Buyout_Stage__c !== 'Document Under Review'     
                ),
                errorMessage: 'Rebate Buyout Document has not been received',
                nextStep: buyoutDocValidation
            },


        ];

        // Handle errors based on validation rules
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

    // Navigate to the next step if no rule satisifes
    handleNext() {        
        this.dispatchEvent(new FlowNavigationNextEvent());
    }
    //handleback to record page 
    handleBack() {
        this._backButtonInvoked = true;
        this.dispatchEvent(new FlowNavigationNextEvent());
    }

}