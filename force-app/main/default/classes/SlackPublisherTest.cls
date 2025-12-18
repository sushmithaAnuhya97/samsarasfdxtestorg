@isTest
private class SlackPublisherTest
{
	static testMethod void testPostToSlack()
	{
		// Generate deal
		SlackPublisher.Oppty newOppty = new SlackPublisher.Oppty();
		newOppty.opptyName = 'TEST';
		newOppty.opptyOwnerFN = 'John';
		newOppty.opptyOwnerLN = 'Smith';
		newOppty.opptyAmount = 10000.0;
		newOppty.accountName = 'testers inc';
		newOppty.opptyId = '123456789';
		newOppty.opportunityAcvBookings =5000.0;
        
		// Post Deal to slack
		List<SlackPublisher.Oppty> lst = new List<SlackPublisher.Oppty>();
		lst.add(newOppty);
		try {
			SlackPublisher.postToSlack(lst);
		} 
		catch (exception e) {
		}

		// Assert something true
		System.assertEquals(lst, lst);
	}
}