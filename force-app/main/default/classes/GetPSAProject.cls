public with sharing class GetPSAProject {
    @TestVisible
    private static String testClassWeekDay = '';

    @AuraEnabled(cacheable=true)
    public static String getUserProfileName() {
        return [SELECT Profile.Name FROM User WHERE Id = :UserInfo.getUserId()].Profile.Name;
    }

    @AuraEnabled
    public static void updateBVSSurvey(List<Id> projectIds, String selectedSurvey, String surveyType) {
        if (projectIds == null || projectIds.isEmpty() || String.isBlank(surveyType)) return;

        List<pse__Proj__c> projectsToUpdate = [
            SELECT Id, BVS_Survey__c, TSM_survey__c, Services_Survey__c
            FROM pse__Proj__c WHERE Id IN :projectIds
        ];

        List<pse__Proj__c> modifiedProjects = new List<pse__Proj__c>();

        for (pse__Proj__c proj : projectsToUpdate) {
            if (surveyType == 'Update BVS') {
                if (proj.BVS_Survey__c == 'Ready to Send' && proj.BVS_Survey__c != selectedSurvey) {
                    proj.BVS_Survey__c = selectedSurvey;
                    modifiedProjects.add(proj);
                }
            } else if (surveyType == 'Update TSM') {
                if (proj.TSM_survey__c == 'Ready to Send' && proj.TSM_survey__c != selectedSurvey) {
                    proj.TSM_survey__c = selectedSurvey;
                    modifiedProjects.add(proj);
                }
            } else if (surveyType == 'Update Services') {
                if (proj.Services_Survey__c == 'Ready to Send' && proj.Services_Survey__c != selectedSurvey) {
                    proj.Services_Survey__c = selectedSurvey;
                    modifiedProjects.add(proj);
                }
            }
        }

        if (!modifiedProjects.isEmpty()) {
            Database.SaveResult[] updateResults = Database.update(modifiedProjects, false);
            for (Database.SaveResult result : updateResults) {
                if (!result.isSuccess()) {
                    for (Database.Error error : result.getErrors()) {
                        System.debug('Survey update failed: ' + error.getMessage());
                    }
                }
            }
        }
    }

    @AuraEnabled
    public static List<pse__Proj__History> getProjects(String surveyType) {
        String dayOfWeek = '';
        if (!Test.isRunningTest()) {
            dayOfWeek = DateTime.newInstance(Date.today().year(), Date.today().month(), Date.today().day()).format('EEEE');
        } else {
            dayOfWeek = testClassWeekDay;
        }

        Date startdate;
        Date enddate;
        if (dayOfWeek == 'Monday')      { startdate = Date.today().addDays(-10); enddate = Date.today().addDays(-4); }
        else if (dayOfWeek == 'Tuesday'){ startdate = Date.today().addDays(-4);  enddate = Date.today(); }
        else if (dayOfWeek == 'Wednesday'){ startdate = Date.today().addDays(-5); enddate = Date.today(); }
        else if (dayOfWeek == 'Thursday'){ startdate = Date.today().addDays(-6); enddate = Date.today(); }
        else if (dayOfWeek == 'Friday') { startdate = Date.today().addDays(-7); enddate = Date.today().addDays(-1); }
        else if (dayOfWeek == 'Saturday'){ startdate = Date.today().addDays(-8); enddate = Date.today().addDays(-2); }
        else if (dayOfWeek == 'Sunday') { startdate = Date.today().addDays(-9); enddate = Date.today().addDays(-3); }

        DateTime startDateTime = DateTime.newInstance(startDate, Time.newInstance(0, 0, 0, 0));
        DateTime endDateTime   = DateTime.newInstance(endDate,   Time.newInstance(23, 59, 59, 999));

        List<pse__Proj__History> projHistoryList = new List<pse__Proj__History>();
        String profile = getUserProfileName();

        if (profile == 'System Administrator' || profile == 'Analytics Cloud Integration User' ||
            profile == 'SalesforceIQ Integration User' || profile == 'IT Read Only' ||
            profile == 'Samsara API Only' || profile == 'Samsara Customer Portal User' ||
            profile == 'System Administrator Copy' || profile == 'Sales Insights Integration User' ||
            profile == 'Samsara SIS' || profile == 'System Administrator API' || profile == 'Sales Ops Profile' ||
            profile == 'Samsara CSM' || profile == 'Samsara CSM Management') {
            if (surveyType == 'Update BVS' && profile != 'Samsara CSM' && profile != 'Samsara CSM Management') {
                projHistoryList = [
                    SELECT Id, Field, Parent.Name, ParentId, OldValue, NewValue, CreatedDate,
                    Parent.pse__Project_ID__c, Parent.Engagement_Type__c, Parent.pse__Stage__c,
                    Parent.pse__End_Date__c, Parent.pse__Credited_Non_Billable_Internal_Hours__c ,Parent.BVS_Survey__c
                    FROM pse__Proj__History
                    WHERE Field = 'BVS_Survey__c'
                    AND Parent.BVS_Survey__c = 'Ready to Send'
                    AND CreatedDate >= :startDateTime
                    AND CreatedDate <= :endDateTime
                    ORDER BY CreatedDate DESC
                ];
            }
            else if(surveyType == 'Update TSM' && profile != 'Samsara CSM' && profile != 'Samsara CSM Management'){
                projHistoryList = [
                    SELECT Id, Field, Parent.Name, ParentId, OldValue, NewValue, CreatedDate,
                    Parent.pse__Project_ID__c, Parent.pse__Stage__c, Parent.TSM_survey__c, Parent.pse__End_Date__c,
                    Parent.TSM_Project_Type__c, Parent.pse__Group__r.Name, Parent.pse__Credited_Non_Billable_Internal_Hours__c
                    FROM pse__Proj__History
                    WHERE Field = 'TSM_survey__c'
                    AND Parent.TSM_survey__c = 'Ready to Send'
                    AND CreatedDate >= :startDateTime
                    AND CreatedDate <= :endDateTime
                    ORDER BY CreatedDate DESC
                ];
            }
            else if(surveyType == 'Update Services' && profile != 'Sales Ops Profile'){
                projHistoryList = [
                    SELECT Id, Field, Parent.Name, ParentId, OldValue, NewValue, CreatedDate,
                    Parent.pse__Project_ID__c, Parent.Engagement_Type__c, Parent.pse__Stage__c,
                    Parent.pse__End_Date__c, Parent.Services_Survey__c
                    FROM pse__Proj__History
                    WHERE Field = 'Services_Survey__c'
                    AND Parent.Services_Survey__c = 'Ready to Send' 
                    AND CreatedDate >= :startDateTime
                    AND CreatedDate <= :endDateTime
                    ORDER BY CreatedDate DESC
                ];
            }            
        }
 
        Map<Id, pse__Proj__History> projHistotyMap = new Map<Id, pse__Proj__History>();
        for (pse__Proj__History ph : projHistoryList) {
            if (!projHistotyMap.containsKey(ph.ParentId)) {
                projHistotyMap.put(ph.ParentId, ph);
            }
        }
        return projHistotyMap.values();
    }
}