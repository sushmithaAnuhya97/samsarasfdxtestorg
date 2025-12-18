/**
 * @description       : 
 * @author            : flavio.contini@samsara.com
 * @group             : 
 * @last modified on  : 02-14-2023
 * @last modified by  : -
**/
public without sharing class ContractDateCleanerBatch implements System.Schedulable, Database.Batchable<Contract>, Database.Stateful {

    @TestVisible private Integer EXECUTE_BATCH_SIZE = 1;
    @TestVisible private Boolean TEST_PERFORM_DMLS = true;
    @TestVisible private Exception TEST_EXCEPTION_OVERRIDE = null;
    @TestVisible private List<String> SUMMARY_EMAIL_RECIPIENTS = new List<String>{
        'navees.ahmed@samsara.com',
        'shobhit.srivastava@samsara.com',
        'megha.sharma@samsara.com'
    };

    public List<String> errorMessages = new List<String>();

    public void execute(System.SchedulableContext ctx){
        Database.executeBatch(new ContractDateCleanerBatch(), EXECUTE_BATCH_SIZE);
    }

    public List<Contract> start(Database.BatchableContext ctx){
        return Database.query(
            'SELECT'+
               ' Id,'+
               ' StartDate,'+
               ' EndDate,'+
               ' SBQQ__Opportunity__c,'+
               ' SBQQ__Opportunity__r.CloseDate,'+
               ' SBQQ__Opportunity__r.License_Start_Date__c,'+
               ' SBQQ__Opportunity__r.License_End_Date__c,'+
               ' (SELECT Id,'+
                       ' SBQQ__SubscriptionStartDate__c,'+
                       ' SBQQ__SubscriptionEndDate__c,'+
                       ' SBQQ__QuoteLine__r.SBQQ__Quote__r.SBQQ__Opportunity2__r.License_Start_Date__c,'+
                       ' SBQQ__QuoteLine__r.SBQQ__Quote__r.SBQQ__Opportunity2__r.License_End_Date__c'+
                ' FROM SBQQ__Subscriptions__r'+
               ' WHERE SBQQ__SubscriptionStartDate__c != null'+
                  ' OR SBQQ__SubscriptionEndDate__c != null)'+
             ' FROM Contract'+
            ' WHERE SBQQ__Opportunity__c != null '+
              ' AND CreatedDate >= YESTERDAY'+
            ' ORDER BY Id'
        );
    }

    public void execute(Database.BatchableContext ctx, List<Contract> listContracts){
        List<Contract> listWithInvalidDate = new List<Contract>();
        List<SBQQ__Subscription__c> listWithInvalidDateWithSubscriptions=new List<SBQQ__Subscription__c>();
        for(Contract c:listContracts){

            if( c.SBQQ__Opportunity__r.CloseDate==c.SBQQ__Opportunity__r.License_Start_Date__c && (c.StartDate!=c.SBQQ__Opportunity__r.License_Start_Date__c || c.EndDate!=c.SBQQ__Opportunity__r.License_End_Date__c)){
                
                c.StartDate=c.SBQQ__Opportunity__r.License_Start_Date__c; 
                c.EndDate=c.SBQQ__Opportunity__r.License_End_Date__c;

                listWithInvalidDate.add(c);
                if(c.SBQQ__Subscriptions__r.size() > 0){
                    for(SBQQ__Subscription__c s : c.SBQQ__Subscriptions__r){
                        if(s.SBQQ__SubscriptionStartDate__c!=null){
                            s.SBQQ__SubscriptionStartDate__c = s.SBQQ__QuoteLine__r.SBQQ__Quote__r.SBQQ__Opportunity2__r.License_Start_Date__c;
                        }
                        if(s.SBQQ__SubscriptionEndDate__c != null){
                            s.SBQQ__SubscriptionEndDate__c = s.SBQQ__QuoteLine__r.SBQQ__Quote__r.SBQQ__Opportunity2__r.License_End_Date__c;   
                        }  
                        listWithInvalidDateWithSubscriptions.add(s);                
                    }
                }
            }
        }
        System.debug('listWithInvalidDate====='+listWithInvalidDate.size());
        System.debug('listWithInvalidDateWithSubscriptions====='+listWithInvalidDateWithSubscriptions.size());
        
        try{
            if (!listWithInvalidDate.isEmpty() && TEST_PERFORM_DMLS) update listWithInvalidDate;
            if (!listWithInvalidDateWithSubscriptions.isEmpty() && TEST_PERFORM_DMLS) update listWithInvalidDateWithSubscriptions;

            if (Test.isRunningTest() && TEST_EXCEPTION_OVERRIDE != null) throw TEST_EXCEPTION_OVERRIDE;

        }catch(DmlException ex){
            this.errorMessages.add(this.fetchErrorMessages(ex));
        }catch(Exception ex){
            this.errorMessages.add('Non DML exception: '+ex.getMessage()+' || Full stack trace: '+ex.getStackTraceString()+'\nOn line '+ex.getLineNumber());
        }
    }

    @TestVisible
    private String fetchErrorMessages(DMLException ex){
        String errorMsg = '';
        for (Integer idx = 0; idx < ex.getNumDml(); idx++){
            errorMsg += String.format((errorMsg.length() <= 0 ? '' : '\n')+'ERR: Error on record {0} | Message: {1}', new List<String>{
                String.valueOf(ex.getDmlId(idx)),
                ex.getDmlMessage(idx)
            });
        }

        return errorMsg + '\nFull stack trace: '+ex.getStackTraceString()+'\nOn line '+ex.getLineNumber();
    }

    public void finish(Database.BatchableContext ctx){
        // Send email
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setToAddresses(SUMMARY_EMAIL_RECIPIENTS);
        mail.setSubject('Errors during Contract Date Cleaner Batch execution: '+this.errorMessages.size());
        mail.setPlainTextBody('Hello,\n\nThe ContractDateCleanerBatch batch Apex job encountered issues during processing: ' + 
                              String.join(this.errorMessages,'\n--------\n'));
        
        if(!this.errorMessages.isEmpty())
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
    }
    
    // start date=License_Start_Date__c
    //EndDate!=c.SBQQ__Opportunity__r.License_End_Date__c
    //if subscriptions 
}