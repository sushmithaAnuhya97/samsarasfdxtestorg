/**********************************************************************
Name: AccountBookTriggerHelper
=======================================================================
Purpose: This class will contain methods to initiate trigger handler                                                         
=======================================================================
History  

VERSION     AUTHOR               DATE               DETAIL                       
1.0        Rodrigo Carpio        2023-Jan-13        INITIAL DEVELOPMENT

***********************************************************************/ 
public without sharing class AccountBookTriggerHelper {
    private static Map<Id, Boolean> mapAEExceedLimit = new Map<Id, Boolean>();
    private static Boolean isADRAssignmentFromBooksRun = false;
   

    
    public static void beforeInsertUpdate(Map<Id, Book_Of_Business__c > oldAccountBookMap, List<Book_Of_Business__c > newAccountBookList) {
        
        Set<Id> setAEIds = new Set<Id>();
        
        FOR(Book_Of_Business__c aeObj : newAccountBookList) {
            Book_Of_Business__c oldRecord = new Book_Of_Business__c();
            if (oldAccountBookMap != null && oldAccountBookMap.containsKey(aeObj.Id))
                oldRecord = oldAccountBookMap.get(aeObj.Id);
            if (oldRecord == null || (oldRecord != null && (oldRecord.AE__c!=aeObj.AE__c)))
                setAEIds.add(aeObj.AE__c);
        }
        
        validateAccountBookAssignment(setAEIds, oldAccountBookMap, newAccountBookList);
        
    }  
    
    
    public static void checkAccountBookAssignment(Map<Id, Account> oldAccountMap, List<Account> newAccountList) 
    {
        
        Set<Id> setBookId = new Set<Id>();
        Map<Id, Id> accountBookIdMap = new Map<Id, Id>();
        //system.debug('RODRIGO checkAccountBookAssignment oldAccountMap ' + oldAccountMap);
        FOR (Account accountId : newAccountList) {
            Account oldAccount = oldAccountMap.get(accountId.Id);
            
            if (accountId.Status__c != null && !accountId.Status__c.containsIgnoreCase('Existing Customer') && ((accountId.Prospecting_Status__c == 'AE Prospecting' && ( (oldAccount == null && accountId.Books_Of_Business__c != null) ||
                                                                                                                                                                         (oldAccount.Books_Of_Business__c != accountId.Books_Of_Business__c))) ||
                                                                                                                (accountId.Books_Of_Business__c != null && accountId.Prospecting_Status__c == 'AE Prospecting' && 
                                                                                                                 accountId.Prospecting_Status__c != oldAccount.Prospecting_Status__c )) )
            {
                setBookId.add(accountId.Books_Of_Business__c);
                accountBookIdMap.put(accountId.Id, accountId.Books_Of_Business__c);
            }
        }
        if (setBookId != null && setBookId.size()>0) {
            //system.debug('RODRIGO  setBookId ' + setBookId);
            List<Book_Of_Business__c> listBook = [SELECT Id, AE__c, AE_Ramp_Status__c  FROM Book_Of_Business__c WHERE Id IN: setBookId ORDER BY AE__c];
            
            Set<Id> setAEIds = new Set<Id>();
            Map<Id, Id> boodIdAEMap = new Map<Id, Id>();
            FOR(Book_Of_Business__c aeObj : listBook) {
                setAEIds.add(aeObj.AE__c);
                boodIdAEMap.put(aeObj.Id, aeObj.AE__c);
            }
            
            //system.debug('RODRIGO  setAEIds ' + setAEIds);
            if(setAEIds != null && setAEIds.size()>0) {
                validateAccountBookAssignment(setAEIds, null, null);
                //system.debug('mapAEExceedLimit ' + mapAEExceedLimit);
                //system.debug('RODRIGO  newAccountList ' + newAccountList);
                FOR (Account accountObj : newAccountList) {
                    if(accountBookIdMap.containsKey(accountObj.Id)) {
                        Id bookId = accountBookIdMap.get(accountObj.Id);
                        Id bookAEId = boodIdAEMap.get(bookId);
                        if (mapAEExceedLimit.containsKey(bookAEId) && mapAEExceedLimit.get(bookAEId)) {
                            // commenting out the VR as part of GTMS - 17591
                            //accountObj.addError('You have reached the limit of accounts in the status AE Prospecting. To resolve consider switching another account in your book to ADR Prospecting to open up room.');        
                        }
                        
                    }
                    
                }
            }            
        }
    }
    
    public static string validateAccountBookAssignment(Set<Id>setAEIds, Map<Id, Book_Of_Business__c > oldAccountBookMap, List<Book_Of_Business__c > newAccountBookList)
    {
        Set<Id> setBookId = new Set<Id>();
        List<Book_Of_Business__c> listBook = [SELECT Id, AE__c, AE_Ramp_Status__c  FROM Book_Of_Business__c WHERE AE__c IN: setAEIds ORDER BY AE__c];
        
        Map<Id, Set<Id>> mapAEId = new Map<Id, Set<Id>>();
        Map<Id, String> mapAERampStatus = new Map<Id, String>();
        FOR (Id eaId : setAEIds) {
            Set<Id> bookIdSet = new Set<Id>();
            String rampStatus = null;
            FOR(Book_Of_Business__c bookObj : listBook) {
                if (eaId == bookObj.AE__c) {
                    rampStatus = bookObj.AE_Ramp_Status__c ;
                    bookIdSet.add(bookObj.Id);
                    setBookId.add(bookObj.Id);
                }
            }
            mapAERampStatus.put(eaId, rampStatus);
            mapAEId.put(eaId, bookIdSet);
        }
        
        //system.debug('setBookId ' + setBookId);
        //Integer accountCount =  [SELECT count() FROM Account WHERE Books_Of_Business__c IN:setBookId];
        List<AggregateResult> lstResult = [SELECT Books_Of_Business__c, count(Id) FROM Account 
                                           WHERE Prospecting_Status__c='AE Prospecting' AND Status__c != 'Existing Customer'
                                           AND Books_Of_Business__c IN:setBookId GROUP BY Books_Of_Business__c];
        
        Map<Id, Integer> mapAEAssignCount = new Map<Id, Integer>();
        FOR(AggregateResult res: lstResult) {
            //system.debug(res.get('Books_Of_Business__c') + ' accountCount ' + res.get('expr0'));
            FOR(Id idAELoc: mapAEId.keySet()) {
                Set<Id> idBookLocSet = mapAEId.get(idAELoc);
                if (idBookLocSet.size()>0) {
                    string bookId = string.valueOf(res.get('Books_Of_Business__c'));
                    if (idBookLocSet.contains(bookId)){
                        Integer locCount = Integer.valueOf(res.get('expr0'));
                        //system.debug('locCount ' + locCount);
                        if(mapAEAssignCount.containsKey(idAELoc)) {
                            Integer currCount = mapAEAssignCount.get(idAELoc);
                            currCount = currCount + locCount;
                            //system.debug('currCount ' + currCount);
                            mapAEAssignCount.put(idAELoc, currCount);
                        }
                        else
                            mapAEAssignCount.put(idAELoc, locCount);
                        
                    }
                    
                }
            }
        }
        
        //system.debug('mapAEAssignCount ' + mapAEAssignCount);
        //system.debug('mapAERampStatus ' + mapAERampStatus);
        Integer tenuredAECount = Integer.valueOf(System.Label.Account_Book_Tenured_AE_Limit);
        Integer newAECount = Integer.valueOf(System.Label.Account_Book_New_AE_Limit);
        //system.debug('tenuredAECount ' + tenuredAECount);
        //system.debug('newAECount ' + newAECount);
        
        FOR (Id cntAEId : mapAEAssignCount.keySet()) {
            Integer aeCount = mapAEAssignCount.get(cntAEId);
            String aeRampStatus = mapAERampStatus.get(cntAEId);
            //system.debug('aeCount ' + aeCount);
            //system.debug('aeRampStatus ' + aeRampStatus);
            if( (aeRampStatus == 'Tenured' && aeCount>=tenuredAECount) ||
               (aeRampStatus == 'New' && aeCount>=newAECount) )
            {
                mapAEExceedLimit.put(cntAEId, true);
                /*CalloutException k = new CalloutException();
k.setMessage('You have reached the limit of accounts in the status AE Prospecting.  To resolve consider switching another account in your book to ADR Prospecting to open up room.');
throw k;*/
            }
        }
        
        if (newAccountBookList != null && newAccountBookList.size()>0) {
            FOR(Book_Of_Business__c aeObj : newAccountBookList) {
                if(mapAEExceedLimit.containsKey(aeObj.AE__c)){
                    //commenting out as per - GTMS-17591- Alpha 3.0
                    //aeObj.addError('You have reached the limit of accounts in the status AE Prospecting. To resolve consider switching another account in your book to ADR Prospecting to open up room.');        
                }
            }
        }
        
        return null;
    }
    public static String bookquery = 'SELECT Id, AE__c, ADR__c,ADR__r.IsActive, Account_Book_Status__c FROM Book_of_Business__c WHERE Account_Book_Status__c = \'Primary: In Seat\' AND AE__c IN :accountOwnerIds';
    // GTMS- 11943 Create/Update Account team members based on the AE/ADR on the Account Book
    public static void AddteamMember(Map<Id, Account> oldAccountsMap,List<Account> newAccountList) {
        Set<Id> bookOfBusinessIds = new Set<Id>();
        Set<Id> accountIdsToQuery = new Set<Id>();
        Map<Id, Id> accountBookMap = new Map<Id, Id>();
        Set<Id> accountOwnerIds = new Set<Id>();
        for (Account newAccount : newAccountList) {
            // insert scenario
            if (oldAccountsMap==null && newAccount.Books_Of_Business__c !=null) {
                bookOfBusinessIds.add(newAccount.Books_Of_Business__c);
                accountBookMap.put(newAccount.Id, newAccount.Books_Of_Business__c);
            }
            // update scenario - when Account Book is updated on Account
            else if (oldAccountsMap != null && ((newAccount.Books_Of_Business__c != oldAccountsMap.get(newAccount.Id).Books_Of_Business__c 
                                                 && newAccount.Books_Of_Business__c != null) || (oldAccountsMap.get(newAccount.Id).Books_Of_Business__c != null 
                                                                                                 && newAccount.Books_Of_Business__c == null))) 
            {
                bookOfBusinessIds.add(newAccount.Books_Of_Business__c);
                accountBookMap.put(newAccount.Id, newAccount.Books_Of_Business__c);
                accountIdsToQuery.add(newAccount.Id);
            }
            // update scenario - when Account Owner is updated and Account_Book_Status__c of Books_of_Business__c = overcarve/AOP 
            else if (oldAccountsMap != null && newAccount.Owner_Role__c!=null && newAccount.Owner_Role__c.contains(' AE') && newAccount.OwnerId != oldAccountsMap.get(newAccount.Id).OwnerId && newAccount.Books_of_Business__c != null &&
                     (newAccount.Account_Book_Status__c == 'Secondary: Overcarve' || newAccount.Account_Book_Status__c == 'Secondary: AOP Hires')) {
                         accountOwnerIds.add(newAccount.OwnerId);
                     }
                
        }
        if (!bookOfBusinessIds.isEmpty()) { 
            if (!accountIdsToQuery.isEmpty()) {
                List<AccountTeamMember> existingTeamMembers = [SELECT Id, UserId, TeamMemberRole 
                                                               FROM AccountTeamMember 
                                                               WHERE AccountId = :accountIdsToQuery 
                                                               AND (TeamMemberRole = 'Account Executive' OR TeamMemberRole = 'Account Development Representative')];
                System.debug(existingTeamMembers);
                // Delete existing AccountTeamMembers
                if (!existingTeamMembers.isEmpty()) {
                    delete existingTeamMembers;
                }
            }            
            Map<Id, Book_Of_Business__c> bookOfBusinessMap = new Map<Id, Book_Of_Business__c>(
                [SELECT Id, AE__c, AE__r.UserRole.Name, ADR__c, ADR__r.UserRole.Name, Account_Book_Status__c,ADR__r.IsActive 
                 FROM Book_Of_Business__c 
                 WHERE Id IN :bookOfBusinessIds AND Account_Book_Status__c != 'Secondary: Overcarve' AND Account_Book_Status__c != 'Secondary: AOP Hires' ]
            );
            
            List<AccountTeamMember> accountTeamMembersToInsert = new List<AccountTeamMember>();
            
            for (Account newAccount : newAccountList) {
                if (accountBookMap.containsKey(newAccount.Id)) {
                    Id bookOfBusinessId = accountBookMap.get(newAccount.Id);// Book of business Id
                    Book_Of_Business__c bookOfBusiness = bookOfBusinessMap.get(bookOfBusinessId);// Account Book with AE and ADR
                    
                    // Add ADR if present
                    addADRToAccountTeam(newAccount.id, bookOfBusiness, accountTeamMembersToInsert);
                    
                    // Add AE if present
                    addAEToAccountTeam(newAccount.id, bookOfBusiness, accountTeamMembersToInsert);
                }
            }
            
            if (!accountTeamMembersToInsert.isEmpty()) {
                insert accountTeamMembersToInsert;
            }
        }
        if (!accountOwnerIds.isEmpty()) {
            // Query Book_of_Business__c records related to the new Account Owners
            Map<Id, Book_of_Business__c> ownerIdToBookOfBusinessMap = new Map<Id, Book_of_Business__c>();
            for (Book_of_Business__c book : Database.query(bookquery)) {
                                                 ownerIdToBookOfBusinessMap.put(book.AE__c, book);
    }
    
            List<AccountTeamMember> accountTeamMembersToAdd = new List<AccountTeamMember>();
            
            // Add ADR to Account Team if conditions met
            for (Account acc : newAccountList) {
                if (accountOwnerIds.contains(acc.OwnerId) && acc.Books_of_Business__c != null) {
                    Book_of_Business__c book = ownerIdToBookOfBusinessMap.get(acc.OwnerId);
                    if (book != null && book.Account_Book_Status__c == 'Primary: In Seat') {
                        addADRToAccountTeam(acc.Id, book, accountTeamMembersToAdd);
                    }
                }
            }
            
            // Insert AccountTeamMembers if any
            if (!accountTeamMembersToAdd.isEmpty()) {
                insert accountTeamMembersToAdd;
            }
        }
        
    }
 
    // Method to add ADR to Account Team if present
    private static void addADRToAccountTeam(id newAccount, Book_Of_Business__c bookOfBusiness, List<AccountTeamMember> accountTeamMembersToInsert) {
        if (bookOfBusiness != null && bookOfBusiness.ADR__c != null && bookOfBusiness.ADR__r.IsActive ) {
            AccountTeamMember accountTeamMemberADR = new AccountTeamMember();
            accountTeamMemberADR.AccountId = newAccount;
            accountTeamMemberADR.UserId = bookOfBusiness.ADR__c;
            accountTeamMemberADR.TeamMemberRole = 'Account Development Representative';
            accountTeamMemberADR.AccountAccessLevel = 'Edit';	
            accountTeamMemberADR.OpportunityAccessLevel = 'Read';
            accountTeamMembersToInsert.add(accountTeamMemberADR);
        }
    }
    
    // Method to add AE to Account Team if present
    private static void addAEToAccountTeam(id newAccount, Book_Of_Business__c bookOfBusiness, List<AccountTeamMember> accountTeamMembersToInsert) {
        if (bookOfBusiness != null && bookOfBusiness.AE__c != null) {
            AccountTeamMember accountTeamMemberAE = new AccountTeamMember();
            accountTeamMemberAE.AccountId = newAccount;
            accountTeamMemberAE.UserId = bookOfBusiness.AE__c;
            accountTeamMemberAE.TeamMemberRole = 'Account Executive';
            accountTeamMemberAE.AccountAccessLevel = 'Edit';	
            accountTeamMemberAE.OpportunityAccessLevel = 'Edit';
            accountTeamMembersToInsert.add(accountTeamMemberAE);
        }
    }
    // Update Account team members when AE/ADRs are updated on the related Account Book
    public static void updateAccountTeamMembers(Map<Id, Book_Of_Business__c> oldBooksMap, List<Book_Of_Business__c> updatedBooksList) {
        Set<Id> updatedBookOfBusinessIds = new Set<Id>();
        Map<Id, Set<Id>> bookToAccountMap = new Map<Id, Set<Id>>();
        List<Book_Of_Business__c> newBooksList = [Select Id, Name, ADR__c, AE__c,ADR__r.isActive from Book_Of_Business__c where Id IN :updatedBooksList ];
        for (Book_Of_Business__c updatedBook : newBooksList) {
            if (oldBooksMap == null || 
                (oldBooksMap.get(updatedBook.Id).AE__c != updatedBook.AE__c) || 
                (oldBooksMap.get(updatedBook.Id).ADR__c != updatedBook.ADR__c)) {
                    updatedBookOfBusinessIds.add(updatedBook.Id);
                }
            
            updateAccountTeamMembersForBook(updatedBook, bookToAccountMap);
        }
    }
    
    public static void updateAccountTeamMembersForBook(Book_Of_Business__c updatedBook, Map<Id, Set<Id>> bookToAccountMap) {
        List<Account> relatedAccounts = [SELECT Id FROM Account WHERE Books_Of_Business__c = :updatedBook.Id];
        Set<Id> accountIds = new Set<Id>();
        
        for (Account acc : relatedAccounts) {
            accountIds.add(acc.Id);
            if (!bookToAccountMap.containsKey(updatedBook.Id)) {
                bookToAccountMap.put(updatedBook.Id, new Set<Id>());
            }
            bookToAccountMap.get(updatedBook.Id).add(acc.Id);
        }
        
        // Delete existing AccountTeamMembers before inserting new ones
        List<AccountTeamMember> existingTeamMembersToDelete = [SELECT Id FROM AccountTeamMember WHERE AccountId IN :accountIds];
        if (!existingTeamMembersToDelete.isEmpty()) {
            delete existingTeamMembersToDelete;
        }
        
        // Insert new AccountTeamMembers
        List<AccountTeamMember> accountTeamMembersToInsert = new List<AccountTeamMember>();
        for (Id accId : accountIds) {
            // Add ADR if present
            addADRToAccountTeam(accId, updatedBook, accountTeamMembersToInsert);
            // Add AE if present
            addAEToAccountTeam(accId, updatedBook, accountTeamMembersToInsert);
        }
        
        if (!accountTeamMembersToInsert.isEmpty()) {
            insert accountTeamMembersToInsert;
        }
    }
    
    
    // Retain team members when Account Owner is changed
    public static Map<Id, List<AccountTeamMember>> accountIdToTeamMembersMap = new Map<Id, List<AccountTeamMember>>();
    
    public static void retainTeamMembers(List<Account> newAccountList,Map<id,Account> oldAccountMap) {
        
        Set<Id> accountIds = new Set<Id>();
        for (Account acc : newAccountList) {
            if (acc.OwnerId != oldAccountMap.get(acc.Id).OwnerId) {
                accountIds.add(acc.Id);
            }
        }
        
        //all Account Team Members for the given accounts
       if( !accountIds.isEmpty() && accountIds.Size() >0){
        List<AccountTeamMember> allTeamMembers = [SELECT AccountId, UserId, AccountAccessLevel, OpportunityAccessLevel, TeamMemberRole 
                                                  FROM AccountTeamMember 
                                                  WHERE AccountId IN :accountIds];
        
        // Store the Account Team Members in the map
        for (AccountTeamMember member : allTeamMembers) {
            if (!accountIdToTeamMembersMap.containsKey(member.AccountId)) {
                accountIdToTeamMembersMap.put(member.AccountId, new List<AccountTeamMember>());
            }
            accountIdToTeamMembersMap.get(member.AccountId).add(member);
        }
           
       }   
    }
    
    public static void reinsertTeamMembers(List<Account> newAccountList, Map<Id, Account> oldAccountMap) {
        List<AccountTeamMember> teamMembersToReinsert = new List<AccountTeamMember>();
        for (Account acc : newAccountList) {
            if (acc.OwnerId != oldAccountMap.get(acc.Id).OwnerId) {
                if(accountIdToTeamMembersMap != null && !accountIdToTeamMembersMap.isEmpty() && accountIdToTeamMembersMap.containsKey(acc.Id)){
                    for (AccountTeamMember originalMember : accountIdToTeamMembersMap.get(acc.Id)) {
                        AccountTeamMember newMember = new AccountTeamMember(
                            AccountId = originalMember.AccountId,
                            UserId = originalMember.UserId,
                            AccountAccessLevel = originalMember.AccountAccessLevel,
                            OpportunityAccessLevel = originalMember.OpportunityAccessLevel,
                            TeamMemberRole = originalMember.TeamMemberRole
                        );
                        teamMembersToReinsert.add(newMember);
                    }
                }
                //GTMS-26025 commenting the below lines as DML is performed in the loop
               /* if (!teamMembersToReinsert.isEmpty()) {
                    // Reinsert Account Team Members
                    try {
                        insert teamMembersToReinsert;
                        System.debug('Account Team Members reinserted successfully for Account Id: ' + acc.Id);
                    } catch (DmlException e) {
                        System.debug('Error reinserting Account Team Members: ' + e.getMessage());
                    }
                } else {
                    System.debug('No Account Team Members found for Account Id: ' + acc.Id);
                }*/
            }
        }
        //GTMS-26025
        if (!teamMembersToReinsert.isEmpty()) {
            // Reinsert Account Team Members
            try {
                insert teamMembersToReinsert;
                //System.debug('Account Team Members reinserted successfully for Account Id: ' + acc.Id);
            } catch (DmlException e) {
                System.debug('Error reinserting Account Team Members: ' + e.getMessage());
            }
        } 
    }
    // GTMS-19301 Update Account Book if field is empty and Account Owner is associated with an Account Book
    public static void updateAccountBook(Map<Id,Account>oldAccountMap,List<Account> newAccountList) {
        Set<Id> accountOwnerIds = new Set<Id>();
        
        for (Account acc : newAccountList) {
            // insert scenario or if oldAccountMap is null
            if (oldAccountMap==null && acc.Books_Of_Business__c == null && acc.Owner_Role__c!=null && acc.Owner_Role__c.contains(' AE')) {
                accountOwnerIds.add(acc.OwnerId);
            }
            
            // update scenario - Account Owner is updated which has a primary book associated with it.
            else if (oldAccountMap != null && acc.Books_Of_Business__c == null && acc.OwnerId != null && acc.OwnerId != oldAccountMap.get(acc.Id).OwnerId && oldAccountMap.get(acc.Id).Books_Of_Business__c == null && acc.Owner_Role__c!=null && acc.Owner_Role__c.contains(' AE')) {
                accountOwnerIds.add(acc.OwnerId);
            }
        }
        if (!accountOwnerIds.isEmpty()) {
            // Query Book_Of_Business__c records where AE__c field is populated and matches the Account owner
            List<Book_Of_Business__c> booksOfBusiness = Database.query(bookquery);
            // Map Account owners to matching Book_Of_Business__c records
            Map<Id, Book_Of_Business__c> ownerToBookMap = new Map<Id, Book_Of_Business__c>();
            for (Book_Of_Business__c book : booksOfBusiness) {
                ownerToBookMap.put(book.AE__c, book);
                System.debug('ownerToBookMap' + ownerToBookMap);
            }
            for (Account acc : newAccountList) {
                Book_Of_Business__c matchingBook = ownerToBookMap.get(acc.OwnerId);
                System.debug('matchingBook' + matchingBook);
                if (matchingBook != null) {
                    acc.Books_Of_Business__c = matchingBook.Id;
                }
                else{
                    acc.Books_Of_Business__c =null;
                }
            }
        }
    }
    
    // GTMS-14574 This method allows quote visibility after account owner changes
public static void quoteSharetonewAccountOwner(Map<Id, Account> oldAccountMap, Map<Id, Account> newAccountMap) {
      
    Set<String> setAccountIdswithOldOwnerIds = new Set<String>();
    Set<Id> setAccountIds = new Set<Id>();
    Set<Id> oldOwnerIds = new Set<Id>();    
    for (Id accId : newAccountMap.keySet()) {
        Account newAccount = newAccountMap.get(accId);
        Account oldAccount = oldAccountMap.get(accId);
       if (newAccount != null && oldAccount != null) {
        if (newAccount.OwnerId != oldAccount.OwnerId && newAccount.OwnerId != null) {
            // Old key for owner and account
            String oldKey = newAccount.Id + '~' + oldAccount.OwnerId;
            setAccountIdswithOldOwnerIds.add(oldKey);

            setAccountIds.add(newAccount.Id);
            oldOwnerIds.add(oldAccount.OwnerId);
        }
    }
    }
    if (!setAccountIds.isEmpty()) {
        // Removing access for old owner ids
        removeQuotesOfOldAccountOwner(setAccountIds, setAccountIdswithOldOwnerIds, oldOwnerIds);

        List<SBQQ__Quote__c> relatedQuotes = [
            SELECT Id, SBQQ__Opportunity2__r.AccountId
            FROM SBQQ__Quote__c
            WHERE SBQQ__Opportunity2__r.AccountId IN :setAccountIds
            AND ((SBQQ__Opportunity2__r.IsClosed = FALSE) OR (SBQQ__Opportunity2__r.IsClosed = true AND SBQQ__Primary__c = true))
        ];

        List<SBQQ__Quote__Share> quoteSharesToCreate = new List<SBQQ__Quote__Share>();
        for (SBQQ__Quote__c quote : relatedQuotes) {
            Id newOwnerId = newAccountMap.get(quote.SBQQ__Opportunity2__r.AccountId).OwnerId;

            SBQQ__Quote__Share share = new SBQQ__Quote__Share(
                ParentId = quote.Id,
                UserOrGroupId = newOwnerId,
                RowCause = 'Manual',
                AccessLevel = 'Edit'
            );
            quoteSharesToCreate.add(share);
        }

        // Insert new share records
        if (!quoteSharesToCreate.isEmpty()) {
            Database.insert(quoteSharesToCreate, false);
        }
    }
}

// To delete old account owner shared quotes
private static void removeQuotesOfOldAccountOwner(Set<Id> setAccountIds, Set<String> setAccountIdswithOldOwnerIds, Set<Id> oldOwnerIds) {
    List<SBQQ__Quote__Share> lstToDelete = new List<SBQQ__Quote__Share>();

    // Query to find CPQ Quote Share records with RowCause == Manual
    List<SBQQ__Quote__Share> sharesToDelete = [
        SELECT Id, UserOrGroupId, Parent.SBQQ__Account__c
        FROM SBQQ__Quote__Share
        WHERE RowCause = 'Manual'
        AND UserOrGroupId IN :oldOwnerIds
        AND Parent.SBQQ__Account__c IN :setAccountIds
    ];

    // Iteration in case there was a manual share that's not part of the owner transition but manually given on the quote
    for (SBQQ__Quote__Share quoteShare : sharesToDelete) {
        String oldKey = quoteShare.Parent.SBQQ__Account__c + '~' + quoteShare.UserOrGroupId;

        if (setAccountIdswithOldOwnerIds.contains(oldKey)) {
            lstToDelete.add(quoteShare);
        }
    }

    if (!lstToDelete.isEmpty()) {
        delete lstToDelete;
    }
}

//GTMS- 25388 This method is used to update ADR assignment on Account when updated/Changed on Account Boook
    public static void updateADRAssignmentFromBooksOnAccount(Map<Id, Book_Of_Business__c> oldBooksMap, List<Book_Of_Business__c> updatedBooksList) {
        if (isADRAssignmentFromBooksRun) {
        return;
    }
    isADRAssignmentFromBooksRun = true;
        Map<Id, Id> bookToADRMap = new Map<Id, Id>();
        for (Book_Of_Business__c newBook : updatedBooksList) {
            if (oldBooksMap != null &&
                oldBooksMap.get(newBook.Id) != null &&
                oldBooksMap.get(newBook.Id).ADR__c != newBook.ADR__c) {
                    bookToADRMap.put(newBook.Id, newBook.ADR__c);
                }
        }
        if (booktoADRMap.isEmpty()) {
            return;
        }
        List<Account> accountsToUpdate = [
            SELECT Id, Books_Of_Business__c, adrassignment__c
            FROM Account
            WHERE Books_Of_Business__c IN :bookToADRMap.keyset() 
        ];
        Set<Id> updatedAccountIds = new Set<Id>();
        for (Account acc : accountsToUpdate) {
            if(bookToADRMap.containsKey(acc.Books_Of_Business__c)){
                acc.adrassignment__c = bookToADRMap.get(acc.Books_Of_Business__c);
                updatedAccountIds.add(acc.Id);
            }
        }
        if (!updatedAccountIds.isEmpty()) {
            try {
                TriggerHandler.bypass('GS_AccountTriggerHandler');
                update accountsToUpdate;
                if (!System.isBatch() && !System.isFuture() && !System.isQueueable()) {
                ContactADRAssignmentBatch contactBatch = new ContactADRAssignmentBatch(updatedAccountIds);
                Database.executeBatch(contactBatch, Integer.valueOf(System.Label.ContactADRAssignmentBatchJobSize));
                }
            } catch (DmlException e) {
                System.debug(LoggingLevel.ERROR, 'Error updating accounts: ' + e.getMessage());
                System.debug(LoggingLevel.ERROR, 'Stack trace: ' + e.getStackTraceString());
            }
        }
    }
}