/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 10-02-2024
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public with sharing class OpportunityCreateNewVFP {
    public ApexPages.StandardSetController setController;
    public User currentUser{get; set;}
    public Boolean validation=false;
	public String displayErrorMessage='Please go to Account and click Create Opportunity button.';
        
    public OpportunityCreateNewVFP(ApexPages.StandardSetController setController) {
        this.setController = setController;
        this.currentUser = [SELECT  Id, 
                                    Name, 
                                    Email, 
                                    Profile.Name, 
                                    UserRole.Name 
                            FROM User 
                            WHERE Id = :userinfo.getUserId() 
                            LIMIT 1];
     }    
    public PageReference validateOpportunity() {
        //String displayErrorMessage='Please go to Account and click Create Opportunity button.';
        PageReference nextPage;
        //Boolean validation=false;
        List<string> AllAEs = (System.Label.All_AE_Roles.split(';'));
        for(string anyAE : AllAEs){
            if(this.currentUser.userrole.Name.contains(anyAE)){
               validation=true;
                Break;
            }
        }
        if(validation){
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.FATAL,displayErrorMessage));
            //nextPage = new PageReference();
            //nextPage.setRedirect(false);
        }
        else{
            nextPage = new PageReference('/lightning/o/Opportunity/new?count=2&nooverride=1&useRecordTypeCheck=1&navigationLocation=LIST_VIEW');
            nextPage.setRedirect(true);            
        }
        
        return nextPage;        
    }    
}