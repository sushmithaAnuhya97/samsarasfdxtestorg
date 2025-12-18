public class TrackPlatformEvents implements Queueable {
    
    // Used by Queueable 
    public Object newRecord;
    public Object oldRecord;
    public String quiddity;
    public String userName;
    public String userId;
    public DateTime publishedTime;
    public Event platformEventIndicator;
    
    // Used by future
    public String newRecordJson;
    public String oldRecordJson;
    
    public TrackPlatformEvents(Event platformEventIndicator, Object newRecord, Object oldRecord,String quiddity,String userName,String userId,DateTime publishedTime){
        this.quiddity = quiddity;
        this.newRecord=newRecord;
        this.oldRecord=oldRecord;
        this.userName=userName;
        this.userId=userId;
        this.publishedTime=publishedTime;
        this.platformEventIndicator=platformEventIndicator;
    }
    
    public enum Event {NETSUITE, WEBSTORE, BILLING_EMAIL, SHIPPING_ADDRESS, PRODUCT, CUSTOMER_360}
    
    public static void enQueuePlatformEventJob(Event platformEventIndicator, Object newRecord, Object oldRecord){
        String quiddity = Request.getCurrent().getQuiddity().name();
        String userName = UserInfo.getName();
        String userId = UserInfo.getUserId();
        DateTime publishedTime = getUTCDateTime();
        
        if(System.isQueueable() && Limits.getFutureCalls() < Limits.getLimitFutureCalls()) {
            String newRecordJson = JSON.serialize(newRecord);
            String oldRecordJson = JSON.serialize(oldRecord);
            
            trackPlatformEventsFuture(platformEventIndicator.name(), newRecordJson, oldRecordJson, quiddity, userName, userId, publishedTime);
        }
        else  {
            if(Limits.getQueueableJobs() < Limits.getLimitQueueableJobs()) {
                System.enqueueJob(new TrackPlatformEvents(platformEventIndicator,newRecord,oldRecord,quiddity, userName, userId,publishedTime));
            }        	
        }
    }
    
    @future
    public static void trackPlatformEventsFuture(String platformEventIndicator, String newRecordJson, String oldRecordJson, String quiddity, String userName, String userId, DateTime publishedTime) {
        Event eventIndicator = EVENT.valueOf(platformEventIndicator);
        Object newRecord;
        Object oldRecord;
        
        switch on eventIndicator {
            when NETSUITE, BILLING_EMAIL{
                newRecord = (Object)JSON.deserialize(newRecordJson, List<Account>.class);
                oldRecord = (Object)JSON.deserialize(oldRecordJson, Map<Id, Account>.class);
            }
            when SHIPPING_ADDRESS {
                newRecord = (Object)JSON.deserialize(newRecordJson, List<Shipping_Address__c>.class);
                oldRecord = (Object)JSON.deserialize(oldRecordJson, Map<Id, Shipping_Address__c>.class);
            }
        }
        
        new TrackPlatformEvents(eventIndicator,newRecord,oldRecord,quiddity, userName, userId,publishedTime).execute(null);
    }
    
    public void execute(QueueableContext context) {
        List<Platform_Events_Monitor__c> pemList = new List<Platform_Events_Monitor__c>();
        
        DateTime dt = System.now();
        DateTime dt2 =  Datetime.newInstanceGmt(dt.year(),dt.month(),dt.day(),00,00,00);
        DateTime dt3 = dt2.addDays(1);
        
        List<PlatformEventUsageMetric> lst = [Select id,EventName,UsageType,TimeSegment,value from PlatformEventUsageMetric where TimeSegment ='Daily' and StartDate >=:dt2 and EndDate <=:dt3 and EventType = 'CUSTOM_PLATFORM_EVENT'and EventName in ('Account_Sync_Event__e','Product_Event__e')];
        
        Long account_publish_count;
        Long account_delivered_count;
        
        Long product_publish_count;
        Long product_delivered_count;
        
        for(PlatformEventUsageMetric peum:lst){
            if(peum.EventName=='Account_Sync_Event__e' && peum.UsageType=='PUBLISH'){
                account_publish_count = peum.value;
            }
            if(peum.EventName=='Account_Sync_Event__e' && peum.UsageType=='DELIVERY'){
                account_delivered_count = peum.value;
            }
            if(peum.EventName=='Product_Event__e' && peum.UsageType=='PUBLISH'){
                product_publish_count = peum.value;
            }
            if(peum.EventName=='Product_Event__e' && peum.UsageType=='DELIVERY'){
                product_delivered_count = peum.value;
            }
        }
        
        switch on platformEventIndicator{
            when NETSUITE{
                String objectName = 'Account';
                List<Account> acctList = (List<Account>)newRecord;
                Map<Id,Account> oldAccountMap = (Map<Id,Account>)oldRecord;
                Sync_Object_Field__mdt[] accountSyncFields = [Select Id,Object_Api_Name__c,Field_Api_Name__c from Sync_Object_Field__mdt Where Object_Api_Name__c =:objectName];
                
                for(Account newAccountRecord: acctList){
                    Account oldAccountRecord = oldAccountMap.get(newAccountRecord.Id);
                    pemList.addAll(logPlatformEventNetsuiteDetails(newAccountRecord,oldAccountRecord,accountSyncFields,Event.NETSUITE,
                                                                   account_publish_count,account_delivered_count,product_publish_count,product_delivered_count));
                }
            }
            when BILLING_EMAIL{
                String objectName = 'Account';
                List<Account> acctList = (List<Account>)newRecord;
                Map<Id,Account> oldAccountMap = (Map<Id,Account>)oldRecord;
                Sync_Object_Field__mdt[] accountSyncFields = [Select Id,Object_Api_Name__c,Field_Api_Name__c from Sync_Object_Field__mdt Where Object_Api_Name__c =:objectName];
                
                for(Account newAccountRecord: acctList){
                    Account oldAccountRecord = oldAccountMap.get(newAccountRecord.Id);
                    pemList.addAll(logPlatformEventNetsuiteDetails(newAccountRecord,oldAccountRecord,accountSyncFields,Event.BILLING_EMAIL,
                                                                   account_publish_count,account_delivered_count,product_publish_count,product_delivered_count));
                }
            }/*
            when WEBSTORE{
                System.debug('newRecord----------->'+newRecord);
                if(newRecord instanceOf List<Account>){
                System.debug('Nagesh--------------->1');
                String objectName = 'Account';
                List<Account> acctList = (List<Account>)newRecord;
                Map<Id,Account> oldAccountMap = (Map<Id,Account>)oldRecord;
                List<Sync_Object_Field_WebStore__mdt> accountSyncFields = [Select Id,Object_Api_Name__c,Field_Api_Name__c,Null_Check_Needed__c from Sync_Object_Field_WebStore__mdt Where Object_Api_Name__c =:objectName];
                
                for(Account newAccountRecord: acctList){
                Account oldAccountRecord = oldAccountMap.get(newAccountRecord.Id);
                pemList.addAll(logPlatformEventWebstoreDetails(newAccountRecord,oldAccountRecord,accountSyncFields));
                }
                }else if(newRecord instanceOf List<Contract>){
                System.debug('Nagesh--------------->2');
                List<Contract> contractsList = (List<Contract>)newRecord;
                Map<Id,Contract> oldContractMap = (Map<Id,Contract>)oldRecord;
                
                List<String> contractSyncFields = new List<String>{'EndDate'};
                for(Contract newContractRecord: contractsList){
                Contract oldContractRecord = oldContractMap.get(newContractRecord.Id);
                pemList.addAll(logPlatformEventWebstoreDetails(newContractRecord,oldContractRecord,contractSyncFields));
                }
                }else if(newRecord instanceOf List<User>){
                System.debug('Nagesh--------------->3');
                List<User> userList = (List<User>)newRecord;
                Map<Id,User> oldUserMap = (Map<Id,User>)oldRecord;
                
                List<String> userSyncFields = new List<String>{'FirstName','LastName'};
                for(User newUserRecord: userList){
                User oldUserRecord = oldUserMap.get(newUserRecord.Id);
                pemList.addAll(logPlatformEventWebstoreDetails(newUserRecord,oldUserRecord,userSyncFields));
                }
                }
            }*/
            when SHIPPING_ADDRESS{
                List<Shipping_Address__c> shippingAddressRecordList = (List<Shipping_Address__c>)newRecord;
                Map<Id,Shipping_Address__c> oldShippingAddressRecordMap = (Map<Id,Shipping_Address__c>)oldRecord;
                for(Shipping_Address__c newShippingAddressRecord: shippingAddressRecordList){
                    if(oldShippingAddressRecordMap!=null){
                        Shipping_Address__c oldShippingAddressRecord = oldShippingAddressRecordMap.get(newShippingAddressRecord.Id);
                        pemList.addAll(logPlatformEventShippingAddressDetails(newShippingAddressRecord,oldShippingAddressRecord,account_publish_count,account_delivered_count,product_publish_count,product_delivered_count));
                    }
                }
            }
        }  
        
        if(!pemList.isEmpty()){
            INSERT pemList;
        }
    }
    
    public List<Platform_Events_Monitor__c> logPlatformEventNetsuiteDetails(Account newAccount, Account oldAccount,Sync_Object_Field__mdt[] accountSyncFields, Event eventName, Long publishCount, Long deliveryCount,Long productPublishCount, Long productDeliveryCount){
        String objectName = 'Account';
        List<Platform_Events_Monitor__c> pemList = new List<Platform_Events_Monitor__c>();
        
        for(Sync_Object_Field__mdt mdt: accountSyncFields){
            Platform_Events_Monitor__c pm = new Platform_Events_Monitor__c();
            pm.Account_PEs_Publish_Count__c = publishCount;
            pm.Account_PEs_Delivery_Count__c = deliveryCount;
            pm.Product_PEs_Publish_Count__c  = productPublishCount;
            pm.Product_PEs_Delivery_Count__c  = productDeliveryCount;
            pm.Event_Name__c = eventName.name();
            pm.Event_Published_Time__c=publishedTime;
            pm.Field_Api_Name__c=mdt.Field_Api_Name__c;
            pm.Object_Name__c = objectName;
            pm.User_Id__c = this.userId;
            pm.User_Name__c = this.userName;
            pm.Quiddity__c = this.quiddity;
            if(oldAccount!=null && (newAccount.get(mdt.Field_Api_Name__c)!=oldAccount.get(mdt.Field_Api_Name__c))){
                pm.New_Value__c =string.valueof(newAccount.get(mdt.Field_Api_Name__c));
                pm.Old_Value__c =string.valueof(oldAccount.get(mdt.Field_Api_Name__c));
                pm.RecordId__c = oldAccount.Id;
                pemList.add(pm);
                break;
            }
        }
        return pemList;
    }
    
    /*
    public List<Platform_Events_Monitor__c> logPlatformEventWebstoreDetails(Account newAccount, Account oldAccount,List<Sync_Object_Field_WebStore__mdt> accountSyncFields){
        String objectName = 'Account';
        List<Platform_Events_Monitor__c> pemList = new List<Platform_Events_Monitor__c>();
        
        for(Sync_Object_Field_WebStore__mdt mdt: accountSyncFields){
            Platform_Events_Monitor__c pm = new Platform_Events_Monitor__c();
            pm.Event_Name__c = Event.WEBSTORE.name();
            pm.Event_Published_Time__c=publishedTime;
            pm.Field_Api_Name__c=mdt.Field_Api_Name__c;
            pm.Object_Name__c = objectName;
            pm.User_Id__c = this.userId;
            pm.User_Name__c = this.userName;
            pm.Quiddity__c = this.quiddity;
            if(oldAccount!=null && (newAccount.get(mdt.Field_Api_Name__c)!=oldAccount.get(mdt.Field_Api_Name__c))){
                pm.New_Value__c =string.valueof(newAccount.get(mdt.Field_Api_Name__c));
                pm.Old_Value__c =string.valueof(oldAccount.get(mdt.Field_Api_Name__c));
                pm.RecordId__c = oldAccount.Id;
                pemList.add(pm);
                break;
            }
        }
        return pemList;
    }
    
    public List<Platform_Events_Monitor__c> logPlatformEventWebstoreDetails(Contract newContract, Contract oldContract,List<String> contractSyncFields){
        String objectName = 'Contract';
        List<Platform_Events_Monitor__c> pemList = new List<Platform_Events_Monitor__c>();
        
        for(String fieldName: contractSyncFields){
            Platform_Events_Monitor__c pm = new Platform_Events_Monitor__c();
            pm.Event_Name__c = Event.WEBSTORE.name();
            pm.Event_Published_Time__c=publishedTime;
            pm.Field_Api_Name__c=fieldName;
            pm.Object_Name__c = objectName;
            pm.User_Id__c = this.userId;
            pm.User_Name__c = this.userName;
            pm.Quiddity__c = this.quiddity;
            if(oldContract!=null && (newContract.get(fieldName)!=oldContract.get(fieldName))){
                pm.New_Value__c =string.valueof(newContract.get(fieldName));
                pm.Old_Value__c =string.valueof(oldContract.get(fieldName));
                pm.RecordId__c = oldContract.Id;
                pemList.add(pm);
                break;
            }
        }
        return pemList;
    }
    
    public List<Platform_Events_Monitor__c> logPlatformEventWebstoreDetails(User newUser, User oldUser,List<String> userSyncFields){
        String objectName = 'User';
        List<Platform_Events_Monitor__c> pemList = new List<Platform_Events_Monitor__c>();
        
        for(String fieldName: userSyncFields){
            Platform_Events_Monitor__c pm = new Platform_Events_Monitor__c();
            pm.Event_Name__c = Event.WEBSTORE.name();
            pm.Event_Published_Time__c=publishedTime;
            pm.Field_Api_Name__c=fieldName;
            pm.Object_Name__c = objectName;
            pm.User_Id__c = this.userId;
            pm.User_Name__c = this.userName;
            pm.Quiddity__c = this.quiddity;
            if(oldUser!=null && (newUser.get(fieldName)!=oldUser.get(fieldName))){
                pm.New_Value__c =string.valueof(newUser.get(fieldName));
                pm.Old_Value__c =string.valueof(oldUser.get(fieldName));
                pm.RecordId__c = oldUser.Id;
                pemList.add(pm);
                break;
            }
        }
        return pemList;
    }
*/
    
    public List<Platform_Events_Monitor__c> logPlatformEventShippingAddressDetails(Shipping_Address__c newShippingAddress, Shipping_Address__c oldShippingAddress, 
                                                                                   Long publishCount, Long deliveryCount,Long productPublishCount, Long productDeliveryCount) {
        List<Platform_Events_Monitor__c> pemList = new List<Platform_Events_Monitor__c>();
        Set<String> trackFields = new Set<String>{'Name','Shipping_Zip_Code__c','Shipping_Address_Line_1__c','Shipping_Address_Line_2__c','Shipping_City__c','Shipping_State__c','Shipping_Email__c','Shipping_Country__c'};
            for(String fieldName: trackFields){
                Platform_Events_Monitor__c pm = new Platform_Events_Monitor__c();
                pm.Account_PEs_Publish_Count__c = publishCount;
                pm.Account_PEs_Delivery_Count__c = deliveryCount;
                pm.Product_PEs_Publish_Count__c  = productPublishCount;
                pm.Product_PEs_Delivery_Count__c  = productDeliveryCount;
                pm.Event_Name__c = Event.SHIPPING_ADDRESS.name();
                pm.Event_Published_Time__c=publishedTime;
                pm.Field_Api_Name__c=fieldName;
                pm.Object_Name__c = 'Shipping_Address__c';
                pm.User_Id__c = this.userId;
                pm.User_Name__c = this.userName;
                pm.Quiddity__c = this.quiddity;
                if(oldShippingAddress!=null && (newShippingAddress.get(fieldName)!=oldShippingAddress.get(fieldName))){
                    pm.New_Value__c =string.valueof(newShippingAddress.get(fieldName));
                    pm.Old_Value__c =string.valueof(oldShippingAddress.get(fieldName));
                    pm.RecordId__c = oldShippingAddress.Id;
                    pemList.add(pm);
                    break;
                }
            }
                                                                                       
        return pemList;
    }
    
    public static DateTime getUTCDateTime(){
        DateTime dt = System.now();
        return Datetime.newInstanceGmt(dt.year(),dt.month(),dt.day(),dt.hour(),dt.minute(),dt.second());
    }
}