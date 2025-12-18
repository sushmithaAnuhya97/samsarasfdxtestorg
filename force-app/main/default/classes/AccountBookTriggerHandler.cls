/**********************************************************************
Name: AccountBookTriggerHandler
=======================================================================
Purpose: This class will contain methods to initiate trigger handler                                                         
=======================================================================
History  

VERSION     AUTHOR               DATE               DETAIL                       
1.0        Rodrigo Carpio        2023-Jan-13        INITIAL DEVELOPMENT

***********************************************************************/ 
public class AccountBookTriggerHandler extends TriggerHandler {
    private Map<Id, Book_Of_Business__c> oldAccountBookMap;
	private Map<Id, Book_Of_Business__c> newAccountBookMap;
	private List<Book_Of_Business__c> newAccountBookList;
    public AccountBookTriggerHandler() {
		this.oldAccountBookMap = (Map<Id, Book_Of_Business__c >) Trigger.oldMap;
		this.newAccountBookMap = (Map<Id, Book_Of_Business__c >) Trigger.newMap;
		this.newAccountBookList = (List<Book_Of_Business__c >) Trigger.new;
    }
    public static Boolean alreadyRanUpdate = false;
	public static Boolean alreadyRanInsert = false;
	public override void beforeInsert() {
        if (!alreadyRanInsert) {
            AccountBookTriggerHelper.beforeInsertUpdate(oldAccountBookMap, newAccountBookList);
            alreadyRanInsert = true;
        }
    }
    public override void afterInsert() {
    }
    public override void beforeUpdate() {
        if (!alreadyRanUpdate){
            AccountBookTriggerHelper.beforeInsertUpdate(oldAccountBookMap, newAccountBookList);
            alreadyRanUpdate = true;
        }
    }
    public override void afterUpdate() {
            AccountBookTriggerHelper.updateAccountTeamMembers(oldAccountBookMap,newAccountBookList );
	        AccountBookTriggerHelper.updateADRAssignmentFromBooksOnAccount(oldAccountBookMap,newAccountBookList );

    }
}