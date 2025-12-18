/**********************************************************************
Name: OpportunityHelperCalculateRollUps

Purpose: This class will contains method that is related to rollup calculations                                                    

History  

VERSION     AUTHOR               DATE               DETAIL                       
1.0        Rodrigo Carpio        2025-Apr-11        INITIAL DEVELOPMENT 

***********************************************************************/
public class OpportunityHelperCalculateRollUps implements Callable  {
    static Map<String, Rollup_Switch__mdt> mapOFRollupFieldVsMetadata = new Map<String, Rollup_Switch__mdt> ();
    private static Set<String> targetRollupAccountSet = new Set<String> ();
    private static Boolean futureCustomRollupRan = false;
    private static Boolean isFutureCustomRollup = false;
    private static List<Opportunity> targetOpportunities = new List<Opportunity>();
    public static List<Schema.SObjectType> MY_SOBJECTS = new List<Schema.SObjectType>{
        Account.SobjectType,
            Opportunity.SObjectType
            };
                private static Callable callInstance;
    private static Id opportunityRevRecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('Standard_Opportunity').getRecordTypeId();
    
    static {
        OpportunityHelperCalculateRollUps opp = new OpportunityHelperCalculateRollUps();
        callInstance = (Callable) opp;
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
        GS_AccountTriggerHandler.alreadyRan = true;
        isFutureCustomRollup = true;
        mapOFRollupFieldVsMetadata = RollUpSwitchService.getRollupSwitchMetadata('Account', 'Opportunity');
        if (mapOFRollupFieldVsMetadata.isEmpty()) return;
        loadOppTargetRollupAccountSet(oppList, OldOpportunitiesMap);
        loadTargetOpportunities();
        calculateAllRollUpsToAccount();
    }
    
    private static Boolean accountReparenting(Opportunity thisOpp, Opportunity oldOpp) {
        return (thisOpp.AccountId != oldOpp.AccountId);
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
                    if(!Test.isRunningTest()){
                        OpportunityTriggerHandlerContext.logExecution.add('calculateAllRollUpsToAccount'); 
                        DMLWrapper.doUpdate(thisAccount, new List<SobjectField>{theDirtyField}); }
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
                if(!Test.isRunningTest()){
                    OpportunityTriggerHandlerContext.logExecution.add('calculateAllRollUpsToAccount');
                    DMLWrapper.doUpdate(thisAccount, new List<SobjectField>{theDirtyField});
                }
            }
        }
        if(isFutureCustomRollup) DMLWrapper.publishDML();
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
    
    private Decimal Sum(List<Sobject>recordList, String field) {
        return RollupService.Sum(recordList, field);
    }
    
    private Decimal Max(List<Sobject>recordList, String field) {
        return RollupService.max(recordList, field);
    }
    
    private Sobject first(List<Sobject>recordList, String field) {
        return RollupService.first(recordList, field);
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
    
    private Boolean Open_OpportunityPreCheck(Opportunity thisOpp, Opportunity OldOpp) {
        return (
            (thisOpp.IsClosed != OldOpp.IsClosed
             || thisOpp.Type != OldOpp.Type)
            && (Open_OpportunityCondition(thisOpp) || Open_OpportunityCondition(OldOpp))
        );
    }
    
    private Boolean rollup_ProbabilityPreCheck(Opportunity thisOpp, Opportunity OldOpp) {
        return (
            ((thisOpp.Probability != OldOpp.Probability)
             || thisOpp.IsClosed != OldOpp.IsClosed
             || thisOpp.Type != OldOpp.Type)
            && (rollup_ProbabilityCondition(thisOpp) || rollup_ProbabilityCondition(OldOpp)));
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
    
    private boolean rollup_ACV_Bookings_SOTPreCheck(Opportunity thisOpp, Opportunity OldOpp) {
        return ((thisOpp.Type != OldOpp.Type
                 || thisOpp.StageName != OldOpp.StageName
                 || thisOpp.ACV_Bookings_SOT__c != oldOpp.ACV_Bookings_SOT__c)
                && (rollup_ACV_Bookings_SOTCondition(thisOpp) || rollup_ACV_Bookings_SOTCondition(OldOpp)));
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
    
    private boolean Open_OpportunityCondition(Opportunity thisOpp) {
        return (thisOpp.Type == 'Revenue Opportunity' && thisOpp.IsClosed == false);
    }
    
    //GTMS-4452 - Anil Bogadi
    private boolean rollup_ProbabilityCondition(Opportunity thisOpp) {
        // return (thisOpp.IsClosed == False && thisOpp.Type == 'Revenue Opportunity');
        return (thisOpp.IsClosed == False && thisOpp.Type == 'Revenue Opportunity' && !thisOpp.Name.contains('Renewal') && thisOpp.Owner.Name != 'Samsara Small Fleets');
    }
    
    private boolean rollup_ExpectedRevenueCondition(Opportunity thisOpp) {
        return (thisOpp.IsClosed == False && thisOpp.Type == 'Revenue Opportunity');
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
}