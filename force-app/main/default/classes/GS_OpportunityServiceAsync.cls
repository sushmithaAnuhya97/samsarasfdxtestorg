public with sharing class GS_OpportunityServiceAsync extends BaseAsyncHandler {
    gslib_IModuleLogger thisModuleLogger = gslib_LoggerService.getModuleLogger('GTMS');
    gslib_ILogger thisLogger = thisModuleLogger.getLogger(); 

    @TestVisible private String RebateTypeFormulaTestOverride;

    public override String getRequestType(){
        return 'Opportunity Service Async Job';
    } 
    
    List<Schema.SObjectType> MY_SOBJECTS = new List<Schema.SObjectType>{
        Clari_Opp__c.SOBjectType,
        Opportunity.SObjectType,
        Account.SObjectType,
        Contact.SObjectType,
        OpportunityTeamMember.SObjectType,
        OpportunityLineItem.SObjectType,
        ADR_Transfer_Log__c.SOBjectType
    };
    
    UnitOfWork uow;
    List<Id> recordsIds;
    List<Opportunity> oppList;
    Map<Id,ConsolidatedProcessAsyncConditions> conditionMap;
    
    public override void execute(Async_Request__c ar){

        recordsIds = ar.Params__c.split(PARAMETERS_SPLITTER);
        if(recordsIds.isEmpty()) return;
        Options opt = (Options) JSON.deserialize(ar.Options__c, Options.class);
        conditionMap = (opt.conditionMap != null ? opt.conditionMap : new Map<Id,ConsolidatedProcessAsyncConditions>());

        DMLWrapper.intializeUnitOfWork(MY_SOBJECTS);
        
        switch on opt.Operation {
            when 'AFTER_INSERT_OPERATIONS' {	
                this.loadOpportunities(recordsIds);

                this.afterInsertOperations();
                this.opptyConsolidatedProcesses();
            }
            when 'AFTER_UPDATE_OPERATIONS' {	
                this.loadOpportunities(recordsIds);
                this.opptyConsolidatedProcesses();
            }

        }

        this.publishDMLs();
    }

    private void loadOpportunities(List<Id> idList){
        if (oppList == null){
            this.oppList = (new GS_OpportunitySelector(false)).loadOpportunityWithItems(new Set<Id>(idList));
        }
    }

    private void afterInsertOperations(){
        Map<Id, Id> relatedOppToOppIdMap = new Map<Id, Id>();
        Map<Id, Account> oppAccountsMap = new Map<Id, Account>(this.loadRelatedAccountsFromOpportunity(this.oppList));

        for (Opportunity opp : this.oppList){
            System.debug('==== Service Async: '+opp.Type);
            if((opp.type == 'Free Trial Opportunity') && (opp.TrialResolutionOppty__c != null)){
                relatedOppToOppIdMap.put(opp.TrialResolutionOppty__c, opp.Id);
            }
            else if((opp.type == 'Rebate' || opp.type == 'Remorse Refund') && (opp.Returning_Opportunity__c != null)){
                relatedOppToOppIdMap.put(opp.Returning_Opportunity__c, opp.Id);
            }  
            
            // Groundswell : Tanuj - WFlow Rule - Update Account for NS Sync
            // Start
            Account thisOppAccount = new Account();
            if (opp.AccountId != NULL && oppAccountsMap.containsKey(opp.AccountId)) {
                thisOppAccount = oppAccountsMap.get(opp.AccountId);
                OpportunityWorkflowConversion.afterInsertUpdateMethod(opp, null, thisOppAccount);
            }
            // End
        }

        (new GS_ClariOppService()).createClariOpp(this.oppList);
        
        System.debug('RelatedOppIdMap is empty: '+relatedOppToOppIdMap.isEmpty());
        if(!relatedOppToOppIdMap.isEmpty()){
            (new GS_OpportunityTeamMemberServiceAsync()).createOpportunityTeams(relatedOppToOppIdMap);
        }

    }

    private List<Account> loadRelatedAccountsFromOpportunity(List<Opportunity> oppList){
        List<Id> accountIdList = new List<Id>();
        for (Opportunity opp : oppList){
            if (opp.AccountId != null) accountIdList.add(opp.Id);
        }

        return (accountIdList.size() > 0 ? (new GS_AccountSelector(false)).getAccountsWithOppAndShipAddrByIds(accountIdList) : new List<Account>());
    }
    
    // Replaces: Oppty: Consolidated Processes
    public void opptyConsolidatedProcesses(){
        Map<Id, OpportunityLineItem> lineItemsToUpdate = new Map<Id, OpportunityLineItem>();
        Map<Id, Contact> contactsToUpdate = new Map<Id, Contact>();

        // query orgWideEmailAddresses for from argument in sendEmail methods
        OrgWideEmailAddress noReplyEmail = Utility.getOrgWideEmailAddressBasedOnAddress('no-reply@samsara.com');//[SELECT Id, Address FROM OrgWideEmailAddress WHERE Address = 'no-reply@samsara.com' LIMIT 1]; 
        OrgWideEmailAddress financeEmail = Utility.getOrgWideEmailAddressBasedOnAddress('finance@samsara.com');//[SELECT Id, Address FROM OrgWideEmailAddress WHERE Address = 'finance@samsara.com' LIMIT 1]; 
        OrgWideEmailAddress noreply      = Utility.getOrgWideEmailAddressBasedOnAddress('no-reply@samsara.com');//[SELECT Id, Address FROM OrgWideEmailAddress WHERE Address = 'no-reply@samsara.com' LIMIT 1];
        
        //List<Opportunity> queriedOpportunities = OpportunityHelper.queryOpportunities(newOpptyMap.keySet()).values();

        for(Opportunity oppty : this.oppList){
            ConsolidatedProcessAsyncConditions recordConditions = this.conditionMap.get(oppty.Id);

            // Condition 1 ====
            //if(oppty.Shipping_Address_NEW__c != null && isChanged(oppty, oldOpp, Schema.Opportunity.Shipping_Address_NEW__c)){
            if (recordConditions != null && recordConditions.c1){
                (new GS_OpportunityToLineItemUpdateAsync()).updateShipToToMatchAddressFromOpportunity(oppty);
            }

            if(oppty.StageName == 'Closing'){
                if(oppty.RecordType.Name == 'Industrial Opportunity'){
                    /* Replaces Node 'HM Opp Closing' */
                    this.sendEmail(oppty, Id.valueOf('00X1a000000dkU0'), new List<String>{System.Label.Industrial_Opp_Closing_Email}, noReplyEmail);
                }               
            }

            String opptyRebateTypeFormula = (Test.isRunningTest() && String.isNotBlank(RebateTypeFormulaTestOverride) ? RebateTypeFormulaTestOverride : oppty.Rebate_Type_Formula__c);
            if(opptyRebateTypeFormula != null){
                Opportunity returningOpp = new Opportunity();
                switch on opptyRebateTypeFormula {
                    when 'Buyout' {
                        /* Replaces Node 'Buyout opp created' */
                        returningOpp.Id = oppty.Returning_Opportunity__c;
                        returningOpp.Buyout_Opportunity__c = oppty.Id;
                        DMLWrapper.doUpdate(returningOpp, new List<SobjectField>{
                            Opportunity.Buyout_Opportunity__c
                        });
                        //System.debug('OpportunityProcessBuilderConversion - Running Node: Buyout opp created');
                    }
                    when 'Subsidy' {
                        /* Replaces Node 'Subsidy opp created' */
                        returningOpp.Id = oppty.Returning_Opportunity__c;
                        returningOpp.Subsidy_Opportunity__c = oppty.Id;
                        DMLWrapper.doUpdate(returningOpp, new List<SobjectField>{
                            Opportunity.Subsidy_Opportunity__c
                        });
                        //System.debug('OpportunityProcessBuilderConversion - Running Node: Subsidy opp created');
                    }
                    when 'Partner Referral' {
                        /* Replaces Node 'Partner Referral opp created' */
                        returningOpp.Id = oppty.Returning_Opportunity__c;
                        returningOpp.Partner_Referral_Opportunity__c = oppty.Id;
                        DMLWrapper.doUpdate(returningOpp, new List<SobjectField>{
                            Opportunity.Partner_Referral_Opportunity__c
                        });
                        //System.debug('OpportunityProcessBuilderConversion - Running Node: Partner Referral opp created');
                    }
                }
            }

            if(oppty.Resend_Return_Email__c){
                /* Replaces Node 'Resend Return Email Checked' */
                oppty.Resend_Return_Email__c = false;
                DMLWrapper.doUpdate(oppty, new List<SObjectField>{Opportunity.Resend_Return_Email__c});
                //System.debug('OpportunityProcessBuilderConversion - Running Node: Resend Return Email Checked');
            }

            // TODO: License_Term__c
            // Condition 2 ====
            if(recordConditions != null && recordConditions.c2){
                /* Replaces Node 'License Term Changes' */
                for(OpportunityLineItem oli : oppty.OpportunityLineItems){
                    oli.License_Term_Copy__c = oppty.License_Term__c;
                    DMLWrapper.doUpdate(oli, new List<SObjectField>{OpportunityLineItem.License_Term_Copy__c});
                    //System.debug('OpportunityProcessBuilderConversion - Running Node: License Term Changes');
                }
            }

            if(oppty.Trial_Primary_Contact__c != null && !oppty.Trial_Primary_Contact__r.Trial_Deactivation_Email__c){
                /* Replaces Node 'Trial Contact Deactivation Email' */
                oppty.Trial_Primary_Contact__r.Trial_Deactivation_Email__c = true;
                contactsToUpdate.put(oppty.Trial_Primary_Contact__c, oppty.Trial_Primary_Contact__r);
                //System.debug('OpportunityProcessBuilderConversion - Running Node: Trial Contact Deactivation Email');
            }

            // Condition 3 =====
            if(recordConditions != null && recordConditions.c3){
                /* Replaces Node 'Closed Won Amount Change' */
                //System.debug('OpportunityProcessBuilderConversion - Running Node: Closed Won Amount Change');
                this.sendEmail(oppty, Id.valueOf('00X1P0000015xqz'), new List<String> {System.Label.SFDC_Pool_Email}, financeEmail);
            }
            
            List<String> closedWonErrorEmailList = System.Label.Closed_Opp_Error_Emails.split(',');
            // Condition 4 =====
            if(recordConditions != null && recordConditions.c4){
                this.sendEmail(oppty, Id.valueOf(system.label.Closed_Won_Opp_Stage_Change_Email_Template ), closedWonErrorEmailList, noreply);
            }
        }

        if(!contactsToUpdate.isEmpty()){
            //update contactsToUpdate.values();
            DMLWrapper.doUpdate(contactsToUpdate.values());
        }

        (new GS_ADRTransferService()).updateTransferLog(this.oppList);
    }

    // Condition 1
    private Boolean hasShippingAddressAndIsChanged(Opportunity oldOpp, Opportunity opp){
        return opp.Shipping_Address_NEW__c != null && HelperClass.isChanged(opp, oldOpp, Schema.Opportunity.Shipping_Address_NEW__c);
    }

    // Condition 2
    private Boolean hasLicenseTermChanged(Opportunity oldOpp, Opportunity opp){
        return HelperClass.isChanged(opp, oldOpp, Schema.Opportunity.License_Term__c);
    }

    // Condition 3
    private Boolean isWonAndHasChangedAmountOrClosedDate(Opportunity oldOpp, Opportunity opp){
        return opp.IsWon
            && oldOpp != null
            && oldOpp.StageName == 'Closed Won'
            && (HelperClass.isChanged(opp, oldOpp, Schema.Opportunity.Amount)
                || HelperClass.isChanged(opp, oldOpp, Schema.Opportunity.CloseDate));
    }

    // Condition 4
    private Boolean wasWonAndHasChangedAmountOrStage(Opportunity oldOpp, Opportunity opp){
        return oldOpp != null
            && oldOpp.StageName == 'Closed Won'
            && (HelperClass.isChanged(opp, oldOpp, Schema.Opportunity.Amount)
                || HelperClass.isChanged(opp, oldOpp, Schema.Opportunity.StageName));
    }

    // Sends an email to the appropriate email addresses 
    private void sendEmail(Opportunity opp, Id emailTemplateId, List<String> toEmailAddresses, OrgWideEmailAddress fromEmail){
        // In the future, use a custom object or metadata type to store a dictionary of Process Builder Node Reference : Email Template Id
        // For now, the email template ID's will be hard coded
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        
        System.debug('Sending email for Opportunity: ' + opp);
        System.debug('Shipping contact emails: ' + opp.Shipping_Address_NEW__r.Shipping_Contact__c + ' AND ' + opp.Shipping_Contact__c );
        email.setTemplateId(emailTemplateId);
        email.setTargetObjectId(opp.Shipping_Address_NEW__r.Shipping_Contact__c);
        // email.setTargetObjectId(opp.Shipping_Address_NEW__r.Shipping_Contact__c != null ? opp.Shipping_Address_NEW__r.Shipping_Contact__c : opp.Trial_Primary_Contact__c);
        // email.setTargetObjectId(shippingContactId);
        email.setTreatTargetObjectAsRecipient(false);
        email.setToAddresses(toEmailAddresses);
        email.setWhatId(opp.Id);
        email.saveAsActivity = false;

        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        if (fromEmail != null && fromEmail.Address != null) {
            email.setOrgWideEmailAddressId(fromEmail.Id);
        }

        List<Messaging.SendEmailResult> resultSend = Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{ email });
    }
    
    private void publishDMLs() {
        uow = DMLWrapper.uow;
        DMLWrapper.publishDML(uow);
    }

    /**
     * @description : Checks this record if the consolidated process should be executed for it.
     */
    public ConsolidatedProcessAsyncConditions validateRecordForConsolidatedProcesses(Opportunity oldOpp, Opportunity opp){
        Boolean c1 = this.hasShippingAddressAndIsChanged(oldOpp, opp);
        Boolean c2 = this.hasLicenseTermChanged(oldOpp, opp);
        Boolean c3 = this.isWonAndHasChangedAmountOrClosedDate(oldOpp, opp);
        Boolean c4 = this.wasWonAndHasChangedAmountOrStage(oldOpp, opp);

        if (c1 || c2 || c3 || c4){
            return new ConsolidatedProcessAsyncConditions(c1, c2, c3, c4);
        }else{
            return null;
        }
    }

    public class ConsolidatedProcessAsyncConditions {
        public Boolean c1;
        public Boolean c2;
        public Boolean c3;
        public Boolean c4;

        public ConsolidatedProcessAsyncConditions(Boolean c1, Boolean c2, Boolean c3, Boolean c4){
            this.c1  = c1;
            this.c2  = c2;
            this.c3  = c3;
            this.c4  = c4;
        }
    }
    
    public class Options {
        public String Operation {get; set;}
        public Map<Id, ConsolidatedProcessAsyncConditions> conditionMap {get; set;}

        public Options(String operation){
            this.Operation = operation;
            this.conditionMap = null;
        }
        
        public Options(String operation, Map<Id, ConsolidatedProcessAsyncConditions> conditionMap){
            this.Operation = operation;
            this.conditionMap = conditionMap;
        }
    }
}