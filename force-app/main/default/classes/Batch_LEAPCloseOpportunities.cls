/*
 * @Author : Siddharth Kumar Mishra
 * @Description : GTMS - 7001  -  4/19/2022  -  Move opportunities to "Closed Lost" if all conditions are met
 * @note : to run the job : System.schedule('Batch_LEAPCloseOpportunities',  '0 0 21 ? * MON,TUE,WED,THU,FRI *', new Batch_LEAPCloseOpportunities());
 * June-29-2022 Siddharth GTMS-7643 Free Trial Return - Add Products 
 */
public class Batch_LEAPCloseOpportunities implements Database.Batchable<sObject>,Schedulable
{
    public SamsaraLoggerService thisSamsaraLoggerService = new SamsaraLoggerService();
    List<Database.SaveResult> updateResults = new List<Database.SaveResult>();
    
    
    //START METHOD
    public Database.QueryLocator start(Database.BatchableContext BC)
    {  
        //List<Id> testids = new List<Id>{'0061P00000TzcYuQAJ'};
        String query = 'SELECT id,StageName,recordType.name FROM Opportunity WHERE ((((((Type = \'Revenue Opportunity\' AND Account.Account_Assignment_Date__c < LAST_N_DAYS:60 AND (Account.Last_Meaningful_Engagement_Date__c < LAST_N_DAYS:60 OR Account.Last_Meaningful_Engagement_Date__c=null)) AND (Account.Lifetime_Purchases__c=null OR Account.Lifetime_Purchases__c=0)) AND (Owner.UserRole.Name LIKE \'%Fleet IS AE1 NA US%\' OR Owner.UserRole.Name LIKE \'%Fleet IS AE2 NA US%\')) AND Account.First_Purchase_Date__c = null) AND Account.Parent.Name = null ) AND Reseller__r.name=null) AND Insurance_Partner__r.name=null AND Referral_Partner__r.name=null AND (NOT Account.name LIKE \'%musselman & hall contractor LLC%\') AND (NOT Owner.Name=null) AND StageName In (\'Incubate\',\'Qualified\',\'Trial\',\'Proposal\',\'Decision\',\'Purchase\') AND Account.Golden_Ticket__c=null AND (NOT Account.Name LIKE \'%authority brands%\') AND ((Not Owner.UserRole.Name Like \'%manager%\') OR (Not Owner.UserRole.Name Like \'%director%\') OR (Not Owner.UserRole.Name Like \'%ENT%\') OR (Not Owner.UserRole.Name Like \'%ism%\') OR (Not Owner.UserRole.Name Like \'%isd%\')) AND (Account.Owner.Leave_Return_Date__c < TODAY OR Account.Owner.Leave_Return_Date__c=null )' ; //AND Id IN:testids
        
        return Database.getQueryLocator(query);
    }
    
    //EXECUTE METHOD
    public void execute(Database.BatchableContext BC, List<Opportunity> oppsToClose)
    {  
        CloseOpportunities(oppsToClose);        
    }
    
    //FINISH METHOD
    public void finish(Database.BatchableContext BC)
    { 
        
    }
    
    public void CloseOpportunities(List<Opportunity> oppsToClose)
    {
        system.debug('oppsToClose ---->'+oppsToClose);
        for(Opportunity opp : oppsToClose)
        {
            opp.Closed_Lost_Reason__c = 'Opportunity closed due to customer inactivity';
            opp.StageName = 'Closed Lost';
            if(opp.recordType.name=='Industrial Opportunity')
            {
                opp.Industrial_Closed_Lost_Reason__c='';
            }
        }
        Integer failedRecords = 0;
        List<String> failedRecordIds = new List<String>();
        List<Database.SaveResult> updateResults = Database.update(oppsToClose,false);
        for(Database.SaveResult sr : updateResults)
        {
            if(!sr.isSuccess())
            {
                for(Database.Error err : sr.getErrors())
                {
                    if(err.getMessage().contains('You are trying to close a revenue opportunity that already contains one or more unclosed trials. Please close them by ensuring the return of the products.'))
                    {
                        failedRecords++;
                        failedRecordIds.add(sr.getId()); 
                    }
                }
            }
        }
        if(failedRecords!=0)
        {
            thisSamsaraLoggerService.logger.logTrace('Batch_LEAPCloseOpportunities: Number of Failed Records ::'+ failedRecords +' | Failed Record Ids:: '+ failedRecordIds);
            thisSamsaraLoggerService.logger.dispatch();
            createFreeTrialReturns(failedRecordIds);
        }
        
       
    }
    //create free trial return opportunities
    //GTMS-7643 Added OpportunityLineItem functionality for returns
    public void createFreeTrialReturns(List<String> failedRecordIds)
    {
        List<Opportunity> freeTrialReturnOpportunities = new List<Opportunity>();
        list<Opportunity> failedRecords = [Select id,Name,StageName,Closed_Lost_Reason__c From opportunity Where Id IN:failedRecordIds];
        
        Map<Id,Opportunity> freeTrialOpportunitiesMap1 = new Map<Id,Opportunity>([Select id,OwnerId,AccountId,Type,Qualified_Date__c,Reseller__c,CloseDate,StageName,
                    Related_Contact__c,Next_Step_Due_Date__c,Next_Steps__c,Notes__c,Trial_Goal_1__c,Trial_Goal_2__c,
                    Trial_Goal_3__c,Hours_of_Service_flag__c,Planned_Trial_Installation_Date__c,
                    Trial_Period__c,Shipping_Address_NEW__c,Ship_From_Location__c,Shipping_Method__c,
                    Return_Close_Date__c,Returning_Opportunity__c,Name,RecordTypeId,recordType.name,
                    TrialResolutionOppty__c,CurrencyIsoCode,Pricebook2Id  
                                                    from Opportunity 
                                                    Where Type='Free Trial Opportunity' 
                                                        AND TrialResolutionOppty__c IN :failedRecordIds 
                                                        AND FT_Return__c =null]);
        
        

        
        
        Map<id,id> freeTrialOpportunitiesOwnerMap = new Map<id,Id>();
        Id returnOppRecTypeId = [Select id from RecordType where Name = 'Return Opportunity' and SObjectType='Opportunity'].Id;
        for(Opportunity trialOpp: freeTrialOpportunitiesMap1.values())
        {
            Opportunity newOppty = new Opportunity(
                                                Name=trialOpp.Name+' - RTN',
                                                AccountId=trialOpp.AccountId,
                                                StageName='Return Created',
                                                Type='Free Trial Return',
                                                Returning_Opportunity__c=trialOpp.Id,
                                                CloseDate=trialOpp.CloseDate,
                                                RecordTypeId=returnOppRecTypeId,

                                                CurrencyIsoCode=trialOpp.CurrencyIsoCode,
                                                Pricebook2Id=trialOpp.Pricebook2Id,                                                
                                                Related_Contact__c=trialOpp.Related_Contact__c,                                                
                                                Ship_From_Location__c=trialOpp.Ship_From_Location__c,
                                                Shipping_Address_NEW__c=trialOpp.Shipping_Address_NEW__c,
                                                Shipping_Method__c=trialOpp.Shipping_Method__c,                                                
                                                TrialResolutionOppty__c=trialOpp.TrialResolutionOppty__c
                                                
             );
            freeTrialReturnOpportunities.add(newOppty);
            freeTrialOpportunitiesOwnerMap.put(trialOpp.Id, trialOpp.OwnerId);
        }
        Database.insert(freeTrialReturnOpportunities,false);

        List<OpportunityLineItem> trialOppProducts = [Select Id,OpportunityId,quantity,UnitPrice,PricebookEntryId,Product2Id,Name,Ship_From_Location__c,TotalPrice,License_Term_Copy__c,NS_Unit_Rate__c 
                                                        from OpportunityLineItem
                                                        Where opportunityId IN :freeTrialOpportunitiesMap1.keyset()];
        Map<Id,List<OpportunityLineItem>>  freeTrialOpp_OppProductMap = new Map<Id,List<OpportunityLineItem>>();
        for(OpportunityLineItem OLI:trialOppProducts)
        {
            if(freeTrialOpp_OppProductMap.containsKey(OLI.OpportunityId))
            {
                freeTrialOpp_OppProductMap.get(OLI.OpportunityId).add(OLI);
            }
            else 
                {
                    List<OpportunityLineItem> OLIList = new List<OpportunityLineItem>();
                    OLIList.add(OLI);
                    freeTrialOpp_OppProductMap.put(OLI.opportunityId,OLIList);
                }
            
        }
        List<OpportunityLineItem> newReturnOLI = new List<OpportunityLineItem>();
        for(Opportunity opp: freeTrialReturnOpportunities)
        {
            if(freeTrialOpp_OppProductMap.containsKey(opp.Returning_Opportunity__c))
            {
                for(OpportunityLineItem OLI:freeTrialOpp_OppProductMap.get(opp.Returning_Opportunity__c))
                {
                    OpportunityLineItem newOLI =new OpportunityLineItem(
                                                                        OpportunityId=opp.Id,
                                                                        PricebookEntryId=OLI.PricebookEntryId,
                                                                        Quantity=OLI.Quantity,
                                                                        License_Term_Copy__c=OLI.License_Term_Copy__c,
                                                                        Ship_From_Location__c=OLI.Ship_From_Location__c

                    );
                    newReturnOLI.add(newOLI);
                }
            }
        } 
        Database.insert(newReturnOLI,false);                                              
        for(Opportunity opp: freeTrialReturnOpportunities)
        {
            opp.ownerId = freeTrialOpportunitiesOwnerMap.get(opp.Returning_Opportunity__c);
            opp.StageName = 'Return Initiated';
        }
        Database.update(freeTrialReturnOpportunities,false);
        for(Opportunity opp: failedRecords)
        {
            system.debug('failedRecords to update ---->'+opp);
            opp.Closed_Lost_Reason__c = 'Opportunity closed due to customer inactivity';
            opp.StageName = 'Closed Lost';
            /*if(opp.recordType.name=='Industrial Opportunity')
            {
                opp.Industrial_Closed_Lost_Reason__c='';
            }*/
        }
        Database.update(failedRecords);
    }
    
    public void execute(SchedulableContext SC)
    {       
        database.executebatch((new Batch_LEAPCloseOpportunities()),Integer.valueOf(System.Label.Batch_LEAPCloseOpportunities_batch_size));
    }
}