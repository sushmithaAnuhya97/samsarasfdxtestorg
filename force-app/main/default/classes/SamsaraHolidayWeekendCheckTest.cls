/**********************************************************************
Name: SamsaraHolidayWeekendCheckTest
=======================================================================
Purpose: Test class for SamsaraHolidayWeekendCheck
=======================================================================
History  

VERSION     AUTHOR               DATE               DETAIL                       
1.0        Chetan Basavaraju   2023-Nov-06        FOR GTMS-15662

***********************************************************************/ 
@isTest
public class SamsaraHolidayWeekendCheckTest {
    
    @isTest static void testHoliday() {
        Holiday holi = new Holiday(Name='Feb 20',ActivityDate=date.parse('02/20/2023'));
		insert holi;
        Test.startTest();
        List<Boolean> isHolidayRes1 = SamsaraHolidayWeekendCheck.isSamasaraHolidayOrWeekend(new List<Date>{System.today()});
        System.assertEquals(FALSE, isHolidayRes1[0]);
        
        List<Boolean> isHolidayRes2 = SamsaraHolidayWeekendCheck.isSamasaraHolidayOrWeekend(new List<Date>{date.parse('02/20/2023')});
		System.assertEquals(TRUE, isHolidayRes2[0]);
        
        List<Boolean> isHolidayRes3 = SamsaraHolidayWeekendCheck.isSamasaraHolidayOrWeekend(new List<Date>{date.parse('11/05/2023')});
        System.assertEquals(TRUE, isHolidayRes3[0]);
        
        SamsaraHolidayWeekendCheck samTest = new SamsaraHolidayWeekendCheck('United States');
        samTest.determineStartDateTime(System.today());
        samTest.isEmailAlertToBeSent('United States','America/Chicago', System.today());
        samTest.isEmailAlertToBeSent('United States','America/Chicago', System.today()-1);
        samTest.isEmailAlertToBeSent('United States','America/Chicago', System.today()-2);
        samTest.isEmailAlertToBeSent('United States','America/Chicago', System.today()-3);
        samTest.isEmailAlertToBeSent('United States','America/Chicago', System.today()-4);
        samTest.isEmailAlertToBeSent('United States','America/Chicago', System.today()-5);
        samTest.isEmailAlertToBeSent('United States','America/Chicago', System.today()-6);
        Test.stopTest();
        
    }
    
}