/*
* TestClass = QuoteOrderedBatchTest

* This Class is used to uncheck and check the Ordered checkbox on Quote for which Orders are not created
* System.schedule('Scheduled Job QuoteOrderedBatch 17', '0 17 * * * ?', new QuoteOrderedBatch(false,null));

* Oct-21-2022 Rajesh :- GTMS-8298
*/
global class QuoteOrderedBatch implements
    Database.Batchable<sObject>, Database.Stateful,Schedulable{
 
   //If True: then check the RenewalForecast on Contract.
   //If Flase: then uncheck the RenewalForecast on Contract.
   public final boolean doCheck;  
   public Set<Id> OppListState = new Set<Id>();
   public Set<Id> OppList = new Set<Id>();
   
   public SamsaraLoggerService thisSamsaraLoggerService = new SamsaraLoggerService();
   public string errorString = '';
   
   public QuoteOrderedBatch(boolean b, Set<Id> oList){
     doCheck = b;
     OppList = oList;
   }
 
   public Database.QueryLocator start(Database.BatchableContext BC){
      if(doCheck){ // Check Contracted on Opp 
         return Database.getQueryLocator('SELECT id,SBQQ__PrimaryQuote__c FROM Opportunity WHERE id IN : OppList');
      }   
      else{ 
         String query='';
         if(Test.isRunningTest()){
             query = 'SELECT id, SBQQ__PrimaryQuote__c FROM Opportunity WHERE StageName =\'' + 'Ready to Ship'+ '\' LIMIT 1';
          }
          else{
             query = System.Label.QuoteOrderedBatchQuery;
          }
          
          return Database.getQueryLocator(query);
       }

   }
    
   public void execute(Database.BatchableContext BC, List<Opportunity> scope){
      SBQQ__Quote__c quote = new SBQQ__Quote__c();
      List<SBQQ__Quote__c> quoteList = new List<SBQQ__Quote__c>();
      
      for(Opportunity s : scope){
         if(s.SBQQ__PrimaryQuote__c <> NULL){
            OppListState.add(s.Id);
            quote.Id = s.SBQQ__PrimaryQuote__c;
            quote.SBQQ__Ordered__c = doCheck;
            quoteList.add(quote);
         }
      }
      
	 List<Database.SaveResult> quoteUpdateResults = Database.update(quoteList,false); 
     for(Database.SaveResult sr : quoteUpdateResults) {
     	if(!sr.isSuccess()) {
     		for(Database.Error err : sr.getErrors()) {
            	thisSamsaraLoggerService.logger.logError('QuoteOrderedBatch: Update failed due to ::'+err.getMessage());
                errorString+= err.getMessage() + '\n';
                thisSamsaraLoggerService.logger.dispatch();
            }
        }
	 }             
   }
 
	public void finish(Database.BatchableContext BC){
        if(!String.isBlank(errorString) && !string.isEmpty(errorString)) {
            emailErrors(errorString);
       	}
        
      if(!doCheck) //if false, then call the true method to check the Contracted
         database.executebatch(new QuoteOrderedBatch(true, OppListState),1);
   }

global void execute(SchedulableContext SC) {
      database.executebatch(new QuoteOrderedBatch(false,null),1);
   }
        
    public void emailErrors(string errorString)
    {
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setToAddresses(getEmailAddresses());
        mail.setSubject('CPQ Error Notification');
        mail.setPlainTextBody(errorString);
        if(!test.isRunningTest())
        {
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });            
        }
        
    }
    
    public List<String> getEmailAddresses()
    {
        List<Id> idList = new List<Id>();
        List<String> mailToAddresses = new List<String>();
        
        Group g = [Select (select userOrGroupId from groupMembers) From group where name = 'CPQ System Notification' LIMIT 1];
        for(GroupMember gm : g.groupMembers)
        {
            idList.add(gm.userOrGroupId);
        }
        
        User[] usr = [SELECT email FROM user WHERE id IN :idList];        
        for(User u : usr) 
        {            
            mailToAddresses.add(u.email);            
        }
        
        return mailToAddresses;
    }        
}