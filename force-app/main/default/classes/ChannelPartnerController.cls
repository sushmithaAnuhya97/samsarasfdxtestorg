/**********************************************************************
Name: ChannelPartnerController
Test Class: ChannelPartnerControllerTest
----------------------------------------------------------------------
Purpose: Add channel Partner Controller Class
----------------------------------------------------------------------
Mar-05-2025 : Venkata Ranga - (GTMS-26585) Update Add channel Partner flow UI
**********************************************************************/
public class ChannelPartnerController {
    
   	@AuraEnabled(cacheable=true)
    public static List<String> getActivePartnerAccountIds() {
        List<String> accountIds = new List<String>();
        
        for(Partner_Program_Enrollment__c enrollment : [
            SELECT Partner_Account__c 
            FROM Partner_Program_Enrollment__c 
            WHERE Member_Status__c = 'Active' 
            AND Approved_for_Add_a_Partner_workflow__c = true
        ]) {
            if(enrollment.Partner_Account__c != null && accountIds.contains(enrollment.Partner_Account__c) == false) {
                accountIds.add(enrollment.Partner_Account__c);
            }
        }
        
        return accountIds;
    }
    
    @AuraEnabled(cacheable=true)
    public static ActivePartnersWrapper getActivePartners(Id opportunityId) {
        Opportunity opp = [SELECT Id, Name, StageName, IsClosed, RecordType.DeveloperName, AccountId, Account.Name FROM Opportunity WHERE Id =: opportunityId];
        List<Account> activePartnersList = [SELECT Id, Name, Partner_Status__c 
                                            FROM Account 
                                            WHERE RecordType.DeveloperName = 'Partner' 
                                            AND Partner_Status__c = 'Transacting Partner'
                                            AND Id IN (SELECT Partner_Account__c FROM Partner_Program_Enrollment__c WHERE Member_Status__c = 'Active' AND Approved_for_Add_a_Partner_workflow__c = true)
                                            ORDER BY Name ASC];
        Boolean isClosed = opp.IsClosed;
        string allowAddPartnerProfile = system.Label.AllowAddPartnerOnClosedWonOrClosedLost;
        if (allowAddPartnerProfile.containsIgnoreCase(UserInfo.getProfileId())&& opp.IsClosed)
            isClosed = false;
        
        ActivePartnersWrapper activePartners = new ActivePartnersWrapper(opp.Name, opp.StageName, isClosed, opp.Account.Name, opp.RecordType.DeveloperName, activePartnersList);  
        return activePartners;
    }
    
    @AuraEnabled(cacheable=true)
    public static List<Partner_Program_Enrollment__c> getPartnerPrograms(Id partnerId) {
        return [SELECT Id, Partner_Program__c, SalesProgramType__c, Partner_Contact__c, Partner_Program__r.Name, Member_Status__c 
                FROM Partner_Program_Enrollment__c
                WHERE Partner_Account__c = :partnerId
                AND Member_Status__c  = 'Active' AND Approved_for_Add_a_Partner_workflow__c = true];
    }
    
    @AuraEnabled(cacheable=true)
    public static List<Contact> getPartnerContacts(Id partnerId) {
        return [SELECT Id, Name, Email, Phone
                FROM Contact
                WHERE AccountId = :partnerId
                ORDER BY Name];
    }
    
    @AuraEnabled
    public static String createChannelRelationship(Id opportunityId, Id partnerId, Id programId, Id contactId, String engagementType, String programType, String productType, Integer numberOfUnit, Id systemIntegratorsId, Decimal serviceAmount, Boolean isPartner) {
        
        // Check for duplicates
        Integer existingCount = [SELECT COUNT() 
                                 FROM Channel_Relationship__c 
                                 WHERE Opportunity__c = :opportunityId 
                                 AND Channel_Partner__c = :partnerId
                                 AND Partner_Program__c = :programId];
        if (existingCount > 0) {
            return 'Channel Relationship already exists';
        }
        else{
            // Get opportunity record
            Opportunity opp = [SELECT Id, Name, StageName, Installer__c, Insurance_Partner__c, Referral_Partner__c, Reseller_Partner__c, Reseller__c, Teaming_Partner_Account__c, RecordTypeId, RecordType.DeveloperName, AccountId, Account.Name FROM Opportunity WHERE Id =: opportunityId];
            
            Id standardOpportunityRecordTypeId = getRecordTypeId('Opportunity', 'Standard_Opportunity');
            Id industrialOpportunityRecordTypeId = getRecordTypeId('Opportunity', 'Industrial_Opportunity');
            Id machineVisionOpportunityRecordTypeId = getRecordTypeId('Opportunity', 'Machine_Vision');
            
            if((isPartner == false && opp.RecordTypeId == industrialOpportunityRecordTypeId) 
               || (programType != null && (opp.RecordTypeId == standardOpportunityRecordTypeId || opp.RecordTypeId == industrialOpportunityRecordTypeId || opp.RecordTypeId == machineVisionOpportunityRecordTypeId))){	
                   
                   Id InsurancePartnerCustom;
                   Id ReferralPartnerValue;
                   Id ResellerValue;
                   Id TeamingPartnerAccountId;
                   String InstallerValue;
                   Account partnerAccount;
                   Account SystemIntegrators;
                   Partner_Program_Enrollment__c enrollment;
                   
                   if(isPartner == true){
                       
                       // Get partner account owner for CAM Owner field
                       partnerAccount = [SELECT Id, Name, OwnerId, Partner_Type__c, Partner_Program_Tier__c FROM Account WHERE Id =: partnerId LIMIT 1];
                       
                       // Get program enrollment for terms
                       enrollment = [SELECT Id FROM Partner_Program_Enrollment__c 
                                     WHERE Partner_Account__c = :partnerId 
                                     AND Partner_Program__c = :programId 
                                     AND Member_Status__c = 'Active' LIMIT 1];
                       
                       InsurancePartnerCustom = 
                           (opp.RecordTypeId == standardOpportunityRecordTypeId && partnerAccount.Partner_Type__c == 'Insurance')
                           ? (
                               programType != 'Teaming Partner' &&
                               programType != 'Teaming' &&
                               programType != 'Paid Referral' &&
                               programType != 'Unpaid Referral'
                               ? (
                                   programType == 'Safety Program'
                                   ? (
                                       String.isBlank(opp.Insurance_Partner__c)
                                       ? partnerId
                                       : opp.Insurance_Partner__c
                                   )
                                   : partnerId
                               )
                               : null
                           )
                           : opp.Insurance_Partner__c;
                       ReferralPartnerValue =  programType != null ? programType.contains('Referral') ? partnerId : null : opp.Referral_Partner__c;
                       ResellerValue =  programType != null ? programType.contains('Resale') ? partnerId : opp.Reseller__c !=null ? opp.Reseller__c : null : opp.Reseller__c;
                       TeamingPartnerAccountId = (opp.RecordTypeId == machineVisionOpportunityRecordTypeId && partnerAccount.Partner_Type__c == 'Commercial') || (opp.RecordTypeId == standardOpportunityRecordTypeId && (partnerAccount.Partner_Type__c == 'Commercial' || partnerAccount.Partner_Type__c == 'Installer' || partnerAccount.Partner_Type__c == 'Insurance')) ? 
                           (programType == 'Teaming' || programType == 'Teaming Partner')
                           ? partnerId
                           : (
                               programType == 'Safety Program'
                               ? (
                                   !String.isBlank(opp.Insurance_Partner__c)
                                   ? partnerId
                                   : null
                               )
                               : null
                           )
                       : opp.RecordTypeId == industrialOpportunityRecordTypeId && String.isNotBlank(programType) && programType.contains('Teaming') ? partnerId : opp.Teaming_Partner_Account__c;
                       InstallerValue = opp.RecordTypeId == standardOpportunityRecordTypeId && partnerAccount.Partner_Type__c == 'Installer' ? partnerAccount.Name : opp.Installer__c;
                       
                       opp.Insurance_Partner__c = InsurancePartnerCustom;
                       opp.Referral_Partner__c = ReferralPartnerValue;
                       opp.Reseller_Partner__c = ResellerValue;
                       opp.Reseller__c = ResellerValue;
                       opp.Teaming_Partner_Account__c = TeamingPartnerAccountId;
                       opp.Installer__c = InstallerValue;
                   }
                   
                   if(opp.RecordTypeId == industrialOpportunityRecordTypeId && SystemIntegratorsId != null){
                       opp.System_Integrator__c = SystemIntegratorsId;
                       opp.Service_Amount_cur__c = serviceAmount;
                       SystemIntegrators = [SELECT Id, Name, OwnerId, Partner_Program_Tier__c FROM Account WHERE Id =: SystemIntegratorsId LIMIT 1];
                   }
                   System.debug('@@@SystemIntegratorsId: ' + SystemIntegratorsId);
                   System.debug('@@@SystemIntegrators: ' + SystemIntegrators);
                   update opp;
                   
                   if(opp.StageName == 'Closed Won' && ((opp.RecordTypeId == machineVisionOpportunityRecordTypeId && partnerAccount.Partner_Type__c == 'Commercial') || (opp.RecordTypeId == standardOpportunityRecordTypeId && (partnerAccount.Partner_Type__c == 'Commercial' || partnerAccount.Partner_Type__c == 'Installer' || partnerAccount.Partner_Type__c == 'Insurance'))) ){
                       Account oppAcc = new Account();
                       oppAcc.Id = opp.AccountId;
                       oppAcc.Latest_Partner_Account_Interaction__c = partnerId;
                       oppAcc.Latest_Partner_Program_Interaction__c = programType;
                       
                       update oppAcc;
                   }
                   
                   // Create Channel Relationship
                   Channel_Relationship__c cr = new Channel_Relationship__c(
                       Opportunity__c = opportunityId,
                       Channel_Partner__c = isPartner == true ? partnerId : SystemIntegratorsId,
                       Channel_Partner_Representative__c = contactId,
                       Partner_Program__c = programId,
                       Partner_Enrollment__c = isPartner == true ? enrollment.Id : null,
                       Partner_Interaction_Type__c = 'Partner Influenced',
                       CAM_Owner__c = isPartner == true ? partnerAccount.OwnerId : SystemIntegrators.OwnerId,
                       Product_Type__c = productType,
                       Number_of_units__c = numberOfUnit,
                       CR_Status__c = 'Approved',
                       Partner_Program_Segment__c = isPartner == true ? partnerAccount.Partner_Program_Tier__c : SystemIntegrators.Partner_Program_Tier__c,
                       Program_Type__c = programType,
                       Teaming_Partner__c = programType == 'Teaming Partner' ? partnerId : null
                   );
                   
                   if(opp.RecordTypeId == industrialOpportunityRecordTypeId && SystemIntegratorsId != null){
                       cr.System_Integrator_new__c = SystemIntegratorsId;
                       cr.Service_Amount_currency__c = serviceAmount;
                   }
                   
                   insert cr;
                   
                   return cr.Id;
               }else {
                   return 'Not find the partner';
               }
        }
    }
    
    // Get the RecordTypeId for a specific RecordType DeveloperName
    public static Id getRecordTypeId(String sObjectName, String recordTypeDeveloperName) {
        Map<String, Schema.RecordTypeInfo> recordTypeInfoMap = Schema.getGlobalDescribe()
            .get(sObjectName)
            .getDescribe()
            .getRecordTypeInfosByDeveloperName();
        
        if (recordTypeInfoMap.containsKey(recordTypeDeveloperName)) {
            return recordTypeInfoMap.get(recordTypeDeveloperName).getRecordTypeId();
        } else {
            throw new AuraHandledException('RecordType not found: ' + recordTypeDeveloperName);
        }
    }
    
    public class ActivePartnersWrapper{
        @AuraEnabled Public String opportunityName{get;set;}
        @AuraEnabled Public String currStageName{get;set;}
        @AuraEnabled Public Boolean isClosed{get;set;}
        @AuraEnabled public String customerAccountName{get;set;}
        @AuraEnabled public String oppRecordTypeName{get;set;}
        @AuraEnabled public List<Account> partners{get;set;}
        
        public ActivePartnersWrapper(String opportunityName, string currStageName, boolean isClosed, String customerAccountName, String oppRecordTypeName, List<Account> partners){
            this.opportunityName = opportunityName;
            this.currStageName = currStageName;
            this.isClosed = isClosed;
            this.customerAccountName = customerAccountName;
            this.oppRecordTypeName = oppRecordTypeName;
            this.partners = partners;
        }
    }
}