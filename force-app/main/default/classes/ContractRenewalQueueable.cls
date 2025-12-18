/**
* Created by Abu Saleh Khan on 01-02-2025.
Test Class: ContractRenewalQueueableTest
*/
public class ContractRenewalQueueable implements Queueable,Database.AllowsCallouts{
    public String action;
    public List<ID> quoteId = new List<Id>();
    public List<SBQQ__QuoteLine__c> qlLst = new List<SBQQ__QuoteLine__c>();
    public List<SBQQ__QuoteLine__c> upsertQuoteLineLst = new List<SBQQ__QuoteLine__c>();
    public List<SBQQ__Quote__c> recalculateQuoteLst = new List<SBQQ__Quote__c>();
    public List<Product_Mapping__c> productMappingRecList = new List<product_Mapping__c>();
    public MAP<String,String> productMap = new Map<String,String>();
    public Map<String,String> productCodeCopyMap = new Map<String,String>();
    public Map<String,String> dependentProductMap = new Map<String,String>();
    public Map<String,SBQQ__QuoteLine__c> proSKUDelMap = new Map<String,SBQQ__QuoteLine__c>();
    public List<Id> renewalOppoId  = new List<Id>();
    public List<Id> renewalQuoteList = new List<Id>();
    public List<Contract> conRecLst;
    public List<Id> quoteList = new List<Id>();
    public Map<Id,List<String>> quoteQLMap = new Map<Id,List<String>>();
    public Map<String,String> quotePROQLMap = new Map<String,String>();
    public Map<String,String> legacyProCombo = new Map<String,String>();
    public Map<String,String> prodCodetoProdId = new Map<String,String>();
    public Map<String,Decimal> qlMUPMAP = new Map<String,Decimal>();
    public Map<Id,List<String>> quoteQuoteLineMap = new Map<Id,List<String>>();
    public List<Id> qlMUPList = new List<Id>();
    public List<SBQQ__Quote__c> primaryQuoteList = new List<SBQQ__Quote__c>();
    public List<SBQQ__QuoteLine__c> qlDelList = new List<SBQQ__QuoteLine__c>();
    public Set<String> comboProductsList = new Set<String>();
    public Map<String,String> legacyPro = new Map<String,String>();
    public Map<String,String> dependent2Legacy = new Map<String,String>(); 
    List<Account> accList = new List<Account>();
    public List<Log__c> logList = new List<Log__c>();
    public List<Id> quoteLineId = new List<Id>();
    public Map<String,Decimal> mupQLList = new Map<String,Decimal>();
    public Map<String,String> pmReplace2Legacy = new Map<String,String>();
    public Map<String,Boolean> delCMProMap = new Map<String,Boolean>();
    public Map<String,Decimal> qLineListPrice = new Map<String,Decimal>();
    public Map<String,String> freePricingMap = new Map<String,String>();
    public Map<String,List<Product_Mapping__c>> addOnsMap = new Map<String,List<Product_Mapping__c>>();
    public ContractRenewalQueueable(String action,List<Contract> conRecLst,List<Id> quoteList,List<ID> quoteLineId,Map<String,Decimal> mupQLList,Map<String,String> pmReplace2Legacy,Map<String,String> freePricingMap){
        this.action = action;
        this.conRecLst = conRecLst;
        this.quoteList = quoteList;
        this.quoteLineId = quoteLineId;
        this.mupQLList = mupQLList;
        this.pmReplace2Legacy = pmReplace2Legacy;
        this.freePricingMap = freePricingMap;
    }
    public void execute(QueueableContext context){
        System.debug('Contract List: '+this.conRecLst);        
        List<AsyncApexJob> queueableJobs = [SELECT Id, Status, JobType, CreatedDate, ApexClass.Name FROM AsyncApexJob  WHERE JobType = 'Queueable' AND Status IN ('Queued', 'Processing')];
        System.debug('Number of Queueable jobs in the queue: ' + queueableJobs.size());
        //AsyncOptions asyncOptions = new AsyncOptions();
        System.debug('Current stack depth: ' + AsyncInfo.getCurrentQueueableStackDepth());
        System.debug('getMaximumQueueableStackDepth: ' + AsyncInfo.getMaximumQueueableStackDepth());
        Map<String,String> pmRepleg = new Map<String,String>();
        List<Id> conIdList = new List<Id>();
        if (!AsyncInfo.hasMaxStackDepth()) {   
            switch on this.action {    
                when 'New'{
                    System.debug('I am in New Action: ');
                    System.debug('Contract List: '+this.conRecLst);   
                    for(Contract conId: this.conRecLst){
                        conIdList.add(conId.Id);
                    }
                    List<Contract> conList = [SELECT ID,SBQQ__RenewalOpportunity__c FROM Contract WHERE Id IN: conIdList AND SBQQ__RenewalOpportunity__r.Probability < 95 AND SBQQ__RenewalOpportunity__r.ISClosed = false ];
                    for(Contract con: conList){
                        renewalOppoId.add(con.SBQQ__RenewalOpportunity__c);
                    }
                    System.debug('List of Renewal Opportunity Ids: '+renewalOppoId);
                    if(renewalOppoId.size()>0 && !renewalOppoId.isEmpty()){
                        qlLst = [SELECT ID,SBQQ__Quote__c,SBQQ__Quote__r.SBQQ__Primary__c,Monthly_Unit_Price__c,SBQQ__ListPrice__c,SBQQ__Discount__c,SBQQ__AdditionalDiscountAmount__c,SBQQ__Quote__r.SBQQ__Opportunity2__r.SBQQ__RenewedContract__c,SBQQ__Quote__r.SBQQ__Account__c,SBQQ__Quote__r.Associated_Opportunity_Type__c,SBQQ__Quote__r.SBQQ__Account__r.P_P_Pilot_Customer__c,SBQQ__Quote__r.P_P_Pilot_Customer__c  ,SBQQ__Quote__r.SBQQ__Account__r.P_P_Customer_Type__c,SBQQ__Quote__r.P_P_Customer_Type__c  ,SBQQ__ProductCode__c ,Product_Code_Copy__c ,SBQQ__Product__c,SBQQ__Product__r.ProductCode,SBQQ__Quote__r.Shipping_Address_NEW__c,SBQQ__Quantity__c,SBQQ__RenewedSubscription__c,Previous_Quantity__c FROM SBQQ__QuoteLine__c WHERE SBQQ__Quote__r.SBQQ__Opportunity2__c IN :renewalOppoId AND SBQQ__Quote__r.Associated_Opportunity_Type__c = 'Revenue Opportunity'];
                    }
                    System.debug('qlLst: '+qlLst);
                    productMappingRecList = [SELECT ID, Legacy_Product__c,Legacy_Product__r.ProductCode ,Replacement_Product__c,Replacement_Product__r.ProductCode,Dependent_Product__c,Dependent_Product__r.ProductCode,Delete_Product__c,Active__c,Free_Pricing__c,Action__c FROM Product_Mapping__c WHERE Active__c = true];
                    System.debug('productMappingRecList: '+productMappingRecList);
                    List<String> pmLegacyList = new List<String>();
                    Set<SBQQ__Quote__c> primaryQuoteSet = new Set<SBQQ__Quote__c>();
                    Set<Account> accSet = new Set<Account>();
                    
                    for(Product_Mapping__c pm: productMappingRecList){
                        if(pm.Legacy_Product__c!= NULL){
                            pmLegacyList.add(pm.Legacy_Product__r.ProductCode);
                            legacyProCombo.put(pm.Legacy_Product__r.ProductCode,pm.Dependent_Product__r.ProductCode);
                        }
                        if(pm.Legacy_Product__c!=NULL && pm.Replacement_Product__c!= NULL && pm.Action__c == 'Replace'){
                            productMap.put(pm.Legacy_Product__c,pm.Replacement_Product__c);
                            productCodeCopyMap.put(pm.Legacy_Product__r.ProductCode,pm.Replacement_Product__r.ProductCode);
                            pmRepleg.put(pm.Replacement_Product__r.ProductCode,pm.Legacy_Product__r.ProductCode);
                        }
                        if(pm.Legacy_Product__c != NULL && pm.Dependent_Product__c != NULL){
                            dependentProductMap.put(pm.Legacy_Product__r.ProductCode,pm.Dependent_Product__r.ProductCode);
                            legacyPro.put(pm.Dependent_Product__r.ProductCode,pm.Legacy_Product__r.ProductCode);
                            // dependent2Legacy.put(pm.Legacy_Product__r.ProductCode,pm.Dependent_Product__r.ProductCode);
                            prodCodetoProdId.put(pm.Dependent_Product__r.ProductCode,pm.Legacy_Product__c);                 
                            comboProductsList.add(pm.Dependent_Product__r.ProductCode);
                            comboProductsList.add(pm.Legacy_Product__r.ProductCode);                           
                            pmRepleg.put(pm.Replacement_Product__r.ProductCode,pm.Dependent_Product__r.ProductCode);
                        }
                        if(pm.Delete_Product__c){
                            delCMProMap.put(pm.Legacy_Product__r.ProductCode,pm.Delete_Product__c);
                        }
                        // GTMS-28388 : Create a map of free pricing for the replacement product
                        if(pm.Replacement_Product__c!= NULL && String.isNotBlank(pm.Free_Pricing__c)){
                            if(freePricingMap == null){
                                freePricingMap = new Map<String,String>();
                            }
                            freePricingMap.put(pm.Replacement_Product__r.ProductCode,pm.Free_Pricing__c);
                        }              
                        // GTMS-28388 : Create a map of additional products to add for the legacy product
                        if(pm.Legacy_Product__c != NULL && pm.Replacement_Product__c!= NULL && pm.Action__c == 'Add'){
                            if(!addOnsMap.containsKey(pm.Legacy_Product__r.ProductCode)){
                                addOnsMap.put(pm.Legacy_Product__r.ProductCode, new List<Product_Mapping__c>());
                            }
                            addOnsMap.get(pm.Legacy_Product__r.ProductCode).add(pm);
                        }
                    }
                    for(SBQQ__QuoteLine__c qlRec: qlLst){
                        System.debug('qlRec.SBQQ__Quote__r.SBQQ__Primary__c: '+qlRec.SBQQ__Quote__r.SBQQ__Primary__c);
                        qLineListPrice.put(qlRec.Id,qlRec.Monthly_Unit_Price__c);
                        if(qlRec.SBQQ__Quote__r.SBQQ__Primary__c != NULL){
                            SBQQ__Quote__c primaryQuoteRec = new SBQQ__Quote__c();
                            primaryQuoteRec.Id = qlRec.SBQQ__Quote__c;
                            primaryQuoteRec.SBQQ__Primary__c = false;
                            primaryQuoteRec.P_P_Pilot_Customer__c = True;
                            // GTMS-28388 : All renewals are FY26 P&P going forward
                            primaryQuoteRec.P_P_Customer_Type__c= 'FY26 P&P'; 
                            if(!primaryQuoteList.contains(primaryQuoteRec)){
                                primaryQuoteList.add(primaryQuoteRec);
                            }
                        }
                        if(quoteQLMap.containskey(qlRec.SBQQ__Quote__c)){
                            System.debug('containsKey: '+qlRec.SBQQ__Quote__c);
                            System.debug('value: '+qlRec.Product_Code_Copy__c);
                            quoteQLMap.get(qlRec.SBQQ__Quote__c).add(qlRec.Product_Code_Copy__c);
                            
                        }else{
                            System.debug('else: '+qlRec.SBQQ__Quote__c);
                            System.debug('else value: '+qlRec.Product_Code_Copy__c);
                            quoteQLMap.put(qlRec.SBQQ__Quote__c,new List<String>{qlRec.Product_Code_Copy__c});
                            
                        }
                        if(dependentProductMap.containsKey(qlRec.Product_Code_Copy__c)){
                            System.debug('if qlRec.Product_Code_Copy__c CM1-PRO: '+qlRec.Product_Code_Copy__c);
                            quotePROQLMap.put(qlRec.Product_Code_Copy__c,qlRec.SBQQ__Product__c);
                            proSKUDelMap.put(qlRec.Product_Code_Copy__c,qlRec);
                            
                        }
                        if(pmLegacyList.contains(qlRec.SBQQ__productCode__c)){
                            String qlIdPc = qlRec.Id +'-'+qlRec.SBQQ__productCode__c;
                            qlMUPMAP.put(qlIdPc,qlRec.Monthly_Unit_Price__c);
                        }
                        
                    }
                    
                    System.debug('pmLegacyList: '+pmLegacyList);
                    System.debug('dependentProductMap: '+dependentProductMap);
                    System.debug('qlMUPMAP Monthly Unit Price : '+qlMUPMAP);
                    System.debug('quoteQLMap: '+quoteQLMap);
                    System.debug('quotePROQLMap: '+quotePROQLMap);
                    System.debug('primaryQuoteList: '+primaryQuoteList);
                    try{
                        if(!primaryQuoteList.isEmpty()){
                            SBQQ.TriggerControl.disable();
                            update primaryQuoteList;
                            SBQQ.TriggerControl.enable();
                            for(SBQQ__Quote__c qteRec: primaryQuoteList){
                                Log__c logRec = new Log__c();
                                //logRec.Quote__c = qteRec;
                                logRec.ClassName__c = 'ContractRenewalQueueable';
                                logRec.Message__c = 'Quote Updated Successfully';
                                logList.add(logRec);
                            }
                        }
                    }catch(Exception ex){
                        Log__c logRec = new Log__c();
                        logRec.ExceptionMessage__c = ex.getMessage();
                        logRec.StackTrace__c = ex.getStackTraceString();
                        logRec.ClassName__c = 'ContractRenewalQueueable';
                        logList.add(logRec);
                        System.debug('Error Occured: '+ex.getMessage());
                    }  
                    
                    System.debug('try primaryQuoteList: '+primaryQuoteList);
                    System.debug('productMap: '+productMap);
                    System.debug('productCodeCopyMap: '+productCodeCopyMap);
                    
                    for(SBQQ__QuoteLine__c qlRec: qlLst){                       
                        if(pmLegacyList.contains(qlRec.Product_Code_Copy__c) && !productMap.isEmpty() && !productCodeCopyMap.isEmpty() && !dependentProductMap.containskey(qlRec.Product_Code_Copy__c)  && legacyProCombo.get(qlRec.Product_Code_Copy__c) == NULL && !quoteQLMap.get(qlRec.SBQQ__Quote__c).contains(legacyPro.get(qlRec.SBQQ__ProductCode__c))){
                            System.debug('No PRO SKU ZONE qlRec.Product_Code_Copy__c: '+qlRec.Product_Code_Copy__c);
                            System.debug('productCodeCopyMap.get(qlRec.Product_Code_Copy__c): '+productCodeCopyMap.get(qlRec.Product_Code_Copy__c));
                            System.debug('quoteQLMap.get(qlRec.SBQQ__Quote__c): '+quoteQLMap.get(qlRec.SBQQ__Quote__c));
                            System.debug('quoteRecordLine.Id: '+qlRec.Id);
                            SBQQ__QuoteLine__c quoteLineRecord = new SBQQ__QuoteLine__c();
                            quoteLineRecord.Id = qlRec.Id;
                            quoteLineRecord.SBQQ__Product__c = productMap.get(qlRec.SBQQ__Product__c);
                            quoteLineRecord.Product_Code_Copy__c = productCodeCopyMap.get(qlRec.Product_Code_Copy__c);

                            if(!upsertQuoteLineLst.contains(quoteLineRecord)){
                                upsertQuoteLineLst.add(quoteLineRecord);
                            }
                            if(!qlMUPList.contains(qlRec.Id)){
                                qlMUPList.add(qlRec.Id); 
                            }

                            // GTMS-28388 : Add additional products to the quote
                            if(addOnsMap.containsKey(qlRec.Product_Code_Copy__c)){
                                for(Product_Mapping__c addOnMapping: addOnsMap.get(qlRec.Product_Code_Copy__c)){
                                    System.debug('freeAddOn: '+addOnMapping.Replacement_Product__r.ProductCode);
                                    
                                    SBQQ__QuoteLine__c addOnRecord = new SBQQ__QuoteLine__c();
                                    addOnRecord.SBQQ__Quote__c = qlRec.SBQQ__Quote__c;
                                    addOnRecord.SBQQ__Product__c = addOnMapping.Replacement_Product__c;
                                    addOnRecord.Account__c = qlRec.SBQQ__Quote__r.SBQQ__Account__c;
                                    addOnRecord.Ship_To__c = qlRec.SBQQ__Quote__r.Shipping_Address_NEW__c;
                                    addOnRecord.Product_Code_Copy__c = addOnMapping.Replacement_Product__r.ProductCode;
                                    addOnRecord.SBQQ__Quantity__c = qlRec.SBQQ__Quantity__c;
                                    addOnRecord.SBQQ__RenewedSubscription__c = qlRec.SBQQ__RenewedSubscription__c; 
                                    addOnRecord.Previous_Quantity__c = qlRec.Previous_Quantity__c;

                                    upsertQuoteLineLst.add(addOnRecord);  
                                }
                            }  

                            System.debug('qlRec.SBQQ__Quote__c: '+qlRec.SBQQ__Quote__c);
                            if(!renewalQuoteList.contains(qlRec.SBQQ__Quote__c)){
                                renewalQuoteList.add(qlRec.SBQQ__Quote__c);
                            }                                                
                            System.debug('renewalQuoteList1: '+renewalQuoteList);
                        }if(pmLegacyList.contains(qlRec.Product_Code_Copy__c) && !quotePROQLMap.isEmpty() && !productMap.isEmpty() && !productCodeCopyMap.isEmpty() ){
                            System.debug('PRO SKU Zone quoteRecordLine.Id: '+qlRec.Id);
                            System.debug('qlRec.Product_Code_Copy__c*** '+qlRec.Product_Code_Copy__c);
                            System.debug('dependentProductMap.values().contains(qlRec.Product_Code_Copy__c): '+dependentProductMap.values().contains(qlRec.Product_Code_Copy__c));
                            System.debug('quoteQLMap.get(qlRec.SBQQ__Quote__c).contains(legacyPro.get(qlRec.Product_Code_Copy__c)): '+quoteQLMap.get(qlRec.SBQQ__Quote__c).contains(legacyPro.get(qlRec.Product_Code_Copy__c)));
                            System.debug('legacyProCombo.get(qlRec.Product_Code_Copy__c): '+legacyProCombo.get(qlRec.Product_Code_Copy__c));
                            if(comboProductsList.contains(qlRec.Product_Code_Copy__c) && dependentProductMap.values().contains(qlRec.Product_Code_Copy__c) && quoteQLMap.get(qlRec.SBQQ__Quote__c).contains(legacyPro.get(qlRec.Product_Code_Copy__c))){
                                System.debug('In CMX-CMX-ENT-PRO: '+qlRec.Product_Code_Copy__c + '-'+legacyPro.get(qlRec.Product_Code_Copy__c));
                                System.debug('QLID: '+qlRec.Id);
                                System.debug('Prod Code COPY: '+qlRec.Product_Code_Copy__c);
                                SBQQ__QuoteLine__c quoteLineRecord = new SBQQ__QuoteLine__c();
                                quoteLineRecord.Id = qlRec.Id;
                                quoteLineRecord.SBQQ__Product__c = productMap.get(quotePROQLMap.get(legacyPro.get(qlRec.Product_Code_Copy__c)));
                                quoteLineRecord.Product_Code_Copy__c = productCodeCopyMap.get(legacyPro.get(qlRec.Product_Code_Copy__c));
                                
                                if(!upsertQuoteLineLst.contains(quoteLineRecord)){
                                    upsertQuoteLineLst.add(quoteLineRecord);
                                }
                                if(!qlMUPList.contains(qlRec.Id)){
                                    qlMUPList.add(qlRec.Id); 
                                }
                                System.debug('upsertQuoteLineLst: '+upsertQuoteLineLst);
                                System.debug('upsertQuoteLineLst.size(): '+upsertQuoteLineLst.size());
                                if(!renewalQuoteList.contains(qlRec.SBQQ__Quote__c)){
                                    renewalQuoteList.add(qlRec.SBQQ__Quote__c);
                                } 
                            }
                            if(comboProductsList.contains(qlRec.Product_Code_Copy__c) && legacyProCombo.get(qlRec.Product_Code_Copy__c) != NULL && dependentProductMap.keySet().contains(qlRec.SBQQ__ProductCode__c)){
                                System.debug('qlRec.SBQQ__Quote__r.P_P_Pilot_Customer__c: '+qlRec.SBQQ__Quote__r.P_P_Pilot_Customer__c);
                                System.debug('pmLegacyList.contains(qlRec.Product_Code_Copy__c): '+pmLegacyList.contains(qlRec.Product_Code_Copy__c));
                                System.debug('productMap.isEmpty(): '+productMap.isEmpty());
                                System.debug('productCodeCopyMap.isEmpty(): '+productCodeCopyMap.isEmpty());                                
                                if(!qlDelList.contains(qlRec) && quoteQLMap.get(qlRec.SBQQ__Quote__c).contains(dependentProductMap.get(qlRec.Product_Code_Copy__c))){
                                    qlDelList.add(qlRec);
                                    
                                } 
                            }
                            
                        }
                        
                    }
                    System.debug('qlMUPList1: '+qlMUPList);
                    List<SBQQ__QuoteLine__c> delQuoteLineLst = new List<SBQQ__QuoteLine__c>();
                    if(qlDelList.size()>0){
                        for(SBQQ__QuoteLine__c delQLRec: qlDelList){
                            System.debug('delQLRec.SBQQ__ProductCode__c: '+delQLRec.SBQQ__ProductCode__c);
                            System.debug('delCMProMap.get(delQLRec.SBQQ__ProductCode__c): '+delCMProMap.get(delQLRec.SBQQ__ProductCode__c));
                            if(delCMProMap.get(delQLRec.SBQQ__ProductCode__c)){
                                delQuoteLineLst.add(delQLRec);
                            }
                        }
                        System.debug('Update delQuoteLineLst: '+delQuoteLineLst);
                    }
                    
                    System.debug('qlMUPList.size(): '+qlMUPList.size());
                    System.debug('qlMUPList: '+qlMUPList);
                    System.debug('qlDelList.size(): '+qlDelList.size());
                    System.debug('qlDelList: '+qlDelList);
                    System.debug('renewalQuoteList2: '+renewalQuoteList);
                    try{
                        if(upsertQuoteLineLst.size()>0 && !upsertQuoteLineLst.isEmpty()){
                            System.debug('Upsert QuoteLine: ');
                            SBQQ.TriggerControl.disable();
                            upsert upsertQuoteLineLst;                         
                            SBQQ.TriggerControl.enable();
                            System.debug('Upserted QL: '+upsertQuoteLineLst);
                            
                            // GTMS-28388 : Re-add line ids to qlMUPList after upsert
                            for(SBQQ__QuoteLine__c qlRec: upsertQuoteLineLst){ 
                                if(!qlMUPList.contains(qlRec.Id)){
                                    qlMUPList.add(qlRec.Id); 
                                }
                            }
                            System.debug('qlMUPList.size() post upsert: '+qlMUPList.size());
                            System.debug('qlMUPList post upsert: '+qlMUPList);
                        }
                        if(delQuoteLineLst.size()>0 && !delQuoteLineLst.isEmpty()){
                            System.debug('Update delQuoteLineLst: '+delQuoteLineLst);
                            SBQQ.TriggerControl.disable();
                            delete delQuoteLineLst;
                            SBQQ.TriggerControl.enable();
                            
                        }
                        System.debug('upsertQuoteLineLst: '+upsertQuoteLineLst);
                        
                        System.debug('renewalQuoteList3: '+renewalQuoteList);
                        if(!upsertQuoteLineLst.isEmpty() && !renewalQuoteList.isEmpty()){
                            System.debug('RefreshPrice IF: ');
                            if(!Test.isRunningTest()){
                                ID jobID = System.enqueueJob(new ContractRenewalQueueable('RefreshPrice',this.conRecLst,renewalQuoteList,qlMUPList,qLineListPrice,pmRepleg,freePricingMap),2);
                            }
                        } 
                    }catch(Exception ex){
                        System.debug(ex.getMessage().subStringAfter(';'));
                        Log__c logRec = new Log__c();
                        logRec.ExceptionMessage__c = ex.getMessage();
                        logRec.StackTrace__c = ex.getStackTraceString();
                        logRec.ClassName__c = 'ContractRenewalQueueable';
                        logList.add(logRec);
                        
                        System.debug('Error Occured: '+ex.getMessage());
                    }
                    if(logList.size()>0){
                        insert logList;
                    }
                    System.debug('End of New Action: '); 
                }
                when 'RefreshPrice'{
                    
                    System.debug('this.qlMUPList: '+this.quoteLineId);
                    System.debug('this.qlMUPMAP: '+this.mupQLList);
                    System.debug('this.pmReplace2Legacy: '+this.pmReplace2Legacy);
                    System.debug('renewalQuoteList4: '+this.quoteList);
                    System.debug('this.conRecLst: '+this.conRecLst);
                    System.debug('this.quoteList: '+this.quoteList.isEmpty());
                    if(!this.quoteList.isEmpty()){
                        
                        Set<Id> renewalQuoteSet = new Set<Id>(this.quoteList);
                        System.debug('renewalQuoteSet: '+renewalQuoteSet);
                        if(!Test.isRunningTest()){
                            SBQQ.QuotePriceRefreshBatch qPRB = new SBQQ.QuotePriceRefreshBatch(SBQQ__Quote__c.sObjectType,renewalQuoteSet);
                            Database.executeBatch(qPRB,1);
                        }
                        integer waitTime = (this.quoteList.size()*60)/60+3;
                        System.debug('WaitTime: '+waitTime);
                        
                        if(!Test.isRunningTest()){
                            ID jobID = System.enqueueJob(new ContractRenewalQueueable('Discounting',this.conRecLst,this.quoteList,this.quoteLineId,this.mupQLList,this.pmReplace2Legacy,this.freePricingMap),waitTime);  
                        }
                        
                    }    
                }
                when 'Discounting'{
                    System.debug('this.qlMUPList: '+this.mupQLList);
                    List<SBQQ__QuoteLine__c> quoteLineRecList = [ SELECT ID, SBQQ__Quote__c, SBQQ__Quote__r.SBQQ__Primary__c, Monthly_Unit_Price__c, SBQQ__ListPrice__c, SBQQ__Discount__c, SBQQ__AdditionalDiscountAmount__c, SBQQ__Quote__r.SBQQ__Opportunity2__r.SBQQ__RenewedContract__c, SBQQ__Quote__r.SBQQ__Account__c, SBQQ__Quote__r.Associated_Opportunity_Type__c, SBQQ__Quote__r.SBQQ__Account__r.P_P_Pilot_Customer__c, SBQQ__Quote__r.P_P_Pilot_Customer__c, SBQQ__Quote__r.SBQQ__Account__r.P_P_Customer_Type__c, SBQQ__Quote__r.P_P_Customer_Type__c, SBQQ__ProductCode__c, Product_Code_Copy__c, SBQQ__Product__c, SBQQ__Product__r.ProductCode, SBQQ__Quote__r.Shipping_Address_NEW__c, SBQQ__RenewedSubscription__c, Previous_Quantity__c FROM SBQQ__QuoteLine__c WHERE ID IN :this.quoteLineId ];
                    
                    Map<String,Decimal> newQLMUPMap = new Map<String,Decimal>();
                    List<SBQQ__QuoteLine__c> updateQLMUPList = new List<SBQQ__QuoteLine__c>();
                    for(SBQQ__QuoteLine__c qlRec: quoteLineRecList){
                        Boolean updateQL = false;
                        SBQQ__QuoteLine__c ql = new SBQQ__QuoteLine__c();
                        ql.Id = qlRec.id;

                        // GTMS-28388 : Don't auto add discount if the new unit price is not set for 'Add' action
                        if(this.mupQLList.containsKey(qlRec.Id) && this.mupQLList.get(qlRec.Id) != null){
                            Decimal newUnitPrice = qlRec.SBQQ__ListPrice__c/12;
                            Decimal amountDiscount = (1-(this.mupQLList.get(qlRec.Id)/newUnitPrice))*100;
                            ql.SBQQ__Discount__c = amountDiscount;
                            ql.SBQQ__AdditionalDiscountAmount__c = null;
                            updateQL = true;
                        }
                        
                        // GTMS-28388 : Apply free pricing if configured
                        if(this.freePricingMap != null && this.freePricingMap.containsKey(qlRec.Product_Code_Copy__c)){
                            String pricingType = this.freePricingMap.get(qlRec.Product_Code_Copy__c);
                            if(pricingType == 'Zero List Price'){
                                ql.SBQQ__ListPrice__c = 0;
                                ql.SBQQ__Discount__c = null; // Reset discount since list price is zero
                            } else if(pricingType == '100% Discount'){
                                ql.SBQQ__Discount__c = 100; // Override the calculated discount
                            }
                            updateQL = true;
                        }
                        
                        if(updateQL){
                            updateQLMUPList.add(ql);
                        }
                    }
                    
                    if(updateQLMUPList.size()>0 && !updateQLMUPList.isEmpty()){
                        System.debug('Update updateQLMUPList: ');
                        SBQQ.TriggerControl.disable();
                        Database.update(updateQLMUPList,false);                         
                        SBQQ.TriggerControl.enable();
                        System.debug('Updated QL: '+updateQLMUPList);
                        if(!Test.isRunningTest()){
                            ID jobID = System.enqueueJob(new ContractRenewalQueueable('Recalculate',this.conRecLst,this.quoteList,NULL,NULL,NULL,NULL),2);
                        }
                    }
                    
                    
                }
                when 'Recalculate'{
                    System.debug('I am in Recalculate Action: ');
                    System.debug('renewalQuoteList: '+this.quoteList);
                    System.debug('this.quoteList: '+this.quoteList.isEmpty());
                    List<SBQQ__QuoteLine__c> quoteLineList = [SELECT ID,SBQQ__Quote__c,SBQQ__Quote__r.SBQQ__Primary__c,SBQQ__Quote__r.SBQQ__Opportunity2__r.SBQQ__RenewedContract__c,SBQQ__Quote__r.SBQQ__Account__c,SBQQ__Quote__r.SBQQ__Account__r.P_P_Pilot_Customer__c,SBQQ__Quote__r.P_P_Pilot_Customer__c  ,SBQQ__Quote__r.SBQQ__Account__r.P_P_Customer_Type__c,SBQQ__Quote__r.P_P_Customer_Type__c,SBQQ__ProductCode__c ,Product_Code_Copy__c ,SBQQ__Product__c FROM SBQQ__QuoteLine__c WHERE SBQQ__Quote__c IN :this.quoteList];
                    System.debug('quoteLineList: '+quoteLineList);
                    System.debug('quoteLineList Empty Check: '+quoteLineList.isEmpty());
                    if(!this.quoteList.isEmpty() && !quoteLineList.isEmpty()){
                        System.debug('Recalculate If not isEmpty: ');
                        if(!Test.isRunningTest()){
                            ContractRenewalBatch contractRenBatch = new ContractRenewalBatch(quoteLineList,this.quoteList);
                            Database.executeBatch(contractRenBatch,1);
                        }
                    }
                }
                
            }
        }else{
            System.debug('Maximum stack depth reached. Exiting to prevent stack overflow.');
        }
    }
}