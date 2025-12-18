/*
 *  This class tests 1 trigger:
 *  - CampaignOppUpdateFinal
 *  @author: Will GInsberg
 */

@isTest
private class CampaiagnOppUpdateFinaltest {
    @testSetup
    private static void avalaraSetup() {
        
    }
    
    static testMethod void CampaignOppUpdate() {
        //insert new AVA_SFCORE__AvaTaxSettings__c(Name='AvaTax', AVA_SFCORE__Enable_AvaTax_Tax_Calculation__c = FALSE);
        
        // --------------- create and insert accounts --------------- //
        Account a = new Account (Name = 'Slater Co', Organization_Size__c = '5000+', BillingCountry = 'United States', BillingState = 'California', Industry = 'Other');
        insert a;

        // --------------- create and insert accounts --------------- //

        // --------------- create and insert contacts --------------- //
        Contact cntc = new Contact(AccountId = a.Id, FirstName = 'John', LastName = 'Florence', email = 'john@slater.com', Source__c = 'Other');            
        insert cntc;                
        Contact cntc3 = new Contact(AccountId = a.Id, FirstName = 'Bob', LastName = 'Jones', email = 'bob@jones.com', Source__c = 'MVF ');            
        insert cntc3;
        // --------------- create and insert contacts --------------- //

        // --------------- create and insert users --------------- //

        User u = new User(
             LastName = 'last',
             FirstName = 'BILLY',
             Email = 'puser000@amamaaama.com',
             Username = 'puser000@amaaamama.com' + System.currentTimeMillis(),
             CompanyName = 'TEST',
             Title = 'title',
             Alias = 'alias',
             CommunityNickName='awesdfdsfawef',
             TimeZoneSidKey = 'America/Los_Angeles',
             EmailEncodingKey = 'UTF-8',
             LanguageLocaleKey = 'en_US',
             LocaleSidKey = 'en_US',
             ProfileId = '00e1a000000UoNa',
             EmployeeNumber = 'abcdefg'
        );
        insert u;
                
        // --------------- create and insert contacts --------------- //

        
        // --------------- create and insert campaigns --------------- //
        Campaign cmp1 = new Campaign(Name = 'List1');
        insert cmp1;
        
        Campaign cmp2 = new Campaign(Name = 'List2', ParentId = cmp1.Id);
        insert cmp2;
        
        Campaign cmp3 = new Campaign(Name = 'List3', ParentId = cmp2.Id);
        insert cmp3;

        Campaign cmp4 = new Campaign(Name = 'List11');
        insert cmp4;
        
        // Get the ID of cmp1 so that we can pass in as the Parent of cmp2
        Campaign cmp22 = new Campaign(Name = 'List22', ParentId = cmp4.Id);
        insert cmp22;
        
        // Get the ID of cmp2 so we can pass in as the parent of cmp3
        Campaign cmp33 = new Campaign(Name = 'List33', ParentId = cmp22.Id);
        insert cmp33;

        // --------------- create and insert campaigns --------------- //
        Opportunity O5 = new Opportunity(Name = 'Oppor5', AccountId = a.Id, StageName = 'Qualified', Amount = 10000, CloseDate = System.today()+90, Type='Revenue Opportunity');
        insert O5;
        
        // --------------- create and insert campaign members --------------- /
        Campaignmember C4 = new Campaignmember(ContactId = cntc3.Id, CampaignId = cmp1.Id, Status = 'Sent', Campaign_Interaction_Date__c = System.today() -10, ADR_Role_Copy__c = 'ADR - Team2 - Inbound',  ADR_Transfer_By__c = u.Id);
        insert C4;

        C4.status='Responded';
        update C4;
        // --------------- create and insert  campaign members --------------- //

        String status = [Select Status from CampaignMember where ID = :C4.Id][0].Status;
        System.assertEquals(status, 'Responded');
        String adrRoleCopy = [Select ADR_Role_Copy__c from CampaignMember where ID = :C4.Id][0].ADR_Role_Copy__c;
        System.assertEquals(adrRoleCopy, 'ADR - Team2 - Inbound');

    }
}