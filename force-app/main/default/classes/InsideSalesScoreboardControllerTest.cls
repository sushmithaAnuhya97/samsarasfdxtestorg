@isTest(SeeAllData=true) 
public class InsideSalesScoreboardControllerTest {
    static testMethod void testController() {
		InsideSalesScoreboardController x = new InsideSalesScoreboardController(Date.newInstance(2030,12,25));    //cheat - use date way in the future so we test all the loops
        String s = x.CQName;
    }
}