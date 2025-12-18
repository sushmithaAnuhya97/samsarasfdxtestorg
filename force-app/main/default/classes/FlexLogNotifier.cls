/*************************************************************************************************************************************************************************
 * @Test class: FlexAccountCancelReplaceControllerTest
 * Date      	- Project#     - Developer/ Company      	   - Description
 * ------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 * 02/03/2025    - Flex C&R     - Pratyush Ranjan/ Accenture 	   - Method to send & manage log notifications to ensure proper tracking and alerting of system events.
 *											
 */
public class FlexLogNotifier {
    /**
     * Merges the name parts from a full name string.
     * @param fullName The full name string.
     * @return The merged name.
     */
    public static String nameMerger(String fullName) {
        List<String> parts = fullName.split(',');
        List<String> nameParts = new List<String>();
        for (String part : parts) {
            if (part.contains('@')) {
                break;
            }
            nameParts.add(part.trim());
        }
        return String.join(nameParts, ', ');
    }
    

    /**
     * Notifies the user and admin by email based on the status of the provided Flex Log records.
     * @param logRecords The list of Flex_Log__c records to process and notify about.
     */
    public static void notifyByEmail(List<Flex_Log__c> logRecords) {
        String baseUrl = System.URL.getOrgDomainUrl().toExternalForm();
        List<String> userEmailAddress = new List<String>{ UserInfo.getUserEmail() };
        String adminEmailAddressString = FlexConstants__c.getValues('FlexConstants').adminEmailAddress__c;
        String enablementLink = FlexConstants__c.getValues('FlexConstants').Enablement_Link__c;
        List<String> adminEmailAddress = adminEmailAddressString != null ? adminEmailAddressString.split(';') : new List<String>();
        Boolean hasFailedLogs = false;
        Set<String> contractList = new Set<String>();
        String notificationTitle = '';
        String getCreatedByUserId = UserInfo.getUserId();
        String userMailBody = '';
        String replacementQuoteId='';

        for (Flex_Log__c log : logRecords) {
            if (log.Status__c != 'Completed') {
                replacementQuoteId = 'null';
                break;

            }
            replacementQuoteId = log.RevenueQuoteId__c;
        }


        // Collect contract IDs from log records
        for (Flex_Log__c log : logRecords) {
            if (log.Status__c != 'Completed') {


                hasFailedLogs = true;
            }

            contractList.add(log.ContractId__c);
        }
        String contractIdParam = '';
        if (!contractList.isEmpty()) {
            contractIdParam += String.join(contractList, ',');
        }
        String name = '';
        String revenueOppId = '';
        String revenueOppName = '';

        if (!hasFailedLogs) {
            Opportunity revenueOpp = [SELECT Id, Owner_Full_Name_Email__c, Name FROM Opportunity WHERE Id = :logRecords[0].RevenueOpportunityId__c LIMIT 1];

            revenueOppId = revenueOpp.Id;
            revenueOppName = revenueOpp.Name;
            name = nameMerger(revenueOpp.Owner_Full_Name_Email__c);
        } else {
            name = UserInfo.getName();
        }

        String accountId = logRecords[0].AccountId__c;
        String accountName = '<a href=" ' + baseUrl + '/' + accountId + ' "> ' + [SELECT Name FROM Account WHERE Id = :accountId].Name + ' </a>';
        String visualForcePageLinkForUser = '<a href="' + baseUrl + '/apex/FlexLogDetailsPage?accountId=' + accountId + 
            '&userId=' + getCreatedByUserId + 
            '&notify=' + 'true' + 
            '&contractIds=' + contractIdParam + 
            '&showLogs=' + 'false' + 
            '"> Click here </a>';
        String visualForcePageLinkForAdmin = '<a href="' + baseUrl + '/apex/FlexLogDetailsPage?accountId=' + accountId + 
            '&userId=' + getCreatedByUserId + 
            '&notify=' + 'true' + 
            '&contractIds=' + contractIdParam + 
            '&showLogs=' + 'true' + 
            '"> Click here </a>';

        String accountNameForNotification = [SELECT Name FROM Account WHERE Id = :accountId].Name;
        String notificationBody = accountNameForNotification + '.\n An Email has been sent to your inbox containing further details.';
        String contractIdnLink = ' <h4> Contract Details </h4> <ul>';

        Map<Id, Contract> contractMap = new Map<Id, Contract>([
            SELECT Id, ContractNumber FROM Contract WHERE Id IN :contractList
        ]);

        // Process each log record and build email content
        for (Flex_Log__c log : logRecords) {
            String contractName = contractMap.containsKey(log.ContractId__c) ? contractMap.get(log.ContractId__c).ContractNumber : 'Unknown Contract';
            contractIdnLink += ' <li> Contract: ' + '<a href=" ' + baseUrl + '/' + log.ContractId__c + ' "> ' + contractName + ' </a>' + '(' + log.Status__c + ')' + ' </li>';
        }
        contractIdnLink += '</ul>';

        // Update log records to indicate user notification
        for (Flex_Log__c log : logRecords) {
            log.userNotified__c = true;
        }
        update logRecords;

        if (hasFailedLogs) {
            notificationTitle = 'Error: The C&R Process Did Not Initiate';
            notificationBody = ' The system encountered an issue and was unable to initiate the C&R Process for ' + notificationBody;
            Id templateIdFailure = [SELECT Id FROM EmailTemplate WHERE DeveloperName = 'Flex_C_R_Failure_Template'].Id;
            Id templateIdFailureAdmin = [SELECT Id FROM EmailTemplate WHERE DeveloperName = 'Flex_C_R_Failure_Template_Admin'].Id;
            // Send in-app notification regardless of email success/failure
            sendInAppNotification('failedUpgradeQuoteId', notificationBody, notificationTitle);
            
            try {
                sendEmailUsingTemplate(userEmailAddress, templateIdFailure, accountName, name, contractIdnLink, revenueOppId, revenueOppName, visualForcePageLinkForUser,'','');
                sendEmailUsingTemplate(adminEmailAddress, templateIdFailureAdmin, accountName, name, contractIdnLink, revenueOppId, revenueOppName, visualForcePageLinkForAdmin,'','');
            } catch(Exception e) {
                // Update existing log records with email error
                for(Flex_Log__c log : logRecords) {
                    if (log.ErrorMessage__c != null) {
                        log.ErrorMessage__c += '\n\n' + 'Failed to send email notification: ' + e.getMessage() + '\n' + 'Stack Trace: ' + e.getStackTraceString();
                    } else {
                        log.ErrorMessage__c = 'Failed to send email notification: ' + e.getMessage() + '\n' + 'Stack Trace: ' + e.getStackTraceString();
                    }
                }
                update logRecords;
            }
                
        } else {
            notificationTitle = 'Your Replacement Quote is Ready';
            notificationBody = ' The Mid-Contract Change (C&R) has been successfully initiated for ' + notificationBody;
            Id templateIdSuccess = [SELECT Id FROM EmailTemplate WHERE DeveloperName = 'Flex_C_R_Success_Template'].Id;
            
            // Send in-app notification first
            sendInAppNotification(logRecords[0].RevenueQuoteId__c, notificationBody, notificationTitle);
            
            try {
                sendEmailUsingTemplate(userEmailAddress, templateIdSuccess, accountName, name, contractIdnLink, revenueOppId, revenueOppName, visualForcePageLinkForUser,enablementLink,replacementQuoteId);
            } catch(Exception e) {
                // Update existing log records with email error
                for(Flex_Log__c log : logRecords) {
                    if (log.ErrorMessage__c != null) {
                        log.ErrorMessage__c += '\n\n' + 'Failed to send email notification: ' + e.getMessage() + '\n' + 'Stack Trace: ' + e.getStackTraceString();
                    } else {
                        log.ErrorMessage__c = 'Failed to send email notification: ' + e.getMessage() + '\n' + 'Stack Trace: ' + e.getStackTraceString();
                    }
                }
                update logRecords;
            }
        }
        System.debug('Email sent and logs updated successfully.');
    }

    /**
     * Sends an email using the specified template and replaces placeholders with actual values.
     * @param emailAddress The list of email addresses to send the email to.
     * @param templateId The ID of the email template to use.
     * @param accountName The account name to replace in the template.
     * @param oppOwnerName The opportunity owner name to replace in the template.
     * @param contractDetails The contract details to replace in the template.
     * @param revenueOppId The revenue opportunity ID to replace in the template.
     * @param revenueOppName The revenue opportunity name to replace in the template.
     * @param link The visual force page link to replace in the template.
     */
    public static void sendEmailUsingTemplate(List<String> emailAddress, Id templateId, String accountName, String oppOwnerName, String contractDetails, String revenueOppId, String revenueOppName, String link, String enablementLink , String replacementQuoteId) {
        try {
            String baseUrl = System.URL.getOrgDomainUrl().toExternalForm();
            // Query the email template
            EmailTemplate template = [SELECT Id, Body FROM EmailTemplate WHERE Id = :templateId];

            // Render the email template
            Messaging.SingleEmailMessage email = Messaging.renderStoredEmailTemplate(template.Id, UserInfo.getUserId(), null);

            // Replace placeholders in the email body
            String renderedEmailBody = email.getHtmlBody();
            renderedEmailBody = renderedEmailBody.replace('@@AccountName@@', accountName);
            renderedEmailBody = renderedEmailBody.replace('@@OppOwnerName@@', oppOwnerName);
            renderedEmailBody = renderedEmailBody.replace('@@Quote@@','<a href=" ' + baseUrl + '/' + replacementQuoteId + ' "> ' + 'Quote' + '</a>  ');
            
            
            renderedEmailBody = renderedEmailBody.replace('@@ReplacementOppName@@', '<a href=" ' + baseUrl + '/' + revenueOppId + ' "> ' + revenueOppName + '</a>  ');
            renderedEmailBody = renderedEmailBody.replace('@@VFPageLink@@', link);
            renderedEmailBody = renderedEmailBody.replace('@@EnablementLink@@', enablementLink != null ? enablementLink : '#');
            renderedEmailBody = renderedEmailBody.replace('@@ContractDetails@@', contractDetails);
            
            // Set the email details
            email.setToAddresses(emailAddress);
            email.setHtmlBody(renderedEmailBody);
            email.setSaveAsActivity(false); // Set saveAsActivity to false

            // Send the email
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { email });
            System.debug('Email sent successfully using template.');
        } catch (Exception e) {
            System.debug('Error sending email using template: ' + e.getMessage());
            throw e;
        }
    }

    /**
     * Sends an in-app notification to the user.
     * @param upgradeQuoteId The ID of the upgrade quote related to the notification.
     * @param notificationBody The body content of the notification.
     * @param notificationTitle The title of the notification.
     */
    public static void sendInAppNotification(String upgradeQuoteId, String notificationBody, String notificationTitle) {
        Id targetUpgradeQuoteId = upgradeQuoteId != 'failedUpgradeQuoteId' ? Id.valueOf(upgradeQuoteId) : '000000000000000AAA';
        Id userId = UserInfo.getUserId();
        Set<String> recipientsIds = new Set<String>{userId};
        String notificationDeveloperName = 'flexInAppNotificationForLogs';
        CustomNotificationFromApex.notifyUsers(recipientsIds, targetUpgradeQuoteId, notificationDeveloperName, notificationTitle, notificationBody);
        System.debug('notification sent!!');
    }
}