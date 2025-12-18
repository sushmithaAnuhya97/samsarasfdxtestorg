@isTest
public class PCommunityCustomerLogoControllerTest {

    private static String CONTACT_EMAIL = 'testemail@cttmail5619815161.com';
    private static String ACCOUNT_LOGO  = 'https://www.google.com/';

    @TestSetup
    static void setup(){
        
        RecordType accountPartnerRT = [Select Id from RecordType Where SObjectType = 'Account' and Name = 'Partner' LIMIT 1]; 
        Account acc = (Account) TestFactory.createSObject(new Account(Name='Partner', Website='test.test', CSM_First_30d_Stage__c = 'Pending Intro', LogoURL__c = ACCOUNT_LOGO, RecordTypeId = accountPartnerRT.Id));
        insert acc;

        acc.isPartner = true;
        update acc;

        RecordType contactPartnerRT = [Select Id from RecordType Where SObjectType = 'Contact' and Name = 'Partner' LIMIT 1];
        Contact ctt = (Contact) TestFactory.createSObject(new Contact(FirstName = 'Don', LastName = 'Cherry', Email = CONTACT_EMAIL, AccountId = acc.Id, RecordTypeId = contactPartnerRT.Id));
        insert ctt;

        System.runAs(new User(Id = UserInfo.getUserId())){
            Integer randomInt = Integer.valueOf(math.rint(math.random()*1000000));
            insert new User(
                FirstName = 'First',
                LastName = 'Name',
                Email = CONTACT_EMAIL,
                ContactId = ctt.Id,
                Username = 'unique-'+UserInfo.getOrganizationId()+randomInt+'@testuser.com.uat',
                EmailEncodingKey = 'UTF-8',
                Alias = '12398ali',
                TimeZoneSidKey = 'America/Los_Angeles',
                LocaleSidKey = 'en_US',
                LanguageLocaleKey = 'en_US',
                ProfileId = [SELECT Id FROM Profile WHERE Name = 'Samsara Partner Community Login License Admin' LIMIT 1].Id,
                RR_Is_Pool_User__c = false,
                EmployeeNumber='123'
            );
        }
    }

    @isTest
    public static void testGuestUser(){
        String logoUrl = PCommunityCustomerLogoController.getLogoUrlFromAccount(CONTACT_EMAIL);

        System.assertEquals(ACCOUNT_LOGO, logoUrl);
    }

    @isTest
    public static void testInvalidUser(){
        String logoUrl = PCommunityCustomerLogoController.getLogoUrlFromAccount('invalidemail@test.com');

        System.assertEquals('', logoUrl);
    }
}