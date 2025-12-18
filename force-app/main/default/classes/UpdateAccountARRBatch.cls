/**********************************************************************
Name: UpdateAccountARRBatch
Test Class: UpdateAccountARRBatchTest
-----------------------------------------------------------------------
Purpose: This class used to update account Active Acv field value based on certain conditions which is scheduled to run at 12:00AM daily                                                       
-----------------------------------------------------------------------
History  
GTMS-12830	MANJUSHA JAMMULA	07/23/24	Intial Development 
***********************************************************************/ 

global class UpdateAccountARRBatch implements Database.Batchable<sObject>, Database.stateful, Schedulable{
    
    private Date yesterdayDate;    
    private Boolean updateAccount = false;
    private Set<Id> accountIds = new Set<Id>();  
    private Id accountRecordId;  
    Map<Id,Decimal> accountCustomerARRMap = new Map<Id,Decimal>();
    private Date startDate;
    private Date endDate;
    private static final String OPPORTUNITY_QUERY = 
        'SELECT AccountId ' +
        'FROM Opportunity ' +
        'WHERE AccountId != null ' +
        'AND ACV_Bookings_USD__c != null AND ACV_Bookings_USD__c != 0 ' +
        'AND Rebate_Type__c != \'Buyout\' ' +
        'AND (' +
        '        (StageName = \'Closed Won\' ' +
        '        AND (License_Start_Date__c = :yesterdayDate OR License_End_Date__c = :yesterdayDate )) ' +
        '        OR (' +
        '            StageName = \'Refunded - Closed\' ' +
        '           AND Returning_Opportunity__r.StageName = \'Closed Won\' ' +                        
        '            AND (Returning_Opportunity__r.License_Start_Date__c = :yesterdayDate OR Returning_Opportunity__r.License_End_Date__c = :yesterdayDate)' +
        '    )' +
        'OR ' +
        '('+
        '        StageName = \'Refunded - Closed\' AND DAY_ONLY(LastStageChangeDate) = :yesterdayDate ' + 
        ')'+
        ')'+
        'ORDER BY AccountId';
    
    private static final String ACCOUNT_QUERY = 
        'SELECT AccountId ' +
        'FROM Opportunity ' +
        'WHERE AccountId != null ' +
        'AND ACV_Bookings_USD__c != null AND ACV_Bookings_USD__c != 0 ' +
        'AND Rebate_Type__c != \'Buyout\' ' +
        'AND (' +
        '        (StageName = \'Closed Won\' ' +
        '        AND ((License_Start_Date__c >= :startDate AND License_Start_Date__c <= :endDate ) OR ' +
        '             (License_End_Date__c >= :startDate AND License_End_Date__c <= :endDate ))' + 
        '        ) ' +
        '        OR (' +
        '            StageName = \'Refunded - Closed\' ' +
        '           AND Returning_Opportunity__r.StageName = \'Closed Won\' ' +                        
        '            AND ((Returning_Opportunity__r.License_Start_Date__c >= :startDate AND Returning_Opportunity__r.License_Start_Date__c <= :endDate) OR ' +
        '                 (Returning_Opportunity__r.License_End_Date__c >= :startDate AND Returning_Opportunity__r.License_End_Date__c <= :endDate))' +
        '    )' +
        ') '+
        'ORDER BY AccountId';
    
    
    
    public UpdateAccountARRBatch() {
        this.yesterdayDate = Date.today() - 1;
    }
    
    public UpdateAccountARRBatch(Date startDate, Date endDate) {
        this.startDate = startDate;
        this.endDate = endDate;
        this.updateAccount = true;
    }
    
    public UpdateAccountARRBatch(Id accountRecordId) {
        this.accountRecordId = accountRecordId;
        this.updateAccount = true;
       
    }
    
    
    global Database.QueryLocator start(Database.BatchableContext BC) {
        System.debug('updateAccount :: ' + updateAccount);
        if(updateAccount){
            if(accountRecordId != null){
                String ACCOUNT_SINGLE_QUERY = 'SELECT Id FROM Account WHERE Id = : accountRecordId';
                return  Database.getQueryLocator(ACCOUNT_SINGLE_QUERY);
            }else{
                return  Database.getQueryLocator(ACCOUNT_QUERY);
            }
            
            
        }else{
            return  Database.getQueryLocator(OPPORTUNITY_QUERY);
        }
        
    }
    
    global void execute(Database.BatchableContext BC, List<Sobject> scope) {
        System.debug('scope ::' + scope.size());
        if(updateAccount && accountRecordId != null){
            for(Account acc : (List<Account>)scope){
                accountIds.add(acc.Id);
            }
        }else{
            for(Opportunity opp : (List<Opportunity>)scope){
                accountIds.add(opp.AccountId);
            }
        }
    }
    
    global void finish(Database.BatchableContext BC) {
        System.debug('accountIds ' + accountIds.size());
        if(updateAccount){
            Database.executeBatch(new AccountARRCalculationBatch(accountIds),Integer.valueOf(Label.ARRAccountBatchSize));
        }else{
            Database.executeBatch(new AccountARRCalculationBatch(accountIds),Integer.valueOf(Label.ARRBatchSize));
        }
    }
    
    public void execute(System.schedulableContext sc){
        Database.executeBatch(new UpdateAccountARRBatch(), Integer.valueOf(Label.ARRBatchSize));
    }
    
    
    
}