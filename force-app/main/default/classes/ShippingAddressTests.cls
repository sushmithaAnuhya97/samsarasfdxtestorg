@isTest
public class ShippingAddressTests {
    
    testMethod static void createShippingAddress() {
        
        Account newAccount = new Account(Name = 'Testers 6 Inc',
                                         BillingState='California',
                                         BillingCountry = 'United States',
                                         Organization_Size__c = '100 - 499',
                                         Approved_Payment_Type__c = 'Direct Monthly',
                                         Industry = 'Other');
        insert newAccount;
        
        Contact c = new Contact (Email= 'test@test.com', 
                                 LastName='lastname', 
                                 AccountId = newAccount.Id);
        insert c;
        
        //Test Opportunities
        Opportunity returningOppty = (Opportunity)
            TestFactory.createSObject(new Opportunity(AccountId = newAccount.Id, 
                                                      Type = 'Trial',
                                                      Name = 'Returning Oppty 001',
                                                      StageName = 'Proposal',
                                                      Shipping_Contact__c = c.Id, 
                                                      Price_Book_Name__c = 'Standard',
                                                      Selected_Payment_Type__c = 'Direct Annual'));
        Insert returningOppty;
        
        Shipping_Address__c sa = new Shipping_Address__c(Shipping_Zip_Code__c = '94105', 
                                                         Shipping_Contact__c = c.Id, 
                                                         Shipping_Address_Line_1__c= '1 Dolores, Dallas', 
                                                         Shipping_City__c='Dallas', 
                                                         Shipping_Country__c='United States', 
                                                         Shipping_State__c='Texas', 
                                                         Name='Test', 
                                                         Account__c = newAccount.Id);
        Test.startTest();
        insert sa;
        
        Opportunity ReturnOppty = (Opportunity)
            TestFactory.createSObject(new Opportunity(AccountId = newAccount.Id, 
                                                      Type = 'Exchange',
                                                      Name = 'Return Opportunity 001',
                                                      StageName = 'Return initiated',
                                                      Returning_Opportunity__c = returningOppty.id,
                                                      amount = null,  
                                                      Rebate_Amount__c = null,
                                                      CloseDate = System.today() + 90,
                                                      RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Return Opportunity').getRecordTypeId(),
                                                      Shipping_Contact__c = c.Id,
                                                      Shipping_Address_NEW__c = sa.Id));
        Insert ReturnOppty;
        
        //sa.Shipping_Address_Line_1__c = '2 Dolores, Dallas';
        //sa.Shipping_Zip_Code__c = '94106';
        sa.Shipping_Address_Line_2__c= '3 Dolores, Dallas';
        sa.Shipping_City__c='Alberta';
        sa.Shipping_Email__c = 'test@mail.com';
        sa.Push_to_NetSuite__c = false;
        sa.Shipping_State__c = 'Alberta';
        sa.Shipping_Country__c = 'Canada';
        update sa;
        Test.stopTest();
    }
}