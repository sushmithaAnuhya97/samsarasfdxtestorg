@isTest
public class SSUtilsTest {

    @isTest
    public static void getUUIDTest() {
        Test.startTest();
        String uuid = SSUtils.getUUID();
        Test.stopTest();
        System.assertEquals(uuid != null, true, 'UUID is not generated');
    }
}