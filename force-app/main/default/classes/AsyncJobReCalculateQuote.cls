public class AsyncJobReCalculateQuote implements Queueable {
    public Integer batchStep;
    public Set<Id> qteIds;
    public List<Log__c> logListAfter = new List<Log__c>();
    
	public AsyncJobReCalculateQuote(set<string> quoteIds ){
        Set<Id> qteeIds =new Set<Id>();
        for(string qt: quoteIds){
            qteeIds.add(qt);
        }
        this.qteIds = qteeIds;
    }
    public void execute(QueueableContext context) {
            
        	if(qteIds.size()>0){
            	GS_SBQQQuoteService.sourceQuoteData = new GS_SBQQQuoteSelector(true).checkFatalError().getQuotesAndQuoteLinesById(qteIds);
				for(SBQQ__Quote__c qte: GS_SBQQQuoteService.sourceQuoteData.values()){
                	if(GS_SBQQQuoteService.getRenewalDataErrorCategoryType(qte)){
                    
                    Log__c logRecord = new Log__c();
                    logRecord.Quote__c = qte.Id;
                    logRecord.Opportunity__c = qte.SBQQ__Opportunity2__c;
                    logRecord.ClassName__c = 'JobReCalculateQuote';
                    logRecord.Type__c = 'Renewal Validation Job';
                    logRecord.Message__c = 'Erros After Job';
                    logRecord.ExceptionMessage__c = qte.Renewal_Data_Error_Category__c;
                    logRecord.StackTrace__c = null;
                    logRecord.Exception_Type__c = null;
                    logRecord.LogLevel__c = 'Info';
                    this.logListAfter.add(logRecord);
                	}
            	}
        	}
        
                if(logListAfter.size() > 0){ 
                    try{
                    	Database.insert(logListAfter, false);
                	}catch(Exception e){
                    	System.debug('e.getMessage()====='+e.getMessage());
                    } 
                }
                
            
        
    }
	
}