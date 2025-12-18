@isTest
private class QuotaTests {

    @isTest
    static void prezClubQuota() {
        Period prezClubQuarterlyCeiling;
        String prezClubQuarterlyCelingQuery;
        String prezClubUserQuery;    
        User prezClubUser;

        String currentFiscalYear = [SELECT FiscalYearSettings.Name 
                                    FROM Period 
                                    WHERE Type = 'Year' 
                                    AND StartDate <= TODAY 
                                    AND EndDate >= TODAY].FiscalYearSettings.Name;

        Dashboard_Setting__mdt dashboardSetting = [ SELECT  Prez_Club_Eligibility_Delta__c,
                                                            Prez_Club_Eligibility_Scope__c,
                                                            Winner_Circle_Eligibility_Delta__c,
                                                            Winner_Circle_Eligibility_Scope__c,
                                                            Winner_Circle_Eligible_Roles__c,
                                                            Prez_Club_Eligible_Roles__c,
                                                            Percentage_Based_Roles__c
                                                    FROM Dashboard_Setting__mdt
                                                    WHERE MasterLabel = : currentFiscalYear
                                                    LIMIT 1];

        String pcEligibleRole = dashboardSetting.Prez_Club_Eligible_Roles__c.split(',').get(1);
        String pcEligible = '\'%'+pcEligibleRole+'%\'';

        if(dashboardSetting.Prez_Club_Eligibility_Scope__c == 'Quarters'){
            prezClubQuarterlyCelingQuery = 'SELECT StartDate FROM Period WHERE Type  = \'Quarter\' AND StartDate = LAST_N_FISCAL_QUARTERS:'+dashboardSetting.Prez_Club_Eligibility_Delta__c.intValue()+' AND EndDate <= THIS_FISCAL_YEAR ORDER BY StartDate ASC LIMIT 1';
            prezClubQuarterlyCeiling = database.query(prezClubQuarterlyCelingQuery);
            Time myT = Time.newInstance(0,0,0,0);
            DateTime prezClubCeilingDt = DateTime.newInstance(prezClubQuarterlyCeiling.StartDate, myT);
            String prezClubQuarterlyCeilingDate = prezClubCeilingDt.format('YYYY-MM-dd');
            prezClubUserQuery = 'SELECT Id, Name, Role_Start_Date__c, UserRole.Name FROM User WHERE Role_Start_Date__c <= '+prezClubQuarterlyCeilingDate+' AND UserRole.Name LIKE '+pcEligible+' AND IsActive = true LIMIT 1';
            system.debug(LoggingLevel.INFO, 'presClubQUERYSTRING:'+prezClubUserQuery);

        } else if (dashboardSetting.Prez_Club_Eligibility_Scope__c == 'Months'){
            prezClubUserQuery = 'SELECT Id, Name, Role_Start_Date__c, UserRole.Name FROM User WHERE Role_Start_Date__c <= LAST_N_MONTHS:'+dashboardSetting.Prez_Club_Eligibility_Delta__c.intValue()+' AND UserRole.Name LIKE '+pcEligible+' AND IsActive = true LIMIT 1';
            system.debug(LoggingLevel.INFO, 'presClubQUERYSTRING:'+prezClubUserQuery);
        }

        prezClubUser = database.query(prezClubUserQuery);

        Quota__c newQuota = new Quota__c(   User__c = prezClubUser.Id, 
                                            Role_Start_Date__c = prezClubUser.Role_Start_Date__c,
                                            Role_at_Start_of_Fiscal_Period__c = prezClubUser.UserRole.Name,
                                            Fiscal_Period_Start_Date__c = System.now().date(), 
                                            Fiscal_Period_End_Date__c = System.now().date()+30, 
                                            Fiscal_Period__c='Q4-3000');
        
        Test.startTest();
        insert newQuota;
        Test.stopTest();
    }

    @isTest
    static void winnersCircleQuota() {

        Period winnersCircleQuarterlyCeiling;
        String winnersCircleQuarterlyCelingQuery;
        String winnersCircleUserQuery;
        User winnersCircleUser;


        String currentFiscalYear = [SELECT FiscalYearSettings.Name 
                                    FROM Period 
                                    WHERE Type = 'Year' 
                                    AND StartDate <= TODAY 
                                    AND EndDate >= TODAY].FiscalYearSettings.Name;

        Dashboard_Setting__mdt dashboardSetting = [ SELECT  Prez_Club_Eligibility_Delta__c,
                                                            Prez_Club_Eligibility_Scope__c,
                                                            Winner_Circle_Eligibility_Delta__c,
                                                            Winner_Circle_Eligibility_Scope__c,
                                                            Winner_Circle_Eligible_Roles__c,
                                                            Prez_Club_Eligible_Roles__c,
                                                            Percentage_Based_Roles__c
                                                    FROM Dashboard_Setting__mdt
                                                    WHERE MasterLabel = : currentFiscalYear
                                                    LIMIT 1];

        String wcEligibleRole = dashboardSetting.Winner_Circle_Eligible_Roles__c.split(',').get(1);
        String wcEligible = '\'%'+wcEligibleRole+'%\'';

        if(dashboardSetting.Winner_Circle_Eligibility_Scope__c =='Quarters'){
            winnersCircleQuarterlyCelingQuery = 'SELECT StartDate FROM Period WHERE Type  = \'Quarter\' AND StartDate = LAST_N_FISCAL_QUARTERS:'+dashboardSetting.Winner_Circle_Eligibility_Delta__c.intValue()+' AND EndDate <= THIS_FISCAL_YEAR ORDER BY StartDate ASC LIMIT 1';
            winnersCircleQuarterlyCeiling = database.query(winnersCircleQuarterlyCelingQuery);
            Time myT = Time.newInstance(0,0,0,0);
            DateTime winnerCircleCeilingDt = DateTime.newInstance(winnersCircleQuarterlyCeiling.StartDate, myT);
            String winnersCircleQuarterlyCeilingDate = winnerCircleCeilingDt.format('YYYY-MM-dd');
            winnersCircleUserQuery = 'SELECT Id, Name, Role_Start_Date__c, UserRole.Name FROM User WHERE Role_Start_Date__c <= '+winnersCircleQuarterlyCeilingDate+' AND UserRole.Name LIKE '+wcEligible+' AND IsActive = true LIMIT 1';
            system.debug(LoggingLevel.INFO, 'winnersCircleQUERYSTRING:'+winnersCircleUserQuery);

        } else if(dashboardSetting.Winner_Circle_Eligibility_Scope__c == 'Months'){
            winnersCircleUserQuery = 'SELECT Id, Name, Role_Start_Date__c, UserRole.Name FROM User WHERE Role_Start_Date__c <= LAST_N_MONTHS:'+dashboardSetting.Winner_Circle_Eligibility_Delta__c.intValue()+' AND UserRole.Name LIKE '+wcEligible+' AND IsActive = true LIMIT 1';
            system.debug(LoggingLevel.INFO, 'winnersCircleQUERYSTRING:'+winnersCircleUserQuery);
        }

        winnersCircleUser = database.query(winnersCircleUserQuery);

        Quota__c newQuota = new Quota__c(   User__c = winnersCircleUser.Id, 
                                            Role_Start_Date__c = winnersCircleUser.Role_Start_Date__c, 
                                            Role_at_Start_of_Fiscal_Period__c = winnersCircleUser.UserRole.Name, 
                                            Fiscal_Period_Start_Date__c = System.now().date(), 
                                            Fiscal_Period_End_Date__c = System.now().date()+30, 
                                            Fiscal_Period__c='Q4-3000');

        Test.startTest();
        insert newQuota;
        Test.stopTest();
    }
}