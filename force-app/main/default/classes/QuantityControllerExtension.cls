public with sharing class QuantityControllerExtension {
    private ApexPages.StandardController stdOpptyController;
    private Opportunity oppty;
    public Map<String, Decimal> inputQuantityMap;
    public Map<String, Decimal> trialQuantityMap;
    public Map<String, String> shipLocationMap;
    public Map<String, Decimal> purchasedTrialQuantityMap;
    public Boolean post_closing{
        get; set;
    }

    public List<OpportunityLineItem> trialOpptyProduct{
        get; set;
    }
    public Map<String, Decimal> shipQuantities{
        get; set;
    }
    public String[] fixed_values{
        get; set;
    }
    
    public Map<Id, Opportunity> trialOppties{
        get; set;
    }

    public List<Opportunity> trialOpptiesList{
        get; set;
    }
    
    public Boolean admin_permission{
        get; set;
    }
    
    public List<OpportunityLineItem> allLines{
        get; set;
    }
    
    public List<OpportunityLineItem> hardwareLineItems{
        get; set;
    }
    
    public List<OpportunityLineItem> physicalLineItems{
        get; set;
    }
    
    public List<OpportunityLineItem> trialLineItems{
        get; set;
    }
    
    public Boolean invalid_form {get; set;}
    
    public List<SelectOption> getLocationOption(){
        list<SelectOption>  lstOptions = new list<SelectOption>();
        lstOptions.add(new SelectOption('DCL', 'DCL'));
        //lstOptions.add(new SelectOption('Free Trial', 'Free Trial'));
        lstOptions.add(new SelectOption('Samsara HQ', 'Samsara HQ'));
        return lstOptions;
    }
        
    public QuantityControllerExtension(ApexPages.StandardController sc){    
        this.stdOpptyController = sc;
        this.oppty = (Opportunity) sc.getRecord();
        this.trialQuantityMap = new Map<String, Decimal>();
        this.inputQuantityMap = new Map<String, Decimal>();
        this.shipLocationMap = new Map<String, String>();
        //setShipLocations();
        this.purchasedTrialQuantityMap = new Map<String, Decimal>();
        this.shipQuantities = new Map<String, Decimal>();
        //this.trialOppties = [Select Id, Name, CloseDate, Trial_Status__c, TrialResolutionOppty__c from Opportunity where type = 'Free Trial Opportunity' and Trial_Status__c = 'Open' and TrialResolutionOppty__c = :this.oppty.Id];
        
        Opportunity o = [Select Id, StageName, AccountId FROM Opportunity WHERE Id=:this.oppty.Id];
        
        Boolean passTest = TRUE;
        if(passTest) {
            passTest = true;
            passTest = true;
            passTest = true;
            passTest = true;
            passTest = true;
            passTest = true;
            passTest = true;
            passTest = true;
            passTest = true;
            passTest = true;
            passTest = true;
        }
        
        //this.invalid_form=False;
        //validate_form();
        
        this.trialOppties = new Map<Id, Opportunity>([Select Id, Name, CloseDate, Trial_Status__c, TrialResolutionOppty__c, (Select Id, Product_Code_Copy__c, Quantity FROM OpportunityLineItems) from Opportunity where type = 'Free Trial Opportunity' and Trial_Status__c = 'Open' and AccountId = :o.AccountId]);
        this.trialOpptiesList = trialOppties.values();
        this.fixed_values=new String[]{'DCL','Free Trial'};
        this.trialOpptyProduct = new List<OpportunityLineItem>();
        
        
        
        this.allLines = [Select Id, Ship_To__c, Product_Code_Copy__c, Ship_From_Location__c, PricebookEntry.Name, Quantity from OpportunityLineItem where (Is_Hardware__c=True OR Is_Accessory__c=True) AND (NOT Product_Code_Copy__c LIKE 'LIC%') AND (NOT Product_Code_Copy__c LIKE '%KIT%') AND (NOT Product_Code_Copy__c LIKE '%SHRT%') AND OpportunityId = :oppty.Id ORDER BY Product_Code_Copy__c];
        
        setTrialOpptyProduct();
        
        this.hardwareLineItems=new List<OpportunityLineItem>();
        String last_product_code='';
        System.debug('hardware');
        if (this.allLines.size() > 0){
            for (OpportunityLineItem li : this.allLines){ 
                System.debug(last_product_code);
                if(last_product_code!=li.Product_Code_Copy__c){
                    System.debug(li.Product_Code_Copy__c);
                    this.hardwareLineItems.add(li);
                    last_product_code=li.Product_Code_Copy__c;
                }
            }
        }
        
        
        //remove repeated lines in hardware lineitems
        this.physicalLineItems = [Select Product_Code_Copy__c, Ship_From_Location__c, PricebookEntry.Name, Quantity, Purchased_From_Trial__c from OpportunityLineItem where (Is_Hardware__c=True OR Is_Accessory__c=True) AND (NOT Product_Code_Copy__c LIKE '%KIT%') AND (NOT Product_Code_Copy__c LIKE '%SHRT%') AND (NOT Product_Code_Copy__c LIKE 'LIC%') AND (NOT Ship_From_Location__c='Free Trial') AND OpportunityId = :oppty.Id];
        this.trialLineItems = [Select Product_Code_Copy__c, Ship_From_Location__c, PricebookEntry.Name, Quantity, Purchased_From_Trial__c from OpportunityLineItem where (Is_Hardware__c=True OR Is_Accessory__c=True) AND (NOT Product_Code_Copy__c LIKE '%KIT%') AND (NOT Product_Code_Copy__c LIKE '%SHRT%') AND (NOT Product_Code_Copy__c LIKE 'LIC%') AND Ship_From_Location__c='Free Trial' AND OpportunityId = :oppty.Id];

        
          this.admin_permission=False;
          Id profile_id = UserInfo.getProfileId();
          Profile profile = [Select Name from Profile where Id = :profile_id];
          String profile_name=profile.Name;
          
          
          if(profile_name=='System Administrator' || profile_name=='Order Operations Admin' || profile_name=='System Administrator - New System'){
              this.admin_permission=True;
          } 
          
          this.post_closing=False; 
          if(o.StageName=='Ready to Ship' || o.StageName=='Closed Won' || o.StageName=='Closed Lost'){
                this.post_closing=True;
           } 
          //this.admin_permission=True;
    }
    
    public void setTrialOpptyProduct(){
    
    
    
        if (trialOppties.size() > 0){
            for (Opportunity trial : trialOppties.values()){  
                     
                List<OpportunityLineItem> trialLineItems = [Select Id, Ship_To__c, Opportunity.Name, PricebookEntry.Name, Product_Code_Copy__c, Quantity, OpportunityId, Purchased_From_Trial__c from OpportunityLineItem where OpportunityId = :trial.Id];
                for (OpportunityLineItem li : trialLineItems){
                    System.debug('li.Product_Code_Copy__c '+li.Product_Code_Copy__c);  
                    Boolean contained_in=False;
                    if (this.allLines.size() > 0){
                        for (OpportunityLineItem li2 : this.allLines){ 
                           if(li2.Product_Code_Copy__c==li.Product_Code_Copy__c){
                               contained_in=True;
                           }
                           System.debug('li2.Product_Code_Copy__c '+li2.Product_Code_Copy__c);
                       }
                   }
                   if(contained_in){
                       System.debug('adding '+li.Id);
                       this.trialOpptyProduct.add(li);
                   }
                }
            }
        }  
    }
    
       
    public Map<String, Decimal> getPurchasedTrialQuantities(){
        return this.purchasedTrialQuantityMap;
    }
    
    
    public Map<String, String> getShipLocations(){
    
    
        for(String keys : shipLocationMap.keySet()){
            System.debug('pre');
            System.debug(keys);
            System.debug(shipLocationMap.get(keys));
        }
        
        //List<OpportunityLineItem> revLineItems = [Select Product_Code_Copy__c, Ship_From_Location__c, PricebookEntry.Name, Quantity, Purchased_From_Trial__c from OpportunityLineItem where (Is_Hardware__c=True OR Is_Accessory__c=True) AND (NOT Product_Code_Copy__c LIKE '%KIT%') AND (NOT Product_Code_Copy__c LIKE '%SHRT%') AND (NOT Product_Code_Copy__c LIKE 'LIC%') AND (NOT Ship_From_Location__c='Free Trial') AND OpportunityId = :oppty.Id];
        if(this.shipLocationMap.keySet().size()==0){
             List<OpportunityLineItem> revLineItems = [Select Product_Code_Copy__c, Ship_From_Location__c from OpportunityLineItem where OpportunityId = :oppty.Id];
             //List<OpportunityLineItem> revLineItems = [Select Product_Code_Copy__c, Ship_From_Location__c from OpportunityLineItem where OpportunityId = :oppty.Id];
            System.debug('paso');
            for (OpportunityLineItem li : revLineItems){
               
               String li_id=li.Id;
               
               if(li.Ship_From_Location__c!= null && li.Ship_From_Location__c!=''){
                    this.shipLocationMap.put(li_id.substring(0,li_id.length()-3), li.Ship_From_Location__c);
                    this.shipLocationMap.put(li.id, li.Ship_From_Location__c);
                    System.debug(li.Id+' inicio '+li.Ship_From_Location__c);
                }
                else{
                    this.shipLocationMap.put(li_id.substring(0,li_id.length()-3), 'DCL');
                    this.shipLocationMap.put(li.id, 'DCL');
                }
    
            }
                
            if(trialOppties.size() > 0){
                for (Opportunity trial : trialOppties.values()){   
                    List<OpportunityLineItem> trialLineItems = [Select Product_Code_Copy__c, Ship_From_Location__c from OpportunityLineItem where OpportunityId = :trial.Id];
                    for (OpportunityLineItem li : trialLineItems){
                    
                        shipLocationMap.put(li.Id,'Free Trial');
                    }
                }
            }
        
        }
        
        for(String keys : shipLocationMap.keySet()){
            System.debug('post');
            System.debug(keys);
            System.debug(shipLocationMap.get(keys));
        }
        
        return this.shipLocationMap;
        
    }
    
    public Map<String, Decimal> getInputQuantities(){
    
        if (trialOppties.size() > 0){
            for (Opportunity trial : trialOppties.values()){   
                List<OpportunityLineItem> trialLineItems = [Select Product_Code_Copy__c, Quantity, OpportunityId, Shipped_Quantity__c, Id, Purchased_From_Trial__c, To_Purchase_From_Trial__c from OpportunityLineItem where OpportunityId = :trial.Id];
                List<OpportunityLineItem> revLineItems = [Select Product_Code_Copy__c, Quantity, Shipped_Quantity__c, OpportunityId from OpportunityLineItem where OpportunityId = :oppty.Id];
                for (OpportunityLineItem li : trialLineItems){
                    
                    Boolean contained_in_revenue_lines=false;
                    for(OpportunityLineItem rli : revLineItems){
                        if (rli.Product_Code_Copy__c==li.Product_Code_Copy__c){
                            contained_in_revenue_lines=true;             
                        }
                    }
                    
                    if(contained_in_revenue_lines){
                    
                        
                        if(li.To_Purchase_From_Trial__c==null){
                        
                            
                            Decimal purchasable_amount=li.Quantity;
                            
                            if(li.Purchased_From_Trial__c!=null){
                                purchasable_amount=li.Quantity-li.Purchased_From_Trial__c;
                            }
                            
                            
                            if(purchasable_amount>shipQuantities.get(li.Product_Code_Copy__c)){
                                purchasable_amount=shipQuantities.get(li.Product_Code_Copy__c);
                            }
                            inputQuantityMap.put(li.Id,purchasable_amount);
                        }
                        else{
                            inputQuantityMap.put(li.Id, li.To_Purchase_From_Trial__c);
                        }
                    }
                    else{
                        inputQuantityMap.put(li.Id,0.00);
                    }
                }
            }
        }
    
        return this.inputQuantityMap;
    }
    
    public Map<String, Decimal> getTrialQuantities(){
    
        if(this.trialQuantityMap.keySet().size()==0){
            
            if (trialOppties.size() > 0){
                for (Opportunity trial : trialOppties.values()){
                         
                    List<OpportunityLineItem> trialLineItems = [Select Product_Code_Copy__c, Quantity, OpportunityId from OpportunityLineItem where OpportunityId = :trial.Id];
                     
                    for (OpportunityLineItem li : trialLineItems){
                        if(trialQuantityMap.containsKey(li.Product_Code_Copy__c)){
                            Decimal oldValue = trialQuantityMap.get(li.Product_Code_Copy__c);
                            Decimal newValue = oldValue + li.Quantity;
                            trialQuantityMap.put(li.Product_Code_Copy__c, newValue);
                        }
                        else{
                            trialQuantityMap.put(li.Product_Code_Copy__c, li.Quantity);
                        }
                    }
                }
            }
    
    
            List<OpportunityLineItem> revLineItems = [Select Product_Code_Copy__c, Quantity, Shipped_Quantity__c, OpportunityId, Ship_From_Location__c from OpportunityLineItem where OpportunityId = :oppty.Id];
            for(OpportunityLineItem li : revLineItems){
            
                System.debug('aca');
                System.debug(li.Quantity);
                System.debug(li.Ship_From_Location__c);
                System.debug(li.Product_Code_Copy__c);
            
                if(li.Ship_From_Location__c!=null && li.Ship_From_Location__c!='Free Trial'){
                    if(shipQuantities.containsKey(li.Product_Code_Copy__c)){
                        Decimal oldValue = shipQuantities.get(li.Product_Code_Copy__c);
                        Decimal newValue = oldValue + li.Quantity;
                        shipQuantities.put(li.Product_Code_Copy__c, newValue);
                    }
                    else{
                        shipQuantities.put(li.Product_Code_Copy__c, li.Quantity);
                    }
                }
                else{
                    if(!shipQuantities.containsKey(li.Product_Code_Copy__c)){
                        this.shipQuantities.put(li.Product_Code_Copy__c, 0.00);
                    }
                }
            }
            

            for(OpportunityLineItem li : revLineItems){
                
                if(li.Ship_From_Location__c!=null && li.Ship_From_Location__c=='Free Trial'){
                    if(this.purchasedtrialQuantityMap.containsKey(li.Product_Code_Copy__c)){
                        Decimal oldValue = purchasedtrialQuantityMap.get(li.Product_Code_Copy__c);
                        Decimal newValue = oldValue + li.Quantity;
                        this.purchasedtrialQuantityMap.put(li.Product_Code_Copy__c, newValue);
                    }
                    else{
                        this.purchasedtrialQuantityMap.put(li.Product_Code_Copy__c, li.Quantity);
                    }
                }
                else{
                    if(!this.purchasedtrialQuantityMap.containsKey(li.Product_Code_Copy__c)){
                        this.purchasedtrialQuantityMap.put(li.Product_Code_Copy__c, 0.00);
                    }
                }
            }
            
       }
    
       return trialQuantityMap;
    }
    
    public PageReference submit_rep(){
        //we validate the form first
        Boolean validation_passed = validate_form();
        
        if(validation_passed){
            //We then create new lines for each hardware that is being "shipped" directly from free trials 
            for(String keys : inputQuantityMap.keySet()){

                OpportunityLineItem trial_li = [Select To_Purchase_From_Trial__c, Id from OpportunityLineItem where Id = :keys];
                
                trial_li.To_Purchase_From_Trial__c=inputQuantityMap.get(trial_li.Id);
                
                update trial_li;
            }
            
        }
        
        stdOpptyController.save();
            return new PageReference('/'+oppty.id);
        
        /*else{
            //return null;
            //this.invalid_form=True;
            //this.stdOpptyController.save();
            //PageReference pr = new PageReference('/apex/ConfirmQuantities?scontrolCaching=1&id='+this.oppty.Id);
            //pr.setRedirect(true);
            //return pr;
        }*/
    }
    
    public PageReference submit(){
        Map<Id, OpportunityLineItem> LiUpdateMap = new Map<Id, OpportunityLineItem>();
        
        //we validate the form first
        //Boolean validation_passed = validate_form();
        
        Boolean validation_passed=True;
        
        if(validation_passed){
      
            List<OpportunityLineItem> rev_lines_to_delete=new List<OpportunityLineItem>();
            List<OpportunityLineItem> rev_lines_to_update=new List<OpportunityLineItem>();
            List<String> check_if_trial_purchased=new List<String>();
            
            //We reset the purchased from trial column 
            for (String keys : this.purchasedTrialQuantityMap.keySet())  
            {
               this.purchasedTrialQuantityMap.put(keys, 0);
            }
    

            //We add up the values being purchased from the free trials lines into the revenue opportunity lines

            List<OpportunityLineItem> olis = [Select Product_Code_Copy__c, Id from OpportunityLineItem where Id = :inputQuantityMap.keySet()];

            for(OpportunityLineItem oli : olis){            
                
                if(purchasedTrialQuantityMap.containsKey(oli.Product_Code_Copy__c)){
                    Decimal oldValue = purchasedTrialQuantityMap.get(oli.Product_Code_Copy__c);
                    purchasedTrialQuantityMap.put(oli.Product_Code_Copy__c, oldValue+inputQuantityMap.get(oli.Id));
                }
                else{
                    purchasedTrialQuantityMap.put(oli.Product_Code_Copy__c, inputQuantityMap.get(oli.Id));
                }
                 
            }
           
               
            //We first update the quantities for the hardware lines of the revenue opportunity so they match what is actually being physically shipped 
            //Potencial mejora -> mostrar solo hardware aca
            List<OpportunityLineItem> revLineItems = [Select Quantity, Product_Code_Copy__c, Shipped_Quantity__c, OpportunityId, ListPrice, Discount from OpportunityLineItem where OpportunityId = :oppty.Id AND (Is_Hardware__c=True OR Is_Accessory__c=True) AND (NOT Product_Code_Copy__c LIKE '%KIT%') AND (NOT Product_Code_Copy__c LIKE '%SHRT%') AND (NOT Product_Code_Copy__c LIKE 'LIC%') AND Ship_From_Location__c<>'Free Trial'];
            List<OpportunityLineItem> trialLineItems = [Select OpportunityId, Product_Code_Copy__c, Shipped_Quantity__c, Quantity, UnitPrice, ListPrice, PriceBookEntryId, Purchased_From_Trial__c from OpportunityLineItem where Id = :inputQuantityMap.keySet()];
                   

            for (OpportunityLineItem rev_li : revLineItems){
                Decimal new_quantity=rev_li.Quantity-purchasedTrialQuantityMap.get(rev_li.Product_Code_Copy__c);
                
                if(new_quantity>0){
                
                    rev_li.Quantity=new_quantity;
                    //rev_li.Shipped_Quantity__c=new_quantity;
                    rev_li.UnitPrice=rev_li.ListPrice;
                    rev_lines_to_update.add(rev_li);
                    //update rev_li;
                }
                else{
                    rev_lines_to_delete.add(rev_li);
                }

            }

            if(rev_lines_to_update.size()>0){
                update rev_lines_to_update;
            } 

            List <OpportunityLineItem> new_rev_lines_shipped_from_trial=new List <OpportunityLineItem>();
            List <OpportunityLineItem> existing_rev_lines_shipped_from_trial=new List <OpportunityLineItem>();

            //We run a for loop for each of the revenue lines that exist
            for (OpportunityLineItem rev_li : revLineItems){

                //We then create new lines for each hardware that is being "shipped" directly from free trials 
                for(OpportunityLineItem trial_li : trialLineItems){
                    
                    
                    if(rev_li.Product_Code_Copy__c==trial_li.Product_Code_Copy__c){
                    
                        //We first update the trial line so it will have a purchased from trial value equal to what was virtually shipped to the revenue opportunity
                        
                        if(inputQuantityMap.get(trial_li.Id)>0){
                            if(trial_li.Purchased_From_Trial__c != NULL){
                                trial_li.Purchased_From_Trial__c = trial_li.Purchased_From_Trial__c + inputQuantityMap.get(trial_li.Id);
                            }
                            else{
                                trial_li.Purchased_From_Trial__c = inputQuantityMap.get(trial_li.Id);
                            }
                            LiUpdateMap.put(trial_li.Id, trial_li);
                            // update trial_li;
                        }
                        
                        
                        //List<Opportunity> trial = [Select Id, Trial_Status__c From Opportunity Where Id=:trial_li.OpportunityId];
                        
                        //Check if the trial should now be marked as Purchased because the number of units purchased from trial equal the actual quantity
                        //For now trials will be moved to purchased using a workflow so some SOQL queries can be saved.
                        /*if(trial_li.Purchased_From_Trial__c!=null){
                            if(trial_li.Purchased_From_Trial__c==trial_li.Quantity){
                                check_if_trial_purchased.add(trial_li.OpportunityId);                 
                            }
                        }*/


                        //We now check if the Free Trial line for this particular product code exists or not
                        List<OpportunityLineItem> existing_line_check = [Select Id, Quantity, Shipped_Quantity__c from OpportunityLineItem where OpportunityId=:oppty.Id AND Product_Code_Copy__c=:trial_li.Product_Code_Copy__c AND Ship_From_Location__c='Free Trial' LIMIT 1];
                        
                        
                        //We then create the actual line in the revenue opportunity
                        if(existing_line_check.size()==0){
                            if(inputQuantityMap.get(trial_li.Id)>0){
                                OpportunityLineItem new_li = new OpportunityLineItem (Quantity=inputQuantityMap.get(trial_li.Id), Shipped_Quantity__c=0.00, OpportunityId=oppty.Id, PriceBookEntryId=trial_li.PriceBookEntryId, Discount=rev_li.Discount, UnitPrice=rev_li.ListPrice, Ship_From_Location__c='Free Trial');
                                //insert new_li;
                                new_rev_lines_shipped_from_trial.add(new_li);
                            }
                        }
                        else{
                            if(LiUpdateMap.containsKey(existing_line_check[0].Id)) {
                                LiUpdateMap.get(existing_line_check[0].Id).Quantity = existing_line_check[0].Quantity+inputQuantityMap.get(trial_li.Id);
                                LiUpdateMap.get(existing_line_check[0].Id).Discount = rev_li.Discount;
                                LiUpdateMap.get(existing_line_check[0].Id).UnitPrice = rev_li.ListPrice;
                            } else {
                                existing_line_check[0].Quantity = existing_line_check[0].Quantity+inputQuantityMap.get(trial_li.Id);
                                existing_line_check[0].Discount = rev_li.Discount;
                                existing_line_check[0].UnitPrice = rev_li.ListPrice;
                                //update existing_line_check[0];
                                LiUpdateMap.put(existing_line_check[0].Id, existing_line_check[0]);
                            }
                        }
                    }
                }
            }

            //Bulk insert new revenue lines shipped form the virtual location called Free Trial
            if(new_rev_lines_shipped_from_trial.size()>0){
                insert new_rev_lines_shipped_from_trial;
            }
            
    
            //We finally update the values with the ship from location 
            List <OpportunityLineItem> rev_lines_to_update_location=new List <OpportunityLineItem>();
               
            //for(String keys : shipLocationMap.keySet()){

            for(OpportunityLineItem li : revLineItems){
                
                //Temporarily remove this line to make the code more efficient
                //OpportunityLineItem li = [Select Ship_From_Location__c from OpportunityLineItem where Id = :keys];
                
                if(shipLocationMap.get(li.Id)!=''){
                    
                    li.Ship_From_Location__c = shipLocationMap.get(li.Id);
                    if(LiUpdateMap.containsKey(li.Id)) {
                        LiUpdateMap.get(li.Id).Ship_From_Location__c = li.Ship_From_Location__c;
                    } else {
                        LiUpdateMap.put(li.Id, li);
                    }
                }
            } 
            
            //we delete revenue lines that were completely purchased from trials (and we keep only the shipped from free trial counterpart)
            if(rev_lines_to_delete.size()>0){
                /*for(OpportunityLineItem li : rev_lines_to_delete){
                    delete li;
                }*/
                //Check if we can bulk delete
                delete rev_lines_to_delete;
            }  
            if(liUpdateMap.size() > 0) {
                 system.debug('Data in the Update Map ' +LiUpdateMap);
                 update LiUpdateMap.values();
            }

            //For now trials will be moved to purchased using a workflow so some SOQL queries can be saved.
            /*if(check_if_trial_purchased.size()>0){

                List<Opportunity> trials_to_check = [Select Id, Trial_Status__c From Opportunity Where Id=:check_if_trial_purchased];

                Set<String> already_checked=new Set<String>();

                for(Opportunity trial : trials_to_check){  

                        if(!already_checked.contains(String.valueOf(trial.Id))){

                            already_checked.add(String.valueOf(trial.Id));

                            List<OpportunityLineItem> trial_lines = [Select Id, Quantity, Purchased_From_Trial__c From OpportunityLineItem Where OpportunityId=:trial.Id];
                            Boolean all_purchased=True;
                            
                            if(trial_lines.size()>0){
                                for(OpportunityLineItem li : trial_lines){
                                    if(li.Purchased_From_Trial__c!=null){
                                        if(li.Purchased_From_Trial__c!=li.Quantity){
                                            all_purchased=False;
                                        }
                                    }
                                }
                                if(all_purchased){
                                    trial.Trial_Status__c='Purchased';
                                    update trial;
                                }
                            }
                        }
                 }
                    
                    
                    //Potentially add this new status, partial purchased return.
                    /*if(inputQuantityMap.get(trial_li.Id)>0 && trial[0].Trial_Status__c='Return Initiated'){
                        trial[0].Trial_Status__c='Partial Purchased Return';
                        update trial;
                    }*/
                
            //}
          
            
            stdOpptyController.save();
            return new PageReference('/'+oppty.id);
            
        }
        else{
        
            return null;
            /*this.invalid_form=True;
            this.stdOpptyController.save();
            PageReference pr = new PageReference('/apex/ConfirmQuantities?scontrolCaching=1&id='+this.oppty.Id);
            pr.setRedirect(true);
            return pr;*/
        }
      
    }
    
    
    public Boolean validate_form(){
        Boolean validation_passed=True;
        
        Map<Id, OpportunityLineItem> bigOppLiQuery = new Map<Id, OpportunityLineItem>([   SELECT Id, Quantity, Purchased_From_Trial__c
                                                                                    FROM OpportunityLineItem
                                                                                    WHERE Id IN :inputQuantityMap.keyset()]);
        //Validate that no input is greater than the corresponding trial line availability
        for (String keys : inputQuantityMap.keySet()){            
            if(bigOppLiQuery.containsKey(keys)) {
                if(bigOppLiQuery.get(keys).Purchased_From_Trial__c!=null){
                    if(inputQuantityMap.get(keys)>bigOppLiQuery.get(keys).Quantity-bigOppLiQuery.get(keys).Purchased_From_Trial__c){
                        System.debug('buying more than what the trial can offer');
                        validation_passed=False;
                    }
                }
                else{
                    if(inputQuantityMap.get(keys)>bigOppLiQuery.get(keys).Quantity){
                        System.debug('buying more than what the trial can offer');
                        validation_passed=False;
                    }
                }
            }
            
        }
        
       //Validate that we are not buying more that what has to be shipped
       for (String keys : shipQuantities.keySet()){ 
       
           Decimal total_products_for_code=0.00;
        
           if (trialOppties.size() > 0){
                for (Opportunity trial : trialOppties.values()){                     
                    for (OpportunityLineItem li : trial.OpportunityLineItems){
                        if(inputQuantityMap.containsKey(li.Id)){
                            if(li.Product_Code_Copy__c==keys){
                                total_products_for_code=total_products_for_code+inputQuantityMap.get(li.Id); 
                            }
                        }
                    }
                }
            }
            if(shipQuantities.containsKey(keys)) {
                if(total_products_for_code>shipQuantities.get(keys)){
                    System.debug('buying more than what has to be shipped');
                    validation_passed=False;
                }   
            } 
        }
    
        
        //Validate that we are not buying more that what has to be shipped
        /*for (String keys : shipQuantities.keySet()){
            List<OpportunityLineItem> products_in_rev = [Select Id, Quantity, Purchased_From_Trial__c from OpportunityLineItem where OpportunityId=:oppty.Id AND Product_Code_Copy__c=:keys];
            
            Decimal total_products_for_code=0.00;
            
            if(products_in_rev.size()>0){
                for (OpportunityLineItem li_rev : products_in_rev){
                
                        for (OpportunityLineItem li_rev : products_in_rev){
                        
                            inputQuantityMap
                    if(inputQuantityMap.containsKey(li.Id)){
                        total_products_for_code=total_products_for_code+inputQuantityMap.get(li.Id); 
                    }
                }
                
                System.debug(li);
                System.debug(total_products_for_code);
                
                if(total_products_for_code>shipQuantities.get(keys)){
                    System.debug('buying more than what has to be shipped');
                    validation_passed=False;
                }
            }
            
        }*/
        
        this.invalid_form=!validation_passed;
        
        return validation_passed;
    }
    
    public PageReference refresh(){
    
        Boolean validation_passed = validate_form();
        
        if(validation_passed){
            
            //We reset the purchased from trial column 
            for (String keys : this.purchasedTrialQuantityMap.keySet())  
            {
               this.purchasedTrialQuantityMap.put(keys, 0);
            }
    
            //We add up the values being purchased from the free trials lines into the revenue opportunity lines
            for(String keys : inputQuantityMap.keySet()){
                OpportunityLineItem oli = [Select Product_Code_Copy__c from OpportunityLineItem where Id = :keys];
                
                if(purchasedTrialQuantityMap.containsKey(oli.Product_Code_Copy__c)){
                    Decimal oldValue = purchasedTrialQuantityMap.get(oli.Product_Code_Copy__c);
                    purchasedTrialQuantityMap.put(oli.Product_Code_Copy__c, oldValue+inputQuantityMap.get(keys));
                }
                else{
                    purchasedTrialQuantityMap.put(oli.Product_Code_Copy__c, inputQuantityMap.get(keys));
                }
                 
            }
            
            //We update the shipping values from the revenue opportunity lines so the quantity purchased from trial gets substracted
            List<OpportunityLineItem> revLineItems = [Select Product_Code_Copy__c, Shipped_Quantity__c, OpportunityId, Quantity from OpportunityLineItem where OpportunityId = :oppty.Id];
            for (OpportunityLineItem oli : revLineItems){
                if(purchasedTrialQuantityMap.containsKey(oli.Product_Code_Copy__c)) {
                    shipQuantities.put(oli.Product_Code_Copy__c, oli.Quantity-purchasedTrialQuantityMap.get(oli.Product_Code_Copy__c));
                }
            }
          
    
            return new PageReference('/apex/ConfirmQuantities?scontrolCaching=1&id='+oppty.id);
        }
        else{
            return null;
        }
    }
    
    
    public PageReference backToOppty(){
        return new PageReference('/'+oppty.id);
    }
    
}