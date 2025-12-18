/*
 * Controller for ADR_Transfer_Options VF Page
 * June 22nd, 2022 Siddharth Kumar Mishra (GTMS-6307) - passes selected option and contact refernce to ADRTransferController
*/
public class ADRTransferOptionsController
{
    private ApexPages.StandardController stdContactController;
    public Contact currentContact{get; set;}
    public String stringOpp{get; set;}
    public string selectedValue{get; set;}
       
    
    //Constructor
    public ADRTransferOptionsController(ApexPages.StandardController sc)
    {
        // get the controller and associate it to the current contact
        this.stdContactController = sc;
        this.currentContact = (Contact) sc.getRecord();
        
    }
    
    public PageReference submit()
    {
         PageReference pageRef = new PageReference('/apex/ADR_Transfer');
         pageRef.setRedirect(true);
         pageRef.getParameters().put('selectedValue',selectedValue);
         pageRef.getParameters().put('currentContactID',currentContact.Id);
         return pageRef;
    }
    
    // if user clicks cancel
    public PageReference backToContact() {
        return new PageReference('/'+currentContact.id);
    }
    
}