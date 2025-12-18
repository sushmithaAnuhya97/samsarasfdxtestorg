/**
* Created By : Groundswell - Flávio Contini
* @Date August 12, 2021
*
* @description : This class will be responsible for handling all Opportunity queries / SOQLs
* SFA-10
*
**/
public class GS_OpportunitySelector extends GS_SObjectBaseSelector{
    public GS_OpportunitySelector(Boolean checkFatalError){
        super(checkFatalError);
    }
    public GS_OpportunitySelector checkFatalError(){
        return (GS_OpportunitySelector) super.validateFatalError();
    }
    /**
    * Return the Opportunity by Id with the base fields to get the resolution status
    * @param List<id> idList
    */
    public List<Opportunity> getOppForResolutionById(List<Id> idList){
        return [
            SELECT Id, StageName, Type, isWon, Probability
            FROM Opportunity
            WHERE Id in :idList
        ];
    }
    /**
    * Return the Opportunity by Id with the base fields to get the resolution status
    * @param List<id> idList
    */
    public List<Opportunity> getOppForReturnProcessById(List<Id> idList){
        return [
            SELECT Id, AccountId, Cable_Tool_Activated__c, Corresponding_Netsuite_ID__c, CurrencyIsoCode, Return_Number_Shipping__c,
            Notes__c, Type, Shipping_Address_NEW__c, Zendesk_Ticket_Number__c, Replacement_Opportunity__c,
            Shipping_Country__c, Order_Admin__c, Warranty_Exchange_Reason__c //Alekya
            FROM Opportunity
            WHERE Id in :idList
        ];
    }
    /**
    * Return the Opportunity by Id with the base fields to execute the trial service functions
    * @param List<id> idList
    */
    public List<Opportunity> getOppForTrialServiceById(List<Id> idList){
        return [
            SELECT Id, Returning_Opportunity__c, FT_Return__c, CurrencyISOCode, Pricebook2Id, Free_Trial_Kit_Type__c, Welcome_Kit_Type__c, Type, AccountId
            FROM Opportunity
            WHERE Id IN :idList
        ];
    }
    /**
    * Return the Opportunity by Id with the base fields to execute the Post to Slack logic
    * @param List<id> idList
    */
        public List<Opportunity> getOppForPostToSlackServiceById(List<Id> idList){
        return [
            SELECT Id, Name, Amount_Number_Formula__c, Account.Name, Owner.FirstName, Owner.LastName, ACV_Bookings__c
            FROM Opportunity
            WHERE Id IN :idList
        ];
    }
    /**
    * Return the Opportunity by Id with the base fields to execute the Post to NetSuite logic
    * @param List<id> idList
    */
    public List<Opportunity> getOppForPostToNetSuiteServiceById(List<Id> idList){
        return [
            SELECT Id, Name, Type, StageName, Retry_TO_to_NS__c, netsuite_conn__Push_To_NetSuite__c,
            Buyout_Opportunity__c, Subsidy_Opportunity__c, Partner_Referral_Opportunity__c, CloseDate, Push_Return_to_Netsuite__c
            FROM Opportunity
            WHERE Id IN :idList
        ];
    }
    /**
    * @description : Loads DB version of the Opportunities in received Id List
    * @param : List<Id> opportunityIds
    */
    public List<Opportunity> loadOpportunityWithItems(Set<Id> opportunityIds) {
        return [SELECT Id, Name, Pricebook2Id, Pricebook2.Name, Shipping_Address_NEW__c, Shipping_Address_NEW__r.Shipping_Country__c, TrialResolutionOppty__c, Trial_Status__c, VAT_Number__c, VAT_Validation_Status__c,
                Shipping_Country__c, Shipping_Method__c, Type, Returning_Opportunity__r.Reseller_Partner__c,Bookings_Owner_Segment__c, SBQQ__AmendedContract__c, SBQQ__RenewedContract__c,
                Returning_Opportunity__r.Referral_Partner__c,Returning_Opportunity__r.Insurance_Partner__c,Insurance_Partner__c, StageName, Rebate_Type__c, Delinquent_Return_Past_180_Days__c,
                OwnerId, RecordType.Name, Stripe_Subscription_Id__c, Finance_Notes__c, Express_Agreement_Accepted_Date__c,
                Balance_Due__c, Rebate_Type_Formula__c, Returning_Opportunity__r.Buyout_Opportunity__c, Returning_Opportunity__r.Owner_Segment__c,
                Returning_Opportunity__r.Subsidy_Opportunity__c, Returning_Opportunity__c, Returning_Opportunity__r.License_Term__c, Returning_Opportunity__r.License_End_Date__c,
                Returning_Opportunity__r.Partner_Referral_Opportunity__c, Returning_Opportunity__r.CloseDate, Price_Book_Name__c, Payment_Token__c,
                First_Purchase__c, Probability, IsClosed, Account.New_Billing_Process_Approved__c, Resend_Return_Email__c, Configuration_Segment__c,
                Account.Overwrite_Validation_Rule__c, License_Term__c, CloseDate, IsWon, Owner_Segment__c, Account.Segment__c,
                License_Term_Approval_Status__c, License_End_Date__c, ContractId, Approved_Discount__c, License_Start_Date__c,
                Contract.EndDate, Contract.Original_Approved_Discount__c, Account.Latest_Active_Contract__c, Renewal__c, RecordTypeId,
                Segment_Sales_Role__c, Account.Latest_Active_Contract__r.Original_Approved_Discount__c,
                Account.Latest_Active_Contract__r.EndDate, netsuite_conn__Bill_To_Tier__c, netsuite_conn__Celigo_Contract__c,
                Selected_Payment_Type__c, Discount_Approval_Status__c, Blended_Discount__c, Trial_Primary_Contact__c,
                Trial_Primary_Contact__r.Trial_Deactivation_Email__c, ADR_Transfer__c,
                ADR_Transfer__r.ADR_Manager_Name_Copy_at_Qualification__c, ADR_Transfer__r.ADR_Transfer_Qualified_Date__c,
                ADR_Transfer__r.ADR_Transfer_By__r.ManagerId, ADR_Transfer__r.ADR_Role_Copy_at_Qualification__c,
                ADR_Transfer__r.ADR_Transfer_By__r.UserRole.Name, ADR_Transfer__r.ADR_Transfer_Status__c, Amount, Account.CSM__c,
                Account.CSM__r.FirstName, Account.CSM__r.LastName, Shipping_Instructions__c, Account_Approved_Payment_Type__c,
                Account.Approved_Payment_Type__c, Owner_Manager_Name_Copy__c, Returning_Opportunity__r.Owner_Manager_Name_Copy__c,
                Owner.ManagerId, Owner.UserRole.Name, Owner_Role_Copy__c, Returning_Opportunity__r.Owner_Role_Copy__c, Owner_Director_Name_Copy__c,
                Owner.Manager.ManagerId, Returning_Opportunity__r.Owner_Director_Name_Copy__c, Owner_Manager_Role_Copy__c, Owner.Manager.Email, Returning_Opportunity__r.Owner_Manager_Email_Copy__c,
                Owner.Manager.UserRole.Name, Returning_Opportunity__r.Owner_Manager_Role_Copy__c, Overwrite_Validation_Rule__c,
                Contract_Amount_Agreed_To__c, Shipping_Address_NEW__r.Shipping_Contact__c, Owner.Manager.Manager.Level__c, Owner.Manager.Level__c,
                of_Serialized_Products__c, Shipping_Contact__c, Oppty_Owners_CSM__c,Owner.IsActive,
                Owner_Geo_Copy__c, Owner.Territory__c, Owner_Director_Role_Copy__c, Owner_Manager_Email_Copy__c,
                Returning_Opportunity__r.Id, Returning_Opportunity__r.Name, Returning_Opportunity__r.Owner.Territory__c, Owner.Level__c,
                Returning_Opportunity__r.Owner.Level__c, Returning_Opportunity__r.Owner_Director_Name_Copy__r.Id,
                Owner.Manager.Manager.Id, SBQQ__PrimaryQuote__c, SBQQ__PrimaryQuote__r.ApprovalStatus__c, netsuite_conn__From_Contract__r.Original_Approved_Discount__c, netsuite_conn__From_Contract__c, Hold_Reason__c,
                Express_Selected_Discount__c,  Total_License_Due__c, Express_Annual_Discount__c, Express_Upfront_Discount__c,
                (
                    SELECT Id, Ship_To__c, License_Term_Copy__c, Discount, Express_Upfront_Discount__c, Express_Annual_Discount__c, Selected_Sales_Price__c, Express_Selected_Discount__c, UnitPrice
                    FROM OpportunityLineItems
                )
                FROM Opportunity
                WHERE Id IN :opportunityIds];
    }
    public List<Opportunity> loadOpportunityWithOpptyLineItems(Set<Id> opportunityIds) {
        return [SELECT Id, AccountId, Amount, Type, StageName, Returning_Opportunity__r.Owner_Role_Copy__c, Configuration_Segment__c,
                Pricebook2.Name, Pricebook2Id, CurrencyISOCode, Owner.UserRole.Name, (
                    SELECT Id, Description, Discount, ListPrice,
                    Name, OpportunityId, Product2Id,
                    PriceBookEntryId, ProductCode,
                    TotalPrice, UnitPrice, Quantity,
                    Other_Discount__c, Selected_Sales_Price__c, Express_Upfront_Discount__c, Express_Selected_Discount__c,
                    Express_Annual_Discount__c, Ship_To_Country__c
                    FROM OpportunityLineItems
                ), (
                    SELECT Channel_Partner__c, Channel_Partner__r.Partner_Status__c, Channel_Partner__r.RecordType.Name,
                    Channel_Partner__r.Business_Unit__c
                    FROM Channel_Relationships__r
                    LIMIT 1
                )
                FROM Opportunity
                WHERE Id
                IN :opportunityIds];
    }
    /**
    * @description : Loads DB version of the Opportunities in received Id List
    * @param : List<Id> opportunityIds
    */
    public List<Opportunity> loadOpportunityWithTeamMembers(Set<Id> opportunityIds) {
        return [SELECT Id, (SELECT Id, OpportunityAccessLevel, OpportunityId, UserId, TeamMemberRole FROM OpportunityTeamMembers)
                FROM Opportunity
                WHERE ID IN : opportunityIds];
    }
    /**
    * @description : Queries opportunities with dynamic query based on predefined quote to opportunity field mapping
    * @param : Set<Id> opportunityIds
    */
    public Map<Id, Opportunity> getQuoteToOppotyFieldMappingData(Set<Id> opportunityIds, List<Quote_To_Opportunity_Mapping__mdt> fieldMapping) {
        if (opportunityIds.size() == 0) {
            return null;
        }
        Set<Id> oppIds = opportunityIds;
        String queryStart = 'SELECT Id';
        String queriedFields = '';
        for(Integer i = 0; i < fieldMapping.size(); i++){
            queriedFields = queriedFields+','+fieldMapping[i].Opportunity_Field__c;
        }
        String query = queryStart+queriedFields+',Is_Webstore_Upsell_Opportunity__c, Account.Segment__c FROM Opportunity WHERE Id IN :oppIds';
        System.debug(LoggingLevel.INFO, 'Opp Query: '+query);
        return new Map<Id, Opportunity>((List<Opportunity>)Database.query(query));
    }
    /**
    * @description : Loads Free Trial Opportunities
    * @param : List<Id> opportunityIds
    */
    public List<Opportunity> loadFreeTrialOpportunity(Set<Id> opportunityIds) {
        return [SELECT Id, TrialResolutionOppty__c, Trial_Status__c, StageName
                FROM Opportunity
                WHERE type = 'Free Trial Opportunity'
                AND TrialResolutionOppty__c IN :opportunityIds];
    }
    /**
    * @description : Retrieves opportunities with associated Quotes, for provided Opportunity Ids
    * @param : Set<Id> opportunityIds
    */
    public Map<Id, Opportunity> getOpptyWithQuotesById(Set<Id> opptyIds) {
        return new Map<Id, Opportunity>([
            SELECT Id,StageName, Configuration_Segment__c ,Segment__c,Shipping_Address_NEW__c, Shipping_Method__c, Shipping_Account_Type__c, Related_Contact__c,OwnerId, Owner.ProfileId, Owner.isActive,
            Shipping_Carrier__c, Ship_From_Location__c, Shipping_Country__c, Shipping_State__c, Owner_Role_Copy__c,Referral_Partner__c,
            Shipping_Address_NEW__r.Shipping_State__c, Renewal__c, Probability, Type, Trial_Period__c, Payment_Type_Opportunity_only_Exception__c, 
            Shipping_Address_NEW__r.Shipping_Country__c,ContractId, CloseDate, Name, SBQQ__Renewal__c, 
            Shipping_Address_NEW__r.Name, Shipping_Address_NEW__r.Shipping_Address_Line_1__c, Account.Approved_Payment_Type__c, 
            Shipping_Address_NEW__r.Shipping_City__c, Shipping_Address_NEW__r.Shipping_Zip_Code__c,Reseller__c, Small_Fleet_Opportunity__c,
            Contract.EndDate, Reseller_Partner__c, Sub_Type__c, License_Term__c, Owner.Region__c,Insurance_Partner__c, Finance_Partner__c,
            Insurance_Partner__r.Payment_Terms__c, Finance_Partner__r.Payment_Terms__c, Reseller_Partner__r.Payment_Terms__c,
            Segment_Sales_Role__c,SBQQ__RenewedContract__r.Auto_Renewal__c, SBQQ__RenewedContract__c, Is_Webstore_Upsell_Opportunity__c,
            Selected_Payment_Type__c, Renewal_ACV__c, FP_and_Upsell_ACV__c, SBQQ__AmendedContract__c, Account.Payment_Terms__c, Account.Segment__c,
            Account.Latest_Partner_Account_Interaction__c,Account.Latest_Partner_Account_Interaction__r.Partner_Discount__c,
            SBQQ__RenewedContract__r.SBQQ__Opportunity__r.Blended_Discount__c, SBQQ__RenewedContract__r.SBQQ__Opportunity__r.License_Term__c,
            SBQQ__RenewedContract__r.SBQQ__Opportunity__r.Selected_Payment_Type__c, SBQQ__RenewedContract__r.Original_Blended_Discount_Manual__c,
            //Edit by: Govindaraju Boddu (21st, July 2023)
            Account.CM_Tier__c,Account.VG_Tier__c,Account.First_Purchase_Date__c,Account.P_P_Pilot_Customer__c,Account.P_P_Customer_Type__c,
            //Edit by: Govindaraju Boddu (20th, September 2023)
            Account.Platform_Type__c,Account.LIC_CM1_PRO__c,Account.LIC_CM2_PRO__c,Account.LIC_PLTFM_PRO__c,Account.LIC_VG_PRO__c,/*,Account.CM_Platform_Tier__c,Account.VG_Platform_Tier__c,Account.Platform_Premium__c,*/
            //Edit end: Govindaraju Boddu (20th, September 2023)
            //Edit End: Govindaraju Boddu (21st, July 2023)
            //Edit by: Abu Saleh Khan (Jan 13 2025)
            SBQQ__RenewedContract__r.P_P_Renewals__c,
            //Edit by: Abu Saleh Khan (Jan 13 2025). --> End
            (SELECT Id,Program_Type__c,Opportunity__c FROM Channel_Relationships__r WHERE Opportunity__c = :opptyIds),
            Account.BillingCity,Account.BillingCountry,Account.BillingPostalCode,Account.BillingState,Account.BillingStreet,Account.Billing_Contact__c,SBQQ__RenewedContract__r.Selected_Payment_Type__c,Owner.P_P_Pilot__c,
            Account.Owner.Region__c, //Edit by: Aditya Balaji (22nd, August 2025) GTMS-28767
            (SELECT Id FROM SBQQ__Quotes2__r)
            FROM Opportunity
            WHERE ID IN :opptyIds
        ]);
    }
    /**
    * @param ids Set of Opportunity ids to be queried from
    *@description Used from GS_AsyncSBQQQuoteFromOpportunityService
    * @return List Of Opportunity
    */
    public List<Opportunity> getOpportunityFromIds(Set<Id> ids){
        return [SELECT Id,
                VAT_Number__c,
                Reseller__c,
                CloseDate,
                Probability,
                Type,
                CPQ_Opportunity__c,
                Insurance_Partner__c,
                Reseller_Partner__c,
                Referral_Partner__c,
                SBQQ__AmendedContract__c
                FROM Opportunity
                WHERE Id IN : ids];
    }
    /**
    *@param recordsIds Set of Opportunity ids to be queried from
    *@description Used from GS_AsyncFreeTrialQuoteService
    *@return List Of Opportunity
    */
    public Map<Id, Opportunity> getOpportunityMapFromIds(Set<Id> recordsIds) {
        return new Map<Id, Opportunity>(
            [SELECT Id,
             Name,
             Pricebook2Id,
             Trial_Primary_Contact__c,
             Trial_Primary_Contact__r.Id,
             Trial_Primary_Contact__r.Email,
             Account.Billing_Email__c,
             Account.Name,
             Account.Which_written_language__c,
             Account.Owner.Email
             FROM Opportunity
             WHERE Id IN :recordsIds]);
    }
    /**
    *@param recordsIds Set of Opportunity ids to be queried based on TrialResolutionOppty__c field
    *@description Used from GS_DisconnectTrialOppService
    *@return List Of Opportunity
    */
    public List<Opportunity> getTrialOpportunitiesFromTrialResolutionIds(Set<Id> recordsIds) {
        return [SELECT Id,
                TrialResolutionOppty__c
                FROM Opportunity
                WHERE TrialResolutionOppty__c IN :recordsIds];
    }
}