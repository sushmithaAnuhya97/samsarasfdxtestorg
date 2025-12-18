/**********************************************************************
Name: TIConnectedAppCustomAttrHandler
=======================================================================
Purpose: This class has the logic to generate the custom attributes for connected app                                                        
=======================================================================
History  

VERSION     AUTHOR               DATE               DETAIL                       
1.0        Rodrigo Carpio        2023-Jul-17        INITIAL DEVELOPMENT FOR GTMS-14389
2.0        Rodrigo Carpio        2024-Jan-04        modified for GTMS-17830
***********************************************************************/ 
global class TIConnectedAppCustomAttrHandler  extends Auth.ConnectedAppPlugin {

	// Return a user’s permission set assignments            
    global override Map<String,String> customAttributes(Id userId, Id connectedAppId, Map<String,String>
        formulaDefinedAttributes, Auth.InvocationContext context)         
    {  
        List<PermissionSetAssignment> psas = [SELECT id, PermissionSet.Name FROM PermissionSetAssignment 
        WHERE PermissionSet.IsOwnedByProfile = false AND (AssigneeId = :userId)];
        String permsets = '[';
        if (psas != null && psas.size()>0) {
            for (PermissionSetAssignment psa :psas)
            {
                permsets += psa.PermissionSet.Name + ';';
            }
        }
        
        permsets += ']';
        //formulaDefinedAttributes.put('PermissionSets', permsets);
        
        String accountName = null;
        String accoundId = null;
        String contactId = null;
        string programType = null;
        string partnerType = null;
        string systemIntegrationType = null;
        string contactOwner = null;
        string locale = null;
        string clientId = System.label.TIClientID;
        string studentLicenseSku = null;
        User ojbUser = [SELECT Id, ContactId, LocaleSidKey  FROM User WHERE Id =: userId];
        if (ojbUser.ContactId != null) {
            Contact con = [SELECT Id, Owner.Name, AccountId, Account.Name, Account.Program_Type__c, Account.Partner_Type__c, Account.ServicesIntegration_Program_Type__c FROM Contact WHERE Id =: ojbUser.ContactId];
            contactOwner = con.Owner.Name;
            contactId = con.id;
            //Account acct = [SELECT Id, Name FROM Account WHERE Id =: con.AccountId];
            accountName = con.Account.Name;
            accoundId = con.Account.id;
            programType = con.Account.Program_Type__c;
            partnerType = con.Account.Partner_Type__c;
            systemIntegrationType = con.Account.ServicesIntegration_Program_Type__c; 
        }
        
        locale = ojbUser.LocaleSidKey;
        // added for GTMS-23211 starts here
        if (systemIntegrationType != null && (systemIntegrationType.containsIgnoreCase('Installation') || systemIntegrationType.containsIgnoreCase('Implementation')))
            studentLicenseSku = 'PR_INSTALL';
        else if (partnerType != null && partnerType == 'Insurance')
            studentLicenseSku = 'PR_INSURANCE';
        else {
            if( programType != null && (programType.containsIgnoreCase('Paid Referral') || programType.containsIgnoreCase('Unpaid Referral')) 
               || (partnerType.containsIgnoreCase('Commercial')) )
                studentLicenseSku = 'PR_COMMERCIAL';
            else
                studentLicenseSku = 'PR_COMMERCIAL';
        }
        // added for GTMS-23211 ends here
        /* commented for GTMS-23211
        // logic for GTMS-14534
        //If (partnerType == 'Installer') -- condition changed for GTMS-17830
        //studentLicenseSku = 'PR_INSTALL';
        //else
        If (partnerType == 'Insurance')
			studentLicenseSku = 'PR_INSURANCE';
        //else if (programType == 'Resale')
        //    studentLicenseSku = 'PR_RESALE';
        else if (partnerType == 'Commercial')
            studentLicenseSku = 'PR_COMMERCIAL';
        else
            studentLicenseSku = 'PR_COMMERCIAL';
        
        // added for GTMS-17830 starts here
        if (systemIntegrationType != null && (systemIntegrationType.containsIgnoreCase('Installation') || systemIntegrationType.containsIgnoreCase('Consulting ')))
        	studentLicenseSku = (studentLicenseSku==null) ? 'PR_INSTALL' : studentLicenseSku+',PR_INSTALL';
        
        if (systemIntegrationType != null && (systemIntegrationType.containsIgnoreCase('Software Integration') 
                                              || systemIntegrationType.containsIgnoreCase('Systems Integration')))
        	studentLicenseSku = (studentLicenseSku==null) ? 'PR_TECHNOLOGY' : studentLicenseSku+',PR_TECHNOLOGY';
        
        // added for GTMS-17830 ends here
        if(programType!=null) {
            If (programType.containsIgnoreCase('Paid Referral') || programType.containsIgnoreCase('Unpaid Referral')
                || programType.containsIgnoreCase('Resale'))
            {
                if( (programType.containsIgnoreCase('Paid Referral') || programType.containsIgnoreCase('Unpaid Referral')) && (partnerType != 'Commercial'))
                    studentLicenseSku = (studentLicenseSku==null) ? 'PR_COMMERCIAL' : studentLicenseSku+',PR_COMMERCIAL';
                if(programType.containsIgnoreCase('Resale'))
                    studentLicenseSku = (studentLicenseSku==null) ? 'PR_RESALE' : studentLicenseSku+',PR_RESALE';
            }
        }
        */
        
        formulaDefinedAttributes.put('ContactId', contactId);
        formulaDefinedAttributes.put('AccountName', accountName);
        formulaDefinedAttributes.put('AccountId', accoundId);
        formulaDefinedAttributes.put('ProgramType', programType);
        formulaDefinedAttributes.put('PartnerType', partnerType);
        formulaDefinedAttributes.put('ContactOwner', contactOwner);
        formulaDefinedAttributes.put('Locale', locale);
        formulaDefinedAttributes.put('ClientId', clientId);
        formulaDefinedAttributes.put('ClientSku', 'PR_Partners');
        formulaDefinedAttributes.put('StudentLicenseSku', studentLicenseSku);
        return formulaDefinedAttributes;     
      
    } 
}