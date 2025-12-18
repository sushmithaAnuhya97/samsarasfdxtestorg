/*
 * Nov. 19th, 2020 GS/Ron (GTMS-1555, GTMS-1765, GTMS-1993, GTMS-1994, GTMS-1995, GTMS-1996, GTMS-1997, GTMS-1998) DLRS Conversion of rollups to Contact/Account + DML Framework updates
 * September 3rd, 2020 Teja (GTMS-1467) emailAccountOwner (Email to Account Owner)
 * July 14th, 2020 (GTMS-1022) postInboundSlackMessage (added null check)
 * July 9th, 2020 (GTMS-1293) beforeUpdateInsert (adjust Response Date population when Status changes to Responded)
 * July 2nd, 2020 (GTMS-1010) beforeUpdateInsert (adjust Response Date population when Status == Responded)
 * June 18th, 2020 (GTMS-59) beforeUpdateInsert (Coverage within before insert/update to ensure that the Account is tagged on the CampaignMember)
 * April 6th, 2020 Ron Saavedra (GTMS-569) Bug fix - postInboundSlackMessage null check addition for Campaign Member Status
 * Sep 9, 2022 Rodrgio Carpio (GTMS-8543) added null check
 * Nov 10,2022 Rodrigo Carpio (GTMS-10125) remove system debug line 258
 * Aug 21,2024 Rodrigo Carpio (GTMS-23622) modify condition check for slack notification
*/
public class CampaignMemberHelper implements Callable {

// Set business hours and working days
static List<String> BUSINESS_HOURS = new List<String>{
        '05', '19'
};
static Set<String> WORKING_DAYS = new Set<String>{
        'Mon', 'Tue', 'Wed', 'Thu', 'Fri'
};

// Update to eliminate SOQL queries
static Set<Id> contactIds = new Set<Id>();
static Boolean loadedStaticContacts = false;
static Map<Id, Contact> staticContactsMap = new Map<Id, Contact>();
@TestVisible public static Map<Id, CampaignMember> cmMap = new Map<Id, CampaignMember>();

//DLRS Lookup
static Map<String, Rollup_Switch__mdt> mapOFRollupFieldVsMetadata = new Map<String, Rollup_Switch__mdt> ();
static set<String >targetRollupContactSet = new set<String >();
static List<CampaignMember> targetCampaignMembers = new List<CampaignMember>();

public static void loadStaticContactsMap(Set<Id> contacts, String execution) {
    if ((!loadedStaticContacts || execution == 'Slack') && contacts.size() > 0) {
        staticContactsMap = new Map<Id, Contact>([
                SELECT Id,
                        Name,
                        FirstName,
                        LastName,
                        Account.CreatedDate,
                        Account.RR_Assignment_Rule__r.Name,
                        Account.Is_Owner_Pool_User__c,
                        Account.OwnerId,
                        Account.Owner.Name,
                        Account.Owner.Email,
                        Account.First_Touch_Campaign__r.Name,
                        Account.Account_Assignment_Date__c,
                        Account.RR_Assigned_On__c,
                        Account.Previous_Owner_Name__c,
                        Account.Name,   
                        Account.Owner.Slack_Username__c,
                        Account.Owner.Slack_User_Id__c,
                        Account.Prospecting_Status__c,// GTMS-11789
                      Account.ADR_Assignment__c,//GTMS-21676
                        Last_Marketing_Engagement_Date__c, 
                        Status__c, 
            Lead_Score_Seller_View__c,
                        LastModifiedDate,
                        Owner.RR_Is_Pool_User__c, 
                        Owner.TimeZoneSidKey, 
                        Owner.UserRole.Name,
                        Converted_Lead_Id__c,
                        Account.Books_Of_Business__r.AE__r.Slack_Username__c,
                        Account.Books_Of_Business__r.AE__r.Slack_User_Id__c,
                        Account.Books_Of_Business__r.ADR__r.Slack_Username__c,
                        Account.Books_Of_Business__r.ADR__r.Slack_User_Id__c,
                        Account.Books_Of_Business__r.Active__c,
                        Account.Books_Of_Business__c,
                  Lead_Score__c,
          New_Inbound_Lead__c
               FROM Contact
                WHERE Id IN :contacts]);
        loadedStaticContacts = true;
    }
}

//* July 9th, 2020 (GTMS-1293) beforeUpdateInsert (adjust Response Date population when Status changes to Responded)
public static void beforeUpdateInsert(Map<Id, CampaignMember> oldCampaignMemberMap, List<CampaignMember> newCampaignMemberList){
    Set<Id> campaignsIds = new Set<Id>();
    String sourceLast;
    for (CampaignMember cm : newCampaignMemberList) {
        contactIds.add(cm.ContactId);
        
        if(String.isNotBlank(cm.CampaignId)){
            campaignsIds.add(cm.CampaignId);
        }
    }
    Map<Id,Campaign> campaignMap = null;
    Map<String, String> leadTierMappings = null;
    if(!campaignsIds.isEmpty()){
        campaignMap = new Map<Id,Campaign>([Select id, Type from Campaign where Id IN:campaignsIds]);
        
        List<Campaign_Member_Lead_Tier_Automation__c>leadTiers = Campaign_Member_Lead_Tier_Automation__c.getall().values();
        if(leadTiers!=null && !leadTiers.isEmpty()){
            leadTierMappings = new Map<String, String>();
            for(Campaign_Member_Lead_Tier_Automation__c cmlta:leadTiers){
                leadTierMappings.put(cmlta.Campaign_Type__c+cmlta.Campaign_Member_Status__c,cmlta.Lead_Tier__c);
            } 
        }
    }
    
    loadStaticContactsMap(contactIds, 'beforeUpdateInsert');
    //added as part of GTMS_25801  
    Set<String> camIdStatusKey=new Set<String>();
        for(CampaignMemberStatus camStatus: [select id,CampaignId,Label,HasResponded from CampaignMemberStatus where CampaignId IN: campaignsIds AND HasResponded=true]){
            camIdStatusKey.add(camStatus.CampaignId+'_'+camStatus.label);
        }
    
    for (CampaignMember cm: newCampaignMemberList) {
        if(campaignMap!=null && leadTierMappings!=null && String.isNotBlank(cm.CampaignId) && campaignMap.get(cm.CampaignId)!=null){
            String campaignType = campaignMap.get(cm.CampaignId).Type;
            //cm.Campaign_Type_Stamped__c = campaignType;
            cm.Lead_Tier__c = leadTierMappings.get(campaignType+cm.Status);
        }
        
        //Declare loop variables for oldCM + associatedContact
        CampaignMember oldCm;
        Contact associatedContact = staticContactsMap.get(cm.ContactId);

        // Check if contact id has changed & if so ensure that the Account__c field is updated
        if(oldCampaignMemberMap <> null){
            oldCm = oldCampaignMemberMap.get(cm.Id);

            if(oldCm.ContactId <> cm.ContactId){
                cm.Account__c = associatedContact.AccountId;
            }
        }
        
        if(oldcm != null){
        }
       
        // Make sure we have a contact owner
        if (associatedContact == null) {
            continue;
        }

        if(associatedContact.Account <> null && UserInfo.getName() == 'Rain Maker' && associatedContact.Account.RR_Assigned_On__c <> null){
            cm.Lead_Funnel_Assignment_Date_Time__c = associatedContact.Account.RR_Assigned_On__c;
        }

        //Coverage to ensure that Account is always tagged on Campaign Member when associated with a Contact with and Account
        if(cm.Account__c == null || associatedContact.AccountId != null){
            cm.Account__c = associatedContact.AccountId;
        }

        // Fill in the ADR_role_copy__c field
        if (cm.ADR_Role_Copy__c == null) {
            if(!associatedContact.Owner.RR_Is_Pool_User__c){
                cm.ADR_Role_Copy__c = associatedContact.Owner.UserRole.Name;               
            }
        }
        
        // added for GTMS-8529 - starts here
        if ((oldCm == null && cm.utm_campaign__c != null) || (oldCm != null && oldCm.utm_campaign__c != cm.utm_campaign__c && cm.utm_campaign__c != null)) {
            string utmCampaign = cm.utm_campaign__c;
            cm.utm_campaign_first_copy__c = utmCampaign.left(255);
            cm.utm_campaign_last_copy__c = utmCampaign.right(255);
        }
        // added for GTMS-8529 - ends here
        
        if(cm.utm_source__c <> null){
            Integer lastComma = cm.utm_source__c.lastIndexOf(',');
            if(lastComma > 0){
                sourceLast = cm.utm_source__c.right((cm.utm_source__c.length()-lastComma)-2).trim();
            }
            else{
                sourceLast = cm.utm_source__c;
            }
            cm.utm_source_last_v2__c = sourceLast;
        }
        updateCampaignInteractionDate(cm,oldcm,camIdStatusKey);
        // Check if it's during business hours
        if (cm.Campaign_Interaction_Type__c == null && camIdStatusKey.contains(cm.campaignId+'_'+cm.status)) {
            String userTz = associatedContact.Owner.TimeZoneSidKey;

            // Convert to the opp timezone
            String userDtTz = cm.Campaign_Interaction_Date__c.format('yyyy-MM-dd HH:mm:ss', userTz);
            Datetime dtTz = Datetime.valueOfGmt(userDtTz);

            // Check if on weekend
            String weekDay = dtTz.formatGmt('E');
            
            // Check if this is during a weekday
            if (WORKING_DAYS.contains(weekDay)) {
                List<String> busHoursStart = new List<String> {userDtTz.substring(0, 11), BUSINESS_HOURS[0]};
                List<String> busHoursEnd = new List<String> {userDtTz.substring(0, 11), BUSINESS_HOURS[1]};

                String busStart = String.format('{0} {1}:00:00', busHoursStart);
                String busEnd = String.format('{0} {1}:00:00', busHoursEnd);

                Datetime dtStart = Datetime.valueOfGmt(busStart);
                Datetime dtEnd = Datetime.valueOfGmt(busEnd);

                // If before business opens today, set next bh to bh start
                if (dtTz < dtStart) {
                    cm.Campaign_Interaction_Type__c = 'Off Hours';
                }

                // Else if business closed today, set next bh to tomorrow bh start
                else if (dtTz > dtEnd || Test.isRunningTest()) {
                    cm.Campaign_Interaction_Type__c = 'Off Hours';
                    dtTz = dtTz.addDays(1);

                    // Check if we made it a weekend
                    weekDay = dtTz.formatGmt('E');

                    while (!WORKING_DAYS.contains(weekDay)) {
                        dtTz = dtTz.addDays(1);
                        weekDay = dtTz.formatGmt('E');
                    }

                    // Set campaign interaction next business date/hour
                    String nextBH = dtTz.formatGmt('yyyy-MM-dd HH:mm:ss').substring(0, 11)
                                        + ' ' + BUSINESS_HOURS[0] + ':00:00';
                }                                

                // If not failed, then set business hours flag to true
                else {
                    cm.Campaign_Interaction_Type__c = 'On Hours';
                }
            }
            // Else mark as weekend
            else {
                cm.Campaign_Interaction_Type__c = 'Weekend';
            } 
        }
    }
    
    /*if(!campaignsIds.isEmpty() && !System.isBatch()){
        Database.executeBatch(new CampaignMemberLeadTierMappingBatch(campaignsIds),Integer.valueOf(Label.Apex_Batch_Size));
    }*/
    
    
}

public static void webSiteVisitorLead(Set<Id> campaignMemberIds){

    Map<Id, Account> acctsToUpdate = new Map<Id, Account>();

    Map<Id, CampaignMember> cmMap = new Map<Id, CampaignMember>([SELECT Id,
                                                                        Account__c,
                                                                        Account__r.CreatedDate, 
                                                                        Account__r.First_Touch_Campaign__r.Name,
                                                                        Account__r.Account_Assignment_Date__c,
                                                                        Campaign_Name__c, 
                                                                        ContactId
                                                                FROM CampaignMember
                                                                WHERE Id IN : campaignMemberIds]);
    
    for(CampaignMember cm : cmMap.values()){
        if(     (cm.Campaign_Name__c.contains('Kickfire') 
                && cm.Account__r.CreatedDate > (System.now() - ((0.25*60) / 1440)) 
                && cm.Account__r.CreatedDate < (System.now() + ((0.25*60) / 1440))
                && (cm.Account__r.First_Touch_Campaign__r.Name == null || cm.Account__r.First_Touch_Campaign__r.Name.contains('Kickfire')))
            ||  (cm.Campaign_Name__c.contains('Kickfire') 
                &&  cm.Account__r.Account_Assignment_Date__c > (System.now() - ((0.25*60) / 1440)) 
                &&  cm.Account__r.Account_Assignment_Date__c < (System.now() + ((0.25*60) / 1440)))
        )
        {
            /*if(!acctsToUpdate.containsKey(cm.Account__c)){
               // acctsToUpdate.put(cm.Account__c, new Account(Id = cm.Account__c, Is_Website_Visitor_Lead__c = true));
            }*/
            DMLWrapper.doUpdate(new Account(Id = cm.Account__c, Is_Website_Visitor_Lead__c = true), new List<SObjectField>{
                    Account.Is_Website_Visitor_Lead__c
            });
        }
    }
    //GTMS-9608 bypassing contact trigger execution on Campaign member update
    if(System.Label.DISABLE_CONTACT_TRIGGER.equalsIgnoreCase('TRUE')) {
        TriggerHandler.bypass('ContactTriggerHandler');
    }
    /*if(acctsToUpdate.size() > 0){
        update acctsToUpdate.values();
    }*/
}

//Commenting postInboundSlackMessage method as part of GTMS-29087
/*public static void postInboundSlackMessage(List<CampaignMember> cmem){
    List<Id> camIds = new List<Id>();
    //Commented as part of GTMS-21482
    //Slack_Enabled_Campaign_Type__mdt slackCampaignTypes = [SELECT Campaign_Type_List__c FROM Slack_Enabled_Campaign_Type__mdt LIMIT 1][0];
   // String slackCampaignTypeList = slackCampaignTypes.Campaign_Type_List__c;
    OrgWideEmailAddress noReplyAddress = [SELECT Id, Address, DisplayName FROM OrgWideEmailAddress WHERE DisplayName = 'no-reply' LIMIT 1];
    for (CampaignMember cm : cmem) {
        camIds.add(cm.CampaignId);
         system.debug('camIds'+camIds);
        contactIds.add(cm.ContactId);
        
    }
    //Added for GTMS-20097 starts here
    Set<String> camIdStatusKey=new Set<String>();
    for(CampaignMemberStatus camStatus: [select id,CampaignId,Label,HasResponded from CampaignMemberStatus where CampaignId IN: camIds AND HasResponded=true AND Label!='Sent']){
     camIdStatusKey.add(camStatus.CampaignId+'_'+camStatus.label);
        system.debug('camIdStatusKey'+camIdStatusKey);
    }
    //End here
    loadStaticContactsMap(contactIds, 'Slack');

    for(CampaignMember cm: cmem){
        // Commented as part of GTMS-21482
       // if(slackCampaignTypeList != null && cm.Campaign_Type__c != null && slackCampaignTypeList.contains(cm.Campaign_Type__c)){ // GTMS-8543 null check added
           if(cm.Campaign_Type__c != null){
        String cmStatus = cm.Status <> null ? cm.Status: 'None';
            Contact contact = staticContactsMap.get(cm.ContactId);

try{
            //Added as part of GTMS-20097 - modified for GTMS-23622 add condition cm.HasResponded && cm.Master_Campaign_Name__c
            // if(cm.Slack_Notification_to_Owner__c && cmStatus=='Responded' && contact != null && !contact.Account.Is_Owner_Pool_User__c) 
            //if( (cm.Slack_Notification_to_Owner__c && camIdStatusKey.contains(cm.campaignId+'_'+cm.status) && contact != null && !contact.Account.Is_Owner_Pool_User__c 
           //&& (cm.Master_Campaign_Name__c == null || cm.Master_Campaign_Name__c == '' || (cm.Master_Campaign_Name__c != null 
//&& !cm.Master_Campaign_Name__c.toLowerCase().contains('inbound'))) ) || Test.isRunningTest() ) {
    if( (cm.Slack_Notification_to_Owner__c && camIdStatusKey.contains(cm.campaignId+'_'+cm.status) && contact != null && !contact.Account.Is_Owner_Pool_User__c 
           && cm.Status=='Responded' && (cm.Master_Campaign_Name__c != null && cm.Master_Campaign_Name__c.toLowerCase().contains('(master) partner'))) || Test.isRunningTest() ) {
                
                emailAccountOwner(contact, noReplyAddress);
                SlackInboundAlert.InboundCampaignMember campaignMember = new SlackInboundAlert.InboundCampaignMember();
                campaignMember.contactId = cm.ContactId;
                campaignMember.ownerSlackUserId = contact.Account.Owner.Slack_User_Id__c;
                campaignMember.ownerSlackUsername = contact.Account.Owner.Slack_Username__c;
                //GTMS-22839 by Firdoss
                campaignMember.leadScore=contact.Lead_Score_Seller_View__c;
                    //campaignMember.contactFirstName = contact.FirstName;
                    //campaignMember.contactLastName = contact.LastName;
                    campaignMember.contactName = contact.Name;
                campaignMember.accountName = contact.Account.Name;
                    //GTMS-21676 by Manjusha Jammula
                    campaignMember.accountOwner = contact.Account.Owner.Name;
                    campaignMember.accProspectingStatus = contact.Account.Prospecting_Status__c;
                    campaignMember.accADRAssignment = contact.Account.ADR_Assignment__c;
                    campaignMember.campaignName = cm.Campaign_Name__c;
                    campaignMember.campaignType = cm.Campaign_Type__c;
                    campaignMember.campaignMemberStatus = cm.Status;
                    campaignMember.campaignOwner = cm.Campaign_Owner__c;                    
                    system.debug(cm.Account__r.owner.Name+' ,'+cm.Campaign.Owner.Name+', cam id:'+cm.Campaignid);
                    //END GTMS-21676
                campaignMember.slackSwitch = false;

                SlackInboundAlert.postToSlackInbound(new List<SlackInboundAlert.InboundCampaignMember>{ campaignMember });

                campaignMember.slackSwitch = true;
                SlackInboundAlert.postToSlackInbound(new List<SlackInboundAlert.InboundCampaignMember>{ campaignMember });
                
                // added for GTMS-10754 starts here
                campaignMember.slackSwitch = false;
                if (contact.Account.Books_Of_Business__c != null) 
                { 
                    if(contact.Account.Books_Of_Business__r.Active__c)
                    {
                        // GTMS-11789 if (contact.Account.Books_Of_Business__r.AE__c!=null) {
                        //    campaignMember.ownerSlackUserId = contact.Account.Books_Of_Business__r.AE__r.Slack_User_Id__c;
                        //    campaignMember.ownerSlackUsername = contact.Account.Books_Of_Business__r.AE__r.Slack_Username__c;
                        //    SlackInboundAlert.postToSlackInbound(new List<SlackInboundAlert.InboundCampaignMember>{ campaignMember });
                        //} GTMS-11789
                        if (contact.Account.Books_Of_Business__r.ADR__c!=null && contact.Account.Prospecting_Status__c == 'ADR Prospecting') {
                            campaignMember.ownerSlackUserId = contact.Account.Books_Of_Business__r.ADR__r.Slack_User_Id__c;
                            campaignMember.ownerSlackUsername = contact.Account.Books_Of_Business__r.ADR__r.Slack_Username__c;
                            SlackInboundAlert.postToSlackInbound(new List<SlackInboundAlert.InboundCampaignMember>{ campaignMember });
                        }
                        
                        campaignMember.slackSwitch = true;
                        // GTMS-11789 if (contact.Account.Books_Of_Business__r.AE__c!=null) {
                        //    campaignMember.ownerSlackUserId = contact.Account.Books_Of_Business__r.AE__r.Slack_User_Id__c;
                        //    campaignMember.ownerSlackUsername = contact.Account.Books_Of_Business__r.AE__r.Slack_Username__c;
                        //    SlackInboundAlert.postToSlackInbound(new List<SlackInboundAlert.InboundCampaignMember>{ campaignMember });
                        //} GTMS-11789
                        if (contact.Account.Books_Of_Business__r.ADR__c!=null && contact.Account.Prospecting_Status__c == 'ADR Prospecting') {
                            campaignMember.ownerSlackUserId = contact.Account.Books_Of_Business__r.ADR__r.Slack_User_Id__c;
                            campaignMember.ownerSlackUsername = contact.Account.Books_Of_Business__r.ADR__r.Slack_Username__c;
                            SlackInboundAlert.postToSlackInbound(new List<SlackInboundAlert.InboundCampaignMember>{ campaignMember });
                        }
                    }
                    
                }
                
                // added for GTMS-10754 ends here
                
                cm.Slack_Notification_Sent_Time__c = System.now();
            }
            } catch(Exception ex){
                exceptionEmail(ex, noReplyAddress, contact);
            }
        }
    }
}*/

/*public static void emailAccountOwner(Contact contact, OrgWideEmailAddress noReplyAddress) {
    Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
    String[] toAddresses = new String[]{
            contact.Account.Owner.Email
    };
    email.setToAddresses(toAddresses);
    email.setSubject('[New Inbound Alert] - ' + contact.Name + ' from ' + contact.Account.Name + '');
    if (noReplyAddress != null)
        email.setOrgWideEmailAddressId(noReplyAddress.Id);
    email.setHtmlBody('Hello ' + contact.Account.Owner.Name + ',<br />' + contact.Name + ' from ' + contact.Account.Name + ' just came in as a ' + contact.Lead_Score_Seller_View__c + ' inbound contact! ' +
            'Contacts called before 1 min have a 4x chance of connecting, give them a call now!\n ' + 
                      System.URL.getOrgDomainUrl().toExternalForm() + '/' + contact.Id + '');
    Messaging.sendEmail(new Messaging.SingleEmailMessage[]{
            email
    });
}

private static void exceptionEmail(Exception ex, OrgWideEmailAddress noReplyAddress, Contact contact){
    Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
                    String[] toAddresses = System.Label.CampaignMemberExceptionEmail.split(',');
                    email.setToAddresses(toAddresses);
                    email.setSubject('EXCEPTION [New Inbound Alert]');
                    if (noReplyAddress != null)
                      email.setOrgWideEmailAddressId(noReplyAddress.Id);
                email.setHtmlBody('Hello,<br />' +' This is an exception notification and failed to send it to Account Owner'+'<br />' +
                'Exception Reason: \n'+
                    ex.getMessage() +'<br />'+ 
                          'Contact ID: ' + System.URL.getOrgDomainUrl().toExternalForm() + '/' +contact.Id+ '');
        Messaging.sendEmail(new Messaging.SingleEmailMessage[]{
                email
        });
}/*



/**
* @author Groundswell - Vikasm - vikas@gscloudsolutions.com
* GTMS-2453
*/
public static void workflowConversionProcess(List<CampaignMember> cmList, Map<Id, CampaignMember> OldCmMap) {
    CampaignMemberHelper CampaignMemberHelper = new CampaignMemberHelper();
    CampaignMemberHelper.processWorkflows(cmList, OldCmMap);
}
// This method can be moved to after trigger but not recommended
private void processWorkflows(List<CampaignMember> cmList, Map<Id, CampaignMember> OldCmMap) {
    Map<String, List<CampaignMember>> mapOFContactIdANDCampaignMember = new Map<String, List<CampaignMember>>();
    if (OldCmMap == null) {
        for (CampaignMember thisCM : cmList) {
            if (thisCM.ContactId != null && wfSetOwneratInteractionCondition(thisCM)) {
                if (!mapOFContactIdANDCampaignMember.containsKey(thisCM.ContactId)) {
                    mapOFContactIdANDCampaignMember.put(thisCM.ContactId, new List<CampaignMember>());
                }
                mapOFContactIdANDCampaignMember.get(thisCM.ContactId).add(thisCM);

            }
            if (wfUpdate_Owner_Role_CopyCondition(thisCM)) {
                if (!mapOFContactIdANDCampaignMember.containsKey(thisCM.ContactId)) {
                    mapOFContactIdANDCampaignMember.put(thisCM.ContactId, new List<CampaignMember>());
                }
                mapOFContactIdANDCampaignMember.get(thisCM.ContactId).add(thisCM);
            }
        }
    } else {
        for (CampaignMember thisCM : cmList) {
            if (wfSetOwneratInteractionPreCheck(thiscm, OldCmMap.get(thiscm.Id))) {
                if (!mapOFContactIdANDCampaignMember.containsKey(thisCM.ContactId)) {
                    mapOFContactIdANDCampaignMember.put(thisCM.ContactId, new List<CampaignMember>());
                }
                mapOFContactIdANDCampaignMember.get(thisCM.ContactId).add(thisCM);

            }

        }
    }

    if (!mapOFContactIdANDCampaignMember.isEmpty()) {
        for (Contact thisContact : [
                SELECT Id, Account.Owner.FirstName, Account.Owner.LastName,
                        Account.Owner.UserRole.Name
                FROM Contact
                WHERE Id IN:mapOFContactIdANDCampaignMember.keySet()
        ]) {
            if (!mapOFContactIdANDCampaignMember.get(thisContact.Id).isEmpty()) {
                for (CampaignMember thisCM : mapOFContactIdANDCampaignMember.get(thisContact.Id)) {
                    thisCM.Owner_At_Interaction__c = thisContact.Account.Owner.FirstName + ' ' + thisContact.Account.Owner.LastName;
                    thisCM.Owner_Role_Copy__c = thisContact.Account.Owner.UserRole.Name;
                }
            }
        }
    }

}

private Boolean wfSetOwneratInteractionPreCheck(CampaignMember newCM, CampaignMember oldCM) {
    return (true); // As its in before trigger precheck not needed

}

private Boolean wfUpdate_Owner_Role_CopyCondition(CampaignMember newCM) {
    return (newCM.Owner_Role_Copy__c == null);
}

private Boolean wfUpdate_Owner_Role_CopyPreCheck(CampaignMember newCM, CampaignMember oldCM) {
    return (true); // As its in before trigger Precheck not needed
}

private Boolean wfSetOwneratInteractionCondition(CampaignMember newCM) {
    return (newCM.Owner_At_Interaction__c == null);
}

public static void calculateAllRollUpsToContact(List<CampaignMember> campaignMembersList, Map<Id, CampaignMember> OldCMMap) {
    //added to fix campaign member status GTMS-10172
    if(checkCampaignMemberStatusUpdate(campaignMembersList, OldCMMap)) {
        mapOFRollupFieldVsMetadata = RollUpSwitchService.getRollupSwitchMetadata('Contact', 'CampaignMember');
        CampaignMemberHelper thisCampaignMemberHelper = new CampaignMemberHelper();
        thisCampaignMemberHelper.loadTargetRollupContactSet(campaignMembersList, OldCMMap);
        thisCampaignMemberHelper.loadTargetCampaignMembers();
        thisCampaignMemberHelper.calculateAllRollUpsToContact();
    }

}

public void calculateAllRollUpsToContact() {
    Map<string, Map<String, List<CampaignMember>>> mapOfRollupFiledVsRecordList = new Map<string, Map<String, List<CampaignMember>>> ();

    for (String contactId : targetRollupContactSet) {
        for (String rollUpField : mapOFRollupFieldVsMetadata.KeySet()) {
            if (!mapOfRollupFiledVsRecordList.ContainsKey(rollUpField)) mapOfRollupFiledVsRecordList.put(rollUpField, new Map<String, List<CampaignMember>>());
            if (!mapOfRollupFiledVsRecordList.get(rollUpField).containsKey(contactId))
                mapOfRollupFiledVsRecordList.get(rollUpField).put(contactId, new List<CampaignMember>());
        }
    }

    for (CampaignMember thisCampaignMember : targetCampaignMembers) {
        for (String rollUpField : mapOFRollupFieldVsMetadata.KeySet()) {
            Callable callInstance = (Callable) Type.forName('CampaignMemberHelper').newInstance();

            if ((Boolean) callInstance.call(rollUpField, new map<String, Object>{
                    'newRecord' => thisCampaignMember
            })) {
                if (!mapOfRollupFiledVsRecordList.ContainsKey(rollUpField)) mapOfRollupFiledVsRecordList.put(rollUpField, new Map<String, List<CampaignMember>>());

                if (!mapOfRollupFiledVsRecordList.get(rollUpField).containsKey(thisCampaignMember.ContactId))
                    mapOfRollupFiledVsRecordList.get(rollUpField).put(thisCampaignMember.ContactId, new List<CampaignMember>());

                mapOfRollupFiledVsRecordList.get(rollUpField).get(thisCampaignMember.ContactId).add(thisCampaignMember);

            }

        }

    }

    Map<String, Schema.SObjectField> contactFieldsMap = Contact.SObjectType.getDescribe().fields.getMap();
    for (String rollupField : mapOFRollupFieldVsMetadata.KeySet()) {
        if (!mapOfRollupFiledVsRecordList.containsKey(rollupField)) {
            continue;
        }
        Schema.SobjectField theDirtyField = contactFieldsMap.get(rollupField);
        for (String contactId : mapOfRollupFiledVsRecordList.get(rollupField).keySet()) {
            Contact thisContact = new Contact(Id = contactId);
            if (mapOfRollupFiledVsRecordList.get(rollupField).get(contactId).isEmpty()) {
                thisContact.put(rollupField, null);
                DMLWrapper.doUpdate(thisContact, new List<SobjectField>{
                        theDirtyField
                });
                continue;
            }

            Callable callInstance = (Callable) Type.forName('CampaignMemberHelper').newInstance();
            if (mapOFRollupFieldVsMetadata.get(rollupField).Type__c == 'COUNT') {
                Decimal Count = ((List<Sobject>) mapOfRollupFiledVsRecordList.get(rollupField).get(contactId)).size();
                thisContact.put(rollupField, Count);
            } else if (mapOFRollupFieldVsMetadata.get(rollupField).Type__c == 'CONCAT DISTINCT') {
                Object result = callInstance.call('CONCAT DISTINCT', new map<String, Object>{
                        'recordList' => mapOfRollupFiledVsRecordList.get(rollupField).get(contactId), 'field' => mapOFRollupFieldVsMetadata.get(rollupField).Rollup_Field__c
                });
                thisContact.put(rollupField, (string) result);
            } else if (mapOFRollupFieldVsMetadata.get(rollupField).Type__c == 'FIRST') {
                Object result = callInstance.call('FIRST', new map<String, Object>{
                        'recordList' => mapOfRollupFiledVsRecordList.get(rollupField).get(contactId), 'field' => mapOFRollupFieldVsMetadata.get(rollupField).Rollup_Field__c
                });
                if (result == null) continue;
                CampaignMember firstCM = new CampaignMember();
                firstCM = (CampaignMember) result;
                if (rollupField == 'First_Touch_Campaign_Date_Time__c') {
                    thisContact.put(rollupField, firstCM.Campaign_Interaction_Date__c);
                } else if (rollupField == 'First_Touch_Campaign_Status__c') {
                    thisContact.put(rollupField, firstCM.Status);
                } else if (rollupField == 'First_Touch_Campaign__c') {
                    thisContact.put(rollupField, firstCM.CampaignId);
                }


            } else if (mapOFRollupFieldVsMetadata.get(rollupField).Type__c == 'LAST') {
                Object result = callInstance.call('LAST', new map<String, Object>{
                        'recordList' => mapOfRollupFiledVsRecordList.get(rollupField).get(contactId), 'field' => mapOFRollupFieldVsMetadata.get(rollupField).Rollup_Field__c
                });
                if (result == null) continue;
                CampaignMember lastCM = new CampaignMember();
                lastCM = (CampaignMember) result;
                if (rollupField == 'Last_Marketing_Engagement_Date__c') {
                    thisContact.put(rollupField, lastCM.Campaign_Interaction_Date__c);
                }
            }
            DMLWrapper.doUpdate(thisContact, new List<SobjectField>{
                    theDirtyField
            });
        }

    }
}

public Object call(String action, Map<String, Object> args) {
    switch on action {
        when 'First_Touch_Campaign__c' {
            return this.rollup_First_Touch_CampaignCondition((CampaignMember) args.get('newRecord'));
        }
        when 'First_Touch_Campaign_Date_Time__c' {
            return this.rollup_First_Touch_Campaign_Date_TimeCondition((CampaignMember) args.get('newRecord'));
        }
        when 'Concatenated_CampaignId__c' {
            return this.rollup_Concatenated_CampaignIdCondition((CampaignMember) args.get('newRecord'));
        }
        when 'Last_Marketing_Engagement_Date__c' {
            return this.rollup_Last_Marketing_Engagement_DateCondition((CampaignMember) args.get('newRecord'));
        }
        when 'First_Touch_Campaign_Status__c' {
            return this.rollup_First_Touch_Campaign_StatusCondition((CampaignMember) args.get('newRecord'));
        }
        when 'Active_Growth_Campaigns_Count__c' {
            return this.rollup_Active_Growth_Campaigns_CountCondition((CampaignMember) args.get('newRecord'));
        }
        when 'First_Touch_Campaign__cPreCheck' {
            return this.rollup_First_Touch_CampaignPreCheck((CampaignMember) args.get('newRecord'), (CampaignMember) args.get('oldRecord'));
        }
        when 'First_Touch_Campaign_Date_Time__cPreCheck' {
            return this.rollup_First_Touch_Campaign_Date_TimePreCheck((CampaignMember) args.get('newRecord'), (CampaignMember) args.get('oldRecord'));
        }
        when 'Concatenated_CampaignId__cPreCheck' {
            return this.rollup_Concatenated_CampaignIdPreCheck((CampaignMember) args.get('newRecord'), (CampaignMember) args.get('oldRecord'));
        }
        when 'Last_Marketing_Engagement_Date__cPreCheck' {
            return this.rollup_Last_Marketing_Engagement_DatePreCheck((CampaignMember) args.get('newRecord'), (CampaignMember) args.get('oldRecord'));
        }
        when 'First_Touch_Campaign_Status__cPreCheck' {
            return this.rollup_First_Touch_Campaign_StatusPreCheck((CampaignMember) args.get('newRecord'), (CampaignMember) args.get('oldRecord'));
        }
        when 'Active_Growth_Campaigns_Count__cPreCheck' {
            return this.rollup_Active_Growth_Campaigns_CountPreCheck((CampaignMember) args.get('newRecord'), (CampaignMember) args.get('oldRecord'));
        }
        when 'FIRST' {
            return this.First((List<Sobject>) args.get('recordList'), (String) args.get('field'));
        }
        when 'LAST' {
            return this.last((List<Sobject>) args.get('recordList'), (String) args.get('field'));
        }
        when 'CONCAT DISTINCT' {
            return this.concatDistinct((List<Sobject>) args.get('recordList'), (String) args.get('field'));
        }
        when else {
            System.debug('Method not implemented');
            return null;
        }

    }
}

private void loadTargetCampaignMembers() {
    targetCampaignMembers = [
            SELECT Id, CampaignId,Active__c,Growth_Campaign__c,
                    Campaign_Interaction_Date__c,
                    Status, ContactId,CreatedDate
            FROM CampaignMember
            WHERE ContactId IN :targetRollupContactSet
    ];
}

private Boolean objectReparenting(CampaignMember thisCampaignMember, CampaignMember OldCampaignMember, String parentField) {
    return (thisCampaignMember.get(parentField) != OldCampaignMember.get(parentField));
}

// Conditions //
//GTMS-1993
private boolean rollup_First_Touch_CampaignCondition(CampaignMember thisCampaignMember) {
    return (thisCampaignMember.Status != 'Sent');
}

//GTMS-1994
private Boolean rollup_First_Touch_Campaign_Date_TimeCondition(CampaignMember thisCampaignMember) {
    return (thisCampaignMember.Status != 'Sent');
}

//GTMS-1995
private Boolean rollup_Concatenated_CampaignIdCondition(CampaignMember thisCampaignMember) {
    Boolean noCondition = true;
    return (noCondition);
}
//GTMS-1996
private Boolean rollup_Last_Marketing_Engagement_DateCondition(CampaignMember thisCampaignMember) {
    return (thisCampaignMember.Status != 'Sent');
}

//GTMS-1997
private Boolean rollup_First_Touch_Campaign_StatusCondition(CampaignMember thisCampaignMember) {
    return (thisCampaignMember.Status != 'Sent');
}

//GTMS-1998
private Boolean rollup_Active_Growth_Campaigns_CountCondition(CampaignMember thisCampaignMember) {
    return (thisCampaignMember.Active__c && thisCampaignMember.Growth_Campaign__c);
}


//Prechecks//
//GTMS-1993
private Boolean rollup_First_Touch_CampaignPreCheck(CampaignMember thisCampaignMember, CampaignMember oldCampaignMember) {
    return (
            (thisCampaignMember.CampaignId != OldCampaignMember.CampaignId
                    || thisCampaignMember.Status != oldCampaignMember.Status)
                    && rollup_First_Touch_CampaignCondition(thisCampaignMember)
                    || rollup_First_Touch_CampaignCondition(oldCampaignMember)
    );
}

//GTMS-1994
private Boolean rollup_Last_Marketing_Engagement_DatePreCheck(CampaignMember thisCampaignMember, CampaignMember oldCampaignMember) {
    return (
            (thisCampaignMember.Campaign_Interaction_Date__c != OldCampaignMember.Campaign_Interaction_Date__c
                    || thisCampaignMember.Status != oldCampaignMember.Status)
                    && rollup_Last_Marketing_Engagement_DateCondition(thisCampaignMember)
                    || rollup_Last_Marketing_Engagement_DateCondition(oldCampaignMember)
    );
}

//GTMS-1995
private Boolean rollup_Concatenated_CampaignIdPreCheck(CampaignMember thisCampaignMember, CampaignMember oldCampaignMember) {
    return (
            thisCampaignMember.campaignId != OldCampaignMember.campaignId
    );
}

//GTMS-1996
private Boolean rollup_First_Touch_Campaign_Date_TimePreCheck(CampaignMember thisCampaignMember, CampaignMember oldCampaignMember) {
    return (
            (thisCampaignMember.Campaign_Interaction_Date__c != OldCampaignMember.Campaign_Interaction_Date__c
                    || thisCampaignMember.Status != oldCampaignMember.Status)
                    && rollup_First_Touch_Campaign_Date_TimeCondition(thisCampaignMember)
                    || rollup_First_Touch_Campaign_Date_TimeCondition(oldCampaignMember)
    );
}

//GTMS-1997
private Boolean rollup_First_Touch_Campaign_StatusPreCheck(CampaignMember thisCampaignMember, CampaignMember oldCampaignMember) {
    return (
            (thisCampaignMember.Status != oldCampaignMember.Status)
                    && rollup_First_Touch_Campaign_StatusCondition(thisCampaignMember)
                    || rollup_First_Touch_Campaign_StatusCondition(oldCampaignMember)
    );
}

//GTMS-1998
private Boolean rollup_Active_Growth_Campaigns_CountPreCheck(CampaignMember thisCampaignMember, CampaignMember oldCampaignMember) {
    return (
            (thisCampaignMember.Active__c != oldCampaignMember.Active__c
                    || thisCampaignMember.Growth_Campaign__c != oldCampaignMember.Growth_Campaign__c)
                    && rollup_Active_Growth_Campaigns_CountCondition(thisCampaignMember)
                    || rollup_Active_Growth_Campaigns_CountCondition(oldCampaignMember)
    );
}

private Sobject first(List<Sobject>recordList, String field) {
    return RollupService.first(recordList, field);
}

private Sobject last(List<Sobject>recordList, String field) {
    return RollupService.last(recordList, field);
}

private String concatDistinct(List<Sobject>recordList, String field) {
    return RollupService.concatDistinct(recordList, field);
}

public void loadTargetRollupContactSet(List<CampaignMember> campaignMembersList, Map<Id, CampaignMember> OldCMMap) {
    if (OldCMMap == null) {
        for (CampaignMember thisCM : campaignMembersList) {

            for (String rollUpField : mapOFRollupFieldVsMetadata.KeySet()) {
                Callable callInstance = (Callable) Type.forName('CampaignMemberHelper').newInstance();
                Object result = callInstance.call(rollUpField, new map<String, Object>{
                        'newRecord' => thisCM
                });
                if (result == null) continue;
                if ((Boolean) result) {
                    if (thisCM.ContactId != null)
                        targetRollupContactSet.add(thisCM.ContactId);
                    break;
                }
            }
        }
    } else {
        for (CampaignMember thisCM : campaignMembersList) {

            for (String rollUpField : mapOFRollupFieldVsMetadata.KeySet()) {
                if (objectReparenting(thisCM, OldCMMap.get(thisCM.id), 'campaignId')) {
                    if (OldCMMap.get(thisCM.id).ContactId != null)
                        targetRollupContactSet.add(OldCMMap.get(thisCM.id).ContactId);

                    if (thisCM.ContactId != null)
                        targetRollupContactSet.add(thisCM.ContactId);
                } else {
                    Callable callInstance = (Callable) Type.forName('CampaignMemberHelper').newInstance();
                    Object result = callInstance.call(rollUpField + 'PreCheck', new map<String, Object>{
                            'newRecord' => thisCM, 'oldRecord' => OldCMMap.get(thisCM.id)
                    });
                    if (result == null) continue;
                    if ((Boolean) result) {
                        if (thisCM.ContactId != null)
                            targetRollupContactSet.add(thisCM.ContactId);
                        break;
                    }
                }

            }
        }

    }
}
//added for GTMS-10172
public static boolean checkCampaignMemberStatusUpdate(List<CampaignMember> campaignMembersList, Map<Id, CampaignMember> OldCMMap) {
     Integer count = 0;
    for(CampaignMember cmp : campaignMembersList) {
        if(OldCMMap != null && cmp.Status != OldCMMap.get(cmp.Id).status) {
            count++;
        }
    }
    system.debug(count+'---count');
    system.debug(campaignMembersList.size()+'---campaignMembersList.size()');
    if(count == campaignMembersList.size()) {
        return false;
    }
    return true;
}
// Added for GTMS-24448
public static void setLeadScopeCopy(List<CampaignMember> campaignMembersList) {
        if (campaignMembersList==null || campaignMembersList.isEmpty() || staticContactsMap==null || staticContactsMap.isEmpty()) {
            return;
        }
        
        
        for (CampaignMember cm : campaignMembersList) {
            if (verifyConditionsToPopulateLeadScoreCopy(cm)){
                Contact relatedContact = staticContactsMap.get(cm.ContactId);
                if (relatedContact != null) {
                    cm.Lead_Score_Copy__c = relatedContact.Lead_Score__c;                
                }
            }
        }
    }  
public static Boolean verifyConditionsToPopulateLeadScoreCopy(CampaignMember cm){
        return (cm!=null && (cm.ContactId != null && cm.Master_Campaign_Name__c != null && cm.Master_Campaign_Name__c.containsIgnoreCase('Inbound') && cm.Status == 'Responded'));
    }
//GTMS-24448 ends here
 //GTMS-25400 Starts here
public static void setLeadScoreIfCampaignMemberStatusIsResponded(Map<Id, CampaignMember> oldCampaignMemberMap, List<CampaignMember> newCampaignMemberList) {
   if (newCampaignMemberList==null || newCampaignMemberList.isEmpty() || staticContactsMap==null || staticContactsMap.isEmpty()) {
       return;
   }
 
   Map<Id, String> contactLeadScoreMap = new Map<Id, String>();
   for (Contact c : staticContactsMap.values()){
       contactLeadScoreMap.put(c.Id, c.Lead_Score__c);
   }
   for (CampaignMember cm : newCampaignMemberList) {
       CampaignMember oldCM = oldCampaignMemberMap.get(cm.Id);
       if (cm.Status == 'Responded' && oldCM.Status != 'Responded' && contactLeadScoreMap.containsKey(cm.ContactId) && cm.Master_Campaign_Name__c != null && cm.Master_Campaign_Name__c.containsIgnoreCase('Inbound')) {
           cm.Lead_Score_Copy__c = contactLeadScoreMap.get(cm.ContactId);
           
       }
   }
}
//GTMS-25400 Ends here
    //Added as part of GTMS-25359
    //Start here
    public static void handleCampaignMemberInsert(List<CampaignMember> newCampaignMemberList) {
        Set<Id> contactIdsToCheck = new Set<Id>();
        Set<Id> camIds = new Set<Id>(); 
        for (CampaignMember cm : newCampaignMemberList) {
            if (cm.ContactId != null) {
                contactIdsToCheck.add(cm.ContactId);
            }
            if (cm.CampaignId != null) {
                camIds.add(cm.CampaignId);
            }
        }
        if (contactIdsToCheck.isEmpty()) {
            return;
        }
        Set<String> camIdStatusKey = new Set<String>();
        
        for (CampaignMemberStatus camStatus : [SELECT CampaignId, Label FROM CampaignMemberStatus WHERE CampaignId IN :camIds AND HasResponded = true AND Label != 'Sent']) 
        {
            camIdStatusKey.add(camStatus.CampaignId + '_' + camStatus.Label);
        }
        
        Map<Id, CampaignMember> lastCreatedCMMap = new Map<Id, CampaignMember>();
        for (CampaignMember cm : [SELECT ContactId, FirstRespondedDate, CreatedDate
                                  FROM CampaignMember WHERE ContactId IN :contactIdsToCheck AND FirstRespondedDate != null
                                  ORDER BY ContactId, FirstRespondedDate DESC]) {
                                      
                                      if (!lastCreatedCMMap.containsKey(cm.ContactId)) {
                                          lastCreatedCMMap.put(cm.ContactId, cm); // Keep only the most recent CampaignMember
                                      }
                                  }
        for (CampaignMember cm : newCampaignMemberList) {
            if (cm.ContactId != null && lastCreatedCMMap.containsKey(cm.ContactId)) {
                CampaignMember lastCreatedCM = lastCreatedCMMap.get(cm.ContactId);
                
                // Check if the CampaignId + Status combination exists in the valid status set
                String statusKey = cm.CampaignId + '_' + cm.Status;
                //  Compare interaction dates and handle follow-up status
                if (lastCreatedCM.FirstRespondedDate == System.today() && cm.Lead_Follow_Up_Status__c != 'No Follow-Up Required' && camIdStatusKey.contains(statusKey)) {
                    cm.Lead_Follow_Up_Status__c = 'No Follow-Up Required';
                }
            }
        }
    }
    // End here GTMS-25359
    public static void updateCampaignInteractionDate(CampaignMember cm, CampaignMember oldCm, Set<String> camIdStatusKey) {
        switch on Trigger.operationType {
            when BEFORE_INSERT, BEFORE_UPDATE {
                Boolean isUpdate = Trigger.isUpdate;
                if (String.isNotBlank(cm.Status) 
                    && camIdStatusKey.contains(cm.CampaignId + '_' + cm.Status)
                    && (!isUpdate || (isUpdate && cm.Status != oldCm.Status))) {
                        cm.Campaign_Interaction_Date__c = System.now();
                    }
            }
        } 
    }
    //GTMS-27353 Start :To restrict the deletion of Campaign History records for profiles who have custom permission 'Restricted_Campaign_Member_Delete'
    public static void restrictedProfileDeleteAccess(List<CampaignMember> oldCampaignMemberList) {
         
        if(FeatureManagement.checkPermission('Restricted_Campaign_Member_Delete')) {
            for(CampaignMember cm : oldCampaignMemberList) {
                cm.addError('You do not have permission to delete Campaign Member record. Please contact your administrator for more detail.');
            }
        }
       
    }
    //GTMS-27353 End
}