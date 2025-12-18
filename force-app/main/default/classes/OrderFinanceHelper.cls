public class OrderFinanceHelper {
    
    public static void updateOppOwnerContra(List<Opportunity> newOppList, Map<Id, Opportunity> oldOppMap) {
        ReturnOwnerCopyDataUtility.updateReturnOwner(newOppList, oldOppMap);
    }
    
    public static void updateOppCopyDataContra(Opportunity returnOpp, Opportunity oldOpp, Opportunity revOpp, Map<Id, User> mapUsers, Boolean isInsertOrLinked) {
        ReturnOwnerCopyDataUtility.updateCopyFields(returnOpp, oldOpp, revOpp, mapUsers, isInsertOrLinked);
    }
    
    public static void logOrderAutomationFailures(List<Opportunity> newOppList, Map<Id, Opportunity> oldOppMap) {
        OrderAutomationLoggingService.evaluateAutomationErrors(newOppList, oldOppMap);
    }
    
}