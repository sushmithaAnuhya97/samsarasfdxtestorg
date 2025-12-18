//Aug-22-2022  Chinmaya Dash GTMS-6069 Created this Test class for ReturnShipmentEventTrigger Trigger.
@isTest
public class ReturnShipmentEventTriggerTest {
    @isTest 
    static void platformEventTest() {
        Account a = new Account (Name = 'Acme Co', Organization_Size__c = '5000+', BillingCountry = 'Canada', Industry = 'Other');
        insert a;
        
        Opportunity rev = new Opportunity(AccountId = a.Id, Name = 'Rev', CloseDate = System.today() + 90, StageName = 'Incubate',Type = 'Remorse Refund');            
        insert rev;
        
        Test.startTest();
        
        zkmulti__MCShipment__c  shipment = new zkmulti__MCShipment__c();        
        shipment.zkmulti__Tracking_Number__c = '1z1w7w420374732280';  
        shipment.Opportunity__c = rev.id;        
        insert shipment;
        
        Return_Shipment__e  event = new Return_Shipment__e ();
        event.Opportunity_Id__c  = shipment.Opportunity__c;
        event.Tracking_Id__c  = shipment.zkmulti__Tracking_Number__c;
        EventBus.publish(event); 
        
        Test.stopTest();        
    }    
}