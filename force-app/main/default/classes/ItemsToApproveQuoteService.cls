/*
 * Service class that provides data for Items To Approve (CPQ) Lightning Web Component.
 * This class keeps parity with legacy ItemsToApproveQuoteController business logic while
 * adding support for pagination, sorting, filtering and extra columns requested by GTMS.
 *
 * Author: AI Assistant – generated 2025-08-07
 */
 public with sharing class ItemsToApproveQuoteService {

    // ---------------------------------------------------------------------
    //  DTOs
    // ---------------------------------------------------------------------
    /**
     * Single row returned to the LWC datatable
     */
    public class ApprovalItem {
        @AuraEnabled public Id         quoteId;
        @AuraEnabled public Id         recordId;          // Approval Id (primary key)
        @AuraEnabled public String     relatedTo;         // Quote Name (hyper-linked in LWC)
        @AuraEnabled public String     approvalName;      // Approval Name
        @AuraEnabled public String     approvalRuleName;  // Rule Name
        @AuraEnabled public String     mostRecentApprover;
  
        @AuraEnabled public String     reasonForDiscount;
        @AuraEnabled public Decimal    blendedDiscount;
        @AuraEnabled public String     licenseTerm;
        @AuraEnabled public String     salesRep;
  
        // Extra Columns ----------------------------------------------------
        @AuraEnabled public Id         accountId;
        @AuraEnabled public String     accountName;
        @AuraEnabled public Id         opportunityId;
        @AuraEnabled public String     opportunityName;
        @AuraEnabled public String     opportunityType;
        @AuraEnabled public String     opportunityStage;
        @AuraEnabled public Date       opportunityCloseDate;
        @AuraEnabled public Decimal    opportunityACV;
        @AuraEnabled public Decimal    accountCustomerARR;
  
        // Additional Account details for Opportunity column ----------------
        @AuraEnabled public String     accountSegment;
        @AuraEnabled public Decimal    accountLifetimeACV;
        @AuraEnabled public String     accountCurrencyIsoCode;
  
        // Meta Data --------------------------------------------------------
        @AuraEnabled public String     processId;         // Process Instance Id (used to build approve/reject links)
        @AuraEnabled public String     dateSubmitted;     // Formatted created-date string
        @AuraEnabled public Datetime   createdDate;       // raw created date for aging filters
    }
  
    /**
     * Paged result sent back to the client
     */
    public class PagedResult {
        @AuraEnabled public List<ApprovalItem> items;
        @AuraEnabled public Integer           totalRecords;
    }
  
    // ---------------------------------------------------------------------
    //  Public API (Aura/LWC)
    // ---------------------------------------------------------------------
  
    /**
     * Fetches pending approval items for the current user (and the groups they belong to) with
     * optional pagination / sorting / keyword filtering. Duplicate approvals (per Quote) are
     * removed.  Only approvals whose quotes are still pending (not Approved / Rejected) are returned.
     *
     * @param pageSize     – number of rows per page (default 20 when null/zero)
     * @param pageNumber   – 1-based page index (default 1 when null/zero)
     * @param sortBy       – API name of the field on SBAA__Approval__c / child objects to sort by
     * @param sortDirection – 'ASC' or 'DESC' (case-insensitive).  Default DESC.
     * @param searchKey     – optional free-text filter applied to Quote name, Account name or Opportunity name
     */
    @AuraEnabled(cacheable=true)
    public static PagedResult fetchApprovals(Integer pageSize,
                                             Integer pageNumber,
                                             String  sortBy,
                                             String  sortDirection,
                                             String  searchKey) {
        // ­­­­­-------------------------------------------------------------
        //  Parameter normalisation
        // ­­­­­-------------------------------------------------------------
        Integer effectivePageSize   = (pageSize    == null || pageSize   <= 0) ? 20 : pageSize;
        Integer effectivePageNumber = (pageNumber  == null || pageNumber <= 0) ? 1  : pageNumber;
        String  effectiveSortBy     = String.isBlank(sortBy)        ? 'CreatedDate' : sortBy.trim();
        String  effectiveSortDir    = String.isBlank(sortDirection) ? 'DESC'        : sortDirection.trim().toUpperCase();
        if(effectiveSortDir != 'ASC' && effectiveSortDir != 'DESC') {
            effectiveSortDir = 'DESC';
        }
  
        // ­­­­­-------------------------------------------------------------
        //  Resolve user-and-group scope
        // ­­­­­-------------------------------------------------------------
        Set<Id> userIds  = new Set<Id>{ UserInfo.getUserId() };
        Set<Id> groupIds = getGroupIdsForUsers(userIds);
  
        Set<String> allUserIdFormats  = getAllIdFormats(userIds);
        Set<String> allGroupIdFormats = getAllIdFormats(groupIds);
  
        // ­­­­­-------------------------------------------------------------
        //  Build SOQL dynamically (safe – no user supplied values concatenated directly
        //  apart from ORDER BY which is strictly controlled via allow-list below).
        // ­­­­­-------------------------------------------------------------
  
        // Allow-list of fields that can be used for sorting
        Set<String> allowedSortFields = new Set<String>{
            'CreatedDate','sbaa__Rule__r.Name','SBAA__Status__c','Quote__r.Name','Quote__r.SBQQ__Account__r.Name',
            'Quote__r.SBQQ__Opportunity2__r.Name','Quote__r.SBQQ__Opportunity2__r.StageName',
            'Quote__r.SBQQ__Opportunity2__r.CloseDate','Quote__r.SBQQ__Opportunity2__r.ACV_Bookings_SOT__c',
            'Quote__r.SBQQ__Account__r.Customer_ARR_Netsuite__c'
        };
        if(!allowedSortFields.contains(effectiveSortBy)) {
            effectiveSortBy = 'CreatedDate';
        }
  
        // ­­­­­-------------------------------------------------------------
        //  Fetch ALL approvals (not just 'Requested') to compute latest per Quote+Rule pair
        // ­­­­­-------------------------------------------------------------
        String baseQuery = 'SELECT Id, Quote__c, Quote__r.Name, Quote__r.SBQQ__Status__c, ' +
                'Quote__r.Reason_for_Discount__c, Quote__r.Blended_Discount__c, Quote__r.License_Term__c, ' +
                'Quote__r.SBQQ__Account__c, Quote__r.SBQQ__Account__r.Name, Quote__r.SBQQ__SalesRep__r.Name, ' +
                'Quote__r.SBQQ__Account__r.CurrencyIsoCode, ' +
                'Quote__r.SBQQ__Account__r.Segment__c, Quote__r.SBQQ__Account__r.Account_Lifetime_ACV__c, ' +
                'Quote__r.SBQQ__Account__r.Customer_ARR_Netsuite__c, ' +
                'Quote__r.SBQQ__Opportunity2__c, Quote__r.SBQQ__Opportunity2__r.Name, ' +
                'Quote__r.SBQQ__Opportunity2__r.Type, Quote__r.SBQQ__Opportunity2__r.StageName, ' +
                'Quote__r.SBQQ__Opportunity2__r.CloseDate, Quote__r.SBQQ__Opportunity2__r.ACV_Bookings_SOT__c, ' +
                'SBAA__Status__c, CreatedDate, Name, sbaa__Rule__c, sbaa__Rule__r.Name, Quote__r.ApprovalStatus__c ' +
            'FROM SBAA__Approval__c ' +
            'WHERE (SBAA__AssignedTo__c IN :allUserIdFormats OR SBAA__AssignedGroupId__c IN :allGroupIdFormats) ' +
            'AND Quote__c != null ' +
            'AND Quote__r.SBQQ__Status__c NOT IN (\'Approved\',\'Rejected\')' +
            'AND Quote__r.ApprovalStatus__c != \'Recalled\'';
  
        // Free-text filter (safe binder vars)
        if(String.isNotBlank(searchKey)) {
            String likeExp = '%' + searchKey.replace('%','\\%') + '%';
            baseQuery += ' AND (Quote__r.Name LIKE :likeExp OR ' +
                         'Quote__r.SBQQ__Account__r.Name LIKE :likeExp OR ' +
                         'Quote__r.SBQQ__Opportunity2__r.Name LIKE :likeExp OR ' +
                         'Quote__r.SBQQ__Account__r.Segment__c LIKE :likeExp OR ' +
                         'Quote__r.SBQQ__SalesRep__r.Name LIKE :likeExp OR ' +
                         'sbaa__Rule__r.Name LIKE :likeExp)';
        }
  
        // Execute query to get all relevant approvals
        String fullQuery = baseQuery + ' ORDER BY CreatedDate DESC, Id DESC';
        List<SBAA__Approval__c> allApprovals = Database.query(fullQuery);
  
        // ­­­­­-------------------------------------------------------------
        //  Compute newest approval per Quote+Rule pair; keep only if newest is 'Requested'
        // ­­­­­-------------------------------------------------------------
        Map<String,SBAA__Approval__c> pairToLatest = new Map<String,SBAA__Approval__c>();
        for(SBAA__Approval__c ap : allApprovals) {
            if(ap.Quote__c == null) { continue; }
            String ruleKey = (ap.sbaa__Rule__c == null) ? 'null' : String.valueOf(ap.sbaa__Rule__c);
            String pairKey = String.valueOf(ap.Quote__c) + '|' + ruleKey;
            
            if(!pairToLatest.containsKey(pairKey)){
                pairToLatest.put(pairKey, ap);
            }
        }
  
        // Filter to pairs where latest status is 'Requested'
        Map<String,SBAA__Approval__c> pairToApproval = new Map<String,SBAA__Approval__c>();
        for(String pairKey : pairToLatest.keySet()){
            SBAA__Approval__c latest = pairToLatest.get(pairKey);
            if(latest.SBAA__Status__c == 'Requested'){
                pairToApproval.put(pairKey, latest);
            }
        }
  
        // ­­­­­-------------------------------------------------------------
        //  Apply sorting and pagination in-memory on actionable pairs
        // ­­­­­-------------------------------------------------------------
        List<SBAA__Approval__c> sortedApprovals = new List<SBAA__Approval__c>(pairToApproval.values());
        sortApprovals(sortedApprovals, effectiveSortBy, effectiveSortDir);
        
        // Calculate total before pagination
        Integer totalDistinctPairs = sortedApprovals.size();
        
        // Apply pagination
        Integer startIndex = (effectivePageNumber - 1) * effectivePageSize;
        Integer endIndex = Math.min(startIndex + effectivePageSize, sortedApprovals.size());
        List<SBAA__Approval__c> pagedApprovals = new List<SBAA__Approval__c>();
        if(startIndex < sortedApprovals.size()){
            for(Integer i = startIndex; i < endIndex; i++){
                pagedApprovals.add(sortedApprovals[i]);
            }
        }
  
        // Fetch latest approver info for chain approvals (mirrors legacy controller)
        Set<Id> quotesInResult = new Set<Id>();
        for (SBAA__Approval__c kept : pagedApprovals) {
            quotesInResult.add(kept.Quote__c);
        }
        Map<Id,String> quoteToLastApprover = fetchLatestApproverNames(quotesInResult);
  
        List<ApprovalItem> items = new List<ApprovalItem>();
        for(SBAA__Approval__c ap : pagedApprovals) {
            ApprovalItem dto                 = new ApprovalItem();
            dto.quoteId                      = ap.Quote__c;
            dto.recordId                     = ap.Id;
            dto.relatedTo                    = ap.Quote__r != null ? ap.Quote__r.Name : null;
            dto.approvalName                 = ap.Name;
            dto.approvalRuleName             = (ap.sbaa__Rule__r != null) ? ap.sbaa__Rule__r.Name : null;
            dto.mostRecentApprover           = quoteToLastApprover.get(ap.Quote__c);
  
            dto.reasonForDiscount            = ap.Quote__r.Reason_for_Discount__c;
            dto.blendedDiscount              = ap.Quote__r.Blended_Discount__c;
            dto.licenseTerm                  = ap.Quote__r.License_Term__c;
            dto.salesRep                     = ap.Quote__r.SBQQ__SalesRep__r != null ? ap.Quote__r.SBQQ__SalesRep__r.Name : null;
  
            dto.accountId                    = ap.Quote__r.SBQQ__Account__c;
            dto.accountName                  = ap.Quote__r.SBQQ__Account__r != null ? ap.Quote__r.SBQQ__Account__r.Name : null;
            dto.accountSegment               = ap.Quote__r.SBQQ__Account__r != null ? ap.Quote__r.SBQQ__Account__r.Segment__c : null;
            dto.accountLifetimeACV           = ap.Quote__r.SBQQ__Account__r != null ? ap.Quote__r.SBQQ__Account__r.Account_Lifetime_ACV__c : null;
            dto.accountCurrencyIsoCode       = ap.Quote__r.SBQQ__Account__r != null ? ap.Quote__r.SBQQ__Account__r.CurrencyIsoCode : null;
            dto.accountCustomerARR           = ap.Quote__r.SBQQ__Account__r != null ? ap.Quote__r.SBQQ__Account__r.Customer_ARR_Netsuite__c : null;
  
            dto.opportunityId                = ap.Quote__r.SBQQ__Opportunity2__c;
            dto.opportunityName              = ap.Quote__r.SBQQ__Opportunity2__r != null ? ap.Quote__r.SBQQ__Opportunity2__r.Name : null;
            dto.opportunityType              = ap.Quote__r.SBQQ__Opportunity2__r != null ? ap.Quote__r.SBQQ__Opportunity2__r.Type : null;
            dto.opportunityStage             = ap.Quote__r.SBQQ__Opportunity2__r != null ? ap.Quote__r.SBQQ__Opportunity2__r.StageName : null;
            dto.opportunityCloseDate         = ap.Quote__r.SBQQ__Opportunity2__r != null ? ap.Quote__r.SBQQ__Opportunity2__r.CloseDate : null;
            dto.opportunityACV               = ap.Quote__r.SBQQ__Opportunity2__r != null ? ap.Quote__r.SBQQ__Opportunity2__r.ACV_Bookings_SOT__c : null;
  
            dto.processId                    = ap.Id; // Using approval Id for deep-linking to approve/reject pages
            dto.dateSubmitted                = ap.CreatedDate.format('MM/dd/yyyy hh:mm a');
            dto.createdDate                  = ap.CreatedDate;
  
            items.add(dto);
        }
  
        PagedResult result  = new PagedResult();
        result.items        = items;
        result.totalRecords = totalDistinctPairs;
        return result;
    }
  
    // ---------------------------------------------------------------------
    //  Helper Methods
    // ---------------------------------------------------------------------
  
    /**
     * Returns Set of GroupIds the supplied users belong to
     */
    private static Set<Id> getGroupIdsForUsers(Set<Id> userIds){
        Set<Id> grpIds = new Set<Id>();
        for(GroupMember gm : [SELECT GroupId FROM GroupMember WHERE UserOrGroupId IN :userIds]){
            grpIds.add(gm.GroupId);
        }
        return grpIds;
    }
  
    /**
     * Returns a set with both 15-char and 18-char flavours for each Id provided (handles text fields).
     */
    private static Set<String> getAllIdFormats(Set<Id> ids){
        Set<String> result = new Set<String>();
        for(Id i : ids){
            if(i != null){
                String s = String.valueOf(i);
                result.add(s);
                result.add(s.substring(0,15));
            }
        }
        return result;
    }
  
    /**
     * For the supplied quote Ids, fetch the most recent approver name (mirrors legacy controller logic).
     * Uses a large limit (40k) to cover bulk scenarios but only returns first match per Quote.
     */
    private static Map<Id,String> fetchLatestApproverNames(Set<Id> quoteIds){
        Map<Id,String> outMap = new Map<Id,String>();
        if(quoteIds.isEmpty()){ return outMap; }
        for(SBAA__Approval__c a : [SELECT Quote__c, SBAA__ApprovedBy__r.Name
                                   FROM SBAA__Approval__c
                                   WHERE Quote__c IN :quoteIds AND SBAA__Status__c = 'Approved'
                                   ORDER BY LastModifiedDate DESC
                                   LIMIT 40000]){
            if(!outMap.containsKey(a.Quote__c)){
                outMap.put(a.Quote__c, a.SBAA__ApprovedBy__r.Name);
            }
        }
        return outMap;
    }
  
    /**
     * In-memory sort of approval records based on sortBy field and direction.
     * Supports nested fields via dot notation (e.g. 'Quote__r.Name').
     */
    private static void sortApprovals(List<SBAA__Approval__c> approvals, String sortBy, String sortDir){
        if(approvals.isEmpty()){ return; }
        
        Boolean isAsc = (sortDir == 'ASC');
        
        // Simple bubble sort for in-memory sorting (adequate for typical page sizes)
        for(Integer i = 0; i < approvals.size() - 1; i++){
            for(Integer j = i + 1; j < approvals.size(); j++){
                SBAA__Approval__c a = approvals[i];
                SBAA__Approval__c b = approvals[j];
                
                Integer comparison = compareApprovals(a, b, sortBy);
                
                if((isAsc && comparison > 0) || (!isAsc && comparison < 0)){
                    approvals[i] = b;
                    approvals[j] = a;
                }
            }
        }
    }
  
    /**
     * Compare two approval records based on the sortBy field.
     * Returns negative if a < b, 0 if equal, positive if a > b.
     */
    private static Integer compareApprovals(SBAA__Approval__c a, SBAA__Approval__c b, String sortBy){
        Object valA = getFieldValue(a, sortBy);
        Object valB = getFieldValue(b, sortBy);
        
        if(valA == null && valB == null){ return compareByCreatedDate(a, b); }
        if(valA == null){ return 1; }  // nulls last
        if(valB == null){ return -1; }
        
        // Type-specific comparison
        if(valA instanceof String){
            Integer cmp = ((String)valA).compareTo((String)valB);
            return cmp != 0 ? cmp : compareByCreatedDate(a, b);
        } else if(valA instanceof Decimal){
            Decimal diff = (Decimal)valA - (Decimal)valB;
            if(diff > 0){ return 1; }
            if(diff < 0){ return -1; }
            return compareByCreatedDate(a, b);
        } else if(valA instanceof Date){
            Date dA = (Date)valA;
            Date dB = (Date)valB;
            if(dA > dB){ return 1; }
            if(dA < dB){ return -1; }
            return compareByCreatedDate(a, b);
        } else if(valA instanceof Datetime){
            Datetime dtA = (Datetime)valA;
            Datetime dtB = (Datetime)valB;
            if(dtA > dtB){ return 1; }
            if(dtA < dtB){ return -1; }
            return compareByCreatedDate(a, b);
        }
        
        return compareByCreatedDate(a, b);
    }
  
    /**
     * Tie-breaker: compare by CreatedDate DESC, then Id
     */
    private static Integer compareByCreatedDate(SBAA__Approval__c a, SBAA__Approval__c b){
        if(a.CreatedDate > b.CreatedDate){ return -1; }
        if(a.CreatedDate < b.CreatedDate){ return 1; }
        return String.valueOf(a.Id).compareTo(String.valueOf(b.Id));
    }
  
    /**
     * Extract field value from approval record, supporting nested relationships via dot notation.
     */
    private static Object getFieldValue(SBAA__Approval__c ap, String fieldPath){
        if(String.isBlank(fieldPath)){ return null; }
        
        List<String> parts = fieldPath.split('\\.');
        SObject current = ap;
        
        for(Integer i = 0; i < parts.size(); i++){
            if(current == null){ return null; }
            String part = parts[i];
            
            // If not the last part, it's a relationship - use getSObject
            if(i < parts.size() - 1){
                current = current.getSObject(part);
            } else {
                // Last part - it's a field value
                return current.get(part);
            }
        }
        
        return null;
    }
  }