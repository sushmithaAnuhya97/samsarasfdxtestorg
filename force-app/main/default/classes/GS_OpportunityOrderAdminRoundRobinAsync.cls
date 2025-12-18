/**
 * Created by Tanuj Tyagi on 2021-09-16.
 */
public with sharing class GS_OpportunityOrderAdminRoundRobinAsync extends BaseAsyncHandler {
    public SamsaraLoggerService thisSamsaraLoggerService = new SamsaraLoggerService();

    public override String getRequestType(){
        return 'OpportunityOrderAdminRoundRobin Async Job';
    } 
    
    List<Schema.SObjectType> MY_SOBJECTS = new List<Schema.SObjectType>{
        User.SObjectType
        };
    
    /* UnitOfWork uow = new UnitOfWork(MY_SOBJECTS); */
    List<Id> recordsIds = new List<Id>();
    Map<Id, User> userList;

    public override void execute(Async_Request__c ar){

        recordsIds = ar.Params__c.split(PARAMETERS_SPLITTER);
        if(recordsIds.isEmpty()) return;

        DMLWrapper.intializeUnitOfWork(MY_SOBJECTS);
        
        try{
        thisSamsaraLoggerService.logger.logTrace('Entering in GS_OpportunityOrderAdminRoundRobinAsync');
        this.loadRecords(recordsIds);

        this.orderAdminRoundRobin();

        this.publishDMLs();
        }catch(Exception ex){
            thisSamsaraLoggerService.logger.logError('Error in GS_OpportunityOrderAdminRoundRobinAsync::', new SamsaraLoggerObjectMVP(
                ex, recordsIds
        ));
            throw ex;
        }
        finally {
            thisSamsaraLoggerService.logger.logTrace('Exiting in GS_OpportunityOrderAdminRoundRobinAsync');
            thisSamsaraLoggerService.logger.dispatch();
        }
    }

    private void loadRecords(List<Id> idList){
        if (this.userList == null || this.userList.isEmpty()){
            this.userList = (new GS_UserSelector(false)).getUserMapByIds(new Set<Id>(idList));
        }
    }


    private void orderAdminRoundRobin(){
        for(User userObj : this.userList.values()) {
            userObj.Order_Admin_Oppty_Date__c = System.now();
            DMLWrapper.doUpdate(userObj, new List<SobjectField>{
                User.Order_Admin_Oppty_Date__c
            });
        }
    }


    private void publishDMLs() {
        DMLWrapper.publishDML();
    }
    

    public void orderAdminRoundRobin(Map<Id, Opportunity> oldOppMap, List<Opportunity> newOppList) {

        Set<Id> updateUsersId = new Set<Id>();
        Map<Id, Opportunity> roundRobinThese = new Map<Id, Opportunity>();
        Map<Id, User> updateUsers = new Map<Id, User>();
        List<User> usersUK = new List<User>();
        List<User> usersUS = new List<User>();
        List<Shipping_Countries__mdt> lstShipCtry = [SELECT Country__c, Ship_From_Location__c FROM Shipping_Countries__mdt];
        List<String> lstShipCountries = new List<String>();
        Map<String, Shipping_Countries__mdt> shipFromMap = new Map<String, Shipping_Countries__mdt>();
        for (Shipping_Countries__mdt country : lstShipCtry) {
            lstShipCountries.add(country.Country__c);
            shipFromMap.put(country.Country__c, country);
        }

        // Query round robin-able users, if necessary
        for (Opportunity oppty : newOppList) {
            if (oppty.Type == 'Revenue Opportunity' 
                || oppty.Type == 'Promo Opportunity' 
                || oppty.Type == 'Free Trial Opportunity') {
                if (oppty.Order_Admin__c == NULL 
                    && oppty.Probability == 98 
                    && (oldOppMap.get(oppty.Id).Probability != oppty.Probability)) {
                    roundRobinThese.put(oppty.Id, oppty);
                }
            }
        }

         // If we don't need to assign any users, don't do anything else.
         if (roundRobinThese.size() > 0) {
             // Query eligible users (up to the number that we need)
            List<User> eligibleUsers = new GS_UserSelector(true).checkFatalError().getOrderAdminAvailableUser();
            if (eligibleUsers.size() == 0) {
                eligibleUsers = new GS_UserSelector(true).checkFatalError().getOrderAdminFallbackUser();
            }
            for (User user : eligibleUsers) {
                if (user.Entity__c == 'Samsara UK') {
                    usersUK.add(user);
                } else {
                    usersUS.add(user);
                }
            }
            //Two variables to track the total number of users in each region
            Integer countUS = 0;
            Integer countUK = 0;
            for (Opportunity opp : roundRobinThese.values()) {
                //assigning users based on Shipping Countryx
                string shipFromLocation = shipFromMap.get(opp.Shipping_Country__c).Ship_From_Location__c;
                if (opp.Shipping_Country__c != null && (shipFromLocation == 'VCK' || shipFromLocation == 'Samsara UK') && !usersUK.isEmpty()) {
                    opp.Order_Admin__c = usersUK[countUK].Id;
                    updateUsersId.add(usersUK[countUK].Id);
                    countUK++;
                    countUK = (countUK >= usersUK.size()) ? 0 : countUK;
                } else if (!usersUS.isEmpty()) {
                    opp.Order_Admin__c = usersUS[countUS].Id;
                    updateUsersId.add(usersUS[countUS].Id);
                    countUS++;
                    countUS = (countUS >= usersUS.size()) ? 0 : countUS;
                }
            }
            if (!updateUsersId.isEmpty()) {
                DMLWrapper.doInsert(new GS_OpportunityOrderAdminRoundRobinAsync().prepareAsyncRequests(updateUsersId));
              }
            }
         }
}