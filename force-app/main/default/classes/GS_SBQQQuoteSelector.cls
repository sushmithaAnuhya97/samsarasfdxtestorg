/**
* Created By : Groundswell - Suman Kundu
* @Date September 10, 2021
* Feb-17-2023 Rajesh GTMS-11327 Added AutoRenewal Field  to query
* Feb-23-2023 Rajesh GTMS-10935 Added Adjusted RenewalOpp EndDate to the query
* May-23-2023 Rajesh GTMS-13193 Opp Renewal to the query
* June-28-2023 Rajesh GTMS-13687 Added Latest Active COntract to Query
* March-04-2024 Vijaychandra GTMS-19085 Added 3 more fields to Query in getQuotesAndQuoteLinesById method.
* May-20-2024 Vijaychandra (GTMS-20818): Added 1 field to Query in getQuotesAndQuoteLinesById method
* @description : This class will be responsible for handling all Quote queries / SOQLs
* SFA-10
*
**/
public inherited sharing class GS_SBQQQuoteSelector extends GS_SObjectBaseSelector{
    public GS_SBQQQuoteSelector(Boolean checkFatalError){
        super(checkFatalError);
    }

    public GS_SBQQQuoteSelector checkFatalError(){
        return (GS_SBQQQuoteSelector) super.validateFatalError();
    }

    /**
    * Return the Quote by Id with the required fields
    * @param Set<id> quoteIds
    */

    public Map<Id, SBQQ__Quote__c> getAllCustomFieldsQuotesById(Set<Id> quoteIds){
        if (quoteIds.size() == 0) {
            return null;
        }
        Set<Id> recordIds = quoteIds;
        String query = 'SELECT Id';
        Map<String,Schema.SObjectField> mfields = SBQQ__Quote__c.SObjectType.getDescribe().fields.getMap();
        for (SObjectField field : mfields.values()) {
            Schema.DescribeFieldResult fieldDescribe = field.getDescribe();
            if (fieldDescribe.isCustom()) {
                query += ',' + fieldDescribe.getName();
            }
        }
        query += ' FROM SBQQ__Quote__c WHERE Id IN :recordIds';
        System.debug(LoggingLevel.INFO, 'SBQQ__Quote__c Query: '+query);
        return new Map<Id, SBQQ__Quote__c>((List<SBQQ__Quote__c>)Database.query(query));
    }

    /**
    * Return the Quotes by provided Ids
    * @param Set<id> quoteIds
    */
    public Map<Id, SBQQ__Quote__c> getQuotesById(Set<Id> quoteIds) {
        return new Map<Id, SBQQ__Quote__c>([
        SELECT Id, Approved_Discount__c, ApprovedProductsCount__c, Selected_Payment_Type__c,
        SBQQ__Source__c, SBQQ__Source__r.Selected_Payment_Type__c,SBQQ__Opportunity2__c,
        SBQQ__Opportunity2__r.CloseDate, SBQQ__Opportunity2__r.Name,SBQQ__Partner__c,SBQQ__Partner__r.Partner_Discount__c,
        SBQQ__Opportunity2__r.Renewable_ACV__c,SBQQ__Account__r.Customer_ARR__c,
        SBQQ__Opportunity2__r.Finance_Partner__c,SBQQ__Opportunity2__r.Payment_Type__c,
        SBQQ__Opportunity2__r.Contract.Auto_Renewal__c,SBQQ__Account__r.Renewal_AE__c,Renewal__c,SBQQ__MasterEvergreenContract__c,
        SBQQ__Account__c,SBQQ__Account__r.Partner_Discount__c, Co_Term_Contract__c, Co_Term_Contract__r.EndDate, SBQQ__MasterContract__r.EndDate,
        SBQQ__Opportunity2__r.SBQQ__AmendedContract__r.EndDate,SBQQ__Opportunity2__r.SBQQ__RenewedContract__r.P_P_Renewals__c, 
        
  SBQQ__Opportunity2__r.Type, SBQQ__Opportunity2__r.StageName, SBQQ__Account__r.Approved_Payment_Type__c,SBQQ__Opportunity2__r.Finance_Segment_Stamp__c,SBQQ__Opportunity2__r.Segment_Sales_Role__c,
  CurrencyIsoCode,Competitor_Buyout_Amount__c,Total_Estimated_Installation_Costs__c, Is_Installation_Reimbursable__c,Number_of_months_of_Free_service__c,Future_Free_Months_Amount__c,Total_License_Price__c,Bypass_Multiline__c,ApprovalStatus__c,
        SBQQ__Opportunity2__r.Buyout_Opportunity__c,SBQQ__LastCalculatedOn__c,SBQQ__Opportunity2__r.Probability,SBQQ__Opportunity2__r.Subsidy_Opportunity__c,License_Term__c,SBQQ__PriceBook__c,SBQQ__NetAmount__c,Net_Amount_Rebate__c,X3rd_PF_Interest_Subsidy__c,SBQQ__Opportunity2__r.Subsidy_Opportunity__r.Rebate_Type__c ,
        Configuration_Segment__c,Estimated_Annual_Payment__c,Estimated_Upfront_Amount__c,SBQQ__SubscriptionTerm__c, New_DC_architecture__c, SBQQ__Opportunity2__r.Payment_Terms__c, SBQQ__Opportunity2__r.Payment_Method__c, SBQQ__Opportunity2__r.Amount_Received__c, SBQQ__Opportunity2__r.Owner_Role_Copy__c, SBQQ__Opportunity2__r.First_Purchase__c,
            SBQQ__Status__c,OTD_Amt__c, Future_Free_Service_Type__c, Buyout_Incumbent_Provider__c
        FROM SBQQ__Quote__c
        WHERE ID IN :quoteIds
        ]);
    }

    /**
    * @param ids SBQQ__Opportunity2__c ids set to query Quote based upon
    *@description Used from GS_AsyncSBQQQuoteFromOpportunityService and GS_SBQQQuoteUpdationService
    * @return List of SBQQ__Quote__c
    */
    public List<SBQQ__Quote__c> getQuoteFromOpportunityIds(Set<Id> ids){
        return [SELECT Id,
        SBQQ__Opportunity2__c,
        SBQQ__StartDate__c,
        SBQQ__MasterContract__c
        FROM SBQQ__Quote__c
        WHERE SBQQ__Opportunity2__c  IN : ids];
    }

    /**
    * @description : Retrieves all base fields within getQuotesById plus all QLs associated with them
    * @param Set<Id> quoteIds
    */
    //10/23/23 Vijaychandra (GTMS-16283): Added opportunity fields in the query and Product code field in Quote Line subquery
    //07/31/24 GTMS-22224
    public Map<Id, SBQQ__Quote__c> getQuotesAndQuoteLinesById(Set<Id> quoteIds){
        /*GTMS-22183 ---> CreatedBy Abu 07/10/2024*/
        String appId = Label.FT_Exception_RuleId;
        List<String> strLstId = new List<String>();
        if(String.isNotBlank(appId))
            strLstId = appId.split(',');
        /*GTMS-22183 ---> CreatedBy Abu 07/10/2024*/
        return new Map<Id, SBQQ__Quote__c>([
        SELECT Id,ApprovalStatus__c, Approved_Discount__c,Close_Date__c, ApprovedProductsCount__c, Selected_Payment_Type__c,SBQQ__Opportunity2__r.SBQQ__RenewedContract__c,OwnerId ,Owner.ProfileId,Finance_Partner_Account__c,Finance_Partner_Account__r.Is_Finance_Partner_Active__c,
        SBQQ__Source__c, SBQQ__Source__r.Selected_Payment_Type__c,SBQQ__Opportunity2__c, SBQQ__Opportunity2__r.isClosed,SBQQ__Primary__c, SBQQ__RenewalUpliftRate__c,SBQQ__Opportunity2__r.SBQQ__RenewedContract__r.SBQQ__RenewalUpliftRate__c,
        SBQQ__Opportunity2__r.CloseDate, SBQQ__Opportunity2__r.Name,SBQQ__Partner__c,SBQQ__Partner__r.Partner_Discount__c,/*(GTMS-26363)*/SBQQ__Opportunity2__r.SBQQ__RenewedContract__r.Webstore_Renewal_Quote_Step__c,
        SBQQ__Opportunity2__r.Renewable_ACV__c,SBQQ__Account__r.Customer_ARR__c, SBQQ__Uncalculated__c, Renewal_Data_Error_Category__c, SBQQ__Opportunity2__r.Account.Segment__c, 
        SBQQ__Opportunity2__r.Finance_Partner__c,SBQQ__Opportunity2__r.Payment_Type__c, License_Term__c, Shipping_Address_NEW__c, SBQQ__Opportunity2__r.Account.Approved_Payment_Type__c,  
        SBQQ__Opportunity2__r.Contract.Auto_Renewal__c,SBQQ__Account__r.Renewal_AE__c,Renewal__c,SBQQ__MasterEvergreenContract__c, SBQQ__Opportunity2__r.Payment_Type_Opportunity_only_Exception__c, 
        SBQQ__Opportunity2__r.Custom_Schedule__c,SBQQ__Opportunity2__r.Type,SBQQ__Opportunity2__r.Owner_Role_Copy__c,SBQQ__Opportunity2__r.Owner_Manager_Role_Copy__c,SBQQ__Opportunity2__r.Custom_Billing__c,SBQQ__Opportunity2__r.Custom_Billing_Schedule_Details__c,
        SBQQ__Opportunity2__r.Segment__c, SBQQ__Opportunity2__r.Finance_Segment__c,SBQQ__Opportunity2__r.Is_Webstore_Upsell_Opportunity__c,SBQQ__Opportunity2__r.SBQQ__Renewal__c,SBQQ__Opportunity2__r.Renewal__c,
        SBQQ__Account__c,SBQQ__Account__r.Partner_Discount__c, SBQQ__Opportunity2__r.SBQQ__AmendedContract__c, SBQQ__Opportunity2__r.CreatedDate,Co_Term_Contract__r.EndDate,
            SBQQ__Opportunity2__r.SBQQ__RenewedContract__r.Auto_Renewal__c,SBQQ__Opportunity2__r.SBQQ__RenewedContract__r.Adjusted_RenewalOpp_EndDate__c,SBQQ__Account__r.Latest_Active_Contract__c,SBQQ__Account__r.Approved_Payment_Type__c, /*GTMS-25155*/SBQQ__Account__r.Payment_Terms__c,
        /*(GTMS-16283)*/SBQQ__Opportunity2__r.Selected_Payment_Type__c,SBQQ__Opportunity2__r.Buyout_Opportunity__c,SBQQ__Opportunity2__r.Subsidy_Opportunity__c,SBQQ__Opportunity2__r.CurrencyIsoCode,
        SBQQ__Opportunity2__r.VAT_Validation_Status__c,SBQQ__Opportunity2__r.Owner_Segment__c,SBQQ__Opportunity2__r.StageName,SBQQ__Opportunity2__r.Blended_Discount__c,SBQQ__Account__r.Skip_Silent_Auto_Renewal__c,SBQQ__Opportunity2__r.SBQQ__RenewedContract__r.Skip_Silent_Auto_Renewal__c,
        /*GTMS-17941*/SBQQ__Opportunity2__r.Small_Fleet_Opportunity__c,/*GTMS-17941*//*GTMS-19085*/SBQQ__Opportunity2__r.OwnerId,/*GTMS-21781 */SBQQ__Opportunity2__r.Owner.ProfileId,SBQQ__Opportunity2__r.Owner.isActive,Owner.IsActive /*GTMS-21781 */, SBQQ__Opportunity2__r.Owner_Director_Name_Copy__c,SBQQ__Opportunity2__r.Owner_Manager_Name_Copy__c,/*GTMS-19085*/
        SBQQ__Opportunity2__r.Payment_Terms__c, SBQQ__Opportunity2__r.Reseller__c,SBQQ__Opportunity2__r.Initial_Payment_Terms__c,SBQQ__NetAmount__c,Associated_Opportunity_Probability__c,Free_Trial__c,SBQQ__Account__r.Latest_Active_Contract__r.EndDate, SBQQ__Opportunity2__r.SBQQ__RenewedContract__r.EndDate,
        /*GTMS-22224*/SBQQ__Opportunity2__r.ACV_Bookings_SOT__c,SBQQ__Opportunity2__r.SBQQ__RenewedContract__r.Contract_Renewable_ACV__c,SBQQ__Opportunity2__r.SBQQ__RenewedContract__r.Deactivated__c,/*GTMS-22224*/
        /*GTMS-20818*/SBQQ__Opportunity2__r.First_Purchase__c,/*GTMS-20818*/SBQQ__Opportunity2__r.SBQQ__RenewedContract__r.Weighted_Average_Start_Date__c,SBQQ__Opportunity2__r.SBQQ__RenewedContract__r.SBQQ__Opportunity__r.Shipping_Address_NEW__c,SBQQ__Opportunity2__r.Shipping_Address_NEW__c,
        SBQQ__Opportunity2__r.SBQQ__RenewedContract__r.SBQQ__Opportunity__r.Selected_Payment_Type__c,Tax_Calculation_Status__c,SBQQ__Opportunity2__r.License_Term__c,SBQQ__Opportunity2__r.Amount,Blended_Discount__c,Process_Eligibility__c,Recalculate_Quote__c,SBQQ__Opportunity2__r.Processing_Type__c,SBQQ__Opportunity2__r.Finance_Segment_Stamp__c,SBQQ__Opportunity2__r.Segment_Sales_Role__c, SBQQ__Opportunity2__r.Payment_Method__c, SBQQ__Opportunity2__r.Amount_Received__c, 
  SBQQ__Opportunity2__r.Probability, SBQQ__Opportunity2__r.Returning_Opportunity__r.Type,SBQQ__Opportunity2__r.AccountId,
        Buyout_Amount__c,SBQQ__Status__c,SBQQ__LineItemCount__c,First_Months_Payment__c,First_Quarter_Payment__c,First_Annual_Payment__c,First_Semi_Annual_Payment__c, Is_First_Invoice_Amount_Negative__c,Competitor_Buyout_Amount__c, Total_Estimated_Installation_Costs__c, override__c,
        Is_Installation_Reimbursable__c,SBQQ__PricebookId__c,CurrencyIsoCode,Number_of_months_of_Free_service__c, Future_Free_Months_Amount__c,Total_License_Price__c,Bypass_Multiline__c,SBQQ__Opportunity2__r.Buyout_Amount__c,SBQQ__Opportunity2__r.Subsidy_Amount__c,SBQQ__PriceBook__c,X3rd_PF_Interest_Subsidy__c,Free_service_months_requested__c,SBQQ__SubscriptionTerm__c,Subsidy_Amount__c,SBQQ__Opportunity2__r.Deal_Components__c,
        /*GTMS- 27600SBQQ__Opportunity2__r.Returning_Opportunity__c, SBQQ__Opportunity2__r.Returning_Opportunity__r.CloseDate,SBQQ__Opportunity2__r.Returning_Opportunity__r.SBQQ__PrimaryQuote__c,SBQQ__Opportunity2__r.Returning_Opportunity__r.SBQQ__PrimaryQuote__r.SBQQ__SubscriptionTerm__c, */ 

        SBQQ__Opportunity2__r.Sub_Type__c, SBQQ__Opportunity2__r.Billing_360_Transaction__c,SBQQ__Opportunity2__r.Purchase_Type__c, SBQQ__StartDate__c, SBQQ__EndDate__c, SBQQ__Account__r.Billing_Anniversary_Date__c, Billing_Ann_Date__c, SBQQ__MasterContract__r.SBQQ__Opportunity__r.Selected_Payment_Type__c, Associated_Opportunity_Type__c,
        API_Status__c, API_Error_msg__c, SBQQ__MasterContract__c, SBQQ__MasterContract__r.SBQQ__Opportunity__r.Billing_360_Transaction__c, Prorated_Amount__c,Prorated_Amount_with_Tax__c, Next_Recurring_Bill_Date__c, //GTMS-28089
        OTD_Amt__c, Future_Free_Service_Type__c,SBQQ__Opportunity2__r.Related_Contact__c, SBQQ__Opportunity2__r.Need__c, SBQQ__Opportunity2__r.Budget_Confirmed__c, Buyout_Incumbent_Provider__c,
  (SELECT Id, Name, SBQQ__NetTotal__c,SBQQ__Product__r.ProductCode,Renewal_Data_Error_Type__c,Total_Annual_Price__c,Conga_Line_Item_Type__c,Product_Type__c, SBQQ__ProductCode__c, SBQQ__Quantity__c, SBQQ__Quote__c, Ship_To__c,Rebate_Buyout_Ratio__c,SBQQ__PricebookEntryId__c, SBQQ__ListPrice__c,SBQQ__SubscriptionPricing__c,SBQQ__SubscriptionBase__c,SBQQ__SubscriptionType__c,SBQQ__DefaultSubscriptionTerm__c,
        SBQQ__Product__r.Sales_Charge_Type__c,SBQQ__Product__r.Baseline_Cost__c, Billing_Contract_Line_Id__c, SBQQ__EffectiveQuantity__c, SBQQ__UpgradedSubscription__c, Ship_From_Location__c, SBQQ__Quote__r.Ship_From_Location__c, Original_FT_Oppty_Line_Item_SF_Id__c, SBQQ__Quote__r.Shipping_Address_NEW__c,
        SBQQ__Quote__r.SBQQ__Opportunity2__r.Type, SBQQ__Quote__r.Co_Term_Contract__c, SBQQ__Quote__r.Co_Term_Contract__r.Billing_Contract_Line_Id__c, SBQQ__ChargeType__c
     FROM SBQQ__LineItems__r),
        (SELECT Id,sbaa__Status__c,Quote__c,SBAA__Rule__c from AAE_Approvals__r where SBAA__Rule__c = :strLstId ) //GTMS-22183 ---> CreatedBy Abu 07/10/2024
        FROM SBQQ__Quote__c
        WHERE ID IN :quoteIds
        ]);
    }
}