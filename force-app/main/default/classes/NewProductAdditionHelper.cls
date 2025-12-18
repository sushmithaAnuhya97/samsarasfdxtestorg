/*
 * 04/06/20 Tommy - (GTMS-736): Added Product Short Name and Readable Name to fields to copy to Product2 record upon creation
 * 02/25/21 Gaurav Sharma - (GTMS-2854): Added New_Product_Addition__c record to Product related list
 * 04/30/21 Lavanya - (GTMS-1396): Added code to insert Price Book Entry records for the newly created products
  * 08/35/21 Anil - (GTMS-4028): Remove manual steps for PM on SKU Creation approval workflow
 */
public class NewProductAdditionHelper {
  
    private static Map<Id, New_Product_Addition__c> oldNPAS;
    private static Map<Id, New_Product_Addition__c> newNPAS;
    
    
    public static void ProductCreator(
        Map<Id, New_Product_Addition__c> oldTriggerNPAS,
        Map<Id, New_Product_Addition__c> newTriggerNPAS){
            oldNPAS = oldTriggerNPAS;
            newNPAS = newTriggerNPAS;
            system.debug('ProductCreator initiated');
            createNewProducts();

    }

    
    public static void createNewProducts(){
        List<Product2> prodsToInsert = new List<Product2>();
        List<New_Product_Addition__c> prodsAddedToInsert = new List<New_Product_Addition__c>();
        Map<String,New_Product_Addition__c> newProdsAdded=new Map<String,New_Product_Addition__c>();
        List<PricebookEntry> priceBookEntryList = new List<PricebookEntry>();
        
        for (New_Product_Addition__c npa : newNPAS.values()){
            New_Product_Addition__c oldNPA = oldNPAS.get(npa.Id);
            if (oldNPA.Status__c != npa.Status__c && npa.Status__c == 'Launched EA') {
                npa.Lauched_EA_Date__c = system.now();
            }
            if (oldNPA.Status__c != npa.Status__c && npa.Status__c == 'Launched GA') {
                npa.Launched_GA_Date__c = system.now();
            }
            system.debug('Old ID is: ' + oldNPA.Id);
            if (oldNPA.Id != NULL){
                boolean alreadyCreated = oldNPA.Status__c == 'Product Creation';
                system.debug('About to create product');
                if (!alreadyCreated && npa.Status__c.equals('Product Creation')){
                    Product2 newProd                = new Product2();
                    newProd.Name                    = npa.Product_Name__c;
                    newProd.ProductCode             = npa.Product_Code__c;
                    newProd.Description             = npa.Description__c;
                    newProd.Family                  = npa.Product_Family__c;
                    newProd.Sub_Family__c           = npa.Sub_Family__c;                    
                    newProd.Product_Type__c         = npa.Type__c;
                    newProd.Weight_oz__c            = npa.Weight_oz__c;
                    newProd.Dimensions_cm3__c       = npa.Dimensions_cm3__c;
                    newProd.Geo_Availablity__c      = npa.Geo_Availability__c;
                    newProd.Segment_Availability__c = npa.Segment_Availability__c;
                    newProd.Sales_Segment__c        = npa.Sales_Segment__c;
                    
                    //newProd.Readable_Name__c        = npa.Readable_Name__c;
                    //newProd.Product_Short_Name__c   = npa.Product_Short_Name__c;
                    newProd.New_Product_Addition__c = npa.Id;
                    
                    //create a map here between npa and product getting inserted
                    newProdsAdded.put(newProd.Name,npa);                    
                    system.debug('Prod created');
                    
                    prodsToInsert.add(newProd);
                }
            }
            
            if(prodsToInsert.size() > 0){
                insert prodsToInsert;
            }
            List<String> pbookNames = Label.Price_Books_for_NPA.Split(',');
            //Query the price books
            List<Pricebook2> priceBookList = [Select Id,Name from Pricebook2 where name in :pbookNames];
            
            if(prodsToInsert.size() > 0){
                for(Product2 prod:prodsToInsert){
                    New_Product_Addition__c npa2 = newProdsAdded.get(prod.Name);
                    
                    npa2.Product2__c = prod.Id;
                    prodsAddedToInsert.add(npa2);
                    
                    for(Pricebook2 pb: priceBookList){
                        if(npa2.Standard_Price_CAD__c != null){
                            priceBookEntryList.add(createPBE(prod,pb,'CAD',npa2.Standard_Price_CAD__c));
                        }
                        if(npa2.Standard_Price_CHF__c != null){
                            priceBookEntryList.add(createPBE(prod,pb,'CHF',npa2.Standard_Price_CHF__c));
                        }
                        if(npa2.Standard_Price_EUR__c != null){
                            priceBookEntryList.add(createPBE(prod,pb,'EUR',npa2.Standard_Price_EUR__c));
                        }
                        if(npa2.Standard_Price_GBP__c != null){
                            priceBookEntryList.add(createPBE(prod,pb,'GBP',npa2.Standard_Price_GBP__c));
                        }
                        if(npa2.Standard_Price_MXN__c != null){
                            priceBookEntryList.add(createPBE(prod,pb,'MXN',npa2.Standard_Price_MXN__c));
                        }
                        if(npa2.Standard_Price_USD__c != null){
                            priceBookEntryList.add(createPBE(prod,pb,'USD',npa2.Standard_Price_USD__c));
                        } 
                    }
                }
            }
            
            if(!priceBookEntryList.isEmpty()){
                insert priceBookEntryList;
            }
            //perform the iteration on prodsToInsert
            //npa.Product__c = newProd.Id;
            
            
            
             system.debug('There were '+ prodsToInsert.size() + ' products created.');
        }
    }
    
    public static PricebookEntry createPBE(Product2 prod, PriceBook2 pb,String currencyCode,Decimal unitPrice){
        PricebookEntry pbe = new PricebookEntry();
        pbe.Product2Id = prod.Id;
        pbe.Pricebook2Id = pb.Id;
        pbe.UnitPrice = unitPrice;
        pbe.CurrencyIsoCode = currencyCode;
        pbe.IsActive = true;
        return pbe;
    }

// Below Medod to update stage - Anil Bogadi
     public static void updateStage(Map<Id, New_Product_Addition__c> oldTriggerNPAS,
        Map<Id, New_Product_Addition__c> newTriggerNPAS){
           List<New_Product_Addition__c> newNPASList = new List<New_Product_Addition__c>(); 
            for (New_Product_Addition__c npa : newTriggerNPAS.values()){
                if(((npa.Weight_oz__c != null && npa.Dimensions_cm3__c != null && npa.BOM_Cost__c != null && npa.Lead_Time__c != null  && 
                     npa.Revenue_Recognition_Type__c != null && npa.Type__c == 'Hardware') ||
                    (npa.Revenue_Recognition_Type__c != null && npa.Type__c == 'Accessory') ||
                    (npa.Revenue_Recognition_Type__c != null && npa.Type__c == 'Cable') ||
                    (npa.Revenue_Recognition_Type__c != null && npa.Type__c == 'License') ||
                    (npa.Revenue_Recognition_Type__c != null && npa.Type__c == 'Service Fee')) &&
                     npa.Status__c == 'Back Office Processing' )  {
                  New_Product_Addition__c newProductAddition = new New_Product_Addition__c();
                    newProductAddition.Id = npa.Id;    
                    newProductAddition.Status__c = 'Ready to Approve';
                    newNPASList.add(newProductAddition);    
                }    
            }
            if(newNPASList.size() > 0){
              update newNPASList; 
               
              OrgWideEmailAddress owa = [Select Id from OrgWideEmailAddress Where Address = 'no-reply@samsara.com'];
              New_Product_Addition__c  ToAddressesEmail = [Select Id,Product_Owner_Manager__r.email from New_Product_Addition__c Where id =: newNPASList[0].Id];
              Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
              message.setOrgWideEmailAddressId(owa.Id);
              message.setToAddresses(new String[]{ToAddressesEmail.Product_Owner_Manager__r.email});// Product_Owner_Manager__c.Email
              //message.setToAddresses(new String[]{'anilkumar.bogadi@gmail.com'});
              message.subject = '[Action Requested] - Submit NPA for Approval';
              String intro = 'Hello, A new product has been moved to the Ready to Approve stage. Please go into the New Product Addition record and click the “Submit for Approval” button to initiate the approval workflow.';
              String email = intro+'\n https://samsara--uat.lightning.force.com/'+ToAddressesEmail.Id;
              message.plainTextBody = email;
              Messaging.SingleEmailMessage[] messages =   new List<Messaging.SingleEmailMessage> {message};
              Messaging.SendEmailResult[] results = Messaging.sendEmail(messages);
              if (results[0].success) {
             System.debug('The email was sent successfully.');
             } else {
           System.debug('The email failed to send: ' + results[0].errors[0].message);
}  
            }
            
    }
}