//public class DNBI_Integration {
global class DNBI_Integration {
    
    //Function: Call the D&B Direct API to obtain the Credit Check fields for a particular company
    //Inputs: accountName: Name of Company, territoryName: Territory/State Abbreviation, accountID: SFDC Internal Account ID, countryCode: Country Abbreviation
    //Outputs: void
    
    //public void getDNBIFields(String accountName, String territoryName, String accountID, String countryCode){
    @InvocableMethod(label='getDNBIFields' description='Emails finance partners with relevant information for partners to execute assessment')
    webservice static void getDNBIFields(List<Id> newAcctList){
        
        List<Account> accounts = [SELECT  Id, 
                                  Name, 
                                  BillingStreet, 
                                  BillingCity, 
                                  BillingStateCode, 
                                  BillingCountryCode, 
                                  BillingPostalCode,
                                  Website
                                  FROM Account WHERE Id IN :newAcctList];
        
        List<String> accountName = new List<String>();
        List<String> accountID = new List<String>();
        List<String> territoryName = new List<String>();
        List<String> countryCode = new List<String>();
        List<String> streetName = new List<String>();
        List<String> cityName = new List<String>();
        List<String> zipCode = new List<String>();
        List<String> website = new List<String>();
        
        for(Account act: accounts){
            accountName.add(act.Name);
            accountID.add(String.valueOf(act.Id));
            territoryName.add(act.BillingStateCode);
            countryCode.add(act.BillingCountryCode);
            streetName.add(act.BillingStateCode);
            cityName.add(act.BillingCity);
            zipCode.add(act.BillingPostalCode);
            website.add(act.Website);
        }
        
        
        AuthenticateDNBI(accountName, territoryName, accountID, countryCode, streetName,cityName, zipCode, website);
        //setPaydex(paydex,opID);
    }
    
    @future(callout=true)
    public static void AuthenticateDNBI(List<String> accountName, List<String> territoryName, List<String> accountID, List<String> countryCode,  List<String> streetName, List<String> cityName, List<String> zipCode, List<String> website){
        
        ///DNB_Settings__c auth_settings = DNB_Settings__c.getInstance();
        
        //Retrieve the Custom Settings for D&B
        DNB_Settings__c auth_settings = [Select Id, Token_Last_Updated__c, Token__c, DNBIPwd__c, DNBIUser__c From DNB_Settings__c];
        //DNB_Settings__c auth_settings = DNB_Settings__c.getOrgDefaults();
        
        //System.debug('Time: '+auth_settings.Token_Last_Updated__c);
        
        String AuthenticationToken = '';
        Http h = new Http();
        
        //System.debug('Time Diff: '+decimal.valueof((System.now().getTime() - auth_settings.Token_Last_Updated__c.getTime())/(60*60*1000)));
        if(auth_settings.Token__c == null || auth_settings.Token_Last_Updated__c == null || decimal.valueof((System.now().getTime() - auth_settings.Token_Last_Updated__c.getTime())/(60*60*1000)) >= 24){
            
            //User ID and Password to authenticate with D&B Direct API
            
            String DNBIUser = auth_settings.DNBIUser__c;
            String DNBIPwd = auth_settings.DNBIPwd__c;
            
            // Instantiate a new HTTP request, specify the method (POST) as well as the endpoint
            HttpRequest req = new HttpRequest();
            String DNBIAuthUrl = 'https://direct.dnb.com/Authentication/V2.0/'; 
            req.setEndpoint(DNBIAuthUrl);
            req.setMethod('POST');
            req.setHeader('x-dnb-user', DNBIUser);
            req.setHeader('x-dnb-pwd', DNBIPwd);
            
            
            // Send the request, and return a response
            HttpResponse res = h.send(req);
            //System.debug(res);
            
            //Parse the returned JSON to retrieve the Authenticatio Token
            Map<String, Object> authBody = (Map<String, Object>)JSON.deserializeUntyped(res.getBody());
            Map<String, Object> authDetail = (Map<String, Object>) authBody.get('AuthenticationDetail');
            AuthenticationToken = (String)authDetail.get('Token');
            System.debug(AuthenticationToken);
            auth_settings.Token__c = AuthenticationToken;
            auth_settings.Token_Last_Updated__c = System.now();
            
        } else{
            AuthenticationToken = auth_settings.Token__c;
        }
        
        List<Account> account = [Select Id, BillingCity, BillingPostalCode  from Account where Id in : accountID];
		List<Credit_Report__c> cs_report = new List<Credit_Report__c>();
        for(Integer index = 0; index < accountName.size() ; index++){
            
            //String account_name = accountName[index].replace(' ','%20');
            String web = '';
            if(website[index] != null){
                web = '&URLText='+EncodingUtil.urlEncode(website[index],'UTF-8');
            }
            String DNBIDunsUrl = 'https://direct.dnb.com/V5.0/organizations?CountryISOAlpha2Code='+EncodingUtil.urlEncode(countryCode[index],'UTF-8')+'&SubjectName='+EncodingUtil.urlEncode(accountName[index],'UTF-8')+'&match=true&MatchTypeText=Advanced&TerritoryName='+EncodingUtil.urlEncode(territoryName[index],'UTF-8')+'&StreetAddressLine-1='+EncodingUtil.urlEncode(streetName[index],'UTF-8')+'&PrimaryTownName='+EncodingUtil.urlEncode(cityName[index],'UTF-8')+'&FullPostalCode='+EncodingUtil.urlEncode(zipCode[index],'UTF-8')+web+'&ConfidenceLowerLevelThresholdValue=4';
            System.debug(DNBIDunsUrl);
            
            HttpRequest req = new HttpRequest();
            req.setEndpoint(DNBIDunsUrl);
            req.setMethod('GET');
            req.setHeader('Authorization', AuthenticationToken);
            
            // Send the request, and return a response
            HttpResponse duns_res = h.send(req);
            System.debug(duns_res.getBody());
            
            
            
            if(duns_res.getStatusCode() == 200){
                
                account[index].DNBI_Data_Available__c = true;
                Map<String, Object> dunsBody = (Map<String, Object>)JSON.deserializeUntyped(duns_res.getBody());
                Map<String, Object> matchResponse = (Map<String, Object>) dunsBody.get('MatchResponse');
                Map<String, Object> matchDetail = (Map<String, Object>) matchResponse.get('MatchResponseDetail');
                List<Object> matchCandidate = (List<Object>) matchDetail.get('MatchCandidate');
                //String duns = (String)matchCandidate.get('DUNSNumber');
                
                Map<String, Object> candidate = (Map<String, Object>) matchCandidate[0];
                boolean found_match = true;
                /*for(Integer i = 0; i < matchCandidate.size() ; i++){

candidate = (Map<String, Object>) matchCandidate[i];
Map<String, Object> candidate_address = (Map<String, Object>)candidate.get('PrimaryAddress');
String candidate_city = (String)candidate_address.get('PrimaryTownName');
String candidate_zip = (String)candidate_address.get('PostalCode');

if(candidate_city.toLowerCase() == account[index].BillingCity.toLowerCase() && candidate_zip == account[index].BillingPostalCode.substringBefore('-')) break;

if(i == (matchCandidate.size() - 1)) found_match = true;
}*/
                
                if(found_match || Test.isRunningTest()){
                    
                    String duns = (String)candidate.get('DUNSNumber');
                    
                    String match_name = (String)((Map<String, Object>)((Map<String, Object>)candidate.get('OrganizationPrimaryName')).get('OrganizationName')).get('$');
                    System.debug('Match Name: '+match_name);
                    String DNBIPaydexUrl = 'https://direct.dnb.com/V5.0/organizations/'+duns+'/products/PIAP_ENH';
                    //String DNBIPaydexUrl = 'https://maxcvservices.dnb.com/V4.0/organizations/804735132/products/PIAP_ENH';
                    req.setEndpoint(DNBIPaydexUrl);
                    req.setMethod('GET');
                    req.setHeader('Authorization', AuthenticationToken);
                    HttpResponse res = h.send(req);
                    
                    String DNBIFinanceUrl = 'https://direct.dnb.com/V5.0/organizations/'+duns+'/products/PBPR_STD';
                    //String DNBIFinanceUrl = 'https://maxcvservices.dnb.com/V4.0/organizations/804735132/products/PBPR_STD';
                    HttpRequest risk_req = new HttpRequest();
                    risk_req.setEndpoint(DNBIFinanceUrl);
                    risk_req.setMethod('GET');
                    risk_req.setHeader('Authorization', AuthenticationToken);
                    HttpResponse risk_res = h.send(risk_req);
                    
                    String DNBIViabilityUrl = 'https://direct.dnb.com/V5.0/organizations/'+duns+'/products/VIAB_RAT';
                    //String DNBIViabilityUrl = 'https://maxcvservices.dnb.com/V4.0/organizations/804735132/products/VIAB_RAT';
                    HttpRequest viab_req = new HttpRequest();
                    viab_req.setEndpoint(DNBIViabilityUrl);
                    viab_req.setMethod('GET');
                    viab_req.setHeader('Authorization', AuthenticationToken);
                    HttpResponse viab_res = h.send(viab_req);
                    
                    Integer paydex;
                    Integer avghigh_credit_amount;
                    Double slow_neg_exp_count;
                    Double exp_count;
                    Double slow_neg_exp_percentage;
                    String payment_behavior_text;
                    Integer payment_behavior_days; 
                    boolean late_pay; 
                    
                    if(res.getStatusCode() == 200){
                        
                        String reformatted_paydex_response = res.getBody().replace('$','Dollars').replace('@','');
                        
                        //DNBI_PIAP_ENH paydexBody = (DNBI_PIAP_ENH)JSON.deserialize(reformatted_paydex_response, DNBI_PIAP_ENH.class);
                        DNBI_PIAP_ENH paydexBody = DNBI_PIAP_ENH.parse(reformatted_paydex_response);
                        
                        try{
                            paydex = paydexBody.OrderProductResponse.OrderProductResponseDetail.Product.Organization.BusinessTrading.Purchaser.CurrentPaydexScore.TwentyFourMonthsPaydex[0].PaydexScore;
                        } catch(Exception e){
                            paydex = null;
                        }
                        
                        try{
                            avghigh_credit_amount = paydexBody.OrderProductResponse.OrderProductResponseDetail.Product.Organization.BusinessTrading.Purchaser.PurchaserDerivedData[0].TwentyFourMonthsDataCoveragePayments.PaymentPeriodSummary[0].PaymentsWithHighCredit.AverageHighCreditAmount.Dollars;
                        } catch(Exception e){
                            avghigh_credit_amount = null;
                        }
                        
                        //Integer slow_neg_exp_count = paydexBody.OrderProductResponse.OrderProductResponseDetail.Product.Organization.BusinessTrading.Purchaser.PurchaserDerivedData[0].TwentyFourMonthsDataCoveragePayments.SlowNegativeExperienceCount;
                        try{
                            slow_neg_exp_count = paydexBody.OrderProductResponse.OrderProductResponseDetail.Product.Organization.BusinessTrading.Purchaser.PurchaserDerivedData[0].TwentyFourMonthsDataCoveragePayments.PaymentPeriodSummary[0].PaymentsWithHighCredit.SlowNegativeExperienceCount;
                        } catch(Exception e){
                            slow_neg_exp_count = null;
                        }
                        
                        try{
                            exp_count = paydexBody.OrderProductResponse.OrderProductResponseDetail.Product.Organization.BusinessTrading.Purchaser.PurchaserDerivedData[0].TwentyFourMonthsDataCoveragePayments.PaymentPeriodSummary[0].PaymentsWithHighCredit.ExperienceCount;
                        } catch(Exception e){
                            exp_count = 0.0;
                        }
                        
                        try{
                            slow_neg_exp_percentage = (slow_neg_exp_count*100.0)/exp_count;
                        } catch(Exception e){
                            slow_neg_exp_percentage = null;
                        }
                        
                        try{
                            payment_behavior_text = paydexBody.OrderProductResponse.OrderProductResponseDetail.Product.Organization.BusinessTrading.Purchaser.CurrentPaydexScore.TwentyFourMonthsPaydex[0].PaymentBehaviorText;
                        } catch(Exception e){
                            payment_behavior_text = '';
                        }
                        
                        try{
                            late_pay = payment_behavior_text.contains('Beyond');
                        } catch(Exception e){
                            late_pay = false; 
                        }
                        
                        try{
                            payment_behavior_days = paydexBody.OrderProductResponse.OrderProductResponseDetail.Product.Organization.BusinessTrading.Purchaser.CurrentPaydexScore.TwentyFourMonthsPaydex[0].PaymentBehaviorDaysQuantity;
                        } catch(Exception e){
                            payment_behavior_days = null;
                        }
                        
                        System.debug('Paydex '+paydex);
                        System.debug('Avg High Credit '+avghigh_credit_amount);
                        System.debug('Slow Neg Exp '+slow_neg_exp_percentage);
                    } else{
                        System.debug('Payment Data Not Available');
                    }
                    
                    Integer rec_credit_limit;
                    Integer comm_credit_percentage;
                    Integer fin_stress_score;
                    
                    if(risk_res.getStatusCode() == 200){
                        
                        String reformatted_risk_response = risk_res.getBody().replace('$','Dollars').replace('@','');
                        
                        //DNBI_PBPR_STD riskBody = (DNBI_PBPR_STD)JSON.deserialize(reformatted_risk_response, DNBI_PBPR_STD.class);
                        DNBI_PBPR_STD riskBody = DNBI_PBPR_STD.parse(reformatted_risk_response);
                        
                        try{
                            rec_credit_limit = riskBody.OrderProductResponse.OrderProductResponseDetail.Product.Organization.Assessment.DNBCreditLimitRecommendation.MaximumRecommendedLimitAmount.Dollars;
                        } catch(Exception e){
                            rec_credit_limit = null;
                        }
                        
                        try{
                            comm_credit_percentage = riskBody.OrderProductResponse.OrderProductResponseDetail.Product.Organization.Assessment.CommercialCreditScore[0].NationalPercentile;
                        } catch(Exception e){
                            comm_credit_percentage = null;
                        }
                        
                        try{
                            fin_stress_score = riskBody.OrderProductResponse.OrderProductResponseDetail.Product.Organization.Assessment.FinancialStressScore[0].NationalPercentile;
                        } catch(Exception e){
                            fin_stress_score = null;
                        }
                    } else{
                        System.debug('Risk Data Not Available');
                    }
                    
                    System.debug('Rec Credit Limit '+rec_credit_limit);
                    System.debug('Comm Credit Percentage '+comm_credit_percentage);
                    System.debug('Fin Stress Score '+fin_stress_score);
                    
                    
                    if(viab_res.getStatusCode() == 200){
                        String reformatted_viab_response = viab_res.getBody().replace('$','Dollars').replace('@','');
                        
                        //DNBI_VIAB_RAT viabBody = (DNBI_VIAB_RAT)JSON.deserialize(reformatted_viab_response, DNBI_VIAB_RAT.class);
                        DNBI_VIAB_RAT viabBody = DNBI_VIAB_RAT.parse(reformatted_viab_response);
                        
                        String viability_rating;
                        try{
                            viability_rating = viabBody.OrderProductResponse.OrderProductResponseDetail.Product.Organization.Assessment.DNBViabilityRating.DNBViabilityRating;
                        } catch(Exception e){
                            viability_rating = '';
                        }
                        
                        String years_in_business;
                        try{
                            years_in_business = viabBody.OrderProductResponse.OrderProductResponseDetail.Product.Organization.Assessment.DNBViabilityRating.OrganizationProfileDetail.YearsInBusinessDetail.AssessmentText[0];
                        } catch(Exception e){
                            years_in_business = '';
                        }
                        
                        System.debug('Viab Rating '+viability_rating);
                        System.debug('Years In Business '+years_in_business);
                        
                        //account[index].DNBI_PAYDEX__c = paydex;
                        //account[index].DNBI_Avg_High_Credit_Amount__c = avghigh_credit_amount;
                        //account[index].DNBI_SlowNegExpCount__c = slow_neg_exp_percentage;
                        //account[index].DNBI_Recommended_Credit_Limit__c = rec_credit_limit;
                        //account[index].DNBI_Commercial_Credit_Percentage__c = comm_credit_percentage;
                        //account[index].DNBI_Financial_Stress_Score__c = fin_stress_score;
                        //account[index].DNBI_DUNS_NO__c = duns;
                        //account[index].DNBI_Trade_Experiences_Count__c = exp_count;
                        //account[index].DNBI_Match_Name__c = match_name;
                        
                        
                        Credit_Report__c cr = new Credit_Report__c();
                        
                        cr.Name = 'Dun & Bradstreet';
                        cr.RecordTypeId = Schema.SObjectType.Credit_Report__c.getRecordTypeInfosByName().get('Dun & Bradstreet').getRecordTypeId();
                        cr.Account__c = Id.valueOf(accountID[index]);
                        cr.D_B_Data_Available__c = true;
                        cr.PAYDEX__c = paydex;
                        cr.Average_High_Credit_Amount__c = avghigh_credit_amount;
                        cr.Slow_Negative__c = slow_neg_exp_percentage;
                        cr.Credit_Limit__c = rec_credit_limit;
                        cr.Commercial_Credit_Percentile__c = comm_credit_percentage;
                        cr.Financial_Stress_Score_Percentile__c = fin_stress_score;
                        cr.DUNS_Number__c = duns;
                        cr.Trade_Experiences_Count__c = exp_count;
                        cr.Report_Match_Name__c = match_name;
                        cr.Credit_Report_Timestamp__c = Datetime.now();
                        cs_report.add(cr);                       
                    } else{
                        System.debug('Viability Data Not Available');
                    }
                    
                    /*account.DNBI_Data_Available__c = false;
account.DNBI__PAYDEX__c = null;
account.DNBI_Avg_High_Credit_Amount__c = null;
account.DNBI_SlowNegExpCount__c = null;
account.DNBI_Recommended_Credit_Limit__c = null;
account.DNBI_Commercial_Credit_Percentage__c = null;
account.DNBI_Financial_Stress_Score__c = null;*/
                } else {
                    System.debug('DUNS Number Not Found');
                    account[index].DNBI_Data_Available__c = false;
                }  
                
            } else{
                System.debug('DUNS Number Not Found');
                account[index].DNBI_Data_Available__c = false;
            }
            
        }
		//GTMS-26025 - Performing DML outside the loop
		if(!Test.isRunningTest() && !cs_report.isEmpty()){
			insert cs_report;
		}
        if(!Test.isRunningTest()){
            update auth_settings;
        }
    }
    
}