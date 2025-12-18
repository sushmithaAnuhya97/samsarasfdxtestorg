public class TrialOpptyUpdater {

    // Avoid recursion
    public static Boolean isRecurse = false;
    
    public static void handleTrialUpdate(Map<Id, Opportunity> oldOppMap, List<Opportunity> newOppList) {    
        // System.debug('newOppList = ' + newOppList);
        // Takes a list of Trial oppties with Stage or Resolution Pointer updates, and updates Trial Status in place
        List<Id> trialResolutionOppIdSet = new List<Id>();
        List<Opportunity> trialUpdateList = new List<Opportunity>();
        for (Opportunity o : newOppList) {
            if(o.Type == 'Free Trial Opportunity') {
                if(oldOppMap != NULL) {
                    if( o.TrialResolutionOppty__c != oldOppMap.get(o.Id).TrialResolutionOppty__c ||
                        o.StageName != oldOppMap.get(o.Id).StageName) {
                            trialUpdateList.add(o);
                            trialResolutionOppIdSet.add(o.TrialResolutionOppty__c);
                    }
                } else {
                    trialUpdateList.add(o);
                    trialResolutionOppIdSet.add(o.TrialResolutionOppty__c);
                }
            }
        }
        Map<ID,Opportunity> resolutions = NULL;
        if (trialResolutionOppIdSet != NULL) {        
            resolutions = new Map<ID,Opportunity>([SELECT Id, Trial_Status__c, Free_Trial_Purchase__c, StageName, Type, isWon, Probability FROM Opportunity WHERE Id in :trialResolutionOppIdSet]);
        }
        for (Opportunity o : trialUpdateList) {
            if (o.TrialResolutionOppty__c == NULL) {
                // No resolution pointer, set status based on Stage
                if (o.StageName == 'Closed Won') {
                    o.Trial_Status__c = 'Open';
                } else {
                    o.Trial_Status__c = 'Not Shipped';
                }
            } else if (o.StageName != 'Closed Won') {
                // ignore resolution pointer if trial hasn't shipped
                o.Trial_Status__c = 'Not Shipped';
            } else {
                Opportunity res = resolutions.get(o.TrialResolutionOppty__c);
                if (res != Null) {
                    
                    if(o.StageName == 'Closed Won'){
                        o.Trial_Status__c='Open';
                    }
                    
                    String newStatus=getStatusFromResolution(res);
                    if(String.isBlank(newStatus)){
                        newStatus=o.Trial_Status__c;
                    }
                    
                    o.Trial_Status__c = newStatus;
                }
            }
        }
    }
    
    public static void handleRevenueUpdate(Map<Id, Opportunity> oldOppMap, Map<Id, Opportunity> newOppMap) {
        // Takes a list of Revenue oppties with Stage changes, and updates any trial oppties that point to them
        List<Opportunity> trials = new List<Opportunity>();

        // Here's the logic from what was originally the handleRevenueUpdate method combined with the error handling from the trigger
        // Check if we have any opps that meet query criteria. This should be broken out into a method of the opp helper class.
        List<Opportunity> updates = new List<Opportunity>();
        Boolean needToQuery = FALSE;
        for(Opportunity o : newOppMap.values()) {
            if((o.type == 'Revenue Opportunity' || o.type == 'Revenue Opportunity - Bill Only') && o.StageName != oldOppMap.get(o.Id).StageName) {
                needToQuery = TRUE;
                break;
            }
        }
        
        // Query all associated trials
        Map<Id, Opportunity> trialOppMap = new Map<Id, Opportunity>();

        if(needToQuery) {
            trialOppMap = new Map<Id, Opportunity>([SELECT Id, TrialResolutionOppty__c, Trial_Status__c, Free_Trial_Purchase__c, StageName 
                                                    FROM Opportunity 
                                                    WHERE type = 'Free Trial Opportunity' 
                                                    AND TrialResolutionOppty__c IN :newOppMap.keySet()]);
        }

        // Map rev opps to associated trials
        Map<Id, List<Opportunity>> revToTrialOppsMap = new Map<Id, List<Opportunity>>();
        for(Opportunity t : trialOppMap.values()) {
            // If this trial hasn't been mapped to any rev opps yet, we create a new list with this rev opp and map it to the trial
            if(!revToTrialOppsMap.containsKey(t.TrialResolutionOppty__c) && t.TrialResolutionOppty__c != NULL) {
                List<Opportunity> trialOpps = new List<Opportunity>();
                trialOpps.add(t);
                revToTrialOppsMap.put(t.TrialResolutionOppty__c, trialOpps);
            // If this trial has been mapp to a rev opp already, add this rev opp to the list of mapped opps on this trial
            } else if(revToTrialOppsMap.containsKey(t.TrialResolutionOppty__c)) {
                List<Opportunity> trialOpps = revToTrialOppsMap.get(t.TrialResolutionOppty__c);
                trialOpps.add(t);
                revToTrialOppsMap.put(t.TrialResolutionOppty__c, trialOpps);
            }
        }

        // Now we do the work
        try {
            // Loop through all rev opps
            for (Opportunity o : newOppMap.values()) {
                if((o.type == 'Revenue Opportunity' || o.type == 'Revenue Opportunity - Bill Only') && o.StageName != oldOppMap.get(o.Id).StageName) {
                    if(revToTrialOppsMap.containsKey(o.Id)) {
                        for(Opportunity t : revToTrialOppsMap.get(o.Id)) {
                            if(t.Trial_Status__c == 'Open') {
                                if(o.Probability == 0 && oldOppMap.get(o.Id).Probability > 0) {
                                    if(!FeatureManagement.checkPermission('NetSuite_Service_User_Permission')) {
                                        o.addError('You are trying to close a revenue opportunity that already contains one or more unclosed trials. Please close them by ensuring the return of the products.');
                                    }                                    
                                    continue;
                                }
                            }
                            // Loop through all associated trial opps with this rev opp
                            if(t.Trial_Status__c != 'Returned' && t.Trial_Status__c != 'Purchased') {
                                String newStatus = getStatusFromResolution(o);                            
                                if(String.isBlank(newStatus)){
                                    newStatus=t.Trial_Status__c;
                                }                    
                                if (newStatus != t.Trial_Status__c) {
                                    t.Trial_Status__c = newStatus;
                                    //updates.add(t);
                                    DMLWrapper.doUpdate(t, new List<SobjectField>{
                                            Opportunity.Trial_Status__c
                                    });
                                }
                            }
                        }
                    }
                }
            }
            /*if (!updates.isEmpty()) {
                update updates;
                //DMLWrapper.doUpdate(updates);
            }*/
        }
        catch(Exception e) {
            System.debug('Error! ' + e);
        }
    }

    public static void handleReturnUpdate(Map<Id, Opportunity> oldOppMap, Map<Id, Opportunity> newOppMap) {
        // Takes a list of Return oppties with Stage changes, and updates any trial oppties that point to them
        List<Opportunity> updates = new List<Opportunity>();
        List<Opportunity> returnUpdates = new List<Opportunity>();
        for(Opportunity o : newOppMap.values()) {
            if((o.type == 'Free Trial Return') && o.StageName != oldOppMap.get(o.Id).StageName) {
                returnUpdates.add(o);
            }
        }
        List<Opportunity> trials = new List<Opportunity>();
        if(returnUpdates.size() > 0) {
            trials = new List<Opportunity>([SELECT Id, Returning_Opportunity__c, Trial_Status__c, StageName  
                                            FROM Opportunity 
                                            WHERE Type = 'Free Trial Opportunity' 
                                            AND Trial_Status__c NOT IN ('Returned','Purchased') 
                                            AND FT_Return__c IN :returnUpdates]);
        }                                               
       
        // System.debug('trying to update trial status based on return change');
        // System.debug(trials);
       
        for (Opportunity o : returnUpdates) {
            for (Opportunity t : trials) {
                if (o.Returning_Opportunity__c == t.Id) {
                    // System.debug('Paso1');
                    String newStatus = getStatusFromResolution(o);
                    // System.debug(newStatus);
                    
                    if(String.isBlank(newStatus)){
                        newStatus=t.Trial_Status__c;
                    }
                    
                    
                    if (newStatus != t.Trial_Status__c) {
                        // System.debug(LoggingLevel.INFO, 'nuevo: '+ t.Trial_Status__c +' viejo:'+newStatus);
                        t.Trial_Status__c = newStatus;
                        //updates.add(t);
                        DMLWrapper.doUpdate(t, new List<SobjectField>{
                                Opportunity.Trial_Status__c
                        });
                    }
                }
            }
        }
        /*if (!updates.isEmpty()) {
            update updates;
            //DMLWrapper.doUpdate(updates);
        }*/
    }

 
    
    public static void disconnectTrialsFromDeletes(Map<Id, Opportunity> ops) {
        // Takes a list of Revenue or Return oppties being deleted, and updates status of any Trial records that point to them       
        Set<Id> deleteIds = new Set<Id>();
        for(Opportunity o : ops.values()) {
            if(o.Type == 'Revenue Opportunity' || o.Type == 'Free Trial Return' || o.Type == 'Revenue Opportunity - Bill Only') {
                deleteIds.add(o.Id);
            }
        }
        List<Opportunity> trials = new List<Opportunity>([SELECT Id, TrialResolutionOppty__c FROM Opportunity WHERE 
                                                         TrialResolutionOppty__c IN :deleteIds]);                                               
        for (Opportunity o : trials) {
            // Clear pointer. Status will be set on resulting update trigger.
            o.TrialResolutionOppty__c = Null;
            DMLWrapper.doUpdate(o, new List<SobjectField>{
                    Opportunity.TrialResolutionOppty__c
            });
        }
        /*if(trials.size() > 0) {
            update trials;
            //DMLWrapper.doUpdate(trials);
        }*/
    }
    
    
    private static String getStatusFromResolution(Opportunity res) {
        String stage = null;
        // Determines trial status based on resolution state        
        if (res.type == 'Revenue Opportunity' || res.type == 'Revenue Opportunity - Bill Only') {
            if (res.StageName == 'Closed Won') {
                stage = 'Purchased';
                if(res.Trial_Status__c == 'Partial Buy' || res.Free_Trial_Purchase__c == 'Partial Buy') {
                    stage = 'Partial Purchase';
                }
            } 
        }
        if (res.type == 'Free Trial Return') {      
            stage = 'Open';
            if (res.Probability == 100) {
                stage = 'Returned';
            } else if (res.Probability > 0) {
                stage = 'Return In Process';
            }
            if(res.Trial_Status__c == 'Partial Buy' || res.Free_Trial_Purchase__c == 'Partial Buy') {
                stage = 'Partial Return';
            }
        }    
        return stage;    
    }
    
    public static void handleReturnCreation(Map<Id, Opportunity> opsMap) {
        // Takes a list of return oppties being created and assign its object as a pointer for the trials
        List<Opportunity> trialUpdates = new List<Opportunity>();

        // Create a set of all connected returning opp Ids
        for (Opportunity o : opsMap.values()) {
            if (o.Type == 'Free Trial Return' && o.Returning_Opportunity__c != NULL) {
                System.debug(LoggingLevel.INFO, 'test: ' + o);
                // Add return opp to updateList after constructing
                /*trialUpdates.add(new Opportunity(Id = o.Returning_Opportunity__c,
                        FT_Return__c = o.Id));*/
                Opportunity returningOpportunity = new Opportunity(Id = o.Returning_Opportunity__c,
                        FT_Return__c = o.Id);
                DMLWrapper.doUpdate(returningOpportunity, new List<SobjectField>{
                        Opportunity.FT_Return__c
                });
            }
        }
        //update trialUpdates;
        //DMLWrapper.doUpdate(trialUpdates);
    }
    
}