global class PopulateOwnerAVPonOpportunities implements Database.Batchable<SObject> {
    global Database.QueryLocator start(Database.BatchableContext BC) {
        String query = 'SELECT Id,OwnerId,Owner.Manager.Name,Owner.Manager.Manager.Name,Owner.Manager.Manager.Manager.Name,Owner.Manager.UserRole.Name,Owner.Manager.Manager.UserRole.Name,Owner.Manager.Manager.Manager.UserRole.Name,Owner.Manager.Sales_User_Type__c,Owner.Manager.Manager.Sales_User_Type__c,Owner.Manager.Manager.Manager.Sales_User_Type__c FROM Opportunity WHERE Type = \'Revenue Opportunity\' and StageName != \'Closed Won\' and Type != \'Closed Lost\' and owner.managerid != null';
        system.debug('***'+Database.getQueryLocator(query));
        return Database.getQueryLocator(query);
        
    }
    global void execute(Database.BatchableContext BC, List<Opportunity> scope) {
        system.debug('****'+scope);
        try {
            List<Opportunity> opptiesToUpdate = new List<Opportunity>();
            for(Opportunity oppty: scope){
                system.debug('*******Owner_AVP_Name_Copy__c'+oppty.Owner.Manager.Name);
                    oppty.Owner_AVP_Name_Copy__c = oppty.Owner.Manager.Sales_User_Type__c != null ? oppty.Owner.Manager.Name : (oppty.Owner.Manager.Manager.Sales_User_Type__c != null ? oppty.Owner.Manager.Manager.Name :oppty.Owner.Manager.Manager.Manager.Name);
                    oppty.Owner_AVP_Role_Copy__c = oppty.Owner.Manager.Sales_User_Type__c != null ? oppty.Owner.Manager.UserRole.Name : (oppty.Owner.Manager.Manager.Sales_User_Type__c != null ? oppty.Owner.Manager.Manager.UserRole.Name :oppty.Owner.Manager.Manager.Manager.UserRole.Name);
                    oppty.Owner_AVP_Team__c = oppty.Owner.Manager.Sales_User_Type__c != null ? oppty.Owner.Manager.Sales_User_Type__c : (oppty.Owner.Manager.Manager.Sales_User_Type__c != null ? oppty.Owner.Manager.Manager.Sales_User_Type__c :(oppty.Owner.Manager.Manager.Manager.Sales_User_Type__c != null ? oppty.Owner.Manager.Manager.Manager.Sales_User_Type__c :''));
                    opptiesToUpdate.add(oppty);
            }
            if(opptiesToUpdate.size() > 0){
                update opptiesToUpdate;
            }
        } 
        catch(Exception e) {
            system.debug('Errors'+e);
        }        
    }
    
    global void finish(Database.BatchableContext BC) {
        
    }
}