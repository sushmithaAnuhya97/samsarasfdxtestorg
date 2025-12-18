public with sharing class GS_OpportunityToUpdateAccountAsync extends BaseAsyncHandler {
    public SamsaraLoggerService thisSamsaraLoggerService = new SamsaraLoggerService();

    public override String getRequestType(){
        return 'OpportunityToAccountUpdate Async Job';
    }
    
    List<Schema.SObjectType> MY_SOBJECTS = new List<Schema.SObjectType>{
        Account.SObjectType
    };

    List<Id> recordsIds;
    List<Opportunity> opptyList;
    Map<Id,ConsolidatedAccountUpdateAsyncConditions> conditionMap;
    public GS_OpportunityCacheService oppCache = new GS_OpportunityCacheService();
    public override void execute(Async_Request__c ar){

        recordsIds = ar.Params__c.split(PARAMETERS_SPLITTER);
        if(recordsIds.isEmpty()) return;
        Options opt = (Options) JSON.deserialize(ar.Options__c, Options.class);
    
        DMLWrapper.intializeUnitOfWork(MY_SOBJECTS);
        
        try{
            thisSamsaraLoggerService.logger.logTrace('Entering in GS_OpportunityToUpdateAccountAsync');
            conditionMap = (opt.conditionMap != null ? opt.conditionMap : new Map<Id,ConsolidatedAccountUpdateAsyncConditions>());
            switch on opt.Operation {
                when 'BEFORE_UPDATE_OPERATIONS' {	
                    this.loadOpportunities(recordsIds);

                    this.beforeUpdateOperations();
                }
                when 'AFTER_UPDATE_OPERATIONS' {
                    this.loadOpportunities(recordsIds);

                    this.afterUpdateOperations();
                }
            }
            this.publishDMLs();
        }catch(Exception ex){
            thisSamsaraLoggerService.logger.logError('Error in GS_OpportunityToUpdateAccountAsync::', new SamsaraLoggerObjectMVP(
                ex, recordsIds
        ));
            throw ex;
        }
        finally {
            thisSamsaraLoggerService.logger.logTrace('Exiting in GS_OpportunityToUpdateAccountAsync');
            thisSamsaraLoggerService.logger.dispatch();
        }
    }


    private void loadOpportunities(List<Id> idList){
        if (opptyList == null){
            this.opptyList = (new GS_OpportunitySelector(false)).loadOpportunityWithItems(new Set<Id>(idList));
            oppCache.cacheRelatedIdsFromOpps(this.opptyList);
            oppCache.loadOppRelatedAccounts(oppCache.cachedAccountIds);
        }
    }

    private void beforeUpdateOperations(){

        for(Opportunity oppty : this.opptyList){
            
            Account thisOppAccount = (oppCache.relatedAccountMap.containsKey(oppty.AccountId) ? oppCache.relatedAccountMap.get(oppty.AccountId) : new Account());


            ConsolidatedAccountUpdateAsyncConditions recordConditions = this.conditionMap.get(oppty.Id);
            
            // Condition 1 ====
            if(recordConditions != null && recordConditions.c1){
                thisOppAccount.VATId__c = oppty.VAT_Number__c;
                thisOppAccount.VAT_Validation_Status__c = oppty.VAT_Validation_Status__c;
                DMLWrapper.doUpdate(thisOppAccount, new List<SObjectField>{
                    Account.VATId__c, Account.VAT_Validation_Status__c
                        });
            }
            

            // Condition 2 ====
            if(recordConditions != null && recordConditions.c2){
                thisOppAccount.First_Purchase_Value__c = oppty.Amount;
                    DMLWrapper.doUpdate(thisOppAccount, new List<SObjectField>{
                        Account.First_Purchase_Value__c
                            });
            }
            

            // Condition 3 ====
            if(recordConditions != null && recordConditions.c3){
                thisOppAccount.New_Billing_Process_Approved__c = true;
                    DMLWrapper.doUpdate(thisOppAccount, new List<SObjectField>{Account.New_Billing_Process_Approved__c});
            }
        }
    }

    private void afterUpdateOperations(){
       
        Map<Id, Account> oppAccountsRev = new GS_OpportunityService().getAccountsForClosedOrRevenueTypeOppty(oppCache.relatedAccountMap);
        for(Opportunity oppty : this.opptyList){
            String accountStatus;
            Account thisOppAccount = (oppCache.relatedAccountMap.containsKey(oppty.AccountId) ? oppCache.relatedAccountMap.get(oppty.AccountId) : new Account());
            Account oppRevAccount = (oppAccountsRev.containsKey(oppty.AccountId) ? oppAccountsRev.get(oppty.AccountId) : new Account());

            ConsolidatedAccountUpdateAsyncConditions recordConditions = this.conditionMap.get(oppty.Id);
        
            if(oppRevAccount != null){
				// Condition 1 ====
                if(recordConditions != null && recordConditions.c1){
                    accountStatus = 'Open Opportunity';
                }
                // Condition 2 ====
                if(recordConditions != null && recordConditions.c2){
                    accountStatus = 'Existing Customer';
                }
                if (accountStatus != null) {
                    oppRevAccount.Status__c = accountStatus;
                    DMLWrapper.doUpdate(oppRevAccount, new List<SObjectField>{
                            Account.Status__c
                    });
                }
                // Condition 3 ====
                if(recordConditions != null && recordConditions.c3){
                    oppRevAccount.Link_to_Last_Order__c  = URL.getSalesforceBaseUrl().toExternalForm() + '/' + oppty.Id;

                    DMLWrapper.doUpdate(oppRevAccount, new List<SObjectField>{
                        Account.Link_to_Last_Order__c
                    });
                }
            }

            // Condition 4 ====
            //Groundswell - Nilesh Jain : Update Payment Method Link on Account workflow changes
            if(recordConditions != null && recordConditions.c4){
                thisOppAccount.Churn_Update_CC_Link__c = oppty.StageName == 'Closed Won' ?
                    System.Label.UpdatePaymentMethodLink + thisOppAccount.Id : '';
                DMLWrapper.doUpdate(thisOppAccount, new List<SObjectField>{Account.Churn_Update_CC_Link__c});
            }

            // Condition 5 ====
            // Groundswell : Tanuj - WFlow Rule - Update Account for NS Sync
            // Update Account for NS Sync when Opportunity is at Decision,Qualified,Proposal,Purchase,Trial
            if(recordConditions != null && recordConditions.c5){
                thisOppAccount.Push_to_Netsuite__c = true;
                DMLWrapper.doUpdate(thisOppAccount, new List<SObjectField>{Account.Push_to_Netsuite__c}); 
            }
            
            // Condition 6 ====
            //Groundswell - Nilesh Jain : Account Internally Financed workflow changes.
            if(recordConditions != null && recordConditions.c6){
                thisOppAccount.Internally_Financed__c = true;
                DMLWrapper.doUpdate(thisOppAccount, new List<SObjectField>{Account.Internally_Financed__c});
            }

        }
    }


    private void publishDMLs() {
        DMLWrapper.publishDML();
    }

    //Before-Update Condition 1
    private Boolean hasValidationStatusAndIsChanged(Opportunity oldOpp, Opportunity newOpp, Account thisOppAccount){
            return (newOpp.isClosed == FALSE 
                    && HelperClass.isChanged(newOpp, oldOpp, Schema.Opportunity.VAT_Validation_Status__c) 
                    && newOpp.VAT_Validation_Status__c == 'Verified' 
                    && thisOppAccount.VAT_Validation_Status__c != 'Verified' 
                    && newOpp.VAT_Number__c != null);
    }


    //Before-Update Condition 2
    private Boolean hasFirstPurchaseValue(Opportunity newOpp, Account thisOppAccount){
            return (newOpp.Type == 'Revenue Opportunity'
                    && newOpp.IsWon == TRUE 
                    && newOpp.Amount > 0
                    && thisOppAccount.First_Purchase_Value__c == NULL);    
    }


    //Before-Update Condition 3
    private Boolean isNewBillingProcessApproved(Opportunity vOpportunity){
    /* Replaces Node 'New Billing Process Approval' */
        return ((vOpportunity.Price_Book_Name__c != null 
                   && vOpportunity.Configuration_Segment__c == 'Express') 
                && vOpportunity.Payment_Token__c != null
                && vOpportunity.Probability >= 98
                && !vOpportunity.IsClosed
                && !vOpportunity.Account.New_Billing_Process_Approved__c);
    }

    
	//After-Update Condition 1
   	private Boolean isAccountStatusOpenOpportunity(Opportunity oldOpportunity, Opportunity newOpp, Account oppRevAccount, Boolean oldOppNull){
            return (oppRevAccount.Status__c != 'Open Opportunity' 
                    && newOpp.StageName != 'Closed Lost' 
                    && newOpp.StageName != 'Closed Won'
                    && ((newOpp.StageName != oldOpportunity.StageName && !oldOppNull) || oldOppNull)
                    && newOpp.Type == 'Revenue Opportunity');
    }

    //After-Update Condition 2
    private Boolean isAccountStatusExistingCustomer(Opportunity newOpp, Opportunity oldOpp){
            return (newOpp.StageName == 'Closed Won' 
                    && newOpp.StageName != oldOpp.StageName 
                    && newOpp.Type == 'Revenue Opportunity');
    }

    //After-Update Condition 3
    private Boolean isAccountLinkedToLastOrder(Opportunity newOpp, Opportunity oldOpp){
            return (newOpp.StageName == 'Closed Won' 
                    && newOpp.StageName != oldOpp.StageName 
                    && newOpp.Type == 'Revenue Opportunity');
    }

    //After-Update Condition 4
    private Boolean isUpdatePaymentMethodLink(Opportunity newOpp, Opportunity oldOpportunity, Account opportunityAccount){
            return (opportunityAccount.Id != null 
                    && newOpp.Amount_Received__c != oldOpportunity.Amount_Received__c);
    }

    //After-Update Condition 5
    private Boolean isUpdateAccountForNsSync(Opportunity newOpp, Account opportunityAccount){
        Set<String> stageTypeSet = new Set<String>{'Decision', 'Qualified', 'Proposal', 'Purchase', 'Trial'};
            return ((stageTypeSet.contains(newOpp.StageName)) 
                    &&(opportunityAccount != null 
                       && opportunityAccount.Netsuite_Id__c == null));
    }

    //After-Update Condition 6
    private Boolean isAccountInternallyFinanced(Opportunity newOpp, Account opportunityAccount){
            return (opportunityAccount.Id != null 
                    && !opportunityAccount.Internally_Financed__c
                    && newOpp.Internal_Finance__c == 'Approved' 
                    && newOpp.StageName == 'Closed Won');
    }


    /**
     * @description : Checks this record if the consolidated process should be executed for it.
     */
    public ConsolidatedAccountUpdateAsyncConditions validateRecordForAccountProcessesBeforeUpdate(Opportunity oldOpp, Opportunity newOpp, Opportunity vOpportunity, Account thisOppAccount){
        Boolean c1 = this.hasValidationStatusAndIsChanged(oldOpp, newOpp, thisOppAccount);
        Boolean c2 = this.hasFirstPurchaseValue(newOpp, thisOppAccount);
        Boolean c3 = this.isNewBillingProcessApproved(vOpportunity);

        if (c1 || c2 || c3){
            return new ConsolidatedAccountUpdateAsyncConditions(c1, c2, c3);
        }else{
            return null;
        }
    }

    public ConsolidatedAccountUpdateAsyncConditions validateRecordForAccountProcessesAfterUpdate(Opportunity oldOpp, Opportunity newOpp, Account thisOppAccount, Account oppRevAccount, Boolean oldOppNull){
        Boolean c1 = oppRevAccount != null ? this.isAccountStatusOpenOpportunity(oldOpp, newOpp, oppRevAccount, oldOppNull) : false;
        Boolean c2 = oppRevAccount != null ? this.isAccountStatusExistingCustomer(newOpp, oldOpp) : false;
        Boolean c3 = oppRevAccount != null ? this.isAccountLinkedToLastOrder(newOpp, oldOpp) : false;
        Boolean c4 = this.isUpdatePaymentMethodLink(newOpp, oldOpp, thisOppAccount);
        Boolean c5 = this.isUpdateAccountForNsSync(newOpp, thisOppAccount);
        Boolean c6 = this.isAccountInternallyFinanced(newOpp, thisOppAccount);

        if (c1 || c2 || c3 || c4 || c5 || c6){
            return new ConsolidatedAccountUpdateAsyncConditions(c1, c2, c3, c4, c5, c6);
        }else{
            return null;
        }
    }

    public class ConsolidatedAccountUpdateAsyncConditions {
        public Boolean c1;
        public Boolean c2;
        public Boolean c3;
        public Boolean c4;
        public Boolean c5;
        public Boolean c6;

        public ConsolidatedAccountUpdateAsyncConditions(Boolean c1, Boolean c2, Boolean c3){
            this.c1  = c1;
            this.c2  = c2;
            this.c3  = c3;
        }

        public ConsolidatedAccountUpdateAsyncConditions(Boolean c1, Boolean c2, Boolean c3, Boolean c4, Boolean c5, Boolean c6){
            this.c1  = c1;
            this.c2  = c2;
            this.c3  = c3;
            this.c4  = c4;
            this.c5  = c5;
            this.c6  = c6;

        }
    }
    
    public class Options {
        public String Operation {get; set;}
        public Map<Id, ConsolidatedAccountUpdateAsyncConditions> conditionMap {get; set;}
    
        public Options(String operation, Map<Id, ConsolidatedAccountUpdateAsyncConditions> conditionMap){
            this.Operation = operation;
            this.conditionMap = conditionMap;
        }
    }

}