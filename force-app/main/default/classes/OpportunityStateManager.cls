/**
 * Created by henryzhao on 2020-01-20.
 */

public class OpportunityStateManager {
    private static OpportunityStateManager instance = null;

    private static Map<String, Boolean> contextFirstRun = new Map<String, Boolean>();

    public Map<Id, Contact> contactInformationMap;
    public Map<Id, Account> accountInformationMap;
    public Map<Id, User> userInformationMap;
    private OrgWideEmailAddress samsaraSalesEmail;
    private Map<String, Map<String, Id>> languageToTemplateId;

    public static OpportunityStateManager getInstance() {
        if (instance == null) {
            instance = new OpportunityStateManager();
        }
        return instance;
    }

    private OpportunityStateManager() {
        this.languageToTemplateId = new Map<String, Map<String, Id>>();
        this.samsaraSalesEmail = null;
    }

    /**
    * @author Groundswell - Henry Zhao - henry@gscloudsolutions.com
    * @date 2020-01-22
    *
    * @description Controls whether a trigger context can be re-executed
    */
    public static Boolean ctxCanRun() {
        return methodCanRun(String.valueOf(Trigger.operationType));
    }

    public static Boolean methodCanRun(String methodName) {
        if (contextFirstRun.keySet().contains(methodName)) {
            return contextFirstRun.get(methodName);
        }
        return true;
    }

    /**
    * @author Groundswell - Henry Zhao - henry@gscloudsolutions.com
    * @date 2020-01-22
    *
    * @description Sets the already-ran flag
    */
    public static void ctxRan() {
        methodRan(String.valueOf(Trigger.operationType));
    }
    public static void methodRan(String methodName) {
        contextFirstRun.put(methodName, false);
    }

    public Map<String, Id> getlanguageToTemplateId(String key) {
        if (!this.languageToTemplateId.keySet().contains(key)) {
            Map<String, Id> res = TemplateSelectionHelper.getTemplates(key);
            this.languageToTemplateId.put(key, res);
        }
        return this.languageToTemplateId.get(key);
    }

    public OrgWideEmailAddress getsamsaraSalesEmail() {
        if (this.samsaraSalesEmail == null) {
            OrgWideEmailAddress res = [
                    SELECT Id, Address
                    FROM OrgWideEmailAddress
                    WHERE Address = 'sales@samsara.com'
                    LIMIT 1
            ];
            this.samsaraSalesEmail = res;
        }
        return this.samsaraSalesEmail;
    }

    public void addToUserMap(List<Opportunity> opps) {
        if (this.userInformationMap != null) {
            return;
        }
        this.userInformationMap = new Map<Id, User>();
        Set<Id> userIdsToQuery = new Set<Id>();
        for (Opportunity opp : opps) {
            userIdsToQuery.add(opp.OwnerId);
        }

        this.userInformationMap.putAll(UserService.selectUserForEmail(userIdsToQuery));
    }

    public void addToContactMap(List<Opportunity> opps) {
        if (this.contactInformationMap != null) {
            return;
        }
        this.contactInformationMap = new Map<Id, Contact>();
        Set<Id> contactIdsToQuery = new Set<Id>();

        for (Opportunity opp : opps) {
            if (opp.Trial_Primary_Contact__c != null) {
                contactIdsToQuery.add(opp.Trial_Primary_Contact__c);
            } else if (opp.Shipping_Contact__c != null) {
                contactIdsToQuery.add(opp.Shipping_Contact__c);
            } else {
//                should never reach here, invalid data
            }
        }
        this.contactInformationMap.putAll(new Map<Id, Contact>([
                SELECT Id, FirstName, LastName, Email
                FROM Contact
                WHERE Id IN :contactIdsToQuery
        ]));
    }
    public void addToAccountMap(List<Opportunity> opps) {
        if (this.accountInformationMap != null) {
            return;
        }
        this.accountInformationMap = new Map<Id, Account>();
        Set<Id> accountIds = new Set<Id>();
        for (Opportunity opp : opps) {
            accountIds.add(opp.AccountId);
        }
        Map<Id, Account> oppAccounts = new Map<Id, Account>([
                SELECT Id, Free_Trial_Kit_Sent_Date__c,
                        Welcome_Kit_Sent_Date__c, Segment_Text_stamped__c,
                        Billing_Email__c, BillingCountry,Which_written_language__c,
                        BillingState, First_Purchase_Value__c, (
                        SELECT Id, Pricebook2.Name, Pricebook2Id,
                                CloseDate, StageName, Type
                        FROM Opportunities
                        ORDER BY CloseDate DESC
                ), (
                        SELECT id, Name
                        FROM Shipping_Addresses__r
                        ORDER BY LastModifiedDate desc
                        LIMIT 1
                )
                FROM Account
                WHERE Id
                        IN :accountIds
        ]);

        this.accountInformationMap.putAll(oppAccounts);
    }

    public Map<Id, Opportunity> selectExtendedOpportunityMap(Set<Id> opportunityIds) {
        return new Map<Id, Opportunity>([
                SELECT Id, AccountId, Amount, Type, StageName,
                        Pricebook2.Name, Pricebook2Id, CurrencyISOCode, (
                        SELECT Id, Description, Discount, ListPrice,
                                Name, OpportunityId, Product2Id,
                                PriceBookEntryId, ProductCode,
                                TotalPrice, UnitPrice, Quantity,
                                Other_Discount__c, Selected_Sales_Price__c,
                                Express_Annual_Discount__c
                        FROM OpportunityLineItems
                )
                FROM Opportunity
                WHERE Id
                        IN :opportunityIds
        ]);
    }

}