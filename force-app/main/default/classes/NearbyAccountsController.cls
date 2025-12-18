/**
* @File Name : NearbyAccountsController.cls
* @Description : This class used for showing the nearby accounts to user 
* @Author : Vigneshwaran Durairaj
* @Last Modified By : June 3 2025
* @Last Modified On : May 20, 2025
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | June 3, 2025 |   | Initial Version
**/


public with sharing class NearbyAccountsController {
    
    // Static variables for roles/profiles that should use existing USER_MODE (excluded from custom logic)
    private static Set<String> EXCLUDED_ROLES_OR_PROFILES = new Set<String>{'Sales Ops', 'SVP','System Administrator'};        
	
    // Static map to cache role hierarchy - built once and reused
    private static Map<Id, Set<Id>> roleHierarchyMap;
    
    @AuraEnabled(cacheable=true)
    public static List<Account> getNearbyAccounts(Map<String, Object> params) {
        
        Double userLat;
        if (params.containsKey('userLat') && params.get('userLat') != null) {
            Object val = params.get('userLat');
            if (val instanceof Double) {
                userLat = (Double)val;
            } else if (val instanceof Decimal) {
                userLat = ((Decimal)val).doubleValue();
            } else if (val instanceof String) {
                userLat = Double.valueOf((String)val);
            }
        }
        Double userLon;
        if (params.containsKey('userLon') && params.get('userLon') != null) {
            Object val = params.get('userLon');
            if (val instanceof Double) {
                userLon = (Double)val;
            } else if (val instanceof Decimal) {
                userLon = ((Decimal)val).doubleValue();
            } else if (val instanceof String) {
                userLon = Double.valueOf((String)val);
            }
        }
        Decimal radiusMiles;
        if (params.containsKey('radiusMiles') && params.get('radiusMiles') != null) {
            Object val = params.get('radiusMiles');
            if (val instanceof Decimal) {
                radiusMiles = (Decimal)val;
            } else if (val instanceof Double) {
                radiusMiles = Decimal.valueOf(String.valueOf(val));
            } else if (val instanceof String) {
                radiusMiles = Decimal.valueOf((String)val);
            }
        }
        String city = params.get('city') != null ? String.valueOf(params.get('city')) : null;
        String state = params.get('state') != null ? String.valueOf(params.get('state')) : null;
        String segment = params.get('segment') != null ? String.valueOf(params.get('segment')) : null;
        String industry = params.get('industry') != null ? String.valueOf(params.get('industry')) : null;
        String csSentiment = params.get('csSentiment') != null ? String.valueOf(params.get('csSentiment')) : null;
        
        // Safe type conversion for account type filters
        List<String> accountTypeFilters = new List<String>();
        if (params.get('accountTypeFilter') != null) {
            try {
                Object accountTypeFilterObj = params.get('accountTypeFilter');
                System.debug('accountTypeFilter type: ' + accountTypeFilterObj);
                System.debug('accountTypeFilter value: ' + accountTypeFilterObj);
                
                if (accountTypeFilterObj instanceof List<String>) {
                    accountTypeFilters = (List<String>)accountTypeFilterObj;
                } else if (accountTypeFilterObj instanceof List<Object>) {
                    List<Object> objList = (List<Object>)accountTypeFilterObj;
                    for (Object obj : objList) {
                        accountTypeFilters.add(String.valueOf(obj));
                    }
                } else {
                    accountTypeFilters.add(String.valueOf(accountTypeFilterObj));
                }
            } catch (Exception e) {
                System.debug('Error converting accountTypeFilter: ' + e.getMessage());
                accountTypeFilters = new List<String>();
            }
        }
        
        // Safe type conversion for owner filters
        List<String> ownerFilters = new List<String>();
        if (params.get('ownerFilter') != null) {
            try {
                Object ownerFilterObj = params.get('ownerFilter');
                System.debug('ownerFilter type: ' + ownerFilterObj);
                System.debug('ownerFilter value: ' + ownerFilterObj);
                
                if (ownerFilterObj instanceof List<String>) {
                    ownerFilters = (List<String>)ownerFilterObj;
                } else if (ownerFilterObj instanceof List<Object>) {
                    List<Object> objList = (List<Object>)ownerFilterObj;
                    for (Object obj : objList) {
                        ownerFilters.add(String.valueOf(obj));
                    }
                } else {
                    ownerFilters.add(String.valueOf(ownerFilterObj));
                }
            } catch (Exception e) {
                System.debug('Error converting ownerFilter: ' + e.getMessage());
                ownerFilters = new List<String>();
            }
        }

        List<String> excludeUsers = new List<String>{'%Pool%','%Reservoir%','%Samsara Small Fleets%','%Rain Maker%'};

        String baseQuery = 'SELECT Id, Name, BillingStreet, BillingCity, BillingState, BillingPostalCode, BillingCountry, ' +
            'BillingLatitude, BillingLongitude, AnnualRevenue, Total_Parent_Account_Customer_ARR__c, ' +
            'Segment__c, Industry, CSM_Health_Rating__c, Total_Pipeline__c, ' +
            'OwnerId, Owner.Name, Owner.Manager.Name, CreatedBy.Name, ' +
            'DISTANCE(BillingAddress, GEOLOCATION(:userLat, :userLon), \'mi\') distance ' +
            'FROM Account WHERE BillingLatitude != null AND BillingLongitude != null ' +
            'AND DISTANCE(BillingAddress, GEOLOCATION(:userLat, :userLon), \'mi\') < :radiusMiles ' +
            'AND (NOT Owner.Name LIKE :excludeUsers) ' +
            'AND (NOT Segment__c LIKE \'%Management%\') ';
        if (!String.isBlank(city)) {
            baseQuery += 'AND BillingCity = :city ';
        }
        if (!String.isBlank(state)) {
            baseQuery += 'AND BillingState = :state ';
        }

        if(segment == 'null'){
            baseQuery += 'AND (Segment__c = null OR Segment__c = \'\') ';
        }
        else if (!String.isBlank(segment) && segment != 'All') {
            baseQuery += 'AND Segment__c = :segment ';
        }

        if (industry == 'null') {
            baseQuery += 'AND (Industry = null OR Industry = \'\') ';
        } else if (!String.isBlank(industry) && industry != 'All') {
            baseQuery += 'AND Industry = :industry ';
        }

        if (accountTypeFilters != null && !accountTypeFilters.isEmpty()) {
            List<String> conditions = new List<String>();
            
            for (String accountTypeFilter : accountTypeFilters) {
                if (accountTypeFilter == 'customers_with_pipeline') {
                    conditions.add('(Total_Parent_Account_Customer_ARR__c > 0 AND Total_Pipeline__c > 0)');
                } else if (accountTypeFilter == 'all_customers') {
                    conditions.add('(Total_Parent_Account_Customer_ARR__c > 0)');
                } else if (accountTypeFilter == 'prospects_with_pipeline') {
                    conditions.add('((Total_Parent_Account_Customer_ARR__c = 0 OR Total_Parent_Account_Customer_ARR__c = null) AND Total_Pipeline__c > 0)');
                } else if (accountTypeFilter == 'prospects_without_pipeline') {
                    conditions.add('((Total_Parent_Account_Customer_ARR__c = 0 OR Total_Parent_Account_Customer_ARR__c = null) AND (Total_Pipeline__c = 0 OR Total_Pipeline__c = null))');
                } else if (accountTypeFilter == 'customers_without_pipeline') {
                    conditions.add('(Total_Parent_Account_Customer_ARR__c > 0 AND (Total_Pipeline__c = 0 OR Total_Pipeline__c = null))');
                } else if (accountTypeFilter == 'all_with_pipeline') {
                    conditions.add('(Total_Pipeline__c > 0)');
                }
                // Note: 'all_near_me' doesn't add any conditions, so it's not included here
            }
            
            if (!conditions.isEmpty()) {
                baseQuery += 'AND (' + String.join(conditions, ' OR ') + ') ';
            }
        }

        if(csSentiment == 'null'){
            baseQuery += 'AND (CSM_Health_Rating__c = null OR CSM_Health_Rating__c = \'\') ';
        }
        else if (!String.isBlank(csSentiment) && csSentiment != 'All') {
            baseQuery += 'AND CSM_Health_Rating__c = :csSentiment ';
        }

        // Handle owner filter
        if (ownerFilters != null && !ownerFilters.isEmpty()) {
            List<String> ownerConditions = new List<String>();
            
            for (String ownerFilter : ownerFilters) {
                if (ownerFilter == 'null' || ownerFilter == '__NONE__') {
                    ownerConditions.add('(OwnerId = null)');
                } else if (ownerFilter != 'All') {
                    ownerConditions.add('OwnerId = \'' + String.escapeSingleQuotes(ownerFilter) + '\'');
                }
            }
            
            if (!ownerConditions.isEmpty()) {
                baseQuery += 'AND (' + String.join(ownerConditions, ' OR ') + ') ';
            }
        }
        
        Set<Id> ownerIds = new Set<Id>();
        
        if(!shouldUseExistingUserMode()){
           ownerIds =  getAllSubordinateUserIds();
           baseQuery += 'AND (OwnerId IN :ownerIds OR SE_Assignment__c IN :ownerIds) ';
        }
        
        baseQuery += ' limit 50000 ';

        try {
            // Execute query first
            List<Account> results = Database.query(baseQuery,System.AccessLevel.USER_MODE);
            
            // Find existing session log for current user
            List<SamsaraLog__c> sessionLogs = [
                SELECT Id FROM SamsaraLog__c 
                WHERE Context_User__c = :UserInfo.getUserId() 
                AND Functionality_Type__c = 'Nearby Accounts'
                AND Functionality_Sub_Type__c = 'User Session'
                ORDER BY CreatedDate DESC 
                LIMIT 1
            ];
            
            // Note: Removed search completion logging to avoid duplicate entries
            // Only log specific user actions, not every search operation
            
            return results;
        } catch (Exception e) {
            // Log error to existing session log if available
            try {
                List<SamsaraLog__c> sessionLogs = [
                    SELECT Id FROM SamsaraLog__c 
                    WHERE Context_User__c = :UserInfo.getUserId() 
                    AND Functionality_Type__c = 'Nearby Accounts'
                    AND Functionality_Sub_Type__c = 'User Session'
                    ORDER BY CreatedDate DESC 
                    LIMIT 1
                ];
                
                if (!sessionLogs.isEmpty()) {
                    processLogEntryAsync(sessionLogs[0].Id, 'Search Error', 'Search failed: ' + e.getMessage());
                }
            } catch (Exception logError) {
                System.debug('Error logging search failure: ' + logError.getMessage());
            }
            throw e;
        }
    }

    @AuraEnabled(cacheable=true)
    public static String getGooglePlaceSuggestions(String input) {
        // Use custom label for API key
        String apiKey = System.Label.NearbyAccountsGoogleMapApiKey;
        String endpoint = 'https://maps.googleapis.com/maps/api/place/autocomplete/json?input=' + EncodingUtil.urlEncode(input, 'UTF-8') + '&key=' + apiKey;
        HttpRequest req = new HttpRequest();
        req.setEndpoint(endpoint);
        req.setMethod('GET');
        Http http = new Http();
        try {
            HttpResponse res = http.send(req);
            if (res.getStatusCode() == 200) {
                return res.getBody();
            } else {
                return '{"status":"ERROR","message":"HTTP ' + res.getStatusCode() + '"}';
            }
        } catch (Exception e) {
            return '{"status":"ERROR","message":"' + e.getMessage() + '"}';
        }
    }

    @AuraEnabled(cacheable=true)
    public static String getGooglePlaceDetails(String placeId) {
        // Use custom label for API key
        String apiKey = System.Label.NearbyAccountsGoogleMapApiKey;
        String endpoint = 'https://maps.googleapis.com/maps/api/place/details/json?placeid=' + EncodingUtil.urlEncode(placeId, 'UTF-8') + '&key=' + apiKey;
        HttpRequest req = new HttpRequest();
        req.setEndpoint(endpoint);
        req.setMethod('GET');
        Http http = new Http();
        try {
            HttpResponse res = http.send(req);
            if (res.getStatusCode() == 200) {
                return res.getBody();
            } else {
                return '{"status":"ERROR","message":"HTTP ' + res.getStatusCode() + '"}';
            }
        } catch (Exception e) {
            return '{"status":"ERROR","message":"' + e.getMessage() + '"}';
        }
    }
    
    private static Boolean shouldUseExistingUserMode() {
        User currentUser = [SELECT Id, Profile.Name, UserRole.Name FROM User WHERE Id = :UserInfo.getUserId()];
         for(String rolesOrProfiles : EXCLUDED_ROLES_OR_PROFILES){
             if((currentUser.UserRoleId != null && rolesOrProfiles.containsIgnoreCase(currentUser.UserRole.Name)) || (currentUser.ProfileId != null && rolesOrProfiles.containsIgnoreCase(currentUser.Profile.Name))){
                 return true;
             }
             
         }
        return false;
    }
        
    public static Set<Id> getAllSubordinateUserIds() {
        Set<Id> userIds = new Set<Id>();
        
        // Add current user
        userIds.add(UserInfo.getUserId());
        
        // Get all subordinates in role hierarchy
        User currentUser = [SELECT UserRoleId FROM User WHERE Id = :UserInfo.getUserId()];
        
        if (currentUser.UserRoleId != null) {
            // Get all roles below current user in hierarchy
            Set<Id> subordinateRoleIds = getSubordinateRoleIds(currentUser.UserRoleId);
            
            // Get users in those roles
            List<User> subordinateUsers = [SELECT Id FROM User 
                                          WHERE UserRoleId IN :subordinateRoleIds];
            
            for (User u : subordinateUsers) {
                userIds.add(u.Id);
            }
        }
        
        system.debug(userIds.size());
        
        return userIds;
    }
    
    private static Set<Id> getSubordinateRoleIds(Id parentRoleId) {
          // Build role hierarchy map if not already built
        if (roleHierarchyMap == null) {
            buildRoleHierarchyMap();
        }
        
        Set<Id> allSubordinateRoleIds = new Set<Id>();
        getAllSubordinateRoles(parentRoleId, allSubordinateRoleIds);
        
        system.debug(allSubordinateRoleIds);
        return allSubordinateRoleIds;
    }
    
     private static void buildRoleHierarchyMap() {
        roleHierarchyMap = new Map<Id, Set<Id>>();
        
        // Query all roles once
        List<UserRole> allRoles = [SELECT Id, ParentRoleId FROM UserRole];
        
        // Build the map: ParentRoleId -> Set of Child Role IDs
        for (UserRole role : allRoles) {
            if (role.ParentRoleId != null) {
                if (!roleHierarchyMap.containsKey(role.ParentRoleId)) {
                    roleHierarchyMap.put(role.ParentRoleId, new Set<Id>());
                }
                roleHierarchyMap.get(role.ParentRoleId).add(role.Id);
            }
        }
    }
    
    private static void getAllSubordinateRoles(Id parentRoleId, Set<Id> allSubordinates) {
        // Get immediate children
        Set<Id> children = roleHierarchyMap.get(parentRoleId);
        
        if (children != null) {
            for (Id childRoleId : children) {
                allSubordinates.add(childRoleId);
                // Recursively get all descendants
                getAllSubordinateRoles(childRoleId, allSubordinates);
            }
        }
    }
    
    @AuraEnabled
    public static String createUserSession(Map<String, Object> sessionData) {
        try {
            // Create ONE log record for user session
            SamsaraLog__c sessionLog = new SamsaraLog__c(
                Functionality_Type__c = 'Nearby Accounts',
                Functionality_Sub_Type__c = 'User Session',
                Context_User__c = UserInfo.getUserId(),
                User_Transaction__c = 'NA_SESSION_' + System.currentTimeMillis()
            );
            insert sessionLog;
            
            // Batch all log entries
            List<SamsaraLogEntries__c> logEntries = new List<SamsaraLogEntries__c>();
            String deviceType = sessionData.get('deviceType') != null ? String.valueOf(sessionData.get('deviceType')) : 'Unknown';
            
            // Create log entry for session start
            logEntries.add(new SamsaraLogEntries__c(
                SamsaraLog__c = sessionLog.Id,
                Level__c = 'INFO',
                Message__c = 'User session started on ' + (deviceType != null ? deviceType : 'Unknown'),
                Method__c = 'createUserSession',
                SourceMetadataType__c = 'LWC',
                SourceApiName__c = 'nearbyAccounts'
            ));
            
            // Create log entry for device info
            logEntries.add(new SamsaraLogEntries__c(
                SamsaraLog__c = sessionLog.Id,
                Level__c = 'DEBUG',
                Message__c = 'Device info: ' + JSON.serialize(sessionData),
                Method__c = 'createUserSession',
                SourceMetadataType__c = 'LWC',
                SourceApiName__c = 'nearbyAccounts'
            ));
            
            // Single DML operation for all log entries
            insert logEntries;
            
            // Return the session log ID
            return sessionLog.Id;
        } catch (Exception e) {
            System.debug('Error creating user session log: ' + e.getMessage());
            return null;
        }
    }
    
    @AuraEnabled
    public static void addLogEntryToSession(String sessionLogId, String action, Map<String, Object> details) {
        try {
            if (sessionLogId != null) {
                // Call future method for asynchronous processing
                processLogEntryAsync(sessionLogId, action, JSON.serialize(details));
            }
        } catch (Exception e) {
            System.debug('Error queuing log entry: ' + e.getMessage());
        }
    }
    
    // Future method to process log entries asynchronously
    @future
    public static void processLogEntryAsync(String sessionLogId, String action, String detailsJson) {
        try {
            SamsaraLogEntries__c entry = new SamsaraLogEntries__c(
                SamsaraLog__c = sessionLogId,
                Level__c = 'INFO',
                Message__c = action + ': ' + detailsJson,
                Method__c = 'addLogEntryToSession',
                SourceMetadataType__c = 'LWC',
                SourceApiName__c = 'nearbyAccounts'
            );
            insert entry;
        } catch (Exception e) {
            System.debug('Error processing log entry asynchronously: ' + e.getMessage());
        }
    }
}