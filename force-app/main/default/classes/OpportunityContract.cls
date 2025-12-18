public class OpportunityContract {

    public void populateLicenseEndDate(List<Opportunity> opportunities) {

        Set<Id> accountIds = new Set<Id>();
        for (Opportunity opp : opportunities) {
            if (opp.AccountId != null && opp.Type == 'Revenue Opportunity') {
                accountIds.add(opp.AccountId);
            }
        }

        Map<Id,Account> accountById = new Map<Id,Account>([select First_Purchase_Date__c
                                                             from Account
                                                            where Id IN :accountIds
                                                              and First_Purchase_Date__c != null
                                                        ]);

        Map<Id,Date> mostInTheFutureContractEndDateByAccountId = getMostInTheFutureContractEndDateByAccountId(accountById);

        for (Opportunity opp : opportunities) {
            if (mostInTheFutureContractEndDateByAccountId.containsKey(opp.AccountId)) {
                opp.License_End_Date__c = mostInTheFutureContractEndDateByAccountId.get(opp.AccountId);
            }
        }

    }

    private Map<Id,Date> getMostInTheFutureContractEndDateByAccountId(Map<Id,Account> accountById) {

        Map<Id,Date> mostInTheFutureContractEndDateByAccountId = new Map<Id,Date>();
        for (Contract contract : [select AccountId, EndDate from Contract where AccountId IN :accountById.keySet()]) {

            if (mostInTheFutureContractEndDateByAccountId.containsKey(contract.AccountId)) {
                Date existingDate = mostInTheFutureContractEndDateByAccountId.get(contract.AccountId);
                if (contract.EndDate > existingDate) {
                    mostInTheFutureContractEndDateByAccountId.put(contract.AccountId, contract.EndDate);
                }
            }
            else {
                mostInTheFutureContractEndDateByAccountId.put(contract.AccountId, contract.EndDate);
            }
        }
        return mostInTheFutureContractEndDateByAccountId;
    }

}