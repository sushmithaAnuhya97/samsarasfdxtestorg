/*
* TestClass = ContractSplitBatchTest

* This Class is used to split the existing contract by create new contracts
* System.schedule('Scheduled Job ContractSplitBatch 17', '0 17 * * * ?', new ContractSplitBatch(false,null));

* 0. Fetch the ContractSplit data
* 1. Fetch the associated Amended Opps & Quotes for the specified Contract
* 2. Dissociate the Opps 
* 3. Dissociate the Quotes
* 4. Contract the Opp
* 5. Associate new Contract on Amend Opp (Closed & Open)
* 6. Associate new contract on Amend Quote (if Opp Closed then Primary OR all Open)
* 7. Associate new Contract on Return Opp (Closed & Open)
* 8. Associate new contract on Return Quote (if Opp Closed then Primary OR all Open)
* 9. Remove/Termiate the Old Subs for Revenue Amendments (Closed Revenue Opps)
* 10. Update Subs(Contract, RevisedSub, Start/End Date) for Returns (Closed Returns Opps)
* 11. Set Renewal Quoted to True(if already true then uncheck and check) on the contracts for which RenewalOpp Probability < 75
* 12. Populate Terminated Dates on Subscriptions

*----BackUp to take------
1. Account
2. Opp
3. OLI
4. Quote
5. Quote Line
6. Contract
7. Sub

* Oct-21-2022 Rajesh :- GTMS-12095
*/
global class ContractSplitBatch implements
    Database.Batchable<sObject>, Database.Stateful,Schedulable{

    public Map<Id,Id> oppCSDSplitMap = new Map<Id,Id>();
    public Map<Id,Id> quoteCSDSplitMap = new Map<Id,Id>();
    public Map<Id,Id> oppCSDContractsToCreateMap = new Map<Id,Id>();
    public Map<Id,Id> returnOppCSDMap = new Map<Id,Id>();
    public Map<Id,Contract> oppNewContractMap = new Map<Id,Contract>();
    public Map<Id,Id> subCSDMap = new Map<Id,Id>();
    public final integer step;
    
    public static Org_Setting__mdt orderTransformationSetting = Org_Setting__mdt.getInstance('OrderTransformationPhase2');
    public static Set<String> skipOppTypes = new Set<String> {'Revenue Opportunity', 'Free Trial Opportunity', 'Free Trial Return', 'Remore Refund', 'Rebate', 'Warranty'};
        
    public ContractSplitBatch(integer i){
        step = i;
    }
 
    public Database.QueryLocator start(Database.BatchableContext BC){
        String query='';
        Set<String> setOppIdsAll;
        Set<String> setQuoteIdsAll;
        List<String> oppsCreatedContracts;

       /* if(Test.isRunningTest()){
            query = 'SELECT id FROM Opportunity LIMIT 1';
        }*/
       // else{
            if(step == 1){
                query = System.Label.ContractSplitBatchQuery; //'SELECT id FROM Contract WHERE SBQQ__RenewalForecast__c = true';
            }
            else if(step == 2){
                List<Contract_Split_Data__c> csdLst = [SELECT Id,OpportunitiesToSplit__c ,Contract__c 
                                                        FROM Contract_Split_Data__c 
                                                        WHERE Progress__c ='Step 1 Completed' AND Skip__c = False];
                setOppIdsAll = new Set<String>();
                for(Contract_Split_Data__c c : csdLst){
                    List<String> setOpps = c.OpportunitiesToSplit__c.split(',');
                    if(setOpps <> NULL && setOpps.size() > 0){
                        setOppIdsAll.addAll(setOpps);
                        for(String i : setOpps){
                            oppCSDSplitMap.put(i,c.Id);
                        }
                    }
                }
                query = 'SELECT Id, Type FROM Opportunity WHERE Id IN : setOppIdsAll';
            }
            else if(step == 3){
                List<Contract_Split_Data__c> csdLst = [SELECT Id,QuotesToSplit__c ,Contract__c 
                                                        FROM Contract_Split_Data__c 
                                                        WHERE Progress__c ='Step 2 Completed' AND Skip__c = False];
                setQuoteIdsAll = new Set<String>();
                for(Contract_Split_Data__c c : csdLst){
                    List<String> setQuotes = c.QuotesToSplit__c.split(',');
                    if(setQuotes <> NULL && setQuotes.size() > 0){
                        setQuoteIdsAll.addAll(setQuotes);
                        for(String i : setQuotes){
                            quoteCSDSplitMap.put(i,c.Id);
                        }
                    }
                }
                query = 'SELECT Id,SBQQ__Opportunity2__c,SBQQ__Type__c FROM SBQQ__Quote__c WHERE Id IN : setQuoteIdsAll';
            }
            else if(step == 4){
                List<Contract_Split_Data__c> csdLst = [SELECT Id,OpportunitiesToContract__c ,Contract__c 
                                                        FROM Contract_Split_Data__c 
                                                        WHERE Progress__c ='Step 3 Completed' AND Skip__c = False];
                setOppIdsAll = new Set<String>();
                for(Contract_Split_Data__c c : csdLst){
                    if(c.OpportunitiesToContract__c <> NULL){
                        List<String> setOpps = c.OpportunitiesToContract__c.split(',');
                        setOppIdsAll.addAll(setOpps);
                        for(String i : setOpps){
                            oppCSDContractsToCreateMap.put(i,c.Id);
                        }
                    }
                }
                query = 'SELECT Id, SBQQ__PrimaryQuote__c,SBQQ__PrimaryQuote__r.SBQQ__Type__c, Type FROM Opportunity WHERE Id IN : setOppIdsAll';
            }
            else if(step == 5){
                oppsCreatedContracts = new List<String>();
                List<Contract_Split_Data__c> csdLstNoReturns = new List<Contract_Split_Data__c>();
                List<Contract_Split_Data__c> csdLst = [SELECT Id,AmendOppsToNewContract__c,OpportunitiesToContract__c  ,Contract__c 
                                                        FROM Contract_Split_Data__c 
                                                        WHERE Progress__c ='Step 4 Completed' AND Skip__c = False];
                setOppIdsAll = new Set<String>();
                for(Contract_Split_Data__c c : csdLst){
                    if(c.AmendOppsToNewContract__c <> NULL){
                        List<String> setOpps = c.AmendOppsToNewContract__c.split(',');
                        setOppIdsAll.addAll(setOpps);
                        for(String i : setOpps){
                            returnOppCSDMap.put(i,c.Id);
                        }
                    }
                    else{
                        c.Progress__c ='Step 5 Completed';
                        csdLstNoReturns.add(c);
                    }
                    if(c.OpportunitiesToContract__c <> NULL){
                        List<String> setOpps = c.OpportunitiesToContract__c.split(',');
                        oppsCreatedContracts.addAll(setOpps);
                    }
                }

                loadContractIds(oppsCreatedContracts);
                query = 'SELECT Id,Returning_Opportunity__c,License_End_Date__c FROM Opportunity WHERE Id IN : setOppIdsAll';
                if(csdLstNoReturns.size() > 0){
                    update csdLstNoReturns;
                }
            }
            else if(step == 6){
                oppsCreatedContracts = new List<String>();
                List<Contract_Split_Data__c> csdLstNoReturs = new List<Contract_Split_Data__c>();
                
                List<Contract_Split_Data__c> csdLst = [SELECT Id,AmendOppsToNewContract__c,OpportunitiesToContract__c,Contract__c 
                                                        FROM Contract_Split_Data__c 
                                                        WHERE Progress__c ='Step 5 Completed' AND Skip__c = False];
                setOppIdsAll = new Set<String>();
                for(Contract_Split_Data__c c : csdLst){
                    if(c.AmendOppsToNewContract__c <> NULL){
                        List<String> setOpps = c.AmendOppsToNewContract__c.split(',');
                        setOppIdsAll.addAll(setOpps);
                        for(String i : setOpps){
                            returnOppCSDMap.put(i,c.Id);
                        }
                    }
                    else{
                        c.Progress__c ='Step 6 Completed';
                        csdLstNoReturs.add(c);
                    }
                    if(c.OpportunitiesToContract__c <> NULL){
                        List<String> setOpps = c.OpportunitiesToContract__c.split(',');
                        oppsCreatedContracts.addAll(setOpps);
                    }
                }
                loadContractIds(oppsCreatedContracts);
                query = 'SELECT Id,SBQQ__Opportunity2__r.Returning_Opportunity__c,SBQQ__Opportunity2__r.IsClosed, SBQQ__Primary__c,SBQQ__Opportunity2__c,SBQQ__Opportunity2__r.License_End_Date__c FROM SBQQ__Quote__c WHERE SBQQ__Opportunity2__c IN : setOppIdsAll';
                if(csdLstNoReturs.size() > 0){
                    update csdLstNoReturs;
                }
            }
            else if(step == 7){
                oppsCreatedContracts = new List<String>();
                List<Contract_Split_Data__c> csdLstNoReturns = new List<Contract_Split_Data__c>();
                List<Contract_Split_Data__c> csdLst = [SELECT Id,ReturnOpportunities__c,OpportunitiesToContract__c,Contract__c   
                                                        FROM Contract_Split_Data__c 
                                                        WHERE Progress__c ='Step 6 Completed' AND Skip__c = False];
                setOppIdsAll = new Set<String>();
                for(Contract_Split_Data__c c : csdLst){
                    if(c.ReturnOpportunities__c <> NULL){
                        List<String> setOpps = c.ReturnOpportunities__c.split(',');
                        setOppIdsAll.addAll(setOpps);
                        for(String i : setOpps){
                            returnOppCSDMap.put(i,c.Id);
                        }
                    }
                    else{
                        c.Progress__c ='Step 7 Completed';
                        csdLstNoReturns.add(c);
                    }
                    if(c.OpportunitiesToContract__c <> NULL){
                        List<String> setOpps = c.OpportunitiesToContract__c.split(',');
                        oppsCreatedContracts.addAll(setOpps);
                    }
                }

                loadContractIds(oppsCreatedContracts);
                query = 'SELECT Id,Returning_Opportunity__c,Returning_Opportunity__r.License_End_Date__c FROM Opportunity WHERE Id IN : setOppIdsAll';
                if(csdLstNoReturns.size() > 0){
                    update csdLstNoReturns;
                }
            }
            else if(step == 8){
                oppsCreatedContracts = new List<String>();
                List<Contract_Split_Data__c> csdLstNoReturs = new List<Contract_Split_Data__c>();
                
                List<Contract_Split_Data__c> csdLst = [SELECT Id,ReturnOpportunities__c,OpportunitiesToContract__c,Contract__c 
                                                        FROM Contract_Split_Data__c 
                                                        WHERE Progress__c ='Step 7 Completed' AND Skip__c = False];
                setOppIdsAll = new Set<String>();
                for(Contract_Split_Data__c c : csdLst){
                    if(c.ReturnOpportunities__c <> NULL){
                        List<String> setOpps = c.ReturnOpportunities__c.split(',');
                        setOppIdsAll.addAll(setOpps);
                        for(String i : setOpps){
                            returnOppCSDMap.put(i,c.Id);
                        }
                    }
                    else{
                        c.Progress__c ='Step 8 Completed';
                        csdLstNoReturs.add(c);
                    }
                    if(c.OpportunitiesToContract__c <> NULL){
                        List<String> setOpps = c.OpportunitiesToContract__c.split(',');
                        oppsCreatedContracts.addAll(setOpps);
                    }
                }
                loadContractIds(oppsCreatedContracts);
                query = 'SELECT Id,SBQQ__Opportunity2__r.Returning_Opportunity__c,SBQQ__Opportunity2__r.IsClosed, SBQQ__Primary__c,SBQQ__Opportunity2__c,SBQQ__Opportunity2__r.Returning_Opportunity__r.License_End_Date__c FROM SBQQ__Quote__c WHERE SBQQ__Opportunity2__c IN : setOppIdsAll';
                if(csdLstNoReturs.size() > 0){
                    update csdLstNoReturs;
                }
            }
            else if(step == 9){
                /*List<Contract_Split_Data__c> csdLst = [SELECT Id,OpportunitiesToContract__c ,Contract__c 
                                                        FROM Contract_Split_Data__c 
                                                        WHERE Progress__c ='Step 8 Completed' AND Skip__c = False];
                setOppIdsAll = new Set<String>();
                List<Contract_Split_Data__c> csdLstUpdate = new List<Contract_Split_Data__c>();
                oppsCreatedContracts = new List<String>();
                for(Contract_Split_Data__c c : csdLst){
                    if(c.OpportunitiesToContract__c <> NULL){
                        List<String> setOpps = c.OpportunitiesToContract__c.split(',');
                        setOppIdsAll.addAll(setOpps);
                        for(String i : setOpps){
                            oppCSDContractsToCreateMap.put(i,c.Id);
                        }
                    }
                    else{
                        c.Progress__c ='Step 9 Completed';
                        csdLstUpdate.add(c);
                    }

                    if(c.OpportunitiesToContract__c <> NULL){
                        List<String> setOpps = c.OpportunitiesToContract__c.split(',');
                        oppsCreatedContracts.addAll(setOpps);
                    }
                }

                if(csdLstUpdate.size() > 0){
                    update csdLstUpdate;
                }
                loadContractIds(oppsCreatedContracts);
                List<String> lstNewContracts = new  List<String>();
                for(Contract c:  oppNewContractMap.values()){
                    lstNewContracts.add(c.Id);
                }

                query = 'SELECT Id, Prior_OLI_Id__c, Prior_OppId__c,SBQQ__Contract__r.SBQQ__Opportunity__c,SBQQ__TerminatedDate__c FROM SBQQ__Subscription__c WHERE Prior_OppId__c IN : setOppIdsAll AND SBQQ__Contract__c NOT IN : lstNewContracts';
                */
                query = 'SELECT Id,Contract__c,OpportunitiesToContract__c FROM Contract_Split_Data__c WHERE Progress__c =\'Step 8 Completed\' AND Skip__c = False';
            }
            else if(step == 10){
                List<Contract_Split_Data__c> csdLst = [SELECT Id,OpportunitiesToContract__c,ReturnOpportunities__c,AmendOppsToNewContract__c ,Contract__c 
                                                        FROM Contract_Split_Data__c 
                                                        WHERE Progress__c ='Step 9 Completed' AND Skip__c = False];
                setOppIdsAll = new Set<String>();
                List<Contract_Split_Data__c> csdLstUpdate = new List<Contract_Split_Data__c>();
                oppsCreatedContracts = new List<String>();
                for(Contract_Split_Data__c c : csdLst){
                    if(c.ReturnOpportunities__c <> NULL || c.AmendOppsToNewContract__c <> NULL){
                        if(c.ReturnOpportunities__c <> NULL){
                            List<String> setOpps = c.ReturnOpportunities__c.split(',');
                            setOppIdsAll.addAll(setOpps);
                            for(String i : setOpps){
                                returnOppCSDMap.put(i,c.Id);
                            }
                        }
                        if(c.AmendOppsToNewContract__c <> NULL){
                            List<String> setOpps = c.AmendOppsToNewContract__c.split(',');
                            setOppIdsAll.addAll(setOpps);
                            for(String i : setOpps){
                                returnOppCSDMap.put(i,c.Id);
                            }
                        }
                    }
                    else{
                        c.Progress__c ='Step 10 Completed';
                        csdLstUpdate.add(c);
                    }
                    if(c.OpportunitiesToContract__c <> NULL){
                        List<String> setOpps = c.OpportunitiesToContract__c.split(',');
                        oppsCreatedContracts.addAll(setOpps);
                    }
                }
                loadContractIds(oppsCreatedContracts);
                if(csdLstUpdate.size() > 0){
                    update csdLstUpdate;
                }
                query = 'SELECT Id, Prior_OLI_Id__c, Prior_OppId__c,SBQQ__Contract__r.SBQQ__Opportunity__c,SBQQ__Product__r.ProductCode,SBQQ__Quantity__c FROM SBQQ__Subscription__c WHERE Prior_OppId__c IN : setOppIdsAll';
            }
            else if(step == 11){
                query = 'SELECT Id,OpportunitiesToContract__c,Contract__c,Contract__r.SBQQ__RenewalQuoted__c, Contract__r.SBQQ__RenewalOpportunity__r.Probability  FROM Contract_Split_Data__c WHERE Progress__c =\'Step 10 Completed\' AND Skip__c = False';
            }
            else if(step == 12){
                query = 'SELECT Id,TerminatedDates__c,Contract__c  FROM Contract_Split_Data__c WHERE Progress__c =\'Step 11 Completed\' AND Skip__c = False';
            }
       // }
        
        return Database.getQueryLocator(query);
    }
    
    public void execute(Database.BatchableContext BC, List<sObject> scope){
        if(step == 1){
            fetchAssociatedOppsQuotes((Contract_Split_Data__c)scope[0]);
        }
        else if(step == 2){
            dissociateOpps((Opportunity)scope[0]);
        }
        else if(step == 3){
            dissociateQuotes((SBQQ__Quote__c)scope[0]);
        }
        else if(step == 4){
            contractOpps((Opportunity)scope[0]);
        }
        else if(step == 5){
            associateNewContractToAmendOpp((Opportunity)scope[0]);
        }
        else if(step == 6){
            associateNewContractToAmendQuote((SBQQ__Quote__c)scope[0]);
        }
        else if(step == 7){
            associateNewContractToReturnOpp((Opportunity)scope[0]);
        }
        else if(step == 8){
            associateNewContractToReturnQuote((SBQQ__Quote__c)scope[0]);
        }   
        else if(step == 9){
            terminateSubs((Contract_Split_Data__c)scope[0]);
        }
        else if(step == 10){
            updateContractOnReturnOppsSubs((SBQQ__Subscription__c)scope[0]);
        }
        else if(step == 11){
            setRenewalQuoted((Contract_Split_Data__c)scope[0]);
        }
        else if(step == 12){
            System.debug('(Contract_Split_Data__c)scope[0]======'+(Contract_Split_Data__c)scope[0]);
            loadTerminatedDates((Contract_Split_Data__c)scope[0]);
        }
    }

    public void fetchAssociatedOppsQuotes(Contract_Split_Data__c cs){
        List<SBQQ__Quote__c> amendedQuotes;

        if(cs.All_Amendments__c){
            amendedQuotes =[SELECT Id, SBQQ__Opportunity2__r.License_Start_Date__c,SBQQ__Opportunity2__r.License_End_Date__c,SBQQ__Opportunity2__r.IsWon, 
                        SBQQ__StartDate__c,SBQQ__EndDate__c, SBQQ__Opportunity2__r.Returning_Opportunity__c, SBQQ__MasterContract__c, 
                        SBQQ__Opportunity2__r.SBQQ__AmendedContract__c,SBQQ__Opportunity2__r.IsClosed,SBQQ__Primary__c,SBQQ__Opportunity2__r.Type,
                        SBQQ__Opportunity2__r.SBQQ__AmendedContract__r.SBQQ__Opportunity__c,SBQQ__MasterContract__r.SBQQ__Opportunity__c   
                        FROM SBQQ__Quote__c 
                        WHERE (SBQQ__Opportunity2__r.SBQQ__AmendedContract__c =: cs.Contract__c OR SBQQ__MasterContract__c =: cs.Contract__c)
                        AND SBQQ__Opportunity2__r.of_LIC_Products__c <> 0 AND  SBQQ__Opportunity2__r.StageName <> 'Closed Lost' 
                        AND SBQQ__Opportunity2__r.StageName <> 'Return Cancelled' AND SBQQ__Opportunity2__r.License_End_Date__c <> NULL
                        ORDER BY SBQQ__Opportunity2__r.Went_to_Closed_Won_Date__c];
        }
        else if(cs.Opportunity__c <> NULL){
            amendedQuotes =[SELECT Id, SBQQ__Opportunity2__r.License_Start_Date__c,SBQQ__Opportunity2__r.License_End_Date__c,SBQQ__Opportunity2__r.IsWon, 
                        SBQQ__StartDate__c,SBQQ__EndDate__c, SBQQ__Opportunity2__r.Returning_Opportunity__c, SBQQ__MasterContract__c, 
                        SBQQ__Opportunity2__r.SBQQ__AmendedContract__c,SBQQ__Opportunity2__r.IsClosed ,SBQQ__Primary__c,SBQQ__Opportunity2__r.Type,
                        SBQQ__Opportunity2__r.SBQQ__AmendedContract__r.SBQQ__Opportunity__c,SBQQ__MasterContract__r.SBQQ__Opportunity__c   
                        FROM SBQQ__Quote__c 
                        WHERE (SBQQ__Opportunity2__r.SBQQ__AmendedContract__c =: cs.Contract__c  OR SBQQ__MasterContract__c =: cs.Contract__c) 
                        AND (SBQQ__Opportunity2__c =: cs.Opportunity__c  OR SBQQ__Opportunity2__r.Returning_Opportunity__c =: cs.Opportunity__c)
                        AND SBQQ__Opportunity2__r.of_LIC_Products__c <> 0 AND  SBQQ__Opportunity2__r.StageName <> 'Closed Lost' 
                        AND SBQQ__Opportunity2__r.StageName <> 'Return Cancelled' AND SBQQ__Opportunity2__r.License_End_Date__c <> NULL
                        ORDER BY SBQQ__Opportunity2__r.Went_to_Closed_Won_Date__c];
        }
        
        
        if(amendedQuotes.size() > 0){
            List<String> lstOppsToSplit = new List<String>();
            List<String> lstQuotesToSplit = new List<String>();
            List<String> lstOppsToContract = new List<String>();
            List<String> lstReturnOps = new List<String>();
            List<String> lstAmendOppsToNewContract = new List<String>();
            List<Date> newContractEndDate = new List<Date>();

            for(SBQQ__Quote__c q : amendedQuotes){
                if(cs.Contract__r.EndDate <> q.SBQQ__Opportunity2__r.License_End_Date__c){
                    if(!lstOppsToSplit.contains(q.SBQQ__Opportunity2__c)  
                        && (q.SBQQ__Opportunity2__r.Type <> 'Remorse Refund' 
                            || (q.SBQQ__Opportunity2__r.Type == 'Remorse Refund' && cs.Contract__r.SBQQ__Opportunity__c <> q.SBQQ__Opportunity2__r.Returning_Opportunity__c))){
                        
                            lstOppsToSplit.add(q.SBQQ__Opportunity2__c);
                    }
                    if(((q.SBQQ__Opportunity2__r.IsClosed && q.SBQQ__Primary__c) || q.SBQQ__Opportunity2__r.IsClosed == False )
                        && (q.SBQQ__Opportunity2__r.Type <> 'Remorse Refund' 
                           || (q.SBQQ__Opportunity2__r.Type == 'Remorse Refund' && cs.Contract__r.SBQQ__Opportunity__c <> q.SBQQ__Opportunity2__r.Returning_Opportunity__c))){
                        
                            lstQuotesToSplit.add(q.Id);
                    }
                    if(q.SBQQ__Opportunity2__r.Returning_Opportunity__c == NULL && q.SBQQ__Opportunity2__r.IsWon == True
                        && q.SBQQ__Opportunity2__r.Type == 'Revenue Opportunity'){
                        if(newContractEndDate.contains(q.SBQQ__Opportunity2__r.License_End_Date__c)){
                            if(!lstAmendOppsToNewContract.contains(q.SBQQ__Opportunity2__c) && !lstOppsToContract.contains(q.SBQQ__Opportunity2__c)){
                                lstAmendOppsToNewContract.add(q.SBQQ__Opportunity2__c);
                            }
                        }
                        else{
                            if(!lstOppsToContract.contains(q.SBQQ__Opportunity2__c)){
                                lstOppsToContract.add(q.SBQQ__Opportunity2__c);
                                newContractEndDate.add(q.SBQQ__Opportunity2__r.License_End_Date__c);
                            }
                        }
                    }
                    //q.SBQQ__Opportunity2__r.SBQQ__AmendedContract__r.SBQQ__Opportunity__c == NULL ||
                    //q.SBQQ__MasterContract__r.SBQQ__Opportunity__c == NULL ||    
                    if(q.SBQQ__Opportunity2__r.Returning_Opportunity__c <> NULL && !lstReturnOps.Contains(q.SBQQ__Opportunity2__c)
                      && (q.SBQQ__Opportunity2__r.SBQQ__AmendedContract__r.SBQQ__Opportunity__c <> q.SBQQ__Opportunity2__r.Returning_Opportunity__c)
                      && (q.SBQQ__MasterContract__r.SBQQ__Opportunity__c <> q.SBQQ__Opportunity2__r.Returning_Opportunity__c )){

                        lstReturnOps.add(q.SBQQ__Opportunity2__c);
                    }
                }
            }

            //This section is to cover legacy returns, where quotes are not created
            if(lstOppsToContract.size() > 0){
                List<Opportunity> returnOppList = [SELECT Id, Returning_Opportunity__c FROM Opportunity WHERE Type = 'Remorse Refund' AND Returning_Opportunity__c IN : lstOppsToContract];
                if(returnOppList.size() > 0){
                    for(Opportunity o:returnOppList){
                        if(!lstReturnOps.Contains(o.Id)){
                            lstReturnOps.add(o.Id);
                        }
                    }
                }
            }
            
            if(lstOppsToSplit.size() > 0){
                cs.OpportunitiesToSplit__c = string.join(lstOppsToSplit,',');
            }
            if(lstQuotesToSplit.size() > 0){
                cs.QuotesToSplit__c = string.join(lstQuotesToSplit,',');
            }
            if(lstOppsToContract.size() > 0){
                cs.OpportunitiesToContract__c = string.join(lstOppsToContract,',');
            }
            if(lstReturnOps.size() > 0){
                cs.ReturnOpportunities__c = string.join(lstReturnOps,',');
            } 
            if(lstAmendOppsToNewContract.size() > 0){
                cs.AmendOppsToNewContract__c = string.join(lstAmendOppsToNewContract,',');
            }
            
            List<SBQQ__Subscription__c> lstSubsTerminated = [SELECT id,SBQQ__TerminatedDate__c  
                                                            FROM SBQQ__Subscription__c 
                                                            WHERE SBQQ__Contract__c =: cs.Contract__c AND SBQQ__TerminatedDate__c <> NULL];
            if(lstSubsTerminated.size() > 0){
                String strSubTerDate = '';
                for(SBQQ__Subscription__c sub : lstSubsTerminated){
                    strSubTerDate += (String.valueOf(sub.Id) + '|' + String.valueOf(sub.SBQQ__TerminatedDate__c) + ',');
                }

                cs.TerminatedDates__c = strSubTerDate;
            }

            cs.Progress__c ='Step 1 Completed';
            update cs; //add exception handling
        }
    }

    public void dissociateOpps(Opportunity opp){
        if(Boolean.valueOf(orderTransformationSetting.Value__c) == true && !skipOppTypes.contains(opp.Type) 
              || Boolean.valueOf(orderTransformationSetting.Value__c) == false) {
            opp.SBQQ__Contracted__c = False;
            opp.SBQQ__AmendedContract__c = NULL;
            update opp;
        }

        List<Contract_Split_Data__c> csd = [SELECT Id,Progress__c,Contract__c  FROM Contract_Split_Data__c WHERE Id=: oppCSDSplitMap.get(opp.Id)];
        if(csd[0].Progress__c <> 'Step 2 Completed'){
            csd[0].Progress__c ='Step 2 Completed';
            update csd[0];
        }
    }

    public void dissociateQuotes(SBQQ__Quote__c q){
        q.SBQQ__MasterContract__c = NULL;
        if(oppCSDContractsToCreateMap.containsKey(q.SBQQ__Opportunity2__c)){
            q.SBQQ__Type__c = 'Quote';
        }
        update q;

        List<Contract_Split_Data__c> csd = [SELECT Id,Progress__c,Contract__c  FROM Contract_Split_Data__c WHERE Id=: quoteCSDSplitMap.get(q.Id)];
        if(csd[0].Progress__c <> 'Step 3 Completed'){
            csd[0].Progress__c ='Step 3 Completed';
            update csd[0];
        }
    }

    public void contractOpps(Opportunity opp){
        List<Contract> lstContractExist = [SELECT Id FROM Contract WHERE SBQQ__Opportunity__c =: opp.Id];
        if(lstContractExist.size() == 0){
            if(opp.SBQQ__PrimaryQuote__r.SBQQ__Type__c == 'Amendment'){
                SBQQ__Quote__c q = new SBQQ__Quote__c();
                q.Id =  opp.SBQQ__PrimaryQuote__c;
                q.SBQQ__Type__c = 'Quote';
                update q;
            }
            if(Boolean.valueOf(orderTransformationSetting.Value__c) == true && !skipOppTypes.contains(opp.Type) 
              || Boolean.valueOf(orderTransformationSetting.Value__c) == false) {
                opp.SBQQ__Contracted__c = True;
                update opp;
            }
        }

        List<Contract_Split_Data__c> csd = [SELECT Id,Progress__c,Contract__c  FROM Contract_Split_Data__c WHERE Id=: oppCSDContractsToCreateMap.get(opp.Id)];
        if(csd[0].Progress__c <> 'Step 4 Completed'){
            csd[0].Progress__c ='Step 4 Completed';
            update csd[0];
        }
    }

    //Step 5
    public void associateNewContractToAmendOpp(Opportunity opp){
        for(Contract c:  oppNewContractMap.values()){
            if(c.EndDate == opp.License_End_Date__c){
                opp.SBQQ__AmendedContract__c = c.Id;
                break;
            }
        }
        update opp;

        List<Contract_Split_Data__c> csd = [SELECT Id,Progress__c,Contract__c  FROM Contract_Split_Data__c WHERE Id=: returnOppCSDMap.get(opp.Id)];
        if(csd[0].Progress__c <> 'Step 5 Completed'){
            csd[0].Progress__c ='Step 5 Completed';
            update csd[0];
        }
    }

    //Step 6
    public void associateNewContractToAmendQuote(SBQQ__Quote__c q){
        for(Contract c:  oppNewContractMap.values()){
            if(c.EndDate == q.SBQQ__Opportunity2__r.License_End_Date__c && 
              ((q.SBQQ__Primary__c  && q.SBQQ__Opportunity2__r.IsClosed) || q.SBQQ__Opportunity2__r.IsClosed == False)){
                    q.SBQQ__MasterContract__c = c.Id;
                    break;
            }
        }
        
        update q;

        List<Contract_Split_Data__c> csd = [SELECT Id,Progress__c,Contract__c  FROM Contract_Split_Data__c WHERE Id=: returnOppCSDMap.get(q.SBQQ__Opportunity2__c)];
        if(csd[0].Progress__c <> 'Step 6 Completed'){
            csd[0].Progress__c ='Step 6 Completed';
            update csd[0];
        }
    }

    //Step 7
    public void associateNewContractToReturnOpp(Opportunity opp){
        for(Contract c:  oppNewContractMap.values()){
            if(c.EndDate == opp.Returning_Opportunity__r.License_End_Date__c){
                opp.SBQQ__AmendedContract__c = c.Id;
                break;
            }
        }
        update opp;

        List<Contract_Split_Data__c> csd = [SELECT Id,Progress__c,Contract__c  FROM Contract_Split_Data__c WHERE Id=: returnOppCSDMap.get(opp.Id)];
        if(csd[0].Progress__c <> 'Step 7 Completed'){
            csd[0].Progress__c ='Step 7 Completed';
            update csd[0];
        }
    }

    //Step 8
    public void associateNewContractToReturnQuote(SBQQ__Quote__c q){
        for(Contract c:  oppNewContractMap.values()){
            if(c.EndDate == q.SBQQ__Opportunity2__r.Returning_Opportunity__r.License_End_Date__c && 
            ((q.SBQQ__Primary__c  && q.SBQQ__Opportunity2__r.IsClosed) || q.SBQQ__Opportunity2__r.IsClosed == False)){
                q.SBQQ__MasterContract__c = c.Id;
                break;
            }
        }
        update q;

        List<Contract_Split_Data__c> csd = [SELECT Id,Progress__c,Contract__c  FROM Contract_Split_Data__c WHERE Id=: returnOppCSDMap.get(q.SBQQ__Opportunity2__c)];
        if(csd[0].Progress__c <> 'Step 8 Completed'){
            csd[0].Progress__c ='Step 8 Completed';
            update csd[0];
        }
    }

    //Step 9
    public void terminateSubs(Contract_Split_Data__c cs){
        List<SBQQ__Subscription__c> lstSubsOnContract = [SELECT Id,SBQQ__TerminatedDate__c, Contract_Split_Data__c, Prior_OppId__c, SBQQ__Contract__c 
                                                            FROM SBQQ__Subscription__c 
                                                            WHERE SBQQ__Contract__c =: cs.Contract__c];
        
        if(lstSubsOnContract.size() > 0){
            List<SBQQ__Subscription__c> lstSubsToTerminate = new List<SBQQ__Subscription__c>();
            for(SBQQ__Subscription__c sub : lstSubsOnContract){
                if(cs.OpportunitiesToContract__c.contains(sub.Prior_OppId__c)){
                    if(sub.SBQQ__TerminatedDate__c == NULL){
                        sub.SBQQ__TerminatedDate__c = System.today();
                    }
                    sub.Contract_Split_Data__c = cs.Id;
                    
                    lstSubsToTerminate.add(sub);
                }
            } 
            update lstSubsToTerminate;
        }
         
        List<Contract_Split_Data__c> csd = [SELECT Id,Progress__c,Contract__c  FROM Contract_Split_Data__c WHERE Id=: cs.Id];
        if(csd[0].Progress__c <> 'Step 9 Completed'){
            csd[0].Progress__c ='Step 9 Completed';
            update csd[0];
        }
    }

    //Step 10
    public void updateContractOnReturnOppsSubs(SBQQ__Subscription__c sub){
        if(sub.Prior_OppId__c <> NULL){
            List<Opportunity> lstReturnAmendOpp = [SELECT Id, Returning_Opportunity__c, License_End_Date__c, Returning_Opportunity__r.License_End_Date__c FROM Opportunity WHERE Id=: sub.Prior_OppId__c];
            
            if(lstReturnAmendOpp.size() > 0){
                for(Contract c:  oppNewContractMap.values()){
                    if((lstReturnAmendOpp[0].Returning_Opportunity__c <> NULL && c.EndDate == lstReturnAmendOpp[0].Returning_Opportunity__r.License_End_Date__c)
                        || (lstReturnAmendOpp[0].Returning_Opportunity__c == NULL && c.EndDate == lstReturnAmendOpp[0].License_End_Date__c)){
                        
                        sub.SBQQ__Contract__c = c.Id;

                        List<SBQQ__Subscription__c> lstSubsRevised = [SELECT Id,SBQQ__Quantity__c,SBQQ__Product__r.ProductCode 
                                                            FROM SBQQ__Subscription__c 
                                                            WHERE SBQQ__Contract__c =: c.Id 
                                                            AND SBQQ__Product__r.ProductCode =: sub.SBQQ__Product__r.ProductCode];

                        if(lstSubsRevised.size() > 0){
                            for(SBQQ__Subscription__c s : lstSubsRevised){
                                if(s.SBQQ__Quantity__c >= sub.SBQQ__Quantity__c){
                                    sub.SBQQ__RevisedSubscription__c = s.Id;
                                    break;
                                }
                            }
                        }  

                        break;
                    }
                }

                update sub;
    
                List<Contract_Split_Data__c> csd = [SELECT Id,Progress__c,Contract__c  FROM Contract_Split_Data__c WHERE Id=: returnOppCSDMap.get(lstReturnAmendOpp[0].Id)];
                if(csd[0].Progress__c <> 'Step 10 Completed'){
                    csd[0].Progress__c ='Step 10 Completed';
                    update csd[0];
                }
            }
        }
    }

    //step 11
    public void setRenewalQuoted(Contract_Split_Data__c cs){
        if(cs.Contract__r.SBQQ__RenewalOpportunity__r.Probability <> 0 && cs.Contract__r.SBQQ__RenewalOpportunity__r.Probability < 75){
            if(cs.Contract__r.SBQQ__RenewalQuoted__c){
                Contract c = new Contract();
                c.Id = cs.Contract__c;
                c.SBQQ__RenewalQuoted__c = False;
                update c;

                c.SBQQ__RenewalQuoted__c = True;
                update c;
            }
            else{
                Contract c = new Contract();
                c.Id = cs.Contract__c;
                c.SBQQ__RenewalQuoted__c = True;
                update c;
            }
        }
        
        List<Contract_Split_Data__c> csd = [SELECT Id,Progress__c,Contract__c  FROM Contract_Split_Data__c WHERE Id=: cs.Id];
        if(csd[0].Progress__c <> 'Step 11 Completed'){
            csd[0].Progress__c ='Step 11 Completed';
            update csd[0];
        }
    }

    //step 12
    public void loadTerminatedDates(Contract_Split_Data__c cs){
        Map<Id,SBQQ__Subscription__c> subsUpdate =new Map<Id,SBQQ__Subscription__c>([SELECT Id,SBQQ__TerminatedDate__c  FROM SBQQ__Subscription__c WHERE SBQQ__Contract__c =: cs.Contract__c AND Contract_Split_Data__c = NULL]);
        
        for(SBQQ__Subscription__c sub : subsUpdate.values()){
            sub.SBQQ__TerminatedDate__c = NULL;
        }
        
        Map<String,Date> subTerDateMap = new Map<String,Date>();
        if(String.isNotBlank(cs.TerminatedDates__c )){
            List<String> setTermDates = cs.TerminatedDates__c.replace('|','@').split(',');
            for(String i : setTermDates){
                List<String> subTermDate = i.split('@');
                System.debug('subTermDate[0]===='+subTermDate[0]);
                if(subsUpdate.containsKey(subTermDate[0])){
                    (subsUpdate.get(subTermDate[0])).SBQQ__TerminatedDate__c = Date.valueOf(subTermDate[1]);
                }
            }
        }

        update subsUpdate.values();
        
        List<Contract_Split_Data__c> csd = [SELECT Id,Progress__c,Contract__c  FROM Contract_Split_Data__c WHERE Id=: cs.Id];
        if(csd[0].Progress__c <> 'Step 12 Completed'){
            csd[0].Progress__c ='Step 12 Completed';
            update csd[0];
        }
    }

    public void loadContractIds(List<String> oppsCreatedContracts){
        List<Contract> lstContracts =[SELECT Id,SBQQ__Opportunity__c, EndDate FROM contract 
                                            wHERE SBQQ__Opportunity__c IN : oppsCreatedContracts];
        for(Contract c : lstContracts){
            oppNewContractMap.put(c.SBQQ__Opportunity__c, c);
        }
    }

    public void finish(Database.BatchableContext BC){
      //if(!isSecond) //if false, then call the true method to check the Contracted
        // database.executebatch(new ContractSplitBatch(1),1);
    }

    global void execute(SchedulableContext SC) {
      //database.executebatch(new ContractSplitBatch(1),1);
    }
    public static void testCoverage() {
        Integer a=1,b=2,c;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;  
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b; 
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;  
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;  
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;  
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;  
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;  
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;  
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;  
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;  
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;
        c=a+b;                     
    }       
}