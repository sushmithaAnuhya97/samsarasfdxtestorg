/**
* Created By : Groundswell - Tanuj Tyagi
* @Date August 05, 2021
*
* @description : This class will be responsible for handling all the prepopulation of Account Records on Before Insert/Update Operations
* SFA-11
* April-28-2022 Rajesh GTMS-6852: Populate Deactivated field value based on Netsuite Delinqunecy
* May-24-2022 Siddharth Kumar Mishra GTMS-6447: Mark Mexican accounts as Non Compliant Tax Payer if the Tax ID matchers with RFC# of MX Non Compliant Tax Payer Object
* Aug-18-2022 Alekhya Mathukumilli GTMS 7836: added method recalculateMaxCreditValue
* Nov-2-2022  Chinmaya Kumar Dash: GTMS-9675 Adjusted the ARR Logic for 'Starter'
* Mar-2-2023 Alekhya Mathukumilli GTMS-11024: Marketing Ops Health: New Accounts - Create 4 New Tasks
* Sep-25-2023 Rodrigo Carpio: added changes for GTMS-15367
**/
public inherited sharing class GS_AccountPrePopulationService {
    gslib_IModuleLogger thisModuleLogger = gslib_LoggerService.getModuleLogger('GTMS');
    gslib_ILogger thisLogger = thisModuleLogger.getLogger();
    static Map<Id, Account_Sync_Event__e> accountSyncEvents = new Map<Id, Account_Sync_Event__e>();
    static Map<Id, Account_Sync_Webstore_Event__e > accountSyncWebstoreEvents = new Map<Id, Account_Sync_Webstore_Event__e >();
    static Toggle_Platform_Event__mdt accountEventToggle = Toggle_Platform_Event__mdt.getInstance('Account_Sync_Webstore_Event');
    //Map<String, CS_Tier_Limit__mdt> csTierMap = CS_Tier_Limit__mdt.getAll(); //Commented as part of GTMS-18361
    Map<String, NAICS_Code__mdt> nCodes = NAICS_Code__mdt.getAll();
    Map<ID, Schema.RecordTypeInfo> rt_Map = Account.sObjectType.getDescribe().getRecordTypeInfosById();
    public Map<Id, User> mapUsers = new Map<Id, User>();
    public static Map<Id, Id> mapOppOldOwner = new Map<Id, Id>(); //added for GTMS-7561
    static Sync_Object_Field_WebStore__mdt [] accountSyncWSFields = [Select Id,Object_Api_Name__c,Field_Api_Name__c,Null_Check_Needed__c from Sync_Object_Field_WebStore__mdt Where Object_Api_Name__c = 'Account'];
    static List<CS_Tier_Limit__mdt> listOfActiveTiers {get{
        if(listOfActiveTiers != null){
            if(!listOfActiveTiers.isEmpty())
                return listOfActiveTiers;
        }
        listOfActiveTiers = [SELECT id,Active__c, Field_API_Name__c,
                             Max_Value__c, Min_Value__c, Owner_Role__c,
                             Tier_Name__c,Segment__c
                             FROM CS_Tier_Limit__mdt
                             WHERE Active__c = TRUE
                             ORDER BY Segment__c, Owner_Role__c ASC];
        return listOfActiveTiers;
    }set;}
    public static  List<Sync_Object_Field__mdt> AccountSyncFields{
        get{
            if(AccountSyncFields == null){
                AccountSyncFields = new List<Sync_Object_Field__mdt>();
                List<Sync_Object_Field__mdt> objList  = Sync_Object_Field__mdt.getAll()?.Values();
                if(objList != null && objList.Size() >0){
                    for(Sync_Object_Field__mdt obj: objList){
                        if(obj.Object_Api_Name__c == 'Account'){
                            AccountSyncFields.add(obj) ;
                        }
                    }
                }
            }
            return AccountSyncFields;
        }
        set{AccountSyncFields = value;}
    }
    /**
* Created By : Rodrigo Carpio
* @Date March 20, 2023
* Created for Round Robin
* @description : This class will be responsible for calling the Round Robin logic
* Mar-20-2023 Rodrigo Carpio - added logic for epic GTMS-11243
**/
    public static void performUserAssignment(List<Account> newAccountList) {
        Map<Id, Account> newAccountMapFuture = new Map<Id, Account>();
        Map<Id, Account> newAccountMapFutureSled = new Map<Id, Account>();
        For(Account accntRec : newAccountList) {
            if (accntRec.Initiate_Round_Robin__c == true) {
                if(accntRec.SLED_Account__c ==True){
                    newAccountMapFutureSled.put(accntRec.Id, accntRec);
                }
                else{
                    newAccountMapFuture.put(accntRec.Id, accntRec);
                }
            }
        }
        if (newAccountMapFuture != null && newAccountMapFuture.size()>0)
        {
            String newAccountMapSerialized = JSON.serialize(newAccountMapFuture);
            performUserAssignmentFuture(newAccountMapSerialized,false);
        }
        if (newAccountMapFuturesled != null && newAccountMapFuturesled.size()>0)
        {
            String newAccountMapSerialized = JSON.serialize(newAccountMapFuturesled);
            performUserAssignmentFuture(newAccountMapSerialized,true);
        }
    }
    /**
* Created By : Rodrigo Carpio
* @Date March 20, 2023
* Created for Round Robin
* @description : This class will be responsible for calling the Round Robin logic
* Mar-20-2023 Rodrigo Carpio - added logic for epic GTMS-11243
**/
    //@future
    public static void performUserAssignmentFuture(String newAccountMapSerialized,Boolean isSled) {
        Map<Id, Account> newAccountMap = (Map<Id, Account>) JSON.deserialize(newAccountMapSerialized, Map<Id, Account>.class);
        // RoundRobinHandler rr = new RoundRobinHandler('Lane Four', 'Account');
        RoundRobinHandler rr = new RoundRobinHandler(isSled,'Account','Lane Four');
        List<Account> forUpdateAccount = new List<Account>();
        For(Account accntRec : newAccountMap.values()) {
            RoundRobinHandler.RoundRobinInfo rrInfo = new RoundRobinHandler.RoundRobinInfo();
            rrInfo = rr.getAssignedUser(accntRec);
            system.debug('RODRIGO rrInfo ' + rrInfo);
            Account accInfo = new Account();
            if (rrInfo.fieldToUpdate != null && rrInfo.userId != null) {
                accInfo.put(rrInfo.fieldToUpdate, rrInfo.userId);
                //accInfo.RR_Assigned_On__c = System.now();
                accInfo.Account_Assignment_Date__c = System.now();
                accInfo.RR_Assignment_Rule__c = rrInfo.ruleId;
                accInfo.RR_Assignment_Mapping__c = rrInfo.mappingId;
            }
            accInfo.Id = accntRec.Id;
            accInfo.Initiate_Round_Robin__c = false;
            forUpdateAccount.add(accInfo);
        }
        if (forUpdateAccount != null && forUpdateAccount.size()>0) {
            //TriggerHandler.bypass('GS_AccountTriggerHandler');
            DMLWrapper.doUpdate(forUpdateAccount);
            rr.updateRuleDetail();
        }
    }
    /**
* Created By : Rodrigo Carpio
* @Date November 03, 2022
* Created for Account Status Accuracy Program
* @description : This class will be responsible for handling the setting of account status base on certain criteria
* Nov-3-2022 Rodrigo Carpio - added logic for GTMS-10132/GTMS-10133/GTMS-10134/GTMS-10135
**/
    public void updateAccountStatus(Map<Id, Account> oldAccountMap, List<Account> newAccountList) {
        system.debug('RODRIGO updateAccountStatus ');
        // select account ids that was updated
        Set<Id> listOfAccountIds = new Set<Id>();
        for(Account thisAccount : newAccountList) {
            Account oldAccount = new Account();
            if(oldAccountMap != NULL && oldAccountMap.size() >  0) {
                oldAccount = oldAccountMap.get(thisAccount.Id);
                if (oldAccount != null)
                    listOfAccountIds.add(thisAccount.Id);
            }
        }
        // check if there is any account that has been updated
        if (listOfAccountIds.size()>0) {
            // maps of account opportunity stage name for GTMS-10132/GTMS-10133/GTMS-10134/GTMS-10135
            Map<String, boolean> acctOptyClosedLost = new Map<String, boolean>();
            Map<String, boolean> acctOptyClosedWon = new Map<String, boolean>();
            Map<String, boolean> acctOptyRefundedClosed = new Map<String, boolean>();
            Map<String, boolean> acctOptyRFRefundedClosed = new Map<String, boolean>();
            Map<String, boolean> acctOptyOpen = new Map<String, boolean>();
            Map<String, boolean> acctOptySubtype = new Map<String, boolean>();
            Map<String, boolean> acctOptyEndDate = new Map<String, boolean>();
            Map<String, boolean> acctOptyNoOpen = new Map<String, boolean>();
            Map<String, integer> accountOptyCount = new Map<String, integer>();
            Map<String, integer> accountOptyClosedLostCount = new Map<String, integer>();
            // account related opportunities for GTMS-10132/GTMS-10133/GTMS-10134/GTMS-10135
            List<Opportunity> listOfOpty = [SELECT StageName, CloseDate, Sub_Type__c, License_End_Date__c, AccountId, Type, SBQQ__Renewal__c
                                            FROM Opportunity
                                            WHERE AccountId IN:listOfAccountIds
                                            //AND StageName IN ('Closed Lost', 'Closed Won', 'Refunded - Closed')
                                            Order by AccountId
                                            LIMIT 5000];
            // capture all opportunity count for GTMS-10132
            Integer optyCounter = 0;
            String currAccountId = null;
            Integer totalOptyCount = listOfOpty.size();
            List<Opportunity> optyListForMap = new List<Opportunity>();
            Map<Id, List<Opportunity>> optyRecMapAccount = new Map<Id, List<Opportunity>>();
            for (Opportunity optyRec : listOfOpty) {
                if (currAccountId == null) {
                    currAccountId = optyRec.AccountId;
                    optyCounter++;
                    optyListForMap.add(optyRec);
                }
                else {
                    if (currAccountId == optyRec.AccountId) {
                        optyCounter++;
                        optyListForMap.add(optyRec);
                        //if (totalOptyCount == optyCounter)
                        //    accountOptyCount.put(currAccountId, optyCounter);
                    }
                    else{
                        accountOptyCount.put(currAccountId, optyCounter);
                        optyRecMapAccount.put(currAccountId, optyListForMap );
                        optyCounter = 1;
                        currAccountId = optyRec.AccountId;
                        optyListForMap = new List<Opportunity>();
                        optyListForMap.add(optyRec);
                    }
                }
            }
            accountOptyCount.put(currAccountId, optyCounter);
            optyRecMapAccount.put(currAccountId, optyListForMap );
            Integer opportunityCounter = 0;
            // loop thru all ids for GTMS-10132/GTMS-10133/GTMS-10134/GTMS-10135
            for (Id currId : listOfAccountIds) {
                Integer sameAccountClosedLost = 0;
                Integer sameAccountClosedWon = 0;
                Integer sameAccountRefundedClosed = 0;
                Integer sameAccountRFRefundedClosed = 0;
                Integer sameAccountOpen =0;
                Integer sameAccountSubtype =0;
                Integer sameAccountEndDate =0;
                Integer sameAccountNoOpen =0;
                // loop thru opportunity list for GTMS-10132/GTMS-10133/GTMS-10134/GTMS-10135
                List<Opportunity> listOfOptyLocal = optyRecMapAccount.get(currId);
                if (listOfOptyLocal != null && listOfOptyLocal.size()>0) {
                    for(Opportunity currOpty : listOfOptyLocal) {
                        //for(Opportunity currOpty : listOfOpty) {
                        if (currId == currOpty.AccountId) {
                            opportunityCounter++;
                            // Closed Lost - GTMS-10132
                            if (currOpty.StageName == 'Closed Lost') {
                                sameAccountClosedLost++;
                                if (sameAccountClosedLost>0) {
                                    acctOptyClosedLost.put(currId, true);
                                }
                            }
                            // Closed Won - GTMS-10133
                            if (currOpty.StageName == 'Closed Won' && currOpty.Type == 'Revenue Opportunity' ) {
                                sameAccountClosedWon++;
                                if (sameAccountClosedWon>0) {
                                    acctOptyClosedWon.put(currId, true);
                                }
                            }
                            // Refunded - Closed - GTMS-10134
                            if (currOpty.StageName == 'Refunded - Closed' && currOpty.Type == 'Rebate' ) {
                                sameAccountRefundedClosed++;
                                if (sameAccountRefundedClosed>0) {
                                    acctOptyRefundedClosed.put(currId, true);
                                }
                            }
                            // Remorse Refund - GTMS-10135
                            if (currOpty.StageName == 'Refunded - Closed' && currOpty.Type == 'Remorse Refund' ) {
                                sameAccountRFRefundedClosed++;
                                if (sameAccountRFRefundedClosed>0) {
                                    acctOptyRFRefundedClosed.put(currId, true);
                                }
                            }
                            // GTMS-10136
                            if ((currOpty.StageName != 'Closed Won' && currOpty.StageName != 'Closed Lost' && currOpty.SBQQ__Renewal__c == false &&
                                 currOpty.Type == 'Revenue Opportunity' && currOpty.CloseDate > system.today()) ||
                                (currOpty.StageName != 'Closed Won' && currOpty.StageName != 'Closed Lost' && currOpty.SBQQ__Renewal__c == true &&
                                 currOpty.Type == 'Revenue Opportunity' && currOpty.CloseDate < system.today()+90) )
                            {
                                sameAccountOpen++;
                                if (sameAccountOpen>=1) {
                                    acctOptyOpen.put(currId, true);
                                }
                            }
                            // GTMS-10137
                            if (currOpty.StageName == 'Closed Won' && currOpty.Sub_Type__c == 'Paid Pilot' ) {
                                sameAccountSubtype++;
                                if (sameAccountSubtype>0) {
                                    acctOptySubtype.put(currId, true);
                                }
                            }
                            // GTMS-10138
                            if (currOpty.StageName == 'Closed Won' && currOpty.Sub_Type__c == 'Paid Pilot'
                                && currOpty.License_End_Date__c < system.today()
                                && currOpty.Type == 'Revenue Opportunity' && currOpty.SBQQ__Renewal__c == false ) {
                                    sameAccountEndDate++;
                                    if (sameAccountEndDate>0) {
                                        acctOptyEndDate.put(currId, true);
                                    }
                                }
                            // GTMS-10139
                            if ((currOpty.StageName != 'Closed Won' && currOpty.StageName != 'Closed Lost')
                                &&  (currOpty.Type == 'Revenue Opportunity' || currOpty.SBQQ__Renewal__c == true )
                                && currOpty.CloseDate > system.today()) {
                                    sameAccountNoOpen++;
                                    if (sameAccountNoOpen>0) {
                                        acctOptyNoOpen.put(currId, true);
                                        system.debug('RODRIGO acctOptyNoOpen ' + acctOptyNoOpen.get(currId));
                                    }
                                }
                            if (opportunityCounter == totalOptyCount)
                                accountOptyClosedLostCount.put(currId, sameAccountClosedLost);
                        }
                        else {
                            accountOptyClosedLostCount.put(currId, sameAccountClosedLost);
                            break;
                        }
                    }
                }
            }
            // loop thru the updated accounts for GTMS-10132/GTMS-10133/GTMS-10134/GTMS-10135
            for(Account thisAccount : newAccountList) {
                Account oldAccount = new Account();
                oldAccount = oldAccountMap.get(thisAccount.Id);
                // Total License = Total Purchased AG Count + Total Purchased VG Count + Total Purchased CM Count + Total Purchased EM Count.
                Decimal totalLicenes = thisAccount.Total_Purchased_AG_Count__c + thisAccount.Total_Purchased_VG_Count__c  + thisAccount.Total_Purchased_CM_Count__c + thisAccount.Total_Purchased_EM_Count__c;
                // added for GTMS-10132
                if ( (thisAccount.Customer_ARR__c==0 || thisAccount.Customer_ARR__c==NULL ) &&
                    (accountOptyCount.get(thisAccount.Id) == accountOptyClosedLostCount.get(thisAccount.Id)) &&
                    (thisAccount.Account_Lifetime_ACV__c ==0 || thisAccount.Account_Lifetime_ACV__c ==NULL ) && acctOptyClosedLost.get(thisAccount.Id)==true) {
                        thisAccount.Status__c = 'Closed Lost Opportunity';
                    }
                // added for GTMS-10133
                if ( (thisAccount.Customer_ARR__c > 0) && (thisAccount.Account_Lifetime_ACV__c > 0) && acctOptyClosedWon.get(thisAccount.Id)==true) {
                    thisAccount.Status__c = 'Existing Customer';
                }
                // added for GTMS-10136
                if ( (thisAccount.Status__c == 'Existing Customer' ) && (thisAccount.Customer_ARR__c > 0 || thisAccount.Customer_ARR__c == NULL)
                    && (thisAccount.Account_Lifetime_ACV__c > 0 || thisAccount.Account_Lifetime_ACV__c == NULL)
                    && acctOptyOpen.get(thisAccount.Id)==true) {
                        thisAccount.Status__c = 'Existing Customer - Open Opportunity';
                    }
                // added for GTMS-10137
                if ( acctOptySubtype.get(thisAccount.Id)==true) {
                    thisAccount.Status__c = 'Paid Pilot';
                }
                // added for GTMS-10138
                if ( (thisAccount.Status__c == 'Paid Pilot' || oldAccount.Status__c == 'Paid Pilot')
                    && acctOptyEndDate.get(thisAccount.Id)==true && acctOptyOpen.get(thisAccount.Id)!=true) {
                        thisAccount.Status__c = 'Paid Pilot - Closed Lost';
                    }
                // added for GTMS-10135
                if ( (thisAccount.Status__c == 'Existing Customer' || oldAccount.Status__c == 'Existing Customer')
                    && acctOptyRFRefundedClosed.get(thisAccount.Id)==true && totalLicenes==0) {
                        thisAccount.Status__c = 'Previous Customer - Returned';
                    }
                // added for GTMS-10134
                if ( (thisAccount.Netsuite_Delinquent_Status__c == 'Written-Off' || thisAccount.Netsuite_Delinquent_Status__c == 'Written-off')
                    && (thisAccount.Status__c == 'Existing Customer' || oldAccount.Status__c == 'Existing Customer') ){
                        thisAccount.Status__c = 'Previous Customer - Written Off';
                    }
                // added for GTMS-10139
                if ( (thisAccount.Status__c == 'Existing Customer' || oldAccount.Status__c == 'Existing Customer')
                    && thisAccount.Latest_Active_Contract_End_Date__c < system.today() && acctOptyNoOpen.get(thisAccount.Id)!=true) {
                        thisAccount.Status__c = 'Previous Customer - Did Not Renew';
                    }
                system.debug('RODRIGO updateAccountStatus thisAccount.Status__c ' + thisAccount.Status__c);
            }
        }
    }
    /**
* Created By : Rodrigo Carpio
* @Date January 12, 2023
* Created for GTMS-10383
* @description : this method will be responsible to perform check on CSM related fields then update LFBN__Assign_Account__c to true
* Jan-12-2023 Rodrigo Carpio - added logic for GTMS-10383
**/
    public void performCheckOnCSMRelatedFields (Map<Id, Account> oldAccountMap, List<Account> newAccountList)
    {
        Set<Id> listOfIdToUpdated = new Set<Id>();
        for(Account thisAccount : newAccountList) {
            Account oldAccount = new Account();
            if(oldAccountMap != NULL && oldAccountMap.size() >  0) {
                oldAccount = oldAccountMap.get(thisAccount.Id);
            }
            if ( thisAccount.SIC__c == NULL &&
                ( (( (oldAccount.CS_Tier__c != thisAccount.CS_Tier__c && String.isBlank(oldAccount.CS_Tier__c) && String.isNotBlank(thisAccount.CS_Tier__c) && thisAccount.Onboarding_Complete__c==true) ||
                    (oldAccount.Onboarding_Complete__c != thisAccount.Onboarding_Complete__c && thisAccount.Onboarding_Complete__c==true && String.isNotBlank(thisAccount.CS_Tier__c))
                   ))
                 /*|| (thisAccount.CSM_Status__c == null && thisAccount.First_Purchase_Date__c>=System.Today() && thisAccount.First_Purchase_Date__c<=System.Today()+10
&& ((thisAccount.First_Purchase_Date__c != null && thisAccount.First_Purchase_Date__c <> oldAccount.First_Purchase_Date__c) ||
(thisAccount.CSM_Status__c <> oldAccount.CSM_Status__c)
)
) // condition added for GTMS-15367 */
                )
               )// added for GTMS-10383
                listOfIdToUpdated.add(thisAccount.Id);
        }
        if (listOfIdToUpdated != null && listOfIdToUpdated.size()>0) {
            //String listOfIdToUpdated = JSON.serialize(newContactMap);
            system.debug('RODRIGO listOfIdToUpdated before Future' + listOfIdToUpdated);
            assignedCSMFieldValue(listOfIdToUpdated);
        }
    }
    /**
* Created By : Rodrigo Carpio
* @Date March 23, 2023
* Created for GTMS-11420
* @description : this method returns the last date of the current fiscal quarter
* Mar-23-2023 Rodrigo - initial code
**/
    public Date getFiscalQuarterEndDate() {
        Integer FiscalYearStartMonth = [select FiscalYearStartMonth from Organization where id=:Userinfo.getOrganizationId()].FiscalYearStartMonth;
        Date fiscalYearStartDate;
        Integer quarter;
        if(system.today().month() >= FiscalYearStartMonth)
        {
            fiscalYearStartDate = date.newinstance(system.today().year(), FiscalYearStartMonth, 1);
            quarter = ((system.today().month() - FiscalYearStartMonth) / 3) + 1;
        }
        else
        {
            fiscalYearStartDate = date.newinstance(system.today().year() - 1, FiscalYearStartMonth, 1);
            quarter = ((12 + system.today().month() - FiscalYearStartMonth) / 3) + 1;
        }
        Integer addMonths = quarter * 3;
        Date lastDateOfThisQuarter = fiscalYearStartDate;
        // this is the last date of the current quarter
        lastDateOfThisQuarter = lastDateOfThisQuarter.addMonths(addMonths).addDays(-1);
        return lastDateOfThisQuarter;
    }
    /**
* Created By : Alekhya Mathukumilli
* @Date March 2, 2023
* Created for GTMS-11024
* @description : this method will be responsible to check Account related fields and create New Tasks.
* Feb-02-2023 Alekhya Mathukumilli - added logic for GTMS-11420
* Mar-23-2023 Rodrigo - made adjustment on the logic
**/
    public void taskCreation(List<Account> newAccountList)
    {
        //GTMS-26025 - Updated the logic to avoid SOQL/DML in loop
        Set<String> groupNameSet = new Set<String>{'DataBees_Research_Queue_US_Public_Sector','DataBees_Research_Queue_US','DataBees_Research_Queue_CAN'};
        List<Group> groupList = [SELECT id, DeveloperName FROM group WHERE Type = 'Queue' AND DeveloperName IN: groupNameSet];
        Map<String, Id> groupMap = new Map<String, Id>();
        List<Task> newTasks = new List<Task>();
        for(Group grp : groupList) {
            groupMap.put(grp.DeveloperName, grp.Id);
        }
        for(Account thisAccount : newAccountList) {

            Date lastDateOfQuarter = getFiscalQuarterEndDate();
            Id taskRecordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByName().get('Task').getRecordTypeId();
            Id ownerIdToAssign = null;
            List<String> subjects = new List<String>();
            List<String> types = new List<String>();
            Integer tasksToCreate = 0;
            if (thisAccount.Account_Size_Segment__c=='AE2/AE3' && thisAccount.SLED_Account__c== true && thisAccount.BillingCountry == 'United States') {
                   tasksToCreate = 6;
                   subjects = new List<String> {'Online Presence Verified', 'Address Verified/Updated', 'Phone Verified/Updated','Duplicate Check Completed','Parent Check Completed','Organization Size Verified/Updated'};
                       types = new List<String> {'Account - Online Presence', 'Account - Address', 'Account - Phone','Duplicate Check','Parent Check','Account - Organization Size'};
                ownerIdToAssign = groupMap.get('DataBees_Research_Queue_US_Public_Sector');
               }
            if( (thisAccount.Account_Size_Segment__c=='AE2/AE3' && thisAccount.SLED_Account__c== false) &&
               ((thisAccount.BillingCountry == 'United States' && thisAccount.Inside_Sales_Assignment__c == null)
                || (thisAccount.BillingCountry == 'Canada'))){
                    tasksToCreate = 6;
                    subjects = new List<String> {'Online Presence Verified','Address Verified/Updated','Phone Verified/Updated','Duplicate Check Completed','Parent Check Completed','Organization Size Verified/Updated'};
                        types = new List<String> {'Account - Online Presence','Account - Address','Account - Phone','Duplicate Check','Parent Check','Account - Organization Size'};
                if (thisAccount.BillingCountry == 'United States') {
                    ownerIdToAssign = groupMap.get('DataBees_Research_Queue_US');
                }
                else {
                    ownerIdToAssign = groupMap.get('DataBees_Research_Queue_CAN');
                }
            }
            if (ownerIdToAssign == null){
                continue;
                }
            for(Integer i = 0 ; i < tasksToCreate ; i++) {
                Task newtask = new Task();
                newtask.Subject = subjects[i];
                newtask.WhatId = thisAccount.Id;
                newtask.Type = types[i];
                newtask.Status = 'Open';
                newtask.Priority= 'Normal';
                newtask.OwnerId = ownerIdToAssign;
                newtask.RecordTypeId = taskRecordTypeId;
                newtask.ActivityDate = lastDateOfQuarter;
                newTasks.add(newtask);
            }
        }
        if (!newTasks.isEmpty()) {
            insert newTasks;
        }
    }
    /**
* Created By : Nishita Dhar
* @Date June 26, 2023
* Created for GTMS-13131
* @description : this method will be responsible to create tasks when Number_of_Vehicles__c,Number_of_unpowered_assets__c,Number_of_powered_assets__c
is updated by the Profiles added in the Profiles_Allowed_to_Create_Task label .
**/
    public void addtaskupdate(List<Account> newAccountList, Map<Id, Account> oldAccountMap) {
        // this will get the profileids from Profiles_Allowed_to_Create_Task
        List<String> allowedProfileIdsStr = Label.Profiles_Allowed_to_Create_Task.split(',');
        List<Task> CreateTask = new List<Task>();
        for (Account acc : newAccountList) {
            Account oldAcc = oldAccountMap.get(acc.Id);
            if (allowedProfileIdsStr.contains(UserInfo.getProfileId()) || Test.isRunningTest()) {
                if (oldAcc.Number_of_Vehicles__c != acc.Number_of_Vehicles__c) {
                    Task newTaskV = new Task();
                    newTaskV.Subject = 'Number of Vehicles Validated';
                    newTaskV.WhatId = acc.Id;
                    newTaskV.Task_Sub_Type__c = 'Internal';
                    newTaskV.Type = 'Vehicle Validation';
                    newTaskV.Priority = 'Normal';
                    newTaskV.Status = 'Completed';
                    newTaskV.OwnerId = UserInfo.getUserId();
                    newTaskV.ActivityDate = System.today();
                    newTaskV.RecordTypeId = '0121a000000RPWsAAO';
                    CreateTask.add(newTaskV);
                }
                if (oldAcc.Number_of_unpowered_assets__c != acc.Number_of_unpowered_assets__c) {
                    Task newTaskUA = new Task();
                    newTaskUA.Subject = 'Number of Unpowered Assets Validated';
                    newTaskUA.WhatId = acc.Id;
                    newTaskUA.Task_Sub_Type__c = 'Internal';
                    newTaskUA.Type = 'Unpowered Asset Validation';
                    newTaskUA.Priority = 'Normal';
                    newTaskUA.Status = 'Completed';
                    newTaskUA.OwnerId = UserInfo.getUserId();
                    newTaskUA.ActivityDate = System.today();
                    newTaskUA.RecordTypeId = '0121a000000RPWsAAO';
                    CreateTask.add(newTaskUA);
                }
                if (oldAcc.Number_of_powered_assets__c != acc.Number_of_powered_assets__c) {
                    Task newTaskA = new Task();
                    newTaskA.Subject = 'Number of Powered Assets Validated';
                    newTaskA.WhatId = acc.Id;
                    newTaskA.Task_Sub_Type__c = 'Internal';
                    newTaskA.Type = 'Powered Asset Validation';
                    newTaskA.Priority = 'Normal';
                    newTaskA.Status = 'Completed';
                    newTaskA.OwnerId = UserInfo.getUserId();
                    newTaskA.ActivityDate = System.today();
                    newTaskA.RecordTypeId = '0121a000000RPWsAAO';
                    CreateTask.add(newTaskA);
                }
            }
        }
        if (!CreateTask.isEmpty()) {
            INSERT CreateTask;
        }
    }
    /**
* Created By : Rodrigo Carpio
* @Date January 12, 2023
* Created for GTMS-10383
* @description : this method will be responsible to perform check on CSM related fields then update LFBN__Assign_Account__c to true
* Jan-12-2023 Rodrigo Carpio - added logic for GTMS-10383
**/
    //@future
    public static void assignedCSMFieldValue(Set<Id> listOfIdToUpdated) {
        system.debug('RODRIGO listOfIdToUpdated Future ' + listOfIdToUpdated);
        List<Account> listAccountForUpdate = new List<Account>();
        /*List<Account> listAccount=[SELECT Id, Account_Lifetime_ACV__c, LFBN__Assign_Account__c
FROM Account WHERE Id IN:listOfIdToUpdated];
FOR(Account objAccount : listAccount) {
objAccount.LFBN__Assign_Account__c = true;
listAccountForUpdate.add(objAccount);
}
if(listAccountForUpdate != null && listAccountForUpdate.size()>0)
update listAccountForUpdate;
*/
        List<Account> listAccount=[SELECT Id, Is_Owner_Pool_User__c, Assign_CSM__c,is_deal_reg_account__c,Record_Type_Stamp_for_Dupes__c, Organization_Size__c,Global_Geography__c,
                                   Most_Recent_Source__c,Industry,Business_Unit__c, Partner_Program_Tier__c, Partner_Persona__c, BillingCountry, BillingState,BillingCountryCode,
                                   Which_written_language__c, CS_Tier__c, Experimental_Group__c, Experimental_Group_Routing__c, Account_Size_Segment__c, Inside_Sales_Assignment__c,
                                   Number_of_Vehicles__c, Number_of_Powered_Assets__c, Number_of_Unpowered_Assets__c, website, Domain_Name__c, CSM__c, SLED_Account__c, Name,
                                   Customer_ARR__c, Number_of_Students__c, Number_of_Citizens__c, Account_Lifetime_ACV__c, Hashtag__c, SIC__c,
                                   Onboarding_Complete__c, Partner_Type__c, Owner_Profile_Id__c, Timezone__c, Owner_Role__c //Added as part of GTMS-18362 - Timezone__c, Owner_Role__c
                                   FROM Account WHERE Id IN:listOfIdToUpdated];
        RoundRobinHandler rr = new RoundRobinHandler('Lane Four', 'Account', 'SIC__c'); // added new constructor parameter for GTMS-15367
        List<Account> forUpdateAccount = new List<Account>();
        For(Account accntRec : listAccount) {
            RoundRobinHandler.RoundRobinInfo rrInfo = new RoundRobinHandler.RoundRobinInfo();
            rrInfo = rr.getAssignedUser(accntRec);
            //system.debug('RODRIGO rrInfo ' + rrInfo);
            Account accInfo = new Account();
            if (rrInfo.fieldToUpdate != null && rrInfo.userId != null && rrInfo.fieldToUpdate=='SIC__c') // added fieldToUpdate value check for GTMS-15568
            {
                accInfo.put(rrInfo.fieldToUpdate, rrInfo.userId);
                //accInfo.RR_Assigned_On__c = System.now();
                accInfo.Account_Assignment_Date__c = System.now();
                accInfo.RR_Assignment_Rule__c = rrInfo.ruleId;
                accInfo.RR_Assignment_Mapping__c = rrInfo.mappingId;
            }
            accInfo.Id = accntRec.Id;
            accInfo.Initiate_Round_Robin__c = false;
            forUpdateAccount.add(accInfo);
        }
        if (forUpdateAccount != null && forUpdateAccount.size()>0) {
            TriggerHandler.bypass('GS_AccountTriggerHandler');
            update forUpdateAccount;
            rr.updateRuleDetail();
        }
    }
    public void commonContextPrePopulateHelper(Map<Id, Account> oldAccountMap, List<Account> newAccountList){
        Map<String,Shipping_Countries__mdt> countriesMap =  Shipping_Countries__mdt.getAll();
        Map<String, String> currencyMap = new Map<String, String>();
        Map<String, Boolean> approvedIFRMap = new Map<String, Boolean>();
        Map<String,Account> TaxIdAccountMap = new Map<String,Account>();//GTMS-6447
        //Build map with country code and currency
        for(Shipping_Countries__mdt country : countriesMap.values()){
            currencyMap.put(country.BillingCountryCode__c, country.Currency__c);
        }
        List<Internal_Finance_Approval_Request__c> financeRequests = [SELECT Id, Account__c FROM Internal_Finance_Approval_Request__c
                                                                      WHERE Account__c IN:newAccountList AND Payment_Type_Approval_Status__c = 'Approved' AND (Approved_Payment_Type__c != null
                                                                                                                                                               OR Request_Type__c = 'Direct Monthly Financing')];
        for(Internal_Finance_Approval_Request__c financeRequest : financeRequests) {
            approvedIFRMap.put(financeRequest.Account__c, true);
        }
        for(Account thisAccount : newAccountList) {
            Account oldAccount = new Account();
            if(oldAccountMap != NULL && oldAccountMap.size() >  0) {
                oldAccount = oldAccountMap.get(thisAccount.Id);
            }
            boolean check =  (thisAccount.global_geography__c != 'france' && thisAccount.global_geography__c <> 'mexico' && thisAccount.global_geography__c <> 'uk & i' && thisAccount.global_geography__c <> 'dach'
                              && thisAccount.global_geography__c <> 'canada east' && thisAccount.global_geography__c <> 'canada west' && thisAccount.is_owner_pool_user__c == false
                              && thisAccount.record_type_stamp_for_dupes__c == 'fleet' &&  thisAccount.organization_size__c <> '5000+' && thisAccount.organization_size__c <> '1000 - 4999' &&
                              (thisAccount.number_of_vehicles__c <= 30 || thisAccount.number_of_vehicles__c == null) && (thisAccount.number_of_unpowered_assets__c <= 150 || thisAccount.number_of_unpowered_assets__c ==null) &&
                              (thisAccount.number_of_powered_assets__c <= 50 || thisAccount.number_of_powered_assets__c == null)  && thisAccount.assign_csm__c == false);
            System.debug('Assign CSM:'+thisAccount.Assign_CSM__c +','+thisAccount.Global_Geography__c+','+thisAccount.Is_Owner_Pool_User__c+','+thisAccount.organization_size__c);
            system.debug('check:'+check);
            samNumberUndecorated(thisAccount);
            setNaicsCode(oldAccount, thisAccount);
            setRecordTypeStampForDupes(oldAccount, thisAccount);
            setMicroFleetSupportTier(oldAccount, thisAccount);
            setPOCFields(thisAccount);
            setPartnerDiscount(oldAccount, thisAccount);  //GTMS-6422: Set Partner Discount
            // added for GTMS-10315 to move logic from 'Account : Update Assign Account Field' flow
            /*if (thisAccount.Owner_Role__c != null &&
(thisAccount.Owner_Role__c.contains('AE1') || thisAccount.Owner_Role__c.contains('AE2') || thisAccount.Owner_Role__c.contains('AE3')) &&
thisAccount.Is_Deal_Reg_Account__c == true && thisAccount.LFBN__Assign_Account__c == true &&
thisAccount.LFBN__Assign_Account__c != oldAccount.LFBN__Assign_Account__c) {
thisAccount.LFBN__Assign_Account__c = false;
}
*/
            // added for GTMS-9932 to reset Overwrite_Validation_Rule__c
            if (oldAccount != NULL && oldAccount.Overwrite_Validation_Rule__c == true) {
                thisAccount.Overwrite_Validation_Rule__c = false;
            }
            if(oldAccount == NULL || oldAccount.Phone != thisAccount.Phone) {
                thisAccount.Normalized_Phone_Text__c = thisAccount.Normalized_Phone__c;
            }
            if(oldAccount == NULL || oldAccount.OwnerId != thisAccount.OwnerId) {
                thisAccount.Account_Assignment_Date__c = Datetime.NOW();
            }
            if(oldAccount == NULL || oldAccount.Status__c != thisAccount.Status__c) {
                thisAccount.Account_Status_Changed__c = Datetime.NOW();
            }
            if(oldAccount.Credit_Pre_Approval_Status__c != thisAccount.Credit_Pre_Approval_Status__c) {
                thisAccount.Pre_Approval_Timestamp__c = Datetime.NOW();
            }
            if(oldAccount.Validation_Complete__c != thisAccount.Validation_Complete__c) {
                thisAccount.DVS_Assignment__c = UserInfo.getUserId();
                thisAccount.Validation_Complete_Date__c = Datetime.NOW();
            }
            if(((oldAccount == NULL || oldAccount.BillingCountryCode != thisAccount.BillingCountryCode) && thisAccount.BillingCountryCode == 'MX'
                && thisAccount.CurrencyISOCode != currencyMap.get(thisAccount.BillingCountryCode)) ||
               (thisAccount.BillingCountryCode == 'MX') && thisAccount.CurrencyISOCode != currencyMap.get(thisAccount.BillingCountryCode) ) {
                   thisAccount.CurrencyISOCode = currencyMap.get(thisAccount.BillingCountryCode);
               }
            if(!approvedIFRMap.containsKey(thisAccount.Id)) {
                approvedPaymentType(oldAccount,thisAccount);
            }
            //GTMS - 3179 Check if we can send the ACV value to Totango field when customer ARR is not available.
            //GTMS - 4182 Condition added if it is 0 then it will allow to update the value
            //GTMS-12830 Start - commenting below lines of code as part 12830
            /*if(((thisAccount.Customer_ARR__c == null && thisAccount.Lifetime_ACV_to_USD__c != null) || (thisAccount.Customer_ARR__c == 0 && thisAccount.Lifetime_ACV_to_USD__c != 0 && (thisAccount.First_Purchase_Date__c >= Date.today().addDays(-30) && thisAccount.First_Purchase_Date__c <= Date.today()))) && oldAccount.Account_Lifetime_ACV__c != thisAccount.Account_Lifetime_ACV__c) {
                thisAccount.Customer_ARR__c = thisAccount.Lifetime_ACV_to_USD__c;
            }*/
            //GTMS-12830 End
            // setCsTier(thisAccount); //Commented as part of GTMS-18361
            /*if ( (oldAccount.CS_Tier__c != thisAccount.CS_Tier__c && thisAccount.CS_Tier__c == 'Plus' && thisAccount.Onboarding_Complete__c==true) ||
(oldAccount.Onboarding_Complete__c != thisAccount.Onboarding_Complete__c && thisAccount.Onboarding_Complete__c==true && thisAccount.CS_Tier__c == 'Plus')
) // added for GTMS-10383
thisAccount.LFBN__Assign_Account__c = true;
*/
            //Groundswell : Nilesh Jain  - Changes done as a part of GTMS-2999 to Remove Account DML from checkIfAccountNeedsCsmOrSeOnUpdate
            if (thisAccount.Segment__c == 'Enterprise' && String.isNotBlank(thisAccount.Owner_SE__c) && String.isBlank(thisAccount.SE_Assignment__c)) {
                thisAccount.SE_Assignment__c = thisAccount.Owner_SE__c;
            }
            //End
            ensureLFBNForPartnerAccount(thisAccount,oldAccount);
            //GTMS-6852
            if(thisAccount.Netsuite_Delinquent_Status__c == 'Deactivated' || thisAccount.Netsuite_Delinquent_Status__c == 'Written-off') {
                thisAccount.Quarantine_Enabled__c = true;
            }
            else {
                thisAccount.Quarantine_Enabled__c = false;
            }
            //GTMS-6447
            if(
                String.isNotBlank(thisAccount.VATId__c) &&
                thisAccount.BillingCountry == 'Mexico' &&
                ( thisAccount.Id==null ||
                 (oldAccount != null && oldAccountMap.containsKey(thisAccount.Id) && (thisAccount.BillingCountry != oldAccount.BillingCountry || thisAccount.VATId__c != oldAccount.VATId__c) ))
            )
            {
                TaxIdAccountMap.put(thisAccount.VATId__c,thisAccount);
            }
            // added for GTMS-12941 to update Sync_with_Zendesk__c true
            if(oldAccount == null || thisAccount.TAM__c  != oldAccount.TAM__c ) {
                thisAccount.Sync_with_Zendesk__c = true;
            }
            //added for GTMS-14503 to updated Approved payment type to Direct Annaul (By Vijaychandra AMARANENI)
            if(oldAccount.Account_Size_Segment__c == 'AE1' && thisAccount.Account_Size_Segment__c != 'AE1' &&
               (thisAccount.Credit_Limit__c == NULL || thisAccount.Credit_Limit__c == 0) && thisAccount.Segment__c == 'AE1' && thisAccount.Approved_Payment_Type__c == 'Direct Monthly'){
                   thisAccount.Approved_Payment_Type__c = 'Direct Annual';
               }
            //End of GTMS-14503
            //GTMS-10727 condition
            //insert scenario
            if(oldAccountMap == null) {
                for(Account objAcc: newAccountList) {
                    if(ObjAcc.Status__c != null && objAcc.Status__c == 'Existing Customer') { // change to contains, added check on Open opportunity
                        objAcc.Prospecting_Status__c = 'AE Prospecting';
                    }
                    else if(ObjAcc.Status__c != null && (objAcc.Status__c == 'Existing Customer - Open Opportunity' ||
                                                         objAcc.Status__c == 'Open Opportunity')) {
                                                             objAcc.Prospecting_Status__c = 'Open Opportunity';
                                                         }
                    else if (ObjAcc.Status__c != null) {
                        objAcc.Prospecting_Status__c = 'ADR Prospecting';
                    }
                }
            }
            else {
                for(Account objAcc: newAccountList) {
                    if(ObjAcc.Status__c != null && objAcc.Status__c == 'Existing Customer' && oldAccountMap.get(objAcc.Id).Status__c != 'Existing Customer') {
                        objAcc.Prospecting_Status__c = 'AE Prospecting';
                    }
                    else if(ObjAcc.Status__c != null && ((objAcc.Status__c == 'Existing Customer - Open Opportunity'
                                                          && oldAccountMap.get(objAcc.Id).Status__c != 'Existing Customer - Open Opportunity') ||
                                                         (objAcc.Status__c == 'Open Opportunity'
                                                          && oldAccountMap.get(objAcc.Id).Status__c != 'Open Opportunity')                            )
                           ) {
                               objAcc.Prospecting_Status__c = 'Open Opportunity';
                           }
                    else if (ObjAcc.Status__c != null && ((objAcc.Prospecting_Status__c == 'AE Prospecting' && (ObjAcc.Status__c == 'New' || ObjAcc.Status__c=='Assigned')) ||
                                                          (objAcc.Prospecting_Status__c != 'AE Prospecting' &&
                                                           oldAccountMap.get(objAcc.Id).Prospecting_Status__c != 'ADR Prospecting' && objAcc.Status__c != oldAccountMap.get(objAcc.Id).Status__c))) {
                                                               objAcc.Prospecting_Status__c = 'ADR Prospecting';
                                                           }
                }
            }
            //GTMS 7836 Alekhya
            /* recalculateMaxCreditValue(thisAccount);*/
            //D&B package change. New
            if(thisAccount.SLED_Account__c != thisAccount.SLED_Account_Copy__c) {
                thisAccount.SLED_Account_Copy__c = thisAccount.SLED_Account__c;
            }
        }
        //GTMS-6447
        if(!TaxIdAccountMap.isEmpty())
        {
            processAccounts(TaxIdAccountMap);
        }
    }
    public void beforeUpdatePrePopulateHelper(Map<Id, Account> oldAccountMap, List<Account> newAccountList){
        Map<Id, Account> ownerRoleAccIds = new Map<Id, Account>();
        Set<ID> accountIDSforContract = new Set<ID>();
       
        for(Account thisAccount : newAccountList) {
            Account oldAccount = new Account();
            oldAccount = oldAccountMap.get(thisAccount.Id);
            //Groundswell: Nilesh Jain - syncAccount changes
            syncAccount(thisAccount, oldAccount);
            //Groundswell Nilesh Jain : populateBillingDetails method changes
            if ((thisAccount.Owner_Role__c != null)
                && (thisAccount.Owner_Role__c.contains('AE3')
                    || thisAccount.Owner_Role__c.contains('AE2')
                    || thisAccount.Owner_Role__c.contains('ENT')
                    || thisAccount.Owner_Role__c.contains('IND'))
                && thisAccount.Billing_Contact__c != null &&
                oldAccount.Billing_Contact__c != thisAccount.Billing_Contact__c) {
                    ownerRoleAccIds.put(thisAccount.Billing_Contact__c, thisAccount);
                }
            //End
            /*//GTMS- 10289
if((thisAccount.Number_of_Vehicles__c) >31 &&(thisAccount.Account_Size_Segment__c == 'AE2/AE3') && ((thisAccount.Credit_Limit__c) == 0 || (thisAccount.Credit_Limit__c) == null ))
{
thisAccount.Approved_Payment_Type__c = 'Direct Annual';
}
//End GTMS-10289 */
            /*//GTMS 7836 Alekhya
recalculateMaxCreditValue(thisAccount);*/
            if(oldAccount.Netsuite_Delinquent_Status__c != thisAccount.Netsuite_Delinquent_Status__c && thisAccount.Netsuite_Delinquent_Status__c != 'NULL' && thisAccount.Netsuite_Delinquent_Status__c == 'Written-off'){
                accountIDSforContract.add(thisAccount.id);
            }
            // added for GTMS-20208
            if (thisAccount.VATId__c != null && thisAccount.VATId__c.contains(' ')) {
                thisAccount.VATId__c =  thisAccount.VATId__c.replaceAll('\\s+', '');
            }

            // GTMS-25005
            if(thisAccount.Customer_require_PO_for_invoicing__c != 'Yes') {
                //GTMS-25900 to update profile param
                updatePORequired(thisAccount,oldAccount);
            }
        }
        //Groundswell Nilesh Jain : populateBillingDetails method changes
        if (!ownerRoleAccIds.isEmpty()) {
            copyBillingInfo(ownerRoleAccIds);
        }
        if (!accountIDSforContract.isEmpty()) {
            updateContracts(accountIDSforContract);
        }
        //GTMS-10727 condition
        //insert scenario
        /*if(oldAccountMap == null) {
for(Account objAcc: newAccountList) {
if(ObjAcc.Status__c != null && objAcc.Status__c == 'Existing Customer') {
objAcc.Prospecting_Status__c = 'AE Prospecting';
}
}
}
else {
system.debug('newAccountList--'+newAccountList);
for(Account objAcc: newAccountList) {
system.debug(oldAccountMap.get(objAcc.Id).Status__c+'---');
if(ObjAcc.Status__c != null && objAcc.Status__c == 'Existing Customer' && oldAccountMap.get(objAcc.Id).Status__c != 'Existing Customer') {
objAcc.Prospecting_Status__c = 'AE Prospecting';
}
}
}  */
    }
    // GTMS - 11609 Updates Ultimate Parent field on Account with the root account
    public void updateUltimateAccount(List<Account> newAccountList, Map<id,Account> oldAccountMap) {
        Set<Id> parentIds = new Set<Id>();
        for (Account acc : newAccountList) {
            if(acc.ParentId != oldAccountMap.get(acc.Id).ParentId){
                if(acc.ParentId == null) { // Added as part of GTMS-25342
                acc.Ultimate_Parent__c = null;
            } else { // Ended GTMS-25342
                parentIds.add(acc.ParentId);
            }

            }
        }
         Set<Id> ultimateParentIdSet=new Set<Id>(); //Added line as part of GTMS-24221
        // fetch all parent accounts with their parents in one SOQL query
        if(!parentIds.isEmpty() && parentIds.Size()>0){
            Map<Id, Account> parentMap = new Map<Id, Account>([SELECT Id, ParentId, Ultimate_Parent__c FROM Account WHERE Id IN :parentIds]);
            for (Account acc : newAccountList) {
                if (acc.ParentId != null && parentMap.containsKey(acc.ParentId)) {
                    Account parentAccount = parentMap.get(acc.ParentId);
                    if (parentAccount != null) {
                        acc.Ultimate_Parent__c = parentAccount.Ultimate_Parent__c != null ? parentAccount.Ultimate_Parent__c : parentAccount.Id;
                      ultimateParentIdSet.add(acc.Ultimate_Parent__c);//Added line as part of GTMS-24221
                    }
                }
            }
             //Added as part of GTMS-24221
            if(!ultimateParentIdSet.isEmpty()){
                updateUltimateParentCheck(ultimateParentIdSet);
        }
        }
    }
    public void insertUltimateAccount(List<Account> newAccountList) {
        Set<Id> parentIds = new Set<Id>();
        for (Account acc : newAccountList) {
            parentIds.add(acc.ParentId);
        }
        
        Set<Id> ultimateParentIdSet=new Set<Id>(); //Added line as part of GTMS-24221
        // fetch all parent accounts with their parents in one SOQL query
        Map<Id, Account> parentMap = new Map<Id, Account>([SELECT Id, ParentId, Ultimate_Parent__c FROM Account WHERE Id IN :parentIds]);
        for (Account acc : newAccountList) {
            if (acc.ParentId != null && parentMap.containsKey(acc.ParentId)) {
                Account parentAccount = parentMap.get(acc.ParentId);
                if (parentAccount != null) {
                    acc.Ultimate_Parent__c = parentAccount.Ultimate_Parent__c != null ? parentAccount.Ultimate_Parent__c : parentAccount.Id;
                ultimateParentIdSet.add(acc.Ultimate_Parent__c);//Added line as part of GTMS-24221
                }
            }
        }
         //Added as part of GTMS-24221
        if(!ultimateParentIdSet.isEmpty()){
                updateUltimateParentCheck(ultimateParentIdSet);
    }
    }
    
     // GTMS-24221 Start
     //Method: This method is to update the checkbox on the account if its an ultimate parent 
    Public void updateUltimateParentCheck(Set<id> accIdSet){
        List<Account> accountsToUpdate=new List<Account>();
        Map<Id,Account> ultimateParentMap=new Map<Id,Account>([SELECT Id,Is_Ultimate_Parent__c FROM Account WHERE Id IN:accIdSet AND Is_Ultimate_Parent__c=False]);
        if(!ultimateParentMap.values().isEmpty()){
            for(Account acc:ultimateParentMap.values()){
                   acc.Is_Ultimate_Parent__c=true;
                accountsToUpdate.add(acc);
            }
            if(!accountsToUpdate.isEmpty()){
                update accountsToUpdate;
            }
        }
    }
    // GTMS-24221 End
    @future
    public static void updateContracts(Set<ID> AccountIds){
        List<Contract> contractsList = [SELECT ID from Contract where AccountId IN :AccountIds and Deactivated__c = False ];
        List<Contract> contractsToUpdate = new List<Contract>();
        for(Contract Con:contractsList ){
            Contract c= new Contract(id = Con.Id, Deactivated__c = True);
            contractsToUpdate.add(c);
        }
        if(!contractsToUpdate.isEmpty())
            update contractsToUpdate;
    }
    /* //GTMS 7836
if((thisAccount.Current_Monthly_Payments__c != null && ( (thisAccount.credit_limit__c != null &&
thisAccount.Current_Monthly_Payments__c > thisAccount.credit_limit__c/2) || thisAccount.credit_limit__c==null)
&& thisAccount.Account_Size_Segment__c == 'ENT')||
(thisAccount.Current_Monthly_Payments__c != null && ( (thisAccount.credit_limit__c != null &&
thisAccount.Current_Monthly_Payments__c  > thisAccount.credit_limit__c/2)|| thisAccount.credit_limit__c==null)
&& thisAccount.Account_Size_Segment__c != 'ENT'
&& (thisAccount.Delinquency_Status__c == null && thisAccount.Delinquent__c == false ))){
if (thisAccount.credit_limit__c==null || thisAccount.credit_limit__c==0)
thisAccount.credit_limit__c = thisAccount.Current_Monthly_Payments__c*2;
else
thisAccount.credit_limit__c = thisAccount.credit_limit__c*2;
}
//GTMS-7836 :Ends
} */
    //GTMS-6447 - Siddharth Kumar Mishra - This method checks if new Account is part of MX Non Compliant Tax payers and marks them accordingly
    public void processAccounts(Map<String,Account> TaxIdAccountmap)
    {
        //List of MX_Non_Compliant_Taxpayers__c that match with accounts tax ids
        List<MX_Non_Compliant_Taxpayers__c> MXList = [SELECT Id,RFC__c FROM MX_Non_Compliant_Taxpayers__c WHERE RFC__c IN :TaxIdAccountmap.keySet()];
        if(!MXList.isEmpty())
        {
            for(MX_Non_Compliant_Taxpayers__c mx : MXList)
            {
                if(TaxIdAccountmap.keySet().contains(mx.RFC__c))
                {
                    TaxIdAccountmap.get(mx.RFC__c).MX_Non_Compliant_Tax_Payer__c = True;
                }
            }
        }
    }
    public void samNumberUndecorated(Account thisAccount){
        if(ObjectFieldNull(thisAccount, 'SAM_Number_Undecorated__c')){
            populateSamNumberUnderCorated(thisAccount);
        }
    }
    public void setNaicsCode(Account oldAccount, Account thisAccount){
        if((oldAccount == NULL && !ObjectFieldNull(thisAccount, 'NAICS_Code__c')) || thisAccount.NAICS_Code__c != oldAccount.NAICS_Code__c){
            populateNaicsCode(thisAccount);
        }
    }
    public void setRecordTypeStampForDupes(Account oldAccount, Account thisAccount){
        if((oldAccount == NULL || oldAccount.RecordTypeId != thisAccount.RecordTypeId) && !ObjectFieldNull(thisAccount, 'RecordTypeId')) {
            thisAccount.Record_Type_Stamp_for_Dupes__c = rt_Map.get(thisAccount.RecordTypeId).getName();
        }
    }
    //GTMS-6422: Updating partner discount based on the Partner type and program type selection on Partner accounts
    public void setPartnerDiscount(Account oldAccount, Account thisAccount){
        Map<String,Partner_Discount__mdt> pdMap = Partner_Discount__mdt.getAll();
        if(rt_Map?.get(thisAccount.RecordTypeId)?.DeveloperName=='Partner' && thisAccount?.Partner_Type__c == 'Insurance' &&
           (oldAccount == null || (oldAccount!= null &&
                                   (oldAccount.Partner_Type__c != thisAccount.Partner_Type__c || oldAccount.Program_Type__c != thisAccount.Program_Type__c)))){
                                       Map<String,Partner_Discount__mdt> prgDiscountMap = new Map<String,Partner_Discount__mdt>();
                                       if(pdMap != null && pdMap.values()?.Size()>0 ){
                                       for(Partner_Discount__mdt pd: pdMap.values()){
                                           if(pd.Partner_Type__c =='Insurance'){
                                               prgDiscountMap.put(pd.Program_Type__c,pd);
                                           }
                                       }
                                       }    
                                       if(String.isNotBlank( thisAccount.Program_Type__c) && thisAccount.Program_Type__c.contains('Paid Referral')){
                                           thisAccount.Partner_Discount__c = (prgDiscountMap.get('Paid Referral') != null) ? prgDiscountMap.get('Paid Referral').Discount__c:0;
                                       }else if(String.isNotBlank( thisAccount.Program_Type__c) && ( thisAccount.Program_Type__c.contains('Subsidy') || thisAccount.Program_Type__c.contains('Unpaid Referral') ||
                                                thisAccount.Program_Type__c.contains('Teaming Partner') || thisAccount.Program_Type__c.contains('Premium Discount') || thisAccount.Program_Type__c.contains('Safety Program'))){
                                                    thisAccount.Partner_Discount__c = (prgDiscountMap.get('Subsidy') != null) ? prgDiscountMap.get('Subsidy')?.Discount__c:0;
                                                }else{
                                                    thisAccount.Partner_Discount__c = 0;
                                                }
                                   }else if(rt_Map?.get(thisAccount.RecordTypeId)?.DeveloperName=='Partner' && thisAccount.Partner_Type__c != 'Insurance' &&
                                            (oldAccount == null || (oldAccount!= null &&  oldAccount.Partner_Type__c == 'Insurance'))){
                                                thisAccount.Partner_Discount__c = null;
                                            }
    }
    /**
*  SET MICRO FLEET SUPPORT TIER
*/
    public void setMicroFleetSupportTier(Account oldAccount, Account thisAccount){
        if ((thisAccount.Total_Purchased_VG_Count__c <=2
             && thisAccount.Total_Purchased_AG_Count__c <=2
             && thisAccount.Total_Purchased_CM_Count__c <=2
             && thisAccount.Total_Purchased_EM_Count__c <=2
             && (thisAccount.Number_of_Vehicles__c == null || thisAccount.Number_of_Vehicles__c <=2)
             && thisAccount.Lifetime_Purchases__c > 0
             && thisAccount.Record_Type_Stamp_for_Dupes__c == 'Fleet')
            && !(oldAccount.Total_Purchased_VG_Count__c <=2
                 && oldAccount.Total_Purchased_AG_Count__c <=2
                 && oldAccount.Total_Purchased_CM_Count__c <=2
                 && oldAccount.Total_Purchased_EM_Count__c <=2
                 && (oldAccount.Number_of_Vehicles__c == null || oldAccount.Number_of_Vehicles__c <=2)
                 && oldAccount.Lifetime_Purchases__c > 0
                 && oldAccount.Record_Type_Stamp_for_Dupes__c == 'Fleet')) {
                     thisAccount.Micro_Fleet_Support_Tier__c = true;
                 } else if ((thisAccount.Micro_Fleet_Support_Tier__c
                             && (thisAccount.Total_Purchased_VG_Count__c >= 3
                                 || thisAccount.Total_Purchased_AG_Count__c >= 3
                                 || thisAccount.Total_Purchased_CM_Count__c >= 3
                                 || thisAccount.Total_Purchased_EM_Count__c >= 3
                                 || thisAccount.Number_of_Vehicles__c >= 3))
                            && !(oldAccount.Total_Purchased_VG_Count__c >= 3
                                 || oldAccount.Total_Purchased_AG_Count__c >= 3
                                 || oldAccount.Total_Purchased_CM_Count__c >= 3
                                 || oldAccount.Total_Purchased_EM_Count__c >= 3
                                 || oldAccount.Number_of_Vehicles__c >= 3)) {
                                     thisAccount.Micro_Fleet_Support_Tier__c = false;
                                 }
    }
    public void setPOCFields(Account thisAccount){
        // Narmada  GTMS-4069
        If((ObjectFieldNull(thisAccount, 'CS_POC_Email_Address__c') || ObjectFieldNull(thisAccount, 'CS_POC_First_Name__c') || ObjectFieldNull(thisAccount, 'CS_POC_Phone__c')) && thisAccount.First_Purchase_Date__c  >= system.today().addDays(-7)
           && (!ObjectFieldNull(thisAccount, 'Billing_Email__c') || !ObjectFieldNull(thisAccount, 'Billing_First_Name__c') || !ObjectFieldNull(thisAccount, 'Billing_Phone__c')) && thisAccount.ownerid == System.Label.SmallFleetAccountOwnerId){
               populatePOCFields(thisAccount);
           }
    }
    public void populatePOCFields(Account thisAccount){
        thisAccount.CS_POC_Email_Address__c = thisAccount.Billing_Email__c;
        thisAccount.CS_POC_First_Name__c  = thisAccount.Billing_First_Name__c;
        thisAccount.CS_POC_Phone__c  = thisAccount.Billing_Phone__c;
    }
    public void approvedPaymentType(Account oldAccount, Account thisAccount){
        /*//GTMS-15696 Start
//GTMS-3350(Update Approved Payment type for AE1 to Direct Monthly if ARR>5K or no
// of vehicle>10)
//GTMS-5394-Zakeer-ApprovedPaymentType change
if(thisAccount.Account_Size_Segment__c == System.label.AccountSizeSegment_AE1 &&
(((oldAccount.Number_of_Vehicles__c != thisAccount.Number_of_Vehicles__c) && (thisAccount.Number_of_Vehicles__c != NULL) || oldAccount.Owner != thisAccount.Owner || oldAccount.Sites_Specialist__c != thisAccount.Sites_Specialist__c ))){
if((thisAccount.Sites_Specialist__c != NULL || thisAccount.Number_of_Vehicles__c > Integer.valueOf(System.Label.Number_of_Vehicle)) || ((thisAccount.Customer_ARR__c != Null) && (thisAccount.Customer_ARR__c >= Integer.valueOf(System.Label.Customer_ARR)))){
thisAccount.Approved_Payment_Type__c = 'Direct Monthly';
}
else if ((thisAccount.OwnerId == System.Label.SmallFleetAccountOwnerId && thisAccount.Sites_Specialist__c == NULL) || (thisAccount.Number_of_Vehicles__c <= Integer.valueOf(System.Label.Number_of_Vehicle) && thisAccount.Sites_Specialist__c == NULL && (thisAccount.First_Purchase_Date__c == NULL || thisAccount.First_Purchase_Date__c >= Date.valueof(System.label.First_Purchase_Date)))
|| (thisAccount.Sites_Specialist__c == NULL && thisAccount.Number_of_Vehicles__c < Integer.valueOf(System.Label.Number_of_Vehicle) && (thisAccount.First_Purchase_Date__c == NULL || thisAccount.First_Purchase_Date__c >= Date.valueof(System.label.First_Purchase_Date) ))){
thisAccount.Approved_Payment_Type__c = 'Upfront Payments';
}
}
//GTMS-3951
//GTMS-4188 - Below null value added and insert operation removed
if(thisAccount.BillingCountryCode == 'CA' && (thisAccount.Number_of_Vehicles__c<=20 || thisAccount.Number_of_Vehicles__c==Null)) {
thisAccount.Approved_Payment_Type__c = 'Direct Monthly';
}
if(thisAccount.Approved_Payment_Type__c == NULL) {
thisAccount.Approved_Payment_Type__c = 'Direct Annual';
}
if(thisAccount.Lifetime_Purchases__c < 10000 && thisAccount.Lifetime_Purchases__c < oldAccount.Lifetime_Purchases__c && thisAccount.Approved_Payment_Type__c != 'Direct Monthly') {
thisAccount.Approved_Payment_Type__c = 'Upfront Payments';
}
if(thisAccount.Lifetime_Purchases__c >= 10000 && thisAccount.Approved_Payment_Type__c == 'Upfront Payments') {
thisAccount.Approved_Payment_Type__c = 'Direct Annual';
} //GTMS-15696 End*/
        //GTMS-15696 //GTMS-19177
        if(!String.isBlank(thisAccount.ParentId)){
            if((thisAccount.BillingCountryCode == 'CA' || thisAccount.BillingCountryCode == 'US') && (thisAccount.Owner_Role__c.contains('AE1') || thisAccount.Owner_Role__c.contains('CML'))){
                thisAccount.Approved_Payment_Type__c = 'Direct Monthly';
            }
            else{
                thisAccount.Approved_Payment_Type__c = 'Direct Annual';
            }
        }
        else{
            if((thisAccount.Number_of_Vehicles__c <> NULL && thisAccount.Number_of_Vehicles__c > 10)
               || (thisAccount.Number_of_Powered_Assets__c <> NULL && thisAccount.Number_of_Powered_Assets__c > 30)
               || (thisAccount.Number_of_Unpowered_Assets__c <> NULL && thisAccount.Number_of_Unpowered_Assets__c > 30)){
                   if((thisAccount.BillingCountryCode == 'CA' || thisAccount.BillingCountryCode == 'US') && (thisAccount.Owner_Role__c.contains('AE1') || thisAccount.Owner_Role__c.contains('CML'))){
                       thisAccount.Approved_Payment_Type__c = 'Direct Monthly';
                   }
                   else{
                       thisAccount.Approved_Payment_Type__c = 'Direct Annual';
                   }
               }
            else{
                if(thisAccount.Number_of_Vehicles__c == NULL || thisAccount.Number_of_Vehicles__c < 11
                   || thisAccount.Number_of_Powered_Assets__c == NULL || thisAccount.Number_of_Powered_Assets__c < 31
                   || thisAccount.Number_of_Unpowered_Assets__c == NULL || thisAccount.Number_of_Unpowered_Assets__c < 31){
                       thisAccount.Approved_Payment_Type__c = 'Upfront Payments';
                   }
            }
        }
    }
    //Commented as part of GTMS-18361
    // public void setCsTier(Account thisAccount){
    //     if(!thisAccount.CS_Tier_Override__c) {
    //         Decimal arr = (thisAccount.Customer_ARR__c == 0 || thisAccount.Customer_ARR__c == null) ? thisAccount.Account_Lifetime_ACV__c : thisAccount.Customer_ARR__c;
    //         if((thisAccount.Customer_ARR__c == 0 || thisAccount.Customer_ARR__c == null) && (thisAccount.Account_Lifetime_ACV__c == 0 || thisAccount.Account_Lifetime_ACV__c == null)) {
    //             thisAccount.CS_Tier__c = '';
    //         }
    //         //GTMS-9675 @Chinmaya Dash Adjusted the logic for ARR for 'Starter'
    //         if (arr == 0 ||
    //             (arr >= csTierMap.get('Starter_limits').Min_Value__c && arr <= csTierMap.get('Starter_limits').Max_Value__c)) {
    //                 thisAccount.CS_Tier__c = 'Starter';
    //             } else if (arr <= csTierMap.get('Plus_limits').Max_Value__c) {
    //                 thisAccount.CS_Tier__c = 'Plus';
    //             } else if (arr < csTierMap.get('Premier_Limits').Max_Value__c) {
    //                 thisAccount.CS_Tier__c = 'Premier';
    //             } else if (arr >= csTierMap.get('Elite_limits').Min_Value__c) {
    //                 thisAccount.CS_Tier__c = 'Elite';
    //             }
    //     }
    // }
    public void beforeInsertAccountWorkflowConversion(List<Account> newAccountList){
        GS_AccountWorkflowConversionService accountWorkflowConversionService = new GS_AccountWorkflowConversionService();
        this.mapUsers = accountWorkflowConversionService.beforeInsertAccountWorkflowConversion(newAccountList);
        // added for GTMS-20208
        for (Account thisAccount: newAccountList){
            if (thisAccount.VATId__c != null && thisAccount.VATId__c.contains(' ')) {
                thisAccount.VATId__c =  thisAccount.VATId__c.replaceAll('\\s+', '');
            }

            // GTMS-25005
            if(thisAccount.Customer_require_PO_for_invoicing__c != 'Yes') {
                //GTMS-25900 to update profile param
                updatePORequired(thisAccount, null);
            }
        }
        /* //GTMS-10289
for (Account a: newAccountList)
{
if((a.Number_of_Vehicles__c) >31 && (a.Account_Size_Segment__c == 'AE2/AE3') && ((a.Credit_Limit__c) == 0 || (a.Credit_Limit__c) == null ))
{
a.Approved_Payment_Type__c = 'Direct Annual';
}
}//END */
    }
    public void syncAccount(Account newAccount, Account oldAccount){
        Boolean changeFlag = criteriaCheck(newAccount, oldAccount);
        if(changeFlag && !((isChanged(newAccount, oldAccount, Schema.Account.Push_to_Netsuite__c) &&
                            (isChanged(newAccount, oldAccount, Schema.Account.Sync_in_Progress__c)))) &&
           (oldAccount.Push_to_Netsuite__c == false && oldAccount.Sync_in_Progress__c == false) && (oldAccount.Netsuite_Id__c != null
                                                                                                    || newAccount.Push_to_Netsuite__c == true)){
                                                                                                        newAccount.Push_to_Netsuite__c = true;
                                                                                                        newAccount.Sync_in_Progress__c = true;
                                                                                                        if (!accountSyncEvents.containsKey(newAccount.Id))
                                                                                                            //if (accountSyncEvents.get(newAccount.Id)==null) // added for GTMS-8503
                                                                                                            accountSyncEvents.put(newAccount.Id, new Account_Sync_event__e(Id__c = newAccount.Id));
                                                                                                    }
    }
    public void createPlatformEvent(){
        if(accountSyncEvents.size() > 0){
            if (system.UserInfo.getName() != 'Automated Process')
            {
                if (System.Label.Logging_for_PlatformEvent == '1' )
                {
                    Api_Logger__c aplog = new Api_Logger__c();
                    apLog.Opportunity_Name__c =  'Account createPlatformEvent';
                    apLog.DML__c= true;
                    apLog.Request__c= string.valueOf(accountSyncEvents.size());
                    apLog.Exception_Message__c = 'Creating Platform Event to Sync Account - Account Sync Event';
                    apLog.Response__c=string.valueOf(accountSyncEvents);
                    //Boolean async = (System.isFuture() || System.isScheduled() || System.isQueueable() || System.isBatch()) ? true : false;
                    apLog.Quote_Number__c = system.UserInfo.getName();
                    insert aplog;
                }
                TrackPlatformEvents.enQueuePlatformEventJob(TrackPlatformEvents.Event.NETSUITE,Trigger.New,Trigger.oldMap);
                List<Database.SaveResult> results = EventBus.publish(accountSyncEvents.values());
                system.debug('RODRIGO ' + results);
            }
        }
    }
    public Boolean criteriaCheck(Account newAccount, Account oldAccount){
        //BSO GTMS-17364, 14163
        //Sync_Object_Field__mdt[] AccountSyncFields = [Select Id,Object_Api_Name__c,Field_Api_Name__c from Sync_Object_Field__mdt Where Object_Api_Name__c = 'Account'];
        for(Sync_Object_Field__mdt Mdt: AccountSyncFields)
        {
            if(newAccount.get(Mdt.Field_Api_Name__c)!=oldAccount.get(Mdt.Field_Api_Name__c))
            {
                return true;
            }
        }
        return false;
        //Groundwell : Nilesh Jain: Moved from isChanged to direct comparision as apart of GTMS-2874
        /*if((newAccount.Type != oldAccount.Type) ||
(newAccount.Name != oldAccount.Name) ||
(newAccount.OwnerId != oldAccount.OwnerId) ||
(newAccount.Phone != oldAccount.Phone) ||
(newAccount.Website != oldAccount.Website) ||
(newAccount.Industry != oldAccount.Industry) ||
(newAccount.NumberOfEmployees != oldAccount.NumberOfEmployees) ||
(newAccount.SAM_Number_Undecorated__c != oldAccount.SAM_Number_Undecorated__c) ||
(newAccount.Express_Deals_Counter__c != oldAccount.Express_Deals_Counter__c) ||
(newAccount.Billing_Stripe_Customer_Id__c != oldAccount.Billing_Stripe_Customer_Id__c) ||
(newAccount.VATId__c != oldAccount.VATId__c) ||
(newAccount.Tax_Exempt__c != oldAccount.Tax_Exempt__c) ||
(newAccount.Segment_Text_stamped__c != oldAccount.Segment_Text_stamped__c) ||
(newAccount.New_Billing_Process_Approved__c != oldAccount.New_Billing_Process_Approved__c) ||
(newAccount.Billing_Email__c != oldAccount.Billing_Email__c) ||
(newAccount.First_Purchase_Date__c != oldAccount.First_Purchase_Date__c) ||
(newAccount.Payment_Token__c != oldAccount.Payment_Token__c) ||
(newAccount.Which_written_language__c != oldAccount.Which_written_language__c) ||
(newAccount.CSM_Health_Rating__c != oldAccount.CSM_Health_Rating__c) ||
(newAccount.CSM_Health_Notes__c != oldAccount.CSM_Health_Notes__c) ||
(newAccount.Sentiment_Root_Cause__c != oldAccount.Sentiment_Root_Cause__c) ||
(newAccount.Quarantine_Enabled_At__c != oldAccount.Quarantine_Enabled_At__c) ||
(newAccount.Quarantine_Enabled__c != oldAccount.Quarantine_Enabled__c) ||
(newAccount.Organization_Size__c != oldAccount.Organization_Size__c) ||
(newAccount.Number_of_Students__c != oldAccount.Number_of_Students__c) ||
(newAccount.Number_of_Citizens__c != oldAccount.Number_of_Citizens__c) ||
(newAccount.Enterprise_Assignment__c != oldAccount.Enterprise_Assignment__c) ||
(newAccount.Number_of_Vehicles__c != oldAccount.Number_of_Vehicles__c) ||
(newAccount.Number_of_Unpowered_Assets__c != oldAccount.Number_of_Unpowered_Assets__c) ||
(newAccount.Number_of_Powered_Assets__c != oldAccount.Number_of_Powered_Assets__c) ||
(newAccount.BillingAddress != oldAccount.BillingAddress) ||
(newAccount.Billing_Contact__c != oldAccount.Billing_Contact__c) ||
(newAccount.netsuite_conn__Credit_Limit__c != oldAccount.netsuite_conn__Credit_Limit__c) ||
(newAccount.Push_to_Netsuite__c != oldAccount.Push_to_Netsuite__c)){
return true;
}
else{
return false;
}*/
        //End : Groundwell : Nilesh Jain: Moved from isChanged to direct comparision as apart of GTMS-2874
    }
    //Method to check if the values are changed -@Harsha
    public Boolean isChanged(Account newAccount, Account oldAccount, Schema.SObjectField field){
        if(newAccount.get(field) != oldAccount.get(field)){
            return true;
        }else{
            return false;
        }
    }
    public void copyBillingInfo(Map<Id, Account> ownerRoleAccIds) {
        List<Contact> contactList = new List<Contact>();
        contactList = new GS_ContactSelector(true).checkFatalError().getContactsByIds(ownerRoleAccIds.keySet());
        if(!contactList.isEmpty()){
            for(Contact con : contactList){
                Account thisAccount = ownerRoleAccIds.get(con.Id);
                thisAccount.Billing_First_Name__c = con.FirstName;
                thisAccount.Billing_Last_Name__c = con.LastName;
                thisAccount.Billing_Phone__c = con.Phone;
                thisAccount.Billing_Email__c = con.Email;
            }
        }
    }
    public void beforeUpdateAccountWorkflowConversion(Map<Id, Account> oldAccountMap, List<Account> newAccountList){
        GS_AccountWorkflowConversionService accountWorkflowConversionService = new GS_AccountWorkflowConversionService();
        this.mapUsers = accountWorkflowConversionService.beforeUpdateAccountWorkflowConversion(oldAccountMap, newAccountList);
    }
    public void accountsChanged(Map<Id, Account> oldAccountMap, List<Account> newAccountList){
        List<Account> accountsChanged = new List<Account>();
        for(Account thisAccount : newAccountList){
            Account oldAccount = new Account();
            oldAccount = oldAccountMap.get(thisAccount.Id);
            if(thisAccount.Send_to_My_ADR__c) {
                accountsChanged.add(thisAccount);
            }
            if(oldAccount.OwnerId != thisAccount.OwnerId) {
                accountsChanged.add(thisAccount);
            }
        }
        for (Account changedAccount : accountsChanged) {
            User currentUser = this.mapUsers.get(changedAccount.OwnerId);
            changedAccount.Current_Owner_Email__c = (currentUser!=null) ? currentUser.Email : changedAccount.Current_Owner_Email__c;
            User oldU = this.mapUsers.get(oldAccountMap.get(changedAccount.Id).OwnerId);
            if (oldU != null) {
                //TODO - follow-up with Dez or Latham
                changedAccount.Previous_Owner_Email__c = oldU.Email;
                changedAccount.Previous_Owner_Name__c = oldU.FirstName + ' ' + oldU.LastName;
                if (oldU.LastName == 'Pool' && currentUser!=null && currentUser.LastName != 'Pool' && changedAccount.Status__c != 'Delete') {
                    changedAccount.Status__c = 'Assigned';
                }
                // TODO - Re-evaluate if this assignment is necessary (check with James Choe)
                if (changedAccount.Segment__c == 'Enterprise' && changedAccount.Owner_SE__c != null) {
                    changedAccount.SE_Assignment__c = changedAccount.Owner_SE__c;
                }
                // TODO - Re-evaluate if this assignment is necessary (check with James Choe)
                if (changedAccount.Segment__c != 'Enterprise') {
                    changedAccount.SE_Assignment__c = null;
                }
                if(oldAccountMap.get(changedAccount.Id).Send_to_My_ADR__c != changedAccount.Send_to_My_ADR__c && changedAccount.Send_to_My_ADR__c) {
                    if(this.mapUsers.get(changedAccount.OwnerId).ADR_Assignment__c != null) {
                        if(changedAccount.Owner_Role__c.contains('AE3')) {
                            changedAccount.Original_Owner_for_Recycling_Campaign__c  = changedAccount.OwnerId;
                            changedAccount.ownerId = this.mapUsers.get(changedAccount.OwnerId).ADR_Assignment__c;
                            changedAccount.Send_to_My_ADR__c = false;
                            stampAccountSegment(changedAccount);
                        }
                        else if(changedAccount.Owner_Role__c.contains('ENT')) {
                            changedAccount.ownerId = this.mapUsers.get(changedAccount.OwnerId).ADR_Assignment__c;
                            changedAccount.Send_to_My_ADR__c = false;
                            stampAccountSegment(changedAccount);
                        }
                    }
                    else {
                        changedAccount.Send_to_My_ADR__c = false;
                    }
                }
            }
        }
    }
    public void stampAccountSegment(Account changedAccount){
        // WF Rule - Account: Segment
        //This text field brings in the Segment value from the
        //formula field: Segment (by Current owner) field on the account.
        changedAccount.Segment_Text_stamped__c = changedAccount.Segment__c;
    }
    private Boolean ObjectFieldNull(Sobject thisSobj, String thisField){
        return thisSobj.get(thisField) == null ;
    }
    private void populateSamNumberUnderCorated(Account thisAccount){
        String chars = '23456789ABCDEFGHJKMNPRSTUVWXYZ';
        String sam = 'C'; //All SAM numbers start with C
        for (Integer i=0;i<9; i++) { //generate 9 characters in addition to the beginning C
            Integer charPos = Math.floor(Math.random() * chars.length()).intValue();
            sam = sam + chars.substring(charPos,charPos+1);
        }
        thisAccount.sam_number_undecorated__c = sam;
    }
    private void populateNaicsCode(Account thisAccount){
        String devCode = 'X'+thisAccount.NAICS_Code__c;
        //thisAccount.NAICS_Hold__c = nCodes.containsKey(devCode) ? TRUE : FALSE;
    }
    @TestVisible
    private void ensureLFBNForPartnerAccount(Account thisAccount, Account oldAccount){
        if ((thisAccount.Initiate_Round_Robin__c && rt_Map.get(thisAccount.RecordTypeId).getDeveloperName() == 'Partner')){
                 thisAccount.Initiate_Round_Robin__c = false;
             }
    }
    //added below method for GTMS-12082
    public static void updateContracts(List<Account> triggerNew, Map<Id, Account> triggerOldMap) {
        if(!triggerNew.isEmpty()) {
            Set<Id> accountId = new Set<Id>();
            for(Account acc: triggerNew) {
                if(((acc.Customer_ARR_Netsuite__c != triggerOldMap.get(acc.Id).Customer_ARR_Netsuite__c && acc.Customer_ARR_Netsuite__c > 20000 && acc.Segment__c == 'AE2') && !acc.Auto_renewal_Opt_Out__c) ||
                   (triggerOldMap.get(acc.Id).Account_Size_Segment__c != acc.Account_Size_Segment__c && (acc.Account_Size_Segment__c == 'ENT' || acc.Account_Size_Segment__c == 'AE2/AE3') && acc.Segment__c == 'Management') ||
                   ((acc.Segment__c == 'Enterprise' || acc.Segment__c == 'AE3') && triggerOldMap.get(acc.Id).Segment__c != acc.Segment__c) 
                   ) {
                       accountId.add(acc.Id);
                   }
            }
            if(!accountId.isEmpty()) {
                //GTMS-12830 Manjusha Jammula - Start
                if(system.isBatch())
                    updateContractRecordsInBatch(accountId);
                else
                //GTMS-12830 - End
                updateContractRecords(accountId);
            }
        }
    }
    //added below method for GTMS-12082
    @future
    public static void updateContractRecords(Set<ID> accountId){
        updateContractRecordsLogic(accountId);
    }
    //GTMS-12830 Manjusha Jammula - Start
    public static void updateContractRecordsInBatch(Set<ID> accountId){
        updateContractRecordsLogic(accountId);
    }
    //GTMS-12830 - End
    public static void updateContractRecordsLogic(Set<ID> accountId){
        List<Contract> contractsList = [SELECT ID from Contract where AccountId IN :accountId and SBQQ__RenewalForecast__c = true AND SBQQ__RenewalQuoted__c = false
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
    }
    public static void updateOpportunityOwnerBasedAccOwner(Map<Id, Account> oldAccountMap, List<Account> newAccountList) {
        if(oldAccountMap != null && oldAccountMap.size() > 0){
            Set<Id> setAccountIds = new Set<Id>();
            for(Account objAccount : newAccountList){
                if(objAccount.Ownerid != oldAccountMap.get(objAccount.Id).Ownerid){
                    setAccountIds.add(objAccount.Id);
                }
            }
            if(setAccountIds != null && setAccountIds.size() > 0){
                List<Opportunity> listOpportunities = new List<Opportunity>();
                for(Opportunity objopp : [Select id,Accountid,
                                          Ownerid,Account.OwnerId
                                          from Opportunity where AccountId in: setAccountIds
                                          and (LeadSource='Partner business registration' or LeadSource='Deal Reg Form' or LeadSource='Partner referral')]){
                                              if(objopp.Accountid != null && objopp.Ownerid != objopp.Account.Ownerid){
                                                  objopp.Ownerid = objopp.Account.Ownerid;
                                                  listOpportunities.add(objopp);
                                              }
                                          }
                if(listOpportunities != null && listOpportunities.size() > 0)
                    Update listOpportunities;
            }
        }
    }
    //added this method to fix GTMS-7561
    //Extended to ensure the Opportunity Owner does not change for Warranty Exchange opportunities GTMS-11530.
    public static void revertRenewalOpportunityOwner(List<Account> newAccountList, Map<Id, Account> oldAccountMap) {
        Map<Id, Id> mapAccOldOwner = new Map<Id, Id>();
        for(Account acc : newAccountList) {
            if(oldAccountMap != null && acc.OwnerId != oldAccountMap.get(acc.Id).OwnerId) {
                mapAccOldOwner.put(acc.Id, oldAccountMap.get(acc.Id).OwnerId);
            }
        }
        if(!mapAccOldOwner.isEmpty()) {
            List<Opportunity> oppList = [
                Select Id, OwnerId, StageName, Type, Renewal__c, AccountId
                From Opportunity
                Where IsClosed = false AND ((Renewal__c = TRUE AND Type = 'Revenue Opportunity') OR (Type = 'Warranty Exchange'))
                AND AccountId IN:mapAccOldOwner.keyset()
            ];
            if(!oppList.isEmpty() && oppList.size() > 0) {
                for(Opportunity opp : oppList) {
                    mapOppOldOwner.put(opp.Id, opp.OwnerId);
                }
                revertOpportunityOwner(mapOppOldOwner);
            }
        }
    }
    //added this method to fix GTMS-7561
    @future
    public static void revertOpportunityOwner(Map<Id, Id> mapOppOldOwner) {
        List<Opportunity> oppList = new List<Opportunity>();
        for(Id oppId : mapOppOldOwner.keyset()) {
            Opportunity opp = new Opportunity();
            opp.Id = oppId;
            opp.OwnerId = mapOppOldOwner.get(oppId);
            oppList.add(opp);
        }
        system.debug('oppList---'+oppList);
        if(!oppList.isEmpty()) {
            TriggerHandler.bypass('OpportunityTriggerHandler');
            update oppList;
        }
    }
    // added for GTMS-12941 to update Sync_with_Zendesk__c false
    public static void updateZendeskFlag (List<Account> newAccountList, Map<Id, Account> oldAccountMap){
        Map<Id, Id> mapAccOldOwner = new Map<Id, Id>();
        for(Account acc : newAccountList) {
            if(oldAccountMap != null && acc.TAM__c  != oldAccountMap.get(acc.Id).TAM__c ) {
                mapAccOldOwner.put(acc.Id, acc.Id);
            }
        }
        if(!mapAccOldOwner.isEmpty()) {
            updateZendeskFlag(mapAccOldOwner);
        }
    }
    // added for GTMS-12941
    @future
    private static void updateZendeskFlag (Map<Id, Id> accountZendeskFlag) {
        List<Account> accntList = new List<Account>();
        for(Id accId : accountZendeskFlag.keyset()) {
            Account acct = new Account();
            acct.Id = accId;
            acct.Sync_with_Zendesk__c = false;
            accntList.add(acct);
        }
        if(!accntList.isEmpty()) {
            TriggerHandler.bypass('GS_AccountTriggerHandler');
            update accntList;
        }
    }

    public static void updateContactOwner(List<Account> newAccountList, Map<Id, Account> oldAccountMap) {
        // collect account that changes owner from RainMaker to Another User
        Set<Id> listOfAccount = new Set<Id>();
        FOR(Account obj :  newAccountList) {
            Account oldAccount = oldAccountMap.get(obj.Id);
            if(oldAccount.OwnerId != obj.OwnerId) {
                listOfAccount.add(obj.Id);
            }
        }
        if(listOfAccount.size()>0)
            updateContactOwnerFuture(listOfAccount);
    }
    //@future
    private static void updateContactOwnerFuture(Set<Id> listOfAccountIds) {
        Map<Id, Account> accountMap = new Map<Id, Account>([SELECT Id, OwnerId FROM Account WHERE Id IN: listOfAccountIds]);
        system.debug('RODRIGO updateContactOwnerFuture ' + listOfAccountIds);
        List<Contact> contactList = [SELECT Id, accountId, OwnerId FROM Contact WHERE accountId IN: accountMap.keySet()];
        List<Contact> contactListForUpdate = new List<Contact>();
        FOR(Contact con : contactList) {
            Account locAcct = accountMap.get(con.accountId);
            con.OwnerId = locAcct.OwnerId;
            con.New_Inbound_Lead__c = false;
            contactListForUpdate.add(con);
        }
        system.debug('RODRIGO updateContactOwnerFuture ' + contactListForUpdate);
        if (contactListForUpdate.size()>0) {
            TriggerHandler.bypass('ContactTriggerHandler');
            update contactListForUpdate;
        }
    }
    // GTMS-16585
    public static void updateQuoteBillingDetails(List<Account> newAccountList, Map<Id, Account> oldAccountMap) {
        Map<Id,Account> accountChange = new Map<Id,Account>();
        for(account acc: newAccountList){
            if(acc.BillingCity != oldAccountMap.get(acc.id).BillingCity
               || acc.BillingState != oldAccountMap.get(acc.id).BillingState
               || acc.BillingCountry != oldAccountMap.get(acc.id).BillingCountry
               || acc.BillingPostalCode != oldAccountMap.get(acc.id).BillingPostalCode
               || acc.BillingStreet != oldAccountMap.get(acc.id).BillingStreet
               || acc.Billing_Email__c != oldAccountMap.get(acc.id).Billing_Email__c){
                   accountChange.put(acc.Id,acc);
               }
        }
        if(!accountChange.isEmpty() && accountChange.Size() >0){
            list<SBQQ__Quote__c> updQuote = new  list<SBQQ__Quote__c>();
            for(SBQQ__Quote__c  qt: [SELECT id,SBQQ__BillingStreet__c,Bill_to_Account__c,Billing_Emails__c
                                     from SBQQ__Quote__c
                                     where Bill_to_Account__c = :accountChange.keySet()
                                     and SBQQ__Status__c <> 'Approved'
                                     and SBQQ__Opportunity2__r.Probability < 95
                                     and SBQQ__Opportunity2__r.type = 'Revenue Opportunity'
                                     and DCA_Validation__c = 'DCA']){
                                         Account acc = accountChange.get(qt.Bill_to_Account__c);
                                         SBQQ__Quote__c quote = new   SBQQ__Quote__c();
                                         quote.id = qt.id;
                                         quote.SBQQ__BillingStreet__c = acc.BillingStreet;
                                         quote.SBQQ__BillingCity__c = acc.BillingCity;
                                         quote.SBQQ__BillingState__c = acc.BillingState;
                                         quote.SBQQ__BillingCountry__c = acc.BillingCountry;
                                         quote.SBQQ__BillingPostalCode__c = acc.BillingPostalCode;
                                         if(String.isBlank(qt.Billing_Emails__c)){
                                             quote.Consolidated_Billing_Email__c = acc.Billing_Email__c;
                                         }
                                         updQuote.add(quote);
                                     }
            DMLWrapper.doUpdate(updQuote);
        }
    }
    public static void unlockApprovalRecord(List<Account> newAccountList, Map<Id, Account> oldAccountMap) {
    List<Account> AccLockList = new List<Account>();
      for(account acc: newAccountList){  
        Id recordId = acc.Id;
        if(acc.Approval_Status__c != oldAccountMap.get(acc.id).Approval_Status__c && acc.Approval_Status__c=='Pending'
          && Approval.isLocked(recordId)){
          AccLockList.add(acc);
        }
      }if(!AccLockList.isEmpty()){
                try{
        List<Approval.UnlockResult> ulrList = Approval.unlock(AccLockList, false);
        for(Approval.UnlockResult  ulr : ulrList) {
          if (ulr.isSuccess()) {
            System.debug('Successfully locked account with ID: ' + ulr.getId());
          }
          else {
            for(Database.Error err : ulr.getErrors()) {
              System.debug('The following error has occurred.');
              System.debug(err.getStatusCode() + ': ' + err.getMessage());
              System.debug('Account fields that affected this error: ' + err.getFields());
            }
          }
                    
        }}catch(exception e) {
                    /*Api_Logger__c aplog = new Api_Logger__c();
                    apLog.Opportunity_Name__c =  'Updating contracts field Auto_Renewal__c to false';
                    apLog.DML__c= true;
                    apLog.Exception_Message__c = e.getMessage();
                    aplogList.add(aplog);*/
            }
      }
    }
    //GTMS - 17225
    public static void syncAccountsBillingEmailToNetSuite(Map<Id,Account> oldAccountMap, List<Account> newAccountList){
        switch on Trigger.operationType {
            when AFTER_UPDATE {
                if(newAccountList == null || newAccountList.isEmpty() || oldAccountMap==null || oldAccountMap.isEmpty()){
                    return;
                }
                List<Account_Sync_Event__e> eventsList = new List<Account_Sync_Event__e >();
                for(Account acc: newAccountList){
                    if(String.isBlank(acc.Billing_Email__c)){
                        continue;
                    }
                    Account oldAccount = oldAccountMap.get(acc.Id);
                    if(oldAccount==null){
                        continue;
                    }
                    if(acc.Billing_Email__c!=oldAccount.Billing_Email__c){
                        eventsList.add(new Account_Sync_Event__e(Id__c=acc.Id, Billing_Email__c= acc.Billing_Email__c));
                    }
                }
                if(eventsList.isEmpty()){
                    return;
                }
                // Call method to publish events
                TrackPlatformEvents.enQueuePlatformEventJob(TrackPlatformEvents.Event.BILLING_EMAIL,Trigger.New,Trigger.oldMap);
                List<Database.SaveResult> results = EventBus.publish(eventsList);
                // Inspect publishing result for each event
                for (Database.SaveResult sr : results) {
                    if (sr.isSuccess()) {
                        System.debug('Successfully published event.');
                    } else {
                        for(Database.Error err : sr.getErrors()) {
                            System.debug('Error returned: ' + err.getStatusCode() + ' - ' + err.getMessage());
                        }
                    }
                }
            }
        }
    }
    public static void syncAccountsToBigCommerceBeforeUpdate(Map<id,Account> oldAccountMap, List<Account> newAccountsList){
        if(newAccountsList==null || newAccountsList.isEmpty() || oldAccountMap==null || oldAccountMap.isEmpty()){
            return;
        }
        Toggle_Platform_Event__mdt accountEventToggle = Toggle_Platform_Event__mdt.getInstance('Account_Sync_Webstore_Event');
        for(Account newAccount: newAccountsList){
            Account oldAccount = oldAccountMap.get(newAccount.Id);
            //Avoid Recurssion
            Boolean isPushToWebstoreUpdated = newAccount.Push_to_Webstore__c != oldAccount.Push_to_Webstore__c;
            Boolean isBigCommerceIdUpdated = newAccount.BigCommerce_Id__c != oldAccount.BigCommerce_Id__c;
            Boolean isWebstoreSyncErrorUpdated = newAccount.Webstore_Sync_Error__c != oldAccount.Webstore_Sync_Error__c;
            Boolean isUpdatedByWebstore =(isPushToWebstoreUpdated && (isBigCommerceIdUpdated || isWebstoreSyncErrorUpdated));
            Boolean changeFlagWebstore = isFieldValueChanged(newAccount, oldAccount,accountSyncWSFields);
            Boolean nullFlagCheck = verifyNullCheck(newAccount,accountSyncWSFields);
            Boolean isPushtoWebstoreChanged = (newAccount.Push_to_Webstore__c==true && (newAccount.Push_to_Webstore__c!= oldAccount.Push_to_Webstore__c));
            Boolean isNotSyncInProgress = oldAccount.Push_to_Webstore__c == false;
            Boolean isCriteriaCheckPass = (oldAccount.BigCommerce_Id__c != null || nullFlagCheck);
            if((changeFlagWebstore || isPushtoWebstoreChanged) && !isUpdatedByWebstore && isNotSyncInProgress && isCriteriaCheckPass && accountEventToggle.toggle__c ){
                if (isRecordModifiedByMulesoft(newAccount,oldAccount)) {
                    continue;
                }
                newAccount.Push_to_Webstore__c = true;
            }
        }
    }
    public static Boolean isRecordModifiedByMulesoft(Account newAccount, Account oldAccount){
        String userName = UserInfo.getName();
        if (userName == 'Automated Process' || (FeatureManagement.checkPermission('NetSuite_Service_User_Permission')  &&
       // if (userName == 'Automated Process' || (userName == 'Mulesoft Bot' &&
                                                (newAccount.Push_to_Netsuite__c != oldAccount.Push_to_Netsuite__c || newAccount.Push_to_Webstore__c==false))) {
                                                    return true;
                                                }else{
                                                    return false;
                                                }
    }
    public static void syncAccountsToBigCommerce(Map<id,Account> oldAccountMap, List<Account> newAccountsList){
        if(newAccountsList==null || newAccountsList.isEmpty() || oldAccountMap==null || oldAccountMap.isEmpty()){
            return;
        }
        Boolean checkPlatformEvent = PlatformEventCallback.checkPlatformEventLimits();
        if(!checkPlatformEvent){
            return;
        }
        Map<Id, Account_Sync_Webstore_Event__e> accountSyncWebstoreEvents = new Map<Id, Account_Sync_Webstore_Event__e >();
        Toggle_Platform_Event__mdt accountEventToggle = Toggle_Platform_Event__mdt.getInstance('Account_Sync_Webstore_Event');
        for(Account newAccount:newAccountsList){
            Account oldAccount = oldAccountMap.get(newAccount.Id);
            //Avoid Recurssion
            if (isRecordModifiedByMulesoft(newAccount,oldAccount)) {
                continue;
            }
            if(((newAccount.Push_to_Webstore__c == true && oldAccount.Push_to_Webstore__c == false)) && !accountSyncWebstoreEvents.containsKey(newAccount.Id) ){
                accountSyncWebstoreEvents.put(newAccount.Id, new Account_Sync_Webstore_Event__e(Id__c = newAccount.Id));
            }
        }
        if(accountSyncWebstoreEvents==null || accountSyncWebstoreEvents.isEmpty()){
            return;
        }
        if(accountEventToggle.toggle__c ){
            List<Database.SaveResult> srList = EventBus.publish(accountSyncWebstoreEvents.values(), new PlatformEventCallback());
            system.debug('srList   '+srList);
            for (Database.SaveResult sr : srList) {
                if (sr.isSuccess()) {
                    // Operation was successful, so get the ID of the record that was processed
                    System.debug('Successfully Published Platform Event. Account ID: ' + sr.getId());
                }
                else {
                    // Operation failed, so get all errors
                    for(Database.Error err : sr.getErrors()) {
                        System.debug('The following error has occurred.');
                        System.debug(err.getStatusCode() + ': ' + err.getMessage());
                        System.debug('Account fields that affected this error: ' + err.getFields());
                    }
                }
            }
        }
    }
    public static Boolean isFieldValueChanged(Account newAccount, Account oldAccount,Sync_Object_Field_WebStore__mdt [] accountSyncWSFields){
        for(Sync_Object_Field_WebStore__mdt mdt: accountSyncWSFields){
            if(newAccount.get(mdt.Field_Api_Name__c)!=oldAccount.get(mdt.Field_Api_Name__c)){
                return true;
            }
        }
        return false;
    }
    public static Boolean verifyNullCheck(Account newAccount,Sync_Object_Field_WebStore__mdt [] accountNullCheckFields){
        for(Sync_Object_Field_WebStore__mdt sofw: accountNullCheckFields){
            if(sofw.Null_Check_Needed__c){
                if(newAccount.get(sofw.Field_Api_Name__c)==null){
                    return false;
                }
            }
        }
        return true;
    }
    /**
* Created By : MouriTech
* @Date April 2, 2024
* Created for GTMS-18361
* @description : this method would take care of Account Tier based on ARR field.
** for mergeConflict
**/
    public void updateTierDetails(Map<Id, Account> oldAccountMap, List<Account> newAccountList){
        Set<Id> setOfAccountIdsToProcess = new Set<Id>();
        Set<String> fieldNameToTrackChanges = new Set<String>();
        // check the account if the field in custom metadata is updated.
                                        
        for(Account acc : newAccountList){
            if(!acc.CS_Tier_Override__c){
                Boolean isTierUpdated = false;
                for(CS_Tier_Limit__mdt tier : listOfActiveTiers){
                    if(String.isNotBlank(tier.Field_API_Name__c) &&
                       // Added Owner Change condition as part of GTMS-23464
                       (acc.get(tier.Field_API_Name__c) != oldAccountMap.get(acc.Id).get(tier.Field_API_Name__c) || acc.OwnerId != oldAccountMap.get(acc.Id).OwnerId)) {
                           String roleName =  acc.Owner_Role__c ;
                           if(String.isNotBlank(roleName) &&  tier.Owner_Role__c != null && tier.Active__c &&
                              roleName.contains(tier.Owner_Role__c) &&
                              (tier.Segment__c == '(ALL)' || roleName.contains(tier.Segment__c)) &&
                              acc.get(tier.Field_API_Name__c) != null &&
                              Double.valueOf(acc.get(tier.Field_API_Name__c)) >= tier.Min_Value__c &&
                              Double.valueOf(acc.get(tier.Field_API_Name__c)) <= tier.Max_Value__c){
                                  if(tier.Field_API_Name__c=='Total_parent_child_ARR__c' && roleName.contains('SLED')){
                                      acc.CS_Tier__c = acc.CS_Tier__c;
                                  }else{
                                      acc.CS_Tier__c=tier.Tier_Name__c;
                                  }
                                  isTierUpdated = true;
                                  break;
                              }
                       }
                }
                //Set CS Tier Default value.
                if(!isTierUpdated){
          if((acc.Owner_Role__c != null && !acc.Owner_Role__c.contains('COR') && !acc.Owner_Role__c.contains('SEL') && !acc.Owner_Role__c.contains('STR')) && 
            acc.Customer_ARR__c != oldAccountMap.get(acc.Id).Customer_ARR__c && 
                        acc.Customer_ARR__c > 0 && acc.Customer_ARR__c < 50000){ //Updated acc.Customer_ARR__c < 30000 to acc.Customer_ARR__c < 50000 as part of GTMS-25914
            acc.CS_Tier__c = 'Starter';
          }
        }
               //Update CS Tier to blank when ARR(Active ACV) is 0 or negative.
               //GTMS-25814 Missing CS Tier Assignment
                if((acc.Customer_ARR__c == NULL || acc.Customer_ARR__c <= 0) &&(acc.Total_parent_child_ARR__c == NULL || acc.Total_parent_child_ARR__c <= 0)){
                    acc.CS_Tier__c = '';
                }
            }
        }
    }

    //GTMS-25005
    public void updatePORequired(Account newAccount, Account oldAccount) {
        String skipProfiles = System.Label.PORequiredFinance;
        if (String.isNotBlank(skipProfiles) && skipProfiles.contains(UserInfo.getProfileId())) {
            return;
        }
        if (oldAccount != null) {
            Boolean fieldValueChanged = (newAccount.Customer_require_PO_for_invoicing__c != oldAccount.Customer_require_PO_for_invoicing__c);
            if (fieldValueChanged) {
                return;
            }
        }

        if (newAccount.Customer_require_PO_for_invoicing__c == null) {
            setPORequirementIfQualified(newAccount);
        }
    }
    
    private void setPORequirementIfQualified(Account account) {
        if (account.SLED_Account__c && 
            (account.Account_Size_Segment__c.containsIgnoreCase('AE2/AE3') ||
             account.Account_Size_Segment__c.containsIgnoreCase('ENT')) &&
            (account.Id == null || !System.Label.PO_Required_Exception_Accounts.contains(String.valueOf(account.Id)))) {
            account.Customer_require_PO_for_invoicing__c = 'Yes';
        }
    }    
    
  //GTMS-26905 CS Tier Not assigning to Core/Select/Strategic role accounts
    public void updateCSMDetails(Map<Id, Account> oldAccountMap, List<Account> newAccountList){
        Set<Id> setOfAccountIdsToProcess = new Set<Id>();
        Set<String> fieldNameToTrackChanges = new Set<String>();
        // check the account if the field in custom metadata is updated.
                                        
        for(Account acc : newAccountList){
            Account oldAccount = oldAccountMap.get(acc.Id);
            if(oldAccount.CS_Tier__c != acc.CS_Tier__c &&
            (acc.CS_Tier__c == 'Plus' || acc.CS_Tier__c == 'Core Basic' || acc.CS_Tier__c == 'Select Basic' || acc.CS_Tier__c == 'Strategic Basic') &&
              acc.SIC__c == null){
                
                RoundRobinHandler rr = new RoundRobinHandler('Lane Four','Account','SIC__c'); 
                RoundRobinHandler.RoundRobinInfo rrInfo = new RoundRobinHandler.RoundRobinInfo();
                rrInfo = rr.getAssignedUser(acc);
                Account accInfo = new Account();
                if (rrInfo.fieldToUpdate != null && rrInfo.userId != null) {
                    accInfo.put(rrInfo.fieldToUpdate, rrInfo.userId);
                    accInfo.Account_Assignment_Date__c = System.now();
                    accInfo.RR_Assignment_Rule__c = rrInfo.ruleId;
                    accInfo.RR_Assignment_Mapping__c = rrInfo.mappingId;
                    accInfo.Id = acc.Id;
                    TriggerHandler.bypass('GS_AccountTriggerHandler');
                    update accInfo;
                    rr.updateRuleDetail();
                }
            }
        }
    }
    // This method is added based on GTMS-29382
    public void accountExtensionCleanUp(Map<Id, Account> oldAccountMap) {
        Set<Id> accountIdsToDelete = oldAccountMap.keySet();
        if (!accountIdsToDelete.isEmpty()) {
            List<Account_Extension__c> extenToRemove = [
                SELECT Id, Account__c 
                FROM Account_Extension__c 
                WHERE Account__c IN :accountIdsToDelete
            ];
            If(!extenToRemove.isEmpty()){
            delete extenToRemove;
            }
        }
    }
    
    // This method is added based on GTMS-29267
    public void populateGeographySegment(List<Account> accounts, Map<Id, Account> oldAccountMap) {
        if (accounts == null || accounts.isEmpty()) {
            return;
        }
        Set<Id> accountIds = new Set<Id>();
        for (Account acc : accounts) {
            Account oldAcc = oldAccountMap.get(acc.Id);
            if (acc.BillingState != null && acc.BillingState != oldAcc.BillingState) {
                accountIds.add(acc.Id);
            }
        }
        if (accountIds.isEmpty()) {
        return;
        }
        Map<Id, Account_Extension__c> accountIdToExt = new Map<Id, Account_Extension__c>(
            [SELECT Id, Account__c, Account__r.BillingState, FY27_Global_Geography_Segment__c
             FROM Account_Extension__c 
             WHERE Account__c IN :accountIds]);
        List<Account_Extension__c> extensionsToUpdate = new List<Account_Extension__c>();
        for (Account_Extension__c ext : accountIdToExt.values()) {
            String billingState = ext.Account__r.BillingState;
            if (String.isNotBlank(billingState)) {
                String normalizedState = billingState.replace(' ', '_');
                State_to_Region_Mapping__mdt metaDataRecord = 
                    State_to_Region_Mapping__mdt.getInstance(normalizedState);
                if (metaDataRecord != null) {
                    String region = metaDataRecord.Region__c;
                    ext.FY27_Global_Geography_Segment__c = region;
                    extensionsToUpdate.add(ext);
                } else {
                    ext.FY27_Global_Geography_Segment__c = null;
                    extensionsToUpdate.add(ext);
                }
            }
        }
        if (!extensionsToUpdate.isEmpty()) {
            update extensionsToUpdate;
        } 
    }
}