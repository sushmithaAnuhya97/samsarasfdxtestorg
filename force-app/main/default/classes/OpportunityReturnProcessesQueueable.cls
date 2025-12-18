/**
 * Created by vikasmishra on 2020-11-09.
 */

public without sharing class OpportunityReturnProcessesQueueable implements Queueable {
    private List<Opportunity> filteredOpportunities;
    private List<Opportunity> triggeredOpportunities;
    public OpportunityReturnProcessesQueueable(List<Opportunity> thisList, List<Opportunity> thisTriggeredList) {
        filteredOpportunities = new List<Opportunity>();
        filteredOpportunities.addALl(thisList);
        triggeredOpportunities = new List<Opportunity>();
        triggeredOpportunities.addALl(thisTriggeredList);

    }

    public void execute(QueueableContext context) {
        OpportunityReturnProcesses.createShipmentFromQueueable(filteredOpportunities, triggeredOpportunities);
    }
}