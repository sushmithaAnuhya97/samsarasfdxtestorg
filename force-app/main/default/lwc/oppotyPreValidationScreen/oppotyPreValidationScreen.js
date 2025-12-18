import { LightningElement, api, wire } from 'lwc';
import { gql, graphql } from 'lightning/uiGraphQLApi';
import { FlowNavigationNextEvent } from 'lightning/flowSupport';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import hasOpportunityValidationExemption from '@salesforce/customPermission/Validation_Exemption_Opportunity';
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
import Submit_To_Closing_Docusign_Warning from '@salesforce/label/c.Submit_To_Closing_Docusign_Warning';
import Previous_Stage_Validation_Error_Message from '@salesforce/label/c.Previous_Stage_Validation_Error_Message';
import Previous_Stage_Validation_Next_Steps from '@salesforce/label/c.Previous_Stage_Validation_Next_Steps';
import Contract_C_R_In_Progress from '@salesforce/label/c.Flex_Prevent_Stage_Closing';
import Contract_CR_In_Progress_Error from '@salesforce/label/c.Contract_CR_In_Progress_Error';
import ChurnRiskSwapReturnNotice from '@salesforce/label/c.ChurnRiskSwapReturnNotice';
import buyoutDocValidation from '@salesforce/label/c.Buyout_Document_Validation';
import Has_Insurance_Subsidy_Product from '@salesforce/label/c.Has_Insurance_Subsidy_Product';
import Add_Insurance_Subsidy_Product from '@salesforce/label/c.Add_Insurance_Subsidy_Product';
import docusignError from '@salesforce/label/c.Oppty_Stage_Validation_Docusign_Error';
import docusignNS from '@salesforce/label/c.Oppty_Stage_Validation_Docusign_NS';
import trialStartDateError from '@salesforce/label/c.Oppty_Stage_Validation_Trial_Start_Date_Error';
import trialStartDateNS from '@salesforce/label/c.Oppty_Stage_Validation_Trial_Start_Date_NS';
import Non_360_ProratedAmount_Error from '@salesforce/label/c.Non_360_ProratedAmount_Error'; //B360 Changes
import Prorated_Amount_Pending_Error from '@salesforce/label/c.Prorated_Amount_Pending_Error'; //B360 Changes
import Prorated_Amount_Failed_Error from '@salesforce/label/c.Prorated_Amount_Failed_Error'; //B360 Changes
import Non360_Opportunity_BAD_DerivedNextBillDate_Error from '@salesforce/label/c.Non360_Opportunity_BAD_DerivedNextBillDate_Error'; //B360 Changes
import eligibileForProrationAPIError from '@salesforce/label/c.eligibileForProrationAPIError'; //B360 Changes
import bypassB360Validations from '@salesforce/customPermission/Bypass_B360_Validations'; //B360 Changes
import Docusign_attachment_Error from '@salesforce/label/c.Oppty_Docusign_attachment_Error_Mesage';//GTMS-29390
import Docusign_attachment_NS from '@salesforce/label/c.Oppty_Docusign_attachment_NS';//GTMS-29390

export default class OppotyPreValidationScreen extends LightningElement {
    @api opportunityRecord;
    @api accountRecord;
    @api quoteRecord;
    @api quoteLineRecords;
    @api loggedInUser;
    @api contactRecord;
    @api shippingRecord;
    @api opptyOwnerRecord;
    @api userRoleRecord;
    @api userProfileRecord;
    @api docuSignStatusRecords;
    @api contractRecord;
    @api periodRecord;
    @api BuyoutAmountInUSD;

    attachmentRecords;
    opportunity;
    account;
    quote;
    user;
    validationHeadline = Validations_headline;
    errorDetails;
    warningDetails = []; // Array to hold warning messages
    _backButtonInvoked = false;  
    stageValidation = false;
    isLoading = false;
    graphqlComplete = false;
    connectedCallBackComplete = false;
    docusignDisabled = false;
    stageValidationDisabled = false;
    hasChildTrialsWOTrialStartDate = false;
    processingComplete = false;

    get gqlVaribales(){
        return {
            opptyId: this.opportunityRecord.Id
        }
    }

    @wire(graphql, {
        query: gql`
            query AutomationSettings ($opptyId: ID!){
                uiapi {
                    query {
                        Automation_Settings__c(
                            where: {
                                or: [
                                    { Name: { eq: "Stage Validation Docusign" } }
                                    { Name: { eq: "Stage Validation" } }
                                ]
                            }
                        ) {
                            edges {
                                node {
                                    Name { value }
                                    Disabled__c { value }
                                    Data__c { value }
                                }
                            }
                        }
                        Oppty_Stage_Validation_Exempt__c(
                            where: {
                                or: [
                                    { Invert_Stage_Validation__c: { eq: true } }
                                    { Invert_Stage_Validation_Docusign__c: { eq: true } }
                                ]
                            }, first: 2000
                        ) {
                            edges {
                                node {
                                    Name { value }
                                    Invert_Stage_Validation__c { value }
                                    Invert_Stage_Validation_Docusign__c { value }
                                }
                            }
                        }
                        
                        Opportunity (where: {TrialResolutionOppty__c:{ eq: $opptyId }}) {
                            edges {
                                node {
                                    Id
                                    Trial_Start_Date_new__c {
                                        value
                                    }
                                }
                            }
                        }
                        ContentDocumentLink (where: {LinkedEntityId:{ eq: $opptyId }}) {
                            edges {
                                node {
                                    Id
                                    ContentDocumentId { value }
                                    LinkedEntityId { value }
                                }
                            }
                        }
                    }
                }
            }
        `, variables: "$gqlVaribales"
          })graphqlQueryResult({ data, errors }) {

            if(data){
                
                try{
                    const result = data.uiapi.query.Automation_Settings__c.edges.map((edge) => edge.node);
                    const resultRoleConfig = data.uiapi.query.Oppty_Stage_Validation_Exempt__c.edges.map((edge) => edge.node);
                    const childTrialOppties = data.uiapi.query.Opportunity.edges.map((edge) => edge.node);
                    const attachmentLinks = data.uiapi.query.ContentDocumentLink.edges.map((edge) => edge.node);

                    console.log(`Graphql Automation Settings result: ${JSON.stringify(result)}`);
                    console.log(`Graphql Stage Validation Exempt result: ${JSON.stringify(resultRoleConfig)}`);

                    // Store attachment records for validation
                    this.attachmentRecords = attachmentLinks;
                    console.log(`Graphql Attachment Links result: ${JSON.stringify(attachmentLinks)}`);

                    if(result && result.length > 0) {                       
                        this.docusignDisabled = result.find(rec => rec.Name.value == 'Stage Validation Docusign').Disabled__c.value;
                        this.stageValidationDisabled = result.find(rec => rec.Name.value == 'Stage Validation').Disabled__c.value;
                    }

                    console.log(`Role Used for calculation: ${this.opportunityRecord.Owner_Role_Copy__c}`);

                    let roleConfigRec;

                    if(this.opportunityRecord.Owner_Role_Copy__c)
                        roleConfigRec = resultRoleConfig.find( rec => this.opportunityRecord.Owner_Role_Copy__c.includes(rec.Name.value));

                    if(roleConfigRec){
                        this.docusignDisabled = (this.docusignDisabled && !roleConfigRec.Invert_Stage_Validation_Docusign__c.value) || (!this.docusignDisabled && roleConfigRec.Invert_Stage_Validation_Docusign__c.value);
                        this.stageValidationDisabled = (this.stageValidationDisabled && !roleConfigRec.Invert_Stage_Validation__c.value) || (!this.stageValidationDisabled && roleConfigRec.Invert_Stage_Validation__c.value);
                    }

                    if(childTrialOppties && childTrialOppties.length > 0){
                        console.log(`Trial Oppties: ${JSON.stringify(childTrialOppties)}`);
                        this.hasChildTrialsWOTrialStartDate = childTrialOppties.some( trialOpty => trialOpty.Trial_Start_Date_new__c.value == null);
                    }

                    this.graphqlComplete = true;
                    console.log(`Data Retrieved`);
                    
                    this.validateRecords();
                }catch(error){
                    this.graphqlComplete = true;
                    this.processingComplete = true;
                    console.log(`Error Processing Graphql data:${JSON.stringify(error)}`);
                }
                
            } else if(errors){
                console.log(`Graphql Failure:${JSON.stringify(errors)}`);
                this.isLoading = false;
            }
          }
    
    // Add getter to check if there are errors
    get hasErrors() {
        return this.errorDetails && this.errorDetails.length > 0;
    }

    get showDefaultScreen(){
        return !this.errorDetails && this.processingComplete; 
    }

    // Add getter to check if there are warnings
    get hasWarnings() {
        return this.warningDetails && this.warningDetails.length > 0;
    }
    
    // Add getter to check if all validations passed (no errors and no warnings)
    get allValidationsPassed() {
        return (!this.hasErrors && !this.hasWarnings);
    }

    @api
    get backButtonInvoked() {
        return this._backButtonInvoked;
    }

    connectedCallback() {
        try {
            this.isLoading = true;
            this.connectedCallBackComplete = true;            
            this.validateRecords();
            this.isLoading = false;
        } catch (error) {
            this.isLoading = false;
            this.processingComplete = true;
            console.error("Error in connectedCallback:", error);
            this.showToast(Validating_error_message, 'error');
        }
    }

    validateRecords() {

        if(!this.connectedCallBackComplete || !this.graphqlComplete) return;

        console.log(`We are successfully in`);
        this.isLoading = false;

        const hasValidationExemptionPermission = hasValidationExemption;
        const hasTaxerrorExemptionPermission = hasTaxerrorExemption;
        const hasOpportunityValidationExemptionPermission = hasOpportunityValidationExemption;
        const trimQuoteRecalculateOnly = Quote_Recalculate_Only?.replace(/;$/, '');
        const trimGenerateNewDocuSign = Generate_New_DocuSign?.replace(/;$/, '');
        const trimOpptyQuoteAmountMismatch = Oppty_Quote_Amount_Mismatch?.replace(/;$/, '');     
        const pstDateParts = new Date().toLocaleDateString('en-US', { timeZone: 'America/Los_Angeles' }).split('/');
        const formattedPSTDate = `${pstDateParts[2]}-${pstDateParts[0].padStart(2, '0')}-${pstDateParts[1].padStart(2, '0')}`;
        const stageValidationEnforcedOppty = this.opportunityRecord.Type == 'Revenue Opportunity'  //Skip Validations for Renewal, free Trial & Webstore Opportunities
                                                && !this.opportunityRecord.SBQQ__RenewedContract__c 
                                                && !this.opportunityRecord.Renewal__c 
                                                && !this.opportunityRecord.Is_Webstore_Upsell_Opportunity__c; 

        //Added to restrict Submit to closing button process if Stage name is beyond Closing stage [GTMS-26875 Dev-Riyaz Shaik]
        const stageList = OpptyStageName.split(',')
        const stageName = this.opportunityRecord?.StageName;
            if(stageList.includes(stageName)){
                this.stageValidation = true;
            }

        const bypassB360Validation = bypassB360Validations; //B360 Changes


        console.log('hasOpportunityValidationExemption', hasOpportunityValidationExemption);
        console.log('Contract_C_R_In_Progress__c from contractRecord:', this.contractRecord?.Contract_C_R_In_Progress__c);
        console.log('Contract Record:', JSON.stringify(this.contractRecord));

        // Debug logs for C&R validation condition
        console.log('C&R Validation Condition Check:');
        console.log('1. !hasOpportunityValidationExemptionPermission:', !hasOpportunityValidationExemptionPermission);
        console.log('2. of_LIC_Products__c !== 0:', this.opportunityRecord?.of_LIC_Products__c !== 0);
        console.log('3. accountRecord:', JSON.stringify(this.accountRecord));
        console.log('3. Account_C_R_In_Progress__c:', this.accountRecord?.Account_C_R_In_Progress__c);
        console.log('4. SBQQ__AmendedContract__c:', this.opportunityRecord?.SBQQ__AmendedContract__c);
        console.log('5. Contract_C_R_In_Progress__c:', this.contractRecord?.Contract_C_R_In_Progress__c);
        console.log('6. Sub_Type__c !== Contract Cancellation:', this.opportunityRecord?.Sub_Type__c !== 'Contract Cancellation');
        console.log('7. Sub_Type__c !== Contract Replacement:', this.opportunityRecord?.Sub_Type__c !== 'Contract Replacement');
        console.log('8. SBQQ__AmendedContract__c !== null:', this.opportunityRecord?.SBQQ__AmendedContract__c !== null);

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
                // C&R Validation Rule - Prevent closing if contract is in C&R process and has LIC products
                condition: !hasOpportunityValidationExemptionPermission && 
                    this.opportunityRecord?.of_LIC_Products__c !== 0 && 
                    this.accountRecord?.Account_C_R_In_Progress__c && 
                    this.opportunityRecord?.SBQQ__AmendedContract__c && 
                    this.contractRecord?.Contract_C_R_In_Progress__c &&
                    this.opportunityRecord?.Sub_Type__c !== 'Contract Cancellation' && 
                    this.opportunityRecord?.Sub_Type__c !== 'Contract Replacement' && 
                    this.opportunityRecord?.SBQQ__AmendedContract__c !== null,
                errorMessage: Contract_CR_In_Progress_Error,
                nextStep: Contract_C_R_In_Progress
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
            //Rule 2 :Since this is a co-termed opportunity, the close date must equal today's date.
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
                    !this.opportunityRecord?.Is_Webstore_Upsell_Opportunity__c,
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

            // Rule 17: DocuSign validation
            {
                condition: (
                    this.opportunityRecord?.Is_Webstore_Upsell_Opportunity__c &&
                    this.opportunityRecord?.Owner_Segment__c !== 'AE1' &&
                    (
                        this.docuSignStatusRecords && 
                        // Update by Swami Gurrala - GTMS - 28926 - OPEN
                        Array.isArray(this.docuSignStatusRecords) &&
                        this.docuSignStatusRecords.some(record => 
                            record.dsfs__Envelope_Status__c === 'Completed' && 
                            (record.Account_Name__c === null || record.Account_Name__c === '')
                        // CLOSE
                        )
                    )
                ),
                errorMessage: 'DocuSign is in progress, please wait for it to complete before proceeding',
                nextStep: Submit_To_Closing_Docusign_Warning
            },
            // Rule 18: Validate Rebate Buyout Document Approved
            {
                condition: (
                    this.quoteRecord?.Competitor_Buyout_Amount__c!== null && 
                    this.BuyoutAmountInUSD >= 500000 &&
                    this.opportunityRecord?.Buyout_Stage__c !== 'Approved' &&
                    this.opportunityRecord?.Buyout_Stage__c !== 'Document Under Review'  
                ),
                errorMessage: 'Rebate Buyout Document has not been received',
                nextStep: buyoutDocValidation
            },
                          // Rule 19: Validate INS Subsidy Product for Subsidy Partner Opportunities
            {
                condition: (
                    this.opportunityRecord?.hasSubsidyPartner__c === true &&
                    this.quoteLineRecords &&
                    this.quoteLineRecords.length > 0 &&
                    !this.quoteLineRecords.some(line => line.SBQQ__ProductCode__c === 'INS-SUBSIDY')
                ),
                errorMessage: Has_Insurance_Subsidy_Product,
                nextStep: Add_Insurance_Subsidy_Product
            },
            // Rule 19: VR Rule - Payment Validation for AE2 First Purchase and Due in Advance
            {
                condition: (
                    // Check if billing stripe ID is null (checkout link not completed)
                    (this.opportunityRecord?.Stripe_Intent_Id__c === null || this.opportunityRecord?.Stripe_Intent_Id__c === '' || this.opportunityRecord?.Stripe_Intent_Id__c === undefined) && 
                        this.opportunityRecord?.Type === 'Revenue Opportunity' &&
                    (
                        // Scenario 1: AE2 First Purchase + Payment Method = Credit Card/ACH debit
                        (
                            this.opportunityRecord?.Owner_Segment__c === 'AE2' &&
                            this.opportunityRecord?.First_Purchase__c === true &&
                            this.quoteRecord?.Customer_Preferred_Payment_Method__c === 'Credit Card/ACH Debit' &&
                            // Out of scope exclusions for AE2
                            !this.accountRecord?.SLED_Account__c && // Public Sector Accounts
                            !this.opportunityRecord?.Finance_Partner__c && // Finance Partner field
                            !this.opportunityRecord?.Reseller__c && // Reseller field
                            !((this.quoteRecord?.Subsidy_Amount__c != null && this.quoteRecord?.Subsidy_Amount__c != '') || (this.quoteRecord?.X3rd_PF_Interest_Subsidy__c != null && this.quoteRecord?.X3rd_PF_Interest_Subsidy__c != '') || (this.quoteRecord?.Buyout_Amount__c != null && this.quoteRecord?.Buyout_Amount__c != '')) && // transactions with rebates
                            !['EUR', 'GBP', 'MXN'].includes(this.opportunityRecord?.CurrencyIsoCode) // exclude EUR, GBP, MXN
                        ) ||
                        
                        // Scenario 2: Payment Terms = Due in Advance (all segments) + Payment Method = Credit Card/ACH debit
                        (
                            this.accountRecord?.Payment_Terms__c?.toLowerCase() === 'due in advance' &&
                            this.quoteRecord?.Customer_Preferred_Payment_Method__c === 'Credit Card/ACH Debit' &&
                            !this.opportunityRecord?.Adjust_License_Start_Date__c // Skip error if Adjust_License_Start_Date__c is true
                        )
                    )
                ),
                errorMessage: this.getPaymentValidationErrorMessage(),
                nextStep: 'Please direct customer to complete the checkout link in order to proceed.'
            },
                          
            // Stage Validation - Must have atleast 1 product, closed date & related contact. When not an add-on Opportunity BANT Need & BANT Budget Confirmed must also be filled.
            { 
                condition: ( 
                    stageValidationEnforcedOppty
                    && !hasValidationExemptionPermission
                    && !this.stageValidationDisabled
                    && !(this.periodRecord 
                        && ( 
                            this.opportunityRecord.SBQQ__AmendedContract__c
                            || ( 
                                !this.opportunityRecord.SBQQ__AmendedContract__c
                                && this.opportunityRecord.Need__c 
                                && this.opportunityRecord.Budget_Confirmed__c
                            ) 
                        )
                        && this.opportunityRecord.Product_Count__c > 0
                        && this.opportunityRecord.Related_Contact__c
                        && this.opportunityRecord.CloseDate
                    )
                ),          
                errorMessage: Previous_Stage_Validation_Error_Message,
                nextStep: Previous_Stage_Validation_Next_Steps
            },

            // Stage Validation - Must have a completed docusign record.
            {
                condition: stageValidationEnforcedOppty
                && !hasValidationExemptionPermission
                && !this.docusignDisabled 
                && !this.stageValidationDisabled 
                && !(this.opportunityRecord?.Sub_Type__c != null && this.opportunityRecord?.Sub_Type__c === 'Auto-Renewal') 
                && !(
                        this.docuSignStatusRecords 
                        && Array.isArray(this.docuSignStatusRecords) 
                        && this.docuSignStatusRecords.some(docRec => docRec.dsfs__Envelope_Status__c == 'Completed')
                ),
                errorMessage: docusignError,
                nextStep: docusignNS
            },

            // GTMS-29390 --- New Rule: DocuSign or attachment Validation, Excluding for Auto-renewals, Promo Opportunities, and Free Trial Opportunities
            {
            condition: (
            !hasValidationExemptionPermission &&
            //!(this.opportunityRecord?.Owner_Role_Copy__c && this.opportunityRecord.Owner_Role_Copy__c.includes('AE1')) &&
            !((this.opportunityRecord?.Sub_Type__c != null && this.opportunityRecord?.Sub_Type__c === 'Auto-Renewal') || this.quoteRecord?.Is_Promo__c === true || this.opportunityRecord?.Type === 'Free Trial Opportunity') &&
            (!this.docuSignStatusRecords ||
            !Array.isArray(this.docuSignStatusRecords) ||
            !this.docuSignStatusRecords.some(record => record.dsfs__Envelope_Status__c === 'Completed')) &&
            (!this.attachmentRecords ||
            !Array.isArray(this.attachmentRecords) ||
            this.attachmentRecords.length === 0)
            ),
            errorMessage: Docusign_attachment_Error,
            nextStep: Docusign_attachment_NS
            },

            // Stage Validation - If there are Trial Opportunities, all of them must have a Trial Start Date
            {
                condition: stageValidationEnforcedOppty
                && !hasValidationExemptionPermission
                && this.hasChildTrialsWOTrialStartDate
                && !this.stageValidationDisabled,
                errorMessage: trialStartDateError, //msg: Found a related Trial Opportunity with no Trial Start Date.
                nextStep: trialStartDateNS //msg: Fill the Trial Start Date of all related Trial Opportunities.
            },
            // B360 Change: Non-360 deal with a Prorated Amount blocks submission
            {
            condition: (
                this.quoteRecord?.Prorated_Amount__c != null &&
                this.opportunityRecord?.Billing_360_Transaction__c === false &&
                !bypassB360Validation
            ),
            errorMessage: Non_360_ProratedAmount_Error,
            nextStep: ' ',
            },

            // B360 Change: 360 deal with pending Prorated Amount blocks submission
            {
            condition: (
                this.quoteRecord?.API_Status__c?.includes('Pending') &&
                this.opportunityRecord?.Billing_360_Transaction__c === true &&
                !bypassB360Validation
            ),
            errorMessage: Prorated_Amount_Pending_Error,
            nextStep: ' ',
            },
            // B360 Change: 360 deal with failed Prorated Amount blocks submission
            {
            condition: (
                (
                this.quoteRecord?.API_Status__c?.includes('Failed') ||
                this.quoteRecord?.API_Status__c?.includes('Error')
                ) &&
                this.opportunityRecord?.Billing_360_Transaction__c === true &&
                !bypassB360Validation
            ),
            errorMessage: Prorated_Amount_Failed_Error,
            nextStep: ' ',
            },

            // B360 change: Non-360 deal with BAD and DerivedNextBillDate blocks submission
            {
            condition: (
                this.opportunityRecord?.Billing_360_Transaction__c === false &&
                this.quoteRecord?.Billing_Ann_Date__c != null &&
                this.quoteRecord?.Derived_Next_Bill_Date__c != null &&
                !bypassB360Validation
            ),
            errorMessage: Non360_Opportunity_BAD_DerivedNextBillDate_Error,
            nextStep: ' ',
            },
            // B360 Change: If B360 deal Prorated Amount is null and the deal is valid for Proration, blocks the submission
            {
            condition: (
                this.opportunityRecord?.Billing_360_Transaction__c === true &&
                this.quoteRecord != null &&
                this.opportunityRecord?.Type === 'Revenue Opportunity' &&
                !bypassB360Validation &&
                this.quoteRecord?.API_Status__c === null &&
                this.quoteRecord?.Prorated_Amount__c === null &&
                this.quoteRecord?.Next_Recurring_Bill_Date__c != null &&
                this.quoteRecord?.B360_Proration_Identifier__c === true
            ),
            errorMessage: eligibileForProrationAPIError,
            nextStep: ' ',
            },
        ];


        // Handle errors based on validation rules
        this.errorDetails = validationRules
            .filter(rule => {                
                return rule.condition;
            })
            .map(rule => ({
                errorMessage: rule.errorMessage,
                nextStep: rule.nextStep
            }));

        // Check for warnings after validating for errors
        this.checkForWarnings();

        this.processingComplete = true;

        // If no errors AND no warnings, automatically navigate to next step
        if (this.errorDetails.length === 0 && this.warningDetails.length === 0) {
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
        if (this.hasErrors) {
            this.showToast('Please resolve all validation issues before proceeding', 'error');
            return;
        }
        
        const navigateNextEvent = new FlowNavigationNextEvent();
        this.dispatchEvent(navigateNextEvent);
    }
    //handleback to record page 
    handleBack() {
        this._backButtonInvoked = true;
        this.dispatchEvent(new FlowNavigationNextEvent());
    }

    // Helper method to determine the appropriate payment validation error message for VR Rule
   getPaymentValidationErrorMessage() {
    // Check AE2 First Purchase condition first (Scenario 1)
    if ((this.opportunityRecord?.Stripe_Intent_Id__c === null || this.opportunityRecord?.Stripe_Intent_Id__c === '' || this.opportunityRecord?.Stripe_Intent_Id__c === undefined) &&
        this.opportunityRecord?.Type === 'Revenue Opportunity' &&
        this.opportunityRecord?.Owner_Segment__c === 'AE2' &&
        this.opportunityRecord?.First_Purchase__c === true &&
        this.quoteRecord?.Customer_Preferred_Payment_Method__c === 'Credit Card/ACH Debit' &&
        !this.accountRecord?.SLED_Account__c &&
        !this.opportunityRecord?.Finance_Partner__c &&
        !this.opportunityRecord?.Reseller__c &&
        !((this.quoteRecord?.Subsidy_Amount__c != null && this.quoteRecord?.Subsidy_Amount__c != '') || (this.quoteRecord?.X3rd_PF_Interest_Subsidy__c != null && this.quoteRecord?.X3rd_PF_Interest_Subsidy__c != '') || (this.quoteRecord?.Buyout_Amount__c != null && this.quoteRecord?.Buyout_Amount__c != '')) &&
        !['EUR', 'GBP', 'MXN'].includes(this.opportunityRecord?.CurrencyIsoCode)
        ) {
        return 'No payment method found on the account, though quote specifies Credit Card/ACH Debit via checkout link.';
    }
    
    // Check Due in Advance condition (Scenario 2)
    if ((this.opportunityRecord?.Stripe_Intent_Id__c === null || this.opportunityRecord?.Stripe_Intent_Id__c === '' || this.opportunityRecord?.Stripe_Intent_Id__c === undefined) &&
        this.opportunityRecord?.Type === 'Revenue Opportunity' &&
        !this.opportunityRecord?.Adjust_License_Start_Date__c &&
        this.accountRecord?.Payment_Terms__c?.toLowerCase() === 'due in advance' &&
        this.quoteRecord?.Customer_Preferred_Payment_Method__c === 'Credit Card/ACH Debit') {
        return 'Customer\'s payment terms require advance payment but no amount has been received.';
    }
    
    // Default fallback message
    return 'No payment method found on the account, though quote specifies Credit Card/ACH Debit via checkout link.';
    }

    // New method to check for warnings
   checkForWarnings() {
    const warnings = [];

    // Warning : Check if PO Number is required but not provided
    if (this.accountRecord?.Customer_require_PO_for_invoicing__c === 'Yes') {
        // Get the PO Number value, defaulting to empty string if null/undefined
        const poNumber = this.opportunityRecord?.PO_Number__c ?? '';
        
        // Check all invalid PO number conditions
        const isInvalidPO = 
            poNumber === '' || 
            poNumber === '-' || 
            poNumber === 'null' || 
            poNumber === 'undefined' ||
            (typeof poNumber === 'string' && poNumber.trim() === '');
            
        if (isInvalidPO) {
            console.log('PO warning will be pushed');
            warnings.push({
                warningMessage: '⚠️ IMPORTANT: Customer requires a PO for invoicing, but no valid PO number is provided',
                recommendation: 'Enter a valid PO number on the opportunity to avoid closing delays.',
                cssClass: 'warning-item po-warning'
            });
        }
    }

    // --- Fiscal Quarter Swap Warning ---
    const isRevenueOpp = this.opportunityRecord?.Type === 'Revenue Opportunity';    
    const renewedContract = this.opportunityRecord?.SBQQ__RenewedContract__c; 
    const isRenewal = this.opportunityRecord?.Renewal__c;
    const isSwapChecked = this.opportunityRecord?.Swap__c;    
    const today = new Date();
    const endDate = this.periodRecord ? new Date(this.periodRecord.EndDate) : null;
    

    let isWithinLast17Days = false;
    if (endDate) {
        const diffTime = endDate.getTime() - today.getTime();
        const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24));
        isWithinLast17Days = diffDays >= 0 && diffDays <= 17;
        
    }

    if (isRevenueOpp  && isSwapChecked && isWithinLast17Days && !renewedContract && !isRenewal) {
      
        warnings.push({
            warningMessage: `⚠️ IMPORTANT: ${ChurnRiskSwapReturnNotice}`,
            recommendation: 'Fiscal Quarter End is with in 17 days.',
            cssClass: 'warning-item po-warning'
        });
    }

    
        this.warningDetails = warnings;
        
    }

}