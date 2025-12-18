@isTest
public class GS_TaskBatchLMEDTest 
{
    
    @testsetup
    public static void setup()
    {
        insert new Global_Automation_Settings__c(Allow_Handler_Selection__c = true);
    }
    
    static testMethod void testMethod11() 
    {
      
        Account acc2 = new Account();
        acc2.Name ='Test CS Record deletion 2';       
        acc2.Organization_Size__c = '1 - 99';
        acc2.billingstate='Alabama';
        acc2.Account_Assignment_Date__c = System.now().addDays(-700); 
        acc2.Sites_Account_Status__c = 'Assigned to sales';
        //acc2.Last_Contacted__c = System.now().addDays(-5);
        acc2.Last_Meaningful_Engagement_Date__c = (System.now().addDays(-5)).date();
        insert acc2;
        

        Contact con = new Contact();
        con.LastName ='Con';
        con.AccountId = acc2.id;       
        insert con;
        
        System.assertEquals(con.LastName, 'Con');       

        List<Task> lstTask= new List<Task>();
        for(Integer i=0 ;i <4;i++)
        {
            Task t = new Task();
            t.Subject ='Name' + i;
            t.TaskSubtype = 'Call';
            t.CallType = 'Outbound';
            t.Related_Contact__c = con.id;
            t.WhoId = con.id;
            t.CallDurationInSeconds = 100;
            lstTask.add(t);
        }
        
        Task t1 = new Task();
        t1.Subject ='Email Test';
        t1.Related_Contact__c = con.id;
        t1.WhoId = con.id;
        t1.WhatId = lstTask[3].AccountId;
        lstTask.add(t1);
        
        Task t2 = new Task();
        t2.Subject ='Reply Test';
        t2.Related_Contact__c = con.id;
        t2.WhoId = con.id;
        t2.WhatId = lstTask[3].AccountId;
        lstTask.add(t2);
        
        
        insert lstTask;        

        List<Task> lstTaskUpdate = new List<Task>();
        for(Integer i=1 ;i <2;i++)
        {
            Task t = lstTask[i];
            t.Old_Account_Contact__c = lstTask[0].Related_Contact__c + ',' + acc2.id;
            t.Related_Contact__c = lstTask[3].Related_Contact__c;
            t.WhoId = lstTask[3].Related_Contact__c;
            t.WhatId = lstTask[3].AccountId;
            t.CallDurationInSeconds = 100;            

            lstTaskUpdate.add(t);
        }
        update lstTaskUpdate;
        
        Test.startTest();

            GS_TaskBatchLMED obj = new GS_TaskBatchLMED();
            DataBase.executeBatch(obj); 
            
        Test.stopTest();

        
    }    

    static testMethod void myTestMethod3() {        
        test.starttest();
            GS_TaskBatchLMED myClass = new GS_TaskBatchLMED();   
            String chron = '0 1 * * * ?';        
            system.schedule('Test Sched', chron, myClass);
        test.stopTest();
   }

   
}