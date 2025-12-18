@isTest
public class GS_TaskRollupBatchTest 
{
    
    /*static testMethod void testMethod1() 
    {
        List<Account> lstAccount= new List<Account>();
        for(Integer i=0 ;i <2;i++)
        {
            Account acc = new Account();
            acc.Name ='Name' + i;       
            acc.Organization_Size__c = '1 - 99';
            acc.billingstate='Alabama';
            acc.Account_Assignment_Date__c = System.now().addDays(-700); 
            lstAccount.add(acc);            
        }
        insert lstAccount;
        

        List<Contact> lstContact= new List<Contact>();
        for(Account a : lstAccount)
        {
            for(Integer i=0 ;i <2;i++)
            {
                Contact con = new Contact();
                con.LastName ='Con' + i;
                con.AccountId = a.id;       
                lstContact.add(con);
            }
        }        
        insert lstContact;
        
        System.assertEquals(lstContact[0].LastName, 'Con0');
        System.assertEquals(lstContact[1].LastName, 'Con1');

        List<Task> lstTask= new List<Task>();
        for(Contact c : lstContact)
        {
            for(Integer i=0 ;i <2;i++)
            {
                Task t = new Task();
                t.Subject ='Name' + i;
                t.TaskSubtype = 'Call';
                t.CallType = 'Outbound';
                t.Related_Contact__c = c.id;
                t.WhoId = c.id;
                t.CallDurationInSeconds = 100;
                lstTask.add(t);
            }
        }
        insert lstTask;

        

        List<Task> lstTaskUpdate = new List<Task>();
        for(Integer i=1 ;i <2;i++)
        {
            Task t = lstTask[i];
            t.Old_Account_Contact__c = lstTask[0].Related_Contact__c + ',' + lstAccount[0].id;
            t.Related_Contact__c = lstTask[3].Related_Contact__c;
            t.WhoId = lstTask[3].Related_Contact__c;
            t.WhatId = lstTask[3].AccountId;
            t.CallDurationInSeconds = 100;            

            lstTaskUpdate.add(t);
        }
        update lstTaskUpdate;
        
        Test.startTest();

            GS_TaskRollupBatch obj = new GS_TaskRollupBatch(8);
            DataBase.executeBatch(obj); 
            
        Test.stopTest();

        GS_TaskRollupHelper.startRollupProcessing(lstTaskUpdate);
    } */   

    static testMethod void testMethod11() 
    {
        Account acc2 = new Account();
        acc2.Name ='Test CS Record deletion 2';       
        acc2.Organization_Size__c = '1 - 99';
        acc2.billingstate='Alabama';
        acc2.Account_Assignment_Date__c = System.now().addDays(-700); 
        acc2.Sites_Account_Status__c = 'Assigned to sales';
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

            GS_TaskRollupBatch obj = new GS_TaskRollupBatch(8);
            DataBase.executeBatch(obj); 
            
        Test.stopTest();

        GS_TaskRollupHelper.startRollupProcessing(lstTaskUpdate);
    }    

    static testMethod void myTestMethod3() {        
        test.starttest();
            GS_TaskRollupBatch myClass = new GS_TaskRollupBatch (8);   
            String chron = '0 1 * * * ?';        
            system.schedule('Test Sched', chron, myClass);
        test.stopTest();
   }

   
}