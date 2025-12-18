public class CaseTriggerHandler extends TriggerHandler{
	static gslib_IModuleLogger thisModuleLogger;
    static gslib_ILogger thisLogger;

	static
	{
		thisModuleLogger = gslib_LoggerService.getModuleLogger('GTMS');
		thisLogger =  thisModuleLogger.getLogger();		
	}

	private List<Case> newCaseList;
	private UnitOfWork uow;
	public static List<Schema.SObjectType> MY_SOBJECTS = new List<Schema.SObjectType>{
			Case.SObjectType,
			User.SObjectType,
			Issue__c.SObjectType,
			Contact.SObjectType
	};

	public CaseTriggerHandler() {
		this.newCaseList = (List<Case>) Trigger.new;
		DMLWrapper.intializeUnitOfWork(MY_SOBJECTS);
	}

	public override void afterInsert()
	{
		try
		{
			CaseHelper.executeAssignmentRuleForPartnerSupport(this.newCaseList);
			CaseHelper.caseAssignToRoundRobin(this.newCaseList);
			CaseHelper.ReturnPolicyDays(this.newCaseList);
			CaseHelper.caseRollUpAtRiskAndSupportPriority(this.newCaseList);

		} catch (Exception e) 
		{
			thisLogger.logError('CaseTriggerHandler. afterInsert. Error Message ::'+ e.getMessage() +' | StackTrace:: '+ e.getStackTraceString() +' | Case List ::', newCaseList);
			
			throw e;
		}
		finally{
			thisLogger.dispatch();
		}
	}

	public override void afterUpdate()
	{        
		try
		{
			CaseHelper.caseRollUpAtRiskAndSupportPriority(this.newCaseList);

		} catch (Exception e) 
		{
			thisLogger.logError('CaseTriggerHandler. afterUpdate. Error Message ::'+ e.getMessage() +' | StackTrace:: '+ e.getStackTraceString() +' | Case List ::', newCaseList);

			throw e;
		}
		finally{
			thisLogger.dispatch();
		}        
	}

	public override void beforeInsert()
	{   
		try
		{
			CaseHelper.assignContactOnCaseFromDashboard(this.newCaseList);

		} catch (Exception e) 
		{
			thisLogger.logError('CaseTriggerHandler. beforeInsert. Error Message ::'+ e.getMessage() +' | StackTrace:: '+ e.getStackTraceString() +' | Case List ::', newCaseList);

			throw e;
		}
		finally{
			thisLogger.dispatch();
		}
	}

	public override void publishDMLs() {
		uow = DMLWrapper.uow;
		DMLWrapper.publishDML(uow);
	}
}