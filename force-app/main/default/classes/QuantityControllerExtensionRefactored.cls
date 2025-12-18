/* 
 * Class Created: 11/19/18 - Epic SS-63 @author: Harsha
 */

// This class contains code for the ConfirmQuantitiesRefactoredPage.
public with sharing class QuantityControllerExtensionRefactored {

    private ApexPages.StandardController standardOpportutniyController;
    private final Opportunity opportunity;
    public List<Opportunity> trialOpportunitiesList { get; set; } 
    public List<OpportunityLineItem> trialOpportunityLineItems { get; set; }
    public List<OpportunityLineItem> allOpportunityLineItems { get; set; }
    public List<OpportunityLineItem> allFreeTrialOpportunityLineItems { get; set; }
    public List<OpportunityLineItem> allShippedOpportunityLineItems { get; set; }
    public List<OpportunityLineItem> uniqueLineItems{ get; set; }
    public Map<String, Decimal> shipQuantities{ get; set; }
    public Map<Id, Decimal> inputTrialQuantityMap {get; set;}
    public Map<Id, String> shipRevenueOpportunityLocationMap {get; set;}
    Map<String, Map<String, OpportunityLineItem>> detailedNonFreeTrialRevLineItems = new Map<String, Map<String, OpportunityLineItem>>();
    Map<String, Map<String, OpportunityLineItem>> detailedFreeTrialRevLineItems = new Map<String, Map<String, OpportunityLineItem>>();
    private Opportunity currentOpportunity;

    // Constructor initializes most of the variables and call the getDataDuringInitialization which inturn gets and sets most of the data in the page.
    public QuantityControllerExtensionRefactored(ApexPages.StandardController stdController){
        this.standardOpportutniyController = stdController;
        this.opportunity = (Opportunity) stdController.getRecord();
        this.allOpportunityLineItems = new List<OpportunityLineItem>();
        this.allFreeTrialOpportunityLineItems = new List<OpportunityLineItem>();
        this.allShippedOpportunityLineItems = new List<OpportunityLineItem>();
        this.trialOpportunitiesList = new List<Opportunity>();
        this.trialOpportunityLineItems = new List<OpportunityLineItem>();
        this.uniqueLineItems = new List<OpportunityLineItem>();
        this.shipQuantities = new Map<String, Decimal>();
        this.inputTrialQuantityMap = new Map<Id, Decimal>();
        this.shipRevenueOpportunityLocationMap = new Map<Id, String>();

        detailedFreeTrialRevLineItems = MappedRevenueLineItems.mapFreeTrialLines(opportunity);
        detailedNonFreeTrialRevLineItems = MappedRevenueLineItems.mapNonFreeTrialLines(opportunity);

        //system.debug('Detailed Map for free trails ' +detailedFreeTrailRevLineItems);
        //system.debug('Detailed Map for non free trails ' +detailedNonFreeTrailRevLineItems);

        getDataDuringInitialization();
    }

    public void getDataDuringInitialization(){
        List<OpportunityLineItem> allTrialOpportunityLineItems = new List<OpportunityLineItem>();
        // To display only the unique products under 'Opportunity Product - Summary' 
        // Scenario when there are 2 same line items with different quantities 
        // Get the details of the current opportunity.
       currentOpportunity = [SELECT Id, Name, AccountId, StageName, 
                            (SELECT Id, Ship_To_Address_Concatenated__c, Product_Code_Copy__c, 
                                    Ship_From_Location__c, PricebookEntry.Name, Quantity, Discount, Trial_Order_Number__c, Related_Order_Number__c
                                                                                                                    FROM OpportunityLineItems 
                                                                                                                    WHERE (Is_Hardware__c=True OR Is_Accessory__c=True) 
                                                                                                                    AND (NOT Product_Code_Copy__c LIKE '%SHRT%')
                                                                                                                    AND (NOT Product_Code_Copy__c LIKE 'LIC%') 
                                                                                                                    AND (NOT Product_Code_Copy__c LIKE '%KIT%')
                                                                                                                    ORDER BY Product_Code_Copy__c) 
                                                                                                                    FROM Opportunity WHERE Id =: opportunity.Id];
        // Stores all the line items from the opportunity which is either a hardware or accessory  
        allOpportunityLineItems = currentOpportunity.OpportunityLineItems;
        //system.debug('Current Opportunity ' +currentOpportunity);
        //system.debug('Filtered Opportunity Line Items '+allOpportunityLineItems);
        // Get all the trail opportunities that are 'Open' and are of type 'Free Trail Opportunity'.
        trialOpportunitiesList = [SELECT Id, Name, CloseDate, Trial_Status__c, TrialResolutionOppty__c, 
                                 (SELECT Id, Ship_To_Address_Concatenated__c, Opportunity.Name, Opportunity.Id, Product_Code_Copy__c, 
                                 PricebookEntry.Name, Quantity, Purchased_From_Trial__c, To_Purchase_From_Trial__c, Trial_Status__c, Related_Order_Number__c, 
                                 Trial_Order_Number__c, Ship_To__c  FROM OpportunityLineItems
                                                                    WHERE (Is_Hardware__c=True OR Is_Accessory__c=True) 
                                                                    AND (NOT Product_Code_Copy__c LIKE '%SHRT%')
                                                                    AND (NOT Product_Code_Copy__c LIKE 'LIC%') 
                                                                    AND (NOT Product_Code_Copy__c LIKE '%KIT%')
                                                                    ORDER BY Product_Code_Copy__c)
                                                                    FROM Opportunity 
                                                                    WHERE type = 'Free Trial Opportunity' 
                                                                    AND Trial_Status__c = 'Open' 
                                                                    AND StageName = 'Closed Won'
                                                                    AND AccountId =: currentOpportunity.AccountId];
        //system.debug('Open Trail Opportunities ' +trailOpportunitiesList);

        /* Gets all the line items for the current revenue opportunity to display aggregated details under Opportunity Product - Summary section
         * using the List uniqueLineItems.
         * Also populating the maps shipQuantities (to calculate the aggregated quantity) and shipRevenueOpportunityLocationMap. (to get and display
         * the ship from under  Opportunity Product - Details )
         */
        for(OpportunityLineItem lineItem : allOpportunityLineItems){
            if((shipQuantities.size()>0) && (shipQuantities.containsKey(lineItem.Product_Code_Copy__c))){
                Decimal exsistingQuantity = shipQuantities.get(lineItem.Product_Code_Copy__c);
                shipQuantities.put(lineItem.Product_Code_Copy__c, exsistingQuantity + lineItem.Quantity);
                shipRevenueOpportunityLocationMap.put(lineItem.Id, lineItem.Ship_From_Location__c);
            }
            else{
               shipQuantities.put(lineItem.Product_Code_Copy__c, lineItem.Quantity); 
               uniqueLineItems.add(lineItem);
               shipRevenueOpportunityLocationMap.put(lineItem.Id, lineItem.Ship_From_Location__c);
            }
            //system.debug('Before all free trails '+lineItem.Ship_From_Location__c);
            if(lineItem.Ship_From_Location__c == 'Free Trial'){
                allFreeTrialOpportunityLineItems.add(lineItem);
            }
            else{
                allShippedOpportunityLineItems.add(lineItem);
            }
        }
        //system.debug('All free trails '+allFreeTrailOpportunityLineItems);
        // Get all the trail opportunity line items and populate in the list allTrailOpportunityLineItems.
        for(Opportunity trialOpportunity : trialOpportunitiesList){
            allTrialOpportunityLineItems.addAll(trialOpportunity.OpportunityLineItems);
        }
        // From the list allTrailOpportunityLineItems, only lineitems that are not with the trail status as 'Purchased' will be displayed.
        for(OpportunityLineItem uniqueTrialLineItem : allTrialOpportunityLineItems){
            if(uniqueTrialLineItem.Trial_Status__c != 'Purchased'){
                trialOpportunityLineItems.add(uniqueTrialLineItem);
            }
        }
        // Map to get and set the quantities of the trail items that are selected.
        for(OpportunityLineItem trialLineItem : trialOpportunityLineItems){
            inputTrialQuantityMap.put(trialLineItem.id,trialLineItem.Quantity - trialLineItem.Purchased_From_Trial__c);
        }
        //system.debug('Data in Map ' +shipQuantities);
       // system.debug('Data in the Unique List ' +uniqueLineItems);     
    }

    // Get the shipping locations from the custom meta data type 'Shipping Location' and displays in the drop down accordingly. 
    public List<SelectOption> getLocationOption(){
        
        list<SelectOption>  shipFromOptions = new list<SelectOption>();
        List<Shipping_Location__mdt> locationMetaData = [SELECT MasterLabel, Value__c FROM Shipping_Location__mdt]; 
        
        if(locationMetaData.size() > 0){
            for(Shipping_Location__mdt locationData : locationMetaData){
                shipFromOptions.add(new SelectOption(locationData.Value__c, locationData.MasterLabel));
            }
        }
        else{
            shipFromOptions.add(new SelectOption('DCL', 'DCL'));
        }
        return shipFromOptions;
    }

    //This method set the flag to true or false and depending on that the input fields for the quantity are disabled.
    public Boolean getOpportunityStageFlag(){
        Boolean opportunityStageFlag;
        if(currentOpportunity.StageName == 'Closed Won'){
            opportunityStageFlag = true;
        }
        else{
            opportunityStageFlag = false;
        }
        return opportunityStageFlag;
    }

    // This method sets the the count of free trial line items on the vf page
    public Map<String, Decimal> getFreeTrialCount(){
        
        Map<String, Decimal> freeTrialCount = new Map<String, Decimal>();
        
        for(OpportunityLineItem lineItem : allOpportunityLineItems){
            //system.debug('Line Items '+lineItem);
            if(lineItem.Ship_From_Location__c == 'Free Trial'){
                if((freeTrialCount.size()>0) && (freeTrialCount.containsKey(lineItem.Product_Code_Copy__c))){
                    Decimal exsistingQuantity = freeTrialCount.get(lineItem.Product_Code_Copy__c);
                    freeTrialCount.put(lineItem.Product_Code_Copy__c, exsistingQuantity + lineItem.Quantity);
                    //system.debug('In If free tail count map '+freeTrailCount);
                }
                else{
                    freeTrialCount.put(lineItem.Product_Code_Copy__c, lineItem.Quantity); 
                    //system.debug('In else free tail count map '+freeTrailCount);
                }      
            }
            else if((lineItem.Ship_From_Location__c != 'Free Trial') && !(freeTrialCount.containsKey(lineItem.Product_Code_Copy__c))){
                freeTrialCount.put(lineItem.Product_Code_Copy__c, 0.00); 
                //system.debug('In outside else free tail count map '+freeTrailCount);
            }
        }
        //system.debug('Final free trail count '+freeTrailCount);
        return freeTrialCount;
    }

    // This method sets the the count of non free trial line items on the vf page
    public Map<String, Decimal> getNonFreeTrialCount(){
        
        Map<String, Decimal> nonFreeTrialCount = new Map<String, Decimal>();
        
        for(OpportunityLineItem lineItem : allOpportunityLineItems){
            if(lineItem.Ship_From_Location__c != 'Free Trial'){
                if((nonFreeTrialCount.size()>0) && (nonFreeTrialCount.containsKey(lineItem.Product_Code_Copy__c))){
                    Decimal exsistingQuantity = nonFreeTrialCount.get(lineItem.Product_Code_Copy__c);
                    nonFreeTrialCount.put(lineItem.Product_Code_Copy__c, exsistingQuantity + lineItem.Quantity);
                }
                else{
                    nonFreeTrialCount.put(lineItem.Product_Code_Copy__c, lineItem.Quantity); 
                }      
            }
            else if((lineItem.Ship_From_Location__c == 'Free Trial') && !(nonFreeTrialCount.containsKey(lineItem.Product_Code_Copy__c))){
                nonFreeTrialCount.put(lineItem.Product_Code_Copy__c, 0.00); 
            }
        }
        return nonFreeTrialCount;
    }
    
    // This method has the functionality for the Submit function on the VF page
    public PageReference submit(){

        Map<Id, OpportunityLineItem> updatedTrialLineItemsList = new Map<Id, OpportunityLineItem>();

        for(OpportunityLineItem exsistingTrialLineItem : trialOpportunityLineItems){
            OpportunityLineItem relatedNonFreeTrial = new OpportunityLineItem();
            if((inputTrialQuantityMap.containsKey(exsistingTrialLineItem.Id) && (inputTrialQuantityMap.get(exsistingTrialLineItem.Id) <= exsistingTrialLineItem.Quantity))){  
                Decimal selectedQuantity = inputTrialQuantityMap.get(exsistingTrialLineItem.Id);
                exsistingTrialLineItem.Purchased_From_Trial__c = exsistingTrialLineItem.Purchased_From_Trial__c + selectedQuantity;
                exsistingTrialLineItem.To_Purchase_From_Trial__c = exsistingTrialLineItem.Quantity - exsistingTrialLineItem.Purchased_From_Trial__c;
                if(detailedNonFreeTrialRevLineItems.containsKey(exsistingTrialLineItem.Ship_To__c)){
                    Map<String, OpportunityLineItem> revLineItemMap = detailedNonFreeTrialRevLineItems.get(exsistingTrialLineItem.Ship_To__c);
                        if(revLineItemMap.containsKey(exsistingTrialLineItem.Product_Code_Copy__c)){
                            relatedNonFreeTrial = revLineItemMap.get(exsistingTrialLineItem.Product_Code_Copy__c);
                        }
                }  
                //system.debug('Related non free trail' +relatedNonFreeTrial.Id);
                if(relatedNonFreeTrial.Id != null){
                    if((inputTrialQuantityMap.get(exsistingTrialLineItem.Id) > relatedNonFreeTrial.Quantity) || (exsistingTrialLineItem.Purchased_From_Trial__c > relatedNonFreeTrial.Quantity + exsistingTrialLineItem.Purchased_From_Trial__c)){
                        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Please check the quantity for the trial line item ' +exsistingTrialLineItem.PricebookEntry.Name + '.You cannot have the quantity greater than the corresponding revenue line item units. Please click the \'Refresh\' button before making any changes and submitting the quantities again.' ));
                        return null;
                    }
                    if(exsistingTrialLineItem.To_Purchase_From_Trial__c == 0){
                        exsistingTrialLineItem.Trial_Status__c = 'Purchased';
                    }
                    if(exsistingTrialLineItem.To_Purchase_From_Trial__c < 0){
                        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Please check the quantity for the trial line item ' +exsistingTrialLineItem.PricebookEntry.Name + '.You cannot have the quantity greater than the available trial units. Please click the \'Refresh\' button before making any changes and submitting the quantities again.' ));
                        return null;
                    } 
                    /*else if((exsistingTrailLineItem.Purchased_From_Trial__c > shipQuantities.get(exsistingTrailLineItem.Product_Code_Copy__c) && (shipQuantities.get(exsistingTrailLineItem.Product_Code_Copy__c) > 0))){
                        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Please check the quantity for the trail line item ' +exsistingTrailLineItem.PricebookEntry.Name + '.You cannot select trail quantity greater than total quantity on the corresponding revenue line item.' ));
                        return null;
                    }*/
                    //system.debug('Trail line items in the list '+exsistingTrailLineItem);
                    updatedTrialLineItemsList.put(exsistingTrialLineItem.Id, exsistingTrialLineItem);
                    //system.debug('In get Input Quantities '+inputTrailQuantityMap.get(exsistingTrailLineItem.Id));
                }
                else if((relatedNonFreeTrial.Id == null) && (inputTrialQuantityMap.get(exsistingTrialLineItem.Id) > 0)){
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'You cannot select the quantity for the for the trial\'s that are not present in the revenue opportunity. Please make the quantitiy to 0. Do click the \'Refresh\' button before making any changes and submitting the quantities again.'));
                    return null;
                }
            }
            else{
                //system.debug('In get Input Quantities else part');
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Please check the quantity for the trial line item ' +exsistingTrialLineItem.PricebookEntry.Name + '.You cannot have the quantity greater than the available trial units. Please click the \'Refresh\' button before making any changes and submitting the quantities again.' ));
                return null;
            }
        }

        //system.debug('Befrore updating trail line items '+updatedTrailLineItemsList.values());
        update updatedTrialLineItemsList.values();
        //Test
        updateRevenueLineItems(updatedTrialLineItemsList);

           // system.debug('Input Revenue Ship TO Location '+shipRevenueOpportunityLocationMap);
           // system.debug('Input Trail Quantity Map ' +inputTrailQuantityMap);

            return ApexPages.hasMessages() ? null : new PageReference('/'+opportunity.id);
    
    }

    /* This method has the functionality to update the revenue line items.
     * Either creating new free trail revenue line items
     * Updating exsisiting free trail revenue line items
     * Updating the exsisiting revenue line items
     */
    public void updateRevenueLineItems(Map<Id, OpportunityLineItem> updatedTrialLineItemsList){

        //system.debug('In update revenue line items');
        
        List<OpportunityLineItem> deletedLineItems = new List<OpportunityLineItem>();
        List<OpportunityLineItem> lineItems = new List<OpportunityLineItem>();
        //Set <OpportunityLineItem> lineItemsWithShipFrom = new Set <OpportunityLineItem>();
        //List <OpportunityLineItem> updatedLineItemsWithShipFrom = new List <OpportunityLineItem>();
        Map<Id, OpportunityLineItem> updatedLineItems = new Map<Id, OpportunityLineItem>();



        for(OpportunityLineItem updatedTrialLineItem : updatedTrialLineItemsList.values()){
            OpportunityLineItem associatedNonFreeTrial;
            OpportunityLineItem freeTrialRevLine = new OpportunityLineItem();
            OpportunityLineItem exsistingFreeTrialRevLine = new OpportunityLineItem();
            Boolean containsFreeTrialLineItem;

            //system.debug('Updated Trail Line items '+updatedTrailLineItem);
            //system.debug('Data in the Map '+detailedNonFreeTrailRevLineItems);
                                            /*OpportunityLineItem new_li = new OpportunityLineItem (Quantity=inputQuantityMap.get(trial_li.Id), Shipped_Quantity__c=0.00, OpportunityId=oppty.Id, PriceBookEntryId=trial_li.PriceBookEntryId, Discount=rev_li.Discount, UnitPrice=rev_li.ListPrice, Ship_From_Location__c='Free Trial');*/
            
            if(detailedNonFreeTrialRevLineItems.containsKey(updatedTrialLineItem.Ship_To__c)){
                Map<String, OpportunityLineItem> revLineItemMap = detailedNonFreeTrialRevLineItems.get(updatedTrialLineItem.Ship_To__c);
                if(revLineItemMap.containsKey(updatedTrialLineItem.Product_Code_Copy__c)){
                    associatedNonFreeTrial = revLineItemMap.get(updatedTrialLineItem.Product_Code_Copy__c);
                    //system.debug('Associated non free trail is '+associatedNonFreeTrail);
                }
            }

            if(detailedFreeTrialRevLineItems.containsKey(updatedTrialLineItem.Ship_To__c)){
                Map<String, OpportunityLineItem> revFreeTrialLineItemMap = detailedFreeTrialRevLineItems.get(updatedTrialLineItem.Ship_To__c);
                if(revFreeTrialLineItemMap.containsKey(updatedTrialLineItem.Product_Code_Copy__c)){
                    exsistingFreeTrialRevLine = revFreeTrialLineItemMap.get(updatedTrialLineItem.Product_Code_Copy__c);
                    containsFreeTrialLineItem = true;
                    //system.debug('Associated free trail is '+exsistingFreeTrailRevLine);
                }
                else{
                    containsFreeTrialLineItem = false;
                }
            }

            if((detailedFreeTrialRevLineItems.size() == 0) || (!detailedFreeTrialRevLineItems.containsKey(updatedTrialLineItem.Ship_To__c))
            || (!containsFreeTrialLineItem)) {
              //18system.debug('In the problem if condition');
              freeTrialRevLine.OpportunityId = opportunity.id;
              freeTrialRevLine.Shipped_Quantity__c = 0.00;
              freeTrialRevLine.PriceBookEntryId = updatedTrialLineItem.PriceBookEntryId;
              freeTrialRevLine.Discount = associatedNonFreeTrial.Discount;
              freeTrialRevLine.UnitPrice = associatedNonFreeTrial.ListPrice;
              freeTrialRevLine.Quantity = updatedTrialLineItem.Purchased_From_Trial__c;
              freeTrialRevLine.Ship_From_Location__c='Free Trial';
              freeTrialRevLine.Trial_Order_Number__c = updatedTrialLineItem.Related_Order_Number__c;
              freeTrialRevLine.Ship_To__c = updatedTrialLineItem.Ship_To__c;
              //system.debug('New Free trail to add '+freeTrailRevLine);
              lineItems.add(freeTrialRevLine);
            }
            else{
                /*if(detailedFreeTrailRevLineItems.containsKey(updatedTrailLineItem.Ship_To_Address_Concatenated__c)){
                    //Test
                    Map<String, OpportunityLineItem> revFreeTrailLineItemMap = detailedFreeTrailRevLineItems.get(updatedTrailLineItem.Ship_To_Address_Concatenated__c);
                        if(revFreeTrailLineItemMap.containsKey(updatedTrailLineItem.Product_Code_Copy__c)){
                            exsistingFreeTrailRevLine = revFreeTrailLineItemMap.get(updatedTrailLineItem.Product_Code_Copy__c);
                            system.debug('Associated free trail is '+exsistingFreeTrailRevLine);
                        }
                } */

                //Added this condition to have multiple trail order numbers if they are are added from different trail line items 
                try{
                    if(!exsistingFreeTrialRevLine.Trial_Order_Number__c.contains(updatedTrialLineItem.Related_Order_Number__c)){
                        exsistingFreeTrialRevLine.Trial_Order_Number__c = exsistingFreeTrialRevLine.Trial_Order_Number__c+';'+updatedTrialLineItem.Related_Order_Number__c;
                    }
                }
                catch(NullPointerException e){
                    system.debug('There is no data in the respective lists ' +e.getMessage());
                }
                

                
                //exsistingFreeTrialRevLine.Quantity = updatedTrialLineItem.Purchased_From_Trial__c;
                //This line handles the count of exsisting free trail line items
                exsistingFreeTrialRevLine.Quantity = exsistingFreeTrialRevLine.Quantity + inputTrialQuantityMap.get(updatedTrialLineItem.Id);
                exsistingFreeTrialRevLine.UnitPrice = associatedNonFreeTrial.ListPrice;
                //system.debug('Exsisting free trail rev line before added to the list '+exsistingFreeTrailRevLine);
                lineItems.add(exsistingFreeTrialRevLine);
            }

            if(associatedNonFreeTrial != null){
                //Error is occuring in this line
                //associatedNonFreeTrail.Quantity = associatedNonFreeTrail.Quantity - updatedTrailLineItem.Purchased_From_Trial__c;
                associatedNonFreeTrial.Quantity = associatedNonFreeTrial.Quantity - inputTrialQuantityMap.get(updatedTrialLineItem.Id);
                associatedNonFreeTrial.UnitPrice = associatedNonFreeTrial.ListPrice;
                //system.debug('Ship To is '+shipRevenueOpportunityLocationMap.get(associatedNonFreeTrail.id));
                associatedNonFreeTrial.Ship_From_Location__c = shipRevenueOpportunityLocationMap.get(associatedNonFreeTrial.id);
                   if(associatedNonFreeTrial.Quantity == 0){
                        deletedLineItems.add(associatedNonFreeTrial);
                    }
                    else{
                        updatedLineItems.put(associatedNonFreeTrial.Id, associatedNonFreeTrial);
                    }
                }
            
            /*if( detailedFreeTrailRevLineItems.get(updatedTrailLineItem.Ship_To_Address_Concatenated__c).get(updatedTrailLineItem.Product_Code_Copy__c) != null){
                            OpportunityLineItem relatedFreeTrailRevenueLineItem = detailedFreeTrailRevLineItems.get(updatedTrailLineItem.Ship_To_Address_Concatenated__c).get(updatedTrailLineItem.Product_Code_Copy__c);
                                        system.debug('Related Rli for free trails ' +relatedFreeTrailRevenueLineItem);

            }

            //Test


            if(detailedNonFreeTrailRevLineItems.get(updatedTrailLineItem.Ship_To_Address_Concatenated__c).get(updatedTrailLineItem.Product_Code_Copy__c) != null){
                    OpportunityLineItem relatedNonFreeTrailRevenueLineItem = detailedNonFreeTrailRevLineItems.get(updatedTrailLineItem.Ship_To_Address_Concatenated__c).get(updatedTrailLineItem.Product_Code_Copy__c);
                                system.debug('Related Rli for non free trails ' +relatedNonFreeTrailRevenueLineItem);*/

                                        /*for(OpportunityLineItem revOpportunityLineItem : allOpportunityLineItems){
            for(OpportunityLineItem updatedTrailLineItem : updatedTrailLineItemsList.values()){
                if((revOpportunityLineItem.Product_Code_Copy__c == updatedTrailLineItem.Product_Code_Copy__c) && (updatedTrailLineItem.Purchased_From_Trial__c > 0) && (updatedTrailLineItem.Purchased_From_Trial__c < revOpportunityLineItem.Quantity)){
                    Decimal newQuantity=revOpportunityLineItem.Quantity-updatedTrailLineItem.Purchased_From_Trial__c;
                    OpportunityLineItem newRevenueOpportunityLineItem = new OpportunityLineItem();
                    if(newQuantity > 0){
                            revOpportunityLineItem.Quantity = newQuantity;
                            revOpportunityLineItem.UnitPrice = revOpportunityLineItem.ListPrice;
                            //newRevenueOpportunityLineItem.Quantity = 
                    }
                    else if(newQuantity == 0){

                    }
                }
            }
        }*/
        }

        for(OpportunityLineItem revenueLine : allOpportunityLineItems){
            //system.debug('Line Item ' +revenueLine);
            if(!updatedLineItems.containsKey(revenueLine.Id)){

            String shipFrom = shipRevenueOpportunityLocationMap.get(revenueLine.id);
            //system.debug('Ship From before '+shipFrom);
            if(revenueLine.Ship_From_Location__c != shipFrom){
                    //system.debug('Ship From '+shipFrom);
                    revenueLine.Ship_From_Location__c = shipFrom;
                    updatedLineItems.put(revenueLine.id,revenueLine);
                }
            }
            }

        //system.debug('Before upsert '+lineItems);
        if(lineItems.size()>0){
            upsert lineItems;
        }
        //system.debug('Before update '+lineItemsWithShipFrom);
        if(updatedLineItems.size() > 0){
            update updatedLineItems.values();
        }
        if(deletedLineItems.size()>0){
            delete deletedLineItems;
        }
    }

    // This method have the code for the refresh button on the vf page
    public PageReference refresh(){
        PageReference pageReference =  ApexPages.currentPage();
        pageReference.setRedirect(true);
        return pageReference;
    }

    //This method have the code for the back to opportunity button on the vf page
    public PageReference returnToOpportunity(){
        PageReference pageReference =  new pageReference('/'+opportunity.id);
        return pageReference;
    }

}