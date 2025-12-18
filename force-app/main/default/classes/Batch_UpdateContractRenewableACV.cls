/*
* @Author : Siddharth Kumar Mishra
* @Description : GTMS - 12367  -   Modify logic to account for negative lines
* @note : to run the batch class Database.executebatch((new Batch_UpdateContractRenewableACV()),1);
*/
public class Batch_UpdateContractRenewableACV implements Database.Batchable<sObject>,Database.Stateful
{
    //START METHOD
    public Database.QueryLocator start(Database.BatchableContext BC)
    { 
        String query = 'SELECT id,Contract_Renewable_ACV__c from Contract';
        //List<Id> testids = new List<Id>{'8001P000000cZQvQAM'};
        //String query = 'SELECT id,Contract_Renewable_ACV__c FROM Contract WHERE id in:testids';
        
        
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
        
    }
    
    
    public void updateContracts(List<Contract> contractList)
    {       
        Map<id,list<SBQQ__Subscription__c>> contractidSubListMap = new Map<id,list<SBQQ__Subscription__c>>();
        //Map<Id,Contract> subIdContractMap = new Map<Id,Contract>();
        //Map<Id,Id> SubIdProductMap = new Map<Id,Id>();
        //Map<Id,decimal> SubIdQuantityMap = new Map<Id,decimal>();
        Map<Id,Map<String,List<SBQQ__Subscription__c>>> conIdProdCodeSubListMap = new Map<Id,Map<String,List<SBQQ__Subscription__c>>>();
        Map<Id,Map<String,Map<String,List<SBQQ__Subscription__c>>>> conIdProdCodeQuantSubListMap = new Map<Id,Map<String,Map<String,List<SBQQ__Subscription__c>>>>();
        Map<String,List<SBQQ__Subscription__c>> prodCodeSubListMap = new Map<String,List<SBQQ__Subscription__c>>();
        Map<String,List<SBQQ__Subscription__c>> PosOrNegQuantitySubListMap1 = new Map<String,List<SBQQ__Subscription__c>>();
        Map<String,List<SBQQ__Subscription__c>> PosOrNegQuantitySubListMap2 = new Map<String,List<SBQQ__Subscription__c>>();
        
        List<Contract> contractsList = new List<Contract>();
        List<Id> contractIdsList = new List<Id>();
        for(contract c: contractList)
        {
            contractIdsList.add(c.id);
            
        }
        List<SBQQ__Subscription__c> sbqqSubscriptionList = [Select id,SBQQ__Quantity__c,SBQQ__RenewalPrice__c,SBQQ__CustomerPrice__c,SBQQ__Contract__c,SBQQ__Product__r.ProductCode,createdDate from SBQQ__Subscription__c WHERE SBQQ__Contract__c IN:contractIdsList order by CreatedDate desc];
        if(sbqqSubscriptionList!=null && sbqqSubscriptionList.size()>0)
        {
            for(SBQQ__Subscription__c s:sbqqSubscriptionList)
            {
                List<SBQQ__Subscription__c> subsList = new List<SBQQ__Subscription__c>();
                if(!contractidSubListMap.containsKey(s.SBQQ__Contract__c))
                {
                    contractidSubListMap.put(s.SBQQ__Contract__c,new List<SBQQ__Subscription__c>{s});
                }
                else 
                {
                    contractidSubListMap.get(s.SBQQ__Contract__c).add(s);
                }
            }
            
            contractsList = [Select id,Contract_Renewable_ACV__c from Contract where id in:contractidSubListMap.KeySet()];
            PosOrNegQuantitySubListMap2.put('POSITIVE',new List<SBQQ__Subscription__c>());
            PosOrNegQuantitySubListMap2.put('NEGATIVE',new List<SBQQ__Subscription__c>());
            for(Contract Con : contractsList)
            {
                Map<String,Map<String,List<SBQQ__Subscription__c>>> tempMap2 = new Map<String,Map<String,List<SBQQ__Subscription__c>>>();
                for(SBQQ__Subscription__c s:contractidSubListMap.get(Con.id))
                {
                    System.debug('s.SBQQ__Quantity__c ---->'+s.SBQQ__Quantity__c);
                    if(s.SBQQ__Quantity__c > 0)
                    {
                        
                        if(!tempMap2.containsKey(s.SBQQ__Product__r.ProductCode))
                        {
                            Map<String,List<SBQQ__Subscription__c>> tempQtyMap = new Map<String,List<SBQQ__Subscription__c>>();
                            tempQtyMap.put('POSITIVE',new List<SBQQ__Subscription__c>{s}); 
                            tempMap2.put(s.SBQQ__Product__r.ProductCode,tempQtyMap);
                        }
                        else
                        {
                            if(!tempMap2.get(s.SBQQ__Product__r.ProductCode).containsKey('POSITIVE'))
                            {
                                tempMap2.get(s.SBQQ__Product__r.ProductCode).put('POSITIVE',new List<SBQQ__Subscription__c>{s});
                            }
                            else
                            {
                                tempMap2.get(s.SBQQ__Product__r.ProductCode).get('POSITIVE').add(s);
                            }
                        }
                    }
                    else if(s.SBQQ__Quantity__c < 0)
                    {
                        if(!tempMap2.containsKey(s.SBQQ__Product__r.ProductCode))
                        {
                            Map<String,List<SBQQ__Subscription__c>> tempQtyMap = new Map<String,List<SBQQ__Subscription__c>>();
                            tempQtyMap.put('NEGATIVE',new List<SBQQ__Subscription__c>{s}); 
                            tempMap2.put(s.SBQQ__Product__r.ProductCode,tempQtyMap);
                        }
                        else
                        {
                            if(!tempMap2.get(s.SBQQ__Product__r.ProductCode).containsKey('NEGATIVE'))
                            {
                                tempMap2.get(s.SBQQ__Product__r.ProductCode).put('NEGATIVE',new List<SBQQ__Subscription__c>{s});
                            }
                            else
                            {
                                tempMap2.get(s.SBQQ__Product__r.ProductCode).get('NEGATIVE').add(s);
                            }
                        }
                        
                    }
                }
                for(String s: tempMap2.keySet())
                {
                    System.debug('tempMap2 prodCode ---->'+s);
                    System.debug('tempMap2 Inner Map ---->'+tempMap2.get(s));
                }
                conIdProdCodeQuantSubListMap.put(Con.Id,tempMap2);
            }
            
            /*------------------------------------------------------*/            
            Contract Con = contractsList[0];
            
            for(String prodCode: conIdProdCodeQuantSubListMap.get(Con.Id).keySet())
            {
                System.debug('prodCode ---->'+prodCode);
                System.debug('Negative subscriptions ---->'+conIdProdCodeQuantSubListMap.get(Con.Id).get(prodCode).get('NEGATIVE'));
                System.debug('Positive subscriptions ---->'+conIdProdCodeQuantSubListMap.get(Con.Id).get(prodCode).get('POSITIVE'));
                if(conIdProdCodeQuantSubListMap.get(Con.Id).get(prodCode).get('NEGATIVE')!=null && !conIdProdCodeQuantSubListMap.get(Con.Id).get(prodCode).get('NEGATIVE').isEmpty())
                {                   
                   
                    for(SBQQ__Subscription__c N:conIdProdCodeQuantSubListMap.get(Con.Id).get(prodCode).get('NEGATIVE'))
                    {
                        for(SBQQ__Subscription__c P:conIdProdCodeQuantSubListMap.get(Con.Id).get(prodCode).get('POSITIVE'))
                        {
                            if((P.SBQQ__Quantity__c !=0) && (Math.abs(N.SBQQ__Quantity__c) == P.SBQQ__Quantity__c))
                            {
                                P.SBQQ__Quantity__c = 0;
                                N.SBQQ__Quantity__c = 0;
                                break;
                            }
                            else if((P.SBQQ__Quantity__c !=0) && (Math.abs(N.SBQQ__Quantity__c) > P.SBQQ__Quantity__c))
                            {
                                N.SBQQ__Quantity__c = N.SBQQ__Quantity__c + P.SBQQ__Quantity__c;
                                if(P.SBQQ__RenewalPrice__c!=NULL)
                                {
                                    N.SBQQ__RenewalPrice__c = P.SBQQ__RenewalPrice__c;
                                }
                                else if(P.SBQQ__RenewalPrice__c==NULL && P.SBQQ__CustomerPrice__c!=NULL)
                                {
                                    N.SBQQ__CustomerPrice__c = P.SBQQ__CustomerPrice__c;
                                }
                                else
                                {
                                    N.SBQQ__RenewalPrice__c = NULL;
                                    N.SBQQ__CustomerPrice__c = NULL;
                                }
                                P.SBQQ__Quantity__c = 0;
                                Continue;
                            }
                            else if((P.SBQQ__Quantity__c !=0) && (Math.abs(N.SBQQ__Quantity__c) < P.SBQQ__Quantity__c))
                            {
                                
                                P.SBQQ__Quantity__c = N.SBQQ__Quantity__c + P.SBQQ__Quantity__c;
                                N.SBQQ__Quantity__c = 0;
                            }
                        }
                    }
                    System.debug('After Cancelling Negative subscriptions ---->'+conIdProdCodeQuantSubListMap.get(Con.Id).get(prodCode).get('NEGATIVE'));
                    System.debug('After Cancelling Positive subscriptions ---->'+conIdProdCodeQuantSubListMap.get(Con.Id).get(prodCode).get('POSITIVE'));
                    
                }
                
            }
            /*------------------------------------------------------*/
            //Populating the contract Renewable ACV Field
            Con.Contract_Renewable_ACV__c = 0;
            for(String prodCode: conIdProdCodeQuantSubListMap.get(Con.Id).keySet())
            {
                System.debug('ProdCode ---->'+prodCode);
                System.debug('+ve subs for '+prodCode+' ---->'+conIdProdCodeQuantSubListMap.get(Con.Id).get(prodCode).get('POSITIVE'));
                for(SBQQ__Subscription__c P:conIdProdCodeQuantSubListMap.get(Con.Id).get(prodCode).get('POSITIVE'))
                {
                    if(P.SBQQ__Quantity__c!=0)
                    {
                        if(Con.Contract_Renewable_ACV__c == Null)
                        {
                            Con.Contract_Renewable_ACV__c = (P.SBQQ__Quantity__c*(P.SBQQ__RenewalPrice__c!=null?P.SBQQ__RenewalPrice__c:(P.SBQQ__CustomerPrice__c!=null?p.SBQQ__CustomerPrice__c:0)));
                        }
                        else
                        {
                            Con.Contract_Renewable_ACV__c += (P.SBQQ__Quantity__c*(P.SBQQ__RenewalPrice__c!=null?P.SBQQ__RenewalPrice__c:(P.SBQQ__CustomerPrice__c!=null?p.SBQQ__CustomerPrice__c:0)));
                        }                        
                    }
                }
            }
            
            List<Contract> conToBeUpdated = new List<Contract>{};
            conToBeUpdated.add(Con);
            
            Database.update(conToBeUpdated,False);
        }
    }
    
}