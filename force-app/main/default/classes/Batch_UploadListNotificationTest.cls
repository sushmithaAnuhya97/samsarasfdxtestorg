/*
* @Author : Siddharth Kumar Mishra
* @Description:- Test class for Batch_UploadListNotification ( GTMS - 6447  -  4/23/2022  -  MX Non Compliant Tax Payers )
*/
@IsTest
public class Batch_UploadListNotificationTest
{
    @IsTest
    static void testMethod01()
    {
        Test.startTest();
        database.executebatch((new Batch_UploadListNotification()),200);
        Test.stopTest();
    }
    
}