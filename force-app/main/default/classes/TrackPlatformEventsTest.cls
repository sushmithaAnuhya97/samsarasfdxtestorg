@isTest
public class TrackPlatformEventsTest {

    @isTest
    public static void netsuiteTest(){
        Id accountId = generateFakeId(Account.SObjectType);
        Account oldAccount = new Account();
        oldAccount.Id = accountId;
        oldAccount.Billing_Email__c = 'abc@samsara.com';
        
        Map<Id,Account> mp = new Map<Id,Account>();
        mp.put(accountId,oldAccount);
        
        Account newAccount = new Account();
        newAccount.Id = accountId;
        newAccount.Billing_Email__c = 'sfdc@samsara.com';
        
        
        TrackPlatformEvents.enQueuePlatformEventJob(TrackPlatformEvents.Event.NETSUITE,new List<Account>{newAccount},mp);
    }
    
    @isTest
    public static void netsuiteAsyncTest(){
        Test.startTest();
        System.enqueueJob(new Queueable1());
        Test.stopTest();
        
        List<AsyncApexJob> jobs = [SELECT Status FROM AsyncApexJob WHERE JobType = 'Queueable'];
        System.assert(jobs.size() > 0);
    }
    
    @isTest
    public static void billingEmailTest(){
        Id accountId = generateFakeId(Account.SObjectType);
        Account oldAccount = new Account();
        oldAccount.Id = accountId;
        oldAccount.Billing_Email__c = 'abc@samsara.com';
        
        Map<Id,Account> mp = new Map<Id,Account>();
        mp.put(accountId,oldAccount);
        
        Account newAccount = new Account();
        newAccount.Id = accountId;
        newAccount.Billing_Email__c = 'sfdc@samsara.com';
        
        TrackPlatformEvents.enQueuePlatformEventJob(TrackPlatformEvents.Event.BILLING_EMAIL,new List<Account>{newAccount},mp);
    }
    
    @isTest
    public static void shippingAddressTest(){
        Id fakeId = generateFakeId(Shipping_Address__c.SObjectType);
        
        Shipping_Address__c oldSA = new Shipping_Address__c();
        oldSA.Id=fakeId;
        oldSA.Shipping_Address_Line_1__c = 'Austin,Tx';
        
        Map<Id,Shipping_Address__c> mp = new Map<Id,Shipping_Address__c>();
        mp.put(fakeId,oldSA);
        
        Shipping_Address__c newSA = new Shipping_Address__c();
        newSA.Id=fakeId;
        newSA.Shipping_Address_Line_1__c = 'Dallas,Tx';
        TrackPlatformEvents.enQueuePlatformEventJob(TrackPlatformEvents.Event.SHIPPING_ADDRESS,new List<Shipping_Address__c>{newSA},mp);
    }
    
    @isTest
    public static void shippingAddressAsyncTest(){
        
        Test.startTest();
        
        Schedulable1 testSchedule = new Schedulable1(); 
        String sch ='0 48 * * * ?'; 
        System.schedule('Schedule', sch,testSchedule);
        
    	Test.stopTest();
        
        List<AsyncApexJob> jobs = [SELECT Status FROM AsyncApexJob WHERE JobType = 'ScheduledApex'];
        System.assert(jobs.size() > 0);
        
    }
    
    public static String generateFakeId(Schema.SObjectType sot){
        Integer s_num = 1;
        String result = String.valueOf(s_num++);
        return sot.getDescribe().getKeyPrefix() + '0'.repeat(12-result.length()) + result;
    }
    
    public class Queueable1 implements Queueable {
        public void execute(QueueableContext context) {
            Id accountId = generateFakeId(Account.SObjectType);
            Account oldAccount = new Account();
            oldAccount.Id = accountId;
            oldAccount.Billing_Email__c = 'abc@samsara.com';
            
            Map<Id,Account> mp = new Map<Id,Account>();
            mp.put(accountId,oldAccount);
            
            Account newAccount = new Account();
            newAccount.Id = accountId;
            newAccount.Billing_Email__c = 'sfdc@samsara.com';
            
            
            TrackPlatformEvents.enQueuePlatformEventJob(TrackPlatformEvents.Event.NETSUITE,new List<Account>{newAccount},mp);
        }
    }
    
    public class Schedulable1 implements Schedulable {
        public void execute(SchedulableContext context) {
            Id fakeId = generateFakeId(Shipping_Address__c.SObjectType);
        
            Shipping_Address__c oldSA = new Shipping_Address__c();
            oldSA.Id=fakeId;
            oldSA.Shipping_Address_Line_1__c = 'Austin,Tx';
            
            Map<Id,Shipping_Address__c> mp = new Map<Id,Shipping_Address__c>();
            mp.put(fakeId,oldSA);
            
            Shipping_Address__c newSA = new Shipping_Address__c();
            newSA.Id=fakeId;
            newSA.Shipping_Address_Line_1__c = 'Dallas,Tx';
            TrackPlatformEvents.enQueuePlatformEventJob(TrackPlatformEvents.Event.SHIPPING_ADDRESS,new List<Shipping_Address__c>{newSA},mp);
        }
    }
}