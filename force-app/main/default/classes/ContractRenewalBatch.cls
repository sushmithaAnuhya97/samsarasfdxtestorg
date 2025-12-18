/**
* Created by Abu Saleh Khan on 01-02-2025.
Test Class: ContractRenewalQueueableTest
*/
public class ContractRenewalBatch implements Database.Batchable<SObject>{
    public List<SBQQ__QuoteLine__c> qlRecList;
    public List<Id> renewQuoteIdList;
    public List<Product_Mapping__c> productMappingRecList = new List<product_Mapping__c>();
    public List<SBQQ__Quote__c> primaryQuoteRecList = new List<SBQQ__Quote__c>();
    public List<Contract> contractRenewList = new List<Contract>();
    public MAP<Id,Id> contractRenewalOppoList = new Map<Id,Id>();
    public List<SBQQ__Quote__c> recalculateQuoteRecList = new List<SBQQ__Quote__c>();
    public MAP<String,String> productMap = new Map<String,String>();
    public Map<String,String> productCodeCopyMap = new Map<String,String>();
    public List<String> pmLegacyList = new List<String>();
    public ContractRenewalBatch(List<SBQQ__QuoteLine__c> qlRecList, List<Id> renewQuoteIdList){
        this.qlRecList = qlRecList;
        this.renewQuoteIdList = renewQuoteIdList;
    }
    public Database.QueryLocator start(Database.BatchableContext BC){
        
        System.debug('this.renewQuoteIdList: ' + renewQuoteIdList); 
        return Database.getQueryLocator(System.Label.QueryQuoteRecalculate );   
    }
    public void execute(Database.BatchableContext BC,List<SBQQ__Quote__c> scope ){
        
        if(!Scope.isEmpty() && Scope != NULL){
            System.debug('this.qlRecList1: ' + this.qlRecList); 
            System.debug('this.renewQuoteIdList: ' + this.renewQuoteIdList); 
            for(SBQQ__Quote__c qrec: scope){
                List<String> quoteRecids = new List<String>();
                if(!quoteRecids.contains(qrec.Id)){
                    SBQQ__Quote__c recalQuote = new SBQQ__Quote__c(Id = qrec.Id,Recalculate_Quote__c = True);  
                    recalculateQuoteRecList.add(recalQuote); 
                }
                
            }
            System.debug('recalculateQuoteRecList: ' + recalculateQuoteRecList); 
            try{
                Database.Update(recalculateQuoteRecList,false);  
            }catch(Exception ex){
                System.debug('Error updating quotes: ' + ex.getMessage()); 
            }
            productMappingRecList = [SELECT ID, Legacy_Product__c,Legacy_Product__r.ProductCode ,Replacement_Product__c,Replacement_Product__r.ProductCode,Action__c,Free_Pricing__c FROM Product_Mapping__c WHERE Active__c = true];
            List<SBQQ__QuoteLine__c> quoteLinesUnchangedList = [SELECT ID,Product_Code_Copy__c,SBQQ__Product__c,SBQQ__Quote__r.SBQQ__Opportunity2__r.SBQQ__RenewedContract__c,SBQQ__Quote__r.SBQQ__Opportunity2__c FROM SBQQ__QuoteLine__c WHERE SBQQ__Quote__c IN :renewQuoteIdList];
            System.debug('productMappingRecList: '+productMappingRecList);
            for(Product_Mapping__c pm: productMappingRecList){
                if(pm.Legacy_Product__c!= NULL){
                    pmLegacyList.add(pm.Legacy_Product__r.ProductCode);
                    
                }
                
            }
            for(SBQQ__QuoteLine__c qlrecc: quoteLinesUnchangedList){
                System.debug('qlrecc.Product_Code_Copy__c: '+qlrecc.Product_Code_Copy__c);
            }
            System.debug('pmLegacyList: '+pmLegacyList);
            for(SBQQ__QuoteLine__c qlRec: quoteLinesUnchangedList){
                System.debug('qlRec.Product_Code_Copy__c: '+qlRec.Product_Code_Copy__c);
                System.debug('qlRec.SBQQ__Quote__r.SBQQ__Opportunity2__c: '+qlRec.SBQQ__Quote__r.SBQQ__Opportunity2__c);
                System.debug('qlRec.SBQQ__Quote__r.SBQQ__Opportunity2__r.SBQQ__RenewedContract__c: '+qlRec.SBQQ__Quote__r.SBQQ__Opportunity2__r.SBQQ__RenewedContract__c);
                System.debug('pmLegacyList.contains(qlRec.Product_Code_Copy__c): '+pmLegacyList.contains(qlRec.Product_Code_Copy__c));
                if(pmLegacyList.contains(qlRec.Product_Code_Copy__c) && qlRec.SBQQ__Quote__r.SBQQ__Opportunity2__c != NULL && qlRec.SBQQ__Quote__r.SBQQ__Opportunity2__r.SBQQ__RenewedContract__c != NULL){
                    contractRenewalOppoList.put(qlRec.SBQQ__Quote__r.SBQQ__Opportunity2__r.SBQQ__RenewedContract__c,qlRec.SBQQ__Quote__r.SBQQ__Opportunity2__c); 
                }
            }
            System.debug('this.qlRecList: '+this.qlRecList);
            System.debug('contractRenewalOppoList: '+contractRenewalOppoList);
            for(Id conId: contractRenewalOppoList.keySet()){
                Contract conRecId = new Contract();
                conRecId.Id = conId;
                conRecId.SBQQ__RenewalOpportunity__c = contractRenewalOppoList.get(conId);
                contractRenewList.add(conRecId);
            }
            System.debug('contractRenewList: '+contractRenewList);
            if(!contractRenewList.isEmpty() && contractRenewList.size()>0){
                System.debug('In if ContractRenewList is not empty: ');
                
                ID jobID = System.enqueueJob(new ContractRenewalQueueable('New',contractRenewList,NULL,NULL,NULL,NULL,NULL));
                
            } 
        }
    }
    public void finish(Database.BatchableContext BC){
        
    }
}