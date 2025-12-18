/*
* GTMS - GTMS-11667 Siddharth Kumar Mishra -  03/17/2023  - Add scheduled batch job to fix returns data                
*/
public class Batch_ReturnOpptyDataFix implements Database.Batchable<sObject>,Database.Stateful,Schedulable
{
    public SamsaraLoggerService thisSamsaraLoggerService = new SamsaraLoggerService();
    public string errorString = '';
    
    //START METHOD
    public Database.QueryLocator start(Database.BatchableContext BC)
    { 
        String query = 'SELECT Id,AccountId,Account.Name,Account.Customer_ARR__c , Account.Segment__c ,Type,StageName,CloseDate,CreatedDate, CreatedBy.Name, ContractID,SBQQ__AmendedContract__c, Contract.EndDate, Returning_Opportunity__c,Returning_Opportunity__r.Name,Returning_Opportunity__r.AccountId, Returning_Opportunity__r.ContractId, Returning_Opportunity__r.SBQQ__AmendedContract__c FROM opportunity WHERE type =\'Remorse Refund\' AND CloseDate >= LAST_N_DAYS:7 AND Returning_Opportunity__c !=null AND SBQQ__AmendedContract__c =null AND stagename = \'Refunded - Closed\' AND ContractID=null  AND of_LIC_Products__c!=0 ';
        
        
        return Database.getQueryLocator(query);
    }
    
    //EXECUTE METHOD
    public void execute(Database.BatchableContext BC, List<Opportunity> opportunityList)
    {
        findContracts(opportunityList);
        
        
    }
    
    //FINISH METHOD
    public void finish(Database.BatchableContext BC)
    { 
        if(!String.isBlank(errorString) && !string.isEmpty(errorString))
        {
            emailErrors(errorString);
        }
        
    }
    
    public void findContracts(List<Opportunity> opportunityList)
    {
        Set<Id> oppIds = new Set<Id>();
        for(Opportunity o:opportunityList)
        {
            oppIds.add(o.Id);          
        }
        Map<Id,Opportunity> mapOpps=new Map<Id,Opportunity>([Select Id,AccountId,Account.Name,Account.Customer_ARR__c , Account.Segment__c ,Type,StageName,CloseDate,CreatedDate, CreatedBy.Name, ContractID,SBQQ__AmendedContract__c, Contract.EndDate, Returning_Opportunity__c,Returning_Opportunity__r.Name,Returning_Opportunity__r.AccountId, Returning_Opportunity__r.ContractId, Returning_Opportunity__r.SBQQ__AmendedContract__c, (Select Id From SBQQ__Contracts__r) ,(Select Id,Product2Id,Quantity From OpportunityLineItems Where ProductCode like '%LIC%') From Opportunity where Id IN:oppIds order by Id]);
        Map<Id,Id> OriginalReturnOppID=new Map<Id,Id>();
        Map<Id,Id> ReturnOriginalOppID=new Map<Id,Id>();
        Map<Id,Id> returnOppID=new Map<Id,Id>();
        Map<Id,Id> originalOppWithContractMap = new Map<Id,Id>();
        for(Opportunity o:mapOpps.values()){
            OriginalReturnOppID.put(o.Id,o.Returning_Opportunity__c);
            ReturnOriginalOppID.put(o.Returning_Opportunity__c,o.Id);
        }
        
        Map<Id,Opportunity> mapReturnOpps=new Map<Id,Opportunity> ([Select Id, CreatedDate, CreatedBy.Name, ContractID, Contract.EndDate,SBQQ__AmendedContract__c,(Select Id,EndDate From SBQQ__Contracts__r) From Opportunity where id=:OriginalReturnOppID.values() ]);
        Map<Id,Id> ReturnOppWithContractID=new Map<Id,Id>();
        Map<Id,Id> ContractReturnOppWithID=new Map<Id,Id>();
        Map<Id,Id> oppWithoutContract=new Map<Id,Id>();
        for(Opportunity o:mapReturnOpps.values()){
            if(o.ContractID!=null){
                ReturnOppWithContractID.put(o.Id,o.ContractID);
                ContractReturnOppWithID.put(o.ContractId,o.Id);
            }
            else if(o.SBQQ__AmendedContract__c!=null){
                ReturnOppWithContractID.put(o.Id,o.SBQQ__AmendedContract__c);
                ContractReturnOppWithID.put(o.SBQQ__AmendedContract__c,o.Id);
            }
            else if(o.SBQQ__Contracts__r.size()>0){
                ReturnOppWithContractID.put(o.Id,o.SBQQ__Contracts__r[0].Id);
                ContractReturnOppWithID.put(o.SBQQ__Contracts__r[0].Id,o.Id);
                if(o.SBQQ__Contracts__r.size()>1){
                    System.debug('Opp withmore than one contract---->'+o.Id);
                }
            }
            else{
                oppWithoutContract.put(ReturnOriginalOppID.get(o.Id),o.Id);
            }
        }
        if(!ReturnOppWithContractID.isEmpty())
        {
            for(Id i:ReturnOppWithContractID.keySet())
            {
                createSubscriptions(ReturnOriginalOppID.get(i),ReturnOppWithContractID.get(i));
            }	            
        }
        
    }
    
    public void createSubscriptions(Id oppId, Id contractId)
    {
        String result='';
        if(String.isNotBlank(contractId) && String.isNotBlank(oppId)){
            try{
                Opportunity o;
                List<Opportunity>  listO=[Select Id,SBQQ__AmendedContract__c,(Select Id,Product2Id,Quantity,OpportunityId,Opportunity.CloseDate From OpportunityLineItems where Product2.ProductCode like 'LIC-%' and Quantity<0 ) From Opportunity Where Id=:oppId];
                if(listO.size()==0){
                    result='Opportunity not found';
                }
                else{
                    o=listO[0];
                }
                if(o!=null && o.SBQQ__AmendedContract__c!=null){
                    result='Opportunity is already updated';
                }
                else if(o!=null){
                    List<String> reqFields = getFields('SBQQ__Subscription__c');
                    Contract c=Database.query('Select Id,(Select '+String.join(reqFields,',')+' From SBQQ__Subscriptions__r) From Contract Where Id=:contractId ');
                    Map<Id,SBQQ__Subscription__c> mapSub=new Map<Id,SBQQ__Subscription__c>();
                    Map<Id,Decimal> mapSubQuantity=new Map<Id,Decimal>();
                    Map<Id,Decimal> mapOLIQuantity=new Map<Id,Decimal>();
                    for(SBQQ__Subscription__c s:c.SBQQ__Subscriptions__r){
                        if(!mapSubQuantity.containsKey(s.SBQQ__Product__c)){
                            mapSubQuantity.put(s.SBQQ__Product__c,0);
                        }
                        mapSub.put(s.SBQQ__Product__c,s);
                        mapSubQuantity.put(s.SBQQ__Product__c,mapSubQuantity.get(s.SBQQ__Product__c)+s.SBQQ__Quantity__c);
                    }
                    for(OpportunityLineItem oli:o.OpportunityLineItems){
                        if(!mapOLIQuantity.containsKey(oli.Product2Id)){
                            mapOLIQuantity.put(oli.Product2Id,0);
                        }
                        mapOLIQuantity.put(oli.Product2Id,mapOLIQuantity.get(oli.Product2Id)+oli.Quantity);                
                    }
                    List<SBQQ__Subscription__c> listS=new List<SBQQ__Subscription__c>();
                    Set<String> processIDs=new Set<String>();
                    for(OpportunityLineItem oli:o.OpportunityLineItems){
                        if(processIDs.contains(oli.Product2Id))
                        {
                            continue;
                        }
                        processIDs.add(oli.Product2Id);
                        SBQQ__Subscription__c oliS=mapSub.get(oli.Product2Id);
                        Decimal subQuantity=mapSubQuantity.get(oli.Product2Id);
                        Decimal oliQuantity=mapOLIQuantity.get(oli.Product2Id);
                        if(oliS!=null && (subQuantity+oliQuantity)>=0){
                            SBQQ__Subscription__c clonedS=oliS.clone();
                            // clonedS.SBQQ__Discount__c=null;
                            // clonedS.SBQQ__AdditionalDiscountAmount__c=null;
                            clonedS.Prior_OLI_Id__c=oli.Id;
                            clonedS.Prior_OppId_Legacy__c=oli.OpportunityId;
                            clonedS.SBQQ__Product__c=oli.Product2Id;
                            clonedS.SBQQ__Quantity__c=oliQuantity;
                            clonedS.SBQQ__QuoteLine__c=null;
                            clonedS.SBQQ__SubscriptionStartDate__c=oli.Opportunity.CloseDate;
                            clonedS.SBQQ__RootId__c=null;
                            clonedS.OwnerId='0054p000002sSsE'; //Dataload Bot
                            //clonedS.SBQQ__RenewalQuantity__c=oli.Quantity;
                            clonedS.SBQQ__RevisedSubscription__c=oliS.Id;
                            
                            if((subQuantity+oliQuantity)<=0){
                                clonedS.SBQQ__TerminatedDate__c=oli.Opportunity.CloseDate;
                                for(SBQQ__Subscription__c s:c.SBQQ__Subscriptions__r){
                                    if(s.SBQQ__Product__c==oli.Product2Id){
                                        s.SBQQ__TerminatedDate__c=oli.Opportunity.CloseDate;
                                        listS.add(s);
                                    }
                                }                        
                                
                            }
                            listS.add(clonedS);
                        }
                    }
                    
                    if(listS.size()>0){
                        upsert listS;
                        o.SBQQ__AmendedContract__c=contractId;
                        update o;
                        result='Successfully updated';
                    }
                    else{
                        result='Sum of sub after applying is less than zero';
                    }
                    
                }
                
            }
            catch(Exception ex){
                result=ex.getMessage();
            }
        }
        System.debug('@@@==='+oppId+'='+result+'===@@@');
        
    }
    
    public static List<string> getFields(String selectedObject)
    {
        List<String> reqFields = new List<String>();
        Map <String,Schema.SObjectType> gd = Schema.getGlobalDescribe();
        Schema.SObjectType sobjType = gd.get(selectedObject);
        Schema.DescribeSObjectResult r = sobjType.getDescribe();
        Map<String, Schema.SObjectField> MapofField = r.fields.getMap();
        
        for(String fieldName : MapofField.keySet()) {
            Schema.SObjectField field = MapofField.get(fieldName);
            Schema.DescribeFieldResult F = field.getDescribe();
            //System.debug('field---->'+field);
            //  System.debug('F---->'+F.getType()); //type of field
            reqFields.add(fieldName);
        }
        System.debug(reqFields);
        return reqFields;
    }
    
    public void emailErrors(string errorString)
    {
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setToAddresses(getEmailAddresses());
        mail.setSubject('CPQ Error Notification');
        mail.setPlainTextBody(errorString);
        if(!test.isRunningTest())
        {
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });            
        }
        
    }
    public List<String> getEmailAddresses()
    {
        List<Id> idList = new List<Id>();
        List<String> mailToAddresses = System.Label.Batch_ReturnOpptyDataFix_Error_Emails.Split(',');
        
        return mailToAddresses;
    }
    
    //Schedulable execute
    public void execute(SchedulableContext SC)
    {
        Database.executebatch((new Batch_ReturnOpptyDataFix()),1);
    }
}