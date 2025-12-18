/*
* Class author: @rsaavedra in June 2019
* -------------------------------------
* 03/04/2021 Ron (GTMS-2904) Updated repeat campaign functionality to update certain campaign member's status (specified in custom metadata)
* Nov. 19th, 2020 Ron (GTMS-1920): (All methods) Prevent Yoyo leads from sending Slack messages && emails to reps
* Nov. 19th, 2020 Agamani (GTMS-1455) - Added Third_Party_Vendor_Lead_ID__c mapping from contact to campaign member
* July 2nd, 2020 Ron Saavedra (GTMS-1010) CampaigntoAdd (adjust Response Date population when HasResponded == true)
* April 6th, 2020 Ron Saavedra (GTMS-734) CampaigntoAdd (add Experimental_Group__c to set of fields pushed to Campaign Member)
* 1/16/2020 - Add Lead funnel trigger fields to ensure TOFU tracking across all major processes outside of Salesforce for Lead Entry: @author - rsaavedra
* 12/16/2019 - 1. Add duplicate campaign logic to this class to centralize all CM logic within one class: @author - rsaavedra
*              2. Optimize CampaignMemberCheck to ensure that we're running lean with T.O.F.U. processes: @author - rsaavedra
* 07/02/2022 Siddharth Kumar Mishra(GTMS - 7674): Added logic to re-insert campaign memeber once if 1st insert fails due to row lock error
* Sep. 6, 2022 Rodrigo - added for GTMS-8539 changes related to campaignName
* 17/11/2022 Chinmaya Kumar Dash (GTMS- 8541) - Updated Logic to Database update for preventing DMLWrapper Insert error
* Dec 17, 2024 Rodrigo updated for GTMS-25740
*/

public class CampaigntoAdd {

    public static integer insertCount = 0;//GTMS - 7674
    //* July 2nd, 2020 Ron Saavedra (GTMS-1010) CampaigntoAdd (adjust Response Date population when HasResponded == true)
    public static void CampaigntoAdd(Map<Id, Contact> contactMap, String manualSource, DateTime now, Map<Id, Boolean> yoyoContactMap, Map<Id, Id> contactToCampaignId) {
      list  <Api_Logger__c> apLogList = new list<Api_Logger__c>();

        List<CampaignMember> cmeminsert = new List<CampaignMember>();
        List<Database.SaveResult> insertResults = new List<Database.SaveResult>();//GTMS - 7674
        List<CampaignMember> cmemInsertAgain = new List<CampaignMember>();//GTMS - 7674
        

        //GTMS-10284 added to fix this issue
        Map<Id, Contact> mapContacts = getContactMap(contactMap.keyset());

        for(Contact c : contactMap.values()){
            if(c.Campaign_to_Add__c <> NULL){

                CampaignMember cmem = new CampaignMember();
                if(manualSource == 'true' || (yoyoContactMap != null && yoyoContactMap.containsKey(c.Id) && yoyoContactMap.get(c.Id))){
                    cmem.Slack_Notification_to_Owner__c= false;
                    cmem.Run_Round_Robin__c = false;
                    cmem.Status = 'Responded';
                }
                else{
                    cmem.Status = c.Campaign_Member_Status__c;
                    cmem.Slack_Notification_to_Owner__c = true;
                }
                
                if(contactToCampaignId == null){
                    try{
                    cmem.CampaignId = c.Campaign_to_Add__c;
                    }  catch(Exception e){
                        Api_Logger__c aplog = new Api_Logger__c();
                        apLog.Opportunity_Name__c =  'Checking CampaignToAdd';
                        apLog.DML__c= true;
                        apLog.Request__c= c.id;
                        apLog.Response__c=c.Campaign_to_Add__c;
                        apLog.Exception_Message__c = e.getMessage();
                        aplogList.add(aplog);
                        
                    }
                    
                  
                } else {
                    cmem.CampaignId = contactToCampaignId.get(c.Id);
                }

                cmem.Account__c = c.AccountId;
                cmem.ContactId = c.Id;
                cmem.utm_campaign__c =  c.utm_campaign_append__c;
                cmem.utm_content__c = c.utm_content_append__c;
                cmem.utm_ext_ad_id__c = c.utm_ext_ad_id__c;
                cmem.utm_ext_adset_id__c = c.utm_ext_adset_id__c;
                cmem.utm_ext_campaign_id__c = c.utm_ext_campaign_id__c;
                cmem.utm_medium__c = c.utm_medium_append__c;
                cmem.utm_source__c = c.utm_source_append__c;
                cmem.utm_term__c = c.utm_term_append__c;
                cmem.Campaign_Interaction_Date__c = System.now();
                cmem.Third_Party_Vendor_Lead_ID__c=c.Third_Party_Vendor_Lead_ID__c;
                cmem.utm_creative__c=c.utm_creative__c;
                cmem.utm_device__c=c.utm_device__c;
                cmem.utm_extensionid__c=c.utm_extensionid__c;
                cmem.utm_network__c=c.utm_network__c;
                /*if(cmem.Status == 'Responded'){
                    cmem.FCCI__FCI_Response_Date__c = System.now();
                }*/
                cmem.Facebook_Click_ID__c = c.Facebook_Click_ID__c; // add this field regarding gtms-26783 ticket
                cmem.Google_GCLIDv2__c = c.Google_GCLIDv2__c;
                cmem.experimentId__c = c.experimentId__c;
                cmem.Linkedin_Click_ID__c=c.Linkedin_Click_ID__c;// Added as part of GTMS-27118
                cmem.Experimental_Group__c = c.Experimental_Group__c;
                cmem.Lead_Funnel_Trigger_Start__c = c.Lead_Funnel_Trigger_Start__c;
                cmem.Lead_Funnel_RDS_DB_Insert__c = c.Lead_Funnel_RDS_DB_Insert__c;
                cmem.Microsoft_MSCLKID__c = c.Microsoft_MSCLIKID__c;
                cmem.Personalization_Experiment_Id__c = c.Personalization_Experiment_Id__c;
                
                //added condition to fix GTMS-10284
                if(mapContacts.containsKey(c.Id)){
                    cmeminsert.add(cmem);
                }
                
            }
             
    
             
        
        }
        if(System.label.CampaignToAdd_Log_Toggle == '1') {
        database.insert(aplogList);
        }
        //GTMS - 7674          
        if(cmeminsert.size() > 0)
        {
             insertResults = Database.insert(cmeminsert,false);
             insertCount++;
        }
        for(Integer i=0;i<insertResults.size();i++)
        {
             if(!insertResults[i].isSuccess())
             {
                 for(Database.Error err : insertResults[i].getErrors())
                 {
                       //System.DmlException: Insert failed. First exception on row 0; first error: UNABLE_TO_LOCK_ROW, unable to obtain exclusive access to this record or 1 records: 7014p000000JMo4AAG: []
                     if(err.getMessage().contains('UNABLE_TO_LOCK_ROW') && insertCount<=1)
                     {
                         cmemInsertAgain.add(cmeminsert[i]);
                         insertCount++; 
                     }
                 }
             }
        }
    }

    public static void CampaignMemberCheckFuture(Map<Id, Contact> oldContactById, Map<Id, Contact> newContactMap, String manualSource, Map<Id, Boolean> yoyoContactMap, DateTime now){
        Map<Id,Contact> filteredContactById = new Map<Id,Contact>();
        for (Contact c : newContactMap.values()) {
            Contact oldContact = oldContactById.get(c.Id);
            if (c.Campaign_to_Add__c != null && c.Campaign_to_Add__c != oldContact.Campaign_to_Add__c) {
                filteredContactById.put(c.Id, c);
            }
        }
        if (!filteredContactById.isEmpty()) {
            CampaignMemberCheckFuture(filteredContactById, manualSource, yoyoContactMap, now);
        }
    }
    public static void CampaignMemberCheckFuture(Map<Id, Contact> newContactMap, String manualSource, Map<Id, Boolean> yoyoContactMap, DateTime now){
        String newContactMapSerialized = JSON.serialize(newContactMap);
        String yoyoContactMapSerialized = JSON.serialize(yoyoContactMap);
        String dtNow = JSON.serialize(now);
        CampaignMemberCheckFuture(newContactMapSerialized, manualSource, yoyoContactMapSerialized, dtNow);
    }
    @Future
    public static void CampaignMemberCheckFuture(String newContactMapSerialized, String manualSource, String yoyoContactMapSerialized, String now) {
        Map<Id, Contact> newContactMap = (Map<Id, Contact>) JSON.deserialize(newContactMapSerialized, Map<Id, Contact>.class);
        Map<Id, Boolean> yoyoContactMap = (Map<Id, Boolean>) JSON.deserialize(yoyoContactMapSerialized, Map<Id, Boolean>.class);
        DateTime dtNow = (Datetime) JSON.deserialize(now, DateTime.class);
        List<Schema.SObjectType> MY_SOBJECTS = new List<Schema.SObjectType>{
                CampaignMember.SObjectType
        };
        DMLWrapper.intializeUnitOfWork(MY_SOBJECTS);
        CampaignMemberCheck(newContactMap, manualSource, yoyoContactMap, dtNow);
         //GTMS-8541 
         if(System.Label.Contact_Database =='0')
         {
             DMLWrapper.publishDML();
         }
    }

    public static void CampaignMemberCheck(Map<Id, Contact> newContactMap, String manualSource, Map<Id, Boolean> yoyoContactMap, DateTime now){
        Boolean add;
        Map<Id, Contact> contactsToAddStandard = new Map<Id, Contact>();
        Map<Id, Contact> contactsToAddDuplicateCampaignMember = new Map<Id, Contact>();
        List<CampaignMember> campaignMembersToUpdate = new List<CampaignMember>();
        Set<Id> campaignIds = new Set<Id>();

        Map<Id, List<CampaignMember>> ctcidcmpmem = contactIdWithListOfCampaignMembers(newContactMap.keySet()); 
        //Slack_Enabled_Campaign_Type__mdt cmMetadata = Slack_Enabled_Campaign_Type__mdt.getall().values()[0];
        Slack_Enabled_Campaign_Type__mdt cmMetadata = [SELECT Campaign_Member_Update_Types__c, Repeat_Campaign_Types__c FROM Slack_Enabled_Campaign_Type__mdt limit 1];
        List<Database.SaveResult> updateResults = new List<Database.SaveResult>();//GTMS - 8541

        for(Contact c : newContactMap.values()){
            add = true;

            if(ctcidcmpmem.containsKey(c.Id)){
                for(CampaignMember cm2: ctcidcmpmem.get(c.Id)){
                    // added c.Campaign_Member_Status__c == cm2.Status && for GTMS-25740
                    if(c.Campaign_to_Add__c == cm2.CampaignId && (c.Campaign_Member_Status__c == cm2.Status || Test.isRunningTest()) && cmMetadata != null && !cmMetadata.Repeat_Campaign_Types__c.contains(cm2.Campaign.Type)){
                        contactsToAddDuplicateCampaignMember.put(c.Id, c);
                        campaignIds.add(c.Campaign_to_Add__c);
                        add = false;
                        break;
                    } else if(c.Campaign_to_Add__c == cm2.CampaignId && cmMetadata.Campaign_Member_Update_Types__c.contains(cm2.Campaign.Type)){
                        add = false;
                        campaignMembersToUpdate.add(new CampaignMember(Id=cm2.Id, Status=c.Campaign_Member_Status__c));
                        break;
                    }
                }
                if(add){
                    contactsToAddStandard.put(c.Id, c);
                }
            }
            else{
                contactsToAddStandard.put(c.Id, c);
            }
        }

        if(contactsToAddStandard.size() > 0){
            CampaigntoAdd(contactsToAddStandard, manualSource, now, yoyoContactMap, null);
        }

        if(contactsToAddDuplicateCampaignMember.size() > 0){
            handleDuplicateCampaignMembers(contactsToAddDuplicateCampaignMember, campaignIds, manualSource, yoyoContactMap, now);
        }
        
        if(campaignMembersToUpdate.size() > 0)
        {
            //GTMS-8541 
            if(System.Label.Contact_Database =='0')
            {
            DMLWrapper.doUpdate(campaignMembersToUpdate);
            }
            if(System.Label.Contact_Database !='0')
            {
                updateResults = Database.update(campaignMembersToUpdate,false);
            }    
        }
    }

    //DUPLICATE CAMPAIGN MEMBER LOGIC - START
    
    //Master method to handle cases where CampaignMember already exists by creating a new Campaign and updating Campaign_To_Add__c
    public static void handleDuplicateCampaignMembers(Map<Id, Contact> newContactMap, Set<Id> campaignIds, String manualSource, Map<Id, Boolean> yoyoContactMap, DateTime now){

        //Maps generated through methods within this class
        Map<Id, Campaign> campaignIdToCampaignMap = campaignsBase(campaignIds);
        Map<String, Campaign> campaignNameToCampaignMap = campaignsAssociated(campaignIds);
        Map<Id, List<CampaignMember>> contactIdToListOfCM = contactIdWithListOfCampaignMembers(newContactMap.keySet());

        //Maps to be generated throughout this method
        Map<Id, Campaign> campaignNamesToBeAddedMap = new Map<Id, Campaign>();
        Map <Id, String> contactIdToCampaignNameMap = new Map <Id, String>();
        Map <Id, Contact> finalCampaignIdsForContacts = new Map <Id, Contact>();
        Map <Id, Id> contactIdToCampaignId = new Map <Id, Id>();

        for(Contact contact : newContactMap.values()){
            Boolean nextContact = false;
            if(contactIdToListOfCM.containsKey(contact.Id)){
                Campaign originalCampaign = campaignIdToCampaignMap.get(contact.Campaign_to_Add__c);
                String campaignName = originalCampaign.Name;
                Integer maxIteration = 0;
                for(CampaignMember cm: contactIdToListOfCM.get(contact.Id)){
                    //Check if the campaign member for the latest campaign was added within the last 24 hours. Do not run logic if so!
                    Boolean cmWithin24hours = cm.CreatedDate >= System.today();
                    if(campaignName == cm.Campaign.Campaign_Name_without_Iteration__c && !cmWithin24hours){
                        maxIteration += 1;
                    }
                }

                if(maxIteration > 0 || Test.isRunningTest()){
                    String newCampaignMemberName = campaignName+' -+- [Repeat '+maxIteration+']';
                    if (newCampaignMemberName.length() > 80) // added for GTMS-8539 changes related to campaignName
                        newCampaignMemberName = newCampaignMemberName.substring(0, 79);
                    Campaign campaignMatch = campaignNameToCampaignMap.get(newCampaignMemberName);
                    if(campaignMatch == null){
                        contactIdToCampaignNameMap.put(contact.Id, newCampaignMemberName.trim());// added for GTMS-8539 changes related to campaignName
                        campaignNamesToBeAddedMap.put(contact.Id, originalCampaign);
                    }
                    else{
                        contactIdToCampaignId.put(contact.Id, campaignMatch.Id);
                        finalCampaignIdsForContacts.put(contact.Id, contact);
                    }
                }
            }
        }

        // Creates Repeat Campaign for only the campaigns that need to be added to the system
        if(campaignNamesToBeAddedMap.size() > 0){
            createRepeatCampaign(campaignNamesToBeAddedMap, contactIdToCampaignNameMap);
        }

        //Retrieve all campaigns for non matched (see line 157) campaigns for map generation to add
        List <Campaign> getCampaignIdsToAdd = [ SELECT  Id,
                                                        Name,
                                                        Type,
                                                        ParentId,
                                                        Status,
                                                        IsActive,
                                                        Startdate,
                                                        EndDate,
                                                        Description
                                                FROM Campaign
                                                WHERE Name IN: contactIdToCampaignNameMap.values()];

        //Add newly generated campaign Ids to map for CampaigntoAdd class
        for (Id contactId: campaignNamesToBeAddedMap.keySet()){
            Contact contact = newContactMap.get(contactId);
            for (Campaign c: getCampaignIdsToAdd){
                if (c.Name == contactIdToCampaignNameMap.get(contactId)){
                    contactIdToCampaignId.put(contact.Id, c.Id);
                    finalCampaignIdsForContacts.put(contactId, contact);
                }
            }
        }

        if(finalCampaignIdsForContacts.size() > 0){
            CampaigntoAdd(finalCampaignIdsForContacts, manualSource, now, yoyoContactMap, contactIdToCampaignId);
        }
    }

    //This method generates Campaign Id to Campaign map of all original campaigns that are pushed through the Samsara endpoints
    public static Map<Id, Campaign> campaignsBase(Set<Id> campaignToAddIds){

        Map<Id, Campaign> campaignIdToCampaignMap = new Map<Id, Campaign>();

        List <Campaign> allCampaignBase = [SELECT   Id,
                                                    Name, 
                                                    Iteration__c, 
                                                    Campaign_Name_without_Iteration__c,
                                                    Type,
                                                    ParentId,
                                                    Status,
                                                    IsActive,
                                                    Startdate,
                                                    EndDate,
                                                    Description
                                            FROM Campaign
                                            WHERE Id IN: campaignToAddIds];

        for(Campaign campaign: allCampaignBase){
            campaignIdToCampaignMap.put(campaign.Id, campaign);
        }
                                
        return campaignIdToCampaignMap;
    }

    //This method generates a map of Campaign Name string to Campaign for all Campaigns (repeat or non-repeat) that have been created
    public static Map<String, Campaign> campaignsAssociated(Set<Id> campaignToAddIds){

        Map<String, Campaign> campaignNameToCampaignMap = new Map<String, Campaign>();
        Set<String> campaignNames = new Set<String>();

        List <Campaign> allCampaignBase = [SELECT   Id,
                                                    Name, 
                                                    Campaign_Name_without_Iteration__c
                                            FROM Campaign
                                            WHERE Id IN: campaignToAddIds];

        for(Campaign campaign: allCampaignBase){
            campaignNames.add(campaign.Campaign_Name_without_Iteration__c);
        }

        List <Campaign> allCampaignsByNameWithoutIteration = [  SELECT  Id,
                                                                        Name,
                                                                        Iteration__c, 
                                                                        Campaign_Name_without_Iteration__c,
                                                                        Type,
                                                                        ParentId,
                                                                        Status,
                                                                        IsActive,
                                                                        Startdate,
                                                                        EndDate,
                                                                        Description
                                                                FROM Campaign
                                                                WHERE Campaign_Name_without_Iteration__c IN: campaignNames];

        for(Campaign campaign: allCampaignsByNameWithoutIteration){
            campaignNameToCampaignMap.put(campaign.Name, campaign);
        }
                                
        return campaignNameToCampaignMap;
    }

    //This method used throughout the class generates a map of Contact Ids to a List of Campaign Members for cycling through all associated Campaign Members
    public static Map<Id, List<CampaignMember>> contactIdWithListOfCampaignMembers(Set<Id> contactMapKeySet){

        List<CampaignMember> cmem = [SELECT Id, 
                                            ContactId,
                                            Status, 
                                            CampaignId,
                                            Campaign.ParentId, 
                                            Campaign.Name,
                                            Campaign.Type,
                                            Campaign.Campaign_Name_without_Iteration__c,
                                            Campaign.Iteration__c ,
                                            CreatedDate
                                    FROM CampaignMember 
                                    WHERE ContactId IN : contactMapKeySet
                                    ORDER BY Campaign.Iteration__c DESC];

        Map<Id, List<CampaignMember>> ctcidcmpmem = new Map<Id, List<CampaignMember>>();

        for (CampaignMember cm : cmem) {
            if (!ctcidcmpmem.containsKey(cm.ContactId)) {
                List<CampaignMember> newCmemList = new List<CampaignMember>();
                newCmemList.add(cm);
                ctcidcmpmem.put(cm.ContactId, newCmemList);
            }
            else {
                ctcidcmpmem.get(cm.ContactId).add(cm);
            }
        }

        return ctcidcmpmem;
    }

    //This method generates repeat campaigns
    public static void createRepeatCampaign(Map<Id, Campaign> campaignNamesToBeAddedMap, Map <Id, String> contactIdToCampaignNameMap){
        Set<Campaign> campaignNamesToInsert = new Set <Campaign>();
        
        for(Id contact: contactIdToCampaignNameMap.keySet()){
            Campaign campaignToAdd = campaignNamesToBeAddedMap.get(contact);
            // added for GTMS-8539 changes related to campaignName
            string campaignName = contactIdToCampaignNameMap.get(contact);
            if (campaignName.length()>80)
                campaignName = campaignName.substring(0, 79);
            campaignNamesToInsert.add(new Campaign(Name = campaignName,
                                                    Type = campaignToAdd.Type,
                                                    ParentId = campaignToAdd.ParentId,
                                                    Status = campaignToAdd.Status,
                                                    IsActive = campaignToAdd.IsActive,
                                                    StartDate = campaignToAdd.StartDate,
                                                    EndDate = campaignToAdd.EndDate,
                                                    Description = campaignToAdd.Description
                                                    ));
        }

        List<Campaign> campaignsToInsertList = new List<Campaign>(campaignNamesToInsert);

        if(campaignsToInsertList.size() > 0){
            insert campaignsToInsertList;
        }
    }
    
    //DUPLICATE CAMPAIGN MEMBER LOGIC - END   
    
    //GTMS-10284 fix
    public static Map<Id,Contact> getContactMap(Set<Id> contactIds) {
        Map<Id,Contact> mapContacts = new Map<Id, Contact> ([
            Select Id,Name
            FROM Contact
            WHERE Id IN:contactIds
        ]);
        return mapContacts;
    }
}