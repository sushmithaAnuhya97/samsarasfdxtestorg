@istest
private class UpdateUserRoleInAccountSchedularTest{
    @isTest
	private static void testschedule() {
		Test.StartTest();
		UpdateUserRoleInAccountSchedular testsche = new UpdateUserRoleInAccountSchedular();
		String sch = '0 2 * * * ?';
		system.schedule('Test status Check', sch, testsche );
		Test.stopTest();
	}
}