public class AdrTransferOpportunityLinkBatch implements Database.Batchable<SObject>, Database.Stateful {
    private Set<String> processedKeys = new Set<String>();

    public Database.QueryLocator start(Database.BatchableContext bc) {
        String baseQuery = 'SELECT Id, ADR_Transfer__c, AccountId, Related_Contact__c, CreatedDate '+
                            'FROM Opportunity ' +
                            'WHERE AccountId != null AND Related_Contact__c != null AND ADR_Transfer__c = null';

        String filter = System.Label.ADR_Opp_Link_Batch_Opp_Filter;
        if (String.isNotBlank(filter)) {
            baseQuery += filter.trim().startsWithIgnoreCase('AND') ? ' ' + filter : ' AND ' + filter;
        }
        return Database.getQueryLocator(baseQuery);
    }

    public void execute(Database.BatchableContext bc, List<Opportunity> scope) {
        if (scope.isEmpty()) return;
        try {
            Map<String, List<Opportunity>> oppMap = new Map<String, List<Opportunity>>(); 
            Set<Id> accIds = new Set<Id>();
            Set<Id> conIds = new Set<Id>();

			for (Opportunity opp : scope) {
                String key = opp.AccountId + '-' + opp.Related_Contact__c;
                if (processedKeys.contains(key)) continue;

                accIds.add(opp.AccountId);
                conIds.add(opp.Related_Contact__c);
            }
            if (accIds.isEmpty() || conIds.isEmpty()) return;

            String baseQuery = 'SELECT Id, ADR_Transfer__c, AccountId, Related_Contact__c, CreatedDate ' +
                               'FROM Opportunity ' +
                               'WHERE ADR_Transfer__c = null AND AccountId IN :accIds AND Related_Contact__c IN :conIds';
            String filter = System.Label.ADR_Opp_Link_Batch_Opp_Filter;
            if (String.isNotBlank(filter)) {
                baseQuery += filter.trim().startsWithIgnoreCase('AND') ? ' ' + filter : ' AND ' + filter;
            }

            List<Opportunity> oppListAll = Database.query(baseQuery);

			for (Opportunity opp : oppListAll) {
                String key = opp.AccountId + '-' + opp.Related_Contact__c;
                if (processedKeys.contains(key)) continue;

                // Fix: oppMap stores List<Opportunity>, so use .isEmpty() instead of .CreatedDate
                if (!oppMap.containsKey(key)) {
                    oppMap.put(key, new List<Opportunity>());
                }
                oppMap.get(key).add(opp);
            }
            if (oppMap.isEmpty()) return;

			String atlBase = 'SELECT Id, Account__c, Contact__c, ADR_Transfer_Date__c, CreatedDate, Opportunity__c ' +
						   'FROM ADR_Transfer_Log__c ' +
						   'WHERE Account__c IN :accIds ' +
						   'AND Contact__c IN :conIds ' +
                           'AND Opportunity__c = null';

			String atlFilter = System.Label.ADR_Opp_Link_Batch_ADR_Filter;
			if (String.isNotBlank(atlFilter)) {
				atlBase += atlFilter.trim().startsWithIgnoreCase('AND') ? ' ' + atlFilter : ' AND ' + atlFilter;
			}

			List<ADR_Transfer_Log__c> atls = Database.query(atlBase);

            Map<String, List<ADR_Transfer_Log__c>> atlMap = new Map<String, List<ADR_Transfer_Log__c>>();

			for (ADR_Transfer_Log__c atl : atls) {
                String key = atl.Account__c + '-' + atl.Contact__c;

                if (processedKeys.contains(key)) continue;

                if (!atlMap.containsKey(key)) {
                    atlMap.put(key, new List<ADR_Transfer_Log__c>());
                }
                atlMap.get(key).add(atl);
            }
            if (atlMap.isEmpty()) return;

			Map<Id, Opportunity> linkedOpps = new Map<Id, Opportunity>();
			Map<Id, ADR_Transfer_Log__c> linkedAdrs = new Map<Id, ADR_Transfer_Log__c>();

			for (String key : oppMap.keySet()) {
				List<Opportunity> oppList = oppMap.get(key);
				List<ADR_Transfer_Log__c> adrList = atlMap.get(key);

				if (oppList == null || oppList.isEmpty() || adrList == null || adrList.isEmpty() || processedKeys.contains(key)) {
					continue;
				}

				// For each ADR (earliest first), find the earliest Opportunity that falls within (ADR_Date, ADR_Date + 90)
				for (ADR_Transfer_Log__c adr : adrList) {
					if (linkedAdrs.containsKey(adr.Id)) {
						continue;
					}
                    // Get adr date for comparision with opportunity. If ADR Transfer Date is null use CreatedDate as fallback.
					Date adrDate = adr.ADR_Transfer_Date__c != null? adr.ADR_Transfer_Date__c.date() : adr.CreatedDate.date();

					Opportunity match = null;
					for (Opportunity opp : oppList) {
						if (linkedOpps.containsKey(opp.Id)) {
							continue;
						}
						Date oppDate = opp.CreatedDate == null ? null : opp.CreatedDate.date();
						if (oppDate == null) {
							continue;
						}
						if (oppDate > adrDate && oppDate < adrDate.addDays(90)) {
							match = opp;
							break; // earliest opp due to ordering
						}
					}

					if (match != null) {
						match.ADR_Transfer__c = adr.Id;
						adr.Opportunity__c = match.Id;
						linkedOpps.put(match.Id, match);
						linkedAdrs.put(adr.Id, adr);
					}
				}

				processedKeys.add(key);
			}

            TriggerHandler.bypass('OpportunityTriggerHandlerContext');
            TriggerHandler.bypass('OpportunityTriggerHandler');
			if (!linkedOpps.isEmpty()) update linkedOpps.values();
			if (!linkedAdrs.isEmpty()) update linkedAdrs.values();

        } catch (Exception e) {
            String errorMessage = 'Exception in execute method: ' + e.getMessage() + '\n' + e.getStackTraceString();
            System.debug(errorMessage);
            Logger.atError()
                .setClassName('AdrTransferOpportunityLinkBatch')
                .setMethod('execute')
                .setRecordId(null)
                .setExceptionOrMessage(e);
            Logger.insertMasterLogs();
        }
    }

    public void finish(Database.BatchableContext bc) {
        System.debug('Batch finished successfully. Processed Keys: ' + processedKeys.size());
    }
}