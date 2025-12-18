public without sharing class C360CreatorBatch implements Schedulable, Database.Batchable<sObject> {

    public integer batchSize = 50;
    private string query = 'SELECT Id, CurrencyIsoCode, Book_Of_Business__c,C360_Processed__c, Excluded_From_C360__c, (SELECT Id FROM Customer_360_Staging__r) FROM Account';
    private string defaultFilter = ' Where Id in (SELECT AccountId FROM Contract where StartDate <= TODAY AND EndDate >= TODAY AND Is_Active__c = true AND RecordTypeName__c != \'Free Trial\') AND C360_Processed__c = false and Excluded_From_C360__c = false';
    private string filterCriteria;
    private map<String, String> productCodeToC360Mapping {get{

            if(productCodeToC360Mapping != null) {return productCodeToC360Mapping;}

            productCodeToC360Mapping = new map<String, String>();

            for(Opportunity_Product_Code__mdt mtdRec :Opportunity_Product_Code__mdt.getall().values()){

                if(!mtdRec.Is_Checked__c && mtdRec.Is_Active__c){
                    productCodeToC360Mapping.put(mtdRec.Name__c, mtdRec.Value__c);
                }
            }

            return productCodeToC360Mapping;
        } set;
    }

    public C360CreatorBatch(){}
    
    public C360CreatorBatch(String filterCriteria){
        this.filterCriteria = filterCriteria;
    }

    public void execute(SchedulableContext sc){
        Database.executeBatch(new C360CreatorBatch(), batchSize);
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {

        if(String.isNotBlank(filterCriteria)){return Database.getQueryLocator(query+' '+defaultFilter + ' and '+filterCriteria);}

        Automation_Settings__c directorSetting = Automation_Settings__c.getValues('C360 Director Ids');

        String directorIds = directorSetting?.Data__c;

        if(String.isBlank(directorIds) && directorSetting.disabled__c){return Database.getQueryLocator(query +' '+defaultFilter+ ' AND Id = null');}
        
        if(!directorSetting.disabled__c){return Database.getQueryLocator(query+ ' '+ defaultFilter);}

        directorIds = '(\''+directorIds.replaceAll(',','\',\'')+'\')'; //Coma separated director Ids, within braces

        query += ' WHERE (OwnerId in '+directorIds; //HIERARCHY LEVEL - 1
        query += ' OR Owner.ManagerId in '+directorIds; //HIERARCHY LEVEL - 2
        query += ' OR Owner.Manager.ManagerId in '+directorIds; //HIERARCHY LEVEL - 3
        query += ' OR Owner.Manager.Manager.ManagerId in '+directorIds; //HIERARCHY LEVEL - 4
        query += ' OR Owner.Manager.Manager.Manager.ManagerId in '+directorIds+')'; //HIERARCHY LEVEL - 5
        
        return test.isRunningTest() ? Database.getQueryLocator(query) : Database.getQueryLocator(query+' '+defaultFilter.replaceFirst('Where', ' and '));
    }

    public void execute(Database.BatchableContext bc, List<sObject> recordList) {
        
        Map<Id,Account> accMap = new Map<Id,Account>();

        List<Customer_360_Staging__c> c360ToUpsert = new List<Customer_360_Staging__c>();
        Map<Id,Customer_360_Staging__c> accIdToC360StagingMap = new Map<Id,Customer_360_Staging__c>();
        Customer_360__c c360Rec;

        Account acc;
        // List<Account> accListToProcess = new List<Account>();

        for(sObject rec :recordList){

            acc = (Account) rec;

            if(acc.C360_Processed__c || acc.Excluded_From_C360__c){continue;}
            
            // accListToProcess.add(new Account(Id = acc.Id));

            accMap.put(acc.Id, acc);

            for(Customer_360_Staging__c existing360StagingRec :accMap.get(acc.Id).Customer_360_Staging__r){
                // existing360Rec.SOT__c = false; //Mark existing Customer 360's Source of Truth as false
                accIdToC360StagingMap.put(acc.Id, existing360StagingRec);
            }
        }

        Map<Id,List<Opportunity>> accIdToOppsMap = new Map<Id,List<Opportunity>>();
        Map<Id,List<OpportunityLineItem>> accIdToOptLinesMap = new Map<Id,List<OpportunityLineItem>>();
        

        List<Opportunity> oppRenewalList = new List<Opportunity>([SELECT Id, Payment_Terms__c, First_Purchase__c, Renewal__c, AccountId, 
                                                            (SELECT Id, ProductCode, SBQQ__QuoteLine__r.SBQQ__TotalDiscountRate__c, Monthly_Unit_Price__c FROM OpportunityLineItems ORDER BY SBQQ__QuoteLine__r.SBQQ__TotalDiscountRate__c) 
                                                            FROM Opportunity 
                                                            WHERE StageName = 'Closed Won' 
                                                            AND Type = 'Revenue Opportunity'
                                                            AND (SBQQ__RenewedContract__c != null OR SBQQ__Renewal__c = true) 
                                                            AND Id in (SELECT SBQQ__Opportunity__c FROM Contract WHERE Is_Active__c = true
                                                                                                                    AND StartDate <= TODAY 
                                                                                                                    AND EndDate >= TODAY
                                                                                                                    AND AccountId in :accMap.keySet())
                                                            AND AccountId in :accMap.keySet()
                                                            ORDER BY CloseDate DESC]);
        Set<Id> renewalOptyIds = new Set<Id>();
        

        // Amendements and the first opportunity
        List<Opportunity> oppAmendmentList = new List<Opportunity>([SELECT Id, Payment_Terms__c, First_Purchase__c, Renewal__c, AccountId, 
                                                            (SELECT Id, OpportunityId, ProductCode, SBQQ__QuoteLine__r.SBQQ__TotalDiscountRate__c, Monthly_Unit_Price__c FROM OpportunityLineItems ORDER BY SBQQ__QuoteLine__r.SBQQ__TotalDiscountRate__c) 
                                                            FROM Opportunity 
                                                            WHERE StageName = 'Closed Won' 
                                                            AND Type = 'Revenue Opportunity'
                                                            AND ((SBQQ__AmendedContract__r.StartDate  <= TODAY 
                                                                AND SBQQ__AmendedContract__r.EndDate >= TODAY 
                                                                AND SBQQ__AmendedContract__r.Is_Active__c = true)
                                                            OR (SBQQ__PrimaryQuote__r.SBQQ__MasterContract__r.StartDate  <= TODAY 
                                                                AND SBQQ__PrimaryQuote__r.SBQQ__MasterContract__r.EndDate >= TODAY 
                                                                AND SBQQ__PrimaryQuote__r.SBQQ__MasterContract__r.Is_Active__c = true)
                                                            OR (SBQQ__PrimaryQuote__r.Co_Term_Contract__r.StartDate  <= TODAY 
                                                                AND SBQQ__PrimaryQuote__r.Co_Term_Contract__r.EndDate >= TODAY 
                                                                AND SBQQ__PrimaryQuote__r.Co_Term_Contract__r.Is_Active__c = true)
                                                            OR (SBQQ__AmendedContract__c = null AND SBQQ__PrimaryQuote__r.SBQQ__MasterContract__c = null AND SBQQ__PrimaryQuote__r.Co_Term_Contract__c = null and SBQQ__PrimaryQuote__c != null
                                                                AND (SBQQ__Renewal__c = false OR SBQQ__RenewedContract__c = null)))
                                                            AND AccountId in :accMap.keySet()                                                        
                                                            ORDER BY CloseDate]);
                                                                
        Set<Id> amendedOptyIds = new Set<Id>();
        
        for(Opportunity opp :oppRenewalList){

            renewalOptyIds.add(opp.Id);
            
            if(!accIdToOppsMap.containsKey(opp.AccountId)){
                accIdToOppsMap.put(opp.AccountId, new list<Opportunity>());
                accIdToOptLinesMap.put(opp.AccountId, new list<OpportunityLineItem>());
            }
                
            accIdToOppsMap.get(opp.AccountId).add(opp);
            accIdToOptLinesMap.get(opp.AccountId).addAll(opp.OpportunityLineItems);
        }
        
        for(Opportunity opp :oppAmendmentList){
            
            amendedOptyIds.add(opp.Id);

            if(!accIdToOppsMap.containsKey(opp.AccountId)){
                accIdToOppsMap.put(opp.AccountId, new list<Opportunity>());
                accIdToOptLinesMap.put(opp.AccountId, new list<OpportunityLineItem>());
            }
                
            accIdToOppsMap.get(opp.AccountId).add(opp);
            accIdToOptLinesMap.get(opp.AccountId).addAll(opp.OpportunityLineItems);
        }

        try {

            for(Id accRecId :accIdToOppsMap.keySet()){ //Change the logic to iterator over closed won opty map
                
                if(!accIdToC360StagingMap.containsKey(accRecId))accIdToC360StagingMap.put(accRecId, new Customer_360_Staging__c(Account__c = accRecId, CurrencyIsoCode = accMap.get(accRecId).CurrencyIsoCode));

                //Populate Header Data of a Customer 360 record related to a single account
                populateHeaderData(accMap.get(accRecId), accIdToOppsMap.get(accRecId), accIdToOptLinesMap.get(accRecId), accIdToC360StagingMap.get(accRecId));

                //Populate Discounts & MUPs
                populateDiscountAndMUP(accIdToOppsMap.get(accRecId), accIdToC360StagingMap.get(accRecId), renewalOptyIds, amendedOptyIds);

                c360ToUpsert.add(accIdToC360StagingMap.get(accRecId));
            }

            upsert c360ToUpsert;
            // update accListToProcess;

        } catch (Exception ex) {

            logException(ex);
        }
    }

    public void finish(Database.BatchableContext bc) {
       
    }

    private void populateHeaderData(Account acc, List<Opportunity> oppList, List<OpportunityLineItem> oppLines, Customer_360_Staging__c c360StagingRec){

        //Copied from Original source
        //Populate Hide_Licenses_in_Webstore__c
        // if(String.isNotBlank(acc.Book_Of_Business__c)){
        //     c360StagingRec.Hide_Licenses_in_Webstore__c = true; // When there is book of business field data in account make it true.
        // }

        //Using newly built formula field, no longer required to populate
        // for(Opportunity opp :oppList){

        //     if((opp.First_Purchase__c || opp.Renewal__c)){
        //         c360StagingRec.Payment_Terms__c = opp.Payment_Terms__c;
        //     }
        // }
        
        boolean ppPilotHeaderPassed = false;
        boolean vgHeaderPassed = false;
        boolean cmHeaderPassed = false;
        boolean pltFmHeaderPassed = false;
        boolean licTagHeaderPass = false;
        boolean licVgBasicHeaderPass = false; //LIC-VG-BASIC Header - hard coded, no reference requried.
        boolean licVgENTHeaderPass = false; //LIC-VG-ENT Header - hard coded, no reference requried.
        boolean licCM1ProHeaderPass = false;
        boolean licCM2ProHeaderPass = false;
        boolean licPltfmProHeaderPass = false;
        boolean licVGProHeaderPass = false;
        map<string, string> cmVgTierMap = new map<string, string>();


        for(OpportunityLineItem oppLine :oppLines){

            if(oppLine.ProductCode.endsWith('PLTFM-ESS') || oppLine.ProductCode.endsWith('PLTFM-PREM') && !ppPilotHeaderPassed){

                c360StagingRec.P_P_Pilot_Customer__c = ppPilotHeaderPassed = true;
            }

            if(!cmHeaderPassed || !vgHeaderPassed){
                if(!cmVgTierMap.containsKey(oppLine.ProductCode) && (oppLine.ProductCode.contains('LIC-VG-') || oppLine.ProductCode.contains('LIC-CM-'))) cmVgTierMap.put(oppLine.ProductCode, new OpptyLineitemDiscountBatch().cmVgTierRegexMatcher(oppLine.ProductCode));

                if(oppLine.ProductCode.contains('LIC-VG-') && oppLine.ProductCode.contains('-PLTFM-') && cmVgTierMap.get(oppLine.ProductCode) != null){

                    c360StagingRec.VG_Tier__c = cmVgTierMap.get(oppLine.ProductCode);
                    vgHeaderPassed = true;
                }
                    
                if((oppLine.ProductCode.contains('LIC-CM-S-') || oppLine.ProductCode.contains('LIC-CM-D-'))
                        && oppLine.ProductCode.contains('-PLTFM-') && cmVgTierMap.get(oppLine.ProductCode) != null){

                    c360StagingRec.CM_Tier__c = cmVgTierMap.get(oppLine.ProductCode);
                    cmHeaderPassed = true;
                }
            }

            if(!pltFmHeaderPassed){

                string pltfmData = OpptyLineitemDiscountBatch.pltfmPatternMatcher(oppLine.ProductCode);

                if(pltfmData != null){

                    c360StagingRec.Platform_Type__c = pltfmData;
                    pltFmHeaderPassed = true;
                }
            }

            if( !licTagHeaderPass && oppLine.ProductCode.contains(System.label.LIC_AT_TAG)){

                c360StagingRec.LIC_AT_TAG__c = licTagHeaderPass = true;
            }

            if( !licVgBasicHeaderPass && oppLine.ProductCode == 'LIC-VG-BASIC'){

                c360StagingRec.VG_Basic_Purchased__c = licVgBasicHeaderPass = true;
            }

            if( !licVgENTHeaderPass && oppLine.ProductCode == 'LIC-VG-ENT'){

                c360StagingRec.VG_ENT_Purchased__c = licVgENTHeaderPass = true;
            }

            if( !licCM1ProHeaderPass && oppLine.ProductCode == 'LIC-CM1-PRO'){
                c360StagingRec.LIC_CM1_PRO__c = licCM1ProHeaderPass = true;
            } 

            if( !licCM2ProHeaderPass && oppLine.ProductCode == 'LIC-CM2-PRO'){
                c360StagingRec.LIC_CM2_PRO__c = licCM2ProHeaderPass = true;
            } 

            if( !licPltfmProHeaderPass && oppLine.ProductCode == 'LIC-PLTFM-PRO'){
                c360StagingRec.LIC_PLTFM_PRO__c = licPltfmProHeaderPass = true;
            } 

            if( !licVGProHeaderPass && oppLine.ProductCode == 'LIC-VG-PRO'){
                c360StagingRec.LIC_VG_PRO__c = licVGProHeaderPass = true;
            }

            if(ppPilotHeaderPassed && vgHeaderPassed && cmHeaderPassed && pltFmHeaderPassed 
                && licTagHeaderPass && licVgBasicHeaderPass && licVgENTHeaderPass && licCM1ProHeaderPass 
                && licCM2ProHeaderPass && licPltfmProHeaderPass && licVGProHeaderPass){ break; } //If all the header values are populated, end the loop
        }
    }

    private void populateDiscountAndMUP(List<Opportunity> oppList, Customer_360_Staging__c c360StagingRec, set<Id> renewalOptyIds, set<Id> amendedOptyIds){

        //Per ProductCode store Discount & MUP values
        Map<String, Decimal> fieldToDiscountORMUPMap = new Map<String, Decimal>();

        //Renewal Loop
        for(Opportunity opp :oppList){
            
            if(renewalOptyIds.contains(opp.Id)) {collectDiscountsAndMUP(fieldToDiscountORMUPMap, opp.OpportunityLineItems);}
        }

        //Amendment Loop
        for(Opportunity opp :oppList){

            if(amendedOptyIds.contains(opp.Id)) {collectDiscountsAndMUP(fieldToDiscountORMUPMap, opp.OpportunityLineItems);}
        }
        
        for(String field :fieldToDiscountORMUPMap.keySet()){

            c360StagingRec.put(field, fieldToDiscountORMUPMap.get(field));
        }
    }

    //When discount is null, ignore it, when discount is 0, MUP is not ignored when discount is null.
    private void collectDiscountsAndMUP(Map<String, Decimal> fieldToDiscountORMUPMap, List<OpportunityLineItem> oppLinesList){

        for(OpportunityLineItem oppLine :oppLinesList){

            //When the Product has mapping and non empty discount & Monthly Unit Price & if no discount/Montly unit price exist for its field mapping, register the field & its data
            if(productCodeToC360Mapping.containsKey(oppLine.ProductCode) && oppLine.SBQQ__QuoteLine__r.SBQQ__TotalDiscountRate__c != null && !fieldToDiscountORMUPMap.containsKey(productCodeToC360Mapping.get(oppLine.ProductCode)))
                fieldToDiscountORMUPMap.put(productCodeToC360Mapping.get(oppLine.ProductCode), oppLine.SBQQ__QuoteLine__r.SBQQ__TotalDiscountRate__c);

            if(productCodeToC360Mapping.containsKey(oppLine.ProductCode+'-MUP') && oppLine.Monthly_Unit_Price__c != null && !fieldToDiscountORMUPMap.containsKey(productCodeToC360Mapping.get(oppLine.ProductCode+'-MUP')))
                fieldToDiscountORMUPMap.put(productCodeToC360Mapping.get(oppLine.ProductCode+'-MUP'), oppLine.Monthly_Unit_Price__c);
        }
    }

    private void logException(Exception ex){

        insert new Log__c(ClassName__c = 'C360CreatorBatch',
                    Type__c = 'Apex Log',
                    Error_Message__c = 'Failure Creating C360 Record',
                    ExceptionMessage__c = ex.getMessage(),
                    StackTrace__c = ex.getStackTraceString(),
                    Exception_Type__c = ex.getTypeName(),
                    LogLevel__c = 'Error');
    }
}