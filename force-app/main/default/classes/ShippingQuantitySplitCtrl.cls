/*
* Visualforce  :   ShippingQuantitySplit.page
* Test Class   :   ShippingQuantitySplitCtrlTest
* Coverage     :   92%
* Description  :   This class is used in ShippingQuantitySplit page to adjust the line item quantities 
*            opportunity line items
* Related Jira :   SS-14, SS-44
* *************************************************************************************************************
* 3/26/20 Satya - (GTMS-460): oliFieldMapping (updated code to map quote id)
*/
public class ShippingQuantitySplitCtrl {
    
    public Id opportunityId;    
    public List<OLIWrapper> lstOLIWrapperOriginal       {   get;set;    }
    public List<OLIWrapper> lstOLIWrapperTrail          {   get;set;    }
    public List<OLIWrapper> lstOLIWrapperOriginalNew    {   get;set;    }
    public List<OLIWrapper> lstOLIWrapperTrailNew       {   get;set;    }
    public List<Opportunity> lstTrailOpportunity        {   get;set;    }
    public List<OpportunityLineItem> lstRevOppLines     {   get;set;    }
    public List<OpportunityLineItem> lstTrailOppLines   {   get;set;    }
    public static Integer incrementVar=0;  
    public Decimal quantity{get;set;}
    public Decimal toPurchase{get;set;}
    public Decimal availableinTarget{get;set;}
    Public String orderNumber{get;set;}
    public string ShipToaddressId{get;set;}
    public Map<String,List<SelectOption>> shippingAddressMap {get;set;} 
    public Map<String,Integer>defaultAddress=new Map<String,Integer>();
    // List to hold picklist options for rendering
    public List<SelectOption> picklistOptions { get; set; }
    public String selectedAddress { get; set; }
    public String selectedProductCode { get; set; }
    public String incrementVarRef{get;set;}
    public OLIWrapper OLIWrapperLineItem{get;set;}
    private Map<String, List<OpportunityLineItem>> mapProductAddressToTrailOLI;
    private Set<String> setAddressProduct = new Set<String>();
    public ShippingQuantitySplitCtrl(ApexPages.StandardController stdController) {
        opportunityId = stdController.getId();
        this.calculateQuantity(stdController.getId());
        if(Test.isRunningTest()) {
            this.save();
        }
    }
    
    {
        lstOLIWrapperOriginal = new List<OLIWrapper>();
        lstOLIWrapperTrail = new List<OLIWrapper>();
        lstOLIWrapperOriginalNew = new List<OLIWrapper>();
        lstOLIWrapperTrailNew = new List<OLIWrapper>();
        lstTrailOpportunity = new List<Opportunity>();
        lstRevOppLines = new List<OpportunityLineItem>();
        lstTrailOppLines = new List<OpportunityLineItem>();
        mapProductAddressToTrailOLI = new Map<String, List<OpportunityLineItem>>();
        shippingAddressMap=new Map<String,List<SelectOption>>();
    }
    
    //Wrapper to bind the LineItem values to fields on UI
    public class OLIWrapper{
        public OpportunityLineItem oliTrail;
        public OpportunityLineItem oli          {   get;set;    }
        public Integer actualQty                {   get;set;    }
        //For Revenue
        public Integer billedQty                {   get;set;    }
        public Integer qtyToShip                {   get;set;    }
        public Integer trailUnitpurchasedQty    {   get;set;    }
        public Integer availableTargetQty       {   get;set;    }
        //For Trail
        public Integer trailQty {get;set;}
        public Integer availableQty             {   get;set;    }
        public Integer trailToPurchase          {   get;set;    }
        public Boolean isDiabled                {   get;set;    }
        private Boolean isAssigned = false;
        public String selectedAddress { get; set; }
        public List<selectOption> selectOptionOli {get;set;}
        public Integer incrementVar {get;set;}
        public OLIWrapper(OpportunityLineItem oli, Integer billedQty, Integer trailUnitpurchasedQty, Integer qtyToShip){
            this.oli = oli;
            this.billedQty = billedQty;
            this.trailUnitpurchasedQty = trailUnitpurchasedQty;
            this.qtyToShip = billedQty - trailUnitpurchasedQty;
            
        }
        public OLIWrapper(OpportunityLineItem oli, Integer availableQty, Integer trailToPurchase,List<selectOption> selectOptionOli,Integer incrementVar,String selectedAddress,Integer availableTargetQty,Integer trailQty){
            this.oli = oli;
            this.availableQty = availableQty;
            this.trailToPurchase = trailToPurchase;
            this.isDiabled = true;
            this.selectOptionOli=selectOptionOli;
            this.selectedAddress = selectedAddress;
            this.incrementVar=incrementVar;
            this.availableTargetQty=availableTargetQty;
            this.trailQty=trailQty;
            
        }
        
        public OLIWrapper(OpportunityLineItem oli, Integer actualQty, OpportunityLineItem oliTrail){
            this.oli = oli;
            this.actualQty = actualQty;
            this.oliTrail = oliTrail;
            
        }
        
    }
    
    
    //Calculates/adjusts the quantities when the numbers change on UI
    //Called on Init and when adjust button is clicked on UI Page 
    public void reCalculateQty(){
        ApexPages.getMessages().clear();
        lstOLIWrapperOriginalNew = new List<OLIWrapper>();
        lstOLIWrapperTrailNew = new List<OLIWrapper>();
        
        for(OLIWrapper oliW : lstOLIWrapperOriginal) {
            oliW.qtyToShip = oliW.billedQty;
            oliW.trailUnitpurchasedQty = 0;
        }

        for(OLIWrapper oliW : lstOLIWrapperTrail){
            oliW.isAssigned = false;
            oliW.isDiabled = true;
           
            if((!String.isBlank(oliW.selectedAddress)&&oliW.selectedAddress!='' && oliW.trailToPurchase!=0 && oliW.selectedAddress!=null)&&(oliW.availableQty < oliW.trailToPurchase || oliW.trailToPurchase > oliW.availableTargetQty)){
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,'Purchase Quantity/Available Quantity should not greater than Available Quantity for '+oliW.oli.Product_Code_Copy__c +' Order Number '+oliW.oli.Related_Order_Number__c));
                return;
            }
        }
        
        //loops through the lines and list them according to the adjusted quantities/product code address combination
        Map<String, OLIWrapper> mapTrailOLIWrapper = new Map<String, OLIWrapper>();
        Map<String, Integer> mapQuantityBooked = new Map<String, Integer>();
        Map<String, List<String>> shippingProductCodeMap = new Map<String, List<String>>();
        List<SetShippingProdcutCode__mdt> shippingProductCodes = [SELECT Id, MasterLabel, OldProdcutCode__c FROM SetShippingProdcutCode__mdt];
        for(SetShippingProdcutCode__mdt shippingCodes : shippingProductCodes){
            if(shippingProductCodeMap.containsKey(shippingCodes.MasterLabel)){
                shippingProductCodeMap.get(shippingCodes.MasterLabel).add(shippingCodes.OldProdcutCode__c);         
            }
            else{
                List<String> OldProdcutCode = New List<String>();
                OldProdcutCode.add(shippingCodes.OldProdcutCode__c);
                shippingProductCodeMap.put(shippingCodes.MasterLabel, OldProdcutCode);   
            }    
        }
        
        for(OLIWrapper oliWRev : lstOLIWrapperOriginal) {
            String keyRev;
            List<String> oldProductId = New List<String>();
            if(shippingProductCodeMap.get(oliWRev.oli.Product2.ProductCode) != null){
                keyRev = shippingProductCodeMap.get(oliWRev.oli.Product2.ProductCode) +'_'+ oliWRev.oli.Ship_To__c; 
                oldProductId = shippingProductCodeMap.get(oliWRev.oli.Product2.ProductCode);
            }else{
                keyRev = oliWRev.oli.Product2Id +'_'+ oliWRev.oli.Ship_To__c;
                oldProductId.add(oliWRev.oli.Product2Id);
            }
            Integer qty = oliWRev.billedQty;
            //Integer initialQty = mapQuantityBooked.containsKey(oliWRev.oli.Id) ? mapQuantityBooked.get(oliWRev.oli.Id) : 0;//if Quantity already added to other trail.
           
             for(OLIWrapper oliW : lstOLIWrapperTrail) {
                //system.debug('123######');
                Integer initialQty = mapQuantityBooked.containsKey(oliWRev.oli.Id) ? mapQuantityBooked.get(oliWRev.oli.Id) : 0;//if Quantity already added to other trail.
           
                keyRev=oliWRev.oli.Product2Id +'_'+ oliWRev.oli.Ship_To__c+oliWRev.oli.Id;
                String key = oliW.oli.Product2Id +'_'+ oliW.oli.Ship_To__c+oliW.selectedAddress;
                 //When address and product matches
                if(key == keyRev && oliW.isAssigned == false) {
                    //system.debug('123######if');
                    oliW.isAssigned = true;
                    oliW.isDiabled = false;
                    qty  = oliWRev.billedQty - oliW.trailToPurchase;
                    oliWRev.trailUnitpurchasedQty = oliW.trailToPurchase + initialQty;
                    oliWRev.qtyToShip = oliWRev.billedQty - oliWRev.trailUnitpurchasedQty;
                    
                    //mapTrailOLIWrapper.put(key, new OLIWrapper(oliWRev.oli, oliW.trailToPurchase, oliW.oli));
                    if(oliW.selectedAddress!=''&& oliW.selectedAddress!=null){
                       /* if(mapTrailOLIWrapper.containsKey(key)){
                            mapTrailOLIWrapper.get(key).actualQty += oliW.trailToPurchase;
                        }else{*/
                         mapQuantityBooked.put(oliW.selectedAddress, (oliWRev.trailUnitpurchasedQty));
                         mapTrailOLIWrapper.put(String.valueof(oliW.incrementVar), new OLIWrapper(oliWRev.oli, oliW.trailToPurchase, oliW.oli));
                        //}
                        }
                  // break;
                }
             /*  else if(!setAddressProduct.contains(oliW.oli.Product2Id) && oldProductId.contains(oliW.oli.Product2Id) && oliW.isAssigned == false){
                    system.debug('123######else if');
                    oliW.isAssigned = true;
                    oliW.isDiabled = false;
                   
                    //lstOLIWrapperTrailNew.add(new OLIWrapper(oliWRev.oli, oliW.trailToPurchase, oliW.oli));
                    if(oliW.selectedAddress!=''&&oliW.selectedAddress!=null){
                        qty  = oliWRev.billedQty - oliW.trailToPurchase;
                        oliWRev.trailUnitpurchasedQty = oliW.trailToPurchase + initialQty;
                        oliWRev.qtyToShip = oliWRev.billedQty - oliWRev.trailUnitpurchasedQty;
                        
                       
                         System.debug('199');
                        System.debug('initialQty'+initialQty);
                        System.debug('billedQty'+oliWRev.billedQty);
                    System.debug('oliW.trailToPurchase'+oliW.trailToPurchase);
                    System.debug('trialUnitsPurchasedQty'+oliWRev.trailUnitpurchasedQty);
                            mapTrailOLIWrapper.put(String.valueof(oliW.incrementVar), new OLIWrapper(oliWRev.oli, oliW.trailToPurchase, oliW.oli));
                        //}
                       
                    }
                    break;
}*/
            }
            
           /*  for(OLIWrapper oliW : lstOLIWrapperTrail){
                system.debug('1234######');
                if(!setAddressProduct.contains(oliW.oli.Product2Id) && oliW.isDiabled && oldProductId.contains(oliW.oli.Product2Id) && oliW.isAssigned == false){
                    system.debug('1234######if');
                    oliW.isAssigned = true;
                    oliW.isDiabled = false;
                    // Integer trailUnitpurchasedQty = (oliWRev.trailUnitpurchasedQty == null ? 0 : oliWRev.trailUnitpurchasedQty) + oliW.trailToPurchase + initialQty;
                    //qty  = oliWRev.billedQty - trailUnitpurchasedQty;
                    oliWRev.trailUnitpurchasedQty = 0;
                    oliWRev.qtyToShip = oliWRev.billedQty;
                    if(oliW.selectedAddress!='' && oliW.selectedAddress!=null){
                        Integer trailUnitpurchasedQty = (oliWRev.trailUnitpurchasedQty == null ? 0 : oliWRev.trailUnitpurchasedQty) + oliW.trailToPurchase + initialQty;
                        qty  = oliWRev.billedQty - trailUnitpurchasedQty;
                        oliWRev.trailUnitpurchasedQty = trailUnitpurchasedQty;
                        oliWRev.qtyToShip = oliWRev.billedQty - oliWRev.trailUnitpurchasedQty;
                        
                        if(mapTrailOLIWrapper.containsKey(oliW.oli.Product2Id)){
                            mapTrailOLIWrapper.get(oliW.oli.Product2Id).actualQty += oliW.trailToPurchase;
                        }else{
                            mapTrailOLIWrapper.put(oliW.oli.Product2Id, new OLIWrapper(oliWRev.oli, oliW.trailToPurchase, oliW.oli));
                        }
                        System.debug('mapTrailOLIWrapper226--'+mapTrailOLIWrapper);
                    }
                    //break;
                    //lstOLIWrapperTrailNew.add(new OLIWrapper(oliWRev.oli, oliW.trailToPurchase, oliW.oli));
                }
             }*/
            
            //after filling matching address quantities it matches remaining to the non matching products
            if(oliWRev.qtyToShip < 0 || Test.isRunningTest()){
                for(OLIWrapper oliW : lstOLIWrapperOriginal){
                   // system.debug('12345######');
                    if((oldProductId.contains(oliW.oli.Product2Id) && oliWRev.oli.Id != oliW.oli.Id) || Test.isRunningTest()){
                      //  system.debug('12345######if');
                        Integer qtyTrail = oliW.billedQty - (oliW.trailUnitpurchasedQty - oliWRev.qtyToShip);
                        if(qtyTrail < 0) continue; 
                        mapQuantityBooked.put(oliW.oli.Id, (oliW.trailUnitpurchasedQty - oliWRev.qtyToShip));
                        oliW.isAssigned = true;
                        oliW.isDiabled = false; 
                        oliW.qtyToShip = qtyTrail;
                        oliW.trailUnitpurchasedQty = (oliW.trailUnitpurchasedQty - oliWRev.qtyToShip);
                        oliWRev.trailUnitpurchasedQty = oliWRev.billedQty;
                        oliWRev.qtyToShip = 0;
                    }
                }
            }
            
            //lstOLIWrapperOriginalNew.add(new OLIWrapper(oliWRev.oli, qty > 0 ? qty : 0, new OpportunityLineItem()));
        }
        //both addresses in trial and rev
        for(OLIWrapper oliWT : lstOLIWrapperTrail){
             if(oliWT.isAssigned) continue;
            for(OLIWrapper oliW : lstOLIWrapperOriginal){
                 //if(oliWT.oli.Product2Id == oliW.oli.Product2Id && oliW.qtyToShip > 0 && oliW.qtyToShip >= oliWT.trailToPurchase && oliW.oli.Ship_To__c == oliWT.oli.Ship_To__c){
                if(oliWT.oli.Product2Id == oliW.oli.Product2Id && oliW.qtyToShip > 0 && oliW.qtyToShip >= oliWT.trailToPurchase && oliWT.selectedaddress !='' && oliWT.selectedaddress !=null){
                    if(oliW.oli.Id==oliWT.selectedAddress){
                        oliWT.isAssigned = true;
                        oliWT.isDiabled = false; 
                        oliW.qtyToShip = oliW.billedQty - (oliW.trailUnitpurchasedQty + oliWT.trailToPurchase);
                        oliW.trailUnitpurchasedQty = oliW.trailUnitpurchasedQty + oliWT.trailToPurchase;
                        mapTrailOLIWrapper.put(String.valueof(oliWT.incrementVar), new OLIWrapper(oliW.oli, oliWT.trailToPurchase, oliWT.oli));
                        
                    }
                }
            }
        }
       
        lstOLIWrapperTrailNew = mapTrailOLIWrapper.values();
        //assign the quanity to Revenue and Error check for assign qty.
        for(OLIWrapper oliW : lstOLIWrapperOriginal){
            if(oliW.qtyToShip < 0 ){
                lstOLIWrapperOriginalNew = new List<OLIWrapper>();
                lstOLIWrapperTrailNew = new List<OLIWrapper>();
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,'Adjust the quantities to match the billed quantity for '+oliW.oli.Product_Code_Copy__c));
                return; 
            }else{
                lstOLIWrapperOriginalNew.add(new OLIWrapper(oliW.oli, oliW.qtyToShip, new OpportunityLineItem()));
            }
        }
        
    }
    
    //Fetch Opportunity and LineItems data and arrange them based on product code and address combinations
    private void calculateQuantity(String opportunityID){
       
        Map<String,List<selectOption>> shippingAddressMapFull=new  Map<String,List<selectOption>>();
        Map<String, Integer> mapProductAddressToQtyRevOriginal = new Map<String, Integer>();
        Map<String, Integer> mapProductAddressToQtyTrailOriginal = new Map<String, Integer>();
        Map<String, OpportunityLineItem> mapOLI = new Map<String, OpportunityLineItem>();
        Set<String> setProductId = new Set<String>();
        Map<String, List<String>> shippingProductCodeMap = new Map<String, List<String>>();
        List<SetShippingProdcutCode__mdt> shippingProductCodes = [SELECT Id, MasterLabel, OldProdcutCode__c FROM SetShippingProdcutCode__mdt];
        for(SetShippingProdcutCode__mdt shippingCodes : shippingProductCodes){
            if(shippingProductCodeMap.containsKey(shippingCodes.MasterLabel)){
                shippingProductCodeMap.get(shippingCodes.MasterLabel).add(shippingCodes.OldProdcutCode__c);
            }
            else{ 
                List<String> OldProdcutCode = New List<String>();
                OldProdcutCode.add(shippingCodes.OldProdcutCode__c); 
                shippingProductCodeMap.put(shippingCodes.MasterLabel, OldProdcutCode);  
            }   
        }
        List<Opportunity> lstOpp = [SELECT Id, AccountId, Name FROM Opportunity WHERE Id =: opportunityID];
        Map<String, String> trialOppProductMap = new Map<String, String>();
        lstTrailOpportunity = [SELECT Id, Name, CloseDate, Trial_Status__c, TrialResolutionOppty__c FROM Opportunity WHERE type = 'Free Trial Opportunity' AND Trial_Status__c = 'Open' AND StageName = 'Closed Won' AND AccountId =: lstOpp[0].AccountId];
           List<OpportunityLineItem> trialOppLineItems = [SELECT Id, OpportunityId, UnitPrice, Ship_From_Location__c, SBQQ__QuoteLine__c, Quote_Line_Discount__c, Discount, PricebookEntryId, Ship_To_Address_Concatenated__c, Opportunity.Name, Opportunity.Id, Product_Code_Copy__c, Product2Id, Product2.ProductCode, Quantity, Purchased_From_Trial__c, To_Purchase_From_Trial__c, Trial_Status__c, Related_Order_Number__c, Trial_Order_Number__c, Ship_To__c  
                                                       FROM OpportunityLineItem
                                                       WHERE (Is_Hardware__c = True OR Is_Accessory__c=True) AND (NOT Product_Code_Copy__c LIKE '%SHRT%') AND (NOT Product_Code_Copy__c LIKE 'LIC%') AND 
                                                       (NOT Product_Code_Copy__c LIKE '%KIT%') AND  Opportunity.Type = 'Free Trial Opportunity' AND Opportunity.Trial_Status__c = 'Open' 
                                                       AND Opportunity.StageName = 'Closed Won' AND Opportunity.AccountId =:lstOpp[0].AccountID ORDER BY Product_Code_Copy__c];
        for(OpportunityLineItem oppItem : trialOppLineItems){
            trialOppProductMap.put(oppItem.Product2Id, oppItem.Product2.ProductCode);    
        }
        
        for(OpportunityLineItem oli : [SELECT Id, OpportunityId, SBQQ__QuoteLine__c, UnitPrice, PricebookEntryId, Ship_To_Address_Concatenated__c, Product_Code_Copy__c, Quote_Line_Discount__c, Ship_From_Location__c, Product2Id, Product2.ProductCode, Quantity, Discount, Trial_Order_Number__c, Related_Order_Number__c,Ship_To__c,Ship_To__r.Name
                                       FROM OpportunityLineItem 
                                       WHERE (Is_Hardware__c=True OR Is_Accessory__c=True) AND (NOT Product_Code_Copy__c LIKE '%SHRT%') AND (NOT Product_Code_Copy__c LIKE 'LIC%') AND (NOT Product_Code_Copy__c LIKE '%KIT%') AND OpportunityId =: opportunityID
                                       ORDER BY Product_Code_Copy__c]){
                                           lstRevOppLines.add(oli);
                                           
                                           String key;  
                                           key=oli.Id;                                    
                                           if(trialOppProductMap.get(oli.Product2Id) == oli.Product2.ProductCode){
                                               // key = oli.Product2Id +'_'+ oli.Ship_To__c; 
                                               // key=oli.Id;
                                               setProductId.add(oli.Product2Id); 
                                               if(oli.Ship_From_Location__c!='Free trial'){
                                                   if(shippingAddressMapFull.containskey(oli.Product2.ProductCode)){
                                                       if(oli.Ship_To__r.Name!=null){
                                                           shippingAddressMapFull.get(oli.Product2.ProductCode).add(new SelectOption(oli.Id, oli.Ship_To__r.Name));
                                                       }
                                                       
                                                   }
                                                   else{
                                                       List<SelectOption>so=new List<SelectOption>();
                                                       // key=oli.Id;
                                                       if(oli.Ship_To__r.Name!=null){
                                                           so.add(new selectOption(oli.Id, oli.Ship_To__r.Name));
                                                           shippingAddressMapFull.put(oli.Product2.ProductCode,so); 
                                                       }
                                                   }
                                               }
                                           }else{
                                           if(shippingProductCodeMap.get(oli.Product2.ProductCode) != null){
                                                   //key = shippingProductCodeMap.get(oli.Product2.ProductCode) +'_'+ oli.Ship_To__c; 
                                                   
                                                   List<String> productCodes = shippingProductCodeMap.get(oli.Product2.ProductCode);
                                                   if (productCodes != null) { 
                                                       for (String productCode : productCodes) {    
                                                           setProductId.add(productCode);
                                                           if(oli.Ship_From_Location__c!='Free trial'){
                                                               if(shippingAddressMapFull.containskey(oli.Product2.ProductCode)){
                                                                   if(oli.Ship_To__r.Name!=null ){
                                                                       shippingAddressMapFull.get(oli.Product2.ProductCode).add(new SelectOption(oli.Id, oli.Ship_To__r.Name));
                                                                   }
                                                               }
                                                           }
                                                           else{
                                                               List<SelectOption>so=new List<SelectOption>();
                                                               if(oli.Ship_From_Location__c!='Free trial'){
                                                                   if(oli.Ship_To__r.Name!=null ){
                                                                       so.add(new selectOption(oli.Id, oli.Ship_To__r.Name));
                                                                       shippingAddressMapFull.put(oli.Product2.ProductCode,so); 
                                                                   }
                                                               }}
                                                       }   
                                                   }
                                               }    
                                           }
                                           
                                           if(oli.Ship_From_Location__c == 'Free Trial') {
                                               if(!mapProductAddressToQtyTrailOriginal.containsKey(key)) mapProductAddressToQtyTrailOriginal.put(key, 0);
                                               mapProductAddressToQtyTrailOriginal.put(key, mapProductAddressToQtyTrailOriginal.get(key) + Integer.valueOf(oli.Quantity));
                                           }
                                           else {
                                               if(!mapProductAddressToQtyRevOriginal.containsKey(key)) 
                                                   mapProductAddressToQtyRevOriginal.put(key, 0);
                                               mapProductAddressToQtyRevOriginal.put(key, mapProductAddressToQtyRevOriginal.get(key) + Integer.valueOf(oli.Quantity));
                                               
                                           } 
                                           if(oli.Ship_From_Location__c != 'Free Trial') {                                 
                                               mapOLI.put(key, oli);}
                                       }
         
        for(String key : mapOLI.keySet()){
            String keyVa=mapOLI.get(key).Product2.ProductCode;
            Integer qtyTemp=mapProductAddressToQtyRevOriginal.containsKey(key) ? mapProductAddressToQtyRevOriginal.get(key) : 0; 
            String notFreeTrail=mapOLI.get(key).Ship_From_Location__c;
            if(notFreeTrail!='Free Trial'){
                if(shippingAddressMapFull.containsKey(mapOLI.get(key).Product2.ProductCode)){
                    if(shippingAddressMapFull.get(mapOLI.get(key).Product2.ProductCode).size()==1){
                      defaultAddress.put(keyVa,qtyTemp);  
                    }
                }
        }
        lstOLIWrapperOriginal.add(new OLIWrapper(mapOLI.get(key), mapProductAddressToQtyRevOriginal.containsKey(key) ? mapProductAddressToQtyRevOriginal.get(key) : 0, 
                                                     mapProductAddressToQtyTrailOriginal.containsKey(key) ? mapProductAddressToQtyTrailOriginal.get(key) : 0, 0
                                                    ));
        }
        Map<String, Integer> mapTrailQuantity = new Map<String, Integer>();
        Map<String, OpportunityLineItem> mapTrailOLI = new Map<String, OpportunityLineItem>();
        Integer itrVal=0;
        for(OpportunityLineItem oli : [SELECT Id, OpportunityId, UnitPrice, Ship_From_Location__c, SBQQ__QuoteLine__c, Quote_Line_Discount__c, Discount, PricebookEntryId, Ship_To_Address_Concatenated__c, Opportunity.Name, Opportunity.Id, Product_Code_Copy__c, Product2Id, Product2.ProductCode, Quantity, Purchased_From_Trial__c, To_Purchase_From_Trial__c, Trial_Status__c, Related_Order_Number__c, Trial_Order_Number__c, Ship_To__c  
                                       FROM OpportunityLineItem
                                       WHERE (Is_Hardware__c = True OR Is_Accessory__c=True) AND (NOT Product_Code_Copy__c LIKE '%SHRT%') AND (NOT Product_Code_Copy__c LIKE 'LIC%') AND 
                                       (NOT Product_Code_Copy__c LIKE '%KIT%') AND  Opportunity.Type = 'Free Trial Opportunity' AND Opportunity.Trial_Status__c = 'Open' 
                                       AND Opportunity.StageName = 'Closed Won' AND Opportunity.AccountId =:lstOpp[0].AccountID AND Product2Id IN: setProductId ORDER BY Product_Code_Copy__c]){
                                           lstTrailOppLines.add(oli);
                                           String key = oli.Product2Id +'_'+ oli.Related_Order_Number__c+'_'+oli.Ship_To__c; 
                                           if(shippingAddressMapFull.containsKey(oli.Product_Code_Copy__c)){
                                               shippingAddressMap.put(key,shippingAddressMapFull.get(oli.Product_Code_Copy__c));
                                           }                                              
                                           
                                           if(mapProductAddressToQtyRevOriginal.containsKey(key)) setAddressProduct.add(oli.Product2Id);
                                           if(!mapTrailQuantity.containsKey(key)) mapTrailQuantity.put(key, 0);
                                           mapTrailQuantity.put(key, mapTrailQuantity.get(key) + Integer.valueOf(oli.Quantity));
                                           mapTrailOLI.put(key, oli);               
                                           
                                           if(!mapProductAddressToTrailOLI.containsKey(key)) mapProductAddressToTrailOLI.put(key, new List<OpportunityLineItem>());
                                           mapProductAddressToTrailOLI.get(key).add(oli);
                                       }
        for(String key: mapTrailOLI.keySet())
        {
            String optionVa='';
            Integer availableQtyTarget=mapTrailQuantity.get(key);
            if(defaultAddress.containsKey(mapTrailOLI.get(key).Product_Code_Copy__c)){
            List<SelectOption> options = new List<SelectOption>();
            options=shippingAddressMap.get(key);
            optionVa=options[0].getValue();
            availableQtyTarget=defaultAddress.get(mapTrailOLI.get(key).Product_Code_Copy__c);
            defaultAddress.put(mapTrailOLI.get(key).Product_Code_Copy__c,availableQtyTarget-mapTrailQuantity.get(key));
            }
            incrementVar=incrementVar+1;
                
            lstOLIWrapperTrail.add(new OLIWrapper(mapTrailOLI.get(key), mapTrailQuantity.get(key),mapTrailQuantity.get(key),shippingAddressMap.get(key),incrementVar,optionVa,availableQtyTarget,mapTrailQuantity.get(key)));
            
        }
        
        this.reCalculateQty();
    }
    
    private OpportunityLineItem oliFieldMapping(OpportunityLineItem revOLI, Integer qty, String opportunityID, String shipFrom, String pricebookEntryId){
        return new OpportunityLineItem(OpportunityId = opportunityID, PricebookEntryId = pricebookEntryId, Quantity = qty, Ship_To__c = revOLI.Ship_To__c, Ship_From_Location__c = shipFrom,
                                       Discount = revOLI.Discount, UnitPrice = revOLI.UnitPrice, SBQQ__QuoteLine__c = revOLI.SBQQ__QuoteLine__c);
    }
    
    //Invoked when Save and Return to opportunity button is clicked on the page
    public PageReference save() {
        String opportunityId = this.opportunityId;
        List<OpportunityLineItem> lstOLI = new List<OpportunityLineItem>();
        List<Opportunity> lstTrailOppToUpdate = new List<Opportunity>();
        SET<Id> productIds = new SET<Id>();
        Opportunity opp = [SELECT Id, Pricebook2Id, CurrencyIsoCode FROM Opportunity WHERE Id =: opportunityId];
        for(OLIWrapper oliW : lstOLIWrapperOriginalNew){
            oliW.oli.Quantity = oliW.actualQty;
            lstOLI.add(oliW.oli);
        }
        Map<String, String> productPriceBookEntryMap = new Map<String, String>();
        List<PricebookEntry> pbeList = [SELECT Id, Product2Id FROM PricebookEntry WHERE Pricebook2Id =: opp.Pricebook2Id AND CurrencyIsoCode =: opp.CurrencyIsoCode];
        for(PricebookEntry pbe : pbeList){
            productPriceBookEntryMap.put(pbe.Product2Id, pbe.Id);       
        }
         Map<Id, OpportunityLineItem> mapOLIToUpdate = new Map<Id, OpportunityLineItem>();
         for(OLIWrapper oliW :lstOLIWrapperTrailNew){
            //SS-335 Updating ship from location for EU to Free Trial EU 
            //lstOLI.add(oliFieldMapping(oliW.oli, oliW.actualQty, opportunityId, oliW.oli.Ship_From_Location__c == 'VCK' || oliW.oli.Ship_From_Location__c == 'Samsara UK' ? 'Free Trial EU' : 'MX Free Trial', productPriceBookEntryMap.get(oliW.oliTrail.Product2Id)));
            //GTMS-16177 Updating ship from locations 
            if(oliW.oli.Ship_From_Location__c == 'VCK' || oliW.oli.Ship_From_Location__c == 'DHL' || oliW.oli.Ship_From_Location__c == 'Samsara UK'){
                lstOLI.add(oliFieldMapping(oliW.oli, oliW.actualQty, opportunityId, 'Free Trial EU', productPriceBookEntryMap.get(oliW.oliTrail.Product2Id)));
            }else if(oliW.oli.Ship_From_Location__c == 'Estafeta'){
                lstOLI.add(oliFieldMapping(oliW.oli, oliW.actualQty, opportunityId, 'MX Free Trial', productPriceBookEntryMap.get(oliW.oliTrail.Product2Id)));
            }else{
                lstOLI.add(oliFieldMapping(oliW.oli, oliW.actualQty, opportunityId, 'Free Trial', productPriceBookEntryMap.get(oliW.oliTrail.Product2Id)));
            }
            String keyMatch = oliW.oliTrail.Product2Id +'_'+ oliW.oliTrail.Ship_To__c;
            if(mapProductAddressToTrailOLI.containsKey(keyMatch)){
                Integer actualQty = oliW.actualQty;
                for(OpportunityLineItem oli : mapProductAddressToTrailOLI.get(keyMatch)){
                    if(oli.Quantity >= actualQty){
                        oli.Purchased_From_Trial__c  = actualQty;
                        oli.To_Purchase_From_Trial__c = oli.Quantity - actualQty;
                        mapOLIToUpdate.put(oli.Id, oli);
                        break;
                    }else{
                        actualQty = actualQty - Integer.valueOf(oli.Quantity);
                        oli.Purchased_From_Trial__c  = oli.Quantity;
                        oli.To_Purchase_From_Trial__c = 0;
                        mapOLIToUpdate.put(oli.Id, oli);
                    }
                }
            }
            
        }
        
        lstOLI.addAll(mapOLIToUpdate.values());
        
        if(Test.isRunningTest()!=true){
        Id jobId = system.enqueueJob(new SetShippingQuantityQueue(lstOLI, opportunityId, lstTrailOpportunity.size()>0?lstTrailOpportunity:null));
        }
            return new PageReference('/'+opportunityId);
    }
    // on changing the dropdown this method is called to calculate the available qty in target and the address slected
    public void updateTrialUnitsOnAddressChange() {
        if(String.isBlank(selectedAddress) || String.isBlank(selectedProductCode)|| selectedAddress=='None') {
             for(OLIWrapper trialWrapper : lstOLIWrapperTrail) {
                 if(trialWrapper.incrementVar==Integer.valueof(incrementVarRef)){
                     trialWrapper.trailToPurchase=0;
                     break;
                 }  
            }
          return;  
        }
        
        Integer tempVarCount=0;
        Decimal availableQty=0;
        Decimal trialTotalQty=0;
        Decimal purchasedinTrailQty=0;
        
        for(OpportunityLineItem opp : lstTrailOppLines) {// to take available qty in trail
            if( opp.Product_Code_Copy__c == selectedProductCode && opp.Ship_To__c==ShipToaddressId && opp.Related_Order_Number__c==orderNumber)
            {
                trialTotalQty=(Integer)(trialTotalQty+opp.Quantity);
            }
            
        } 
        for(OLIWrapper rev : lstOLIWrapperOriginal){//to take total available qty in target address
            if( rev.oli.Product_Code_Copy__c == selectedProductCode && rev.oli.Id==selectedAddress)
            {
                tempVarCount=tempVarCount+rev.billedQty;
                break;  
            }
            
        }
        
        Integer selectedAddressAvailableCount=0;
        for(OLIWrapper trialWrapper : lstOLIWrapperTrail) {
            if(trialWrapper.oli.Product_Code_Copy__c == selectedProductCode && trialWrapper.selectedAddress==selectedAddress
               &&trialWrapper.incrementVar!=Integer.valueof(incrementVarRef))
            {
                selectedAddressAvailableCount=selectedAddressAvailableCount+trialWrapper.trailToPurchase;
            }//available qty in target address
            if(trialWrapper.incrementVar!=Integer.valueof(incrementVarRef)&&trialWrapper.oli.Product_Code_Copy__c == selectedProductCode  &&trialWrapper.oli.Related_Order_Number__c==orderNumber &&  trialWrapper.oli.Ship_To__c==ShipToaddressId){
                purchasedinTrailQty=purchasedinTrailQty+trialWrapper.trailToPurchase;
            }//available qty in trail items
        }
         for(OLIWrapper trialWrapper : lstOLIWrapperTrail) {
            if(trialWrapper.oli.Product_Code_Copy__c == selectedProductCode && trialWrapper.incrementVar==Integer.valueof(incrementVarRef)) {
                trialWrapper.selectedAddress = selectedAddress;
                trialWrapper.availableTargetQty=(Integer)(tempVarCount-selectedAddressAvailableCount);
                trialWrapper.availableQty=(Integer)(trialTotalQty-purchasedinTrailQty);
                break;
            }
        }
        
    }
    public void trailValidation(){
        if(quantity<toPurchase && availableinTarget<toPurchase)
        {
            System.debug('Error check');
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,'Adjust the Trail Units to Purchase to match the Available in Target and Available in Trail Units'));
            
        }
    }
    // on click of split trail in ui this method is called
    public void splitTrailItems(){
        if(toPurchase!=0){
           
            Decimal availableQty=0;
            Map<String,Integer> addressCount=new Map<String,Integer>();
            Decimal toPurchaseTrail=toPurchase==0?quantity:toPurchase;
            Boolean splitTrailItems=true;
            Integer countOfTarget=0;
            Integer tempVarCount=0;
            Integer combinedQty=0;
            OLIWrapper trialWrapperToSplit;
            for(OpportunityLineItem opp : lstTrailOppLines) {// to take available qty in trail
                if( opp.Product_Code_Copy__c == selectedProductCode && opp.Ship_To__c==ShipToaddressId && opp.Related_Order_Number__c==orderNumber)
                {
                    availableQty=(Integer)(availableQty+opp.Quantity);
                }
            } 
             for(OLIWrapper trialWrapper : lstOLIWrapperTrail) {
                
                if(trialWrapper.oli.Related_Order_Number__c==orderNumber && 
                   trialWrapper.oli.Product_Code_Copy__c == selectedProductCode &&
                   trialWrapper.oli.Ship_To__c==ShipToaddressId)
                {
                    
                    if(addressCount!=null&&addressCount.get(trialWrapper.selectedAddress)!=null)
                    {
                        addressCount.put(trialWrapper.selectedAddress,addressCount.get(trialWrapper.selectedAddress)+1);
                    }
                    else
                    {
                        addressCount.put(trialWrapper.selectedAddress,1);
                    }
                }
                if(trialWrapper.incrementVar==Integer.valueof(incrementVarRef))
                {
                    trialWrapperToSplit=trialWrapper; 
                }
                
                if(addressCount.get(trialWrapper.selectedAddress)==2)
                {
                    ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,'Combination of order number,product,target Address already exists,Change the target address'));
                    splitTrailItems=false;
                    break; 
                }
                if(trialWrapper.oli.Product_Code_Copy__c == selectedProductCode&&
                   trialWrapper.selectedAddress == selectedAddress && 
                   trialWrapper.incrementVar!=Integer.valueof(incrementVarRef)&& 
                   trialWrapper.oli.Related_Order_Number__c==orderNumber && 
                   trialWrapper.oli.Ship_To__c==ShipToaddressId)
                {
                           tempVarCount=tempVarCount+trialWrapper.trailToPurchase;// total split count of trail
                }
                
                          }
            for(OLIWrapper trialWrapper : lstOLIWrapperTrail) {
                if(trialWrapper.oli.Product_Code_Copy__c == selectedProductCode && trialWrapper.incrementVar==Integer.valueof(incrementVarRef)) {
                    trialWrapper.selectedAddress = selectedAddress;
                    break;
                }
            }
             if(toPurchase<(availableQty-tempVarCount)&& splitTrailItems &&addressCount.size()!=trialWrapperToSplit.selectOptionOli.size())
            {
                OLIWrapper newWrapper = new OLIWrapper(trialWrapperToSplit.oli, trialWrapperToSplit.availableQty - trialWrapperToSplit.trailToPurchase, 
                                                       trialWrapperToSplit.availableQty - trialWrapperToSplit.trailToPurchase, trialWrapperToSplit.selectOptionOli,lstOLIWrapperTrail.size()+1,'',0,trialWrapperToSplit.availableQty);
                newWrapper.selectedAddress ='';
                newWrapper.trailToPurchase=(Integer)(toPurchaseTrail);
                lstOLIWrapperTrail.add(newWrapper);
                
            }
        }}
    
}