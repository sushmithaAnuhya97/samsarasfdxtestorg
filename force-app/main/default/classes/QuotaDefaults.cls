/**
 * Created by henryzhao on 2020-12-17.
 * 06/14/21 Lavanya - (GTMS-3540) setDefaultsFromUser (Updated code to check if it is insert or update)
 * 06/01/21 Lavanya - (GTMS-3771) setRampStatus (Replaced Ramp_Month formula field with the formula)
 * 03/04/21 Harsha - (GTMS-2886) setDefaultsFromUser (Criteria check to the method)
 * 02/18/21 Harsha - (GTMS-2917) QuotaDefaults (Added a null check)
 * 9/13/2022 Siddharth Kumar Mishra (GTMS-9364) Adding null check to eliminate Null pointer exception
 */

public with sharing class QuotaDefaults {
    private List<String> QUALIFYING_ROLES_FISCAL_PERIOD = new List<String>();
    private Map<String, Integer> ROLE_TO_MONTH_CUTOFF_RAMP_STATUS = new Map<String, Integer>();
    private Map<String, String> QUOTA_TO_USER_FIELD_MAPPING = new Map<String, String>();
    private static final String RAMPING = 'Ramping';
    private static final String FULLY_RAMPED = 'Fully Ramped';
	private Map<Id, User> userIdMap;
    @TestVisible private Map<Id, User> quotaToUserMap = new Map<Id, User>();

    public QuotaDefaults(List<Quota__c> quotas) {
        if(quotas != null){
            /** Start by populating user map so we get relationship data and fields **/
        	Set<Id> usrIds = new Set<Id>();
        	for (Quota__c quota : quotas) {
            	usrIds.add(quota.User__c);
        	}
//        TODO: This can be dynamic field search with custom metadata in future
        	userIdMap = this.getCorrespondingUserFields(usrIds);
        	for (Quota__c quota : quotas) {
            	this.quotaToUserMap.put(quota.Id, userIdMap.get(quota.User__c));
        	}
//        TODO: Abstract this for stubbing in future
        	this.initCustomMetadata();           
        }
    }

    public void onApplyDefaults(Quota__c quota, Quota__c oldQuota) {
        this.setDefaultsFromUser(quota,oldQuota);
        this.setAdjRoleStartDate(quota);
        this.setRampStatus(quota);
    }

    /**
    * @author Groundswell - Henry Zhao - henry@gscloudsolutions.com
    * @date 2021-01-06
    *
    * @description Initializes default values as configured in Quota_Defaults__mdt
    */
    private void initCustomMetadata() {
        final List<Quota_Defaults__mdt> CONFIGURED_DEFAULTS = [
                SELECT Key__c,
                        Value__c,
                        Category__c
                FROM Quota_Defaults__mdt
                ORDER BY Category__c
        ];

        for (Quota_Defaults__mdt quotaDefaults : CONFIGURED_DEFAULTS) {
            switch on quotaDefaults.Category__c {
                when 'User Field Map' {
                    this.QUOTA_TO_USER_FIELD_MAPPING.put(quotaDefaults.Key__c, quotaDefaults.Value__c);
                }
                when 'Ramp Status Map' {
                    this.ROLE_TO_MONTH_CUTOFF_RAMP_STATUS.put(quotaDefaults.Key__c,
                            Integer.valueOf(quotaDefaults.Value__c));
                }
                when 'Qualifying Roles' {
                    this.QUALIFYING_ROLES_FISCAL_PERIOD.add(quotaDefaults.Value__c);
                }
            }
        }
    }

    /**
    * @author Groundswell - Henry Zhao - henry@gscloudsolutions.com
    * @date 2020-12-17
    *
    * @description Sets user as owner. Applies default for territory, geo, office,
     * segment, etc. of the user onto the Quota object.
    */
    private void setDefaultsFromUser(Quota__c quota,Quota__c oldQuota) {
        final User usr;
        if(quota.Id != null){
           usr = this.quotaToUserMap.get(quota.Id);
        } else{
           usr = userIdMap.get(quota.User__c);
        }

        if (usr == null) {
            return;
        }
//        Set user mappings
        for (String field : QUOTA_TO_USER_FIELD_MAPPING.keySet()) {
            if (quota.get(field) == null) {
                final String usrField = QUOTA_TO_USER_FIELD_MAPPING.get(field);
                quota.put(field, usr.get(usrField));
            }
        }


//        Set always true mappings
        if(oldQuota == null){
        	quota.ADR_Segment_Alignment__c = usr.ADR_Segment_Alignment__c;
            quota.Role_at_Start_of_Fiscal_Period__c = usr.UserRole.Name;
        }
        quota.OwnerId = usr.Id;
    }

    /**
    * @author Groundswell - Henry Zhao - henry@gscloudsolutions.com
    * @date 2020-12-18
    *
    * @description Logic pertaining to role start date v2 defaults
    */
    private void setAdjRoleStartDate(Quota__c quota) {
        for(String qualifyingRole: this.QUALIFYING_ROLES_FISCAL_PERIOD){
            if (quota.Role_at_Start_of_Fiscal_Period__c.contains(qualifyingRole)
                && quota.Adj_Role_Start_Date_v2__c == null && quota.Role_Start_Date__c != null) {
                if (quota.Role_Start_Date__c.day() < 15) {
                    quota.Adj_Role_Start_Date_v2__c = Date.newInstance(
                            quota.Role_Start_Date__c.year(),
                            quota.Role_Start_Date__c.month(),
                            1
                    );
                } else {
                    quota.Adj_Role_Start_Date_v2__c = Date.newInstance(
                            quota.Role_Start_Date__c.year(),
                            quota.Role_Start_Date__c.month() + 1,
                            1
                    );
                }
        	}
        }
    }


    /**
    * @author Groundswell - Henry Zhao - henry@gscloudsolutions.com
    * @date 2020-12-18
    *
    * @description Sets default ramp status given ramp month and role
    */
    private void setRampStatus(Quota__c quota) {
        if (!String.isBlank(quota.Ramp_Status__c)) {
            return;
        }
        for (String role : ROLE_TO_MONTH_CUTOFF_RAMP_STATUS.keySet()) {
            if (quota.Role_at_Start_of_Fiscal_Period__c.contains(role)) {
                //GTMS-9364
                Integer numberofDays;
                if(quota.Adj_Role_Start_Date_v2__c!=null && quota.Fiscal_Period_Start_Date__c!=null)
                {
                    numberofDays = quota.Adj_Role_Start_Date_v2__c.daysBetween(quota.Fiscal_Period_Start_Date__c);
                }
                //Integer numberofDays = quota.Adj_Role_Start_Date_v2__c.daysBetween(quota.Fiscal_Period_Start_Date__c);
                Decimal RampMonth = (numberofDays / 365 * 12 < 1) ? ((numberofDays / 365 * 12 ) + 1): 
                ((Math.ceil(numberofDays) / 365 * 12) + 1);
                    
                    System.debug('Ramp Month: '+RampMonth);
                System.debug('Ramp Role: '+ROLE_TO_MONTH_CUTOFF_RAMP_STATUS.get(role));
                quota.Ramp_Status__c =
                        RampMonth >= ROLE_TO_MONTH_CUTOFF_RAMP_STATUS.get(role) ?
                                FULLY_RAMPED : RAMPING;
            }
        }
    }

    /**
    * @author Groundswell - Henry Zhao - henry@gscloudsolutions.com
    * @date 2020-12-17
    *
    * @description Grab required relationship fields from User
     *
     * @return Map of user id to user record
    */
//    TODO: Abstract to external class for test stubbing
    private Map<Id, User> getCorrespondingUserFields(Set<Id>usrIds) {
        return new Map<Id, User>([
                SELECT Id,
                        Office_Location__c,
                        ManagerId,
                        Business_Unit__c,
                        Territory__c,
                        Role_Start_Date__c,
                        UserRole.Name,
                        ADR_Segment_Alignment__c
                FROM User
                WHERE Id IN :usrIds
        ]);
    }
		// GTMS - 11971 - To default Q1,Q2,Q3,Q4 based on Quota Period
		 public void setDefaults(List<Quota__c> quotas) {
    Map<String, List<Quota__c>> periodToQuotas = new Map<String, List<Quota__c>>();
    for (Quota__c quota : quotas) {
        String period = quota.Quota_Period__c;
        if (period != null && period.length() > 0) {
            if (!periodToQuotas.containsKey(period)) {
                periodToQuotas.put(period, new List<Quota__c>());
            }
            periodToQuotas.get(period).add(quota);
        }
    }
    for (String period : periodToQuotas.keySet()) {
        List<Quota__c> periodQuotas = periodToQuotas.get(period);
        for (Quota__c quota : periodQuotas) {
            if (period.contains('Q1')) {
                quota.Q1_Quota__c = quota.Quota__c;
                quota.Q2_Quota__c = 0;
                quota.Q3_Quota__c = 0;
                quota.Q4_Quota__c = 0;
            } else if (period.contains('Q2')) {
                quota.Q1_Quota__c = 0;
                quota.Q2_Quota__c = quota.Quota__c;
                quota.Q3_Quota__c = 0;
                quota.Q4_Quota__c = 0;
            } else if (period.contains('Q3')) {
                quota.Q1_Quota__c = 0;
                quota.Q2_Quota__c = 0;
                quota.Q3_Quota__c = quota.Quota__c;
                quota.Q4_Quota__c = 0;
            } else if (period.contains('Q4')) {
                quota.Q1_Quota__c = 0;
                quota.Q2_Quota__c = 0;
                quota.Q3_Quota__c = 0;
                quota.Q4_Quota__c = quota.Quota__c;
            } else if (period.contains('H1')) {
                quota.Q3_Quota__c = 0;
                quota.Q4_Quota__c = 0;
            } else if (period.contains('H2')) {
                quota.Q1_Quota__c = 0;
                quota.Q2_Quota__c = 0;
            }
            if (quota.Quota__c == null || quota.Quota__c == 0) {
                quota.Q1_Quota__c = 0;
                quota.Q2_Quota__c = 0;
                quota.Q3_Quota__c = 0;
                quota.Q4_Quota__c = 0;
            }
            if (quota.Q1_Quota__c == null) {
                quota.Q1_Quota__c = 0;
            }
            if (quota.Q2_Quota__c == null) {
                quota.Q2_Quota__c = 0;
            }
            if (quota.Q3_Quota__c == null) {
                quota.Q3_Quota__c = 0;
            }
            if (quota.Q4_Quota__c == null) {
                quota.Q4_Quota__c = 0;
            }

        }
    }
}
}