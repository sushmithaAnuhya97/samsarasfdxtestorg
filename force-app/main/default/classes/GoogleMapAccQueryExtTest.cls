@isTest
public class GoogleMapAccQueryExtTest {
    static testMethod void checkGoogleMapExtController() {
        GoogleMapAccQueryExt.getAccounts('SELECT Id, Name FROM Account');
    }
}