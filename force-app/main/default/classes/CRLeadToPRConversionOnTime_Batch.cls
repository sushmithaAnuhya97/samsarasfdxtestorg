public class CRLeadToPRConversionOnTime_Batch implements Database.Batchable<sObject>, Database.Stateful, Database.AllowsCallouts  {
    
    public Date dateValue;
    public Boolean isPartner = false;//Added variable for phase project (Make this variable "true" when it is running for partner application records)
    public string partnerTypeVal;//Added variable for phase project (Make this variable as "Partner_Application" when it is running for partner application records) 
    public string leadSourceVal;//Added variable for phase project (Make this variable as "Partner Application Form" when it is running for partner application records) 
    public List<Id> idList = new List<Id>();
    public List<String> emailIdList = new List<String>();
    public Map<Id,string> failedLeads = new Map<Id,string>();
    public Boolean inProgressLeads = false;
    public Boolean convertedLeads = false;
    public Boolean deniedLeads = false;
    public Database.QueryLocator start(Database.BatchableContext bc){
        Map<String, Object> bindValues = new Map<string, Object>{'recordType'=>partnerTypeVal,//replaced static value with variable for phase project
            													'dateVal'=>dateValue,
            													'leadSource'=>leadSourceVal,
            													'idList'=>idList};//replaced static value with variable for phase project
                                                                    
        string queryString = queryStringMethod();
        queryString += ' WHERE LeadSource =: leadSource AND RecordType.DeveloperName=:recordType AND createdDate < :dateVal';
        if(!idList.isEmpty()){
            queryString += ' AND Id IN :idList';
        }else{
            if(!isPartner){
                if(inProgressLeads){queryString += ' AND Is_Deal_Registration__c = true AND IsConverted = false and Deal_Registration_Denied__c = false';}
                else If(convertedLeads){queryString += ' AND IsConverted = true';}
                else If(deniedLeads){queryString += ' AND Deal_Registration_Denied__c = True AND Is_Deal_Registration__c = true and IsConverted = False';}
                else{queryString += ' AND (Is_Deal_Registration__c = true OR (Is_Deal_Registration__c = false AND IsConverted = true))';}
            }else{
                //queryString +=' WHERE (LeadSource =: leadSource AND RecordType.DeveloperName=:recordType AND createdDate < :dateVal)';
            }
           
        }
        queryString += ' Order By CreatedDate DESC';
        return Database.getQueryLocatorWithBinds(queryString,bindValues,AccessLevel.SYSTEM_MODE);
    }
    
    public void execute(Database.BatchableContext bc, List<Lead> scope){
        
        List<Partner_Registration__c> prList = new List<Partner_Registration__c>();
        Map<Id,Lead> leadMap = new Map<Id,Lead>(scope);
        Map<String,String> leadPrMap = new Map<String,String>();
        for(Partner_Registration__c pr:[SELECT Id,Lead__c FROM Partner_Registration__c WHERE Lead__c IN :leadMap.keySet()]){
            if(pr.Lead__c != null){leadPrMap.put(pr.Lead__c,pr.Id);}
        }
        for(Lead ld: scope){
            if(leadPrMap.get(ld.Id) == null){
                if(ld.RecordType.DeveloperName == 'Channel_Registration'){
                   
                    if(ld.IsConverted){
                        prList.add(mapPrFeilds(ld,'AE Approved','Create New Opportunity'));
                    }else{ 
                        try{
                            new SubmitLeadToNotreDame().postLeadToNotreDame(ld.Id);
                        }catch(exception ex){
                            failedLeads.put(ld.Id,ex.getMessage());
                        }
                    } 
                }else if(ld.RecordType.developerName == 'Partner_Application'){
                    if(ld.IsConverted && (ld.Status != 'Verification Pending' || ld.Status != 'New')){
                        prList.add(mapPartnerPrFields(ld,'PAM Approved'));
                    }else{
                        if(ld.Status != 'Verification Pending' && ld.Status != 'New' && ld.Status != 'Processing Approval'){
                            new SubmitLeadToNotreDame().postLeadToNotreDame(ld.Id);
                        }
                        
                    }
                }
            }
        }
        
        IF(!prList.isEmpty()){
            List<Database.saveResult> resultList = Database.insert(prList,false);
            for(Integer i=0;i<resultList.size();i++){
                if(!resultList[i].isSuccess()){failedLeads.put(prList[i].Lead__c,(!resultList[i].getErrors().isEmpty()) ? resultList[i].getErrors()[0].getMessage().replace('\n','--'):'PR Creattion Failed');}
            }
        }
    }
  
    public void finish(Database.BatchableContext bc){
        if(!failedLeads.isEmpty()){
            sendEmailMethod(bc.getJobId(),failedLeads);
        }
    }
    
    public string queryStringMethod(){
         
        string query = 'SELECT Id,ConvertedAccountId,ConvertedAccount.OwnerId, ConvertedContactId, City, CountryCode, PostalCode, StateCode, Street, Business_Unit__c, CAM_Owner__c,'
                       +' Company, Email, Fleet_Segment__c, Geography__c, Has_Agreed_To_Privacy_Policy__c, Inbound_Form_Fleet_Range__c, Industry,'
                       +' LeadSource, RR_Duplicate_Account__c, More_About_Opportunity__c, Most_Recent_Source__c, Number_of_Assets__c, Number_Of_Units__c,'
                       +' Number_Of_Vehicles__c, Organization_Size__c, OwnerId, Partner_Account_lr__c,Partner_Account_lr__r.OwnerId, Partner_Contact_lr__c, Partner_Program_Segment__c, Product_Interest_Type__c,'
                       +' Product_Type__c, Public_Sector__c, Program_Type__c, Website, ConvertedOpportunityId, IsConverted,Channel_Opportunity__c,'
						+' RecordType.DeveloperName, Status, Partner_Type__c'
                       +' FROM Lead';
        return query;
    }
	//created below method as part of partner application project
    public Partner_REgistration__c mapPartnerPrFields(lead leadRec, string Status){
        Partner_Registration__c prRec = new Partner_Registration__c();
        prRec.Partner_Account__c = leadRec.ConvertedAccountId;
        prRec.Address__City__s = leadRec.City;
        prRec.Address__CountryCode__s = leadRec.CountryCode;
        prRec.Address__PostalCode__s = leadRec.PostalCode;
        prRec.Address__StateCode__s = leadRec.StateCode;
        prRec.Address__Street__s = leadRec.Street;
        prRec.Business_Unit__c = leadRec.Business_Unit__c;
        prRec.CAM_Owner__c = leadRec.CAM_Owner__c;
        prRec.Company__c = leadRec.Company;
        prRec.Partner_Contact__c = leadRec.ConvertedContactId;
        prRec.Email__c = leadRec.Email;
        prRec.Fleet_Segment__c = leadRec.Fleet_Segment__c;
        prRec.Geography__c = leadRec.Geography__c;
        prRec.Has_Agreed_to_Privacy_Policy__c = leadRec.Has_Agreed_to_Privacy_Policy__c;
        prRec.Inbound_Form_Fleet_Range__c = leadRec.Inbound_Form_Fleet_Range__c;
        prRec.Industry__c = leadRec.Industry;
        prRec.Lead_Source__c = leadRec.LeadSource;
        prRec.Lead__c = leadRec.Id;
        prRec.Organization_Size__c = leadRec.Organization_Size__c;
        prRec.OwnerId = leadRec.ConvertedAccountId != null ? leadRec.ConvertedAccount.OwnerId : leadRec.OwnerId;
        prRec.PAM__c = leadRec.ConvertedAccountId != null ? leadRec.ConvertedAccount.OwnerId : leadRec.OwnerId;
        prRec.Partner_Program_Segment__c = leadRec.Partner_Program_Segment__c;
        prRec.Product_Interest_Type__c = leadRec.Product_Interest_Type__c;
        prRec.Product_Type__c = leadRec.Product_Type__c;
        prRec.Public_Sector__c = leadRec.Public_Sector__c;
        prRec.Sales_Program_Type__c = leadRec.Program_Type__c;
        prRec.Partner_Team_Alignment__c = leadRec.Partner_Type__c;
        prRec.Status__c = Status;
        prRec.Website__c = leadRec.Website;
        
        return prRec;
    }    
    
    public Partner_Registration__c mapPrFeilds(Lead leadRec, string status, string crValue){
        Partner_Registration__c prRec = new Partner_Registration__c();
        prRec.Account__c = leadRec.ConvertedAccountId;
        prRec.Address__City__s = leadRec.City;
        prRec.Address__CountryCode__s = leadRec.CountryCode;
        prRec.Address__PostalCode__s = leadRec.PostalCode;
        prRec.Address__StateCode__s = leadRec.StateCode;
        prRec.Address__Street__s = leadRec.Street;
        prRec.Business_Unit__c = leadRec.Business_Unit__c;
        prRec.CAM_Owner__c = leadRec.CAM_Owner__c;
        prRec.Company__c = leadRec.Company;
        prRec.Contact__c = leadRec.ConvertedContactId;
        prRec.Email__c = leadRec.Email;
        prRec.Fleet_Segment__c = leadRec.Fleet_Segment__c;
        prRec.Geography__c = leadRec.Geography__c;
        prRec.Has_Agreed_to_Privacy_Policy__c = leadRec.Has_Agreed_to_Privacy_Policy__c;
        prRec.Inbound_Form_Fleet_Range__c = leadRec.Inbound_Form_Fleet_Range__c;
        prRec.Industry__c = leadRec.Industry;
        prRec.Lead_Source__c = leadRec.LeadSource;
        prRec.Lead__c = leadRec.Id;
        prRec.Matched_Account__c = leadRec.RR_Duplicate_Account__c;
        prRec.More_About_Opportunity__c = leadRec.More_About_Opportunity__c;
        prRec.Most_Recent_Source__c = leadRec.Most_Recent_Source__c;
        prRec.Number_of_Assets__c = leadRec.Number_of_Assets__c;
        prRec.Number_of_Units__c = leadRec.Number_of_Units__c;
        prRec.Number_of_Vehicles__c = leadRec.Number_of_Vehicles__c;
        prRec.Opportunity__c = leadRec.Channel_Opportunity__c;
        prRec.Organization_Size__c = leadRec.Organization_Size__c;
        prRec.OwnerId = leadRec.ConvertedAccountId != null ? leadRec.ConvertedAccount.OwnerId : leadRec.OwnerId;
        prRec.PAM__c = leadRec.Partner_Account_lr__c != null ? leadRec.Partner_Account_lr__r.OwnerId : leadRec.OwnerId;
        prRec.Partner_Account__c = leadRec.Partner_Account_lr__c;
        prRec.Partner_Contact__c = leadRec.Partner_Contact_lr__c;
        prRec.Partner_Program_Segment__c = leadRec.Partner_Program_Segment__c;
        prRec.Product_Interest_Type__c = leadRec.Product_Interest_Type__c;
        prRec.Product_Type__c = leadRec.Product_Type__c;
        prRec.Public_Sector__c = leadRec.Public_Sector__c;
        prRec.Sales_Program_Type__c = leadRec.Program_Type__c;
        prRec.Status__c = Status;
        prRec.Website__c = leadRec.Website;
        prRec.CR__c = crValue;
        
        return prRec;
        
    }
    
    public void sendEmailMethod(string jobId,Map<Id,String> failedLeads){
        AsyncApexJob a = [SELECT Id, CreatedBy.Profile.Name,CreatedBy.Email FROM AsyncApexJob WHERE Id =:jobId];
    	List<string> emailList = new List<String>();
        emailList.add(a.CreatedBy.Email);
        if(!emailIdList.isEmpty())emailList.addAll(emailIdList);
        string csvString = string.join(new List<string>{'Lead Id','Error Message'},',')+'\n';
      	List<String> dataList = new List<String>();
        for(Id ew:failedLeads.keySet()){
            dataList.add(ew+','+failedLeads.get(ew));
        }
        csvString += string.join(dataList,'\n');
        Messaging.EmailFileAttachment attachment = new Messaging.EmailFileAttachment();
        attachment.setFileName('Converting of Existings Leads to PR was failed');
        attachment.setBody(Blob.valueOf(csvString));
        attachment.setContentType('tex/csv');
        attachment.setInline(true);
        
        Messaging.singleEmailMessage msg = new Messaging.singleEmailMessage();
        msg.setSubject('Lead Conversion to Partner Registration Failed');
        msg.setHtmlBody('Hi, Some of exisiting leads was not converted to PRs. Pelase find the attachement for failed leadIds');
        msg.setFileAttachments(new List<Messaging.EmailFileAttachment>{attachment});
        msg.setToAddresses(emailList);
        
        Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{msg},false);   
    }
}