/*
    ******************************************************************************
    Apex Class Name    : JobCreateOpportunitySplit
    Created Date       : Dec 12, 2023
    @description       : This is class is used to inser OpportunitySplitRecords
    @author            : Mohamed
    Modification Log:
    -----------------------------------------------------------------------------
    Version |  Date       |   Author       |    Modification
    -----------------------------------------------------------------------------
    1.0     |  12-12-2023 | Mohamed        |      Initial Version
    
    *****************************************************************************
    */
    global class JobCreateOpportunitySplit implements Database.Batchable<sObject> ,  Database.Stateful {
        global String query = '';
        global final String opportunityId;
        global integer recOppSplitInsertSuccess = 0;
        global integer recOppSplitInsertFail= 0;
        global Set<String> failedOppId = new Set<String>();
        global String ExceptionOccured;
        global String OppSplitEmailAddress = System.Label.RattleSnake_OpportunitySplitJobEmailAddresses;
        // get the OpportunitySplitType record where developername is "OverLay"
        global static  OpportunitySplitType OppSplitTypeOverlay = [SELECT Id, DeveloperName, Description, IsActive FROM OpportunitySplitType where DeveloperName='Overlay' and IsActive=true limit 1 ];
        //global string getmonthcondition = (Date.Today().toStartofWeek().month() != Date.Today().month())?' (CloseDate = LAST_N_MONTHS:2 OR CloseDate = THIS_MONTH )':' (CloseDate = LAST_N_MONTHS:1 OR CloseDate = THIS_MONTH )';

        /*
    @description constructor
    */
        global JobCreateOpportunitySplit (String query, String opportunityId) {   
            String selectStatement='SELECT Id,Type, IsSplit, isClosed,IsWon,Went_to_closed_lost_date__c, Split_New_ACV__c, Split_Renewal_ACV__c, Account.Owner.Name, Account.Owner.Email, Account.Owner.UserRole.Name, Account.Renewal_AE__r.Name, Account.Renewal_AE__r.Email, Account.Renewal_AE__r.UserRole.Name, CloseDate, Opportunity.Went_to_Closed_Won_Date__c, Owner.name, Owner.Email, Owner.UserRole.Name, Owner_Manager_Name_Copy__r.Name, Owner_Manager_Name_Copy__r.Email, Owner_Manager_Name_Copy__r.UserRole.Name, Owner_Director_Name_Copy__r.Name, Owner_Director_Name_Copy__r.Email, Owner_Director_Name_Copy__r.UserRole.Name, Amount FROM Opportunity ';         
            //get Query from the batch job or from the custom label
            if(String.isNotBlank(query)){
                String escapedStrQuery = query;
                this.query = escapedStrQuery;
            }
            else{  
                //this.query = System.Label.RattleSnake_OpportunitySplitJob;
                //this.query=selectStatement+' WHERE Overwrite_Split_Values__c = false AND Account.Exclude_HWM__c=false  AND (((Type=\'Remorse Refund\' OR (Type=\'Rebate\' AND Rebate_Type__c =\'Delinquent\')) AND IsWon=true) OR Type=\'Revenue Opportunity\') AND ACV_Bookings_SOT__c !=0 AND Account.CurrencyIsoCode IN (\'USD\',\'CAD\',\'MXN\') AND Account.Segment__c IN (\'Enterprise\',\'AE3\') AND  ((Split_New_ACV__c != null AND Split_New_ACV__c!=0) OR (Split_Renewal_ACV__c != null AND Split_Renewal_ACV__c!=0)) AND (( CloseDate>=2024-02-04 AND CloseDate<=Next_N_DAYS:365 AND ISClosed = false) OR (ISClosed = true AND '+ getmonthcondition +' ) )   ';

                this.query=selectStatement+' WHERE  Account.Exclude_HWM__c=false  AND (((Type=\'Remorse Refund\' OR (Type=\'Rebate\' AND Rebate_Type__c =\'Delinquent\')) AND IsWon=true) OR Type=\'Revenue Opportunity\') AND ACV_Bookings_SOT__c !=0 AND Account.CurrencyIsoCode IN (\'USD\',\'CAD\',\'MXN\') AND Account.Segment__c IN (\'Enterprise\',\'AE3\') AND (NOT Account.Owner_Role__c  LIKE \'%COR%\') AND CloseDate>=2024-02-04 AND CloseDate<=Next_N_DAYS:365 AND ((Split_New_ACV__c != null AND Split_New_ACV__c!=0) OR (Split_Renewal_ACV__c != null AND Split_Renewal_ACV__c!=0))  ';
            }
            // check if the opportunityId is not blank
            if(String.isNotBlank(opportunityId)){
                this.opportunityId=opportunityId;
                String condition = selectStatement+' Where ID = \''+String.escapeSingleQuotes(opportunityId)+'\'';
                this.query  =  condition;
            }
            this.query+=' Order By CreatedDate ASC';
              system.debug('this.query with condition:'+this.query);
        }
        
        /*
    * @description start which is used to get the opportunity records whose segment is Enterprise and AE3 
    * @return Database.QueryLocator
    */
        global Database.QueryLocator start(Database.BatchableContext BC) {
            
            return Database.getQueryLocator(this.query);
        }
        /*
    * @description execute which is used to delete the existing opportunity split Overlay records and insert the opportunity team and opportunitysplit records
    * @param Database.BatchableContext
    * @param oppList conatins the list of opportunity records fetched from start method
    * @return null
    */
        global void execute(Database.BatchableContext BC, List<opportunity> oppList) {
            List<OpportunitySplit> oppSpltLstIns = new List<OpportunitySplit>();
            List<Id> oppIsSplitLst = new List<Id>();
            Set<Id> oppUserIds = new Set<Id>();
            set<Id> oppTeamMemberSet = new set<Id>();
            List<OpportunitySplit> OpSpitLstDel = new List<OpportunitySplit>();
            
            List<OpportunityTeamMember> InsertOppTeamMemberLst = new List<OpportunityTeamMember>();
            try{
                if(
                    oppList.size()==1 && 
                    ( 
                        String.isNotBlank(this.opportunityId) ||
                        oppList[0].IsClosed==false || 
                        (
                            (oppList[0].IsClosed==true && oppList[0].Type!='Revenue Opportunity' && oppList[0].CloseDate>=Date.today().addDays(-1)) || 
                            (oppList[0].IsClosed==true && oppList[0].IsWon==true && oppList[0].Type=='Revenue Opportunity' && oppList[0].Went_to_closed_won_date__c!=null && oppList[0].Went_to_closed_won_date__c>=Date.today().addDays(-1)) ||
                            (oppList[0].IsClosed==true && oppList[0].IsWon==false  && oppList[0].Type=='Revenue Opportunity' && oppList[0].Went_to_closed_lost_date__c!=null && oppList[0].Went_to_closed_lost_date__c>=Date.today().addDays(-1))
                        )
                    )
                ){               
                //if(!oppList.isEmpty()){
                    for(OpportunityTeamMember optm: [SELECT Id, UserId,User.name,TeamMemberRole, OpportunityAccessLevel,Opportunity.Account.OwnerId,Opportunity.Account.Renewal_AE__c FROM OpportunityTeamMember where OpportunityId =:oppList]){
                        oppTeamMemberSet.add(optm.UserId);
                        if(optm.Opportunity.Account.OwnerId != null){
                          oppUserIds.add(optm.Opportunity.Account.OwnerId);  
                        }
                        if(optm.Opportunity.Account.Renewal_AE__c != null){
                          oppUserIds.add(optm.Opportunity.Account.Renewal_AE__c);  
                        }
                        
                    } 
                    Map<String,user> mapUserRecords = new Map<String,user> ([SELECT id,name, ManagerId,Manager.Name,Manager.Email,Manager.UserRole.Name,Manager.Manager.Name,Manager.Manager.Email,Manager.Manager.UserRole.Name
                              FROM user where id =:oppUserIds]);
                    for( Opportunity oppty: oppList ){
                         // check if the opportunity has split record  and if the opportunity is not closed or closed yesterday
                         //&& (!oppty.isClosed || (oppty.isClosed  && oppty.Went_to_closed_won_date__c >= (System.today() - 1)))
                        if(oppty.IsSplit ){
                            oppIsSplitLst.add(oppty.Id);
                        }
                        if(oppty.Split_New_ACV__c != null && oppty.Split_New_ACV__c <>0 && oppty.Account.OwnerId != null){
                            //Create opportunity team member record only when the oppty.Account.OwnerId is not available as the opportunity team member of that opportunity
                            if(!oppTeamMemberSet.contains(oppty.Account.OwnerId)){
                                OpportunityTeamMember oppTeamMem = new OpportunityTeamMember();   
                                oppTeamMem.OpportunityId  = oppty.Id;
                                oppTeamMem.userId = oppty.Account.OwnerId;
                                oppTeamMem.TeamMemberRole = 'Account Executive';
                                /********check with business( read or readwrite)*********/
                                oppTeamMem.OpportunityAccessLevel = 'Read';
                                InsertOppTeamMemberLst.add(oppTeamMem);
                                oppTeamMemberSet.add(oppty.Account.OwnerId);                            
                            }                        
                        }
                        if(oppty.Split_Renewal_ACV__c !=null && oppty.Split_Renewal_ACV__c <> 0 && oppty.Account.Renewal_AE__c != null){
                            //Create opportunity team member record only when the oppty.Account.Renewal_AE__c is not available as the opportunity team member of that opportunity
                            if(!oppTeamMemberSet.contains(oppty.Account.Renewal_AE__c)){
                                OpportunityTeamMember oppTeamMem = new OpportunityTeamMember();   
                                oppTeamMem.OpportunityId  = oppty.Id;
                                oppTeamMem.userId = oppty.Account.Renewal_AE__c;
                                oppTeamMem.TeamMemberRole = 'Renewal Account Executive';
                                /********check with business( read or readwrite)*********/
                                oppTeamMem.OpportunityAccessLevel = 'Read';
                                InsertOppTeamMemberLst.add(oppTeamMem);
                            }
                        }
                        //add Opportunity account owner to the opportunity team list for new and renewal opportunity    
                        //(!oppty.isClosed || (oppty.isClosed  && oppty.Went_to_closed_won_date__c >= (System.today() - 1)))
                        //&& 
                        if(((oppty.Split_New_ACV__c != null && oppty.Split_New_ACV__c <>0)||(oppty.Split_Renewal_ACV__c !=null && oppty.Split_Renewal_ACV__c <> 0 ))){                        
                            if(oppty.Split_New_ACV__c != null && oppty.Split_New_ACV__c <>0 && oppty.Account.OwnerId != null){
                                OpportunitySplit oppSplt = new OpportunitySplit();
                                oppSplt.OpportunityId  = oppty.Id;
                                oppSplt.SplitPercentage =100.00;
                                oppSplt.SplitTypeId = OppSplitTypeOverlay.Id;
                                oppSplt.Split_ACV__c   = oppty.Split_New_ACV__c;
                                oppSplt.SplitOwnerId   = oppty.Account.OwnerId;
                                oppSplt.User_Name__c   = oppty.Account.Owner.Name;
                                oppSplt.User_Email__c  = oppty.Account.Owner.Email ;
                                oppSplt.User_Role__c   = oppty.Account.Owner.UserRole.Name;
                                if(mapUserRecords.containsKey(oppty.Account.OwnerId) && mapUserRecords.get(oppty.Account.OwnerId).ManagerId != null){
                                    oppSplt.Manager_Name_Copy__c   = mapUserRecords.get(oppty.Account.OwnerId).Manager.Name;
                                    oppSplt.Manager_Email_Copy__c  = mapUserRecords.get(oppty.Account.OwnerId).Manager.Email;
                                    oppSplt.Manager_Role_Copy__c   = mapUserRecords.get(oppty.Account.OwnerId).Manager.UserRole.Name;
                                    oppSplt.Manager_Copy_Lookup__c   = mapUserRecords.get(oppty.Account.OwnerId).ManagerId;

                                }
                                 if(mapUserRecords.containsKey(oppty.Account.OwnerId) && mapUserRecords.get(oppty.Account.OwnerId).ManagerId != null && mapUserRecords.get(oppty.Account.OwnerId).Manager.ManagerId!=null){
                                    oppSplt.Director_Name_Copy__c   = mapUserRecords.get(oppty.Account.OwnerId).Manager.Manager.Name;
                                    oppSplt.Director_Email_Copy__c  = mapUserRecords.get(oppty.Account.OwnerId).Manager.Manager.Email;
                                    oppSplt.Director_Role_Copy__c   = mapUserRecords.get(oppty.Account.OwnerId).Manager.Manager.UserRole.Name;
                                    oppSplt.Director_Copy_Lookup__c=mapUserRecords.get(oppty.Account.OwnerId).Manager.ManagerId;

                                }
                                oppSpltLstIns.add(oppSplt); 
                            }
                            if(oppty.Split_Renewal_ACV__c !=null && oppty.Split_Renewal_ACV__c <> 0 && oppty.Account.Renewal_AE__r?.Id != null ){
                                OpportunitySplit oppSplt = new OpportunitySplit();
                                oppSplt.OpportunityId  = oppty.Id;
                                oppSplt.SplitPercentage =100.00;
                                oppSplt.SplitTypeId = OppSplitTypeOverlay.Id;
                                oppSplt.Split_ACV__c  = oppty.Split_Renewal_ACV__c;
                                oppSplt.SplitOwnerId  = oppty.Account.Renewal_AE__r?.Id;
                                oppSplt.User_Name__c  = oppty.Account.Renewal_AE__r?.Name;
                                oppSplt.User_Email__c = oppty.Account.Renewal_AE__r?.Email ;                            
                                oppSplt.User_Role__c  = oppty.Account.Renewal_AE__r?.UserRole.Name;
                                if(mapUserRecords.containsKey(oppty.Account.Renewal_AE__c) && mapUserRecords.get(oppty.Account.Renewal_AE__c).ManagerId != null){
                                    oppSplt.Manager_Name_Copy__c   = mapUserRecords.get(oppty.Account.Renewal_AE__c).Manager.Name;
                                    oppSplt.Manager_Email_Copy__c  = mapUserRecords.get(oppty.Account.Renewal_AE__c).Manager.Email;
                                    oppSplt.Manager_Role_Copy__c   = mapUserRecords.get(oppty.Account.Renewal_AE__c).Manager.UserRole.Name;
                                    oppSplt.Manager_Copy_Lookup__c   =mapUserRecords.get(oppty.Account.Renewal_AE__c).ManagerId;
                                }
                                 if(mapUserRecords.containsKey(oppty.Account.Renewal_AE__c) && mapUserRecords.get(oppty.Account.Renewal_AE__c).ManagerId != null && mapUserRecords.get(oppty.Account.Renewal_AE__c).Manager.ManagerId != null){
                                    oppSplt.Director_Name_Copy__c   = mapUserRecords.get(oppty.Account.Renewal_AE__c).Manager.Manager.Name;
                                    oppSplt.Director_Email_Copy__c  = mapUserRecords.get(oppty.Account.Renewal_AE__c).Manager.Manager.Email;
                                    oppSplt.Director_Role_Copy__c   = mapUserRecords.get(oppty.Account.Renewal_AE__c).Manager.Manager.UserRole.Name;
                                    oppSplt.Director_Copy_Lookup__c=mapUserRecords.get(oppty.Account.Renewal_AE__c).Manager.ManagerId;
                                }
                                oppSpltLstIns.add(oppSplt); 
                            }                            
                        }                                            
                    }
                    if(!oppIsSplitLst.isEmpty()){
                        //get the opportunity split records for that particular opportunity
                        OpSpitLstDel = [select id from OpportunitySplit where SplitType.DeveloperName='Overlay' and OpportunityId =:oppIsSplitLst ];   
                        //Delete the opportunity split overlay records
                        if(!OpSpitLstDel.isEmpty()){
                            delete OpSpitLstDel;
                        }                    
                    }   
                    //Insert Opportunity account owner to the opportunity team
                    if(!InsertOppTeamMemberLst.isEmpty()){
                        insert InsertOppTeamMemberLst;
                    }
                    //Insert opportunity split record
                    if(!oppSpltLstIns.isEmpty()){
                        insert oppSpltLstIns;
                    }                                                         
                }
            }
            catch(Exception ex){
                System.Debug('Exception ex---'+ex.getStackTraceString());
                System.debug('The following exception has occurred: ' + ex.getMessage());
                failedOppId.add(oppList[0].id);
                ExceptionOccured = ex.getMessage();
                System.debug('Exception type caught: ' + ex.getTypeName());  
                System.debug('Cause: ' + ex.getCause());    // returns null
                System.debug('Line number: ' + ex.getLineNumber());    
                System.debug('Stack trace: ' + ex.getStackTraceString());
                
            }
        }  
        
        /*
    * @description finish which is used to send status mail after execution of batch
    * @param Database.BatchableContext
    * @return null
    */
        global void finish(Database.BatchableContext BC) {
            AsyncApexJob asynJobRec = [SELECT Id
                                       ,Status
                                       ,ExtendedStatus
                                       ,NumberOfErrors
                                       ,JobItemsProcessed
                                       ,TotalJobItems
                                       ,CreatedBy.Email
                                       FROM AsyncApexJob
                                       WHERE Id =: BC.getJobId()];            
            
            String failedOpportunityId = String.join( failedOppId, ',' ); 
           
            if(!failedOppId.isEmpty()){
                Messaging.singleEmailMessage mail = new Messaging.singleEmailMessage();
                List<String> toEmail=new List<String>();
                for(String e:OppSplitEmailAddress.split(',')){
                    if(String.isNotBlank(e)){
                        toEmail.add(e.trim());
                    }
                }
                mail.setToAddresses(toEmail);
                String jobName ='';
                mail.setSubject(jobName+'Job Create Opportunity Split Batch Job '+ asynJobRec.status);
                String mailText = 'Hi, <br/><br/>';
                mailText +='Please find the below status.<br/><br/>';
                mailText +='Number of Batch run '+asynJobRec.TotalJobItems +'<br/>';
                mailText +='Number of OpportunitySplit Record Inserted '+recOppSplitInsertSuccess+ 'With '+recOppSplitInsertFail+' failures.<br/>';
                mailText +='failed Opportunity Record:'+failedOppId+'<br/>';
                mailText +='Exception occured:'+ExceptionOccured+'<br/><br/>';
                mailText +='Thank You';
                mail.setHTMLBody(mailText);
                Messaging.sendEmail(new Messaging.SingleEmailMessage []{mail});
                system.debug('Mail Successfully Sent');                
            }
        }
                       
    }