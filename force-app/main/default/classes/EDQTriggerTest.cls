@isTest
public class EDQTriggerTest {
    
    public static testmethod void InsertAccountTest()
    {
        List<Account> aList = new List<Account>();
        aList.add((Account) TestFactory.createSObject(new Account(Name='Blah1', Website='test.test', CSM_First_30d_Stage__c = 'Pending Intro')));
        insert aList;
        
        Contract c= new contract();
        c.name='con1';
        c.AccountId=aList[0].id;
        c.StartDate=date.parse('1/1/2020');
        c.EndDate=date.parse('2/3/2020');
        c.Status='Draft';
        c.ContractTerm=36;
        c.CurrencyIsoCode='USD';
        insert c;
        
        Shipping_Address__c shippingAddress = new Shipping_Address__c();
        shippingAddress.Name = 'Test';
        shippingAddress.Account__c = aList[0].id;
        shippingAddress.Shipping_Address_Line_1__c = '27 Pleasant Plains Rd';
        shippingAddress.Shipping_City__c = 'Franklin Park';
        shippingAddress.Shipping_Country__c = 'United States';
        shippingAddress.Shipping_State__c = 'New Jersey';
        shippingAddress.Shipping_Zip_Code__c = '08823-1307';
        insert shippingAddress;
    }
    
}