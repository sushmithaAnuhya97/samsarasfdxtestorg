/*
 * August 6th, 2020 Ron Saavedra - (GTMS-1035, GTMS-1341) Build out QuotaHelper Class to create editable Quota_Junction__c object and scalably manage Winner's Circle/Prez Club
 * 9/19/2022 Siddharth Kumar Mishra - (GTMS-9362) process builder conversion to Trigger('Set the Quota on the User' to 'quotaTrigger')
 * 02/18/2025 Ravindra - (GTMS-25663) Set Trial+Quota on User record
*/
public with sharing class QuotaHelper {

    public static void quotaJunctionCreation(List<Quota__c> newQuotaList) {
        Dashboard_Setting__mdt dashboardSetting;
        Period prezClubQuarterlyCeiling;
        Period winnersCircleQuarterlyCeiling;
        List<String> percentageBasedRoles;
        List<String> prezClubEligibleRoles;
        List<String> winnerCircleEligibleRoles;

        String currentFiscalYear = [
                SELECT FiscalYearSettings.Name
                FROM Period
                WHERE Type = 'Year'
                AND StartDate <= TODAY
                AND EndDate >= TODAY
        ].FiscalYearSettings.Name;

        try {
            dashboardSetting = [
                    SELECT Prez_Club_Eligibility_Delta__c,
                            Prez_Club_Eligibility_Scope__c,
                            Winner_Circle_Eligibility_Delta__c,
                            Winner_Circle_Eligibility_Scope__c,
                            Winner_Circle_Eligible_Roles__c,
                            Prez_Club_Eligible_Roles__c,
                            Percentage_Based_Roles__c
                    FROM Dashboard_Setting__mdt
                    WHERE MasterLabel = :currentFiscalYear
                    LIMIT 1
            ];
        } catch (Exception e) {
            System.debug('There was an excetion when trying to access this years Company Dashboard Settings');
        }

        if (dashboardSetting != null) {
            percentageBasedRoles = dashboardSetting.Percentage_Based_Roles__c.split(',');
            prezClubEligibleRoles = dashboardSetting.Prez_Club_Eligible_Roles__c.split(',');
            winnerCircleEligibleRoles = dashboardSetting.Winner_Circle_Eligible_Roles__c.split(',');

            Integer prezClubDelta = Integer.valueof(dashboardSetting.Prez_Club_Eligibility_Delta__c);
            Integer winnersCircleDelta = Integer.valueof(dashboardSetting.Winner_Circle_Eligibility_Delta__c);

            String prezClubQuarterlyCelingQuery = 'SELECT StartDate FROM Period WHERE Type  = \'Quarter\' AND StartDate = LAST_N_FISCAL_QUARTERS:' + prezClubDelta + ' AND EndDate <= THIS_FISCAL_YEAR ORDER BY StartDate ASC LIMIT 1';
            String winnersCircleQuarterlyCelingQuery = 'SELECT StartDate FROM Period WHERE Type  = \'Quarter\' AND StartDate = LAST_N_FISCAL_QUARTERS:' + winnersCircleDelta + ' AND EndDate <= THIS_FISCAL_YEAR ORDER BY StartDate ASC LIMIT 1';

            prezClubQuarterlyCeiling = database.query(prezClubQuarterlyCelingQuery);
            winnersCircleQuarterlyCeiling = database.query(winnersCircleQuarterlyCelingQuery);

        }

        List<Quota_Junction__c> quotaJunctionList = new List<Quota_Junction__c>();

        for (Quota__c quota : newQuotaList) {
            Boolean prezClubEligible = false;
            Boolean winnerCircleEligible = false;
            Boolean percentageBased = false;

            Integer monthsBetween = 0;

            Quota_Junction__c quotaJunction = new Quota_Junction__c(Quota__c = quota.Id,
                    User__c = quota.User__c,
                    President_s_Club_Eligible__c = false,
                    Winner_s_Circle_Eligible__c = false);

            if (dashboardSetting != null) {
                for (String percentBase : percentageBasedRoles) {
                    if (quota.Role_at_Start_of_Fiscal_Period__c.contains(percentBase)) {
                        percentageBased = true;
                    }
                }

                for (String wcEligible : winnerCircleEligibleRoles) {
                    if (quota.Role_at_Start_of_Fiscal_Period__c.contains(wcEligible)) {
                        winnerCircleEligible = true;
                    }
                }

                for (String pcEligible : prezClubEligibleRoles) {
                    if (quota.Role_at_Start_of_Fiscal_Period__c.contains(pcEligible)) {
                        prezClubEligible = true;
                    }
                }
                if (quota.Role_Start_Date__c != null) {
                    monthsBetween = quota.Role_Start_Date__c.monthsBetween(System.today());
                    if (prezClubEligible && (!percentageBased || (percentageBased
                            && ((dashboardSetting.Prez_Club_Eligibility_Scope__c == 'Quarters' && quota.Role_Start_Date__c <= prezClubQuarterlyCeiling.StartDate)
                            || (dashboardSetting.Prez_Club_Eligibility_Scope__c == 'Months' && monthsBetween >= dashboardSetting.Prez_Club_Eligibility_Delta__c))))) {

                        quotaJunction.President_s_Club_Eligible__c = true;
                    }

                    if (winnerCircleEligible && (!percentageBased || (percentageBased
                            && ((dashboardSetting.Winner_Circle_Eligibility_Scope__c == 'Quarters' && quota.Role_Start_Date__c <= winnersCircleQuarterlyCeiling.StartDate)
                            || (dashboardSetting.Winner_Circle_Eligibility_Scope__c == 'Months' && monthsBetween >= dashboardSetting.Winner_Circle_Eligibility_Delta__c))))) {

                        quotaJunction.Winner_s_Circle_Eligible__c = true;
                    }
                }

            }

            quotaJunctionList.add(quotaJunction);
        }

        if (quotaJunctionList.size() > 0) {
            DMLWrapper.doInsert(quotaJunctionList);
        }
    }
    //GTMS-9362
    @future
    public static void setNewADRQuotaOnUser(List<Id> newADRQuotaIdList)
    {
        List<Quota__c> NewADRQuotaList = [Select id,User__r.CurrencyIsoCode, User__r.Quota__c,CurrencyIsoCode, 
                                          Fiscal_Period_End_Date__c, Fiscal_Period_Start_Date__c, ADR_Quota__c 
                                          from Quota__c 
                                          where id IN:newADRQuotaIdList];
        
        Map<id,id> quotaIdUserIdMap = new Map<id,Id>();
        Map<id,user> quotaIdUserMap = new Map<id,user>();
        for(Quota__c q:NewADRQuotaList)
        {
            quotaIdUserIdMap.put(q.id,q.User__c);
        }
        List<user> userList = [select id,CurrencyIsoCode,Quota__c From user where Id IN:quotaIdUserIdMap.values()];
        for(Quota__c q:NewADRQuotaList)
        {
            for(User u:userList)
            {
                if(q.User__c == u.id)
                {
                    quotaIdUserMap.put(q.id,u);
                }
            }
            
        }
		
        for(Quota__c q:NewADRQuotaList)
        {
            quotaIdUserMap.get(q.id).CurrencyIsoCode = q.CurrencyIsoCode;
            if(System.today()<=q.Fiscal_Period_End_Date__c && System.today()>=q.Fiscal_Period_Start_Date__c)
            {
                quotaIdUserMap.get(q.id).Quota__c = q.ADR_Quota__c;
                //q.user__r.Quota__c = q.ADR_Quota__c;                
            }
            else
            {
                quotaIdUserMap.get(q.id).Quota__c = quotaIdUserMap.get(q.id).Quota__c;
                //q.user__r.Quota__c = q.user__r.Quota__c;
                    
            }
        }
        database.update(quotaIdUserMap.values(),false);
        //database.update(NewADRQuotaList,false);
    }
    //GTMS-9362
    @future
    public static void setNewAEQuotaOnUser(List<Id> newAEQuotaIdList)
    {
        List<Quota__c> NewAEQuotaList = [Select id,User__r.CurrencyIsoCode, User__r.Quota__c,CurrencyIsoCode, 
                                          Fiscal_Period_End_Date__c, Fiscal_Period_Start_Date__c, ADR_Quota__c,Quota__c
                                          from Quota__c 
                                          where id IN:newAEQuotaIdList];
        Map<id,id> quotaIdUserIdMap = new Map<id,Id>();
        Map<id,user> quotaIdUserMap = new Map<id,user>();
        for(Quota__c q:NewAEQuotaList)
        {
            quotaIdUserIdMap.put(q.id,q.User__c);
        }
        List<user> userList = [select id,CurrencyIsoCode,Quota__c From user where Id IN:quotaIdUserIdMap.values()];
        for(Quota__c q:NewAEQuotaList)
        {
            for(User u:userList)
            {
                if(q.User__c == u.id)
                {
                    quotaIdUserMap.put(q.id,u);
                }
            }
            
        }
        for(Quota__c q:NewAEQuotaList)
        {
           quotaIdUserMap.get(q.id).CurrencyIsoCode = q.CurrencyIsoCode;
            if(System.today()<=q.Fiscal_Period_End_Date__c && System.today()>=q.Fiscal_Period_Start_Date__c)
            {
                quotaIdUserMap.get(q.id).Quota__c = q.Quota__c;                
            }
            else
            {
                quotaIdUserMap.get(q.id).Quota__c = quotaIdUserMap.get(q.id).Quota__c;
            }
        } 
        database.update(quotaIdUserMap.values(),false);
    }
    //GTMS-9362
    @future
    public static void setChangedAEQuotaOnUser(List<Id> changedAEQuotaIdList)
    {
        List<Quota__c> changedAEQuotaList = [Select id,User__r.CurrencyIsoCode, User__r.Quota__c,CurrencyIsoCode, 
                                          Fiscal_Period_End_Date__c, Fiscal_Period_Start_Date__c, ADR_Quota__c,Quota__c
                                          from Quota__c 
                                          where id IN:changedAEQuotaIdList];
        Map<id,id> quotaIdUserIdMap = new Map<id,Id>();
        Map<id,user> quotaIdUserMap = new Map<id,user>();
        for(Quota__c q:changedAEQuotaList)
        {
            quotaIdUserIdMap.put(q.id,q.User__c);
        }
        List<user> userList = [select id,CurrencyIsoCode,Quota__c From user where Id IN:quotaIdUserIdMap.values()];
        for(Quota__c q:changedAEQuotaList)
        {
            for(User u:userList)
            {
                if(q.User__c == u.id)
                {
                    quotaIdUserMap.put(q.id,u);
                }
            }
            
        }
        for(Quota__c q:changedAEQuotaList)
        {
            quotaIdUserMap.get(q.id).CurrencyIsoCode = q.CurrencyIsoCode;
            if(System.today()<=q.Fiscal_Period_End_Date__c && System.today()>=q.Fiscal_Period_Start_Date__c)
            {
                quotaIdUserMap.get(q.id).Quota__c = q.Quota__c;                
            }
            else
            {
                quotaIdUserMap.get(q.id).Quota__c = quotaIdUserMap.get(q.id).Quota__c;
            }
        } 
        database.update(quotaIdUserMap.values(),false);
    }
    //GTMS-9362
    @future
    public static void setChangedADRQuotaOnUser(List<Id> changedADRQuotaIdList)
    {
        List<Quota__c> changedADRQuotaList = [Select id,User__r.CurrencyIsoCode, User__r.Quota__c,CurrencyIsoCode, 
                                          Fiscal_Period_End_Date__c, Fiscal_Period_Start_Date__c, ADR_Quota__c,Quota__c
                                          from Quota__c 
                                          where id IN:changedADRQuotaIdList];
        Map<id,id> quotaIdUserIdMap = new Map<id,Id>();
        Map<id,user> quotaIdUserMap = new Map<id,user>();
        for(Quota__c q:changedADRQuotaList)
        {
            quotaIdUserIdMap.put(q.id,q.User__c);
        }
        List<user> userList = [select id,CurrencyIsoCode,Quota__c From user where Id IN:quotaIdUserIdMap.values()];
        for(Quota__c q:changedADRQuotaList)
        {
            for(User u:userList)
            {
                if(q.User__c == u.id)
                {
                    quotaIdUserMap.put(q.id,u);
                }
            }
            
        }
        for(Quota__c q:changedADRQuotaList)
        {
            quotaIdUserMap.get(q.id).CurrencyIsoCode = q.CurrencyIsoCode;
            if(System.today()<=q.Fiscal_Period_End_Date__c && System.today()>=q.Fiscal_Period_Start_Date__c)
            {
                quotaIdUserMap.get(q.id).Quota__c = q.ADR_Quota__c ;                
            }
            else
            {
                quotaIdUserMap.get(q.id).Quota__c = quotaIdUserMap.get(q.id).Quota__c;
            }
        } 
        database.update(quotaIdUserMap.values(),false);
    }
    
/*
* Description: Asynchronously updates the Trial_Quota__c field on User records based on related Quota__c records 
* for the current fiscal period. (GTMS-25663)
* Author: Ravindra
* Date Added: 18th Feb 2025
*/

    @future
    public static void setTrialQuotaOnUser(Set<Id> trialQuotaSetIds){
        try{
            List<Quota__c> changedADRQuotaList = [Select id,User__c,Trial_Quota__c, Fiscal_Period_End_Date__c, Fiscal_Period_Start_Date__c
                                              	from Quota__c where id IN:trialQuotaSetIds AND Fiscal_Period_Start_Date__c <= TODAY AND
                                              	Fiscal_Period_End_Date__c>= TODAY order by lastModifiedDate desc];
            Map<Id,User> quotaIdUserMap = new Map<Id,User>();
            Set<Id> userIdSet = new Set<Id>();
            for(Quota__c q:changedADRQuotaList)
            {
                User u = new User();
                u.Id = q.User__c;
                u.Trial_Quota__c = q.Trial_Quota__c;
                if(q.User__c!=null && !userIdSet.contains(q.User__c))
                {	
                    userIdSet.add(q.User__c);
                    quotaIdUserMap.put(q.id,u);
                }
            }
            
            if(!quotaIdUserMap.isEmpty()){
                database.update(quotaIdUserMap.values(),false);
            }
        }
        catch(Exception ex){
          	system.debug('Error occurred during setTrialQuotaOnUser method, Error:'+ex.getMessage()+', Stack Trace:'+ex.getStackTraceString()); 
        }
    } 
}