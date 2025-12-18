/***************************************************************************************************************************
 * @Test class: FlexAccountCancelReplaceControllerTest (testFlexNotificationDataController method)
* Date      	- Project#     - Developer/ Company      	   - Description
* --------------------------------------------------------------------------------------------------------------------------
* 02/03/2025    - Flex C&R     - Manglesh Kumar/ Accenture 	   - handling the logic related to Flex Notifications
*											
*/
/*
 * @description - This class is responsible for handling the logic related to FlexLogDetailsPage. 
 * It fetches the relevant Flex_Log__c records based on the parameters passed in the URL.
 */
public with sharing class FlexNotificationDataController {
    public String contractParams { get; set; }
    public String accountId { get; set; }
    public String userId { get; set; }
    public Boolean showLogs { get; set; }
    public Boolean notify { get; set; }
    public String baseUrl { get; set; }
    public List<Flex_Log__c> logs { get; set; }
    public List<Flex_Log__c> newLogs { get; set; }


    public FlexNotificationDataController() {
        // Initialize parameters from URL or defaults
        String notifyValue =ApexPages.currentPage().getParameters().get('notify');
        String showLogsValue =ApexPages.currentPage().getParameters().get('showLogs');
        accountId = ApexPages.currentPage().getParameters().get('accountId');
        userId = ApexPages.currentPage().getParameters().get('userId');
        notify = notifyValue == null ? true :  Boolean.valueOf(notifyValue  );
        showLogs = showLogsValue == null ? true :  Boolean.valueOf(showLogsValue  );
        contractParams = ApexPages.currentPage().getParameters().get('contractIds');
        baseUrl = System.URL.getOrgDomainUrl().toExternalForm();
        logs = new List<Flex_Log__c>();
        List<Id> contractIds = new List<Id>();
        String queryString  = 'SELECT  Id, Name , AccountId__c , CreatedDate , CreatedById , ContractId__c, Queueable_Job_Id__c , AmendedQuoteId__c, AmendedOpportunityId__c, RevenueQuoteId__c, RevenueOpportunityId__c, Status__c, userNotified__c , ErrorMessage__c FROM Flex_Log__c  ';
        // Query based on the parameters passed
        List<String> conditions = new List<String>();
        if (accountId != null) {
            conditions.add('AccountId__c = :accountId');
        }
        if (userId != null) {
            conditions.add('CreatedById = :userId');
        }
        if (notify != null) {
            conditions.add('UserNotified__c = :notify');
        }
        if (contractParams != null) {
            List<Id> contractIdList = new List<Id>();
            for (String contract : contractParams.split(',')) {
            if (String.isNotBlank(contract)) {
                contractIdList.add((Id)contract.trim());
            }
            }
            if (!contractIdList.isEmpty()) {
            conditions.add('ContractId__c IN :contractIdList');
            }
        }

        if (!conditions.isEmpty()) {
            queryString += ' WHERE ' + String.join(conditions, ' AND ');
        }
        queryString += ' ORDER BY CreatedDate DESC';
        system.debug(queryString);
        logs = Database.query(queryString);
    }

}