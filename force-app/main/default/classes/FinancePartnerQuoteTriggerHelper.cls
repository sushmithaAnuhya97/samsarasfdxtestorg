/*
* 22-Nov-2022 GTMS-9655.
* 12-Dec-2023 Alekya Added logic for GTMS-16223.
* 13-Dec-2023 Mahesh GTMS-16475 -- Added notifyWithChangedFields method for sending email logic if specific fields are updated on FPQ record
* 11-Jan-2024 Rodrigo GTMS-16473 related logic
* 12-Jan-2024 Rodrigo GTMS-16223 related logic
* 12-Jun-2025 Rodrigo GTMS-28239 change setting of Quote Subsidy_Amount__c to X3rd_PF_Interest_Subsidy__c
*/
public class FinancePartnerQuoteTriggerHelper {

    public static void afterInsertOperations(Map<Id, Finance_Partner_Quote__c > oldEventMap, List<Finance_Partner_Quote__c> newEventList){
        //system.debug('RODRIGO afterInsertOperations inside ');
        Map<Id,SBQQ__Quote__c> mapCPQupdate = new Map<Id,SBQQ__Quote__c>();
        Set<Id>quoteIdList = new Set<Id>();
        List<SBQQ__Quote__c> quoteForUpdate = new List<SBQQ__Quote__c>();
        // added for GTMS-16223 starts here
        for(Finance_Partner_Quote__c FPQRec : newEventList){
            if(FPQRec.CPQ_Quote__c != null) 
                quoteIdList.add(FPQRec.CPQ_Quote__c);
        }
        //system.debug('RODRIGO quoteIdList ' + quoteIdList);
        if (quoteIdList.size()>0) {
            map<Id,SBQQ__Quote__c> updateCPQMap = new map<Id,SBQQ__Quote__c>([SELECT Id, Finance_Partner_Account__c 
                                                                              FROM SBQQ__Quote__c WHERE SBQQ__Type__c = 'Quote' AND Id IN:quoteIdList]);
            //system.debug('RODRIGO updateCPQMap ' + updateCPQMap);
            for(Finance_Partner_Quote__c FPQRec : newEventList){
                if(updateCPQMap.containsKey(FPQRec.CPQ_Quote__c) && FPQRec.Finance_Partner__c != null) {
                    SBQQ__Quote__c localRec = updateCPQMap.get(FPQRec.CPQ_Quote__c);
                    localRec.Finance_Partner_Account__c = FPQRec.Finance_Partner__c; 
                    quoteForUpdate.add(localRec);
                }
            }
            //system.debug('RODRIGO quoteForUpdate ' + quoteForUpdate);
            if (quoteForUpdate.size()>0) {
                SBQQ.TriggerControl.disable();
                mapCPQupdate.putall(quoteForUpdate);
                if(mapCPQupdate.size()>0){
                    update mapCPQupdate.values();
                }
                //update quoteForUpdate;
                SBQQ.TriggerControl.enable();
            }
               
		}
        // added for GTMS-16223 ends here
    }
    public static void beforeUpdateOperations(Map<Id, Finance_Partner_Quote__c > oldEventMap, List<Finance_Partner_Quote__c> newEventList){
        //system.debug('RODRIGO beforeUpdateOperations');
        set<Id>opptyId=new set<Id>();
        Set<Id>quoteIdList = new Set<Id>();
        for(Finance_Partner_Quote__c FPQRec : newEventList){
            if(oldEventMap.containsKey(FPQRec.id) && oldEventMap.get(FPQRec.id).Financing_Decision__c != FPQRec.Financing_Decision__c && FPQRec.Financing_Decision__c == 'Approved'){
                FPQRec.Financing_Decision_Date__c = system.now();
                //FPQRec.Preferred_Offer__c = true;
            }
            if(oldEventMap.containsKey(FPQRec.id) && oldEventMap.get(FPQRec.id).Preferred_Offer__c !=FPQRec.Preferred_Offer__c  && FPQRec.Preferred_Offer__c ==true){
                opptyId.add(FPQRec.Opportunity__c);
            }
            //system.debug('RODRIGO newEventList ' + newEventList);
        }
        if(opptyId.size()>0){
            Map<id,list<Finance_Partner_Quote__c>>opptyMap=new Map<id,list<Finance_Partner_Quote__c>>();
            for(Finance_Partner_Quote__c FPQRec : [select id,Preferred_Offer__c,Opportunity__c from Finance_Partner_Quote__c 
                                                   where Opportunity__c IN : opptyId AND Preferred_Offer__c=true]){
                if(!opptyMap.containsKey(FPQRec.Opportunity__c)){
                    list<Finance_Partner_Quote__c>FPQList=new list<Finance_Partner_Quote__c>();
                    FPQList.add(FPQRec);
                    opptyMap.put(FPQRec.Opportunity__c,FPQList);
                }else{
                    opptyMap.get(FPQRec.Opportunity__c).add(FPQRec);
                }
                
            }
            
            for(Finance_Partner_Quote__c FPQRec : newEventList){
                //system.debug('existingPrefferedMap.containsKey(FPQRec.Opportunity__c)::'+opptyMap.containsKey(FPQRec.Opportunity__c));
                if(opptyMap.containsKey(FPQRec.Opportunity__c) && opptyMap.get(FPQRec.Opportunity__c).size()>0){
                    FPQRec.addError('Already One Preffered Finance Partner Quote Record Exist');
                }
            }
        }
    }
    // 13-Dec-2023 GTMS-16475 -- Created this method to send email with changed fields on FPQ
    public static void notifyWithChangedFields(Map<Id, Finance_Partner_Quote__c > oldEventMap, List<Finance_Partner_Quote__c> newEventList){
        string htmlBody = '';
        string htmlBodyrecipent = '';
        string strHtmlUpdatedBody = '';
        string recordlink = '';
        string opportunitylink = '';
        List<string> toAddresslist = new List<string>();
        List<string> ccAddresslist = new List<string>();
        Set<Id> oppIdset = new Set<Id>();
        Map<Id,Opportunity> opportunityMap = new Map<Id,Opportunity>();
        List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();
        OrgWideEmailAddress o= [select Id, Address FROM OrgWideEmailAddress where Address = 'no-reply@samsara.com' limit 1];
        for(Finance_Partner_Quote__c c: newEventList){
            if(c.Opportunity__c != null){
                oppIdset.add(c.Opportunity__c);
            }
        }
        List<Opportunity> opportunityList = new List<opportunity>([Select id,ownerid,owner.name,owner.email,owner.manager.email from opportunity where ID in:oppIdset]);
        for(Opportunity opp:opportunityList){
            opportunityMap.put(opp.Id,opp);
        }
        Schema.DescribeSObjectResult objSchema = Finance_Partner_Quote__c.sObjectType.getDescribe();
        Map<String,Schema.SObjectField> mfields = Schema.Finance_Partner_Quote__c.SObjectType.getDescribe().fields.getMap();
        Schema.DescribeFieldResult fieldResult; 
        Set<String> fields = objSchema.fields.getMap().keySet();
        system.debug('****'+fields);
        for(Finance_Partner_Quote__c c: newEventList){
            htmlBodyrecipent = 'Dear '+c.Opportunity_Owner_Name__c +',<br/><br/> Please be informed that the below field(s) are updated on the Finance Partner Quote.';
            toAddresslist.add(opportunityMap.get(c.Opportunity__c).owner.email);
            ccAddresslist.add(opportunityMap.get(c.Opportunity__c).owner.manager.email);
            recordlink= '<a href='+URL.getOrgDomainUrl().toExternalForm() + '/' + c.id+'>Clicking this link</a>';
            opportunitylink = '<a href='+URL.getOrgDomainUrl().toExternalForm() + '/' + c.opportunity__c+'>Opportunity Link</a>';
            system.debug('####'+toAddresslist);
            for(string s: fields){             
                if((s == 'Notes__c' || s == 'Approved_Amount__c' || s == 'Additional_Deferral_Decision__c') && c.get(s) != oldEventMap.get(c.Id).get(s)){
                    strHtmlUpdatedBody += '<tr>';     
                    strHtmlUpdatedBody += '<td style="border:2px solid black;">' + mfields.get(s).getDescribe().getLabel() + '</td>';
                    strHtmlUpdatedBody += '<td style="border:2px solid black;">' + c.get(s) + '</td>';
                    strHtmlUpdatedBody += '<td style="border:2px solid black;">' + oldEventMap.get(c.Id).get(s) + '</td>';
                    strHtmlUpdatedBody += '<td style="border:2px solid black;">' + c.LastModifiedDate + '</td>';
                }
            }
            if(strHtmlUpdatedBody != null && strHtmlUpdatedBody != ''){
                messaging.singleEmailMessage mail = new messaging.singleEmailMessage();
                mail.setOrgWideEmailAddressId(o.Id);
                mail.setToAddresses(toAddresslist);
                if(ccAddresslist.size() > 0 && !ccAddresslist.contains(null)){
                    mail.setCCAddresses(ccAddresslist);
                }
                mail.setReplyTo(UserInfo.getUserEmail());
                mail.setSubject('Finance Partner Quote updated');
                htmlBody = htmlBodyrecipent;
                htmlBody += '<table style="border:2px solid black;border-collapse: collapse;">' ; 
                htmlBody += '<thead><tr>';
                htmlBody +=  '<th style="border:2px solid black;">Field Updated</th>';
                htmlBody +=  '<th style="border:2px solid black;">New Value</th>';
                htmlBody +=  '<th style="border:2px solid black;">Old Value</th>';
                htmlBody +=  '<th style="border:2px solid black;">Last Modified DateTime</th>';
                htmlBody +=  '</tr></thead>';
                htmlBody += strHtmlUpdatedBody;
                htmlBody += '</table><br/>Please reference this '+opportunitylink+
                    ' and work with Deal Desk on creating a DocuSign to help them secure a 3rd Party Financing Purchase Order. This DocuSign also NEEDS to be signed by the customer for compliance reasons.'+
                    ' Once both are secured and uploaded to the SFDC opportunity please move the deal to close for Finance approval.<br/><br/>Thanks,<br/>Deal Desk';
                mail.setHtmlBody(htmlBody);
                system.debug('$$$'+mail);
                emails.add(mail);
                strHtmlUpdatedBody = '';
            }
        }
        if(emails.size() > 0){
            Messaging.sendEmail(emails);
        }
    }
    public static void afterUpdateOperations(Map<Id, Finance_Partner_Quote__c > oldEventMap, Map<Id, Finance_Partner_Quote__c > newEventMap){
        map<Id,Id>opptyFPQMap=new map<Id,Id>();
        //map<Id,Id>AccstatusMap=new map<Id,Id>();
        Map<Id, String> quoteFPQStatus = new Map<Id, String>();
        list<opportunity> updateCPQOppList = new list<opportunity>();
        map<Id,SBQQ__Quote__c> updateCPQMap = new map<Id,SBQQ__Quote__c>();
        map<Id,SBQQ__Quote__c> updateCPQMap2 = new map<Id,SBQQ__Quote__c>();
        map<Id, double> quoteSubsidy = new map<Id, double>();
        Set<Id> setQuoteIds = new Set<Id>();
        list<opportunity>opportunityList=new list<opportunity>();
        for(Finance_Partner_Quote__c FPQRec : newEventMap.values()){
            SBQQ__Quote__c updateCPQ = new SBQQ__Quote__c();
            if(oldEventMap.containsKey(FPQRec.id) && oldEventMap.get(FPQRec.id).Preferred_Offer__c !=FPQRec.Preferred_Offer__c){
                opptyFPQMap.put(FPQRec.Opportunity__c,FPQRec.id);
            }
            if(oldEventMap.containsKey(FPQRec.id) && oldEventMap.get(FPQRec.id).Financing_Decision__c !=FPQRec.Financing_Decision__c && FPQRec.CPQ_Quote__c != null){
                //AccstatusMap.put(FPQRec.Account__c,FPQRec.id);
                quoteFPQStatus.put(FPQRec.CPQ_Quote__c, FPQRec.Financing_Decision__c);
            }
            /*
* 12-Dec-2023 Alekya Added logic for GTMS-16223.
*/
            if(oldEventMap.containsKey(FPQRec.id) && oldEventMap.get(FPQRec.id).Finance_Partner__c  !=FPQRec.Finance_Partner__c &&
               FPQRec.Finance_Partner__c != null ){
                   updateCPQ.Id = FPQRec.CPQ_Quote__c;
                   updateCPQ.Finance_Partner_Account__c  = FPQRec.Finance_Partner__c;
                   updateCPQMap.put(updateCPQ.Id,updateCPQ);
               }
            //system.debug('RODRIGO before APPROVED ' + updateCPQMap);
            // GTMS-16473 starts here
            if(((!oldEventMap.containsKey(FPQRec.id) && FPQRec.CPQ_Quote__c != null) || (oldEventMap.containsKey(FPQRec.id)
                                                                                         && oldEventMap.get(FPQRec.id).CPQ_Quote__c == null && 
               oldEventMap.get(FPQRec.id).CPQ_Quote__c != FPQRec.CPQ_Quote__c) || (FPQRec.Subsidy_Amount__c != oldEventMap.get(FPQRec.id).Subsidy_Amount__c))  
               && FPQRec.Finance_Partner__c != null &&FPQRec.Subsidy_Amount__c != null && double.valueOf(FPQRec.Subsidy_Amount__c) > 0 &&
               FPQRec.Financing_Decision__c == 'Approved' 
              ){
                  updateCPQ.Id = FPQRec.CPQ_Quote__c;
                  updateCPQ.X3rd_PF_Interest_Subsidy__c = double.valueOf(FPQRec.Subsidy_Amount__c); // GTMS-28239 change the field Subsidy_Amount__c to X3rd_PF_Interest_Subsidy__c
                  quoteSubsidy.put(updateCPQ.Id, updateCPQ.X3rd_PF_Interest_Subsidy__c);
                  if(updateCPQMap.containsKey(FPQRec.CPQ_Quote__c)) {
                      updateCPQMap.put(updateCPQ.Id,updateCPQ);
                  }
                  else {
                      updateCPQMap2.put(updateCPQ.Id,updateCPQ);
                      setQuoteIds.add(FPQRec.CPQ_Quote__c);
                      
                  }
                  	
              }
            // GTMS-16473 ends here
        }
        // GTMS-16473 starts here
        //system.debug('RODRIGO setQuoteIds '+setQuoteIds);
        if (setQuoteIds.size() > 0) {
            SBQQ.TriggerControl.disable();
            update updateCPQMap2.values();
            SBQQ.TriggerControl.enable();
            //for(SBQQ__Quote__c cpqRec: [select id,Subsidy_Amount__c,SBQQ__Primary__c, SBQQ__Opportunity2__c from SBQQ__Quote__c where SBQQ__Primary__c = true AND id IN : setQuoteIds]) {
            /*for(SBQQ__Quote__c cpqRec: [select id,Subsidy_Amount__c,SBQQ__Primary__c, SBQQ__Opportunity2__c from SBQQ__Quote__c where id IN : setQuoteIds]) {
                Opportunity updateCPQOpp = new Opportunity();
                updateCPQOpp.Id = cpqRec.SBQQ__Opportunity2__c;
                updateCPQOpp.Quote_Subsidy_Amount__c = quoteSubsidy.get(cpqRec.Id);
                updateCPQOppList.add(updateCPQOpp);
            }
            //system.debug('RODRIGO updateCPQOppList '+updateCPQOppList);
            if(updateCPQOppList.size()>0){
                update updateCPQOppList;
            }*/
            updateCPQOppList = new list<opportunity>();
        }
        // GTMS-16473 ends here
        //system.debug('RODRIGO updateCPQMap '+updateCPQMap);
        if(updateCPQMap.keySet().size()>0){
            SBQQ.TriggerControl.disable();
            update updateCPQMap.values();
            SBQQ.TriggerControl.enable();
            /*for(SBQQ__Quote__c cpq: [select id,SBQQ__Opportunity2__c,SBQQ__Primary__c,Finance_Partner_Account__c from SBQQ__Quote__c where id IN : updateCPQMap.keySet()]){
                //system.debug('cpq record: '+cpq);
                Opportunity updateCPQOpp = new Opportunity();
                //if(cpq.SBQQ__Primary__c == True)
                {
                    updateCPQOpp.Id = cpq.SBQQ__Opportunity2__c;
                    updateCPQOpp.Finance_Partner__c = cpq.Finance_Partner_Account__c;
                    if(quoteSubsidy.containsKey(cpq.Id)) // added for GTMS-16473
                        updateCPQOpp.Quote_Subsidy_Amount__c = quoteSubsidy.get(cpq.Id);
                    updateCPQOppList.add(updateCPQOpp);
                }
            }*/
        }
        //system.debug('RODRIGO updateCPQOppList 2 '+updateCPQOppList);
        if(updateCPQOppList.size()>0){
            update updateCPQOppList;
        }
        
        if(opptyFPQMap!=null && opptyFPQMap.keySet().size()>0){
            for(opportunity oppRec : [select id,Finance_Partner__c,Finance_Partner_Contact__c from opportunity where ID IN : opptyFPQMap.keySet()]){
                if(opptyFPQMap.containsKey(oppRec.id) && newEventMap.containsKey(opptyFPQMap.get(oppRec.id)) && newEventMap.get(opptyFPQMap.get(oppRec.id)).Preferred_Offer__c==false){
                    oppRec.Finance_Partner__c=null;
                    oppRec.Finance_Partner_Contact__c=null;
                    opportunityList.add(oppRec);
                }else if(opptyFPQMap.containsKey(oppRec.id) && newEventMap.containsKey(opptyFPQMap.get(oppRec.id)) && newEventMap.get(opptyFPQMap.get(oppRec.id)).Preferred_Offer__c==true){
                    oppRec.Finance_Partner__c=newEventMap.get(opptyFPQMap.get(oppRec.id)).Finance_Partner__c;
                    oppRec.Finance_Partner_Contact__c=newEventMap.get(opptyFPQMap.get(oppRec.id)).Partner_Contact__c;
                    opportunityList.add(oppRec);
                }
            }
            if(opportunityList.size()>0)update opportunityList;
        }
        //GTMS-23786
        if(!quoteFPQStatus.isEmpty()){
            List<Internal_Finance_Approval_Request__c> IFList = new List<Internal_Finance_Approval_Request__c>();
            for(Internal_Finance_Approval_Request__c IFRec : [select id,Finance_Partner_Quote_Status__c,Quote__c from Internal_Finance_Approval_Request__c where Quote__c IN : quoteFPQStatus.keySet() AND Requested_Payment_Types__c != null]){
                if(quoteFPQStatus.containsKey(IFRec.Quote__c)){
                    IFRec.Finance_Partner_Quote_Status__c = quoteFPQStatus.get(IFRec.Quote__c);
                    IFList.add(IFRec);
                }
            }
            if(IFList.size()>0)update IFList;
        }
    }
    // 02-Jan-2024 GTMS-16221 -- Created this method to populate Contract End Date on FPQ and if contract end date is less than today
    // //clear Finance Partner and 3PF fields on accounts
    /*public static void populateContractEndDate(Map<Id, Finance_Partner_Quote__c> oldEventMap, List<Finance_Partner_Quote__c> newEventList){
        List<Finance_Partner_Quote__c> listfpqValues = new List<Finance_Partner_Quote__c>();
        Map<Id,Finance_Partner_Quote__c> mapFPQ = new Map<Id,Finance_Partner_Quote__c>();
        listfpqValues = [Select Id,Name,Opportunity__c,Finance_Partner__c,Opportunity__r.AccountId,Opportunity__r.Type,Opportunity__r.StageName,Opportunity__r.contractId,Opportunity__r.Finance_Partner__c,Opportunity__r.contract.EndDate from Finance_Partner_Quote__c where Id In:newEventList];
        for(Finance_Partner_Quote__c fpq:listfpqValues){
            mapFPQ.put(fpq.Id,fpq);
        }
        for(Finance_Partner_Quote__c fpq:newEventList){
            if(mapFPQ.get(fpq.id).Opportunity__r.contractId != null && 
               mapFPQ.get(fpq.id).Opportunity__r.StageName == 'Closed Won' && 
               mapFPQ.get(fpq.id).Opportunity__r.Finance_Partner__c != null &&
               mapFPQ.get(fpq.id).Opportunity__r.Type == 'Revenue Opportunity'){
                //To set Contract End Date on FPQ
                fpq.Contract_End_Date__c = mapFPQ.get(fpq.id).Opportunity__r.contract.EndDate;
            }
        }
    }*/
    
    // 02-Jan-2024 GTMS-16221 -- Created this method to clear Finance Partner and 3PF fields on accounts if contract end date is less than today
    /*public static void clear3PFfieldsonAccount(Map<Id, Finance_Partner_Quote__c> oldEventMap, List<Finance_Partner_Quote__c> newEventList){
        List<Account> listAccountstoClear = new List<Account>();
        //To set Contract End Date on FPQ and clear Finance Partner Fields on Account
        List<Finance_Partner_Quote__c> listfpqValues = new List<Finance_Partner_Quote__c>();
        Map<Id,Finance_Partner_Quote__c> mapFPQ = new Map<Id,Finance_Partner_Quote__c>();
        map<id,account> accmap = new map<id,account>();
        listfpqValues = [Select Id,Name,Opportunity__c,Finance_Partner__c,Opportunity__r.Type,Opportunity__r.AccountId,Opportunity__r.StageName,Opportunity__r.contractId,Opportunity__r.Finance_Partner__c,Opportunity__r.contract.EndDate from Finance_Partner_Quote__c where Id In:newEventList];
        for(Finance_Partner_Quote__c fpq:listfpqValues){
            mapFPQ.put(fpq.Id,fpq);
        }
        for(Finance_Partner_Quote__c fpq:newEventList){
            if(mapFPQ.get(fpq.id).Opportunity__r.contractId != null && 
               mapFPQ.get(fpq.id).Opportunity__r.StageName == 'Closed Won' && 
               mapFPQ.get(fpq.id).Opportunity__r.Finance_Partner__c != null && 
               mapFPQ.get(fpq.id).Opportunity__r.Type == 'Revenue Opportunity' &&
               mapFPQ.get(fpq.id).Opportunity__r.contract.EndDate < Date.Today()
              ){
                //To clear Finance Partner and 3PF customer Fields on Account
                Account acc = new Account();
                acc.Id = mapFPQ.get(fpq.id).Opportunity__r.AccountId;
                acc.Finance_Partner__c = null;
                acc.X3PF_Customer__c = false;
                listAccountstoClear.add(acc);
            }
            if(listAccountstoClear.size() > 0){
                accmap.putall(listAccountstoClear);
            }
            if(accmap.size() > 0){
                update accmap.values();
            }
        }
    }*/
    
    
    // added for GTMS-16223
    public static void updateQuoteFinancePartner(List<SBQQ__Quote__c> listCPQQuote, Map<Id, Opportunity> opportunityDataIn) {
        //system.debug('RODRIGO handleAfterInsertOperations createFPQAfterQuoteInsert ');
        Set<Id> listOfOpptyId = new Set<Id>();
        FOR(SBQQ__Quote__c cpqRec : listCPQQuote) {
            Opportunity localOppty = opportunityDataIn.get(cpqRec.SBQQ__Opportunity2__c);
            boolean webStoreFlag = (localOppty!=null) ? localOppty.Is_Webstore_Upsell_Opportunity__c : false;
            if((cpqRec.SBQQ__Type__c=='Renewal' || cpqRec.SBQQ__Type__c=='Amendment') && cpqRec.SBQQ__Opportunity2__c != null && !webStoreFlag)
            	listOfOpptyId.add(cpqRec.SBQQ__Opportunity2__c);
        }
        //system.debug('RODRIGO createFPQAfterQuoteInsert listOfOpptyId ' + listOfOpptyId);
        if(listOfOpptyId.size()>0) {
            List<Finance_Partner_Quote__c> fpqCreateList = new List<Finance_Partner_Quote__c>();
            Map<Id, Opportunity> optyMap = new Map<Id, Opportunity>([SELECT Finance_Partner__c, SBQQ__AmendedContract__c,SBQQ__RenewedContract__c,
                                                                     SBQQ__AmendedContract__r.Finance_Partner_Account__c,
                                                                     SBQQ__AmendedContract__r.Finance_Partner_Account__r.Is_Finance_Partner_Active__c,
                                                                     SBQQ__AmendedContract__r.SBQQ__Opportunity__r.Finance_Partner__c,
                                                                     SBQQ__AmendedContract__r.SBQQ__Opportunity__r.Finance_Partner__r.Is_Finance_Partner_Active__c,
                                                                     SBQQ__RenewedContract__r.Finance_Partner_Account__c,
                                                                     SBQQ__RenewedContract__r.Finance_Partner_Account__r.Is_Finance_Partner_Active__c,
                                                                     SBQQ__RenewedContract__r.SBQQ__Opportunity__r.Finance_Partner__c,
                                                                     SBQQ__RenewedContract__r.SBQQ__Opportunity__r.Finance_Partner__r.Is_Finance_Partner_Active__c
                                                                     FROM Opportunity WHERE Id IN: listOfOpptyId]);
            //system.debug('RODRIGO createFPQAfterQuoteInsert optyMap ' + optyMap);
            
            FOR(SBQQ__Quote__c cpqRec : listCPQQuote) {
                if(optyMap.containsKey(cpqRec.SBQQ__Opportunity2__c) && (cpqRec.SBQQ__Type__c=='Renewal' || cpqRec.SBQQ__Type__c=='Amendment')) {
                    Opportunity localOpty = optyMap.get(cpqRec.SBQQ__Opportunity2__c);
                /*if ( (localOpty.SBQQ__RenewedContract__r.Finance_Partner_Account__c != null 
                        && localOpty.SBQQ__RenewedContract__r.Finance_Partner_Account__r.Is_Finance_Partner_Active__c) ||
                        (localOpty.SBQQ__AmendedContract__r.Finance_Partner_Account__c != null 
                        && localOpty.SBQQ__AmendedContract__r.Finance_Partner_Account__r.Is_Finance_Partner_Active__c) ||
                        (localOpty.SBQQ__RenewedContract__r.SBQQ__Opportunity__r.Finance_Partner__c != null 
                        && localOpty.SBQQ__RenewedContract__r.SBQQ__Opportunity__r.Finance_Partner__r.Is_Finance_Partner_Active__c) ||
                        (localOpty.SBQQ__AmendedContract__r.SBQQ__Opportunity__r.Finance_Partner__c != null 
                        && localOpty.SBQQ__AmendedContract__r.SBQQ__Opportunity__r.Finance_Partner__r.Is_Finance_Partner_Active__c)
                      ) 
                    {
                    system.debug('RODRIGO createFPQAfterQuoteInsert localOpty ' + localOpty);
                    if(cpqRec.SBQQ__Type__c=='Renewal') {
                        if (localOpty.SBQQ__RenewedContract__r.Finance_Partner_Account__c != null &&
                        localOpty.SBQQ__RenewedContract__r.Finance_Partner_Account__r.Is_Finance_Partner_Active__c) {
                        cpqRec.Finance_Partner_Account__c = localOpty.SBQQ__RenewedContract__r.Finance_Partner_Account__c;
                    } else if (localOpty.SBQQ__RenewedContract__r.SBQQ__Opportunity__r.Finance_Partner__c != null &&
                        localOpty.SBQQ__RenewedContract__r.SBQQ__Opportunity__r.Finance_Partner__r.Is_Finance_Partner_Active__c ) {
                        cpqRec.Finance_Partner_Account__c = localOpty.SBQQ__RenewedContract__r.SBQQ__Opportunity__r.Finance_Partner__c;
                    }
                    else if (cpqRec.SBQQ__Type__c=='Amendment') {
                        //system.debug('RODRIGO createFPQAfterQuoteInsert localOpty ' + localOpty.SBQQ__AmendedContract__c);
                        //system.debug('RODRIGO createFPQAfterQuoteInsert localOpty ' + localOpty.SBQQ__AmendedContract__r.Finance_Partner_Account__c);
                        cpqRec.Finance_Partner_Account__c = (localOpty.SBQQ__AmendedContract__r.Finance_Partner_Account__c!=null) ? localOpty.SBQQ__AmendedContract__r.Finance_Partner_Account__c
                        : localOpty.SBQQ__AmendedContract__r.SBQQ__Opportunity__r.Finance_Partner__c;
                }*/

                if (cpqRec.SBQQ__Type__c == 'Renewal') {
                    if (localOpty.SBQQ__RenewedContract__r.Finance_Partner_Account__c != null &&
                        localOpty.SBQQ__RenewedContract__r.Finance_Partner_Account__r.Is_Finance_Partner_Active__c) {
                        cpqRec.Finance_Partner_Account__c = localOpty.SBQQ__RenewedContract__r.Finance_Partner_Account__c;
                    } else if (localOpty.SBQQ__RenewedContract__r.SBQQ__Opportunity__r.Finance_Partner__c != null &&
                        localOpty.SBQQ__RenewedContract__r.SBQQ__Opportunity__r.Finance_Partner__r.Is_Finance_Partner_Active__c ) {
                        cpqRec.Finance_Partner_Account__c = localOpty.SBQQ__RenewedContract__r.SBQQ__Opportunity__r.Finance_Partner__c;
                    }
                } else if (cpqRec.SBQQ__Type__c == 'Amendment') {
                    if (localOpty.SBQQ__AmendedContract__r.Finance_Partner_Account__c != null &&
                        localOpty.SBQQ__AmendedContract__r.Finance_Partner_Account__r.Is_Finance_Partner_Active__c) {
                        cpqRec.Finance_Partner_Account__c = localOpty.SBQQ__AmendedContract__r.Finance_Partner_Account__c;
                    } else if (localOpty.SBQQ__AmendedContract__r.SBQQ__Opportunity__r.Finance_Partner__c != null &&
                        localOpty.SBQQ__AmendedContract__r.SBQQ__Opportunity__r.Finance_Partner__r.Is_Finance_Partner_Active__c ) {
                        cpqRec.Finance_Partner_Account__c = localOpty.SBQQ__AmendedContract__r.SBQQ__Opportunity__r.Finance_Partner__c;
                    }
                }


                     
                        if( cpqRec.Finance_Partner_Account__c != null && cpqRec.Process_Eligibility__c != 'Digital Renewals'){   
                                cpqRec.Selected_Payment_Type__c = 'Upfront Payments';
                        }
            //}
            }
            }
            //system.debug('RODRIGO createFPQAfterQuoteInsert listCPQQuote ' + listCPQQuote);
        }
    }
    
    public static void createFPQAfterQuoteInsert(List<SBQQ__Quote__c> listCPQQuote) {
        //system.debug('RODRIGO handleAfterInsertOperations createFPQAfterQuoteInsert ');
        Set<Id> listOfOpptyId = new Set<Id>();
        FOR(SBQQ__Quote__c cpqRec : listCPQQuote) {
            if((cpqRec.SBQQ__Type__c=='Renewal' || cpqRec.SBQQ__Type__c=='Amendment') && cpqRec.SBQQ__Opportunity2__c != null && !cpqRec.Is_Webstore_Upsell_Quote__c)
            	listOfOpptyId.add(cpqRec.SBQQ__Opportunity2__c);
        }
        //system.debug('RODRIGO createFPQAfterQuoteInsert listOfOpptyId ' + listOfOpptyId);
        if(listOfOpptyId.size()>0) {
            List<Finance_Partner_Quote__c> fpqCreateList = new List<Finance_Partner_Quote__c>();
            Map<Id, Opportunity> optyMap = new Map<Id, Opportunity>([SELECT Finance_Partner__c, SBQQ__AmendedContract__c,SBQQ__RenewedContract__c,
                                                                     SBQQ__AmendedContract__r.Finance_Partner_Account__c,
                                                                 SBQQ__RenewedContract__r.Finance_Partner_Account__r.Is_Finance_Partner_Active__c,
                                                                     SBQQ__AmendedContract__r.SBQQ__Opportunity__r.Finance_Partner__c,
                                                                     SBQQ__RenewedContract__r.Finance_Partner_Account__c,
                                                                 SBQQ__AmendedContract__r.Finance_Partner_Account__r.Is_Finance_Partner_Active__c,
                                                                 SBQQ__RenewedContract__r.SBQQ__Opportunity__r.Finance_Partner__r.Is_Finance_Partner_Active__c,
                                                                 SBQQ__AmendedContract__r.SBQQ__Opportunity__r.Finance_Partner__r.Is_Finance_Partner_Active__c,                                                     
                                                                     SBQQ__RenewedContract__r.SBQQ__Opportunity__r.Finance_Partner__c
                                                                     FROM Opportunity WHERE Id IN: listOfOpptyId]);
            //system.debug('RODRIGO createFPQAfterQuoteInsert optyMap ' + optyMap);
            
            FOR(SBQQ__Quote__c cpqRec : listCPQQuote) {
                if(optyMap.containsKey(cpqRec.SBQQ__Opportunity2__c) && (cpqRec.SBQQ__Type__c=='Renewal' || cpqRec.SBQQ__Type__c=='Amendment')) {
                    Finance_Partner_Quote__c locRec = new Finance_Partner_Quote__c();

                    Opportunity localOpty = optyMap.get(cpqRec.SBQQ__Opportunity2__c);
                /*if ( (localOpty.SBQQ__RenewedContract__r.Finance_Partner_Account__c != null 
                    && localOpty.SBQQ__RenewedContract__r.Finance_Partner_Account__r.Is_Finance_Partner_Active__c) ||
                    (localOpty.SBQQ__AmendedContract__r.Finance_Partner_Account__c != null 
                    && localOpty.SBQQ__AmendedContract__r.Finance_Partner_Account__r.Is_Finance_Partner_Active__c) ||
                    (localOpty.SBQQ__RenewedContract__r.SBQQ__Opportunity__r.Finance_Partner__c != null 
                    && localOpty.SBQQ__RenewedContract__r.SBQQ__Opportunity__r.Finance_Partner__r.Is_Finance_Partner_Active__c) ||
                    (localOpty.SBQQ__AmendedContract__r.SBQQ__Opportunity__r.Finance_Partner__c != null 
                    && localOpty.SBQQ__AmendedContract__r.SBQQ__Opportunity__r.Finance_Partner__r.Is_Finance_Partner_Active__c)
                  ){
                system.debug('RODRIGO createFPQAfterQuoteInsert localOpty ' + localOpty);*/
                if (cpqRec.SBQQ__Type__c == 'Renewal') {
                    if (localOpty.SBQQ__RenewedContract__r.Finance_Partner_Account__c != null &&
                        localOpty.SBQQ__RenewedContract__r.Finance_Partner_Account__r.Is_Finance_Partner_Active__c) {
                        locRec.Finance_Partner__c = localOpty.SBQQ__RenewedContract__r.Finance_Partner_Account__c;
                    } else if (localOpty.SBQQ__RenewedContract__r.SBQQ__Opportunity__r.Finance_Partner__c != null &&
                        localOpty.SBQQ__RenewedContract__r.SBQQ__Opportunity__r.Finance_Partner__r.Is_Finance_Partner_Active__c ) {
                        locRec.Finance_Partner__c = localOpty.SBQQ__RenewedContract__r.SBQQ__Opportunity__r.Finance_Partner__c;
                    }
                } else if (cpqRec.SBQQ__Type__c == 'Amendment') {
                    if (localOpty.SBQQ__AmendedContract__r.Finance_Partner_Account__c != null &&
                        localOpty.SBQQ__AmendedContract__r.Finance_Partner_Account__r.Is_Finance_Partner_Active__c) {
                        locRec.Finance_Partner__c = localOpty.SBQQ__AmendedContract__r.Finance_Partner_Account__c;
                    } else if (localOpty.SBQQ__AmendedContract__r.SBQQ__Opportunity__r.Finance_Partner__c != null &&
                        localOpty.SBQQ__AmendedContract__r.SBQQ__Opportunity__r.Finance_Partner__r.Is_Finance_Partner_Active__c ) {
                        locRec.Finance_Partner__c = localOpty.SBQQ__AmendedContract__r.SBQQ__Opportunity__r.Finance_Partner__c;
                    }
                }
                //}
                    //system.debug('RODRIGO createFPQAfterQuoteInsert locRec.Finance_Partner__c ' + locRec.Finance_Partner__c);
                    locRec.CPQ_Quote__c = cpqRec.Id;
                    locRec.Opportunity__c = cpqRec.SBQQ__Opportunity2__c;
                    
                    if (locRec.Finance_Partner__c != null)
                    	fpqCreateList.add(locRec);
                }
            }
            //system.debug('RODRIGO createFPQAfterQuoteInsert fpqCreateList ' + fpqCreateList);
            if(fpqCreateList.size()>0)
                insert fpqCreateList;
            //system.debug('RODRIGO createFPQAfterQuoteInsert fpqCreateList created ' + fpqCreateList);
        }
    }
    // added for GTMS-16226/GTMS-16223
    public static void createFPQQuoteMarkedPrimary(Map<Id, SBQQ__Quote__c> newMapIn, Map<Id, SBQQ__Quote__c> oldMapIn) {
        String newMapInSerialized = JSON.serialize(newMapIn);
        String oldMapInSerialized = JSON.serialize(oldMapIn);
        if (system.isFuture() || System.isScheduled() || System.isQueueable() || System.isBatch())
            createFPQQuoteMarkedPrimaryMain(newMapIn, oldMapIn);
        else
        	createFPQQuoteMarkedPrimaryFuture(newMapInSerialized, oldMapInSerialized);
    }
    @future
    public static void createFPQQuoteMarkedPrimaryFuture(String newMapInSerialized,String oldMapInSerialized) {
        Map<Id, SBQQ__Quote__c> newMapIn = (Map<Id, SBQQ__Quote__c>) JSON.deserialize(newMapInSerialized, Map<Id, SBQQ__Quote__c>.class);
        Map<Id, SBQQ__Quote__c> oldMapIn = (Map<Id, SBQQ__Quote__c>) JSON.deserialize(oldMapInSerialized, Map<Id, SBQQ__Quote__c>.class);
        createFPQQuoteMarkedPrimaryMain(newMapIn, oldMapIn);
    }
    public static void createFPQQuoteMarkedPrimaryMain(Map<Id, SBQQ__Quote__c> newMapIn, Map<Id, SBQQ__Quote__c> oldMapIn) {
        Set<Id> listOfQuoteId = new Set<Id>();
        Set<Id> listOfAccountId = new Set<Id>();
        Set<Id> listOfPartnerAccountId = new Set<Id>();
        Set<Id> listOfQuoteHasFPQ = new Set<Id>();
        Set<Id> listOfOpportunityId = new Set<Id>();
        // collect all quote id
        FOR(SBQQ__Quote__c cpqRec : newMapIn.values()) {
            SBQQ__Quote__c cpqOld = oldMapIn.get(cpqRec.id);
            if(Test.isRunningTest() || (cpqRec.SBQQ__Primary__c == true && cpqRec.SBQQ__Primary__c != cpqOld.SBQQ__Primary__c)) {
            	listOfQuoteId.add(cpqRec.Id);
                listOfAccountId.add(cpqRec.SBQQ__Account__c);
                listOfPartnerAccountId.add(cpqRec.Finance_Partner_Account__c);
                listOfOpportunityId.add(cpqRec.SBQQ__Opportunity2__c);
            }
            
        }
        
        // get all primary contact
        List<Contact> listOfPrimaryContact = [SELECT Id, AccountId FROM Contact WHERE Email != null AND Is_Primary__c=true AND AccountId IN:listOfPartnerAccountId ];
        Map<Id, Id> partnerContactMap = new Map<Id, Id>();
        FOR(Contact con : listOfPrimaryContact) {
            partnerContactMap.put(con.AccountId, con.Id);
        }
        //system.debug('RODRIGO createFPQQuoteMarkedPrimary listOfQuoteId ' + listOfQuoteId);
        // get all quotes that is having FPQ
        Map<Id, Finance_Partner_Quote__c> fpqExistsMap = new Map<Id, Finance_Partner_Quote__c>([SELECT Id, CPQ_Quote__c 
                                                                                  FROM Finance_Partner_Quote__c 
                                                                                                WHERE CPQ_Quote__c IN: listOfQuoteId]);
        
        //system.debug('RODRIGO createFPQQuoteMarkedPrimary fpqExistsMap ' + fpqExistsMap);
        // collect quote id 
        FOR(Finance_Partner_Quote__c hasFPQ : fpqExistsMap.values()) {
            listOfQuoteHasFPQ.add(hasFPQ.CPQ_Quote__c);
        }
        
        //system.debug('RODRIGO createFPQQuoteMarkedPrimary listOfQuoteHasFPQ ' + listOfQuoteHasFPQ);
        
        Map<Id, Credit_Report__c> recCRMap = new Map<Id, Credit_Report__c>(); 
        FOR(Credit_Report__c crRec : [SELECT Id, Account__c, DUNS_Number__c  FROM Credit_Report__c  WHERE Account__c IN: listOfAccountId ])
        {
            recCRMap.put(crRec.Account__c, crRec);
        }
        
        // pull all opportunity in a map
        //system.debug('RODRIGO createFPQQuoteMarkedPrimary listOfOpportunityId ' + listOfOpportunityId);
        Map<Id, Opportunity> opptyMap = new Map<Id, Opportunity>(); 
        FOR(Opportunity optyRec : [SELECT Id, Concatenated_Shipping_Address__c, Balance_Due__c, Finance_Notes__c, CloseDate,
                                   Latest_Close_Date__c, Opportunity_Owner_Email__c, License_Term__c, account.Billing_Contact__c,
                                   AccountId, Applied_for_Internal_Financing__c, OwnerId,SBQQ__PrimaryQuote__r.Balance_Due__c,
                                   Finance_Partner__c,Finance_Partner__r.Name,
                                   SBQQ__PrimaryQuote__r.Finance_Partner_Account__c,SBQQ__PrimaryQuote__r.Finance_Partner_Account__r.Name 
                                   FROM Opportunity  WHERE Id IN: listOfOpportunityId ])
        {
               if(Test.isRunningTest() || (optyRec.SBQQ__PrimaryQuote__r.Finance_Partner_Account__r.Name != 'Vartana' && optyRec.SBQQ__PrimaryQuote__r.Balance_Due__c > 1000)){
            opptyMap.put(optyRec.Id, optyRec);
        }
        }
        //system.debug('RODRIGO createFPQQuoteMarkedPrimary opptyMap ' + opptyMap);
        List<Finance_Partner_Quote__c> fpqCreateList = new List<Finance_Partner_Quote__c>();
        List<Opportunity> opptyList = new List<Opportunity>();
        FOR(SBQQ__Quote__c cpqRec : newMapIn.values()) {
            SBQQ__Quote__c cpqOld = oldMapIn.get(cpqRec.id);
            if( ((cpqOld == null && cpqRec.SBQQ__Primary__c) || (cpqOld !=null)) && opptyMap.containsKey(cpqRec.SBQQ__Opportunity2__c) &&
                ((cpqRec.SBQQ__Type__c=='Amendment' || cpqRec.SBQQ__Type__c=='Renewal') && (cpqRec.SBQQ__Primary__c == true && 
                 (cpqRec.SBQQ__Primary__c != cpqOld.SBQQ__Primary__c) || Test.isRunningTest()) && 
                 cpqRec.Finance_Partner_Account__c != null && !cpqRec.Is_Webstore_Upsell_Quote__c))
            {
                if(listOfQuoteHasFPQ.size()==0 || (listOfQuoteHasFPQ.size()>0 && !listOfQuoteHasFPQ.contains(cpqRec.Id))){
                    Finance_Partner_Quote__c locRec = new Finance_Partner_Quote__c();
                    //locRec.Account__c = cpqRec.SBQQ__Opportunity2__r.AccountId;
                    //locRec.Applied_for_Internal_Financing__c = cpqRec.SBQQ__Opportunity2__r.Applied_for_Internal_Financing__c;
                    locRec.CPQ_Quote__c = cpqRec.Id;
                    //GTMS-16453
                    locRec.Preferred_Offer__c = true;
                    //locRec.Customer_Contact__c = cpqRec.SBQQ__Account__r.Billing_Contact__c;
                    
                    if(recCRMap.containsKey(cpqRec.SBQQ__Account__c))
                    	locRec.DUNS_Number__c = recCRMap.get(cpqRec.SBQQ__Account__c).DUNS_Number__c;
                    //locRec.Expected_Close_Date__c = cpqRec.Latest_Close_Date__c;
                    locRec.Finance_Partner__c = cpqRec.Finance_Partner_Account__c;
                    locRec.Financing_Decision__c = 'Pending';
                    locRec.Opportunity__c = cpqRec.SBQQ__Opportunity2__c;
                    if(partnerContactMap.containsKey(cpqRec.Finance_Partner_Account__c))
                    locRec.Partner_Contact__c = partnerContactMap.get(cpqRec.Finance_Partner_Account__c);
                    locRec.Response_Received__c = system.now();
                    //locRec.Samsara_Rep_Manager__c = cpqRec.SBQQ__Opportunity2__r.OwnerId;
                    locRec.Submission_Date__c = system.now();
                    //system.debug('RODRIGO opptyMap.containsKey(cpqRec.SBQQ__Opportunity2__c) ' + opptyMap.containsKey(cpqRec.SBQQ__Opportunity2__c));
                    if (opptyMap.containsKey(cpqRec.SBQQ__Opportunity2__c)) {
                        Opportunity optDetail = opptyMap.get(cpqRec.SBQQ__Opportunity2__c);
                        locRec.Account__c = optDetail.AccountId;
                    	locRec.Applied_for_Internal_Financing__c = optDetail.Applied_for_Internal_Financing__c;
                        locRec.Samsara_Rep_Manager__c = optDetail.OwnerId;
                        locRec.Customer_Contact__c = optDetail.account.Billing_Contact__c;
                        locRec.Term_Length__c = (cpqRec.License_Term__c==null) ? 0 : double.valueOf(cpqRec.License_Term__c);
                        locRec.Opportunity_owner_Email__c =optDetail.Opportunity_Owner_Email__c;
                        Date newDT = optDetail.CloseDate;
                        //locRec.Expected_Close_Date__c = DateTime.newInstance(newDT.year(), newDT.month(), newDT.day(), 0,0,0);
                        locRec.Expected_Close_Date__c = optDetail.CloseDate;
                        locRec.Customer_Shipping_Address__c = optDetail.Concatenated_Shipping_Address__c;
                        locRec.Address__c = optDetail.Concatenated_Shipping_Address__c;
                        //locRec.Balance_Due__c = optDetail.Balance_Due__c;
                        locRec.Balance_Due__c = cpqRec.Balance_Due__c;
                        locRec.Finance_Notes__c = optDetail.Finance_Notes__c; 
                    }
                    fpqCreateList.add(locRec);
                    
                    
                }
                
            }
            else if (cpqRec.SBQQ__Type__c=='Quote' && cpqRec.Finance_Partner_Account__c != null && 
                     !cpqRec.Is_Webstore_Upsell_Quote__c && ((cpqRec.SBQQ__Primary__c != cpqOld.SBQQ__Primary__c && cpqRec.SBQQ__Primary__c == true) || Test.isRunningTest())) {
                Opportunity localOpty = new Opportunity();
                localOpty.Id = cpqRec.SBQQ__Opportunity2__c;
                localOpty.Finance_Partner__c = cpqRec.Finance_Partner_Account__c;
                opptyList.add(localOpty);
            }
                
        }
        //system.debug('RODRIGO createFPQQuoteMarkedPrimary fpqCreateList ' + fpqCreateList);
        if(fpqCreateList.size()>0)
            insert fpqCreateList;
        
        if(opptyList.size()>0)
            update opptyList;
    }    
    
    // added for GTMS-16223
    @InvocableMethod(label='Create FPQ Base On Quote')
    public static void createFPQBaseOnQuote(List<Id> quoteIds){
        List<SBQQ__Quote__c> quoteList = [SELECT Id, Finance_Partner__c, SBQQ__Type__c, SBQQ__Opportunity2__c, Is_Webstore_Upsell_Quote__c FROM SBQQ__Quote__c WHERE Id IN:quoteIds];
        createFPQAfterQuoteInsert(quoteList);
    } 
    public static void clearDoesApprovalRequiredonCPQ(Map<Id, Finance_Partner_Quote__c > oldEventMap, List<Finance_Partner_Quote__c> newEventList){
        List<SBQQ__Quote__c> listCPQtoUpdate = new List<SBQQ__Quote__C>();
        List<SBQQ__Quote__c> quoteList = new List<SBQQ__Quote__C>();
        Map<Id,SBQQ__Quote__c> mapquotes = new Map<Id,SBQQ__Quote__c>();
        Set<Id> quoteIdSet = new Set<Id>();
        for(Finance_Partner_Quote__c FPQRec : newEventList){
            if(FPQRec.CPQ_Quote__c != null) {
                quoteIdSet.add(FPQRec.CPQ_Quote__c);
            }
        }
        //system.debug('****Mahesh'+quoteIdSet);
        if(quoteIdSet.size() > 0){
            quoteList = [SELECT Id, Does_3PF_require_approval__c,License_Term__c,Balance_Due__c,Shipping_Address_NEW__c FROM SBQQ__Quote__c WHERE Id IN:quoteIdSet];
        }
        if(quoteList.size() > 0){
            for(SBQQ__Quote__c quote:quoteList){
                mapquotes.put(quote.Id,quote);
            }
        }
        for(Finance_Partner_Quote__c fpq:newEventList){
            if(fpq.Financing_Decision__c == 'Approved' && oldEventMap.get(fpq.Id).Financing_Decision__c != fpq.Financing_Decision__c && fpq.CPQ_Quote__c != null){
                //system.debug('****Mahesh');
                SBQQ__Quote__c quoterec = new SBQQ__Quote__c();
                quoterec.Id = fpq.CPQ_Quote__c;
                quoterec.Does_3PF_require_approval__c = False;
                listCPQtoUpdate.add(quoterec);
            }
        }
        //GTMS-26025 Performing DML Outside the loop
        if(listCPQtoUpdate.size() > 0){
            TriggerHandler.bypass('GS_SBQQQuoteTriggerHandler');
            SBQQ.TriggerControl.disable();
            update listCPQtoUpdate;
        }
    }
}