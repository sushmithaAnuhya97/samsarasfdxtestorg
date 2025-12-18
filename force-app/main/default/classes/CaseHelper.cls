//Test Classes used for this class are
//1.CaseTriggerTest
//2.CaseRollUpAtRiskAndSupportPriorityTest
//3.assignContactOnCaseFromDashboardTest

/*
 * Description:- This class is appended with four other Triggers 
 * This is used by batch class GS_ContactAutomation
 * 1-March-2022 - Rajesh :- 6070 - SFDC CI - Multiple Triggers - Case Object
 */

public class CaseHelper {
    
    public static Id partnerSupportRTId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Partner Support').getRecordTypeId();
    public static List<Case> casesToUpdate = new List<Case>();

    //After Insert
    public static void executeAssignmentRuleForPartnerSupport(List<Case> newCaseList){
        casesToUpdate = new List<Case>();
        Database.DMLOptions dmlOpts = new Database.DMLOptions();
        dmlOpts.assignmentRuleHeader.useDefaultRule = true;
        dmlOpts.EmailHeader.triggerAutoResponseEmail = true;
        dmlOpts.EmailHeader.triggerOtherEmail = true;
        dmlOpts.EmailHeader.triggerUserEmail = true;
        
        for(Case currCase: newCaseList){
            if(currCase.RecordTypeId == partnerSupportRTId) {
                Case caseRecord = new Case(Id = currCase.Id);
                caseRecord.setOptions(dmlOpts);
                casesToUpdate.add(caseRecord);
            }
        }
        
        if (casesToUpdate.size() > 0) {
            DMLWrapper.doUpdate(casesToUpdate);
        }
    }

    //After Insert
    public static void caseAssignToRoundRobin(List<Case> newCaseList){        
        Date d = System.today();
        Datetime dt = (DateTime)d;        
        String strNewCaseQueue = (Label.Case_Queues.split(';'))[0]; //'00G1a000000fXCL';

        List<User> users = [Select Id, Support_Round_Robin__c, Support_Round_Robin_Timestamp__c, Number_of_Cases_today__c from User where Support_Round_Robin__c = True order by Support_Round_Robin_Timestamp__c];

        Map<Id,Id> mapCaseIdsAccountIds = new Map<Id,Id>();
        for(Case c: newCaseList){
            if(c.AccountId <> null)
                mapCaseIdsAccountIds.put(c.id,c.AccountId);
        }

        Map <Id,Account> relatedAccounts = new Map<Id,Account> ([Select Id, Support_Escalation__c, Support_Escalation_Owner__c from Account where Id in :mapCaseIdsAccountIds.values()]);

        List<case> lstCasesToUpdate = new List<case>();
        List<user> lstUsersToUpdate = new List<user>();
        User u;
        integer intUserCounter = 0;

        for(Case c: newCaseList){                               
            if(c.Case_Account_Priority__c != 's0' && c.Case_Account_Priority__c != 's1'){
                if(c.Origin == 'Email' || c.Origin == 'Dashboard'){ 
                    if(c.Reason != 'Feedback' ){                
                        if(c.AccountId <> null &  relatedAccounts.containsKey(c.AccountId)){
                            Account relatedAccount = relatedAccounts.get(c.AccountId);
                            if(relatedAccount.Support_Escalation__c == true && relatedAccount.Support_Escalation_Owner__c != null){
                                lstCasesToUpdate.add(new case(id=c.Id, 
                                                        OwnerId =  relatedAccount.Support_Escalation_Owner__c)); 
                            } 
                            else{
                                if(users.size() > 0){                                
                                    u = users[intUserCounter];
                                    u.Number_of_Cases_today__c = u.Number_of_Cases_today__c + 1;
                                    u.Support_Round_Robin_Timestamp__c = system.now();
                                    
                                    lstCasesToUpdate.add(new case(id=c.Id,   
                                                            OwnerId =  u.Id,
                                                            Round_Robined__c = True));
                                    lstUsersToUpdate.add(u);

                                    intUserCounter++;
                                    
                                    if(intUserCounter == users.size())
                                        intUserCounter = 0;
                                }
                                else{
                                    lstCasesToUpdate.add(new case(id=c.Id, 
                                                        OwnerId = strNewCaseQueue,
                                                        Round_Robined__c = False));
                                }                                                
                            }
                        }           
                    } 
                }      
            }            
        }

        if(lstCasesToUpdate.size() > 0)
            DMLWrapper.doUpdate(lstCasesToUpdate);
        if(lstUsersToUpdate.size() > 0)
            DMLWrapper.doUpdate(lstUsersToUpdate);
    }

    
    //After Insert
    public static void ReturnPolicyDays (List<Case> newCaseList){
        string strQueueCustReturns = (Label.Case_Queues.split(';'))[1]; //'00G1a000001jnoW';
        Set<string> setSubject = new Set<String>();
        Map<string,Opportunity> mapSubjectOpp = new map<string,Opportunity>();
        List<Case> lstCasesToUpdate = new List<Case>();
        Date casedate = System.Today();

        //collect case subject
        for(Case c: newCaseList){
            if(c.OwnerId == strQueueCustReturns){ 
                setSubject.add(c.Subject.RIGHT(8));
            }            
        }

        List<Opportunity> lstOpp = [Select Id, Owner.Email, CloseDate, Order_Number__c from Opportunity where Order_Number__c IN :setSubject];
        
        for(Opportunity o : lstOpp){
            mapSubjectOpp.put(o.Order_Number__c, o);
        }
            
        for(Case c: newCaseList){                               
           if(c.OwnerId == strQueueCustReturns && mapSubjectOpp.containsKey(c.Subject.RIGHT(8))){     
            lstCasesToUpdate.add(new case(ID=c.id,
                                            Return_Policy_Days_Left__c = mapSubjectOpp.get(c.Subject.RIGHT(8)).CloseDate.daysBetween(casedate),
                                            Return_Oppty_Owner_Email__c = mapSubjectOpp.get(c.Subject.RIGHT(8)).Owner.Email ));
            }
        }

        if(lstCasesToUpdate.size() > 0)
            DMLWrapper.doUpdate(lstCasesToUpdate);
    }

    
    //Before Insert
    public static void assignContactOnCaseFromDashboard(List<Case> newCaseList){  
        Hardcoded_Id__c samsaraAcct = [SELECT Name, Id__c FROM Hardcoded_Id__c WHERE Name = 'Samsara Account' LIMIT 1];
        set<string> setEmails = new set<string>();
        Set<Id> setAccountIds = new set<Id>();
        Set<String> setEmailAccountId = new Set<String>();
        
        //collect Samsara_Dashboard_Email__c, AccountId
        for (Case c : newCaseList){            
            if (c.Origin.equals('Dashboard')){
                setEmails.add(c.Samsara_Dashboard_Email__c);
                setAccountIds.add(c.AccountId);
                
                if(c.Samsara_Dashboard_Email__c <> null && c.AccountId <> null)
                    setEmailAccountId.add(c.Samsara_Dashboard_Email__c + ';' + c.AccountId);
            }            
        }

        List<Contact> matchedContacts = [SELECT Id, AccountId, Email FROM Contact WHERE Email IN :setEmails AND AccountId IN :setAccountIds];
	   
        Map<String,Id> mapEmailAccountContact = new Map<String,Id>();
        for(Contact con : matchedContacts){
            mapEmailAccountContact.put(con.Email + con.AccountId, con.Id);

            //if this comb exists, then delete from the set, so that we can insert the remaining set items(contacts)
            if(setEmailAccountId.contains(con.Email + ';' + con.AccountId)) 
                setEmailAccountId.remove(con.Email + ';' + con.AccountId);
        }

        List<Contact> lstContactsNew = new List<Contact>();
        for(string s : setEmailAccountId){
            Contact newContact = new Contact();
            newContact.Email = (s.split(';'))[0]; 
            newContact.LastName = (s.split(';'))[0];
            newContact.AccountId = (s.split(';'))[1];
            lstContactsNew.add(newContact);
        }

        //insert & add newly created contacts to map
        if(lstContactsNew.size() > 0){
            insert lstContactsNew;

            for(Contact con : lstContactsNew){
                mapEmailAccountContact.put(con.Email + con.AccountId, con.Id);
            }
        }
        
        for (Case c : newCaseList){
            if (c.Origin.equals('Dashboard')){                
                //Set case account to Samsara if case/feedback came from Samsara user. 
                //String dashboardEmail = c.Samsara_Dashboard_Email__c;
                String dashboardEmailDomain;
                if(c.Samsara_Dashboard_Email__c != NULL){
                    dashboardEmailDomain = c.Samsara_Dashboard_Email__c.split('@').get(1).toLowerCase();
                }               
                    
                if (dashboardEmailDomain.equals('samsara.com')){	
                    c.AccountId = samsaraAcct.Id__c; 
                }
                else{
                    //Find or create contact based on dashboard-account-email and AccountId provided from Dashboard 
                    
                    if (c.Samsara_Dashboard_Email__c <> '' 
                        && c.AccountId <> null 
                        && mapEmailAccountContact.containsKey(c.Samsara_Dashboard_Email__c + c.AccountId)){
                            //Found contact in the specified account. Use the first one, since even if there's more than one, we have to pick
                            c.ContactId = mapEmailAccountContact.get(c.Samsara_Dashboard_Email__c + c.AccountId);     			                       
                    }
                }
            } 
        }
    }

    //After Insert, After Update
    public static void caseRollUpAtRiskAndSupportPriority(List<Case> newCaseList){        
        Map<id,id> mapCaseIssue = new Map<Id,Id>();
        for (Case current_case : newCaseList){
            if(current_case.Related_Issue__c <> Null)
                mapCaseIssue.put(current_case.id,current_case.Related_Issue__c);
        }        

        List<Issue__c> lstIssues = [SELECT Id, Case_Count__c, Account_Count__c, Last_Case_Added_Date__c, 
                Total_Purchased_VG_Count__c, Total_Purchased_AG_Count__c, Total_Purchased_CM_Count__c, Total_Purchased_EM_Count__c,
                (SELECT Id, AccountId, Account.AtRisk__c, Case_Account_Priority__c, Total_Purchased_VG_Count__c, 
                Total_Purchased_AG_Count__c, Total_Purchased_CM_Count__c, Total_Purchased_EM_Count__c,CreatedDate FROM Cases__r ORDER BY CreatedDate DESC)
                FROM Issue__c 
                WHERE Id IN : mapCaseIssue.values()];                

        for (Issue__c issue : lstIssues){       
            Decimal totalAtRisk = 0;
            String priority = '';
            Id AccountInitial;
            Decimal VG_count = 0;
            Decimal AG_count = 0;
            Decimal CM_count = 0;
            Decimal EM_count = 0;            
            Integer accountcount = 0;

            for (case c : issue.Cases__r){   
                if(AccountInitial != c.AccountId){
                    VG_count += c.Total_Purchased_VG_Count__c;
                    AG_count += c.Total_Purchased_AG_Count__c;
                    CM_count += c.Total_Purchased_CM_Count__c;
                    EM_count += c.Total_Purchased_EM_Count__c;
                    
                    if (c.Account.AtRisk__c <> Null){
                        totalAtRisk += c.Account.AtRisk__c;
                    }

                    priority = c.Case_Account_Priority__c == 's0' || c.Case_Account_Priority__c == 's1' ? c.Case_Account_Priority__c : 's2';

                    AccountInitial = c.AccountId;
                    accountcount = accountcount + 1;
                }                
            }

            issue.Total_Purchased_VG_Count__c = VG_count;
            issue.Total_Purchased_AG_Count__c = AG_count;
            issue.Total_Purchased_CM_Count__c = CM_count;
            issue.Total_Purchased_EM_Count__c = EM_count;
            issue.Account_Count__c = accountcount;
            issue.AtRisk__c = totalAtRisk;
            issue.Case_Count__c = issue.Cases__r.size();
            issue.Support_Priority__c = priority;
            issue.Last_Case_Added_Date__c = issue.Cases__r[0].CreatedDate;            
            
            //System.debug(totalAtRisk);
            //System.debug(cases);
        }       
        
        if(lstIssues.size() > 0)
            DMLWrapper.doUpdate(lstIssues);        
    }
}