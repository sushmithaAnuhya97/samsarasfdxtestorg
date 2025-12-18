global class OpportunityContractBatch implements Database.Batchable<sObject> {

    public String additionalWhereClause;
    public static List<String> validTypes = new List<String>{'Revenue Opportunity'};

    // Start Method
    global Database.QueryLocator start(Database.BatchableContext BC) {

        if (additionalWhereClause == null) {
            additionalWhereClause = ' where Id NOT IN (select Account__c from OpportunityContractAccount__c)';
        }

        String opportunitySubQuery = 'select PO_Number__c        ' +
                                     '     , CloseDate           ' +
                                     '     , License_End_Date__c ' +
                                     '     , Type                ' +
                                     '     , ContractId          ' +
                                     '     , Returning_Opportunity__r.ContractId ' +
                                     '     , Returning_Opportunity__c            ' +
                                     '     , RecordType.DeveloperName            ' +
                                     '     , Opportunity.netsuite_conn__Contract_Term__c ' +
                                     '     , Opportunity.netsuite_conn__Start_Date__c    ' +
                                     '  from Opportunities       ' +
                                     ' where AccountId != null   ' +
                                     '   and IsWon = true        ' +
                                     '   and Type IN :validTypes '
                                    ;
        String query = 'select Id, (' + opportunitySubQuery + ') from Account ' + additionalWhereClause;
//        System.debug('** query: ' + query);
        return Database.getQueryLocator(query);
    }

    global void finish(Database.BatchableContext BC){
//        if (!System.Test.isRunningTest()) {
//            Database.executeBatch(new OpportunityContractReturnBatch(), 200);
//        }
    }

    // Execute Logic
    global void execute(Database.BatchableContext BC, List<sObject> objects) {

        List<OpportunityContactWrapper> opportunityContactWrappers = new List<OpportunityContactWrapper>();
        Map<Id,Opportunity> opportunitiesToUpdateById = new Map<Id,Opportunity>();
//        Set<Id> opportunityIdsCheckProducts = new Set<Id>();

        Map<Id,Map<String,List<Opportunity>>> opportunitiesByPONumberByAccountId = new Map<Id,Map<String,List<Opportunity>>>();

        List<OpportunityContractAccount__c>  handledAccounts = new List<OpportunityContractAccount__c>();

        for (Account acct : (List<Account>)objects) {

            handledAccounts.add(new OpportunityContractAccount__c(Account__c = acct.Id));

            if (acct.Opportunities.isEmpty()) {
                continue;
            }

//            List<Opportunity> alreadyHandledOpportunities = new List<Opportunity>();
            Map<Date,List<Opportunity>> opportunitiesByLicenseDate = new Map<Date,List<Opportunity>>();
            Map<String,List<Opportunity>> opportunitiesByPONumber = new Map<String,List<Opportunity>>();

            // License End Date
            for (Opportunity opp : acct.Opportunities) {

                if (opp.License_End_Date__c == null) {
                    continue;
                }

                Date key = opp.License_End_Date__c;
                if (opportunitiesByLicenseDate.containsKey(key)) {
                    opportunitiesByLicenseDate.get(key).add(opp);
                } else {
                    opportunitiesByLicenseDate.put(key, new List<Opportunity>{opp});
                }
            }
            for (Date key : opportunitiesByLicenseDate.keySet()) {

                List<Opportunity> opportunities = opportunitiesByLicenseDate.get(key);
                if (opportunities.size() < 2) {
                    continue;
                }
//                alreadyHandledOpportunities.addAll(opportunities);

                Id contractId = null;
                for (Opportunity opp : opportunities) {
                    if (opp.ContractId != null) {
                        contractId = opp.ContractId;
                    }
                }
                if (contractId != null) {
                    for (Opportunity opp : opportunities) {
                        opp.ContractId = contractId;
                        opportunitiesToUpdateById.put(opp.Id, opp);
                    }
                }
                else {
                    opportunityContactWrappers.add(new OpportunityContactWrapper(opportunities, acct.Id));
                }

                for (Opportunity opp : opportunities) {

                    if (!isValidPONumber(opp.PO_Number__c)) {
                        continue;
                    }
                    if (opportunitiesByPONumber.containsKey(opp.PO_Number__c)) {
                        opportunitiesByPONumber.get(opp.PO_Number__c).add(opp);
                    } else {
                        opportunitiesByPONumber.put(opp.PO_Number__c, new List<Opportunity>{opp});
                    }
                }
            }
            opportunitiesByPONumberByAccountId.put(acct.Id, opportunitiesByPONumber);

//            // Products start with “HW-” and Quantity is > 0
//            for (Opportunity opp : acct.Opportunities) {
//
//                if (alreadyHandledOpportunities.contains(opp) || opp.License_End_Date__c != null) {
//                    continue;
//                }
//                opportunityIdsCheckProducts.add(opp.Id);
//            }
        }

        List<Contract> contractsToInsert = new List<Contract>();
        for (OpportunityContactWrapper wrapper : opportunityContactWrappers) {
            contractsToInsert.add(wrapper.contract);
        }
        insert contractsToInsert;

        for (OpportunityContactWrapper wrapper : opportunityContactWrappers) {
            for (Opportunity opp : wrapper.opportunities) {
                opp.ContractId = wrapper.contract.Id;
                opportunitiesToUpdateById.put(opp.Id, opp);
            }
        }

        // PO Number
        Map<Id,Opportunity> opportunitiesToUpdateForPONumber = executeLogicForPONumber((List<Account>)objects, opportunitiesByPONumberByAccountId, opportunitiesToUpdateById);
        if (!opportunitiesToUpdateForPONumber.isEmpty()) {
            opportunitiesToUpdateById.putAll(opportunitiesToUpdateForPONumber);
        }

//        // Products start with “HW-” and Quantity is > 0
//        Map<Id,List<Opportunity>> opportunitiesWithProductsByAccountId = getOpportunitiesWithProductsByAccountId(opportunityIdsCheckProducts);
//        Map<Id,Opportunity> opportunitiesToUpdateForProducts = executeLogicForProducts(opportunitiesWithProductsByAccountId);
//        if (!opportunitiesToUpdateForProducts.isEmpty()) {
//            opportunitiesToUpdateById.putAll(opportunitiesToUpdateForProducts);
//        }

        // Non matched / single one off Opportunities
        Map<Id,Opportunity> opportunitiesNotMatchedToUpdateById = executeLogicForNonMatchedOpportunities((List<Account>)objects, opportunitiesToUpdateById/*, opportunitiesWithProductsByAccountId*/);
        if (!opportunitiesNotMatchedToUpdateById.isEmpty()) {
            opportunitiesToUpdateById.putAll(opportunitiesNotMatchedToUpdateById);
        }

        // Match remaining with other opportunities with the closest close date
        Map<Id,Opportunity> opportunitiesMatchedByCloseDateToUpdateById = matchRemainingByClosestCloseDate((List<Account>)objects, opportunitiesToUpdateById);
        if (!opportunitiesMatchedByCloseDateToUpdateById.isEmpty()) {
            opportunitiesToUpdateById.putAll(opportunitiesMatchedByCloseDateToUpdateById);
        }

        update opportunitiesToUpdateById.values();

        updateContractEndDate(opportunitiesToUpdateById.values());

        insert handledAccounts;
    }

    // update all contracts that have had opportunities added to them
    // so that the end date / term calculated by the opportunities will include the ones that were added
    public static void updateContractEndDate(List<Opportunity> opportunities) {

        List<Contract> contractsToUpdate = new List<Contract>();

        Map<Id,List<Opportunity>> opportunitiesByContractId = new Map<Id,List<Opportunity>>();
        for (Opportunity opp : opportunities) {

            if (opportunitiesByContractId.containsKey(opp.ContractId)) {
                opportunitiesByContractId.get(opp.ContractId).add(opp);
            } else {
                opportunitiesByContractId.put(opp.ContractId, new List<Opportunity>{opp});
            }
        }

        Map<Id,Contract> contractById = new Map<Id,Contract>([select Contract_End_Date_Manual__c
                                                                   , ContractTerm
                                                                   , StartDate
                                                                from Contract
                                                               where Id IN :opportunitiesByContractId.keySet()]);

        for (Id contractId : opportunitiesByContractId.keySet()) {

            Decimal term = 1;
            Date minCloseDate = null;
            Date maxLicenseEndDate = null;
            for (Opportunity opp : opportunitiesByContractId.get(contractId)) {

                if (minCloseDate == null || opp.CloseDate < minCloseDate) {
                    minCloseDate = opp.CloseDate;
                }

                if (maxLicenseEndDate == null || (opp.License_End_Date__c != null && opp.License_End_Date__c > maxLicenseEndDate)) {
                    maxLicenseEndDate = opp.License_End_Date__c;
                }
            }

            if (minCloseDate == null || maxLicenseEndDate == null) {
                continue;
            }

            Contract contract = contractById.get(contractId);

            // if end date is different then recalculated term and update
            if (contract.Contract_End_Date_Manual__c != maxLicenseEndDate || contract.StartDate != minCloseDate) {

                term = Math.abs(minCloseDate.monthsBetween(maxLicenseEndDate));
                if (term == 0) {
                    term = 1;
                }

                contract.StartDate = minCloseDate;
                contract.ContractTerm = Integer.valueOf(term);
                contract.Contract_End_Date_Manual__c = maxLicenseEndDate;
                contractsToUpdate.add(contract);
            }
        }

        update contractsToUpdate;
    }

    private boolean isValidPONumber(String poNumber) {
        return poNumber != null && poNumber != '-' && poNumber != 'Signed Agreement';
    }

    private class OpportunityContactWrapper {
        public List<Opportunity> opportunities;
        public Contract contract;
        public Id accountId;

        public OpportunityContactWrapper(List<Opportunity> opportunities, Id accountId) {
            this.opportunities = opportunities;
            this.accountId = accountId;

            createContract();
        }

        private void createContract() {

            Decimal term = 1;
            Date minCloseDate = null;
            Date maxLicenseEndDate = null;
            for (Opportunity opp : opportunities) {

                if (minCloseDate == null || opp.CloseDate < minCloseDate) {
                    minCloseDate = opp.CloseDate;
                }

                if (maxLicenseEndDate == null || (opp.License_End_Date__c != null && opp.License_End_Date__c > maxLicenseEndDate)) {
                    maxLicenseEndDate = opp.License_End_Date__c;
                }
            }

            if (maxLicenseEndDate != null) {
                term = Math.abs(minCloseDate.monthsBetween(maxLicenseEndDate));
                if (term == 0) {
                    term = 1;
                }
            }

            this.contract = new Contract();
            this.contract.AccountId = accountId;
            this.contract.StartDate = minCloseDate == null? Date.today() : minCloseDate;
            this.contract.ContractTerm = Integer.valueOf(term);
            this.contract.Contract_End_Date_Manual__c = maxLicenseEndDate;
        }

    }

    private Map<Id,Opportunity> executeLogicForPONumber(List<Account> accounts, Map<Id,Map<String,List<Opportunity>>> opportunitiesByPONumberByAccountId, Map<Id,Opportunity> opportunitiesAlreadyToUpdateById) {

        Map<Id,Opportunity> opportunitiesToUpdateById = new Map<Id,Opportunity>();
        List<OpportunityContactWrapper> opportunityContactWrappers = new List<OpportunityContactWrapper>();

        for (Account acct : accounts) {

            if (acct.Opportunities.isEmpty()) {
                continue;
            }

            Map<String,List<Opportunity>> opportunitiesByPONumber = new Map<String,List<Opportunity>>();
            Map<String,List<Opportunity>> opportunitiesAlreadyHandledByPONumber = opportunitiesByPONumberByAccountId.get(acct.Id);

            for (Opportunity opp : acct.Opportunities) {

                // find records that are valid POs and already grouped by License End Date
                // so that new POs that match by PO Number can be added
                if (!isValidPONumber(opp.PO_Number__c) && !opportunitiesAlreadyToUpdateById.containsKey(opp.Id)) {
                    continue;
                }

                // add opportunity to the same contract that was found or created when grouped by License End Date
                if (opportunitiesAlreadyHandledByPONumber.containsKey(opp.PO_Number__c)) {
                    List<Opportunity> alreadyHandledOpportunities = opportunitiesAlreadyHandledByPONumber.get(opp.PO_Number__c);

                    // get contract that belongs to the most recent opportunity
                    Id contractId = null;
                    Datetime opportunityCreatedDate = null;
                    for (Opportunity alreadyHandledOpportunity : alreadyHandledOpportunities) {
                        if (alreadyHandledOpportunity.ContractId != null && (opportunityCreatedDate == null || alreadyHandledOpportunity.CreatedDate > opportunityCreatedDate)) {
                            contractId = alreadyHandledOpportunity.ContractId;
                            opportunityCreatedDate = alreadyHandledOpportunity.CreatedDate;
                        }
                    }
                    opp.ContractId = contractId;
                    opportunitiesToUpdateById.put(opp.Id,opp);
                    continue;
                }

                if (!isValidPONumber(opp.PO_Number__c)) {
                    continue;
                }

                // collect all other records with PO Numbers that do not match with already grouped by License End Date
                String key = opp.PO_Number__c;
                if (opportunitiesByPONumber.containsKey(key)) {
                    opportunitiesByPONumber.get(key).add(opp);
                } else {
                    opportunitiesByPONumber.put(key, new List<Opportunity>{opp});
                }
            }

            for (String key : opportunitiesByPONumber.keySet()) {

                List<Opportunity> opportunities = opportunitiesByPONumber.get(key);
                if (opportunities.size() < 2) {
                    continue;
                }

                Id contractId = null;
                for (Opportunity opp : opportunities) {
                    if (opp.ContractId != null) {
                        contractId = opp.ContractId;
                    }
                }
                if (contractId != null) {
                    for (Opportunity opp : opportunities) {
                        opp.ContractId = contractId;
                        opportunitiesToUpdateById.put(opp.Id, opp);
                    }
                }
                else {
                    opportunityContactWrappers.add(new OpportunityContactWrapper(opportunities, acct.Id));
                }
            }
        }

        List<Contract> contractsToInsert = new List<Contract>();
        for (OpportunityContactWrapper wrapper : opportunityContactWrappers) {
            contractsToInsert.add(wrapper.contract);
        }
        insert contractsToInsert;

        for (OpportunityContactWrapper wrapper : opportunityContactWrappers) {
            for (Opportunity opp : wrapper.opportunities) {
                opp.ContractId = wrapper.contract.Id;
                opportunitiesToUpdateById.put(opp.Id, opp);
            }
        }

        return opportunitiesToUpdateById;
    }

    private Map<Id,Opportunity> executeLogicForNonMatchedOpportunities(List<Account> accounts, Map<Id,Opportunity> opportunitiesAlreadyToUpdateById/*, Map<Id,List<Opportunity>> opportunitiesWithProductsByAccountId*/) {

        Map<Id,Opportunity> opportunitiesToUpdateById = new Map<Id,Opportunity>();
        List<OpportunityContactWrapper> opportunityContactWrappersForLicenseEndDate = new List<OpportunityContactWrapper>();
        List<OpportunityContactWrapper> opportunityContactWrappersForPONumber = new List<OpportunityContactWrapper>();

//        Map<Id,Opportunity> opportunityWithProductById = new Map<Id,Opportunity>();
//        for (List<Opportunity> opps : opportunitiesWithProductsByAccountId.values()) {
//            for (Opportunity opp : opps) {
//                opportunityWithProductById.put(opp.Id,opp);
//            }
//        }

        for (Account acct : accounts) {

            if (acct.Opportunities.isEmpty()) {
                continue;
            }

            for (Opportunity opp : acct.Opportunities) {

                // skip if already handled
                if (opportunitiesAlreadyToUpdateById.containsKey(opp.Id)) {
                    continue;
                }

                // skip if Contract already exists
                if (opp.ContractId != null) {
                    continue;
                }

                // Close Date & License End Date
                if (opp.License_End_Date__c != null) {
                    opportunityContactWrappersForLicenseEndDate.add(new OpportunityContactWrapper(new List<Opportunity>{opp}, acct.Id));
                }

//                // PO Number
//                else if (isValidPONumber(opp.PO_Number__c)) {
//                    opportunityContactWrappersForPONumber.add(new OpportunityContactWrapper(new List<Opportunity>{opp}, acct.Id));
//                }

//                // Products start with “HW-” and Quantity is > 0
//                else if (opportunityWithProductById.containsKey(opp.Id)) {
//                    opportunitiesToCreateContract.add(opp);
//                }
            }
        }

        List<Contract> contractsToInsert = new List<Contract>();
        for (OpportunityContactWrapper wrapper : opportunityContactWrappersForLicenseEndDate) {
            contractsToInsert.add(wrapper.contract);
        }
        for (OpportunityContactWrapper wrapper : opportunityContactWrappersForPONumber) {
            contractsToInsert.add(wrapper.contract);
        }
        insert contractsToInsert;

        for (OpportunityContactWrapper wrapper : opportunityContactWrappersForLicenseEndDate) {
            for (Opportunity opp : wrapper.opportunities) {
                opp.ContractId = wrapper.contract.Id;
                opportunitiesToUpdateById.put(opp.Id,opp);
            }
        }
        for (OpportunityContactWrapper wrapper : opportunityContactWrappersForPONumber) {
            for (Opportunity opp : wrapper.opportunities) {
                opp.ContractId = wrapper.contract.Id;
                opportunitiesToUpdateById.put(opp.Id,opp);
            }
        }
        return opportunitiesToUpdateById;

    }

//    private Map<Id,List<Opportunity>> getOpportunitiesWithProductsByAccountId(Set<Id> opportunityIds) {
//        Map<Id,List<Opportunity>> opportuniesByAccountId = new Map<Id,List<Opportunity>>();
//        for (OpportunityLineItem item : [select OpportunityId
//                                              , Opportunity.AccountId
//                                              , Opportunity.CloseDate
//                                              , Opportunity.ContractId
//                                              , Opportunity.netsuite_conn__Contract_Term__c
//                                              , Opportunity.netsuite_conn__Start_Date__c
//                                           from OpportunityLineItem
//                                          where ProductCode like 'HW-%'
//                                            and Quantity > 0
//                                            and OpportunityId IN :opportunityIds
//                                        ])
//        {
//            Id key = item.Opportunity.AccountId;
//            if (opportuniesByAccountId.containsKey(key)) {
//                opportuniesByAccountId.get(key).add(item.Opportunity);
//            } else {
//                opportuniesByAccountId.put(key, new List<Opportunity>{item.Opportunity});
//            }
//        }
//        return opportuniesByAccountId;
//    }
//
//    private Map<Id,Opportunity> executeLogicForProducts(Map<Id,List<Opportunity>> opportuniesByAccountId) {
//
//        Map<Id,Opportunity> opportunitiesToUpdateById = new Map<Id,Opportunity>();
//        List<OpportunityContactWrapper> opportunityContactWrappers = new List<OpportunityContactWrapper>();
//
//        for (Id accountId : opportuniesByAccountId.keySet()) {
//
//            Map<String, List<Opportunity>> opportunitiesByCloseDateMonthYear = new Map<String, List<Opportunity>>();
//            for (Opportunity opp : opportuniesByAccountId.get(accountId)) {
//
//                String key = opp.CloseDate.month() + '.' + opp.CloseDate.year();
//                if (opportunitiesByCloseDateMonthYear.containsKey(key)) {
//                    opportunitiesByCloseDateMonthYear.get(key).add(opp);
//                } else {
//                    opportunitiesByCloseDateMonthYear.put(key, new List<Opportunity>{opp});
//                }
//            }
//
//            for (String closeDateMonthYear : opportunitiesByCloseDateMonthYear.keySet()) {
//
//                List<Opportunity> opportunities = opportunitiesByCloseDateMonthYear.get(closeDateMonthYear);
//                if (opportunities.size() < 2) {
//                    continue;
//                }
//
//                Id contractId = null;
//                for (Opportunity opp : opportunities) {
//                    if (opp.ContractId != null) {
//                        contractId = opp.ContractId;
//                    }
//                }
//                if (contractId != null) {
//                    for (Opportunity opp : opportunities) {
//                        opp.ContractId = contractId;
//                        opportunitiesToUpdateById.put(opp.Id,opp);
//                    }
//                }
//                else {
//                    opportunityContactWrappers.add(new OpportunityContactWrapper(opportunitiesByCloseDateMonthYear.get(closeDateMonthYear), accountId));
//                }
//            }
//        }
//
//        List<Contract> contractsToInsert = new List<Contract>();
//        for (OpportunityContactWrapper wrapper : opportunityContactWrappers) {
//            contractsToInsert.add(wrapper.contract);
//        }
//        insert contractsToInsert;
//
//        for (OpportunityContactWrapper wrapper : opportunityContactWrappers) {
//            for (Opportunity opp : wrapper.opportunities) {
//                opp.ContractId = wrapper.contract.Id;
//                opportunitiesToUpdateById.put(opp.Id,opp);
//            }
//        }
//        return opportunitiesToUpdateById;
//    }

    private Map<Id,Opportunity> matchRemainingByClosestCloseDate(List<Account> accounts, Map<Id,Opportunity> opportunitiesAlreadyToUpdateById) {

        Map<Id,Opportunity> opportunitiesToUpdateById = new Map<Id,Opportunity>();
        for (Account acct : accounts) {

            if (acct.Opportunities.isEmpty()) {
                continue;
            }

            List<Date> closeDatesWithContract = new List<Date>();
            List<Date> closeDatesWithoutContract = new List<Date>();
            Map<Date,Id> contractIdByCloseDate = new Map<Date,Id>();
            Map<Date,List<Opportunity>> opportunitiesWithContractByCloseDate = new Map<Date,List<Opportunity>>();
            Map<Date,List<Opportunity>> opportunitiesWithoutContractByCloseDate = new Map<Date,List<Opportunity>>();

            for (Opportunity opp : acct.Opportunities) {

                Opportunity alreadyHandledOpportunity = opportunitiesAlreadyToUpdateById.get(opp.Id);
                if ((alreadyHandledOpportunity != null && alreadyHandledOpportunity.ContractId != null) || opp.ContractId != null ) {

                    Opportunity opportunityWithContract = alreadyHandledOpportunity;
                    if (alreadyHandledOpportunity == null || opportunityWithContract.ContractId == null) {
                        opportunityWithContract = opp;
                    }

                    closeDatesWithContract.add(opportunityWithContract.CloseDate);
                    if (opportunitiesWithContractByCloseDate.containsKey(opportunityWithContract.CloseDate)) {
                        opportunitiesWithContractByCloseDate.get(opportunityWithContract.CloseDate).add(opportunityWithContract);
                    } else {
                        opportunitiesWithContractByCloseDate.put(opportunityWithContract.CloseDate, new List<Opportunity>{opportunityWithContract});
                    }

                } else if (opp.ContractId == null) {

                    closeDatesWithoutContract.add(opp.CloseDate);
                    if (opportunitiesWithoutContractByCloseDate.containsKey(opp.CloseDate)) {
                        opportunitiesWithoutContractByCloseDate.get(opp.CloseDate).add(opp);
                    } else {
                        opportunitiesWithoutContractByCloseDate.put(opp.CloseDate, new List<Opportunity>{opp});
                    }
                }
            }

            if (closeDatesWithContract.isEmpty() || closeDatesWithoutContract.isEmpty()) {
                continue;
            }

            closeDatesWithContract.sort();
            closeDatesWithoutContract.sort();

//            List<Date> closeDatesWithContractReverse = new List<Date>();
//            for(Integer i = closeDatesWithContract.size() - 1; i >= 0; i--){
//                closeDatesWithContractReverse.add(closeDatesWithContract[i]);
//            }

            for (Date closeDateWithoutContract : closeDatesWithoutContract) {

                for (Date closeDateWithContract : closeDatesWithContract) {

                    if (closeDateWithoutContract >= closeDateWithContract) {
                        List<Opportunity> opportunityWithContract = opportunitiesWithContractByCloseDate.get(closeDateWithContract);
                        contractIdByCloseDate.put(closeDateWithoutContract,opportunityWithContract.get(0).ContractId);
                    }
                }
            }

            for (Date closeDateWithoutContract : opportunitiesWithoutContractByCloseDate.keySet()) {

                if (!contractIdByCloseDate.containsKey(closeDateWithoutContract)) {
                    continue;
                }
                Id contractId = contractIdByCloseDate.get(closeDateWithoutContract);
                for (Opportunity opp : opportunitiesWithoutContractByCloseDate.get(closeDateWithoutContract)) {
                    opp.ContractId = contractId;
                    opportunitiesToUpdateById.put(opp.Id,opp);
                }
            }
        }

        return opportunitiesToUpdateById;
    }
}