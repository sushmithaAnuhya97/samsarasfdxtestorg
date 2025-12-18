//GTMS-3737: Lavanya : Updated the IF condition in "moveWebstoreOpptyToClosing" method to check if the amount received and expressed agreement date have been updated and also if the probability is less than 95%
//Groundswell : Nilesh Jain - Opportunity Workflow methods.
//GTMS-5041: Anil Bogadi Update logic behind Configuration_Segment__c so if user role contains "Partner", Non Express is populated.
//GTMS-8619: Aparna Raypitam Updated (oz 5600/2500 to 6500)
//Nov-17-2022 Rajesh GTMS-8209: Added Mexico Freight cost
//Jan-08-2023 Rajesh GTMS-10675: Updated Freight cost for West, East, Central and for NonCanadaFrance
public with sharing class OpportunityWorkflowConversion {

    @TestVisible private static Boolean firstRun = true;

    //Groundswell : Nilesh Jain - Workflow methods to run on insert and update.
    public static void beforeInsertUpdateMethod(Opportunity newOpportunity, Opportunity oldOpportunity, Opportunity oppFields,Account opportunityAccount, User ownerRec){
        setClosedDateForReturns(newOpportunity, oldOpportunity);
        setDefaultShippingAddress(newOpportunity, opportunityAccount);
        updateLicenseTermCreditOnCreation(newOpportunity, oldOpportunity, oppFields);      
        customerFreightAccount(newOpportunity);
        makeFreightChargeszero(newOpportunity, oldOpportunity);
        wabashReferralPayout(newOpportunity, oldOpportunity);
        referralPayoutFleet(newOpportunity, oldOpportunity);
        referralPayoutIndustrialENT(newOpportunity,oldOpportunity, ownerRec);
        //licenseTermUpdateForRebateTypeAndDelinquentOpp(newOpportunity, oldOpportunity, oppFields);  
        stampRTNNumber(newOpportunity, oldOpportunity);
        //GTMS-5041: Anil Bogadi 
        updateOpportunitySegment(newOpportunity, oldOpportunity);

        
        if (firstRun){
            //GTMS - 6244 : Sweta - WFlow Rule
            renewalCredit(newOpportunity, oldOpportunity);
            updatePushToNetsuiteCounter (newOpportunity, oldOpportunity);
            licenseTermUpdateForOtherRebateTypeAndDelinquentOpp(newOpportunity, oppFields);
            financeSegmentStamp(newOpportunity, oldOpportunity);
            setPriceBookName(newOpportunity, oldOpportunity, oppFields);
            copyOwnerRole(newOpportunity,oldOpportunity,oppFields, ownerRec); 
            closingAlertforRepsManager(newOpportunity,oldOpportunity,oppFields,ownerRec);
            addDefaultExpiringDiscountDate(newOpportunity, oldOpportunity, ownerRec); 
            firstRun = false;
        }

        opportunityToAccountRollupWorkflow(newOpportunity,oldOpportunity);
        updateShippingCost(newOpportunity);
        updateShippingCostCanadaAndFrance(newOpportunity);
        matchBlendedToApprovedDiscretionaryDiscount(newOpportunity,oldOpportunity);
    }

    //Groundswell : Nilesh Jain - Workflow methods to run on update only.
    public static void beforeUpdateMethod(Opportunity newOpportunity, Opportunity oldOpportunity, User ownerRec){
        updateToQualified(newOpportunity, oldOpportunity);
        //financeSegmentStamp(newOpportunity, oldOpportunity);
        overwriteValidation(newOpportunity, oldOpportunity);
        saveOpptyAmtWhenClosedWon(newOpportunity, oldOpportunity);
        clearPushTransferToNetsuite(newOpportunity, oldOpportunity);
        mboAuthorizedStamping(newOpportunity, oldOpportunity);
        clearPushReturnToNetsuiteCheckbox(newOpportunity, oldOpportunity);
        moveWebstoreOpptyToClosing(newOpportunity, oldOpportunity);
        clearValueForPrimaryQuote(newOpportunity, oldOpportunity);
        deactivationTimestamp(newOpportunity, oldOpportunity);
        trialInvoiceTimestamp(newOpportunity, oldOpportunity);
        addDefaultExpiringDiscountDate(newOpportunity, oldOpportunity, ownerRec);
        reOpenTrialEndDateExceeded(newOpportunity, oldOpportunity);
        freeTrialReturnDateUpdate(newOpportunity, oldOpportunity);
        stampTrialCompletionDate(newOpportunity, oldOpportunity);
        referralPayoutAmtUncappedFleet(newOpportunity, oldOpportunity);
        stampResponsiblePartyEmail(newOpportunity, oldOpportunity);
    }
    
    //Groundswell : Tanuj - Workflow methods to run on After Insert/Update only.
    public static void afterInsertUpdateMethod(Opportunity newOpportunity, Opportunity oldOpportunity, Account opportunityAccount){
        updateAccountForNsSync(newOpportunity, oldOpportunity, opportunityAccount);
    }

    //Groundswell : Nilesh Jain - Workflow methods to run on After Update only.
    public static void afterUpdateMethod(Opportunity newOpportunity, Opportunity oldOpportunity, Account opportunityAccount){
        accountInternallyFinanced(newOpportunity, opportunityAccount);
        updatePaymentMethodLink(newOpportunity, oldOpportunity, opportunityAccount);
        //updateProductDiscountsOnAccount(newOpportunity, opportunityAccount);
    }
    
    //Groundswell : Nilesh Jain - Uncheck Overwrite Validation workflow changes.
    public static void overwriteValidation(Opportunity newOpportunity, Opportunity oldOpportunity){
        if(oldOpportunity.Id != null && newOpportunity.Overwrite_Validation_Rule__c && !System.isFuture() && !System.isQueueable()){
            newOpportunity.Overwrite_Validation_Rule__c = false;
        }
    }
    //End
    
    //Groundswell : Nilesh Jain - Customer Freight Account workflow changes.
    public static void customerFreightAccount(Opportunity newOpportunity){
        if(newOpportunity.Cust_Partner_Shipping_Account_Number__c != null && newOpportunity.Freight_Account__c != '00000'){
            newOpportunity.Freight_Account__c = '00000';
        }
    }
    //End
    
    //Groundswell : Nilesh Jain - Set Closed Date for Returns workflow changes
    public static void setClosedDateForReturns(Opportunity newOpportunity, Opportunity oldOpportunity){
        if((oldOpportunity.Id == null && (newOpportunity.StageName == 'Refunded - Closed' ||  newOpportunity.StageName == 'Return Cancelled')) ||
                (oldOpportunity.Id != null && newOpportunity.StageName != oldOpportunity.StageName && (newOpportunity.StageName == 'Refunded - Closed' ||  newOpportunity.StageName == 'Return Cancelled'))){
            newOpportunity.CloseDate = system.today();
        }
    }
 
    //Groundswell : Nilesh Jain - Set Default Shipping Address workflow changes
    public static void setDefaultShippingAddress(Opportunity newOpportunity, Account opportunityAccount){
        if(opportunityAccount.Id != null && newOpportunity.Shipping_Address_Line_1__c == null && opportunityAccount.BillingStreet != null){
            newOpportunity.Shipping_Address_Line_1__c = opportunityAccount.BillingStreet;
            newOpportunity.Shipping_City__c = opportunityAccount.BillingCity;
            newOpportunity.Shipping_Zip_Code__c = opportunityAccount.BillingPostalCode;
        }
    }

    //Groundswell : Nilesh Jain - Update To Qualified workflow changes
    public static void updateToQualified(Opportunity newOpportunity, Opportunity oldOpportunity){
        if(newOpportunity.StageName == 'Incubate' && newOpportunity.Product_Count__c != oldOpportunity.Product_Count__c
                && newOpportunity.Product_Count__c > oldOpportunity.Product_Count__c){
            newOpportunity.StageName = 'Qualified';
        }
    }
    //Groundswell : Nilesh Jain - Finance Segment Stamp workflow changes
    /*public static void financeSegmentStamp(Opportunity newOpportunity, Opportunity oldOpportunity){
        if(newOpportunity.StageName != oldOpportunity.StageName && (!newOpportunity.IsClosed || newOpportunity.Finance_Segment_Stamp__c == null)){
            newOpportunity.Finance_Segment_Stamp__c = newOpportunity.Finance_Segment__c;
        }
    }*/
    
    // Groundswell : Tanuj - WFlow Rule - Update License Term Credit on Creation
    public static void updateLicenseTermCreditOnCreation(Opportunity newOpportunity, Opportunity oldOpportunity, Opportunity oppFields){  
        if(newOpportunity.Returning_Opportunity__c != NULL && 
           (newOpportunity.Rebate_Type__c == 'License Term Credit' 
            && newOpportunity.License_Months_to_Credit__c != null)){
                if(oldOpportunity.Id == null){
                    newOpportunity.Name = oppFields.Name +'& - License Term Credit';
                }else{
                  newOpportunity.Name = oppFields.Returning_Opportunity__r.Name +'& - License Term Credit';
                }
                newOpportunity.Amount = 0;
            }
    }
    
    // Groundswell : Tanuj - WFlow Rule - Save the Amount of the Opportunity when Closed Won
    public static void saveOpptyAmtWhenClosedWon(Opportunity newOpportunity, Opportunity oldOpportunity){
        if(oldOpportunity.Id != null
        && (newOpportunity.StageName != oldOpportunity.StageName ||  newOpportunity.Historical_Amount__c  != oldOpportunity.Historical_Amount__c)
        && ((newOpportunity.StageName == 'Closed Won' || newOpportunity.StageName == 'Refunded - Closed') && newOpportunity.Historical_Amount__c == null)
        ){
            newOpportunity.Historical_Amount__c = newOpportunity.Amount;
        }
    }
    
    // Groundswell : Tanuj - WFlow Rule - Clear Push Transfer Order to Netsuite Checkbox
    // Clearing Push Transfer Order to Netsuite Checkbox after the order field has been populated
    public static void clearPushTransferToNetsuite(Opportunity newOpportunity, Opportunity oldOpportunity){
        if(oldOpportunity.Id != null && newOpportunity.Netsuite_Transfer_Order_ID__c != null && newOpportunity.Retry_TO_to_NS__c == true){
            newOpportunity.Retry_TO_to_NS__c = false;
        }    
    }
    
    
    // Groundswell : Tanuj - WFlow Rule - Update Account for NS Sync
    // Update Account for NS Sync when Opportunity is at Decision,Qualified,Proposal,Purchase,Trial
    public static void updateAccountForNsSync(Opportunity newOpportunity, Opportunity oldOpportunity, Account opportunityAccount){
        Set<String> stageTypeSet = new Set<String>{'Decision', 'Qualified', 'Proposal', 'Purchase', 'Trial'};
        if( stageTypeSet.contains(newOpportunity.StageName)
        && (opportunityAccount != null && opportunityAccount.Netsuite_Id__c == null)
        ){
            opportunityAccount.Push_to_Netsuite__c = true;
            DMLWrapper.doUpdate(opportunityAccount, new List<SObjectField>{Account.Push_to_Netsuite__c}); 
        }
    }

    //Groundswell - Nilesh Jain : Account Internally Financed workflow changes.
    public static void accountInternallyFinanced(Opportunity newOpportunity, Account opportunityAccount){
        if(opportunityAccount.Id != null && !opportunityAccount.Internally_Financed__c
        && newOpportunity.Internal_Finance__c == 'Approved' && newOpportunity.StageName == 'Closed Won'){
            opportunityAccount.Internally_Financed__c = true;
            DMLWrapper.doUpdate(opportunityAccount, new List<SObjectField>{Account.Internally_Financed__c});
        }
    }

    //Groundswell - Nilesh Jain : Update Payment Method Link on Account workflow changes
    public static void updatePaymentMethodLink(Opportunity newOpportunity, Opportunity oldOpportunity, Account opportunityAccount){
        if(opportunityAccount.Id != null && newOpportunity.Amount_Received__c != oldOpportunity.Amount_Received__c){
            opportunityAccount.Churn_Update_CC_Link__c = newOpportunity.StageName == 'Closed Won' ?
                    System.Label.UpdatePaymentMethodLink + opportunityAccount.Id : '';
            DMLWrapper.doUpdate(opportunityAccount, new List<SObjectField>{Account.Churn_Update_CC_Link__c});
        }
    }

    //Groundswell - Nilesh Jain : Make freight charge $0 workflow changes
    public static void makeFreightChargeszero(Opportunity newOpportunity, Opportunity oldOpportunity){
        Set<String> opportunityType = new Set<String>{'Free Trial Opportunity','Promo Opportunity','Free Trial Return,Exchange','Remorse Refund','Warranty Exchange'};
        if(((oldOpportunity == null || oldOpportunity.Id == null) || (oldOpportunity != null && oldOpportunity.Id != null && (oldOpportunity.Type != newOpportunity.Type
                || oldOpportunity.Shipping_Method__c != newOpportunity.Shipping_Method__c ||
                oldOpportunity.Shipping_Account_Type__c != newOpportunity.Shipping_Account_Type__c))) &&
                (((newOpportunity.Type == 'Revenue Opportunity')
                        && (newOpportunity.Shipping_Method__c == 'Will Call' || newOpportunity.Shipping_Account_Type__c != 'Samsara Account'))
                        || (opportunityType.contains(newOpportunity.Type)))){
            newOpportunity.Freight_Cost__c = 0;
        }
    }

    // Groundswell : Tanuj - WFlow Rule - MBO Authorized Stamping
    public static void mboAuthorizedStamping(Opportunity newOpportunity, Opportunity oldOpportunity){
        if(oldOpportunity.id != null && newOpportunity.MBO_Authorized__c == true){
            //MBO Authorized By Stamp   
            newOpportunity.MBO_Authorized_By__c =  UserInfo.getFirstName() + ' ' + UserInfo.getLastName();
            //MBO Authorized Date/Time Stamp
            newOpportunity.MBO_Authorized_Date_Time__c  = System.now(); 
        }    
    }
    
    // Groundswell : Tanuj - WFlow Rule -  Clear Push Return to Netsuite Checkbox
    // Clearing Push Return to Netsuite Checkbox after the order field has been populated
    public static void clearPushReturnToNetsuiteCheckbox(Opportunity newOpportunity, Opportunity oldOpportunity){
        Set<String> rebateTypeSet = new Set<String>{'Buyout', 'Subsidy', 'Partner', 'Referral'};
        if(oldOpportunity.id != null
        && newOpportunity.Corresponding_Netsuite_ID__c != null
        && newOpportunity.Push_Return_to_Netsuite__c == true
        && rebateTypeSet.contains(newOpportunity.Rebate_Type__c)
        ){
            //Push Return to Netsuite Clearing   
            newOpportunity.Push_Return_to_Netsuite__c = false;
        } 
    }
    
    
    // Groundswell : Tanuj - WFlow Rule -  Move Webstore Oppty to Closing
    public static void moveWebstoreOpptyToClosing(Opportunity newOpportunity, Opportunity oldOpportunity){
        if(oldOpportunity.id != null
        && newOpportunity.Small_Fleet_Opportunity__c == true
        && newOpportunity.Express_Agreement_Accepted_Date__c != null
        && newOpportunity.Amount_Received__c > 0
        && newOpportunity.Amount > 0
        && (oldOpportunity.Amount_Received__c != newOpportunity.Amount_Received__c
            || oldOpportunity.Express_Agreement_Accepted_Date__c != newOpportunity.Express_Agreement_Accepted_Date__c)
        && newOpportunity.Probability < 95
        ){
            newOpportunity.StageName = 'Closing';
        }
    }

    //Groundswell : Nilesh Jain - Clear the field values from the primary quote workflow changes
    public static void clearValueForPrimaryQuote(Opportunity newOpportunity, Opportunity oldOpportunity){
        if(oldOpportunity.CPQ_Opportunity__c != newOpportunity.CPQ_Opportunity__c && !newOpportunity.CPQ_Opportunity__c){
            newOpportunity.Approved_Discount__c = null;
            newOpportunity.Blended_Discount_CPQ__c = null;
            newOpportunity.Discount_Approval_Status_from_Quote__c = false;
            newOpportunity.Discount__c = null;
            newOpportunity.License_Term_CPQ__c = null;
            newOpportunity.Product_Approval_Status_from_Quote__c = false;
            newOpportunity.Sales_Tax_Amount__c = null;
            newOpportunity.Shipping_and_Handling_Amount__c = null;
            newOpportunity.Hardware_Sales_Tax_CPQ__c = null;
            newOpportunity.License_Sales_Tax_CPQ__c = null;    
        }
    }
    
    //Groundswell : Nilesh Jain - Wabash Referral Payout Amount  workflow changes
    public static void wabashReferralPayout(Opportunity newOpportunity, Opportunity oldOpportunity){
        if((oldOpportunity.Id == null || 
            (oldOpportunity.Id != null && (oldOpportunity.LeadSource != newOpportunity.LeadSource 
            || oldOpportunity.Referral_Partner__c != newOpportunity.Referral_Partner__c))) && 
           (newOpportunity.LeadSource == 'Partner Referral' 
           && newOpportunity.Referral_Partner__c == System.Label.Opportunity_Referral_Partner)){
            newOpportunity.Partner_Referral_Payout_Amount_V2__c = newOpportunity.Amount * -0.25;
        }
    }

    // Groundswell : Tanuj - WFlow Rule -  Deactivation Timestamp
    public static void deactivationTimestamp(Opportunity newOpportunity, Opportunity oldOpportunity){
        if(oldOpportunity.Deactivate__c != newOpportunity.Deactivate__c
        && newOpportunity.Deactivate__c == true
        && newOpportunity.Type == 'Free Trial Opportunity'
        ){
            newOpportunity.Deactivation_Date__c  = system.now();
        }
    }
    
    // Groundswell : Tanuj - WFlow Rule -  Trial Invoice Timestamp
    public static void trialInvoiceTimestamp(Opportunity newOpportunity, Opportunity oldOpportunity){
        if(oldOpportunity.Send_Invoice__c != newOpportunity.Send_Invoice__c
        && newOpportunity.Send_Invoice__c == true
        && newOpportunity.Type == 'Free Trial Opportunity'
        ){
            newOpportunity.Invoice_Date__c   = system.now();
        }
    }

    // Groundswell : Tanuj - WFlow Rule - Referral Payout Amount - Fleet
    public static void referralPayoutFleet(Opportunity newOpportunity, Opportunity oldOpportunity){

        if(newOpportunity.Referral_Partner__c != null 
        && newOpportunity.Referral_Partner__c != System.Label.Opportunity_Referral_Partner
        && newOpportunity.Referral_Partner__c != System.Label.Opportunity_Referral_Partner_Second  
        && newOpportunity.Owner_Role_Copy__c != 'Industrial' 
        && newOpportunity.Uncapped_Partner_Referral_Payout_Amount__c == false){
            //Set Referral Payout Amount - Fleet 
            if(oldOpportunity.id == null){
                newOpportunity.Partner_Referral_Payout_Amount_V2__c = 0;
            }else{
                newOpportunity.Partner_Referral_Payout_Amount_V2__c = 
                    ((-0.2*newOpportunity.ACV_List_Price__c ) > (-50000 *newOpportunity.Currency_Exchange_Rate__c)) ?
                    (-0.2*newOpportunity.ACV_List_Price__c ) :
                    (-50000 *newOpportunity.Currency_Exchange_Rate__c);
            }
        }
    }
    
    // Groundswell : Tanuj - WFlow Rule - Referral Payout Amount - Industrial ENT
    public static void referralPayoutIndustrialENT(Opportunity newOpportunity, Opportunity oldOpportunity, User ownerRec){
        if(ownerRec != null && newOpportunity.Referral_Partner__c != null 
        && newOpportunity.Referral_Partner__c != System.Label.Opportunity_Referral_Partner
        && newOpportunity.Referral_Partner__c != System.Label.Opportunity_Referral_Partner_Second  
        && ownerRec.Business_Unit__c == 'Industrial' && ownerRec.Segment__c  == 'Enterprise'
        ){
        //Set Referral Payout Amount - IND ENT
            if(oldOpportunity.id == null){
                newOpportunity.Partner_Referral_Payout_Amount_V2__c = 0;
            }else{
                newOpportunity.Partner_Referral_Payout_Amount_V2__c = 
                    (newOpportunity.List_Price__c * (-0.05*newOpportunity.Currency_Exchange_Rate__c )) > (-100000*newOpportunity.Currency_Exchange_Rate__c) ?
                    (newOpportunity.List_Price__c * (-0.05*newOpportunity.Currency_Exchange_Rate__c )) :
                    (-100000*newOpportunity.Currency_Exchange_Rate__c);
            }
        }
    }
    
    
    // Groundswell : Tanuj - WFlow Rule - Re Open Trial when End Date Exceeded
    public static void reOpenTrialEndDateExceeded(Opportunity newOpportunity, Opportunity oldOpportunity){
        if((oldOpportunity.Trial_Number_of_Days_Left__c != newOpportunity.Trial_Number_of_Days_Left__c
            || oldOpportunity.Type != newOpportunity.Type)
                && (newOpportunity.Trial_Number_of_Days_Left__c < 0 
                    && newOpportunity.Type == 'Free Trial Opportunity')
            ){
               // Re Open Trial
                newOpportunity.Trial_Status__c = 'Open';
            }
    }


    // Groundswell : Tanuj - WFlow Rule - Free Trial Return Date Update
    public static void freeTrialReturnDateUpdate(Opportunity newOpportunity, Opportunity oldOpportunity){
        if(oldOpportunity.Trial_Status__c != newOpportunity.Trial_Status__c
            && newOpportunity.Trial_Status__c == 'Return In Process'
            && newOpportunity.Type == 'Free Trial Opportunity'
            && newOpportunity.Deactivate__c == false){
               // Update Trial End Date 
                newOpportunity.Trial_Period__c  = (newOpportunity.Trial_Start_Date_new__c.daysBetween(system.today())) + 30;
            }
    }
    
    
    // Groundswell : Tanuj - WFlow Rule - Stamp Trial Completion Date
    public static void stampTrialCompletionDate(Opportunity newOpportunity, Opportunity oldOpportunity){
        if(oldOpportunity.Trial_Status__c != newOpportunity.Trial_Status__c
            && (newOpportunity.Trial_Status__c == 'Purchased' 
                || newOpportunity.Trial_Status__c == 'Returned'
                || newOpportunity.Trial_Status__c == 'Write-off')
            ){
               // Stamp Trial Completion    
                newOpportunity.Trial_Completion_Date__c = system.today();
            }
    }


    // Groundswell : Tanuj - Combined method for License Term Updat Wflows
    // WFlow Rule - License Term Update for other rebate type
    // WFlow Rule - License Term Update for Delinquent Opp
    /*public static void licenseTermUpdateForRebateTypeAndDelinquentOpp(Opportunity newOpportunity, Opportunity oldOpportunity, Opportunity oppFields){  
        if((oldOpportunity.id == null 
            ||  (oldOpportunity.id != null
                    &&(oldOpportunity.Type != newOpportunity.Type
                        || oldOpportunity.Rebate_Type__c != newOpportunity.Rebate_Type__c
                        || oldOpportunity.CloseDate != newOpportunity.CloseDate
                    )))
            && newOpportunity.Returning_Opportunity__c != null
            && newOpportunity.type == 'Rebate'){
                
                if(newOpportunity.Rebate_Type__c != 'Delinquent' 
                    && newOpportunity.Rebate_Type__c != 'Co-Term Credit'){
                        newOpportunity.License_Term__c = oldOpportunity.Id == null ? 
                            oppFields.License_Term__c : 
                        oppFields.Returning_Opportunity__r.License_Term__c;
                    }
                
                if((oppFields.License_End_Date__c != null || oppFields.Returning_Opportunity__r.License_End_Date__c != null)
                    && newOpportunity.Rebate_Type__c == 'Delinquent'){
                        newOpportunity.License_Term__c = oldOpportunity.Id == null ? 
                            ((newOpportunity.CloseDate.daysBetween(oppFields.License_End_Date__c))/30.41).setScale(2) :
                            ((newOpportunity.CloseDate.daysBetween(oppFields.Returning_Opportunity__r.License_End_Date__c))/30.41).setScale(2);
                    }
                
            }
    }*/


    // Groundswell : Tanuj - WFlow Rule - Referral Payout Amount Uncapped - Fleet
    public static void referralPayoutAmtUncappedFleet(Opportunity newOpportunity, Opportunity oldOpportunity){
       
        if(newOpportunity.Referral_Partner__c != null 
           && newOpportunity.Referral_Partner__c != System.Label.Opportunity_Referral_Partner
           && newOpportunity.Referral_Partner__c != System.Label.Opportunity_Referral_Partner_Second  
           && newOpportunity.Owner_Role_Copy__c != 'Industrial' 
           && newOpportunity.Uncapped_Partner_Referral_Payout_Amount__c == true){
               //Set Uncap Referral Payout Amount - Fleet
                newOpportunity.Partner_Referral_Payout_Amount_V2__c = oldOpportunity.id == null ?
                                                                        0:
                                                                        newOpportunity.ACV_List_Price__c * -0.2;
           }
    }
    
    
    // Groundswell : Tanuj - WFlow Rule - Stamp Responsible Party Email
    // Stamp email address of the responsible party that generated the cause for granting customer license credit
    public static void stampResponsiblePartyEmail(Opportunity newOpportunity, Opportunity oldOpportunity){
        if(newOpportunity.Rebate_Type__c == 'License Term Credit'
            && oldOpportunity.License_Credit_Subreason__c != newOpportunity.License_Credit_Subreason__c
            && newOpportunity.License_Credit_Subreason__c != null){
                Map<String,String> partyEmailByLicenseSubreason = getPartyEmailByLicencseCreditSubreason(newOpportunity);
                newOpportunity.License_Credit_Responsible_Party__c = partyEmailByLicenseSubreason.get(newOpportunity.License_Credit_Subreason__c); 
            }
    }


    // Groundswell : Tanuj - WFlow Rule - Stamp RTN Number
    public static void stampRTNNumber(Opportunity newOpportunity, Opportunity oldOpportunity){
        Id returnOpptyRecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Return Opportunity').getRecordTypeId();
        if(newOpportunity.Return_Number_Shipping__c == null
            && newOpportunity.RecordTypeId == returnOpptyRecordTypeId){
                newOpportunity.Return_Number_Shipping__c = newOpportunity.Return_Number__c;
            }
    }  


    // Function to get Map of License Credit Subreason - Email
    public static Map<String,String> getPartyEmailByLicencseCreditSubreason(Opportunity newOpportunity){
        Map<String,String> partyEmailByLicenseSubreason = new Map<String,String>();
        /*partyEmailByLicenseSubreason.put('VG - Compliance fine from DOT due to product failure',System.Label.Email_vg_concession);
        partyEmailByLicenseSubreason.put('VG - Time on site page does not update after manual edit',System.Label.Email_vg_concession);
        partyEmailByLicenseSubreason.put('CM - Cannot retrieve video',System.Label.Email_ingo_wiegand);
        partyEmailByLicenseSubreason.put('CM - Accident not recorded',System.Label.Email_ingo_wiegand);
        partyEmailByLicenseSubreason.put('CM - Audio not recorded',System.Label.Email_ingo_wiegand);
        partyEmailByLicenseSubreason.put('CM - Not upgrading to correct firmware',System.Label.Email_ingo_wiegand);
        partyEmailByLicenseSubreason.put('AG - Not responsive to pings',System.Label.Email_neel_sheth);
        partyEmailByLicenseSubreason.put('AG - Device or cable failure required replacement',System.Label.Email_neel_sheth);
        partyEmailByLicenseSubreason.put('All - Significant technical issue for >1 month',System.Label.Email_joshua_lamarche);
        partyEmailByLicenseSubreason.put('Poor customer support experience',System.Label.Email_joshua_lamarche);
        partyEmailByLicenseSubreason.put('Delayed support ticket resolution - 4+ material technical tickets in 60 days',System.Label.Email_joshua_lamarche);
        partyEmailByLicenseSubreason.put('Ops - Shipping Delays',System.Label.Email_cody_dicara);
        partyEmailByLicenseSubreason.put('Sales - Does not support primary use case',newOpportunity.Return_Oppty_Owner_Email__c);
        partyEmailByLicenseSubreason.put('Sales - Non-referenceable',newOpportunity.Return_Oppty_Owner_Email__c);
        partyEmailByLicenseSubreason.put('Sales - Unable to use products',newOpportunity.Return_Oppty_Owner_Email__c);*/
        
        // GTMS - 4353 CS Concession Email - Anil Bogadi 
        partyEmailByLicenseSubreason.put('VG - Compliance fine from DOT due to product failure',System.Label.Email_vg_concession);
        partyEmailByLicenseSubreason.put('VG - Time on site page does not update after manual edit',System.Label.Email_vg_concession);
        partyEmailByLicenseSubreason.put('CM - Cannot retrieve video',System.Label.Email_ingo_wiegand);
        partyEmailByLicenseSubreason.put('CM - Accident not recorded',System.Label.Email_ingo_wiegand);
        partyEmailByLicenseSubreason.put('CM - Audio not recorded',System.Label.Email_ingo_wiegand);
        partyEmailByLicenseSubreason.put('CM - Not upgrading to correct firmware',System.Label.Email_ingo_wiegand);
        partyEmailByLicenseSubreason.put('AG - Not responsive to pings',System.Label.Email_kevin_omwega);
        partyEmailByLicenseSubreason.put('AG - Device or cable failure required replacement',System.Label.Email_neel_sheth);
        partyEmailByLicenseSubreason.put('All - Significant technical issue for >1 month',System.Label.Email_drago);
        partyEmailByLicenseSubreason.put('Poor customer support experience',System.Label.Email_drago);
        partyEmailByLicenseSubreason.put('Delayed support ticket resolution - 4+ material technical tickets in 60 days',System.Label.Email_drago);
        partyEmailByLicenseSubreason.put('Ops - Shipping Delays',System.Label.Email_cody_dicara);
        partyEmailByLicenseSubreason.put('Sales - Does not support primary use case',newOpportunity.Return_Oppty_Owner_Email__c);
        partyEmailByLicenseSubreason.put('Sales - Non-referenceable',newOpportunity.Return_Oppty_Owner_Email__c);
        partyEmailByLicenseSubreason.put('Sales - Unable to use products',newOpportunity.Return_Oppty_Owner_Email__c);
        return partyEmailByLicenseSubreason;
    }
    //GTMS-5041: Anil Bogadi 
      public static void updateOpportunitySegment(Opportunity newOpportunity, Opportunity oldOpportunity){
        if(newOpportunity.Owner_Role_Copy__c !=null && newOpportunity.Owner_Role_Copy__c.contains('Partner')){
            newOpportunity.Configuration_Segment__c = 'Non Express';    
        }     
    }

    //GTMS - 6244 : Flavio - WFlow Rule - Renewal Credit
    public static void renewalCredit(Opportunity newOpportunity, Opportunity oldOpportunity){
        if (renewalCreditCondition(newOpportunity) && !(renewalCreditCondition(oldOpportunity))){
            newOpportunity.Renewal_Credit_Amount__c = Math.max(newOpportunity.Amount / newOpportunity.License_Term__c - 1,0);
        }
    }

    private static Boolean renewalCreditCondition(Opportunity o){
        if (o.Amount > 0 && o.License_Term__c > 0){
            return ((o.Configuration_Segment__c == 'Express' && o.Renewal_Credit_Amount__c >= (o.Amount / o.License_Term__c))
            ||  (o.Selected_Payment_Type__c == 'Upfront Payments' && o.Renewal_Credit_Amount__c >= o.Amount)
            ||  (o.Selected_Payment_Type__c == 'Direct Annual' && o.Renewal_Credit_Amount__c >= (Math.min(
                    (o.Amount / (o.License_Term__c * 12)),
                     o.Amount
                )))
            ||  (o.Selected_Payment_Type__c == 'Direct Monthly' && o.Renewal_Credit_Amount__c >= o.Amount)
            );
        }
        return false;
    }
    
    //GTMS - 6244 : Sweta - WFlow Rule - Update Push to Netsuite Counter
    public static void updatePushToNetsuiteCounter (Opportunity newOpportunity, Opportunity oldOpportunity){
        if(((newOpportunity.Type == 'Revenue Opportunity')||(newOpportunity.Type == 'Promo Opportunity')) 
            && (oldOpportunity.Push_to_Mulesoft__c == false) 
            && (newOpportunity.Push_to_Mulesoft__c == true))
        {
            newOpportunity.Push_to_Netsuite_Counter__c += 1;
        }

    }

    //GTMS - 6244 : Flavio - WFlow Rule - License Term Update for Delinquent Opp and License Term Update for other rebate type  
    public static void licenseTermUpdateForOtherRebateTypeAndDelinquentOpp(Opportunity newOpportunity, Opportunity oppFields){
        Boolean isRebate          = (newOpportunity.Type == 'Rebate');
        Boolean isDelinquent      = (newOpportunity.Rebate_Type__c == 'Delinquent');
        Boolean isCoCredit        = (newOpportunity.Rebate_Type__c == 'Co-Term Credit');
        Boolean isWithinCloseDate = (newOpportunity.CloseDate > Date.newInstance(2019,12,12));

        if (isRebate && isWithinCloseDate){
            if (!isDelinquent && !isCoCredit && oppFields.Returning_Opportunity__r != null){
               newOpportunity.License_Term__c = oppFields.Returning_Opportunity__r.License_Term__c; //oppfields
            }else if (isDelinquent && oppFields.Returning_Opportunity__r.License_End_Date__c != null){
                newOpportunity.License_Term__c = Math.round((oppFields.CloseDate.daysBetween(oppFields.Returning_Opportunity__r.License_End_Date__c))/30.41); ////oppfields
            }
        }
    }
    
    //GTMS - 6244 : Sweta - WFlow Rule - Finance Segment Stamp
    public static void financeSegmentStamp(Opportunity newOpportunity, Opportunity oldOpportunity){
        if(newOpportunity.StageName != oldOpportunity.StageName && (!newOpportunity.IsClosed || newOpportunity.Finance_Segment_Stamp__c == null)){
            if(newOpportunity.CloseDate < date.newInstance(2019,4,12)){
                newOpportunity.Finance_Segment_Stamp__c = newOpportunity.Segment__c; // This field is marked as Don't use in Opportunity Object Field name - Segment Price Book(Segment__c)
            }else{
                if(newOpportunity.Finance_Segment__c == 'Other' || newOpportunity.Finance_Segment__c == 'ADR' || newOpportunity.Finance_Segment__c == null ){
                    newOpportunity.Finance_Segment_Stamp__c = 'SMB';
                }else{
                    newOpportunity.Finance_Segment_Stamp__c = newOpportunity.Finance_Segment__c;
                }
            }
        }
    }
  
    //GTMS - 6244 : Sweta - WFlow Rule - Set Price Book Name
    public static void setPriceBookName(Opportunity newOpportunity, Opportunity oldOpportunity, Opportunity oppFields){
        if((oldOpportunity.Id == null && newOpportunity.Pricebook2Id != null)
           || (oldOpportunity.Id != null && oldOpportunity.Pricebook2Id != newOpportunity.Pricebook2Id)
           || newOpportunity.Price_Book_Name__c !=oppFields.Pricebook2.Name
        ){
            newOpportunity.Price_Book_Name__c = (oppFields.Pricebook2 == null ? Label.Current_Active_Pricebook_Name : oppFields.Pricebook2.Name);
        }
    }
    
    //GTMS - 6244 : Sweta - WFlow Rule - Match Blended to Approved Discretionary Discount
    public static void matchBlendedToApprovedDiscretionaryDiscount(Opportunity newOpportunity, Opportunity oldOpportunity){
        if((oldOpportunity.Discount_Approval_Status__c != newOpportunity.Discount_Approval_Status__c) && newOpportunity.Discount_Approval_Status__c == 'Approved'){
            newOpportunity.Approved_Discount__c = newOpportunity.Blended_Discount__c + (0.1);
        }
    }
    
    //GTMS - 6244 : Sweta - WFlow Rule - Add Default Expiring Discount Date
    public static void addDefaultExpiringDiscountDate(Opportunity newOpportunity, Opportunity oldOpportunity, User ownerRec){
        if(oldOpportunity.Discount_Approval_Status__c != newOpportunity.Discount_Approval_Status__c 
           && newOpportunity.Discount_Approval_Status__c == 'Approved'
           && newOpportunity.Checkout_Discount_Expiration_Date_Time__c == null
           && ownerRec.Level__c == 'AE 1'
           && newOpportunity.CreatedDate > Datetime.newInstance(2018,09,12,0,0,0)
        ){
            newOpportunity.Checkout_Discount_Expiration_Date_Time__c = system.now() +5 ;
        }
    }
    
   //GTMS - 6244 : Sweta - WFlow Rule - Opportunity to Account rollup workflow
    public static void opportunityToAccountRollupWorkflow(Opportunity newOpportunity, Opportunity oldOpportunity){
        if(oldOpportunity.Id == null 
          || oldOpportunity.Amount != newOpportunity.Amount
          || oldOpportunity.ExpectedRevenue != newOpportunity.ExpectedRevenue
          || oldOpportunity.License_Term_Credit_Amount_Custom__c != newOpportunity.License_Term_Credit_Amount_Custom__c)
        { 
            newOpportunity.License_Credit_Amount_Number__c = newOpportunity.License_Term_Credit_Amount_Custom__c;
            newOpportunity.Amount_Number__c = newOpportunity.Amount;
            newOpportunity.Expected_Revenue_Number__c = newOpportunity.ExpectedRevenue;  
        } 
    }
   
    //Deprecating AccountFields: GTMS-12857-July6
    //GTMS - 6244 : Flavio - WFlow Rule - Update Product Discounts on Account
    /*public static void updateProductDiscountsOnAccount(Opportunity newOpportunity,Account opportunityAccount){
        Boolean hasAnyLicenseCount = (
            newOpportunity.VG_License_Count__c > 0
        ||  newOpportunity.CM1_License_Count__c > 0
        ||  newOpportunity.CM2_License_Count__c > 0
        ||  newOpportunity.AG4_License_Count__c > 0
        ||  newOpportunity.AG2_License_Count__c > 0
        );

        if(opportunityAccount.Id != null
        && newOpportunity.Type == 'Revenue Opportunity'
        && newOpportunity.StageName == 'Closed Won'
        && newOpportunity.Configuration_Segment__c == 'Express'
        && hasAnyLicenseCount
        ){
            Decimal value = (newOpportunity.Express_Selected_Discount__c != null ? newOpportunity.Express_Selected_Discount__c : 0);
            List<Schema.SObjectField> fieldList = new List<Schema.SObjectField>();

            if(newOpportunity.VG_License_Count__c > 0){
               opportunityAccount.VG_Selected_Discount__c = value;
               fieldList.add(Account.VG_Selected_Discount__c);
            }

            if(newOpportunity.CM1_License_Count__c > 0){
               opportunityAccount.CM1_Selected_Discount__c = value;
               fieldList.add(Account.CM1_Selected_Discount__c);
            }

            if(newOpportunity.CM2_License_Count__c > 0){
               opportunityAccount.CM2_Selected_Discount__c = value;
               fieldList.add(Account.CM2_Selected_Discount__c);
            }

            if(newOpportunity.AG4_License_Count__c > 0){
               opportunityAccount.AG4_Selected_Discount__c = value;
               fieldList.add(Account.AG4_Selected_Discount__c);
            }

            if (!fieldList.isEmpty()){
                DMLWrapper.doUpdate(opportunityAccount, fieldList);
            }
        }
    }*/
    
    // GTMS - 6244 : Flavio - WFlow Rule - Update Shipping Cost

    public static void updateShippingCost(Opportunity newOpportunity){
        if (updateShippingCostEntryCriteria(newOpportunity, false)){

            String method = newOpportunity.Shipping_Method__c;
            Decimal multiplier = 0;
            Decimal divider = 22000;
            Decimal totalProductDimensions = (newOpportunity.Total_Product_Dimensions__c != null ? newOpportunity.Total_Product_Dimensions__c : 0);
            //GTMS-8169
            if (newOpportunity.Total_Weight_oz__c < 6500 && (newOpportunity.Shipping_and_Handling_Manual__c == null || newOpportunity.Shipping_and_Handling_Manual__c == 0)){

                switch on (newOpportunity.Shipping_Zone__c) {
                    when 'United Kingdom' {
                        if (method == 'UK Standard') multiplier = 20;
                        if (method == 'UK Express')  multiplier = 35;
                    }
                    when 'Ireland' {
                        if (method == 'UK Standard') multiplier = 45;
                        if (method == 'UK Express')  multiplier = 60;
                    }
                    when 'Germany', 'Netherlands', 'Belgium', 'Austria' {
                        if (method == 'UK Standard') multiplier = 20;
                        if (method == 'UK Express' && newOpportunity.Shipping_Zone__c != 'Austria') multiplier = 75;
                    }
                    when 'West' { //GTMS-10675
                        if (method == 'Ground')       multiplier = 30;
                        if (method == '3 Day Select') multiplier = 54;
                        if (method == 'Next Day Air') multiplier = 236;
                    }
                    when 'Central' {
                        if (method == 'Ground')       multiplier = 35;
                        if (method == '3 Day Select') multiplier = 102;
                        if (method == 'Next Day Air') multiplier = 299;
                    }
                    when 'East' {
                        if (method == 'Ground')       multiplier = 40;
                        if (method == '3 Day Select') multiplier = 114;
                        if (method == 'Next Day Air') multiplier = 306;
                    }
                    when 'Mexico' { //GTMS-8209
                        if (method == 'MX Standard')  multiplier = 150;
                        if (method == 'MX Express') multiplier = 200;
                    }
                }
            }
            
            if (multiplier == 0){
                newOpportunity.Freight_Cost__c = 99999.99;
            }else{
                newOpportunity.Freight_Cost__c = (Math.ceil(totalProductDimensions / divider) * multiplier);
            }
        }
    }

    //GTMS - 6244 : Sweta - WFlow Rule - Update Shipping Cost Canada & France
    public static void updateShippingCostCanadaAndFrance(Opportunity newOpportunity){
        if (updateShippingCostEntryCriteria(newOpportunity, true)){
            String method = newOpportunity.Shipping_Method__c;
            Decimal multiplier = 0;
            Decimal divider = 22000;
            Decimal totalProductDimensions = (newOpportunity.Total_Product_Dimensions__c != null ? newOpportunity.Total_Product_Dimensions__c : 0);
            //GTMS-8169
            if (newOpportunity.Total_Weight_oz__c < 6500 && (newOpportunity.Shipping_and_Handling_Manual__c == null || newOpportunity.Shipping_and_Handling_Manual__c == 0)){
                switch on (newOpportunity.Shipping_Zone__c) {
                    when 'Mid-east' {
                        if (method == 'Ground') multiplier = 88;
                    }
                    when 'West' {
                        if (method == 'Ground') multiplier = 72;
                    }
                }
            }
            
            // Not else if due to potential miscalculations.
            //GTMS-8619
            if (multiplier == 0 && newOpportunity.Total_Weight_oz__c < 6500 && (newOpportunity.Shipping_and_Handling_Manual__c == null || newOpportunity.Shipping_and_Handling_Manual__c == 0)){

                switch on (newOpportunity.Shipping_Zone__c) {
                    when 'Spain' {
                        if (method == 'UK Standard') multiplier = 25;
                    }
                    when 'France' {
                        if (method == 'UK Standard') multiplier = 25;
                        if (method == 'UK Express')  multiplier = 55;
                    }
                    when 'Mid-east' {
                        if (method == '3 Day Select') multiplier = 153;
                        if (method == 'Worldwide Expedited'){
                            multiplier = 75;
                            divider = 11000;
                        }
                    }
                    when 'Territory' {
                        if (method == 'Ground')       multiplier = 92;
                        if (method == '3 Day Select') multiplier = 153;
                        if (method == 'Worldwide Expedited'){
                            multiplier = 82;
                            divider = 11000;
                        }
                    }
                    when 'East' {
                        if (method == 'Ground')       multiplier = 45;
                        if (method == '3 Day Select') multiplier = 130;
                        if (method == 'Worldwide Expedited'){
                            multiplier = 82;
                            divider = 11000;
                        }
                    }
                    when 'West' {
                        if (method == '3 Day Select') multiplier = 130;
                        if (method == 'Worldwide Expedited'){
                            multiplier = 52;
                            divider = 11000;
                        }
                    }
                    when 'Mid-west' {
                        if (method == 'Ground')       multiplier = 73;
                        if (method == '3 Day Select') multiplier = 130;
                        if (method == 'Worldwide Expedited'){
                            multiplier = 60;
                            divider = 11000;
                        }
                    }
                }
            }

            if (multiplier == 0){
                newOpportunity.Freight_Cost__c = 99999.99;
            }else{
                newOpportunity.Freight_Cost__c = (Math.ceil(totalProductDimensions / divider) * multiplier);
            }
        }
    }

    //GTMS - 6244 : Flavio - WFlow Rule - Update Shipping Cost (only entry criteria)
    private static Boolean updateShippingCostEntryCriteria(Opportunity o, Boolean checkForCanadaOrFrance){
        Boolean entryCriteria = (
            (o.Type == 'Revenue Opportunity' || o.Type == 'Revenue Opportunity - Bill Only')
        &&  (o.Shipping_Method__c != 'Will Call' && String.isNotBlank(o.Shipping_Method__c))
        &&  !((new Set<String>{'Cust/Partner Account - FedEx','Cust/Partner Account - UPS','Cust/Partner Account - DHL'}).contains(o.Shipping_Account_Type__c))
        &&  (o.Total_Weight_oz__c != null)
        &&  (o.Probability < 99)
        &&  (o.Shipping_Zone__c != null)
        );

        Boolean isCanadaOrFrance = (o.Shipping_Country__c == 'Canada' || o.Shipping_Country__c == 'France');

        return (entryCriteria && (checkForCanadaOrFrance ? isCanadaOrFrance : !isCanadaOrFrance));
    }

    //GTMS - 6244 : Flavio - WFlow Rule - Closing Alert for Rep's Manager
    public static void closingAlertforRepsManager(Opportunity newOpportunity, Opportunity oldOpportunity, Opportunity oppFields, User ownerRec){
        if(closingAlertForRepsManagerCondition(newOpportunity)
        && !closingAlertForRepsManagerCondition(oldOpportunity)
        && UserInfo.getUserEmail() != 'phillip.front@samsara.com'){
            if(newOpportunity.Type =='Revenue Opportunity' || newOpportunity.Type == 'Free Trial Opportunity' || newOpportunity.Type == 'Promo Opportunity'){
                newOpportunity.Owner_Manager_Email_Copy__c = ownerRec.Manager.Email;
            }else{
                if(newOpportunity.Type =='Remorse Refund' || newOpportunity.Type =='Rebate'){
                    newOpportunity.Owner_Manager_Email_Copy__c = oppFields.Returning_Opportunity__r.Owner_Manager_Email_Copy__c;
                }else{
                    newOpportunity.Owner_Manager_Email_Copy__c = '';
                }
            }
        }
    }

    //GTMS - 6244 : Flavio - WFlow Rule Condition
    private static Boolean closingAlertForRepsManagerCondition(Opportunity opp){
        return (
            (opp.StageName == 'Closing' || opp.StageName == 'Refunded - Closed' || opp.StageName == 'Orders Processing')
         && opp.Owner_Manager_Email_Copy__c != null
        );
    }

    //GTMS - 6244 : Flavio - WFlow Rule - Copy Owner Role 
    public static void copyOwnerRole(Opportunity newOpportunity, Opportunity oldOpportunity, Opportunity oppFields, User ownerRec){
        Set<String> stageConditionSet = new Set<String>{'Incubate','Qualified','Trial','Proposal','Decision','Purchase','Closing',
            'Return Created','Return Initiated','Return Label Sent','Products Processing','Finance Processing','Closed Won','Refunded - Closed'};
        if(oldOpportunity == null || oldOpportunity.OwnerId != newOpportunity.OwnerId || oldOpportunity.StageName != newOpportunity.StageName){
            if ((stageConditionSet.contains(newOpportunity.StageName) ||  (String.isBlank(newOpportunity.Owner_Role_Copy__c)))
                && (newOpportunity.Type != 'Remorse Refund'
                    && (newOpportunity.Type != 'Rebate' || newOpportunity.Rebate_Type__c != 'Delinquent')) //GTMS-29333: Shifted Rebate and Remorse Refund owner role copy logic to ReturnOwnerCopyDataUtility
                && !(newOpportunity.Rebate_Type__c == 'Partner Referral' || newOpportunity.Rebate_Type__c == 'Co-Term Credit'))
            {
                newOpportunity.Owner_Role_Copy__c = ownerRec.UserRole.Name;
            }
        }
    }
}