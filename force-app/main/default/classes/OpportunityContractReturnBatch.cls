global class OpportunityContractReturnBatch implements Database.Batchable<sObject> {

    public String additionalWhereClause;
    public static List<String> validTypes = new List<String>{'Remorse Refund', 'Rebate'};

    global Database.QueryLocator start(Database.BatchableContext BC) {

        if (additionalWhereClause == null) {
            additionalWhereClause = ' where Id NOT IN (select Account__c from OpportunityContractReturnAccount__c)';
        }

        String opportunitySubQuery = 'select PO_Number__c        ' +
                                     '     , CloseDate           ' +
                                     '     , License_End_Date__c ' +
                                     '     , Type                ' +
                                     '     , ContractId          ' +
                                     '     , Returning_Opportunity__r.ContractId         ' +
                                     '     , Returning_Opportunity__r.Type               ' +
                                     '     , Returning_Opportunity__r.CloseDate          ' +
                                     '     , Returning_Opportunity__r.License_End_Date__c' +
                                     '     , Returning_Opportunity__c            ' +
                                     '     , RecordType.DeveloperName            ' +
                                     '  from Opportunities                    ' +
                                     ' where AccountId != null                ' +
                                     '   and IsWon = true                     ' +
                                     '   and Returning_Opportunity__c != null ' +
                                     '   and Type IN :validTypes              '
                                    ;
        String query = 'select Id, (' + opportunitySubQuery + ') from Account ' + additionalWhereClause;
//        System.debug('** query: ' + query);
        return Database.getQueryLocator(query);
    }

    global void finish(Database.BatchableContext BC) {
    }

    // Execute Logic
    global void execute(Database.BatchableContext BC, List<sObject> objects) {

        List<ReturningOpportunityWrapper> returningOpportunityWrappers = new List<ReturningOpportunityWrapper>();

        List<OpportunityContractReturnAccount__c>  handledAccounts = new List<OpportunityContractReturnAccount__c>();

        for (Account acct : (List<Account>)objects) {

            handledAccounts.add(new OpportunityContractReturnAccount__c(Account__c = acct.Id));

            if (acct.Opportunities.isEmpty()) {
                continue;
            }

            Map<Id,List<Opportunity>> opportunitiesByParentId = new Map<Id,List<Opportunity>>();
            for (Opportunity opp : acct.Opportunities) {
                if (opportunitiesByParentId.containsKey(opp.Returning_Opportunity__c)) {
                    opportunitiesByParentId.get(opp.Returning_Opportunity__c).add(opp);
                } else {
                    opportunitiesByParentId.put(opp.Returning_Opportunity__c, new List<Opportunity>{opp});
                }
            }

            for (Id parentId : opportunitiesByParentId.keySet()) {

                List<Opportunity> groupedReturningOpportunities = opportunitiesByParentId.get(parentId);

                Id returningOpportunityContractId = null;
                for (Opportunity opp : groupedReturningOpportunities) {
                    if (opp.Returning_Opportunity__r.ContractId != null) {
                        returningOpportunityContractId = opp.Returning_Opportunity__r.ContractId;
                    }
                }
                if (returningOpportunityContractId != null) {
                    Contract contract = new Contract(Id = returningOpportunityContractId);
                    returningOpportunityWrappers.add(new ReturningOpportunityWrapper(groupedReturningOpportunities, acct.Id, contract));
                }
                else {

                    // only create a contract for the parent when the parent's type is valid for contract creation
                    List<Opportunity> groupedReturningOpportunitiesWhoseParentIsValidForContractCreation = new List<Opportunity>();
                    for (Opportunity opp : groupedReturningOpportunities) {
                        if (OpportunityContractBatch.validTypes.contains(opp.Returning_Opportunity__r.Type)) {
                            groupedReturningOpportunitiesWhoseParentIsValidForContractCreation.add(opp);
                        }
                    }
                    if (!groupedReturningOpportunitiesWhoseParentIsValidForContractCreation.isEmpty()) {
                        returningOpportunityWrappers.add(new ReturningOpportunityWrapper(groupedReturningOpportunities, acct.Id));
                    }
                }
            }
        }

        List<Opportunity> updatedOpportunities = executeLogicForReturningOpportunities(returningOpportunityWrappers);
        OpportunityContractBatch.updateContractEndDate(updatedOpportunities);

        insert handledAccounts;
    }

    private class ReturningOpportunityWrapper {

        public List<Opportunity> opportunities;
        public Contract contract;
        public Id accountId;

        public ReturningOpportunityWrapper(List<Opportunity> opportunities, Id accountId) {
            this.opportunities = opportunities;
            this.accountId = accountId;

            createContract();
        }

        public ReturningOpportunityWrapper(List<Opportunity> opportunities, Id accountId, Contract contract) {
            this.opportunities = opportunities;
            this.accountId = accountId;
            this.contract = contract;
        }

        private void createContract() {

            Decimal term = 1;
            Date minCloseDate = null;
            Date maxLicenseEndDate = null;
            for (Opportunity opp : opportunities) {

                if (minCloseDate == null || opp.Returning_Opportunity__r.CloseDate < minCloseDate) {
                    minCloseDate = opp.Returning_Opportunity__r.CloseDate;
                }

                if (maxLicenseEndDate == null || (opp.Returning_Opportunity__r.License_End_Date__c != null && opp.Returning_Opportunity__r.License_End_Date__c > maxLicenseEndDate)) {
                    maxLicenseEndDate = opp.Returning_Opportunity__r.License_End_Date__c;
                }
            }

            if (maxLicenseEndDate != null) {
                term = Math.abs(minCloseDate.monthsBetween(maxLicenseEndDate));
            }

            this.contract = new Contract();
            this.contract.AccountId = accountId;
            this.contract.StartDate = minCloseDate == null? Date.today() : minCloseDate;
            this.contract.ContractTerm = Integer.valueOf(term);
            this.contract.Contract_End_Date_Manual__c = maxLicenseEndDate;
        }
    }

    private List<Opportunity> executeLogicForReturningOpportunities(List<ReturningOpportunityWrapper> returningOpportunityWrappers) {

        Map<Id,Opportunity> parentReturningOpportunityById = new Map<Id,Opportunity>();
        List<Contract> contractsToInsert = new List<Contract>();
        List<Opportunity> opportunitiesToUpdate = new List<Opportunity>();

        for (ReturningOpportunityWrapper wrapper : returningOpportunityWrappers) {

            // do not have Contracts - create Contract
            if (wrapper.contract.Id == null) {
                contractsToInsert.add(wrapper.contract);
            }
        }

        // insert contracts and assign created Contract to Returning_Opportunity__c
        insert contractsToInsert;

        for (ReturningOpportunityWrapper wrapper : returningOpportunityWrappers) {

            // defensive code
            if (wrapper.contract.Id == null) {
                continue;
            }

            // have Contracts (existing or newly created) - assign Contract to Returning_Opportunity__c
            for (Opportunity opp : wrapper.opportunities) {

                // do not over write existing Contract or update unnecessarily
                if (opp.Returning_Opportunity__r.ContractId == null) {
                    parentReturningOpportunityById.put(opp.Returning_Opportunity__c, new Opportunity(Id = opp.Returning_Opportunity__c, ContractId = wrapper.contract.Id));
                    opp.ContractId = wrapper.contract.Id;
                }
                else {
                    opp.ContractId = opp.Returning_Opportunity__r.ContractId;
                }
                opportunitiesToUpdate.add(opp);

            }
        }
        update parentReturningOpportunityById.values();
        update opportunitiesToUpdate;

        return opportunitiesToUpdate;
    }
}