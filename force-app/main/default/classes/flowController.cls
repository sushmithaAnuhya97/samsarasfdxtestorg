public with sharing class flowController 
{
    String unique_id = ApexPages.currentPage().getParameters().get('id');
    //public flowController(ApexPages.StandardController controller) 
    public flowController()
    { 
        system.debug('With constructor ID ='+ unique_id);
        //returnURL();
    }

   public object flowController1()
    {
        if(unique_id != '')
        {
            system.debug('Within Return URL Method ID ='+ unique_id);
            String oppId =null; 
            try
            {
                oppId = [SELECT Name,  
                         Unique_Flow_Identifier__c, 
                         Id  
                         FROM Opportunity  
                         WHERE Unique_Flow_Identifier__c = :unique_id 
                         ORDER BY CreatedDate DESC LIMIT 1].Id;
            }
            catch (Exception e) 
            {
                System.debug('The following exception has occurred:No oppid found ' + e.getMessage());
            }
            system.debug('oppId ='+ oppId);
            if (oppId == null) 
            {   
                 String url = '/' + unique_id.right(15);                 
                // Return Home if no ID 
                system.debug('OPPID is Null'+ url);
                return new PageReference(url); 
            }
            else
            {
                //Redirect to Opp 
                String url = '/' + oppId; 
                system.debug('OPPID is not Null' + url);
                return new PageReference(url);
            }
        }
        else
        {    
            String url = '/home/home.jsp'; 
            system.debug('UNIQUE ID is Null'+ url);
            return new PageReference(url); 
        }
    }
        
}