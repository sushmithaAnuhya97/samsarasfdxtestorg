/**
* Created By : Satya Dodda
* @Date April 10, 2022
*
* @description : This batch will find / update all opportunities that belongs to Clickpath / Gainsight.
*
* 04/14/22 Flavio (GTMS-6733) Added License Term fields to mapping & adding the logging framework for error handling.
*
* Modified by Pankaj for-(GTMS-19991) and made the following changes:
* Added renewal Bot as criteria in the last condition
* Changed CloseDate logic to be 60 days instead of 45 days
* Adjusted ACV threshold to 15K
* Removed provision that defaults License Term to 12 months
* Implemented automatic recalculation of quotes
* New filter condition Subtype!=Clickpath
*
**/
global class BatchClickPathToGainSight implements Database.Batchable<sObject>, Schedulable, Database.Stateful {
    static gslib_IModuleLogger thisModuleLogger = gslib_LoggerService.getModuleLogger('GTMS');
    static gslib_ILogger thisLogger = thisModuleLogger.getLogger();
    integer INTEGER_DEFAULT_LICENSE_TERM = 12; 
    
    static String LOG_ERROR_TEMPLATE = 'ClickPath batch update failed in record {0} / Errors: {1}';
    
    @TestVisible
    static User TEST_USER_OVERRIDE;
    private list<User> renewalBotUserList {get{
            if(renewalBotUserList != null) return renewalBotUserList;

            renewalBotUserList = [SELECT Id FROM User WHERE Name = 'Renewal Bot' LIMIT 1];

            return renewalBotUserList;
            } set;}

    
    global Database.QueryLocator start(Database.BatchableContext BC) { 
        // Created two new custom labels to store query and filters separately due to the character limit on custom labels.     
        return Database.getQueryLocator(System.Label.Query_BatchClickPath_Fields+' '+System.Label.Query_BatchClickPath_Filters+ ' AND ' +System.Label.Digital_Renewals_Threshold);
    }

    global void execute(Database.BatchableContext BC, List<Opportunity> scope) {

    try{
        List<SBQQ__Quote__c> quoteList = new List<SBQQ__Quote__c>();
        set<Id> primQuoteIds = new set<Id>();
        for(Opportunity opp : scope) {

            primQuoteIds.add(opp.SBQQ__PrimaryQuote__c);

            if(opp.SBQQ__RenewedContract__c != null && opp.SBQQ__RenewedContract__r.SBQQ__Opportunity__c != null) {
                opp.Shipping_Contact__c = opp.SBQQ__RenewedContract__r.SBQQ__Opportunity__r.Shipping_Contact__c;
            }
            else if(opp.SBQQ__AmendedContract__c != null && opp.SBQQ__AmendedContract__r.SBQQ__Opportunity__c != null) {
                opp.Shipping_Contact__c = opp.SBQQ__AmendedContract__r.SBQQ__Opportunity__r.Shipping_Contact__c;
            }
            opp.StageName = 'Purchase';
            opp.Probability = 90;
            opp.Shipping_Contact__c = opp.SBQQ__RenewedContract__r?.SBQQ__Opportunity__r?.Shipping_Contact__c;
            opp.Sales_Tax_Amount__c = opp.SBQQ__PrimaryQuote__r?.Sales_Tax__c;
            opp.Initial_Payment_Terms__c = 'Due on Contract Start';
            opp.Sub_Type__c = 'Clickpath';               
            opp.License_Term__c = opp.License_Term__c ?? INTEGER_DEFAULT_LICENSE_TERM;
            opp.License_Term_CPQ__c = opp.License_Term_CPQ__c ?? INTEGER_DEFAULT_LICENSE_TERM;
            
            if (opp.Owner.Name == 'Renewal Pool' || (Test.isRunningTest())){
                List<User> u = (!(Test.isRunningTest() && TEST_USER_OVERRIDE != null) ? renewalBotUserList : new List<User>{TEST_USER_OVERRIDE});
                if (!u.isEmpty()) opp.OwnerId = u[0].Id;
            }
        }

        List<SBQQ__Quote__c> primQuotes = [SELECT Id, License_Term__c, SBQQ__Uncalculated__c FROM SBQQ__Quote__c WHERE Id in :primQuoteIds];

        for(SBQQ__Quote__c quote :primQuotes){
            
            quote.SBQQ__Status__c = quote.ApprovalStatus__c = 'Approved';
            quote.License_Term__c = quote.License_Term__c ?? String.valueOf(INTEGER_DEFAULT_LICENSE_TERM);
            quote.Recalculate_Quote__c = true;
            
            quoteList.add(quote);
        }

            this.executeDmlAndLogErrors(scope);
            this.executeDmlAndLogErrors(quoteList);
        }catch(Exception ex){
            thisLogger.logError('Error processing Clickpath job: {0} / Stack trace: {1}', new List<Object>{ ex.getMessage(), ex.getStackTraceString() });
            throw ex;
        }finally{
            thisLogger.dispatch();
        }
    }
        
        
    /**
    * @description : Execute the DML & log any errors with the logging framework
    * 
    * @param List<SObject> scope
    */
    private void executeDmlAndLogErrors(List<SObject> scope){
        List<Database.SaveResult> resultList = Database.update(scope, false);
        for (Integer it = 0; it < resultList.size(); it++){
            if (!resultList[it].isSuccess()){
                thisLogger.logError(String.format(LOG_ERROR_TEMPLATE, new List<Object>{
                    scope[it].Id,
                        getErrorList(resultList[it].getErrors())
                        }));
            } 
        }
    }
        
    /**
    * @description : Receives a List of Database Errors and return the messages in a single string separated by "; "
    * 
    * @param List<Database.Error> errors
    * @return String errors in a single line
    */
    private String getErrorList(List<Database.Error> errors){
        String err = '';
        for (Database.Error error : errors)
            err += (String.isBlank(err) ? '' : '; ')+error.message;
        return err;
    }
    
    global void finish(Database.BatchableContext BC) {}
    
    global void execute(SchedulableContext sc){
        Database.executeBatch(new BatchClickPathToGainSight(), 1);
    }
}