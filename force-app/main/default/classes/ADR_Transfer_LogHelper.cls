/**
 * @author Groundswell - Vikasm - vikas@gscloudsolutions.com
 * @date 2020-08-24
 * @lastModified 2020-08-25
 */
public with sharing class ADR_Transfer_LogHelper
{
    List<Opportunity> OpportunitiesToUpdate ;
    Set<string> opportunitiesIdSet ;
    Map<String,Rollup_Switch__mdt> mapOFRollupFieldVsMetadata = new Map<String,Rollup_Switch__mdt> ();
    Map<Id,User> ownerMap = new Map<Id,User>();

    public ADR_Transfer_LogHelper ()
    {
        OpportunitiesToUpdate = new List<Opportunity>();
        opportunitiesIdSet = new set<string>();
        
    }
    
    public void copyTransferPoints(List<ADR_Transfer_Log__c> newADRTransferList) {

        ownerMap = getOwnerData(newADRTransferList);

        for (ADR_Transfer_Log__c record : newADRTransferList) {
            User owner = ownerMap.get(record.OwnerId);
        	Boolean isAE2EMEA = owner != null && 
                            owner.ADR_Segment_Alignment__c == 'AE2' && 
                            owner.UserRole != null && 
                            owner.UserRole.Name != null && 
                            owner.UserRole.Name.contains('EMEA');
            if (record.Transfer_Points__c != null && (ownerMap.get(record.OwnerId)?.ADR_Segment_Alignment__c != 'AE2' || isAE2EMEA))
                record.Transfer_Points_At_Transfer_Copy__c = record.Transfer_Points__c;
        }
    }

    public void rollupAdrOnOpportunity(List<ADR_Transfer_Log__c> adrTransferList )
    {
        mapOFRollupFieldVsMetadata = RollUpSwitchService.getRollupSwitchMetadata('Opportunity', 'ADR_Transfer_Log__c');
        if (mapOFRollupFieldVsMetadata.isEmpty() || (!mapOFRollupFieldVsMetadata.isEmpty() && !mapOFRollupFieldVsMetadata.ContainsKey('ADR_Transfer__c'))) {
            return;
        }
        
        for(ADR_Transfer_Log__c record : adrTransferList )
        {
            opportunitiesIdSet.add(record.Opportunity__c);
        }
        processOpportunity();
        
    }

    public void rollupAdrOnOpportunity(Map<Id, ADR_Transfer_Log__c>  oldADRTransferMap, List<ADR_Transfer_Log__c> newADRTransferList )
    {
        
        for(ADR_Transfer_Log__c record : newADRTransferList )
        {
           if(oldADRTransferMap.containsKey(record.Id) 
                && record.Opportunity__c !=oldADRTransferMap.get(record.Id).Opportunity__c)
                {
                    if(record.Opportunity__c != null)
                    opportunitiesIdSet.add(record.Opportunity__c);
                    opportunitiesIdSet.add(oldADRTransferMap.get(record.Id).Opportunity__c);
                }
            
        }
        processOpportunity();

    }

    private void processOpportunity()
    {
        for(Opportunity thisOpp: [SELECT Id , ADR_Transfer__c,
                                    (SELECT Id FROM ADR_Transfer_Logs__r 
                                    ORDER BY CreatedDate ASC LIMIT 1) 
                                    FROM Opportunity 
                                    WHERE Id IN :opportunitiesIdSet])
         {
            if(thisOpp.ADR_Transfer_Logs__r.isEmpty() )
            {
                thisOpp.ADR_Transfer__c = null;
            }
            else
            {
                if(thisOpp.ADR_Transfer__c != thisOpp.ADR_Transfer_Logs__r[0].Id)
                {
                    thisOpp.ADR_Transfer__c = thisOpp.ADR_Transfer_Logs__r[0].Id;
                    
                }
            }
            OpportunitiesToUpdate.add(thisOpp);
                
         }
         DMLWrapper.doUpdate(OpportunitiesToUpdate);
    }

    public map<Id,User> getOwnerData(List<ADR_Transfer_Log__c> newADRTransferList){

        Set<Id> ownerIds = new Set<Id>();

        for(ADR_Transfer_Log__c adrRec : newADRTransferList){
            ownerIds.add(adrRec.OwnerId);
        }

        return new Map<Id,User>([SELECT Id, ADR_Segment_Alignment__c, UserRole.Name FROM User WHERE Id in :ownerIds]);
    }
}