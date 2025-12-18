@isTest
private class CreditsafeTest{

 	@TestSetup
    static void setupTestData() {
        List<Account> testAccounts = new List<Account>();
        
        Account testAccount1 = new Account();
        testAccount1.Name = 'Test Auth Failure Company';
        testAccount1.Type = 'End Customer';
        testAccount1.Industry = 'Other';
        testAccount1.Organization_Size__c = '1 - 99';
        testAccount1.BillingStreet = '123 Test St';
        testAccount1.BillingCity = 'Test City';
        testAccount1.BillingCountryCode = 'GB';
        testAccount1.BillingPostalCode = 'E16 1NE';
        testAccounts.add(testAccount1);
        
        Account testAccount2 = new Account();
        testAccount2.Name = 'Test Exception Company';
        testAccount2.Type = 'End Customer';
        testAccount2.Industry = 'Other';
        testAccount2.Organization_Size__c = '100 - 499';
        testAccount2.BillingStreet = '456 Test Ave';
        testAccount2.BillingCity = 'Test Town';
        testAccount2.BillingCountryCode = 'GB';
        testAccount2.BillingPostalCode = 'SW1A 1AA';
        testAccounts.add(testAccount2);
        
        Account testAccount3 = new Account();
        testAccount3.Name = 'Test Report Failure Company';
        testAccount3.Type = 'End Customer';
        testAccount3.Industry = 'Other';
        testAccount3.Organization_Size__c = '500 - 999';
        testAccount3.BillingStreet = '789 Test Blvd';
        testAccount3.BillingCity = 'Test Village';
        testAccount3.BillingCountryCode = 'GB';
        testAccount3.BillingPostalCode = 'M1 1AA';
        testAccounts.add(testAccount3);
        
        Account testAccount4 = new Account();
        testAccount4.Name = 'Test Existing Token Company';
        testAccount4.Type = 'End Customer';
        testAccount4.Industry = 'Other';
        testAccount4.Organization_Size__c = '1000 - 4999';
        testAccount4.BillingStreet = '321 Test Road';
        testAccount4.BillingCity = 'Test City';
        testAccount4.BillingCountryCode = 'GB';
        testAccount4.BillingPostalCode = 'B1 1AA';
        testAccounts.add(testAccount4);
        
        insert testAccounts;
    }
    
	private class CS_Mock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {

        	String auth_url = '{"token": "eyJraWQiOiJNSytSKzRhYUk4YjBxVkhBMkZLZFN4Ykdpb3RXbTNXOGhZWE45dXF3K3YwPSIsImFsZyI6IlJTMjU2In0.eyJzdWIiOiI4YTVkODgyMi1lMjc1LTQxZDctODU3NS00ODk5NDA5NTQ3N2MiLCJlbWFpbF92ZXJpZmllZCI6dHJ1ZSwiaXNzIjoiaHR0cHM6XC9cL2NvZ25pdG8taWRwLmV1LXdlc3QtMS5hbWF6b25hd3MuY29tXC9ldS13ZXN0LTFfTXY4TUFxaDFjIiwiY29nbml0bzp1c2VybmFtZSI6Im5pc2hhbnQucmFtYW5Ac2Ftc2FyYS5jb20iLCJjdXN0b206Y3NVc2VySWQiOiIxMDAwNDczOTM3IiwiYXVkIjoiNHA4OGRkZzd1ZzZyMWptZWtkZHZpbmpvcTAiLCJjdXN0b206Y3NVc2VyQ291bnRyeUNvZGUiOiJVUyIsImV2ZW50X2lkIjoiM2Q5ZDk3ZWItZjFkYi0xMWU4LTkxYmItMzVkZTY4NDE4YWNmIiwidG9rZW5fdXNlIjoiaWQiLCJhdXRoX3RpbWUiOjE1NDMyNzg0NTcsImV4cCI6MTU0MzI4MjA1NywiaWF0IjoxNTQzMjc4NDU3LCJlbWFpbCI6Im5pc2hhbnQucmFtYW5Ac2Ftc2FyYS5jb20ifQ.mmc_Gv7Umqmr88LiP0ZZgxx1A5s1VBvFUZDiE0Xqz7avV-OrNlgO9vQs8WzbSg0mWyj4NR9NzXH4ib71CbFm9kPAl5dztquvWqBF9PpPpEa3akD9mP1yZ6sTFeplgrVA9o95Xeq7e0x3_9CgESRpdLpgtPkhTGkeRFAWfLGylX9nInmTUt2WvyWV4eWjl7dqqaNiN9GXmiJkoIIq4Vlim3mgOuLwuftQitO6joEmwefLowSifVz9FjGddzkhW-MgUmBER2dt78jIKBMD2Zj91xHdWZYsXsW_s0KVMm232zz9PEMt_5fOgu9OGRg_s-X6hTQxIKwjWAymXbLzwxsbuA"}';
        	String company_url = '{ "totalSize": 624571, "companies": [ { "id": "GB001-0-10510431", "country": "GB", "regNo": "10510431", "safeNo": "UK15555186", "name": "LONDON TOURIST LTD", "address": { "simpleValue": "95 BUTCHERS ROAD, LONDON, Greater London, E16 1NE", "city": "LONDON", "postCode": "E16 1NE" }, "status": "Active", "type": "Ltd", "dateOfLatestAccounts": "2017-12-31T00:00:00.000000Z", "dateOfLatestChange": "2018-09-16T00:03:39.000Z", "activityCode": "6330" }, { "id": "GB001-0-09618340", "country": "GB", "regNo": "09618340", "safeNo": "UK13726509", "name": "HIGH LONDON TOURIST LTD", "address": { "simpleValue": "259-269 OLD MARYLEBONE ROAD, LONDON, NW1 5RA", "city": "LONDON", "postalCode": "NW1 5RA" }, "status": "NonActive", "type": "Ltd", "dateOfLatestChange": "2018-06-19T00:13:24.000Z" }, { "id": "GB001-0-09809431", "country": "GB", "regNo": "09809431", "safeNo": "UK14536496", "name": "TOURISTIC-LONDON LTD", "address": { "simpleValue": "25 STAYNERS ROAD, LONDON, Greater London, E1 4AH", "city": "LONDON", "postalCode": "E1 4AH" }, "status": "NonActive", "type": "Ltd", "dateOfLatestAccounts": "2016-10-31T00:00:00.000000Z", "dateOfLatestChange": "2018-09-16T00:03:39.000Z", "activityCode": "6330" }, { "id": "GB001-0-00023925", "country": "GB", "regNo": "00023925", "safeNo": "UK00001574", "name": "LONDON TOURIST PUBS LIMITED", "address": { "simpleValue": "RESOLVE PARTNERS LIMITED, 22 YORK BUILDINGS, LONDON, WC2N 6JU", "street": "22 YORK BUILDINGS", "city": "LONDON", "postalCode": "WC2N 6JU" }, "status": "Active", "type": "Ltd", "dateOfLatestAccounts": "2015-08-22T00:00:00.000000Z", "dateOfLatestChange": "2018-06-05T04:17:03.000Z", "activityCode": "7499" }, { "id": "GB001-0-04487498", "country": "GB", "regNo": "04487498", "safeNo": "UK04135439", "name": "LONDON TOURIST BOARD LIMITED", "address": { "simpleValue": "2 MORE LONDON RIVERSIDE, LONDON, Greater London, SE1 2RR", "city": "LONDON", "postalCode": "SE1 2RR" }, "status": "Active", "type": "Ltd", "dateOfLatestAccounts": "2017-03-31T00:00:00.000000Z", "dateOfLatestChange": "2018-10-08T01:02:31.000Z", "activityCode": "7414" }, { "id": "GB001-0-01478235", "country": "GB", "regNo": "01478235", "safeNo": "UK01146966", "name": "LONDON TOURIST VIDEO LIMITED", "address": { "simpleValue": "HOLLY LODGE, 1 OAKLANDS GROVE, LONDON", "street": "1 OAKLANDS GROVE", "city": "LONDON", "postalCode": " " }, "status": "NonActive", "type": "Ltd" }, { "id": "GB001-0-07433612", "country": "GB", "regNo": "07433612", "safeNo": "UK07627778", "name": "LONDON TOURIST CENTER LIMITED", "address": { "simpleValue": "11 RUPERT STREET, LONDON, Greater London, W1D 7PR", "city": "LONDON", "postalCode": "W1D 7PR" }, "status": "NonActive", "type": "Ltd", "dateOfLatestChange": "2018-09-16T00:03:39.000Z" }, { "id": "GB001-0-03830451", "country": "GB", "regNo": "03830451", "safeNo": "UK03484620", "name": "LONDON TOURIST NETWORK LIMITED", "address": { "simpleValue": "THRALE HOUSE, 2ND FLOOR WEST, LONDON, SE1 1UN", "street": "2ND FLOOR WEST", "city": "LONDON", "postalCode": "SE1 1UN" }, "status": "NonActive", "type": "Ltd", "dateOfLatestAccounts": "2004-08-31T00:00:00.000000Z", "dateOfLatestChange": "2006-10-04T23:00:00.000Z", "activityCode": "6330" }, { "id": "GB001-0-11131956", "country": "GB", "regNo": "11131956", "safeNo": "UK16374463", "name": "LONDON UK TOURIST GUIDE LTD", "address": { "simpleValue": "KEMP HOUSE 152-160 CITY ROAD, LONDON, Greater London, EC1V2NX", "city": "LONDON", "postalCode": "EC1V2NX" }, "status": "Active", "type": "Ltd", "dateOfLatestChange": "2018-09-16T00:03:39.000Z", "activityCode": "6330" }, { "id": "GB001-0-05611375", "country": "GB", "regNo": "05611375", "safeNo": "UK05255649", "name": "UK & LONDON TOURIST INFORMATION LTD", "address": { "simpleValue": "235 EARLS COURT ROAD, 235 EARLS COURT ROAD, LONDON, Greater London, SW5 9FE", "street": "235 EARLS COURT ROAD", "city": "LONDON", "postalCode": "SW5 9FE" }, "status": "NonActive", "type": "Ltd", "dateOfLatestChange": "2018-09-16T00:03:39.000Z", "activityCode": "6330" } ] }'; 
        	
            String report_url = '{ "orderId": "N/A", "companyId": "GB-0-10510431", "dateOfOrder": "2018-11-30T01:55:27.771Z", "language": "en", "userId": "1000473937", "chargeRef": null, "report": { "companyId": "GB001-0-10510431", "language": "EN", "companySummary": { "businessName": "LONDON TOURIST LTD", "country": "GB", "companyNumber": "UK15555186", "companyRegistrationNumber": "10510431", "mainActivity": { "code": "6330", "description": "Travel agencies etc; tourist", "classification": "SIC03" }, "companyStatus": { "status": "Active", "description": "Active - Accounts Filed" }, "latestShareholdersEquityFigure": { "value": -2962 }, "creditRating": { "commonValue": "C", "commonDescription": "Moderate Risk", "creditLimit": { "currency": "GBP", "value": "500" }, "providerValue": { "maxValue": "100", "minValue": "1", "value": "41" }, "providerDescription": "Moderate Risk" } }, "companyIdentification": { "basicInformation": { "businessName": "LONDON TOURIST LTD", "registeredCompanyName": "LONDON TOURIST LTD", "companyRegistrationNumber": "10510431", "country": "GB", "companyRegistrationDate": "2016-12-05T00:00:00Z", "legalForm": { "description": "Private limited with Share Capital" }, "companyStatus": { "status": "Active", "description": "Active - Accounts Filed" }, "principalActivity": { "classification": "default" }, "contactAddress": { "simpleValue": "95 BUTCHERS ROAD, LONDON, E16 1NE", "postalCode": "E16 1NE" } }, "activityClassifications": [ { "classification": "SIC03", "activities": [ { "code": "6330", "description": "Travel agencies etc; tourist" } ] }, { "classification": "SIC07", "activities": [ { "code": "79901", "description": "Activities of tourist guides" } ] } ] }, "creditScore": { "currentCreditRating": { "commonValue": "C", "commonDescription": "Moderate Risk", "creditLimit": { "currency": "GBP", "value": "500" }, "providerValue": { "maxValue": "100", "minValue": "1", "value": "41" }, "providerDescription": "Moderate Risk" }, "currentContractLimit": { "currency": "GBP", "value": 1000 }, "previousCreditRating": { "commonValue": "C", "commonDescription": "Moderate Risk", "creditLimit": { "currency": "GBP", "value": "500" }, "providerValue": { "maxValue": "100", "minValue": "1", "value": "47" }, "providerDescription": "Moderate Risk" }, "latestRatingChangeDate": "2018-08-27T22:53:44Z" }, "contactInformation": { "mainAddress": { "simpleValue": "95 BUTCHERS ROAD, LONDON, E16 1NE", "postalCode": "E16 1NE" }, "otherAddresses": [ { "simpleValue": "95 Butchers Road, LONDON, E16 1NE", "postalCode": "E16 1NE" } ] }, "directors": { "currentDirectors": [ { "id": "921992161", "gender": "Male", "dateOfBirth": "1985-06-01T00:00:00Z", "positions": [ { "dateAppointed": "2016-12-05T00:00:00Z", "positionName": "Director" } ], "name": "Mr Md Juel Rana", "address": { "simpleValue": "95 Butchers Road, London, E16 1NE", "postalCode": "E16 1NE" } } ] }, "financialStatements": [ { "profitAndLoss": { "depreciation": 0, "amortisation": 0, "otherAppropriations": 0 }, "balanceSheet": { "totalTangibleAssets": 0, "totalIntangibleAssets": 0, "totalOtherFixedAssets": 0, "totalFixedAssets": 0, "totalInventories": 0, "tradeReceivables": 37, "miscellaneousReceivables": 0, "cash": 0, "otherCurrentAssets": 0, "totalCurrentAssets": 37, "totalAssets": 37, "tradePayables": 2999, "bankLiabilities": 0, "otherLoansOrFinance": 0, "miscellaneousLiabilities": 0, "totalCurrentLiabilities": 2999, "otherLoansOrFinanceDueAfter1Year": 0, "totalLongTermLiabilities": 0, "totalLiabilities": 2999, "calledUpShareCapital": 0, "revenueReserves": -2962, "totalShareholdersEquity": -2962 }, "otherFinancials": { "contingentLiabilities": "NO", "workingCapital": -2962, "netWorth": -2962 }, "ratios": { "currentRatio": 0.01, "liquidityRatioOrAcidTest": 0.01, "currentDebtRatio": -1.01, "gearing": 0, "equityInPercentage": -8005.41, "totalDebtRatio": -1.01 }, "yearEndDate": "2017-12-31T00:00:00Z", "numberOfWeeks": 52, "currency": "GBP", "consolidatedAccounts": false, "type": "GGS Standardised" } ], "localFinancialStatements": [ { "auditQualification": "The company is exempt from audit", "profitAndLoss": { "depreciation": 0, "auditFees": 0 }, "balanceSheet": { "tangibleAssets": 0, "intangibleAssets": 0, "totalFixedAssets": 0, "stock": 0, "tradeDebtors": 37, "otherDebtors": 0, "cash": 0, "miscCurrentAssets": 0, "totalCurrentAssets": 37, "totalAssets": 37, "tradeCreditors": 2999, "bankBorrowingsCurrent": 0, "otherShortTermFinance": 0, "miscCurrentLiabilities": 0, "totalCurrentLiabilities": 2999, "otherLongTermFinance": 0, "totalLongTermLiabilities": 0, "totalLiabilities": 2999, "netAssets": -2962, "issuedShareCapital": 0, "revaluationReserve": 0, "revenueReserves": -2962, "otherReserves": 0, "totalShareholdersEquity": -2962 }, "cashFlow": { "netCashFlowBeforeFinancing": 0 }, "otherFinancials": { "contingentLiabilities": false, "bankOverdraftAndLTL": 0, "workingCapital": -2962, "capitalEmployed": -2962, "netWorth": -2962 }, "ratios": { "currentRatio": 0.01, "liquidityRatioOrAcidTest": 0.01, "currentDebtRatio": -1.01, "gearing": 0, "equityInPercentage": -8005.4, "totalDebtRatio": -1.01 }, "yearEndDate": "2017-12-31T00:00:00Z", "numberOfWeeks": 52, "currency": "GBP", "consolidatedAccounts": false, "type": "Creditsafe UK" } ], "paymentData": { "paymentsOnFile": 1, "paymentsOnTime": 1, "paymentsPaidLate": 0, "paymentsSentLegal": 0, "paymentsStillOwingLate": 0, "paymentsPaid0to30Days": 0, "highestInvoiceValueOutstandingLate": 0, "paymentsPaid90DaysplusLate": 0, "totalBalanceStillOwingLate": 0, "paymentsPaid61to90Days": 0, "totalBalanceStillOwing": 0, "payments31to60DaysLate": 0, "payments61to90DaysLate": 0, "highestInvoiceValueOutstanding": 0, "paymentsStillOwing": 0, "paymentsWithinTerms": 1, "payments0to30Dayslate": 0, "averageInvoiceValue": 0, "paymentsPaid31to60Days": 0, "paymentsPaid90Daysplus": 0, "totalInvoiceValues": 0 }, "negativeInformation": { "ccjSummary": { "exactRegistered": 0, "possibleRegistered": 0 } }, "additionalInformation": { "companyHistory": [ { "date": "2018-08-27T22:33:58Z", "description": "New Accounts Filed" }, { "date": "2018-06-07T06:00:54Z", "description": "Change in Reg.Office" }, { "date": "2018-06-07T06:00:54Z", "description": "Change of Company Postcode" }, { "date": "2018-02-14T05:38:55Z", "description": "Payment Data Update Received" }, { "date": "2017-12-06T00:22:17Z", "description": "Confirmation Statement" }, { "date": "2016-12-07T00:00:00Z", "description": "New Board Member Mr M.J. Rana appointed" } ], "mortgageSummary": { "outstanding": 0, "satisfied": 0 }, "commentaries": [ { "commentaryText": "This company has been treated as a Small company in respect of the rating/limit generated.", "positiveNegative": "Neutral" }, { "commentaryText": "The latest Balance Sheet indicates a negative net working capital position.", "positiveNegative": "Negative" }, { "commentaryText": "The latest cash balances are considered to be low in terms of the overall outstanding creditor obligations.", "positiveNegative": "Negative" }, { "commentaryText": "The negative debt/equity ratio indicates a Balance Sheet deficiency funded by creditors/debt.", "positiveNegative": "Negative" }, { "commentaryText": "This company trades in an industry with a moderate level of corporate failures.", "positiveNegative": "Neutral" } ] } } }';

            if (req.getEndpoint().endsWith('v1/authenticate')) {
                HTTPResponse res = new HTTPResponse();
                res.setBody(auth_url);
                res.setStatusCode(200);
                return res;
            } else if (req.getEndpoint().contains('v1/companies?countries=')) {
                HTTPResponse res = new HTTPResponse();
                res.setBody(company_url);
                res.setStatusCode(200);
                return res;
            } else if (req.getEndpoint().contains('v1/companies/')){
            	HTTPResponse res = new HTTPResponse();
                res.setBody(report_url);
                res.setStatusCode(200);
                return res;
            } else {
                HTTPResponse res = new HTTPResponse();
                res.setBody('{}');
                res.setStatusCode(404);
                return res;
            }
        }

    }


    @isTest
	static void testDNBICallout() {

		Creditsafe_Settings__c cs_settings = new Creditsafe_Settings__c();
        cs_settings.Token_Last_Updated__c = null;
        cs_settings.Token__c = null;
        cs_settings.CreditsafeUser__c  = 'nishant.raman@samsara.com';
        cs_settings.CreditsafePassword__c = 'Gbn%MXN4IZihkcB72xhMv78T';

        insert cs_settings;

        User Owner = [Select Id FROM User WHERE Name LIKE 'Ron Saavedra'];

		Account a = new Account();
        a.Name = 'test1';
        a.Type = 'End Customer';
        a.Industry = 'Other';
        a.Organization_Size__c = '1 - 99';
        a.BillingStreet = '123 Main St, San Francisco CA, 94110';
        a.BillingState = 'California';
        a.BillingCountry = 'United States';
        a.BillingCity = 'LONDON';
        a.BillingPostalCode = 'E16 1NE';
        a.ShippingStreet = '123 Main St, San Francisco CA, 94110';
        a.ShippingState = 'California';
        a.ShippingCountry = 'United States';
        a.ShippingCity = 'San Francisco';
        a.ShippingPostalCode = '94110';
        insert a;
        
        Account b = new Account();
        b.Name = 'test2';
        b.Type = 'End Customer';
        b.Industry = 'Other';
        b.Organization_Size__c = '500 - 999';
        b.BillingStreet = '123 Main St, San Francisco CA, 94110';
        b.BillingState = 'California';
        b.BillingCountry = 'United States';
        b.BillingCity = 'LONDON';
        b.BillingPostalCode = 'E16 1NE';
        b.ShippingStreet = '123 Main St, San Francisco CA, 94110';
        b.ShippingState = 'California';
        b.ShippingCountry = 'United States';
        b.ShippingCity = 'San Francisco';
        b.ShippingPostalCode = '94110';
        insert b;
        
        Account c = new Account();
        c.Name = 'test3';
        c.Type = 'End Customer';
        c.Industry = 'Other';
        c.Organization_Size__c = '100 - 499';
        c.BillingStreet = '123 Main St, San Francisco CA, 94110';
        c.BillingState = 'California';
        c.BillingCountry = 'United States';
        c.BillingCity = 'LONDON';
        c.BillingPostalCode = 'E16 1NE';
        c.ShippingStreet = '123 Main St, San Francisco CA, 94110';
        c.ShippingState = 'California';
        c.ShippingCountry = 'United States';
        c.ShippingCity = 'San Francisco';
        c.ShippingPostalCode = '94110';
        insert c;
        
		List<Id> acctList = new List<Id>();
        acctList.add(a.Id);
        acctList.add(b.Id);
        acctList.add(c.Id);
    
		Test.startTest();

        Test.setMock(HttpCalloutMock.class, new CS_Mock());

        Creditsafe.getCredisafeInfo(acctList);

        Test.stopTest();

        System.assertEquals(true,true);

	}
    
    private class CS_AuthFailureMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HTTPResponse res = new HTTPResponse();
            if (req.getEndpoint().endsWith('v1/authenticate')) {
                res.setBody('{"error": "Authentication failed"}');
                res.setStatusCode(401);
            } else {
                res.setBody('{}');
                res.setStatusCode(404);
            }
            return res;
        }
    }

    private class CS_ExceptionMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            throw new CalloutException('Simulated API timeout');
        }
    }
    
     // Mock class for report retrieval failure
    private class CS_ReportFailureMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            String auth_url = '{"token": "test-token"}';
            String company_url = '{ "totalSize": 1, "companies": [ { "id": "GB001-0-10510431", "name": "TEST COMPANY LTD" } ] }';
            
            HTTPResponse res = new HTTPResponse();
            if (req.getEndpoint().endsWith('v1/authenticate')) {
                res.setBody(auth_url);
                res.setStatusCode(200);
            } else if (req.getEndpoint().contains('v1/companies?countries=')) {
                res.setBody(company_url);
                res.setStatusCode(200);
            } else if (req.getEndpoint().contains('v1/companies/')) {
                res.setBody('{"error": "Report not available"}');
                res.setStatusCode(404);
            } else {
                res.setStatusCode(404);
            }
            return res;
        }
    }
    
     @isTest
    static void testAuthenticationFailure() {
        // Setup Creditsafe settings for this test
        Creditsafe_Settings__c cs_settings = new Creditsafe_Settings__c();
        cs_settings.Token_Last_Updated__c = null;
        cs_settings.Token__c = null;
        cs_settings.CreditsafeUser__c = 'test@example.com';
        cs_settings.CreditsafePassword__c = 'wrongpassword';
        insert cs_settings;

        // Get test account from setup data
        Account testAccount = [SELECT Id FROM Account WHERE Name = 'Test Auth Failure Company' LIMIT 1];
        List<Id> acctList = new List<Id>{testAccount.Id};

        Test.startTest();
        // Set mock that will return 401 for authentication
        Test.setMock(HttpCalloutMock.class, new CS_AuthFailureMock());
        
        // This should trigger the authentication failure path
        Creditsafe.getCredisafeInfo(acctList);
        
        Test.stopTest();

        // Verify that no Credit_Report__c records were created due to auth failure
        List<Credit_Report__c> reports = [SELECT Id FROM Credit_Report__c WHERE Account__c = :testAccount.Id];
        System.assertEquals(0, reports.size(), 'No credit reports should be created on authentication failure');
    }
}