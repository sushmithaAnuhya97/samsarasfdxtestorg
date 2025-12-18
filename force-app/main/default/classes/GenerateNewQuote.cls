public class GenerateNewQuote {
  
  public GenerateNewQuote(ApexPages.StandardController stdcontroller){
      //Nothing to do here
  }
  
//Generate and insert a new CPQ quote.  Default values that are important for the quoting experience.
    public pageReference genQuote()
    {
        id oppId = ApexPages.currentPage().getParameters().get('id');    
        Opportunity opp = [Select Id, Name, Payment_Terms__c, AccountId, CurrencyIsoCode, Pricebook2Id, SBQQ__AmendedContract__c, (SELECT IsPrimary, ContactId FROM OpportunityContactRoles WHERE IsPrimary = True) FROM Opportunity WHERE Id =: oppId];
        string quoteId;       
        //id primaryContactId;  
        
       //Check for primary contact
       // if (opp.OpportunityContactRoles.size() > 0){
           // primaryContactId = opp.OpportunityContactRoles[0].ContactId;
        //}
        if(opp.SBQQ__AmendedContract__c == null){
        	//Create quote and default data
            SBQQ__Quote__c q = new SBQQ__Quote__c (
            SBQQ__PaymentTerms__c = opp.Payment_Terms__c,//GTMS-17232
            SBQQ__Opportunity2__c = oppId, 
            SBQQ__Account__c = opp.AccountId,
            SBQQ__Status__c = 'Draft',
            SBQQ__Type__c = 'Quote',
            SBQQ__Primary__c = false,
            SBQQ__SubscriptionTerm__c = 36,
            //Map the currency from the Opportunity.
            CurrencyIsoCode = opp.CurrencyIsoCode,
            SBQQ__StartDate__c = Date.Today(),
            SBQQ__ExpirationDate__c = Date.Today() + 30,
            SBQQ__PriceBook__c = opp.Pricebook2Id); //,
           // SBQQ__PrimaryContact__c = primaryContactId);
            //Attempt to insert new quote
            try{
                Database.Insert(q);
            }catch(Exception e){
                System.Debug('An error occurred when trying to insert a new quote: ' + e);
            }       
            quoteId = q.Id;   
            //Return user to the QLE for the inserted quote.  By defualting the "Add products" custom 
            //action record withing CPQ, the user can be taken straight to the product selection page.            
            return new PageReference('/apex/sbqq__sb?scontrolCaching=1&id=' + quoteId);    
        }else{
            return null;
        }
        
    }
}