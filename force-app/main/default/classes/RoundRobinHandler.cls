/**********************************************************************
Name: RoundRobinHandler
=======================================================================
Purpose: This class will contain methods that handles the user assignment                                                        
=======================================================================
History  

VERSION     AUTHOR               DATE               DETAIL                       
1.0        Rodrigo Carpio        2022-Nov-30        INITIAL DEVELOPMENT FOR GTMS-10121
1.1        Rodrigo Carpio.       2023-Mar-16        added RoundRobinInfo class
1.2.       Rodrigo Carpio        2023-Apr-6.        GTMS-12532 - add logic that will handle Queue Name assignment (currQueueName)
1.3        Rodrigo Carpio        2023-Aug-17        added No_Deal_Reg_Check__c for GTMS-14837
1.4.       Rodrigo Carpio.       2023-Aug-24.       added logic for GTMS-14481
1.5        Rodrigo Carpio.       2023-Sep-25.       added logic for GTMS-15367
1.6.       Rodrigo Carpio.       2024-Feb-7.        added logic for GTMS-16050
1.7.       Nishith Cheemakurthi  2024-April-11      added logic for GTMS-18362 (Timezone & Owner Role logic)
***********************************************************************/ 

public class RoundRobinHandler {

    public class RoundRobinInfo {
        public String userId {get;set;}
        public String fieldToUpdate {get;set;}
        public String ruleId {get;set;}
        public String mappingId {get;set;}
    }
    
    // list of rule id where last run will be updated
    private Set<Id> ruleIdToBeUpdated = new Set<Id>();
    public Map<Id, RR_Assignment_Rule__c> mapRule = new Map<Id, RR_Assignment_Rule__c>();
    public Map<Id, RR_Assignment_Rule__c> mapRuleToBeUpdated = new Map<Id, RR_Assignment_Rule__c>();
    public Map<Id, RR_Assignment_Mapping__c > mapMapping = new Map<Id, RR_Assignment_Mapping__c >();
    public Map<Id, RR_Assignment_Mapping__c > mapMappingPause = new Map<Id, RR_Assignment_Mapping__c >();
    public Set<Id> pausedMapIds = new Set<Id>();
    public Map<Id, Map<Id, RR_Assignment_Mapping__c>> ruleUserMaps = new Map<Id, Map<Id, RR_Assignment_Mapping__c>>();
    private Map<Id, Map<Id, Id>> ruleUsersForUpdate = new Map<Id, Map<Id, Id>>();
    Map<Id, Id> userUpd = new Map<Id, Id>();
    private List<RR_Assignment_Log__c> forInsertRRLog = new List<RR_Assignment_Log__c>();
    private Id currRuleId = null;
    private Id currRuleMapping = null;
    private string currQueueName = null;
    private string fieldToBeAssign = null;
    private string rrLogStatus = null;
    private static List<RR_Assignment_Rule__c> defaultRule = new List<RR_Assignment_Rule__c>();
    private boolean useDefaultRule = false;
    public string testRuleName;
    public boolean skipNextAssignment = false;

    //Added as part of GTMS-18362(GTMS-19824), Owner Matching Logic strings
    string negation = '!';
    string openBrackets = '\\(';
    string closedBrackets = '\\)';
    string orString = '\\|\\|';
    string andString = '&&';
    string emptyString = '';
    string semicolan = ';';
    string notTrue = '!true';
    string notfalse = '!false';
    string trueAndTrue = 'true&&true';
    string trueOrTrue = 'true\\|\\|true';
    string trueOrFalse = 'true\\|\\|false';
    string falseOrTrue = 'false\\|\\|true';
    string falseAndfalse = 'false&&false';
    string falseOrfalse = 'false\\|\\|false';
    string trueAndFalse = 'true&&false';
    string falseAndTrue = 'false&&true';
    string trueinBrakets = '(true)';
    string falseinBrackets = '(false)';
    string underscore = '_';
    string space = ' ';

    static final string LANGUAGE_BLANK_STRING = System.label.LanguageBlank??'';

    //private static List<Account> pilotAccounts = new List<Account>();
    //private static List<RR_Assignment_Rule__c> pilotRules = new List<RR_Assignment_Rule__c>();
    //private static Map<Id, Account> pilotAccountsMaps = new Map<Id, Account>();
    //public static Map<Id, Boolean> customRoutingMap = new Map<Id, Boolean>();
    
    public RoundRobinHandler () {
        if (defaultRule.size()==0)
        defaultRule = [SELECT Id, Next_Assignment__c, Next_Assignment_Mapping__c,  Field_To_Assign_User__c from RR_Assignment_Rule__c WHERE Default__c= true LIMIT 1];
    }
    
    /*
     * this constructor will retrieve list of rules base of Field_To_Assign_User__c value, to retrieve rules specific to Field_To_Assign_User__c value
*/
    public RoundRobinHandler (String category, String objectName, string fieldToAssignUser) // added for GTMS-15367
    {
        // get list of rules base on input object name
        mapRule = new Map<Id, RR_Assignment_Rule__c>([SELECT Id, Category__c, Order__c, Region__c, Type__c, Min_Value__c, Max_Value__c, Name,
        Always_Use_Next_Assignment__c, Next_Assignment__c, SLED__c, Next_Assignment_Mapping__c,Onboarding_Complete__c,Partner_Team_Alignment__c,
        Is_Owner_Pool_User__c, Global_Geography__c, Assign_CSM__c, Record_Type_Stamp_for_Dupes__c, Use_AND_Condition__c,SIC_Null_Check__c,
        Organization_Size__c, Most_Recent_Source__c, Number_of_Vehicles__c, Number_of_Powered_Assets__c, Number_of_Unpowered_Assets__c,
                                         Deal_Reg_Account__c, Business_Unit__c, Partner_Persona__c, Which_written_language__c, CS_Tier__c,
                                                       Industry__c, Partner_Program_Segment__c, Billing_Country__c, Billing_State__c,
                                                       Account_Hashtag__c, Experimental_Group__c, Experimental_Group_Routing__c, Account_Size_Segment__c,
                                                       Inside_Sales_Assignment__c, Number_of_Citizens__c, Number_of_Students__c,Account_Lifetime_ACV__c, 
                                                      Website__c, Domain_Name__c, CSM_Null_Check__c, SLED_Check__c, Field_To_Assign_User__c, Queue_Name__c,
                                                      Next_Assignment_Mapping__r.Pause_Assignment__c, No_Deal_Reg_Check__c, Owner_Role__c, Timezone__c,Owner_Manager__c,Customer_ARR__c,
                                                      No_Pool_User_Check__c
                                        FROM RR_Assignment_Rule__c 
                                                      WHERE Active__c=true AND Field_To_Assign_User__c =: fieldToAssignUser
                                                      AND Category__c =: category AND Object__c =:objectName order by Order__c asc]);
        getRuleRelatedData();
    }
    
    public RoundRobinHandler (String category, String objectName, Boolean isPoolUser) {
        // get list of rules base on input object name
        mapRule = new Map<Id, RR_Assignment_Rule__c>([SELECT Id, Category__c, Order__c, Region__c, Type__c, Min_Value__c, Max_Value__c, Name,
        Always_Use_Next_Assignment__c, Next_Assignment__c, SLED__c, Next_Assignment_Mapping__c,Onboarding_Complete__c,Partner_Team_Alignment__c,
        Is_Owner_Pool_User__c, Global_Geography__c, Assign_CSM__c, Record_Type_Stamp_for_Dupes__c, Use_AND_Condition__c,SIC_Null_Check__c,
        Organization_Size__c, Most_Recent_Source__c, Number_of_Vehicles__c, Number_of_Powered_Assets__c, Number_of_Unpowered_Assets__c,
                                         Deal_Reg_Account__c, Business_Unit__c, Partner_Persona__c, Which_written_language__c, CS_Tier__c,
                                                       Industry__c, Partner_Program_Segment__c, Billing_Country__c, Billing_State__c,
                                                       Account_Hashtag__c, Experimental_Group__c, Experimental_Group_Routing__c, Account_Size_Segment__c,
                                                       Inside_Sales_Assignment__c, Number_of_Citizens__c, Number_of_Students__c,Account_Lifetime_ACV__c, 
                                                      Website__c, Domain_Name__c, CSM_Null_Check__c, SLED_Check__c, Field_To_Assign_User__c, Queue_Name__c,
                                                      Next_Assignment_Mapping__r.Pause_Assignment__c, No_Deal_Reg_Check__c, Owner_Role__c, Timezone__c,Owner_Manager__c,Customer_ARR__c ,
                                                      No_Pool_User_Check__c 
                                        FROM RR_Assignment_Rule__c 
                                                      WHERE Active__c=true AND Is_Owner_Pool_User__c =: isPoolUser
                                                      AND Category__c =: category AND Object__c =:objectName order by Order__c asc]);
        getRuleRelatedData();
    }
    
    public RoundRobinHandler (String category, String objectName) {
        if (category=='Lane Four')
            useDefaultRule = true;
        if (defaultRule.size()==0)
        defaultRule = [SELECT Id, Next_Assignment__c, Next_Assignment_Mapping__c,  Field_To_Assign_User__c from RR_Assignment_Rule__c WHERE Default__c= true LIMIT 1];
    
        // get list of rules base on input object name
        mapRule = new Map<Id, RR_Assignment_Rule__c>([SELECT Id, Category__c, Order__c, Region__c, Type__c, Min_Value__c, Max_Value__c, Name,
        Always_Use_Next_Assignment__c, Next_Assignment__c, SLED__c, Next_Assignment_Mapping__c,Onboarding_Complete__c,Partner_Team_Alignment__c,
        Is_Owner_Pool_User__c, Global_Geography__c, Assign_CSM__c, Record_Type_Stamp_for_Dupes__c, Use_AND_Condition__c,SIC_Null_Check__c,
        Organization_Size__c, Most_Recent_Source__c, Number_of_Vehicles__c, Number_of_Powered_Assets__c, Number_of_Unpowered_Assets__c,
                                         Deal_Reg_Account__c, Business_Unit__c, Partner_Persona__c, Which_written_language__c, CS_Tier__c,
                                                       Industry__c, Partner_Program_Segment__c, Billing_Country__c, Billing_State__c,
                                                       Account_Hashtag__c, Experimental_Group__c, Experimental_Group_Routing__c, Account_Size_Segment__c,
                                                       Inside_Sales_Assignment__c, Number_of_Citizens__c, Number_of_Students__c,Account_Lifetime_ACV__c, 
                                                      Website__c, Domain_Name__c, CSM_Null_Check__c, SLED_Check__c, Field_To_Assign_User__c, Queue_Name__c,
                                                      Next_Assignment_Mapping__r.Pause_Assignment__c, No_Deal_Reg_Check__c, Owner_Role__c, Timezone__c,Owner_Manager__c,Customer_ARR__c ,
                                                      No_Pool_User_Check__c 
                                        FROM RR_Assignment_Rule__c 
                                                      WHERE Active__c=true AND Category__c =: category AND Object__c =:objectName order by Order__c asc]);
        getRuleRelatedData();
    }
    public RoundRobinHandler (Boolean sled,String objectName, String category) {
        if (category=='Lane Four')
            useDefaultRule = true;
        if (defaultRule.size()==0)
        defaultRule = [SELECT Id, Next_Assignment__c, Next_Assignment_Mapping__c,  Field_To_Assign_User__c from RR_Assignment_Rule__c WHERE Default__c= true LIMIT 1];
    
        // get list of rules base on input object name
        mapRule = new Map<Id, RR_Assignment_Rule__c>([SELECT Id, Category__c, Order__c, Region__c, Type__c, Min_Value__c, Max_Value__c, Name,
        Always_Use_Next_Assignment__c, Next_Assignment__c, SLED__c, Next_Assignment_Mapping__c,Onboarding_Complete__c,Partner_Team_Alignment__c,
        Is_Owner_Pool_User__c, Global_Geography__c, Assign_CSM__c, Record_Type_Stamp_for_Dupes__c, Use_AND_Condition__c,SIC_Null_Check__c,
        Organization_Size__c, Most_Recent_Source__c, Number_of_Vehicles__c, Number_of_Powered_Assets__c, Number_of_Unpowered_Assets__c,
                                         Deal_Reg_Account__c, Business_Unit__c, Partner_Persona__c, Which_written_language__c, CS_Tier__c,
                                                       Industry__c, Partner_Program_Segment__c, Billing_Country__c, Billing_State__c,
                                                       Account_Hashtag__c, Experimental_Group__c, Experimental_Group_Routing__c, Account_Size_Segment__c,
                                                       Inside_Sales_Assignment__c, Number_of_Citizens__c, Number_of_Students__c,Account_Lifetime_ACV__c, 
                                                      Website__c, Domain_Name__c, CSM_Null_Check__c, SLED_Check__c, Field_To_Assign_User__c, Queue_Name__c,
                                                      Next_Assignment_Mapping__r.Pause_Assignment__c, No_Deal_Reg_Check__c, Owner_Role__c, Timezone__c,Owner_Manager__c,Customer_ARR__c ,
                                                      No_Pool_User_Check__c 
                                        FROM RR_Assignment_Rule__c 
                                                      WHERE Active__c=true AND Category__c =: category AND Object__c =:objectName AND SLED__c =: sled order by Order__c asc]);
        getRuleRelatedData();
    }
    public RoundRobinHandler (Set<Id> ruleIds) {
        //system.debug('RODRIGO RoundRobinHandler ruleIds ' + ruleIds);
        // get list of rules base on input object name
        mapRule = new Map<Id, RR_Assignment_Rule__c>([SELECT Id, Category__c, Order__c, Region__c, Type__c, Min_Value__c, Max_Value__c, Name,
        Always_Use_Next_Assignment__c, Next_Assignment__c, SLED__c, Next_Assignment_Mapping__c,Onboarding_Complete__c,Partner_Team_Alignment__c,
        Is_Owner_Pool_User__c, Global_Geography__c, Assign_CSM__c, Record_Type_Stamp_for_Dupes__c, Use_AND_Condition__c,SIC_Null_Check__c,
        Organization_Size__c, Most_Recent_Source__c, Number_of_Vehicles__c, Number_of_Powered_Assets__c, Number_of_Unpowered_Assets__c,
                                         Deal_Reg_Account__c, Business_Unit__c, Partner_Persona__c, Which_written_language__c, CS_Tier__c,
                                                       Industry__c, Partner_Program_Segment__c, Billing_Country__c, Billing_State__c,
                                                       Account_Hashtag__c, Experimental_Group__c, Experimental_Group_Routing__c, Account_Size_Segment__c,
                                                       Inside_Sales_Assignment__c, Number_of_Citizens__c, Number_of_Students__c,Account_Lifetime_ACV__c, 
                                                      Website__c, Domain_Name__c, CSM_Null_Check__c, SLED_Check__c, Field_To_Assign_User__c, Queue_Name__c,
                                                      Next_Assignment_Mapping__r.Pause_Assignment__c, No_Deal_Reg_Check__c, Owner_Role__c, Timezone__c,Owner_Manager__c,Customer_ARR__c ,
                                                      No_Pool_User_Check__c 
                                        FROM RR_Assignment_Rule__c 
                                                      WHERE Active__c=true AND Id IN:ruleIds order by Order__c asc]);
        //system.debug('RODRIGO RoundRobinHandler mapRule ' + mapRule);
        getRuleRelatedData();
    }
    
    private void getRuleRelatedData() {
        //system.debug('RODRIGO getRuleRelatedData mapRule ' + mapRule.size());
        // capture pause assignment id
        FOR(RR_Assignment_Rule__c recAR : mapRule.values()) { // added for GTMS-14481
            if (recAR.Next_Assignment_Mapping__r.Pause_Assignment__c)
            pausedMapIds.add(recAR.Next_Assignment_Mapping__c);
        }
        //system.debug('RODRIGO getRuleRelatedData pausedMapIds ' + pausedMapIds.size());
        // get assignment mapping base on the list of rules -- replaced the //Pause_Assignment__c == true  with EnableADRLeads and added user query.
        //  added for GTMS-14481
        mapMappingPause = new Map<Id, RR_Assignment_Mapping__c>([SELECT Id, Order__c, User__c, Assignment_Rule__c, User_Group__c, Is_SLED__c,Type__c,
                                                             Max_Value__c, Value_Total__c, Field_To_Assign__c, Queue_Name__c, Pause_Assignment__c    
                                                            FROM RR_Assignment_Mapping__c 
                                                            WHERE Active__c=true AND User__r.IsActive = true AND Id IN: pausedMapIds order by Order__c asc ]);
        //system.debug('RODRIGO getRuleRelatedData ' + mapRule.keySet());
        // get assignment mapping base on the list of rules -- replaced the //Pause_Assignment__c != true  with EnableADRLeads and added user query.
        mapMapping = new Map<Id, RR_Assignment_Mapping__c>([SELECT Id, Order__c, User__c, Assignment_Rule__c, User_Group__c, Is_SLED__c,Type__c,
                                                             Max_Value__c, Value_Total__c, Field_To_Assign__c, Queue_Name__c, Pause_Assignment__c   
                                                            FROM RR_Assignment_Mapping__c 
                                                            WHERE Active__c=true AND User__r.IsActive = true AND Pause_Assignment__c != true AND User__c!=null
                                                            AND Assignment_Rule__c IN: mapRule.keySet() order by Order__c asc ]);

        
    	
        //system.debug('RODRIGO getRuleRelatedData mapMapping ' + mapMapping.size());
        // collect the user and put them into rule map
        FOR(Id ruleId : mapRule.keySet()) {
            //system.debug('RODRIGO ruleId ' + ruleId);
            Map<Id, RR_Assignment_Mapping__c > userMapping = new Map<Id, RR_Assignment_Mapping__c >();
            FOR (RR_Assignment_Mapping__c userMap : mapMapping.values()) {
                if (userMap.Assignment_Rule__c == ruleId) {
                    //if (userMap.Id == 'aLd560000008bSLCAY')
                    //    system.debug(ruleId + 'RODRIGO userMap ' + userMap);
                    //system.debug('ruleId userMap ' + userMap);
                    //userMapping.put(userMap.User__c, userMap);
                    userMapping.put(userMap.Id, userMap);
                }
                    
            }
            //system.debug('RODRIGO ruleId ' + userMapping.size());
            if (userMapping.size()>0) {
                //system.debug(ruleId + ' RODRIGO ruleId ruleUserMaps ' + userMapping);
                ruleUserMaps.put(ruleId, userMapping);
            }
            	
        	
        }
        //system.debug('RODRIGO getRuleRelatedData ruleUserMaps ' + ruleUserMaps.size());

    }
	    
    /**********************************************************************
    Name: resetRuleMappingTotalValue
    =======================================================================
    Purpose: handles the logic to return user id base given parameters                                                       
    =======================================================================
    History  
    
    VERSION     AUTHOR               DATE               DETAIL                       
    1.0        Rodrigo Carpio        2023-Jan-30        INITIAL DEVELOPMENT
    
    ***********************************************************************/
    public static void resetRuleMappingTotalValue (String inType) {
        List<RR_Assignment_Mapping__c> mappingList = [SELECT Id, Order__c, User__c, Assignment_Rule__c, User_Group__c, Is_SLED__c,Type__c,
                                                             Max_Value__c, Value_Total__c 
                                                            FROM RR_Assignment_Mapping__c 
                                                            WHERE Active__c=true AND User__r.IsActive = true AND Type__c =:inType];
        List<RR_Assignment_Mapping__c> mappingForUpd = new List<RR_Assignment_Mapping__c>();
        FOR (RR_Assignment_Mapping__c rec : mappingList) {
            rec.Value_Total__c = 0;
            mappingForUpd.add(rec);
        }
        
        if (mappingForUpd != null && mappingForUpd.size()>0) {
            update mappingForUpd;
        }
    }
        
    /**********************************************************************
    Name: getAssignedUserByAttributes
    =======================================================================
    Purpose: handles the logic to return user id base given parameters                                                       
    =======================================================================
    History  
    
    VERSION     AUTHOR               DATE               DETAIL                       
    1.0        Rodrigo Carpio        2023-Jan-30        INITIAL DEVELOPMENT
    
    ***********************************************************************/
    public String getAssignedUserByAttributes(Id accountId, boolean sledAccount, string countryCode, decimal customerARR, decimal renewalACV, string AccountName) {
	//public Id getAssignedUserByAttributes(Id accountId, Double renewalACV, string countryCode, boolean sledAccount) {
        String userTobeAssigned=null;
        
        // loop thru all the rule, sequence is base on order
        FOR (RR_Assignment_Rule__c currRule : mapRule.values()) {
            currQueueName = null;
            if (currRule.Type__c == 'Country')
                userTobeAssigned = performCountryBaseRuleCheck(countryCode, currRule); // perform country matching
            if (currRule.Type__c == 'ARR' && userTobeAssigned==null) 
                userTobeAssigned = performARRBaseRuleCheck(customerARR, renewalACV, sledAccount, currRule); // perform ARR matching
            if (userTobeAssigned != null) {
                break;
            }
                
        }
        //system.debug('RODRIGO getAssignedUserByAttributes userTobeAssigned ' + userTobeAssigned);
        //system.debug('RODRIGO getAssignedUserByAttributes currRuleId ' + currRuleId);
        if (userTobeAssigned != null || currQueueName != null) {
            RR_Assignment_Log__c log = new RR_Assignment_Log__c();
            //if (fieldToBeAssign == 'User')
            	log.User__c = userTobeAssigned;
            //if (fieldToBeAssign == 'Queue Name') 
                log.Queue_Name__c = currQueueName;
            log.Record_Id__c = accountId;
            log.Record_Name__c = accountName;
            log.RR_Assignment_Mapping__c = currRuleMapping;
            log.RR_Assignment_Rule__c = currRuleId;
            log.Status__c = 'Success';
            forInsertRRLog.add(log);
        }
        
        if(userTobeAssigned == null) 
            userTobeAssigned = currQueueName;
        
        return userTobeAssigned;
    }   
    
    /**********************************************************************
    Name: getAssignedUser
    =======================================================================
    Purpose: handles the logic to return user info base on account id                                                       
    =======================================================================
    History  
    
    VERSION     AUTHOR               DATE               DETAIL                       
    1.0        Rodrigo Carpio        2022-Nov-30        INITIAL DEVELOPMENT
    
    ***********************************************************************/
    public User getAssignedUser(Id accntId) {
        User userRec = new User();
        Account thisAccount = new Account();
        thisAccount = [SELECT Id, Is_Owner_Pool_User__c, Assign_CSM__c,is_deal_reg_account__c,Record_Type_Stamp_for_Dupes__c, Organization_Size__c,Global_Geography__c,
                       Most_Recent_Source__c,Industry,Business_Unit__c, Partner_Program_Tier__c, Partner_Persona__c, BillingCountry, BillingState,BillingCountryCode,
                       Which_written_language__c, CS_Tier__c, Experimental_Group__c, Experimental_Group_Routing__c, Account_Size_Segment__c, Inside_Sales_Assignment__c,
                       Number_of_Vehicles__c, Number_of_Powered_Assets__c, Number_of_Unpowered_Assets__c, website, Domain_Name__c, CSM__c, SLED_Account__c, Name, 
                       Customer_ARR__c, Number_of_Students__c, Number_of_Citizens__c, Account_Lifetime_ACV__c, Hashtag__c, SIC__c, Onboarding_Complete__c, Partner_Type__c,
                       Owner_Profile_Id__c, Timezone__c, Owner_Role__c,Owner_Manager__c  
                       FROM Account WHERE Id =: accntId];
        //Id userid = getAssignedUser(thisAccount);
        RoundRobinInfo rrInfo = getAssignedUser(thisAccount);
        Id userid = rrInfo.userId;
        if (userid != null)
            userRec = [SELECT Id, Name FROM User WHERE Id =:userid ];
        return userRec;
    }
    
    /**********************************************************************
    Name: getAssignedUser
    =======================================================================
    Purpose: handles the logic to return user info base on account info                                                       
    =======================================================================
    History  
    
    VERSION     AUTHOR               DATE               DETAIL                       
    1.0        Rodrigo Carpio        2022-Nov-30        INITIAL DEVELOPMENT
    1.1.       Rodrigo Carpio        2023-Mar-16        change the type to be returned to RoundRobinInfo
    ***********************************************************************/
    public RoundRobinInfo getAssignedUser(Account accntInfo) {
        Id userTobeAssigned=null;
        Boolean localPauseAssignment = false;
        RoundRobinInfo rrInfo = new RoundRobinInfo();
        string fieldToAssignUser = null;
        // loop thru all the rule, sequence is base on order
        FOR (RR_Assignment_Rule__c currRule : mapRule.values()) {
            //system.debug('RODRIGO Rule currRule ' + currRule.NAME);
            localPauseAssignment = currRule.Next_Assignment_Mapping__r.Pause_Assignment__c;
            fieldToAssignUser = currRule.Field_To_Assign_User__c;
            if (currRule.Category__c=='Automating Pipeline' &&currRule.Type__c == 'Country')
                userTobeAssigned = performCountryBaseRuleCheck(accntInfo.billingcountrycode, currRule); // perform country matching
            if (currRule.Category__c=='Automating Pipeline' &&currRule.Type__c == 'ARR' && userTobeAssigned==null) 
                userTobeAssigned = performARRBaseRuleCheck(accntInfo, currRule); // perform ARR matching
            if (currRule.Category__c=='Lane Four' && (currRule.Type__c == 'Other' || currRule.Type__c == 'ARR') && userTobeAssigned==null) // perform matching base on LaneFour conditions
                userTobeAssigned = performLaneFourRuleCheck(accntInfo, currRule);
            //system.debug('RODRIGO userTobeAssigned ' + userTobeAssigned);
            if (userTobeAssigned != null && localPauseAssignment== true) // added for GTMS-14481
            {
                RR_Assignment_Rule__c localCurrRule = new RR_Assignment_Rule__c();
                localCurrRule = mapRule.get(currRule.Id);
                userTobeAssigned = localCurrRule.Next_Assignment__c;
                currRuleMapping = localCurrRule.Next_Assignment_Mapping__c;
                fieldToAssignUser = localCurrRule.Field_To_Assign_User__c;
                currRuleId = localCurrRule.Id;
                localPauseAssignment = localCurrRule.Next_Assignment_Mapping__r.Pause_Assignment__c;
                assignNextAssignmentUserUsingOrder(currRuleId, userTobeAssigned, null, false, currRuleMapping);
                rrInfo.userId = userTobeAssigned;
                rrInfo.fieldToUpdate = fieldToAssignUser;
                rrInfo.ruleId = currRuleId;
                rrInfo.mappingId = currRuleMapping;
                
                break;
            }
                
            if (userTobeAssigned != null && localPauseAssignment== false) {
                rrInfo.userId = userTobeAssigned;
                rrInfo.fieldToUpdate = fieldToAssignUser;
                rrInfo.ruleId = currRuleId;
                rrInfo.mappingId = currRuleMapping;
                break;
            }
            
        }
        
        /*if (userTobeAssigned == null) {
            // get details of rule that is configured as default
            if (defaultRule !=null && defaultRule.size()>0 && useDefaultRule) {
                rrInfo.userId = defaultRule[0].Next_Assignment__c;
                rrInfo.fieldToUpdate = defaultRule[0].Field_To_Assign_User__c;
                rrInfo.ruleId = defaultRule[0].Id;
                rrInfo.mappingId = defaultRule[0].Next_Assignment_Mapping__c;
                userTobeAssigned = defaultRule[0].Next_Assignment__c;
                currRuleMapping = defaultRule[0].Next_Assignment_Mapping__c;
                currRuleId = defaultRule[0].Id;
                
                assignNextAssignmentUserUsingOrder(currRuleId, userTobeAssigned, null, false, currRuleMapping);
            }
            
        }*/
        
        if (userTobeAssigned != null) {
            RR_Assignment_Log__c log = new RR_Assignment_Log__c();
            log.User__c = userTobeAssigned;
            log.Record_Id__c = accntInfo.Id;
            log.Record_Name__c = accntInfo.Name;
            log.RR_Assignment_Mapping__c = currRuleMapping;
            log.RR_Assignment_Rule__c = currRuleId;
            log.Status__c = 'Success';
            forInsertRRLog.add(log);
        }
        
        return rrInfo;
    }
    /**********************************************************************
    Name: performLaneFourRuleCheck
    =======================================================================
    Purpose: handles the logic to return user id base on Lane Four type rule                                                       
    =======================================================================
    History  
    
    VERSION     AUTHOR               DATE               DETAIL                       
    1.0        Rodrigo Carpio        2022-Nov-30        INITIAL DEVELOPMENT
    
    ***********************************************************************/
    public Id performLaneFourRuleCheck(Account accntInfo, RR_Assignment_Rule__c rule) {
        Id userId = null;
        Id ruleId = null;
        Boolean ruleMatched = false;
        
        ruleId = rule.Id;
        currRuleId = ruleId;
        currRuleMapping = rule.Next_Assignment_Mapping__c;
        string pamProfile = System.Label.PAM_Profiles;
        /*if (rule.NAME==testRuleName )
        {
            system.debug(rule.Is_Owner_Pool_User__c+ ' RODRIGO accntInfo.Is_Owner_Pool_User__c ' + accntInfo.Is_Owner_Pool_User__c);
        system.debug(rule.Assign_CSM__c + ' RODRIGO accntInfo.Assign_CSM__c ' + accntInfo.Assign_CSM__c);
            system.debug(rule.Assign_CSM__c + ' RODRIGO accntInfo.Assign_CSM__c ' + accntInfo.Assign_CSM__c);
        system.debug(rule.Deal_Reg_Account__c + ' RODRIGO accntInfo.is_deal_reg_account__c ' + accntInfo.is_deal_reg_account__c  );
        //system.debug(rule.Record_Type_Stamp_for_Dupes__c + ' RODRIGO accntInfo.Record_Type_Stamp_for_Dupes__c ' + accntInfo.Record_Type_Stamp_for_Dupes__c);
        system.debug(rule.Organization_Size__c + ' RODRIGO accntInfo.Organization_Size__c ' + accntInfo.Organization_Size__c);
        system.debug(rule.Global_Geography__c + ' RODRIGO accntInfo.Global_Geography__c ' + accntInfo.Global_Geography__c);
        system.debug(rule.Most_Recent_Source__c + ' RODRIGO accntInfo.Most_Recent_Source__c ' + accntInfo.Most_Recent_Source__c);
        system.debug(rule.Industry__c + ' RODRIGO accntInfo.Industry ' + accntInfo.Industry);
        system.debug(rule.Business_Unit__c + ' RODRIGO accntInfo.Business_Unit__c ' + accntInfo.Business_Unit__c);
        system.debug(rule.Partner_Program_Segment__c + ' RODRIGO accntInfo.Partner_Program_Segment__c ' + accntInfo.Partner_Program_Tier__c);
        system.debug(rule.Partner_Persona__c + ' RODRIGO accntInfo.Partner_Persona__c ' + accntInfo.Partner_Persona__c);
        system.debug(rule.Billing_Country__c + ' RODRIGO accntInfo.Billing_Country__c ' + accntInfo.BillingCountry);
        system.debug(rule.Billing_State__c + ' RODRIGO accntInfo.Billing_State__c ' + accntInfo.BillingState);
        system.debug(rule.Which_Written_Language__c + ' RODRIGO accntInfo.Which_Written_Language__c ' + accntInfo.Which_Written_Language__c);
        system.debug(rule.CS_Tier__c + ' RODRIGO accntInfo.CS_Tier__c ' + accntInfo.CS_Tier__c);
            system.debug(rule.Experimental_Group__c + ' RODRIGO accntInfo.Experimental_Group__c ' + accntInfo.Experimental_Group__c);
            system.debug(rule.Experimental_Group_Routing__c + ' RODRIGO accntInfo.Experimental_Group_Routing__c ' + accntInfo.Experimental_Group_Routing__c);
            system.debug(rule.Account_Size_Segment__c + ' RODRIGO accntInfo.Account_Size_Segment__c ' + accntInfo.Account_Size_Segment__c);
            system.debug(rule.Inside_Sales_Assignment__c + ' RODRIGO accntInfo.Inside_Sales_Assignment__c ' + accntInfo.Inside_Sales_Assignment__c);
            //system.debug('RODRIGO rule.Partner_Persona__c.containsIgnoreCase(accntInfo.Partner_Persona__c) ' + rule.Partner_Persona__c.containsIgnoreCase(accntInfo.Partner_Persona__c));
            //system.debug('RODRIGO rule.Partner_Persona__c.containsIgnoreCase(accntInfo.Partner_Persona__c) ' + rule.Partner_Program_Segment__c.containsIgnoreCase(accntInfo.Partner_Program_Tier__c));
        }*/
		
        //system.debug('RODRIGO Rule SLED_Check__c ' + rule.SLED_Check__c);
        //if (rule.SLED_Check__c ) { // logic that will be used for SLED related rules
        if(accntInfo.SLED_Account__c && rule.SLED_Check__c) { // change condition to check if account is SLED for // GTMS-17468  

                if (
                rule.Is_Owner_Pool_User__c == accntInfo.Is_Owner_Pool_User__c && 
                    ((rule.Deal_Reg_Account__c == accntInfo.is_deal_reg_account__c) ||
                     (accntInfo.is_deal_reg_account__c && pamProfile.containsIgnoreCase(accntInfo.Owner_Profile_Id__c)))  &&
                rule.Assign_CSM__c == accntInfo.Assign_CSM__c &&
                (string.isNotBlank(rule.Billing_Country__c) && rule.Billing_Country__c.containsIgnoreCase(accntInfo.BillingCountry)) && 
                (string.isNotBlank(rule.Billing_State__c) && rule.Billing_State__c.containsIgnoreCase(accntInfo.BillingState)) && 
                    (accntInfo.Hashtag__c==null || (string.isNotBlank(accntInfo.Hashtag__c) && string.isNotBlank(rule.Account_Hashtag__c) 
                                                    && !accntInfo.Hashtag__c.containsIgnoreCase(rule.Account_Hashtag__c)))
                ) // first SLED condition combination - NA Fleet Outbound ADR SLED #18, modified the codition for GTMS-16050
            {
                    if (accntInfo.Number_of_Vehicles__c==null && accntInfo.Number_of_Powered_Assets__c==null 
                        && accntInfo.Number_of_Students__c==null && accntInfo.Number_of_Citizens__c==null)
                        ruleMatched = true;
                    if (!ruleMatched && ((string.isNotBlank(rule.Number_of_Vehicles__c) && validateAccountAttribute(rule.Number_of_Vehicles__c, accntInfo.Number_of_Vehicles__c)) ||
                   (string.isNotBlank(rule.Number_of_Powered_Assets__c) && validateAccountAttribute(rule.Number_of_Powered_Assets__c, accntInfo.Number_of_Powered_Assets__c)) ||
                   (string.isNotBlank(rule.Number_of_Students__c) && validateAccountAttribute(rule.Number_of_Students__c, accntInfo.Number_of_Students__c)) ||
                                         (string.isNotBlank(rule.Number_of_Citizens__c) && validateAccountAttribute(rule.Number_of_Citizens__c, accntInfo.Number_of_Citizens__c))))
                	ruleMatched = true;
                
                    if (ruleMatched && ( ((accntInfo.is_deal_reg_account__c && pamProfile.containsIgnoreCase(accntInfo.Owner_Profile_Id__c)) ||
                                          (accntInfo.Industry == null && accntInfo.Industry=='Unknown')) ||
                              		(string.isNotBlank(rule.Industry__c) && rule.Industry__c.containsIgnoreCase(accntInfo.Industry))
                                   )
                   )
                    ruleMatched = true;
                else
                    ruleMatched = false;
            }
            //system.debug('RODRIGO Rule SLED_Check__c 2 ' + ruleMatched);
            if ( !ruleMatched &&
                rule.Is_Owner_Pool_User__c == accntInfo.Is_Owner_Pool_User__c &&
                rule.Assign_CSM__c == accntInfo.Assign_CSM__c &&
                (string.isNotBlank(rule.Record_Type_Stamp_for_Dupes__c) && rule.Record_Type_Stamp_for_Dupes__c.containsIgnoreCase(accntInfo.Record_Type_Stamp_for_Dupes__c)) &&
                 ( (string.isNotBlank(rule.Organization_Size__c) && rule.Organization_Size__c.containsIgnoreCase(accntInfo.Organization_Size__c)) || 
                   (string.isNotBlank(rule.Number_of_Students__c) && validateAccountAttribute(rule.Number_of_Students__c, accntInfo.Number_of_Students__c)) ||
                   (string.isNotBlank(rule.Number_of_Citizens__c) &&validateAccountAttribute(rule.Number_of_Citizens__c, accntInfo.Number_of_Citizens__c) ) ) &&
                (
                    (rule.sled__c == accntInfo.sled_account__c && accntInfo.sled_account__c == true) ||
                    validateAccountURLs(rule.Website__c, accntInfo.website) ||
                    validateAccountURLs(rule.Domain_Name__c, accntInfo.Domain_Name__c) ||
                    (string.isNotBlank(rule.Industry__c) && rule.Industry__c.containsIgnoreCase(accntInfo.Industry))
                    
                )
            ) // NA Fleet Enterprise AE SLED
            {
                if (accntInfo.Is_Owner_Pool_User__c == true) {
                    if ((string.isNotBlank(rule.Most_Recent_Source__c) && string.isNotBlank(accntInfo.Most_Recent_Source__c) 
                         && rule.Most_Recent_Source__c.containsIgnoreCase(accntInfo.Most_Recent_Source__c)))
                        ruleMatched = true;
                    else
                        ruleMatched = false;
                }
                    //else
                    //    ruleMatched = true;
            }
            //system.debug('RODRIGO Rule SLED_Check__c 3 ' + ruleMatched);
            if ( !ruleMatched &&
                !accntInfo.is_deal_reg_account__c && // added for GTMS-15570 to exclude accounts that is marked as deal reg
                rule.Is_Owner_Pool_User__c == accntInfo.Is_Owner_Pool_User__c && 
                rule.Assign_CSM__c == accntInfo.Assign_CSM__c &&
                (string.isNotBlank(rule.Billing_Country__c) && rule.Billing_Country__c.containsIgnoreCase(accntInfo.BillingCountry)) && 
                (string.isNotBlank(rule.Billing_State__c) && rule.Billing_State__c.containsIgnoreCase(accntInfo.BillingState)) &&
                (string.isNotBlank(accntInfo.Hashtag__c) && string.isNotBlank(rule.Account_Hashtag__c) && !accntInfo.Hashtag__c.containsIgnoreCase(rule.Account_Hashtag__c))
            ) // NA Fleet SLED AE2 All Regions
            {
                if ((string.isNotBlank(rule.Organization_Size__c) && rule.Organization_Size__c.containsIgnoreCase(accntInfo.Organization_Size__c)) ||
                   //validateAccountAttribute(rule.Number_of_Powered_Assets__c, accntInfo.Number_of_Powered_Assets__c) ||
                   (string.isNotBlank(rule.Number_of_Students__c) && validateAccountAttribute(rule.Number_of_Students__c, accntInfo.Number_of_Students__c)) ||
                   (string.isNotBlank(rule.Number_of_Citizens__c) && validateAccountAttribute(rule.Number_of_Citizens__c, accntInfo.Number_of_Citizens__c)))
                	ruleMatched = true;
                if (ruleMatched && ( (rule.sled__c == accntInfo.sled_account__c && accntInfo.sled_account__c == true) ||
                              		(string.isNotBlank(rule.Industry__c) && rule.Industry__c.containsIgnoreCase(accntInfo.Industry))
                                   )
                   )
                    ruleMatched = true;
                else
                    ruleMatched = false;
            }
                // added for GTMS-17468 starts here
                if ( !ruleMatched &&
                    rule.Is_Owner_Pool_User__c == accntInfo.Is_Owner_Pool_User__c &&
                    string.isBlank(rule.Number_of_Vehicles__c) &&
                    string.isBlank(rule.Number_of_Powered_Assets__c) &&
                    string.isBlank(rule.Number_of_Students__c) &&
                    string.isBlank(rule.Number_of_Citizens__c) &&
                    (string.isNotBlank(rule.Industry__c) && rule.Industry__c.containsIgnoreCase(accntInfo.Industry)) &&
                    (string.isNotBlank(rule.Billing_Country__c) && rule.Billing_Country__c.containsIgnoreCase(accntInfo.BillingCountry)) &&
                    (string.isNotBlank(rule.Billing_State__c) && rule.Billing_State__c.containsIgnoreCase(accntInfo.BillingState)) 
                   ) 
                {
                    ruleMatched = true;
                } // added for GTMS-17468 ends here
                
            //system.debug('RODRIGO Rule SLED_Check__c 4 ' + ruleMatched);
        }
        else{
            string globalGeography = null;
            if (accntInfo.BillingCountry == 'United States' && String.isNotBlank(accntInfo.Global_Geography__c)){ //Modified this condition as part of GTMS-18362(GTMS-19824).
                globalGeography = !accntInfo.Global_Geography__c.contains('United States') ? accntInfo.BillingCountry + ' ' + accntInfo.Global_Geography__c : accntInfo.Global_Geography__c;
            }else
                globalGeography = accntInfo.Global_Geography__c;
            
            if ((rule.Is_Owner_Pool_User__c == accntInfo.Is_Owner_Pool_User__c || rule.No_Pool_User_Check__c) &&
                rule.Assign_CSM__c == accntInfo.Assign_CSM__c &&
                //((rule.Deal_Reg_Account__c == false || (rule.Deal_Reg_Account__c == true && rule.Deal_Reg_Account__c == accntInfo.is_deal_reg_account__c))  &&
                ( (rule.Deal_Reg_Account__c == accntInfo.is_deal_reg_account__c || rule.No_Deal_Reg_Check__c) ||
                 (accntInfo.is_deal_reg_account__c && pamProfile.containsIgnoreCase(accntInfo.Owner_Profile_Id__c)))
                 && // change for GTMS-14837 added OR condition for GTMS-15570
                (rule.Onboarding_Complete__c  == false || (rule.Onboarding_Complete__c  == true && rule.Onboarding_Complete__c  == accntInfo.Onboarding_Complete__c))   &&
                (rule.Experimental_Group__c == false || (rule.Experimental_Group__c == true && rule.Experimental_Group__c == accntInfo.Experimental_Group__c)) && 
                ((rule.Record_Type_Stamp_for_Dupes__c != null && accntInfo.Record_Type_Stamp_for_Dupes__c != null && rule.Record_Type_Stamp_for_Dupes__c.containsIgnoreCase(accntInfo.Record_Type_Stamp_for_Dupes__c)) || rule.Record_Type_Stamp_for_Dupes__c==null) &&
                ((rule.Organization_Size__c != null && accntInfo.Organization_Size__c != null && rule.Organization_Size__c.containsIgnoreCase(accntInfo.Organization_Size__c)) || rule.Organization_Size__c == null) &&
                ((rule.Global_Geography__c != null && accntInfo.Global_Geography__c != null && rule.Global_Geography__c.containsIgnoreCase(globalGeography)) || rule.Global_Geography__c == null) &&
                ((rule.Most_Recent_Source__c != null && accntInfo.Most_Recent_Source__c != null && rule.Most_Recent_Source__c.containsIgnoreCase(accntInfo.Most_Recent_Source__c)) || rule.Most_Recent_Source__c == null) &&
                ((rule.Industry__c != null && accntInfo.Industry != null && rule.Industry__c.containsIgnoreCase(accntInfo.Industry)) || rule.Industry__c == null) &&  
                ((rule.Business_Unit__c != null && accntInfo.Business_Unit__c != null && rule.Business_Unit__c.containsIgnoreCase(accntInfo.Business_Unit__c)) || rule.Business_Unit__c == null ) &&
                ((rule.Partner_Team_Alignment__c != null && accntInfo.Partner_Type__c != null && rule.Partner_Team_Alignment__c.containsIgnoreCase(accntInfo.Partner_Type__c)) || rule.Partner_Team_Alignment__c == null ) &&
                ((rule.Partner_Program_Segment__c  != null && accntInfo.Partner_Program_Tier__c  != null && rule.Partner_Program_Segment__c.containsIgnoreCase(accntInfo.Partner_Program_Tier__c)) || rule.Partner_Program_Segment__c  == null ) &&
                ((rule.Partner_Persona__c != null && accntInfo.Partner_Persona__c != null && rule.Partner_Persona__c.containsIgnoreCase(accntInfo.Partner_Persona__c)) || rule.Partner_Persona__c == null ) &&
                ((rule.Billing_Country__c  != null && accntInfo.BillingCountry  != null && rule.Billing_Country__c.containsIgnoreCase(accntInfo.BillingCountry)) || rule.Billing_Country__c  == null ) &&
                ((rule.Billing_State__c != null && accntInfo.Billing_State__c != null && rule.Billing_State__c.containsIgnoreCase(accntInfo.BillingState)) || rule.Billing_State__c == null ) &&
                ((rule.Which_Written_Language__c  != null && accntInfo.Which_Written_Language__c != null && rule.Which_Written_Language__c.containsIgnoreCase(accntInfo.Which_written_language__c)) || rule.Which_Written_Language__c  == null || 
                (rule.Which_Written_Language__c.containsIgnoreCase(LANGUAGE_BLANK_STRING) && String.isBlank(accntInfo.Which_Written_Language__c))) &&
                ((rule.CS_Tier__c  != null && accntInfo.CS_Tier__c != null && rule.CS_Tier__c.containsIgnoreCase(accntInfo.CS_Tier__c)) || rule.CS_Tier__c  == null ) &&
				((rule.Account_Hashtag__c  != null && accntInfo.Hashtag__c  != null && rule.Account_Hashtag__c.containsIgnoreCase(accntInfo.Hashtag__c)) || rule.Account_Hashtag__c  == null) &&
				//((rule.Experimental_Group__c  != null && rule.Experimental_Group__c == accntInfo.Experimental_Group__c) || rule.Experimental_Group__c  == null ) &&
				((rule.Experimental_Group_Routing__c  != null && rule.Experimental_Group_Routing__c == accntInfo.Experimental_Group_Routing__c) || rule.Experimental_Group_Routing__c  == null ) &&
				((rule.Account_Size_Segment__c  != null && accntInfo.Account_Size_Segment__c  != null && rule.Account_Size_Segment__c.containsIgnoreCase(accntInfo.Account_Size_Segment__c)) || rule.Account_Size_Segment__c  == null ) &&
				((rule.Inside_Sales_Assignment__c  != null && rule.Inside_Sales_Assignment__c==accntInfo.Inside_Sales_Assignment__c) 
                || rule.Inside_Sales_Assignment__c  == null) &&
                // Added below Owner Manager logic as part of GTMS-23546
                 ((rule.Owner_Manager__c != null && accntInfo.Owner_Manager__c != null && rule.Owner_Manager__c.containsIgnoreCase(accntInfo.Owner_Manager__c)) || rule.Owner_Manager__c == null) &&
                 ((rule.Customer_ARR__c!=null && accntInfo.Customer_ARR__c!=null && validateARRCondition(rule.Customer_ARR__c, accntInfo.Customer_ARR__c)) || rule.Customer_ARR__c==null) &&
                //Added as below Timezone & Owner Role logic as part of GTMS-18362(GTMS-19824)
                ((rule.Timezone__c != null && accntInfo.Timezone__c  != null && rule.Timezone__c.containsIgnoreCase(accntInfo.Timezone__c)) || rule.Timezone__c  == null ) &&
				((checkRuleOwnerMatch(rule.Owner_Role__c, accntInfo.Owner_Role__c)))
               )
                
                /*&&
                (((rule.Number_of_Vehicles__c != null && rule.Number_of_Vehicles__c >= accntInfo.Number_of_Vehicles__c) || accntInfo.Number_of_Vehicles__c == null) || 
                ((rule.Number_of_Powered_Assets__c != null && rule.Number_of_Powered_Assets__c >= accntInfo.Number_of_Powered_Assets__c) 
                || accntInfo.Number_of_Powered_Assets__c == null) || 
                ((rule.Number_of_Unpowered_Assets__c != null && rule.Number_of_Unpowered_Assets__c >= accntInfo.Number_of_Unpowered_Assets__c) || accntInfo.Number_of_Unpowered_Assets__c == null) 
                )*/
            {
                system.debug(' RODRIGO Number conditions');
                if (rule.Number_of_Students__c == null && rule.Number_of_Citizens__c == null && rule.Number_of_Vehicles__c == null 
                    && rule.Number_of_Powered_Assets__c == null && rule.Number_of_Unpowered_Assets__c == null && rule.Account_Lifetime_ACV__c == null && rule.Customer_ARR__c==null){
                   system.debug(' RODRIGO Number conditions');
                    ruleMatched = true;
                    }
                else {
                    if (rule.Use_AND_Condition__c) {
                        //system.debug(' RODRIGO Number conditions ' + rule.Use_AND_Condition__c);
                        Boolean numberOfVehicle = false;
                        Boolean numberPoweredAsset = false;
                        Boolean numberUnpoweredAsset = false;
                        if (accntInfo.Number_of_Vehicles__c == null || rule.Number_of_Vehicles__c == null || validateAccountAttribute(rule.Number_of_Vehicles__c, accntInfo.Number_of_Vehicles__c))
                            numberOfVehicle = true;
                        if (accntInfo.Number_of_Powered_Assets__c == null || rule.Number_of_Powered_Assets__c == null || validateAccountAttribute(rule.Number_of_Powered_Assets__c, accntInfo.Number_of_Powered_Assets__c))
                            numberPoweredAsset = true;
                        if (accntInfo.Number_of_Unpowered_Assets__c == null || rule.Number_of_Unpowered_Assets__c == null || validateAccountAttribute(rule.Number_of_Unpowered_Assets__c, accntInfo.Number_of_Unpowered_Assets__c))
                            numberUnpoweredAsset = true;
                        if (numberOfVehicle && numberPoweredAsset && numberUnpoweredAsset)
                            ruleMatched = true;
                        //system.debug(' RODRIGO Number ruleMatched Use_AND_Condition__c ' + ruleMatched);
                    }
                    else {
                        if (rule.Number_of_Vehicles__c != null)
                            ruleMatched = validateAccountAttribute(rule.Number_of_Vehicles__c, accntInfo.Number_of_Vehicles__c);
                        if (!ruleMatched && rule.Number_of_Powered_Assets__c != null)
                            ruleMatched = validateAccountAttribute(rule.Number_of_Powered_Assets__c, accntInfo.Number_of_Powered_Assets__c);
                        if (!ruleMatched && rule.Number_of_Unpowered_Assets__c != null)
                            ruleMatched = validateAccountAttribute(rule.Number_of_Unpowered_Assets__c, accntInfo.Number_of_Unpowered_Assets__c);
                        if (!ruleMatched && rule.Number_of_Students__c != null)
                            ruleMatched = validateAccountAttribute(rule.Number_of_Students__c, accntInfo.Number_of_Students__c);
                        if (!ruleMatched && rule.Number_of_Citizens__c != null)
                            ruleMatched = validateAccountAttribute(rule.Number_of_Citizens__c, accntInfo.Number_of_Citizens__c);
                        //system.debug(' RODRIGO Number conditions 2 ' + ruleMatched );
                        //system.debug(' RODRIGO Number conditions 2 ' + rule.Account_Lifetime_ACV__c );
                        //system.debug(' RODRIGO Number conditions 2 ' + accntInfo.Account_Lifetime_ACV__c );
                        if (!ruleMatched && rule.Account_Lifetime_ACV__c != null)
                            ruleMatched = validateAccountAttribute(rule.Account_Lifetime_ACV__c, accntInfo.Account_Lifetime_ACV__c); 
                       
                    }
                    
                }
                //system.debug(' RODRIGO Number conditions 3 ' + ruleMatched );
                // check domain and website info
                if (rule.Website__c!=null || rule.Domain_Name__c!=null) {
                    if (rule.Website__c!=null)
                        ruleMatched = validateAccountURLs(rule.Website__c, accntInfo.website);
                    if (!ruleMatched && rule.Domain_Name__c!=null)
                        ruleMatched = validateAccountURLs(rule.Domain_Name__c, accntInfo.Domain_Name__c);
                }
                //system.debug(' RODRIGO Number conditions 4 ' + ruleMatched );
                if (rule.CSM_Null_Check__c) {  // logic for CSM field value check
                    if (accntInfo.CSM__c==null)
                        ruleMatched=true;
                    else 
                        ruleMatched=false;
                }
                //system.debug(' RODRIGO Number conditions 5 ' + ruleMatched );
                if (rule.SIC_Null_Check__c) { // logic for CSM field value check
                    if (accntInfo.SIC__c==null)
                        ruleMatched=true;
                    else 
                        ruleMatched=false;
                }
                //system.debug(' RODRIGO Number conditions 6 ' + ruleMatched );
            }
        }
        //system.debug('RODRIGO ruleMatched before exit 1 ' + rule);
        
        if (ruleMatched) {
            ruleIdToBeUpdated.add(ruleId);
            
            if (rule.Always_Use_Next_Assignment__c)
                return rule.Next_Assignment__c;
            else
                userId = rule.Next_Assignment__c;
        }
        
        if (rule.Type__c == 'ARR') {
            //performARRBaseRuleCheck(accntInfo, rule);
            // perform logic to determine next assignment user by ARR Value
            Double locCustomerARR = (accntInfo.Customer_ARR__c!=null) ? accntInfo.Customer_ARR__c : 0;//accntInfo.Customer_ARR__c
            assignNextAssignmentUserUsingValue(rule.Id, userId, null, false, locCustomerARR, rule.Next_Assignment_Mapping__c);
        }
        else {
            // perform logic to determine next assignment user by order
            if (userId != null) {
                assignNextAssignmentUserUsingOrder(ruleId, userId, null, false, currRuleMapping);
            }
        }
        //system.debug('RODRIGO ruleMatched before exit 2 ' + rule);  
        return userId;
    }
    
    //Added as method as part of GTMS-18362(GTMS-19824). Check if the Owner Rule criteria matches the owner rule in account, if no Owner rule in RR, skip evaluation.
    //****NOTE: Once the FormulaEval namespace is GA, replace the below logic with FormulaEval. Reference: https://help.salesforce.com/s/articleView?id=release-notes.rn_apex_formulaeval.htm&release=248&type=5
    private boolean checkRuleOwnerMatch(string input, string actual){

        return string.isBlank(input) ? true : calculateBooleanFormula(replaceCharsWithBooleans(input, actual));
    }
    
    //Added as method as part of GTMS-18362(GTMS-19824). Converts all the characters into booleans if they are available in Actual
    private string replaceCharsWithBooleans(string input, string actual){
        
        string chars = input.replaceAll(openBrackets,emptyString);
        chars = chars.replace(negation,emptyString);
        chars = chars.replaceAll(closedBrackets,emptyString);
        chars = chars.replaceAll(andString,semicolan);
        chars = chars.replaceAll(orString,semicolan);

        list<string> keys = chars.deleteWhitespace().split(semicolan);
        
        for(String key :keys){
            //Each word in input(key) will be replaced by boolean if the word is present in Actual word.
            input = input.replaceFirst(key, string.valueOf(actual.containsIgnoreCase(key.replace(underscore,space))));
        }

        input = input.deleteWhitespace();
 
        input = input.replace(notTrue, 'false');
        input = input.replace(notfalse, 'true');

        return input;
    }
    
    //Added as method as part of GTMS-18362(GTMS-19824). Evaluate the formula
    private boolean calculateBooleanFormula(String input){

        string previousString = '';

        while(input != 'true' && input != 'false'){

            input = input.replace(trueAndTrue, 'true');
            input = input.replaceAll(trueOrTrue, 'true');
            input = input.replaceAll(trueOrFalse, 'true');
            input = input.replaceAll(falseOrTrue, 'true');
            input = input.replace(falseAndfalse, 'false');
            input = input.replace(trueAndFalse, 'false');
            input = input.replace(falseAndTrue, 'false');
            input = input.replaceAll(falseorfalse, 'false');
            input = input.replace(trueinBrakets, 'true');
            input = input.replace(falseinBrackets, 'false');

            //Avoids infinite recurssion.
            if(previousString == input){
                System.debug('Owner Role matching Logic Failed, recheck method --> checkRuleOwnerMatch');
                break;
            }
            previousString = input;
        }

        System.debug(input);
        
        return boolean.valueOf(input);
    }

    
    /**********************************************************************
    Name: validateAccountURLs
    =======================================================================
    Purpose: handles the logic to return validate account website/domain                                                       
    =======================================================================
    History  
    
    VERSION     AUTHOR               DATE               DETAIL                       
    1.0        Rodrigo Carpio        2023-Feb-6        INITIAL DEVELOPMENT
    
    ***********************************************************************/
    public Boolean validateAccountURLs(String ruleDetail, String accntFieldValue) {
        //system.debug('RODRIGO validateAccountURLs ' + ruleDetail);
        //system.debug('RODRIGO validateAccountURLs ' + accntFieldValue);
        Boolean ruleMatched = false;
        if(accntFieldValue == null)
            return true;
        List<String> strToMatch = new List<String>();
        if(ruleDetail != null)
        	strToMatch = ruleDetail.split(';');
       FOR (string str:strToMatch){
            if(accntFieldValue.containsIgnoreCase(str)){
                ruleMatched=true;
                break;
            }
                
        }
        return ruleMatched;
    }
    /**********************************************************************
    Name: validateAccountAttribute
    =======================================================================
    Purpose: handles the logic to validate vehicle/assset/student/citizen counts                                                       
    =======================================================================
    History  
    
    VERSION     AUTHOR               DATE               DETAIL                       
    1.0        Rodrigo Carpio        2023-Feb-3        INITIAL DEVELOPMENT
    
    ***********************************************************************/
    public Boolean validateAccountAttribute(String ruleDetail, Decimal accntFieldValue) {
        Boolean ruleMatched = false;
        if (ruleDetail.containsIgnoreCase('AND')) {
            boolean match1 = false;
            boolean match2 = false;
            string ruleDetail1 = ruleDetail.substringBefore('AND');
            string ruleDetail2 = ruleDetail.substringAfter('AND');
            match1 = validateFieldValue(ruleDetail1.trim(), accntFieldValue);
            match2 = validateFieldValue(ruleDetail2.trim(), accntFieldValue);
            ruleMatched = (match1 && match2) ? true : false;
        }
        else {
          //  system.debug('RODRIGO validateAccountAttribute');
            ruleMatched = validateFieldValue(ruleDetail, accntFieldValue);
        }
        
        return ruleMatched;
    }
    
/**********************************************************************
    Name: validateARRCondition
    =======================================================================
    Purpose: handles the logic to validate Customer ARR counts  
	JIRA Ticket: GTMS-23546
    =======================================================================
    History  
    
    VERSION     AUTHOR               DATE               DETAIL                       
    1.0        Anil Kothapally     2024-Sep-3        INITIAL DEVELOPMENT
    ***********************************************************************/
    
    public Boolean validateARRCondition(String ruleDetail, Decimal accntFieldValue) {
        Boolean ruleMatched = false;
        String conditionValue = ruleDetail.substring(0,2);
        String ruleFieldValue = ruleDetail.substringAfter(conditionValue);
        accntFieldValue = (accntFieldValue != null) ? accntFieldValue : 0;
        Decimal ruleDecValue = Decimal.valueOf(ruleFieldValue.trim());
        if (conditionValue.trim() == '=='){
            ruleMatched = (ruleDecValue == accntFieldValue) ? true : false;
        }
        else if (!ruleMatched && conditionValue.trim() == '>='){
            ruleMatched = (accntFieldValue >= ruleDecValue) ? true : false;
        }
        else if (!ruleMatched && conditionValue.trim() == '<='){
            ruleMatched = (accntFieldValue <= ruleDecValue) ? true : false;
        }
        else if (!ruleMatched && conditionValue.trim() == '<'){
            ruleMatched = (accntFieldValue < ruleDecValue) ? true : false;
        }
        else if (!ruleMatched && conditionValue.trim() == '>'){
            ruleMatched = (accntFieldValue > ruleDecValue) ? true : false;
        }
        //system.debug('RODRIGO ruleMatched ' + ruleMatched);
        return ruleMatched;
    }
    
    
    public Boolean validateFieldValue(String ruleDetail, Decimal accntFieldValue) {
        Boolean ruleMatched = false;
        String conditionValue = ruleDetail.substring(0,2);
        String ruleFieldValue = ruleDetail.substringAfter(conditionValue);
        accntFieldValue = (accntFieldValue != null) ? accntFieldValue : 0;
        /*system.debug('RODRIGO conditionValue ' + conditionValue);
        system.debug('RODRIGO ruleFieldValue ' + ruleFieldValue);
        system.debug('RODRIGO accntFieldValue ' + accntFieldValue);*/
        Decimal ruleDecValue = Decimal.valueOf(ruleFieldValue.trim());
        if (conditionValue.trim() == '==')
            ruleMatched = (ruleDecValue == accntFieldValue) ? true : false;
        if (!ruleMatched && conditionValue.trim() == '>=')
            ruleMatched = (accntFieldValue >= ruleDecValue) ? true : false;
        if (!ruleMatched && conditionValue.trim() == '<=')
            ruleMatched = (accntFieldValue <= ruleDecValue) ? true : false;
        if (!ruleMatched && conditionValue.trim() == '<')
            ruleMatched = (accntFieldValue < ruleDecValue) ? true : false;
        if (!ruleMatched && conditionValue.trim() == '>')
            ruleMatched = (accntFieldValue > ruleDecValue) ? true : false;
        //system.debug('RODRIGO ruleMatched ' + ruleMatched);
        return ruleMatched;
    }
    
    /**********************************************************************
Name: performARRBaseRuleCheck
=======================================================================
Purpose: handles the logic to return user id base on ARR type rule                                                       
=======================================================================
History  

VERSION     AUTHOR               DATE               DETAIL                       
1.0        Rodrigo Carpio        2022-Nov-30        INITIAL DEVELOPMENT

***********************************************************************/
    @testvisible private Id performARRBaseRuleCheck(Decimal customerARR, Decimal renewalACVValue, Boolean sledAccount, RR_Assignment_Rule__c rule) {
        Id userId = null;
        Id ruleId = null;
        String userGroup = null;
        Boolean sledUser = false;
        Double acccountARRValue = 0;
        Double acccountRenewalACVValue = (renewalACVValue != null) ? renewalACVValue : 0;
        /*system.debug('RODRIGO performARRBaseRuleCheck rule ' + rule);
        system.debug('RODRIGO performARRBaseRuleCheck rule ' + rule.Max_Value__c);
        system.debug('RODRIGO performARRBaseRuleCheck rule ' + rule.Min_Value__c);
        system.debug('RODRIGO performARRBaseRuleCheck customerARR ' + customerARR);
        system.debug('RODRIGO performARRBaseRuleCheck renewalACVValue ' + renewalACVValue);
        system.debug('RODRIGO performARRBaseRuleCheck rule.Next_Assignment__c ' + rule.Next_Assignment__c);
        system.debug('RODRIGO performARRBaseRuleCheck rule.Queue_name__c ' + rule.Queue_name__c);*/
        //FOR (RR_Assignment_Rule__c rule : mapRule.values()){
            acccountARRValue = (customerARR != null) ? customerARR : 0;
            ruleId = rule.Id;
            currRuleId = ruleId;
            currRuleMapping = rule.Next_Assignment_Mapping__c;
        	currQueueName = rule.Queue_Name__c;
            if ((rule.Max_Value__c == null || rule.Max_Value__c == 0) && acccountARRValue >= rule.Min_Value__c) { // ARR >= 500K
                //ruleId = rule.Id;
                //currRule = ruleId;
                /*ruleIdToBeUpdated.add(ruleId);
                //userGroup = 'Strat SRAE';
                if (rule.Always_Use_Next_Assignment__c)
                    return rule.Next_Assignment__c;
                else
                    userId = rule.Next_Assignment__c;*/
                //break;
                userId = getRuleAssignmentValue(sledAccount,rule);
            }
            else if ((rule.Min_Value__c != null && rule.Min_Value__c != 0) && acccountARRValue >= rule.Min_Value__c  && acccountARRValue < rule.Max_Value__c ) 
            { // ARR >= 150K and ARR < 500K/ARR >= 25K and ARR < 150K
        		//ruleId = rule.Id;
                //currRule = ruleId;
                /*ruleIdToBeUpdated.add(ruleId);
                userGroup = 'SRAE';
                if (rule.Always_Use_Next_Assignment__c)
                    return rule.Next_Assignment__c;
                else
                    userId = rule.Next_Assignment__c;
				*/
                //break;
                if (rule.SLED__c && sledAccount)
                    sledUser = true;
                userId = getRuleAssignmentValue(sledAccount,rule);
                /*if (rule.SLED__c) {
                    if (sledAccount)
                    {
                        //ruleId = rule.Id;
                        ruleIdToBeUpdated.add(ruleId);
                        sledUser = true;
                        if (rule.Always_Use_Next_Assignment__c)
                            return rule.Next_Assignment__c;
                        else
                            userId = rule.Next_Assignment__c;
                        //   break;
                    }
                } 
                else {
                    //system.debug('RODRIGO performARRBaseRuleCheck before sled check ' + rule.SLED__c);
                    //system.debug('RODRIGO performARRBaseRuleCheck before sled sledAccount ' + sledAccount);
                    if (!sledAccount) {
                        //ruleId = rule.Id;
                        ruleIdToBeUpdated.add(ruleId);
                        if (rule.Always_Use_Next_Assignment__c)
                            return rule.Next_Assignment__c;
                        else
                            userId = rule.Next_Assignment__c;
                        //   break;
                    }
                    //system.debug('RODRIGO performARRBaseRuleCheck ' + userId);
                }*/
            }
            else if ((rule.Min_Value__c == null || rule.Min_Value__c == 0) && acccountARRValue < rule.Max_Value__c) {
                //userGroup = 'RAE';
                if (rule.Is_Owner_Pool_User__c==true) {
                    //ruleId = rule.Id;
                    ruleIdToBeUpdated.add(ruleId);
                    sledUser = true;
                    if (rule.Always_Use_Next_Assignment__c)
                        return rule.Next_Assignment__c;
                    else
                        userId = rule.Next_Assignment__c;
                    //   break;
                }
                else {
                    userId = getRuleAssignmentValue(sledAccount,rule);
                }
                
                
            }	
        //system.debug('RODRIGO performARRBaseRuleCheck ' + ruleIdToBeUpdated);
        //system.debug('RODRIGO performARRBaseRuleCheck ' + userId);
        //}
        // perform logic to determine next assignment user
        //if ((userId != null || currQueueName!=null) && !rule.Always_Use_Next_Assignment__c) 
        if ((currRuleMapping != null) && !rule.Always_Use_Next_Assignment__c)
        {
            //system.debug('RODRIGO assignNextAssignmentUserUsingValue bfore ' + userId);
            assignNextAssignmentUserUsingValue(ruleId, userId, userGroup, sledUser, acccountRenewalACVValue, currRuleMapping);
        }
        
        return userId;
    }
    /**********************************************************************
    Name: getRuleAssignmentValue
    =======================================================================
    Purpose: handles the logic to return user id base on ARR type rule                                                       
    =======================================================================
    History  
    
    VERSION     AUTHOR               DATE               DETAIL                       
    1.0        Rodrigo Carpio        2022-Nov-30        INITIAL DEVELOPMENT
    
    ***********************************************************************/
    @testvisible private Id getRuleAssignmentValue(Boolean sledAccount, RR_Assignment_Rule__c rule) {
        Id userId = null;
        if (rule.SLED__c) {
            if (sledAccount)
            {
                //ruleId = rule.Id;
                ruleIdToBeUpdated.add(rule.id);
                //sledUser = true;
                if (rule.Always_Use_Next_Assignment__c)
                    return rule.Next_Assignment__c;
                else
                    userId = rule.Next_Assignment__c;
                //   break;
            }
        } 
        else {
            if (!sledAccount) {
                //ruleId = rule.Id;
                ruleIdToBeUpdated.add(rule.id);
                if (rule.Always_Use_Next_Assignment__c)
                    return rule.Next_Assignment__c;
                else
                    userId = rule.Next_Assignment__c;
                //   break;
            }
            
        }
        return userId;
    }
    /**********************************************************************
    Name: performARRBaseRuleCheck
    =======================================================================
    Purpose: handles the logic to return user id base on ARR type rule                                                       
    =======================================================================
    History  
    
    VERSION     AUTHOR               DATE               DETAIL                       
    1.0        Rodrigo Carpio        2022-Nov-30        INITIAL DEVELOPMENT
    
    ***********************************************************************/
    @testvisible private Id performARRBaseRuleCheck(Account accntInfo, RR_Assignment_Rule__c rule) {
        Id userId = null;
        Id ruleId = null;
        String userGroup = null;
        Boolean sledUser = false;
        Double acccountARRValue = 0;
        
        //FOR (RR_Assignment_Rule__c rule : mapRule.values()){
            acccountARRValue = accntInfo.Customer_ARR__c;
            ruleId = rule.Id;
            currRuleId = ruleId;
            currRuleMapping = rule.Next_Assignment_Mapping__c;
            currQueueName = rule.Queue_Name__c;
            if ((rule.Max_Value__c == null || rule.Max_Value__c == 0) && accntInfo.Customer_ARR__c >= rule.Min_Value__c) { // ARR >= 500K
                //ruleId = rule.Id;
                //currRule = ruleId;
                ruleIdToBeUpdated.add(ruleId);
                userGroup = 'Strat SRAE';
                if (rule.Always_Use_Next_Assignment__c)
                    return rule.Next_Assignment__c;
                else
                    userId = rule.Next_Assignment__c;
                //break;
            }
            else if ((rule.Min_Value__c != null && rule.Min_Value__c != 0) && accntInfo.Customer_ARR__c >= rule.Min_Value__c  && accntInfo.Customer_ARR__c < rule.Max_Value__c ) { // ARR >= 150K and ARR < 500K
        		//ruleId = rule.Id;
                //currRule = ruleId;
                ruleIdToBeUpdated.add(ruleId);
                userGroup = 'SRAE';
                if (rule.Always_Use_Next_Assignment__c)
                    return rule.Next_Assignment__c;
                else
                    userId = rule.Next_Assignment__c;
                //break;
            }
            else if ((rule.Min_Value__c == null || rule.Min_Value__c == 0) && accntInfo.Customer_ARR__c < rule.Max_Value__c) {
                userGroup = 'RAE';
                if (rule.SLED__c) {
                    if (accntInfo.SLED_Account__c)
                    {
                        //ruleId = rule.Id;
                        ruleIdToBeUpdated.add(ruleId);
                        sledUser = true;
                        if (rule.Always_Use_Next_Assignment__c)
                            return rule.Next_Assignment__c;
                        else
                    		userId = rule.Next_Assignment__c;
                     //   break;
                    }
                } 
                else {
                    if (!accntInfo.SLED_Account__c) {
                        //ruleId = rule.Id;
                        ruleIdToBeUpdated.add(ruleId);
                        if (rule.Always_Use_Next_Assignment__c)
                            return rule.Next_Assignment__c;
                        else
                    		userId = rule.Next_Assignment__c;
                     //   break;
                    }
                }
            }
        //}
        // perform logic to determine next assignment user
        if (userId != null) {
            assignNextAssignmentUserUsingValue(ruleId, userId, userGroup, sledUser, acccountARRValue, currRuleMapping);
        }
        
        return userId;
    }
    
    /**********************************************************************
    Name: performCountryBaseRuleCheck
    =======================================================================
    Purpose: handles the logic to return user id base on country type rule                                                       
    =======================================================================
    History  
    
    VERSION     AUTHOR               DATE               DETAIL                       
    1.0        Rodrigo Carpio        2022-Nov-30        INITIAL DEVELOPMENT
    
    ***********************************************************************/
    private Id performCountryBaseRuleCheck(string countryCode, RR_Assignment_Rule__c rule) {
    	Id userId = null;
        Id ruleId = null;
        //FOR (RR_Assignment_Rule__c rule : mapRule.values()){
            if (rule.Region__c != null && rule.Region__c.containsIgnoreCase(countryCode)) {
                ruleId = rule.Id;
                currRuleId = ruleId;
                currRuleMapping = rule.Next_Assignment_Mapping__c;
                currQueueName = rule.Queue_Name__c;
                ruleIdToBeUpdated.add(ruleId);
                if (rule.Always_Use_Next_Assignment__c)
                    return rule.Next_Assignment__c;
                else
                    userId = rule.Next_Assignment__c;
                //break;
            }
        //}
        
        // perform logic to determine next assignment user
        if (userId != null || currQueueName != null) {
            assignNextAssignmentUserUsingOrder(ruleId, userId, null, false, currRuleMapping);
        }
        
        return userId;
    }
    
    /**********************************************************************
    Name: assignNextAssignmentUserUsingValue
    =======================================================================
    Purpose: handles the logic to determine the Next Assignment User using value                                                      
    =======================================================================
    History  
    
    VERSION     AUTHOR               DATE               DETAIL                       
    1.0        Rodrigo Carpio        2022-Nov-30        INITIAL DEVELOPMENT
    
    ***********************************************************************/
    private void assignNextAssignmentUserUsingValue(Id ruleId, Id userId, String userGroup, Boolean sledFlag, Double arrValue, Id currentMappingId) {
        //system.debug('RODRIGO assignNextAssignmentUserUsingValue ruleUserMaps.get(ruleId) ' + ruleId);
        //system.debug('RODRIGO assignNextAssignmentUserUsingValue ruleUserMaps.get(ruleId) ' + currentMappingId);	
        //system.debug('RODRIGO assignNextAssignmentUserUsingValue ruleUserMaps.get(ruleId) ' + ruleUserMaps.get(ruleId));	
        //RR_Assignment_Mapping__c currAssignment = ruleUserMaps.get(ruleId).get(userId);	
        RR_Assignment_Mapping__c currAssignment = ruleUserMaps.get(ruleId).get(currentMappingId);
        // currRuleMapping = currAssignment.Id;
        // get user mapping list from rule user mapping
        Map<Id, RR_Assignment_Mapping__c> localUserMap = ruleUserMaps.get(ruleId);
        Id nextUserId = null;
        String nextQueueName = null;
        Id firstUser = null;
        Integer recordCounter = 0;
        Integer userCount = localUserMap.size();
        Id nextAssignmentMapping = null;
        Double currentLowerTotal = (currAssignment == null || currAssignment.Value_Total__c == null) ? 0 : currAssignment.Value_Total__c;
        currentLowerTotal = currentLowerTotal + arrValue;
        Id firstUserId = null;
        String firstQueueName = null;
        Id firstAssignmentMapping = null;
        Double firstUserTotal = 0;
        //system.debug('RODRIGO arrValue ' + arrValue);
        
        // loop thru all current rule assignment
        FOR(RR_Assignment_Mapping__c localUserInfo : localUserMap.values()) {
            recordCounter++;
            /*system.debug('RODRIGO ================================================ ' + recordCounter);
            system.debug('RODRIGO localUserInfo ' + currAssignment.User__c);
            system.debug('RODRIGO localUserInfo ' + localUserInfo.User__c);
            system.debug('RODRIGO localUserInfo ' + currAssignment.Queue_Name__c);
            system.debug('RODRIGO localUserInfo ' + localUserInfo.Queue_Name__c);*/
            if ((currAssignment.User__c != localUserInfo.User__c) || 
                (currAssignment.Queue_Name__c != localUserInfo.Queue_Name__c)
               ) {
                   //system.debug('RODRIGO inside queue ' +  localUserInfo.User__c);
                   //system.debug('RODRIGO inside queue ' +  localUserInfo.Queue_Name__c);
                // store first user assignment info with sequence order as 1, to be used later in the logic
                if (localUserInfo.Order__c == 1) {
                    firstUserId = localUserInfo.User__c;
                    firstQueueName = localUserInfo.Queue_Name__c;
                    firstAssignmentMapping = localUserInfo.Id;
                    firstUserTotal = localUserInfo.Value_Total__c;
                }
                
                // check if current assignment current user total value = 0, check against other assignment if also having 0 total value to assign the next user assigment
                if (currAssignment.Value_Total__c == 0 && currAssignment.Value_Total__c == localUserInfo.Value_Total__c) {  
                    nextUserId = localUserInfo.User__c;
                    nextQueueName = localUserInfo.Queue_Name__c;
                    nextAssignmentMapping = localUserInfo.Id;
                    break;
                }
                else if (currAssignment.Value_Total__c == 0) { // additional logic when assignment is the last user in the order of assignment with total value is 0
                    
                    if (firstUserId != localUserInfo.User__c) { // perform logic when user assignment is not the first record
                        if (firstUserTotal > localUserInfo.Value_Total__c && nextUserId==null) { // compare first user total value against other user value
                   			currentLowerTotal = localUserInfo.Value_Total__c;
                            nextUserId = localUserInfo.User__c;
                            nextQueueName = localUserInfo.Queue_Name__c;
                            nextAssignmentMapping = localUserInfo.Id;
                        }
                        else {
                            if (currentLowerTotal > localUserInfo.Value_Total__c) {
                                currentLowerTotal = localUserInfo.Value_Total__c;
                                nextUserId = localUserInfo.User__c;
                                nextQueueName = localUserInfo.Queue_Name__c;
                                nextAssignmentMapping = localUserInfo.Id;
                            }
                        }
                    }
                    // check if the user assigment is one record before the last record
                    if (recordCounter == (userCount-1)) {
                        if (nextUserId==null && nextQueueName==null) {// assign first user value
                            currentLowerTotal = firstUserTotal;
                            nextUserId = firstUserId;
                            nextQueueName = firstQueueName;
                            nextAssignmentMapping = firstAssignmentMapping;
						}
                        Double localTotalValue = (currAssignment.Value_Total__c == null) ? 0 : currAssignment.Value_Total__c;  
                        Double localcurrTotal = localTotalValue+arrValue;
                        if (localcurrTotal<currentLowerTotal) {
                            nextUserId = null; // reset the value
                            nextQueueName = null;
                        }
                    }
                }
				else
                {
                    //system.debug('RODRIGO currentLowerTotal ' + currentLowerTotal);
                    //system.debug('RODRIGO localUserInfo.Value_Total__c ' + localUserInfo.Value_Total__c);
                    //system.debug('RODRIGO localUserInfo.Value_Total__c ' + localUserInfo.Max_Value__c);
                    if (currentLowerTotal > localUserInfo.Value_Total__c && localUserInfo.Value_Total__c < localUserInfo.Max_Value__c) {
                        currentLowerTotal = localUserInfo.Value_Total__c;
                        nextUserId = localUserInfo.User__c;
                        nextQueueName = localUserInfo.Queue_Name__c;
                        nextAssignmentMapping = localUserInfo.Id;
                    }
                    else {
                        if (currentLowerTotal == localUserInfo.Value_Total__c && localUserInfo.Value_Total__c < localUserInfo.Max_Value__c) {
                            if (nextUserId == null) {
                                // check for max value
                                //if (currAssignment.Max_Value__c >= localUserInfo.Max_Value__c ) {
                                    nextAssignmentMapping = localUserInfo.Id;
                                    nextUserId = localUserInfo.User__c;
                                nextQueueName = localUserInfo.Queue_Name__c;
                                //}
                                //else {
                                //    nextAssignmentMapping = currAssignment.Id;
                                //    nextUserId = currAssignment.User__c;
                                //}
                                    
                            }
                                
                        }
                        /*else {
                            currentLowerTotal = localUserInfo.Value_Total__c;
                            nextUserId = localUserInfo.User__c;
                        }*/
                        
                    }
                        
                }    
                    
            }
            if (recordCounter == userCount && nextUserId==null && nextQueueName==null && currAssignment.Value_Total__c < currAssignment.Max_Value__c) {
                nextUserId = currAssignment.User__c;
                nextAssignmentMapping = currAssignment.Id;
                nextQueueName = currAssignment.Queue_Name__c;
            }
        }
        // set current total value for the user
        Double currentTotalValue = (currAssignment.Value_Total__c == null) ? 0 : currAssignment.Value_Total__c;
        currentTotalValue = currentTotalValue + arrValue;
        currAssignment.Value_Total__c = currentTotalValue;
        //system.debug('RODRIGO currAssignment.Value_Total__c ' + currAssignment.Value_Total__c);
        ruleUserMaps.get(ruleId).put(userId, currAssignment);
        // check if there is next user id to be able to set the Next Assignment value of the rule
        if (nextUserId != null || nextQueueName != null) {
            //system.debug('RODRIGO next user to be saved ' + nextUserId);
            RR_Assignment_Rule__c localRule = mapRule.get(ruleId);
            system.debug('RODRIGO nextUserId ' + nextUserId);
            system.debug('RODRIGO nextAssignmentMapping ' + nextAssignmentMapping);
            localRule.Next_Assignment__c = nextUserId;
            localRule.Queue_Name__c = nextQueueName;
            localRule.Next_Assignment_Mapping__c  = nextAssignmentMapping;
            mapRule.put(ruleId, localRule);
            
            //system.debug('RODRIGO currAssignment.Id ' + currAssignment.Id);
            //system.debug('RODRIGO currAssignment.Id ' + userId);
            userUpd.put(currAssignment.Id, userId);
            ruleUsersForUpdate.put(ruleId, userUpd);
            
        }
        
    }
    
    /**********************************************************************
    Name: assignNextAssignmentUserUsingOrder
    =======================================================================
    Purpose: handles the logic to determine the Next Assignment User using Order                                                      
    =======================================================================
    History  
    
    VERSION     AUTHOR               DATE               DETAIL                       
    1.0        Rodrigo Carpio        2022-Nov-30        INITIAL DEVELOPMENT
    
    ***********************************************************************/
    @testvisible public void assignNextAssignmentUserUsingOrder(Id ruleId, Id userId, String userGroup, Boolean sledFlag, Id mappingId) {
        /*system.debug('RODRIGO assignNextAssignmentUserUsingOrder ruleId ' + ruleId);
        system.debug('RODRIGO assignNextAssignmentUserUsingOrder mappingId ' + mappingId);
        system.debug('RODRIGO assignNextAssignmentUserUsingOrder ruleUserMaps.get(ruleId) ' + ruleUserMaps.get(ruleId));
        system.debug('RODRIGO assignNextAssignmentUserUsingOrder ruleUserMaps.get(ruleId) ' + ruleUserMaps.get(ruleId).get(mappingId));
        system.debug('RODRIGO assignNextAssignmentUserUsingOrder mapMappingPause ' + mapMappingPause.get(mappingId));
        Map<Id, RR_Assignment_Mapping__c> localUserMapData = new Map<Id, RR_Assignment_Mapping__c>();
        localUserMapData.put(mappingId, ruleUserMaps.get(ruleId).get(mappingId));*/
            
        RR_Assignment_Mapping__c currAssignment = new RR_Assignment_Mapping__c();
        if (mapMappingPause.get(mappingId) != null) { // added for GTMS-14481
            currAssignment = mapMappingPause.get(mappingId);
            //system.debug('RODRIGO mapMappingPause ' + currAssignment);
        }
        else {
            if (ruleUserMaps.get(ruleId)== null || (ruleUserMaps.get(ruleId) != null && ruleUserMaps.get(ruleId).get(mappingId)==null))
            	return;
        	currAssignment = ruleUserMaps.get(ruleId).get(mappingId);
            //system.debug('RODRIGO currAssignment ' + currAssignment);
        }
        
        //system.debug('RODRIGO assignNextAssignmentUserUsingOrder currAssignment ' + currAssignment);
        // performNextAssignment(currAssignment,ruleId);
        // currRuleMapping = currAssignment.Id;
        // get user mapping list from rule user mapping
        Map<Id, RR_Assignment_Mapping__c> localUserMap = ruleUserMaps.get(ruleId);
        if(localUserMap == null)
            return;
        Id nextUserId = null;
        String nextQueueName = null;
        Id firstUser = null;
        Id firstQueueName = null;
        Integer recordCounter = 0;
        Integer userCount = localUserMap.size();
        Id nextAssignmentMapping = null;
        Id firstMapping = null;
        //system.debug('RODRIGO currAssignment ' + currAssignment);
        FOR(RR_Assignment_Mapping__c localUserInfo : localUserMap.values()) {
            recordCounter++;
            //system.debug('RODRIGO localUserInfo ' + localUserInfo);
            if (recordCounter == 1) {
                firstUser = localUserInfo.User__c;
                firstMapping = localUserInfo.Id;
                firstQueueName = localUserInfo.Queue_Name__c;
            }
            //system.debug('RODRIGO ' + localUserInfo.Order__c);
            //system.debug('RODRIGO ' + currAssignment);
            if (localUserInfo.Order__c > currAssignment.Order__c) {
                nextAssignmentMapping = localUserInfo.Id;
                nextUserId = localUserInfo.User__c;
                nextQueueName = localUserInfo.Queue_Name__c;
                break;
            }
            
            if (recordCounter == userCount && (nextUserId==null && nextQueueName==null))  {
                nextAssignmentMapping = firstMapping;
                nextUserId = firstUser;
                nextQueueName = firstQueueName;
            }
                
        }
        //system.debug('RODRIGO nextUserId ' + nextUserId);
        // check if there is next user id to be able to set the Next Assignment value of the rule
        if (nextUserId != null || nextQueueName!=null) {
            RR_Assignment_Rule__c localRule = mapRule.get(ruleId);
            localRule.Queue_Name__c = nextQueueName;
            localRule.Next_Assignment__c = nextUserId;
            localRule.Next_Assignment_Mapping__c  = nextAssignmentMapping;
            mapRuleToBeUpdated.put(ruleId, localRule);
            system.debug('RODRIGO assignNextAssignmentUserUsingOrder before exit ' + localRule);
            mapRule.put(ruleId, localRule);
        }
        
    }
    
    /**********************************************************************
    Name: assignNextAssignmentUser
    =======================================================================
    Purpose: handles the logic to determine the Next Assignment User                                                      
    =======================================================================
    History  
    
    VERSION     AUTHOR               DATE               DETAIL                       
    1.0        Rodrigo Carpio        2022-Nov-30        INITIAL DEVELOPMENT
    
    ***********************************************************************/
    /*private void assignNextAssignmentUser(Id ruleId, Id userId, String userGroup, Boolean sledFlag) {
        system.debug('RODRIGO assignNextAssignmentUser');
        RR_Assignment_Mapping__c currAssignment = ruleUserMaps.get(ruleId).get(userId);
        system.debug('RODRIGO assignNextAssignmentUser - currAssignment ' + currAssignment);
        // get user mapping list from rule user mapping
        Map<Id, RR_Assignment_Mapping__c> localUserMap = ruleUserMaps.get(ruleId);
        Id nextUserId = null;
        Id firstUser = null;
        Integer recordCounter = 0;
        Integer userCount = localUserMap.size();
        FOR(RR_Assignment_Mapping__c localUserInfo : localUserMap.values()) {
            recordCounter++;
            if (recordCounter == 1)
                firstUser = localUserInfo.User__c;
            
            if (localUserInfo.Order__c > currAssignment.Order__c) {
                system.debug('RODRIGO assignNextAssignmentUser - localUserInfo ' + localUserInfo);
                nextUserId = localUserInfo.User__c;
                break;
            }
            
            if (recordCounter == userCount && nextUserId==null)
                nextUserId = firstUser;
        }
        
        // check if there is next user id to be able to set the Next Assignment value of the rule
        if (nextUserId != null) {
            RR_Assignment_Rule__c localRule = mapRule.get(ruleId);
            localRule.Next_Assignment__c = nextUserId;
            mapRule.put(ruleId, localRule);
        }
        
    }*/
    
    /*private Id getAssignmentUser(String userGroup, Boolean sled) {
        Id userId;
        FOR (RR_Assignment_Mapping__c ruleMap : mapMapping.values()) {
            if(ruleMap.User_Group__c == userGroup && ruleMap.Is_SLED__c == sled)
                userId = ruleMap.User__c;
        }
        return userId;
    }*/
    
    /**********************************************************************
    Name: updateRuleDetail
    =======================================================================
    Purpose: handles the update of Rule fields                                                   
    =======================================================================
    History  
    
    VERSION     AUTHOR               DATE               DETAIL                       
    1.0        Rodrigo Carpio        2022-Nov-30        INITIAL DEVELOPMENT
    
    ***********************************************************************/ 
    public void updateRuleDetail(){
        if(ruleIdToBeUpdated.size()>0) {
            List<RR_Assignment_Rule__c> listOfRule = new List<RR_Assignment_Rule__c>();
            List<RR_Assignment_Mapping__c> listOfAssigment = new List<RR_Assignment_Mapping__c>();
            FOR (Id objId : ruleIdToBeUpdated) {
                
                /*RR_Assignment_Rule__c rule = new RR_Assignment_Rule__c();
                rule.Id = objId;
                rule.Last_Run_Date__c = system.now();
                listOfRule.add(rule);*/
                RR_Assignment_Rule__c rule = new RR_Assignment_Rule__c();
                rule = mapRule.get(objId);
                rule.Last_Run_Date__c = system.now();
                listOfRule.add(rule);
                if (ruleUsersForUpdate.containsKey(objId)) {
                    
                    Map<Id, Id> localKeyValues = ruleUsersForUpdate.get(objId);
                    FOR (Id currKey : localKeyValues.keySet()) {
                        system.debug('RODRIGO currKey ' + currKey);
                        RR_Assignment_Mapping__c currAssignment = ruleUserMaps.get(objId).get(localKeyValues.get(currKey));
                        if (currAssignment != null && currAssignment.Id == currKey)
                            listOfAssigment.add(currAssignment);
                        	
                    }
                    
                }
            }
         
            if (listOfAssigment.size()>0)
                database.update(listOfAssigment, false);
            if (listOfRule.size()>0)
                database.update(listOfRule, false);
            if (forInsertRRLog.size()>0)
                database.insert(forInsertRRLog, false);
        }
    }
    
    /**********************************************************************
    Name: updateLastRun
    =======================================================================
    Purpose: This methods handles the setting of Last Run Date field                                                       
    =======================================================================
    History  
    
    VERSION     AUTHOR               DATE               DETAIL                       
    1.0        Rodrigo Carpio        2022-Nov-30        INITIAL DEVELOPMENT
    
    ***********************************************************************/ 
    /*public void updateLastRun(Set<Id> ruleIdToBeUpdated){
        if(ruleIdToBeUpdated.size()>0) {
            List<RR_Assignment_Rule__c> listOfRule = new List<RR_Assignment_Rule__c>();
            FOR (Id objId:ruleIdToBeUpdated) {
                RR_Assignment_Rule__c rule = new RR_Assignment_Rule__c();
                rule = mapRule.get(objId);
                rule.Last_Run_Date__c = system.now();
                listOfRule.add(rule);
            }
            if (listOfRule.size()>0)
                database.update(listOfRule, false);
        }
    }*/
    
    /**********************************************************************
    Name: updateQueueUserAssignment
    =======================================================================
    Purpose: handles the logic to update the Renewal_AE__c                                                       
    =======================================================================
    History  
    
    VERSION     AUTHOR               DATE               DETAIL                       
    1.0        Rodrigo Carpio        2023-Apr-11        INITIAL DEVELOPMENT
    
    ***********************************************************************/
    public static void updateQueueUserAssignment (String inQueueName, String inUserId) {
        List<Account> accountList = [SELECT Id, Renewal_AE__c, Renewal_AE_Queue__c
                                                            FROM Account 
                                                            WHERE Renewal_AE_Queue__c=:inQueueName];
        List<Account> accountForUpd = new List<Account>();
        FOR (Account rec : accountList) {
            //Account rec = new Account();
            rec.Renewal_AE__c = inUserId;
            rec.Renewal_AE_Queue__c = inUserId;
            accountForUpd.add(rec);
        }
        
        if (accountForUpd != null && accountForUpd.size()>0) {
            update accountForUpd;
        }
    }
    
    public class RoundRobinFlowInput {
        @InvocableVariable public String accountId;
        @InvocableVariable public Account objAccount;
    }
    
    public class RoundRobinFlowResponse {
        @InvocableVariable public boolean useCustomRouting;
       
    }
    /**********************************************************************
    Name: createOpportunityIM
    =======================================================================
    Purpose: handles the logic to create opportunity                                                    
    =======================================================================
    History  
    
    VERSION     AUTHOR               DATE               DETAIL                       
    1.0        Rodrigo Carpio        2023-Mar-06        INITIAL DEVELOPMENT
    
    ***********************************************************************/
    @InvocableMethod(label='Check If Custom Routing Is To Be Used') 
    public static List<RoundRobinFlowResponse> checkIfCustomRoutingIsToBeUsed(List<RoundRobinFlowInput> infoFTDetails) {
        List<RoundRobinFlowResponse> flowRespList = new List<RoundRobinFlowResponse>();
        RoundRobinFlowResponse flowResp = new RoundRobinFlowResponse();
        //flowResp.useCustomRouting = checkIfCustomRoutingIsToBeUsed(infoFTDetails[0].accountId);
        flowRespList.add(flowResp);
        return flowRespList;
    }
    
    /**********************************************************************
    Name: updatePauseAssigmentFlag
    =======================================================================
    Purpose: handles the logic to update the Pause Assignment flag for specific user                                                       
    =======================================================================
    History  
    
    VERSION     AUTHOR               DATE               DETAIL                       
    1.0        Rodrigo Carpio        2023-Jul-26        INITIAL DEVELOPMENT
    
    ***********************************************************************/
    /*public void updatePauseAssigmentFlag (String inUserId, boolean toggleFlagValue) {
        Boolean queryFlag = !toggleFlagValue;
        List<RR_Assignment_Mapping__c> assignMapList = [SELECT Id, Pause_Assignment__c, User__c, Assignment_Rule__c, 
                                     Assignment_Rule__r.Next_Assignment__c, Assignment_Rule__r.Always_Use_Next_Assignment__c  
                                                            FROM RR_Assignment_Mapping__c 
                                                            WHERE Active__c = true AND Pause_Assignment__c =: queryFlag AND User__c=:inUserId];
        
        List<RR_Assignment_Mapping__c> assignMapForUpd = new List<RR_Assignment_Mapping__c>();
        List<RR_Assignment_Rule__c > assignRuleForUpd = new List<RR_Assignment_Rule__c >();
        Map<Id, RR_Assignment_Mapping__c> assignUserRuleMap = new Map<Id, RR_Assignment_Mapping__c>();
        Map<Id, Id> assignUserRuleAlwaysAssignMap = new Map<Id, Id>();
        system.debug('RODRIGO assignMapList ' + assignMapList.size());
        
        FOR (RR_Assignment_Mapping__c rec : assignMapList)
        {
            //rec.Pause_Assignment__c = toggleFlagValue;
            //assignMapForUpd.add(rec);
            if(inUserId == rec.Assignment_Rule__r.Next_Assignment__c ) {
                if(!rec.Assignment_Rule__r.Always_Use_Next_Assignment__c)
                	assignUserRuleMap.put(rec.Assignment_Rule__c, rec);
                // set map of the user that is set as next assign and always assign is to true
                //if (rec.Assignment_Rule__r.Always_Use_Next_Assignment__c && toggleFlagValue) 
                //    assignUserRuleAlwaysAssignMap.put(rec.Assignment_Rule__c, rec.User__c);
            }
        }
        
        system.debug('RODRIGO assignMapForUpd ' + assignMapForUpd.size());
        system.debug('RODRIGO assignUserRuleMap ' + assignUserRuleMap.size());
        system.debug('RODRIGO assignUserRuleAlwaysAssignMap ' + assignUserRuleAlwaysAssignMap.size());
        FOR(Id ruleId : assignUserRuleAlwaysAssignMap.keySet()) {
            RR_Assignment_Rule__c locRule = new RR_Assignment_Rule__c();
            locRule.Id = ruleId;
            locRule.Active__c = !toggleFlagValue;
            assignRuleForUpd.add(locRule);
        }
        
        FOR(Id ruleId : assignUserRuleMap.keySet()) {
            RR_Assignment_Mapping__c locAssignMap = assignUserRuleMap.get(ruleId);
            system.debug('RODRIGO ruleId ' + ruleId);
        	assignNextAssignmentUserUsingOrder(ruleId, locAssignMap.User__c, null, false, locAssignMap.Id);
        }
        
        // perform update on the assignment where the next assignment will be updated, mapRule value is being set to updated in assignNextAssignmentUserUsingOrder
        update mapRule.values();
        
        // perform update on the assignment rule if there is record to be updated for rule having always assigned flag is set to true
        //if (assignRuleForUpd != null && assignRuleForUpd.size()>0) {
        //    update assignRuleForUpd;
        //}
       
        // perform update on the assigment mapping if there is record to be updated
        //if (assignMapForUpd != null && assignMapForUpd.size()>0) {
        //    update assignMapForUpd;
        //}
    
}    */
    
    /*public class RRAssignmentToggleInput {
        @InvocableVariable public String userId;
        @InvocableVariable public Boolean routingToggle;
    }
    */
    /**********************************************************************
    Name: assignmentRoutingToggle
    =======================================================================
    Purpose: handles the logic to call the method that will be update the assignment routing toggle                                                   
    =======================================================================
    History  
    
    VERSION     AUTHOR               DATE               DETAIL                       
    1.0        Rodrigo Carpio        2023-Mar-06        INITIAL DEVELOPMENT
    
    ***********************************************************************/
    /*@InvocableMethod(label='Update RR Assignment Toggle') 
    public static void assignmentRoutingToggle(List<RRAssignmentToggleInput> infoDetails) {
        assignmentRoutingToggleFuture(infoDetails[0].userId, infoDetails[0].routingToggle);
    }
    @future
    public static void assignmentRoutingToggleFuture(String inUserId, boolean toggleFlagValue) {
        RoundRobinHandler rr = new RoundRobinHandler('Lane Four','Account');
        rr.updatePauseAssigmentFlag(inUserId, toggleFlagValue);
    }
    */
    //@future
    public static void updateRuleNextAssignmentFuture(Set<Id> inUserId, boolean toggleFlagValue) {
        RoundRobinHandler rr = new RoundRobinHandler('Lane Four','Account');
        rr.updateRuleNextAssignment(inUserId, toggleFlagValue);
    }
    /*public class RoundRobinFlowResponse {
        @InvocableVariable public boolean useCustomRouting;
       
    }*/
	/**********************************************************************
    Name: updateRuleNextAssignment
    =======================================================================
    Purpose: handles the logic to update the Rule Next Assignment                                                        
    =======================================================================
    History  
    
    VERSION     AUTHOR               DATE               DETAIL                       
    1.0        Rodrigo Carpio        2023-Aug-02        INITIAL DEVELOPMENT
    
    ***********************************************************************/
    public void updateRuleNextAssignment (Set<Id> inUserId, boolean toggleFlagValue) {
        Boolean queryFlag = toggleFlagValue;
        Map<Id, RR_Assignment_Rule__c> forUpdate = new Map<Id, RR_Assignment_Rule__c>();
        List<RR_Assignment_Mapping__c> assignMapList = [SELECT Id, Pause_Assignment__c, User__c, Assignment_Rule__c, Assignment_Rule__r.Next_Assignment_Mapping__c,
                                     Assignment_Rule__r.Next_Assignment__c, Assignment_Rule__r.Always_Use_Next_Assignment__c, Order__c   
                                                            FROM RR_Assignment_Mapping__c 
                                                            WHERE Assignment_Rule__r.Category__c='Lane Four' 
                                                        AND Active__c = true AND User__r.IsActive = true AND Pause_Assignment__c =: queryFlag AND User__c IN:inUserId order by Order__c asc];
        // check for pause assignment value, if false
        if (!toggleFlagValue) {
            FOR(RR_Assignment_Mapping__c rraObj : assignMapList) {
                if(rraObj.Assignment_Rule__r.Next_Assignment_Mapping__c == null) { // check if mapping rule next assignment is null
                    RR_Assignment_Rule__c rraLoc = new RR_Assignment_Rule__c();
                    rraLoc.Next_Assignment__c = rraObj.User__c;
                    rraLoc.Next_Assignment_Mapping__c = rraObj.Id;
                    rraLoc.Id = rraObj.Assignment_Rule__c;
                    forUpdate.put(rraLoc.Id, rraLoc);
                }
            }
            update forUpdate.values();
        }
        else // logic that handles pause assignment true
        {
            //system.debug('RODRIGO updateRuleNextAssignment ');
        List<RR_Assignment_Mapping__c> assignMapForUpd = new List<RR_Assignment_Mapping__c>();
        List<RR_Assignment_Rule__c > assignRuleForUpd = new List<RR_Assignment_Rule__c >();
        Map<Id, RR_Assignment_Mapping__c> assignUserRuleMap = new Map<Id, RR_Assignment_Mapping__c>();
        Map<Id, Id> assignUserRuleAlwaysAssignMap = new Map<Id, Id>();
        //system.debug('RODRIGO assignMapList ' + assignMapList.size());
        
        // get assignment mapping base on the list of rules -- replaced the //Pause_Assignment__c != true  with EnableADRLeads and added user query.
        mapMapping = new Map<Id, RR_Assignment_Mapping__c>([SELECT Id, Order__c, User__c, Assignment_Rule__c, User_Group__c, Is_SLED__c,Type__c,
                                                             Max_Value__c, Value_Total__c, Field_To_Assign__c, Queue_Name__c     
                                                            FROM RR_Assignment_Mapping__c 
                                                            WHERE Active__c=true  AND User__r.IsActive = true AND Pause_Assignment__c=false
                                                            AND Assignment_Rule__c IN: mapRule.keySet() order by Order__c asc]);

        
    	
        system.debug('RODRIGO mapMapping ' + mapRule.size());
        // collect the user and put them into rule map
        FOR(Id ruleId : mapRule.keySet()) {
            //system.debug('RODRIGO ruleId ' + ruleId);
            Map<Id, RR_Assignment_Mapping__c > userMapping = new Map<Id, RR_Assignment_Mapping__c >();
            FOR (RR_Assignment_Mapping__c userMap : mapMapping.values()) {
                if (userMap.Assignment_Rule__c == ruleId) {
                    userMapping.put(userMap.Id, userMap);
                }
                    
            }
            //system.debug('RODRIGO ruleId ' + userMapping.size());
            if (userMapping.size()>0) {
                //system.debug(ruleId + ' RODRIGO ruleId ruleUserMaps ' + userMapping);
                ruleUserMaps.put(ruleId, userMapping);
            }
        }
        
        // get rules assigned mapping count
        Map<Id, RR_Assignment_Rule__c> rules = new Map<Id, RR_Assignment_Rule__c>([SELECT Id, Name, (SELECT id FROM RR_Assignment_Mappings__r  WHERE Pause_Assignment__c=false ) 
                                             FROM RR_Assignment_Rule__c 
                                             WHERE Category__c='Lane Four' AND Always_Use_Next_Assignment__c=false]);
        Set<Id> ruleWithNoAssignment = new Set<Id>();
        List<RR_Assignment_Rule__c> ruleToClearNextAssignment = new List<RR_Assignment_Rule__c>();
        for (RR_Assignment_Rule__c rule : rules.Values()) {
            
            if (rule.RR_Assignment_Mappings__r.size()==0) {
                ruleWithNoAssignment.add(rule.Id);
                rule.Next_Assignment__c = null;
                rule.Next_Assignment_Mapping__c = null;
                ruleToClearNextAssignment.add(rule);
            }
                
            //system.debug('RODRIGO size ' + rule.RR_Assignment_Mappings__r.size());
        }
        
        FOR (RR_Assignment_Mapping__c rec : assignMapList)
        {
            //rec.Pause_Assignment__c = toggleFlagValue;
            //assignMapForUpd.add(rec);
            //system.debug('RODRIGO rec ' + rec.Assignment_Rule__r.Next_Assignment__c);
            if(rec.Assignment_Rule__r.Next_Assignment__c != null && inUserId.contains(rec.Assignment_Rule__r.Next_Assignment__c)) {
                if(!rec.Assignment_Rule__r.Always_Use_Next_Assignment__c)
                	assignUserRuleMap.put(rec.Assignment_Rule__c, rec);
                
            }
        }
        
        
        FOR(Id ruleId : assignUserRuleMap.keySet()) {
            RR_Assignment_Mapping__c locAssignMap = assignUserRuleMap.get(ruleId);
            if (!ruleWithNoAssignment.contains(ruleId))
            	assignNextAssignmentUserUsingOrder(ruleId, locAssignMap.User__c, null, false, locAssignMap.Id);
            	//performNextAssignment(locAssignMap, ruleId);
        }
        
        // perform update on the assignment where the next assignment will be updated, mapRule value is being set to updated in assignNextAssignmentUserUsingOrder
        update mapRule.values();
        
        if (ruleToClearNextAssignment.size()>0)
            update ruleToClearNextAssignment;
        // get rules assigned mapping count
        /*List<RR_Assignment_Rule__c> rules = [SELECT Name, (SELECT id FROM RR_Assignment_Mappings__r  WHERE Pause_Assignment__c=false ) 
                                             FROM RR_Assignment_Rule__c 
                                             WHERE Category__c='Lane Four' AND Always_Use_Next_Assignment__c=false];
        for (RR_Assignment_Rule__c rule : rules) {
            
            if (rule.RR_Assignment_Mappings__r.size()==0)
            	system.debug('RODRIGO size ' + rule.RR_Assignment_Mappings__r.size());
        }*/
        }
    }    
}