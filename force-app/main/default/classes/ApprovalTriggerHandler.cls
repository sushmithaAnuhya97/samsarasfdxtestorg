public class ApprovalTriggerHandler extends TriggerHandler {
    private static final String APPROVAL_SETTING = 'Approval';
    private static final Integer MAX_RUNS = 1;
    private static final String CLASS_NAME = 'ApprovalTriggerHandler';

    private static final String APPROVER_NAME = System.Label.Renewals_Approver_Name;
    public static Set<String> TARGET_APPROVAL_RULE_ID = initializeTargetApprovalRuleId();
    private static final Set<String> EMAIL_RECIPIENT_RENEWALS_REJECTION = initializeRejectionEmailRecipients();
    private static final String SOBJECT_TYPE_SBQQ_QUOTE = 'Quote__c';


    gslib_IModuleLogger thisModuleLogger = gslib_LoggerService.getModuleLogger('GTMS');
    gslib_ILogger thisLogger = thisModuleLogger.getLogger();
    
    private final Map<Id, SBAA__Approval__c> oldApprovalMap;
    private final Map<Id, SBAA__Approval__c> newApprovalMap;
    private final List<SBAA__Approval__c> newApprovalList;
    
    public static final List<Schema.SObjectType> MY_SOBJECTS = new List<Schema.SObjectType>{
        SBAA__Approval__c.SObjectType,
        Approval_Log__c.SObjectType,
        SBAA__ApprovalCondition__c.SObjectType,
        SBQQ__Quote__c.SObjectType,
        Opportunity.SObjectType,
        SBQQ__QuoteLine__c.SObjectType
    };
    
    private static Boolean isTriggerEnabled;
    private static Map<String, Integer> methodsCalled;
    
    public ApprovalTriggerHandler() {
        System.debug(LoggingLevel.DEBUG, CLASS_NAME + ' - Constructor Start');

        this.oldApprovalMap = (Map<Id, SBAA__Approval__c>) Trigger.oldMap;
        this.newApprovalMap = (Map<Id, SBAA__Approval__c>) Trigger.newMap;
        this.newApprovalList = (List<SBAA__Approval__c>) Trigger.new;
            
        if (methodsCalled == null) {
            methodsCalled = new Map<String, Integer>();
        }
            
        if (MY_SOBJECTS != null && !MY_SOBJECTS.isEmpty()) {
            DMLWrapper.intializeUnitOfWork(MY_SOBJECTS);
        } 
        
        System.debug(LoggingLevel.DEBUG, CLASS_NAME + ' - Constructor End');
    }
    
    public override void afterInsert() {
        System.debug(LoggingLevel.DEBUG, CLASS_NAME + ' - afterInsert Start');
        try {
            if (!isEnabled()) {
                thisLogger.logInfo('Approval Logging Error',new SamsaraLoggerObjectMVP('Trigger is disabled',CLASS_NAME));
                return;
            }
            
            if (timesCalled('afterInsert') >= MAX_RUNS) {
                thisLogger.logInfo('Approval Logging Error',new SamsaraLoggerObjectMVP('Maximum number of runs reached',CLASS_NAME));
                return;
            }
            
            addCall('afterInsert');
            if (newApprovalList == null || newApprovalList.isEmpty()) {
                System.debug(LoggingLevel.INFO, CLASS_NAME + ' - No records to process');
                return;
            }
            
            System.enqueueJob(new ApprovalLogQueueable(newApprovalList));                     
            
        } catch (Exception e) {
            thisLogger.logError('Approval Logging Error',new SamsaraLoggerObjectMVP(e,newApprovalList));
            throw e;
        } finally {
            thisLogger.dispatch();
        }
    }
    
    public override void afterUpdate() {
        System.debug(LoggingLevel.DEBUG, CLASS_NAME + ' - afterUpdate Start');
        try {
            if (!isEnabled()) {
                thisLogger.logInfo('Approval Update Logic Info', new SamsaraLoggerObjectMVP('Trigger is disabled, skipping afterUpdate.',CLASS_NAME));
                return;
            }

            if (timesCalled('afterUpdate') >= MAX_RUNS) {
                thisLogger.logInfo(
                    'Approval Update Logic Info', 
                    new SamsaraLoggerObjectMVP(
                        'Maximum number of runs reached for afterUpdate.',
                        CLASS_NAME
                    )
                );
                return;
            }

            addCall('afterUpdate');
            if (newApprovalList == null || newApprovalList.isEmpty()) {
                System.debug(LoggingLevel.INFO, CLASS_NAME + ' - No records to process in afterUpdate');
                return;
            }

            processRejectedApprovals();

        } catch (Exception e) {
            thisLogger.logError('Approval Update Processing Error', new SamsaraLoggerObjectMVP(e,newApprovalList ));
            throw e; 
        } finally {
            thisLogger.dispatch(); 
        }
        System.debug(LoggingLevel.DEBUG, CLASS_NAME + ' - afterUpdate End');
    }
    
    public override void publishDMLs() {
        System.debug(LoggingLevel.DEBUG, CLASS_NAME + ' - publishDMLs Start');
        if (DMLWrapper.uow != null) {
            DMLWrapper.publishDML(DMLWrapper.uow);
        } 
        
        System.debug(LoggingLevel.DEBUG, CLASS_NAME + ' - publishDMLs End');
    }
    
    public static Boolean isEnabled() {
        if (isTriggerEnabled != null) {
            return isTriggerEnabled;
        }

        List<Trigger_Setting__mdt> settings = [
            SELECT Enabled__c 
            FROM Trigger_Setting__mdt 
            WHERE MasterLabel = :APPROVAL_SETTING 
            LIMIT 1
        ];
            
        isTriggerEnabled = settings.isEmpty() ? true : settings[0].Enabled__c;

        return isTriggerEnabled;
    }

    public static void resetAll() {
        if (methodsCalled != null) {
            methodsCalled.clear();
        }
        methodsCalled = new Map<String, Integer>();
        isTriggerEnabled = null;
    }
    
    public static Integer timesCalled(String methodName) {
        if (methodsCalled == null) {
            methodsCalled = new Map<String, Integer>();
        }
        return methodsCalled.containsKey(methodName) ? methodsCalled.get(methodName) : 0;
    }
    
    private static Integer addCall(String methodName) {
        if (methodsCalled == null) {
            methodsCalled = new Map<String, Integer>();
        }
        Integer calls = timesCalled(methodName) + 1;
        methodsCalled.put(methodName, calls);
        return calls;
    }
	/* Added for GTMS-27963 */ 
    private void processRejectedApprovals() {
        Set<Id> candidateApprovalIds = new Set<Id>();

        for (SBAA__Approval__c newApproval : newApprovalList) {
            SBAA__Approval__c oldApproval = this.oldApprovalMap.get(newApproval.Id);

            if (oldApproval != null && 
                oldApproval.sbaa__Status__c != 'Rejected' && newApproval.sbaa__Status__c == 'Rejected' && 
                SOBJECT_TYPE_SBQQ_QUOTE.equalsIgnoreCase(newApproval.sbaa__RecordField__c) && 
                newApproval.Quote__c != null) { 
                candidateApprovalIds.add(newApproval.Id);
            }
        }

        if (candidateApprovalIds.isEmpty()) {
            System.debug(LoggingLevel.INFO, CLASS_NAME + ' - No candidate rejected quote approvals found matching initial criteria.');
            return;
        }

        List<SBAA__Approval__c> approvalsToNotify = [
            SELECT Id, Owner.Email, 
                   Quote__c, 
                   Quote__r.Name,
            	   Quote__r.OwnerId,
				   Quote__r.Owner.Email,
                   Quote__r.SBQQ__Opportunity2__r.Id, 
                   Quote__r.SBQQ__Opportunity2__r.Name, 
                   Quote__r.SBQQ__Opportunity2__r.Owner.Manager.Email,
                   sbaa__Approver__r.name, 
                   sbaa__Rule__r.Name
            FROM SBAA__Approval__c
            WHERE Id IN :candidateApprovalIds
              AND sbaa__Approver__r.Name = :APPROVER_NAME
              AND SBAA__Rule__r.Id IN :TARGET_APPROVAL_RULE_ID
        ];
        
       



        if (approvalsToNotify.isEmpty()) {
            System.debug(LoggingLevel.INFO, CLASS_NAME + ' - No approvals matched all criteria (Approver, Rule Name) for notification.');
            return;
        }
        
        EmailTemplate template;
        
        template = [SELECT Id FROM EmailTemplate WHERE DeveloperName = 'Quote_Rejected_Notification' LIMIT 1];
        
        
        List<Messaging.SingleEmailMessage> emailsToSend = new List<Messaging.SingleEmailMessage>();

        for (SBAA__Approval__c approval : approvalsToNotify) {
            List<String> ccAddresses = new List<String>();
            
            if (!EMAIL_RECIPIENT_RENEWALS_REJECTION.isEmpty()) {
                ccAddresses.addAll(EMAIL_RECIPIENT_RENEWALS_REJECTION);
            }

            if (approval.Quote__r.SBQQ__Opportunity2__r != null && 
                approval.Quote__r.SBQQ__Opportunity2__r.Owner.Manager != null && 
                String.isNotBlank(approval.Quote__r.SBQQ__Opportunity2__r.Owner.Manager.Email)) {
                ccAddresses.add(approval.Quote__r.SBQQ__Opportunity2__r.Owner.Manager.Email);
            }

            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            email.setTemplateId(template.Id);            
            email.setTargetObjectId(approval.OwnerId); 
            if (!Test.isRunningTest()) {
                email.setWhatId(approval.Id);
            }
            email.setToAddresses(new List<String>{approval.Owner.Email}); 
            if (!ccAddresses.isEmpty()) {
                Set<String> uniqueCCAddresses = new Set<String>(ccAddresses);
                email.setCcAddresses(new List<String>(uniqueCCAddresses));
            } 
            email.setSaveAsActivity(false);    
            emailsToSend.add(email);
        }

        if (!emailsToSend.isEmpty() && !Test.isRunningTest()) {
            Messaging.SendEmailResult[] results = Messaging.sendEmail(emailsToSend);     
        } else {
            System.debug(LoggingLevel.INFO, CLASS_NAME + ' - No emails to send after processing all rejected approvals.');
        }
    }

    private static Set<String> initializeTargetApprovalRuleId() {
        Set<String> ruleIds = new Set<String>();
        try {
            String ruleIdFromLabel = System.Label.Renewals_Approval_Rules_For_Robert;
            if (String.isNotBlank(ruleIdFromLabel)) {
                for (String ruleId : ruleIdFromLabel.split(',')) {
                    ruleIds.add(ruleId.trim());
                }
            }
            if (ruleIds.isEmpty()) {
                System.debug(LoggingLevel.WARN, CLASS_NAME + ' - Custom Label Approval_Target_Rule_Names_CSV is not configured or is empty. TARGET_APPROVAL_RULE_NAMES will be empty.');
            }
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, CLASS_NAME + ' - Critical Error: Custom Label Approval_Target_Rule_Names_CSV not found. Please create it. Error: ' + e.getMessage());
           
        }
        return ruleIds;
    }
    
    private static Set<String> initializeRejectionEmailRecipients() {
        Set<String> emailRecipients = new Set<String>();
        try {
            String emailRecipientsFromLabel = System.Label.Renewals_Rejection_Email_CC;
            if (String.isNotBlank(emailRecipientsFromLabel)) {
                for (String email : emailRecipientsFromLabel.split(',')) {
                    emailRecipients.add(email.trim());
                }
            }
            if (emailRecipients.isEmpty()) {
                System.debug(LoggingLevel.WARN, CLASS_NAME + ' - Custom Label Renewals_Rejection_Email_CC is not configured or is empty. EMAIL_RECIPIENT_RENEWALS_REJECTION will be empty.');
            }
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, CLASS_NAME + ' - Critical Error: Custom Label Renewals_Rejection_Email_CC not found. Please create it. Error: ' + e.getMessage());
        }
        return emailRecipients;
    }
    /* GTMS-27963 ENDS */
}