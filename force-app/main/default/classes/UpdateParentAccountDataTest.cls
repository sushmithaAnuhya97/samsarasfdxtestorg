@isTest
public class UpdateParentAccountDataTest {
  
    @isTest
     static void TestUpdateParentAccountData(){
         Test.StartTest();
        Account acc = new Account();
        acc.Name ='Test CS Record deletion';       
        acc.Organization_Size__c = '1 - 99';
        acc.billingstate='Alabama';
        acc.Account_Assignment_Date__c = System.now().addDays(-700); 
        acc.Sites_Account_Status__c = 'Offloaded - Unable to connect';
        acc.Customer_ARR__c = 100;
        acc.SIC__c = UserInfo.getUserId();
        acc.CS_Tier__c = 'Starter';
        insert acc;

        Account acc2 = new Account();
        acc2.Name ='Test CS Record deletion 2';       
        acc2.Organization_Size__c = '1 - 99';
        acc2.billingstate='Alabama';
        acc2.Account_Assignment_Date__c = System.now().addDays(-700); 
        acc2.Sites_Account_Status__c = 'Assigned to sales';
        acc2.parentId = acc.Id;
        acc2.Customer_ARR__c =50;
         acc2.Ultimate_Parent__c = acc.Id;
     acc2.SIC__c = UserInfo.getUserId();
        acc2.CS_Tier__c = 'Starter';       
        insert acc2;
    
        Account acc3 = new Account();
        acc3.Name ='Test CS Record 3';       
        acc3.Organization_Size__c = '1 - 99';
        acc3.billingstate='Alabama';
        acc3.Account_Assignment_Date__c = System.now().addDays(-700); 
        acc3.Sites_Account_Status__c = 'Assigned to sales';
        acc3.parentId = acc.Id;
        acc3.Customer_ARR__c =50;
     acc3.SIC__c = UserInfo.getUserId();
        acc3.CS_Tier__c = 'Starter';       
        insert acc3;
    
        
        List<UpdateParentAccountData.inputVariables> inputVariables = new List<UpdateParentAccountData.inputVariables>();
        UpdateParentAccountData.inputVariables inpVar1 = new UpdateParentAccountData.inputVariables();
        inpVar1.updatedAcc = acc;
        inpVar1.updatedField = 'ARR';
        inputVariables.add(inpVar1);
        UpdateParentAccountData.inputVariables inpVar2 = new UpdateParentAccountData.inputVariables();
        inpVar2.updatedAcc = acc2;
        inpVar2.updatedField = 'CSM';
        inputVariables.add(inpVar2);
        UpdateParentAccountData.inputVariables inpVar3 = new UpdateParentAccountData.inputVariables();
        inpVar3.updatedAcc = acc3;
        inpVar3.updatedField = 'CSTier';
        inputVariables.add(inpVar3);
        List<UpdateParentAccountData.inputVariables> inputVariables2 = new List<UpdateParentAccountData.inputVariables>();
        UpdateParentAccountData.inputVariables inpVar4 = new UpdateParentAccountData.inputVariables();
        inpVar4.updatedAcc = acc;
        inpVar4.updatedField = 'CSTier';
        inputVariables2.add(inpVar4);
        UpdateParentAccountData.updateAccountARR(inputVariables);
        UpdateParentAccountData.updateAccountARR(inputVariables2);
		Test.StopTest();
    }
}