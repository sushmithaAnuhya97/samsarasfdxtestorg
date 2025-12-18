/**
* Created By : 
* @Date 
*
* @description : This class will be responsible for handling all Channel Relationship  Operations
* SFA-11
* Dec-01-2023 : Rodrigo - (GTMS-16044) country/state code related logic
* May-07-2025 : Azra - (GTMS- 27725) Replaced Partner_Contact__c with Channel_Partner_Representative__c
**/
public class ChannelRelationshipHelper {
    
    // GTMS-16044 to set field values if manually set
    public static void setDefualtFieldValues(List<Channel_Relationship__c> newChannelRelationshipList) { 
        Set<Id>opptyIdList = new Set<Id>();
        Set<Id>accountIdList = new Set<Id>();
        
        // get all opportunity ids
        FOR(Channel_Relationship__c crObj : newChannelRelationshipList) {
            if (crObj.Channel_Partner__c!=null)
                accountIdList.add(crObj.Channel_Partner__c);
            opptyIdList.add(crObj.Opportunity__c);
        }
        Map<Id, Opportunity>  opptyMap = new Map<Id, Opportunity>([SELECT Id, Insurance_Partner__c, AccountId,
                                                                    Subsidy_Amount_New__c 
                                                                   FROM Opportunity 
                                                                   WHERE Id IN: opptyIdList]);
        // get all account id
        FOR(Opportunity opptyObj : opptyMap.values()) {
            accountIdList.add(opptyObj.AccountId);
            if(opptyObj.Insurance_Partner__c!=null)
                accountIdList.add(opptyObj.Insurance_Partner__c);
        }
        
        Map<Id, Account> accountMap = new Map<Id, Account>([SELECT Id, Billing_Contact__c, BillingCity, BillingCountryCode,
                                                            BillingStateCode, BillingPostalCode, BillingStreet
                                                             FROM Account 
                                                            WHERE Id IN: accountIdList]);
        FOR(Channel_Relationship__c crObj : newChannelRelationshipList) {
            Opportunity opptyRec =  opptyMap.get(crObj.Opportunity__c);
            Account acctRec = new Account();
            Account acctRec2 = new Account();
            if (crObj.Channel_Partner__c != null)
                acctRec2 = accountMap.get(crObj.Channel_Partner__c);
            if(opptyRec != null) {
                if (crObj.Channel_Partner__c == null)
                	acctRec2 = accountMap.get(opptyRec.Insurance_Partner__c);
                acctRec = accountMap.get(opptyRec.AccountId);
            }
            
            if(crObj.Samsara_Product_SKU__c == null) {
                crObj.Samsara_Product_SKU__c = crObj.Product_Type__c;
            }
            if(crObj.Channel_Partner_Representative__c  == null && acctRec != null) {
                if(acctRec != null)
                	crObj.Channel_Partner_Representative__c  = acctRec.Billing_Contact__c;
            }
            if(crObj.Customer_Account__c == null && opptyRec != null) {
                crObj.Customer_Account__c = opptyRec.AccountId;
            }
            if(crObj.Customer_Contact__c == null && acctRec2 != null) {
                if(acctRec != null)
                	crObj.Customer_Contact__c = acctRec2.Billing_Contact__c;
            }
            if(crObj.Subsidy_Amount__c == null && opptyRec != null) {
                crObj.Subsidy_Amount__c = opptyRec.Subsidy_Amount_New__c;
            }
            if(crObj.Customer_Address__City__s==null && acctRec != null) {
                crObj.Customer_Address__City__s = acctRec.BillingCity;
            }
            
            if(crObj.Customer_Address__CountryCode__s==null && acctRec != null) {
                crObj.Customer_Address__CountryCode__s = acctRec.BillingCountryCode;
            }
            
            if(crObj.Customer_Address__PostalCode__s==null && acctRec != null) {
                crObj.Customer_Address__PostalCode__s = acctRec.BillingPostalCode;
            }
            if(crObj.Customer_Address__StateCode__s==null && acctRec != null && crObj.Customer_Address__CountryCode__s==acctRec.BillingCountryCode) {
                crObj.Customer_Address__StateCode__s = acctRec.BillingStateCode;
            }
            if(crObj.Customer_Address__Street__s==null && acctRec != null) {
                crObj.Customer_Address__Street__s = acctRec.BillingStreet;
            }
            
            if(crObj.Partner_Address__City__s==null && acctRec2 != null) {
                crObj.Partner_Address__City__s = acctRec2.BillingCity;
            }
            
            if(crObj.Partner_Address__CountryCode__s==null && acctRec2 != null) {
                crObj.Partner_Address__CountryCode__s = acctRec2.BillingCountryCode;
            }
            
            if(crObj.Partner_Address__PostalCode__s==null && acctRec2 != null) {
                crObj.Partner_Address__PostalCode__s = acctRec2.BillingPostalCode;
            }
            if(crObj.Partner_Address__StateCode__s==null && acctRec2 != null && crObj.Partner_Address__CountryCode__s==acctRec2.BillingCountryCode) {
                crObj.Partner_Address__StateCode__s = acctRec2.BillingStateCode;
            }
            if(crObj.Partner_Address__Street__s==null && acctRec2 != null) {
                crObj.Partner_Address__Street__s = acctRec2.BillingStreet;
            }
        }
    }
    
    public static void updateCPQQuoteWithPartnerDetails(List<Channel_Relationship__c> newChannelRelationshipList){
        Map<Id, Channel_Relationship__c> oppIdToChannelRelationship = new Map<Id, Channel_Relationship__c>();

        for(Channel_Relationship__c channelRel: newChannelRelationshipList){
            if(channelRel.Opportunity__c != null){
                oppIdToChannelRelationship.put(channelRel.Opportunity__c, channelRel);
            }
        }

        Map<Id, SBQQ__Quote__c> cpqDraftQuotes = new Map<Id, SBQQ__Quote__c>([  SELECT  Id,
                                                                                        SBQQ__Partner__c, 
                                                                                        SBQQ__Opportunity2__c,
                                                                              			Channel_Partner_Discount__c 
                                                                                FROM SBQQ__Quote__c
                                                                                WHERE SBQQ__Opportunity2__c IN : oppIdToChannelRelationship.keySet()
                                                                                AND SBQQ__Status__c = :  'Draft']);
        
        for(SBQQ__Quote__c cpqDraftQuote: cpqDraftQuotes.values()){
            Id partnerAccount = oppIdToChannelRelationship.get(cpqDraftQuote.SBQQ__Opportunity2__c).Channel_Partner__c;
            cpqDraftQuote.SBQQ__Partner__c = partnerAccount;
            cpqDraftQuote.Channel_Partner_Discount__c = oppIdToChannelRelationship.get(cpqDraftQuote.SBQQ__Opportunity2__c).Partner_Discount__c;
        }                  
        
        if(cpqDraftQuotes.size() > 0){
            update cpqDraftQuotes.values();
        }
    } 
    
    // GTMS-16044 get country/state code starts here
    public class countryStateCodeReq {
        @InvocableVariable public string countryName;
        @InvocableVariable public string stateName;
        @InvocableVariable public string countryCode;
        @InvocableVariable public string stateCode;
    }
    
    public class countryStateCodeResp {
        @InvocableVariable public string countryCode;
        @InvocableVariable public string stateCode;
        @InvocableVariable public string countryName;
        @InvocableVariable public string stateName;
    }
    
    @InvocableMethod(label='Get Country/State Code')
    public static List<countryStateCodeResp> getCountryStateCode(List<countryStateCodeReq> requestData){ 
        List<countryStateCodeResp> responseDataList = new List<countryStateCodeResp>();
        countryStateCodeResp responseData = new countryStateCodeResp();
        //if (requestData[0].countryName != null) {
            string countryName = requestData[0].countryName;
            string stateName = requestData[0].stateName;
            string countryCode = requestData[0].countryCode;
            string stateCode = requestData[0].stateCode;
            Schema.DescribeFieldResult fieldResultCountry = User.Countrycode.getDescribe();
            List<Schema.PicklistEntry> pleCountry = fieldResultCountry.getPicklistValues();
            //System.debug('Picklist::'+pleCountry);
            for( Schema.PicklistEntry f : pleCountry){
                if(countryName!= null && countryName == f.getLabel())
                    responseData.countryCode = f.getValue();
                if(countryCode!= null && countryCode == f.getValue())
                    responseData.countryName = f.getLabel();
                //System.debug(f.getLabel() +'::'+ f.getValue());
            }
            
            Schema.DescribeFieldResult fieldResultState = User.Statecode.getDescribe();
            List<Schema.PicklistEntry> pleState = fieldResultState.getPicklistValues();
            //System.debug('Picklist::'+pleState);
            for( Schema.PicklistEntry f : pleState){
                if(stateName!= null && stateName == f.getLabel())
                    responseData.stateCode = f.getValue();
                if(stateCode!= null && stateCode == f.getValue())
                    responseData.stateName = f.getLabel();
                //System.debug(f.getLabel() +'::'+ f.getValue());
            }
        
            
        //}
        system.debug('responseData ' + responseData);
        responseDataList.add(responseData);
       	return responseDataList;
    }
    // GTMS-16044 get country/state code ends here
    
    // GTMS-26105 14 Day Auto-Tag for Partner Deals code starts here
    public static void updNewChannelRelationship14DaysAutoTag(List<Channel_Relationship__c> newChannelRelationshipList) {
        If(newChannelRelationshipList[0].Customer_Account__c != null && newChannelRelationshipList[0].Channel_Partner__c != null) {
            Channel_Relationship__c OldCR = new Channel_Relationship__c();
            
            String query = 'SELECT ';
            for(Schema.FieldSetMember f : SObjectType.Channel_Relationship__c.fieldSets.Auto_Tag_Partner_Deals_14_Days.getFields()) {
                query += f.getFieldPath() + ', ';
            }
            query += 'Id, Opportunity__c, Opportunity__r.LastModifiedDate FROM Channel_Relationship__c WHERE Channel_Partner__c = \'' + newChannelRelationshipList[0].Channel_Partner__c
                + '\' AND Opportunity__r.StageName = \'Closed Lost\' AND Opportunity__r.CloseDate = LAST_N_DAYS:14 AND Opportunity__r.IsClosed = true'
                + ' AND Opportunity__r.AccountId = \'' + newChannelRelationshipList[0].Customer_Account__c 
                + '\' Order by Opportunity__r.LastModifiedDate desc LIMIT 1';
            
            if(Database.query(query).size() > 0){
                OldCR = Database.query(query);
                Channel_Relationship__c NewCR = new Channel_Relationship__c();           
                List<Schema.FieldSetMember> schemaset= Schema.SObjectType.Channel_Relationship__c.fieldSets.Auto_Tag_Partner_Deals_14_Days.getFields();
                NewCR.put('Id', newChannelRelationshipList[0].Id);
                NewCR.put('Source_Opportunity__c', OldCR.Opportunity__c);
                NewCR.put('Partner_Deal_14_Day_Auto_Tag__c', true);
                for(integer a=0; a<schemaset.size(); a++){
                    NewCR.put(schemaset[a].getFieldPath(), OldCR.get(schemaset[a].getFieldPath()));
                }
                
                Update NewCR;
            }
        }  
    }
    // GTMS-26105 14 Day Auto-Tag for Partner Deals code ends here
}