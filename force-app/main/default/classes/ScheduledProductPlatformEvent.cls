/* 
* Class Created: 23/11/22 - @author: Saiteja
* Test Class: ScheduledProductPlatformEventTest
* 11/24/2022 Saiteja - PLM Field Mapping, platform events and Integration testing
*/
/* Created the class to schedule the same for everyday run */
global class ScheduledProductPlatformEvent implements Schedulable{   
    global void execute(SchedulableContext sc){
        String timeFrame = System.label.ProductEventBatch_Hours;
        Integer hrs = Integer.valueOf(timeFrame);
        DateTime dtime = System.Now().addHours(-hrs);
        String myDte = dtime.formatGMT('yyyy-MM-dd\'T\'HH:mm:ss.SSS\'Z\'');
        String query = 'Select Id, Name, Product2Id from PricebookEntry where CreatedDate >='+ myDte +' OR LastModifiedDate >='+ myDte; 
        ProductPlatformEventBatchClass updateBatch = new ProductPlatformEventBatchClass(query);
        Database.executebatch(updateBatch, 100);   
    }
    
}