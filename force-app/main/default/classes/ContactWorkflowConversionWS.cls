/*
* Title: ContactWorkflowConversionWS
* Description: Class to house all the converted Contact workflows
* Created: June 22, 2021

* 08.06.21 Tanuj - (GTMS 4455) Opt Out Failure
* May-31-2023 Siddharth (GTMS-12786): Prevent Contact Status field from being changed if it is in 'Inactive - No Longer There'
* May-13-2024 Anil Kumar (GTMS-20657): Prevent the Contact Status field from being changed if it is New or Assigned and Number_of_Calls_by_Current_Owner_Roll_Up__c is changed from 0 to 1
*/
public with sharing class ContactWorkflowConversionWS {
    public static Set<String> setContactStatus = new Set<String>{'New','Assigned','Attempting',
            'Demo Scheduled','Qualified','Retouch - Did Not Connect','Retouch - Confirmed No Opportunity'};
    public static Set<String> setInboundReasonFaulty = new Set<String>{'Delete Account','Delete Contact Only'};
    public static final String DEFAULT_EMAIL = 'donotcontact@samsara.com';
    public static final String DEFAULT_PHONE = 'Do Not Contact';
    //Removed 'Contact Established' as part of GTMS-25394
    //public static Set<String> setOutboundSourceStatus = new Set<String>{'Contact Established','Demo Scheduled','Qualified'};
    public static Set<String> setOutboundSourceStatus = new Set<String>{'Demo Scheduled','Qualified'};

    public static void beforeInsertUpdateRules(Contact newContact, Contact oldContact, Account accountDetails, Contact contactDetails){
        contactStatusChanged(newContact, oldContact);
        /*
         * Moved these wflow logic in Insert/Update Context 
         * @modified : August 6, 2021
    */
        updatePhoneAndEmailOptOut(newContact, oldContact);
        updatePhoneOptOut(newContact, oldContact);
        updateEmailOptOut(newContact, oldContact);
        //GTMS-29989 START
        if (oldContact != null) {
            ContactHelper.updateOptoutFields(new List<Contact>{newContact}, new Map<Id, Contact>{newContact.Id => oldContact});
        }
        // GTMS-29989 END
        updateContactForEmailOpt(newContact, oldContact);
        updateContactForPhoneOpt(newContact, oldContact);
    }

    public static void beforeUpdate(Contact newContact, Contact oldContact, Account accountDetails, Contact contactDetails){
        outboundSourceForListImport(newContact, oldContact);
      //Commented invocation of setContactFromNew method as part of GTMS-20657  
      //  setContactFromNew(newContact, oldContact);
        updateContactStatusToDemoScheduled(newContact, oldContact, contactDetails);

    }

    //Groundswell Nilesh Jain : Contact Status Changed  workflow changes
    public static void contactStatusChanged(Contact newContact, Contact oldContact){
        //Commented as part of GTMS-25351
        //if((oldContact == null || oldContact.Status__c != newContact.Status__c) && setContactStatus.contains(newContact.Status__c)){
        if(((oldContact == null || oldContact.Status__c != newContact.Status__c) && setContactStatus.contains(newContact.Status__c)) || ((oldContact == null || oldContact.Inbound_Reason_Faulty__c != newContact.Inbound_Reason_Faulty__c) && setInboundReasonFaulty.contains(newContact.Inbound_Reason_Faulty__c))){
            newContact.Contact_Status_Changed__c =  System.Now();
        }
    }
    
    //Groundswell Nilesh Jain : Set Contact from New to Attempting when first call is made workflow changes
   /*
    *Anil Kumar: Commented as part of GTMS-20657 
    public static void setContactFromNew(Contact newContact, Contact oldContact){
        if((oldContact.Number_of_Calls_by_Current_Owner_Roll_Up__c == 0 &&
            newContact.Number_of_Calls_by_Current_Owner_Roll_Up__c >= 1 &&
            (newContact.Status__c == 'New' || newContact.Status__c == 'Assigned'))
           || (oldContact.Number_of_Calls_by_Current_Owner_Roll_Up__c != 0
               && newContact.Number_of_Calls_by_Current_Owner_Roll_Up__c >= 1
               && oldContact.Status__c != newContact.Status__c
               && (newContact.Status__c == 'New' || newContact.Status__c == 'Assigned'))){
                   //GTMS-12786
                   if(newContact.Status__c!='Inactive - No Longer There')
                   {
                       newContact.Status__c = 'Demo Scheduled';
                   }        
               }
    }*/

    //Groundswell Nilesh Jain : Outbound source for List Import  workflow changes
    public static void outboundSourceForListImport(Contact newContact, Contact oldContact){
        if((oldContact.Source__c != newContact.Source__c || oldContact.Status__c != newContact.Status__c)
                && newContact.Source__c == 'List Import (no prior engagement)' && setOutboundSourceStatus.contains(newContact.Status__c)){
            newContact.Source__c = 'Outbound call / email / linkedin';
        }
    }

    //Groundswell : Tanuj : Update Contact Status to Demo Scheduled
   //Updates the contact status to Demo Scheduled when a valid Scheduled Demo Date has been inputted or when Demo Completed Date has been removed
   public static void updateContactStatusToDemoScheduled(Contact newContact, Contact oldContact, Contact contactDetails){
        if(newContact.Scheduled_Demo_Date__c != null 
        && oldContact.Scheduled_Demo_Date__c != newContact.Scheduled_Demo_Date__c
           && contactDetails.Owner.UserRole.Name.contains(Label.ExpressSegment)
           && newContact.ADR_Transfer_By__c == null
           && newContact.Hot_Transfer_To__c == null
           && (newContact.Source__c == 'List Import (no prior engagement)'
               || newContact.Source__c == 'Outbound call / email / linkedin')
          ){
              // Update Contact Status Demo Scheduled  
              // GTMS-12786
              // Commented as part of GTMS-25351
              //if(newContact.Status__c!='Inactive - No Longer There')
              if(newContact.Inbound_Reason_Faulty__c!='Inactive - No Longer There')
              {
                  newContact.Status__c = 'Demo Scheduled'; 
              } 
              
          }
    }


    //Groundswell Nilesh Jain : Update Phone and Email Opt Out workflow changes
    public static void updatePhoneAndEmailOptOut(Contact newContact, Contact oldContact){
        if((oldContact == null || oldContact.Opt_Out_Request__c != newContact.Opt_Out_Request__c) && 
        (newContact.Opt_Out_Request__c == 'GDPR' || newContact.Opt_Out_Request__c == 'Both Phone and Email') ){
            newContact.Phone_Opt_Out__c = true;
            newContact.Sales_Email_Opt_Out__c = true;
        }
    }

    //Groundswell Nilesh Jain : Update Phone Opt Out workflow changes
    public static void updatePhoneOptOut(Contact newContact, Contact oldContact){
        if((oldContact == null || oldContact.Opt_Out_Request__c != newContact.Opt_Out_Request__c) && 
        (newContact.Opt_Out_Request__c == 'Phone' || newContact.Opt_Out_Request__c == 'TPS List' || newContact.Opt_Out_Request__c == 'CTPS List') ){
            newContact.Phone_Opt_Out__c = true;
        }
    }

    //Groundswell Nilesh Jain : Update Email Opt Out workflow changes
    public static void updateEmailOptOut(Contact newContact, Contact oldContact){
        if((oldContact == null || oldContact.Opt_Out_Request__c != newContact.Opt_Out_Request__c) && newContact.Opt_Out_Request__c != null && newContact.Opt_Out_Request__c.contains('Email') ){
            newContact.HasOptedOutOfEmail  = true;
            newContact.Sales_Email_Opt_Out__c = true;  
            //Added as part of GTMS-21887
            if (newContact.HasOptedOutOfEmail == true) {
                newContact.Email_Event_Opt_In__c = false;
                newContact.Email_Newsletter_Opt_In__c = false;
                newContact.Email_Product_Ann_Updates_Opt_In__c = false;
                newContact.Email_Resource_Opt_In__c = false;
                newContact.Email_Special_Offer_Opt_In__c = false;
                newContact.Email_Webinar_Opt_In__c = false;
                newContact.Email_Blog_Opt_In__c = false;
                newContact.Email_Surveys_Opt_In__c = false;
                newContact.Email_Using_Samsara_Opt_In__c = false;
                
            }
            // End here GTMS-21887
        }
    }

    //Groundswell : Nilesh Jain : Update Contact for Email Opt Out Request workflow changes
    public static void updateContactForEmailOpt(Contact newContact, Contact oldContact){
        If(newContact.Email==DEFAULT_EMAIL){
            newContact.HasOptedOutOfEmail  = true;
            newContact.Sales_Email_Opt_Out__c = true;  
            //Added as part of GTMS-21887
                newContact.Email_Event_Opt_In__c = false;
                newContact.Email_Newsletter_Opt_In__c = false;
                newContact.Email_Product_Ann_Updates_Opt_In__c = false;
                newContact.Email_Resource_Opt_In__c = false;
                newContact.Email_Special_Offer_Opt_In__c = false;
                newContact.Email_Webinar_Opt_In__c = false;
                newContact.Email_Blog_Opt_In__c = false;
                newContact.Email_Surveys_Opt_In__c = false;
                newContact.Email_Using_Samsara_Opt_In__c = false;
        }
        if((oldContact == null || oldContact.Sales_Email_Opt_Out__c != newContact.Sales_Email_Opt_Out__c) && newContact.Sales_Email_Opt_Out__c){
            if(newContact.Email != DEFAULT_EMAIL){
                newContact.Opt_Out_Email_Copy__c = newContact.Email;
                   }
             
            if(newContact.Email!=DEFAULT_EMAIL){
                newContact.Email = DEFAULT_EMAIL;
            }
        }
    }

    //Groundswell Nilesh Jain : Update Contact for Phone Opt Out Request workflow changes
    public static void updateContactForPhoneOpt(Contact newContact, Contact oldContact){
        if((oldContact == null || oldContact.Phone_Opt_Out__c != newContact.Phone_Opt_Out__c || 
            oldContact.Registered_on_TPS__c != newContact.Registered_on_TPS__c) 
        && (newContact.Phone_Opt_Out__c || newContact.Registered_on_TPS__c)){
            if(newContact.MobilePhone != DEFAULT_PHONE){
                newContact.Opt_Out_Mobile_Phone_Copy__c = newContact.MobilePhone;    
            }
            if(newContact.Phone != DEFAULT_PHONE){
                newContact.Opt_Out_Phone_Copy__c = newContact.Phone; //Check with Harsha.   
            }   
            newContact.Opt_Out_Phone__c = newContact.Phone != DEFAULT_PHONE ?
                                        newContact.Phone :
                                            newContact.Opt_Out_Phone_Copy__c;
            newContact.Opt_Out_Mobile_Phone__c = newContact.MobilePhone != DEFAULT_PHONE ?
                                                newContact.MobilePhone :
                                                    newContact.Opt_Out_Mobile_Phone_Copy__c;
            newContact.Phone = DEFAULT_PHONE;
            newContact.MobilePhone = DEFAULT_PHONE;      
        }
    }

}