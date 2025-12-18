/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 06-25-2023,06-30-2023
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
 * @Test Class        : QueueableContractConsolidationTest
 * @VF Page           : QueueableContractConsolidationVf.vfp
 * @VF Controller     : QueueableContractConsolidationVf.apxc
 * https://help.salesforce.com/s/articleView?id=000383742&type=1
**/
public  class QueueableContractConsolidation implements Queueable,Database.AllowsCallouts{
    public static Integer waitTime=Integer.valueOf(System.Label.QueueableContractConsolidationWaitTime);
    public String ccrName;
    public String action;
    public QueueableContractConsolidation(String action,String ccrName) {
        this.action=action;
        this.ccrName=ccrName;
        
    }
    public void execute(QueueableContext context) {
            System.debug('action===='+this.action+'==');
            System.debug('I am in execute and ccrName Is: '+ccrName);
            GS_SBQQQuoteServiceAsync.asyncContext = 'CopyQuoteFieldsToOppty';
            switch on this.action {
            when 'Quoted UnChecked' {	
                String status='New';
                List<Contract_Consolidation_Request__c> listCCR=[Select Id,CreatedById,Name,Contract__r.AccountId,Error_Message__c,Contract__c,Status__c,Comments__c From Contract_Consolidation_Request__c Where Status__c=:status and Name=:this.ccrName limit 1];
                if(listCCR.size()==1){
                    Contract_Consolidation_Request__c ccr=listCCR[0];
                    try{
                        Boolean shouldCreateQuote = true;
                        
                        // Check if this is Digital Renewal (already has 3 quotes)
                        List<SBQQ__Quote__c> existingDRQuotes = [
                            SELECT Id FROM SBQQ__Quote__c 
                            WHERE SBQQ__Opportunity2__r.SBQQ__RenewedContract__c = :ccr.Contract__c
                            AND Process_Eligibility__c = 'Digital Renewals'
                            LIMIT 1
                        ];
                        
                        if(!existingDRQuotes.isEmpty()) {
                            // Digital Renewal - skip quote creation
                            shouldCreateQuote = false;
                        } else {
                            // Non-DR: Check if renewal opportunity already has a primary quote
                            List<Contract> contractWithRenewalOpp = [SELECT Id, SBQQ__RenewalOpportunity__c, SBQQ__RenewalOpportunity__r.SBQQ__PrimaryQuote__c FROM Contract WHERE Id = :ccr.Contract__c LIMIT 1];
                            
                            if(!contractWithRenewalOpp.isEmpty() && contractWithRenewalOpp[0].SBQQ__RenewalOpportunity__c != null && contractWithRenewalOpp[0].SBQQ__RenewalOpportunity__r.SBQQ__PrimaryQuote__c != null) {
                                shouldCreateQuote = false;
                            }
                        }
                        
                        if(shouldCreateQuote) {
                            Contract c=new Contract(Id=ccr.Contract__c,SBQQ__RenewalQuoted__c=false);
                            update c;
                        }
                        ccr.Status__c='Quoted UnChecked';
                    }
                    catch(Exception ex){
                        ccr.Status__c='Failed';
                        ccr.Comments__c=this.action+'\r\n'+ex.getMessage()+'\r\n'+ex.getStackTraceString();
                         String str1 = ex.getMessage().subStringAfter(';');
                        String errorMessage = str1.subStringBefore('Class.');
                        ccr.Error_Message__c = errorMessage;
                    }
                    update ccr;
                }
                listCCR=[Select Id,CreatedById,Name,Contract__c,Contract__r.AccountId,Status__c,Master_Contract__c,Error_Message__c,CreatedDate From Contract_Consolidation_Request__c Where Name=:this.ccrName];
                System.debug('I am in listCCR: '+listCCR);
                Integer totalNew=0,totalQuotedUnChecked=0,totalFailed=0;
                for(Contract_Consolidation_Request__c ccr:listCCR){
                    if(ccr.Status__c=='New'){
                        totalNew++;
                    }
                    else if(ccr.Status__c=='Quoted UnChecked'){
                        totalQuotedUnChecked++;
                    }    
                    else if(ccr.Status__c=='Failed'){
                        totalFailed++;
                    }                                      
                }
                System.debug('I am in for loop checking the size of the list: '+listCCR.size()+'totalQuotedUnChecked: '+totalQuotedUnChecked);
                if(totalNew>0 && totalFailed==0 && !Test.isRunningTest()){
                   
                    ID jobID = System.enqueueJob(new QueueableContractConsolidation('Quoted UnChecked',this.ccrName),QueueableContractConsolidation.waitTime); 
                   
                }
                
                else if(totalQuotedUnChecked==listCCR.size() && listCCR.size()>0 && !Test.isRunningTest()){
                    
                        ID jobID = System.enqueueJob(new QueueableContractConsolidation('Quoted Checked',this.ccrName),QueueableContractConsolidation.waitTime);
                   
                     
                }
                else if(totalFailed>0 && listCCR.size()>0){
                    Id createdById,targetId;
                    createdById=listCCR[0].CreatedById;
                    targetId=listCCR[0].Contract__r.AccountId;
                    String notificationBody=listCCR[0].Error_Message__c;
                    Set<String> recipientsIds=new Set<String>{createdById};
                    CustomNotificationFromApex.notifyUsers(recipientsIds,targetId,CustomNotificationFromApex.Contract_Consolidation,null,notificationBody);     
                }                
            }	
            when 'Quoted Checked' {		
                String status='Quoted UnChecked';
                List<Contract_Consolidation_Request__c> listCCR=[Select Id,CreatedById,Name,Contract__r.AccountId,Contract__c,Status__c,Comments__c,Master_Contract__c From Contract_Consolidation_Request__c Where Status__c=:status and Name=:this.ccrName limit 1];
                if(listCCR.size()==1){
                    Contract_Consolidation_Request__c ccr=listCCR[0];
                    try{
                        Boolean shouldCreateQuote = true;
                        
                        // Check if this is Digital Renewal (already has 3 quotes)
                        List<SBQQ__Quote__c> existingDRQuotes = [
                            SELECT Id FROM SBQQ__Quote__c 
                            WHERE SBQQ__Opportunity2__r.SBQQ__RenewedContract__c = :ccr.Contract__c
                            AND Process_Eligibility__c = 'Digital Renewals'
                            LIMIT 1
                        ];
                        
                        if(!existingDRQuotes.isEmpty()) {
                            // Digital Renewal - skip quote creation
                            shouldCreateQuote = false;
                        } else {
                            // Non-DR: Check if renewal opportunity already has a primary quote
                            List<Contract> contractWithRenewalOpp = [SELECT Id, SBQQ__RenewalOpportunity__c, SBQQ__RenewalOpportunity__r.SBQQ__PrimaryQuote__c FROM Contract WHERE Id = :ccr.Contract__c LIMIT 1];
                            
                            if(!contractWithRenewalOpp.isEmpty() && contractWithRenewalOpp[0].SBQQ__RenewalOpportunity__c != null && contractWithRenewalOpp[0].SBQQ__RenewalOpportunity__r.SBQQ__PrimaryQuote__c != null) {
                                shouldCreateQuote = false;
                            }
                        }
                        
                        if(shouldCreateQuote) {
                            Contract c=new Contract(Id=ccr.Contract__c,SBQQ__RenewalQuoted__c=true);
                            update c;
                        }
                        
                        ccr.Status__c='Quoted Checked';
                        if(ccr.Master_Contract__c){
                            ccr.Status__c='Completed';
                        }
                    }
                    catch(Exception ex){
                        ccr.Status__c='Failed';
                        ccr.Comments__c=this.action+'\r\n'+ex.getMessage()+'\r\n'+ex.getStackTraceString();
                         String str2 = ex.getMessage().subStringAfter(';');
                        String errorMessageChecked = str2.subStringBefore('Class.');
                        ccr.Error_Message__c = errorMessageChecked;
                    }
                    update ccr;
                }
                listCCR=[Select Id,CreatedById,Name,Contract__r.AccountId,Contract__c,Status__c,Master_Contract__c,Error_Message__c From Contract_Consolidation_Request__c Where Name=:this.ccrName];
                Integer totalQuotedUnChecked=0,totalQuotedChecked=0,totalFailed=0;
                for(Contract_Consolidation_Request__c ccr:listCCR){
                    if(ccr.Status__c=='Quoted UnChecked'){
                        totalQuotedUnChecked++;
                    }
                    else if(ccr.Status__c=='Quoted Checked' || (ccr.Status__c=='Completed' && ccr.Master_Contract__c)){
                        totalQuotedChecked++;
                    }    
                    else if(ccr.Status__c=='Failed'){
                        totalFailed++;
                    }                                      
                }
                if(totalQuotedUnChecked>0 && totalFailed==0 && !Test.isRunningTest()){
                   
                      ID jobID = System.enqueueJob(new QueueableContractConsolidation('Quoted Checked',this.ccrName),QueueableContractConsolidation.waitTime);   
                   
                    
                }
                else if(totalQuotedChecked==listCCR.size() && listCCR.size()>0 && !Test.isRunningTest()){
                    
                     ID jobID = System.enqueueJob(new QueueableContractConsolidation('Consolidate',this.ccrName),QueueableContractConsolidation.waitTime);    
                    
                    
                }
                else if(totalFailed>0 && listCCR.size()>0){
                    Id createdById,targetId;
                    createdById=listCCR[0].CreatedById;
                    targetId=listCCR[0].Contract__r.AccountId;
                    String notificationBody=listCCR[0].Error_Message__c;
                     Set<String> recipientsIds=new Set<String>{createdById};
                    CustomNotificationFromApex.notifyUsers(recipientsIds,targetId,CustomNotificationFromApex.Contract_Consolidation,null,notificationBody);     
                }      
            }
            when 'Consolidate' {		
                /*String status='Quoted Checked';
                List<Contract_Consolidation_Request__c> listCCR=[Select Id,CreatedById,Name,Contract__c,Contract__r.AccountId,Status__c,Comments__c,Master_Contract__c,Contract__r.SBQQ__RenewalOpportunity__c,Contract__r.SBQQ__RenewalOpportunity__r.SBQQ__PrimaryQuote__c From Contract_Consolidation_Request__c Where Status__c=:status and Name=:this.ccrName and Master_Contract__c=false and Contract__r.SBQQ__RenewalOpportunity__c!=null and Contract__r.SBQQ__RenewalOpportunity__r.SBQQ__PrimaryQuote__c!=null limit 1];
                if(listCCR.size()==1){
                    consolidate(listCCR);
                }*/
                List<Contract_Consolidation_Request__c> listCCR=[Select Id,CreatedById,Name,Contract__c,Contract__r.AccountId,Status__c,Error_Message__c,Contract__r.SBQQ__RenewalOpportunity__c,Contract__r.SBQQ__RenewalOpportunity__r.SBQQ__PrimaryQuote__c,Contract__r.SBQQ__RenewalOpportunity__r.of_LIC_Products__c,Master_Contract__c From Contract_Consolidation_Request__c Where Name=:this.ccrName];
               
                
                Integer totalCompleted=0,totalQuotedChecked=0,totalFailed=0,totalWithoutOppQuote=0;
                Id masterQuoteId;
                for(Contract_Consolidation_Request__c ccr:listCCR){
                    if(ccr.Contract__r.SBQQ__RenewalOpportunity__c==null || ccr.Contract__r.SBQQ__RenewalOpportunity__r.SBQQ__PrimaryQuote__c==null || ccr.Contract__r.SBQQ__RenewalOpportunity__r.of_LIC_Products__c==null || ccr.Contract__r.SBQQ__RenewalOpportunity__r.of_LIC_Products__c==0){
                        totalWithoutOppQuote++;
                    }
                    else if(ccr.Status__c=='Completed'){
                        totalCompleted++;
                        if(ccr.Master_Contract__c){
                            masterQuoteId=ccr.Contract__r.SBQQ__RenewalOpportunity__r.SBQQ__PrimaryQuote__c;
                        }
                    }
                    else if(ccr.Status__c=='Quoted Checked'){
                        totalQuotedChecked++;
                    }    
                    else if(ccr.Status__c=='Failed'){
                        totalFailed++;
                        System.debug('totalFailed: '+totalFailed);
                    }                                      
                }
                if(totalWithoutOppQuote>0){
                    Id createdById,targetId;
                    createdById=listCCR[0].CreatedById;
                    targetId=listCCR[0].Contract__r.AccountId;
                    String notificationBody='Contract Renewal/Consolidation failed because no opportunity/quote/license products. Please create a help ticket.';
                    Set<String> recipientsIds=new Set<String>{createdById};
                    CustomNotificationFromApex.notifyUsers(recipientsIds,targetId,CustomNotificationFromApex.Contract_Consolidation,null,notificationBody);   
                }
                else if(totalQuotedChecked>0){
                    String status='Quoted Checked';
                    listCCR=[Select Id,CreatedById,Name,Contract__c,Contract__r.AccountId,Status__c,Error_Message__c,Comments__c,Master_Contract__c,Contract__r.SBQQ__RenewalOpportunity__c,Contract__r.SBQQ__RenewalOpportunity__r.SBQQ__PrimaryQuote__c From Contract_Consolidation_Request__c Where Status__c=:status and Name=:this.ccrName and Master_Contract__c=false and Contract__r.SBQQ__RenewalOpportunity__c!=null and Contract__r.SBQQ__RenewalOpportunity__r.SBQQ__PrimaryQuote__c!=null limit 1];
                    if(listCCR.size()==1 ){
                        if(!Test.isRunningTest()){
                        ID jobID = System.enqueueJob(new QueueableContractConsolidation('Consolidate',this.ccrName),QueueableContractConsolidation.waitTime); 
                        }
                        consolidate(listCCR);
                    }                    
                    //ID jobID = System.enqueueJob(new QueueableContractConsolidation('Consolidate',this.ccrName),QueueableContractConsolidation.waitTime); 
                }
                else if(totalFailed>0 && listCCR.size()>0){
                    Id createdById,targetId;
                    createdById=listCCR[0].CreatedById;
                    targetId=listCCR[0].Contract__r.AccountId;
                    String notificationBody=listCCR[0].Error_Message__c;
                    Set<String> recipientsIds=new Set<String>{createdById};
                    CustomNotificationFromApex.notifyUsers(recipientsIds,targetId,CustomNotificationFromApex.Contract_Consolidation,null,notificationBody);     
                }   
                else if(totalCompleted==listCCR.size() && totalCompleted>0){
                   // SBQQ__Quote__c masterQuote=new SBQQ__Quote__c(Id=masterQuoteId,Recalculate_Quote__c=true);
                   // update masterQuote;
                   // Code added on 06/27/2023
                   PageReference pg = new PageReference('/apex/QueueableContractConsolidationVf');
        		   pg.getParameters().put('Id', masterQuoteId);
                   pg.getParameters().put('RecalculateQuote','false'); 
                   if(!Test.isRunningTest())
                   pg.getContent(); 
                   System.debug('PageReference: '+pg);
                   // Code added on 06/27/2023
                   if(!Test.isRunningTest()){
                        ID jobID = System.enqueueJob(new QueueableContractConsolidation('Recalculate Quote',this.ccrName),QueueableContractConsolidation.waitTime); 
                        }
                    /*Id createdById,targetId;
                    createdById=listCCR[0].CreatedById;
                    targetId=listCCR[0].Contract__r.AccountId;
                    String notificationBody='Contract Renewal/Consolidation completed successfully.';
                    Set<String> recipientsIds=new Set<String>{createdById};
                    CustomNotificationFromApex.notifyUsers(recipientsIds,targetId,CustomNotificationFromApex.Contract_Consolidation,null,notificationBody);     */
                }                
            }
            when 'Recalculate Quote'{
                String masterQuoteId;
              List<Contract_Consolidation_Request__c> listCCR=[Select Id,CreatedById,Name,Contract__c,Contract__r.AccountId,Status__c,Error_Message__c,Contract__r.SBQQ__RenewalOpportunity__c,Contract__r.SBQQ__RenewalOpportunity__r.SBQQ__PrimaryQuote__c,Contract__r.SBQQ__RenewalOpportunity__r.of_LIC_Products__c,Master_Contract__c From Contract_Consolidation_Request__c Where Name=:this.ccrName];
                   for(Contract_Consolidation_Request__c ccr:listCCR){
                     if(ccr.Status__c=='Completed'){
                        if(ccr.Master_Contract__c){
                            masterQuoteId=ccr.Contract__r.SBQQ__RenewalOpportunity__r.SBQQ__PrimaryQuote__c;
                        }
                    }
               }
                
                
                    PageReference pg = new PageReference('/apex/QueueableContractConsolidationVf');
        		   pg.getParameters().put('Id', masterQuoteId);
                   pg.getParameters().put('RecalculateQuote','true'); 
                   if(!Test.isRunningTest())
                   pg.getContent(); 
                
                
                  Id createdById,targetId;
                    createdById=listCCR[0].CreatedById;
                    targetId=listCCR[0].Contract__r.AccountId;
                    String notificationBody='Contract Renewal/Consolidation completed successfully.';
                    Set<String> recipientsIds=new Set<String>{createdById};
                    CustomNotificationFromApex.notifyUsers(recipientsIds,targetId,CustomNotificationFromApex.Contract_Consolidation,null,notificationBody);  
                 if(!Test.isRunningTest()) {
                        ID jobID = System.enqueueJob(new QueueableContractConsolidation('Validate',this.ccrName),QueueableContractConsolidation.waitTime); 
                    }
            }
            when 'Validate'{
                validate(this.ccrName);
            }
        }        
        //ID jobID = System.enqueueJob(new QueueableContractConsolidation('Action',ccrName),waitTime);
    }
    public void consolidate(List<Contract_Consolidation_Request__c> ccrList) {
        if(ccrList!=null && ccrList.size()>0){
            Contract_Consolidation_Request__c ccr=ccrList[0];
            try{
                SBQQ.TriggerControl.disable();
                Contract_Consolidation_Request__c masterCCR=[Select Id,Name,CreatedById,Contract__c From Contract_Consolidation_Request__c Where Name=:ccrList[0].Name AND Master_Contract__c=true];
                String masterContractId=masterCCR.Contract__c;
                String childContractId=ccrList[0].Contract__c;
                Map<Id,Contract> mapContracts=new Map<Id,Contract>([Select Id,Name,CreatedById,SBQQ__RenewalOpportunity__c,StartDate,EndDate, SBQQ__RenewalOpportunity__r.SBQQ__PrimaryQuote__c,Contract_Renewal_ACV__c,SBQQ__Opportunity__c,SBQQ__Opportunity__r.Selected_Payment_Type__c From Contract where Id=:masterContractId OR Id=:childContractId order by Contract_Renewal_ACV__c DESC NULLS LAST]);
                 Id primaryQuoteId=mapContracts.get(masterContractId).SBQQ__RenewalOpportunity__r.SBQQ__PrimaryQuote__c;
                Id primaryOppId=mapContracts.get(masterContractId).SBQQ__RenewalOpportunity__c;
                Contract masterContract=mapContracts.get(masterContractId);
                List<Opportunity> oppsToUpdate=new List<Opportunity>();
                Opportunity masterOpp=new Opportunity(Id=primaryOppId,CloseDate=masterContract.EndDate,License_Start_Date__c=masterContract.EndDate);
                oppsToUpdate.add( masterOpp);
                Set<Id> quoteIDs=new Set<Id>();
                String selectedPaymentType='';
                String fullRecordURL = URL.getSalesforceBaseUrl().toExternalForm() + '/';
                for(Contract c:mapContracts.values()){
                    if(String.isBlank(selectedPaymentType) && c.SBQQ__Opportunity__c!=null && String.isNotBlank(c.SBQQ__Opportunity__r.Selected_Payment_Type__c)){
                        selectedPaymentType=c.SBQQ__Opportunity__r.Selected_Payment_Type__c;
                    }
                    if(c.Id!=masterContractId && c.SBQQ__RenewalOpportunity__c!=primaryOppId){
                        quoteIDs.add(c.SBQQ__RenewalOpportunity__r.SBQQ__PrimaryQuote__c);
                        oppsToUpdate.add(new Opportunity(Id=c.SBQQ__RenewalOpportunity__c,StageName='Closed Lost',Closed_Lost_Reason__c	 = 'Consolidated opportunity',Closed_Lost_Reason_Detail__c='Contract: '+fullRecordURL+masterContract.Id+'\r\nOpportunity:'+fullRecordURL+masterOpp.Id,Closed_Lost_Renewal_Reason__c='Renewal admin issue',Closed_Lost_Renewal_Sub_reason__c='Consolidated renewal',Consolidated_Renewal_Opportunity_Id__c=masterOpp.Id));
                        c.SBQQ__RenewalOpportunity__c=primaryOppId;
                    }
                    if(c.Id!=masterContractId){
                        c.Consolidated_Master_Contract__c=masterContractId;
                    }
                }
                if(String.isNotBlank(selectedPaymentType)){
                    masterOpp.Selected_Payment_Type__c=selectedPaymentType;
                }
                
                update oppsToUpdate;
                update mapContracts.values();
                List<String> reqFields = getFields('SBQQ__QuoteLine__c');
                List<SBQQ__QuoteLine__c> listQL=Database.query('Select '+String.join(reqFields,',')+' From SBQQ__QuoteLine__c Where SBQQ__Quote__c=:quoteIDs ');
                List<SBQQ__QuoteLine__c> listQLNew=new List<SBQQ__QuoteLine__c>();
                for(SBQQ__QuoteLine__c ql:listQL){
                    SBQQ__QuoteLine__c newQL=ql.clone();
                    newQL.SBQQ__Quote__c=primaryQuoteId;
                    newQL.Previous_Quantity__c=ql.SBQQ__Quantity__c;
                            listQLNew.add(newQL);
                }
                insert listQLNew;   
                ccr.Status__c='Completed';    
            }
            catch(Exception ex){
                ccr.Status__c='Failed';
                ccr.Comments__c=this.action+'\r\n'+ex.getMessage()+'\r\n'+ex.getStackTraceString();
                String str3 = ex.getMessage().subStringAfter(';');
                String errorMessageCompleted = str3.subStringBefore('Class.');
                ccr.Error_Message__c = errorMessageCompleted;
            }                         
            update ccr;         
        }

    } 

	    public void validate(String ccrName) {
            // Get all contracts for this consolidation request
            
            List<Contract_Consolidation_Request__c> listCCR = [
            SELECT Id, CreatedById, Name, Contract__c, Contract__r.AccountId, 
            Contract__r.Deactivated__c,
                   Contract__r.SBQQ__RenewalOpportunity__c, Contract__r.SBQQ__RenewalOpportunity__r.SBQQ__PrimaryQuote__c,
                   Contract__r.SBQQ__RenewalOpportunity__r.StageName, Contract__r.SBQQ__RenewalOpportunity__r.IsClosed, 
                   Contract__r.SBQQ__RenewalOpportunity__r.IsWon, Contract__r.SBQQ__RenewalOpportunity__r.of_LIC_Products__c,
                   Status__c, Error_Message__c, Comments__c, Master_Contract__c
            FROM Contract_Consolidation_Request__c 
            WHERE Name = :ccrName
        ];
        if(listCCR.isEmpty()) {
            System.debug('No Contract Consolidation Requests found for name: ' + ccrName);
            return;
        }
        
        // Group contracts by AccountId
        Map<String, List<Contract_Consolidation_Request__c>> accountContractMap = new Map<String, List<Contract_Consolidation_Request__c>>();
        for(Contract_Consolidation_Request__c ccr : listCCR) {
            String accountId = ccr.Contract__r.AccountId;
            if(!accountContractMap.containsKey(accountId)) {
                accountContractMap.put(accountId, new List<Contract_Consolidation_Request__c>());
            }
            accountContractMap.get(accountId).add(ccr);
        }
        
        System.debug('accountContractMap---'+accountContractMap);
        
        // Collect all contract IDs for bulk queries
        // IMPORTANT: If we're consolidating a contract that was previously consolidated,
        // we need to include ALL contracts from the previous consolidation(s) in our validation.
        // Example: C1 was consolidated with C2+C3. Now consolidating C1+C4.
        // Master quote has lines from C1+C2+C3+C4, so we must validate against all 4 contracts' subscriptions.
        Set<Id> allContractIds = new Set<Id>();
        for(Contract_Consolidation_Request__c ccr : listCCR) {
            allContractIds.add(ccr.Contract__c);
        }
        
        // Check if any contracts in the current group were previously consolidated
        // If so, we need to include those previously consolidated contracts in our validation
        List<Contract_Consolidation_Request__c> previousConsolidations = [
            SELECT Id, Name, Contract__c, Master_Contract__c
            FROM Contract_Consolidation_Request__c
            WHERE Contract__c IN :allContractIds
            AND Master_Contract__c = true
            AND Name != :ccrName
        ];
        
        if(!previousConsolidations.isEmpty()) {
            System.debug('Found previously consolidated contracts: ' + previousConsolidations.size());
            
            // Get all contract IDs from previous consolidation groups
            Set<String> previousCCRNames = new Set<String>();
            for(Contract_Consolidation_Request__c prevCCR : previousConsolidations) {
                previousCCRNames.add(prevCCR.Name);
            }
            
            // Fetch all contracts from previous consolidation groups
            List<Contract_Consolidation_Request__c> allPreviousCCRs = [
                SELECT Id, Contract__c, Master_Contract__c
                FROM Contract_Consolidation_Request__c
                WHERE Name IN :previousCCRNames
            ];
            
            // Add all previously consolidated contract IDs
            for(Contract_Consolidation_Request__c prevCCR : allPreviousCCRs) {
                allContractIds.add(prevCCR.Contract__c);
            }
            
            System.debug('Total contract IDs including previous consolidations: ' + allContractIds.size());
        }
        
        System.debug('allContractIds'+allContractIds);
        Map<Id, Contract> contractMap ;
        // Bulk query all contracts with their renewal opportunity and quote information
        if(Test.isRunningTest()){
			contractMap = new Map<Id, Contract>([
            SELECT Id, SBQQ__RenewalOpportunity__c, SBQQ__RenewalOpportunity__r.SBQQ__PrimaryQuote__c,
                   SBQQ__RenewalOpportunity__r.StageName, SBQQ__RenewalOpportunity__r.IsClosed, SBQQ__RenewalOpportunity__r.IsWon,
                   EndDate, Contract_Renewable_ACV_USD__c
            FROM Contract
            WHERE Id IN :allContractIds 
        ]);            
        } else {
         contractMap = new Map<Id, Contract>([
            SELECT Id, SBQQ__RenewalOpportunity__c, SBQQ__RenewalOpportunity__r.SBQQ__PrimaryQuote__c,
                   SBQQ__RenewalOpportunity__r.StageName, SBQQ__RenewalOpportunity__r.IsClosed, SBQQ__RenewalOpportunity__r.IsWon,
                   EndDate, Contract_Renewable_ACV_USD__c
            FROM Contract
            WHERE Id IN :allContractIds AND Deactivated__c = false
        ]);
        
        System.debug('contractMap'+ contractMap);
        }
        
        // Update Available_TO_Renew__c on master opportunity after consolidation is complete
        updateAvailableToRenewOnMasterOpportunity(listCCR, contractMap);
        
        // Query previous opportunities for contracts
        Map<Id, List<Opportunity>> contractOpportunitiesMap = new Map<Id, List<Opportunity>>();
        for(Opportunity opp : [
            SELECT Id, StageName, IsClosed, IsWon, SBQQ__RenewedContract__c
            FROM Opportunity
            WHERE SBQQ__RenewedContract__c IN :allContractIds
            ORDER BY CreatedDate DESC
        ]) {
            if(!contractOpportunitiesMap.containsKey(opp.SBQQ__RenewedContract__c)) {
                contractOpportunitiesMap.put(opp.SBQQ__RenewedContract__c, new List<Opportunity>());
            }
            contractOpportunitiesMap.get(opp.SBQQ__RenewedContract__c).add(opp);
        }
        
        // Query opportunity products for master contract renewal opportunities
        Map<Id, List<OpportunityLineItem>> masterOpportunityProductsMap = new Map<Id, List<OpportunityLineItem>>();

        if(Test.isRunningTest()){
            for(OpportunityLineItem oli : [
            SELECT Id, OpportunityId, Product2Id, Quantity, TotalPrice,
                   Product2.Name, Product2.SBQQ__RenewalProduct__c
            FROM OpportunityLineItem
            WHERE OpportunityId IN (
                SELECT SBQQ__RenewalOpportunity__c
                FROM Contract
                WHERE Id IN :allContractIds
                AND SBQQ__RenewalOpportunity__c != null
            )
        ]) {
            if(!masterOpportunityProductsMap.containsKey(oli.OpportunityId)) {
                masterOpportunityProductsMap.put(oli.OpportunityId, new List<OpportunityLineItem>());
            }
            masterOpportunityProductsMap.get(oli.OpportunityId).add(oli);
        }
        }else{
        for(OpportunityLineItem oli : [
            SELECT Id, OpportunityId, Product2Id, Quantity, TotalPrice,
                   Product2.Name, Product2.SBQQ__RenewalProduct__c
            FROM OpportunityLineItem
            WHERE OpportunityId IN (
                SELECT SBQQ__RenewalOpportunity__c
                FROM Contract
                WHERE Id IN :allContractIds
                AND SBQQ__RenewalOpportunity__c != null AND Deactivated__c = false
            )
        ]) {
            if(!masterOpportunityProductsMap.containsKey(oli.OpportunityId)) {
                masterOpportunityProductsMap.put(oli.OpportunityId, new List<OpportunityLineItem>());
            }
            masterOpportunityProductsMap.get(oli.OpportunityId).add(oli);
        }
    }
        // Bulk query all subscriptions with their products
        Map<Id, List<SBQQ__Subscription__c>> contractSubscriptionsMap = new Map<Id, List<SBQQ__Subscription__c>>();
        for(SBQQ__Subscription__c sub : [
            SELECT Id, SBQQ__Contract__c, SBQQ__Product__c, SBQQ__Quantity__c,
                   SBQQ__Product__r.SBQQ__RenewalProduct__c, SBQQ__Product__r.SBQQ__RenewalProduct__r.Id
            FROM SBQQ__Subscription__c
            WHERE SBQQ__Contract__c IN :allContractIds
        ]) {
            if(!contractSubscriptionsMap.containsKey(sub.SBQQ__Contract__c)) {
                contractSubscriptionsMap.put(sub.SBQQ__Contract__c, new List<SBQQ__Subscription__c>());
            }
            contractSubscriptionsMap.get(sub.SBQQ__Contract__c).add(sub);
        }
        
        // Collect all quote IDs for bulk query
        Set<Id> quoteIds = new Set<Id>();
        for(Contract c : contractMap.values()) {
            if(c.SBQQ__RenewalOpportunity__c != null && c.SBQQ__RenewalOpportunity__r.SBQQ__PrimaryQuote__c != null) {
                quoteIds.add(c.SBQQ__RenewalOpportunity__r.SBQQ__PrimaryQuote__c);
            }
        }
        
        // Bulk query all quote lines
        Map<Id, List<SBQQ__QuoteLine__c>> quoteLinesMap = new Map<Id, List<SBQQ__QuoteLine__c>>();
        for(SBQQ__QuoteLine__c ql : [
            SELECT Id, SBQQ__Quote__c, SBQQ__Product__c, SBQQ__Quantity__c
            FROM SBQQ__QuoteLine__c
            WHERE SBQQ__Quote__c IN :quoteIds
        ]) {
            if(!quoteLinesMap.containsKey(ql.SBQQ__Quote__c)) {
                quoteLinesMap.put(ql.SBQQ__Quote__c, new List<SBQQ__QuoteLine__c>());
            }
            quoteLinesMap.get(ql.SBQQ__Quote__c).add(ql);
        }
        
        // Process each account's contracts
        for(String accountId : accountContractMap.keySet()) {
            List<Contract_Consolidation_Request__c> contracts = accountContractMap.get(accountId);
            Date highestDate = Date.newInstance(1900, 1, 1);
            Contract_Consolidation_Request__c masterContract;
            
            // Find the master contract (the one with Master_Contract__c = true)
            for(Contract_Consolidation_Request__c contract : contracts) {
                if(contract.Master_Contract__c) {
                    masterContract = contract;
                    break;
                }
            }
            
            // If no master contract found, find the one with highest end date
            if(masterContract == null) {
                for(Contract_Consolidation_Request__c contract : contracts) {
                    Contract contractRecord = contractMap.get(contract.Contract__c);
                    if(contractRecord != null && contractRecord.EndDate > highestDate) {
                        highestDate = contractRecord.EndDate;
                        masterContract = contract;
                    }
                }
            }
            
            // Initialize error collection
            List<String> accountErrors = new List<String>();
            
            // Get master contract's renewal opportunity
            Contract masterContractRecord = null;
            Id masterRenewalOppId = null;
            if(masterContract != null) {
                masterContractRecord = contractMap.get(masterContract.Contract__c);
                masterRenewalOppId = masterContractRecord != null ? masterContractRecord.SBQQ__RenewalOpportunity__c : null;
            }
            
            // Check renewal opportunities for child contracts
            for(Contract_Consolidation_Request__c childContract : contracts) {
                if(!childContract.Master_Contract__c) {
                    Contract childContractRecord = contractMap.get(childContract.Contract__c);
                    Id childRenewalOppId = childContractRecord != null ? childContractRecord.SBQQ__RenewalOpportunity__c : null;
                    
                    if(masterRenewalOppId != null && childRenewalOppId != null) {
                        if(masterRenewalOppId != childRenewalOppId) {
                            // Check if child contract's previous renewal opportunity is Closed Lost
                            List<Opportunity> childOpportunities = contractOpportunitiesMap.get(childContract.Contract__c);
                            if(childOpportunities != null && !childOpportunities.isEmpty()) {
                                Opportunity previousRenewalOpp = childOpportunities[0];
                                
                                if(!(previousRenewalOpp.IsClosed && !previousRenewalOpp.IsWon)) {
                                    accountErrors.add('Child Contract ' + childContract.Contract__c +
                                                   ': Previous renewal opportunity is not marked as Closed Lost. ' +
                                                   'Current Stage: ' + previousRenewalOpp.StageName);
                                }
                            } else {
                                accountErrors.add('Child Contract ' + childContract.Contract__c +
                                               ': No previous renewal opportunity found');
                            }
                        }
                    } else {
                        accountErrors.add('Child Contract ' + childContract.Contract__c +
                                       ': Missing renewal opportunity');
                    }
                }
            }
            
            // Get master contract's quote lines
            List<SBQQ__QuoteLine__c> masterQuoteLines = new List<SBQQ__QuoteLine__c>();
            if(masterContractRecord != null &&
               masterContractRecord.SBQQ__RenewalOpportunity__c != null &&
               masterContractRecord.SBQQ__RenewalOpportunity__r.SBQQ__PrimaryQuote__c != null) {
                masterQuoteLines = quoteLinesMap.get(masterContractRecord.SBQQ__RenewalOpportunity__r.SBQQ__PrimaryQuote__c);
            }
            
            // Get subscriptions from all contracts in allContractIds (which already includes previously consolidated contracts)
            // This ensures we validate against ALL subscriptions that should be in the master quote
            List<SBQQ__Subscription__c> childSubscriptions = new List<SBQQ__Subscription__c>();
            for(Id contractId : allContractIds) {
                if(contractSubscriptionsMap.containsKey(contractId)) {
                    childSubscriptions.addAll(contractSubscriptionsMap.get(contractId));
                }
            }
            
            System.debug('Total subscriptions for validation: ' + childSubscriptions.size());
            
            // Compare product distribution
            Map<Id, Decimal> childProductQuantity = new Map<Id, Decimal>();
            Map<Id, Decimal> masterProductQuantity = new Map<Id, Decimal>();
            
            for(SBQQ__Subscription__c sub : childSubscriptions) {
                Id productId = sub.SBQQ__Product__c;
                // If the product has a renewal product, use the renewal product ID for comparison
                if(sub.SBQQ__Product__r.SBQQ__RenewalProduct__c != null) {
                    productId = sub.SBQQ__Product__r.SBQQ__RenewalProduct__c;
                }
                
                if(!childProductQuantity.containsKey(productId)) {
                    childProductQuantity.put(productId, 0);
                }
                childProductQuantity.put(productId,
                    childProductQuantity.get(productId) + (sub.SBQQ__Quantity__c != null ? sub.SBQQ__Quantity__c : 0));
            }
            
            if(masterQuoteLines != null) {
                for(SBQQ__QuoteLine__c ql : masterQuoteLines) {
                    if(!masterProductQuantity.containsKey(ql.SBQQ__Product__c)) {
                        masterProductQuantity.put(ql.SBQQ__Product__c, 0);
                    }
                    masterProductQuantity.put(ql.SBQQ__Product__c,
                        masterProductQuantity.get(ql.SBQQ__Product__c) + (ql.SBQQ__Quantity__c != null ? ql.SBQQ__Quantity__c : 0));
                }
            }
            
            // Compare quantities and identify discrepancies 
            Set<Id> allProducts = new Set<Id>();
            allProducts.addAll(childProductQuantity.keySet());
            allProducts.addAll(masterProductQuantity.keySet());
            
            for(Id productId : allProducts) {
                Decimal childQty = childProductQuantity.get(productId) != null ? childProductQuantity.get(productId) : 0;
                Decimal masterQty = masterProductQuantity.get(productId) != null ? masterProductQuantity.get(productId) : 0;
                if(childQty != masterQty) {
                    accountErrors.add('Product ' + productId +
                                   ': Quantity mismatch - Total Subscriptions Quantity: ' + childQty +
                                   ', Master Quote Line Quantity: ' + masterQty);
                }
            }
            
            // Validate master contract opportunity products sync with quote lines
            if(masterContract != null && masterContract.Master_Contract__c) {
                System.debug('MasterContract:--'+ masterContract);
                masterContractRecord = contractMap.get(masterContract.Contract__c);
                System.debug('masterContractRecord----'+ masterContractRecord);
                System.debug('masterContractRenewalOpportunity---'+masterContractRecord.SBQQ__RenewalOpportunity__c);
                if(masterContractRecord != null && masterContractRecord.SBQQ__RenewalOpportunity__c != null) {
                    
                    masterRenewalOppId = masterContractRecord.SBQQ__RenewalOpportunity__c;
                    System.debug('masterRenewalOppId:::'+masterRenewalOppId);
                    System.debug('masterOpportunityProductsMap'+masterOpportunityProductsMap);
                    List<OpportunityLineItem> masterOppProducts = masterOpportunityProductsMap.get(masterRenewalOppId);
                    System.debug('masterOppProducts'+ masterOppProducts);
                    
                    if(masterOppProducts != null && !masterOppProducts.isEmpty()) {
                        // Compare quote lines with opportunity products
                        Map<Id, Decimal> quoteProductQuantity2 = new Map<Id, Decimal>();
                        Map<Id, Decimal> oppProductQuantity2 = new Map<Id, Decimal>();
                        Map<Id, String> productNames2 = new Map<Id, String>();
                        
                        // Process quote lines
                        if(masterQuoteLines != null) {
                            for(SBQQ__QuoteLine__c ql : masterQuoteLines) {
                                Id productId = ql.SBQQ__Product__c;
                                if(!quoteProductQuantity2.containsKey(productId)) {
                                    quoteProductQuantity2.put(productId, 0);
                                }
                                quoteProductQuantity2.put(productId,
                                    quoteProductQuantity2.get(productId) + (ql.SBQQ__Quantity__c != null ? ql.SBQQ__Quantity__c : 0));
                            }
                        }
                        
                        // Process opportunity products
                        for(OpportunityLineItem oli : masterOppProducts) {
                            Id productId = oli.Product2Id;
                            
                            if(!oppProductQuantity2.containsKey(productId)) {
                                oppProductQuantity2.put(productId, 0);
                            }
                            oppProductQuantity2.put(productId,
                                oppProductQuantity2.get(productId) + (oli.Quantity != null ? oli.Quantity : 0));
                            
                            productNames2.put(productId, oli.Product2.Name);
                        }
                        
                        // Compare quantities and identify discrepancies
                        Set<Id> allProducts2 = new Set<Id>();
                        allProducts2.addAll(quoteProductQuantity2.keySet());
                        allProducts2.addAll(oppProductQuantity2.keySet());
                        
                        for(Id productId : allProducts2) {
                            Decimal quoteQty = quoteProductQuantity2.get(productId) != null ? quoteProductQuantity2.get(productId) : 0;
                            Decimal oppQty = oppProductQuantity2.get(productId) != null ? oppProductQuantity2.get(productId) : 0;
                            
                            if(quoteQty != oppQty) {
                                String productName = productNames2.get(productId);
                                accountErrors.add('Master Contract Product Sync Issue - ' + productName +
                                               ': Quote Quantity: ' + quoteQty +
                                               ', Opportunity Quantity: ' + oppQty +
                                               ', Difference: ' + (oppQty - quoteQty));
                            }
                        }
                        
                        // Check for missing products
                        for(Id quoteProductId : quoteProductQuantity2.keySet()) {
                            if(!oppProductQuantity2.containsKey(quoteProductId)) {
                                String productName = productNames2.get(quoteProductId);
                                accountErrors.add('Master Contract Product Missing in Opportunity - ' + productName +
                                               ': Quote Quantity: ' + quoteProductQuantity2.get(quoteProductId));
                            }
                        }
                        
                        for(Id oppProductId : oppProductQuantity2.keySet()) {
                            if(!quoteProductQuantity2.containsKey(oppProductId)) {
                                String productName = productNames2.get(oppProductId);
                                accountErrors.add('Master Contract Extra Product in Opportunity - ' + productName +
                                               ': Opportunity Quantity: ' + oppProductQuantity2.get(oppProductId));
                            }
                        }
                    } else {
                        accountErrors.add('No opportunity products found for master contract renewal opportunity');
                    }
                }
            }
            
            // Update CCR records with validation results
            for(Contract_Consolidation_Request__c ccr : contracts) {
                if(!accountErrors.isEmpty()) {
                    ccr.Status__c = 'Failed';
                    ccr.Error_Message__c = String.join(accountErrors, '\n');
                    ccr.Comments__c = 'Validation failed: ' + String.join(accountErrors, '\n');
                } else {
                    ccr.Status__c = 'Validated';
                    ccr.Comments__c = 'Validation completed successfully';
                }
            }
            
            // Display validation results
            if(!accountErrors.isEmpty()) {
                System.debug('=== Validation Errors for Account ' + accountId + ' ===');
                for(String error : accountErrors) {
                    System.debug(error);
                }
                System.debug('=====================================');
            } else {
                System.debug('No validation errors found for Account ' + accountId);
            }
        }
        
        // Update all CCR records
        update listCCR;
        
        // Send notification if there are validation errors
        List<Contract_Consolidation_Request__c> failedCCRs = [
            SELECT Id, CreatedById, Contract__r.AccountId, Error_Message__c 
            FROM Contract_Consolidation_Request__c 
            WHERE Name = :ccrName AND Status__c = 'Failed'
        ];
        
        if(!failedCCRs.isEmpty()) {
            Id createdById = failedCCRs[0].CreatedById;
            Id targetId = failedCCRs[0].Contract__r.AccountId;
            String notificationBody = failedCCRs[0].Error_Message__c;
            Set<String> recipientsIds = new Set<String>{createdById};
            CustomNotificationFromApex.notifyUsers(recipientsIds, targetId, CustomNotificationFromApex.Contract_Consolidation, null, notificationBody);
        }
    }    
    public static List<string> getFields(String selectedObject)
    {
        List<String> reqFields = new List<String>();
        Map <String,Schema.SObjectType> gd = Schema.getGlobalDescribe();
        Schema.SObjectType sobjType = gd.get(selectedObject);
        Schema.DescribeSObjectResult r = sobjType.getDescribe();
        Map<String, Schema.SObjectField> MapofField = r.fields.getMap();
        for(String fieldName : MapofField.keySet()) {
            
            Schema.SObjectField field = MapofField.get(fieldName);
            Schema.DescribeFieldResult F = field.getDescribe();
            if(F.isAccessible()){
                reqFields.add(fieldName);
            }
        }
        System.debug(reqFields);
        return reqFields;
    } 
    
	/**
     * Updates Available_TO_Renew__c field on master opportunity with sum of Contract_Renewal_ACV__c
     * from all consolidated contracts (master + child contracts)
     * Note: contractMap already includes previously consolidated contracts (populated by validate method)
     */
    private void updateAvailableToRenewOnMasterOpportunity(List<Contract_Consolidation_Request__c> listCCR, Map<Id, Contract> contractMap) {
        try {
            // Find the master contract and its renewal opportunity
            Contract_Consolidation_Request__c masterCCR = null;
            for(Contract_Consolidation_Request__c ccr : listCCR) {
                if(ccr.Master_Contract__c) {
                    masterCCR = ccr;
                    break;
                }
            }
            
            if(masterCCR == null) {
                return;
            }
            
            Contract masterContract = contractMap.get(masterCCR.Contract__c);
            if(masterContract == null || masterContract.SBQQ__RenewalOpportunity__c == null) {
                return;
            }
            
            // Calculate total renewable ACV from all contracts in contractMap
            // The contractMap already contains all contracts including previously consolidated ones
            Decimal totalRenewableACV = 0;
            for(Contract contract : contractMap.values()) {
                if(contract.Contract_Renewable_ACV_USD__c != null) {
                    totalRenewableACV += contract.Contract_Renewable_ACV_USD__c;
                }
            }
            
            System.debug('Total Renewable ACV for master opportunity: ' + totalRenewableACV);
            
            // Update master opportunity with calculated Available_TO_Renew__c
            if(totalRenewableACV > 0) {
                Opportunity masterOppToUpdate = new Opportunity(
                    Id = masterContract.SBQQ__RenewalOpportunity__c,
                    Available_TO_Renew__c = totalRenewableACV
                );
                update masterOppToUpdate;
            }
            
        } catch(Exception ex) {
            System.debug('Error in updateAvailableToRenewOnMasterOpportunity: ' + ex.getMessage());
        }
    }        
}