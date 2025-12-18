public class AccountExtensionHelper {
	@AuraEnabled
    public static Account_Extension__c getAccountExtension(Id accountId) {
        List<Account_Extension__c> extensions = [
            SELECT Id, Account__c, Agreement_Received__c , Agreement_Type__c , Is_PAM_Manager__c,
            Legal_Agreement_Executed__c, MNDA_Signed__c, MNDA_Status__c, Onboarding_Type__c,
            PAM_Manager_Approval__c, Partner_Onboarding_Complete__c, Sales_Ops_Validation__c  
            FROM Account_Extension__c
            WHERE Account__c = :accountId
            LIMIT 1
        ];
        
        return extensions.isEmpty() ? null : extensions[0];
    }
}