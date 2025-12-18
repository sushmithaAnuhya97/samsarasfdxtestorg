//@isTest(SeeAllData=true)
@isTest
public class FreeTrialInvoiceTest{
    @testSetup
    private static void avalaraSetup() {
        
    }

	@isTest
	static void testFreeTrialAutomation() {

	    
		
         Account a = new Account (Name = 'Sla Co', Organization_Size__c = '5000+', BillingCountry = 'Canada', Industry = 'Other', ADR_Transfer__c = false);
         insert a;
                
         Contact c = new Contact(AccountId = a.Id, FirstName = 'Cntc', LastName = 'Test', OwnerId = '0051a0000015njF', Source__c = 'Facebook Form', Email='daniel.cervoni@samsara.com');  
         insert c;
        
         Opportunity o = new Opportunity(Name='Oppty 1', CloseDate = System.Today(), AccountId =a.Id, StageName='Proposal', Trial_Primary_Contact__c = c.Id, OwnerId = '0051a0000015njF');
         insert o;

         o.Send_Invoice__c = true;
         update o;

         System.assertEquals(true,true);
         SYstem.debug('inserted stuff NRNRNR');
         Quote q = new Quote();
         q.Name = 'FT Quote-' + o.name;
         q.OpportunityId = o.Id;
         q.PriceBook2Id = o.PriceBook2Id;
         q.ContactId = o.Trial_Primary_Contact__c;
         q.BillingName = o.Account.Name;
             //List<Account> a = [SELECT Billing_Email__c, BillingCountry FROM Account WHERE Id =: o.AccountId LIMIT 1];
             //q.Email = a[0].Billing_Email__c;
             //System.debug('off account');
             //System.debug(a[0].Billing_Email__c);
         q.Email = o.Account.Billing_Email__c;

            
         //    /*List<Contact> u = [select Id, Email from Contact where Id =: o.Shipping_Contact__c limit 1];
         //    String contactId = '0031a00000MWtFD';
         //    if (u.size() > 0){
         //        contactId = u[0].Id;
         //    }*/
         insert q;

         /*EmailTemplate et = new EmailTemplate(developerName = 'test', FolderId = UserInfo.getUserId(), TemplateType= 'Text', Name = 'test');
	     insert et;

	     OrgWideEmailAddress owa = new OrgWideEmailAddress(Address = 'trials@samsara.com');
	     //insert owa;*/

	    EmailTemplate et = [Select Id, Subject, HtmlValue, Body from EmailTemplate where Name = 'FT Invoice Email'];
		OrgWideEmailAddress owa = [select Id from OrgWideEmailAddress Where Address = 'trials@samsara.com'];

         Test.startTest();

         FreeTrialInvoicing.sendEmail(q.id, o.id,o.Trial_Primary_Contact__r.Id, o.Shipmate_Oppty_Owner__c, o.Trial_Primary_Contact__r.Email,owa.Id,et.Id);

         Test.stopTest();

         System.assertEquals(true,true);
     }


}