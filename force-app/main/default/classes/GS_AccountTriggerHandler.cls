/**
* Created By : Groundswell - Tanuj Tyagi
* @Date August 06, 2021
*
* @description : This Account Handler is created as part of the Audit Optimization. It will only call GS_Account Service Class
* SFA-11
*
**/
public class GS_AccountTriggerHandler extends TriggerHandler{
    private Map<Id, Account> oldAccountMap;
    private Map<Id, Account> newAccountMap;
    private List<Account> newAccountList;
    private List<Account> oldAccountList;
    private Set<Id> OldAccountSet;
    public static Boolean alreadyRan = false;
    public SamsaraLoggerService thisSamsaraLoggerService = new SamsaraLoggerService();
    public static List<Schema.SObjectType> MY_SOBJECTS = new List<Schema.SObjectType>{
    CS_Record__c.SObjectType,
    Contact.SObjectType,
    Account.SobjectType,
    AccountTeamMember.SobjectType,
    Async_Request__c.SobjectType,
    SBQQ__Quote__c.SobjectType
    };
    Private UnitOfWork uow ;
    Private GS_AccountService.AccountTriggerContext accTrigContext;
    public GS_AccountTriggerHandler() {
    this.oldAccountMap = (Map<Id, Account>) Trigger.oldMap;
    this.newAccountMap = (Map<Id, Account>) Trigger.newMap;
    this.newAccountList = (List<Account>) Trigger.new;
    this.oldAccountList = (List<Account>) Trigger.old;
    accTrigContext = new GS_AccountService.AccountTriggerContext(oldAccountMap, newAccountList, oldAccountList,newAccountMap);
    DMLWrapper.intializeUnitOfWork(MY_SOBJECTS);
    }
    public override void beforeInsert() {
    try {
    //thisSamsaraLoggerService.logger.logTrace('Entering in Account Trigger Before Insert');
    system.debug('RODRIGO GS_A beforeInsert ');
    accTrigContext.handleBeforeOperations();
    accTrigContext.handleBeforeInsertOperations();
    }
    catch (Exception ex){
    thisSamsaraLoggerService.logger.logError(
    'Error in Account Trigger Before Insert::',
    new SamsaraLoggerObjectMVP(
    ex, newAccountList
    )
    );
    throw ex;
    }
    finally {
    thisSamsaraLoggerService.logger.dispatch();
    }
    }
    public override void afterInsert() {
    try {
    //thisSamsaraLoggerService.logger.logTrace('Entering in Account Trigger After Insert');
    accTrigContext.handleAfterInsertOperations();
    }
    catch (Exception ex){
    thisSamsaraLoggerService.logger.logError(
    'Error in Account Trigger After Insert::',
    new SamsaraLoggerObjectMVP(
    ex, newAccountList
    )
    );
    throw ex;
    }
    finally {
    thisSamsaraLoggerService.logger.dispatch();
    }
    }
    public override void beforeUpdate() {
    try {
    //thisSamsaraLoggerService.logger.logTrace('Entering in Account Trigger Before Update');
    system.debug('RODRIGO GS_A beforeInsert ');
    accTrigContext.handleBeforeOperations();
    accTrigContext.handleBeforeUpdateOperations();
    }
    catch (Exception ex){
    thisSamsaraLoggerService.logger.logError(
    'Error in Account Trigger Before Update::',
    new SamsaraLoggerObjectMVP(
    ex, newAccountMap.keySet()
    )
    );
    throw ex;
    }
    finally {
    thisSamsaraLoggerService.logger.dispatch();
    }
    //Webstore
    GS_AccountPrePopulationService.syncAccountsToBigCommerceBeforeUpdate(oldAccountMap, newAccountList);
    }
    public override void afterUpdate() {
    try {
    //thisSamsaraLoggerService.logger.logTrace('Entering in Account Trigger After Update');
    GS_AccountService accountService = new GS_AccountService();
    if (!alreadyRan) {
    accountService.stampLawfulBasisAndCheckIfAccountNeedsCsmOrSeOnUpdate(oldAccountMap, newAccountList);
    alreadyRan = true;
    }
    accTrigContext.handleAfterUpdateOperations();
    GS_AccountPrePopulationService.syncAccountsBillingEmailToNetSuite(oldAccountMap, newAccountList);
    }
    catch (Exception ex){
    thisSamsaraLoggerService.logger.logError(
    'Error in Account Trigger After Update::',
    new SamsaraLoggerObjectMVP(
    ex, newAccountMap.keySet()
    )
    );
    throw ex;
    }
    finally {
    thisSamsaraLoggerService.logger.dispatch();
    }
    //Webstore
    GS_AccountPrePopulationService.syncAccountsToBigCommerce(oldAccountMap, newAccountList);
    }
    public override void beforeDelete() {
    try {
    //thisSamsaraLoggerService.logger.logTrace('Entering in Account Trigger Before Delete');
    accTrigContext.beforeDeleteOperations();
    }
    catch (Exception ex){
    thisSamsaraLoggerService.logger.logError(
    'Error in Account Trigger Before Delete::',
    new SamsaraLoggerObjectMVP(
    ex, oldAccountMap.keySet()
    )
    );
    throw ex;
    }
    finally {
    thisSamsaraLoggerService.logger.dispatch();
    }
    }
    public override void publishDMLs() {
    //thisSamsaraLoggerService.logger.logTrace('Exiting Account Trigger Context');
    uow = DMLWrapper.uow;
    DMLWrapper.publishDML(uow);
    }
    public  Void logerrorMessage( String transactionType ,List<object> objList,Exception ex){
    thisSamsaraLoggerService.logger.logError(
    transactionType,
    new SamsaraLoggerObjectMVP(
    ex,objList
    )
    );
    }
    public  Void logerrorMessageUpdate( String transactionType ,Set<Id> objList,Exception ex){
    thisSamsaraLoggerService.logger.logError(
    transactionType,
    new SamsaraLoggerObjectMVP(
    ex,objList
    )
    );
    }
    }