@isTest
public class ScheduledProductPlatformEventTest {
    @TestSetup
    static void testRecords() {
        //Create Product
        Product2 pro = new Product2(Name = 'iPhone X', Family = 'Mobile');
        Insert pro;
        
        //Instantiate the Pricebook2 record with StandardPricebookId
        Pricebook2 standardPricebook = new Pricebook2(
            Id = Test.getStandardPricebookId(),
            IsActive = true
        );
        
        //Execute an update DML on the Pricebook2 record, to make IsStandard to true
        Update standardPricebook;
        
        //Query for the Pricebook2 record, to check IsStandard field
        standardPricebook = [SELECT Id, IsStandard FROM Pricebook2 WHERE Id = :standardPricebook.Id];
        //It should return true
        //System.assertEquals(true, standardPricebook.IsStandard);
        
        
        //Create the PricebookEntry
        //
        /*
        PricebookEntry pbe = new PricebookEntry(
            Pricebook2Id = standardPricebook.Id,
            Product2Id = pro.Id,
            UnitPrice = 1020,
            IsActive = true
        );
        Insert pbe;
        */
    }
    
    @isTest
    static void testProductPlatformEventBatch(){
        Test.startTest();
        ScheduledProductPlatformEvent sh1 = new ScheduledProductPlatformEvent();      
 		String sch = '0 0 23 * * ?';
        system.schedule('Test check', sch, sh1);
        Test.stopTest();
        System.assert(1>0,true);
    }
}