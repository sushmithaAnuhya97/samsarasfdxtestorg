/**********************************************************************
Name: ContractSubscriptionRollupBatch
Test Class: ContractSubscriptionRollupBatchTest

=======================================================================
Purpose: This batch job rollups quantity count based on productcode of a Subscription record.                                                            

=======================================================================
History  

VERSION     AUTHOR               DATE                 DETAIL                       
1.0        Abu Saleh Khan       01/11/2024        INITIAL DEVELOPMENT 
***************************************************************************************************************************************/    

global class ContractSubscriptionRollupBatch implements Database.Batchable<sObject>,Database.Stateful{
    public static Map<String,String> prodCodeValues = new Map<String,String>();
    public static Decimal agCount=0;
    public static Decimal vgCount=0;
    public static Decimal scCount=0;
    public static Decimal cmCount=0;
    
    global Database.QueryLocator start(Database.BatchableContext BC) {        
        //String query = 'SELECT ID,SBQQ__Contract__c,SBQQ__Contract__r.ContractNumber,SBQQ__Quantity__c,SBQQ__Product__c,SBQQ__Product__r.ProductCode FROM SBQQ__Subscription__c WHERE SBQQ__Contract__r.LastModifiedDate = TODAY';
        System.debug('In Start Method: ');
        return Database.getQueryLocator(System.Label.ContractRollupQuery );
        //return Database.getQueryLocator(query);
    }
    global void execute(Database.BatchableContext BC, List<contract> contractList) {   
        System.debug('contractList: '+contractList);
        System.debug('contractList Size: '+contractList.size());
        Map<Id,List<SBQQ__Subscription__c>> subContractMap = new Map<Id,List<SBQQ__Subscription__c>>();
        List<Contract> updateContractList = new List<Contract>();
        Sobject contract_Record;
        List<Id> contractId = new List<Id>();
        String vgProdCode = Subscription_Product_Code__mdt.getInstance('VG_License').Starts_with__c;
        String agProdCode = Subscription_Product_Code__mdt.getInstance('AG_License').Starts_with__c;
        String scProdCode = Subscription_Product_Code__mdt.getInstance('SC_License').Starts_with__c;
        String cmProdCode = Subscription_Product_Code__mdt.getInstance('CM_License').Starts_with__c;
        getMetadataValues();
        for (contract con:contractList) {
               contractId.add(con.Id);               
        } 
        
        for (SBQQ__Subscription__c sub : [SELECT ID,SBQQ__Contract__c,Name,SBQQ__Contract__r.ContractNumber,SBQQ__Quantity__c,SBQQ__Product__c,SBQQ__Product__r.ProductCode FROM SBQQ__Subscription__c WHERE SBQQ__Contract__c =:contractId ]) {
            System.debug('Sub: '+sub);
            
            if(!subContractMap.containsKey(sub.SBQQ__Contract__c)){
                subContractMap.put(sub.SBQQ__Contract__c,new List<SBQQ__Subscription__c>{sub});
                System.debug('subContractMap: '+subContractMap);
            }else{
                subContractMap.get(sub.SBQQ__Contract__c).add(sub);
                System.debug('subContractMap1: '+subContractMap);
            }            
        }        
        for(Id conId:subContractMap.keySet()){
            System.debug('conId: '+conId);
            contract_Record = new Contract();
            System.debug('contract_Record Initiation: '+contract_Record);
            if(contract_Record.get(Schema.Contract.Id)!=conId){
                System.debug('in IF: ');
                contract_Record.put('Id',conId);
            }
            agCount=0;
            vgCount=0;
            scCount=0;
            cmCount=0;
            system.debug('vgProdCode:'+vgProdCode);
            system.debug('agProdCode:'+agProdCode);
            system.debug('scProdCode:'+scProdCode);
            system.debug('cmProdCode:'+cmProdCode);
            for(SBQQ__Subscription__c sub:subContractMap.get(conId)){                
                String prodCode = processProdCode(sub.SBQQ__Product__r.ProductCode);
                System.debug('prodCode: '+prodCode);                
                System.debug('contract_Record: '+contract_Record);    
                system.debug('outside for&&&&&&&');
                System.debug('outeragCount: '+agCount);
                System.debug('outer vgCount: '+vgCount);
                System.debug('outer scCount: '+scCount);
                System.debug('outer cmCount: '+cmCount);
                if(prodCodeValues.keySet().size()>0 && prodCodeValues.containsKey(prodCode)){
                    System.debug('prodCode: '+prodCode);
                    System.debug('prodCodeValues.containsKey(prodCode): '+prodCodeValues.containsKey(prodCode));
                    System.debug('prodCodeValues.get(prodCode): '+prodCodeValues.get(prodCode));
                    System.debug('sub.Id: '+sub.Id);
                    System.debug('sub.Name: '+sub.Name);
                     System.debug('sub.SBQQ__Quantity__c: '+sub.SBQQ__Quantity__c);
                    
                            if(prodCodeValues.containsKey(prodCode) && vgProdCode == prodCode){
                                vgCount = vgCount+sub.SBQQ__Quantity__c;
                                contract_Record.put(prodCodeValues.get(prodCode),vgCount);
                            }
                            if(prodCodeValues.containsKey(agProdCode) && agProdCode == prodCode){
                                agCount = agCount+sub.SBQQ__Quantity__c;
                                contract_Record.put(prodCodeValues.get(prodCode),agCount);
                            }                            
                            if(prodCodeValues.containsKey(scProdCode) && scProdCode == prodCode){
                                scCount = scCount+sub.SBQQ__Quantity__c;
                                contract_Record.put(prodCodeValues.get(prodCode),scCount);
                            }
                             if(prodCodeValues.containsKey(cmProdCode) && cmProdCode == prodCode){ 
                                cmCount = cmCount+sub.SBQQ__Quantity__c;
                                contract_Record.put(prodCodeValues.get(prodCode),cmCount);
                            }
                            system.debug('inside for*************');
                            System.debug('inner agCount: '+agCount);
                            System.debug('inner vgCount: '+vgCount);
                            System.debug('inner scCount: '+scCount);
                            System.debug('inner cmCount: '+cmCount);
                            System.debug('inner contract_Record1: '+contract_Record);
                        
                }
                
            }
            updateContractList.add((Contract)contract_Record);
            
        }
        try{
            system.debug('updateContractList:'+updateContractList);
            if(!updateContractList.isEmpty()){
                Database.update(updateContractList,false);
            }
        }catch(Exception ex){
            System.debug('The Exception occured in ContractSubscriptionRollupBatch class ex line >>> ' + ex.getLineNumber()
                         + ' ex message >>> ' + ex); 
        } 
    }
    global void finish(Database.BatchableContext BC) {        
    }
    public String processProdCode (String ProCode){
        SYSTEM.DEBUG('ProCode^^^:'+ProCode);
        String FinalStr = '';
        String Prodcode = ProCode;
        String s1 = Prodcode.substringBefore ('-');
        system.debug('S1>>>> ' + s1);
        String s2 =  Prodcode.substringAfter ('-');
        system.debug('S2>>>> ' + s2);
        String s3 = s2.substringBefore ('-').left(2);
        //String s4 =  
        system.debug('S3>>>> ' + s3);
        FinalStr = s1 + '-' + s3;
        system.debug('FinalS >>>>' + FinalStr);
        return FinalStr;
    }
    public static Void getMetadataValues(){
        Map<String,Contract_Rollup__mdt> val =  Contract_Rollup__mdt.getall();
        system.debug('val>>>> ' + val);
        for(Contract_Rollup__mdt cr: val.values()){
            prodCodeValues.put(cr.Name__c, cr.Value__c);
        }
    }
}