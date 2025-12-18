@isTest
public class QuoteSavePETests {
	@testSetup
    private static void testDataSetup() {
        
        //Standard Pricebook
        Id pricebookId = Test.getStandardPricebookId();
        
        //Create Products
        List<Product2> products = new List<Product2>();
        Product2 vg33 = new Product2(Name= 'IG41-BUNDLE', ProductCode = 'HW-VG33', Family = 'Test', Sub_Family__c = 'Connected Equipment', Product_Type__c = 'Bundle');
        products.add(vg33);
        Product2 vgLicense = new Product2(Name= 'LIC-IG41-20-ENT', ProductCode = 'LIC-IG41-20-ENT', Family = 'Test', Sub_Family__c = 'Connected Equipment');
        products.add(vgLicense);
        Product2 em11 = new Product2(Name= 'CBL-AG-ACT14', ProductCode = 'CBL-AG-ACT14', Family = 'Test', Sub_Family__c = 'Connected Equipment');
        products.add(em11);
        Product2 emLicense = new Product2(Name= 'LIC-IG15-ENT', ProductCode = 'LIC-IG15-ENT', Family = 'Test');
        products.add(emLicense);
        
        insert products;
        
        //Create PriceBookEntries
        List<PricebookEntry> pricebookEntries = new List<PricebookEntry>();
        PricebookEntry vg33PB = new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = vg33.Id, UnitPrice = 10000, IsActive = true);
        pricebookEntries.add(vg33PB);
        PricebookEntry em11PB = new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = em11.Id, UnitPrice = 10000, IsActive = true);
        pricebookEntries.add(em11PB);
        PricebookEntry vgLicensePB = new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = vgLicense.Id, UnitPrice = 10000, IsActive = true);
        pricebookEntries.add(vgLicensePB);
        PricebookEntry emLicensePB = new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = emLicense.Id, UnitPrice = 10000, IsActive = true);
        pricebookEntries.add(emLicensePB);
        
        insert pricebookEntries;
        
        // Create account
        List<Account> newAccount = new List<Account>();
        Account account = new Account (Name = 'Test Account', Organization_Size__c = '5000+', BillingCountry = 'Canada', Industry = 'Other', Credit_Limit__c = 10000);
        newAccount.add(account);

        insert newAccount;
           
        //Create Opportunity
        List<Opportunity> newOpportunities = new List<Opportunity>();
        Opportunity revenueOpportunity = new Opportunity( AccountId = account.Id, License_Term__c =36, Pricebook2Id = pricebookId, 
                                                         Max_Approved_Discount__c=0, Name = 'Revenue Opportunity', Price_Book_Name__c = 'Standard Price Book', 
                                                         CloseDate = System.today() + 90, StageName = 'Incubate');            
        newOpportunities.add(revenueOpportunity);
        insert newOpportunities;
        
        SBQQ__Quote__c quote = new SBQQ__Quote__c(Quote_Name__c = 'First Quote ', SBQQ__Account__c = account.Id, SBQQ__Opportunity2__c =revenueOpportunity.Id, 
                                                  SBQQ__SubscriptionTerm__c =10,Estimated_Annual_Payment__c = 24, SBQQ__Primary__c = false, Custom_License_Term__c = 2);
        insert quote;
    }
    
    @isTest 
    static void quoteSavePlatformEventTest(){
        
        SBQQ__Quote__c quote = [SELECT Id, SBQQ__Primary__c,Estimated_Monthly_Payment__c,Monthly_Credit_Remaining_on_Account__c, Shipping_Address_NEW__c FROM SBQQ__Quote__c WHERE Quote_Name__c='First Quote']; 
          
        List<Product2> igProduct = [SELECT id, Product_Type__c FROM Product2];
        Product2 igBundle = new Product2();
        for(Product2 p2 : igProduct) {
            if(p2.Product_Type__c == 'Bundle') {
                igBundle = p2;
            }
        }
        
        List<PricebookEntry> pricebookEntry = [SELECT id, Product2Id, UnitPrice FROM PricebookEntry];   
        List<SBQQ__QuoteLine__c> quoteLines = new List<SBQQ__QuoteLine__c>();
        SBQQ__QuoteLine__c bundle = new SBQQ__QuoteLine__c(SBQQ__Quote__c = quote.Id, SBQQ__PricebookEntryId__c = pricebookEntry[0].Id, SBQQ__Quantity__c  = 5,  
                                                                  SBQQ__Discount__c = 0, SBQQ__Product__c = igBundle.Id);
        insert bundle;
        for(Integer i = 0; i < igProduct.size(); i++) {
            Product2 igB = igProduct[i];
            if(igProduct[i].Product_Type__c != 'Bundle') {
             quoteLines.add(new SBQQ__QuoteLine__c(SBQQ__Quote__c = quote.Id, SBQQ__PricebookEntryId__c = pricebookEntry[i].Id, SBQQ__Quantity__c  = 5, SBQQ__RequiredBy__c = bundle.Id,
                                                                  SBQQ__Discount__c = 0, SBQQ__Product__c = igProduct[i].Id));
        	}
        }

        insert quoteLines;
        Test.startTest();
        quote.SBQQ__Primary__c = true;
        quote.Selected_Payment_Type__c = 'Direct Annual';
            update quote;


        
        Test.stopTest();
    }

    @IsTest
    static void shouldTestRowLockExceptions(){
        QuoteSavePETriggerHandler thisHandler = new QuoteSavePETriggerHandler();
        try{
            throw new customException('UNABLE_TO_LOCK_ROW');
        }
        catch(Exception ex){
            try{
                thisHandler.handleExceptions(
                        ex
                );
            }
            catch (Exception iEx){
                System.assert(iEx.getMessage().contains('Row Lock issue, so retrying the trigger again.'), 'should fail with platform exception');
            }
        }


    }

    @IsTest
    static void shouldTestNonRowLockExceptions(){
        QuoteSavePETriggerHandler thisHandler = new QuoteSavePETriggerHandler();
        Test.startTest();
        try{
            throw new customException('unknown other exceptions');
        }
        catch(Exception ex){
            try{
                thisHandler.handleExceptions(
                        ex
                );
            }
            catch (Exception iEx){
                System.assert(!iEx.getMessage().contains('Row Lock issue, so retrying the trigger again.'), 'should fail with platform exception');
            }
        }
        finally {
            QuoteSavePETriggerHandler.thisLoggerService.logger.dispatch();
        }
        Test.stopTest();

        System.assert([SELECT Id FROM Log__c ].size() != 0, 'Should create Log record in the database.');

    }

    public class customException extends Exception{

    }
}