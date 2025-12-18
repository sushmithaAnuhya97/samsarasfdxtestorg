/* 12/17/2018 - SS-177 Added the logic to support Canadian Dollar, Swiss Franc and Mexican Pesos. - @author: Harsha
 * 01/31/2019 - Added changes to support and display ACV Fields on the page. - @uthor: Harsha
 * August 6th, 2020 Ron Saavedra - (GTMS-1301) AddProductsAndLicensesExtension, setLicenseTermAndResetPrices, getInputPrices, saveInformation, calculateOverDiscount (enable non-0 hardware sales by blocking change of replacement hardware through this page)
 */
 
public with sharing class AddProductsAndLicensesExtension {
    private ApexPages.StandardController stdOpptyController;
    public Opportunity oppty;
    public Opportunity vOpportunity;
    public String pricebook_name;
    public String configuration_segment;
    public List<PricebookEntry> pricebook_entries{get; set;}
    public string callfunc{get;set;}
    public List<OpportunityLineItem> sorted_oppty_line_items{get; set;}
    public Boolean editable_prices{get; set;}   // Negotiate By Price: This was used for the MM AE's who are no longer using the add products page
    public Boolean express_opportunity{get; set;}
    public Boolean over_discount{get; set;}
    public Boolean cotermed_account{get; set;}
    public Decimal prorated_price{get; set;} // Not used
    public Decimal express_discount{get; set;}
    public Decimal suggested_term_discount{get; set;}
    public Decimal extended_license_discount{get; set;}
    public Boolean deal_reg{get; set;}
    public Boolean free_trial_opportunity{get; set;}
    public Boolean return_opportunity{get; set;}
    public Date contract_cotermination_date{get; set;}
    public Decimal months_to_coterm{get; set;}
    public String country{get; set;}
    public Decimal coterm_period{get; set;}
    public String opportunity_type{get; set;}
    public Decimal alternative_license_term{get; set;}
    public Decimal selected_license_term{get; set;}
    public Decimal alternative_license_term_from_cotermed{get; set;}
    public Decimal total_amount{get; set;}
    public Decimal totalAcvBooking{get; set;}
    public Decimal ACV{get; set;}
    public Decimal total_discretionary_discount{get; set;}
    public Decimal total_final_discount{get; set;}
    public Decimal approved_discretionary_discount{get; set;}
    public Boolean manager_permission{get; set;}
    public Id opportunity_shipping_address;
    
    public String[] pricebook_names = new String[]{}; // Not used
    public String[] pricebook_codes = new String[]{}; // Not used
    public String[] selected_hardwares = new String[]{};
    public String[] selected_terms = new String[]{};
    public String[] selected_licenses = new String[]{};
    public String[] selected_accessories = new String[]{};
    
    public Map<String, Decimal> inputQuantityMap{get; set;}
    public Map<String, Decimal> inputPriceMap{get; set;}
    public Map<String, Decimal> inputDiscountMap{get; set;}
    public Map<String, Boolean> inputRemovalMap{get; set;}
    
    public List<SelectOption> getItems() {
        return null;
    }

    //* August 6th, 2020 Ron Saavedra - (GTMS-1301) AddProductsAndLicensesExtension, setLicenseTermAndResetPrices, getInputPrices, saveInformation, calculateOverDiscount (enable non-0 hardware sales by blocking change of replacement hardware through this page)
    public AddProductsAndLicensesExtension(ApexPages.StandardController sc){
        this.stdOpptyController = sc;
        this.oppty = (Opportunity) sc.getRecord();

        Opportunity vOpportunity = [
                SELECT Account.Id,Shipping_Address_NEW__c,
                        CurrencyIsoCode,
                        Express_Selected_Discount__c,
                        License_Term__c,
                        Max_Approved_Discount__c,
                        LeadSource,
                        Type,
                        Amount,
                        Selected_Payment_Type__c,
                        CloseDate,
                        Pricebook2Id,
                        Pricebook2.Name,
                        Configuration_Segment__c,
                        ACV_Bookings_SOT__c, (
                        SELECT Id,
                                Ship_To__c,
                                Discount,
                                UnitPrice,
                                ListPrice,
                                Express_Annual_Discount__c,
                                Selected_Sales_Price__c,
                                TotalPrice,
                                Product_Code_Copy__c,
                                Quantity,
                                ProductCode,
                                Shipped_Quantity__c,
                                OpportunityId,
                                Suggested_Sales_Price__c,
                                Line_List_Price__c,
                                Replacement__c
                        FROM OpportunityLineItems //WHERE ListPrice > 0
                        ORDER BY CreatedDate DESC
                ),
                        Account.Co_Term_Account__c,
                        Account.Co_Term_License_Date__c,
                        Account.First_Purchase_Date__c
                FROM Opportunity
                WHERE Id = :THIS.oppty.Id
        ];

        this.vOpportunity = vOpportunity;
        this.pricebook_name=vOpportunity.Pricebook2.Name;

        this.pricebook_entries = [
                SELECT Id, Name, ProductCode, UnitPrice, Product2.Name
                FROM PricebookEntry
                WHERE Pricebook2.Name = :THIS.pricebook_name
                AND CurrencyIsoCode = :vOpportunity.CurrencyIsoCode
                AND Is_Hidden__c = FALSE
                AND IsActive = TRUE
                ORDER BY ProductCode ASC
        ];
        this.sorted_oppty_line_items = [
                SELECT Id, Ship_To__c,
                        Deal_Reg_Discount__c,
                        PricebookEntry.Name,
                        Product_Code_Copy__c,
                        License_Term_Copy__c,
                        ACV_Total_Price_Bookings__c, Quantity, ListPrice, UnitPrice, Discount, TotalPrice, Suggested_Sales_Price__c,
                        Suggested_Line_Price__c, Selected_Sales_Price__c, Replacement__c
                FROM OpportunityLineItem
                WHERE OpportunityId = :THIS.oppty.Id
                ORDER BY CreatedDate DESC
        ];

        this.alternative_license_term=vOpportunity.License_Term__c;
        this.total_amount=vOpportunity.Amount;
        this.totalAcvBooking = vOpportunity.ACV_Bookings_SOT__c;
        this.opportunity_type=vOpportunity.Type;
        this.opportunity_shipping_address = vOpportunity.Shipping_Address_NEW__c;
        this.selected_license_term=vOpportunity.License_Term__c;
        this.express_opportunity=false;
        this.express_discount=0.00;

        setCountry(vOpportunity);

        setExpressDiscount(vOpportunity);

        this.free_trial_opportunity=false;
        this.return_opportunity=false;
        if(vOpportunity.Type=='Free Trial Opportunity'){
            this.free_trial_opportunity=true;
            this.cotermed_account=false;
            this.alternative_license_term=1;
        }


        this.manager_permission = false;
        User vUser = [SELECT Id, Profile.Name, Negotiate_By_Price__c FROM User WHERE Id = :UserInfo.getUserId()];
        List<String> profiles = new List<String>{
                'System Administrator', 'Samsara Sales Management', 'Order Operations Admin', 'Samsara Sales Management - New System', 'Sales Ops Profile'
        };
        if (profiles.contains(vUser.Profile.Name)) {
            this.manager_permission = true;
        }
        this.editable_prices = vUser.Negotiate_By_Price__c;

        Account vAccount = vOpportunity.Account;
        this.cotermed_account=vAccount.Co_Term_Account__c;
        this.months_to_coterm=1;
        this.coterm_period=1;

        this.free_trial_opportunity=false;
        this.return_opportunity=false;
        if(vOpportunity.Type=='Free Trial Opportunity'){
            this.free_trial_opportunity=true;
            this.cotermed_account=false;
            this.alternative_license_term=1;
        }

        if(this.cotermed_account && !this.free_trial_opportunity){
            Date coterm_date=vAccount.Co_Term_License_Date__c;

            Date today=System.today();
            Date close_date=today;
            if(vOpportunity.CloseDate!=null && close_date>today){
                close_date=vOpportunity.CloseDate;
            }
            Date first_purchase_date=close_date;
            if(vAccount.First_Purchase_Date__c!=null){
                first_purchase_date=vAccount.First_Purchase_Date__c;
            }
            if(coterm_date==null){
                this.coterm_period=1;
                this.months_to_coterm=1;
                this.alternative_license_term_from_cotermed=this.oppty.License_Term__c;
                this.contract_cotermination_date=Date.today();
            }
            else{
                this.months_to_coterm = close_date.monthsBetween(coterm_date);
                this.coterm_period = first_purchase_date.monthsBetween(coterm_date);
                this.alternative_license_term_from_cotermed=this.oppty.License_Term__c;
                this.contract_cotermination_date=coterm_date;
            }
        }


        this.deal_reg=false;
        if(vOpportunity.LeadSource=='Deal Reg Form'){
            this.deal_reg=true;
        }

        this.inputQuantityMap = new Map<String, Decimal>();
        this.inputPriceMap = new Map<String, Decimal>();
        this.inputDiscountMap = new Map<String, Decimal>();
        this.inputRemovalMap = new Map<String, Boolean>();

        this.over_discount=false;

        if(this.free_trial_opportunity==false && vOpportunity.Type!='Promo Opportunity' && this.express_opportunity==false){
            calculateOverDiscount();
        }

        calculateExtendedLicenseDiscount();

        this.suggested_term_discount=0;
        if(this.oppty.License_Term__c>=84){
            this.suggested_term_discount=40;
        }
        else if(this.oppty.License_Term__c>=60){
            this.suggested_term_discount=30;
        }
        else if(this.oppty.License_Term__c>=36){
            this.suggested_term_discount=20;
        }
        else if(this.oppty.License_Term__c>=36){
            this.suggested_term_discount=20;
        }

    }
    
    public void insertSelectedLineItems (Id[] selectedLineItems){
        if (selectedLineItems.size() > 0) {
            // Just use this.oppty?
//            Opportunity[] o = [Select License_Term__c, Pricebook2.Name from Opportunity where Id=:this.oppty.id];
            Opportunity vOpportunity = this.vOpportunity;
//            Decimal licenseTerm=vOpportunity.License_Term__c;
            Decimal selectedSalesPriceForInsert;
            Decimal unitPriceForInsert;
//            pricebook_name=o[0].Pricebook2.Name;


            Map<Id, PricebookEntry> itemToEntry = new Map<Id, PricebookEntry>([
                    SELECT Id,UnitPrice,Product2.ProductCode
                    FROM PricebookEntry
                    WHERE Pricebook2.Name = :pricebook_name
                    AND Id IN :selectedLineItems
            ]);
//            List<PricebookEntry> pricebook_entries = [SELECT Id,UnitPrice,Product2.ProductCode
//                                                   FROM PricebookEntry
//                                                   WHERE Pricebook2.Name = :pricebook_name
//                                                   AND Id IN :selectedLineItems];
//            for (PricebookEntry entry : pricebook_entries) {
//                itemToEntry.put(entry.Id, entry);
//            }
            
            List<OpportunityLineItem> itemsToInsert = new List<OpportunityLineItem>();
            for (String item : selectedLineItems){
                PricebookEntry currEntry = itemToEntry.get(item);

                if(currEntry.Product2.ProductCode.startsWith('LIC')) {
                    selectedSalesPriceForInsert = currEntry.UnitPrice/12;
                    unitPriceForInsert = selectedSalesPriceForInsert * vOpportunity.License_Term__c;
                } else {
                    selectedSalesPriceForInsert = currEntry.UnitPrice;
                    unitPriceForInsert = currEntry.UnitPrice;
                }
                OpportunityLineItem newLineItem = new OpportunityLineItem (Quantity=1.00, 
                                                                           Shipped_Quantity__c = 0.00, 
                                                                           License_Term_Copy__c = vOpportunity.License_Term__c,
                                                                           OpportunityId = this.oppty.Id, 
                                                                           PricebookEntryId = currEntry.Id,
                                                                           UnitPrice = unitPriceForInsert,
                                                                           Selected_Sales_Price__c = selectedSalesPriceForInsert,
                                                                           Discount = 0.00);//Zakeer-GTMS-5381removed--> Ship_From_Location__c = 'DCL' because of GTMS-5381, Biz doesn't want to default to DCL
                itemsToInsert.add(newLineItem);
            }
            insert itemsToInsert;
        }
    }
    
  
    // DONE
    public PageReference addProducts() {    
        String[] products = this.selected_hardwares;
        products.addAll(this.selected_licenses);
        products.addAll(this.selected_accessories);
        insertSelectedLineItems(products);
        
//        this.stdOpptyController.save();
        PageReference pr = new PageReference('/apex/AddProductsAndLicenses?scontrolCaching=1&id='+this.oppty.Id);
        pr.setRedirect(true);
        return pr;
    }

    /* 
    public PageReference selectStandardPricebook() {
        return selectPricebook('Standard');
    }

    public PageReference selectExpressPricebook() {
        return selectPricebook('Express');
    } */

    // Code to select the Pricebook and associate it with the opportunity.
    public PageReference selectPricebook() {
        
        Pricebook2 pb = [   SELECT Id 
                            FROM Pricebook2 
                            WHERE Id =: System.Label.Current_Active_Pricebook
                            LIMIT 1];
        
        this.oppty.Pricebook2Id = pb.Id;
        this.stdOpptyController.save();

        PageReference pr = new PageReference('/apex/AddProductsAndLicenses?scontrolCaching=1&id='+this.oppty.Id);
        pr.setRedirect(true);
        return pr;
    }
    
    //* August 6th, 2020 Ron Saavedra - (GTMS-1301) AddProductsAndLicensesExtension, setLicenseTermAndResetPrices, getInputPrices, saveInformation, calculateOverDiscount (enable non-0 hardware sales by blocking change of replacement hardware through this page)
    public PageReference setLicenseTermAndResetPrices(Decimal licenseTerm) {
        if(licenseTerm>0){
        
            //List<OpportunityLineItem> opptyLineItems = [Select Product_Code_Copy__c, ListPrice, Ship_From_Location__c, UnitPrice, TotalPrice, Quantity, Suggested_Sales_Price__c, License_Term_Copy__c from OpportunityLineItem where OpportunityId = :this.oppty.Id];
            List<OpportunityLineItem> opptyLineItems = this.vOpportunity.OpportunityLineItems;

            for (OpportunityLineItem li : opptyLineItems){
                li.License_Term_Copy__c=null;
            }

            this.oppty.License_Term__c=licenseTerm;
            update this.oppty;
            
            Decimal suggestedDiscount = 0;
            
            for (OpportunityLineItem li : opptyLineItems){
                 
                suggestedDiscount = 0; 
                
                if(!li.Replacement__c){
                    li.Selected_Sales_Price__c=li.ListPrice*(1-suggestedDiscount);
                }
                else{
                    li.Selected_Sales_Price__c=li.UnitPrice*(1-suggestedDiscount);
                }
                 
                if(li.Product_Code_Copy__c.startsWith('LIC') && !li.Product_Code_Copy__c.contains('EXPRESS')){
                 
                    if(licenseTerm>=84){
                       suggestedDiscount=0.3;
                    }
                    else if(licenseTerm>=60){
                       suggestedDiscount=0.3;
                    }
                    else if(this.deal_reg){
                       suggestedDiscount=0.25;
                    }
                    else if(licenseTerm>=36){
                       suggestedDiscount=0.2;
                    }
                    if(this.express_opportunity){
                        this.inputPriceMap.put(li.Id,(li.ListPrice.setScale(2)));
                    }
                    else{
                        this.inputPriceMap.put(li.Id,(li.ListPrice.setScale(2))*licenseTerm/12);
                    }
                    
                }
                else{
                    if(this.deal_reg){
                       suggestedDiscount=0.25;
                    }
                    this.inputPriceMap.put(li.Id,li.ListPrice);            
                }
                this.inputDiscountMap.put(li.Id, 0.00);
           }
        }
//        this.stdOpptyController.save();

        PageReference pr = new PageReference('/apex/AddProductsAndLicenses?scontrolCaching=1&id='+this.oppty.Id);
        pr.setRedirect(true);
        return pr;
    }
    
    
    public PageReference setLicenseTermInputField() {

        return setLicenseTermAndResetPrices(this.alternative_license_term);
        
//        this.stdOpptyController.save();
//        PageReference pr = new PageReference('/apex/AddProductsAndLicenses?scontrolCaching=1&id='+this.oppty.Id);
//        pr.setRedirect(true);
//        return pr;
    
    }
    
    public PageReference setLicenseTermFromCotermed() {

        return setLicenseTermAndResetPrices(this.alternative_license_term_from_cotermed);
        
//        this.stdOpptyController.save();
//        PageReference pr = new PageReference('/apex/AddProductsAndLicenses?scontrolCaching=1&id='+this.oppty.Id);
//        pr.setRedirect(true);
//        return pr;
    
    }
    
    public PageReference defaultLicenseTermFromCotermed() {

        return setLicenseTermAndResetPrices(this.months_to_coterm);
        
//        this.stdOpptyController.save();
//        PageReference pr = new PageReference('/apex/AddProductsAndLicenses?scontrolCaching=1&id='+this.oppty.Id);
//        pr.setRedirect(true);
//        return pr;
    
    }
    
     public PageReference defaultLicenseTermFromExpress() {

        if(this.oppty.License_Term__c==12){
            return setLicenseTermAndResetPrices(36);
        }
        
        else{
            return setLicenseTermAndResetPrices(12);
        }
        
        
//        this.stdOpptyController.save();
//        PageReference pr = new PageReference('/apex/AddProductsAndLicenses?scontrolCaching=1&id='+this.oppty.Id);
//        pr.setRedirect(true);
//        return pr;
    
    }
  
    public PageReference setLicenseTermSelectList() {

        return setLicenseTermAndResetPrices(this.selected_license_term);
        
//        this.stdOpptyController.save();
//        PageReference pr = new PageReference('/apex/AddProductsAndLicenses?scontrolCaching=1&id='+this.oppty.Id);
//        pr.setRedirect(true);
//        return pr;
    }
    
    
    public PageReference switchEditableMode() {

        this.editable_prices=!this.editable_prices;

        Id user_id = UserInfo.getUserId();
        User[] u = [Select Negotiate_By_Price__c from User where Id = :user_id];
        u[0].Negotiate_By_Price__c=this.editable_prices;

        update u;

//        this.stdOpptyController.save();
        PageReference pr = new PageReference('/apex/AddProductsAndLicenses?scontrolCaching=1&id='+this.oppty.Id);
        pr.setRedirect(true);
        return pr;
    }


    // TODO: Looks like this method is not used anywhere
    public PageReference saveCotermStatus() {
    
       Opportunity[] o = [Select Account.Id from Opportunity where Id=:this.oppty.id];
       String account_id=o[0].Account.Id;
       Account[] a = [Select Co_Term_Account__c from Account where Id=:account_id];
      
       //if(this.cotermed_account==true && checkbox==false){
       if(this.cotermed_account==true && a[0].Co_Term_Account__c==false){
           //this.cotermed_account=false;
           a[0].Co_Term_Account__c=true;
           update a[0];
       }
       //else if(this.cotermed_account==false && checkbox==true){
       else if(this.cotermed_account==false && a[0].Co_Term_Account__c==true){
           //this.cotermed_account=true;
           a[0].Co_Term_Account__c=false;
           update a[0];
       }
       
       //return null;
       //return new PageReference('/apex/AddProductsAndLicenses?scontrolCaching=1&id='+this.oppty.Id);
       this.stdOpptyController.save();
       PageReference pr = new PageReference('/apex/AddProductsAndLicenses?scontrolCaching=1&id='+this.oppty.Id);
       pr.setRedirect(true);
       return pr;
    }

    
    

    
    public List<SelectOption> getHardwares() {

//        List<SelectOption> options = new List<SelectOption>();
        
//        if(this.pricebook_name.contains('Standard')){
//            /*options.add(new SelectOption('01u1a000001mkUk','HW-VG34'));
//            options.add(new SelectOption('01u1a000001UM33','HW-CM11'));
//            options.add(new SelectOption('01u1a000001oLiK','HW-CM22'));
//            options.add(new SelectOption('01u1a000001oLRn','HW-AG24'));
//            options.add(new SelectOption('01u1a000001YvNB','HW-AG15'));
//            options.add(new SelectOption('01u1a000001TlLa','HW-EM22'));
//            options.add(new SelectOption('01u1a000001TlLV','HW-EM21'));
//            options.add(new SelectOption('01u1a000001noNF','HW-HM11'));
//            options.add(new SelectOption('01u1a000001LLIo','HW-IM33'));
//            options.add(new SelectOption('01u1a000001LLIU','HW-IM32'));
//            options.add(new SelectOption('01u1a0000017smn','HW-IM31'));
//            options.add(new SelectOption('01u1a0000018TE3','HW-PM20'));
//            options.add(new SelectOption('01u1a000001wVet','HW-IG11'));
//            options.add(new SelectOption('01u1a0000017smo','HW-GW22'));*/
//
//            for (PricebookEntry pe : this.pricebook_entries){
//                if(pe.ProductCode.startsWith('HW')){
//                    Boolean contained=False;
//                    for(SelectOption so : options){
//                        if(so.getValue()==pe.Id){
//                            contained=True;
//                        }
//                    }
//                    if(!contained){
//                        options.add(new SelectOption(pe.Id,pe.ProductCode));
//                    }
//                }
//            }
//        }
//
//        else{
//            for (PricebookEntry pe : this.pricebook_entries){
//                if(pe.ProductCode.startsWith('HW')){
//                    options.add(new SelectOption(pe.Id,pe.ProductCode));
//                }
//            }
//        }


        List<SelectOption> options = new List<SelectOption>();
        for (PricebookEntry pe : this.pricebook_entries){
            if(pe.ProductCode.startsWith('HW')){
                options.add(new SelectOption(pe.Id,pe.ProductCode));
            }
        }
        
        
        return options;
    }
    
    public List<SelectOption> getLicenses() {
        List<SelectOption> options = new List<SelectOption>();
        
        for (PricebookEntry pe : this.pricebook_entries){
        
            if(this.configuration_segment == 'Non Express'){
                if(pe.ProductCode.endsWith('ENT') || pe.ProductCode.endsWith('DATA')){
                    options.add(new SelectOption(pe.Id,pe.ProductCode));
                }
            }
            else{
                if(pe.ProductCode.startsWith('LIC') && !pe.ProductCode.endsWith('-MO')){
                    if(this.oppty.License_Term__c==12 && pe.ProductCode.endsWith('12MO')){
                        options.add(new SelectOption(pe.Id,pe.ProductCode));
                    }
                    else if((this.oppty.License_Term__c==36 || this.free_trial_opportunity) && !pe.ProductCode.endsWith('12MO')){
                        options.add(new SelectOption(pe.Id,pe.ProductCode));
                    }
                }
            }
        }
        
        
        return options;
    }
    
    public List<SelectOption> getAccesories() {
        List<SelectOption> options = new List<SelectOption>();
        
        for (PricebookEntry pe : this.pricebook_entries){
            if(!pe.ProductCode.startsWith('LIC') && !pe.ProductCode.startsWith('HW') && (!pe.ProductCode.contains('BUNDLE'))){
                options.add(new SelectOption(pe.Id,pe.ProductCode+' - '+pe.Name));    
            }
        }
        return options;
    }
    
    public List<SelectOption> getTerms() {
        List<SelectOption> options = new List<SelectOption>();
        
        options.add(new SelectOption('12','12 months (1 year)'));
        options.add(new SelectOption('36','36 months (3 years)'));
        options.add(new SelectOption('60','60 months (5 years)'));
        options.add(new SelectOption('84','84 months (7 years)'));
        
        return options;
    }
        
    public String[] getSelectedTerms() {
        //If multiselect is false, countries must be of type String
        return selected_terms;
    }
        
    public void setSelectedTerms(String[] selected_terms) {
        //If multiselect is false, countries must be of type String
        this.selected_terms = selected_terms;
    }
    
    public String[] getSelectedHardwares() {
        //If multiselect is false, countries must be of type String
        return selected_hardwares;
    }
        
    public void setSelectedhardwares(String[] selected_hardwares) {
        //If multiselect is false, countries must be of type String
        this.selected_hardwares = selected_hardwares;
    }
    
    public String[] getSelectedLicenses() {
        //If multiselect is false, countries must be of type String
        return selected_licenses;
    }
        
    public void setSelectedLicenses(String[] selected_licenses) {
        //If multiselect is false, countries must be of type String
        this.selected_licenses = selected_licenses;
    }
    
    public String[] getSelectedAccesories() {
        //If multiselect is false, countries must be of type String
        return selected_accessories;
    }
        
    public void setSelectedAccesories(String[] selected_accessories) {
        //If multiselect is false, countries must be of type String
        this.selected_accessories = selected_accessories;
    }


    public Map<String, Decimal> getInputQuantities() {
        List<OpportunityLineItem> opportunityLineItems = this.vOpportunity.OpportunityLineItems;
        if (opportunityLineItems.size() > 0) {
            for (OpportunityLineItem li : opportunityLineItems) {
                if (li.Quantity != null) {
                    this.inputQuantityMap.put(li.Id, li.Quantity);
                }
            }
        }
        System.debug('inputQuantityMap:' + this.inputQuantityMap);
        return this.inputQuantityMap;
    }

    //* August 6th, 2020 Ron Saavedra - (GTMS-1301) AddProductsAndLicensesExtension, setLicenseTermAndResetPrices, getInputPrices, saveInformation, calculateOverDiscount (enable non-0 hardware sales by blocking change of replacement hardware through this page)
    public Map<String, Decimal> getInputPrices() {
        List<OpportunityLineItem> opptyLineItems = this.vOpportunity.OpportunityLineItems;

        for (OpportunityLineItem li : opptyLineItems) {

            if (this.free_trial_opportunity) {
                this.inputPriceMap.put(li.Id, 0.00);
            } else if (li.Selected_Sales_Price__c != null) {

                if (li.Product_Code_Copy__c.startsWith('LIC')) {
                    this.inputPriceMap.put(li.Id, (li.Selected_Sales_Price__c * this.oppty.License_Term__c).setScale(2));
                } else {
                    this.inputPriceMap.put(li.Id, li.Selected_Sales_Price__c.setScale(2));
                }
            } else {
                if (li.Product_Code_Copy__c.startsWith('LIC')) {
                    this.inputPriceMap.put(li.Id, (li.ListPrice * this.oppty.License_Term__c / 12).setScale(2));
                } else {
                    if(!li.Replacement__c){
                        this.inputPriceMap.put(li.Id, li.ListPrice.setScale(2));
                    } else{
                        this.inputPriceMap.put(li.Id, li.UnitPrice.setScale(2));
                    }
                }
            }
        }
        return this.inputPriceMap;
    }

    public Map<String, Decimal> getInputDiscounts() {
        List<OpportunityLineItem> opptyLineItems = this.vOpportunity.OpportunityLineItems;
        for (OpportunityLineItem li : opptyLineItems) {

            if (this.free_trial_opportunity) {
                this.inputDiscountMap.put(li.Id, 0.00);
            } else {
                if (li.Discount == null) {
                    li.Discount = 0;
                }
                this.inputDiscountMap.put(li.Id, li.Discount.setScale(2));
            }

            /*else if (li.Selected_Sales_Price__c != null && li.Selected_Sales_Price__c != li.Suggested_Sales_Price__c) {
                this.inputDiscountMap.put(li.Id,li.Discount);
            }*/

        }

        return this.inputDiscountMap;
    }

    public Map<String, Boolean> getInputRemovals() {
        List<OpportunityLineItem> opptyLineItems = this.vOpportunity.OpportunityLineItems;
        for (OpportunityLineItem li : opptyLineItems) {
            this.inputRemovalMap.put(li.Id, false);
        }
        return this.inputRemovalMap;
    }
    
    public PageReference Del(){
        return null;
    }
     
    public PageReference refresh(){
        
        System.debug('refreshing');
        //return null;
        return new PageReference('/apex/AddProductsAndLicenses?scontrolCaching=1&id=006g000000FP1qq');
    }
    
    public PageReference save(){
        saveInformation();
        PageReference pr = new PageReference('/apex/AddProductsAndLicenses?scontrolCaching=1&id='+this.oppty.Id);
        pr.setRedirect(true);
        return pr;
    }
    
    public PageReference saveAndBack(){ 
        saveInformation();  
        return new PageReference('/'+oppty.id);
    }
    
    public PageReference back(){
        return new PageReference('/'+oppty.id);
    }
    
    //* August 6th, 2020 Ron Saavedra - (GTMS-1301) AddProductsAndLicensesExtension, setLicenseTermAndResetPrices, getInputPrices, saveInformation, calculateOverDiscount (enable non-0 hardware sales by blocking change of replacement hardware through this page)
    public void saveInformation(){        
//        if(this.free_trial_opportunity){
//            this.oppty.License_Term__c=1;
//            update this.oppty;
//        }
        List<OpportunityLineItem> opptyLiUpdates = new List<OpportunityLineItem>();
        Map<Id, OpportunityLineItem> opptyLineItems = new Map<Id, OpportunityLineItem>([Select Ship_To__c, UnitPrice, ListPrice, Line_List_Price__c, Product_Code_Copy__c, Quantity, Shipped_Quantity__c, OpportunityId, Selected_Sales_Price__c, Suggested_Sales_Price__c, Replacement__c from OpportunityLineItem where OpportunityId = :this.oppty.Id ORDER BY CreatedDate DESC]);
        
        Decimal other_discount=0.00;
        Decimal selected_sales_price=0.00;

        Integer lineItemCount = 0;
        for (OpportunityLineItem li : opptyLineItems.values()){
            
            if(this.inputQuantityMap.get(li.Id)==null){
                this.inputQuantityMap.put(li.Id,1.00);
            }
            else if(this.inputQuantityMap.get(li.Id)==0){
                this.inputQuantityMap.put(li.Id,1.00);
                this.inputRemovalMap.put(li.Id,true);
            }
            
            Decimal suggestedDiscount=0;            
            
            if(li.Product_Code_Copy__c.startsWith('LIC') && !li.Product_Code_Copy__c.contains('EXPRESS')){              
                if(this.oppty.License_Term__c>=84){
                    suggestedDiscount=0.3;
                }
                else if(this.oppty.License_Term__c>=60){
                    suggestedDiscount=0.3;
                }
                else if(this.deal_reg){
                    suggestedDiscount=0.25;
                }
                else if(this.oppty.License_Term__c>=36){
                    suggestedDiscount=0.2;
                }
            }
            else{
                if(this.deal_reg){
                    suggestedDiscount=0.25;
                }
            }  
            if(this.inputPriceMap.get(li.Id)==null){
                if(li.Product_Code_Copy__c.startsWith('LIC')){ 
                    this.inputPriceMap.put(li.Id,(li.ListPrice.setScale(2)*this.oppty.License_Term__c/12).setScale(2));
                }
                else{
                    if(!li.Replacement__c){
                        this.inputPriceMap.put(li.Id,(li.ListPrice).setScale(2));
                    } else{
                        this.inputPriceMap.put(li.Id,(li.UnitPrice).setScale(2));
                    }
                }

            }
            
            if(this.inputDiscountMap.get(li.Id)==null){
                this.inputDiscountMap.put(li.Id, 0.00);
            }
            
            if(!editable_prices){                
                if(this.express_opportunity)
                {   
                    this.inputDiscountMap.put(li.Id, this.express_discount);
                }
                
                if(!li.Replacement__c){
                    this.inputPriceMap.put(li.Id, li.ListPrice*(1-this.inputDiscountMap.get(li.Id)/100));
                } else{
                    this.inputPriceMap.put(li.Id, li.UnitPrice*(1-this.inputDiscountMap.get(li.Id)/100));
                }
                
                if(li.Product_Code_Copy__c.startsWith('LIC')){ 
                    this.inputPriceMap.put(li.Id, (li.ListPrice/12)*this.oppty.License_Term__c*(1-this.inputDiscountMap.get(li.Id)/100));
                }   
            }
            
            //Deal Reg
            li.Deal_Reg_Discount__c=this.deal_reg;
            
            //Quantity
            li.Quantity=this.inputQuantityMap.get(li.Id).setScale(0);
            if(sorted_oppty_line_items.size() != 0){
                if(sorted_oppty_line_items[lineItemCount].Id == li.Id) {
                    li.Ship_To__c = sorted_oppty_line_items[lineItemCount].Ship_To__c;
                    lineItemCount += 1;
                } else{
                    li.Ship_To__c = this.opportunity_shipping_address;
                }
            }
            
            //Prices - Hardware
            if(!li.Replacement__c){
                selected_sales_price=this.inputPriceMap.get(li.Id);
                li.UnitPrice=li.ListPrice;
            }

            //Prices - License
            if(li.Product_Code_Copy__c.startsWith('LIC')){         
                selected_sales_price=selected_sales_price/this.oppty.License_Term__c;
                li.UnitPrice=(li.ListPrice/12)*this.oppty.License_Term__c;    
            }

            if(!li.Replacement__c){
                li.Selected_Sales_Price__c=selected_sales_price; 
            } else{
                li.Selected_Sales_Price__c = li.UnitPrice;
            }
            
            //Discounts
            if(li.UnitPrice==null){
                other_discount=0;
            }
            else{
                if(li.ListPrice!=null && li.ListPrice!=0){
                
                    if(li.Product_Code_Copy__c.startsWith('LIC')){
                        other_discount=1-selected_sales_price/(li.ListPrice/12);
                    }
                    else{
                        other_discount=1-selected_sales_price/li.ListPrice;
                    }
                }    
                else{
                    other_discount=0;
                }
            }
            
            if(other_discount<0){
                other_discount=0;
                
                li.UnitPrice=selected_sales_price;
                if(li.Product_Code_Copy__c.startsWith('LIC')){
                    li.UnitPrice=selected_sales_price*this.oppty.License_Term__c;
                }
            }
            
            li.Discount=100*other_discount;
            
            if(this.express_opportunity){
            
                if(this.express_discount<0){
                               
                    li.UnitPrice=selected_sales_price;
                    if(li.Product_Code_Copy__c.startsWith('LIC')){
                        li.UnitPrice=selected_sales_price*this.selected_license_term;
                    }
                    li.Discount=0;
                    
                }
                else{
                    li.Discount=this.express_discount;
                    li.UnitPrice=selected_sales_price;
                    if(li.Product_Code_Copy__c.startsWith('LIC')){
                        li.UnitPrice=100*selected_sales_price*this.selected_license_term/(100-this.express_discount);
                    }
                }
            }

            if(this.free_trial_opportunity || this.opportunity_type=='Exchange' || this.opportunity_type=='Warranty Exchange' || this.opportunity_type=='Free Trial Return' || this.opportunity_type=='Rebate' || this.opportunity_type=='Promo Opportunity'){
                other_discount=0;
                li.UnitPrice=0.00;
                li.Selected_Sales_Price__c=0.00;
                li.Discount=other_discount;
            }
            
            if(this.opportunity_type=='Remorse Refund'){
              li.UnitPrice=li.UnitPrice*(-1);
            }
            
            if(li.Product_Code_Copy__c.startsWith('LIC')){
                li.License_Term_Copy__c=this.oppty.License_Term__c;
            }
            opptyLiUpdates.add(li);
        }
        //saveInformation
        if(opptyLiUpdates.size() > 0) {
            System.debug('Here is the opptyLiUpdate list! ' + opptyLiUpdates);
            update opptyLiUpdates;
        }

        List<OpportunityLineItem> toDelete = new List<OpportunityLineItem>();
        for (OpportunityLineItem li : opptyLineItems.values()){
            if(this.inputRemovalMap.get(li.Id)==True){
                toDelete.add(li);
            }
        }
        delete toDelete;
        
        Opportunity vOpportunity = this.vOpportunity;
        
        this.total_amount=vOpportunity.Amount;
        if(this.express_discount<0){
            vOpportunity.Express_Selected_Discount__c=0.00;
        }
        else{
            if(vOpportunity.Selected_Payment_Type__c=='Direct Annual' && this.express_discount>=10.00){
                vOpportunity.Express_Selected_Discount__c=this.express_discount-10.00;
            }
            else{
                vOpportunity.Express_Selected_Discount__c=this.express_discount;
            }
        }

        if(this.free_trial_opportunity){
            vOpportunity.License_Term__c=1;
//            update this.oppty;
        }
        
        update vOpportunity;
    }

    public void calculateExtendedLicenseDiscount(){
        Opportunity vOpportunity = this.vOpportunity;

        List<OpportunityLineItem> opptyLineItems = vOpportunity.OpportunityLineItems;

        this.extended_license_discount = 0.00;
        Decimal licenses_total_price = 0.00;
        Decimal licenses_line_price = 0.00;
        this.total_amount = 0.00;

        for (OpportunityLineItem li : opptyLineItems) {
            this.total_amount = this.total_amount + li.TotalPrice;
            if (li.Product_Code_Copy__c.startsWith('LIC')) {
                licenses_total_price = licenses_total_price + li.TotalPrice;
                licenses_line_price = licenses_line_price + li.Line_List_Price__c * li.Quantity;
            }
        }

        if (licenses_line_price != 0) {
            this.extended_license_discount = ((1 - licenses_total_price / licenses_line_price) * 100).setScale(2);
        }

        System.debug('extended_license_discount ' + this.extended_license_discount);
    }
    
            
    //* August 6th, 2020 Ron Saavedra - (GTMS-1301) AddProductsAndLicensesExtension, setLicenseTermAndResetPrices, getInputPrices, saveInformation, calculateOverDiscount (enable non-0 hardware sales by blocking change of replacement hardware through this page)
    public void calculateOverDiscount(){

        Opportunity vOpportunity = this.vOpportunity;
        List<OpportunityLineItem> opptyLineItems = vOpportunity.OpportunityLineItems;

        if(vOpportunity.Max_Approved_Discount__c!=null){
            this.approved_discretionary_discount=vOpportunity.Max_Approved_Discount__c/100;
        } else{       
            this.approved_discretionary_discount=0;     
        }
        Decimal licenseTerm=vOpportunity.License_Term__c;
        
        Decimal line_list_price=0;
        Decimal line_suggested_price=0;
        Decimal line_actual_price=0;
        
        Decimal total_list_price=0;
        Decimal total_suggested_price=0;
        Decimal total_actual_price=0;

        for (OpportunityLineItem li : opptyLineItems){
            
            if(!li.Replacement__c){
                line_list_price=li.ListPrice*li.Quantity;
            } else{
                line_list_price=li.UnitPrice*li.Quantity;
            }

            if(li.ProductCode.startsWith('LIC')){
                line_list_price=(line_list_price/12)*licenseTerm;
            }
            
            line_suggested_price=li.Suggested_Sales_Price__c*li.Quantity;
            if(li.ProductCode.startsWith('LIC')){
                line_suggested_price=line_suggested_price*licenseTerm;
            }
            
            line_actual_price=li.Suggested_Sales_Price__c*li.Quantity;
            if(li.Selected_Sales_Price__c!=null){
                line_actual_price=li.Selected_Sales_Price__c*li.Quantity;
            }
            if(li.ProductCode.startsWith('LIC')){
                line_actual_price=line_actual_price*licenseTerm;
            }
           
            
            total_list_price=total_list_price+line_list_price;
            total_suggested_price=total_suggested_price+line_suggested_price;
            total_actual_price=total_actual_price+line_actual_price;

        }
        
        Decimal total_suggested_discount=0;
        this.total_final_discount=0;
        this.total_discretionary_discount=0;
        
        if(total_list_price>0){
            total_suggested_discount=1-total_suggested_price/total_list_price;
            this.total_final_discount=1-total_actual_price/total_list_price;
            this.total_discretionary_discount=total_final_discount-total_suggested_discount;
        }
        
        System.debug('total_suggested_discount '+total_suggested_discount);
        System.debug('total_final_discount '+total_final_discount);
        System.debug('total_discretionary_discount '+total_discretionary_discount);
        System.debug('approved_discretionary_discount '+approved_discretionary_discount);
      
        this.over_discount=false;
        
        Decimal approved_discount=0;
        
        if(this.oppty.License_Term__c>=60){
            approved_discount=0.35;
        }
        else if(this.oppty.License_Term__c>=36){
            approved_discount=0.25;
        }
        
        if(this.express_opportunity){
            approved_discount=0.1;
        }

        
        //if(this.total_discretionary_discount>this.approved_discretionary_discount){
        if(this.total_final_discount>approved_discount){
            this.over_discount=true;
            //System.debug('over_discount');
            //callfunc='<script> func(); </script>';
        }
    
    }

    private void setCountry(Opportunity vOpportunity) {
        switch on vOpportunity.CurrencyIsoCode {
            when 'GBP' {
                this.country = 'UK';
            }
            when 'EUR' {
                this.country = 'FR';
            }
            when 'CAD' {
                this.country = 'CAN';
            }
            when 'MXN' {
                this.country = 'MEX';
            }
            when 'CHF' {
                this.country = 'CHE';
            }
            when else {
                this.country = 'United States';
            }
        }
    }

    private void setExpressDiscount(Opportunity vOpportunity) {
        if (vOpportunity.Configuration_Segment__c == 'Express'){
            this.express_opportunity = true;

            List<OpportunityLineItem> oli = vOpportunity.OpportunityLineItems;
            if (oli.size() > 0) {

                if (vOpportunity.Express_Selected_Discount__c != null && oli[0].Express_Annual_Discount__c != null) {
                    this.express_discount = vOpportunity.Express_Selected_Discount__c + oli[0].Express_Annual_Discount__c;
                } else if (vOpportunity.Express_Selected_Discount__c != null) {
                    this.express_discount = vOpportunity.Express_Selected_Discount__c;
                } else if (oli[0].Express_Annual_Discount__c != null) {
                    this.express_discount = oli[0].Express_Annual_Discount__c;
                }
            }
        }
    }
     
}