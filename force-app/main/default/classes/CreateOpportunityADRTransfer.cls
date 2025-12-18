/* 
* June 18th, 2020 (GTMS-942) adrCampaignAttribution (Add query prams to auxADRTransfer object to ensure that logic executes with Second pass transfers)
*/

public class CreateOpportunityADRTransfer {
    public static ADR_Transfer_Log__c adrTransfer;
    public static ADR_Transfer_Log__c auxADRTransfer;
    public static Contact currentContact;
    public static Account currentAccount;
    
    //* June 18th, 2020 (GTMS-942) adrCampaignAttribution (Add query prams to auxADRTransfer object to ensure that logic executes with Second pass transfers)
	@InvocableMethod
    public static void adrCampaignAttribution(List<String> adrTransferIds){
        List<String> oppIds = new List<String>();
        
        adrTransfer = [SELECT  Id,
                               ADR_Role_Copy__c,
                               Contact__c,
                               Account__c
                       FROM ADR_Transfer_Log__c 
                       WHERE Id = :adrTransferIds[0] 
                       LIMIT 1];
        
        currentContact = [SELECT  Id, 
                                  Campaign_to_Add__c, 
                                  Campaign_Member_Status__c
                          FROM Contact 
                          WHERE Id = :adrTransfer.Contact__c
                          LIMIT 1];
        
		auxADRTransfer = [ SELECT Id,
                                  ADR_Transfer__c,
                                  ADR_Transfer_By__c,
                                  ADR_Transfer_By__r.FirstName,
                                  ADR_Transfer_By__r.LastName,
                                  ADR_Transfer_By__r.Email,
                                  ADR_Transfer_Status__c,
                                  ADR_Accepted_Date__c,
                                  ADR_Role_Copy__c
                            FROM ADR_Transfer_Log__c
                            WHERE Contact__c = : currentContact.Id
                            AND (ADR_Demo_Date__c = LAST_N_DAYS:30
                            OR Second_Meeting_Date__c = LAST_N_DAYS:30)
                            AND ADR_Transfer__c = false
                            ORDER BY CreatedDate DESC
                            LIMIT 1];
        
        if(auxADRTransfer != null){
            createOutboundADRCampaign();
        }
    } 
    
    public static void createOutboundADRCampaign(){
        // ADR campaign logic. If campaign exists and has HasResponded = False, then change to Responded. Otherwise, attach ADR generic campaign.
        // for Logic please refer to https://docs.google.com/document/d/14O1pP4ivj08Y9I2b94pSVT_nTKOQFBQCMXylcqNsf2w/edit
        List<CampaignMember> inboundCampaigns = [SELECT Id, 
                                                        ContactId, 
                                                        Status, 
                                                        CampaignId 
                                                FROM CampaignMember 
                                                WHERE ContactId =: currentContact.Id 
                                                AND FirstRespondedDate = LAST_N_DAYS:90 
                                                AND Master_Campaign_Name__c Like '%Inbound%' 
                                                LIMIT 1]; 
        
        if (inboundCampaigns.size() == 0 && auxADRTransfer != null){
        
            // in case it's there's an Inbound ADR transfer but no recent inbound campaigns, create a (Child) ADR - Inbound campaign
            if (auxADRTransfer.ADR_Role_Copy__c.contains('IB')){
                 List <Campaign> adrInboundCampaign = [ SELECT Id 
                                                        FROM Campaign 
                                                        WHERE Name = '(Child) ADR Inbound' 
                                                        LIMIT 1];
                 
                 if (adrInboundCampaign.size() > 0){
                     currentContact.Campaign_to_Add__c = adrInboundCampaign[0].Id;
                     currentContact.Campaign_Member_Status__c = 'Responded';
                 } else{
                     Campaign newInboundADRCampaign= new Campaign(Name='(Child) ADR Inbound');
                     newInboundADRCampaign.Type = 'Sales - ADR Outbound';
                     insert newInboundADRCampaign;
                     currentContact.Campaign_to_Add__c = newInboundADRCampaign.Id;
                     currentContact.Campaign_Member_Status__c = 'Responded';
                 }
                
            } else {
                // if it's not an Inbound ADR, check if there are any growth campaigns in the last 90 days and change the status of the most recent one to Responded. Otherwise attach a generic ADR campaign
                List<CampaignMember> relatedCampaigns = [SELECT Id, 
                                                                ContactId, 
                                                                Status, 
                                                                CampaignId 
                                                        FROM CampaignMember 
                                                        WHERE ContactId =: currentContact.Id 
                                                        AND CreatedDate = LAST_N_DAYS:90 
                                                        AND HasResponded = False 
                                                        AND Campaign.Type = 'Sales - ADR Outbound' 
                                                        ORDER BY CreatedDate DESC 
                                                        LIMIT 1];
                if (relatedCampaigns.size() == 0){
                     List <Campaign> adrCampaign = [SELECT Id 
                                                    FROM Campaign 
                                                    WHERE Name LIKE '(Child) ADR Outbound' 
                                                    LIMIT 1];
                     if (adrCampaign.size() > 0){
                         currentContact.Campaign_to_Add__c = adrCampaign[0].Id;
                         currentContact.Campaign_Member_Status__c = 'Responded';
                     } else{
                         Campaign newADRCampaign= new Campaign(Name='(Child) ADR Outbound');
                         newADRCampaign.Type = 'Sales - ADR Outbound';
                         insert newADRCampaign;
                         currentContact.Campaign_to_Add__c = newADRCampaign.Id;
                         currentContact.Campaign_Member_Status__c = 'Responded';
                     }
                } else {
                    relatedCampaigns[0].Status = 'Responded';
                    update relatedCampaigns[0];
                     
                }
            }
            
            update currentContact;
        }
    }
}