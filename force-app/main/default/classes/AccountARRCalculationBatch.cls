global class AccountARRCalculationBatch implements Database.Batchable<sObject>, Database.stateful{
    
    private Date todayDate; 
    private Set<Id> accountIds;
    Set<Id> accountResetIds = new Set<Id>();
    Map<Id,Decimal> accountCustomerARRMap = new Map<Id,Decimal>(); 
     private static final String OPPORTUNITY_QUERY = 
        'SELECT Id, Name, Type, StageName, SBQQ__Renewal__c, SBQQ__AmendedContract__c, ' +
        'License_Start_Date__c, License_End_Date__c, ' +
        'ACV_Bookings_USD__c, Returning_Opportunity_18_Digit_ID__c, Returning_Opportunity__r.License_End_Date__c, ' +
        'Returning_Opportunity__r.StageName, AccountId, Account.Customer_ARR__c, Rebate_Type__c,  ' +
        'Returning_Opportunity__r.License_Start_Date__c ' +
        'FROM Opportunity ' +
        'WHERE AccountId =: accountIds ' +
        'AND ACV_Bookings_USD__c != null AND ACV_Bookings_USD__c != 0 ' +
        'AND Rebate_Type__c != \'Buyout\' ' +
        'AND (' +
        '        (StageName = \'Closed Won\' ' +
        '        AND (License_Start_Date__c <= :todayDate AND License_End_Date__c >= :todayDate )) ' +
        '        OR (' +
        '            StageName = \'Refunded - Closed\' ' +
        '           AND Returning_Opportunity__r.StageName = \'Closed Won\' ' +                        
        '            AND (Returning_Opportunity__r.License_Start_Date__c <= :todayDate AND Returning_Opportunity__r.License_End_Date__c >= :todayDate)' +
        '    )' +
        ')'+
        'ORDER BY AccountId';
    
    public AccountARRCalculationBatch(Set<Id> accountIds) {
        this.todayDate = Date.today();
        this.accountIds = accountIds;
        this.accountResetIds.addAll(accountIds);
    }
    
    global Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator(OPPORTUNITY_QUERY);
    }
    
    global void execute(Database.BatchableContext BC, List<Opportunity> scope) {
        Map<Id,Decimal> mapAccountARR = new Map<Id,Decimal>();
        Map<Id, List<Opportunity>> accountOpportunitiesMap = new Map<Id, List<Opportunity>>();
        for (Opportunity opp : scope) {
            if (!accountOpportunitiesMap.containsKey(opp.AccountId)) {
                accountOpportunitiesMap.put(opp.AccountId, new List<Opportunity>());
            }
            accountOpportunitiesMap.get(opp.AccountId).add(opp);
            mapAccountARR.put(opp.AccountId,opp.Account.Customer_ARR__c);
        } 
        List<Account> accountsToUpdateList = new List<Account>();
        for (Id accId : accountOpportunitiesMap.keySet()) {
            accountResetIds.remove(accId);
            List<Opportunity> oppList = accountOpportunitiesMap.get(accId);
            Decimal totalACV = calculateTotalACV(oppList,todayDate);
            Decimal customerARR = 0;
            if (!accountCustomerARRMap.containsKey(accId)) {
                customerARR = totalACV; 
                accountCustomerARRMap.put(accId,totalACV);
            }else{
                Decimal accountArr = accountCustomerARRMap.get(accId);
                customerARR = accountArr + totalACV;
                accountCustomerARRMap.put(accId,totalACV);
            }

            Decimal existingARR = mapAccountARR.get(accId);
            
            Account acc = new Account(
                Id = accId,
                Customer_ARR__c = customerARR 
            );
            if(customerARR != existingARR){
                accountsToUpdateList.add(acc);
            }
            
        }
        
        
        // Perform the update
        if (!accountsToUpdateList.isEmpty()) {
            Database.SaveResult[] results = Database.update(accountsToUpdateList, false);
            
            // Log any errors encountered during update
            for (Database.SaveResult result : results) {
                if (!result.isSuccess()) {
                    for (Database.Error error : result.getErrors()) {
                        System.debug('Error updating Account in UpdateAccountARRQueueable: ' + error.getMessage());
                    }
                }
            }
        }
    }
    
    global void finish(Database.BatchableContext BC) {
        List<Account> resetAccountList = new List<Account>();
        if(!accountResetIds.isEmpty()){
            for(Id accId : accountResetIds){
                resetAccountList.add(new Account( Id = accId,Customer_ARR__c = 0));
            }
        }
        
        if(!resetAccountList.isEmpty()){
        	Database.SaveResult[] results = Database.update(resetAccountList, false);    
        }
    }
    
    public static Decimal calculateTotalACV(List<Opportunity> oppList,Date todayDate) {
        Decimal totalACV = 0;
        for (Opportunity opp : oppList) {
            if (opp.Rebate_Type__c != 'Buyout' && !opp.SBQQ__Renewal__c && opp.SBQQ__AmendedContract__c == null && 
                ((opp.StageName == 'Closed Won' && (opp.Type == 'Revenue Opportunity' || opp.Type == 'Warranty Exchange' || opp.Type == 'Parent Opportunity')) || 
                 (opp.StageName == 'Refunded - Closed' && opp.Returning_Opportunity__r.StageName == 'Closed Won' && opp.Returning_Opportunity_18_Digit_ID__c != null && 
                  (opp.Type == 'Exchange' || opp.Type == 'Work Order' || opp.Type == 'Free Trial Return' || opp.Type == 'Unplanned Return' || opp.Type == 'Warranty Exchange' || opp.Type == 'Parent Opportunity' || opp.Type == 'Remorse Refund' || (opp.Type == 'Rebate' && opp.Rebate_Type__c != 'Partner Referral'))))) {
                if ((opp.License_Start_Date__c <= todayDate && opp.License_End_Date__c >= todayDate && opp.StageName == 'Closed Won' && opp.Returning_Opportunity_18_Digit_ID__c == null ) || (opp.StageName == 'Refunded - Closed' && opp.Returning_Opportunity__r.License_Start_Date__c <= todayDate && opp.Returning_Opportunity__r.License_End_Date__c >= todayDate ) ){
                    totalACV += opp.ACV_Bookings_USD__c;
                }
            }
            else if(opp.Rebate_Type__c != 'Buyout' && (opp.SBQQ__Renewal__c && opp.StageName == 'Closed Won' && (opp.Type == 'Revenue Opportunity' || opp.Type == 'Warranty Exchange' || opp.Type == 'Parent Opportunity')) || 
                    (opp.ACV_Bookings_USD__c != null && opp.SBQQ__AmendedContract__c != null && 
                     ((opp.StageName == 'Closed Won' && (opp.Type == 'Revenue Opportunity' || opp.Type == 'Warranty Exchange' || opp.Type == 'Parent Opportunity')) ||
                      (opp.StageName == 'Refunded - Closed' && opp.Returning_Opportunity_18_Digit_ID__c != null && opp.Returning_Opportunity__r.StageName == 'Closed Won' && (opp.Type == 'Remorse Refund' || (opp.Type == 'Exchange' || opp.Type == 'Work Order' || opp.Type == 'Free Trial Return' || opp.Type == 'Unplanned Return' || opp.Type == 'Warranty Exchange' || opp.Type == 'Parent Opportunity' || (opp.Type == 'Rebate' && opp.Rebate_Type__c != 'Partner Referral')) ))))){
                if((opp.License_Start_Date__c <= todayDate && opp.License_End_Date__c >= todayDate && opp.StageName == 'Closed Won') || (opp.StageName == 'Refunded - Closed' && opp.Returning_Opportunity__r.License_Start_Date__c <= todayDate && opp.Returning_Opportunity__r.License_End_Date__c >= todayDate )){
                    totalACV += opp.ACV_Bookings_USD__c;
                }              
            }
            
        }
        return totalACV;
    }
    
    
}