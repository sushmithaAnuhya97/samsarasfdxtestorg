@IsTest
private class NewProductAdditionHelperTest {
    @IsTest
    private static void testCreateNewProducts(){
        //Create a Price Book
        Pricebook2 standardPricebook = new Pricebook2(
            Id = Test.getStandardPricebookId(),
            Name = 'Standard Price Book',
            IsActive = true
        );
        Update standardPricebook;
        
        //create NPA record
        New_Product_Addition__c npaTest = new New_Product_Addition__c(
          Product_Name__c = 'NPA TEST',
          Product_Code__c = 'NPA-TESTER-123',
          Product_Family__c = 'Safety',
          Sub_Family__c = 'Samsara Brand',
          Standard_Price_CAD__c = 123.12,
          Standard_Price_CHF__c = 0,
          Standard_Price_EUR__c = 100,
          Standard_Price_USD__c = 115,
          Standard_Price_GBP__c = 102,
          Standard_Price_MXN__c = 200,
          Status__c = 'Product Initiated'
        );
        insert npaTest;
        //update NPA record    
        npaTest.Status__c = 'Product Creation';
        update npaTest;
        //query for new product record
        Product2 newProduct = [SELECT Id, 
                                      Name,
                                      New_Product_Addition__c,
                                      ProductCode,
                                      (Select Id from PriceBookEntries) FROM Product2 WHERE
                                      Name        = 'NPA Test' AND
                                      ProductCode = 'NPA-TESTER-123'
                              ];
        System.debug('NPA ID: ' + npaTest.Id);
        System.debug('NPA ID on Product: ' + newProduct.New_Product_Addition__c);
        
        System.assertEquals(newProduct.New_Product_Addition__c, npaTest.id);
        System.assertEquals(newProduct.PriceBookEntries.size(), 6);
        
    
    
    }
    

}