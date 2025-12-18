/**
* @description       :
* @author            : ChangeMeIn@UserSettingsUnder.SFDoc
* @group             :
* @last modified on  : 03-28-2024
* @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
//OpportunityTests, ValidateProductQuantityCalloutTest,PopulateFinancePartneronAccountBatchTest provides the test coverage for the class
/* 11/03/21 Anil Bogadi (GTMS-4994) SFDC bug that has ops team members deleting approved discount and license term
* 09/01/21 Lavanya (GTMS-4517) Updated logic related to Bookings Owner Segment and Finance segment stamp fields
* 06/21/21 Anil(GTMS-3913) Last order opportunity link in Account Object.
* 05/20/21 Harsha (GTMS-3356) Modified the criteria for New Billing Process
* 05/06/21 Teja (GTMS-3317) Added email deliverability to Account Owner instead of Shipmate Owner in freeTrialQuoteCreator method
* 04/27/21 Lavanya - (GTMS-3471) calculateCurrentMonthlyPayments (Added logic to handle 'Divide by 0' error)
* 04/15/21 Harsha (GTMS-3486) Removed code references for deleted fields
* 03/18/21 Harsha (GTMS-2715) Made changes to managerFormula method
* 03/04/21 Harsha (GTMS-3198) Removed the dependencies for Corporate_Partner__c
* 03/04/21 Ron (GTMS-2878) Annual Payments no longer trigger payment processing fee
* 06/24/2021 Tanuj - Updated managerFormula method to pass newOpportunity Record
* June-22-2022 Lipun GTMS-6450 SFDC CI - Move Before Save Flow to Trigger
* June-29-2022 Rajesh GTMS-7220 Automation Request for Payment Processing Fee
* Aug-23-2022 Rajesh GTMS-8011 Set Opp's default owner to AccountAE if it exists
* Sep-02-2022 Raghavendran Ragothaman - GTMS-8352 - Refactoring the Owner logic for Delinquent Rebate Opportunity
* Sep-26-2022 Raghavendran Ragothaman - GTMS-9687 - Added null check on Shipping_Address_New__c.Shipping_Contact__c before sending email
* Sep-26-2022 Raghavendran Ragothaman - GTMS-8640, 8059 - Removed auto tagging of all Partner from WebStore Opportunities
* Oct-01-2022 Raghavendran Ragothaman - GTMS-9601 - Validation rule not allowing Users to update opp when select HW products with probability < 90% and stage changed.
* Nov-15-2022 Rajesh GTMS-9570- Added field ACV_Bookings_SOT__c in queryOpportunities()
* Nov-17-2022 Siddharth Kumar Mishra GTMS-7139 -Populating the values of Billing Payment Type and Shipmate Service Type for return opportunities
* Feb-6-2023 Rajesh - GTMS-11183 - Commented the method call calculateEquipmentACV - as this logic is being executed from batch job
* May-26-2023 Rajesh - GTMS-12823 - Populating AmendedContract when MasterContract is populated
* June-9-2023 Rajesh - GTMS-13653 - Fixed Null pointer exception which is occurring while creating renewal opp
* Aug-7-2023 Rajesh - GTMS-13689 - Populating Rover's manager details
* Sep-2023 Zakeer GTMS-13035 - Direct Quarterly extend logic with Direct Monthly.
* Feb-2024 Rodrigo GTMS-15659 - smart approval field change
* Aug-2024 Arun GTMS-22650 Ensure Non clickpath Auto Renewal Deals move to Orders Processing Stage after checkout process is completed in Webstor.
* Jul-2025 GTMS-28236 Rodrigo
*/
public class OpportunityHelper implements Callable {
public SamsaraLoggerService thisSamsaraLoggerService = new SamsaraLoggerService();
public static Map<Id, Account> oppAccounts = null;
public static Map<Id, Opportunity> oppFields {get; private set;}
private static Map<Id, Opportunity> trialOppFields = new Map<Id, Opportunity>();
private static Set<Id> oppAccountIds = null;
private static Set<Id> pricebookIdSet = null;
private static Map<Id, Map<String, Map<String, PricebookEntry>>> pricebookToCodesToEntriesMap = null;
private static Map<Id, User> ownerMap = null;
private static Map<Id, Contact> contactMap = null;
private static Map<Id, Contract> contractsMap = new Map<Id, Contract>();
private static Map<Id, List<CampaignMember>> cmMap = null;
public static Map<Id, Account> oppAccountsRev = null;
public static Map<Id, User> mapUsers = null;
private static Map<Id,List<Channel_Relationship__c>> crMap = null;
private static Map<Id, Account> accountUpdateMap = new Map<Id, Account>();
public static OrgWideEmailAddress samsaraSalesEmail = null;
private static boolean expressSetDiscountRun = false;
private static boolean updateDiscountRun = false;
private static boolean campAttrRun = false;
private static Integer maxRuns = 0;
private static Integer runsSoFar = 0;
private static boolean isInsert = FALSE;
public static Map<String, Id> trailLangugeTemplateIdMap = new Map<String, Id>();
public static Map<String, Id> trailAgreementAcceptanceLangugeTemplateIdMap = new Map<String, Id>();
private static List<Opportunity_Event__e> opportunityEvents = new List<Opportunity_Event__e>();
private static List<Order_Event__e> orderSyncEvents = new List<Order_Event__e>();
private Set<Id> duplicateOpportunityEvents = new Set<Id>();
static Map<String, Rollup_Switch__mdt> mapOFRollupFieldVsMetadata = new Map<String, Rollup_Switch__mdt> ();
private static List<Rebate_Event__e> rebateSyncEvents = new List<Rebate_Event__e>();
private List<Opportunity> clickPathOppList;
private Map<Id, Id> primaryQuoteToOppIdMap;
private static Boolean isRecursion = false;
private final static String GAINSIGHT_IGNORE_STATUS = Label.Success;
private set<Id> accountIdSet = new set<Id>(); //GTMS-6450
@testvisible private Set<Id> closedLostOppIdSet;
//GTMS-9688-Zakeer-CI-Init
private static Boolean futureCustomRollupRan = false;
private static Boolean isFutureCustomRollup = false;
    private static Set<Id> newOppIdSet = new Set<Id>();     //GTMS-26285 :Store all the CurrentId
public static List<Schema.SObjectType> MY_SOBJECTS = new List<Schema.SObjectType>{
Account.SobjectType,
Opportunity.SObjectType
};
public static Org_Setting__mdt orderTransformationSetting = Org_Setting__mdt.getInstance('OrderTransformationPhase2');
/**
* @author Groundswell - Vikasm - vikas@gscloudsolutions.com
* @date 2020-08-31
* Not yet deployed for Production
* GTMS-1471
*/
private static Set<String> targetRollupAccountSet = new Set<String> ();
private static List<Opportunity> targetOpportunities = new List<Opportunity>();
// Define kit product codes here
private final Set<String> kitProductCodeCriteria = new Set<String>{
'FREE-TRIAL-KIT',
'WELCOME-KIT',
'EXPRESS-WELCOME-KIT'
};
private static Callable callInstance;
private static Id opportunityRevRecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('Standard_Opportunity').getRecordTypeId();
static {
OpportunityHelper opp = new OpportunityHelper();
callInstance = (Callable) opp;
}
/**
* @author Groundswell - Vikasm - vikas@gscloudsolutions.com
* @date 2020-08-31
* Not yet deployed for Production
* GTMS-1471
*/
public static void loadOppTargetRollupAccountSet(List<Opportunity> oppList, Map<Id, Opportunity> OldOpportunitiesMap) {
if (OldOpportunitiesMap == null) {
for (Opportunity thisOpp : oppList) {
if (thisOpp.AccountId == null) continue;
for (String rollUpField : mapOFRollupFieldVsMetadata.KeySet()) {
//Callable callInstance = (Callable) Type.forName('OpportunityHelper').newInstance();
Object result = callInstance.call(rollUpField, new map<String, Object>{
'newRecord' => thisOpp
});
if (result == null) continue; // When metadata is not defined
if ((Boolean) result) {
targetRollupAccountSet.add(thisOpp.AccountId);
break;
}
}
}
}
else
{
for(Opportunity thisOpp : oppList)
{
for (String rollUpField : mapOFRollupFieldVsMetadata.KeySet()) {
if (accountReparenting(thisOpp, OldOpportunitiesMap.get(thisOpp.id))) {
if (OldOpportunitiesMap.get(thisOpp.id).AccountId != null)
targetRollupAccountSet.add(OldOpportunitiesMap.get(thisOpp.id).AccountId);
if (thisOpp.AccountId != null)
targetRollupAccountSet.add(thisOpp.AccountId);
} else {
//Callable callInstance = (Callable) Type.forName('OpportunityHelper').newInstance();
Object result = callInstance.call(rollUpField + 'PreCheck', new map<String, Object>{
'newRecord' => thisOpp, 'oldRecord' => OldOpportunitiesMap.get(thisOpp.id)
});
if (result == null) continue;
if ((Boolean) result) {
if (thisOpp.AccountId != null)
targetRollupAccountSet.add(thisOpp.AccountId);
break;
}
}
}
}
}
}
//GTMS-6422: Query to fetch channel relationship records linked to an account
/*** PARTNER RECORD TYPE PROJECT CHANGES: Commenting this code as the requirement for this change is temporarily onhold
public void loadChannelRelationshipRecords(List<Opportunity> oppList){
if(crMap == null){
loadOppAccountIds(oppList);
crMap = new Map<Id,List<Channel_Relationship__c>> ();
List<Channel_Relationship__c> crList = [SELECT id, Name, Opportunity__c,Opportunity__r.AccountId,Channel_Partner__c, Program_Type__c,CreatedDate
FROM Channel_Relationship__c
WHERE Opportunity__r.AccountId in :oppAccountIds AND Program_Type__c IN ('Paid Referral','Unpaid Referral')
ORDER By LastModifiedDate asc];
for(Id accId:oppAccountIds){
List<Channel_Relationship__c> craccList = new List<Channel_Relationship__c>();
for(Channel_Relationship__c cr: crList){
if(cr.Opportunity__r.AccountId == accId){
craccList.add(cr);
}
}
crMap.put(accId,craccList);
}
}
}*/
public static void loadOppAccounts(List<Opportunity> oppList) {
if (oppAccounts == null) {
loadOppAccountIds(oppList);
oppAccounts = new Map<Id, Account>([
    SELECT Id, Name, Account_C_R_In_Progress__c, Free_Trial_Kit_Sent_Date__c, Segment__c, Number_of_Vehicles__c,CurrencyIsoCode,Payment_Terms__c,Owner.UserRole.Name,Owner.CurrencyIsoCode,
Welcome_Kit_Sent_Date__c, Segment_Text_stamped__c, Latest_Active_Contract__r.EndDate, Approved_Payment_Type__c,
Billing_Email__c, BillingStreet,BillingCity, BillingPostalCode, Latest_Active_Contract__c, Book_of_Business__c,
BillingCountry, Internally_Financed__c, Churn_Update_CC_Link__c, Which_written_language__c, IS_Named_Account__c,
VAT_Validation_Status__c, BillingState, First_Purchase_Value__c, VATId__c, Status__c, First_Purchase_Date__c,
Partner_Status__c, RecordType.Name, Business_Unit__c, Critically_Escalated_Hardware_Returns__c, SLED_Account__c, Owner_Role__c,
Netsuite_Id__c, Push_to_Netsuite__c ,Ownerid,Latest_Partner_Account_Interaction__c,Latest_Partner_Program_Interaction__c,
Latest_Partner_Account_Interaction__r.OwnerId,Latest_Partner_Account_Interaction__r.Partner_Discount__c,Renewal_AE__c,Account_Size_Segment__c,
Total_Purchased_AG_Count__c, Total_Purchased_CM_Count__c, Total_Purchased_VG_Count__c, Total_Purchased_EM_Count__c, Referral_Rebate__c,//GTMS-13490
Cross_Sell__c,// P&P 2.0 for Enhanced Cross-Sell logic(PRO SKUS) 032724
    Customer_require_PO_for_invoicing__c, // GTMS-25962
    Billing_First_Name__c, Billing_Last_Name__c, Billing_Phone__c,
(
SELECT Id, Pricebook2.Name, Pricebook2Id,
    CloseDate, StageName, Sub_Type__c, Type
FROM Opportunities
ORDER BY CloseDate DESC
), (
SELECT id, Name, Shipping_Country__c
FROM Shipping_Addresses__r
ORDER BY LastModifiedDate desc
LIMIT 1
)
FROM Account
WHERE Id
IN :oppAccountIds
]);
}
// Filter by closed revenue oppties
oppAccountsRev = new Map<Id, Account>(oppAccounts);
for (Id accountId : oppAccountsRev.keySet()) {
for (Integer i = oppAccountsRev.get(accountId).Opportunities.size() - 1; i >= 0; i--) {
Opportunity oppty = oppAccountsRev.get(accountId).Opportunities[i];
if (oppty.StageName != 'Closed Won' ||
oppty.Type != 'Revenue Opportunity') {
oppAccountsRev.get(accountId).Opportunities.remove(i);
}
}
}
}
public static void loadOppAccountIds(List<Opportunity> oppList) {
if (oppAccountIds == null) {
oppAccountIds = new Set<Id>();
for (Opportunity o : oppList) {
oppAccountIds.add(o.AccountId);
//GTMS-13490===START
if(o.Referral_Partner__c != null){oppAccountIds.add(o.Referral_Partner__c);}
//GTMS-13490===END
//GTMS-17232
if(o.Finance_Partner__c != null){oppAccountIds.add(o.Finance_Partner__c);}
if(o.Reseller__c != null){oppAccountIds.add(o.Reseller__c);}
if(o.Insurance_Partner__c != null) {
oppAccountIds.add(o.Insurance_Partner__c);
}
//GTMS-17232 === END
}
}
}
public void loadOppFields(Map<Id, Opportunity> oppMap) {
if (oppFields == null || Test.isRunningTest()) {
oppFields = new Map<Id, Opportunity>([
                    SELECT Id, AccountId,SBQQ__AmendedContract__r.Contract_C_R_In_Progress__c,Upgraded_Opportunity_ID__c, Sub_Type__c, Account.Account_C_R_In_Progress__c, Account.Owner_Role__c, Amount, Type, StageName, Returning_Opportunity__r.Owner_Role_Copy__c, Configuration_Segment__c,Returning_Opportunity__c,Returning_Opportunity__r.Renewal__c,Owner.Profile.Name,Renewal__c,Finance_Partner__c,Finance_Partner__r.Is_Finance_Partner_Active__c,
Pricebook2.Name, Pricebook2Id, CurrencyISOCode,Customer_require_PO_for_invoicing__c,Account.Customer_require_PO_for_invoicing__c, Owner.UserRole.Name, Owner.Manager.Name,Owner.Manager.Manager.Manager.Name, Owner.Manager.Manager.Manager.UserRole.Name, Ship_From_Location__c,
SBQQ__PrimaryQuote__c,SBQQ__PrimaryQuote__r.DCA_Validation__c, SBQQ__PrimaryQuote__r.Co_Term_Contract__c,SBQQ__PrimaryQuote__r.Co_Term_Contract__r.EndDate, SBQQ__PrimaryQuote__r.SBQQ__BillingCountry__c,SBQQ__PrimaryQuote__r.SBQQ__Status__c, (
SELECT Id, Description, Discount, ListPrice,
Name, OpportunityId, Product2Id,
PriceBookEntryId, ProductCode,
TotalPrice, UnitPrice, Quantity, Product_Cost__c,
Other_Discount__c, Selected_Sales_Price__c, Express_Upfront_Discount__c, Express_Selected_Discount__c,
Express_Annual_Discount__c, Ship_To_Country__c, Ship_From_Location__c
, Product2.Product_Status__c, Product2.CPQ_Enabled_Product__c,Product2.Product_Type__c, //GTMS-9061
    Product2.Key_Account_Eligible__c //GTMS-21691
FROM OpportunityLineItems
), (
SELECT Channel_Partner__c, Channel_Partner__r.Partner_Status__c, Channel_Partner__r.RecordType.Name,
Channel_Partner__r.Business_Unit__c
FROM Channel_Relationships__r
LIMIT 1
), (
SELECT Id FROM Orders
    ),
    (SELECT Id,Primary_Quote__c,dsfs__Opportunity__c,Customer_require_PO_for_invoicing__c,PO_Number__c from  R00N80000002fD9vEAE where Envelope_Type__c != 'Rebate Document' AND dsfs__Envelope_Status__c = 'Completed' order by lastModifiedDate desc),
    (SELECT Id, Type, Trial_Status__c FROM Opportunities__r),
    (SELECT Id, Name, Flex_Is_Rebook__c FROM ReplacementContracts__r LIMIT 1),
    (SELECT Id, Name, SBQQ__Opportunity2__c, SBQQ__Opportunity2__r.Upgraded_Opportunity_ID__c, SBQQ__Opportunity2__r.SBQQ__AmendedContract__c, SBQQ__StartDate__c, OwnerId FROM SBQQ__Quotes2__r),
//                (SELECT Id, Name, CloseDate, StageName, OwnerId, Upgraded_Opportunity_ID__c,SBQQ__AmendedContract__c, Upgraded_Opportunity__r.StageName, Sub_Type__c, AccountId, (SELECT Id, Name, SBQQ__Opportunity2__c, SBQQ__Opportunity2__r.Upgraded_Opportunity_ID__c, SBQQ__StartDate__c, OwnerId, SBQQ__Opportunity2__r.SBQQ__AmendedContract__c, SBQQ__Opportunity2__r.SBQQ__AmendedContract__r.Flex_Is_Rebook__c FROM SBQQ__Quotes2__r) FROM Opportunities4__r)
(SELECT Id, Revenue_Opportunity__c, Revenue_Opportunity__r.CloseDate, Revenue_Opportunity__r.StageName, Revenue_Opportunity__r.OwnerId, Revenue_Opportunity__r.Sub_Type__c , Revenue_Opportunity__r.AccountId,
Cancelation_Opportunity__c,Cancelation_Opportunity__r.CloseDate, Cancelation_Opportunity__r.StageName, Cancelation_Opportunity__r.OwnerId , Cancelation_Opportunity__r.SBQQ__AmendedContract__c, Cancelation_Opportunity__r.Sub_Type__c , Cancelation_Opportunity__r.AccountId,Cancelation_Opportunity__r.Upgraded_Opportunity_ID__c, 
(Select Id, Name, SBQQ__Opportunity2__c, SBQQ__Opportunity2__r.Upgraded_Opportunity_ID__c, SBQQ__StartDate__c, OwnerId, SBQQ__Opportunity2__r.SBQQ__AmendedContract__c, SBQQ__Opportunity2__r.SBQQ__AmendedContract__r.Flex_Is_Rebook__c From RelatedQuotes__r) From Related_Opportunities__r) 
FROM Opportunity
WHERE Id
IN :oppMap.keyset()
]);
}
}
public void loadOppFields(List<Opportunity> lstOpp) {
Map<Id, Opportunity> mapOpp = new Map<Id, Opportunity>();
for (Opportunity opp : lstOpp) {
mapOpp.put(opp.Id, opp);
}
if (!mapOpp.isEmpty()) {
loadOppFields(mapOpp);
}
}
public void updateAccountRecords() {
if (accountUpdateMap.values().size() > 0) {
List<Account> accounts = new List<Account>();
accounts.addAll(accountUpdateMap.values());
accountUpdateMap.clear();
DMLWrapper.doUpdate(accounts);
}
}
/*
* @description - GTMS-25781 Sync Mechanism between the Replacement Opportunity and Cancellation Opportunities
* @param - newOppList, oldOppMap, newOppMap
*/
public void flexSyncReturnOpportunities(List<Opportunity> newOppList, Map<Id, Opportunity> oldOppMap, Map<Id, Opportunity> newOppMap) {
    Map<Id, Opportunity> upgradeOpportunityMap = new Map<Id, Opportunity>();   // Map to store upgraded opportunities 
    Map<String, String> upgradeToReturnStageMap = new Map<String, String>(); // Map to store stage name mappings from custom metadata
    
    // Fetching stage name mappings from custom metadata
    List<Flex_Opportunity_StageName_Mapping__mdt> stageNameMetadata = Flex_Opportunity_StageName_Mapping__mdt.getAll().values();
    for (Flex_Opportunity_StageName_Mapping__mdt metadataRecord : stageNameMetadata) {
        upgradeToReturnStageMap.put(metadataRecord.Upgrade_Opportunity_StageName__c, metadataRecord.Return_Opportunity_StageName__c);
    }
    
    // Process new opportunities
    for (Opportunity newOpp : newOppList) {
        Opportunity oldOpp = oldOppMap.get(newOpp.Id);
        // Determine if the opportunity is a contract replacement and if Closed date, stage name, owners have changed
        Boolean isContractReplacement = newOpp.Sub_Type__c == 'Contract Replacement';
        Boolean isCloseDateChanged = newOpp.CloseDate != oldOpp.CloseDate;
        Boolean isStageNameChanged = newOpp.StageName != oldOpp.StageName;
        Boolean isOwnerChanged = newOpp.OwnerId != oldOpp.OwnerId;        
        // Add to upgradeOpportunityMap if it is a contract replacement and closed date, stage name have changed
        if (isContractReplacement && isStageNameChanged) {
            upgradeOpportunityMap.put(newOpp.Id, newOpp);
        }
        // Add to upgradeOpportunityMap and opportunityIdSet if the owner has changed
        if (isContractReplacement && isCloseDateChanged) {
            upgradeOpportunityMap.put(newOpp.Id, newOpp);
        }
        if (isContractReplacement && isOwnerChanged) {
            upgradeOpportunityMap.put(newOpp.Id, newOpp);
        }
    }
    
    // Update return opportunities
    if (!upgradeOpportunityMap.isEmpty()) {
        List<Opportunity> returnOpportunityList = new List<Opportunity>();
        List<SBQQ__Quote__c> quotesList = new List<SBQQ__Quote__c>();
        for (Id key : upgradeOpportunityMap.keySet()) {
            Opportunity opp = oppFields.get(key);
            quotesList.addAll(opp.SBQQ__Quotes2__r);             // upgrade opportunity quotes
            /*returnOpportunityList.addAll(oppFields.get(key).Opportunities4__r); // Assuming oppFields is defined elsewhere              
            for(Opportunity returnOpp : returnOpportunityList)
            {
                quotesList.addAll(returnOpp.SBQQ__Quotes2__r);              // return opportunity quotes
            }*/
            for(Related_Opportunity__c ro:opp.Related_Opportunities__r){
                if(ro.Cancelation_Opportunity__c!=null){
                    returnOpportunityList.add(ro.Cancelation_Opportunity__r);
                }
                if(ro.RelatedQuotes__r.size()>0){
                    quotesList.addAll(ro.RelatedQuotes__r);
                }
            }            
        }
        
        if (!returnOpportunityList.isEmpty()) {
            OpportunityTriggerHandler.bypassForSyncMechanism = true; // bypassing sync opportunities mechanism
            Map<Id,Opportunity> returnOppUpdateMap = new Map<Id,Opportunity>();
            for (Opportunity returnOpp : returnOpportunityList) {
                //Opportunity upgradedOpp = upgradeOpportunityMap.get(returnOpp.Upgraded_Opportunity_ID__c); 
                Opportunity newOpp = newOppMap.get(returnOpp.Upgraded_Opportunity_ID__c);
                Opportunity oldOpp = oldOppMap.get(returnOpp.Upgraded_Opportunity_ID__c);
                
                returnOpp.Bypass_Validation_Rule_DateTime__c = Datetime.now();
                // Update return opportunity fields based on changes in the upgraded opportunity
                if (newOpp.CloseDate != oldOpp.CloseDate) {
                    returnOpp.CloseDate = newOpp.CloseDate;
                    returnOppUpdateMap.put(returnOpp.Id, returnOpp);
                    
                }
                if (newOpp.StageName != oldOpp.StageName && upgradeToReturnStageMap.containsKey(newOpp.StageName)) {
                    returnOpp.StageName = upgradeToReturnStageMap.get(newOpp.StageName);
                    returnOppUpdateMap.put(returnOpp.Id, returnOpp);
                } 
                if (newOpp.OwnerId != oldOpp.OwnerId) {
                    returnOpp.OwnerId = newOpp.OwnerId;         
                    returnOppUpdateMap.put(returnOpp.Id, returnOpp);
                }                
            }
            if(!returnOppUpdateMap.keySet().isEmpty())
            {
                update returnOppUpdateMap.values(); // Update the return opportunities
            }
        }
        
        // Update quote owners
        if(!quotesList.isEmpty()) {
            Map<Id,SBQQ__Quote__c> quoteMap= new Map<Id,SBQQ__Quote__c>();
            
            for (SBQQ__Quote__c quote : quotesList) {
                String opportunityId = quote.SBQQ__Opportunity2__r.Upgraded_Opportunity_ID__c != null ? 
                    quote.SBQQ__Opportunity2__r.Upgraded_Opportunity_ID__c :
                quote.SBQQ__Opportunity2__c;
                
                Opportunity newOpp = upgradeOpportunityMap.get(opportunityId);
                Opportunity oldOpp = oldOppMap.get(opportunityId);
                
                if(newOpp.OwnerId != oldOpp.OwnerId) {
                    quote.OwnerId = newOpp.OwnerId;
                }
                
                if(newOpp.CloseDate != oldOpp.CloseDate) {
                    Boolean isContractRebook = false;
                    
                    if (quote.SBQQ__Opportunity2__r.Upgraded_Opportunity_ID__c != null) {
                        isContractRebook = quote.SBQQ__Opportunity2__r.SBQQ__AmendedContract__r.Flex_Is_Rebook__c;
                    }
                    else if(quote.SBQQ__Opportunity2__r.Upgraded_Opportunity_ID__c == null && oppFields.containsKey(quote.SBQQ__Opportunity2__c) && !oppFields.get(quote.SBQQ__Opportunity2__c).ReplacementContracts__r.isEmpty()) {
                        isContractRebook = oppFields.get(quote.SBQQ__Opportunity2__c).ReplacementContracts__r[0].Flex_Is_Rebook__c;
                    }
                    
                    quote.SBQQ__StartDate__c = isContractRebook ? (newOpp.CloseDate + 15) : newOpp.CloseDate;
                }
                
                if (newOpp.OwnerId != oldOpp.OwnerId || newOpp.CloseDate != oldOpp.CloseDate) {
                    quote.Flex_Bypass_Validation_Rule_Date_Time__c = DateTime.now(); //GTMS-25783
                    quoteMap.put(quote.Id, quote);
                }
            }
            
            if(!quoteMap.keySet().isEmpty())
            {
                update quoteMap.values(); // Update the return opportunities
            }
        }                               
    }
}
/*
* @description - GTMS-26285  Unset C&R flag from Account and Contract.
* @param - newOppList, oldOppMap, newOppMap
*/   
public void flexUnsetCnRFlag(List<Opportunity> oppList, Map<Id, Opportunity> oldOppMap,Map<Id, Opportunity> newOppMap) {
    Set<Id> upgradeOppIdSet = new Set<Id>();
    List<Contract> cnrContractList = new List<Contract>();
    Set<Id> accountIdSet = new Set<Id>();  // To track account updates
    for (Opportunity opp : oppList)
    {
        if(opp.Upgraded_Opportunity_ID__c == null && opp.Sub_Type__c=='Contract Replacement')
        {
            upgradeOppIdSet.add(opp.Id);
        }
        Opportunity oldOpp = oldOppMap.get(opp.Id);        
        if(opp.AccountId != null && opp.StageName != oldOpp.StageName && oppAccounts.containsKey(opp.AccountId) && oppAccounts.get(opp.AccountId).Account_C_R_In_Progress__c)
        {           
            // Identifying the corrrect Opprtunity.
            if(opp.Upgraded_Opportunity_ID__c != null &&  opp.Sub_Type__c=='Contract Cancellation'&& (opp.StageName == 'Refunded - Closed' || opp.StageName == 'Return Cancelled'))
            {
                // Stores AccountId retrieved from return opportunity
                accountIdSet.add(opp.AccountId);
                newOppIdSet.add(opp.Id);
            }
            if(opp.Sub_Type__c=='Contract Replacement'&& (opp.StageName =='Closed Won' || opp.StageName =='Closed Lost'))
            {
                
                // Stores AccountId retrieved from Upgrade opportunity
                accountIdSet.add(opp.AccountId);
                newOppIdSet.add(opp.Id);
            }
        }
    }
    
    if (!accountIdSet.isEmpty()) {
        Boolean allValidOpp = true;
        List<Account> accountsToProcessList = new List<Account>();
        for (Id accountId : accountIdSet) 
        {
            Boolean allValidOpportunities = true;
            Account acc = oppAccounts.get(accountId);
            for (Opportunity opp : acc.Opportunities) 
            {   
                if (!newOppIdSet.contains(opp.Id) && ((opp.Sub_Type__c == 'Contract Cancellation' && opp.StageName != 'Refunded - Closed' && opp.StageName != 'Return Cancelled') || (opp.Sub_Type__c == 'Contract Replacement' && opp.StageName != 'Closed Won' && opp.StageName != 'Closed Lost'))) 
                {
                    allValidOpportunities = false;
                    break; 
                }
                
            }
            if(allValidOpportunities)
            {
                accountsToProcessList.add(new Account(Id = accountId, Account_C_R_In_Progress__c = false));
            }
        }
        if(!upgradeOppIdSet.isEmpty()) {
            
            for(Id opportunityId : upgradeOppIdSet){
                List<Opportunity> returnOppty = new List<Opportunity>();
                if(newOppMap.get(opportunityId).StageName=='Closed Lost') {
                    
                    //List<Opportunity> returnOppty= oppFields.get(opportunityId).Opportunities4__r;
                    Opportunity oppty = oppFields.get(opportunityId);
                    for(Related_Opportunity__c ro:oppty.Related_Opportunities__r){
                        if(ro.Cancelation_Opportunity__c!=null){
                            returnOppty.add(ro.Cancelation_Opportunity__r);
                        }
                    }
                    if(!returnOppty.isEmpty()) {
                        for(Opportunity opp : returnOppty)
                        {
                            if(opp.Upgraded_Opportunity_ID__c != null && opp.SBQQ__AmendedContract__c!=null)
                            {			
                                Contract contract = new Contract(Id = opp.SBQQ__AmendedContract__c);                           
                                contract.Contract_C_R_In_Progress__c = false;
                                cnrContractList.add(contract);	                             
                            }
                        }
                    }
                }
            }
        }
        // Update Account in bulk
        if(!accountsToProcessList.isEmpty()) {
            update accountsToProcessList;
        }
        // Update Contracts in bulk 
        if (!cnrContractList.isEmpty()) {
            update cnrContractList;
        }
    }
    }
//TEST CODE FOR CLARI CUSTOM OBJECT CREATION
public void afterInsertOperations(List<Opportunity> newOppList){
Opportunity oldOpportunity = new Opportunity();
List <Clari_Opp__c> clariOppsToCreate = new List <Clari_Opp__c>();
Map<Id, Id> opportunityIds = new Map<Id, Id>();
loadOppAccounts(newOppList);
for (Opportunity opp : newOppList){
if(opp.type != 'Free Trial Opportunity' && opp.Type != 'Free Trial Return') {
Clari_Opp__c clariOpp = new Clari_Opp__c();
clariOpp.Opportunity__c = opp.Id;
clariOppsToCreate.add(clariOpp);
}
if((opp.type == 'Free Trial Opportunity') && (opp.TrialResolutionOppty__c != null)){
opportunityIds.put(opp.TrialResolutionOppty__c, opp.Id);
}
else if((opp.type == 'Rebate' || opp.type == 'Remorse Refund') && (opp.Returning_Opportunity__c != null)){
opportunityIds.put(opp.Returning_Opportunity__c, opp.Id);
}
// Groundswell : Tanuj - WFlow Rule - Update Account for NS Sync
// Start
Account thisOppAccount = new Account();
if (opp.AccountId != NULL && oppAccounts.containsKey(opp.AccountId)) {
thisOppAccount = oppAccounts.get(opp.AccountId);
OpportunityWorkflowConversion.afterInsertUpdateMethod(opp, null, thisOppAccount);
}
// End
}
//Zakeer: added !System.isBatch() -- Oct26-2021-->ContractAutomation
if(!opportunityIds.isEmpty() && !System.isBatch()){
createOpportunityTeams(opportunityIds);
}
insert clariOppsToCreate;
}
@future
public static void createOpportunityTeams(Map<Id, Id> opportunityIds) {
Map<Id, Opportunity> queriedOpportunities;
List<OpportunityTeamMember> opportunityTeams = new List<OpportunityTeamMember>();
if(!opportunityIds.isEmpty()){
queriedOpportunities = new Map<Id, Opportunity>([SELECT Id, (SELECT Id, OpportunityAccessLevel, OpportunityId, UserId, TeamMemberRole FROM OpportunityTeamMembers)
                            FROM Opportunity WHERE ID IN : opportunityIds.keyset()]);
}
for(Opportunity relatedOpp : queriedOpportunities.values()){
List<OpportunityTeamMember> teams = relatedOpp.OpportunityTeamMembers;
if(teams.size() > 1){
for(OpportunityTeamMember member : teams){
if(member.TeamMemberRole != 'Opportunity Owner'){
OpportunityTeamMember newMember = new OpportunityTeamMember();
newMember.TeamMemberRole = member.TeamMemberRole;
newMember.UserId = member.UserId;
newMember.OpportunityId = opportunityIds.get(relatedOpp.Id);
opportunityTeams.add(newMember);
}
}
}
}
if(opportunityTeams.size()>0){
insert opportunityTeams;
}
}
//added this condition for GTMS-10997
public Map<String, String> getCanadaShipFrom() {
Map<String, String> mapCanadaState = new Map<String, String>();
String ShippingStateMapping = Shipping_Countries__mdt.getInstance('Canada')?.Shipping_State_Mapping__c;
if(ShippingStateMapping != null) {
List<String> strArr = ShippingStateMapping.split('\\*');
List<String> dclla = strArr[0].split('\\@');
if(dclla != null) {
for(String s : dclla[0].split('\\;')) {
mapCanadaState.put(s, dclla[1]);
}
}
List<String> dclky = strArr[1].split('\\@');
if(dclky != null) {
for(String s : dclky[0].split('\\;')) {
mapCanadaState.put(s, dclky[1]);
}
}
}
return mapCanadaState;
}
// Begin trigger methods
//* 12/17/2020 Ron, Harsha (GTMS-2395) beforeInsertOnly (Configuration Segment)
public void beforeInsertOnly(List<Opportunity> newOppList) {
valueforSelectedPaymentType(newOppList);
// Load up the opp accounts static list.
Set<Id> contractIds = new Set<Id>();
//GTMS-8352
Set<Id> returnIds = new Set<Id>();
Map<Id, Id> rebateOppByOwnerId = new Map<Id, Id>();
//GTMS-8640, 8059
List<String> cwRoboIds = System.Label.Corpweb_SFDC_Robot.split(',');
List<Opportunity> amendmentOppsList = new List<Opportunity>();
String configurationSegment;
loadOppAccounts(newOppList);
for (Opportunity o : newOppList) {
if (o.ContractId != NULL) {
contractIds.add(o.ContractId);
}
// Renewal Code - Harsha
if(o.SBQQ__AmendedContract__c != null){
contractIds.add(o.SBQQ__AmendedContract__c);
amendmentOppsList.add(o);
}
if(o.SBQQ__RenewedContract__c != null){
contractIds.add(o.SBQQ__RenewedContract__c);
}
//GTMS-16445 Setting UUID in opportunity
o.Opportunity_UUID__c = SSUtils.getUUID();
//GTMS-8352
if(o.type=='Rebate' && o.rebate_type__c=='Delinquent' && o.Returning_Opportunity__c != null){
returnIds.add(o.Returning_Opportunity__c);
}
}
if (contractIds.size() > 0) {
loadContracts(contractIds);
}
//GTMS-8352
if(!returnIds.isEmpty()){
rebateOppByOwnerId = getOwnerForDelinquentRebateOpportunity(returnIds);
}
//GTMS-7139
id ReturnOppRecTypeId = [Select Id,name from RecordType where name='Return Opportunity' AND SobjectType='Opportunity'].id;
for(Opportunity o : newOppList)
{
if(o.RecordTypeId == ReturnOppRecTypeId && (o.Type == 'Exchange' || o.Type == 'Warranty Exchange' || o.Type == 'Free Trial Return' || o.Type == 'Remorse Refund'))
{
//Populating billing payment type as 'SENDER' for the non-US countries
if(o.Shipmate_Country__c != 'United States')
{
o.Billing_Payment_Type__c = 'shipper';
}
//Populating the service type for various countries
if(o.Shipmate_Country__c == 'United States')
{
o.Shipmate_Service_Type__c = 'ups_ground';
}
else if(o.Shipmate_Country__c == 'Canada')
{
o.Shipmate_Service_Type__c = 'ups_worldwide_express';
}
else if(o.Shipmate_Country__c == 'Mexico')
{
o.Shipmate_Service_Type__c = 'ups_worldwide_saver';
}
else if(o.Shipmate_Country__c == 'Ireland' ||o.Shipmate_Country__c == 'United Kingdom' || o.Shipmate_Country__c == 'France' || o.Shipmate_Country__c == 'Germany' || o.Shipmate_Country__c == 'Austria' || o.Shipmate_Country__c == 'Italy' || o.Shipmate_Country__c == 'Switzerland' || o.Shipmate_Country__c == 'Spain' || o.Shipmate_Country__c == 'Netherlands')
{
o.Shipmate_Service_Type__c = 'ups_standard';
}
}
If(o.Type == 'Free Trial Opportunity' && o.SBQQ__AmendedContract__c != Null){
if(contractsMap != Null && contractsMap.get(o.SBQQ__AmendedContract__c) != Null && contractsMap.get(o.SBQQ__AmendedContract__c).endDate != Null){
o.License_End_Date__c = contractsMap.get(o.SBQQ__AmendedContract__c).endDate;
}
}
//GTMS-15659 added to set initial value for smart approval
DateTime myDateTime = DateTime.now();
o.Smart_Approve_Standard_Term_Indicator__c = myDateTime.millisecond() + myDateTime.minute() + myDateTime.hour() + myDateTime.day() + myDateTime.month() + myDateTime.year();
}
/*GTMS-6422: Commenting this code as business requested to place this change onhold
if(amendmentOppsList.size()>0){
loadChannelRelationshipRecords(amendmentOppsList);
}*/
    
    // GTMS-27516 Tag Reseller partners on Amendment Opportunity only for the given accounts IDs(added in metadata)
    Map<String,Reseller_Partner_Account_Config__mdt>  resellerPartnerConfigMap = Reseller_Partner_Account_Config__mdt.getAll();
    Set<Id> activeResellerAmendAccountIds = new Set<Id>();
    Set<Id> activeResellerRenewAccountIds = new Set<Id>();
    
    for (Reseller_Partner_Account_Config__mdt config : resellerPartnerConfigMap.values()) {
        if (
            config.Active__c &&
            config.Account_Id__c != null &&
            (config.Account_Id__c.length() == 15 || config.Account_Id__c.length() == 18) &&
            config.Account_Id__c.startsWith('001')
        ) {
            if(config.Category__c == 'Opportunity Amendment') 
            activeResellerAmendAccountIds.add(config.Account_Id__c);
            else if (config.Category__c == 'Opportunity Renewal')
            activeResellerRenewAccountIds.add(config.Account_Id__c);
        }
    }

for (Opportunity o : newOppList) {
Account thisOppAccount = new Account();
if (o.AccountId != NULL && oppAccounts.containsKey(o.AccountId)) {
thisOppAccount = oppAccounts.get(o.AccountId);
o.Account_Owners_18_Digit_User_ID__c = oppAccounts.get(o.AccountId).ownerId;
//GTMS-6422: Updating the Partner fields on the Amendment opportunity based on the program type information populated on the customer account
if(o.SBQQ__AmendedContract__c!= null){
if(thisOppAccount.Latest_Partner_Account_Interaction__c != null){
        if(!cwRoboIds.contains(UserInfo.getUserId()) && thisOppAccount.Latest_Partner_Program_Interaction__c != null && thisOppAccount.Latest_Partner_Program_Interaction__c =='Resale')
        { // GTMS-8640, 8059
            
            if (
                !activeResellerAmendAccountIds.isEmpty() &&
                activeResellerAmendAccountIds.contains(thisOppAccount.Latest_Partner_Account_Interaction__c)
            ) {
                o.Reseller_Partner__c = thisOppAccount.Latest_Partner_Account_Interaction__c; //GTMS-27516 Only set Reseller_Partner__c if the account is in the active set retrieved from Reseller_Partner_Account_Config__mdt 
                o.Reseller__c = thisOppAccount.Latest_Partner_Account_Interaction__c; // GTMS-27654
            }
        } 
        else if(!cwRoboIds.contains(UserInfo.getUserId()) && thisOppAccount.Latest_Partner_Program_Interaction__c!= null &&
(thisOppAccount.Latest_Partner_Program_Interaction__c == 'Subsidy' || thisOppAccount.Latest_Partner_Program_Interaction__c =='Premium Discount')){
    o.Insurance_Partner__c = thisOppAccount.Latest_Partner_Account_Interaction__c;
}
/*** PARTNER RECORD TYPE PROJECT CHANGES: Commenting this code as the requirement for this change is temporarily onhold
else if(thisOppAccount.Latest_Partner_Program_Interaction__c!= null &&
(thisOppAccount.Latest_Partner_Program_Interaction__c == 'Paid Referral'|| thisOppAccount.Latest_Partner_Program_Interaction__c == 'Unpaid Referral') ){
if(crMap!=null && crMap.containsKey(thisOppAccount.Id)){
List<Channel_Relationship__c> crList = new List<Channel_Relationship__c>();
crList = crMap.get(thisOppAccount.Id);
System.debug(crList);
for(Channel_Relationship__c cr : crList){
Date crDate = cr.CreatedDate.Date();
if((cr.Program_Type__c == 'Paid Referral' || cr.Program_Type__c == 'Unpaid Referral')
&& crDate.daysBetween(Date.today()) < 365){
system.debug('cr: '+cr);
o.Referral_Partner__c = cr.Channel_Partner__c;
}
}
}
}*/
}
}
}
if(contractsMap.containsKey(o.SBQQ__AmendedContract__c)){
contract originalContract = contractsMap.get(o.SBQQ__AmendedContract__c);
//GTMS-7487-June22
if(!o.Is_Webstore_Upsell_Opportunity__c || (o.Account.Book_Of_Business__c == Null && o.Is_Webstore_Upsell_Opportunity__c)){
o.Payment_Terms__c = originalContract.SBQQ__Opportunity__r.Payment_Terms__c;
}
o.Shipping_Contact__c = originalContract.SBQQ__Opportunity__r.Shipping_Contact__c;
o.Approved_Discount__c = originalContract.SBQQ__Opportunity__r.Approved_Discount__c;
//o.Selected_Payment_Type__c = originalContract.SBQQ__Opportunity__r.Selected_Payment_Type__c;
o.Name = 'Amendment - '+ originalContract.Account.Name.Left(Integer.valueOf(System.Label.Opportunity_Account_Name_Limit)) + ' - ' + originalContract.ContractNumber;
//GTMS-10933
if(thisOppAccount.Account_Size_Segment__c == 'AE1'){
system.debug(' SBQQ__AmendedContract ' +o.SBQQ__AmendedContract__c);
system.debug(' Account_Size_Segment ' +thisOppAccount.Account_Size_Segment__c);
o.License_End_Date__c = originalContract.EndDate;
}
}
if(contractsMap.containsKey(o.SBQQ__RenewedContract__c)){
contract originalContract = contractsMap.get(o.SBQQ__RenewedContract__c);
//GTMS-7487-June22
if(!o.Is_Webstore_Upsell_Opportunity__c || (o.Account.Book_Of_Business__c == Null && o.Is_Webstore_Upsell_Opportunity__c)){
o.Payment_Terms__c = originalContract.SBQQ__Opportunity__r.Payment_Terms__c;
}
o.Shipping_Contact__c = originalContract.SBQQ__Opportunity__r.Shipping_Contact__c;
//o.Selected_Payment_Type__c = originalContract.SBQQ__Opportunity__r.Selected_Payment_Type__c;
o.Finance_Partner__c = originalContract.SBQQ__Opportunity__r.Finance_Partner__c;
o.Shipping_Address_NEW__c = originalContract.SBQQ__Opportunity__r.Shipping_Address_NEW__c;
o.Original_AE__c = originalContract.SBQQ__Opportunity__r.OwnerId;
o.Approved_Discount__c = originalContract.SBQQ__Opportunity__r.Approved_Discount__c;
o.Name = 'Renewal - '+ originalContract.Account.Name.Left(Integer.valueOf(System.Label.Opportunity_Account_Name_Limit)) + ' - ' + originalContract.ContractNumber;
//GTMS-12059 - Renewal Opportunity Close Date should be set to the day after the renewal contract end date
if(o.Renewal__c || o.SBQQ__Renewal__c){
o.CloseDate = originalContract.EndDate.addDays(1);
}
if(!cwRoboIds.contains(UserInfo.getUserId())){
if(!o.Renewal__c) {
o.Insurance_Partner__c = originalContract.SBQQ__Opportunity__r.Insurance_Partner__c; //.GTMS 8059
}
    if (
        !activeResellerRenewAccountIds.isEmpty() && originalContract.SBQQ__Opportunity__r.Reseller_Partner__c != null &&
        activeResellerRenewAccountIds.contains(originalContract.SBQQ__Opportunity__r.Reseller_Partner__c)
    ) {
        o.Reseller_Partner__c = originalContract.SBQQ__Opportunity__r.Reseller_Partner__c; //GTMS-27654 Only set Reseller_Partner__c if the account is in the active set retrieved from Reseller_Partner_Account_Config__mdt 
        o.Reseller__c = originalContract.SBQQ__Opportunity__r.Reseller__c; // GTMS-27654
    }
}
}
//GTMD 8640, 8059
if (!cwRoboIds.contains(UserInfo.getUserId()) && o.Type == 'Rebate' && o.Returning_Opportunity__r.Reseller_Partner__c != NULL) {
o.Reseller_Partner__c = o.Returning_Opportunity__r.Reseller_Partner__c;
}
// Code to populate the Shipping Address New on opportunity create
//Zakeer: added condition -- GTMS5381
if ((thisOppAccount.Shipping_Addresses__r.size() > 0) && ((String.valueOf(o.Type) == 'Revenue Opportunity') || (String.valueOf(o.Type) == 'Free Trial Opportunity') || (String.valueOf(o.Type) == 'Promo Opportunity')) && !cwRoboIds.contains(UserInfo.getUserId())){
Shipping_Address__c relatedShippingAddress = thisOppAccount.Shipping_Addresses__r;
if(o.Shipping_Address_NEW__c == null){
o.Shipping_Address_NEW__c = relatedShippingAddress.id;
}
if(String.valueOf(relatedShippingAddress.Shipping_Country__c) != String.valueOf(o.Shipping_Country__c)){
o.Shipping_Country__c = relatedShippingAddress.Shipping_Country__c;
}
HelperClass.setShippingDefaults(o, NULL, relatedShippingAddress.Shipping_Country__c);
}
//Clears out serial numbers on opportunities - @Tommy
if (o.All_Serial_Numbers__c != NULL) {
o.All_Serial_Numbers__c = NULL;
}
// Code to update VAT if it is available on the Account -@Harsha
// o.VAT_Number__c = thisOppAccount.VATId__c;
o.Shipping_Country__c = thisOppAccount.BillingCountry;
o.Shipping_State__c = thisOppAccount.BillingState;
if(o.Pricebook2Id == null && !Test.isRunningTest()){
o.Pricebook2Id = System.Label.Current_Active_Pricebook;
}
// GTMS-25293 Check if Account currency is 'MXN' and set Opportunity's CurrencyIsoCode
if (thisOppAccount.CurrencyIsoCode == 'MXN') {
if ( thisOppAccount.Owner.UserRole!=null && thisOppAccount.Owner.UserRole.Name.contains('MX') && thisOppAccount.Owner.UserRole.Name.contains('AE') &&  thisOppAccount.Owner.CurrencyIsoCode =='MXN')  {
o.CurrencyIsoCode = thisOppAccount.CurrencyIsoCode;
} else {
o.CurrencyIsoCode = 'USD';
    }
 }
configurationSegment = thisOppAccount.Segment__c != null && thisOppAccount.Segment__c.contains(System.Label.Account_Express_Segment) ? 'Express' : 'Non Express';
o.Configuration_Segment__c = configurationSegment;
if(o.Name.contains('Renewal') && o.SBQQ__RenewedContract__c != null && o.OwnerId != System.Label.Renewal_Pool_User){
o.OwnerId = System.Label.Renewal_Pool_User;
o.Renewal__c = TRUE;
}
//GTMS-8011
if(o.Name.toLowerCase().contains('renewal') && thisOppAccount.Renewal_AE__c != null){
o.OwnerId = thisOppAccount.Renewal_AE__c;
}
//GTMS-8352
if(o.type=='Rebate' && o.rebate_type__c=='Delinquent' && rebateOppByOwnerId != null && rebateOppByOwnerId.containsKey(o.Returning_Opportunity__c)){
o.ownerId = rebateOppByOwnerId.get(o.Returning_Opportunity__c);
system.debug('---Owner Id set in Before Insert --'+o.ownerId);
}
}
}
// GTMS-11894 - OrderTransformation : Extension Scenario
public void submitForTrialExtensionApproval(List<Opportunity> newOppList, Map<Id, Opportunity> oldOppMap) {
List<Approval.ProcessSubmitRequest> submitRequests = new List<Approval.ProcessSubmitRequest>();
system.debug('Reached here');
Set<Id> oppIds = new Set<Id>();
for (Opportunity opp : newOppList) {
if (opp.Free_Trial_Approval__c && !oldOppMap.get(opp.Id).Free_Trial_Approval__c) {
oppIds.add(opp.Id);
system.debug('line 622');
}
}
if (!oppIds.isEmpty()) {
for (Id oppId : oppIds) {
Approval.ProcessSubmitRequest req = new Approval.ProcessSubmitRequest();
system.debug('submitted for approval');
Id submitterId = UserInfo.getUserId();
system.debug('User Id'+submitterId);
req.setObjectId(oppId);
req.setSubmitterId(submitterId);
submitRequests.add(req);
}
if(submitRequests.size()>0 && !Test.isRunningTest()){
List<Approval.ProcessResult> results = Approval.process(submitRequests);
} else {
ApexPages.Message msg = new ApexPages.Message(ApexPages.Severity.INFO, 'No Approval process related to this Opportunity');
ApexPages.addMessage(msg);
}
}
}
public void updateContractDate(List<Opportunity> newOppList, Map<Id, Opportunity> oldOppMap) {
    Set<Id> oppIdsToUpdate = new Set<Id>();
    Map<Id, Integer> amendedContractTrialDiffs = new Map<Id, Integer>();

for (Opportunity opp : newOppList) {
        Opportunity oldOpp = oldOppMap.get(opp.Id);
        Boolean isTrialPeriodChanged = opp.Trial_Period__c != oldOpp.Trial_Period__c;
        Boolean isFreeTrialApproved = opp.Free_Trial_Extension_Status__c != oldOpp.Free_Trial_Extension_Status__c && opp.Free_Trial_Extension_Status__c == 'Approved';

        if (isFreeTrialApproved || isTrialPeriodChanged) {
            oppIdsToUpdate.add(opp.Id);
        }

        if (isTrialPeriodChanged && opp.SBQQ__AmendedContract__c != null) {
            Integer trialPeriodDiff = Integer.valueOf(opp.Trial_Period__c - oldOpp.Trial_Period__c);
            amendedContractTrialDiffs.put(opp.SBQQ__AmendedContract__c, trialPeriodDiff);
}
}

    if (!oppIdsToUpdate.isEmpty() || !amendedContractTrialDiffs.isEmpty()) {
        System.enqueueJob(new OpportunityAmendmentQueueable(JSON.serialize(amendedContractTrialDiffs), oppIdsToUpdate));
}
}
//GTMS -10938
public  void valueforSelectedPaymentType(List<Opportunity> newOppList) {
Set<Id> contractIds = new Set<Id>();
List<Opportunity> renewedOpps = new List<Opportunity>();
for(Opportunity opp : newOppList){
if(opp.SBQQ__Renewal__c == true && opp.SBQQ__RenewedContract__c <> null){
contractIds.add(opp.SBQQ__RenewedContract__c);
renewedOpps.add(opp);
}
}
Map<Id,Contract> conMap = new Map<Id,Contract>([SELECT Id, SBQQ__Opportunity__r.Selected_Payment_Type__c,SBQQ__RenewalOpportunity__r.Selected_Payment_Type__c FROM Contract WHERE ID IN : contractIds]);
Map<Id,Opportunity> amendOpps = new Map<Id,Opportunity>([SELECT Id, SBQQ__AmendedContract__c,Selected_Payment_Type__c FROM Opportunity WHERE SBQQ__AmendedContract__c IN : contractIds]);
Map<Id, Map<id, String>> amendedOppsForContracts = new Map<Id, Map<id, String>>();
for(Opportunity o : amendOpps.values()){
if(o.SBQQ__AmendedContract__c <> null && !amendedOppsForContracts.containsKey(o.SBQQ__AmendedContract__c)){
Map<id, string> amendOpPayment =  new Map<id, string>();
amendOpPayment.put(o.id,o.Selected_Payment_Type__c);
amendedOppsForContracts.put(o.SBQQ__AmendedContract__c, amendOpPayment);
}
else{
amendedOppsForContracts.get(o.SBQQ__AmendedContract__c).put(o.id, o.Selected_Payment_Type__c);
}
}
for(Opportunity opp : newOppList){
if(opp.SBQQ__Renewal__c == true && opp.SBQQ__RenewedContract__c <> null){
if(amendedOppsForContracts.containsKey(opp.SBQQ__RenewedContract__c)){
boolean isAmendOppPaymentDiffernt = false;
string strConOriginalOppPaymentType = '';
if(conMap.containsKey(opp.SBQQ__RenewedContract__c)){
strConOriginalOppPaymentType = (conMap.get(opp.SBQQ__RenewedContract__c)).SBQQ__Opportunity__r.Selected_Payment_Type__c;
}
for(String s : amendedOppsForContracts.get(opp.SBQQ__RenewedContract__c).values()){
if(strConOriginalOppPaymentType != s){
isAmendOppPaymentDiffernt = true;
break;
}
}
if(isAmendOppPaymentDiffernt){
opp.Selected_Payment_Type__c = 'Direct Annual';
}
else{
opp.Selected_Payment_Type__c = strConOriginalOppPaymentType;
}
}
else if(conMap.containsKey(opp.SBQQ__RenewedContract__c)){
opp.Selected_Payment_Type__c = (conMap.get(opp.SBQQ__RenewedContract__c)).SBQQ__Opportunity__r.Selected_Payment_Type__c;
}
}
}
}
// COMMENTS FOR OPTIMIZING THE CURRENT CODE
// 1. We can fsolidate similar conditions, for example if probability <= 95
// * 03/04/2021 Ron (GTMS-2878) Annual Payments no longer trigger payment processing fee
    public void beforeInsertOrUpdate(List<Opportunity> newOppList, Map<Id, Opportunity> oldOppMap,Map<Id, Opportunity> newOppMap) {
loadOppAccounts(newOppList);
loadOppFields(newOppList);
Set<Id> contractIds = new Set<Id>();
//Map<Id, Contract> contractsMap = new Map<Id, Contract>();
Opportunity oldOpportunity = new Opportunity();
Set<Id> opportunityIds = new Set<Id>();
Map<Id, Opportunity> oppsToUpdate = new Map<Id, Opportunity>();
Set<Id> shippingAddressIds = new Set<Id>();
String shippingAndHandlingTaxLocations = System.Label.Shipping_and_Handling_Tax;
Boolean changeAddressQueryFlag = false;
String configurationSegment;
Set<Id> ownerIds = new Set<Id>();
Map<Id, Opportunity> opptyWithOwnerRoleMap = new Map<Id, Opportunity>();
Map<String, Object> flowParams = new Map<String, Object>();
Set<String> opptyStagesForOwnerRole = new Set<String>{'Incubate', 'Qualified', 'Trial', 'Proposal', 'Decision', 'Purchase' , 'Closing' , 'Return Created', 'Return Initiated','Return Label Sent','Products Processing','Finance Processing'};
//GTMS-8640, 8059
List<String> cwRoboIds = System.Label.Corpweb_SFDC_Robot.split(',');
//GTMS-9601
List<String> profileIdsForHwAG4ValdiationRule = System.Label.HWAG4ProductLineProfiles.split(',');
String HWAG4ValidationErrorMsg = System.Label.HWAG4ProductLineValidationErrorMsg;
List<String> returnOppTypes = System.Label.Return_Opportunity_Types.split(','); //GTMS-10297
//Groundswell - Nilesh Jain : Workflow Changes
//GTMS-10997
Map<String, String> mapCanadaState = getCanadaShipFrom();
Set<Id> oppIds = new Set<Id>();
// Query any related contract end dates
setOpportunityTypeForFreeTrials(newOppList);
for (Opportunity o : newOppList) {

if(oldOppMap != null && o.StageName != oldOppMap.get(o.Id).StageName && o.StageName == 'Closing') {
oppIds.add(o.Id);
}
//GTMS-23000
if (o.SBQQ__RenewedContract__c != null){
contractIds.add(o.SBQQ__RenewedContract__c);
}
//added condition for GTMS-10997
if(o.Shipping_State__c != null && mapCanadaState.containsKey(o.Shipping_State__c) && o.Shipping_Country__c == 'Canada' &&
o.Type == 'Promo Opportunity' && o.StageName == 'Orders Processing') {
//o.Ship_From_Location__c = mapCanadaState.get(o.Shipping_State__c); GTMS-28141 -- ABU --> 06262025
o.Shipping_Carrier__c = 'UPS';
//o.Shipping_Method__c = 'Ground'; GTMS-28141 -- ABU --> 06262025
}
//update for GTMS-22807
if (o.StageName == 'Incubate' && (oldOppMap == null || oldOppMap.get(o.Id).StageName != 'Incubate')) {
    o.Went_To_Incubate_Date__c = Datetime.Now();
    o.Went_To_Incubate__c = TRUE;
    } else if (o.StageName == 'Qualified' && (oldOppMap == null || oldOppMap.get(o.Id).StageName != 'Qualified')) {
    o.Went_To_Qualified_Date__c = Datetime.Now();
    o.Went_To_Qualified__c = TRUE;
    } else if (o.StageName == 'Trial' && (oldOppMap == null || oldOppMap.get(o.Id).StageName != 'Trial')) {
    o.Went_To_Trial_Date__c = Datetime.Now();
    o.Went_To_Trial__c = TRUE;
    } else if (o.StageName == 'Proposal' && (oldOppMap == null || oldOppMap.get(o.Id).StageName != 'Proposal')) {
    o.Went_To_Proposal_Date__c = Datetime.Now();
    o.Went_To_Proposal__c = TRUE;
    } else if (o.StageName == 'Decision' && (oldOppMap == null || oldOppMap.get(o.Id).StageName != 'Decision')) {
    o.Went_To_Decision_Date__c = Datetime.Now();
    o.Went_To_Decision__c = TRUE;
    } else if (o.StageName == 'Purchase' && (oldOppMap == null || oldOppMap.get(o.Id).StageName != 'Purchase')) {
    o.Went_To_Purchase_Date__c = Datetime.Now();
    o.Went_To_Purchase__c = TRUE;
    } else if (o.StageName == 'Closing' && (oldOppMap == null || oldOppMap.get(o.Id).StageName != 'Closing')) {
    o.Went_To_Closing_Date__c = Datetime.Now();
    o.Went_To_Closing__c = TRUE;
    } else if (o.StageName == 'Orders Processing' && (oldOppMap == null || oldOppMap.get(o.Id).StageName != 'Orders Processing')) {
    o.Went_to_Orders_Processing_Date__c = Datetime.Now();
    o.Went_to_Orders_Processing__c = TRUE;
    if (!(o.Type == 'Revenue Opportunity' && o.SBQQ__Renewal__c == true) && o.CloseDate != Date.today()){
    o.CloseDate = Date.today();
    }
    } else if (o.StageName == 'Ready To Ship' && (oldOppMap == null || oldOppMap.get(o.Id).StageName != 'Ready To Ship')) {
    o.Went_To_Ready_To_Ship_Date__c = Datetime.Now();
    o.Went_To_Ready_To_Ship__c = TRUE;
    } else if (o.StageName == 'Closed Won' && (oldOppMap == null || oldOppMap.get(o.Id).StageName != 'Closed Won')) {
    o.Went_To_Closed_Won_Date__c = Datetime.Now();
    o.Went_To_Closed_Won__c = TRUE;
    }
//GTMS-21691
if((oldOppMap != null && HelperClass.isChanged(o, oldOpportunity, Schema.Opportunity.Probability)) &&oppFields.Containskey(o.id) &&oppFields.get(o.Id).opportunityLineItems != null && !(o.SE_Key_Account__c)){
o.SE_Key_Account_Override__c = KeyAccountEligible(oppFields.get(o.Id).opportunityLineItems);
}
// added for GTMS-16051
if (o.Insurance_Partner__c != null &&  (((oldOppMap == null || (oldOppMap != null && oldOppMap.get(o.Id) == null)) && o.LOI_Status__c =='Sent')
                || (oldOppMap != null && (oldOppMap.get(o.Id) != null && oldOppMap.get(o.Id).LOI_Status__c != o.LOI_Status__c) && o.LOI_Status__c =='Sent')))
{
o.SCL_Status_Sent_Date__c = system.now();
}
// added for GTMS-20208
if (o.VAT_Number__c != null && o.VAT_Number__c.contains(' ')) {
o.VAT_Number__c =  o.VAT_Number__c.replaceAll('\\s+', '');
}
//GTMS-9601
if(Trigger.isBefore && Trigger.isUpdate && oldOppMap != null &&
oppFields.containsKey(o.Id) && oppFields.get(o.Id).opportunityLineItems != null){
Boolean isError = validateOppForHWProducts(oppFields.get(o.Id).opportunityLineItems, o,
                            oldOppMap, profileIdsForHwAG4ValdiationRule, returnOppTypes );
if(isError){
o.addError(HWAG4ValidationErrorMsg);
}
}
//GTMS-13685             (o.Renewal__c || o.SBQQ__Renewal__c) &&
if (Trigger.isBefore && Trigger.isUpdate &&
!System.Label.SkipCotermContractValidationProfileIDs.contains(UserInfo.getProfileId()) &&
o.Probability>=75 &&
oppFields.containsKey(o.Id) &&
oppFields.get(o.Id).SBQQ__PrimaryQuote__c!=null &&
oppFields.get(o.Id).SBQQ__PrimaryQuote__r.Co_Term_Contract__c!=null &&
oppFields.get(o.Id).SBQQ__PrimaryQuote__r.Co_Term_Contract__r.EndDate!=null &&
o.CloseDate.daysBetween(oppFields.get(o.Id).SBQQ__PrimaryQuote__r.Co_Term_Contract__r.EndDate)<=30){
o.addError('Co-term Contract on primary Quote will expire in 30 days when the opportunity will close. Please change/remove co-term Contract on primary quote or change close date on opportunity.');
}
/*
//GTMS-7702
if ((o.Shipping_and_Handling_Amount__c == 99999 || o.Total_Weight_oz__c > 2500) && (o.StageName == 'Purchase' && o.Probability == 90))
{
system.debug('RODRIGO send email');
o.Shipping_Carrier__c = 'FEDEX FREIGHT';
o.Shipping_Method__c = 'ECONOMY';
}  */
//GTMS-7702
if (o.Shipping_Address_NEW__c != null) {
shippingAddressIds.add(o.Shipping_Address_NEW__c);
if (!HelperClass.opportunityShippingAddresses.isEmpty() && !HelperClass.opportunityShippingAddresses.containsKey(o.Shipping_Address_NEW__c)) {
changeAddressQueryFlag = true;
}
}
//GTMS-6450
if(o.AccountId <> null)
accountIdSet.add(o.AccountId);
//GTMS-13490 --Start : to add referral rebate value based referral partner account.
if(trigger.isBefore){
if(trigger.isInsert){
o.Referral_Rebate__c = o.Referral_partner__c != null ? oppAccounts.get(o.Referral_Partner__c) != null ?  oppAccounts.get(o.Referral_Partner__c).Referral_Rebate__c : null : null;
}else if(trigger.isUpdate){
o.Referral_Rebate__c = oldOppMap.get(o.Id).Referral_partner__c !=  o.Referral_Partner__c ? oppAccounts.get(o.Referral_Partner__c) != null ?  oppAccounts.get(o.Referral_Partner__c).Referral_Rebate__c : null : oppAccounts.get(o.Referral_Partner__c) != null ? oppAccounts.get(o.Referral_Partner__c).Referral_Rebate__c : o.Referral_Rebate__c;
}
}
//GTMS-13490 -- End
//GTMS-25658
Id opptyReturnRecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('Return_Opportunity').getRecordTypeId();

 if (o.RecordTypeId == opptyReturnRecordTypeId) {
     if (o.Shipping_Country__c == 'United States') {
         o.Shipmate_Service_Type__c = 'ups_ground';
     } else if (o.Shipping_Country__c == 'Canada') {
         o.Shipmate_Service_Type__c = 'ups_worldwide_express';
     } else if (o.Shipping_Country__c == 'Mexico') {
         o.Shipmate_Service_Type__c = 'ups_worldwide_saver';
     } else if (o.Shipping_Country__c != null && System.label.EMEA_Countries.Contains(o.Shipping_Country__c)) {
         o.Shipmate_Service_Type__c = 'ups_standard';
     } 
 }

			//Added for GTMS-28039
			if(o.SBQQ__RenewedContract__c != null && o.Probability < 95 && o.stageName != 'Closed Lost' && o.CloseDate != null && o.CloseDate >= Date.valueOf(System.Label.Checkout_Link_For_Renewal_Go_Live_Date) && o.SBQQ__PrimaryQuote__c != null){
    			Account relatedAccount = (oppAccounts != null && oppAccounts.containsKey(o.AccountId)) ? oppAccounts.get(o.AccountId) : null;
    			Opportunity oppWithFields = (oppFields != null && oppFields.containsKey(o.Id)) ? oppFields.get(o.Id) : null;
                if(relatedAccount != null && oppWithFields != null){
                    setRenewalCheckoutAgreementLink(o, relatedAccount, oppWithFields);
                }
    			
			}
}
//GTMS-28039 End
//End
if(oppIds.size() > 0) {
for(Opportunity opp : [SELECT Id, AccountId, Amount, Type, StageName, Returning_Opportunity__r.Owner_Role_Copy__c, Configuration_Segment__c, TrialResolutionOppty__c,
Pricebook2.Name, Pricebook2Id, CurrencyISOCode, Owner.UserRole.Name, Owner.Manager.Name,Owner.Manager.Manager.Manager.Name, Owner.Manager.Manager.Manager.UserRole.Name, Ship_From_Location__c,
SBQQ__PrimaryQuote__c, SBQQ__PrimaryQuote__r.Co_Term_Contract__c,SBQQ__PrimaryQuote__r.Co_Term_Contract__r.EndDate
FROM Opportunity
WHERE TrialResolutionOppty__c IN :oppIds
]) {
    trialOppFields.put(opp.TrialResolutionOppty__c, opp);
}
}
//GTMS-23000
if(contractIds.size()>0 && (contractsMap == null || contractsMap.size() <= 0)){
loadContracts(contractIds);
}
if ((shippingAddressIds.size() > 0) && (HelperClass.opportunityShippingAddresses.isEmpty() || changeAddressQueryFlag)) {
HelperClass.opportunityShippingAddresses = HelperClass.getShippingData(shippingAddressIds);
}
Org_Setting__mdt otLaunchSetting = Org_Setting__mdt.getInstance('OTLaunchDate');
for (Opportunity vOpportunity : newOppList) {
if(trialOppFields.containsKey(vOpportunity.Id) && vOpportunity.CreatedDate >= Date.valueOf(otLaunchSetting.Value__c)) {
vOpportunity.addError('This revenue opportunity is associated with a Free Trial. Please complete the free trial decision flow before moving this to closing.');
}
if(vOpportunity.Id != null){
opportunityIds.add(vOpportunity.Id);
}else if(vOpportunity.Returning_Opportunity__c != null){
opportunityIds.add(vOpportunity.Returning_Opportunity__c);
}
if (oldOppMap != null) {
oldOpportunity = oldOppMap.get(vOpportunity.Id);
}
if(vOpportunity.OwnerId != null){
ownerIds.add(vOpportunity.OwnerId);
//WF Rule - Copy Owner Role
if((opptyStagesForOwnerRole.contains(vOpportunity.StageName) || (vOpportunity.Owner_Role_Copy__c == null)) && (vOpportunity.Rebate_Type__c != 'Partner Referral' || vOpportunity.Rebate_Type__c != 'Co-Term Credit')
){
opptyWithOwnerRoleMap.put(vOpportunity.OwnerId,vOpportunity);
}
}
}
Map<Id, Opportunity> opportunitiesDataByIds = queryOpportunities(opportunityIds);
    if(oldOppMap != null) {
            RebateLogicHandler.updateQuoteFieldsDealComp(newOppMap, opportunitiesDataByIds);//GTMS-27273
        }
//GTMS-15132
Map<String,Id> gvLabelUserId = new Map<String,Id>();
Map<String,Global_Variable__mdt>  globalVariables = Global_Variable__mdt.getall();
if(globalVariables != null){
for(Global_Variable__mdt gv:globalVariables.values()){
if(gv.DeveloperName.startsWith('Rebate_')){
gvLabelUserId.put(gv.Label, gv.Value__c);
    ownerIds.add(gv.Value__c);
}
}
}
if(ownerIds != null && ownerIds.size() > 0){
ownerIds.add(Label.Clickpath_Opportunity_Won_User_Id); //Flavio:GTMS:6105-Mar2022
getOpptyOwner(ownerIds);
system.debug('$$$$$$$ownerIds=====> ' + ownerIds);
}    
        ShippingHandlingCalculations.getShippingConfigurations(); // GTMS-28236 Rodrigo
for (Opportunity o : newOppList) {
//DCA Code Start
if(o.IsClosed==false){
o.DCA_Enabled__c=getDCAEnabled(o);
}
//DCA Code End
if (oldOppMap != null) {
oldOpportunity = oldOppMap.get(o.Id);
}
/*Merge conflict Issue */
if(oppAccounts != Null && oppAccounts.containsKey(o.AccountId)) {
if(o.Type == 'Revenue Opportunity' && o.RecordTypeId == opportunityRevRecordTypeId && oppAccounts.get(o.AccountId).Segment__c != 'AE1') {
//GTMS-17232
if(oppAccounts.get(o.Finance_Partner__c) != null && ((trigger.isInsert && o.Finance_Partner__c != Null)
                                        || (trigger.isUpdate && trigger.isBefore && oldOpportunity != Null && oldOpportunity.Finance_Partner__c != o.Finance_Partner__c))) {
                                            o.Payment_Terms__c = oppAccounts.get(o.Finance_Partner__c).Payment_Terms__c;
                                            o.Internal_Finance_Payment_Type__c = oppAccounts.get(o.Finance_Partner__c).Approved_Payment_Type__c;
                                        }
else if(oppAccounts.get(o.Reseller__c) != null && ((trigger.isInsert && o.Reseller__c != Null) || (trigger.isUpdate && trigger.isBefore && oldOpportunity != Null && oldOpportunity.Reseller__c != o.Reseller__c))) {
                                    o.Payment_Terms__c = oppAccounts.get(o.Reseller__c).Payment_Terms__c != null ? oppAccounts.get(o.Reseller__c).Payment_Terms__c : 'Net 30';//Net 30 added as part of GTMS-26451 If payment terms on reseller are blank need to populate default value as Net 30;
                                        o.Internal_Finance_Payment_Type__c = oppAccounts.get(o.Reseller__c).Approved_Payment_Type__c;
                                    }
else if(oppAccounts.get(o.Insurance_Partner__c) != null && ((trigger.isInsert && o.Insurance_Partner__c != Null)  || (trigger.isUpdate && trigger.isBefore && oldOpportunity != Null && oldOpportunity.Insurance_Partner__c != o.Insurance_Partner__c))) {
                                                o.Payment_Terms__c = oppAccounts.get(o.Insurance_Partner__c).Payment_Terms__c;
                                                o.Internal_Finance_Payment_Type__c = oppAccounts.get(o.Insurance_Partner__c).Approved_Payment_Type__c;
                                            }
else if(trigger.isInsert && oppAccounts.get(o.Insurance_Partner__c) == null && oppAccounts.get(o.Reseller__c) == null && oppAccounts.get(o.Finance_Partner__c) == null && ( o.Payment_Terms__c == null || o.Internal_Finance_Payment_Type__c == null)) {
if(oppAccounts.get(o.AccountId) != null) {
if(String.isNotBlank(oppAccounts.get(o.AccountId).Payment_Terms__c)) {
o.Payment_Terms__c = oppAccounts.get(o.AccountId).Payment_Terms__c;
}
if(String.isNotBlank(oppAccounts.get(o.AccountId).Approved_Payment_Type__c)) {
o.Internal_Finance_Payment_Type__c = oppAccounts.get(o.AccountId).Approved_Payment_Type__c;
}
}
}
if(trigger.isInsert && String.isNotBlank(o.Payment_Terms__c)) {
o.Initial_Payment_Terms__c = o.Payment_Terms__c;
}
//GTMS-17232
}
//GTMS-24282
if(o.Type == 'Revenue Opportunity' && o.RecordTypeId == opportunityRevRecordTypeId && o.SBQQ__AmendedContract__c != null && Trigger.isInsert && String.isNotBlank(o.Payment_Terms__c) && oppAccounts.get(o.AccountId).Segment__c == 'AE1'){
o.Initial_Payment_Terms__c = o.Payment_Terms__c;
}
}
//GTMS-12823
if(Trigger.isUpdate && opportunitiesDataByIds <> NULL && opportunitiesDataByIds.get(o.Id).SBQQ__PrimaryQuote__c <> NULL){
if((o.SBQQ__AmendedContract__c == NULL && opportunitiesDataByIds.get(o.Id).SBQQ__PrimaryQuote__r.sbqq__mastercontract__c <> NULL) ||
(o.SBQQ__AmendedContract__c <> NULL && opportunitiesDataByIds.get(o.Id).SBQQ__PrimaryQuote__r.sbqq__mastercontract__c == NULL) ||
(o.SBQQ__AmendedContract__c <> NULL && opportunitiesDataByIds.get(o.Id).SBQQ__PrimaryQuote__r.sbqq__mastercontract__c <> NULL && o.SBQQ__AmendedContract__c <> opportunitiesDataByIds.get(o.Id).SBQQ__PrimaryQuote__r.sbqq__mastercontract__c)){
o.SBQQ__AmendedContract__c = opportunitiesDataByIds.get(o.Id).SBQQ__PrimaryQuote__r.sbqq__mastercontract__c;
}
}
//Satya: GTMS-6110 Apr 29 2022
if(o.Type == 'Revenue Opportunity' && oldOpportunity.StageName != o.StageName && o.SBQQ__Contracted__c && o.StageName == 'Closed Won' && o.SBQQ__AmendedContract__c != null && !opportunitiesDataByIds.get(o.Id).SBQQ__AmendedContract__r.SBQQ__RenewalQuoted__c && !isRecursion) {
flowParams.put('contractId', o.SBQQ__AmendedContract__c);
Flow.Interview.Send_Email_on_Closed_Amendment_Opp email = new Flow.Interview.Send_Email_on_Closed_Amendment_Opp(flowParams);
email.start();
isRecursion = true;
}
            // GTMS-22650    
            Boolean isAutoRenewal = false;
            if(contractsMap != Null && contractsMap.containsKey(o.SBQQ__RenewedContract__c)){
                isAutoRenewal = contractsMap.get(o.SBQQ__RenewedContract__c).Auto_Renewal__c;
            }
//Flavio:GTMS:6105-Mar2022
if(o.Type == 'Revenue Opportunity'
               && (o.Sub_Type__c == 'Clickpath' || isAutoRenewal)
&& o.Renewal__c
    && !(oppAccounts.containsKey(o.AccountId) && oppAccounts.get(o.AccountId).Customer_require_PO_for_invoicing__c == 'Yes' && (o.PO_Number__c == '-' || o.PO_Number__c == '' || o.PO_Number__c == null))
&& (oldOpportunity != null && oldOpportunity.Id != null)
&& (o.Express_Agreement_Accepted_Date__c != null && oldOpportunity.Express_Agreement_Accepted_Date__c != o.Express_Agreement_Accepted_Date__c)
&& (o.SBQQ__RenewedContract__c != NULL || o.SBQQ__AmendedContract__c != NULL)){
o.StageName = 'Orders Processing';
if (o.CloseDate > System.today()){
o.Adjust_License_Start_Date__c = true;
o.License_Start_Date__c = o.CloseDate;
}
//GTMS-23000
updateOpptyFromContractUsingWASD(o, contractsMap);
if (o.OwnerId == Id.valueOf(Label.Renewal_Pool_User) && mapUsers.containsKey(Label.Clickpath_Opportunity_Won_User_Id) && mapUsers.get(Label.Clickpath_Opportunity_Won_User_Id).IsActive){
o.OwnerId = Id.valueOf(Label.Clickpath_Opportunity_Won_User_Id);
}
}
//Zakeer: GTMS-4675-Dec-16
if(o.Adjust_License_Start_Date__c && o.StageName == 'Closed Won'){
o.CloseDate = o.License_Start_Date__c;
}
//workflow
if (o.Probability > 0 && o.Qualified_Date__c == null && o.Type == 'Revenue Opportunity') {
o.Qualified_Date__c = System.now();
}
Account thisOppAccount = new Account();
if (o.AccountId != NULL && oppAccounts.containsKey(o.AccountId)) {
thisOppAccount = oppAccounts.get(o.AccountId);
}
//GTMS-14333
If(thisOppAccount != null && thisOppAccount.Segment__c != Null && !Trigger.IsUpdate && !thisOppAccount.Segment__c.contains('AE1')) {
o.Selected_Payment_Type__c = thisOppAccount.Approved_Payment_Type__c;
o.Internal_Finance_Payment_Type__c = thisOppAccount.Approved_Payment_Type__c;
}
if (o.isClosed == FALSE) {
if(HelperClass.isChanged(o, oldOpportunity, Schema.Opportunity.OwnerId)){
configurationSegment = thisOppAccount.Segment__c != null && thisOppAccount.Segment__c.contains(System.Label.Account_Express_Segment) ? 'Express' : 'Non Express';
o.Configuration_Segment__c = configurationSegment;
}
// Logic to update FP & Upsell for Buyouts & Subsidy
if((o.Amount != NULL && o.License_Term__c != NULL && o.License_Term__c != 0  && o.Rebate_Type__c != NULL && o.Type != NULL) && System.Label.Rebate.contains(o.Type) && (oldOppMap == null || oldOpportunity.Amount != o.Amount || o.License_Term__c != oldOpportunity.License_Term__c)
&& (System.Label.Buyout.contains(o.Rebate_Type__c) || System.Label.Subsidy.contains(o.Rebate_Type__c) || System.Label.Partner_Referral.contains(o.Rebate_Type__c) || System.Label.Delinquent.contains(o.Rebate_Type__c) || System.Label.Non_Commissionable_SKU.contains(o.Rebate_Type__c))){
if(o.Owner_Role_Copy__c != NULL && o.Owner_Role_Copy__c.contains(System.Label.Renewal)){
o.Renewal_ACV__c = o.Amount / (o.License_Term__c /12);
}
else{
o.FP_and_Upsell_ACV__c = o.Amount / (o.License_Term__c /12);
}
}
if (HelperClass.isChanged(o, oldOpportunity, Schema.Opportunity.VAT_Validation_Status__c) &&
o.VAT_Validation_Status__c == 'Verified' &&
thisOppAccount.VAT_Validation_Status__c != 'Verified' &&
o.VAT_Number__c != null) {
thisOppAccount.VATId__c = o.VAT_Number__c;
thisOppAccount.VAT_Validation_Status__c = o.VAT_Validation_Status__c;
DMLWrapper.doUpdate(thisOppAccount, new List<SObjectField>{
Account.VATId__c, Account.VAT_Validation_Status__c
});
}
// Need to make sure variables are set properly for the commissionable dollars field to work, at least until we run a mass update on historical closed won opps so we can change that formula field)
// For new internal financing, just uncomment the line below and delete the if(o.internal_finance__c = 'approved') part.
o.Internal_Finance__c = 'Approved';
if (o.Selected_Payment_Type__c == 'Direct Monthly') {
o.Direct_Monthly__c = TRUE;
o.Direct_Annual__c = FALSE;
o.Direct_Quarterly__c = FALSE;
} else if (o.Selected_Payment_Type__c == 'Direct Quarterly') {
//GTMS-13035 - DirectQuarterly
o.Direct_Quarterly__c = TRUE;
o.Direct_Monthly__c = FALSE;
o.Direct_Annual__c = FALSE;
} else if (o.Selected_Payment_Type__c == 'Direct Annual') {
o.Direct_Monthly__c = FALSE;
o.Direct_Quarterly__c = FALSE;
o.Direct_Annual__c = TRUE;
} else {
o.Direct_Monthly__c = FALSE;
o.Direct_Annual__c = FALSE;
o.Direct_Quarterly__c = FALSE;
}
if (o.Probability < 98) {
o.ACV_Commissionable_Dollars_Copy__c = o.ACV_Commissionable_Dollars__c;
}
}
// Stamp ACV Bookings Copy
if (o.ACV_Bookings_Copy__c != o.ACV_Bookings_SOT__c && o.CloseDate >= Date.valueOf(SYSTEM.Label.Annualize_ACV_Date)) {
o.ACV_Bookings_Copy__c = o.ACV_Bookings_SOT__c;
}
// Stamp finance approved amount, if necessary
if (o.Probability >= 95 && o.Finance_Approved_Amount_Stamp__c == NULL) {
o.Finance_Approved_Amount_Stamp__c = o.Amount;
}
if (o.Small_Fleet_Opportunity__c == TRUE && o.Express_Annual_Discount__c > 0 && o.StageName !='Closed Won') {
o.Express_Annual_Discount__c = 0;
}
if (o.Small_Fleet_Opportunity__c == TRUE && o.Express_Upfront_Discount__c > 0 && o.StageName !='Closed Won') {
o.Express_Upfront_Discount__c = 0;
}
//Satya-GTMS-5905
if (o.Price_Book_Name__c <> null && o.StageName !='Closed Won') {
if (o.Configuration_Segment__c == 'Express' && !o.Small_Fleet_Opportunity__c ) {
o.Express_Upfront_Discount__c = 15;
o.Express_Annual_Discount__c = 10;
}
if(o.Configuration_Segment__c == 'Express' && (thisOppAccount.Number_of_Vehicles__c != NULL && thisOppAccount.Number_of_Vehicles__c < 11) && (o.AG2_License_Count__c + o.AG4_License_Count__c) < 31 ||
(o.Configuration_Segment__c == 'Express' && (o.CM1_License_Count__c + o.CM2_License_Count__c) == 0 && o.VG_License_Count__c == 0 && (o.AG2_License_Count__c + o.AG4_License_Count__c) < 31)) {
o.Express_Upfront_Discount__c = 0;
o.Express_Annual_Discount__c = 0;
}
}
if (o.Type == 'Revenue Opportunity' && o.IsWon == TRUE && o.Amount > 0) {
if (thisOppAccount.First_Purchase_Value__c == NULL) {
thisOppAccount.First_Purchase_Value__c = o.Amount;
DMLWrapper.doUpdate(thisOppAccount, new List<SObjectField>{
Account.First_Purchase_Value__c
});
}
}
Opportunity vOpportunity = new Opportunity();
if(o.Id != null){
vOpportunity = opportunitiesDataByIds.get(o.Id);
}else if(o.Returning_Opportunity__c != null){
vOpportunity = opportunitiesDataByIds.get(o.Returning_Opportunity__c);
}else if(o.Id == null){
    vOpportunity = o;
}    

      //added by KrishnaRao GTMS-25417
     Id recordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Return Opportunity').getRecordTypeId();
if (vOpportunity != null && o.Id == null) {
    if ((vOpportunity.Rebate_Type__c != 'Partner Referral'
            && vOpportunity.Rebate_Type__c != 'Renewal Credit'
            )
            || vOpportunity.Overwrite_Validation_Rule__c) {
        o.Owner_Manager_Name_Copy__c = (Id) managerFormula(o, vOpportunity, 'Manager Name');
        o.Owner_Manager_Role_Copy__c = (String) managerFormula(o, vOpportunity, 'Manager Role');
        o.Owner_Director_Name_Copy__c = (Id) managerFormula(o, vOpportunity, 'Director Name');
        o.Owner_Manager_Email_Copy__c = (String) managerFormula(o, vOpportunity, 'Manager Email');
    }
}
if (vOpportunity != null && o.Id != null) {
if (vOpportunity.Type == 'Rebate') {
if(vOpportunity.Rebate_Type__c != null && System.Label.Rebate_Close_Date.contains(vOpportunity.Rebate_Type__c) && vOpportunity.StageName == 'Refunded - Closed'){
o.CloseDate = vOpportunity.Returning_Opportunity__r.CloseDate;
}
//GTMD-8640, 8059
if (!cwRoboIds.contains(UserInfo.getUserId()) && vOpportunity.Returning_Opportunity__r.Referral_Partner__c != null) {
    o.Referral_Partner__c = o.Referral_Partner__c != null ? o.Referral_Partner__c : vOpportunity.Returning_Opportunity__r.Referral_Partner__c;
//GTMS-13490==START
o.Referral_Rebate__c = vOpportunity.Returning_Opportunity__r.Referral_Partner__r.Referral_Rebate__c;
//GTMS-13490==END
}
//GTMS-8640, 8059
if (!cwRoboIds.contains(UserInfo.getUserId()) && vOpportunity.Returning_Opportunity__r.Insurance_Partner__c != null) {
o.Insurance_Partner__c = vOpportunity.Returning_Opportunity__r.Insurance_Partner__c;
}
}
//GTMS-15132
if (((o.Type == 'Rebate' && o.Rebate_Type__c == 'Delinquent' ) || o.Type == 'Remorse Refund')
&& o.StageName == 'Refunded - Closed'
&& (o.Returning_Opportunity__r == null || vOpportunity.Returning_Opportunity__r.Owner.Name != 'Samsara Small Fleets')
&& o.Delinquent_Return_Past_180_Days__c){
if(vOpportunity.Returning_Opportunity__c != null && vOpportunity.Returning_Opportunity__r.Owner.UserRole.Name.Contains('Renewal')){
o.OwnerId = gvLabelUserId.get('Renewal');
}
                        else if(vOpportunity.Returning_Opportunity__c != null && vOpportunity.Returning_Opportunity__r.Owner.UserRole.Name.Contains('EMEA')){
o.OwnerId = gvLabelUserId.get('EMEA');
}
                        else if(vOpportunity.Returning_Opportunity__c != null && vOpportunity.Returning_Opportunity__r.Owner.UserRole.Name.Contains('ENT')){
o.OwnerId = gvLabelUserId.get('ENT');
}
                        else if(vOpportunity.Returning_Opportunity__c != null && vOpportunity.Returning_Opportunity__r.Owner.UserRole.Name.Contains('Fleet IS')){
o.OwnerId = gvLabelUserId.get('Fleet IS');
}
else{
o.OwnerId = gvLabelUserId.get('Default');
}
}
//Zakeer: added IF condition -- GTMS5381
/* Replaces Node 'Shipping Country is Canada or Mexico' */
if (o.Shipping_Address_NEW__c != null && o.Type != 'Free Trial Opportunity'){
string ShippingCountry = HelperClass.opportunityShippingAddresses.get(o.Shipping_Address_NEW__c).Shipping_Country__c;
if ((o.Shipping_Address_NEW__c != oldOppMap.get(o.Id).Shipping_Address_NEW__c || o.Shipping_Country__c != ShippingCountry || o.IsClone()) && !cwRoboIds.contains(UserInfo.getUserId())) {
if(o.Shipping_Country__c != ShippingCountry){
o.Shipping_Country__c = ShippingCountry;
}
HelperClass.setShippingDefaults(o, NULL, shippingCountry);
}
}
if (vOpportunity.Shipping_Address_NEW__r.Shipping_Country__c == 'Canada'
&& vOpportunity.Probability <= 95
&& (vOpportunity.Shipping_Country__c != 'Canada')) {
o.Shipping_Country__c = 'Canada';
o.Shipping_Method__c = 'Ground';
}
if(HelperClass.isChanged(o, oldOpportunity, Schema.Opportunity.Product_Count__c)
&& o.Product_Count__c > oldOpportunity.Product_Count__c
&& oldOpportunity.StageName == 'Incubate'){
o.StageName = 'Qualified';
}
/* Sonal: Changed on 9th April, 2020 Replaces Node 'Express Amount Agreed To' */
if (o.Express_Agreement_Accepted_Date__c != null) {
o.Contract_Amount_Agreed_To__c = vOpportunity.Amount;
}
/* Replaces Node 'Express Discount is Added to Blended Discount' */
//TODO - Ensure that we stamp the Discount Approval Needed
// Anil Bogadi - GTMS-4994
if (((vOpportunity.Selected_Payment_Type__c <> null && (vOpportunity.Selected_Payment_Type__c == 'Direct Annual' || vOpportunity.Selected_Payment_Type__c == 'Upfront Payments'))
|| (vOpportunity.SBQQ__PrimaryQuote__c <> null && vOpportunity.SBQQ__PrimaryQuote__r.ApprovalStatus__c == 'Approved'))
&& vOpportunity.Pricebook2.Name <> null && vOpportunity.Configuration_Segment__c == 'Express' && vOpportunity.CPQ_Opportunity__c == true ) {
if(vOpportunity.Blended_Discount__c !=  oldOpportunity.Blended_Discount__c){
o.Approved_Discount__c = vOpportunity.Blended_Discount__c + 0.1;
}
o.Discount_Approval_Status__c = 'Approved';
}
/* Replaces Node 'New Billing Process Approval' */
if ((vOpportunity.Price_Book_Name__c != null
&& vOpportunity.Configuration_Segment__c == 'Express')
&& vOpportunity.Payment_Token__c != null && vOpportunity.Probability >= 98 && !vOpportunity.IsClosed && !vOpportunity.Account.New_Billing_Process_Approved__c) {
thisOppAccount.New_Billing_Process_Approved__c = true;
DMLWrapper.doUpdate(thisOppAccount, new List<SObjectField>{Account.New_Billing_Process_Approved__c});
}
/* Replaces Node 'Mexico Shipping' */
if (vOpportunity.Type == 'Free Trial Opportunity' && o.Shipping_Country__c == 'Mexico'
&& vOpportunity.Shipping_Instructions__c == null) {
o.Shipping_Instructions__c = 'Please add Sample Label';
}
/* Replaces Node 'Stamp Manager On Stage Change' */
if ((vOpportunity.Rebate_Type__c != 'Partner Referral'
&& vOpportunity.Rebate_Type__c != 'Renewal Credit'
&& (HelperClass.isChanged(o, oldOpportunity, Schema.Opportunity.Probability) || vOpportunity.ownerId != o.ownerId)
//|| vOpportunity.Owner_Manager_Email_Copy__c != (String) managerFormula(o, vOpportunity, 'Manager Name')
) || vOpportunity.Overwrite_Validation_Rule__c) {
o.Owner_Manager_Name_Copy__c = (Id) managerFormula(o, vOpportunity, 'Manager Name');
o.Owner_Manager_Role_Copy__c = (String) managerFormula(o, vOpportunity, 'Manager Role');
}
/* Groundswell : Tanuj - WFlow Rule - Copy Owner Manager Email When Closing
* This rule copies the name of the owner's manager when opportunity is moved into closing
*/
if((o.StageName == 'Closing'
|| o.StageName == 'Refunded - Closed'
|| o.StageName == 'Orders Processing')
&& o.Owner_Manager_Email_Copy__c == null){
o.Owner_Manager_Email_Copy__c = (String) managerFormula(o, vOpportunity, 'Manager Email');
}
/*
* End of WFlow Rule - Copy Owner Manager Email When Closing
*/
/* Replaces Node 'Stamp Director On Stage Change' */
if ((vOpportunity.Rebate_Type__c != 'Partner Referral'
&& vOpportunity.Rebate_Type__c != 'Renewal Credit'
&& (HelperClass.isChanged(o, oldOpportunity, Schema.Opportunity.Probability) || vOpportunity.ownerId != o.ownerId)
//|| vOpportunity.Owner_Director_Role_Copy__c != (String) managerFormula(o, vOpportunity, 'Director Name')
) || vOpportunity.Overwrite_Validation_Rule__c) {
o.Owner_Director_Name_Copy__c = (Id) managerFormula(o, vOpportunity, 'Director Name');
//GTMS-26431 Copy Owner Director Email 
o.Owner_Director_Email_Copy__c = (String) managerFormula(o, vOpportunity, 'Director Email');
//Zakeer-GTMS:5758-Mar3-2022
o.Owner_AVP_Name_Copy__c   = (String) managerFormula(o, vOpportunity, 'DirectorsManagersName');
o.Owner_AVP_Role_Copy__c   = (String) managerFormula(o, vOpportunity, 'DirectorsManagersRole');
//GTMS-17681 -- Start -- Added below logic to set Owner AVP team on oppty
o.Owner_AVP_Team__c   = (String) managerFormula(o, vOpportunity, 'DirectorsManagersSalesUserType');
}
/* Replaces Node 'Stamp Geo On Stage Change' */
if ((vOpportunity.Rebate_Type__c != 'Partner Referral'
&& vOpportunity.Rebate_Type__c != 'Renewal Credit'
&& vOpportunity.Probability <= 95
&& (HelperClass.isChanged(o, oldOpportunity, Schema.Opportunity.Probability)
|| vOpportunity.Owner_Geo_Copy__c != vOpportunity.Owner.Territory__c))
|| vOpportunity.Overwrite_Validation_Rule__c) {
o.Owner_Geo_Copy__c = extractOwnerGeographyCopy(vOpportunity);
}
if(oldOppMap.get(o.Id).Payment_Terms__c != o.Payment_Terms__c && o.Payment_Terms__c != NULL && o.Payment_Terms__c != o.Initial_Payment_Terms__c) {
o.Initial_Payment_Terms__c = o.Payment_Terms__c;
}
if (o.SBQQ__PrimaryQuote__c == null &&
o.Shipping_and_Handling__c != null && o.Shipping_and_Handling__c > 0 && o.Shipping_and_Handling__c != 99999.99
&& o.Sales_Tax_Rate_NEW__c != null && o.Sales_Tax_Rate_NEW__c > 0 && o.Sales_Tax_Rate_NEW__c < 100
&& ((o.Shipping_Country__c != null && !(shippingAndHandlingTaxLocations.contains(o.Shipping_Country__c))))) {
o.S_H_Tax__c = o.Shipping_and_Handling__c * (o.Sales_Tax_Rate_NEW__c / 100);
} else {
o.S_H_Tax__c = 0;
}
}
if(Trigger.isInsert || (HelperClass.isChanged(o, oldOpportunity, Schema.Opportunity.Owner_Role_Copy__c )) || o.Probability >= 90) {
String ownerSegment;
if(o.Id != null && o.Returning_Opportunity__c != null){
ownerSegment = opportunitiesDataByIds.get(o.Id).Returning_Opportunity__r.Owner_Segment__c;
}else if(o.Returning_Opportunity__c != null){
ownerSegment = opportunitiesDataByIds.get(o.Returning_Opportunity__c).Owner_Segment__c;
    /*o.Owner_Manager_Name_Copy__c = opportunitiesDataByIds.get(o.Returning_Opportunity__c).Owner_Manager_Name_Copy__c;
    o.Owner_Manager_Role_Copy__c = opportunitiesDataByIds.get(o.Returning_Opportunity__c).Owner_Manager_Role_Copy__c;
    o.Owner_Director_Role_Copy__c = opportunitiesDataByIds.get(o.Returning_Opportunity__c).Owner_Director_Role_Copy__c;
    o.Owner_Director_Name_Copy__c = opportunitiesDataByIds.get(o.Returning_Opportunity__c).Owner_Director_Name_Copy__c;
    o.Owner_Manager_Email_Copy__c =  opportunitiesDataByIds.get(o.Returning_Opportunity__c).Owner_Manager_Email_Copy__c;*/

}
if(o.Owner_Segment__c != 'Other' && !String.isBlank(o.Owner_Segment__c)) {
o.Bookings_Owner_Segment__c  = o.Owner_Segment__c;
}
else if(o.Returning_Opportunity__c != Null && ownerSegment != 'Other' && !String.isBlank(ownerSegment)) {
o.Bookings_Owner_Segment__c  = ownerSegment;
}
else {
if(oppAccounts.get(o.AccountId) != Null) o.Bookings_Owner_Segment__c  = oppAccounts.get(o.AccountId).Segment__c;
}
if((!o.IsClosed || o.Finance_Segment_Stamp__c == null) && o.Bookings_Owner_Segment__c != NULL){
/* Update Finance Segment Stamp Field */
IF(o.CloseDate <= date.newInstance(2021, 08, 06)){
o.Finance_Segment_Stamp__c = o.Finance_Segment_Stamp__c;
}else if(o.Bookings_Owner_Segment__c.contains('Small Business') || o.Bookings_Owner_Segment__c.contains('AE1')){
o.Finance_Segment_Stamp__c = 'SMB';
}else if(o.Bookings_Owner_Segment__c.contains('Enterprise')){
o.Finance_Segment_Stamp__c = 'Enterprise';
}else{
o.Finance_Segment_Stamp__c = 'Mid Market';
}
}
}
//Need to assign oldOpportunity again as the value is only assigned if the opportunity is not closed.
if (oldOppMap != null) {
oldOpportunity = oldOppMap.get(o.Id);
// Update the cross sell identifier and purchase type fields
updateCrossSellIdentifier(o, oldOpportunity, thisOppAccount, opportunitiesDataByIds.get(o.Id)?.OpportunityLineItems);
    o.Shipping_and_Handling_Value__c = ShippingHandlingCalculations.calculateShippingAndHandlingForOpportunity(null,o, opportunitiesDataByIds.get(o.Id)?.OpportunityLineItems);
    //o.Shipping_and_Handling_Value__c = ShippingHandlingCalculations.calculateShippingAndHandlingForOpportunity(o, opportunitiesDataByIds.get(o.Id)?.OpportunityLineItems);
}
if(null != mapUsers && mapUsers.get(o.OwnerId) != null)
OpportunityWorkflowConversion.beforeInsertUpdateMethod(o, oldOpportunity, vOpportunity, thisOppAccount, mapUsers.get(o.OwnerId));
if(oldOpportunity.Id !=null){
OpportunityWorkflowConversion.beforeUpdateMethod(o, oldOpportunity, mapUsers.get(o.OwnerId));
// Code for new Renewal Process
OpportunityProcessBuilderConversion.stampDataForAmendments(o, oppAccounts.get(o.AccountId), oldOpportunity);
//GTMS-23000
OpportunityHelper.updateOpptyFromContractUsingWASD(o,contractsMap);
}
//End
//GTMS-25660
 if ((o.Type == 'Exchange' || o.Type == 'Warranty Exchange') && o.Shipping_Country__c == 'United States' && o.Shipmate_Preference__c == 'ShippingPreference-000029' && o.Shipmate_Preference_Override__c) {
                o.Shipmate_Service_Type__c  = 'ups_next_day_air';
            }
   if (o.Type == 'Warranty Exchange') {
                o.Comments__c = 'Product replaced under warranty, value for Customs purpose only';
            } else {
                o.Comments__c = null;
            }
}
updateAccountRecords();
}
@TestVisible
//This method is used to update the Opportunity purchase type and cross sell identifier fields
public static void updateCrossSellIdentifier(Opportunity newOpp, Opportunity oldOpp, Account acc, List<OpportunityLineItem> itemList){
System.debug('updateCrossSellIdentifier');
if (oldOpp == null || acc == null || itemList == null || itemList.size() <= 0) return;
Boolean purchaseTypeHasChangedOrBlank = ((oldOpp.Purchase_Type__c != newOpp.Purchase_Type__c) || String.isBlank(newOpp.Purchase_Type__c));
if (newOpp.Type == 'Revenue Opportunity'
&&((newOpp.StageName == 'Closed Won' && ((oldOpp.StageName != newOpp.StageName) || purchaseTypeHasChangedOrBlank))
|| (newOpp.SBQQ__PrimaryQuote__c != null && ((oldOpp.SBQQ__PrimaryQuote__c != newOpp.SBQQ__PrimaryQuote__c) || purchaseTypeHasChangedOrBlank)))
){
//Account.First_Purchase_Date__c = CloseDate || ISBLANK(Account.First_Purchase_Date__c)
if (acc.First_Purchase_Date__c == newOpp.CloseDate || acc.First_Purchase_Date__c == null){
newOpp.Purchase_Type__c = 'First Purchase';
}else{
Boolean isCrossSell = false;
List<Product_Code_by_Type__mdt> prodByTypeMdt = Product_Code_by_Type__mdt.getAll().values();
for (OpportunityLineItem item : itemList){
if (String.isBlank(item.ProductCode)) continue;
if ((isCrossSell = checkForCrossSellOnOppItems(acc, item, prodByTypeMdt)) == true) break;
}
if (isCrossSell) newOpp.Purchase_Type__c = 'Cross-Sell';
else             newOpp.Purchase_Type__c = 'Add-On';
}
}else if (newOpp.StageName != 'Closed Won' && newOpp.SBQQ__PrimaryQuote__c == null && newOpp.Purchase_Type__c != null){
newOpp.Purchase_Type__c = '';
}
}
//DCA Logic Start
public static String getDCAEnabled(Opportunity o){
String dcaString='Non DCA';
 //List<String> roleList = system.Label.DCA_Phase_Two_Launch?.split(',');   
if(o!=null && mapUsers!=null && mapUsers.containsKey(o.OwnerId) ){
User oppOwner=mapUsers.get(o.OwnerId);
if(  String.isNotBlank(System.Label.DCA_Enabled_Users) && 
(System.Label.DCA_Enabled_Users.contains(o.OwnerId)|| getDcaEnabledForOpportunity(System.Label.DCA_Enabled_Users,oppOwner)
/*(oppOwner.ManagerId!=null && System.Label.DCA_Enabled_Users.contains(oppOwner.ManagerId)) ||
(oppOwner.ManagerId!=null && oppOwner.Manager.ManagerId!=null && System.Label.DCA_Enabled_Users.contains(oppOwner.Manager.ManagerId)) ||
(oppOwner.ManagerId!=null && oppOwner.Manager.ManagerId!=null  && oppOwner.Manager.Manager.ManagerId!=null && System.Label.DCA_Enabled_Users.contains(oppOwner.Manager.Manager.ManagerId)) ||
(oppOwner.ManagerId!=null && oppOwner.Manager.ManagerId!=null  && oppOwner.Manager.Manager.ManagerId!=null && oppOwner.Manager.Manager.Manager.ManagerId!=null && System.Label.DCA_Enabled_Users.contains(oppOwner.Manager.Manager.Manager.ManagerId)) ||
(oppOwner.ManagerId!=null && oppOwner.Manager.ManagerId!=null  && oppOwner.Manager.Manager.ManagerId!=null && oppOwner.Manager.Manager.Manager.ManagerId!=null && oppOwner.Manager.Manager.Manager.Manager.ManagerId!=null && System.Label.DCA_Enabled_Users.contains(oppOwner.Manager.Manager.Manager.Manager.ManagerId))
*/
)    
)
{
dcaString='DCA';
}else if(  String.isNotBlank(System.Label.DCA_Phase_Two_Launch_Users) && 
(System.Label.DCA_Phase_Two_Launch_Users.contains(o.OwnerId)|| getDcaEnabledForOpportunity(System.Label.DCA_Phase_Two_Launch_Users,oppOwner) )){
    dcaString='DCA Phase Two';
}else if (oppOwner.UserRole.Name != null && String.isBlank(oppOwner.ContactId) && !oppOwner.UserRole.Name.contains('AE1') && !oppOwner.UserRole.Name.contains('Small Fleets') &&
         oppOwner.Profile.Name != 'System Administrator' && oppOwner.Profile.Name != 'System Administrator API' &&
         oppOwner.Profile.Name != 'Systems Automation' && oppOwner.Profile.Name != 'Samsara API Only'){
    dcaString='DCA Phase Three';
}
}
return dcaString;
}
    public Static Boolean getDcaEnabledForOpportunity(String users ,User oppOwner){
        return ((oppOwner.ManagerId!=null && users.contains(oppOwner.ManagerId)) ||
(oppOwner.ManagerId!=null && oppOwner.Manager.ManagerId!=null && users.contains(oppOwner.Manager.ManagerId)) ||
(oppOwner.ManagerId!=null && oppOwner.Manager.ManagerId!=null  && oppOwner.Manager.Manager.ManagerId!=null && users.contains(oppOwner.Manager.Manager.ManagerId)) ||
(oppOwner.ManagerId!=null && oppOwner.Manager.ManagerId!=null  && oppOwner.Manager.Manager.ManagerId!=null && oppOwner.Manager.Manager.Manager.ManagerId!=null && users.contains(oppOwner.Manager.Manager.Manager.ManagerId)) ||
(oppOwner.ManagerId!=null && oppOwner.Manager.ManagerId!=null  && oppOwner.Manager.Manager.ManagerId!=null && oppOwner.Manager.Manager.Manager.ManagerId!=null && oppOwner.Manager.Manager.Manager.Manager.ManagerId!=null && users.contains(oppOwner.Manager.Manager.Manager.Manager.ManagerId)));
    }    
//DCA Logic End
@TestVisible
private static Boolean checkForCrossSellOnOppItems(Account acc, OpportunityLineItem item, List<Product_Code_by_Type__mdt> prodByTypeMdt){
Boolean isCrossSell = false;
for (Product_Code_by_Type__mdt mdt : prodByTypeMdt){
Decimal purchasedInAccount = (
mdt.Product_Type__c == 'AG' ? acc.Total_Purchased_AG_Count__c :
mdt.Product_Type__c == 'CM' ? acc.Total_Purchased_CM_Count__c :
mdt.Product_Type__c == 'VG' ? acc.Total_Purchased_VG_Count__c :
mdt.Product_Type__c == 'EM' ? acc.Total_Purchased_EM_Count__c :
null
);
System.debug('purchasedInAccount'+purchasedInAccount);
if ((item.ProductCode.startsWith(mdt.Product_Code_Prefix__c) && purchasedInAccount == 0 )|| acc.Cross_Sell__c){
isCrossSell = true;
break;
}
}
return isCrossSell;
}
// Anil Bogadi - GTMS-4994
public void beforeUpdateOnly(Map<Id, Opportunity> oldOppMap, List<Opportunity> newOppList) {
//beforeInsertOrUpdate(newOppList, oldOppMap);
syncOpportunity(newOppList, oldOppMap);
        //GTMS-25560 - Feb-10-2025 -- Start
        List<Opportunity> remorseOppo = new List<Opportunity>();
        Set<String> naCurrencySet = new Set<String>{'USD','CAD','MXN'};
        Set<String> emeaCurrencySet = new Set<String>{'CHF','EUR','GBP'};  
        //GTMS-25560 - Feb-10-2025 -- End
Map<Id, Id> opportunityIds  = new Map<Id, Id>();
        Set<Id> setOfUserIds = new Set<Id>();
//GTMS-6450
Map<ID,Account> accountMapBookBiz = new Map<Id,Account>([SELECT Id,Book_of_Business__c FROM ACCOUNT WHERE ID IN : accountIdSet AND  Book_of_Business__c = null]);
//GTMS-16225: START
Set<Id> primaryQuoteIds = new Set<Id>();
for (Opportunity oppt : newOppList) {
if(oppt.SBQQ__PrimaryQuote__c !=null){
primaryQuoteIds.add(oppt.SBQQ__PrimaryQuote__c);
}
            if(oppt.StageName != oldOppMap.get(oppt.Id).StageName && oppt.StageName != null && (oppt.StageName == 'Orders Processing' || oppt.StageName == 'Ready to Ship' ||  oppt.StageName == 'Closed Won')){
                setOfUserIds.add(Userinfo.getUserId());
            }
}
Map<ID,SBQQ__Quote__c> finanaceMapQuote = new Map<Id,SBQQ__Quote__c>([SELECT Id, Finance_Partner_Account__c,DCA_Validation__c from SBQQ__Quote__c where Id =: primaryQuoteIds]);
//GTMS-16225: END
        if(!setOfUserIds.isEmpty()){ 
            getOpptyOwner(new Set<Id>{Userinfo.getUserId()}); 
        }
for (Opportunity o : newOppList) {
        if (System.isFuture() || System.isScheduled() || System.isBatch() || System.isQueueable()) {
                o.Bypass_Validation_Rule_DateTime__c = Datetime.now(); //GTMS-25783: Bypass VR Return_Opportunities_are_locked_for_Sel
            }
            // GTMS 25726: Restrict amended opp linked to In progress C&R from closing
            if(o.AccountId != null && o.SBQQ__AmendedContract__c != null && oppFields.containskey(o.Id))
            {
                // GTMS 25726: FeatureManagement.checkPermission returns true if the user has the specified   custom permission.
                
                if (!System.FeatureManagement.checkPermission('Validation_Exemption_Opportunity')&& 
                    o.of_LIC_Products__c!= 0 && 
                    oppFields.get(o.Id).Account.Account_C_R_In_Progress__c && 
                    oppFields.get(o.Id).SBQQ__AmendedContract__r.Contract_C_R_In_Progress__c && 
                    (o.Sub_Type__c!= 'Contract Cancellation' && o.Sub_Type__c!= 'Contract Replacement') && 
                    o.StageName == 'Closing')
                {
                    o.addError('You cannot submit this Opportunity to “Closing” because the amending contract is undergoing a C&R process, and this opportunity contains LIC which may alter this contract');
                }  
            }
            if( o.StageName != oldOppMap.get(o.Id).StageName && o.StageName != null  && mapUsers.containskey(Userinfo.getUserId()) && !System.isBatch() && !System.isQueueable() && Label.SkipValidationForStages.contains(mapUsers.get(Userinfo.getUserId()).Profile.Name) && (o.StageName == 'Orders Processing' || o.StageName == 'Ready to Ship' ||  o.StageName == 'Closed Won')){
                o.addError('Action not allowed: As an Account Executive, you cannot save this record when the stage is either Orders Processing, Ready to Ship, Closed Won, or Closed Lost.Please ensure you have the appropriate access.');
            }
string quoteDcaValidation = (finanaceMapQuote != null) ? finanaceMapQuote.get(o.SBQQ__PrimaryQuote__c)?.DCA_Validation__c:null;
if( o.SBQQ__PrimaryQuote__c != null && o.SBQQ__PrimaryQuote__c != oldOppMap.get(o.Id).SBQQ__PrimaryQuote__c && quoteDcaValidation == 'DCA'  && o.isClosed == false){
Opportunity oppo = (oppFields != null )? oppFields.get(o.Id):null;
List<dsfs__DocuSign_Status__c> docuSignStatus = oppo?.R00N80000002fD9vEAE;
                if(docuSignStatus != null){
for(dsfs__DocuSign_Status__c docu:docuSignStatus){
if(docu.Primary_Quote__c == o.SBQQ__PrimaryQuote__c && String.isNotBlank(docu.Customer_require_PO_for_invoicing__c) ){
o.Customer_require_PO_for_invoicing__c =  docu.Customer_require_PO_for_invoicing__c;
o.PO_Number__c = docu.PO_Number__c;
break ;
}
}
}
            }
Opportunity oldOpp = new Opportunity();
//GTMS-21122 Setting UUID in opportunity
if(String.isBlank(o.Opportunity_UUID__c)){
o.Opportunity_UUID__c = SSUtils.getUUID();
}
//GTMS-5451: Setting the "Is_Webstore_Upsell_Opportunity__c" to true if that field is being modified
if(o.Is_Webstore_Upsell_Opportunity__c != oldOppMap.get(o.Id).Is_Webstore_Upsell_Opportunity__c){
o.Is_Webstore_Upsell_Opportunity__c = true;
}
if(o.Is_Webstore_Upsell_Opportunity__c){
o.Finance_Partner__c=null; // added for GTMS-19857
if(oppAccounts != null && oppAccounts.get(o.AccountId) != null) {
if(String.isNotBlank(oppAccounts.get(o.AccountId).Payment_Terms__c)) {
o.Payment_Terms__c = oppAccounts.get(o.AccountId).Payment_Terms__c;
}
if(String.isNotBlank(oppAccounts.get(o.AccountId).Approved_Payment_Type__c)) {
o.Internal_Finance_Payment_Type__c = oppAccounts.get(o.AccountId).Approved_Payment_Type__c;
}
}
}
//GTMS-16225: START
if(!finanaceMapQuote.isEmpty()){
   if((o.Probability == 98 && oldOppMap.get(o.Id).Probability == 95) && finanaceMapQuote.containsKey(o.SBQQ__PrimaryQuote__c) && (o.Finance_Partner__c != finanaceMapQuote.get(o.SBQQ__PrimaryQuote__c).Finance_Partner_Account__c)){
o.addError('Opportunity Finance Partner and Quote Finance Partner does not match.');
}     
}

//GTMS-16225: END
if(o.License_Term__c != oldOppMap.get(o.Id).License_Term__c && o.CPQ_Opportunity__c == true){
o.License_Term__c = o.License_Term_CPQ__c != null ? o.License_Term_CPQ__c : o.License_Term__c;
}
if (oldOppMap.size() > 0) {
oldOpp = oldOppMap.get(o.Id);
}
// Stamp stage change analysis fields
OpportunityTriggerHandler.addCall('OpportunityHelper.stageChangeAnalysis');
System.debug('OpportunityHelper.stageChangeAnalysis: ' + OpportunityTriggerHandler.timesCalled('OpportunityHelper.stageChangeAnalysis'));
//rattlesnake project requirement
if(oppAccounts != null && oppAccounts.containsKey(o.AccountId) && ((oppAccounts.get(o.AccountId).Segment__c == 'Enterprise' || oppAccounts.get(o.AccountId).Segment__c == 'AE3') && oppAccounts.get(o.AccountId).Owner_Role__c != null && 
   !oppAccounts.get(o.AccountId).Owner_Role__c.contains('COR')) && (oppAccounts.get(o.AccountId).CurrencyIsoCode=='USD' || oppAccounts.get(o.AccountId).CurrencyIsoCode=='CAD' || oppAccounts.get(o.AccountId).CurrencyIsoCode=='MXN') &&
(String.isNotBlank(o.Type) && (o.Type=='Revenue Opportunity' || o.Type=='Remorse Refund' || (o.Type=='Rebate'  && o.Rebate_Type__c =='Delinquent')))
){
                //Run Rattlesnake Logic
}
else if(
(o.isClosed == false ||(o.IsClosed == true && oldOpp.isClosed == false))
){
if(o.SBQQ__RenewedContract__c!=null || o.Renewal__c || (oppFields!=null && oppFields.containsKey(o.Id) && oppFields.get(o.Id).Returning_Opportunity__c!=null && oppFields.get(o.Id).Returning_Opportunity__r.Renewal__c)){
o.Split_New_ACV__c = 0;
o.Split_Renewal_ACV__c = o.ACV_Bookings_SOT__c;
}
else{
o.Split_New_ACV__c = o.ACV_Bookings_SOT__c;
o.Split_Renewal_ACV__c = 0;
}
}
//update for GTMS-22807, commented the populuation of went to fields
// as this needs to be called in insert and update both scenarios.
/*if (o.StageName == 'Incubate' && oldOpp.StageName != 'Incubate') {
o.Went_To_Incubate_Date__c = Datetime.Now();
o.Went_To_Incubate__c = TRUE;
} else if (o.StageName == 'Qualified' && oldOpp.StageName != 'Qualified') {
o.Went_To_Qualified_Date__c = Datetime.Now();
o.Went_To_Qualified__c = TRUE;
} else if (o.StageName == 'Trial' && oldOpp.StageName != 'Trial') {
o.Went_To_Trial_Date__c = Datetime.Now();
o.Went_To_Trial__c = TRUE;
} else if (o.StageName == 'Proposal' && oldOpp.StageName != 'Proposal') {
o.Went_To_Proposal_Date__c = Datetime.Now();
o.Went_To_Proposal__c = TRUE;
} else if (o.StageName == 'Decision' && oldOpp.StageName != 'Decision') {
o.Went_To_Decision_Date__c = Datetime.Now();
o.Went_To_Decision__c = TRUE;
} else if (o.StageName == 'Purchase' && oldOpp.StageName != 'Purchase') {
o.Went_To_Purchase_Date__c = Datetime.Now();
o.Went_To_Purchase__c = TRUE;
} else if (o.StageName == 'Closing' && oldOpp.StageName != 'Closing') {
o.Went_To_Closing_Date__c = Datetime.Now();
o.Went_To_Closing__c = TRUE;
} else if (o.StageName == 'Orders Processing' && oldOpp.StageName != 'Orders Processing') {
o.Went_to_Orders_Processing_Date__c = Datetime.Now();
o.Went_to_Orders_Processing__c = TRUE;
if (!(o.Type == 'Revenue Opportunity' && o.SBQQ__Renewal__c == true) && o.CloseDate != Date.today()){
o.CloseDate = Date.today();
}
} else if (o.StageName == 'Ready To Ship' && oldOpp.StageName != 'Ready To Ship') {
o.Went_To_Ready_To_Ship_Date__c = Datetime.Now();
o.Went_To_Ready_To_Ship__c = TRUE;
} else*/ if (o.StageName == 'Closed Won' && oldOpp.StageName != 'Closed Won') {
//o.Went_To_Closed_Won_Date__c = Datetime.Now();
//o.Went_To_Closed_Won__c = TRUE;
if(((Boolean.valueOf(orderTransformationSetting.Value__c) == false && o.Type != 'Free Trial Opportunity') || (Boolean.valueOf(orderTransformationSetting.Value__c) == true && o.Type != 'Free Trial Opportunity') && o.Type != 'Revenue Opportunity') ||
(Boolean.valueOf(orderTransformationSetting.Value__c) == true && oppFields.containsKey(o.Id) && oppFields.get(o.Id).Orders.isEmpty() && ( o.Type == 'Free Trial Opportunity' || o.Type == 'Revenue Opportunity'))) {
o.SBQQ__Contracted__c = True;
}
} else if ((o.StageName == 'Refunded - Closed' && oldOpp.StageName != 'Refunded - Closed') && o.SBQQ__AmendedContract__c != NULL ) {
if(Boolean.valueOf(orderTransformationSetting.Value__c) == false || (Boolean.valueOf(orderTransformationSetting.Value__c) == true
                                                    && o.Type != 'Free Trial Return' && o.Type != 'Warranty' && o.Type != 'Rebate')) {
                                                        o.SBQQ__Contracted__c = True;
                                                    }
} else if (o.StageName == 'Closed Lost' && oldOpp.StageName != 'Closed Lost') {
o.Went_To_Closed_Lost_Date__c = Datetime.Now();
o.Went_To_Closed_Lost__c = TRUE;
o.CloseDate = Date.Today();
if (closedLostOppIdSet == null) closedLostOppIdSet = new Set<Id>();
if (o.SBQQ__RenewedContract__c == null) closedLostOppIdSet.add(o.Id);
}
if ((o.Type == 'Warranty Exchange' || o.Type == 'Exchange' || o.Type == 'Remorse Refund') && o.StageName == 'Return Initiated' && oldOpp.StageName != 'Return Initiated') {
o.Return_Label_Sent_At__c = Date.Today();
}
if(!duplicateOpportunityEvents.contains(o.Id) && o.SBQQ__RenewedContract__c != NULL && o.StageName != oldOpp.StageName && o.StageName == 'Ready to Ship'){
opportunityEvents.add(new Opportunity_Event__e(Id__c = o.Id));
duplicateOpportunityEvents.add(o.Id);
}
if(o.Amount != NULL && o.SBQQ__RenewedContract__c != NULL && o.Renewal_ACV__c == NULL && o.License_Term_CPQ__c != NULL && o.License_Term_CPQ__c != 0 ){
o.Renewal_ACV__c = o.Amount / (o.License_Term_CPQ__c / 12);
}
/* GTMS-11183
if(oldOpp != null){
system.debug('*******calculateEquipmentACV********');
EquipmentACVCalculationService eqpAcvCalcService = new EquipmentACVCalculationService();
eqpAcvCalcService.calculateEquipmentACV(oldOpp, o);
}*/
// Map to store delinquent and respective returning oppty IDS based on below criteria
if(o.Type == 'Rebate' && o.Rebate_Type__c == 'Delinquent' && o.StageName != oldOpp.StageName && o.StageName == 'Refunded - Closed' && o.Returning_Opportunity__c != null){
opportunityIds.put(o.Returning_Opportunity__c, o.id);
}
//GTMS-6450  //GTMS-17289
/*if(o.Initial_Payment_Terms__c <> 'Due in advance' && o.Selected_Payment_Type__c == 'Upfront Payments'
&& o.Express_Agreement_Accepted_Date__c <> null && accountMapBookBiz.containsKey(o.AccountId)) //oldOppMap.get(o.Id).Account.Book_of_Business__c == null
{
o.Initial_Payment_Terms__c = 'Due in advance';
o.Payment_Terms__c = 'Due in advance';
}
else */
/*
* If the opportunity is AE1, it’s not a Webstore Opp and Amount Received is greater than 0, then stamp the Payment_Terms__c to “Due in advance”.
*/
if(((o.Configuration_Segment__c == 'Express' && o.Amount_Received__c > 0 && o.Express_Agreement_Accepted_Date__c <> null)
|| (o.Amount_Received__c > 0 && o.Configuration_Segment__c == 'Non Express'))
&& (o.Is_Webstore_Upsell_Opportunity__c == false && o.Small_Fleet_Opportunity__c == false) && o.Segment_Sales_Role__c == 'AE1'
&& accountMapBookBiz.containsKey(o.AccountId)) //oldOppMap.get(o.Id).Account.Book_of_Business__c == null
{
o.Payment_Terms__c = 'Due in advance';
}
if(o.StageName == 'Return Initiated' && o.Type == 'Remorse Refund' && o.of_HW_Products__c == 0
&& o.of_Accessories__c == 0 && o.of_LIC_Products__c < 0)
{
o.StageName = 'Finance Processing';
}
/* GTMS-8426 - Flavio - Wrong value fix for Ship from location in LIC only opportunities */
if ((o.Ship_From_Location__c != oldOppMap.get(o.Id).Ship_From_Location__c
||   o.of_LIC_Products__c != oldOppMap.get(o.Id).of_LIC_Products__c
||   o.of_HW_Products__c != oldOppMap.get(o.Id).of_HW_Products__c)
&&  o.Probability > 0 && o.Probability < 100
&&  o.of_LIC_Products__c > 0 && o.of_HW_Products__c <= 0 && o.Total_Weight_oz__c <= 0){
    // GTMS-28141 -- ABU --> 06262025 --> Start
if (HelperClass.shippingCountryDefaults == null || HelperClass.shippingCountryDefaults.isEmpty()){
HelperClass.queryShippingCountryDefaults();
}
    // GTMS-28141 -- ABU --> 06262025 --> End
if (o.Type == 'Revenue Opportunity' || o.Type == 'Free Trial Opportunity' || o.Type == 'Promo Opportunity'){

if (HelperClass.shippingCountryDefaults.containsKey(o.Shipping_Country__c) && o.Shipping_Country__c != 'Canada') //GTMS-28141 -- ABU --> 06262025 
{
o.Ship_From_Location__c = HelperClass.shippingCountryDefaults.get(o.Shipping_Country__c).Ship_From_Location__c;
o.Shipping_Method__c = HelperClass.shippingCountryDefaults.get(o.Shipping_Country__c).Shipping_Method__c;
o.Shipping_Carrier__c = HelperClass.shippingCountryDefaults.get(o.Shipping_Country__c).Shipping_Carrier__c;
}
}else if ((o.Type == 'Exchange' || o.Type == 'Remorse Refund' || o.Type == 'Free Trial Return' || o.Type == 'Unplanned Return') && o.Shipping_Country__c != 'Canada') //GTMS-28141 -- ABU --> 06262025
{

o.Ship_From_Location__c = Label.Ship_From_Location_for_Virtual_Returns;
    //o.Shipping_Method__c = HelperClass.shippingCountryDefaults.get(o.Shipping_Country__c).Shipping_Method__c;
   // o.Shipping_Carrier__c = HelperClass.shippingCountryDefaults.get(o.Shipping_Country__c).Shipping_Carrier__c;

}
}
/* GTMS-10539 - Flavio - Rolling up product costs for Shipmate on Remorse Refunds */
if (o.Type == 'Remorse Refund'
&& (o.Shipping_Country__c == 'Canada' || o.Shipping_Country__c == 'Mexico' || o.Shipping_Country__c == 'United Kingdom')){
o.Shipmate_Declared_Value__c = rollupOpportunityProductCosts(o);
}
            //GTMS-25560 - Feb-10-2025 -- Start              
                    if(o.Type == 'Remorse Refund' && o.Returning_Opportunity__c != NULL){
                        List<String> prodCodeLst =  System.Label.MEM_PLTFMPRO.split(',');
                        if(oppFields.containsKey(o.id) && oppFields.get(o.id).OpportunityLineItems.size()>0){
                            for(OpportunityLineItem oLI: oppFields.get(o.id).OpportunityLineItems){
                                if(prodCodeLst.contains(oLI.ProductCode)){                
                                    if(naCurrencySet.contains(o.CurrencyISOCode) && String.isNotBlank(o.Owner_Role_Copy__c)){
                                        if(oppFields.get(o.id).Account.Owner_Role__c.contains('AE1 ')|| oppFields.get(o.id).Account.Owner_Role__c.contains('AE2 ')){
                                            o.OwnerId = System.Label.MEM_AE1AE2;
                                        }else If(oppFields.get(o.id).Account.Owner_Role__c.contains('AE3 ')|| oppFields.get(o.id).Account.Owner_Role__c.contains('ENT ')){
                                            o.OwnerId = System.Label.MEM_ENTAE3;
                                        }
                                    }else If(emeaCurrencySet.contains(o.CurrencyISOCode)){
                                        o.OwnerId = System.Label.MEM_EMEA;
                                    }
                                    break;
                                } 
                            } 
                        }            
                    }
            //GTMS-25560 - Feb-10-2025 -- End
    //GTMS-20484
            if (o.StageName != oldOppMap.get(o.Id).StageName && o.StageName == 'Return Label Sent' && o.Type == 'Remorse Refund' && 
                o.Sub_Type__c  == 'Upgrade') {
                    o.StageName = 'Finance Processing';                
            }
//GTMS-7220
if(o.CurrencyIsoCode == 'USD' && o.Payment_Method__c == 'Credit Card' && o.Finance_Segment__c <> 'SMB' && !(oppAccounts.get(o.AccountId) != NULL && oppAccounts.get(o.AccountId).Book_of_Business__c != NULL && ((oppAccounts.get(o.AccountId).Book_of_Business__c).contains('ENT')) && !(oppAccounts.get(o.AccountId).IS_Named_Account__c)))
o.Payment_Processing_Fee__c = true;
this.addToClickpathOpportunityList(o);
setOwnerSubRegion(o, oppAccounts.get(o.AccountId));
setOwnerBusinessUnit(o, oppAccounts.get(o.AccountId));
}
if(!opportunityIds.isEmpty())
updateRenewedLinesforRebate(opportunityIds);
this.setClickpathAuditStatus(oldOppMap);
this.validateClosedLostOpps(newOppList);
this.setSyncInProgress(oldOppMap,newOppList);
}
public static void setOwnerSubRegion(Opportunity opp, Account acc){
// +'' to avoid null pointers
String ownRole = (opp != null && opp.Owner_Role_Copy__c != null ? opp.Owner_Role_Copy__c : '');
String accRole = (acc != null && acc.Owner_Role__c != null ? acc.Owner_Role__c : '');
String subRegion;
if      (ownRole.contains(' US ')   || ownRole.endsWithIgnoreCase(' US')  ) subRegion = 'US';
else if (ownRole.contains(' CA ')   || ownRole.endsWithIgnoreCase(' CA')  ) subRegion = 'CA';
else if (ownRole.contains(' MX ')   || ownRole.endsWithIgnoreCase(' MX')  ) subRegion = 'MX';
else if (ownRole.contains(' UK ')   || ownRole.endsWithIgnoreCase(' UK')  ) subRegion = 'UK';
else if (ownRole.contains(' FR ')   || ownRole.endsWithIgnoreCase(' FR')  ) subRegion = 'FR';
else if (ownRole.contains(' DE ')   || ownRole.endsWithIgnoreCase(' DE')  ) subRegion = 'DE';
else if (ownRole.contains(' NL ')   || ownRole.endsWithIgnoreCase(' NL')  ) subRegion = 'NL';
else if (ownRole.contains(' EMEA ') || ownRole.endsWithIgnoreCase(' EMEA')) subRegion = 'EMEA';
else if (ownRole.contains(' NA ')   || ownRole.endsWithIgnoreCase(' NA')  ) subRegion = 'NA';
else if (accRole.contains(' US ')   || accRole.endsWithIgnoreCase(' US')  ) subRegion = 'US';
else if (accRole.contains(' CA ')   || accRole.endsWithIgnoreCase(' CA')  ) subRegion = 'CA';
else if (accRole.contains(' MX ')   || accRole.endsWithIgnoreCase(' MX')  ) subRegion = 'MX';
else if (accRole.contains(' UK ')   || accRole.endsWithIgnoreCase(' UK')  ) subRegion = 'UK';
else if (accRole.contains(' FR ')   || accRole.endsWithIgnoreCase(' FR')  ) subRegion = 'FR';
else if (accRole.contains(' DE ')   || accRole.endsWithIgnoreCase(' DE')  ) subRegion = 'DE';
else if (accRole.contains(' NL ')   || accRole.endsWithIgnoreCase(' NL')  ) subRegion = 'NL';
else if (accRole.contains(' EMEA ') || accRole.endsWithIgnoreCase(' EMEA')) subRegion = 'EMEA';
else if (accRole.contains(' NA ')   || accRole.endsWithIgnoreCase(' NA')  ) subRegion = 'NA';
else subRegion = 'US';
opp.Owner_Sub_Region__c = subRegion;
}
public static void setOwnerBusinessUnit(Opportunity opp, Account acc){
// +'' to avoid null pointers
String ownerRole = (opp != null && opp.Owner_Role_Copy__c != null ? opp.Owner_Role_Copy__c : '');
String businessUnit;
if (ownerRole.contains(' SLED ') || ownerRole.endsWithIgnoreCase(' SLED')) businessUnit = 'Public Sector';
else businessUnit = 'Private Sector';
opp.Owner_Business_Unit__c = businessUnit;
}
public void validateClosedLostOpps(List<Opportunity> oppList){
Boolean isAEProfile = Label.Samsara_AEs_Profiles_List.contains(String.valueOf(UserInfo.getProfileId()));
if (closedLostOppIdSet != null && !closedLostOppIdSet.isEmpty() && (isAEProfile || Test.isRunningTest())){
Set<Id> oppsWithInsight = new Set<Id>();
for (Closed_Deal_Insights__c insight : [
SELECT Opportunity__c
FROM Closed_Deal_Insights__c
WHERE Opportunity__c IN :closedLostOppIdSet
]){
oppsWithInsight.add(insight.Opportunity__c);
}
for (Opportunity opp : oppList){
if (opp.Type != 'Free Trial Opportunity' && closedLostOppIdSet.contains(opp.Id) && !oppsWithInsight.contains(opp.Id) && !Test.isRunningTest()){
opp.addError(Label.Closed_Lost_Flow_Validation_Error_Message);
}
}
}
}
private static Decimal rollupOpportunityProductCosts(Opportunity opp){
Decimal cost = 0;
if(oppFields!=null && oppFields.containsKey(opp.Id)) {
if (oppFields.get(opp.Id).OpportunityLineItems.isEmpty()) return cost;
for (OpportunityLineItem item : oppFields.get(opp.Id).OpportunityLineItems)
cost += (item.Product_Cost__c != null ? item.Product_Cost__c : 0);
}
return cost;
}
// Bulkified future method that will update delinquent oppty lines  'Renewed line' to True based returning oppty lines renewed line
@future
public static void UpdateRenewedLinesforRebate(Map<Id, Id> opportunityIds) {
Set<Id> eligibleDelinquentOpptys = new Set<Id>();
Map<Id, Set<String>> returningOpptyOLIMap = new Map<Id,Set<String>>(); // Map for returning oppty => eligbile product codes (renewedline = true)
List<OpportunityLineItem> delinquentOLIsToUpdate = new List<OpportunityLineItem>();
//Get all oppty lines from returning oppty where Renewed_Line__c = True
for(OpportunityLineItem Oli : [SELECT Id,ProductCode, Renewed_Line__c,OpportunityId FROM OpportunityLineItem where Renewed_Line__c = true and OpportunityId IN : opportunityIds.keySet()]){
eligibleDelinquentOpptys.add(opportunityIds.get(Oli.OpportunityId));
//If the returning oppty is already in the map, add the respective string of product codes with new product codes
if(returningOpptyOLIMap.ContainsKey(Oli.OpportunityId)){
Set<String> productCodes = returningOpptyOLIMap.get(Oli.OpportunityId);
productCodes.add(Oli.ProductCode);
returningOpptyOLIMap.put(Oli.OpportunityId, productCodes);
}else{ // if the map doesn't have returning oppty id -> initiate with new set of product codes
returningOpptyOLIMap.put(Oli.OpportunityId, new Set<String>{Oli.Productcode});
}
}
// Get the related delinquent Oppty lines based on the eligible delinquent opptys from above logic
List<OpportunityLineItem> deliquentOLIs = [Select Id, Renewed_Line__c, Opportunity.Returning_Opportunity__c,productCode from OpportunityLineItem where OpportunityId IN : eligibleDelinquentOpptys];
for(OpportunityLineItem delinquentOli : deliquentOLIs){
// if the product code matches in returning oli map then we need to update delinquent OLI to renewedline = true
if(returningOpptyOLIMap.containsKey(delinquentOli.Opportunity.Returning_Opportunity__c)){
Set<String> productCodes = returningOpptyOLIMap.get(delinquentOli.Opportunity.Returning_Opportunity__c);
if(productCodes.contains(delinquentOli.productCode)){
OpportunityLineItem Oli = new OpportunityLineItem(Id = delinquentOli.Id, Renewed_Line__c = true);
delinquentOLIsToUpdate.add(Oli);
}
}
}
// Final list of delinquent oppty OLIs for update
if(!delinquentOLIsToUpdate.isEmpty()) update delinquentOLIsToUpdate;
}
// * 8/20/20 Tommy - (GTMS-1362) orderAdminRoundRobin (changed criteria for UK Users so that all EMEA orders are assigned to Nora Csillag)
public void orderAdminRoundRobin(Map<Id, Opportunity> oldOppMap, Map<Id, Opportunity> newOppMap) {
Map<Id, Opportunity> roundRobinThese = new Map<Id, Opportunity>();
Map<Id, User> updateUsers = new Map<Id, User>();
List<User> usersUK = new List<User>();
List<User> usersUS = new List<User>();
List<Shipping_Countries__mdt> lstShipCtry = Shipping_Countries__mdt.getAll()?.values();
List<String> lstShipCountries = new List<String>();
Map<String, Shipping_Countries__mdt> shipFromMap = new Map<String, Shipping_Countries__mdt>();
String userNamesString = System.Label.Order_Admin_Removal_Users;
List<String> adminUsersRemovalList = userNamesString.split(',');
if(lstShipCtry != null && lstShipCtry.Size() > 0 ){
for (Shipping_Countries__mdt country : lstShipCtry) {
lstShipCountries.add(country.Country__c);
shipFromMap.put(country.Country__c, country);
}
}
// Query round robin-able users, if necessary
for (Opportunity o : newOppMap.values()) {
if (o.Type == 'Revenue Opportunity' || o.Type == 'Promo Opportunity' || o.Type == 'Free Trial Opportunity') {
if (o.Order_Admin__c == NULL && (o.StageName == System.Label.Orders_Processing || o.Probability == 98) && (((oldOppMap.get(o.Id).StageName != newOppMap.get(o.Id).StageName)) || ((oldOppMap.get(o.Id).Probability != newOppMap.get(o.Id).Probability)))) {
roundRobinThese.put(o.Id, o);
}
}
}
// If we don't need to assign any users, don't do anything else.
if (roundRobinThese.size() > 0) {
// Query eligible users (up to the number that we need)
List<User> eligibleUsers = [SELECT Id, Order_Admin_Oppty_Date__c, Entity__c FROM User WHERE Order_Admin_Available__c = TRUE AND isActive = TRUE AND Name NOT IN :adminUsersRemovalList ORDER BY Order_Admin_Oppty_Date__c ASC];
if (eligibleUsers.size() == 0) {
eligibleUsers = [SELECT Id, Entity__c, Order_Admin_Oppty_Date__c FROM User WHERE Order_Admin_Fallback_User__c = TRUE AND isActive = TRUE AND Name NOT IN :adminUsersRemovalList ORDER BY Order_Admin_Oppty_Date__c ASC];
}
for (User user : eligibleUsers) {
if (user.Entity__c == 'Samsara UK') {
usersUK.add(user);
} else {
usersUS.add(user);
}
}
//Two variables to track the total number of users in each region
Integer countUS = 0;
Integer countUK = 0;
for (Opportunity opp : roundRobinThese.values()) {
//assigning users based on Shipping Country
string shipFromLocation = shipFromMap.get(opp.Shipping_Country__c).Ship_From_Location__c;
if (opp.Shipping_Country__c != null && (shipFromLocation == 'VCK' || shipFromLocation == 'Samsara UK') && !usersUK.isEmpty()) {
opp.Order_Admin__c = usersUK[countUK].Id;
updateUsers.put(usersUK[countUK].Id, new User(Id = usersUK[countUK].Id, Order_Admin_Oppty_Date__c = System.now()));
countUK++;
countUK = (countUK >= usersUK.size()) ? 0 : countUK;
} else if (!usersUS.isEmpty()) {
opp.Order_Admin__c = usersUS[countUS].Id;
updateUsers.put(usersUS[countUS].Id, new User(Id = usersUS[countUS].Id, Order_Admin_Oppty_Date__c = System.now()));
countUS++;
countUS = (countUS >= usersUS.size()) ? 0 : countUS;
}
}
if (updateUsers.size() > 0) {
try {
//update updateUsers.values();
DMLWrapper.doUpdate(updateUsers.values());
} catch (Exception e) {
System.debug('There was an error: ' + e);
}
}
}
}
public void populateOptyTrackerField(Map<Id, Opportunity> oldOppMap, Map<Id, Opportunity> newOppMap){
for(Opportunity opp :newOppMap.values()){
//When Express Agreement Accepted Date is nullified in the current transaction, remove the warnings
if(opp.Express_Agreement_Accepted_Date__c == null && oldOppMap.get(opp.Id).Express_Agreement_Accepted_Date__c != opp.Express_Agreement_Accepted_Date__c) removeWarningFromOptyTrackerField(opp);
//If empty or changed in this transaction, skip
if(opp.Express_Agreement_Accepted_Date__c == null || oldOppMap.get(opp.Id).Express_Agreement_Accepted_Date__c != opp.Express_Agreement_Accepted_Date__c) continue;
for(Schema.FieldSetMember fm : Schema.SObjectType.Opportunity.fieldSets.getMap().get('Opportunity_Field_Track').getFields()){
if(oldOppMap.get(opp.Id).get(fm.getFieldPath()) == opp.get(fm.getFieldPath())) continue;
if(opp.get(fm.getFieldPath()) != 'Closed Lost' && fm.getFieldPath() == 'StageName') continue;
if(String.isNotBlank(opp.Opportunity_Tracking__c)){
if(opp.Opportunity_Tracking__c.split(';').contains('Warning: '+fm.getlabel())) continue;
}
opp.Opportunity_Tracking__c = String.isBlank(opp.Opportunity_Tracking__c)?'Warning: '+fm.getlabel():opp.Opportunity_Tracking__c+(';Warning: '+fm.getlabel());
}
}
}
private void removeWarningFromOptyTrackerField(Opportunity opp){
if(String.isBlank(opp.Opportunity_Tracking__c)) return;
list<String> pickList = new list<String>();
for(String pickVal :opp.Opportunity_Tracking__c.split(';')){
if(pickVal.startsWith('Warning: ')) continue;
pickList.add(pickVal);
}
opp.Opportunity_Tracking__c = String.join(pickList,';');
}
public void sendReturnLabelEmail(Map<Id, Opportunity> oldOppMap, Map<Id, Opportunity> newOppMap) {
// Could be modified to a process builder
Map<Id, Opportunity> returnOpptysToEmail = new Map<Id, Opportunity>();
for (Opportunity o : newOppMap.values()) {
if (o.type == 'Free Trial Return' || o.type == 'Exchange' || o.type == 'Remorse Refund' || o.type == 'Warranty Exchange') {
if (o.Return_Label_Attachment__c != null && !o.Bypass_return_Email__c &&
                    ((!System.Label.Commercial_Invoice_Inernational_Shipment.contains(o.Shipping_Country__c) && ((o.StageName != oldOppMap.get(o.Id).StageName && o.StageName == 'Return Label Sent') || (o.StageName != oldOppMap.get(o.Id).StageName && o.StageName == 'Finance Processing'
                          && o.Sub_Type__c == 'Upgrade' && o.type == 'Remorse Refund'))) //20484
|| (System.Label.Commercial_Invoice_Inernational_Shipment.contains(o.Shipping_Country__c) && o.Return_Label_Attachment__c != oldOppMap.get(o.Id).Return_Label_Attachment__c && o.Return_Label_Attachment__c.contains(',') && o.StageName == 'Return Label Sent')
|| (o.Resend_Return_Email__c != oldOppMap.get(o.Id).Resend_Return_Email__c && o.Resend_Return_Email__c))) {
if (o.Tracking_Number__c != NULL && o.Shipping_Address_NEW__c != NULL) {
returnOpptysToEmail.put(o.Id, o);
}
}
}
}
if (returnOpptysToEmail.size() > 0) {
ReturnLabelEmailer.sendReturnEmails(returnOpptysToEmail);
}
}
public void createFirstOpportunityFromContact(List<Opportunity> newOppList) {
/*System.debug('this is opp firstname ' + newOppList[0].Name);
System.debug('I am in the createFirstOpportunityFromContract method!');
// Maybe could be process builder, but not sure how to throw exception
// Messes up test classes since it throws callout exception
if (!Test.isRunningTest() || newOppList[0].Name == 'Run the createFirstOpportunityFromContact test') {
loadOppAccounts(newOppList);
for (Opportunity o : newOppList) {
Account associatedAccount = oppAccounts.get(o.AccountId);
if (associatedAccount == null) {
o.adderror('Please associate an Account to the opportunity.');
} else {
if (oppAccounts.get(o.AccountId).Opportunities.size() == 0 &&
o.Can_Create__c == False) {
System.debug('Cant create because it is the first oppty and we are not creating it from a contact');
CalloutException k = new CalloutException();
k.setMessage('This is the first opportunity for this Account so it must be created out of a Contact using the Create Opportunity button.');
throw k;
} else {
System.debug('Can create because there is more than one oppty');
}
}
}
}*/
}
//* Dec 17th, 2020 Ron (GTMS-2033) expressSetAnnualDiscountLineItem (pull back in for Webstore Deals + legacy AE1 deals)
// After the Annual Discount logic is deprecated, this method can be given a generic name -@Harsha
public void expressSetAnnualDiscountLineItem(Map<Id, Opportunity> oldOppMap, Map<Id, Opportunity> newOppMap) {
if (OpportunityHelper.expressSetDiscountRun) {
return;
}
loadOppFields(newOppMap);
Map<String, String> prodCodesToDispatchMap = new Map<String, String>();
List<OpportunityLineItem> opptyLToUpdate = new List<OpportunityLineItem>();
List<String> lstDCLProdCodes = new List<String>();
List<String> byPassShipFromLocation = System.Label.GTMS_ShipFromLocationProducts.split(',');
for (Opportunity newOpp : newOppMap.values()) {
Opportunity oldOpp = oldOppMap.get(newOpp.Id);
String prodCodesToDispatch = '';
Decimal productCount = newOpp.of_HW_Products__c + newOpp.of_Accessories__c;
Decimal expressSelectedDiscount = newOpp.Express_Selected_Discount__c != null ? newOpp.Express_Selected_Discount__c : 0;
if(oldOpp.StageName != 'Orders Processing' && newOpp.StageName == 'Orders Processing' && ((newOpp.Type == 'Promo Opportunity' && satisfyPromoOpp(newOpp,productCount))
                                                                    || (newOpp.Type == 'Free Trial Opportunity' && satisfyFreeTrailOpp(newOpp,productCount)) || (newOpp.Type == 'Revenue Opportunity' && satisfyRevenueOpp(newOpp,productCount))) && satisfyMatchingconditions(newOpp)){
                                                                        Integer QtyLimitPerProduct = getQtyLimitPerProduct(newOpp.Type);
                                                                        if(newOpp.Type == 'Free Trial Opportunity' || newOpp.Type == 'Promo Opportunity'){
                                                                            lstDCLProdCodes.addAll(System.Label.DCL_Product_SKU_List.split(','));
                                                                            lstDCLProdCodes.addAll(System.Label.DCL_Product_SKU_List_1.split(','));
                                                                            if(newOpp.Type == 'Promo Opportunity') {//GTMS-18016 - Added If for mexico location start
                                                                                lstDCLProdCodes.addAll(System.Label.Mexico_SKU_Product_for_Promo.split(','));
                                                                                //GTMS-18016 - Added If for mexico location End
                                                                            }
                                                                            
                                                                        }else if(newOpp.Type == 'Revenue Opportunity'){
                                                                            lstDCLProdCodes.addAll(System.Label.DCL_Product_list_for_RevOppty.split(','));
                                                                            lstDCLProdCodes.addAll(System.Label.DCL_Product_list_for_RevOppty_extend_1.split(','));
                                                                            lstDCLProdCodes.addAll(System.Label.DCL_Product_list_for_RevOppty_extend_2.split(','));
                                                                            lstDCLProdCodes.addAll(System.Label.DCL_Product_list_for_RevOppty_extend_3.split(','));
                                                                            lstDCLProdCodes.addAll(System.Label.DCL_Product_list_for_RevOppty_extend_4.split(','));
                                                                             //GTMS-18016 - Added If for mexico location start
                                                                            lstDCLProdCodes.addAll(System.Label.Mexico_SKU_Product_for_Revenue.split(','));
                                                                            lstDCLProdCodes.addAll(System.Label.Mexico_SKU_Products_for_Revenue_1.split(','));
                                                                            lstDCLProdCodes.addAll(System.Label.Mexico_SKU_Products_for_Revenue_2.split(','));
                                                                            //GTMS-18016 - Added If for mexico location star
                                                                        }
                                                                        Boolean productFlag = true;
                                                                        for (OpportunityLineItem oli : oppFields.get(newOpp.Id).OpportunityLineItems) {
                                                                            // modified below condition to cater condition for canada GTMS-10997
                                                                            // commented the oli.Quantity for GTMS-18017 and GTMS-10999
                                                                            if (lstDCLProdCodes.contains(oli.ProductCode) && oli.Quantity >= 1 && (oli.Ship_To_Country__c == 'United States' || oli.Ship_To_Country__c == 'Canada' ||  oli.Ship_To_Country__c == 'Mexico')) {
                                                                                prodCodesToDispatch = prodCodesToDispatch + ',' + oli.ProductCode;
                                                                            } else {
                                                                                productFlag = false;
                                                                            }
                                                                        }
                                                                        if (prodCodesToDispatch != '' && productFlag == true) {
                                                                            prodCodesToDispatchMap.put(newOpp.Id, prodCodesToDispatch);
                                                                        }
                                                                    }
if (((newOpp.Selected_Payment_Type__c != null && oldOpp.Selected_Payment_Type__c != newOpp.Selected_Payment_Type__c) || newOpp.Name.contains('Webstore')) && newOpp.Configuration_Segment__c != null && newOpp.Configuration_Segment__c == 'Express' && newOpp.Probability < 95 && newOpp.Total_License_Due__c > 0 && newOpp.SBQQ__PrimaryQuote__c == null) {
for (OpportunityLineItem oli : oppFields.get(newOpp.Id).OpportunityLineItems) {
OpportunityLineItem triggerHandlerOli;
if(OpportunityTriggerHandler.opportunityLineItems != null && OpportunityTriggerHandler.opportunityLineItems.get(oli.Id) != null){
triggerHandlerOli = OpportunityTriggerHandler.opportunityLineItems.get(oli.Id);
} else{
triggerHandlerOli = new OpportunityLineItem(Id = oli.Id, Express_Selected_Discount__c = oli.Express_Selected_Discount__c, Discount = oli.Discount, Express_Annual_Discount__c = oli.Express_Annual_Discount__c, Selected_Sales_Price__c = oli.Selected_Sales_Price__c, UnitPrice = oli.UnitPrice);
}
if (oli.ProductCode.contains('LIC')) {
if (newOpp.Selected_Payment_Type__c == 'Direct Annual') {
triggerHandlerOli.Express_Annual_Discount__c = (((newOpp.Total_License_Due__c - (newOpp.Total_License_Due__c * (1 - (newOpp.Express_Annual_Discount__c / 100)))) / (newOpp.Total_License_Due__c / (1 - (expressSelectedDiscount / 100)))) * 100);
if (newOpp.Express_Selected_Discount__c != null) {
triggerHandlerOli.Discount = newOpp.Express_Selected_Discount__c + triggerHandlerOli.Express_Annual_Discount__c;
} else if (triggerHandlerOli.Discount != null) {
triggerHandlerOli.Discount = triggerHandlerOli.Discount + triggerHandlerOli.Express_Annual_Discount__c;
} else {
triggerHandlerOli.Discount = triggerHandlerOli.Express_Annual_Discount__c;
}
if (newOpp.License_Term__c != null) {
triggerHandlerOli.Selected_Sales_Price__c = triggerHandlerOli.UnitPrice * (100 - triggerHandlerOli.Discount) / (newOpp.License_Term__c * 100);
} else {
triggerHandlerOli.Selected_Sales_Price__c = triggerHandlerOli.UnitPrice * (100 - triggerHandlerOli.Discount) / (36 * 100);
}
} else if (newOpp.Selected_Payment_Type__c == 'Upfront Payments') {
triggerHandlerOli.Express_Upfront_Discount__c = (((newOpp.Total_License_Due__c - (newOpp.Total_License_Due__c * (1 - (newOpp.Express_Upfront_Discount__c / 100)))) / (newOpp.Total_License_Due__c / (1 - (expressSelectedDiscount / 100)))) * 100);
if (newOpp.Express_Selected_Discount__c != null) {
triggerHandlerOli.Discount = newOpp.Express_Selected_Discount__c + triggerHandlerOli.Express_Upfront_Discount__c;
} else if (triggerHandlerOli.Discount != null) {
triggerHandlerOli.Discount = triggerHandlerOli.Discount + triggerHandlerOli.Express_Upfront_Discount__c;
} else {
triggerHandlerOli.Discount = triggerHandlerOli.Express_Upfront_Discount__c;
}
if (newOpp.License_Term__c != null) {
triggerHandlerOli.Selected_Sales_Price__c = triggerHandlerOli.UnitPrice * (100 - triggerHandlerOli.Discount) / (newOpp.License_Term__c * 100);
} else {
triggerHandlerOli.Selected_Sales_Price__c = triggerHandlerOli.UnitPrice * (100 - triggerHandlerOli.Discount) / (36 * 100);
}
} else {
triggerHandlerOli.Express_Annual_Discount__c = 0;
if (newOpp.Express_Selected_Discount__c != null) {
triggerHandlerOli.Discount = newOpp.Express_Selected_Discount__c + triggerHandlerOli.Express_Annual_Discount__c;
} else if (triggerHandlerOli.Discount != null) {
triggerHandlerOli.Discount = triggerHandlerOli.Discount + triggerHandlerOli.Express_Annual_Discount__c;
} else {
triggerHandlerOli.Discount = triggerHandlerOli.Express_Annual_Discount__c;
}
if (newOpp.License_Term__c != null) {
triggerHandlerOli.Selected_Sales_Price__c = triggerHandlerOli.UnitPrice * (100 - triggerHandlerOli.Discount) / (newOpp.License_Term__c * 100);
} else {
triggerHandlerOli.Selected_Sales_Price__c = triggerHandlerOli.UnitPrice * (100 - triggerHandlerOli.Discount) / (36 * 100);
}
}
//System.debug('Adding OpportunityLineItem to update: ' + triggerHandlerOli.Id);
opptyLToUpdate.add(triggerHandlerOli);
OpportunityTriggerHandler.opportunityLineItems.put(oli.Id, triggerHandlerOli);
}
}
}
//Zakeer-GTMS-5183-Feb17 //GTMS-13653
if(newOpp.Ship_From_Location__c != oldOppMap.get(newOpp.Id).Ship_From_Location__c
&& oppFields <> NULL && oppFields.get(newOpp.Id) <> NULL && oppFields.get(newOpp.Id).OpportunityLineItems <> NULL
&& !((oppFields.get(newOpp.Id).OpportunityLineItems).isEmpty())){
//System.debug('Updating Ship_From_Location for Opportunity: ' + newOpp.Id);
for(OpportunityLineItem l : oppFields.get(newOpp.Id).OpportunityLineItems){
if( !byPassShipFromLocation.contains(l.Ship_From_Location__c) && newOpp.Ship_From_Location__c != l.Ship_From_Location__c){
l.Ship_From_Location__c = newOpp.Ship_From_Location__c;
opptyLToUpdate.add(l);
}
}
}
}
/**
* @author Groundswell - Henry Zhao - henry@gscloudsolutions.com
* @date 2020-10-06
* @deprecated per request of Ron. This logic is no longer needed with the launch of CPQ
*/
if (opptyLToUpdate.size() > 0) {
//System.debug('Updating OpportunityLineItems: ' + opptyLToUpdate.size());        
OpportunityHelper.expressSetDiscountRun = true;
//update opptyLToUpdate;
DMLWrapper.doUpdate(opptyLToUpdate);
}
/*if (!prodCodesToDispatchMap.isEmpty() && !Test.isRunningTest() && !System.isBatch() && !System.isFuture() ) {
ValidateProductQuantityFuture.fetchProductQuantity(prodCodesToDispatchMap);
}*/
// DLC Warehouse Quantity future class changed to Queueable class as part of GTMS-22357
if(!prodCodesToDispatchMap.isEmpty() && !Test.isRunningTest() ){
ValidateProductQuantityQueueable que = new ValidateProductQuantityQueueable(prodCodesToDispatchMap);
System.enqueueJob(que);
}
} 
/**
* @author - Satya Dodda
* @date 2020-01-08
* @additional filter conditions for DCL automation
*/
public boolean checkDCLQualified(Opportunity newOpp, Opportunity oldOpp) {
boolean promoCheck = false;
boolean ftCheck = false;
if(newOpp.Type == 'Promo Opportunity' && String.isBlank(newOpp.Shipping_Instructions__c) && String.isBlank(newOpp.Netsuite_Id__c) &&
(newOpp.Sales_Tax__c == 0 || newOpp.Sales_Tax__c == null)&&
(newOpp.Balance_Due__c == 0 || newOpp.Balance_Due__c == null) &&
(newOpp.Shipping_and_Handling__c == 0 || newOpp.Shipping_and_Handling__c == null) &&
(newOpp.Shipping_and_Handling_Manual__c == 0 || newOpp.Shipping_and_Handling_Manual__c == null )&&
(newOpp.Shipping_and_Handling_Amount__c == 0 || newOpp.Shipping_and_Handling_Amount__c == null) &&
(newOpp.Owner_Role_Copy__c == 'Operations' || newOpp.Owner_Role_Copy__c == 'Management') &&
(newOpp.Shipping_Carrier__c == 'UPS')) {
promoCheck = true;
}
if(newOpp.Type == 'Free Trial Opportunity' && String.isBlank(newOpp.Netsuite_Transfer_Order__c) && String.isBlank(newOpp.Netsuite_Transfer_Order_ID__c)) {
ftCheck = true;
}
return (ftCheck || promoCheck);
}
// Promo opp criteria for automation
public boolean satisfyPromoOpp(Opportunity opp, Decimal productCount){
if((opp.Sales_Tax__c == 0 || opp.Sales_Tax__c == null) && (opp.Balance_Due__c == 0 || opp.Balance_Due__c == null) && (opp.Shipping_and_Handling__c == 0 || opp.Shipping_and_Handling__c == null)
&& (opp.Shipping_and_Handling_Manual__c == 0 || opp.Shipping_and_Handling_Manual__c == null ) && (opp.Shipping_and_Handling_Amount__c == 0 || opp.Shipping_and_Handling_Amount__c == null)
&& ((opp.Shipping_Country__c != 'Mexico' && productCount <= 50) || (opp.Shipping_Country__c == 'Mexico' && productCount <= 100))){
return true;
}
return false;
}
// Free-Trail opp criteria for automation
public boolean satisfyFreeTrailOpp(Opportunity opp, Decimal productCount){
if(((opp.Shipping_Country__c != 'Mexico' && productCount <= 50) || (opp.Shipping_Country__c == 'Mexico' && productCount <= 100)) && opp.Trial_Agreement_Accepted__c && opp.Shipping_Contact__c!= null && String.isBlank(opp.Netsuite_Transfer_Order_ID__c) && String.isBlank(opp.Netsuite_Transfer_Order__c)){
return true;
}
return false;
}
//Revenue opp criteria for automation
// Modified the satisfyRevenueOpp filter conditions for GTMS-18017 and GTMS-10999
public boolean satisfyRevenueOpp(Opportunity opp, Decimal productCount){
if(opp.Shipping_Country__c != 'Mexico' && (opp.Shipping_and_Handling__c != null && opp.Shipping_and_Handling__c < 99999) && (opp.Total_Weight_oz__c < 25000 || opp.Total_Weight_oz__c < 6500) &&
((opp.Owner_Segment__c == 'SMB' || opp.Owner_Segment__c == 'Small business') ||
(opp.Segment_Sales_Role__c == 'AE1' && opp.Free_Trial_Purchase__c == null && productCount < 250) ||
((opp.Segment_Sales_Role__c == 'AE2' || opp.Segment_Sales_Role__c == 'AE3' || opp.Segment_Sales_Role__c == 'Enterprise') && (opp.name.contains('Webstore') ? (opp.Free_Trial_Purchase__c == NULL) : (opp.Free_Trial_Purchase__c == 'No Purchase')) && productCount < 3000 &&
((opp.CurrencyIsoCode == 'GBP' || opp.CurrencyIsoCode == 'EUR' || opp.CurrencyIsoCode == 'CHR' || opp.CurrencyIsoCode == 'USD' || opp.CurrencyIsoCode == 'CAD' || opp.CurrencyIsoCode == 'MXN') && opp.Amount < 100000))
)) {
// commented the below if block for GTMS-18017 and GTMS-10999
/* if(opp.Shipping_Method__c == 'Next Day Air' && opp.Shipping_and_Handling__c < 100){
return false;
}*/
return true;
}else if(opp.Shipping_Country__c == 'Mexico' && (opp.Shipping_and_Handling__c != null && opp.Shipping_and_Handling__c < 99999) && opp.Total_Weight_oz__c < 6500 &&
((opp.Segment_Sales_Role__c == 'AE2' || opp.Segment_Sales_Role__c == 'Enterprise') && (opp.name.contains('Webstore') ? (opp.Free_Trial_Purchase__c == NULL) : (opp.Free_Trial_Purchase__c == 'No Purchase')) && productCount < 3000 &&
((opp.CurrencyIsoCode == 'GBP' || opp.CurrencyIsoCode == 'EUR' || opp.CurrencyIsoCode == 'CHR' || opp.CurrencyIsoCode == 'USD' || opp.CurrencyIsoCode == 'CAD' || opp.CurrencyIsoCode == 'MXN') && opp.Amount < 100000))
) {
return true;
}
return false;
}
public Integer getQtyLimitPerProduct(String oppType){
if(oppType == 'Free Trial Opportunity' || oppType == 'Promo Opportunity')
return 10;
else if(oppType == 'Revenue Opportunity')
return 20;
return null;
}
// Modified the satisfyMatchingconditions filter conditions for GTMS-18017 and GTMS-10999
public boolean satisfyMatchingconditions(Opportunity opp){
if(!opp.Multi_Line_Shipping__c && String.isBlank(opp.Shipping_Instructions__c) && opp.Order_Ops_Notes__c == null && String.isBlank(opp.Internal_RFO_Notes__c) && opp.Hold_Reason__c == null && (opp.Price_Book_Name__c != null && opp.Price_Book_Name__c == 'Samsara FY22')
/*&& opp.Unique_Shipping_Addresses__c == 1 */ && (opp.Shipping_Carrier__c == 'UPS' || opp.Shipping_Carrier__c == 'Estafeta') && !validatePoBox(opp.Concatenated_Shipping_Address__c)
//added below condition for GTMS-10997
&& (opp.Shipping_Method__c == '3 Day Select' || opp.Shipping_Method__c == 'Ground' || opp.Shipping_Method__c == 'Next Day Air' || opp.Shipping_Method__c == 'Worldwide Expedited'  || opp.Shipping_Method__c == 'MX Express' || opp.Shipping_Method__c == 'MX Standard') && (opp.Ship_From_Location__c == 'DCL-LA' || opp.Ship_From_Location__c == 'DCL-KY' || opp.Ship_From_Location__c == 'ON-Logistics' || opp.Ship_From_Location__c == 'Estafeta')){
return true;
}
return false;
}
public boolean validatePoBox(String Address){
String regex = '(?si).*\\b(p\\.?\\s*o\\.?\\s*|.*post\\s+office)\\s+box.*';
Pattern pattern = Pattern.compile(regex);
Matcher matcher = pattern.matcher(Address);
return matcher.matches();
}
//DML wrapper cannot be used as future method been invoked and required ids from the DML
public void freeTrialQuoteCreator(Map<Id, Opportunity> oldOppMap, Map<Id, Opportunity> newOppMap, List<Opportunity> newOppList) {
Id freeTrailTemplateId;
if (checkRecursive.runOnce('FreeTrialInvoice', 'FreeTrialInvoiceTrigger') && !System.isFuture()) {
boolean free_trial_invoice = false;
for (Opportunity o : newOppList) {
if (newOppMap.get(o.Id).Type == 'Free Trial Opportunity' && newOppMap.get(o.Id).Send_Invoice__c == True && oldOppMap.get(o.Id).Send_Invoice__c != newOppMap.get(o.Id).Send_Invoice__c) {
free_trial_invoice = true;
}
}
//EmailTemplate et;
OrgWideEmailAddress owa;
List<Opportunity> opps;
List<OpportunityLineItem> line_items;
if (free_trial_invoice) {
//et = [Select Id, Subject, HtmlValue, Body from EmailTemplate where Name = 'FT Invoice Email'];
if (!(trailLangugeTemplateIdMap.size() > 0)) {
trailLangugeTemplateIdMap = TemplateSelectionHelper.getTemplates('Free Trail');
}
owa = [select Id from OrgWideEmailAddress Where Address = 'trials@samsara.com'];
opps = [
Select Id, Name, PriceBook2Id, Trial_Primary_Contact__c, Trial_Primary_Contact__r.Id, Trial_Primary_Contact__r.Email,
Account.Billing_Email__c, Account.Name, Account.Which_written_language__c, Account.Owner.Email,
Trial_primary_contact__r.isEmailBounced , Shipping_Contact_Email__c //GTMS-8575
from Opportunity
where Id in :newOppMap.keySet()
];
line_items = [
SELECT Description,Id,Discount,ListPrice,Name,OpportunityId,Product2Id,PriceBookEntryId,ProductCode,Quantity,TotalPrice,UnitPrice
FROM OpportunityLineItem
where OpportunityId in :newOppMap.keySet()
];
for (Opportunity o : opps) {
String language;
if (newOppMap.get(o.Id).Type == 'Free Trial Opportunity' && newOppMap.get(o.Id).Send_Invoice__c == True && oldOppMap.get(o.Id).Send_Invoice__c != newOppMap.get(o.Id).Send_Invoice__c) {
Quote q = new Quote();
q.Name = 'FT Quote-' + o.name;
q.OpportunityId = o.Id;
q.PriceBook2Id = o.PriceBook2Id;
q.ContactId = o.Trial_Primary_Contact__c;
q.BillingName = o.Account.Name;
q.Email = o.Account.Billing_Email__c;
insert q;
for (OpportunityLineItem oli : line_items) {
if (oli.OpportunityId == o.Id) {
QuoteLineItem qLine = new QuoteLineItem();
qLine.QuoteId = q.Id;
qLine.Quantity = oli.Quantity;
qLine.UnitPrice = oli.UnitPrice;
qLine.Discount = oli.Discount;
qLine.PriceBookEntryId = oli.PriceBookEntryId;
insert qLine;
}
}
language = o.Account.Which_written_language__c;
if ((!String.isBlank(language)) && (trailLangugeTemplateIdMap.containsKey(language))) {
freeTrailTemplateId = trailLangugeTemplateIdMap.get(language);
} else {
freeTrailTemplateId = trailLangugeTemplateIdMap.get('English');
}
//GTMS-8575
String validEmail = '';
validEmail = o.Trial_primary_contact__r.isEmailBounced ? (o.Account.Billing_Email__c != null ? o.Account.Billing_Email__c : o.Shipping_Contact_Email__c) : o.Trial_Primary_Contact__r.Email;
if(validEmail != null && validEmail != ''){
//GTMS-8575
FreeTrialInvoicing.sendEmail(q.Id, o.Id, o.Trial_Primary_Contact__r.Id, o.Account.Owner.Email, validEmail, owa.Id, freeTrailTemplateId);
}
}
}
}
}
}
public void rebateBuyoutSubsidyToNetsuite(Map<Id, Opportunity> oldOppMap, Map<Id, Opportunity> newOppMap, List<Opportunity> newOppList) {
if (HelperClass.firstRun) {
for (Opportunity o : newOppMap.values()) {
if (!(Test.isRunningTest()) && o.Type == 'Rebate' && newOppMap.get(o.Id).StageName.equals('Finance Processing') && o.Returning_Opportunity_Closed_Won__c == true && oldOppMap.get(o.Id).Push_Return_to_Netsuite__c != true &&
newOppMap.get(o.Id).Push_Return_to_Netsuite__c == true && String.isBlank(o.Corresponding_Netsuite_ID__c)) {
if (o.Rebate_Type__c == 'Renewal Credit') {
integrator_da__.RealTimeExporter.run('rebate-renewal-credit-sync');
}
HelperClass.firstRun = false;
}
}
}
}
public void deleteQuotaOpportunityRecords(Map<Id, Opportunity> oldOppMap,
            Map<Id, Opportunity> newOppMap,
            List<Opportunity> newOppList) {
                Set<Id> filteredOpportunityIds = new Set<Id>();
                List<Quota_Opportunity__c> relatedQuotaOpportunities = new List<Quota_Opportunity__c>();
                for (Opportunity updatedOpportunity : newOppList) {
                    if ((oldOppMap.get(updatedOpportunity.Id).IsWon == true) && (newOppMap.get(updatedOpportunity.Id).IsWon == false)) {
                        filteredOpportunityIds.add(updatedOpportunity.Id);
                    }
                }
                if ((Schema.sObjectType.Quota_Opportunity__c.isAccessible()) && (filteredOpportunityIds.size() > 0)) {
                    relatedQuotaOpportunities = [SELECT Id FROM Quota_Opportunity__c WHERE Opportunity__r.Id IN :filteredOpportunityIds];
                    if (relatedQuotaOpportunities.size() > 0) {
                        try {
                            delete relatedQuotaOpportunities;
                        } catch (DMLException e) {
                            system.debug('Unable to delete the QO records because of the following exception: ' + e.getMessage());
                        }
                    }
                }
            }
public void accountFieldUpdate(List<Opportunity> lstOpportunityNew, Map<Id, Opportunity> mapOpportunityOld) {
loadOppAccounts(lstOpportunityNew);
Map<Id, Account> mapAccount = new Map<Id, Account>();
Set<Id> closedWonOpportunityIdSet = new Set<Id>();
for(Opportunity opp : lstOpportunityNew){
if(opp.StageName == 'Closed Won' && mapOpportunityOld.get(opp.Id).StageName != 'Closed Won'){
closedWonOpportunityIdSet.add(opp.Id);
}
}
Map<Id, Channel_Relationship__c> opptyIdToChannelRelMap = new Map<Id, Channel_Relationship__c>();
if(!closedWonOpportunityIdSet.isEmpty()){
for(Channel_Relationship__c chnl : [Select Id, Opportunity__c, Channel_Partner__c, Program_Type__c, CreatedDate from Channel_Relationship__c where Opportunity__c IN :closedWonOpportunityIdSet]){
if((opptyIdToChannelRelMap.containsKey(chnl.Opportunity__c) && opptyIdToChannelRelMap.get(chnl.Opportunity__c).CreatedDate < chnl.CreatedDate) || !opptyIdToChannelRelMap.containsKey(chnl.Opportunity__c)){
opptyIdToChannelRelMap.put(chnl.Opportunity__c, chnl);
}
}
}
for (Opportunity opp : lstOpportunityNew) {
Account a = oppAccountsRev.get(opp.AccountId);
String accountStatus;
if(opptyIdToChannelRelMap.containsKey(opp.Id)){
if(a.Id <> opptyIdToChannelRelMap.get(opp.Id).Channel_Partner__c){ //GTMS-13629
a.Latest_Partner_Account_Interaction__c = opptyIdToChannelRelMap.get(opp.Id).Channel_Partner__c;
}
a.Latest_Partner_Program_Interaction__c = opptyIdToChannelRelMap.get(opp.Id).Program_Type__c;
}
Opportunity oldOpp = new Opportunity();
Boolean oldOppNull = true;
if (mapOpportunityOld != null) {
oldOpp = mapOpportunityOld.get(opp.Id);
oldOppNull = false;
}
if (a != null) {
if (a.Status__c != 'Open Opportunity' && opp.StageName != 'Closed Lost' && opp.StageName != 'Closed Won'
&& ((opp.StageName != oldOpp.StageName && !oldOppNull) || oldOppNull) && opp.Type == 'Revenue Opportunity') {
accountStatus = 'Open Opportunity';
} else if (opp.StageName == 'Closed Won' && opp.StageName != oldOpp.StageName && opp.Type == 'Revenue Opportunity') {
accountStatus = 'Existing Customer';
}
//Sri Global - Anil Bogadi: Last order opportunity link in Account Object - GTMS-3913.
if( opp.StageName == 'Closed Won' && opp.StageName != oldOpp.StageName && opp.Type == 'Revenue Opportunity'){
    a.Link_to_Last_Order__c  = URL.getOrgDomainUrl().toExternalForm() + '/' + opp.Id;
}
if (accountStatus != null) {
a.Status__c = accountStatus;
DMLWrapper.doUpdate(a, new List<SObjectField>{
Account.Status__c
});
}
}
// Groundswell : Tanuj - WFlow Rule - Update Account for NS Sync
Account thisOppAccount = new Account();
if (opp.AccountId != NULL && oppAccounts.containsKey(opp.AccountId)) {
thisOppAccount = oppAccounts.get(opp.AccountId);
OpportunityWorkflowConversion.afterUpdateMethod(opp, oldOpp, thisOppAccount);
OpportunityWorkflowConversion.afterInsertUpdateMethod(opp, oldOpp, thisOppAccount);
}
}
}
//GTMS-13689 //GTMS -19921 adding new changes related to this Jira
private static Object managerFormula(Opportunity newOpportunity, Opportunity oppty, String managerType) {
Object returnObject = null; 
User opportunityOwner = mapUsers.containsKey(newOpportunity.ownerId) ? mapUsers.get(newOpportunity.ownerId) : null;//GTMS - 19921
if (oppty.Type == 'Revenue Opportunity' || oppty.Type == 'Free Trial Opportunity'
|| oppty.Type == 'Promo Opportunity' || ((oppty.Type == 'Rebate' || oppty.Type == 'Remorse Refund')
                    && opportunityOwner != null && opportunityOwner.Level__c != null && oppty.Returning_Opportunity__c != null && oppty.Returning_Opportunity__r.Owner.Level__c != null
                    && opportunityOwner.Level__c.equals('AE 1') && oppty.Returning_Opportunity__r.Owner.Level__c.equals('AE 1'))) {
                        switch on managerType {
                            when 'Manager Name' {
                                if(oppty.Owner_Role_Copy__c <> null && (oppty.Owner_Role_Copy__c.contains('Regional') || oppty.Owner_Role_Copy__c.contains('Rover')) && oppty.SBQQ__PrimaryQuote__c <> null && oppty.SBQQ__PrimaryQuote__r.SBQQ__SalesRep__c <> null){
                                    returnObject = oppty.SBQQ__PrimaryQuote__r.SBQQ__SalesRep__r.ManagerId;
                                }else{
                                    returnObject = opportunityOwner.ManagerId;
                                }
                            }
                            when 'Manager Role' {
                                if(oppty.Owner_Role_Copy__c <> null && (oppty.Owner_Role_Copy__c.contains('Regional') || oppty.Owner_Role_Copy__c.contains('Rover')) &&oppty.SBQQ__PrimaryQuote__c <> null && oppty.SBQQ__PrimaryQuote__r.SBQQ__SalesRep__c <> null){
                                    returnObject = oppty.SBQQ__PrimaryQuote__r.SBQQ__SalesRep__r.Manager.UserRole.Name;
                                }else{
                                    returnObject = opportunityOwner.Manager.UserRole.Name;
                                }
                            }
                            when 'Director Name' {
                                if(opportunityOwner.Manager.Manager.Level__c != null && opportunityOwner.Manager.Manager.Level__c.contains('ISD')){
                                    returnObject = opportunityOwner.Manager.ManagerId;
                                }
                                else if(opportunityOwner.Manager.Level__c != null && opportunityOwner.Manager.Level__c.contains('ISD')){
                                    returnObject = opportunityOwner.ManagerId;
                                }
                                else{
                                    returnObject = opportunityOwner.Manager.ManagerId;
                                }
                            }
                            //GTMS-26431 Copy Owner Director Email
                            when 'Director Email' {
                                if(opportunityOwner.Manager.Manager.Level__c != null && opportunityOwner.Manager.Manager.Level__c.contains('ISD')){
                                    returnObject = opportunityOwner.Manager.Email;
                                }
                                else if(opportunityOwner.Manager.Level__c != null && opportunityOwner.Manager.Level__c.contains('ISD')){
                                    returnObject = opportunityOwner.Email;
                                }
                                else{
                                    returnObject = opportunityOwner.Manager.Email;
                                }
                            }
                            when 'Manager Email' {
                                if(oppty.Owner_Role_Copy__c <> null && (oppty.Owner_Role_Copy__c.contains('Regional') || oppty.Owner_Role_Copy__c.contains('Rover')) && oppty.SBQQ__PrimaryQuote__c <> null && oppty.SBQQ__PrimaryQuote__r.SBQQ__SalesRep__c <> null){
                                    returnObject = oppty.SBQQ__PrimaryQuote__r.SBQQ__SalesRep__r.Manager.Email;
                                }else{
                                    returnObject = opportunityOwner.Manager.Email;
                                }
                            }
                            when 'DirectorsManagersName' {
                                if(opportunityOwner.Manager.Sales_User_Type__c != NULL || opportunityOwner.Manager.Manager.Sales_User_Type__c != NULL || opportunityOwner.Manager.Manager.Manager.Sales_User_Type__c != NULL){
                                    //returnObject = opportunityOwner.Manager.Manager.Manager.Name;
                                    returnObject = opportunityOwner.Manager.Sales_User_Type__c != null ? opportunityOwner.Manager.Name : (opportunityOwner.Manager.Manager.Sales_User_Type__c != null ? opportunityOwner.Manager.Manager.Name :(opportunityOwner.Manager.Manager.Manager.Sales_User_Type__c != null ? opportunityOwner.Manager.Manager.Manager.Name :''));
                                        }
                            }
                            when 'DirectorsManagersRole' {
                                if(opportunityOwner.Manager.Sales_User_Type__c != NULL || opportunityOwner.Manager.Manager.Sales_User_Type__c != NULL || opportunityOwner.Manager.Manager.Manager.Sales_User_Type__c != NULL){
                                    //returnObject = opportunityOwner.Manager.Manager.Manager.UserRole.Name;
                                    returnObject = opportunityOwner.Manager.Sales_User_Type__c != null ? opportunityOwner.Manager.UserRole.Name : (opportunityOwner.Manager.Manager.Sales_User_Type__c != null ? opportunityOwner.Manager.Manager.UserRole.Name :(opportunityOwner.Manager.Manager.Manager.Sales_User_Type__c != null ? opportunityOwner.Manager.Manager.Manager.UserRole.Name :''));
                                        }
                            }
                            //GTMS-17681 -- Start -- Added logic to set Sales_User_Type__c of User's Manager and their manager by checking if Sales_User_Type__c not blank and set it to Owner_AVP_Team__c  on Oppty
                            when 'DirectorsManagersSalesUserType' {
                                if(opportunityOwner.Manager.Sales_User_Type__c != NULL || opportunityOwner.Manager.Manager.Sales_User_Type__c != NULL || opportunityOwner.Manager.Manager.Manager.Sales_User_Type__c != NULL){
                                    returnObject = opportunityOwner.Manager.Sales_User_Type__c != null ? opportunityOwner.Manager.Sales_User_Type__c : (opportunityOwner.Manager.Manager.Sales_User_Type__c != null ? opportunityOwner.Manager.Manager.Sales_User_Type__c :(opportunityOwner.Manager.Manager.Manager.Sales_User_Type__c != null ? opportunityOwner.Manager.Manager.Manager.Sales_User_Type__c :''));
                                        }
                            }
                            //GTMS-17681 -- End
                        }
                    }else if((newOpportunity.Type == 'Rebate'
                            || newOpportunity.Type == 'Remorse Refund')
                            && managerType == 'Manager Email'){
                                switch on managerType {
                                    when 'Manager Email' {
                                        returnObject = oppty.Returning_Opportunity__r.Owner_Manager_Email_Copy__c;
                                    }
                                }
                            } else {
                                switch on managerType {
                                    when 'Manager Name' {
                                        returnObject = oppty.Returning_Opportunity__r.Owner_Manager_Name_Copy__c;
                                    }
                                    when 'Manager Role' {
                                        returnObject = oppty.Returning_Opportunity__r.Owner_Manager_Role_Copy__c;
                                    }
                                    when 'Director Name' {
                                        returnObject = oppty.Returning_Opportunity__r.Owner_Director_Name_Copy__c;
                                    }
                                    //GTMS-26431 Copy Owner Director Email
                                    when 'Director Email' {
                                        returnObject = oppty.Returning_Opportunity__r.Owner_Director_Email_Copy__c;
                                    }
                                    when 'DirectorsManagersName' {
                                        if(oppty.Returning_Opportunity__r.Owner_AVP_Name_Copy__c != NULL){
                                            returnObject = oppty.Returning_Opportunity__r.Owner_AVP_Name_Copy__c;
                                        } else if(opportunityOwner.Manager.Manager.Manager != NULL){
                                            //returnObject = opportunityOwner.Manager.Manager.Manager.Name;
                                            returnObject = opportunityOwner.Manager.Sales_User_Type__c != null ? opportunityOwner.Manager.Name : (opportunityOwner.Manager.Manager.Sales_User_Type__c != null ? opportunityOwner.Manager.Manager.Name :(opportunityOwner.Manager.Manager.Manager.Sales_User_Type__c != null ? opportunityOwner.Manager.Manager.Manager.Name :''));
                                                }
                                    }
                                    when 'DirectorsManagersRole' {
                                        if(oppty.Returning_Opportunity__r.Owner_AVP_Role_Copy__c != NULL){
                                            returnObject = oppty.Returning_Opportunity__r.Owner_AVP_Role_Copy__c;
                                        } else if(opportunityOwner.Manager.Manager.Manager.UserRole != NULL) {
                                            //returnObject = opportunityOwner.Manager.Manager.Manager.UserRole.Name;
                                            returnObject = opportunityOwner.Manager.Sales_User_Type__c != null ? opportunityOwner.Manager.UserRole.Name : (opportunityOwner.Manager.Manager.Sales_User_Type__c != null ? opportunityOwner.Manager.Manager.UserRole.Name :(opportunityOwner.Manager.Manager.Manager.Sales_User_Type__c != null ? opportunityOwner.Manager.Manager.Manager.UserRole.Name :''));
                                                }
                                    }
                                    //GTMS-17681 -- Start -- Added logic to set Sales_User_Type__c of User's Manager and their manager by checking if Sales_User_Type__c not blank and set it to Owner_AVP_Team__c  on Oppty
                                    when 'DirectorsManagersSalesUserType' {
                                        if(oppty.Returning_Opportunity__r.Owner_AVP_Team__c != NULL){
                                            returnObject = oppty.Returning_Opportunity__r.Owner_AVP_Team__c;
                                        } else if(opportunityOwner.Manager.Sales_User_Type__c != NULL || opportunityOwner.Manager.Manager.Sales_User_Type__c != NULL || opportunityOwner.Manager.Manager.Manager.Sales_User_Type__c != NULL){
                                            returnObject = opportunityOwner.Manager.Sales_User_Type__c != null ? opportunityOwner.Manager.Sales_User_Type__c : (opportunityOwner.Manager.Manager.Sales_User_Type__c != null ? opportunityOwner.Manager.Manager.Sales_User_Type__c :(opportunityOwner.Manager.Manager.Manager.Sales_User_Type__c != null ? opportunityOwner.Manager.Manager.Manager.Sales_User_Type__c :''));
                                                }
                                    }
                                }
                            }
return returnObject;
}
@testvisible
private static String extractOwnerGeographyCopy(Opportunity newOpp) {
List<String> opportunityTypes = new List<String>{
'Revenue Opportunity', 'Free Trial Opportunity', 'Promo Opportunity', 'Rebate', 'Remorse Refund'
};
if (opportunityTypes.contains(newOpp.Type)) {
return newOpp.Owner.Territory__c;
} else {
return newOpp.Returning_Opportunity__r.Owner.Territory__c;
}
}
public void syncOpportunity(List<Opportunity> newOpportunityList, Map<Id, Opportunity> oldMap) {
List<Opportunity> opptiesToUpdate = new List<Opportunity>();
for (Opportunity oppty : newOpportunityList) {
Opportunity oldOppty = oldMap.get(oppty.Id);
if (((Boolean.valueOf(orderTransformationSetting.Value__c) == false && (oppty.Type == 'Revenue Opportunity' || oppty.Type == 'Promo Opportunity'))
|| (Boolean.valueOf(orderTransformationSetting.Value__c) == true && oppty.Type == 'Promo Opportunity'))
&& oppty.StageName.equals('Ready to Ship')
&& ((oldOppty.StageName != oppty.StageName) || (oppty.Push_to_Mulesoft__c && (oldOppty.Push_to_Mulesoft__c != oppty.Push_to_Mulesoft__c)))
&& String.isBlank(oppty.Netsuite_Id__c)
&& oppty.Sync_in_Progress__c != true) {
oppty.Sync_in_Progress__c = true;
orderSyncEvents.add(new Order_Event__e(Id__c = oppty.Id, Type__c = oppty.Type));
}
    // || oppty.Type == 'Free Trial Opportunity' remove for GTMS-13390
if ((oppty.Type == 'Work Order' ) && oppty.StageName.equals('Ready to Ship') && ((oldOppty.StageName != oppty.StageName) || (oppty.Push_to_Mulesoft__c && (oldOppty.Push_to_Mulesoft__c != oppty.Push_to_Mulesoft__c)))
&& String.isBlank(oppty.Netsuite_Id__c) && oppty.Sync_in_Progress__c != true) {
oppty.Sync_in_Progress__c = true;
orderSyncEvents.add(new Order_Event__e(Id__c = oppty.Id, Type__c = oppty.Type));
}
// temp removed  oppty.StageName.equals('Finance Processing') && oppty.Returning_Opportunity_Closed_Won__c == true
    //3/24/25 Vijaychandra AMARANENI  (GTMS-28240): Added or condition to handle the case where the oppty is closed won and the stage is moved to finance processing and the push to netsuite is true and the rebate type is partner referral
if (oppty.Type == 'Rebate' && (oppty.Rebate_Type__c == 'Buyout' || oppty.Rebate_Type__c == 'Partner Referral' || oppty.Rebate_Type__c == 'Subsidy')
    && oppty.Returning_Opportunity_Closed_Won__c == true && ((oldOppty.Push_Return_to_Netsuite__c != true && oppty.Push_Return_to_Netsuite__c == true && oppty.StageName.equals('Finance Processing')) || (oppty.Push_Return_to_Netsuite__c == true && oppty.StageName.equals('Finance Processing') && oldOppty.StageName != 'Finance Processing' && oppty.Rebate_Type__c == 'Partner Referral'))
&& String.isBlank(oppty.Corresponding_Netsuite_ID__c) && oppty.Sync_in_Progress__c != true) {
oppty.Sync_in_Progress__c = true;
rebateSyncEvents.add(new Rebate_Event__e(Id__c = oppty.Id, Type__c = oppty.Type, Sub_Type__c = oppty.Rebate_Type__c));
}
}
}
public void createPlatformEvent() {
if(opportunityEvents.size() > 0){
List<Database.SaveResult> results = EventBus.publish(opportunityEvents);
}
if (orderSyncEvents.size() > 0) {
List<Database.SaveResult> results = EventBus.publish(orderSyncEvents);
}
if (rebateSyncEvents.size() > 0) {
List<Database.SaveResult> results = EventBus.publish(rebateSyncEvents);
}
} 
public static Map<Id, Opportunity> queryOpportunities(Set<Id>
                        opportunityIds) {
                            Map<Id, Opportunity> opportunitiesDataByIds = new Map<Id, Opportunity>([
                                SELECT Id, Name, CurrencyIsoCode,Pricebook2Id, Pricebook2.Name, Shipping_Address_NEW__c, Shipping_Address_NEW__r.Shipping_Country__c,
                                Shipping_Country__c, Shipping_Method__c, Type, Returning_Opportunity__r.Reseller_Partner__c, Bookings_Owner_Segment__c,Returning_Opportunity__r.Referral_Partner__r.Referral_Rebate__c,//GTMS-13490
                                Returning_Opportunity__r.Referral_Partner__c,Returning_Opportunity__r.Insurance_Partner__c,Insurance_Partner__c, StageName, Rebate_Type__c, Delinquent_Return_Past_180_Days__c,
                                OwnerId, RecordType.Name, Stripe_Subscription_Id__c, Finance_Notes__c, Express_Agreement_Accepted_Date__c, Owner_Segment__c,
                                Balance_Due__c, Rebate_Type_Formula__c, Returning_Opportunity__r.Buyout_Opportunity__c, Returning_Opportunity__r.Owner_Segment__c,Returning_Opportunity__r.Owner_Director_Role_Copy__c,
                                Returning_Opportunity__r.Subsidy_Opportunity__c, Returning_Opportunity__c, Returning_Opportunity__r.License_Term__c, Returning_Opportunity__r.License_End_Date__c,
                                Returning_Opportunity__r.Partner_Referral_Opportunity__c, Returning_Opportunity__r.CloseDate, Price_Book_Name__c, Payment_Token__c,
                                First_Purchase__c, Probability, IsClosed, Account.New_Billing_Process_Approved__c, Resend_Return_Email__c, Configuration_Segment__c,
                                Account.Overwrite_Validation_Rule__c, License_Term__c, CloseDate, IsWon, CPQ_Opportunity__c,SBQQ__AmendedContract__r.SBQQ__RenewalQuoted__c,
                                License_Term_Approval_Status__c, License_End_Date__c, ContractId, Approved_Discount__c, License_Start_Date__c,
                                Contract.EndDate, Contract.Original_Approved_Discount__c, Account.Latest_Active_Contract__c, Renewal__c, RecordTypeId,
                                Segment_Sales_Role__c, Account.Latest_Active_Contract__r.Original_Approved_Discount__c,
                                Account.Latest_Active_Contract__r.EndDate, netsuite_conn__Bill_To_Tier__c, netsuite_conn__Celigo_Contract__c,
                                Selected_Payment_Type__c, Discount_Approval_Status__c, Blended_Discount__c, Trial_Primary_Contact__c,
                                Trial_Primary_Contact__r.Trial_Deactivation_Email__c, ADR_Transfer__c,
                                ADR_Transfer__r.ADR_Manager_Name_Copy_at_Qualification__c, ADR_Transfer__r.ADR_Transfer_Qualified_Date__c,
                                ADR_Transfer__r.ADR_Transfer_By__r.ManagerId, ADR_Transfer__r.ADR_Role_Copy_at_Qualification__c,
                                ADR_Transfer__r.ADR_Transfer_By__r.UserRole.Name, ADR_Transfer__r.ADR_Transfer_Status__c, Amount, Account.CSM__c,
                                Account.CSM__r.FirstName, Account.CSM__r.LastName, Shipping_Instructions__c, Account_Approved_Payment_Type__c,Account.Payment_Terms__c,
                                Account.Approved_Payment_Type__c, Owner_Manager_Name_Copy__c, Returning_Opportunity__r.Owner_Manager_Name_Copy__c,
                                Owner.ManagerId, Owner.UserRole.Name, Owner_Role_Copy__c, Returning_Opportunity__r.Owner_Role_Copy__c, Owner_Director_Name_Copy__c,Owner_Director_Email_Copy__c,
                                Owner.Manager.ManagerId, Returning_Opportunity__r.Owner_Director_Name_Copy__c,Returning_Opportunity__r.Owner_Director_Email_Copy__c, Owner_Manager_Role_Copy__c, Owner.Manager.Email, Returning_Opportunity__r.Owner_Manager_Email_Copy__c,
                                Owner.Manager.UserRole.Name, Returning_Opportunity__r.Owner_AVP_Name_Copy__c, Returning_Opportunity__r.Owner_AVP_Role_Copy__c, Returning_Opportunity__r.Owner_Manager_Role_Copy__c, Overwrite_Validation_Rule__c,
                                Contract_Amount_Agreed_To__c, Shipping_Address_NEW__r.Shipping_Contact__c, Owner.Manager.Manager.Level__c, Owner.Manager.Level__c,
                                of_Serialized_Products__c, Shipping_Contact__c, Oppty_Owners_CSM__c,Returning_Opportunity__r.Owner.Name,
                                Owner_Geo_Copy__c, Owner.Territory__c, Owner_Director_Role_Copy__c, Owner_Manager_Email_Copy__c,
                                Returning_Opportunity__r.Id, Returning_Opportunity__r.Name, Returning_Opportunity__r.Owner.Territory__c, Owner.Level__c,
                                Returning_Opportunity__r.Owner.Level__c, Returning_Opportunity__r.Owner_Director_Name_Copy__r.Id, Owner_Director_Name_Copy__r.Manager.Name, Owner_Director_Name_Copy__r.Manager.UserRole.Name,
                                Account.Number_of_Vehicles__c, Owner.Manager.Manager.Manager.Name, Owner.Manager.Manager.Manager.UserRole.Name, Owner.Manager.Manager.Id, SBQQ__PrimaryQuote__c, SBQQ__PrimaryQuote__r.ApprovalStatus__c,
                                netsuite_conn__From_Contract__r.Original_Approved_Discount__c, netsuite_conn__From_Contract__c,ACV_Bookings_SOT__c,SBQQ__PrimaryQuote__r.sbqq__mastercontract__c,
                                SBQQ__PrimaryQuote__r.SBQQ__SalesRep__c,SBQQ__PrimaryQuote__r.SBQQ__SalesRep__r.ManagerId, SBQQ__PrimaryQuote__r.SBQQ__SalesRep__r.Manager.UserRole.Name,SBQQ__PrimaryQuote__r.SBQQ__SalesRep__r.Manager.Email,
                                Returning_Opportunity__r.Owner.UserRole.Name,Owner.Manager.Sales_User_Type__c, Owner.Manager.Manager.Sales_User_Type__c, Owner.Manager.Manager.Manager.Sales_User_Type__c,
                                Owner.Manager.Name, Owner.Manager.Manager.Name, Owner.Manager.Manager.UserRole.Name,Returning_Opportunity__r.Owner_AVP_Team__c,
                                (SELECT Id, Product_Type_Copy__c, Product_Code_Copy__c, Product2.Baseline_Cost__c, Ship_To__c, License_Term_Copy__c, Discount, Express_Upfront_Discount__c, Express_Annual_Discount__c, 
                                     Selected_Sales_Price__c, Express_Selected_Discount__c, UnitPrice,ProductCode, Quantity, Product2Id,Product2.ProductCode
                                FROM OpportunityLineItems)
                                FROM Opportunity
                                WHERE Id IN :opportunityIds
                            ]);
                            system.debug('opportunitiesDataByIds ::::>'+opportunitiesDataByIds);
                            return opportunitiesDataByIds;
                        }
/**
* @author Groundswell - Vikasm - vikas@gscloudsolutions.com
* @date 2020-08-31
* Not yet deployed for Production
* GTMS-1471
*/
//GTMS-9688-Zakeer-CI-Conversion from sync to Async-Future
public void calculateAllRollUpsToAccount(List<Opportunity> oppList, Map<Id, Opportunity> OldOpportunitiesMap) {
CustomRollupsInAsync__c asyncSetting = CustomRollupsInAsync__c.getInstance();
if (asyncSetting != null && asyncSetting.Async__c != null && asyncSetting.Async__c == false){
mapOFRollupFieldVsMetadata = RollUpSwitchService.getRollupSwitchMetadata('Account', 'Opportunity');
if (mapOFRollupFieldVsMetadata.isEmpty()) return;
loadOppTargetRollupAccountSet(oppList, OldOpportunitiesMap);
loadTargetOpportunities();
calculateAllRollUpsToAccount();
}else{
if(System.isFuture() || System.isScheduled() || System.isQueueable() || System.isBatch()) return;
String JsonNewOppList = JSON.serialize(oppList);
String JsonOldOppMap = JSON.serialize(OldOpportunitiesMap);
if(!futureCustomRollupRan){
calculateAllRollUpsToAccountFuture(JsonNewOppList, JsonOldOppMap);
futureCustomRollupRan = true;
}
}
}
@future
public static void calculateAllRollUpsToAccountFuture(String jsonOppList, String jsonOldOppMap){
List<Opportunity> oppList = (List<Opportunity>)JSON.deserialize(jsonOppList,List<Opportunity>.class);
Map<Id, Opportunity> OldOpportunitiesMap = new Map<Id, Opportunity>();
if(jsonOldOppMap != NULL){
OldOpportunitiesMap = (Map<Id, Opportunity>)JSON.deserialize(jsonOldOppMap,Map<Id, Opportunity>.class);
}
//Map<String, Rollup_Switch__mdt> mapOFRollupFieldVsMetadata = new Map<String, Rollup_Switch__mdt> ();
AccountTriggerHandler.alreadyRan = true;
isFutureCustomRollup = true;
mapOFRollupFieldVsMetadata = RollUpSwitchService.getRollupSwitchMetadata('Account', 'Opportunity');
if (mapOFRollupFieldVsMetadata.isEmpty()) return;
loadOppTargetRollupAccountSet(oppList, OldOpportunitiesMap);
loadTargetOpportunities();
calculateAllRollUpsToAccount();
}
/**
* @author Groundswell - Vikasm - vikas@gscloudsolutions.com
* @date 2020-08-31
* Not yet deployed for Production
* GTMS-1471
* Todo : Dynamic query for rollup fields
*/
// Anil Bogadi GTMS-4452
private static void loadTargetOpportunities() {
targetOpportunities = [
SELECT Id,Name, Owner.Name, AccountId, Type, StageName, ACV_Bookings_SOT__c,
ExpectedRevenue, IsClosed, Probability,
CreatedDate, CloseDate, Active_Opportunity__c,
Monthly_Deal_or_Monthly_Return__c, License_End_Date__c,
Total_License_Due__c, Returning_Opportunity__c, Returning_Opportunity__r.License_End_Date__c
FROM Opportunity
WHERE AccountId IN :targetRollupAccountSet
];
}
/**
* @author Groundswell - Vikasm - vikas@gscloudsolutions.com
* @date 2020-08-31
* Not yet deployed for Production
* GTMS-1471
*/
//GTMS-9688-Zakeer-CI
private static void calculateAllRollUpsToAccount() {
//Map<String, Rollup_Switch__mdt> mapOFRollupFieldVsMetadata = new Map<String, Rollup_Switch__mdt> ();
mapOFRollupFieldVsMetadata = RollUpSwitchService.getRollupSwitchMetadata('Account', 'Opportunity');
Map<string, Map<String, List<Opportunity>>> mapOfRollupFiledVsRecordList = new Map<string, Map<String, List<Opportunity>>> ();
if (isFutureCustomRollup) DMLWrapper.intializeUnitOfWork(MY_SOBJECTS);
//TODO: Condition for Accounts with no Opp
for (String accountId : targetRollupAccountSet) {
for (String rollUpField : mapOFRollupFieldVsMetadata.KeySet()) {
if (!mapOfRollupFiledVsRecordList.ContainsKey(rollUpField)) mapOfRollupFiledVsRecordList.put(rollUpField, new Map<String, List<Opportunity>>());
if (!mapOfRollupFiledVsRecordList.get(rollUpField).containsKey(accountId))
mapOfRollupFiledVsRecordList.get(rollUpField).put(accountId, new List<Opportunity>());
}
}
for (Opportunity thisOpp : targetOpportunities) {
if (thisOpp.AccountId == null)
continue;
for (String rollUpField : mapOFRollupFieldVsMetadata.KeySet()) {
//Callable callInstance = (Callable) Type.forName('OpportunityHelper').newInstance();
if ((Boolean) callInstance.call(rollUpField, new map<String, Object>{
'newRecord' => thisOpp
})) {
if (!mapOfRollupFiledVsRecordList.ContainsKey(rollUpField)) mapOfRollupFiledVsRecordList.put(rollUpField, new Map<String, List<Opportunity>>());
if (!mapOfRollupFiledVsRecordList.get(rollUpField).containsKey(thisOpp.AccountId))
mapOfRollupFiledVsRecordList.get(rollUpField).put(thisOpp.AccountId, new List<Opportunity>());
mapOfRollupFiledVsRecordList.get(rollUpField).get(thisOpp.AccountId).add(thisOpp);
}
}
}
Map<String, Schema.SObjectField> accountFieldMap = Account.getSObjectType().getDescribe().fields.getMap();
//Zakeer
Map<String, Account> mapAcc = new Map<String, Account>();
for (String rollupField : mapOFRollupFieldVsMetadata.KeySet()) {
if (!mapOfRollupFiledVsRecordList.containsKey(rollupField)) {
continue;
}
Schema.SobjectField theDirtyField = accountFieldMap.get(rollupField);
for (String accountId : mapOfRollupFiledVsRecordList.get(rollupField).keySet()) {
/*if (!accountUpdateMap.ContainsKey(accountId)) {
accountUpdateMap.put(accountId, new Account(Id = accountId));
}*/
Account thisAccount = new Account(Id = accountId);
//Callable callInstance = (Callable) Type.forName('OpportunityHelper').newInstance();
if (mapOfRollupFiledVsRecordList.get(rollupField).get(accountId).isEmpty()) {
if (rollupField == 'Open_Opportunity__c') {
thisAccount.put(rollupField, false);
}else{
thisAccount.put(rollupField, null);
//accountUpdateMap.get(accountId).put(rollupField, null);
}
DMLWrapper.doUpdate(thisAccount, new List<SobjectField>{
theDirtyField
});
continue;
}
if (mapOFRollupFieldVsMetadata.get(rollupField).Type__c == 'SUM') {
Object result;
//GTMS-1582 Not a normal rollup run time field calculation needed
if (rollupField == 'Current_Monthly_Payments__c') {
result = calculateCurrentMonthlyPayments(mapOfRollupFiledVsRecordList.get(rollupField).get(accountId));
} else {
result = callInstance.call('SUM', new map<String, Object>{
'recordList' => mapOfRollupFiledVsRecordList.get(rollupField).get(accountId), 'field' => mapOFRollupFieldVsMetadata.get(rollupField).Rollup_Field__c
});
}
if (result == null) continue;
thisAccount.put(rollupField, (Decimal) result);
} else if (mapOFRollupFieldVsMetadata.get(rollupField).Type__c == 'MAX') {
Object result = callInstance.call('MAX', new map<String, Object>{
'recordList' => mapOfRollupFiledVsRecordList.get(rollupField).get(accountId), 'field' => mapOFRollupFieldVsMetadata.get(rollupField).Rollup_Field__c
});
if (result == null) continue;
thisAccount.put(rollupField, (Decimal) result);
} else if (mapOFRollupFieldVsMetadata.get(rollupField).Type__c == 'FIRST') {
Object result = callInstance.call('FIRST', new map<String, Object>{
'recordList' => mapOfRollupFiledVsRecordList.get(rollupField).get(accountId), 'field' => mapOFRollupFieldVsMetadata.get(rollupField).Rollup_Field__c
});
if (result == null) continue;
Opportunity firstOpp = new Opportunity();
firstOpp = (Opportunity) result;
//Exception GTMS-1587 Open_Opportunity__c is Boolean field
if (rollupField == 'Open_Opportunity__c') {
thisAccount.put(rollupField, true);
} else {
thisAccount.put(rollupField, firstOpp.Id);
}
}
DMLWrapper.doUpdate(thisAccount, new List<SobjectField>{
theDirtyField
});
}
}
if(isFutureCustomRollup) DMLWrapper.publishDML();
}
/**
* @author Groundswell - Vikasm - vikas@gscloudsolutions.com
* @date 2020-08-31
* Not yet deployed for Production
* GTMS-1471
*/
private boolean rollup_ACV_Bookings_SOTCondition(Opportunity thisOpp) {
return ((thisOpp.Type == 'Revenue Opportunity' && thisOpp.StageName == 'Closed Won')
|| (thisOpp.Type == 'Remorse Refund' && thisOpp.StageName == 'Refunded - Closed')
|| (thisOpp.Type == 'Rebate' && thisOpp.StageName == 'Refunded - Closed'));
}
private boolean rollup_ExpectedRevenueCondition(Opportunity thisOpp) {
return (thisOpp.IsClosed == False && thisOpp.Type == 'Revenue Opportunity');
}
//GTMS-4452 - Anil Bogadi
private boolean rollup_ProbabilityCondition(Opportunity thisOpp) {
// return (thisOpp.IsClosed == False && thisOpp.Type == 'Revenue Opportunity');
return (thisOpp.IsClosed == False && thisOpp.Type == 'Revenue Opportunity' && !thisOpp.Name.contains('Renewal') && thisOpp.Owner.Name != 'Samsara Small Fleets');
}
//    private boolean Total_ACV_PipelineCondition(Opportunity thisOpp) {
//        return ((thisOpp.Type == 'Revenue Opportunity' || thisOpp.Type == 'Revenue Opportunity - Bill Only') && thisOpp.IsClosed == false);
//    }
private boolean Open_OpportunityCondition(Opportunity thisOpp) {
return (thisOpp.Type == 'Revenue Opportunity' && thisOpp.IsClosed == false);
}
@testvisible
private boolean Current_Monthly_PaymentsCondition(Opportunity thisOpp) {
return ((thisOpp.Type == 'Revenue Opportunity' ||
thisOpp.Type == 'Revenue Opportunity - Bill Only' ||
thisOpp.Type == 'Remorse Refund' ||
thisOpp.Type == 'Rebate' ||
thisOpp.Type == 'Warranty Exchange') &&
thisOpp.Active_Opportunity__c == true &&
thisOpp.Monthly_Deal_or_Monthly_Return__c == true);
}
private boolean rollup_ACV_Bookings_SOTPreCheck(Opportunity thisOpp, Opportunity OldOpp) {
return ((thisOpp.Type != OldOpp.Type
|| thisOpp.StageName != OldOpp.StageName
|| thisOpp.ACV_Bookings_SOT__c != oldOpp.ACV_Bookings_SOT__c)
&& (rollup_ACV_Bookings_SOTCondition(thisOpp) || rollup_ACV_Bookings_SOTCondition(OldOpp)));
}
/**
* @author Groundswell - Vikasm - vikas@gscloudsolutions.com
* @date 2020-09-08
* Not yet deployed for Production
* GTMS-1471
*/
private Boolean rollup_ExpectedRevenuePreCheck(Opportunity thisOpp, Opportunity OldOpp) {
return ((thisOpp.IsClosed != OldOpp.IsClosed
|| thisOpp.Type != OldOpp.Type)
&& (rollup_ExpectedRevenueCondition(thisOpp) || rollup_ExpectedRevenueCondition(OldOpp)));
}
private Boolean rollup_ProbabilityPreCheck(Opportunity thisOpp, Opportunity OldOpp) {
return (
((thisOpp.Probability != OldOpp.Probability)
|| thisOpp.IsClosed != OldOpp.IsClosed
|| thisOpp.Type != OldOpp.Type)
&& (rollup_ProbabilityCondition(thisOpp) || rollup_ProbabilityCondition(OldOpp)));
}
/*    private Boolean Total_ACV_PipelinePreCheck(Opportunity thisOpp, Opportunity OldOpp) {
//        return (
//                (thisOpp.ACV_Bookings_SOT__c != OldOpp.ACV_Bookings_SOT__c
//                        || thisOpp.IsClosed != OldOpp.IsClosed
//                        || thisOpp.Type != OldOpp.Type
//                ) && (
//                        Total_ACV_PipelineCondition(thisOpp)
//                                || Total_ACV_PipelineCondition(OldOpp)
//                )
//        );
//    } */
private Boolean Open_OpportunityPreCheck(Opportunity thisOpp, Opportunity OldOpp) {
return (
(thisOpp.IsClosed != OldOpp.IsClosed
|| thisOpp.Type != OldOpp.Type)
&& (Open_OpportunityCondition(thisOpp) || Open_OpportunityCondition(OldOpp))
);
}
private boolean Current_Monthly_PaymentsPreCheck(Opportunity thisOpp, Opportunity OldOpp) {
return ((thisOpp.StageName != OldOpp.StageName ||
thisOpp.License_End_Date__c != oldOpp.License_End_Date__c ||
thisOpp.CloseDate != OldOpp.CloseDate ||
thisOpp.type != OldOpp.type ||
thisOpp.Active_Opportunity__c != OldOpp.Active_Opportunity__c ||
thisOpp.Monthly_Deal_or_Monthly_Return__c != OldOpp.Monthly_Deal_or_Monthly_Return__c) &&
(Current_Monthly_PaymentsCondition(thisOpp) || Current_Monthly_PaymentsCondition(oldOpp)));
}
private static Boolean accountReparenting(Opportunity thisOpp, Opportunity oldOpp) {
return (thisOpp.AccountId != oldOpp.AccountId);
}
public Object call(String action, Map<String, Object> args) {
switch on action {
when 'Account_Lifetime_ACV__c' {
return this.rollup_ACV_Bookings_SOTCondition((Opportunity) args.get('newRecord'));
}
when 'Total_Open_Opp_Expected_Revenue__c' {
return this.rollup_ExpectedRevenueCondition((Opportunity) args.get('newRecord'));
}
when 'Highest_Probability_Open_Opportunity__c' {
return this.rollup_ProbabilityCondition((Opportunity) args.get('newRecord'));
}
//            when 'Total_ACV_Pipeline__c' {
//                return this.Total_ACV_PipelineCondition((Opportunity) args.get('newRecord'));
//            }
when 'Open_Opportunity__c' {
return this.Open_OpportunityCondition((Opportunity) args.get('newRecord'));
}
when 'Current_Monthly_Payments__c' {
return this.Current_Monthly_PaymentsCondition((Opportunity) args.get('newRecord'));
}
when 'Account_Lifetime_ACV__cPreCheck' {
return this.rollup_ACV_Bookings_SOTPreCheck((Opportunity) args.get('newRecord'), (Opportunity) args.get('oldRecord'));
}
when 'Total_Open_Opp_Expected_Revenue__cPreCheck' {
return this.rollup_ExpectedRevenuePreCheck((Opportunity) args.get('newRecord'), (Opportunity) args.get('oldRecord'));
}
when 'Highest_Probability_Open_Opportunity__cPreCheck' {
return this.rollup_ProbabilityPreCheck((Opportunity) args.get('newRecord'), (Opportunity) args.get('oldRecord'));
}
//            when 'Total_ACV_Pipeline__cPreCheck' {
//                return this.Total_ACV_PipelinePreCheck((Opportunity) args.get('newRecord'), (Opportunity) args.get('oldRecord'));
//            }
when 'Open_Opportunity__cPreCheck' {
return this.Open_OpportunityPreCheck((Opportunity) args.get('newRecord'), (Opportunity) args.get('oldRecord'));
}
when 'Current_Monthly_Payments__cPreCheck' {
return this.Current_Monthly_PaymentsPreCheck((Opportunity) args.get('newRecord'), (Opportunity) args.get('oldRecord'));
}
when 'SUM' {
return this.Sum((List<Sobject>) args.get('recordList'), (String) args.get('field'));
}
when 'MAX' {
return this.Max ((List<Sobject>) args.get('recordList'), (String) args.get('field'));
}
when 'FIRST' {
return this.first((List<Sobject>) args.get('recordList'), (String) args.get('field'));
}
when else {
System.debug('Method not implemented');
return null;
}
}
}
private Decimal Sum(List<Sobject>recordList, String field) {
return RollupService.Sum(recordList, field);
}
private Decimal Max(List<Sobject>recordList, String field) {
return RollupService.max(recordList, field);
}
private Sobject first(List<Sobject>recordList, String field) {
return RollupService.first(recordList, field);
}
@testvisible
private static Decimal calculateCurrentMonthlyPayments(List<Opportunity> opportunityList) {
Decimal sum = 0;
for (Opportunity thisOpp : opportunityList) {
Date licenseEndDate = ((thisOpp.Returning_Opportunity__c != null && thisOpp.Returning_Opportunity__r.License_End_Date__c != null) ? thisOpp.Returning_Opportunity__r.License_End_Date__c : thisOpp.License_End_Date__c);
if (licenseEndDate == null) continue;
Integer numberOfMonths = thisOpp.CloseDate.monthsBetween(licenseEndDate) != 0 ? thisOpp.CloseDate.monthsBetween(licenseEndDate) : 1;
if (thisOpp.Total_License_Due__c != null && thisOpp.CloseDate != null && licenseEndDate != null){
Sum += (thisOpp.Total_License_Due__c / numberOfMonths);
}
}
return sum;
}
public void getOpptyOwner(Set<Id> userIds){
if(mapUsers == null || !(mapUsers.keySet().containsAll(userIds))){
mapUsers = new Map<Id, User>([SELECT Email, UserRole.Name, profileId, profile.name, contactId, Manager.Email, Manager.Name, Manager.UserRole.Name, Level__c, Business_Unit__c, Segment__c, IsActive,
                                         ManagerId,Manager.ManagerId,Manager.Manager.ManagerId,Manager.Manager.Manager.ManagerId,Manager.Manager.Manager.Manager.ManagerId,Manager.Manager.Name,Manager.Manager.Manager.Name,Manager.Manager.Manager.Manager.Name, Manager.Manager.Manager.UserRole.Name,Manager.Sales_User_Type__c,Manager.Manager.Manager.Sales_User_Type__c,
                                          Manager.Manager.Sales_User_Type__c,Manager.Manager.UserRole.Name,Manager.Manager.Level__c,Manager.Level__c FROM User where Id IN : userIds]);
}
}
private void setClickpathAuditStatus(Map<Id, Opportunity> oldOppMap){
if (this.clickPathOppList == null || this.clickPathOppList.isEmpty()) return;
List<SBQQ__QuoteLine__c> quoteLineList = [
SELECT Name, SBQQ__Quote__c, Gainsight_Audit_Status__c,SBQQ__Quote__r.Process_Eligibility__c
FROM SBQQ__QuoteLine__c
WHERE SBQQ__Quote__c IN :primaryQuoteToOppIdMap.keySet()
AND Gainsight_Audit_Status__c != :GAINSIGHT_IGNORE_STATUS
];
Map<Id, String> opportunityIdToStatus = new Map<Id, String>();
Map<Id, String> primaryQuoteEligibilityMap = new Map<Id, String>();
// Join quote lines by Opportunity/Quote
for (SBQQ__QuoteLine__c ql : quoteLineList){
Id opportunityId = primaryQuoteToOppIdMap.get(ql.SBQQ__Quote__c);
String oppStatus = opportunityIdToStatus.get(opportunityId);
if (String.isBlank(oppStatus)) oppStatus = '';
else oppStatus += '\n';
oppStatus += String.format(Label.Clickpath_QuoteLine_has_the_following_issues, new List<String>{ql.Name})+' '+(String.isBlank(ql.Gainsight_Audit_Status__c) ? Label.Clickpath_Pending_Update : ql.Gainsight_Audit_Status__c);
opportunityIdToStatus.put(opportunityId, oppStatus);
if (!primaryQuoteEligibilityMap.containsKey(ql.SBQQ__Quote__c)) {
primaryQuoteEligibilityMap.put(ql.SBQQ__Quote__c, ql.SBQQ__Quote__r.Process_Eligibility__c);
}
}
String customerPrice = Label.Clickpath_Customer_price_does_not_match;
String missingSubs = Label.Clickpath_Missing_renewed_subscription;
String pendingUpdate = Label.Clickpath_Pending_Update;
String quantityMismatch = Label.Clickpath_Quantity_does_not_match;
Set<Id> contractIdSet = new Set<Id>();
for (Opportunity opp : this.clickPathOppList){
String processEligibility = primaryQuoteEligibilityMap.get(opp.SBQQ__PrimaryQuote__c);
String status;
// Assigning status and testing it
if (String.isNotBlank(status = opportunityIdToStatus.get(opp.Id))){
opp.Gainsight_Audit_Status__c = (status.length() > 254 ? status.left(255) : status);
if(String.isNotBlank(opp.Gainsight_Audit_Status__c) && opp.Gainsight_Audit_Status__c.contains(customerPrice) && !opp.Gainsight_Audit_Status__c.contains(missingSubs) 
&& !opp.Gainsight_Audit_Status__c.contains(pendingUpdate) && !opp.Gainsight_Audit_Status__c.contains(quantityMismatch) 
&& processEligibility == 'Digital Renewals'){
opp.Gainsight_Audit_Status__c =  Label.Success;
}
}else{
opp.Gainsight_Audit_Status__c =  Label.Success;
}
if (opp.SBQQ__RenewedContract__c != null) contractIdSet.add(opp.SBQQ__RenewedContract__c);
}
if (contractIdSet.size() > 0 && (contractsMap == null || contractsMap.size() <= 0)){
loadContracts(contractIdSet);
}
for (Opportunity opp : this.clickPathOppList){
if(contractsMap.get(opp.SBQQ__RenewedContract__c) != null){
this.processFutureDatedAutoRenewal(opp, (oldOppMap != null ? oldOppMap.get(opp.Id) : null), contractsMap.get(opp.SBQQ__RenewedContract__c));
//GTMS-23000
updateOpptyFromContractUsingWASD(opp,contractsMap);
}
}
}
// GTMS-6099 process future-dated auto-renewals
@TestVisible
private void processFutureDatedAutoRenewal(Opportunity opp, Opportunity oldOpp, Contract ctt){
Integer daysUntilClosing = (System.today().daysBetween(ctt.EndDate));
Boolean isAutoRenewal = (opp.Sub_Type__c == 'Auto-Renewal');
Boolean isWithinTimeframe = (daysUntilClosing >= 0 && daysUntilClosing <= 30);
// Changed from something else to success or override has been checked.
Boolean gainsightChangedToSuccess = (
(
(oldOpp == null || oldOpp.Gainsight_Audit_Status__c != opp.Gainsight_Audit_Status__c)
&&   opp.Gainsight_Audit_Status__c == Label.Success
)
||
(
(oldOpp == null || oldOpp.Gainsight_Audit_Override__c != opp.Gainsight_Audit_Override__c)
&&   opp.Gainsight_Audit_Override__c
)
);
if (isAutoRenewal && gainsightChangedToSuccess && isWithinTimeframe){
opp.StageName = 'Purchase';
// If closeDate != today
if (daysUntilClosing > 0){
opp.Adjust_License_Start_Date__c = true;
opp.License_Start_Date__c = opp.CloseDate;
if (opp.OwnerId == Id.valueOf(Label.Renewal_Pool_User)
&& mapUsers.containsKey(Label.Clickpath_Opportunity_Won_User_Id)
&& mapUsers.get(Label.Clickpath_Opportunity_Won_User_Id).IsActive){
opp.OwnerId = Id.valueOf(Label.Clickpath_Opportunity_Won_User_Id);
}
}
}
}
private void addToClickpathOpportunityList(Opportunity opp){
if (this.isClickpathOpp(opp) && this.isRenewal(opp)){
if (this.clickPathOppList == null){
this.clickPathOppList = new List<Opportunity>();
this.primaryQuoteToOppIdMap = new Map<Id, Id>();
}
if (opp.SBQQ__PrimaryQuote__c != null){
this.clickPathOppList.add(opp);
this.primaryQuoteToOppIdMap.put(opp.SBQQ__PrimaryQuote__c, opp.Id);
}
}
}
private Boolean isClickpathOpp(Opportunity opp){
return (opp.Sub_type__c == 'Clickpath' || opp.Sub_Type__c == 'Auto-Renewal');
}
private Boolean isRenewal(Opportunity opp){
return opp.Renewal__c;
}
private void loadContracts(Set<Id> contractIds){
// No cache is being made so it will refresh at every recursion and avoid null pointers.
        contractsMap = new Map<Id, Contract>([SELECT Id, StartDate, EndDate, ContractNumber, Auto_Renewal__c, Original_Reseller_ID__c,SBQQ__Opportunity__r.Insurance_Partner__c,
            SBQQ__Opportunity__r.Referral_Partner__c, SBQQ__Opportunity__r.Reseller_Partner__c,
            SBQQ__Opportunity__r.Shipping_Contact__c, SBQQ__Opportunity__r.Payment_Terms__c, SBQQ__Opportunity__r.Selected_Payment_Type__c,
            SBQQ__Opportunity__r.Approved_Discount__c, SBQQ__Opportunity__r.Reseller__c, SBQQ__Opportunity__r.Finance_Partner__c,
            SBQQ__Opportunity__r.Shipping_Address_NEW__c, SBQQ__Opportunity__r.OwnerId, SBQQ__Opportunity__c, Account.Name, Weighted_Average_Start_Date__c
            FROM Contract WHERE Id IN :contractIds]);
}
/** GTMS-8352 methods start --*/
@TestVisible
private static Map<Id, Id> getOwnerForDelinquentRebateOpportunity(Set<Id> oppByRetOpp){
Map<String, Id> defaultUsers = new Map<String, Id>();
Set<Id> oppIds = new Set<Id>();
Map<Id, Opportunity> oppsByoppId = new Map<Id, Opportunity>();
Map<Id, Id> oppByOwnerId = new Map<Id, Id>();
oppIds.addAll(oppByRetOpp);
system.debug('===>>>Returning Opp Ids'+oppIds);
if(!oppIds.isEmpty()){
oppsByoppId = getReturnAndRebateOpps(oppIds);
}
system.debug('===>>>Returning opps'+oppsByOppId);
defaultUsers = getUserForOwnerId();
for(Id rebateOppId : oppsByoppId.keySet()){
Opportunity returnOpp = oppsByoppId.get(rebateOppId);
oppByOwnerId.put(rebateOppId, getOwnerIdForRebateOpp(returnOpp, defaultUsers));
}
system.debug('===>>>oppByOwnerId'+oppByOwnerId);
return oppByOwnerId;
}
@TestVisible
private static Id getOwnerIdForRebateOpp(Opportunity returnOpp,Map<String, Id> defaultUsers){
Id rebateOwnerId = null;
String AEUser = System.Label.RebateDefaultUserAmitVyas;
String entUser = System.Label.RebateDefaultUserClintNelson;
String defUser = System.Label.RebateDefaultUserAndyMcCall;
system.debug('---defaultUsers---'+defaultUsers+'>>>'+ defaultUsers.get(defUser));
Set<String> segmentCodesForAE = new Set<String> (System.Label.RebateAESegment.split(','));
String segmentCodesForEnterprise = System.Label.RebateEnterpriseSegment;
if(returnOpp.Is_Owner_Active__c){
system.debug('===> 1. Owner active');
rebateOwnerId = returnOpp.OwnerId;
}else if(returnOpp.Is_Owner_Manager_Active__c){
system.debug('===> 2. Owner manger active');
rebateOwnerId = returnOpp.Owner_Manager_Name_Copy__c;
}else if(returnOpp.Is_Owner_Director_Active__c){
system.debug('===> 3. Owner director inactive');
rebateOwnerId = returnOpp.Owner_Director_Name_Copy__c;
}else if(segmentCodesForAE.contains(returnOpp.Owner_Segment__c)){
system.debug('===> 4. Owner Segment AE');
rebateOwnerId = defaultUsers.containsKey(AEUser) ? defaultUsers.get(AEUser) : defaultUsers.get(defUser);
}else if(segmentCodesForEnterprise.contains(returnOpp.owner_segment__c)){
system.debug('===> 5. Owner Segment Enterprise');
rebateOwnerId= defaultUsers.containsKey(entUser) ? defaultUsers.get(entUser) : defaultUsers.get(defUser);
}else{
system.debug('===> 6. Andy McCall');
rebateOwnerId =  defaultUsers.get(defUser);
}
system.debug('===>>> final ownerId --'+rebateOwnerId);
return rebateOwnerId;
}
@TestVisible
private static Map<Id, Opportunity> getReturnAndRebateOpps(Set<Id> oppIds){
return new Map<Id, Opportunity>([SELECT Id, OwnerId, Is_Owner_Active__c, Is_Owner_Manager_Active__c, Owner_Manager_Name_Copy__c,
        Is_Owner_Director_Active__c, Owner_Director_Name_Copy__c, Owner_Segment__c, Owner_Director_Email_Copy__c
        FROM Opportunity
        WHERE id in: oppIds]);
}
@TestVisible
private static Map<String, Id> getUserForOwnerId(){
List<String> userNames = new List<String>();
userNames.add(System.Label.RebateDefaultUserAmitVyas);
userNames.add(System.Label.RebateDefaultUserClintNelson);
userNames.add(System.Label.RebateDefaultUserAndyMcCall);
Map<String, Id> userNameById = new Map<String, Id>();
List<user> usrs = [Select Id, name from user where Name in :userNames and isActive = true];
for(User usr : usrs){
userNameById.put(usr.name, usr.Id);
}
return userNameById;
}
/** GTMS-8352 methods End --*/
//GTMS-9601
public static Boolean doesLineItemContainsEOL(List<OpportunityLineItem> oppLineItems, Opportunity opp){
system.debug('---In doesLineItemContainsEOL---'+oppLineItems.size());
for(OpportunityLineItem oli : oppLineItems){
if((oli.Product2.Product_Status__c == 'EOL' && !oli.Product2.CPQ_Enabled_Product__c) || (oli.ProductCode.contains('ACC-EI') && oppAccounts.get(opp.AccountId) != NULL)){
system.debug('---In true---');
return true;
}
}
return false;
}
//GTMS-9601
public static Boolean validateOppForHWProducts(List<OpportunityLineItem> oppLineItems, Opportunity opp, Map<Id, Opportunity> oldOppMap, List<String> profileIdsForHwAG4ValdiationRule, List<String> returnOppTypes){
if(opp.probability < 90 &&
oldOppMap!=null && opp.stageName != oldOppMap.get(opp.Id).stageName &&
doesLineItemContainsEOL(oppLineItems, opp) &&
!profileIdsForHwAG4ValdiationRule.contains(UserInfo.getProfileId())  &&
!returnOppTypes.contains(opp.Type)
){
return true;
}
return false;
}
//GTMS-21691: Start
private static Boolean KeyAccountEligible(List<OpportunityLineItem> oppLineItems){
  for(OpportunityLineItem oli : oppLineItems){
  if(oli.Product2.Key_Account_Eligible__c == true){
                return true;
}
}
return false;
}   
//GTMS-21691: END    
//GTMS-5727: Moved the below code changes from OpportunityProcessBuilderConversion
public void associateRebateOppsToChannelOpps(Map<Id, Opportunity> opsMap) {
for (Opportunity o : opsMap.values()) {
Opportunity returningOpp = new Opportunity();
if(o.Rebate_Type_Formula__c != null){
switch on o.Rebate_Type_Formula__c {
when 'Buyout' {
returningOpp.Id = o.Returning_Opportunity__c;
returningOpp.Buyout_Opportunity__c = o.Id;
DMLWrapper.doUpdate(returningOpp, new List<SobjectField>{
Opportunity.Buyout_Opportunity__c
});
}
when 'Subsidy' {
returningOpp.Id = o.Returning_Opportunity__c;
returningOpp.Subsidy_Opportunity__c = o.Id;
DMLWrapper.doUpdate(returningOpp, new List<SobjectField>{
Opportunity.Subsidy_Opportunity__c
});
}
when 'Partner Referral' {
returningOpp.Id = o.Returning_Opportunity__c;
returningOpp.Partner_Referral_Opportunity__c = o.Id;
DMLWrapper.doUpdate(returningOpp, new List<SobjectField>{
Opportunity.Partner_Referral_Opportunity__c
});
}
}
}
}
}
// End trigger methods
////added below method for GTMS-12082
/*public void uncheckContractRenewal(Map<Id, Opportunity> triggerOldMap, List<Opportunity> triggernew) {
Set<Id> opptyId = new Set<Id>();
for(Opportunity opp : triggernew) {
if(opp.ACV_Bookings_SOT__c != triggerOldMap.get(opp.Id).ACV_Bookings_SOT__c && opp.ACV_Bookings_SOT__c > 10000) {
opptyId.add(opp.Id);
}
if(!opptyId.isEmpty()) {
updateContractRecords(opptyId);
}
}
}*/
////added below method for GTMS-12082
/*@future
public static void updateContractRecords(Set<ID> opptyId){
List<Contract> contractsList = [SELECT ID from Contract where SBQQ__RenewalOpportunity__c IN :opptyId
AND EndDate > TODAY AND Auto_Renewal__c = True];
List<Contract> contractsToUpdate = new List<Contract>();
List<Api_Logger__c> aplogList = new List<Api_Logger__c>();
for(Contract Con:contractsList ){
Contract c= new Contract(id = Con.Id, Auto_Renewal__c = false);
contractsToUpdate.add(c);
}
if(!contractsToUpdate.isEmpty())
try{
update contractsToUpdate;
}
catch(exception e) {
Api_Logger__c aplog = new Api_Logger__c();
apLog.Opportunity_Name__c =  'Updating contracts field Auto_Renewal__c to false';
apLog.DML__c= true;
apLog.Exception_Message__c = e.getMessage();
aplogList.add(aplog);
}
if(!aplogList.isEmpty()) {
insert apLogList;
}
}*/
private void setOpportunityTypeForFreeTrials(List<Opportunity> oppList){
if(oppList==null){
return;
}
Map<Id,Opportunity> amendContracts = new Map<Id, Opportunity>();
for(Opportunity o:oppList){
if(o.SBQQ__AmendedContract__c!=null){
amendContracts.put(o.SBQQ__AmendedContract__c,o);
}
}
if(amendContracts.isEmpty()){
return;
}
//Better to create utility method to get the recordtype id.
Id contractRecordTypeId = Schema.SObjectType.Contract.getRecordTypeInfosByDeveloperName().get('Free_Trial').getRecordTypeId();
Id opportunityTrialRecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('Trial').getRecordTypeId();
if(String.isBlank(contractRecordTypeId)|| String.isBlank(opportunityTrialRecordTypeId)){
return;
}
for(Contract con : [Select id,Opportunity_Type__c from Contract where RecordTypeId = :contractRecordTypeId and id IN :amendContracts.keySet()]){
Opportunity freeTrialOpportunity = amendContracts.get(con.id);
if(freeTrialOpportunity!=null){
freeTrialOpportunity.RecordTypeId = opportunityTrialRecordTypeId;
freeTrialOpportunity.Type = con.Opportunity_Type__c;
}
}
}
private void setSyncInProgress(Map<Id, Opportunity> oldOppMap, List<Opportunity> newOppList){
if(oldOppMap.isEmpty() || newOppList.isEmpty()){
return;
}
for(Opportunity newOpportunityData: newOppList){
Opportunity oldOpportunityData = oldOppMap.get(newOpportunityData.Id);
if(oldOpportunityData==null){
continue;
}
if ( newOpportunityData.SBQQ__PrimaryQuote__c!=null && ((newOpportunityData.StageName == 'Ready To Ship' && oldOpportunityData.StageName != newOpportunityData.StageName && newOpportunityData.Type == 'Free Trial Opportunity') ||
                                (newOpportunityData.StageName == 'Return Initiated' && oldOpportunityData.StageName != newOpportunityData.StageName && newOpportunityData.Type == 'Free Trial Return')) )
{
newOpportunityData.Sync_in_Progress__c  = true;
}
}
}
public void updateOrders(Map<Id, Opportunity> oldOppMap, List<Opportunity> newOppList){
Set<Id> oppIds = new Set<Id>();
Map<Id, Opportunity> newOppMap = new Map<Id, Opportunity>(newOppList);
for(Opportunity newOpportunityData: newOppList){
Opportunity oldOpportunityData = oldOppMap.get(newOpportunityData.Id);
if ((newOpportunityData.StageName == 'Refunded - Closed' || newOpportunityData.StageName == 'Return Cancelled') && oldOpportunityData.StageName != newOpportunityData.StageName &&
(newOpportunityData.Type == 'Remorse Refund' || newOpportunityData.Type == 'Rebate' || newOpportunityData.Type == 'Exchange' || newOpportunityData.Type == 'Warrant Exchange')) {
oppIds.add(newOpportunityData.Id);
}
}
List<Order> updatedOrders = new List<Order>();
List<Order> orders = [SELECT Id, OpportunityId, Status FROM Order WHERE OpportunityId IN :oppIds];
for(Order order : orders) {
Opportunity opp = newOppMap.get(order.OpportunityId);
if(opp != null) {
order.Status = opp.StageName == 'Refunded - Closed' ? 'Return Completed' : 'RMA Canceled';
updatedOrders.add(order);
}
}
if(!updatedOrders.isEmpty()) {
update updatedOrders;
}
}
/**GTMS-13565 - START**/
public static String checkLicenceProducts(List<OpportunityLineItem> oppLineItems){
boolean allLicenseTypeProds = true;
boolean partOfLicenseProdList = false;
List<String> licenseProdCodes = System.Label.LICENSE_PRODUCT_CODE.split(',');
for(OpportunityLineItem opli : oppLineItems){
if(opli.Product2.Product_Type__c != 'License') {
allLicenseTypeProds = false;break;
}
if(opli.Product2.Product_Type__c == 'License' && licenseProdCodes.contains(opli.ProductCode))
{
partOfLicenseProdList = true;
}
}
if(allLicenseTypeProds && !(partOfLicenseProdList)){
return 'Ready to Ship';
} else {
return 'Orders Processing';
}
}
/* public Opportunity updateStageReadyToShip(Opportunity o){
o.StageName = 'Ready To Ship';
o.Probability = 99;
o.Went_To_Ready_To_Ship_Date__c = Datetime.Now();
o.Went_To_Ready_To_Ship__c = TRUE;
return o;
}*/
/**GTMS-13565 - End**/
/** GTMS-15414- START **/
public void emeaOpsAutomationPromoOppty(List<Opportunity> newOppList, Map<Id, Opportunity> oldOppMap) {
loadOppAccounts(newOppList);
loadOppFields(newOppList);
Map<String, String> prodCodesToDispatchMap = new Map<String, String>();
List<String> lstDCLProdCodes = new List<String>();
//lstDCLProdCodes = System.Label.DCL_Product_SKU_List.split(',');
// DCL_Product_SKU_List Custom Label Changed to VCK_EMEA_Promo_SKU as rqusted GTMS-21311 ticket
lstDCLProdCodes = System.Label.VCK_EMEA_Promo_SKU.split(',');
//-- Add condition for GTMS-15414 - START
List<String> emeaShippingCountryList = System.Label.EMEA_SHIPPING_COUNTRIES.split(',');
List<String> oderOpsAdminProfiles = System.Label.Order_Automation_Profile_Promo_Oppty.split(',');
for (Opportunity o : newOppList) {
String prodCodesToDispatch = '';
if(oderOpsAdminProfiles.contains(UserInfo.getProfileId()) && emeaShippingCountryList.contains(o.Shipping_Country__c) && o.Shipping_Carrier__c == 'DHL' && o.Ship_From_Location__c == 'VCK' &&
(o.Shipping_Method__c == 'UK Standard' || o.Shipping_Method__c == 'UK Express') &&
(o.CurrencyIsoCode == 'GBP' || o.CurrencyIsoCode == 'EUR' || o.CurrencyIsoCode == 'CHR') &&
String.isBlank(o.VAT_Number__c) && o.Type == 'Promo Opportunity' && o.StageName == 'Orders Processing'
&& String.isBlank(o.Shipping_Instructions__c) && String.isBlank(o.Order_Ops_Notes__c) && String.isBlank(o.Internal_RFO_Notes__c) && String.isBlank(o.Hold_Reason__c)
&& String.isBlank(o.Netsuite_Id__c) && o.Sales_Tax__c == 0 && o.Balance_Due__c == 0 && o.Shipping_and_Handling__c == 0 /*&&
o.Unique_Shipping_Addresses__c == 1*/ && o.Price_Book_Name__c == 'Samsara FY22')
{
//lstDCLProdCodes = System.Label.DCL_Product_SKU_List.split(',');
if (oppFields.containsKey(o.Id) && oppFields.get(o.Id).OpportunityLineItems != null) {
for (OpportunityLineItem oli : oppFields.get(o.Id).OpportunityLineItems) {
system.debug('****'+oli.ProductCode);
system.debug('****'+oli.Product2Id);
if (lstDCLProdCodes.contains(oli.ProductCode) && oli.Quantity >= 1 && oli.Quantity < 100) {
if(prodCodesToDispatch != ''){
prodCodesToDispatch = prodCodesToDispatch + ',' + oli.ProductCode;
}
else{
prodCodesToDispatch = oli.ProductCode;
}
}
if (prodCodesToDispatch != '' ) {
prodCodesToDispatchMap.put(o.Id, prodCodesToDispatch);
}
}
}
}
/**GTMS-13565 - START - Checking License Type Products**/
if(o.StageName == 'Orders Processing' && oldOppMap != null && oldOppMap.get(o.Id) != null && o.StageName != oldOppMap.get(o.Id).StageName
&& oppFields != NULL && oppFields.get(o.Id) != NULL && !oppFields.get(o.Id).OpportunityLineItems.isEmpty() /*&& oppFields.get(o.Id).OpportunityLineItems != NULL*/)
{
string returnDecision = checkLicenceProducts(oppFields.get(o.Id).OpportunityLineItems);
if(returnDecision == 'Ready to Ship'){
//o = updateStageReadyToShip(o);
Set<Id> setId = new Set<id>();
Map<String,Set<Id>> paramMap = New Map<String,Set<Id>>();
setId.add(o.Id);
if(setId.size() >0){
paramMap.put('RecordCole',setId);
Flow.Interview.Opportunity_Stage_Update_to_Ready_to_Ship flow1 = new Flow.Interview.Opportunity_Stage_Update_to_Ready_to_Ship(paramMap);
flow1.start();
}
} else {
o.StageName = returnDecision;
}
}
/**GTMS-13565 - END - Checking License Type Products**/
}
if (!prodCodesToDispatchMap.isEmpty() && !System.isFuture() && !System.isScheduled() && !System.isQueueable() && !System.isBatch()) {
ValidateProductQuantityVCKFuture.fetchVCKProductQuantity(prodCodesToDispatchMap);
}
}
/** GTMS-15414- END **/
/** GTMS-18015 Started **/
public void emeaOpsAutomationRevnueOppty(List<Opportunity> newOppList, Map<Id, Opportunity> oldOppMap) {
loadOppAccounts(newOppList);
loadOppFields(newOppList);
Map<String, String> prodCodesToDispatchMap = new Map<String, String>();
Set<String> lstDCLProdCodes = new Set<String>();
lstDCLProdCodes.addAll(System.Label.VCK_EMEA_Revenue_SKU.split(','));
lstDCLProdCodes.addAll(System.Label.VCK_EMEA_Revenue_SKU_extend_1.split(','));
lstDCLProdCodes.addAll(System.Label.VCK_EMEA_Revenue_SKU_extend_2.split(','));
lstDCLProdCodes.addAll(System.Label.VCK_EMEA_Revenue_SKU_extend_3.split(','));
Set<String> emeaShippingCountryList = new Set<String>(System.Label.EMEA_SHIPPING_COUNTRIES.split(','));
for (Opportunity opp : newOppList) {
String prodCodesToDispatch = '';
Decimal productCount = opp.of_HW_Products__c + opp.of_Accessories__c;
if(emeaShippingCountryList.contains(opp.Shipping_Country__c) && opp.Shipping_Carrier__c == 'DHL' && opp.Ship_From_Location__c == 'VCK' &&
(opp.Shipping_Method__c == 'UK Standard' || opp.Shipping_Method__c == 'UK Express') && ((opp.CurrencyIsoCode == 'GBP' || opp.CurrencyIsoCode == 'EUR' || opp.CurrencyIsoCode == 'CHR') && opp.Amount < 100000) && opp.Type == 'Revenue Opportunity' && opp.StageName == 'Orders Processing' &&
((opp.Segment_Sales_Role__c == 'AE2' || opp.Segment_Sales_Role__c == 'AE3' || opp.Segment_Sales_Role__c == 'Enterprise') && (opp.name.contains('Webstore') ? (opp.Free_Trial_Purchase__c == NULL) : (opp.Free_Trial_Purchase__c == 'No Purchase'))) &&
String.isBlank(opp.Shipping_Instructions__c) && String.isBlank(opp.Order_Ops_Notes__c) && String.isBlank(opp.Internal_RFO_Notes__c) && String.isBlank(opp.Hold_Reason__c) && opp.Shipping_and_Handling__c < 99999 /*&& opp.Unique_Shipping_Addresses__c == 1*/ && opp.Price_Book_Name__c == 'Samsara FY22' &&  opp.Total_Weight_oz__c < 6500 && productCount < 3000 )
{
Boolean productFlag = true;
if (oppFields.containsKey(opp.Id) && oppFields.get(opp.Id).OpportunityLineItems != null) {
for ( OpportunityLineItem oli : oppFields.get(opp.Id).OpportunityLineItems) {
if (lstDCLProdCodes.contains(oli.ProductCode) && oli.Quantity >= 1 && oli.Quantity < 100) {
prodCodesToDispatch = prodCodesToDispatch + ',' + oli.ProductCode;
}
else{
productFlag = false;
}
}
if (prodCodesToDispatch != '' && productFlag == true  ) {
prodCodesToDispatchMap.put(opp.Id, prodCodesToDispatch);
}
}
}
}
/*if (!prodCodesToDispatchMap.isEmpty() && !System.isFuture() && !System.isScheduled() && !System.isQueueable() && !System.isBatch()) {
ValidateProductQuantityVCKFuture.fetchVCKProductQuantity(prodCodesToDispatchMap);
}*/
// VCK Warehouse Quantity future class changed to Queueable class as part of GTMS-18018
if(!prodCodesToDispatchMap.isEmpty() && !Test.isRunningTest() ){
ValidateProductQuantityVCKQueueable que = new ValidateProductQuantityVCKQueueable(prodCodesToDispatchMap);
System.enqueueJob(que);
}
}
/** GTMS-18015 Ended **/
//GTMS-14163
public void afterUpdateAccount(Map<Id, Opportunity> oldOppMap, List<Opportunity> newOppList)
{
List<dsfs__DocuSign_Status__c> docuSignListToUpdate = new List<dsfs__DocuSign_Status__c> ();
for(Opportunity opp: newOppList)
{
if(opp.Type == 'Revenue Opportunity' && opp.RecordTypeId == opportunityRevRecordTypeId && opp.StageName == 'Ready to Ship'
&& opp.Payment_Type_Opportunity_only_Exception__c == false && String.isNotBlank(opp.Selected_Payment_Type__c)
&& opp.of_LIC_Products__c > 0 && opp.Is_Webstore_Upsell_Opportunity__c == false
&& opp.Small_Fleet_Opportunity__c == false) {
if(!accountUpdateMap.containsKey(opp.AccountId)) {
accountUpdateMap.put(Opp.AccountId, new Account(Id = opp.AccountId));
}
accountUpdateMap.get(Opp.AccountId).Approved_Payment_Type__c = opp.Selected_Payment_Type__c;
}
Opportunity oldopp = (oldOppMap != null && oldOppMap.containsKey(opp.Id))?   oldOppMap.get(opp.Id):null;
Opportunity oppo = (oppFields != null )? oppFields.get(opp.Id):null;
if(oppo != null && oppo.SBQQ__PrimaryQuote__c != null && oppo.SBQQ__PrimaryQuote__r.DCA_Validation__c == 'DCA' && opp.StageName == 'Closing' && opp.StageName != oldopp?.StageName){
String accountPOException = oppo.Account.Customer_require_PO_for_invoicing__c;
if(opp.Customer_require_PO_for_invoicing__c =='Yes' && (String.isBlank(accountPOException) || accountPOException == 'No')){
if(!accountUpdateMap.containsKey(opp.AccountId)) {
accountUpdateMap.put(Opp.AccountId, new Account(Id = opp.AccountId));
}
accountUpdateMap.get(Opp.AccountId).Customer_require_PO_for_invoicing__c = 'Yes';
}else if(opp.Customer_require_PO_for_invoicing__c =='No' &&  (String.isBlank(accountPOException))){
if(!accountUpdateMap.containsKey(opp.AccountId)) {
accountUpdateMap.put(Opp.AccountId, new Account(Id = opp.AccountId));
}
accountUpdateMap.get(Opp.AccountId).Customer_require_PO_for_invoicing__c = 'No';
}
}
if( oppo != null && ! string.isBlank(opp.Customer_require_PO_for_invoicing__c) && opp.Customer_require_PO_for_invoicing__c != oldopp?.Customer_require_PO_for_invoicing__c && opp.isClosed == false){
List<dsfs__DocuSign_Status__c> docuSignStatus = oppo?.R00N80000002fD9vEAE;
for(dsfs__DocuSign_Status__c docu:docuSignStatus){
if( string.isBlank( docu.Customer_require_PO_for_invoicing__c)){
docu.Customer_require_PO_for_invoicing__c = opp.Customer_require_PO_for_invoicing__c;
docu.PO_Number__c = opp.PO_Number__c;
docuSignListToUpdate.add(docu);
break ;
}
}
}
}
if(docuSignListToUpdate.size() >0){
update docuSignListToUpdate;
}
updateAccountRecords();
/*
TriggerHandler.bypass('GS_OpportunityTriggerHandler');
TriggerHandler.bypass('OpportunityTriggerHandler');
TriggerHandler.bypass('GS_SBQQQuoteTriggerHandler');
TriggerHandler.bypass('SBQQQuoteLineTriggerHandler');
TriggerHandler.bypass('OpportunityLineItemTriggerHandler');
TriggerHandler.bypass('AccountTriggerHandler');
TriggerHandler.bypass('GS_AccountTriggerHandler');
TriggerHandler.bypass('ContractTriggerHandler');
TriggerHandler.bypass('GS_ContactTriggerHandler');
TriggerHandler.bypass('ContactTriggerHandler');
SBQQ.TriggerControl.disable();
update accounts.Values();
SBQQ.TriggerControl.enable();
TriggerHandler.clearAllBypasses();
*/
}
/** GTMS-15659 starts here **/
public void checkForChangeInSmartApprovalFields(Map<Id, Opportunity> oldOppMap, List<Opportunity> newOppList) {
for (Opportunity o : newOppList) {
Opportunity oldOpty = oldOppMap.get(o.Id);
if (o.SLA_Termination_right__c != oldOpty.SLA_Termination_right__c ||
o.Samsara_insolvency__c != oldOpty.Samsara_insolvency__c  ||
o.Permanent_Downsize__c  != oldOpty.Permanent_Downsize__c  ||
o.Partial_use_seasonal__c  != oldOpty.Partial_use_seasonal__c  ||
o.MSA_negotiated_under_good_faith_after_or__c  != oldOpty.MSA_negotiated_under_good_faith_after_or__c  ||
o.Price_stability_for_renewal__c  != oldOpty.Price_stability_for_renewal__c  ||
o.Termination_for_convenience__c  != oldOpty.Termination_for_convenience__c  ||
o.Termination_for_lack_of_appropriation_of__c  != oldOpty.Termination_for_lack_of_appropriation_of__c  ||
o.Temporary_Suspension__c  != oldOpty.Temporary_Suspension__c  ||
o.Extended_returns_beyond_30_days__c  != oldOpty.Extended_returns_beyond_30_days__c  ||
o.Price_lock_language_for_add_on_orders__c  != oldOpty.Price_lock_language_for_add_on_orders__c  ||
o.Non_Standard_terms_description__c  != oldOpty.Non_Standard_terms_description__c
) {
DateTime myDateTime = DateTime.now();
o.Smart_Approve_Standard_Term_Indicator__c = (o.Smart_Approve_Standard_Term_Indicator__c!=null)?o.Smart_Approve_Standard_Term_Indicator__c+5:myDateTime.millisecond() + myDateTime.minute() + myDateTime.hour() + myDateTime.day() + myDateTime.month() + + myDateTime.year();
}
}
}
/** GTMS-15659 ends here **/
// added for GTMS-16003 starts here
public void performUpdateOnFPQ(List<Opportunity> newOppList, Map<Id, Opportunity> oldOppMap) {
Set<Id> opptyIdSet = new Set<Id>();
Set<Id> opptyIdForContractSet = new Set<Id>();
for (Opportunity o : newOppList) {
if (oldOppMap.get(o.Id) != null && (o.StageName == 'Closed Won' || o.StageName == 'Closed Lost')) {
opptyIdSet.add(o.Id);
if (o.StageName == 'Closed Won' && o.Finance_Partner__c != null)
opptyIdForContractSet.add(o.Id);
}
}
List<Finance_Partner_Quote__c> listFPQ = [SELECT Id FROM Finance_Partner_Quote__c
                WHERE Financing_Decision__c = 'Pending' AND Opportunity__c IN: opptyIdSet];
List<Finance_Partner_Quote__c> listFPQForUpdate = new List<Finance_Partner_Quote__c>();
FOR(Finance_Partner_Quote__c recFPQ : listFPQ) {
recFPQ.Financing_Decision__c = 'Withdrawn ';
listFPQForUpdate.add(recFPQ);
}
List<Contract> listContractForUpdate = new List<Contract>();
    FOR(Contract recCon : [SELECT Id, Finance_Partner_Account__c, SBQQ__Opportunity__r.Finance_Partner__c  FROM Contract
    WHERE SBQQ__Opportunity__c IN: opptyIdForContractSet AND SBQQ__Opportunity__r.Finance_Partner__c != null
    AND SBQQ__Opportunity__r.StageName = 'Closed Won' AND SBQQ__Opportunity__r.Finance_Partner__r.Is_Finance_Partner_Active__c = true]) {
recCon.Finance_Partner_Account__c = recCon.SBQQ__Opportunity__r.Finance_Partner__c;
listContractForUpdate.add(recCon);
}
if(listFPQForUpdate.size()>0) {
update listFPQForUpdate;
}
if(listContractForUpdate.size()>0) {
update listContractForUpdate;
}
}
// added for GTMS-16003 ends here
//GTMS-16221 -- Created method to check for closed won opps and pass to Future method
public void populateFinacePartneronAccount(Map<Id,Opportunity> mapOldOpp, List<opportunity> newOppList){
Set<Id> closedWonOpportunityAccIdSet = new Set<Id>();
Set<Id> closedWonOpportunityIdSet = new Set<Id>();
for(Opportunity opp : newOppList){
if(mapOldOpp == null && opp.StageName == 'Closed Won' &&  opp.Finance_Partner__c != null && opp.Type == 'Revenue Opportunity'){
closedWonOpportunityAccIdSet.add(opp.AccountId);
closedWonOpportunityIdSet.add(opp.Id);
}
else if(mapOldOpp !=null && opp.StageName == 'Closed Won' && mapOldOpp.get(opp.Id).StageName != 'Closed Won' &&  opp.Finance_Partner__c != null && opp.Type == 'Revenue Opportunity'){
system.debug('***populateFinacePartneronAccountCheckPASSED');
closedWonOpportunityAccIdSet.add(opp.AccountId);
closedWonOpportunityIdSet.add(opp.Id);
}
}
if(!closedWonOpportunityAccIdSet.isEmpty()){
String JsonoppAccIds = JSON.serialize(closedWonOpportunityAccIdSet);
String JsonoppIds = JSON.serialize(closedWonOpportunityIdSet);
//GTMS-16221 -- Invoking below future method to process the required logic as update is on Account object
if(!System.isFuture() && !System.isScheduled() && !System.isQueueable() && !System.isBatch()){
populateFinacePartneronAccountFuture(JsonoppAccIds,JsonoppIds);
}
}
}
//GTMS-16221 -- Created future method to update accounts with Finance Partner details
@Future
public static void populateFinacePartneronAccountFuture(String jsonOppAccIds, String jsonOppIds){
Set<Id> oppAccIds = (Set<Id>)JSON.deserialize(jsonOppAccIds,Set<Id>.class);
Set<Id> oppIds = (Set<Id>)JSON.deserialize(jsonOppIds,Set<Id>.class);
Map<Id, Opportunity> oldestOpportunityMap = new Map<Id, Opportunity>();
List<Account> listAccountstoUpdate = new List<Account>();
List<Finance_Partner_Quote__c> listFPQstoUpdate = new List<Finance_Partner_Quote__c>();
List<Opportunity> listOpportunities = new List<Opportunity>([SELECT Id, Name, AccountId, CloseDate,Finance_Partner__c FROM Opportunity WHERE AccountId In:oppAccIds and StageName = 'Closed Won' and Finance_Partner__c != '' and Type = 'Revenue Opportunity' ORDER BY CloseDate ASC]);
List<Finance_Partner_Quote__c> listfpqValues = new List<Finance_Partner_Quote__c>([Select Id,Name,Opportunity__c,Finance_Partner__c,Opportunity__r.AccountId,Opportunity__r.Type,Opportunity__r.StageName,Opportunity__r.contractId,Opportunity__r.Finance_Partner__c,Opportunity__r.contract.EndDate from Finance_Partner_Quote__c where Opportunity__c In:oppIds]);
system.debug('***populateFinacePartneronAccountFuture'+listOpportunities);
for (Opportunity opp : listOpportunities) {
if (!oldestOpportunityMap.containsKey(opp.AccountId)) {
// If account is not already in the map, add the opportunity
oldestOpportunityMap.put(opp.AccountId, opp);
} else {
// Check if the current opportunity's close date is earlier than the one in the map
Opportunity existingOldestOpportunity = oldestOpportunityMap.get(opp.AccountId);
if (opp.CloseDate < existingOldestOpportunity.CloseDate) {
// Update the map if the current opportunity is older
oldestOpportunityMap.put(opp.AccountId, opp);
}
}
system.debug('***populateFinacePartneronAccountFutureMAP'+oldestOpportunityMap);
}
//To set Finance Partner and 3PF customer Fields on Account
for (Opportunity opp : oldestOpportunityMap.values()) {
Account acc = new Account();
acc.Id = opp.AccountId;
acc.Finance_Partner__c = opp.Finance_Partner__c;
acc.X3PF_Customer__c = true;
listAccountstoUpdate.add(acc);
}
//Update accounts with Finance Partner
if(listAccountstoUpdate.size() > 0){
update listAccountstoUpdate;
}
//To set Contract EndDate on FPQ records
if(listfpqValues.size() > 0){
for(Finance_Partner_Quote__c fpquote:listfpqValues){
Finance_Partner_Quote__c fpq = new Finance_Partner_Quote__c();
fpq.Id = fpquote.Id;
fpq.Contract_End_Date__c = fpquote.Opportunity__r.contract.EndDate;
listFPQstoUpdate.add(fpq);
}
}
//Update Contract EndDate on FPQ records
if(listFPQstoUpdate.size() >0){
update listFPQstoUpdate;
}
}
//GTMS-16459 -- Added validation to check if License Term of Quote and Orderform are not matching,
// and stage is moved to 98% by AE profiles on FinancePartner Opportunities, display an error message and block the update
public void validateLicenseTermOnOfandCPQ(List<Opportunity> newOppList, Map<Id, Opportunity> oldOppMap) {
Set<Id> oppIDs = new Set<Id>();
List<dsfs__DocuSign_Status__c> listOFCPtoValidate = new List<dsfs__DocuSign_Status__c>();
Map<Id,dsfs__DocuSign_Status__c > mapOFQuoteLicenseTerms = new Map<Id,dsfs__DocuSign_Status__c >();
for(Opportunity opp:newOppList){
if(opp.Finance_Partner__c != null && Label.Samsara_AEs_Profiles_List.contains(String.valueOf(UserInfo.getProfileId())) && opp.StageName == 'Orders Processing' && opp.SBQQ__PrimaryQuote__c != null){
oppIDs.add(opp.Id);
}
}
if(oppIDs.size() > 0){
listOFCPtoValidate = [Select Id,License_Term__c ,dsfs__Opportunity__c ,
dsfs__Opportunity__r.SBQQ__PrimaryQuote__c,dsfs__Opportunity__r.SBQQ__PrimaryQuote__r.License_Term__c
from dsfs__DocuSign_Status__c where dsfs__Opportunity__c in : oppIDs and
License_Term__c != null and
dsfs__Opportunity__r.SBQQ__PrimaryQuote__r.License_Term__c != ''];
}
if(listOFCPtoValidate.size () > 0){
for(dsfs__DocuSign_Status__c docsts:listOFCPtoValidate){
mapOFQuoteLicenseTerms.put(docsts.dsfs__Opportunity__c,docsts);
}
}
if(mapOFQuoteLicenseTerms != null){
for(Opportunity opptoValidate:newOppList){
if(mapOFQuoteLicenseTerms.containsKey(opptoValidate.Id) && mapOFQuoteLicenseTerms.get(opptoValidate.Id).dsfs__Opportunity__r.SBQQ__PrimaryQuote__r.License_Term__c != String.valueOf(mapOFQuoteLicenseTerms.get(opptoValidate.Id).License_Term__c)){
opptoValidate.addError('There is a difference in license term on Order Form/SFDC');
}
}
}
}
//GTMS-23000
public static void updateOpptyFromContractUsingWASD(Opportunity opp,Map<Id, Contract> contractsMapNew) {
if(System.Label.WASD_Logic_Check.equalsIgnoreCase('true') && contractsMapNew != null && contractsMapNew.size()>0 && contractsMapNew.containsKey(opp.SBQQ__RenewedContract__c)
	&& contractsMapNew.get(opp.SBQQ__RenewedContract__c).Weighted_Average_Start_Date__c != null){
			opp.License_Start_Date__c = contractsMapNew.get(opp.SBQQ__RenewedContract__c).Weighted_Average_Start_Date__c;
        	if(opp.IsClosed==false){
				if(opp.License_Start_Date__c >= date.today()){
					opp.Adjust_License_Start_Date__c = true;
				}else{
					opp.Adjust_License_Start_Date__c = false;
				}
}
} 
}
    public void updateChildTrialOptyTrialStatus(Map<Id, Opportunity> oldOppMap, list<Opportunity> newOppList){

        loadOppFields(newOppList);

        for(Opportunity opty :newOppList){
            
            if(opty.stageName != 'Ready to Ship' || oldOppMap.get(opty.Id).stageName == 'Ready to Ship' || oppFields.get(opty.Id).Type != 'Revenue Opportunity' || oppFields.get(opty.Id).Opportunities__r == null)
                continue;

            for(Opportunity trialOpty : oppFields.get(opty.Id).Opportunities__r){

                if(trialOpty.Type != 'Free Trial Opportunity') continue;

                if(opty.Free_Trial_Purchase__c == 'Full Buy') trialOpty.Trial_Status__c = 'Purchased';
                if(opty.Free_Trial_Purchase__c == 'Partial Buy') trialOpty.Trial_Status__c = 'Partial Purchase';

                if(trialOpty.Trial_Status__c == 'Purchased' || trialOpty.Trial_Status__c == 'Partial Purchase') DMLWrapper.doUpdate(trialOpty, new List<SObjectField>{Opportunity.Trial_Status__c});
            }
        }
    } 
    //GTMS-23446 Start
public void masterSheetReqBefore(List<Opportunity> newOppList, Map<Id, Opportunity> oldOppMap) {
    Map<String, FieldNamesByApiNamesSetting__mdt> fieldSettings = FieldNamesByApiNamesSetting__mdt.getAll();
    Map<String, String> fieldApiNames = new Map<String, String>();
    Map<String, FieldNamesByApiNamesSetting__mdt> fieldApiNamesByMeta = new Map<String, FieldNamesByApiNamesSetting__mdt>();
        List<String> emeaShippingCountryList = System.Label.EMEA_SHIPPING_COUNTRIES.split(','); // EMEA automation notes logic
        
    List<String> listOfValues = new List<String>();
    for (String key : fieldSettings.keySet()) {
        FieldNamesByApiNamesSetting__mdt setting = fieldSettings.get(key);
        fieldApiNames.put(setting.Field_API_Name__c, setting.Field_Label__c);
        fieldApiNamesByMeta.put(setting.Field_API_Name__c + '-' + setting.Opportunity_type__c, setting);
        if (setting.Values__c != null) {
            listOfValues.addAll(setting.Values__c.split(','));
        }
    }
    for (Opportunity opp : newOppList) {
        List<String> notNullFieldsForPromo = new List<String>();
        List<String> notNullFieldsForRevenue = new List<String>();
        Opportunity oldOpp = oldOppMap.get(opp.Id);
        for (String fP : fieldApiNames.keySet()) {
                if ((opp.Shipping_Country__c == 'United States' || opp.Shipping_Country__c == 'Canada' || emeaShippingCountryList.contains(opp.Shipping_Country__c)) && (opp.of_LIC_Products__c == 0 || (opp.of_LIC_Products__c != 0 && (opp.of_HW_Products__c != 0 || opp.of_Accessories__c != 0))) && // EMEA automation notes logic
                ((oldOpp.StageName != 'Orders Processing' && opp.StageName == 'Orders Processing') ||
                 (opp.StageName == 'Closing' && String.isBlank(opp.Finance_Kickback_Reason__c) && oldOpp.StageName != 'Closing' && opp.Bypass_Validation_rule__c))) {
                opp.Automation_Notes__c = '';
                Boolean isPromoOpportunity = opp.Type == 'Promo Opportunity';
                Boolean isRevenueOpportunity = opp.Type == 'Revenue Opportunity';
                if (opp.get(fP) != null && fieldApiNamesByMeta.containsKey(fP + '-' + opp.Type)) {
                    if (isPromoOpportunity) {
                        if ((fP == 'Free_Trial_Purchase__c' && opp.Free_Trial_Purchase__c != null) ||
                            (fP == 'Total_Weight_oz__c' && opp.Total_Weight_oz__c > 6500) ||
                            (fP == 'Shipping_Carrier__c' && !listOfValues.contains(opp.Shipping_Carrier__c)) ||
                            (fP == 'Shipping_Method__c' && !listOfValues.contains(opp.Shipping_Method__c)) ||
                            (fP == 'Shipping_Country__c' && !listOfValues.contains(opp.Shipping_Country__c)) ||
                            (fP != 'Free_Trial_Purchase__c' && fP != 'Shipping_Country__c' && fP != 'Shipping_Method__c' && fP != 'Shipping_Carrier__c' && fP != 'Total_Weight_oz__c')) {
                            notNullFieldsForPromo.add(fieldApiNames.get(fP));
                        }
                    } else if (isRevenueOpportunity) {
                        if ((fP == 'Free_Trial_Purchase__c' && opp.Free_Trial_Purchase__c != null && opp.Free_Trial_Purchase__c != 'No Purchase') ||
                            (fP == 'Total_Weight_oz__c' && opp.Total_Weight_oz__c > 6500) ||
                            (fP == 'Shipping_Carrier__c' && !listOfValues.contains(opp.Shipping_Carrier__c)) ||
                            (fP == 'Shipping_Method__c' && !listOfValues.contains(opp.Shipping_Method__c)) ||
                            (fP == 'Shipping_Country__c' && !listOfValues.contains(opp.Shipping_Country__c)) ||
                            (fP == 'Amount' && opp.Amount > 100000) ||
                            (fP != 'Segment_Sales_Role__c' && fP != 'Free_Trial_Purchase__c' && fP != 'Shipping_Country__c' && fP != 'Shipping_Method__c' && fP != 'Shipping_Carrier__c' && fP != 'Total_Weight_oz__c' && fP != 'Amount')) {
                            notNullFieldsForRevenue.add(fieldApiNames.get(fP));
                        }
                    }
                }
            }
        }
        if (!notNullFieldsForPromo.isEmpty()) {
            String fieldNames = String.join(notNullFieldsForPromo, ', ');
            String automationNotes = 'Not meeting the criteria: field names: ' + fieldNames;
            if (automationNotes.length() > 255) {
                automationNotes = automationNotes.substring(0, 255);
            }
            opp.Automation_Notes__c = automationNotes;
        }
        if (!notNullFieldsForRevenue.isEmpty()) {
            String fieldNames = String.join(notNullFieldsForRevenue, ', ');
            String automationNotes = 'Not meeting the criteria: field names: ' + fieldNames;
            if (automationNotes.length() > 255) {
                automationNotes = automationNotes.substring(0, 255);
            }
            opp.Automation_Notes__c = automationNotes;
        }
    }
}
// Method to handle logic for setting the annual discount line item before updates
public void expressSetAnnualDiscountLineItemOnbefore(Map<Id, Opportunity> oldOppMap, Map<Id, Opportunity> newOppMap) {
    if (OpportunityHelper.expressSetDiscountRun) {
        return;
    }
        // EMEA automation notes logic
    List<Opportunity> updateOpty = new List<Opportunity>();
    loadOppFields(newOppMap);
    List<String> lstDCLProdCodes = new List<String>();
        
        Map<String, String> prodCodesToDispatchMap = new Map<String, String>();
        List<String> emeaShippingCountryList = System.Label.EMEA_SHIPPING_COUNTRIES.split(',');
        
        // EMEA automation notes logic
        List<OpportunityLineItem> opptyLToUpdate = new List<OpportunityLineItem>();
    List<String> byPassShipFromLocation = System.Label.GTMS_ShipFromLocationProducts.split(',');
    for (Opportunity newOpp : newOppMap.values()) {
        String labelError = '';
        Opportunity oldOpp = oldOppMap.get(newOpp.Id);
        String prodCodesToDispatch = '';
        Decimal productCount = newOpp.of_HW_Products__c + newOpp.of_Accessories__c;
        Decimal expressSelectedDiscount = newOpp.Express_Selected_Discount__c != null ? newOpp.Express_Selected_Discount__c : 0;
        Integer QtyLimitPerProduct = getQtyLimitPerProduct(newOpp.Type);
            // EMEA automation notes logic
            if ((newOpp.Shipping_Country__c == 'Mexico' || newOpp.Shipping_Country__c == 'United States' || newOpp.Shipping_Country__c == 'Canada' || emeaShippingCountryList.contains(newOpp.Shipping_Country__c)) && (newOpp.of_LIC_Products__c == 0 || (newOpp.of_LIC_Products__c != 0 && (newOpp.of_HW_Products__c != 0 || newOpp.of_Accessories__c != 0))) && oldOpp.StageName != 'Orders Processing' && newOpp.StageName == 'Orders Processing') {
            if (newOpp.Type == 'Free Trial Opportunity' || newOpp.Type == 'Promo Opportunity') {
                    lstDCLProdCodes.addAll(System.Label.DCL_Product_SKU_List.split(','));
                lstDCLProdCodes.addAll(System.Label.DCL_Product_SKU_List_1.split(','));
                    lstDCLProdCodes.addAll(System.Label.VCK_EMEA_Promo_SKU.split(','));
                    if(newOpp.Type == 'Promo Opportunity') {
                        lstDCLProdCodes.addAll(System.Label.Mexico_SKU_Product_for_Promo.split(','));//GTMS-18016
                    }
                    
                    
            } else if (newOpp.Type == 'Revenue Opportunity') {
                lstDCLProdCodes.addAll(System.Label.DCL_Product_list_for_RevOppty.split(','));
                lstDCLProdCodes.addAll(System.Label.DCL_Product_list_for_RevOppty_extend_1.split(','));
                lstDCLProdCodes.addAll(System.Label.DCL_Product_list_for_RevOppty_extend_2.split(','));
                lstDCLProdCodes.addAll(System.Label.DCL_Product_list_for_RevOppty_extend_3.split(','));
                lstDCLProdCodes.addAll(System.Label.DCL_Product_list_for_RevOppty_extend_4.split(','));
                lstDCLProdCodes.addAll(System.Label.VCK_EMEA_Revenue_SKU.split(','));
                lstDCLProdCodes.addAll(System.Label.VCK_EMEA_Revenue_SKU_extend_1.split(','));
                lstDCLProdCodes.addAll(System.Label.VCK_EMEA_Revenue_SKU_extend_2.split(','));
                lstDCLProdCodes.addAll(System.Label.VCK_EMEA_Revenue_SKU_extend_3.split(','));
                lstDCLProdCodes.addAll(System.Label.Mexico_SKU_Product_for_Revenue.split(','));//GTMS-18016
                lstDCLProdCodes.addAll(System.Label.Mexico_SKU_Products_for_Revenue_1.split(','));//GTMS-18016
                lstDCLProdCodes.addAll(System.Label.Mexico_SKU_Products_for_Revenue_2.split(','));//GTMS-18016
                    
            }
            Boolean productFlag = true;
            for (OpportunityLineItem oli : oppFields.get(newOpp.Id).OpportunityLineItems) {
                if (lstDCLProdCodes.contains(oli.ProductCode) && oli.Quantity >= 1) {
                    prodCodesToDispatch = prodCodesToDispatch + ',' + oli.ProductCode;
                } else {
                    labelError = 'Check if the products are added as per the Custom label';
                }
            }
            String automationNotes = String.isNotBlank(newOpp.Automation_Notes__c) ? (newOpp.Automation_Notes__c + ' ' + labelError) : labelError;
            if (automationNotes.length() > 255) {
                automationNotes = automationNotes.substring(0, 255);
            }
            newOpp.Automation_Notes__c = automationNotes;
        }
    }
  } 
//GTMS-27166
public void sendWarrantyExchangeEOLEmail(Map<Id, Opportunity> oldOppMap, Map<Id, Opportunity> newOppMap) {
        ReturnLabelEmailer.sendWarrantyExchangeEmailAlert(oldOppMap, newOppMap);
    }

    /**
     * @description Sets the Renewal Checkout Agreement Link based on comprehensive validation checks
     * Validates payment type, billing information, shipping requirements, and business rules
     * @param opportunity The opportunity record to update
     * @param relatedAccount The related account record
     * @param oppWithFields The opportunity record with related fields (including primary quote)
     * @author GTMS-28039
     */
    public void setRenewalCheckoutAgreementLink(Opportunity opportunity, Account relatedAccount, Opportunity oppWithFields) {

        SBQQ__Quote__c primaryQuote = (oppWithFields?.SBQQ__PrimaryQuote__r != null) ? 
                oppWithFields.SBQQ__PrimaryQuote__r : null;
        
        if (primaryQuote == null) {
            return;
        }

        // Initialize validation flags
        Boolean isEligibleForCheckoutLink = false;
        
        try {        

            // Define validation sets for contains checks (best practice: use Sets for O(1) lookup)
            Set<String> restrictedPaymentTypes = new Set<String>{'Direct Semi-Annual', 'Direct Quarterly'};
            Set<String> validNorthAmericaCountries = new Set<String>{'United States', 'Canada', 'Mexico'};
            Set<String> validEuropeanCountries = new Set<String>{
                'United Kingdom', 'France', 'Belgium', 'Germany', 'Netherlands', 
                'Ireland', 'Austria', 'Italy', 'Luxembourg', 'Switzerland'
            };
            Set<String> validEuropeanCurrencies = new Set<String>{'GBP', 'EUR'};
            Set<String> exemptShippingMethods = new Set<String>{
                'Ground', 'Next Day Air', 'MX Standard', 'MX Express', 'UK Standard', 'UK Express'
            };

            // Validation 1: Payment Type Checks (with null safety)
            Boolean paymentChecks = String.isNotBlank(opportunity.Selected_Payment_Type__c) && 
                !(String.isNotBlank(opportunity.Owner_Segment__c) && 
                  opportunity.Owner_Segment__c == 'AE1' && 
                  restrictedPaymentTypes.contains(opportunity.Selected_Payment_Type__c));

            // Validation 2: Basic Business Rules (with comprehensive null checks)
            Boolean basicChecks = relatedAccount != null && 
                primaryQuote != null &&
                opportunity.Reseller__c == null && // Reseller must be blank
                opportunity.Amount != null &&
                opportunity.Amount > 0 && // Opportunity ACV must be greater than 0
                String.isNotBlank(primaryQuote.SBQQ__Status__c) &&
                primaryQuote.SBQQ__Status__c == 'Approved' && // Quote must be approved
                String.isNotBlank(opportunity.Opportunity_UUID__c); // UUID required for link generation
            

            // Validation 3: Billing Information Completeness (with null safety for all fields)
            Boolean billingChecks = relatedAccount != null &&
                String.isNotBlank(opportunity.CurrencyIsoCode) &&
                String.isNotBlank(relatedAccount.CurrencyIsoCode) &&
                opportunity.CurrencyIsoCode == relatedAccount.CurrencyIsoCode && // Currency alignment
                String.isNotBlank(relatedAccount.Billing_First_Name__c) &&
                String.isNotBlank(relatedAccount.Billing_Last_Name__c) &&
                String.isNotBlank(relatedAccount.Billing_Email__c) &&
                String.isNotBlank(relatedAccount.Billing_Phone__c) &&
                String.isNotBlank(relatedAccount.BillingStreet) &&
                String.isNotBlank(relatedAccount.BillingCity) &&
                String.isNotBlank(relatedAccount.BillingPostalCode);

            Boolean validBillingLocation = false;
            if (relatedAccount != null && String.isNotBlank(relatedAccount.BillingCountry)) {
                if (String.isNotBlank(relatedAccount.BillingState) && 
                    validNorthAmericaCountries.contains(relatedAccount.BillingCountry)) {
                    validBillingLocation = true;
                }
                else if (String.isBlank(relatedAccount.BillingState) && 
                         String.isNotBlank(relatedAccount.CurrencyIsoCode) &&
                         validEuropeanCurrencies.contains(relatedAccount.CurrencyIsoCode) && 
                         validEuropeanCountries.contains(relatedAccount.BillingCountry)) {
                    validBillingLocation = true;
                }
            }
            Boolean shippingChecks1 = false;
            Boolean shippingChecks2 = false;

            if (opportunity.Multi_Line_Shipping__c == true && 
                opportunity.Shipping_and_Handling_Manual__c != null) {
                shippingChecks1 = true;
            }
            else if (opportunity.Multi_Line_Shipping__c == false) {
                shippingChecks1 = true; 
            }
            
            if (String.isNotBlank(opportunity.Shipping_Method__c) && 
                exemptShippingMethods.contains(opportunity.Shipping_Method__c)) {
                shippingChecks2 = true; 
            }else if((String.isBlank(opportunity.Shipping_Method__c)) || (String.isNotBlank(opportunity.Shipping_Method__c) && 
                !exemptShippingMethods.contains(opportunity.Shipping_Method__c))) {
                shippingChecks2 = (opportunity.Shipping_and_Handling_Manual__c != null);
            }
            
            Boolean shippingChecks = shippingChecks1 && shippingChecks2;
            isEligibleForCheckoutLink = paymentChecks && basicChecks && billingChecks && validBillingLocation && shippingChecks;

        } catch (Exception ex) {
        }

        if (isEligibleForCheckoutLink && String.isNotBlank(opportunity.Opportunity_UUID__c)) {
            opportunity.Renewal_Checkout_Agreement_Link__c = 
                'https://www.samsara.com/checkout/opportunity?id=' + opportunity.Opportunity_UUID__c;
        } else {
            opportunity.Renewal_Checkout_Agreement_Link__c = null;
        }
    }
}