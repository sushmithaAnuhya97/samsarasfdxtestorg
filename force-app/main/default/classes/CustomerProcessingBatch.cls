//Batch Job for Processing the Records
global class CustomerProcessingBatch implements Database.Batchable<sObject>{
  global String [] email = new String[] {'max@samsara.com'};//Add here your email address here
  
  //Start Method
  global Database.Querylocator start (Database.BatchableContext BC) {
    return Database.getQueryLocator('Select id,Normalized_Phone__c From Contact');//Query which will be determine the scope of Records fetching the same
  } //Account.Domain_Name__c = Null

  //Execute method
  global void execute (Database.BatchableContext BC, List<Contact> scope) {
    List<Contact> updtaedContactList = new List<Contact>();//List to hold updated customer
    for (Contact objScope: scope) {
        objScope.Normalized_Phone_Text__c = objScope.Normalized_Phone__c;
        updtaedContactList.add(objScope);//Add records to the List
    } 
        if (updtaedContactList != null && updtaedContactList.size()>0) {//Check if List is empty or not
            Database.update(updtaedContactList); 
            System.debug('List Size '+updtaedContactList.size());//Update the Records
            }
        
  }

  //Finish Method
  global void finish(Database.BatchableContext BC){
  Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();

  //Below code will fetch the job Id
  AsyncApexJob a = [Select a.TotalJobItems, a.Status, a.NumberOfErrors, a.JobType, a.JobItemsProcessed, a.ExtendedStatus, a.CreatedById, a.CompletedDate From AsyncApexJob a WHERE id = :BC.getJobId()];//get the job Id
  System.debug('$$$ Jobid is'+BC.getJobId());

  //below code will send an email to User about the status
  mail.setToAddresses(email);
  mail.setReplyTo('max@samsara.com');//Add here your email address
  mail.setSenderDisplayName('Apex Batch Processing Module');
  mail.setSubject('Batch Processing '+a.Status);
  mail.setPlainTextBody('The Batch Apex job processed  '+a.TotalJobItems+'batches with  '+a.NumberOfErrors+'failures'+'Job Item processed are'+a.JobItemsProcessed);
  Messaging.sendEmail(new Messaging.Singleemailmessage [] {mail});
  }
}