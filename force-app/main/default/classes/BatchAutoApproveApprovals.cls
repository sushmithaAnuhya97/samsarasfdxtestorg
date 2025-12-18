global without sharing class BatchAutoApproveApprovals implements Database.Batchable<sObject>, Database.AllowsCallouts {
   global Database.QueryLocator start(Database.BatchableContext context) {
        Datetime fourHoursAgo = System.now().addHours(Integer.valueof(system.label.BatchApprovalTimeDiff));
        String utcFormatted = fourHoursAgo.formatGmt('yyyy-MM-dd\'T\'HH:mm:ss\'Z\'');
        String soql;
        //approval rules from metadata
        Map<String,BatchAutoApprovalRules__mdt > autoapprovalRules = BatchAutoApprovalRules__mdt.getAll();
        List<String> appRules=new List<String>();
        for(BatchAutoApprovalRules__mdt ba: autoapprovalRules.values()){
           if(ba.isActive__c && !String.isBlank(ba.Rule_Name__c))
               appRules.add(ba.Rule_Name__c);
        }
        string query=system.label.BatchAutoApprovalQuery;
        String filterQueryRules=null;
        if(appRules.isEmpty()){
            soql=query + 'and Id=null';
            return Database.getQueryLocator(soql) ;// if no approval rules in metadata and no active approval rules to return 0 records -kept id=null condition
        }
       string filterRules=String.join(appRules, '\',\'');
       filterQueryRules=' AND sbaa__Rule__r.Name IN (\''+filterRules+'\')';  
       string filterDate=' AND CreatedDate < '+utcFormatted+' AND CreatedDate >='+System.label.BatchApprovalStartDate+' AND CreatedDate<='+system.label.BatchApprovalEndDate;
       soql=query+filterQueryRules+filterDate+' ORDER BY CreatedDate DESC';
       return Database.getQueryLocator(soql) ;
	}

	global void execute(Database.BatchableContext context, List<sObject> scope) {
        List<Log__c> logList = new List<Log__c>();
		Http httpClient = new Http();
		String orgBaseUrl = URL.getOrgDomainUrl().toExternalForm();
		String endpointUrl = orgBaseUrl + '/services/apexrest/sbaa/ServiceRouter';

		// Reuse the same Authorization header style as elsewhere in this org
		String sessionIdHeaderValue = UserInfo.getOrganizationId() + '' + UserInfo.getSessionId().substring(15);
		String bearerHeader = 'Bearer ' + sessionIdHeaderValue;
       
		for (sObject recordObj : scope) {
			sbaa__Approval__c approval = (sbaa__Approval__c)recordObj;
			try {
                System.debug(approval.id);
				HttpRequest request = new HttpRequest();
				request.setEndpoint(endpointUrl);
				request.setMethod('POST');
				request.setHeader('Content-Type', 'application/json');
				request.setHeader('Authorization', bearerHeader);

                // Provider and payload used by existing automation in this org
                String payload = '{"model":"{\\"approvalId\\":\\"' + String.valueOf(approval.Id) +
                    '\\",\\"comments\\":\\"'+system.label.batch_auto_approval_comments+'\\"}","saver":"SBAA.ApprovalRestApiProvider.Approve"}';
                
                request.setBody(payload);
                HTTPResponse response = httpClient.send(request);
				Integer statusCode = response.getStatusCode();
				if (statusCode >= 200 && statusCode < 300) {
					//totalSuccessCount++;
				} else {
				logList.add( getLog ('AutoApprovalFailure',  approval.Id,response.getBody()) );
                      }
			} catch (Exception ex) {
				
              logList.add( getLog ('AutoApprovalException', approval.Id,ex.getMessage()) );

			}
		}
        if (!logList.isEmpty()) {
			insert logList;
		}
	}

	global void finish(Database.BatchableContext context) {
		
	}
    @testVisible private Log__c getLog(String msg, String errorMsg, String exceptionMsg)
    {
        Log__c logRec = new Log__c();
        logRec.Message__c = msg;
        logRec.ClassName__c = 'BatchAutoApproveApprovals';
        logRec.LogLevel__c = 'Error';
        logRec.Error_Message__c = errorMsg;
        logRec.ExceptionMessage__c = exceptionMsg;
        return logRec;
    }
   
}