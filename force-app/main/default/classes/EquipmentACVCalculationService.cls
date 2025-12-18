public inherited sharing class EquipmentACVCalculationService {


    /**
	* @description : Calculate Equipment bookings ACV by invoking platform Event.
	*/
    @TestVisible
    public void calculateEquipmentACV(Opportunity oldOpp, Opportunity newOpp){
        
    	List<SBQQ__Quote__c> quotelist = new List<SBQQ__Quote__c>();
    	List<String> OpptyStagesList = System.Label.Equipment_ACV_Oppty_Stages.split(',');
        system.debug('********* calculateEquipmentACV method ********');
    	if (OpptyStagesList.contains(newOpp.StageName) && oldOpp.StageName != newOpp.StageName && newOpp.SBQQ__PrimaryQuote__c != null) {
    		quotelist.add(new SBQQ__Quote__c(id = newOpp.SBQQ__PrimaryQuote__c, SBQQ__Primary__c = true));
    		if(quotelist.size() > 0){
                system.debug('********* calculateEquipmentACV quotelist check pass ********');
    		GS_QuoteEventService gsQuoteEventService = new GS_QuoteEventService();
    		gsQuoteEventService.createQuoteSavePE(quotelist);
    		}
    	}
    }
}