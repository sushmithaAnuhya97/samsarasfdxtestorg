/*
* 03/04/2021 Ron (GTMS-2958) Add reason code to German credit pull
* 03/26/20 Kai-Rey - (GTMS-705) made changes to allows for more accurate evaluation of customers credit.
*/

global class Creditsafe{
    
    public class jsonWrapper {
        public String username {get; set;}
        public String password {get; set;}
    }
    @InvocableMethod(label='getCredisafeInfo' description='Internal Financing for non-us customers')
    webservice static void getCredisafeInfo(List<Id> newAcctList){
        
        List<Account> accounts = [SELECT  Id, 
                                  Name, 
                                  BillingStreet, 
                                  BillingCity, 
                                  BillingStateCode, 
                                  BillingCountryCode, 
                                  BillingPostalCode
                                  FROM Account WHERE Id IN :newAcctList];
        
        List<String> accountName = new List<String>();
        List<String> accountID = new List<String>();
        List<String> territoryName = new List<String>();
        List<String> countryCode = new List<String>();
        List<String> streetName = new List<String>();
        List<String> cityName = new List<String>();
        List<String> zipCode = new List<String>();
        
        for(Account act: accounts){
            accountName.add(act.Name);
            accountID.add(String.valueOf(act.Id));
            territoryName.add(act.BillingStateCode);
            countryCode.add(act.BillingCountryCode);
            streetName.add(act.BillingStreet);
            cityName.add(act.BillingCity);
            zipCode.add(act.BillingPostalCode);
        }
        
        creditsafeIntegration(accountName, territoryName, accountID, countryCode, streetName, cityName,zipCode);
        //setPaydex(paydex,opID);
    }
    
    @future(callout=true)
    public static void creditsafeIntegration(List<String> accountName, List<String> territoryName, List<String> accountID, List<String> countryCode, List<String> streetName,List<String> cityName, List<String> zipCode){
        Creditsafe_Settings__c auth_settings = [Select Id, Token_Last_Updated__c, Token__c, CreditsafePassword__c, CreditsafeUser__c From Creditsafe_Settings__c];
        
        String AuthenticationToken = '';
        Http h = new Http();
        
        if(auth_settings.Token__c == null || auth_settings.Token_Last_Updated__c == null || decimal.valueof((System.now().getTime() - auth_settings.Token_Last_Updated__c.getTime())/(60*60*1000)) >= 24){
            String CreditsafeUser = auth_settings.CreditsafeUser__c;
            String CreditsafePassword = auth_settings.CreditsafePassword__c;
            
            jsonWrapper wrap = new jsonWrapper();
            wrap.username = CreditsafeUser;
            wrap.password = CreditsafePassword;
            String jsonBody = JSON.serialize(wrap);
            HttpRequest req = new HttpRequest();
            String CreditsafeAuthUrl = 'https://connect.creditsafe.com/v1/authenticate'; 
            //String requestBody = '{"username": '+CreditsafeUser+',"password": '+CreditsafePassword+'}"';
            req.setEndpoint(CreditsafeAuthUrl);
            req.setMethod('POST');
            req.setHeader('Content-Type', 'application/json');
            req.setBody(jsonBody);
            
            HttpResponse res;
            try {
                res = h.send(req);
                if (res.getStatusCode() == 200) {
                    Map<String, Object> authBody = (Map<String, Object>)JSON.deserializeUntyped(res.getBody());
                    //Map<String, Object> authDetail = (Map<String, Object>) authBody.get('AuthenticationDetail');
                    AuthenticationToken = (String)authBody.get('token');
                    auth_settings.Token__c = AuthenticationToken;
                    auth_settings.Token_Last_Updated__c = System.now();
                }
                else {
                    String errorMessage = 'POST Authentication request failed: Status Code ' + res.getStatusCode() + ' Error Message '+res.getBody();
                    System.debug(errorMessage);
                    Logger.atError()
                        .setClassName('Creditsafe')
                        .setMethod('creditsafeIntegration')
                        .setExceptionOrMessage('Account Id'+ accountID+'POST Authentication request failed: Status Code ' + res.getStatusCode() + ' Error Message '+res.getBody());
                    Logger.insertMasterLogs();
                    sendEmailAlert('Creditsafe Authentication Failed', errorMessage, accountID);
                }
            } catch (Exception e) {
                String errorMessage = 'POST Authentication callout exception: ' + e.getMessage();
                System.debug(errorMessage);
                Logger.atError()
                    .setClassName('Creditsafe')
                    .setMethod('creditsafeIntegration')
                    .setExceptionOrMessage('Account Id'+ accountID+' POST Authentication callout exception: ' + e.getMessage());
                Logger.insertMasterLogs();
                sendEmailAlert('Creditsafe Authentication Failed', errorMessage, accountID);
                return;
            }
        } else{
            AuthenticationToken = auth_settings.Token__c;
        }
        
        List<Credit_Report__c> cs_report = new List<Credit_Report__c>();
        //List<Account> account = [Select Id, BillingCity, BillingPostalCode  from Account where Id in : accountID];
        for(Integer index = 0; index < accountName.size() ; index++){
            
            String account_name = EncodingUtil.urlEncode(accountName[index],'UTF-8');
            String zip_code = EncodingUtil.urlEncode(zipCode[index],'UTF-8');
            String city = EncodingUtil.urlEncode(cityName[index],'UTF-8');
            String street = EncodingUtil.urlEncode(streetName[index],'UTF-8');
            //String CreditsafeCompanyUrl = 'https://connect.creditsafe.com/v1/companies?countries='+countryCode[index]+'&name='+account_name+'&city='+city+'&postCode='+zip_code+'&street='+street;
            //String CreditsafeCompanyUrl = 'https://connect.sandbox.creditsafe.com/v1/companies?countries='+countryCode[index]+'&name='+account_name+'&postCode='+zip_code.substring(0,2)+'*';
            String CreditsafeCompanyUrl = 'https://connect.creditsafe.com/v1/companies?countries='+countryCode[index]+'&name='+account_name+'&postCode='+zip_code;
            
            HttpRequest req = new HttpRequest();
            req.setEndpoint(CreditsafeCompanyUrl);
            req.setMethod('GET');
            req.setHeader('Authorization', AuthenticationToken);
            
            // Send the request, and return a response
            HttpResponse report_res;
            try{
                HttpResponse creditsafe_res = h.send(req);
                
                Map<String, Object> company_matches = (Map<String, Object>)JSON.deserializeUntyped(creditsafe_res.getBody());
                
                List<Object> matchCandidate = (List<Object>)company_matches.get('companies');
                String companyId = (String)((Map<String, Object>)matchCandidate[0]).get('id');
                String companyName = (String)((Map<String, Object>)matchCandidate[0]).get('name');
                /*if(matchCandidate != null) {
                    for(Integer i = 0; i < matchCandidate.size() ; i++){
                    
                    Map<String, Object> candidate = (Map<String, Object>) matchCandidate[i];
                    Map<String, Object> candidate_address = (Map<String, Object>)candidate.get('address');
                    String candidate_city = (String)candidate_address.get('city');
                    String candidate_zip = ((String)candidate_address.get('postCode')).replace(' ','');
                    
                    if(candidate_city.toLowerCase() == account[index].BillingCity.toLowerCase() && candidate_zip == account[index].BillingPostalCode.substringBefore('-').replace(' ','')){
                    companyId = (String)candidate.get('id');
                    companyName = (String)candidate.get('name');
                    break;
                    }
                    
                    if(i == (matchCandidate.size() - 1)) found_match = false;
                    }
                    } else {
                    found_match = false;
                    }*/ 
                String reasonCodeCheck = countryCode[index] == 'DE'? companyId+'?customData=de_reason_code::2':companyId;
                String ReportURL = 'https://connect.creditsafe.com/v1/companies/'+reasonCodeCheck;
                
                HttpRequest report_req = new HttpRequest();
                report_req.setEndpoint(ReportURL);
                report_req.setMethod('GET');
                report_req.setHeader('Authorization', AuthenticationToken);
                
                report_res = h.send(report_req);
            }
            catch (Exception e) {
                Logger.atError()
                    .setClassName('Creditsafe')
                    .setMethod('creditsafeIntegration')
                    .setExceptionOrMessage('Account Id '+ accountID+'GET Authentication request failed: ' + report_res);
                Logger.insertMasterLogs();
                sendEmailAlert('Creditsafe Response Failed', 'GET Authentication request failed in catch block', accountID);
                return; 
            }
            if(report_res.getStatusCode() == 200){
                
                Map<String, Object> creditsafe_reponse;
                try{
                    creditsafe_reponse = (Map<String, Object>)JSON.deserializeUntyped(report_res.getBody());
                }catch(Exception e){
                    creditsafe_reponse = null;
                }
                
                Map<String, Object> report;
                try{
                    report = (Map<String, Object>)creditsafe_reponse.get('report');
                } catch(Exception e){
                    report = null;
                }
                Map<String, Object> companySummary;
                try{
                    companySummary = (Map<String, Object>)report.get('companySummary');
                } catch(Exception e){
                    companySummary = null;
                }
                Map<String, Object> financialStatements;
                Map<String, Object> financialStatementsOld;
                try{
                    financialStatements = (Map<String, Object>)((List<Object>)report.get('financialStatements'))[0];
                    financialStatementsOld = (Map<String, Object>)((List<Object>)report.get('financialStatements'))[1];
                } catch(Exception e){
                    financialStatements = null;
                    financialStatementsOld = null;
                }
                
                Map<String, Object> localFinancialStatements;
                Map<String, Object> localFinancialStatementsOld;
                try{
                    localFinancialStatements = (Map<String, Object>)((List<Object>)report.get('localFinancialStatements'))[0];
                    localFinancialStatementsOld = (Map<String, Object>)((List<Object>)report.get('localFinancialStatements'))[1];
                } catch(Exception e){
                    localFinancialStatements = null;
                    localFinancialStatementsOld = null;
                }
                
                Map<String, Object> companyIdentification;
                try{
                    companyIdentification = (Map<String, Object>)report.get('companyIdentification');
                } catch(Exception e){
                    companyIdentification = null;
                }
                
                Map<String, Object> additionalInformation;
                try{
                    additionalInformation = (Map<String, Object>)report.get('additionalInformation');
                } catch(Exception e){
                    additionalInformation = null;
                }
                
                String cs_id;
                try{
                    cs_id = (String)((Map<String, Object>)report).get('companyId');
                } catch(Exception e){
                    cs_id = '';
                }
                
                String commonValue;
                try{
                    commonValue = (String)((Map<String, Object>)companySummary.get('creditRating')).get('commonValue');
                } catch(Exception e){
                    commonValue = '';
                }
                String status;
                try{
                    status = (String)((Map<String, Object>)companySummary.get('companyStatus')).get('status');
                } catch(Exception e){
                    status = '';
                }
                String match_name;
                try{
                    match_name = (String)((Map<String, Object>)companySummary).get('businessName');
                } catch(Exception e){
                    match_name = '';
                }
                
                Decimal creditLimit;
                try{
                    creditLimit = decimal.valueOf((String)((Map<String, Object>)((Map<String, Object>)companySummary.get('creditRating')).get('creditLimit')).get('value'));
                } catch(Exception e){
                    creditLimit = null;
                }
                
                Decimal totalCurrentAssets;
                Decimal totalCurrentAssetsOld; 
                Decimal totalCurrentAssetsVariance; 
                try{
                    totalCurrentAssets = (Decimal)((Map<String, Object>)financialStatements.get('balanceSheet')).get('totalCurrentAssets');
                    totalCurrentAssetsOld = (Decimal)((Map<String, Object>)financialStatementsOld.get('balanceSheet')).get('totalCurrentAssets');
                } catch(Exception e){
                    totalCurrentAssets = null;
                    totalCurrentAssetsOld = null; 
                }
                totalCurrentAssetsVariance = calculateVariance(totalCurrentAssets, totalCurrentAssetsOld);
                
                Decimal totalCurrentLiabilities;
                Decimal totalCurrentLiabilitiesOld;
                Decimal totalCurrentLiabilitiesVariance; 
                try{
                    totalCurrentLiabilities = (Decimal)((Map<String, Object>)financialStatements.get('balanceSheet')).get('totalCurrentLiabilities');
                    totalCurrentLiabilitiesOld = (Decimal)((Map<String, Object>)financialStatementsOld.get('balanceSheet')).get('totalCurrentLiabilities');
                } catch(Exception e){
                    totalCurrentLiabilities = null;
                    totalCurrentLiabilitiesOld = null; 
                }
                totalCurrentLiabilitiesVariance = calculateVariance(totalCurrentLiabilities, totalCurrentLiabilitiesOld);
                
                Decimal totalAssets;
                Decimal totalAssetsOld; 
                Decimal totalAssetsVariance; 
                try{
                    totalAssets  = (Decimal)((Map<String, Object>)financialStatements.get('balanceSheet')).get('totalAssets');
                    totalAssetsOld  = (Decimal)((Map<String, Object>)financialStatementsOld.get('balanceSheet')).get('totalAssets');
                } catch(Exception e){	
                    totalAssets = null;
                    totalAssetsOld = null; 
                }
                totalAssetsVariance = calculateVariance(totalAssets, totalAssetsOld);
                
                Decimal totalLiabilities;
                Decimal totalLiabilitiesOld;
                Decimal totalLiabilitiesVariance; 
                try{
                    totalLiabilities = (Decimal)((Map<String, Object>)financialStatements.get('balanceSheet')).get('totalLiabilities');
                    totalLiabilitiesOld = (Decimal)((Map<String, Object>)financialStatementsOld.get('balanceSheet')).get('totalLiabilities');
                } catch(Exception e){
                    totalLiabilities = null;
                    totalLiabilitiesOld = null; 
                }
                totalLiabilitiesVariance = calculateVariance(totalLiabilities, totalCurrentLiabilitiesOld);
                
                Decimal revenue;
                Decimal revenueOld;
                Decimal revenueVariance; 
                try{
                    revenue = (Decimal)((Map<String, Object>)financialStatements.get('profitAndLoss')).get('revenue');
                    revenueOld = (Decimal)((Map<String, Object>)financialStatementsOld.get('profitAndLoss')).get('revenue');
                } catch(Exception e){
                    revenue = null;
                    revenueOld = null; 
                }
                revenueVariance = calculateVariance(revenue, revenueOld);
                
                Decimal operatingProfit;
                Decimal operatingProfitOld;
                Decimal operatingProfitVariance; 
                try{
                    operatingProfit = (Decimal)((Map<String, Object>)financialStatements.get('profitAndLoss')).get('operatingProfit');
                    operatingProfitOld = (Decimal)((Map<String, Object>)financialStatementsOld.get('profitAndLoss')).get('operatingProfit');
                } catch(Exception e){
                    operatingProfit = null;
                    operatingProfitOld = null; 
                }
                operatingProfitVariance = calculateVariance(operatingProfit, operatingProfitOld); 
                
                Decimal profitAfterTax;
                Decimal profitAfterTaxOld;
                Decimal profitAfterTaxVariance; 
                try{
                    profitAfterTax = (Decimal)((Map<String, Object>)financialStatements.get('profitAndLoss')).get('profitAfterTax');
                    profitAfterTaxOld = (Decimal)((Map<String, Object>)financialStatementsOld.get('profitAndLoss')).get('profitAfterTax');
                } catch(Exception e){
                    profitAfterTax = null;
                    profitAfterTaxOld = null; 
                }
                profitAfterTaxVariance = calculateVariance(profitAfterTax, profitAfterTaxOld); 
                
                Decimal cash;
                Decimal cashOld; 
                Decimal cashVariance; 
                try{
                    cash = (Decimal)((Map<String, Object>)financialStatements.get('balanceSheet')).get('cash');
                    cashOld = (Decimal)((Map<String, Object>)financialStatementsOld.get('balanceSheet')).get('cash'); 
                } catch(Exception e){
                    cash = null;
                    cashOld = null;
                }
                cashVariance = calculateVariance(cash, cashOld); 
                
                Decimal workingCapital;
                Decimal workingCapitalOld; 
                Decimal workingCapitalVariance;
                try{
                    workingCapital = (Decimal)((Map<String, Object>)financialStatements.get('otherFinancials')).get('workingCapital');
                    workingCapitalOld = (Decimal)((Map<String, Object>)financialStatementsOld.get('otherFinancials')).get('workingCapital');
                } catch(Exception e){
                    workingCapital = null;
                    workingCapitalOld = null; 
                }
                workingCapitalVariance = calculateVariance(workingCapital, workingCapitalOld);
                
                Decimal costOfSales;
                Decimal costOfSalesOld;
                Decimal costOfSalesVariance; 
                try{
                    costOfSales = (Decimal)((Map<String, Object>)localFinancialStatements.get('profitAndLoss')).get('costOfSales');
                    costOfSalesOld = (Decimal)((Map<String, Object>)localFinancialStatementsOld.get('profitAndLoss')).get('costOfSales');
                } catch(Exception e){
                    costOfSales = null;
                    costOfSalesOld = null; 
                }
                costOfSalesVariance = calculateVariance(costOfSales, costOfSalesOld); 
                
                Decimal turnover;
                Decimal turnoverOld;
                Decimal turnoverVariance; 
                try{
                    turnover = (Decimal)((Map<String, Object>)localFinancialStatements.get('profitAndLoss')).get('turnover');
                    turnoverOld = (Decimal)((Map<String, Object>)localFinancialStatementsOld.get('profitAndLoss')).get('turnover');
                } catch(Exception e){
                    turnover = null;
                    turnoverOld = null;
                }
                turnoverVariance = calculateVariance(turnover, turnoverOld); 
                
                Decimal retainedProfit;
                Decimal retainedProfitOld;
                Decimal retainedProfitVariance; 
                try{
                    retainedProfit = (Decimal)((Map<String, Object>)financialStatements.get('profitAndLoss')).get('retainedProfit');
                    retainedProfitOld = (Decimal)((Map<String, Object>)financialStatementsOld.get('profitAndLoss')).get('retainedProfit');
                } catch(Exception e){
                    retainedProfit = null;
                    retainedProfitOld = null; 
                }
                retainedProfitVariance = calculateVariance(retainedProfit, retainedProfitOld);
                
                Decimal currentRatio;
                Decimal currentRatioOld;
                Decimal currentRatioVariance; 
                try{
                    currentRatio = (Decimal)((Map<String, Object>)financialStatements.get('ratios')).get('currentRatio');
                    currentRatioOld = (Decimal)((Map<String, Object>)financialStatementsOld.get('ratios')).get('currentRatio');
                } catch(Exception e){
                    currentRatio = null;
                    currentRatioOld = null; 
                }
                currentRatioVariance = calculateVariance(currentRatio, currentRatioOld); 
                
                Decimal totalDebtRatio;
                Decimal totalDebtRatioOld;
                Decimal totalDebtRatioVariance; 
                try{
                    totalDebtRatio = (Decimal)((Map<String, Object>)financialStatements.get('ratios')).get('totalDebtRatio');
                    totalDebtRatioOld = (Decimal)((Map<String, Object>)financialStatementsOld.get('ratios')).get('totalDebtRatio');
                } catch(Exception e){
                    totalDebtRatio = null;
                    totalDebtRatioOld = null; 
                }
                totalDebtRatioVariance = calculateVariance(totalDebtRatio, totalDebtRatioOld);
                
                Decimal gearing;
                Decimal gearingOld; 
                Decimal gearingVariance; 
                try{
                    gearing = (Decimal)((Map<String, Object>)financialStatements.get('ratios')).get('gearing');
                    gearingOld = (Decimal)((Map<String, Object>)financialStatementsOld.get('ratios')).get('gearing');
                } catch(Exception e){
                    gearing = null;
                    gearingOld = null; 
                }
                gearingVariance = calculateVariance(gearing, gearingOld);
                
                Datetime establishmentDate;
                try{
                    establishmentDate = Date.valueOf((String)((Map<String, Object>)companyIdentification.get('basicInformation')).get('companyRegistrationDate')); 
                } catch(Exception e){
                    establishmentDate = null;
                }
                
                Credit_Report__c cr = new Credit_Report__c();
                
                //cs_report[0].Account__c = Id.valueOf(accountID[0]);
                //cs_report[0].Common_Value__c = commonValue;
                //cs_report[0].Credit_Limit__c = creditLimit;
                ////cs_report[0].Credit_Report_Timestamp__c = DateTime.now().getTime();
                //cs_report[0].Creditsafe_Data_Available__c = true;
                //cs_report[0].Establishment_Date__c = establishmentDate;
                //cs_report[0].Operating_Profit__c = operatingProfit;
                //cs_report[0].Profit_After_Tax__c = profitAfterTax;
                //cs_report[0].Revenue__c = revenue;
                //cs_report[0].Status__c = status;
                //cs_report[0].Total_Assets__c = totalAssets;
                //cs_report[0].Total_Current_Liabilities__c = totalCurrentLiabilities;
                //cs_report[0].Total_Liabilities__c = totalLiabilities;
                //cs_report[0].Total_Current_Assets__c = totalCurrentAssets;
                
                cr.Name = 'Creditsafe';
                cr.Creditsafe_ID__c = cs_id;
                cr.RecordTypeId = Schema.SObjectType.Credit_Report__c.getRecordTypeInfosByName().get('Creditsafe').getRecordTypeId();
                cr.Account__c = Id.valueOf(accountID[index]);
                cr.Common_Value__c = commonValue;
                cr.Credit_Limit__c = creditLimit;
                cr.Report_Match_Name__c = match_name;
                //cs_report[0].Credit_Report_Timestamp__c = DateTime.now().getTime();
                cr.Creditsafe_Data_Available__c = true;
                cr.Establishment_Date__c = establishmentDate;
                cr.Operating_Profit__c = operatingProfit;
                cr.Profit_After_Tax__c = profitAfterTax;
                cr.Revenue__c = revenue;
                cr.Status__c = status;
                cr.Total_Assets__c = totalAssets;
                cr.Total_Current_Liabilities__c = totalCurrentLiabilities;
                cr.Total_Liabilities__c = totalLiabilities;
                cr.Total_Current_Assets__c = totalCurrentAssets;
                cr.Credit_Report_Timestamp__c = Datetime.now();
                cr.Cash__c = cash;
                cr.Working_Capital__c = workingCapital;
                cr.Current_Ratio__c = currentRatio; 
                cr.Turnover__c = turnover;
                cr.Cost_of_Sales__c = costOfSales;
                cr.Retained_Profit__c = retainedProfit;
                cr.Total_Debt_Ratio__c = totalDebtRatio; 
                cr.Gearing__c = gearing; 
                
                cr.Total_Assets_Variance__c = totalAssetsVariance;
                cr.Total_Current_Assets_Variance__c = totalCurrentAssetsVariance;
                cr.Total_Current_Liabilities_Variance__c = totalCurrentLiabilitiesVariance;
                cr.Total_Liabilities_Variance__c = totalLiabilitiesVariance;
                cr.Operating_Profit_Variance__c = operatingProfitVariance; 
                cr.Revenue_Variance__c = revenueVariance;
                cr.Profit_After_Tax_Variance__c = profitAfterTaxVariance;
                cr.Cash_Variance__c = cashVariance; 
                cr.Cost_Of_Sales_Variance__c = costOfSalesVariance;
                cr.Current_Ratio_Variance__c = currentRatioVariance;
                cr.Gearing_Variance__c = gearingVariance;
                cr.Total_Debt_Ratio_Variance__c = totalDebtRatioVariance;
                cr.Turnover_Variance__c = turnoverVariance;
                cr.Working_Capital_Variance__c = workingCapitalVariance;
                cr.Retained_Profit_Variance__c = retainedProfitVariance;
                
                cs_report.add(cr);
            }
            else{
                Logger.atError()
                    .setClassName('Creditsafe')
                    .setMethod('creditsafeIntegration')
                    .setExceptionOrMessage('Account Id '+ accountID+ 'Response from Creditsafe is failed ' + report_res);
                Logger.insertMasterLogs();
                sendEmailAlert('Creditsafe Response Failed', 'GET Authentication request failed and status code is not 200', accountID);
            }
        }
        
        if(!Test.isRunningTest() && cs_report.size() > 0){
            insert cs_report;
        }
        
    }
    
    public static Decimal calculateVariance(Decimal newValue, Decimal oldValue){
        if(oldValue == null || oldValue == 0){
            return 0; 
        }
        Decimal variance = (newValue - oldValue)/oldValue; 
        
        return variance*100; 
    }
    
    // Helper method to send email alerts for Creditsafe integration failures
    private static void sendEmailAlert(String subject, String errorMessage, List<String> accountIds) {
        try {
            List<String> emailAddresses = new List<String>();
            
            User runningUser = [SELECT Email FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
            if (runningUser.Email != null) {
                emailAddresses.add(runningUser.Email);
            }
            emailAddresses.add(System.Label.Deal_Desk_Email_Address_For_3PF_Email);
            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            email.setToAddresses(emailAddresses);
            email.setSubject(subject);
            
            String emailBody = 'Creditsafe Integration Alert\n\n';
            emailBody += 'An error occurred during Creditsafe integration:\n\n';
            emailBody += 'Error Details: ' + errorMessage + '\n\n';
            emailBody += 'Affected Account ID: ' + String.join(accountIds, ', ') + '\n\n';
            emailBody += 'Timestamp: ' + System.now() + '\n\n';
            emailBody += 'Please reach out to GTMS teams.';
            
            email.setPlainTextBody(emailBody);
            
            if (!Test.isRunningTest()) {
                Messaging.sendEmail(new Messaging.SingleEmailMessage[]{email});
            }
        } catch (Exception e) {
            System.debug('Failed to send email alert: ' + e.getMessage());
        }
    }
    
    
}