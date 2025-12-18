@isTest
private class TaskTests {

	@isTest static void ContactTask() {
		// Create a contact
		Account a = (Account) TestFactory.createSOBject(new Account());
		insert a;
		// Insert contacts with different sources
		Contact c = (Contact) TestFactory.createSOBject(new Contact(Email = 'phillip.front@samsara.com', AccountId = a.Id));
		insert c;
		Task t = new Task(WhoId = c.Id, Subject = 'Call', ActivityDate = Date.Today());
		insert t;
		Task newT = [SELECT Id, Related_Contact__c, WhoId FROM Task LIMIT 1][0];
		System.AssertEquals(newT.WhoId, newT.Related_Contact__c);
		t.WhoId = NULL;
		update t;
		newT = [SELECT Id, Related_Contact__c, WhoId FROM Task LIMIT 1][0];
		System.AssertEquals(newT.WhoId, newT.Related_Contact__c);
	}

	@isTest static void createCallLog() {
		List<Task> tasks = new List<Task>();
		Account a = (Account) TestFactory.createSOBject(new Account(Name = 'Test Account'));
		insert a;
		// Insert contacts with different sources
		Contact c = (Contact) TestFactory.createSOBject(new Contact(Email = 'testymctesterson@email.com', AccountId = a.Id));
		insert c;
		Task taskOne = new Task(WhoId = c.Id, Subject = 'Call', ActivityDate = Date.Today(), CallDurationInSeconds = 60);
		tasks.add(taskOne);
		Task taskTwo = new Task(WhatId = a.Id, Subject = 'Call', ActivityDate = Date.Today(), CallDurationInSeconds = 60);
		tasks.add(taskTwo);

		test.startTest();
		insert tasks;
		test.stopTest();

		Contact ctc = [SELECT Id, Number_of_Calls__c FROM Contact WHERE Id = :c.Id];
		Account account = [SELECT Last_Contacted__c FROM Account WHERE Id = :a.Id];

		System.assertEquals(1, ctc.Number_of_Calls__c);
		System.assert(account.Last_Contacted__c <> null);
	}

	@isTest static void createEmailTask() {
		List<Task> tasks = new List<Task>();
		Account a = (Account) TestFactory.createSOBject(new Account(Name = 'Test Account'));
		insert a;
		// Insert contacts with different sources
		Contact c = (Contact) TestFactory.createSOBject(new Contact(Email = 'testymctesterson@email.com', AccountId = a.Id));
		insert c;
		Task taskOne = new Task(WhoId = c.Id, ActivityDate = Date.Today(), Subject = 'Email');
		tasks.add(taskOne);
		Task taskTwo = new Task(WhatId = a.Id, ActivityDate = Date.Today(), Subject = 'Email Acccount Only');
		tasks.add(taskTwo);

		test.startTest();
		insert tasks;
		test.stopTest();

		Contact ctc = [SELECT Id, Number_of_Calls__c, Last_Contacted__c FROM Contact WHERE Id = :c.Id];
		Account account = [SELECT Last_Contacted__c FROM Account WHERE Id = :a.Id];
		System.assert(ctc.Last_Contacted__c <> null);
		System.assert(account.Last_Contacted__c <> null);
	}

	@isTest static void irtCalculation() {

		Campaign campaign = new Campaign(Name = 'Test Campaign', Type = 'Website - Form');
		insert campaign;

		Account a = (Account) TestFactory.createSOBject(new Account(Name = 'Test Account'));
		insert a;
		// Insert contacts with different sources

		test.startTest();
		Contact c = (Contact) TestFactory.createSOBject(new Contact(Email = 'testymctesterson@email.com', AccountId = a.Id, Campaign_to_Add__c = campaign.Id, Campaign_Member_Status__c = 'Responded'));
		insert c;
		test.stopTest();

		Task t = new Task(WhoId = c.Id, Subject = 'Call', ActivityDate = Date.Today(), CallDurationInSeconds = 60);
		insert t;

		/*CampaignMember cm = [SELECT Id, Initial_Response_Time__c, Campaign_Interaction_Date__c FROM CampaignMember WHERE ContactId = :c.Id];
		System.debug(LoggingLevel.INFO, 'IRT Campaign Member: ' + cm.Id + cm.Campaign_Interaction_Date__c);

		CampaignMember cm2 = [SELECT Id, Initial_Response_Time__c, Campaign_Interaction_Date__c FROM CampaignMember WHERE ContactId = :c.Id];

		System.debug(LoggingLevel.INFO, 'IRT Campaign Member:'+cm2.Id+' '+cm2.Initial_Response_Time__c);
		System.assert(cm2.Initial_Response_Time__c != null);*/
	}

	@isTest static void salesLoft() {
		Account a = (Account) TestFactory.createSOBject(new Account(Name = 'Test Account'));
		insert a;
		// Insert contacts with different sources
		Contact c = (Contact) TestFactory.createSOBject(new Contact(FirstName = 'Testy', LastName = 'McTesterson', Email = 'testymctesterson@email.com', AccountId = a.Id, Description = 'Hello'));
		insert c;
		Task t = new Task(WhoId = c.Id, Subject = 'Call', ActivityDate = Date.Today(), CallDurationInSeconds = 60, RecordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByName().get('Sales Loft').getRecordTypeId(), Description = 'Testing123');

		test.startTest();
		insert t;
		test.stopTest();

		Contact ctc = [SELECT Id, Number_of_Calls__c, Description FROM Contact WHERE Id = :c.Id];
		System.assert(ctc.Description.contains('Testing123'));
		System.assert(ctc.Description.contains('Hello'));
		System.assert(ctc.Description.contains(UserInfo.getFirstName()));
	}

	//@author Groundswell - Vikasm - vikas@gscloudsolutions.com
	//@date 2020-08-31
	//GTMS-1471
	@isTest static void processNumberOfCallsByCurrentOwnerTest() {
		Account acc = new Account ();
		acc = TestFactory.initializeAccount('ADR_Transfer_LogTrigger');
		insert acc;

		Contact Con = new Contact();
		con = TestFactory.initializeContact('ADR_Transfer_LogTrigger');
		insert con;

		Task t = new Task(WhoId = con.Id, WhatId = acc.Id, CallType = 'Outbound', TaskSubtype = 'Call',Subject = 'Outbound to Test', ActivityDate = Date.Today(), CallDurationInSeconds = 60, RecordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByName().get('Sales Loft').getRecordTypeId(), Description = 'Testing123');
		test.startTest();
		insert t;
		test.stopTest();

		//Contact ctc = [SELECT Id, Number_of_Calls_by_Current_Owner_Roll_Up__c FROM Contact WHERE Id = :con.Id];
		//System.assertEquals(ctc.Number_of_Calls_by_Current_Owner_Roll_Up__c, 1);

	}

	@isTest static void processNumberOfCallsByCurrentOwnerTestDeleteUndelete() {
		Account acc = new Account ();
		acc = TestFactory.initializeAccount('ADR_Transfer_LogTrigger');
		insert acc;

		Contact Con = new Contact();
		con = TestFactory.initializeContact('ADR_Transfer_LogTrigger');
		insert con;

		Task t = new Task(WhoId = con.Id, WhatId = acc.Id, CallType = 'Outbound', TaskSubtype = 'Call', Subject = 'Outbound to Test', ActivityDate = Date.Today(), CallDurationInSeconds = 60, RecordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByName().get('Sales Loft').getRecordTypeId(), Description = 'Testing123');
		insert t;
		test.startTest();
		delete t;
		//Contact ctc = [SELECT Id, Number_of_Calls_by_Current_Owner_Roll_Up__c FROM Contact WHERE Id = :con.Id];
		//System.assertEquals(ctc.Number_of_Calls_by_Current_Owner_Roll_Up__c, null);

		Task[] savedTasks = [SELECT Id FROM Task WHERE WhoId = :con.id ALL ROWS];
		undelete savedTasks;
		test.stopTest();


	}

	@isTest static void rollup_Call_by_current_ownerInsertTest() {
		Account acc = new Account ();
		acc = TestFactory.initializeAccount('ADR_Transfer_LogTrigger');
		insert acc;

		Contact Con = new Contact();
		con = TestFactory.initializeContact('ADR_Transfer_LogTrigger');
		insert con;

		Task t = new Task(WhoId = con.Id, WhatId = acc.Id, CallType = 'Outbound', TaskSubtype = 'Call',Subject = 'Outbound to Test', ActivityDate = Date.Today(), CallDurationInSeconds = 60, RecordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByName().get('Sales Loft').getRecordTypeId(), Description = 'Testing123');

		insert t;

		//acc = [SELECT Id, Number_of_Calls_by_Current_Owner__c FROM Account WHERE Id = :acc.Id];
		//System.assertEquals(acc.Number_of_Calls_by_Current_Owner__c, 1);

		test.startTest();
		delete t;
		//acc = [SELECT Id, Number_of_Calls_by_Current_Owner__c FROM Account WHERE Id = :acc.Id];
		//System.assertEquals(acc.Number_of_Calls_by_Current_Owner__c, null);

		Task[] savedTasks = [SELECT Id FROM Task WHERE WhatId = :acc.id ALL ROWS];
		undelete savedTasks;
		test.stopTest();


	}
	//Tested with 200 record insert at once
	@isTest static void rollup_Call_by_current_ownerInsertBulkTest() {
		Integer maxTaskDML = 2;
		Account acc = new Account ();
		acc = TestFactory.initializeAccount('ADR_Transfer_LogTrigger');
		insert acc;

		Contact Con = new Contact();
		con = TestFactory.initializeContact('ADR_Transfer_LogTrigger');
		insert con;
		List<Task> taskList = new List<Task>();
		for (Integer i = 0; i < maxTaskDML; i++) {
			Task t = new Task(WhoId = con.Id, WhatId = acc.Id, CallType = 'Outbound', TaskSubtype = 'Call',Subject = 'Outbound to Test' + i, ActivityDate = Date.Today(), CallDurationInSeconds = 60, RecordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByName().get('Sales Loft').getRecordTypeId(), Description = 'Testing123' + i);
			taskList.add(t);
		}
		test.startTest();
		insert taskList;

		//acc = [SELECT Id, Number_of_Calls_by_Current_Owner__c FROM Account WHERE Id = :acc.Id];
		//System.assertEquals(acc.Number_of_Calls_by_Current_Owner__c, maxTaskDML);

		test.stopTest();


	}

	@isTest static void rollup_Number_of_CallsInsertTest() {
		Account acc = new Account ();
		acc = TestFactory.initializeAccount('ADR_Transfer_LogTrigger');
		insert acc;

		Contact Con = new Contact();
		con = TestFactory.initializeContact('ADR_Transfer_LogTrigger');
		insert con;

		Task t = new Task(WhoId = con.Id, WhatId = acc.Id, CallType = 'Outbound', TaskSubtype = 'Call', Subject = 'Outbound to Test', ActivityDate = Date.Today(), CallDurationInSeconds = 60, RecordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByName().get('Sales Loft').getRecordTypeId(), Description = 'Testing123');

		insert t;

		acc = [SELECT Id, Number_of_Calls__c FROM Account WHERE Id = :acc.Id];
		System.assertEquals(acc.Number_of_Calls__c, 1);

		test.startTest();
		delete t;
		acc = [SELECT Id, Number_of_Calls__c FROM Account WHERE Id = :acc.Id];
		System.assertEquals(acc.Number_of_Calls__c, null);
		test.stopTest();


	}
	//Tested with 200 record insert at once
	@isTest static void rollup_Number_of_CallsInsertBulkTest() {
		Integer maxTaskDML = 2;
		Account acc = new Account ();
		acc = TestFactory.initializeAccount('ADR_Transfer_LogTrigger');
		insert acc;

		Contact Con = new Contact();
		con = TestFactory.initializeContact('ADR_Transfer_LogTrigger');
		insert con;
		List<Task> taskList = new List<Task>();
		for (Integer i = 0; i < maxTaskDML; i++) {
			Task t = new Task(WhoId = con.Id, WhatId = acc.Id, CallType = 'Outbound', TaskSubtype = 'Call', Subject = 'Outbound to Test' + i, ActivityDate = Date.Today(), CallDurationInSeconds = 60, RecordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByName().get('Sales Loft').getRecordTypeId(), Description = 'Testing123' + i);
			taskList.add(t);
		}
		test.startTest();
		insert taskList;

		acc = [SELECT Id, Number_of_Calls__c FROM Account WHERE Id = :acc.Id];
		System.assertEquals(acc.Number_of_Calls__c, maxTaskDML);

		test.stopTest();


	}
}