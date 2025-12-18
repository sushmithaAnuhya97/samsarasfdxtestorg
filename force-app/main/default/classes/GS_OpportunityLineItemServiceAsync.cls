/**
* Created By : Groundswell - Suman Kundu
* @Date September 21, 2021
*
* @description : This class will be responsible for handling Async Actions on OpportunityLineItem
* SFA-11
*
**/

public with sharing class GS_OpportunityLineItemServiceAsync extends BaseAsyncHandler{
    gslib_IModuleLogger thisModuleLogger = gslib_LoggerService.getModuleLogger('GTMS');
    gslib_ILogger thisLogger = thisModuleLogger.getLogger(); 
    public override String getRequestType(){
        return 'OpportunityLineItem Service Async Job';
    } 
    
    List<Schema.SObjectType> MY_SOBJECTS = new List<Schema.SObjectType>{
        OpportunityLineItem.SObjectType
    };
                
    UnitOfWork uow = new UnitOfWork(MY_SOBJECTS);
    @TestVisible List<Id> recordsIds = new List<Id>();
    private Options option;
    
    public override void execute(Async_Request__c ar) {
        recordsIds = ar.Params__c.split(PARAMETERS_SPLITTER);
        if(recordsIds.isEmpty()) return;
        option = (Options) JSON.deserialize(ar.Options__c, Options.class);
        
        // Do something with Quote Records
        try {
            thisLogger.logTrace('Entering in GS_OpportunityLineItemServiceAsync');
            System.debug('****option.Operation> '+option.Operation);
            switch on option.Operation {
                when 'calculateAllRollUpsToOpportunity' {
                    calculateAllRollUpsToOpportunity();
                }
            }
        } catch(Exception ex) {
            thisLogger.logError(
                'Error in GS_SBQQQuoteServiceAsync::',
                new SamsaraLoggerObjectMVP(
                    ex, recordsIds
                )
            );
            throw ex;
        }finally{
            thisLogger.dispatch();
        }
    }

    public void calculateAllRollUpsToOpportunity() {
        DMLWrapper.intializeUnitOfWork(new List<Schema.SObjectType>{
            Opportunity.SObjectType
        });
        Map<string, Map<String, List<OpportunityLineItem>>> mapOfRollupFiledVsRecordList = new Map<string, Map<String, List<OpportunityLineItem>>> ();
		Map<String, Rollup_Switch__mdt> mapOFRollupFieldVsMetadata = RollUpSwitchService.getRollupSwitchMetadata('Opportunity', 'OpportunityLineItem');
        List<OpportunityLineItem> targetOlis = [
            SELECT Id,Related_Shipping_Address_Name__c, Product2.Family, ACV_Total_Price_Bookings__c, OpportunityId
            FROM OpportunityLineItem
            WHERE OpportunityId IN :recordsIds
		];
        for (String OppId : recordsIds) {
			for (String rollUpField : mapOFRollupFieldVsMetadata.KeySet()) {
				if (!mapOfRollupFiledVsRecordList.ContainsKey(rollUpField)) mapOfRollupFiledVsRecordList.put(rollUpField, new Map<String, List<OpportunityLineItem>>());
				if (!mapOfRollupFiledVsRecordList.get(rollUpField).containsKey(OppId))
					mapOfRollupFiledVsRecordList.get(rollUpField).put(OppId, new List<OpportunityLineItem>());
			}
		}

		for (OpportunityLineItem thisOLI : targetOlis) {

			for (String rollUpField : mapOFRollupFieldVsMetadata.KeySet()) {
				Callable callInstance = (Callable) Type.forName('OpportunityLineItemHelper').newInstance();
				if ((Boolean) callInstance.call(rollUpField, new map<String, Object>{
						'newRecord' => thisOLI
				})) {
					if (!mapOfRollupFiledVsRecordList.ContainsKey(rollUpField)) mapOfRollupFiledVsRecordList.put(rollUpField, new Map<String, List<OpportunityLineItem>>());
					if (!mapOfRollupFiledVsRecordList.get(rollUpField).containsKey(thisOLI.OpportunityId))
						mapOfRollupFiledVsRecordList.get(rollUpField).put(thisOli.OpportunityId, new List<OpportunityLineItem>());

					mapOfRollupFiledVsRecordList.get(rollUpField).get(thisOli.OpportunityId).add(thisOLI);
				}
			}
		}
        System.debug('####mapOfRollupFiledVsRecordList> '+mapOfRollupFiledVsRecordList);

		for (String rollupField : mapOFRollupFieldVsMetadata.KeySet()) {
			if (!mapOfRollupFiledVsRecordList.containsKey(rollupField)) {
				continue;
			}
			Schema.SobjectField theDirtyField = Schema.getGlobalDescribe().get('Opportunity').getDescribe().fields.getMap().get(rollupField);
			for (String OpportunityId : mapOfRollupFiledVsRecordList.get(rollupField).keySet()) {
				Opportunity thisOpportunity = new Opportunity(Id = OpportunityId);
				if (mapOfRollupFiledVsRecordList.get(rollupField).get(OpportunityId).isEmpty()) {
					thisOpportunity.put(rollupField, null);
					DMLWrapper.doUpdate(thisOpportunity, new List<SobjectField>{
                        theDirtyField
					});
					continue;
				}

				Callable callInstance = (Callable) Type.forName('OpportunityLineItemHelper').newInstance();
				if (mapOFRollupFieldVsMetadata.get(rollupField).Type__c == 'COUNT DISTINCT') {
					Object result = callInstance.call('COUNT DISTINCT', new map<String, Object>{
                        'recordList' => mapOfRollupFiledVsRecordList.get(rollupField).get(OpportunityId), 'field' => mapOFRollupFieldVsMetadata.get(rollupField).Rollup_Field__c
					});
					thisOpportunity.put(rollupField, (Decimal) result);
				}
				//Groundswell : Nilesh Jain - Changes done as a part of GTMS-3247
				else if (mapOFRollupFieldVsMetadata.get(rollupField).Type__c == 'SUM') {
					object result = callInstance.call('SUM', new map<String, Object>{
                        'recordList' => mapOfRollupFiledVsRecordList.get(rollupField).get(OpportunityId), 'field' => mapOFRollupFieldVsMetadata.get(rollupField).Rollup_Field__c
					});
					thisOpportunity.put(rollupField, (Decimal) result);
				}
				//End
				DMLWrapper.doUpdate(thisOpportunity, new List<SobjectField>{
                    theDirtyField
				});
			}
		}
        DMLWrapper.publishDML();
    }

    public class Options {
        public String Operation {get; set;}
        
        public Options(String operation){
            this.Operation = operation;
        }
    }
}