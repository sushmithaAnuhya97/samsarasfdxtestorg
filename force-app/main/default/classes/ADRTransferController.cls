/*
* Decides the new account owner and transfers the account to them, schedules a new demo and creates an "ADR Transfer Log" record
* June 22nd, 2022 Siddharth Kumar Mishra (GTMS-6307) setRoundRobinUser (Differentiating logic for (fleet and Fleet and sites) and Sites only)
* Aug 31, 2022 Rodrigo Carpio (GTMS-8515) modified getEnterpriseUser
* 
*/
public class ADRTransferController {
    
    private ApexPages.StandardController stdContactController;
    public User currentUser{get; set;}
    public List<AccountTeamMember> accountTeamMembers{get; set;}
    public Contact currentContact{get; set;}
    public Contact enterpriseOwner{get; set;}
    public Contact auxContact{get; set;}
    public String stringOpp{get; set;}
    public Id transferOwner{get; set;}
    public String transferOwnerName{get; set;}
    public Id AEDemoTransferTo{get; set;}
    public ADR_Transfer_Log__c transferLog{get; set;}
    public List <ADR_Transfer_Log__c> existingTransfers{get; set;}
    public Campaign ADR_campaign;
    public User u;
    public EMEA_Countries__c emeaCountries;
    private List<Opportunity> opps;
    public Map<String, List<String>> accountTeamMap = new Map<String, List<String>>();
    public Boolean runflow = false;
    public Boolean enterprise = false;
    public final List<String> enterpriseExceptions = new List<String>{'TBH', 'Pool', 'SLED'};
    public Boolean enterpriseBucket = false;
    public Boolean roundRobin = false;
    public Boolean indRegionAssignment = false;
    public Boolean sitesEnabled = false;
    public Boolean teamEnabled = false;
    public String selectedValue{get; set;}
    public String currentContactID{get; set;}
    public Id ConnectedWorkerPoolUserId{get; set;}
    public String insideSalesAssignment{get; set;}
    public String enterpriseAssignment{get; set;} 
    public Boolean sitesSpecialist = false;
    public Boolean transferError = false;
    public Boolean useCustomRouting = false;
    list<RR_Assignment_Rule__c> sitesRoundRobin = new list<RR_Assignment_Rule__c>();
    List<String> sitesOnlyRoundRobinNames = new List<String>();
    List<RR_Assignment_Mapping__c> roundRobinAssignment = new List<RR_Assignment_Mapping__c>();
    //LFBN__Round_Robin_Credit__c roundRobinCredit;
    
    public ADRTransferController(ApexPages.StandardController sc){
        //GTMS 63076307
        this.sitesOnlyRoundRobinNames = System.Label.Sites_Only_Round_Robin.split(',');
        this.sitesRoundRobin = [SELECT Id,Name FROM RR_Assignment_Rule__c WHERE Rule_Description__c IN :this.sitesOnlyRoundRobinNames];
        this.roundRobinAssignment = [SELECT Id,User__c,Assignment_Rule__r.Name, User__r.Name FROM RR_Assignment_Mapping__c
                                     WHERE Assignment_Rule__c = : this.sitesRoundRobin[0].Id AND Active__c=true ORDER BY Order__c limit 1];
        // get the controller and associate it to the current contact
        //this.stdContactController = sc;
        //this.currentContact = (Contact) sc.getRecord();
        this.currentContactID = System.currentPagereference().getParameters().get('currentContactID');
        this.selectedValue = System.currentPagereference().getParameters().get('selectedValue');
        this.currentContact = [Select ID,Name From Contact Where Id= :this.currentContactID];
        this.transferLog = new ADR_Transfer_Log__c();
        //current User
        this.currentUser = [SELECT  Id, 
                            Name, 
                            Email, 
                            Profile.Name, 
                            UserRole.Name 
                            FROM User 
                            WHERE Id = :userinfo.getUserId() 
                            LIMIT 1];
        // current contact needs access to more information, query it using the same
        this.auxContact = [ SELECT  Id,
                           AccountId,
                           Source__c, 
                           Status__c, 
                           Description, 
                           Inbound_Form_Message__c,
                           OwnerId,
                           Owner.Name,
                           Owner.UserRole.Name,
                           Account.Name,
                           Account.Global_Geography__c,
                           Account.Territory__c,
                           Account.Enterprise_Assignment__c,
                           Account.Enterprise_Experiments__c,
                           Account.Original_Owner_for_Recycling_Campaign__c,
                           Account.Original_Owner_for_Recycling_Campaign__r.Name,
                           Account.Original_Owner_for_Recycling_Campaign__r.IsActive,
                           Account.Original_Owner_for_Recycling_Campaign__r.Role_Start_Date__c, 
                           Account.OwnerId, 
                           Account.Owner.Name, 
                           Account.Owner.UserRole.Name, 
                           Account.Account_Assignment_Date__c, 
                           Account.RecordType.Name,
                           Account.Sites_Specialist__c,
                           Account.Sites_Specialist__r.UserRole.Name,
                           Account.Sites_Specialist__r.Name,
                           Account.Inside_Sales_Assignment__c,
                           Account.Books_Of_Business__c, 
                           Account.Account_Book_Owner__c,
                           Account.Books_Of_Business__r.AE__c,
                           Account.Books_Of_Business__r.Account_Book_Status__c,
                           Account.Books_Of_Business__r.AE__r.Name
                           FROM Contact 
                           WHERE Id = :this.currentContact.Id
                           LIMIT 1];
        this.accountTeamMembers = [ SELECT  Id,
                                   UserId,
                                   User.Name, 
                                   TeamMemberRole
                                   FROM AccountTeamMember 
                                   WHERE AccountId = : this.auxContact.AccountId];
         if(this.accountTeamMembers.size() > 0){
            teamEnabled = true;
            for(AccountTeamMember atm: this.accountTeamMembers){
                // UserId THEN User Name
                List<String> listUserValues = new List<String>{atm.UserId, atm.User.Name};
                    accountTeamMap.put(atm.TeamMemberRole, listUserValues);
            }
        }
        
        this.existingTransfers = [  SELECT  Id, 
                                  ADR_Transfer__c, 
                                  ADR_Transfer_By__c, 
                                  ADR_Transfer_Status__c 
                                  FROM ADR_Transfer_Log__c 
                                  WHERE Contact__c = :this.auxContact.Id 
                                  AND ADR_Transfer_Date__c = LAST_N_DAYS:30 
                                  AND ADR_Transfer__C = false 
                                  AND ADR_Transfer_Status__c != 'Rejected'
                                  ORDER BY CreatedDate DESC 
                                  LIMIT 1];
        
        this.emeaCountries = [  SELECT Named_List_Geo__c 
                              FROM EMEA_Countries__c 
                              WHERE Name = : 'Names' LIMIT 1];
        
        if(this.auxContact.Account.Enterprise_Assignment__c <> null){
            enterprise = true;
            
            for(String s: enterpriseExceptions){
                if(this.auxContact.Account.Enterprise_Assignment__c.contains(s)){
                    enterpriseBucket = true;
                }
            }
            
            if(enterpriseExceptions.contains(this.auxContact.Account.Enterprise_Assignment__c)){
                enterpriseBucket = true;
            }
        }
        
        // check if there are existing opportunities
        if(this.existingTransfers.size() > 0){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO,  'There has already been a transfer initiated in the last 30 days. Contact Sales Operations.',''));
        } else{
            this.ADR_campaign = [SELECT Id, 
                                 Name 
                                 FROM Campaign 
                                 WHERE Name Like '%(Child) ADR%' 
                                 LIMIT 1];
        }
        this.ConnectedWorkerPoolUserId = [Select Id from User Where name='Connected Worker Pool'].Id;
    }
    
    // this method get's called once the page loads, can't do it in the constructor
    // which then will be used to assign the account
    public void setRoundRobinUser(){
        if(this.selectedValue == 'Fleet' || this.selectedValue == 'FleetAndSites')//GTMS -6307 Differentiating logic for (fleet and Fleet and sites) and Sites only - Siddharth Kumar Mishra
        {
            
            //Skip routing of Connected Sites routed leads to Fleet AEs
            //GTMS-4546 : Updated role from CNWKR to Sites
            // Added Books_Of_Business__r.AE__c as part of GTMS-22271
            // Added Account_Book_Status__c as part of  GTMS-24801
            // Added MX as userRole and Samsara Inbound ADRs Profile as a part of GTMS-23319
            Set<String> validAEStatuses = new Set<String>{null,'Primary: In seat'};
                Set<String> validAccountOwnerStatuses = new Set<String>{'Admin hold', 'Secondary: LOA', 'Secondary: Churn', 'Secondary: Overcarve', 'Secondary: AOP Hires','Secondary: Hire Ahead'};
                    
                    if (this.auxContact.Account.Books_Of_Business__c != null && validAEStatuses.contains(this.auxContact.Account.Books_Of_Business__r.Account_Book_Status__c)) {
                        
                        if((this.currentUser.Profile.Name == 'Samsara Account Book ADRs' || this.currentUser.Profile.Name == 'Samsara Sales Management - New System') ||
                           ((this.currentUser.Profile.Name == 'Samsara Sales Management - New System' || this.currentUser.Profile.Name =='Samsara ADRs' || this.currentUser.Profile.Name =='Samsara Inbound ADRs') && (this.currentUser.userrole.Name.contains('EMEA') || this.currentUser.userrole.Name.contains('MX')))){ // && this.auxContact.Account.Account_Book_Owner__c!=null added for GTMS-11453 //updated for GTMS-18694//GTMS-19694
                               this.transferOwner= this.auxContact.Account.Books_Of_Business__r.AE__c;
                               this.transferOwnerName =this.auxContact.Account.Books_Of_Business__r.AE__r.name;
                               // && this.auxContact.Account.Account_Book_Owner__c!=null added for GTMS-11453 //updated for GTMS-18694//GTMS-19694
                               //this.transferOwnerName = this.auxContact.Account.Owner.Name;  
                               /*if (this.auxContact.Account.OwnerId != this.auxContact.Account.Books_Of_Business__r.AE__c) {
                               Account objAccnt = new Account();
                               objAccnt.Id = this.auxContact.AccountId;
                               objAccnt.OwnerId = this.auxContact.Account.Books_Of_Business__r.AE__c;
                               TriggerHandler.bypass('GS_AccountTriggerHandler');
                               database.update(objAccnt);
                               }*/
                           }
                    }
            //Added as part of GTMS-24801
            else if (this.auxContact.Account.Books_Of_Business__c != null && validAccountOwnerStatuses.contains(this.auxContact.Account.Books_Of_Business__r.Account_Book_Status__c)) {
                
                if(((this.currentUser.Profile.Name == 'Samsara Account Book ADRs' ||this.currentUser.Profile.Name == 'Samsara Sales Management - New System') && !this.currentUser.userrole.Name.contains('EMEA'))  ||
                   ((this.currentUser.Profile.Name == 'Samsara Sales Management - New System' || this.currentUser.Profile.Name =='Samsara ADRs' || this.currentUser.Profile.Name =='Samsara Inbound ADRs') && (this.currentUser.userrole.Name.contains('EMEA') || this.currentUser.userrole.Name.contains('MX')))){ // && this.auxContact.Account.Account_Book_Owner__c!=null added for GTMS-11453 //updated for GTMS-18694//GTMS-19694
                       this.transferOwner = this.auxContact.Account.OwnerId;
                       this.transferOwnerName = this.auxContact.Account.Owner.Name;
                       
                   }
            }
            else if(this.currentUser.UserRole.Name.contains('Sites') && this.currentUser.UserRole.Name.contains('ADR') && this.auxContact.Account.Owner.UserRole.Name.contains('Fleet') && this.auxContact.Account.Books_Of_Business__c!=null){
                sitesEnabled = true;
                if(teamEnabled){
                    List<String> sitesDetails = new List<String>();
                    sitesDetails = accountTeamMap.get('Sites Account Executive');
                    if(sitesDetails != null){
                        //GTMS -3183 Update Routing Logic for Sites ADR Transfers - Anil Bogadi
                        //this.transferOwner = sitesDetails[0];
                        //this.transferOwnerName = sitesDetails[1];
                        //this.transferOwner = this.auxContact.Account.OwnerId;
                       // this.transferOwnerName = this.auxContact.Account.Owner.Name;
                         this.transferOwner= this.auxContact.Account.Books_Of_Business__r.AE__c;
                         this.transferOwnerName =this.auxContact.Account.Books_Of_Business__r.AE__r.name;
                    } else{
                        ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO,  'A Sites Account Executive is not associated with this Account. Please Contact Sales Operations.',''));
                    }
                }
            } else{
                // Added new logic for GTMS-28248 by Naved Khan
                // New logic: Check if current contact Owner.UserRole contains 'ADR IB' AND 'US' or 'CA'
                // AND Contact.Account.Owner.UserRole contains 'CML' AND 'US' or 'CA'
                // Then skip Round Robin and keep the same CML AE user
                if(this.auxContact.Owner.UserRole.Name.contains('ADR IB') && (this.auxContact.Owner.UserRole.Name.contains('US') || this.auxContact.Owner.UserRole.Name.contains('CA')) &&
                   this.auxContact.Account.Owner.UserRole.Name.contains('CML') && (this.auxContact.Account.Owner.UserRole.Name.contains('US') || this.auxContact.Account.Owner.UserRole.Name.contains('CA')))
                {
                    // Skip Round Robin and keep the same CML AE user
                    this.transferOwner = this.auxContact.Account.OwnerId;
                    this.transferOwnerName = this.auxContact.Account.Owner.Name;
                }
                //check if the original owner for a recycling campaign is populated 
                else if(this.auxContact.Account.Original_Owner_for_Recycling_Campaign__c != null 
                   && (this.auxContact.Account.Original_Owner_for_Recycling_Campaign__r.IsActive 
                       || this.auxContact.Account.Account_Assignment_Date__c < this.auxContact.Account.Original_Owner_for_Recycling_Campaign__r.Role_Start_Date__c))
                {
                    this.transferOwner = this.auxContact.Account.Original_Owner_for_Recycling_Campaign__c;
                    this.transferOwnerName = this.auxContact.Account.Original_Owner_for_Recycling_Campaign__r.Name;
                } else if(enterprise){
                    //String enterpriseName = getEnterpriseUser(this.auxContact.Account, enterpriseBucket, emeaCountries.Named_List_Geo__c);
                    u = getEnterpriseUser(this.auxContact, enterpriseBucket, emeaCountries.Named_List_Geo__c);
                } else if(this.auxContact.Account.RecordType.Name == 'Industrial' && !enterprise){
                    // call Lane Four to get the next person to be assigned in the Region Assignment
                    if(this.auxContact.Account.Territory__c <> null){
                        Id assignedRegionRep = getRegionAssignment(this.auxContact.Account.Territory__c);
                        u = [SELECT Id, Name FROM User WHERE Id = : assignedRegionRep];
                        indRegionAssignment = true;
                    }
                } else {
                    // call Lane Four to get the next person to be assigned in the RR
                    //if (system.label.LANEFOUR_ROUND_ROBIN_FLAG == '1')
                    //if(!Test.isRunningTest())
                    //    u = LFBN.LaneFourService.getNextAssignment(this.auxContact.AccountId).selectedUser;
                    //else {
                    RoundRobinHandler rr = new RoundRobinHandler('Lane Four','Account');
                    u = rr.getAssignedUser(this.auxContact.AccountId);
                    //rr.updateRuleDetail();
                    //}
                    roundRobin = true;
                } 
                
                if(u <> null){
                    this.transferOwner = u.Id;
                    this.transferOwnerName = u.Name;
                    
                } 
            }
            
        }
        else if(this.selectedValue == 'SitesOnly')//GTMS 6307 - Updated logic for sites only( else if section )  - Siddharth Kumar Mishra
        {
            if(((this.currentUser.Profile.Name == 'Samsara Account Book ADRs' ||this.currentUser.Profile.Name == 'Samsara Sales Management - New System') && !this.currentUser.userrole.Name.contains('EMEA'))  ||
               ((this.currentUser.Profile.Name == 'Samsara Sales Management - New System' || this.currentUser.Profile.Name == 'Samsara ADRs') && this.auxContact.Account.Books_Of_Business__c!=null && this.currentUser.userrole.Name.contains('EMEA'))){ // added for GTMS-11453 //updated for GTMS-18694//GTMS-19694
                   this.transferOwner = this.auxContact.Account.OwnerId;
                   this.transferOwnerName = this.auxContact.Account.Owner.Name; 
                   
               }
            else if(this.auxContact.Account.Inside_Sales_Assignment__c!=null)
            {
                this.insideSalesAssignment = this.auxContact.Account.Inside_Sales_Assignment__c;
                if(this.insideSalesAssignment.contains('IS Pool'))
                {
                    this.transferError = true;
                    this.AEDemoTransferTo = getUser(this.insideSalesAssignment).Id;
                    this.transferOwnerName = this.insideSalesAssignment;
                }
                else 
                {
                    this.transferOwner = getUser(this.insideSalesAssignment).Id;
                    this.transferOwnerName = this.insideSalesAssignment;
                    
                }            
                
            }
            else if(this.auxContact.Account.Enterprise_Assignment__c!=null)
            {
                this.enterpriseAssignment = this.auxContact.Account.Enterprise_Assignment__c;
                if( this.enterpriseAssignment.contains('ENT Pool') )
                {
                    this.transferError = true;
                    this.AEDemoTransferTo = getUser(this.enterpriseAssignment).Id;
                    this.transferOwnerName = this.enterpriseAssignment;
                }
                else 
                {
                    this.transferOwner = getUser(this.enterpriseAssignment).Id;
                    this.transferOwnerName = this.enterpriseAssignment;
                }
            }
            else if(this.auxContact.Account.Sites_Specialist__c!=null)
            {
                if(this.auxContact.Account.Sites_Specialist__r.UserRole.Name.contains('Sites IS AE2'))
                {//contains 'Sites IS AE2'
                    this.AEDemoTransferTo = this.auxContact.Account.Sites_Specialist__c;
                    this.transferOwnerName = this.auxContact.Account.Sites_Specialist__r.Name;
                    if(this.auxContact.Account.Owner.UserRole.Name.contains('ADR'))
                    {
                        this.transferOwner = this.auxContact.Account.Sites_Specialist__c;
                    }
                }
                else //doesn't contain 'Sites IS AE2'
                {
                    //this.roundRobinCredit = [SELECT Id,LFBN__Last_Assigned_Time__c FROM LFBN__Round_Robin_Credit__c WHERE LFBN__Round_Robin_Assignment__c = :this.roundRobinAssignment[0].Id and LFBN__Active__c = true];
                    this.AEDemoTransferTo = this.roundRobinAssignment[0].User__c;
                    this.sitesSpecialist = true;
                    this.transferOwnerName = this.roundRobinAssignment[0].User__r.Name;
                    if(this.auxContact.Account.Owner.UserRole.Name.contains('ADR'))
                    {                   
                        this.transferOwner = this.roundRobinAssignment[0].User__c;
                        //this.roundRobinCredit.LFBN__Last_Assigned_Time__c = System.now();
                    }
                    
                }
            }
            else
            {
                //this.roundRobinCredit = [SELECT Id,LFBN__Last_Assigned_Time__c FROM LFBN__Round_Robin_Credit__c WHERE LFBN__Round_Robin_Assignment__c = :this.roundRobinAssignment[0].Id and LFBN__Active__c = true];
                this.AEDemoTransferTo = this.roundRobinAssignment[0].User__c;
                this.transferOwnerName = this.roundRobinAssignment[0].User__r.Name;
                this.sitesSpecialist = true;
                if(this.auxContact.Account.Owner.UserRole.Name.contains('ADR'))
                {
                    this.transferOwner = this.roundRobinAssignment[0].User__c;
                    //this.roundRobinCredit.LFBN__Last_Assigned_Time__c = System.now();
                }
            }
        }
        
        
    }
    
    public PageReference submit(){
        
        try {
        
        Account currentAccount = new Account(Id=this.auxContact.AccountId);
        String url = '/'+currentContact.id;
        if(this.existingTransfers.size() > 0){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO,  'There has already been a transfer initiated in the last 30 days. Contact Sales Operations.',''));
            return null;
        }
        if(this.transferError == true)
        {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO,  'Cannot transfer Account. Please contact Admin',''));
            return null;
        }
        this.transferLog.ADR_Transfer_Date__c = System.now();
        this.transferLog.ADR_Transfer_By__c = UserInfo.getUserId();
        this.transferLog.Account__c = this.auxContact.AccountId;
        this.transferLog.Contact__c = this.currentContact.Id;
        this.transferLog.ADR_Transfer_Status__c = 'Demo Scheduled';
        this.transferLog.ADR_Notes__c=this.transferLog.ADR_Notes__c;
        if(this.selectedValue == 'Fleet')
        {
            this.transferLog.Samsara_Product_Interest__c = 'Fleet';
        }
        else if(this.selectedValue == 'FleetAndSites')
        {
            this.transferLog.Samsara_Product_Interest__c = 'Fleet and Sites';
        }
        else if(this.selectedValue == 'SitesOnly')
        {
            this.transferLog.Samsara_Product_Interest__c = 'Sites Only';
        }
        if(this.transferOwner!=null)
        {
            this.transferLog.AE_Demo_Transfer_To__c = this.transferOwner;
        }
        else if(this.AEDemoTransferTo!=null)
        {
            this.transferLog.AE_Demo_Transfer_To__c = this.AEDemoTransferTo;
        }     
        String transferCopy = this.auxContact.Account.Enterprise_Experiments__c == null ? 'Standard' : this.auxContact.Account.Enterprise_Experiments__c;
        this.transferLog.Transfer_Type_At_Transfer_Copy__c = transferCopy;
        //this.transferLog.OwnerId = this.transferOwner;
        insert this.transferLog;
        
        /*NOTE: These fields have been reactivated as of June 4th, 2018. Had been inactive for some time before.
They are used for automating demo reminders. They should not be used to report on*/
        currentContact.ADR_Transfer__c = true;
        currentContact.Scheduled_Demo_Date__c = this.transferLog.ADR_Demo_Date__c;
        currentContact.ADR_Transfer_By__c = UserInfo.getUserId();
        update currentContact;
        
        // assign account via recycling campaign if field is populated otherwise Round Robin out via Lane Four
        if(roundRobin){
            //if (useCustomRouting==false)
            //  currentAccount.LFBN__Assign_Account__c = true;
            //else
            currentAccount.Initiate_Round_Robin__c = true;
        }
        else if(indRegionAssignment){
            //if (useCustomRouting==false)
            //  currentAccount.LFBN__Assign_Region_Owner__c = true;
            //else
            currentAccount.Initiate_Round_Robin__c = true;
        }
        else if(!sitesEnabled){
            if(this.transferOwner!=null)
            {
                currentAccount.OwnerId = this.transferOwner;
            }
        }
        
        if(currentAccount.Original_Owner_for_Recycling_Campaign__c != null){
            currentAccount.Original_Owner_for_Recycling_Campaign__c=null;
        }
        if(this.sitesSpecialist==true)//GTMS 6307 -   - Siddharth Kumar Mishra
        {
            currentAccount.Sites_Specialist__c = this.AEDemoTransferTo;
        }
        
        update currentAccount;
        /*if(this.roundRobinCredit!=null)
{
update this.roundRobinCredit;
}*/
        
        
        //Check for Demo Enabled Role names and run the ADR_Transfer flow  through Page Reference URL
        //Updates more than likely needed to ensure that URL hack isn't being used - RSAAVEDRA
        UserRole uRoleName = [SELECT Name FROM UserRole WHERE Id =: UserInfo.getUserRoleId()];
        String userRoleName = uRoleName.Name;
        List<Demo_Enabled__c> DemoEnabled = [   SELECT Name 
                                             FROM Demo_Enabled__c];
        
        if(DemoEnabled.size() > 0){
            for(Demo_Enabled__c dm: DemoEnabled){
                if(userRoleName.contains(dm.Name)){ 
                    runflow = true;
                }
            }
            if(runflow == true){
                url = '/flow/ADR_Transfer?recordId='+currentContact.Id+'&retURL='+currentContact.Id;
            }
        }
        
        return new PageReference(url);

        } catch(Exception ex) {
            String errorMsg = ex.getMessage().contains('FIELD_CUSTOM_VALIDATION_EXCEPTION') ? ex.getMessage().split('FIELD_CUSTOM_VALIDATION_EXCEPTION,')[1].replace(': []','').trim() : ex.getMessage();
            ApexPages.addmessage(new ApexPages.message( ApexPages.severity.Error, errorMsg));
            return null;
        }
    }
    // if user clicks cancel
    public PageReference backToContact() 
    {
        return new PageReference('/'+currentContact.id);
    }
    
    public static User getUser(String username)
    {
        User u = [Select Id,name from User where Name = :username Limit 1];
        return u;
    }
    
    public static User getEnterpriseUser(Contact contact, Boolean enterpriseBucket, String emeaCountries){
        Enterprise_Routing_Default__c enterpriseDefault;
        String enterpriseName;
        User enterpriseUser;
        
        if (!enterpriseBucket){
            enterpriseName = contact.Account.Enterprise_Assignment__c;
        }
        else{
            if(contact.Account.RecordType.Name == 'Industrial'){
                enterpriseDefault = [  SELECT   Id__c, 
                                     Name
                                     FROM Enterprise_Routing_Default__c 
                                     WHERE Region__c = :'Industrial'
                                     LIMIT 1];
            }
            else if(emeaCountries.contains(contact.Account.Global_Geography__c)){
                enterpriseDefault = [  SELECT  Id__c, 
                                     Name
                                     FROM Enterprise_Routing_Default__c 
                                     WHERE Region__c = :'EMEA'
                                     LIMIT 1];
            }
            else{
                enterpriseDefault = [  SELECT  Id__c, 
                                     Name
                                     FROM Enterprise_Routing_Default__c 
                                     WHERE Region__c = :'North America'
                                     LIMIT 1];
            }
            enterpriseName = enterpriseDefault.Name;
        }
        
        if(enterpriseName <> null){
            List<User> localUser = new List<User>(); // added for GTMS-8515
            localUser = [SELECT Id, Name FROM User WHERE Name = : enterpriseName LIMIT 1];
            if(localUser!=null && localUser.size()>0) // added for GTMS-8515
                enterpriseUser = localUser[0];
        }
        return enterpriseUser;
    }
    
    public static Id getRegionAssignment(String territory){
        /*LFBN__Region_Automation_Field_Value__c regionValue = [  SELECT  Id, 
LFBN__Field_Value__c 
FROM  LFBN__Region_Automation_Field_Value__c
WHERE LFBN__Field_API_Name__c = 'ownerid'
AND LFBN__Region_Automation__r.Name = : territory
LIMIT 1][0];
return regionValue.LFBN__Field_Value__c;*/
        return null;
    }
    
}