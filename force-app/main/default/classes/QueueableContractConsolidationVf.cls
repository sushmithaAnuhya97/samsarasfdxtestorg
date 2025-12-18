public class QueueableContractConsolidationVf{
    
    public PageReference updateSBQQ_Quote(){
        Id masterQuoteId = ApexPages.currentPage().getParameters().get('Id');
        string recalculate =   ApexPages.currentPage().getParameters().get('RecalculateQuote');
        Boolean recalculateQuote = (recalculate == 'false') ? false:true;
        GS_SBQQQuoteServiceAsync.asyncContext = (recalculate == 'false') ? 'CopyQuoteFieldsToOppty':'';
        SBQQ__Quote__c masterQuote=new SBQQ__Quote__c(Id=masterQuoteId,Recalculate_Quote__c=recalculateQuote);
        try{
            update masterQuote;
        }catch(Exception ex){
            System.debug('Message: '+ex.getMessage());
        }
        
        System.debug('masterQuote: '+masterQuote); 
        return null;
    }
}