/*
* @Author : Siddharth Kumar Mishra
* @Description : GTMS - 10118  -  11/10/2022  -  
* @note : to run the job biweekly it needs to be scheduled twice: 
System.schedule('Batch_ContractHealthStatus',  '0 0 18 ? 1/1 FRI#1 *', new Batch_ContractHealthStatus());
System.schedule('Batch_ContractHealthStatus',  '0 0 18 ? 1/1 FRI#3 *', new Batch_ContractHealthStatus());
* 14/03/2023 Siddharth GTMS-12001: Added a new custom Label 'Batch_ContractHealthStatus_AdditionalQueryClause' for additional queries.
* April-12-2023 Siddharth GTMS-12001 : Changed criterias for Unhealthy and Unaddressable status
*/
public class Batch_ContractHealthStatus implements Database.Batchable<sObject>,Database.Stateful,Schedulable
{
    public SamsaraLoggerService thisSamsaraLoggerService = new SamsaraLoggerService();
    public string errorString = '';
    
    //START METHOD
    public Database.QueryLocator start(Database.BatchableContext BC)
    { 
        String query = 'SELECT id,Health_Status__c,Contract_Renewable_ACV__c,Account.name,Account.Active_Devices__c,Account.Custom_Active_Hardware_Calculation__c,Account.Delinquent_As_Of__c,account.Overdue_Balance__c,account.Customer_ARR__c,SBQQ__Opportunity__r.name,SBQQ__Opportunity__r.Sub_Type__c,Account.Lifetime_ACV_to_USD__c,Account.Netsuite_Delinquent_Status__c,Deactivated__c,SBQQ__Opportunity__r.Xactly_Opportunity_Segment__c,SBQQ__Opportunity__r.Type,SBQQ__Opportunity__r.Renewal_ACV__c,SBQQ__Opportunity__r.Subsidy_Amount__c FROM Contract WHERE EndDate >= 2023-04-29 AND EndDate=NEXT_N_MONTHS:9 AND Health_Status_Bypass__c!=True ';
        query += System.label.Batch_ContractHealthStatus_AdditionalQueryClause;
        return Database.getQueryLocator(query);
    }
    
    //EXECUTE METHOD
    public void execute(Database.BatchableContext BC, List<Contract> contractList)
    {
        updateContracts(contractList);
    }
    
    //FINISH METHOD
    public void finish(Database.BatchableContext BC)
    { 
        if(!String.isBlank(errorString) && !string.isEmpty(errorString))
        {
            emailErrors(errorString);
            
        }
        
    }
    
    //decide contract health and update the contracts 
    public void updateContracts(List<Contract> contractList)
    {
        List<Id> unaddressableContractIds = new List<Id>();
        List<Contract> unhealthyContracts = new List<Contract>();
        List<Contract> healthyContracts = new List<Contract>();
        Map<id,List<SBQQ__Subscription__c>> subMap = new Map<id,List<SBQQ__Subscription__c>>();
        List<SBQQ__Subscription__c> subscriptionList = [SELECT id,SBQQ__Contract__c,SBQQ__Product__r.SBQQ__RenewalProduct__c,SBQQ__Product__r.Product_Status__c from SBQQ__Subscription__c WHERE SBQQ__Contract__c IN:contractList];
        
        for(SBQQ__Subscription__c sub: subscriptionList)
        {
            if(!subMap.containsKey(sub.SBQQ__Contract__c))
            {
                subMap.put(sub.SBQQ__Contract__c,new List<SBQQ__Subscription__c>{sub});
            }
            else
            {
                subMap.get(sub.SBQQ__Contract__c).add(sub);
            }
        }
        for(Contract con:contractList)
        {
            //Healthy
            con.Health_Status__c = 'Healthy';
            //Unhealthy
            if(con.Account.Active_Devices__c == 0 || con.Account.Active_Devices__c == NULL)
            {
                if(con.Account.Custom_Active_Hardware_Calculation__c==NULL || con.Account.Custom_Active_Hardware_Calculation__c <10)
                {
                    con.Health_Status__c = 'Unhealthy';
                }                
            }
            else if(con.Account.Active_Devices__c < 10)
            {
                con.Health_Status__c = 'Unhealthy';
            }            
            if(((con.Account.Delinquent_As_Of__c!=null)&&(Date.valueOf(con.Account.Delinquent_As_Of__c)).daysBetween(System.today())>90) && (con.account.Overdue_Balance__c>((con.account.Customer_ARR__c/12)*2)))
            {
                con.Health_Status__c = 'Unhealthy';
            }
            
            
            if(subMap.get(con.Id)!=null && !subMap.get(con.Id).isEmpty())
            {
                integer EOL = 0;
                for(SBQQ__Subscription__c sub: subMap.get(con.id))
                    
                {
                    if(sub.SBQQ__Product__r.Product_Status__c != 'EOL' || (sub.SBQQ__Product__r.Product_Status__c == 'EOL' && sub.SBQQ__Product__r.SBQQ__RenewalProduct__c!=null))
                    {
                        break;                        
                    }
                    else
                    {
                        EOL++;
                    }
                }
                if(EOL==subMap.get(con.id).size())
                {
                    
                    con.Health_Status__c = 'Unaddressable';
                    unaddressableContractIds.add(con.Id);
                }
            }
            //Removed Customer_ARR__c condition for GTMS-13525
            //if(con.SBQQ__Opportunity__r.Sub_Type__c == 'Paid Pilot' || ((con.Account.Customer_ARR__c==NULL || con.Account.Customer_ARR__c < 100) || (con.Account.Lifetime_ACV_to_USD__c==NULL || con.Account.Lifetime_ACV_to_USD__c < 100)) || con.Account.Netsuite_Delinquent_Status__c == 'Written-off' || con.Deactivated__c == True || con.SBQQ__Opportunity__r.Xactly_Opportunity_Segment__c == 'Industrial' || (con.Contract_Renewable_ACV__c!=null && con.Contract_Renewable_ACV__c < 100) )
            
            if(con.SBQQ__Opportunity__r.Sub_Type__c == 'Paid Pilot' || (con.Account.Customer_ARR__c==NULL ||(con.Account.Lifetime_ACV_to_USD__c==NULL || con.Account.Lifetime_ACV_to_USD__c < 100)) || con.Account.Netsuite_Delinquent_Status__c == 'Written-off' || con.Deactivated__c == True || con.SBQQ__Opportunity__r.Xactly_Opportunity_Segment__c == 'Industrial' || (con.Contract_Renewable_ACV__c!=null && con.Contract_Renewable_ACV__c < 100) )
            {
                con.Health_Status__c = 'Unaddressable';
                unaddressableContractIds.add(con.Id);
            }
            
        }
        
        
        //Updating contracts
        List<Database.SaveResult> contractUpdateResults = Database.update(contractList,false);
        for(Database.SaveResult sr : contractUpdateResults)
        {
            if(!sr.isSuccess())
            {
                for(Database.Error err : sr.getErrors())
                {
                    thisSamsaraLoggerService.logger.logError('Batch_ContractHealthStatus: Update failed due to ::'+err.getMessage());
                    //contractErrorString+= err.getMessage() + '\n';
                    errorString+= err.getMessage() + '\n';
                    thisSamsaraLoggerService.logger.dispatch();
                }
            }
        }   
        
        if(!unaddressableContractIds.isEmpty())
        {
            List<Opportunity> openRenewalOpptyList = [Select id,stageName,Closed_Lost_Reason__c, Closed_Lost_Renewal_Reason__c from opportunity where SBQQ__RenewedContract__c IN :unaddressableContractIds AND Renewal__c = true AND SBQQ__Renewal__c = true AND (StageName!='Closed Lost' AND StageName!='Closed Won') ];
            if(!openRenewalOpptyList.isEmpty())
            {
                updateRenewalOpportunities(openRenewalOpptyList);
            }
        }
        
        
    }
    
    //Update renewal opportunities
    public void updateRenewalOpportunities(List<Opportunity> openRenewalOpptyList)
    {
        
        for(Opportunity opp:openRenewalOpptyList)
            
        {
            opp.stageName = 'Closed Lost';
            opp.Closed_Lost_Reason__c = 'Closed Lost';
            opp.Closed_Lost_Renewal_Sub_reason__c = 'Previously Churned';
            opp.Closed_Lost_Renewal_Reason__c = 'Renewal Admin Issue';
        }
        //Update openRenewalOpptyList;
        List<Database.SaveResult> opptyUpdateResults = Database.update(openRenewalOpptyList,false);
        for(Database.SaveResult sr : opptyUpdateResults)
        {
            if(!sr.isSuccess())
            {
                for(Database.Error err : sr.getErrors())
                {
                    thisSamsaraLoggerService.logger.logError('Batch_ContractHealthStatus: Update failed due to ::'+err.getMessage());
                    errorString+= err.getMessage() + '\n';
                    thisSamsaraLoggerService.logger.dispatch();
                }
            }
        }
        
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
        List<String> mailToAddresses = new List<String>();
        
        Group g = [Select (select userOrGroupId from groupMembers) From group where name = 'CPQ System Notification' LIMIT 1];
        for(GroupMember gm : g.groupMembers)
        {
            idList.add(gm.userOrGroupId);
        }
        
        User[] usr = [SELECT email FROM user WHERE id IN :idList];        
        for(User u : usr) 
        {            
            mailToAddresses.add(u.email);            
        }
        
        return mailToAddresses;
    }
    
    //Schedulable execute
    public void execute(SchedulableContext SC)
    {
        Database.executebatch((new Batch_ContractHealthStatus()),5);
    }
}