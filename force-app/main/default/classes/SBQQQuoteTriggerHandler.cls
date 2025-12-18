/* 
 * Class Created: 06/14/19 - @author: Harsha
 */  
public class SBQQQuoteTriggerHandler extends TriggerHandler{
    public static List<Schema.SObjectType> MY_SOBJECTS = new List<Schema.SObjectType>{
            SBQQ__QuoteLine__c.SObjectType,
            Opportunity.SObjectType
    };
    private Map<Id, SBQQ__Quote__c > oldSbqqQuoteMap;
    private Map<Id, SBQQ__Quote__c > newSbqqQuoteMap;
    private List<SBQQ__Quote__c > newSbqqQuoteList;
    private SBQQQuoteHelper sbqqQuoteHelper;
    Private UnitOfWork uow ;
    public SBQQQuoteTriggerHandler() {
        sbqqQuoteHelper = new SBQQQuoteHelper();
        this.oldSbqqQuoteMap = (Map<Id, SBQQ__Quote__c>) Trigger.oldMap;
        this.newSbqqQuoteMap = (Map<Id, SBQQ__Quote__c>) Trigger.newMap;
        this.newSbqqQuoteList = (List<SBQQ__Quote__c>) Trigger.new;
        DMLWrapper.intializeUnitOfWork(MY_SOBJECTS);
	}
    
    public override void beforeInsert() {
        System.debug('TriggerHandler beforeInsert Start');
        sbqqQuoteHelper.quoteBeforeInsertOperations(oldSbqqQuoteMap, newSbqqQuoteMap, newSbqqQuoteList);
    }
    
    public override void afterInsert(){
      System.debug('TriggerHandler afterInsert Start');
        SBQQQuoteHelper.createQuoteSavePE(newSbqqQuoteList);
    }

    public override void beforeUpdate() {
        System.debug('TriggerHandler beforeUpdate Start');
        sbqqQuoteHelper.quoteBeforeUpdateOperations(oldSbqqQuoteMap, newSbqqQuoteMap, newSbqqQuoteList);
    }

    public override void afterUpdate() {
        System.debug('TriggerHandler afterUpdate Start');
        SBQQQuoteHelper.createQuoteSavePE(newSbqqQuoteList);
        sbqqQuoteHelper.quoteAfterUpdateOperations(oldSbqqQuoteMap, newSbqqQuoteMap, newSbqqQuoteList);
    }

    public override void publishDMLs() {
        uow = DMLWrapper.uow;
        DMLWrapper.publishDML(uow);
    }

}