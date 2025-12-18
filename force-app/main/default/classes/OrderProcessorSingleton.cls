public class OrderProcessorSingleton {
    
    private static OrderProcessorSingleton instance;
    private Map<Id, Account> accountCache = new Map<Id, Account>();
    private Map<Id, Contact> contactCache = new Map<Id, Contact>();
    private Map<Id, Id> customer360Cache = new Map<Id, Id>();
    private Map<Id, Integer> subscriptionCountCache = new Map<Id, Integer>();
    private Map<Id,Opportunity> opportunityCache = new Map<Id,Opportunity>();
    private Map<Id,SBQQ__Quote__c> quoteCache = new Map<Id,SBQQ__Quote__c>();
    private Map<String, Shipping_Address__c> shippingAddressCache = new Map<String, Shipping_Address__c>();
    private Map<String, Shipping_Address__c> contactsWithShippingAddressCache = new Map<String, Shipping_Address__c>();
    private OrderPayload orderPayloadCache;
    private static Map<String, String> contactAndShippingAddressIdMap = new Map<String, String>();
    private Map<String, Shipping_Countries__mdt> shippingCountryDefaults = new map<String, Shipping_Countries__mdt>();
    
    private OrderProcessorSingleton() {}
    
    public static OrderProcessorSingleton getInstance() {
        if (instance == null) {
            instance = new OrderProcessorSingleton();
        }
        return instance;
    }
    
    public Id queryCustomer360(Id accountId) {
        if (String.isBlank(accountId)) return null;
        
        if (!customer360Cache.containsKey(accountId)) {
            try {
                Id contractId = [SELECT Id, Latest_Active_Contract_Historical__r.Id FROM Customer_360__c WHERE Account__c = :accountId AND Latest_Active_Contract_Historical__r.Id != NULL LIMIT 1]?.Latest_Active_Contract_Historical__r?.Id;
                customer360Cache.put(accountId, contractId);
            } catch (Exception e) {
                throw e;
            }
        }
        return customer360Cache.get(accountId);
    }
    
    public Account queryAccount(Id accountId) {
        if (String.isBlank(accountId)) return null;
        
        if (!accountCache.containsKey(accountId)) {
            try {
                Account accnt = [SELECT Id, Latest_Active_Contract__c,Active_Payment_Processing__c,Auto_renewal_Opt_Out__c,OwnerId FROM Account WHERE Id = :accountId LIMIT 1];
                accountCache.put(accountId, accnt);
            } catch (Exception e) {
                throw e;
            }
        }
        return accountCache.get(accountId);
    }
    
    public Contact queryContact(Id accountId) {
        if (String.isBlank(accountId)) return null;
        
        if (!contactCache.containsKey(accountId)) {
            try {
                List<Contact> cntList = [SELECT Id, AccountId FROM Contact WHERE AccountId = :accountId LIMIT 1];
                if(!cntList.isEmpty()){
                    Contact cnt = cntList[0];
                    contactCache.put(cnt.AccountId, cnt);
                }
            } catch (Exception e) {
                throw e;
            }
        }
        return contactCache.get(accountId);
    }
    
    public Integer getActiveSubscriptionsCount(Id contractId) {
        if (String.isBlank(contractId)) return 0;
        
        if (!subscriptionCountCache.containsKey(contractId)) {
            try {
                AggregateResult[] results = [SELECT COUNT(Id) totalCount FROM SBQQ__Subscription__c WHERE SBQQ__Contract__c = :contractId AND SBQQ__Contract__r.Is_Active__c =true AND SBQQ__Contract__r.EndDate >= TODAY AND SBQQ__TerminatedDate__c = NULL];
                subscriptionCountCache.put(contractId, (Integer) results[0].get('totalCount'));
            } catch (Exception e) {
                throw e;
            }
        }
        return subscriptionCountCache.get(contractId);
    }
    
    public Shipping_Address__c queryShippingAddress(OrderPayload payload) {
        if (payload?.shipping_address == null || payload?.order?.account_id == null) {
            return null;
        }
        
        String accountId = payload.order.account_id.trim();
        OrderPayload.ShippingAddress addr = payload.shipping_address;
        
        // Prepare all fields to be used in the query
        String line1     = addr.shippingAddressLine1?.trim();
        String line2     = addr.shippingAddressLine2?.trim();
        String city      = addr.shippingCity?.trim();
        String state     = addr.shippingState?.trim();
        String zip       = addr.shippingZipCode?.trim();
        String country   = addr.shippingCountry?.trim();
        String firstName = addr.shippingFirstName?.trim();
        String lastName  = addr.shippingLastName?.trim();
        String email     = addr.shippingEmail?.trim();
        String phone     = addr.shippingPhone?.trim();
        
       if (!shippingAddressCache.containsKey(accountId)) {
            try {
                List<Shipping_Address__c> match = [
                    SELECT Id, Name, Account__c, Shipping_Contact__c,
                    Shipping_Address_Line_1__c, Shipping_Address_Line_2__c, 
                    Shipping_City__c, Shipping_State__c, Shipping_Zip_Code__c, 
                    Shipping_Country__c, Shipping_Email__c, Shipping_Phone__c, 
                    Shipping_FirstName__c, Shipping_LastName__c
                    FROM Shipping_Address__c 
                    WHERE Account__c = :accountId
                    AND Shipping_Address_Line_1__c = :line1
                    AND Shipping_Address_Line_2__c = :line2
                    AND Shipping_City__c           = :city
                    AND Shipping_State__c          = :state
                    AND Shipping_Zip_Code__c       = :zip
                    AND Shipping_Country__c        = :country
                    AND Shipping_FirstName__c      = :firstName
                    AND Shipping_LastName__c       = :lastName
                    AND Shipping_Email__c          = :email
                    AND Shipping_Phone__c          = :phone
                    LIMIT 1
                ];
                if(match!=null && !match.isEmpty()){
                    shippingAddressCache.put(accountId, match[0]);
                }
            } catch (QueryException qe) {
                throw qe;
            }
        }
        
        return shippingAddressCache.get(accountId);
    }
    
    
    public static List<SBQQ__QuoteLine__c> queryQuoteLines(Id quoteId) {
        if (String.isBlank(quoteId)) return new List<SBQQ__QuoteLine__c>();
        try {
            return [SELECT Id FROM SBQQ__QuoteLine__c WHERE SBQQ__Quote__c = :quoteId];
        } catch (Exception e) {
            throw e;
        }
    }
    
    public Opportunity queryOpportunity(Id opportunityId){
        if(String.isBlank(opportunityId)){
            return null;
        }
        
        if(!opportunityCache.containsKey(opportunityId)){
            opportunityCache = new Map<Id,Opportunity>([Select id, Name, AccountId, Account.Netsuite_Id__c,Amount,StageName,CloseDate, Shipping_Contact__c,OwnerId,Small_Fleet_Opportunity__c,Pricebook2Id,
                                                        License_Term__c,CurrencyIsoCode,Can_Create__c,Exclude_from_Xactly__c,Is_Webstore_Upsell_Opportunity__c,Initial_Payment_Terms__c,Payment_Terms__c,
                                                        Configuration_Segment__c,Purchase_Type__c,SBQQ__PrimaryQuote__r.id,SBQQ__PrimaryQuote__r.SBQQ__Uncalculated__c,Ship_From_Location__c,
                                                        Amount_Received__c,SBQQ__PrimaryQuote__r.Amount_Received__c,Express_Agreement_Accepted_Date__c,SBQQ__RenewedContract__r.Weighted_Average_Start_Date__c,
                                                        SBQQ__PrimaryQuote__r.Co_Term_Contract__c, Probability, shipping_address_new__c, Shipping_Country__c,Shipping_Method__c,Shipping_Carrier__c from Opportunity where id=:opportunityId]);
        }
        
        return opportunityCache?.get(opportunityId);
    }
    
    public SBQQ__Quote__c queryQuote(Id quoteId){
        if(String.isBlank(quoteId)){
            return null;
        }
        
        if(!quoteCache.containsKey(quoteId)){
            quoteCache = new Map<Id,SBQQ__Quote__c>([Select id, Name, SBQQ__Uncalculated__c,Selected_Payment_Type__c,Checkout_Discount__c,Shipping_Method__c,SBQQ__PaymentTerms__c,PO_Number__c,SBQQ__Primary__c,SBQQ__Status__c,
                                                     SBQQ__StartDate__c,Amount_Received__c,Payment_Token__c,Payment_Method__c,Stripe_Charge_Id__c,Stripe_Intent_Id__c,Shipping_And_Handling_Manual__c,
                                                     VatId__c, Express_Agreement_Accepted_Date__c,Shipping_Address_NEW__c from SBQQ__Quote__c where id=:quoteId]);
        }
        
        return quoteCache?.get(quoteId);
    }
    
    public Request_Tracker__c findRequestTracker(String contractId,String accountId) {
        if(String.isBlank(accountId) || String.isBlank(contractId)) return null;
        
        List<Request_Tracker__c> trackerList = [SELECT Id,OrderId__c, Status__c FROM Request_Tracker__c WHERE contractId__c=:contractId and Account_Id__c=:accountId LIMIT 1];
        return trackerList.isEmpty() ? null : trackerList[0];
    }
    
    public OrderPayload deserializePayload(String jsonPayload) {
        if (String.isBlank(jsonPayload)) return null;
        if (orderPayloadCache == null) {
            try {
                orderPayloadCache = (OrderPayload) JSON.deserialize(jsonPayload, OrderPayload.class);
            } catch (Exception e) {
                throw e;
            }
        }
        return orderPayloadCache;
    }

    
    public Opportunity setShippingDefaults(Opportunity o, String shippingCountry){
        getShippingCountryDefaults();
        
        if (String.isNotBlank(shippingCountry) && (shippingCountryDefaults.containsKey(shippingCountry))){
            //TODO: commenting this for future reference
            o.Shipping_Carrier__c   = shippingCountryDefaults.get(shippingCountry).Shipping_Carrier__c;
            o.Shipping_Method__c = shippingCountryDefaults.get(shippingCountry).Shipping_Method__c;
            o.Ship_From_Location__c = shippingCountryDefaults.get(shippingCountry).Ship_From_Location__c;
        }
        return o;
    }

    private void getShippingCountryDefaults(){
        if(!shippingCountryDefaults.isEmpty()) return; 

        Map<String, Shipping_Countries__mdt> scMDValues = Shipping_Countries__mdt.getAll();
        for(String key :scMDValues.keySet()){
            shippingCountryDefaults.put(scMDValues.get(key).MasterLabel, scMDValues.get(key));
        }
    }

    public Shipping_Address__c queryShiippingAddressById(String shippingAddressId) {
        try {
            return [SELECT Id, Shipping_Contact__c FROM Shipping_Address__c WHERE Id = :shippingAddressId LIMIT 1];
        } catch (Exception e) {
            throw e;
        }
    }
}