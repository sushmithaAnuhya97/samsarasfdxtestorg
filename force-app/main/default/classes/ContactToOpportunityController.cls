/*
* 06/19/19 - Updated logic for Outbound AE and ADR Campaigns- @author: Max
* 1/16/2020 - Optimize logic for efficiency + rework to
* 5/14/2020 - Populate shippping_contact__c with currentcontact.id - Tommy
* 8/20/2022- GTMS-5776  Added this Logic For handling 'UNABLE_TO_LOCK_ROW' issues. @chinmaya Dash
* 1/26/2023 - GTMS-11127 Added AE1 to the Opp creation restriction list
* May-31-2023 Siddharth (GTMS-12786): Prevent Contact Status field from being changed if it is in 'Inactive - No Longer There'
* 06/30/2025 - GTMS-28354 - Added this logic to check if there is an open Partner Registration for the account
*/
 
public with sharing class ContactToOpportunityController {
   
    private ApexPages.StandardController stdContactController; // controller of the page
    private Contact currentContact; // saves the current contact, WHERE button was clicked
    public List <CampaignMember> existingCampaignsforContact{get; set;}
    public Contact auxContact{get; set;}
    public List <ADR_Transfer_Log__c> auxADRTransfer{get; set;}
    private ID oppId;
    private Opportunity rev; // opportunity created from clicking the button
    public String oppsStage {get;set;} // user can define stage of the opp
    public Account currentAccount{get; set;} // current account associated with the contact
    public Opportunity oppty{get; set;}
    public String stringADR{get; set;} // adr string message that makes reps accept terms
    public Boolean adrTransferExists{get; set;} // boolean if ADR is accepted
    public Integer adrTransferSize{get; set;} // size of the ADR Transfer query
    public Boolean contractFlag{get; set;} // Number of Active Contracts on the Accounts
    public Id adrTransferId; // latest adr transfer id
    public Boolean noDemo{get; set;} // boolean if no demo required
    // Commented out per (JIRA NUMBER HERE) public String selectedStage{get; set;}
    public String clickLabel{get; set;} //dynamic label value based on the flow that should be executed
    //06/30/2025 Vijaychandra AMARANENI (GTMS-28354) - Added this boolean to check if open Partner Registration exists
    public Boolean openPartnerRegistrationExists{get; set;} // boolean to check if open Partner Registration exists
   
    List<Database.SaveResult> insertResults = new List<Database.SaveResult>();//GTMS - 5776
    List<Opportunity> OppList = new List<Opportunity>();//GTMS - 5776
   
    List<CampaignMember> campMem = new List<CampaignMember>();
    OpportunityContactRole newContactRoleList;
   
   
    public ContactToOpportunityController(ApexPages.StandardController sc){
       
        this.stdContactController = sc; // get page controller and initialize
        this.currentContact = (Contact) sc.getRecord(); // get contact from page
        // query the account and the contact with the fields to be used
        this.auxContact = [ SELECT  Id,
                           OwnerId,
                           Description,
                           Source__c,
                           ADR_Transfer__c,
                           ADR_Transfer_By__c,
                           ADR_Transfer_Status__c,
                           FirstName,
                           LastName,
                           AccountId,
                           Demo_Date__c
                           FROM Contact
                           WHERE Id = :this.currentContact.Id];
                           
        this.currentAccount = [ SELECT  Id,
                               Name,
                               RecordType.Name,
                               Lifetime_Purchases__c,
                               First_Revenue_Oppty_Creation_Date__c,
                               First_Purchase_Date__c,
                               BillingCity,
                               BillingCountry,
                               BillingPostalCode,
                               BillingState,
                               BillingStreet,
                               ADR_Transfer__c, Owner.UserRole.Name,
                               Number_of_Vehicles__c, Latest_Active_Contract__c
                               FROM Account
                               WHERE Id = :this.auxContact.AccountId];
       
        this.auxADRTransfer = [ SELECT  Id,
                               ADR_Transfer__c,
                               ADR_Transfer_By__c,
                               ADR_Transfer_By__r.FirstName,
                               ADR_Transfer_By__r.LastName,
                               ADR_Transfer_By__r.Email,
                               ADR_Transfer_Status__c,
                               ADR_Accepted_Date__c,
                               ADR_Role_Copy__c
                               FROM ADR_Transfer_Log__c
                               WHERE Contact__c = :this.currentContact.Id
                               AND ADR_Transfer_Date__c = LAST_N_DAYS:30
                               AND ADR_Transfer_Status__c IN ('Second Pass Complete', 'Demo Scheduled')
                               ORDER BY CreatedDate DESC
                               LIMIT 1];
       
        // 06/30/2025 Vijaychandra AMARANENI --START-- (GTMS-28354) : Check for open Partner Registration records with Status 'PAM Reviewed' and matching Account
        List<Partner_Registration__c> openPartnerRegistrations = [
            SELECT Id, Name, Account__c, Status__c
            FROM Partner_Registration__c
            WHERE Status__c = 'PAM Reviewed'
            AND Account__c = :this.auxContact.AccountId
            LIMIT 1
        ];
        this.openPartnerRegistrationExists = !openPartnerRegistrations.isEmpty();
        // 06/30/2025 Vijaychandra AMARANENI --END-- (GTMS-28354) : Check for open Partner Registration records with Status 'PAM Reviewed' and matching Account
       
                               this.existingCampaignsforContact = [SELECT  Id,CampaignId
                                            FROM CampaignMember
                                            WHERE ContactId =: this.currentContact.Id];
        // initialize the oppty but don't save it yet
        this.oppty = new Opportunity();
        this.oppty.Name = this.currentAccount.Name + ' -';
        this.oppty.Shipping_Address_Line_1__c = currentAccount.BillingStreet;
        this.oppty.Shipping_City__c = currentAccount.BillingCity;
        this.oppty.Shipping_State__c = currentAccount.BillingState;
        this.oppty.Shipping_Country__c = currentAccount.BillingCountry;
        this.oppty.Shipping_Zip_Code__c = currentAccount.BillingPostalCode;
        this.oppty.CloseDate = System.today();
        // Initialize Budget Confirmed and Need fields
        //this.oppty.Budget_Confirmed__c = 'No';
        //this.oppty.Need__c = '';
       
        String segment = this.currentAccount.Owner.UserRole.Name;     //GTMS-11127. Added AE1 below  removed  
        contractFlag = (!(UserInfo.getProfileId() == label.Profile_Sales_Ops_Profile ||
                          UserInfo.getProfileId() == label.Profile_System_Administrator || UserInfo.getProfileId() == label.Profile_Order_Operations_Admin
                          || UserInfo.getProfileId() == label.Profile_Samsara_Finance)   && this.currentAccount.Latest_Active_Contract__c != null  
                       );
       
        // Commented out per (INSERT JIRA HERE) this.selectedStage='Qualified';
        this.oppsStage = 'Qualified';
        this.adrTransferSize = 0;
        if (auxADRTransfer.size() > 0){
           
            this.adrTransferSize = auxADRTransfer.size();
           
            this.adrTransferId = auxADRTransfer[0].Id;
           
            this.adrTransferExists = true;
            this.clickLabel = 'Navigate to ADR Transfer';
           
            this.stringADR = '*There is an existing ADR transfer associated with this Contact that must be reviewed prior to continuing with Opportunity creation. Please click submit to follow the ADR Acceptance or Denial process.*';
        }
        else{
            this.clickLabel = 'Create Opportunity';
        }
       
        if (this.auxContact.Source__c == 'List Import (no prior engagement)'){
            this.auxContact.Source__c = 'Outbound call / email / linkedin';
        }
       
    }
   
    public PageReference submit(){
       
        // user clicks submit and wants to create an opportunity
        // start by creating the opty with the information from the page
       
        Savepoint sp = Database.setSavepoint(); // Added by Dhushyanth
        try { // Added by Dhushyanth
 
             if(this.adrTransferSize > 0){
            return new PageReference('/'+adrTransferId);
        }
        else{// set the qualified date and status of the contact
           
            // Validate required fields
            if(String.isBlank(this.oppty.Name)) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, 'Opportunity Name is required.'));
                return null;
            }
            
            if(this.oppty.CloseDate == null) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, 'Close Date is required.'));
                return null;
            }
           
            // check that demo is set
            if (this.currentContact.Demo_Date__c ==  null && this.noDemo == false){
                ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR,  'Please set the Demo Completed Date. If you did not complete any demo, please check the No Demo box. ',''));
                return null;
            }
            //GTMS-12786
            //if(this.currentContact.Status__c!='Inactive - No Longer There') Commented as part of GTMS-25351
            if(this.currentContact.Inbound_Reason_Faulty__c!='Inactive - No Longer There')
            {
                currentContact.Status__c = 'Qualified';
            }            
            currentContact.Qualified_Date__c = System.now();
            this.createOutboundAECampaign();
            update currentContact;
            
            // Determine stage based on Budget Confirmed and Need fields (For Revenue Opportunities ONLY)
            this.oppsStage = String.isBlank(oppty.Budget_Confirmed__c) || String.isBlank(oppty.Need__c) ? 'Incubate' : 'Qualified';
           
            this.rev = createOpp(currentAccount, auxContact, currentContact, oppty);
           
            //GTMS-5776 @chinmaya Dash Added this Logic For handling 'UNABLE_TO_LOCK_ROW' issues.
            List<Opportunity> newlistopp = new List<Opportunity>();
            newlistopp.add(this.rev);
            if(newlistopp.size()>0)
            {
                insertResults = Database.insert(newlistopp,false);
            }
            for(Integer i=0;i<insertResults.size();i++)
            {
                if(!insertResults[i].isSuccess())
                {
                    for(Database.Error err : insertResults[i].getErrors())
                    {
                        //System.DmlException: Insert failed. First exception on row 0; first error: UNABLE_TO_LOCK_ROW, unable to obtain exclusive access to this record or 1 records: 7014p000000JMo4AAG: []
                        if(err.getMessage().contains('UNABLE_TO_LOCK_ROW') )
                        {
                            OppList.add(newlistopp[i]);                            
                        }
                    }
                }
            }
            Database.insert(OppList,false);
            this.oppId = OppList.size() > 0 ? OppList[0].Id : rev.Id;
            //this.oppID = rev.ID;
            newContactRoleList = new OpportunityContactRole(ContactId=currentContact.Id,OpportunityId=rev.Id,Role='Business User',IsPrimary=true);
            try {
                insert newContactRoleList;
            } catch(Exception e) {
                System.debug('Error inserting OpportunityContactRole: ' + e.getMessage());
                ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.WARNING, 'Opportunity created successfully but there was an issue creating the contact role: ' + e.getMessage()));
            }
           
            return new PageReference('/'+oppID);
        }
    }

    catch(Exception e) {
        Database.rollback(sp);
        System.debug('Unexpected error occurred: ' + e.getMessage());
        System.debug('Stack trace: ' + e.getStackTraceString());
        String errorMessage = 'An unexpected error occurred: ' + e.getMessage();
        ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, errorMessage));
        return null;
    }
    }
   
    public void createOutboundAECampaign(){
        //Find all campaigns associated with the contact and assign the contact to Cold call campaign if either no campaigns in the past or no "responded campaigns.
        // for logic please refer to https://docs.google.com/document/d/14O1pP4ivj08Y9I2b94pSVT_nTKOQFBQCMXylcqNsf2w/edit
       
        // query all Campaign Members associated with the account that interacted within 90 days (attribution window defined by marketing team)
        List<CampaignMember> relatedCampaigns = [SELECT Id,
                                                 ContactId,
                                                 Status,
                                                 CampaignId
                                                 FROM CampaignMember
                                                 WHERE ContactId IN (SELECT Id
                                                                     FROM Contact
                                                                     WHERE AccountId =: currentAccount.Id)
                                                 AND FirstRespondedDate = LAST_N_DAYS:90
                                                 AND HasResponded = True];
       
        if (relatedCampaigns.size() == 0){
            List<CampaignMember> relatedCampaignsOutboundAE = [  SELECT Id, ContactId,Status, CampaignId
                                                               FROM CampaignMember
                                                               WHERE ContactId =: this.currentContact.Id
                                                               AND CreatedDate = LAST_N_DAYS:90
                                                               AND HasResponded = False
                                                               AND Campaign.Type = 'Sales - AE Outbound'
                                                               ORDER BY CreatedDate DESC
                                                               LIMIT 1];
           
            if (relatedCampaignsOutboundAE.size() > 0){
                relatedCampaignsOutboundAE[0].Status = 'Responded';
                update relatedCampaignsOutboundAE[0];
            } else{
                if (this.currentAccount.Lifetime_Purchases__c == 0 || Test.isRunningTest()){
                    List <Campaign> AEOutboundCampaign = [SELECT Id
                                                          FROM Campaign
                                                          WHERE Name Like '(Child) AE Outbound'
                                                          LIMIT 1];
                    if (AEOutboundCampaign.size() > 0){
                        currentContact.Campaign_to_Add__c = AEOutboundCampaign[0].Id;
                        currentContact.Campaign_Member_Status__c = 'Responded';
                    } else{
                        Campaign newAECampaign= new Campaign(Name='(Child) AE Outbound');
                        newAECampaign.Type = 'Sales - AE Outbound';
                        insert newAECampaign;
                        currentContact.Campaign_to_Add__c = newAECampaign.Id;
                        currentContact.Campaign_Member_Status__c = 'Responded';
                    }
                } else {
                    List <Campaign> upsellCampaign = [   SELECT Id
                                                      FROM Campaign
                                                      WHERE Name = '(Child) AE Upsell'
                                                      LIMIT 1];
                    if (upsellCampaign.size() > 0) {
                        currentContact.Campaign_to_Add__c = upsellCampaign[0].Id;
                        currentContact.Campaign_Member_Status__c = 'Responded';
                    } else {
                        Campaign newAECampaign= new Campaign(Name='(Child) AE Upsell');
                        newAECampaign.Type = 'Sales - AE Upsells';
                        insert newAECampaign;
                        currentContact.Campaign_to_Add__c = newAECampaign.Id;
                        currentContact.Campaign_Member_Status__c = 'Responded';
                    }
                }
            }
        }
    }
   
    public Opportunity createOpp(Account currentAccount, Contact auxContact, Contact currentContact, Opportunity oppty){
 
         Opportunity newOpp = new Opportunity(  AccountId = currentAccount.Id, LeadSource = auxContact.Source__c,
                                               Name =oppty.Name, CloseDate = oppty.CloseDate, StageName = oppsStage,
                                               Related_Contact__c = currentContact.Id, Shipping_Address_Line_1__c=oppty.Shipping_Address_Line_1__c,
                                               Shipping_City__c=oppty.Shipping_City__c, Shipping_Country__c=oppty.Shipping_Country__c,
                                               Shipping_Zip_Code__c=oppty.Shipping_Zip_Code__c, Notes__c = auxContact.Description,
                                               Can_Create__c=true, shipping_contact__c = currentContact.Id,
                                               Budget_Confirmed__c = oppty.Budget_Confirmed__c, Need__c = oppty.Need__c);
       
        return newOpp;
    }
   
    // if user clicks cancel, redirect him back to the contact page
    public PageReference backToContact(){
        return new PageReference('/'+currentContact.id);
    }   
}