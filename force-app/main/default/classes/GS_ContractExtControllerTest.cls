/*
 Author: Abu Saleh Khan
 GTMS Ticket Details: GTMS-14429, 14430
 Description: Submit Advanced Approval for Grace Period Extension.
 Visualforce Page: SubmitContract.vfp
 Test Class: GS_ContractExtController.apxc
*/
@isTest
public class GS_ContractExtControllerTest {
    public static Account createAccount(String writtenLanguage, String accountName, String segment) {
        Account testAccount = new Account();
        testAccount.Name = accountName;
        testAccount.Industry = 'Biotechnology';
        testAccount.Organization_Size__c = '500 - 999';
        testAccount.BillingStreet = '123 main';
        testAccount.BillingCity = 'Missoula';
        testAccount.BillingState = 'California';
        testAccount.BillingCountry = 'United States';
        testAccount.BillingPostalCode = '59801';
        testAccount.Billing_Email__c = 'foo@bar.com';
        testAccount.Segment_Text_stamped__c = segment;
        testAccount.Approved_Payment_Type__c = 'Direct Monthly';
        testAccount.Which_written_language__c = writtenLanguage;
        return testAccount;
    }
    public static testMethod void testSubmit(){
        Account newAccount = createAccount('English', 'newAccount', 'SMB');
         	insert newAccount;
        List<User> users = [SELECT Id, ManagerId,Manager.Name,Manager.ManagerId,Manager.Manager.Name,Manager.Manager.ManagerId, 
    						Manager.Manager.Manager.Name FROM User WHERE IsActive = TRUE AND ManagerId != NULL 
                            AND Manager.ManagerId != NULL AND Manager.Manager.ManagerId != NULL AND Profile.Name = 'System Administrator' LIMIT 1];

        Contract crtRec = new Contract(AccountId = newAccount.Id,
                StartDate = Date.today(),
                EndDate = Date.today().adddays(130),
                ContractTerm = 12 );                      
               //SBQQ__Opportunity__c = nonRenewalOpp.Id                    
        insert crtRec;
        Test.startTest();
        System.runAs(users[0]){
        GS_ContractExtController gs_CEC = new GS_ContractExtController(new ApexPages.StandardController(crtRec));
        gs_CEC.onSubmit();
        gs_CEC.onCancel();
        gs_CEC.onRecall();
        }
        test.stopTest();
    }
}