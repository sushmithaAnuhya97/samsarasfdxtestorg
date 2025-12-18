@isTest
public class createDisclaimerController_Test {
  @isTest
    static void testgetMessage(){
        list<Credit_Report__c>creditReportList=new list<Credit_Report__c>();
        Credit_Report__c creditObj=new Credit_Report__c();
        creditObj.D_B_Data_Available__c=true;
        creditObj.Commercial_Credit_Percentile__c=100;
        creditObj.Financial_Stress_Score_Percentile__c=79;
        creditObj.PAYDEX__c=80;
        creditReportList.add(creditObj);
        
        Credit_Report__c creditObj1=new Credit_Report__c();
         creditObj1.D_B_Data_Available__c=true;
        creditObj1.Commercial_Credit_Percentile__c=10;
        creditObj1.Financial_Stress_Score_Percentile__c=10;
        creditObj1.PAYDEX__c=80;
        creditReportList.add(creditObj1);
        
        Credit_Report__c creditObj2=new Credit_Report__c();
         creditObj2.D_B_Data_Available__c=true;
        creditObj2.Commercial_Credit_Percentile__c=10;
        creditObj2.Financial_Stress_Score_Percentile__c=10;
        creditObj2.PAYDEX__c=10;
        creditReportList.add(creditObj2);
        insert creditReportList;
       
        Test.startTest();
          string response=createDisclaimerController.getMessage(creditReportList[0].id);
          createDisclaimerController.getMessage(creditReportList[1].id);
          createDisclaimerController.getMessage(creditReportList[2].id);
        Test.stopTest();
    System.assert(response !=null,true);          
    }
}