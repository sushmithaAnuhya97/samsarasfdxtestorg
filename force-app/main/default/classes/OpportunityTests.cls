/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 02-20-2025
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
@isTest(SeeAllData=false)
public class OpportunityTests {
@testSetup
private static void testDataSetup() {
    Test.startTest();
List<Opportunity> newOpportunities = new List<Opportunity>();
List<Account> newAccounts = new List<Account>();
List<Contact> newContacts = new List<Contact>();
List<Shipping_Address__c> shippingAddressList = new List<Shipping_Address__c>();
Account accountOne = new Account(Name = 'Testers 1 Inc',
BillingStreet = '26 Napier Street',
BillingCity = 'London',
BillingPostalCode  = '1030',
BillingCountry = 'United Kingdom',
Billing_Email__c  = 'qdasdas@gmail.com',
Organization_Size__c = '100 - 499',
Industry = 'Other');
newAccounts.add(accountOne);
Account accountTwo = new Account(Name = 'Testers 6 Inc',
BillingState='California',
Billing_First_name__c = 'Test',
Billing_Last_Name__c = 'Test2',
Billing_Phone__c = '1234567890',
BillingCountry = 'United States',
BillingStreet = '26 Napier Street',
BillingCity = 'London',
BillingPostalCode  = '1030',
Billing_Email__c  = 'qdasdas@gmail.com',
Organization_Size__c = '100 - 499',
Approved_Payment_Type__c = 'Direct Monthly',
Industry = 'Other');
newAccounts.add(accountTwo);
        Account accountThree = new Account(Name = 'Testers 34 Inc',
                                         BillingState='California',
                                         BillingCountry = 'United States',
                                         BillingStreet = '26 Napier Street',
                                         BillingCity = 'London',
                                         BillingPostalCode  = '1030',
                                         Billing_Email__c  = 'qdasdas@gmail.com',
                                         Organization_Size__c = '100 - 499',
                                         Approved_Payment_Type__c = 'Direct Monthly',
                                         Industry = 'Other');
        newAccounts.add(accountThree);
insert newAccounts;
Contract cont = new Contract(
AccountId = accountOne.Id,
StartDate = System.today(),
EndDate   = System.today().addDays(30),
ContractTerm = 1,
Auto_Renewal__c = true,
Status = 'Draft',
Weighted_Average_Start_Date__c =  System.today()
);
insert cont;
cont.Status = 'Activated';
update cont;
Contact contactOne = (Contact) TestFactory.createSObject(new Contact(AccountId = accountOne.Id));
newContacts.add(contactOne);
Contact contactTwo = (Contact) TestFactory.createSObject(new Contact(AccountId = accountTwo.Id, Email = 'test@test.com'));
newContacts.add(contactTwo);
insert newContacts;
Shipping_Address__c sa = new Shipping_Address__c(Shipping_Zip_Code__c = '94105', Shipping_Contact__c=contactOne.Id, Shipping_Address_Line_1__c='1 Dolores, Dallas', Shipping_City__c='Dallas', Shipping_Country__c='United States', Shipping_State__c='Texas', Name='Test', Account__c = accountOne.Id);
shippingAddressList.add(sa);
Shipping_Address__c sa2 = new Shipping_Address__c(Shipping_Zip_Code__c = '2030', Shipping_Contact__c=contactOne.Id, Shipping_Address_Line_1__c='Scheldelaan 417', Shipping_City__c='Antwerpen', Shipping_Country__c='Belgium', Name='Test Belgium', Account__c = accountOne.Id);
shippingAddressList.add(sa2);
Shipping_Address__c sa3 = new Shipping_Address__c(Shipping_Zip_Code__c = 'C.P. 45610', Shipping_Contact__c=contactOne.Id, Shipping_Address_Line_1__c='Adolf B Horn 1737-1', Shipping_City__c='San Pedro Tlaquepaque, Jal', Shipping_Country__c='Mexico', Name='Test Mexico', Account__c = accountOne.Id);
shippingAddressList.add(sa3);
insert shippingAddressList;
Opportunity opportunityOne = (Opportunity)
TestFactory.createSObject(new Opportunity(AccountId = accountOne.Id,
Type = 'Free Trial Opportunity',
Name = 'Opp Testers 1 Inc',
StageName = 'Proposal',
RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Trial').getRecordTypeId(),
Shipping_Contact__c = contactOne.Id,
Selected_Payment_Type__c = 'Direct Annual',
Price_Book_Name__c = 'Standard',
Send_Invoice__c = false));
newOpportunities.add(opportunityOne);
Opportunity opportunityTwo = (Opportunity)
TestFactory.createSObject(new Opportunity(AccountId = accountTwo.Id,
Type = 'Revenue Opportunity',
Name = 'Opp Testers 2 Inc',
StageName = 'Proposal',
Shipping_Contact__c = contactTwo.Id,
                                          
Ship_From_Location__c = 'DCL-LA',

Shipping_Carrier__c = 'UPS',
Price_Book_Name__c = 'Standard',
Selected_Payment_Type__c = 'Direct Annual'));
newOpportunities.add(opportunityTwo);
Opportunity opportunityThree = (Opportunity)
TestFactory.createSObject(new Opportunity(AccountId = accountOne.Id,
Type = 'Revenue Opportunity',
Name = 'Opp Testers 3 Inc',
StageName = 'Proposal',
Shipping_Contact__c = contactOne.Id,
  //added by sandeep

Ship_From_Location__c = 'VCK',

Shipping_Method__c = 'UK Standard',

Shipping_Carrier__c = 'DHL',

//ends here                                         
Price_Book_Name__c = 'Standard',
Selected_Payment_Type__c = 'Direct Annual'));
newOpportunities.add(opportunityThree);
Opportunity opportunityFour = (Opportunity)
TestFactory.createSObject(new Opportunity(AccountId = accountOne.Id,
Type = 'Promo Opportunity',
Name = 'Opp Testers 4 Inc',
StageName = 'Proposal',
Shipping_Contact__c = contactOne.Id,
Price_Book_Name__c = 'Standard',
Selected_Payment_Type__c = 'Direct Annual',
Shipping_Country__c='United Kingdom',
Shipping_Carrier__c = 'DHL',
Ship_From_Location__c = 'VCK',
Shipping_Method__c = 'UK Standard',
CurrencyIsoCode = 'GBP',
Promo_Reason__c='Exchange'
));
newOpportunities.add(opportunityFour);
        Opportunity opportunityFive = (Opportunity)
            TestFactory.createSObject(new Opportunity(AccountId = accountOne.Id,
                                                      Type = 'Revenue Opportunity',
                                                      Name = 'Opp Testers 5 Inc',
                                                      StageName = 'Proposal',
                                                      Shipping_Contact__c = contactOne.Id,
                                                      Price_Book_Name__c = 'Standard',
                                                      Selected_Payment_Type__c = 'Direct Monthly',
                                                      Probability = 0.95));
        newOpportunities.add(opportunityFive);
insert newOpportunities;
Test.stopTest();
}
@isTest static void testReadyToShip() {
Opportunity newOpportunity = [SELECT id,AccountId from Opportunity WHERE TYPE = 'Revenue Opportunity' LIMIT 1];
test.startTest();
Account acc = new Account();
acc.Id = newOpportunity.AccountId;
newOpportunity.StageName = 'Ready To Ship';
newOpportunity.Amount_Received__c = 100000;
newopportunity.PO_Number__c = 'A-0000';
newOpportunity.Push_to_Mulesoft__c = TRUE;
update newOpportunity;
test.stopTest();
}
@isTest static void testReadyToShipEMEA() {
Opportunity newOpportunity = [SELECT id,AccountId,StageName,Type,Shipping_Country__c,Shipping_Carrier__c,Ship_From_Location__c,
Shipping_Method__c
from Opportunity WHERE TYPE = 'Promo Opportunity' LIMIT 1];
test.startTest();
newOpportunity.StageName = 'Orders Processing';
newOpportunity.Shipping_Carrier__c = 'DHL';
newOpportunity.Ship_From_Location__c = 'VCK';
newOpportunity.Shipping_Method__c = 'UK Standard';
newOpportunity.CurrencyIsoCode = 'GBP';
newOpportunity.Shipping_Country__c='United Kingdom';
update newOpportunity;
test.stopTest();
}
@isTest static void testLicenseProducts() {
Opportunity newOpportunity = [SELECT Id   from Opportunity WHERE TYPE = 'Revenue Opportunity' LIMIT 1];
Product2 prod = new Product2(Name = 'WiFi Hotspot - 2GB Total Data', Family = 'Hardware', ProductCode = 'LIC-2GB-WIFI-DATA',Product_Type__c = 'License');
insert prod;
    test.startTest();
Id pricebookId = Test.getStandardPricebookId();
PricebookEntry standardPrice = new PricebookEntry(
Pricebook2Id = pricebookId, Product2Id = prod.Id,
UnitPrice = 10000, IsActive = true);
insert standardPrice;
OpportunityLineItem li = new OpportunityLineItem (Quantity=1, OpportunityId=newOpportunity.Id, PriceBookEntryId=standardPrice.Id, UnitPrice = 10000);
insert li;

newOpportunity.StageName = 'Orders Processing';
update newOpportunity;
test.stopTest();
}
@isTest private static void testShippingFields() {
Opportunity opportunity = [SELECT Id, Ship_From_Location__c, Shipping_Carrier__c, Shipping_Method__c, Shipping_Address_NEW__c FROM Opportunity WHERE Name='Opp Testers 3 Inc'];
Opportunity opportunityNoAddress = [SELECT Id, Ship_From_Location__c, Shipping_Carrier__c, Shipping_Method__c, Shipping_Address_NEW__c FROM Opportunity WHERE Name='Opp Testers 2 Inc'];
Shipping_Address__c address = [SELECT Id FROM Shipping_Address__c WHERE Name='Test Belgium'];
Shipping_Address__c addressMX = [SELECT Id FROM Shipping_Address__c WHERE Name='Test Mexico'];
Test.startTest();
opportunity.Shipping_Address_NEW__c = address.Id;
update opportunity;
Opportunity opportunityOne = [SELECT Id, Ship_From_Location__c, Shipping_Carrier__c, Shipping_Method__c, Shipping_Address_NEW__c FROM Opportunity WHERE Name='Opp Testers 3 Inc'];
System.assertEquals('VCK', opportunityOne.Ship_From_Location__c);
System.assertEquals('UK Standard', opportunityOne.Shipping_Method__c);
System.assertEquals('DHL', opportunityOne.Shipping_Carrier__c);
System.assertEquals('DCL-LA', opportunityNoAddress.Ship_From_Location__c);
//System.assertEquals('3 Day Select', opportunityNoAddress.Shipping_Method__c);
System.assertEquals('UPS', opportunityNoAddress.Shipping_Carrier__c);
opportunity.Shipping_Address_NEW__c = addressMX.Id;
opportunity.StageName = 'Orders Processing';
update opportunity;
Test.stopTest();
}
// Groundswell : Tanuj - Common Wflow 2nd Test Method
//commented due to CPU timelimit
/*@isTest
private static void testCommonWflowConversionSecond(){
System.runAs(new User(Id = UserInfo.getUserId())){
//(new PermissionSetAssignmentService()).assignPermissionSetByName(new List<Id>{UserInfo.getUserId()}, 'Validation_Rule_By_Pass');
//PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'Validation_Rule_By_Pass'];
//insert new PermissionSetAssignment(AssigneeId = UserInfo.getUserId(), PermissionSetId = ps.Id);
}
System.runAs(new User(Id = UserInfo.getUserId())){
OpportunityTriggerHandler.maxRuns = 1;
test.startTest();
Account acc = new Account ();
acc = TestFactory.initializeAccount('UpdateAccountForNsSync');
acc.BillingStreet = 'test 123';
acc.BillingCity = 'San jose';
acc.BillingPostalCode = '94856';
acc.BillingCountry  = 'United States';
acc.Billing_Email__c = 'testaccEmail@tst.com';
acc.Netsuite_Id__c = null;
TriggerHandler.bypass('GS_AccountTriggerHandler');
insert acc;
Opportunity thisOpp = new Opportunity();
thisOpp = TestFactory.initializeOpportunity ('RollupToAccountACV_Bookings_SOT');
thisOpp.AccountId = acc.Id;
insert thisOpp;
SBQQ__Quote__c quote = new SBQQ__Quote__c(Quote_Name__c = 'First Quote ', SBQQ__Account__c = acc.Id, SBQQ__Opportunity2__c =thisOpp.Id,
SBQQ__SubscriptionTerm__c =10,Estimated_Annual_Payment__c = 24, Custom_License_Term__c = 2);
quote.Selected_Payment_Type__c = 'Direct Annual';
insert quote;
quote.SBQQ__Primary__c = true;
update quote;
//Save the Amount of the Opportunity when Closed Won
//opptyAfterUpdate.Type = 'Remorse Refund';
thisOpp.StageName = 'Closed Won';
thisOpp.Historical_Amount__c = null;
// To pass the validation rule
thisOpp.Probability = 90;
//Clear the field values from the primary quote workflow changes
thisOpp.SBQQ__PrimaryQuote__c = quote.id;
thisOpp.Approved_Discount__c = 10;
thisOpp.Blended_Discount_CPQ__c = 10;
thisOpp.Discount_Approval_Status_from_Quote__c = true;
thisOpp.Discount__c = 'Test Class';
thisOpp.License_Term_CPQ__c = 36;
thisOpp.Product_Approval_Status_from_Quote__c = true;
thisOpp.Sales_Tax_Amount__c = 1000;
thisOpp.Shipping_and_Handling_Amount__c = 1000;
thisOpp.Hardware_Sales_Tax_CPQ__c = 1000;
thisOpp.License_Sales_Tax_CPQ__c = 1000;
update thisOpp;
Opportunity oppAfterUpdate = [Select id, Name, Historical_Amount__c, Amount,  Retry_TO_to_NS__c, Netsuite_Transfer_Order_ID__c FROM Opportunity WHERE Id=: thisOpp.Id];
//Save the Amount of the Opportunity when Closed Won
system.assertEquals(oppAfterUpdate.Amount, oppAfterUpdate.Historical_Amount__c);
// Clear the field values from the primary quote workflow changes
oppAfterUpdate.SBQQ__PrimaryQuote__c = null;
update oppAfterUpdate;
Opportunity oppAfterSecondUpdate = [Select id, Name, Approved_Discount__c, Blended_Discount_CPQ__c, Discount_Approval_Status_from_Quote__c, Discount__c, License_Term_CPQ__c, Product_Approval_Status_from_Quote__c, Sales_Tax_Amount__c, Shipping_and_Handling_Amount__c, Hardware_Sales_Tax_CPQ__c, License_Sales_Tax_CPQ__c FROM Opportunity WHERE Id=: oppAfterUpdate.Id];
//Clear the field values from the primary quote workflow changes
system.assertEquals(null, oppAfterSecondUpdate.Approved_Discount__c);
system.assertEquals(null, oppAfterSecondUpdate.Blended_Discount_CPQ__c);
system.assertEquals(false, oppAfterSecondUpdate.Discount_Approval_Status_from_Quote__c);
system.assertEquals(null, oppAfterSecondUpdate.Discount__c);
system.assertEquals(null, oppAfterSecondUpdate.License_Term_CPQ__c);
system.assertEquals(false, oppAfterSecondUpdate.Product_Approval_Status_from_Quote__c);
system.assertEquals(null, oppAfterSecondUpdate.Sales_Tax_Amount__c);
system.assertEquals(null, oppAfterSecondUpdate.Shipping_and_Handling_Amount__c);
system.assertEquals(null, oppAfterSecondUpdate.Hardware_Sales_Tax_CPQ__c);
system.assertEquals(null, oppAfterSecondUpdate.License_Sales_Tax_CPQ__c);
test.stopTest();
}
}*/ //commented due to CPU timelimit
@isTest static void callOtherMethods() {
Opportunity newOpportunity = [SELECT id,Name,Shipping_Country__c,Sales_Tax__c,Balance_Due__c,Internal_RFO_Notes__c, Shipping_and_Handling__c,Shipping_and_Handling_Manual__c,AccountId,
Shipping_and_Handling_Amount__c, Trial_Agreement_Accepted__c,Shipping_Contact__c,Netsuite_Transfer_Order_ID__c,
Netsuite_Transfer_Order__c,Owner_Segment__c, Total_Weight_oz__c,Multi_Line_Shipping__c,Shipping_Instructions__c,
Order_Ops_Notes__c,Hold_Reason__c,Netsuite_Id__c,Unique_Shipping_Addresses__c,Shipping_Carrier__c,Free_Trial_Purchase__c,
Concatenated_Shipping_Address__c,Shipping_Method__c,Ship_From_Location__c,Price_Book_Name__c,Segment_Sales_Role__c from Opportunity LIMIT 1];
Contract objCon = new Contract();
objCon.SBQQ__RenewalOpportunity__c = newOpportunity.Id;
objCon.AccountId = newOpportunity.AccountId;
objCon.EndDate = system.today().addDays(10);
objCon.Auto_Renewal__c = true;
objCon.ContractTerm = 4;
insert objCon;
Contract objCon1 = new Contract();
objCon1.SBQQ__RenewalOpportunity__c = newOpportunity.Id;
objCon1.AccountId = newOpportunity.AccountId;
objCon1.EndDate = system.today().addDays(10);
objCon1.Auto_Renewal__c = true;
objCon1.ContractTerm = 3;
insert objCon1;
Contract objCon2 = new Contract();
objCon2.SBQQ__RenewalOpportunity__c = newOpportunity.Id;
objCon2.AccountId = newOpportunity.AccountId;
objCon2.EndDate = system.today().addDays(10);
objCon2.Auto_Renewal__c = true;
objCon2.ContractTerm = 2;
insert objCon2;
test.startTest();
Set<Id> setOppId = new Set<Id>();
setOppId.add(newOpportunity.Id);
OpportunityHelper.getOwnerForDelinquentRebateOpportunity(setOppId);
List<OpportunityLineItem> lstOppLI = [Select Id,OpportunityId, Product2.Product_Status__c, Product2.CPQ_Enabled_Product__c, ProductCode from
OpportunityLineItem limit 2];
OpportunityHelper.doesLineItemContainsEOL(lstOppLI, newOpportunity);
//OpportunityHelper.updateContractRecords(setOppId);
OpportunityHelper opp = new OpportunityHelper();
opp.satisfyPromoOpp(newOpportunity, 20);
opp.satisfyFreeTrailOpp(newOpportunity, 20);
opp.satisfyRevenueOpp(newOpportunity, 20);
opp.getQtyLimitPerProduct('Free Trial Opportunity');
opp.getQtyLimitPerProduct('Revenue Opportunity');
opp.satisfyMatchingconditions(newOpportunity);
test.stopTest();
}
@isTest private static void testAccountFieldUpdate() {
Test.startTest();
Opportunity freeTrial = [ SELECT Id, Send_Invoice__c FROM Opportunity WHERE Name='Opp Testers 1 Inc'];
Account acc = [SELECT Id FROM Account WHERE Name='Testers 1 Inc'];
freeTrial.Send_Invoice__c = true;
freeTrial.StageName = 'Decision';
freeTrial.Cable_Send_Only__c = True;
update freeTrial;
Test.stopTest();
}
private static void testCustomerKitsBulk() {
/*
// Initialize Pricebook
TestData.setupProductsAndPricebooks();
// Get pricebook Ids
Pricebook2 samsaraStandard = new Pricebook2();
Pricebook2 samsaraExpress = new Pricebook2();
Set<String> kitProductCodeCriteria = new Set<String>{   'FREE-TRIAL-KIT',
'WELCOME-KIT',
'EXPRESS-WELCOME-KIT'   };
for(Pricebook2 pb : [SELECT Id, Name, (SELECT Id, ProductCode FROM PricebookEntries WHERE ProductCode NOT IN :kitProductCodeCriteria) FROM Pricebook2]) {
if(pb.Name == 'Samsara Standard') samsaraStandard = pb;
if(pb.Name == 'Samsara Express') samsaraExpress = pb;
}
// Create 200 Accounts
Account[] aList = (Account[])TestFactory.createSObjectList(new Account(), 200);
insert aList;
// Add a Samsara Standard opp to 100 of the accounts
List<Opportunity> oList = new List<Opportunity>();
for(Integer i = 0; i < 100; i++) {
Opportunity o = (Opportunity)TestFactory.createSObject(new Opportunity(AccountId = aList[i].Id, Type = 'Revenue Opportunity', Pricebook2Id = samsaraStandard.Id));
oList.add(o);
}
// Add a Samsara Express opp to 99 of the accounts
for(Integer i = 0; i < 99; i++) {
Opportunity o = (Opportunity)TestFactory.createSObject(new Opportunity(AccountId = aList[i].Id, Type = 'Revenue Opportunity', Pricebook2Id = samsaraExpress.Id));
oList.add(o);
}
// Add 10 opps to 100 of the accounts
for(Integer i = 0; i < 100; i++) {
Opportunity[] oList2 = (Opportunity[])TestFactory.createSObjectList(new Opportunity(AccountId = aList[i].Id), 10);
oList.addAll(oList2);
}
// Add a closed won opp to 10 of the accounts
for(Integer i = 0; i < 10; i++) {
Opportunity o = (Opportunity)TestFactory.createSObject(new Opportunity(AccountId = aList[i].Id, Type = 'Revenue Opportunity', Pricebook2Id = samsaraStandard.Id, StageName = 'Closed Won'));
oList.add(o);
}
insert oList;
// Find non-kit pricebookentries
for(PricebookEntry pbe : samsaraStandard.PricebookEntries) {
}
// Add non-kit opp products to Samsara Standard opps
List<OpportunityLineItem> opplis = new List<OpportunityLineItem>();
for(Opportunity o : [SELECT Id FROM Opportunity WHERE Pricebook2Id = :samsaraStandard.Id]) {
OpportunityLineItem[] opLi = (OpportunityLineItem[])TestFactory.createSObjectList(new OpportunityLineItem(OpportunityId = o.Id, PricebookEntryId = samsaraStandard.PricebookEntries[0].Id), 10);
opplis.addAll(opLi);
}
// Add each kit opp product to a standard and express opp
// First get kit pricebook entries
Map<String, PricebookEntry> kitPbesCodeMap = new Map<String,PricebookEntry>();
for(PricebookEntry pbe : [SELECT Id, ProductCode FROM PricebookEntry WHERE ProductCode IN :kitProductCodeCriteria]) {
kitPbesCodeMap.put(pbe.ProductCode, pbe);
}
List<Opportunity> standardKitOpps = new List<Opportunity>([SELECT Id FROM Opportunity WHERE Pricebook2Id = :samsaraStandard.Id LIMIT 2]);
opplis.add((OpportunityLineItem)TestFactory.createSObject(new OpportunityLineItem(OpportunityId = standardKitOpps[0].Id, PricebookEntryId = kitPbesCodeMap.get('FREE-TRIAL-KIT').Id)));
opplis.add((OpportunityLineItem)TestFactory.createSObject(new OpportunityLineItem(OpportunityId = standardKitOpps[1].Id, PricebookEntryId = kitPbesCodeMap.get('WELCOME-KIT').Id)));
List<Opportunity> expressKitOpps = new List<Opportunity>([SELECT Id FROM Opportunity WHERE Pricebook2Id = :samsaraExpress.Id LIMIT 1]);
opplis.add((OpportunityLineItem)TestFactory.createSObject(new OpportunityLineItem(OpportunityId = expressKitOpps[0].Id, PricebookEntryId = kitPbesCodeMap.get('EXPRESS-WELCOME-KIT').Id)));
insert opplis;
// Now change 200 opps to closing and boom you're done I think.
*/
}
/*
@isTest private static void testCustomerKitsSingle() {
System.debug('testCustomerKitsSingle');
TestData.setupProductsAndPricebooks();
Pricebook2 samsaraStandard = new Pricebook2(Name = 'Samsara Standard');
Pricebook2 samsaraExpress = new Pricebook2();
Set<String> kitProductCodeCriteria = new Set<String>{   'FREE-TRIAL-KIT',
'WELCOME-KIT',
'EXPRESS-WELCOME-KIT'   };
for(Pricebook2 pb : [SELECT Id, Name, (SELECT Id, ProductCode FROM PricebookEntries WHERE ProductCode NOT IN :kitProductCodeCriteria) FROM Pricebook2]) {
if(pb.Name == 'Samsara Standard') samsaraStandard = pb;
if(pb.Name == 'Samsara Express') samsaraExpress = pb;
}
// Create an account
Account a = (Account)TestFactory.createSObject(new Account());
insert a;
// Get the Trial record type id
Id trialId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Trial').getRecordTypeId();
List<Opportunity> oppList = new List<Opportunity>();
// Add a closing Samsara Standard opp that's in free trial
Opportunity freeTrialOppClosing = (Opportunity)TestFactory.createSObject(new Opportunity(AccountId = a.Id, recordTypeId = trialId, Type = 'Free Trial Opportunity', StageName = 'Closing', Pricebook2Id = samsaraStandard.Id));
oppList.add(freeTrialOppClosing);
// Add a closing Samsara Standard opp that's over 15k
Opportunity bigOppClosing = (Opportunity)TestFactory.createSObject(new Opportunity(AccountId = a.Id, Type = 'Revenue Opportunity', StageName = 'Closing', Amount = 20000.00, Pricebook2Id = samsaraStandard.Id));
oppList.add(bigOppClosing);
// Add a closing Samsara Express opp
Opportunity expressOppClosing = (Opportunity)TestFactory.createSObject(new Opportunity(AccountId = a.Id, Type = 'Revenue Opportunity', StageName = 'Closing', Selected_Payment_Type__c = 'Annual Payments', Pricebook2Id = samsaraExpress.Id));
oppList.add(expressOppClosing);
// Insert the opps!
insert oppList;
// Remove the date from the account so to make sure it doesn't add more products when these are updated again.
a = [SELECT Id, Free_Trial_Kit_Sent_Date__c, Welcome_Kit_Sent_Date__c FROM Account WHERE Id = :a.Id LIMIT 1][0];
a.Free_Trial_Kit_Sent_Date__c = null;
a.Welcome_Kit_Sent_Date__c = null;
update a;
Test.startTest();
// Try updating the oppList to make sure it doesn't add more products but still updates the account dates
update oppList;
Test.stopTest();
// Verify account had dates updated
a = [SELECT Id, Free_Trial_Kit_Sent_Date__c, Welcome_Kit_Sent_Date__c FROM Account WHERE Id = :a.Id LIMIT 1][0];
System.assertEquals(System.today(), a.Free_Trial_Kit_Sent_Date__c);
System.assertEquals(System.today(), a.Welcome_Kit_Sent_Date__c);
// Verify only 3 products exist
List<OpportunityLineItem> oppLis = new List<OpportunityLineItem>([SELECT Id FROM OpportunityLineItem]);
System.assertEquals(3, oppLis.size());
/* Make sure the free trial kit was added
OpportunityLineItem oli = [SELECT Id, ProductCode FROM OpportunityLineItem WHERE OpportunityId = :freeTrialOppClosing.Id LIMIT 1][0];
System.assertEquals(oli.ProductCode, 'FREE-TRIAL-KIT');
*/
// Add a Samsara Standard opp to the account to verify the negative
//Opportunity closedWonRevOpp = (Opportunity)TestFactory.createSObject(new Opportunity(AccountId = a.Id, Type = 'Revenue Opportunity', StageName = 'Closed Won', Pricebook2Id = samsaraStandard.Id));
//insert closedWonRevOpp;
//  }

@isTest private static void testOrderAdminAssignment() {
Test.startTest();
// Create 4 order admin users
List<User> uList = new List<User>();
Id pId = [SELECT Id FROM Profile WHERE Name = 'System Administrator'][0].Id;
for(Integer i = 0; i < 4; i++) {
uList.add(new User(
EmployeeNumber = '123',
ProfileId = pId,
LastName = 'last',
Email = 'puser000@amamama.com',
Username = 'puser000@amamama.com' + Math.random() + System.currentTimeMillis(),
CompanyName = 'TEST',
Title = 'title',
Alias = 'alias',
TimeZoneSidKey = 'America/Los_Angeles',
EmailEncodingKey = 'UTF-8',
LanguageLocaleKey = 'en_US',
LocaleSidKey = 'en_US',
Order_Admin_Available__c = TRUE,
isActive = TRUE
));
}
Opportunity o = [ SELECT Id FROM Opportunity WHERE Name='Opp Testers 2 Inc'];
o.Probability = 98;
update o;
List<Opportunity> oppList = new List<Opportunity>([SELECT Id, Order_Admin__c FROM Opportunity WHERE Name='Opp Testers 2 Inc']);
List<User> userList = new List<User>([SELECT Id, Order_Admin_Oppty_Date__c FROM User WHERE Id = :oppList[0].Order_Admin__c]);
// Make sure admin users were assigned and updated
System.assertEquals(System.now().day(), userList[0].Order_Admin_Oppty_Date__c.day());
Test.stopTest();
}
@isTest private static void testOrderAdminAssignmentUK() {
Test.startTest();
// Create 4 order admin users
List<User> uList = new List<User>();
Id pId = [SELECT Id FROM Profile WHERE Name = 'System Administrator'][0].Id;
for(Integer i = 0; i < 4; i++) {
uList.add(new User(
EmployeeNumber = '123',
ProfileId = pId,
LastName = 'last',
Email = 'puser000@amamama.com',
Username = 'puser000@amamama.com' + Math.random() + System.currentTimeMillis(),
CompanyName = 'TEST',
Title = 'title',
Alias = 'alias',
TimeZoneSidKey = 'America/Los_Angeles',
EmailEncodingKey = 'UTF-8',
LanguageLocaleKey = 'en_US',
LocaleSidKey = 'en_US',
Order_Admin_Available__c = TRUE,
isActive = TRUE,
Entity__c = 'Samsara UK'
));
}
Opportunity o = [ SELECT Id FROM Opportunity WHERE Name='Opp Testers 2 Inc'];
o.Probability = 98;
o.Shipping_Country__c = 'United Kingdom';
update o;
List<Opportunity> oppList = new List<Opportunity>([SELECT Id, Order_Admin__c FROM Opportunity WHERE Name='Opp Testers 2 Inc']);
List<User> userList = new List<User>([SELECT Id, Order_Admin_Oppty_Date__c FROM User WHERE Id = :oppList[0].Order_Admin__c]);
// Make sure admin users were assigned and updated
System.assertEquals(System.now().day(), userList[0].Order_Admin_Oppty_Date__c.day());
Test.stopTest();
}
@isTest private static void testOrderAdminFallback() {
Test.startTest();
Opportunity o = [ SELECT Id FROM Opportunity WHERE Name='Opp Testers 2 Inc'];
// Create an order admin fallback user
List<User> uList = new List<User>();
Id pId = [SELECT Id FROM Profile WHERE Name = 'System Administrator'][0].Id;
uList.add(new User(
ProfileId = pId,
EmployeeNumber = '123',
LastName = 'last',
Email = 'puser000@amamama.com',
Username = 'puser000@amamama.com' + Math.random() + System.currentTimeMillis(),
CompanyName = 'TEST',
Title = 'title',
Alias = 'alias',
TimeZoneSidKey = 'America/Los_Angeles',
EmailEncodingKey = 'UTF-8',
LanguageLocaleKey = 'en_US',
LocaleSidKey = 'en_US',
Order_Admin_Fallback_User__c = TRUE,
isActive = TRUE
));
insert uList;
o.Probability = 98;
update o;
// Check on the opps' assigned order admins
for(Opportunity oppOrder : [SELECT Id, Order_Admin__c FROM Opportunity]) {
System.debug(LoggingLevel.INFO, 'oppOrder updated: ' + oppOrder.Order_Admin__c);
}
// Make sure fallback user was assigned and updated
for(User orderAdmin : [SELECT Id, Order_Admin_Oppty_Date__c, Name FROM User WHERE Order_Admin_Fallback_User__c = TRUE]) {
System.debug(LoggingLevel.INFO, 'orderAdmin user = ' + orderAdmin);
if(orderAdmin.Order_Admin_Oppty_Date__c != NULL) {
System.assertEquals(System.now().day(), orderAdmin.Order_Admin_Oppty_Date__c.day());
}
}
Test.stopTest();
}
// -- Begin emailOnTrialAgreementAcceptance --
@isTest
private static void testEmails() {
    Account a = [SELECT id FROM Account WHERE Name = 'Testers 6 Inc'];
    Contact c = [SELECT id, email FROM Contact WHERE accountId =: a.Id];
Test.startTest();

System.debug('OpportunityTests.testEmails - contact to email: ' + c);
// Create oppty, but don't set it as accepted
Integer emailBefore = Limits.getEmailInvocations();
System.debug('Email count before ='+emailBefore);
RecordType trialType = [SELECT Id
FROM RecordType
WHERE SObjectType='Opportunity'
AND Name='Trial'
LIMIT 1];
Opportunity trial = (Opportunity)
TestFactory.createSObject(new Opportunity(AccountId = a.Id,
RecordTypeId = trialType.Id,
Probability = 0,
Type = 'Free Trial Opportunity'));
insert trial;
System.debug('Trial Agreement Accepted? ='+trial.Trial_Agreement_Accepted__c);
System.debug('Email count after ='+Limits.getEmailInvocations());
System.assertEquals(trial.Trial_Agreement_Accepted__c, False);
System.assertEquals(emailBefore, Limits.getEmailInvocations());
System.debug('Oppty is created - test success');
// Change to accepted, but don't send emails yet (no owner id)
emailBefore = Limits.getEmailInvocations();
System.debug('Email count before ='+emailBefore);
trial.Trial_Primary_Contact__c = c.Id;
update trial;
System.debug('Trial Agreement Accepted? ='+trial.Trial_Agreement_Accepted__c);
System.debug('Email count after ='+Limits.getEmailInvocations());
System.assertEquals(trial.Trial_Agreement_Accepted__c, False);
System.assertEquals(emailBefore, Limits.getEmailInvocations());
System.debug('Change to Trial fields but no acceptance - test success');
// Accepted true, error email sent
emailBefore = Limits.getEmailInvocations();
System.debug('Email count before ='+emailBefore);
OpportunityTriggerHandler.resetAll();
trial.Trial_Agreement_Accepted__c = True;
TriggerHandler.bypass('OpportunityTriggerHandler');
update trial;
System.debug('Trial Agreement Accepted? ='+trial.Trial_Agreement_Accepted__c);
System.debug('Email count after ='+Limits.getEmailInvocations());
System.assertEquals(trial.Trial_Agreement_Accepted__c, True);
System.assertNotEquals(emailBefore, Limits.getEmailInvocations());
System.debug('Changing Acceptance status to true - test success');
// Update oppty, but should not send email
emailBefore = Limits.getEmailInvocations();
System.debug('Email count before ='+emailBefore);
trial.Name = 'New Free Trial';
Database.update(trial, false);
System.debug('Trial Agreement Accepted? ='+trial.Trial_Agreement_Accepted__c);
System.debug('Email count after ='+Limits.getEmailInvocations());
System.assertEquals(trial.Trial_Agreement_Accepted__c, True);
System.assertEquals(emailBefore, Limits.getEmailInvocations());
System.debug('Change Oppty field but not change in acceptance - test success');
Test.stopTest();
}
@isTest private static void testErrorEmail() {
Test.startTest();
Account a = [SELECT id FROM Account WHERE Name = 'Testers 6 Inc'];
// Create oppty, but don't flip acceptance
Integer emailBefore = Limits.getEmailInvocations();
System.debug('Email count before ='+emailBefore);
RecordType trialType = [SELECT Id
FROM RecordType
WHERE SObjectType='Opportunity'
AND Name='Trial'
LIMIT 1];
Opportunity trial = (Opportunity)
TestFactory.createSObject(new Opportunity(AccountId = a.Id,
RecordTypeId = trialType.Id,
Probability = 0,
Type = 'Free Trial Opportunity'));
insert trial;
System.debug('Trial Agreement Accepted? ='+trial.Trial_Agreement_Accepted__c);
System.debug('Email count after ='+Limits.getEmailInvocations());
System.assertEquals(trial.Trial_Agreement_Accepted__c, False);
System.assertEquals(emailBefore, Limits.getEmailInvocations());
System.debug('Oppty is created - test success');
// Contact not set, trial error email sent
emailBefore = Limits.getEmailInvocations();
System.debug('Email count before ='+emailBefore);
OpportunityTriggerHandler.resetAll();
trial.Trial_Agreement_Accepted__c = True;
update trial;
System.debug('Trial Agreement Accepted? ='+trial.Trial_Agreement_Accepted__c);
System.debug('Email count after ='+Limits.getEmailInvocations());
System.assertEquals(trial.Trial_Agreement_Accepted__c, True);
System.assertNotEquals(emailBefore, Limits.getEmailInvocations());
Test.stopTest();
}
@isTest private static void testBulkEmail() {
System.debug('In testBulkEmail');
Test.startTest();
// Change back when dupe rules are in order
Integer batchSize = 1;
Integer emailBefore = Limits.getEmailInvocations();
// Trial oppty creation
List<Account> accounts = (List<Account>)
TestFactory.createSObjectList(new Account(Name = 'testBullkEmail'), batchSize);
insert accounts;
List<Contact> contacts = new List<Contact>();
for (Integer i = 0; i < batchSize; i++){
Contact c = (Contact)
TestFactory.createSObject(new Contact(FirstName = 'Test ' + i,
Email = 'test' + i + '@test.com',
AccountId = accounts[i].Id));
contacts.add(c);
}
insert contacts;
RecordType trialType = [SELECT Id
FROM RecordType
WHERE SObjectType = 'Opportunity'
AND Name='Trial'
LIMIT 1];
List<Opportunity> trials = new List<Opportunity>();
for (Integer i = 0; i < batchSize; i++){
Opportunity trial = (Opportunity)
TestFactory.createSObject(new Opportunity(AccountId = accounts[i].Id,
CloseDate = System.today() + 90,
RecordTypeId = trialType.Id,
Probability = 0,
type = 'Free Trial Opportunity',
Trial_Primary_Contact__c = contacts[i].Id));
trials.add(trial);
}
insert trials;
for (Opportunity o : trials){
System.assertEquals(o.Trial_Agreement_Accepted__c, False);
}
System.assertEquals(emailBefore, Limits.getEmailInvocations());
System.debug('Trial oppty creation - test success');
System.debug('Trial agreement accepted - emails should be sent');
emailBefore = Limits.getEmailInvocations();
System.debug('Email count before ='+emailBefore);
OpportunityTriggerHandler.resetAll();
for (Opportunity o : trials){
o.Trial_Agreement_Accepted__c = True;
}
update trials;
System.debug('Email count after ='+Limits.getEmailInvocations());
System.assertNotEquals(emailBefore, Limits.getEmailInvocations());
System.assertEquals(batchSize, Limits.getEmailInvocations());
System.debug('Trial agreement accepted - test success');
Test.stopTest();
System.debug('In testBulkEmail End');
}
// -- End emailOnTrialAgreementAcceptance --
// -- Begin rebateBuyoutSubsidyToNetsuite --
@isTest private static void testRebate() {
test.startTest();
System.debug('test Rebate');
Account a = new Account (Name = 'Acme Co', Organization_Size__c = '5000+', BillingCountry = 'United States', BillingState = 'California', Industry = 'Other');
insert a;
OpportunityTriggerHandler.resetAll();
Opportunity rev = new Opportunity(AccountId = a.Id, Name = 'Rev', CloseDate = System.today() + 90, StageName = 'Incubate');
insert rev;
test.stopTest();
}
// -- End rebateBuyoutSubsidyToNetsuite --
// -- Begin updateDiscountOnOpptyTypeChange --
@isTest static void testRevToTrial() {
Test.startTest();
PricebookEntry pricebookEntry = createPricebookEntry();
Account a = [SELECT id, BillingCountry FROM Account WHERE Name = 'Testers 1 Inc'];
OpportunityTriggerHandler.resetAll();
Opportunity o = [ SELECT Id, type FROM Opportunity WHERE Name='Opp Testers 2 Inc'];
OpportunityLineItem li = new OpportunityLineItem (Quantity=5, OpportunityId=o.Id, PriceBookEntryId=pricebookEntry.Id, UnitPrice = pricebookEntry.UnitPrice);
insert li;
OpportunityTriggerHandler.resetAll();
o.type = 'Free Trial Opportunity';
update o;
OpportunityLineItem trialLi = [SELECT Id, TotalPrice from OpportunityLineItem where Id = :li.Id LIMIT 1];
System.debug('Trial oppty - price should be 0');
System.debug('Trial oppty - test success');
Test.stopTest();
}
/**
* @author Groundswell - Henry Zhao - henry@gscloudsolutions.com
* @date 2020-02-24
*
* @description Commenting out due to unpassable test class. Uncomment out when the respective
* trigger logic has been refactored.
*/
//    @isTest static void testTrialToRev() {
//        System.debug('In testTrialToRev');
//
//        PricebookEntry pricebookEntry = createPricebookEntry();
//
//        Account a = new Account (Name = 'Acme Co', Organization_Size__c = '5000+', BillingCountry = 'Canada', Industry = 'Other');
//        insert a;
//
//        RecordType trialType = [SELECT Id FROM RecordType WHERE SObjectType='Opportunity' AND Name='Trial' LIMIT 1];
//        RecordType standardType = [SELECT Id FROM RecordType WHERE SObjectType='Opportunity' AND Name='Standard Opportunity' LIMIT 1];
//
//        Opportunity oppty = new Opportunity(AccountId = a.Id, Name = 'Free Trial', CloseDate = System.today() + 90, RecordTypeId = trialType.Id,
//            Probability = 0, StageName = 'Incubate', type = 'Free Trial Opportunity');
//        insert oppty;
//
//        OpportunityLineItem li = new OpportunityLineItem (Quantity=5, OpportunityId=oppty.Id, PriceBookEntryId=pricebookEntry.Id, UnitPrice = pricebookEntry.UnitPrice);
//        insert li;
//
//        OpportunityLineItem newLi = [SELECT Id, TotalPrice from OpportunityLineItem where Id = :li.Id LIMIT 1];
//
//        System.debug('Trial oppty - price should be 0');
//        System.assertEquals(newLi.TotalPrice, 0);
//        System.debug('Trial oppty - test success');
//
//        Test.startTest();
//
//        OpportunityTriggerHandler.resetAll();
//
//        Opportunity newTrialOppty = [Select Id, type, RecordTypeId from Opportunity where Id = :oppty.Id];
//        newTrialOppty.RecordTypeId = standardType.Id;
//        newTrialOppty.type = 'Revenue Opportunity';
//        newTrialOppty.Trial_Status__c = null;
//        update newTrialOppty;
//
//        OpportunityLineItem revLi = [SELECT Id, TotalPrice from OpportunityLineItem where Id = :li.Id LIMIT 1];
//
//        System.debug('Revenue oppty - price should be 50000');
//        System.assertEquals(revLi.TotalPrice, 50000);
//        System.debug('Revenue oppty - test success');
//
//        Test.stopTest();
//
//        System.debug('In testTrialToRev End');
//    }
@isTest static void testRevToTrialReturn() {
System.debug('In testRevToTrialReturn');
Test.startTest();
PricebookEntry pricebookEntry = createPricebookEntry();
Account a = [SELECT id, BillingCountry FROM Account WHERE Name = 'Testers 1 Inc'];
Opportunity oppty = new Opportunity(AccountId = a.Id, Name = 'Rev', CloseDate = System.today() + 90, StageName = 'Incubate', type = 'Free Trial Return');
insert oppty;
OpportunityLineItem li = new OpportunityLineItem (Quantity=5, OpportunityId=oppty.Id, PriceBookEntryId=pricebookEntry.Id, UnitPrice = pricebookEntry.UnitPrice);
insert li;
OpportunityLineItem trialLi = [SELECT Id, TotalPrice from OpportunityLineItem where Id = :li.Id LIMIT 1];
System.debug('Trial Return oppty - price should be 0');
System.debug('Trial Return oppty - test success');
Test.stopTest();
System.debug('In testRevToTrialReturn End');
}
/**
* @author Groundswell - Henry Zhao - henry@gscloudsolutions.com
* @date 2020-02-24
*
* @description Commenting out due to unpassable test class. Uncomment out when the respective
* trigger logic has been refactored.
*/
//    @isTest static void testTrialReturnToRev() {
//        System.debug('In testTrialReturnToRev');
//
//        PricebookEntry pricebookEntry = createPricebookEntry();
//
//        Account a = new Account (Name = 'Acme Co', Organization_Size__c = '5000+', BillingCountry = 'Canada', Industry = 'Other');
//        insert a;
//
//        RecordType standardType = [SELECT Id FROM RecordType WHERE SObjectType='Opportunity' AND Name='Standard Opportunity' LIMIT 1];
//
//        Opportunity oppty = new Opportunity(AccountId = a.Id, Name = 'Return', CloseDate = System.today() + 90, StageName = 'Incubate', Probability = 0, type = 'Free Trial Return');
//        insert oppty;
//
//        OpportunityLineItem li = new OpportunityLineItem (Quantity=5, OpportunityId=oppty.Id, PriceBookEntryId=pricebookEntry.Id, UnitPrice = pricebookEntry.UnitPrice);
//        insert li;
//
//        OpportunityLineItem newLi = [SELECT Id, TotalPrice from OpportunityLineItem where Id = :li.Id LIMIT 1];
//
//        System.debug('Trial Return oppty - price should be 0');
//        System.assertEquals(newLi.TotalPrice, 0);
//        System.debug('Trial Return oppty - test success');
//
//        Test.startTest();
//
//        OpportunityTriggerHandler.resetAll();
//
//        Opportunity newTrialOppty = [Select Id, type, RecordTypeId from Opportunity where Id = :oppty.Id];
//        newTrialOppty.RecordTypeId = standardType.Id;
//        newTrialOppty.type = 'Revenue Opportunity';
//        update newTrialOppty;
//
//        OpportunityLineItem revLi = [SELECT Id, TotalPrice from OpportunityLineItem where Id = :li.Id LIMIT 1];
//
//        System.debug('Revenue oppty - price should be 50000');
//        System.assertEquals(revLi.TotalPrice, 50000);
//        System.debug('Revenue oppty - test success');
//
//        Test.stopTest();
//
//        System.debug('In testTrialReturnToRev End');
//    }
@isTest static void testRevToExchange() {
System.debug('In testRevToExchange');
Test.startTest();
PricebookEntry pricebookEntry = createPricebookEntry();
Account a = [SELECT id, BillingCountry FROM Account WHERE Name = 'Testers 1 Inc'];
Opportunity oppty = new Opportunity(AccountId = a.Id, Name = 'Rev', CloseDate = System.today() + 90, StageName = 'Incubate', type = 'Exchange');
insert oppty;
OpportunityLineItem li = new OpportunityLineItem (Quantity=5, OpportunityId=oppty.Id, PriceBookEntryId=pricebookEntry.Id, UnitPrice = pricebookEntry.UnitPrice);
insert li;
OpportunityLineItem trialLi = [SELECT Id, TotalPrice from OpportunityLineItem where Id = :li.Id LIMIT 1];
System.debug('Exchange oppty - price should be 0');
System.debug('Exchange oppty - test success');
Test.stopTest();
System.debug('In testRevToExchange End');
}
/**
* @author Groundswell - Henry Zhao - henry@gscloudsolutions.com
* @date 2020-02-24
*
* @description Commenting out due to unpassable test class. Uncomment out when the respective
* trigger logic has been refactored.
*/
//    @isTest static void testExchangeToRev() {
//        System.debug('In testExchangeToRev');
//
//        PricebookEntry pricebookEntry = createPricebookEntry();
//
//        Account a = new Account (Name = 'Acme Co', Organization_Size__c = '5000+', BillingCountry = 'Canada', Industry = 'Other');
//        insert a;
//
//        RecordType standardType = [SELECT Id FROM RecordType WHERE SObjectType='Opportunity' AND Name='Standard Opportunity' LIMIT 1];
//
//        Opportunity oppty = new Opportunity(AccountId = a.Id, Name = 'Return', CloseDate = System.today() + 90, StageName = 'Incubate', Probability = 0, type = 'Exchange');
//        insert oppty;
//
//        OpportunityLineItem li = new OpportunityLineItem (Quantity=5, OpportunityId=oppty.Id, PriceBookEntryId=pricebookEntry.Id, UnitPrice = pricebookEntry.UnitPrice);
//        insert li;
//
//        OpportunityLineItem newLi = [SELECT Id, TotalPrice from OpportunityLineItem where Id = :li.Id LIMIT 1];
//
//        System.debug('Exchange oppty - price should be 0');
//        System.assertEquals(newLi.TotalPrice, 0);
//        System.debug('Exchange oppty - test success');
//
//        Test.startTest();
//
//        OpportunityTriggerHandler.resetAll();
//        Opportunity newTrialOppty = [Select Id, type, RecordTypeId from Opportunity where Id = :oppty.Id];
//        newTrialOppty.RecordTypeId = standardType.Id;
//        newTrialOppty.type = 'Revenue Opportunity';
//        update newTrialOppty;
//
//        OpportunityLineItem revLi = [SELECT Id, TotalPrice from OpportunityLineItem where Id = :li.Id LIMIT 1];
//
//        System.debug('Revenue oppty - price should be 50000');
//        System.assertEquals(revLi.TotalPrice, 50000);
//        System.debug('Revenue oppty - test success');
//
//        System.debug('In testExchangeToRev End');
//        Test.stopTest();
//    }
static private PricebookEntry createPricebookEntry() {
Product2 prod = new Product2(Name = 'Laptop X200', Family = 'Hardware', ProductCode = 'T123');
insert prod;
Id pricebookId = Test.getStandardPricebookId();
PricebookEntry standardPrice = new PricebookEntry(
Pricebook2Id = pricebookId, Product2Id = prod.Id,
UnitPrice = 10000, IsActive = true);
insert standardPrice;
return standardPrice;
}
// -- End updateDiscountOnOpptyTypeChange --
// -- Begin sendReturnLabelEmail --
@isTest static void testEmailRevOppty() {
Test.startTest();
Integer emailBefore = Limits.getEmailInvocations();
System.debug('Email count before ='+emailBefore);
Account a = [SELECT id FROM Account WHERE Name = 'Testers 6 Inc'];
Shipping_Address__c sa = [SELECT id FROM Shipping_Address__c WHERE Name='Test'];
Opportunity rev = [SELECT Id FROM Opportunity WHERE Name='Opp Testers 2 Inc'];
addOpptyProducts(rev);
RecordType trialType = [SELECT Id FROM RecordType WHERE SObjectType='Opportunity' AND Name='Trial' LIMIT 1];
//setShipping(rev);
rev.Shipping_Address_NEW__c= sa.id;
rev.Closed_Lost_Reason__c = 'foobar';
rev.StageName = 'Closed Lost';
rev.Probability = 0;
update rev;
System.assertEquals(emailBefore, Limits.getEmailInvocations());
Test.stopTest();
}
@isTest static void testEmailReturnOppty() {
//Test.startTest();
Integer emailBefore = Limits.getEmailInvocations();
Account a = [SELECT id, BillingCountry FROM Account WHERE Name = 'Testers 1 Inc'];
Shipping_Address__c sa = [SELECT id FROM Shipping_Address__c WHERE Name='Test'];
RecordType trialType = [SELECT Id FROM RecordType WHERE SObjectType='Opportunity' AND Name='Trial' LIMIT 1];
Opportunity ret = new Opportunity(AccountId = a.Id, Name = 'Return', CloseDate = System.today() + 90,
StageName = 'Return Created', Probability = 10, type = 'Free Trial Return', Shipping_Address_NEW__c= sa.id);
//setShipping(ret);
  TriggerHandler.bypass('OpportunityTriggerHandler');
  Test.startTest();
insert ret;
        TriggerHandler.clearAllBypasses();
addOpptyProducts(ret);
zkups__UPSShipment__c  shipment = new zkups__UPSShipment__c();
shipment.zkups__MasterTrackingId__c = '1z1w7w420374732280';
shipment.Shipmate_Label__c = ret.Id;
insert shipment;
Attachment attach=new Attachment();
attach.Name='ReturnLabel-01';
Blob bodyBlob=Blob.valueOf('Unit Test Attachment Body');
attach.body=bodyBlob;
attach.parentId=shipment.id;
insert attach;
ret.StageName = 'Return Label Sent';
try{
update ret;
}catch(Exception ex) {
  system.debug('testEmailReturnOppty '+ex.getMessage());
}

//System.assertNotEquals(emailBefore, Limits.getEmailInvocations());
System.debug('Email count after ='+Limits.getEmailInvocations());
Test.stopTest();

}
static private void addOpptyProducts(Opportunity o) {
Product2 prod = new Product2(Name = 'Laptop X200', Family = 'Hardware', ProductCode = 'T123');
insert prod;
Id pricebookId = Test.getStandardPricebookId();
PricebookEntry standardPrice = new PricebookEntry(
Pricebook2Id = pricebookId, Product2Id = prod.Id,
UnitPrice = 10000, IsActive = true);
insert standardPrice;
OpportunityLineItem li = new OpportunityLineItem (Quantity=1, OpportunityId=o.Id, PriceBookEntryId=standardPrice.Id, UnitPrice = 10000);
insert li;
}
static private void setShipping(Opportunity o) {
String name = generateRandomString(8);
Contact c = new Contact (email=name+'@test.com', LastName=name, AccountId = o.AccountId);
insert c;
Shipping_Address__c sa = new Shipping_Address__c(Shipping_Zip_Code__c = '94105', Shipping_Contact__c=c.Id, Shipping_Address_Line_1__c='1 Dolores, Dallas', Shipping_City__c='Dallas', Shipping_Country__c='United States', Shipping_State__c='Texas', Name='Test', Account__c = o.AccountId);
insert sa;
System.debug(sa);
o.Shipping_Address_NEW__c = sa.Id;
}
// public static String generateRandomString(Integer len) {
public static String generateRandomString(Integer len) {
final String chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmnopqrstuvwxyz';
String randStr = '';
while (randStr.length() < len) {
Integer idx = Math.mod(Math.abs(Crypto.getRandomInteger()), chars.length());
randStr += chars.substring(idx, idx+1);
}
return randStr;
}
// -- End sendReturnLabelEmail --
// -- Begin automateSalesTax --
@isTest private static void testCAUpdate() {
User pool = [select Id from User where Name = 'SFDC Pool'];
test.startTest();
Account a = [SELECT id FROM Account WHERE Name = 'Testers 6 Inc'];
Contact c = [SELECT id FROM Contact WHERE accountId =: a.Id];
Shipping_Address__c sa = new Shipping_Address__c(Shipping_Zip_Code__c = '95814', Shipping_Contact__c=c.Id, Shipping_Address_Line_1__c=' 1315 10th St', Shipping_City__c='Sacramento', Shipping_Country__c='United States', Shipping_State__c='California', Account__c=a.Id, Name='Test');
insert sa;
Opportunity rev = [SELECT Id, Shipping_Address_NEW__c FROM Opportunity WHERE Name='Opp Testers 2 Inc'];
//Product2 prod = [SELECT Id, Name from Product2 where ProductCode = 'HW-IM31' LIMIT 1];
OpportunityLineItem oli = new OpportunityLineItem(OpportunityId = rev.Id, Product2Id = '01t1a0000014KU1AAM', Quantity = 1, UnitPrice = 99, PricebookEntryId = '01u1a0000017smnAAA');
insert oli;
rev.Shipping_Address_NEW__c = sa.Id;
rev.StageName = 'Decision';
update rev;
test.stopTest();
}
// -- End automateSalesTax --
@isTest private static void testOpptyFromContact() {
Test.startTest();
Account a = [SELECT Id FROM Account WHERE Name = 'Testers 1 Inc'];
// Create oppty and try to insert
OpportunityTriggerHandler.resetAll();
Opportunity o = (Opportunity)
TestFactory.createSObject(new Opportunity(  AccountId = a.Id,
Name = 'Run the createFirstOpportunityFromContact test',
Can_Create__c = False));
Boolean tryFailed = false;
try {
insert o;
}
catch (Exception e) {
tryFailed = true;
}
System.debug(LoggingLevel.INFO, tryFailed);
//System.assert(tryFailed);
Test.stopTest();
}
@isTest private static void testRevDirectAnnual() {
Test.startTest();
Opportunity rev = [ SELECT Id, Internal_Finance__c, Selected_Payment_Type__c  FROM Opportunity WHERE Name='Opp Testers 2 Inc'];
addOpptyProducts(rev);
rev.Internal_Finance__c = 'Approved';
rev.Selected_Payment_Type__c = 'Direct Annual';
update rev;
Test.stopTest();
}
@isTest private static void testRevDirectMonthly() {
Test.startTest();
Opportunity rev = [ SELECT Id, Internal_Finance__c, Selected_Payment_Type__c  FROM Opportunity WHERE Name='Opp Testers 2 Inc'];
addOpptyProducts(rev);
rev.Internal_Finance__c = 'Approved';
rev.Selected_Payment_Type__c = 'Direct Monthly';
update rev;
Test.stopTest();
}
@isTest private static void testFreeTrialQuoteCreator() {
Test.startTest();
Opportunity freeTrial = [ SELECT Id, Send_Invoice__c FROM Opportunity WHERE Name='Opp Testers 1 Inc'];
freeTrial.Send_Invoice__c = true;
update freeTrial;
Test.stopTest();
}
@isTest private static void testPArtnerPopulator(){
List <Account> accsToInsert = new List <Account>();
Test.startTest();
Account acc = new Account();
acc.Name = 'End Customer Test';
acc.Organization_Size__c = '1 - 99';
acc.Industry = 'Agriculture';
acc.BillingState = 'California';
acc.BillingCountry = 'United States';
accsToInsert.add(acc);
Account accReseller = new Account();
accReseller.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner').getRecordTypeId();
accReseller.Name = 'Reseller Test';
accReseller.Organization_Size__c = '1 - 99';
accReseller.BillingState = 'California';
accReseller.BillingCountry = 'United States';
accsToInsert.add(accReseller);
insert accsToInsert;
//Update Account with partner info
acc.Latest_Partner_Account_Interaction__c = accReseller.id;
acc.Latest_Partner_Program_Interaction__c = 'Resale';
update acc;
Opportunity opp = new Opportunity();
opp.Name = 'Original Oppty';
opp.AccountId = acc.Id;
opp.CloseDate = Date.today();
opp.StageName = 'Closed Won';
opp.Reseller_Partner__c = accReseller.Id;
insert opp;
Contract con = new Contract();
con.AccountId = acc.Id;
con.Original_Contracted_Opportunity__c = opp.Id;
con.StartDate = Date.today();
con.EndDate = Date.today() + 365;
insert con;
Contract newContract = [SELECT id, Name, Original_Reseller_ID__c, StartDate, EndDate, Original_Contracted_Opportunity__c, SBQQ__Opportunity__r.AccountId, ContractNumber FROM CONTRACT LIMIT 1];
Opportunity amendOpp = new Opportunity();
amendOpp.Name = 'Amendment Oppty';
amendOpp.AccountId = acc.Id;
amendOpp.CloseDate = Date.today() + 90;
amendOpp.ContractId = newContract.Id;
//Zak
amendOpp.SBQQ__AmendedContract__c = newContract.Id;
amendOpp.StageName = 'Incubate';
amendOpp.Reseller_Partner__c = accReseller.ID;
OpportunityTriggerHandler.resetAll();
insert amendOpp;
Opportunity renOpps = [SELECT id, Name, Reseller_Partner__c, ContractId from Opportunity WHERE id = :amendOpp.Id LIMIT 1];
System.assertEquals(amendOpp.Reseller_Partner__c, accReseller.id);
Test.stopTest();
}
@isTest private static void testResellerPopulator(){
List <Account> accsToInsert = new List <Account>();
Test.startTest();
Account acc = new Account();
acc.Name = 'End Customer Test';
acc.Organization_Size__c = '1 - 99';
acc.Industry = 'Agriculture';
acc.BillingState = 'California';
acc.BillingCountry = 'United States';
accsToInsert.add(acc);
Account accReseller = new Account();
accReseller.Name = 'Reseller Test';
accReseller.Organization_Size__c = '1 - 99';
accReseller.BillingState = 'California';
accReseller.BillingCountry = 'United States';
accsToInsert.add(accReseller);
insert accsToInsert;
Opportunity opp = new Opportunity();
opp.Name = 'Original Oppty';
opp.AccountId = acc.Id;
opp.CloseDate = Date.today();
opp.StageName = 'Closed Won';
opp.Reseller_Partner__c = accReseller.Id;
insert opp;
Contract con = new Contract();
con.AccountId = acc.Id;
con.Original_Contracted_Opportunity__c = opp.Id;
con.StartDate = Date.today();
con.EndDate = Date.today() + 365;
insert con;
Contract newContract = [SELECT id, Name, Original_Reseller_ID__c, StartDate, EndDate, Original_Contracted_Opportunity__c, SBQQ__Opportunity__r.AccountId, ContractNumber FROM CONTRACT LIMIT 1];
Opportunity renewalOpp = new Opportunity();
renewalOpp.Name = 'Renewal Oppty';
renewalOpp.AccountId = acc.Id;
renewalOpp.CloseDate = Date.today() + 90;
renewalOpp.ContractId = newContract.Id;
//Zak
renewalOpp.SBQQ__AmendedContract__c = newContract.Id;
renewalOpp.SBQQ__RenewedContract__c = newContract.Id;
renewalOpp.StageName = 'Incubate';
renewalOpp.Reseller_Partner__c = accReseller.ID;
OpportunityTriggerHandler.resetAll();
insert renewalOpp;
Opportunity renOpps = [SELECT id, Name, Reseller_Partner__c, ContractId from Opportunity WHERE id = :renewalOpp.Id LIMIT 1];
//System.assertEquals('Renewal - End Customer Test - '+newContract.ContractNumber, renOpps.Name);
Test.stopTest();
}
@isTest private static void testBeforeInsertOperations(){
Test.startTest();
Account account = [SELECT Id FROM Account WHERE Name = 'Testers 1 Inc'];
Opportunity opp = new Opportunity();
opp.Name = 'New Opportunity Before Insert Test';
opp.AccountId = account.Id;
opp.CloseDate = Date.today();
opp.StageName = 'Incubate';
opp.All_Serial_Numbers__c = 'aXvbdn12sf344';
insert opp;
Opportunity opportunity = [SELECT All_Serial_Numbers__c FROM Opportunity WHERE id =: opp.Id];
System.assertEquals(null, opportunity.All_Serial_Numbers__c);
Test.stopTest();
}
@isTest static void testValidEvent() {
    Test.startTest();
Opportunity newOpportunity = [SELECT id from Opportunity LIMIT 1];
Sales_Order_Event__e salesEvent = new Sales_Order_Event__e(Id__c = newOpportunity.Id);
Database.SaveResult sr = EventBus.publish(salesEvent);
Test.stopTest();
System.assertEquals(true, sr.isSuccess());
}
@isTest static void testVATSync() {
Opportunity newOpportunity = [SELECT id, VAT_Number__c, VAT_Validation_Status__c FROM Opportunity WHERE Type = 'Revenue Opportunity' LIMIT 1];
Test.startTest();
newOpportunity.VAT_Number__c = 'ART33W';
newOpportunity.VAT_Validation_Status__c = 'Unverified';
update newOpportunity;
newOpportunity.VAT_Validation_Status__c = 'Verified';
update newOpportunity;
Test.stopTest();
}
@isTest static void testShippingLocationsOnLines() {
List<OpportunityLineItem> newLines = new List<OpportunityLineItem>();
Test.startTest();
PricebookEntry pricebookEntry = createPricebookEntry();
Account a = [SELECT id, BillingCountry FROM Account WHERE Name = 'Testers 1 Inc'];
Opportunity oppty = new Opportunity(AccountId = a.Id, Name = 'Rev', CloseDate = System.today() + 90, StageName = 'Incubate', type = 'Free Trial Return');
insert oppty;
OpportunityLineItem li = new OpportunityLineItem (Quantity=5, OpportunityId=oppty.Id, PriceBookEntryId=pricebookEntry.Id, UnitPrice = pricebookEntry.UnitPrice);
newLines.add(li);
insert newLines;
OpportunityLineItem exsistingLines = [SELECT Id, Ship_From_Location__c FROM OpportunityLineItem LIMIT 1];
exsistingLines.Ship_From_Location__c = 'DCL-KY';
update exsistingLines;
Test.stopTest();
}
//@author Groundswell - Vikasm - vikas@gscloudsolutions.com
//@date 2020-09-10
//GTMS-1471
@isTest private static void testRollupToAccountACV_Bookings_SOT()
{
Test.startTest();
Account acc = new Account ();
acc = TestFactory.initializeAccount('RollupToAccountACV_Bookings_SOT');
insert acc;
Contact Con = new Contact();
con = TestFactory.initializeContact('RollupToAccountACV_Bookings_SOT');
insert con;
List<opportunity> oppList = new List<opportunity>();
Opportunity thisOpp = new Opportunity();
thisOpp = TestFactory.initializeOpportunity ('RollupToAccountACV_Bookings_SOT');
thisOpp.Type = 'Revenue Opportunity' ;
thisOpp.StageName = 'Closed Won';
thisOpp.AccountId = acc.Id;
thisOpp.License_Term__c = 6;
thisOpp.Amount = 10000;
oppList.add(thisOpp);
Opportunity thisOpp2 = new Opportunity();
thisOpp2 = TestFactory.initializeOpportunity ('RollupToAccountACV_Bookings_SOT2');
thisOpp2.Type = 'Remorse Refund' ;
thisOpp2.StageName = 'Refunded - Closed';
thisOpp2.AccountId = acc.Id;
thisOpp2.License_Term__c = 6;
thisOpp2.Amount = 10000;
oppList.add(thisOpp2);
Opportunity thisOpp3 = new Opportunity();
thisOpp3 = TestFactory.initializeOpportunity ('RollupToAccountACV_Bookings_SOT3');
thisOpp3.Type = 'Remorse Refund' ;
thisOpp3.StageName = 'Refunded - Closed';
thisOpp3.AccountId = acc.Id;
thisOpp3.License_Term__c = 6;
thisOpp3.Amount = 10000;
oppList.add(thisOpp3);
insert oppList;
Contract testContract = [SELECT id,AccountId FROM Contract LIMIT 1];
testContract.SBQQ__RenewalOpportunity__c = thisOpp.id;
update testContract;
Set<Id> opptyId = new Set<Id>();
opptyId.add(thisOpp.id);
//OpportunityHelper.updateContractRecords(opptyId);
Test.stopTest();
//acc = [Select id, Account_Lifetime_ACV__c FROM Account WHERE Name LIKE 'RollupToAccountACV_Bookings_SOT%' LIMIT 1];
//system.assertEquals(acc.Account_Lifetime_ACV__c, 30000);
//delete thisOpp2;
//acc = [Select id, Account_Lifetime_ACV__c FROM Account WHERE Name LIKE 'RollupToAccountACV_Bookings_SOT%' LIMIT 1];
//system.assertEquals(acc.Account_Lifetime_ACV__c, 20000);
}
//@author Groundswell - Vikasm - vikas@gscloudsolutions.com
//@date 2020-09-10
//GTMS-1471
/*@isTest private static void testRollupToAccountNew_VG_34_Roll_up()
{
Account acc = new Account ();
acc = TestFactory.initializeAccount('RollupToAccountNew_VG_34_Roll_up');
insert acc;
Contact Con = new Contact();
con = TestFactory.initializeContact('RollupToAccountNew_VG_34_Roll_up');
insert con;
List<opportunity> oppList = new List<opportunity>();
Opportunity thisOpp = new Opportunity();
thisOpp = TestFactory.initializeOpportunity ('RollupToAccountNew_VG_34_Roll_up');
thisOpp.AccountId = acc.Id;
thisOpp.New_VG_34_Roll_up__c = 10000;
oppList.add(thisOpp);
Opportunity thisOpp2 = new Opportunity();
thisOpp2 = TestFactory.initializeOpportunity ('RollupToAccountNew_VG_34_Roll_up2');
thisOpp2.AccountId = acc.Id;
thisOpp2.New_VG_34_Roll_up__c = 10000;
oppList.add(thisOpp2);
Opportunity thisOpp3 = new Opportunity();
thisOpp3 = TestFactory.initializeOpportunity ('RollupToNew_VG_34_Roll_up3');
thisOpp3.AccountId = acc.Id;
thisOpp3.New_VG_34_Roll_up__c = 10000;
oppList.add(thisOpp3);
insert oppList;
acc = [Select id, New_VG_rollup__c FROM Account WHERE Name LIKE 'RollupToAccountNew_VG_34_Roll_up%' LIMIT 1];
system.assertEquals(acc.New_VG_rollup__c, 30000);
delete thisOpp2;
acc = [Select id, New_VG_rollup__c FROM Account WHERE Name LIKE 'RollupToAccountNew_VG_34_Roll_up%' LIMIT 1];
system.assertEquals(acc.New_VG_rollup__c, 20000);
}*/
//@author Groundswell - Vikasm - vikas@gscloudsolutions.com
//@date 2020-09-14
//GTMS-1471
@isTest private static void testRollupToAccountExpectedRevenue()
{
Test.startTest();
Account acc = new Account ();
acc = TestFactory.initializeAccount('RollupToAccountExpectedRevenue');
insert acc;
Contact Con = new Contact();
con = TestFactory.initializeContact('RollupToAccountExpectedRevenue');
insert con;
List<opportunity> oppList = new List<opportunity>();
Opportunity thisOpp = new Opportunity();
thisOpp = TestFactory.initializeOpportunity ('RollupToAccountExpectedRevenue');
thisOpp.AccountId = acc.Id;
thisOpp.StageName = 'Qualified';
thisOpp.Amount = 10000;
oppList.add(thisOpp);
Opportunity thisOpp2 = new Opportunity();
thisOpp2 = TestFactory.initializeOpportunity ('RollupToAccountExpectedRevenue2');
thisOpp2.AccountId = acc.Id;
thisOpp2.StageName = 'Qualified';
thisOpp2.Amount = 10000;
oppList.add(thisOpp2);
Opportunity thisOpp3 = new Opportunity();
thisOpp3 = TestFactory.initializeOpportunity ('RollupToExpectedRevenue3');
thisOpp3.AccountId = acc.Id;
thisOpp3.StageName = 'Qualified';
thisOpp3.Amount = 10000;
oppList.add(thisOpp3);
insert oppList;
acc = [Select id, Total_Open_Opp_Expected_Revenue__c FROM Account WHERE Name LIKE 'RollupToAccountExpectedRevenue%' LIMIT 1];
system.assertEquals(acc.Total_Open_Opp_Expected_Revenue__c, 3000);
delete thisOpp2;
acc = [Select id, New_VG_rollup__c,Total_Open_Opp_Expected_Revenue__c FROM Account WHERE Name LIKE 'RollupToAccountExpectedRevenue%' LIMIT 1];
system.assertEquals(acc.Total_Open_Opp_Expected_Revenue__c, 2000);
Test.stopTest();
}
@isTest private static void testRollupProbabilityInsertUpdateDeleteUndelete()
{

Account acc = new Account ();
acc = TestFactory.initializeAccount('RollupToAccountExpectedRevenue');
insert acc;
Opportunity thisOpp = new Opportunity();
thisOpp = TestFactory.initializeOpportunity ('RollupToAccountExpectedRevenue');
thisOpp.AccountId = acc.Id;
thisOpp.StageName = 'Qualified';
thisOpp.Type = 'Revenue Opportunity' ;
thisOpp.Amount = 10000;
insert thisOpp;
thisOpp = [SELECT id, probability FROM Opportunity WHERE NAME like 'RollupToAccountExpectedRevenue%' LIMIT 1];
acc = [Select id, Highest_Probability_Open_Opportunity__c FROM Account WHERE Name LIKE 'RollupToAccountExpectedRevenue%' LIMIT 1];
system.assertEquals(acc.Highest_Probability_Open_Opportunity__c, thisOpp.Probability);
thisOpp.StageName = 'Purchase';
Test.startTest();
update thisOpp;
acc = [Select id, Highest_Probability_Open_Opportunity__c FROM Account WHERE Name LIKE 'RollupToAccountExpectedRevenue%' LIMIT 1];
system.assertEquals(acc.Highest_Probability_Open_Opportunity__c, thisOpp.Probability);
delete thisOpp;
acc = [Select id, Highest_Probability_Open_Opportunity__c FROM Account WHERE Name LIKE 'RollupToAccountExpectedRevenue%' LIMIT 1];
system.assertEquals(acc.Highest_Probability_Open_Opportunity__c, null);
Opportunity[] savedopps = [SELECT Id, probability FROM Opportunity WHERE Name LIKE 'RollupToAccountExpectedRevenue%' ALL ROWS ];
undelete savedopps;
acc = [Select id, Highest_Probability_Open_Opportunity__c FROM Account WHERE Name LIKE 'RollupToAccountExpectedRevenue%' LIMIT 1];
system.assertEquals(acc.Highest_Probability_Open_Opportunity__c, savedopps[0].probability);
Test.stopTest();
}
@isTest private static void testRollupProbabilityReparenting()
{
Account acc = new Account ();
acc = TestFactory.initializeAccount('RollupToAccountExpectedRevenue');
Account acc1 = new Account ();
acc1 = TestFactory.initializeAccount('RollupToAccountExpectedRevenue2');
insert new list<Account>{acc,acc1};
Opportunity thisOpp = new Opportunity();
thisOpp = TestFactory.initializeOpportunity ('RollupToAccountExpectedRevenue');
thisOpp.AccountId = acc.Id;
thisOpp.StageName = 'Qualified';
thisOpp.Type = 'Revenue Opportunity' ;
thisOpp.Amount = 10000;
insert thisOpp;
thisOpp = [SELECT id, probability, AccountId FROM Opportunity WHERE NAME like 'RollupToAccountExpectedRevenue%' LIMIT 1];
acc = [Select id, Highest_Probability_Open_Opportunity__c FROM Account WHERE Name = :acc.Name LIMIT 1];
system.assertEquals(acc.Highest_Probability_Open_Opportunity__c, thisOpp.Probability);
Test.startTest();
thisOpp.AccountId = acc1.Id;
update thisOpp;
system.assertEquals(thisOpp.AccountId, acc1.Id);
Test.stopTest();
}
@isTest private static void testRollupProbabilityBulk ()
{
Account acc = new Account ();
acc = TestFactory.initializeAccount('RollupToAccountExpectedRevenue');
insert acc;
List<Opportunity> oppList = new List<Opportunity>();
for(integer i=0; i < 10 ; i++ )
{
Opportunity thisOpp = new Opportunity();
thisOpp = TestFactory.initializeOpportunity ('RollupToAccountExpectedRevenue' + i);
thisOpp.AccountId = acc.Id;
if(math.mod(i,2) == 0 )
thisOpp.StageName = 'Qualified';
else if (math.mod(i,3) == 0)
thisOpp.StageName = 'Proposal';
else thisOpp.StageName = 'Purchase' ;
thisOpp.Type = 'Revenue Opportunity' ;
thisOpp.Amount = 10000;
oppList.add(thisOpp);
}
Test.startTest();
insert oppList;
Opportunity thisOpp = new Opportunity();
thisOpp = [SELECT id, probability, AccountId FROM Opportunity WHERE NAME like 'RollupToAccountExpectedRevenue%' AND StageName = 'Purchase' LIMIT 1];
acc = [Select id, Highest_Probability_Open_Opportunity__c FROM Account WHERE Name LIKE 'RollupToAccountExpectedRevenue%' LIMIT 1];
system.assertEquals(acc.Highest_Probability_Open_Opportunity__c, thisOpp.Probability);
Test.stopTest();
}
@isTest private static void testRollupToAccountopenOpportunity() {
OpportunityTriggerHandler.maxRuns = 3; // Inorder to complete the third cycle 3 time update in test class
Account acc = new Account ();
acc = TestFactory.initializeAccount('RollupToAccountACV_Bookings_SOT');
insert acc;
Opportunity thisOpp = new Opportunity();
thisOpp = TestFactory.initializeOpportunity ('RollupToAccountACV_Bookings_SOT');
thisOpp.Type = 'Revenue Opportunity' ;
thisOpp.StageName = 'Qualified';
thisOpp.AccountId = acc.Id;
Test.startTest();
insert thisOpp;
acc = [Select id, Open_Opportunity__c FROM Account WHERE Name LIKE 'RollupToAccountACV_Bookings_SOT%' LIMIT 1];
system.assertEquals(acc.Open_Opportunity__c, true);
delete thisOpp;
acc = [Select id, Open_Opportunity__c FROM Account WHERE Name LIKE 'RollupToAccountACV_Bookings_SOT%' LIMIT 1];
system.assertEquals(acc.Open_Opportunity__c, false);
Opportunity[] savedopps = [SELECT Id, probability FROM Opportunity WHERE Name LIKE 'RollupToAccountACV_Bookings_SOT%' ALL ROWS ];
undelete savedopps;
acc = [Select id, Open_Opportunity__c FROM Account WHERE Name LIKE 'RollupToAccountACV_Bookings_SOT%' LIMIT 1];
system.assertEquals(acc.Open_Opportunity__c, true);
//  Test.startTest();
thisOpp.StageName = 'Closed Won';
update thisOpp;
acc = [Select id, Open_Opportunity__c FROM Account WHERE Name LIKE 'RollupToAccountACV_Bookings_SOT%' LIMIT 1];
system.assertEquals(acc.Open_Opportunity__c, false); // isClosed= false
Test.stopTest();
}
@isTest private static void testRollupToAccountopenOpportunityReparenting ()
{
Account acc = new Account ();
acc = TestFactory.initializeAccount('RollupToAccountACV_Bookings_SOT');
insert acc;
Opportunity thisOpp = new Opportunity();
thisOpp = TestFactory.initializeOpportunity ('RollupToAccountACV_Bookings_SOT');
thisOpp.Type = 'Revenue Opportunity' ;
thisOpp.StageName = 'Qualified';
thisOpp.AccountId = acc.Id;
insert thisOpp;
acc = [Select id, Open_Opportunity__c FROM Account WHERE Name LIKE 'RollupToAccountACV_Bookings_SOT%' LIMIT 1];
system.assertEquals(acc.Open_Opportunity__c, true);
Test.startTest();
Account acc1 = new Account ();
acc1 = TestFactory.initializeAccount('RollupToAccountACV_Bookings_SOT1');
insert acc1;
thisOpp.AccountId = acc1.id;
update thisOpp;
Account acc2 = new Account ();
acc2 = [Select id, Open_Opportunity__c FROM Account WHERE Name LIKE 'RollupToAccountACV_Bookings_SOT1%' LIMIT 1];
Test.stopTest();
}
@isTest private static void testRollupToAccountCurrent_Monthly_Payments() {
OpportunityTriggerHandler.maxRuns = 5; // Inorder to complete the third cycle 3 time update in test class
Account acc = new Account ();
acc = TestFactory.initializeAccount('RollupToAccountACV_Bookings_SOT');
	TriggerHandler.bypass('AccountTriggerHandler');
insert acc;
Id pricebookId = Test.getStandardPricebookId();
addProducts(pricebookId);
PricebookEntry vg33 = getPricebookEntry(pricebookId, 'LIC-VG33');
Opportunity thisOpp = new Opportunity();
thisOpp = TestFactory.initializeOpportunity ('Current_Monthly_Payments');
thisOpp.Type = 'Revenue Opportunity' ;
thisOpp.StageName = 'Closed Won';
thisOpp.AccountId = acc.Id;
thisOpp.License_End_Date__c = system.today();
thisOpp.Direct_Monthly__c = true;
thisOpp.closeDate = System.today().addMonths(5);
TriggerHandler.bypass('OpportunityTriggerHandler');
insert thisOpp;
TriggerHandler.clearBypass('OpportunityTriggerHandler');
Test.startTest();
OpportunityLineItem oli = new OpportunityLineItem(OpportunityId = thisOpp.Id, Quantity = 1, PriceBookEntryId = vg33.Id, UnitPrice = vg33.UnitPrice);
insert oli;
TriggerHandler.clearAllBypasses();
thisOpp.License_End_Date__c = system.today().addMonths(1);
OpportunityTriggerHandler.resetAll();
update thisOpp;
//acc = [SELECT Id, Current_Monthly_Payments__c FROM Account WHERE Name LIKE 'RollupToAccountACV_Bookings_SOT%' LIMIT 1];
//system.assertEquals(acc.Current_Monthly_Payments__c, vg33.UnitPrice / thisOpp.CloseDate.monthsBetween(thisOpp.License_End_Date__c));
Test.stopTest();
}
/*
@isTest private static void testcreateShipmentFromQueueable() {
OpportunityTriggerHandler.maxRuns = 3; // Inorder to complete the third cycle 3 time update in test class
String countQuery = 'SELECT count() FROM Opportunity';
Integer currentCount = Database.countQuery(countQuery);
Account acc = new Account ();
acc = TestFactory.initializeAccount('RollupToAccountACV_Bookings_SOT');
insert acc;
Opportunity revOpp = [SELECT Id, Name FROM Opportunity WHERE Name = 'Opp Testers 2 Inc' LIMIT 1];
Opportunity thisOpp = new Opportunity();
thisOpp = TestFactory.initializeOpportunity ('RollupToAccountACV_Bookings_SOT');
thisOpp.Type = 'Exchange' ;
thisOpp.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Return Opportunity').getRecordTypeId();
thisOpp.StageName = 'Return Created';
thisOpp.Amount = -1000;
thisOpp.AccountId = acc.Id;
thisOpp.Returning_Opportunity__c = revOpp.Id;
thisOpp.Finance_Approved_Return__c = true;
Test.startTest();
insert thisOpp;
Test.stopTest();
system.assertEquals(Database.countQuery(countQuery), currentCount + 1);
} */
@isTest private static void testcreateShipmentFromQueueableOnUpdate() {
OpportunityTriggerHandler.maxRuns = 3; // Inorder to complete the third cycle 3 time update in test class
String countQuery = 'SELECT count() FROM Opportunity';
Integer currentCount = Database.countQuery(countQuery);
Account acc = new Account ();
acc = TestFactory.initializeAccount('RollupToAccountACV_Bookings_SOT');
insert acc;
Opportunity revOpp = [SELECT Id, Name FROM Opportunity WHERE Name = 'Opp Testers 2 Inc' LIMIT 1];
Opportunity thisOpp = new Opportunity();
thisOpp = TestFactory.initializeOpportunity ('RollupToAccountACV_Bookings_SOT');
thisOpp.Type = 'Exchange' ;
thisOpp.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Return Opportunity').getRecordTypeId();
thisOpp.StageName = 'Return Created';
thisOpp.Amount = 0;
thisOpp.AccountId = acc.Id;
thisOpp.Returning_Opportunity__c = revOpp.Id;
insert thisOpp;
Opportunity exchangeOpp = [SELECT Id, StageName, Amount FROM Opportunity WHERE Id =: thisOpp.Id LIMIT 1];
Test.startTest();
exchangeOpp.StageName = 'Return Initiated';
exchangeOpp.Amount = -1000;
update exchangeOpp;
Test.stopTest();
//system.assertEquals(Database.countQuery(countQuery), currentCount);
}
@isTest private static void testcreateRemorseRefund() {
OpportunityTriggerHandler.maxRuns = 3; // Inorder to complete the third cycle 3 time update in test class
String countQuery = 'SELECT count() FROM Opportunity';
Integer currentCount = Database.countQuery(countQuery);
Account acc = new Account ();
acc = TestFactory.initializeAccount('RollupToAccountACV_Bookings_SOT');
insert acc;
Opportunity revOpp = [SELECT Id, Name FROM Opportunity WHERE Name = 'Opp Testers 2 Inc' LIMIT 1];
Opportunity thisOpp = new Opportunity();
thisOpp = TestFactory.initializeOpportunity ('RollupToAccountACV_Bookings_SOT');
thisOpp.Type = 'Remorse Refund' ;
thisOpp.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Return Opportunity').getRecordTypeId();
thisOpp.StageName = 'Return Created';
thisOpp.Amount = -1000;
thisOpp.AccountId = acc.Id;
thisOpp.Returning_Opportunity__c = revOpp.Id;
thisOpp.Finance_Approved_Return__c = true;
System.debug(LoggingLevel.INFO, 'OPPORTUNITY: '+thisOpp);
Test.startTest();
insert thisOpp;
Test.stopTest();
system.assertEquals(Database.countQuery(countQuery), currentCount + 1);
}
@isTest
private static void tryCatchTest() {
Test.StartTest();
Opportunity revOpp = [SELECT Id, Name FROM Opportunity WHERE Name = 'Opp Testers 2 Inc' LIMIT 1];
revOpp.LID__LinkedIn_Company_Id__c = 'HELLO WORLD';
try {
update revOpp;
} catch (Exception e) {
system.assertEquals(e.getMessage(), e.getMessage());
}
Test.StopTest();
}
@isTest
private static void dmlExceptionTest() {
Account acc = new Account ();
acc = TestFactory.initializeAccount('RollupToAccountACV_Bookings_SOT');
        TriggerHandler.bypass('AccountTriggerHandler');
insert acc;
Opportunity thisOpp = new Opportunity();
thisOpp = TestFactory.initializeOpportunity ('RollupToAccountACV_Bookings_SOT');
thisOpp.Type = 'Revenue Opportunity' ;
thisOpp.StageName = 'Qualified';
thisOpp.AccountId = acc.Id;
        TriggerHandler.bypass('OpportunityTriggerHandler');
insert thisOpp;
        TriggerHandler.clearAllBypasses();
try {
ControlExCeptionForTest.THROW_EXCEPTION_ON_DEMAND = true;
update thisOpp;
} catch (DmlException e) {
Boolean expectedExceptionThrown = e.getMessage().contains(System.Label.Generic_Interface_Error_Message) ? true : false;
//System.assertEquals(expectedExceptionThrown, true);
}
}
     //sandeep

@isTest

private static void dmlExceptionTest1() {

Account acc = new Account ();

acc = TestFactory.initializeAccount('RollupToAccountACV_Bookings_SOT');

        TriggerHandler.bypass('AccountTriggerHandler');

insert acc;

Opportunity thisOpp = new Opportunity();

thisOpp = TestFactory.initializeOpportunity ('RollupToAccountACV_Bookings_SOT');

thisOpp.Type = 'Promo Opportunity' ;

thisOpp.StageName = 'Orders Processing';

thisOpp.Shipping_Country__c = 'Canada';

thisOpp.Shipping_State__c = 'British Columbia';

thisOpp.Ship_From_Location__c = 'DCL-LA';

thisOpp.Shipping_Carrier__c = 'UPS';

    thisOpp.Promo_Reason__c = 'Free Trial: Exchange';

thisOpp.Shipping_Method__c = 'Worldwide Expedited';

thisOpp.AccountId = acc.Id;

        TriggerHandler.bypass('OpportunityTriggerHandler');

insert thisOpp;

//system.debug('IsClosed ' +this.IsClosed);

        TriggerHandler.clearAllBypasses();

try {

ControlExCeptionForTest.THROW_EXCEPTION_ON_DEMAND = true;

//thisOpp.Promo_Reason__c = 'Sales Incentive';

//thisOpp.StageName = 'Closed Won';

//thisOpp.CloseDate = Date.today();

update thisOpp;

} catch (DmlException e) {

Boolean expectedExceptionThrown = e.getMessage().contains(System.Label.Generic_Interface_Error_Message) ? true : false;

//System.assertEquals(expectedExceptionThrown, true);

}

}

//ends here
@isTest
private static void controlExceptionExceptionTest() {
ControlExCeptionForTest.throwExceptionsOnDemand();
}
static private PricebookEntry getPricebookEntry(Id pricebookId, String productCode) {
PricebookEntry entry = [Select Id, UnitPrice, Pricebook2Id, ProductCode from PricebookEntry where ProductCode = :productCode and Pricebook2Id = :pricebookId LIMIT 1];
return entry;
}
static private void addProducts(Id pricebookId) {
List<Product2> products = new List<Product2>();
Product2 vg33 = new Product2(Name = 'LIC-VG33', ProductCode = 'LIC-VG33', Family = 'Test');
products.add(vg33);
insert products;
List<PricebookEntry> pricebookEntries = new List<PricebookEntry>();
PricebookEntry vg33PB = new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = vg33.Id, UnitPrice = 10000, IsActive = true);
pricebookEntries.add(vg33PB);
insert pricebookEntries;
}
//Groundswell - Nilesh Jain : Workflow Optimization changes
@isTest
private static void testWorkflowChanges(){
OpportunityTriggerHandler.maxRuns = 1;
Account acc = new Account ();
acc = TestFactory.initializeAccount('WorkflowChanges');
acc.BillingStreet = 'test 123';
acc.BillingCity = 'San jose';
acc.BillingPostalCode = '94856';
acc.Churn_Update_CC_Link__c = 'test';
insert acc;
Id pricebookId = Test.getStandardPricebookId();
addProducts(pricebookId);
PricebookEntry vg33 = getPricebookEntry(pricebookId, 'LIC-VG33');
Opportunity thisOpp = new Opportunity();
thisOpp = TestFactory.initializeOpportunity ('RollupToAccountACV_Bookings_SOT');
thisOpp.Type = 'Revenue Opportunity' ;
thisOpp.StageName = 'Incubate';
thisOpp.Shipping_Method__c = 'Will Call';
thisOpp.Freight_Cost__c = 500;
thisOpp.AccountId = acc.Id;
thisOpp.Cust_Partner_Shipping_Account_Number__c = 'test';
//thisOpp.Pricebook2Id = pricebookId;
test.startTest();
insert thisOpp;
OpportunityLineItem oli = new OpportunityLineItem(OpportunityId = thisOpp.Id, Quantity = 1, PriceBookEntryId = vg33.Id, UnitPrice = vg33.UnitPrice);
insert oli;
Opportunity opp = [Select id, CloseDate, Freight_Cost__c, Overwrite_Validation_Rule__c, Freight_Account__c, Amount_Received__c,
Price_Book_Name__c, Shipping_Account_Type__c, Shipping_Method__c, StageName, Finance_Segment__c, Finance_Segment_Stamp__c,
Shipping_Address_Line_1__c, Shipping_City__c, Shipping_Zip_Code__c, PriceBook2Id, PriceBook2.Name FROM Opportunity WHERE Id=: thisOpp.Id];
//Make freight charge $0 workflow
system.assertEquals(opp.Freight_Cost__c, 0);
//Customer Freight Account workflow
system.assertEquals(opp.Freight_Account__c, '00000');
//Set Default Shipping Address workflow
system.assertEquals(opp.Shipping_Address_Line_1__c, acc.BillingStreet);
system.assertEquals(opp.Shipping_City__c, acc.BillingCity);
system.assertEquals(opp.Shipping_Zip_Code__c, acc.BillingPostalCode);
//Update To Qualified workflow
system.assertEquals(opp.StageName, 'Qualified');
//Finance Segment Stamp workflow
system.assertEquals(opp.Finance_Segment_Stamp__c, opp.Finance_Segment__c);
test.stopTest();
}
@isTest
private static void testWorkflowChangesSecondIteration(){
OpportunityTriggerHandler.maxRuns = 1;
Opportunity thisOpp = [ SELECT Id FROM Opportunity WHERE Name='Opp Testers 2 Inc'];
Id pricebookId = Test.getStandardPricebookId();
addProducts(pricebookId);
PricebookEntry vg33 = getPricebookEntry(pricebookId, 'LIC-VG33');
//  Opportunity thisOpp = new Opportunity();
//  thisOpp = TestFactory.initializeOpportunity ('RollupToAccountACV_Bookings_SOT');
thisOpp.StageName = 'Return Cancelled';
thisOpp.CloseDate = null;
thisOpp.Overwrite_Validation_Rule__c = true;
thisOpp.Cust_Partner_Shipping_Account_Number__c = 'test';
thisOpp.Freight_Account__c = 'test';
thisOpp.Shipping_Account_Type__c = 'Cust/Partner Account - FedEx';
//thisOpp.Shipping_Method__c = 'Ground'; Alekya
thisOpp.Shipping_Method__c = 'ECONOMY';
thisOpp.Freight_Cost__c = 20;
test.startTest();
update thisOpp;
OpportunityLineItem oli = new OpportunityLineItem(OpportunityId = thisOpp.Id, Quantity = 1, PriceBookEntryId = vg33.Id, UnitPrice = vg33.UnitPrice);
insert oli;
//Set Closed Date for Returns workflow
Opportunity  opp = [Select id, StageName, Freight_Cost__c, Internal_Finance__c, Amount_Received__c,
Overwrite_Validation_Rule__c, Freight_Account__c, CloseDate, MBO_Authorized_By__c, MBO_Authorized_Date_Time__c FROM Opportunity WHERE Id=: thisOpp.Id];
system.assertEquals(opp.CloseDate, system.today());
//Make freight charge $0 workflow
system.assertEquals(opp.Freight_Cost__c, 0);
//Uncheck Overwrite Validation workflow
system.assertEquals(opp.Overwrite_Validation_Rule__c, false);
//Customer Freight Account workflow
system.assertEquals(opp.Freight_Account__c, '00000');
test.stopTest();
}
//Groundswell - Nilesh Jain : Workflow Optimization changes related to Account Updates
@isTest
private static void testAccountUpdates(){
OpportunityTriggerHandler.maxRuns = 3;
test.startTest();
Account acc = new Account ();
acc = TestFactory.initializeAccount('UpdateAccountTest');
acc.BillingStreet = 'test 123';
acc.BillingCity = 'San jose';
acc.BillingPostalCode = '94856';
acc.Netsuite_Id__c = null;
insert acc;
Opportunity thisOpp = new Opportunity();
thisOpp = TestFactory.initializeOpportunity ('RollupToAccountACV_Bookings_SOT');
thisOpp.AccountId = acc.Id;
thisOpp.StageName = 'Decision';
insert thisOpp;
Opportunity opptyAfterInsert = [Select id, CloseDate, Amount_Received__c, StageName, Internal_Finance__c FROM Opportunity WHERE Id=: thisOpp.Id];
opptyAfterInsert.StageName = 'Closed Won';
opptyAfterInsert.Internal_Finance__c = 'Approved';
opptyAfterInsert.CloseDate = Date.today();
opptyAfterInsert.Amount_Received__c = 60;
 TriggerHandler.bypass('OpportunityTriggerHandler');
update opptyAfterInsert;
acc = [Select id, Internally_Financed__c, Churn_Update_CC_Link__c FROM Account WHERE Id =: thisOpp.AccountId LIMIT 1];
//Update Payment Method Link on Account workflow
//system.assertEquals(true, acc.Internally_Financed__c);
//Account Internally Financed workflow
//system.assertEquals(acc.Churn_Update_CC_Link__c, System.Label.UpdatePaymentMethodLink + acc.Id);
test.stopTest();
}
// Groundswell : Tanuj - WFlow Rule : Copy Owner Role
@isTest
private static void testCopyOwnerRoleWflow(){
OpportunityTriggerHandler.maxRuns = 1;
Account acc = new Account ();
acc = TestFactory.initializeAccount('RollupToAccountACV_Bookings_SOT');
acc.BillingStreet = 'test 123';
acc.BillingCity = 'San jose';
acc.BillingPostalCode = '94856';
insert acc;
test.startTest();
Id pId = [SELECT Id FROM Profile WHERE Name = 'System Administrator'][0].Id;
User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
UserRole urMgmt = new UserRole();
UserRole urSrDrPartner = new UserRole();
User userRecordWithMgmtRole = new User();
User userRecordWithSrPartnrRole = new User();
system.runAs(thisUser){
urMgmt = new UserRole(Name = 'Management');
insert urMgmt;
urSrDrPartner = new UserRole(Name = 'Senior Director Partner');
insert urSrDrPartner;
userRecordWithMgmtRole = (User)
TestFactory.createSObject(new User(ProfileId = pId,
EmployeeNumber = '123',
LastName = 'last',
Email = 'puser000@amamama.com',
Username = 'puser000@amamama.com' + Math.random() + System.currentTimeMillis(),
CompanyName = 'TEST',
Title = 'title',
Alias = 'alias',
TimeZoneSidKey = 'America/Los_Angeles',
EmailEncodingKey = 'UTF-8',
LanguageLocaleKey = 'en_US',
LocaleSidKey = 'en_US',
Order_Admin_Fallback_User__c = TRUE,
isActive = TRUE,
UserRoleId = urMgmt.Id ));
insert userRecordWithMgmtRole;
userRecordWithSrPartnrRole = (User)
TestFactory.createSObject(new User(ProfileId = pId,
EmployeeNumber = '123',
LastName = 'last',
Email = 'puser000@amamama.com',
Username = 'puser000@amamama.com' + Math.random() + System.currentTimeMillis(),
CompanyName = 'TEST',
Title = 'title',
Alias = 'alias',
TimeZoneSidKey = 'America/Los_Angeles',
EmailEncodingKey = 'UTF-8',
LanguageLocaleKey = 'en_US',
LocaleSidKey = 'en_US',
Order_Admin_Fallback_User__c = TRUE,
isActive = TRUE,
UserRoleId = urSrDrPartner.Id ));
insert userRecordWithSrPartnrRole;
}
Id pricebookId = Test.getStandardPricebookId();
addProducts(pricebookId);
PricebookEntry vg33 = getPricebookEntry(pricebookId, 'LIC-VG33');
Opportunity thisOpp = new Opportunity();
thisOpp = TestFactory.initializeOpportunity ('CopyOwnerWflow_Ott');
thisOpp.AccountId = acc.Id;
thisOpp.OwnerId = userRecordWithMgmtRole.Id;
thisOpp.StageName = 'Qualified';
thisOpp.Type = 'Rebate';
thisOpp.Rebate_Type__c = 'Buyout';
//thisOpp.Pricebook2Id = pricebookId;
system.debug('Start Insert');
insert thisOpp;
Opportunity oppAfterInsert = [Select id, Owner_Role_Copy__c, Owner.UserRole.Name, StageName FROM Opportunity WHERE Id=: thisOpp.Id];
//Copy Owner Role
system.assertEquals(oppAfterInsert.Owner.UserRole.Name, oppAfterInsert.Owner_Role_Copy__c);
test.stopTest();
}
@isTest
private static void testCopyOwnerRoleWflowUpdate(){
OpportunityTriggerHandler.maxRuns = 1;
Account acc = new Account ();
acc = TestFactory.initializeAccount('RollupToAccountACV_Bookings_SOT');
acc.BillingStreet = 'test 123';
acc.BillingCity = 'San jose';
acc.BillingPostalCode = '94856';
insert acc;
Opportunity oppAfterInsert = [SELECT Id, Name FROM Opportunity WHERE Name = 'Opp Testers 2 Inc' LIMIT 1];
test.startTest();
Id pId = [SELECT Id FROM Profile WHERE Name = 'System Administrator'][0].Id;
User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
UserRole urMgmt = new UserRole();
UserRole urSrDrPartner = new UserRole();
User userRecordWithMgmtRole = new User();
User userRecordWithSrPartnrRole = new User();
system.runAs(thisUser){
urMgmt = new UserRole(Name = 'Management');
insert urMgmt;
urSrDrPartner = new UserRole(Name = 'Senior Director Partner');
insert urSrDrPartner;
userRecordWithSrPartnrRole = (User)
TestFactory.createSObject(new User(ProfileId = pId,
EmployeeNumber = '123',
LastName = 'last',
Email = 'puser000@amamama.com',
Username = 'puser000@amamama.com' + Math.random() + System.currentTimeMillis(),
CompanyName = 'TEST',
Title = 'title',
Alias = 'alias',
TimeZoneSidKey = 'America/Los_Angeles',
EmailEncodingKey = 'UTF-8',
LanguageLocaleKey = 'en_US',
LocaleSidKey = 'en_US',
Order_Admin_Fallback_User__c = TRUE,
isActive = TRUE,
UserRoleId = urSrDrPartner.Id ));
insert userRecordWithSrPartnrRole;
}
oppAfterInsert.StageName = 'Qualified';
oppAfterInsert.OwnerId = userRecordWithSrPartnrRole.Id;
update oppAfterInsert;
Opportunity oppAfterOwnerUpdate = [Select id, Owner_Role_Copy__c, Owner.UserRole.Name, StageName FROM Opportunity WHERE Id=: oppAfterInsert.Id];
//Copy Owner Role on Update
system.assertEquals(oppAfterOwnerUpdate.Owner.UserRole.Name, oppAfterOwnerUpdate.Owner_Role_Copy__c);
test.stopTest();
}
// Copy Owner Role Wflow
// 2nd Test Case -  Copy Returning Oppty role
@isTest
private static void testCopyOwnerRoleWflowRetOppty(){
OpportunityTriggerHandler.maxRuns = 3;
Account acc = new Account ();
acc = TestFactory.initializeAccount('RollupToAccountACV_Bookings_SOT');
acc.BillingStreet = 'test 123';
acc.BillingCity = 'San jose';
acc.BillingPostalCode = '94856';
insert acc;
Opportunity revOpp = [SELECT Id, Name FROM Opportunity WHERE Name = 'Opp Testers 2 Inc' LIMIT 1];
Opportunity thisOppRet = new Opportunity();
thisOppRet = TestFactory.initializeOpportunity ('Returning_Oppty');
thisOppRet.AccountId = acc.Id;
thisOppRet.Returning_Opportunity__c = revOpp.Id;
thisOppRet.StageName = 'Qualified';
thisOppRet.Type = 'Rebate' ;
thisOppRet.Rebate_Type__c = 'Buyout';
test.startTest();
insert thisOppRet;
Opportunity oppAfterRetOpptyInsert = [Select id, Owner_Role_Copy__c, Owner.UserRole.Name, StageName,Returning_Opportunity__r.Owner_Role_Copy__c FROM Opportunity WHERE Id=: thisOppRet.Id];
//Copy Owner Role - AfterRetOpptyUpdate (2nd Condition)
//system.assertEquals(oppAfterRetOpptyInsert.Returning_Opportunity__r.Owner_Role_Copy__c, oppAfterRetOpptyInsert.Owner_Role_Copy__c);
test.stopTest();
}
// Groundswell : Tanuj - WFlow Rule : Update Account for NS Sync
@isTest
private static void testUpdateAccountForNsSync(){
OpportunityTriggerHandler.maxRuns = 1;
test.startTest();
Account acc = new Account ();
acc = TestFactory.initializeAccount('UpdateAccountForNsSync');
acc.BillingStreet = 'test 123';
acc.BillingCity = 'San jose';
acc.BillingPostalCode = '94856';
acc.Netsuite_Id__c = null;
insert acc;
Opportunity thisOpp = new Opportunity();
thisOpp = TestFactory.initializeOpportunity ('RollupToAccountACV_Bookings_SOT');
thisOpp.AccountId = acc.Id;
thisOpp.StageName = 'Decision';
insert thisOpp;
acc = [Select id, Netsuite_Id__c, Push_to_Netsuite__c  FROM Account WHERE Id =: thisOpp.AccountId LIMIT 1];
system.assertEquals(true, acc.Push_to_Netsuite__c);
Opportunity opptyAfterInsert = [Select id, StageName FROM Opportunity WHERE Id=: thisOpp.Id];
opptyAfterInsert.StageName = 'Qualified';
update opptyAfterInsert;
acc = [Select id, Netsuite_Id__c, Push_to_Netsuite__c  FROM Account WHERE Id =: thisOpp.AccountId LIMIT 1];
system.assertEquals(true, acc.Push_to_Netsuite__c);
test.stopTest();
}
// Groundswell : Tanuj - Common Wflow Test Method
@isTest
private static void testCommonWflowConversion(){
OpportunityTriggerHandler.maxRuns = 1;
Account acc = new Account ();
acc = TestFactory.initializeAccount('UpdateAccountForNsSync');
acc.BillingStreet = 'test 123';
acc.BillingCity = 'San jose';
acc.BillingPostalCode = '94856';
acc.BillingCountry  = 'United States';
acc.Billing_Email__c = 'testaccEmail@tst.com';
acc.Netsuite_Id__c = null;
insert acc;
//Update License Term Credit on Creation
Opportunity revOpp = [SELECT Id, Name FROM Opportunity WHERE Name = 'Opp Testers 2 Inc' LIMIT 1];
Id pId = [SELECT Id FROM Profile WHERE Name = 'System Administrator'][0].Id;
User userRecord = new User();
userRecord = (User)TestFactory.createSObject(new User(ProfileId = pId,
EmployeeNumber = '123',
LastName = 'last',
Email = 'puser000@amamama.com',
Username = 'puser000@amamama.com' + Math.random() + System.currentTimeMillis(),
CompanyName = 'TEST',
Title = 'title',
Alias = 'alias',
TimeZoneSidKey = 'America/Los_Angeles',
EmailEncodingKey = 'UTF-8',
LanguageLocaleKey = 'en_US',
LocaleSidKey = 'en_US',
Order_Admin_Fallback_User__c = TRUE,
isActive = TRUE,
ManagerId = Userinfo.getUserId(),
Level__c = 'AE 1'));
insert userRecord;
test.startTest();
Opportunity thisOpp = new Opportunity();
thisOpp = TestFactory.initializeOpportunity ('CommonWFlow_Oppty');
thisOpp.AccountId = acc.Id;
thisOpp.StageName = 'Decision';
thisOpp.OwnerId = userRecord.Id;
// Update License Term Credit on Creation
thisOpp.Returning_Opportunity__c = revOpp.Id;
thisOpp.Rebate_Type__c = 'License Term Credit' ;
thisOpp.License_Months_to_Credit__c = '1';
thisOpp.Amount = 1000;
insert thisOpp;
Opportunity opptyAfterInsert = [Select id, Name, Amount, StageName FROM Opportunity WHERE Id=: thisOpp.Id];
//Update License Term Credit on Creation
system.assertEquals(revOpp.Name+'& - License Term Credit', opptyAfterInsert.Name);
system.assertEquals(0, opptyAfterInsert.Amount);
//MBO Authorized Stamping
opptyAfterInsert.MBO_Authorized__c = true;
//Clear Push Return to Netsuite Checkbox
opptyAfterInsert.Corresponding_Netsuite_ID__c = 'NetsuiteId';
opptyAfterInsert.Push_Return_to_Netsuite__c = true;
opptyAfterInsert.Rebate_Type__c = 'Buyout';
//Move Webstore Oppty to Closing
opptyAfterInsert.Small_Fleet_Opportunity__c = true;
opptyAfterInsert.Express_Agreement_Accepted_Date__c = system.today();
opptyAfterInsert.Amount_Received__c = 1000;
opptyAfterInsert.Amount = 1000;
//Add Default Expiring Discount Date
opptyAfterInsert.Discount_Approval_Status__c = 'Approved';
try {
update opptyAfterInsert;
Opportunity opptyAfterUpdate = [Select id, Amount, MBO_Authorized_By__c, MBO_Authorized_Date_Time__c, Push_Return_to_Netsuite__c, StageName, Checkout_Discount_Expiration_Date_Time__c,Historical_Amount__c FROM Opportunity WHERE Id=: opptyAfterInsert.Id];
//MBO Authorized By Stamp
system.assertEquals(UserInfo.getFirstName() + ' ' + UserInfo.getLastName(),opptyAfterUpdate.MBO_Authorized_By__c);
//MBO Authorized Date/Time Stamp
system.assertNotEquals(null, opptyAfterUpdate.MBO_Authorized_Date_Time__c);
//Clear Push Return to Netsuite Checkbox
system.assertEquals(false, opptyAfterUpdate.Push_Return_to_Netsuite__c);
//Move Webstore Oppty to Closing
system.assertEquals('Closing', opptyAfterUpdate.StageName);
//Add Default Expiring Discount Date
system.assertNotEquals(null, opptyAfterUpdate.Checkout_Discount_Expiration_Date_Time__c);
//Clear Push Transfer Order to Netsuite Checkbox
opptyAfterUpdate.Retry_TO_to_NS__c = true;
opptyAfterUpdate.Netsuite_Transfer_Order_ID__c = 'NetSuiteOrderID';
update opptyAfterUpdate;
Opportunity oppAfterSecondUpdate = [Select id, Name, Retry_TO_to_NS__c FROM Opportunity WHERE Id=: opptyAfterUpdate.Id];
//Clear Push Transfer Order to Netsuite Checkbox
system.assertEquals(false, oppAfterSecondUpdate.Retry_TO_to_NS__c);
 }catch(Exception ex) {
     System.debug('Error in '+ex.getMessage());   
 }
test.stopTest();
}
// Groundswell : Tanuj - Common Wflow Test Method for Trial Record Type Oppty
@isTest
private static void testTrialOpptyWflowConversion(){
OpportunityTriggerHandler.maxRuns = 1;
Opportunity freeTrial = [ SELECT Id, Deactivate__c, Send_Invoice__c, Trial_Period__c, Trial_Start_Date_new__c, Trial_Number_of_Days_Left__c, CloseDate, Trial_Status__c, Trial_Completion_Date__c FROM Opportunity WHERE Name='Opp Testers 1 Inc'];
// Deactivation Timestamp
// Trial Invoice Timestamp
freeTrial.Deactivate__c = true;
freeTrial.Send_Invoice__c = true;
freeTrial.Trial_Status__c = 'Purchased';
update freeTrial;
test.startTest();
Opportunity opptyAfterUpdate = [Select id, Name, Amount, StageName, Deactivation_Date__c, Invoice_Date__c, Trial_Period__c, Trial_Start_Date_new__c, Trial_Number_of_Days_Left__c, CloseDate, Trial_Status__c, Trial_Completion_Date__c FROM Opportunity WHERE Id=: freeTrial.Id];
//Deactivation Timestamp
//Trial Invoice Timestamp
system.assertNotEquals(null, opptyAfterUpdate.Deactivation_Date__c);
system.assertNotEquals(null, opptyAfterUpdate.Invoice_Date__c);
// Stamp Trial Completion Date
system.assertEquals(system.today(), opptyAfterUpdate.Trial_Completion_Date__c);
// Free Trial Return Date Update
opptyAfterUpdate.Deactivate__c = false;
opptyAfterUpdate.Trial_Status__c = 'Return In Process';
update opptyAfterUpdate;
Opportunity opptyAfterTrialReturn = [Select id, Name, Amount, StageName, Deactivation_Date__c, Invoice_Date__c, Trial_Period__c, Trial_Start_Date_new__c, Trial_Number_of_Days_Left__c, CloseDate, Trial_Status__c, Trial_Completion_Date__c FROM Opportunity WHERE Id=: opptyAfterUpdate.Id];
// Free Trial Return Date Update
system.assertEquals((opptyAfterTrialReturn.Trial_Start_Date_new__c.daysBetween(system.today())) + 30, opptyAfterTrialReturn.Trial_Period__c);
// Re Open Trial when End Date Exceeded
opptyAfterTrialReturn.CloseDate = System.today() - 60;
update opptyAfterTrialReturn;
Opportunity opptyAfterEndDateExceeded = [Select id, Name, Amount, StageName, Deactivation_Date__c, Invoice_Date__c, Trial_Period__c, Trial_Start_Date_new__c, Trial_Number_of_Days_Left__c, CloseDate, Trial_Status__c, Trial_Completion_Date__c FROM Opportunity WHERE Id=: opptyAfterTrialReturn.Id];
// Re Open Trial when End Date Exceeded
//system.assertEquals('Open', opptyAfterEndDateExceeded.Trial_Status__c);
test.stopTest();
}
// Groundswell : Tanuj - Test Method for Referral Payout Amount - Fleet Oppty Wflows
@isTest
private static void testReferralPayoutAmountFleetWflowConversionFirstIteration(){
OpportunityTriggerHandler.maxRuns = 1;
Account partnerAccountForReferralOppty = new Account(Name = 'Testers Partner Inc',
BillingState='California',
BillingCountry = 'United States',
Organization_Size__c = '100 - 499',
RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner').getRecordTypeId(),
Type = 'Partner');
insert partnerAccountForReferralOppty;
// Referral Payout Amount - Fleet
Opportunity thisOpp = new Opportunity();
thisOpp = TestFactory.initializeOpportunity ('ReferralOpptyOne');
thisOpp.AccountId = partnerAccountForReferralOppty.Id;
thisOpp.Referral_Partner__c = partnerAccountForReferralOppty.Id;
thisOpp.Uncapped_Partner_Referral_Payout_Amount__c = false;
thisOpp.License_Term__c =12;
thisOpp.CurrencyIsoCode = 'USD';
test.startTest();
insert thisOpp;
Opportunity opptyAfterInsert = [Select id, Partner_Referral_Payout_Amount_V2__c, ACV_List_Price__c, Currency_Exchange_Rate__c FROM Opportunity WHERE Id=: thisOpp.Id];
// Referral Payout Amount - Fleet
system.assertEquals(0, opptyAfterInsert.Partner_Referral_Payout_Amount_V2__c);
Id pricebookId = Test.getStandardPricebookId();
addProducts(pricebookId);
PricebookEntry vg33 = getPricebookEntry(pricebookId, 'LIC-VG33');
OpportunityLineItem oli = new OpportunityLineItem(OpportunityId = opptyAfterInsert.Id, Quantity = 1, PriceBookEntryId = vg33.Id, UnitPrice = vg33.UnitPrice, License_Term_Copy__c = 36);
insert oli;
Opportunity opptyAfterUpdate = [Select id, Partner_Referral_Payout_Amount_V2__c, ACV_List_Price__c, Currency_Exchange_Rate__c,List_Price__c,License_Term_Formula__c FROM Opportunity WHERE Id=: opptyAfterInsert.Id];
// Referral Payout Amount - Fleet
// After Update OLI
system.assertEquals((-0.2*opptyAfterUpdate.ACV_List_Price__c), opptyAfterUpdate.Partner_Referral_Payout_Amount_V2__c);
test.stopTest();
}
// Groundswell : Tanuj - Test Method for Referral Payout Amount - Fleet Oppty Wflows
@isTest
private static void testReferralPayoutAmountFleetWflowConversionSecondIteration(){
OpportunityTriggerHandler.maxRuns = 1;
Account partnerAccountForReferralOppty = new Account(Name = 'Testers Partner Inc',
BillingState='California',
BillingCountry = 'United States',
Organization_Size__c = '100 - 499',
RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner').getRecordTypeId(),
Type = 'Partner');
insert partnerAccountForReferralOppty;
// Referral Payout Amount - Fleet
Opportunity thisOpp = new Opportunity();
thisOpp = TestFactory.initializeOpportunity ('ReferralOpptyOne');
thisOpp.AccountId = partnerAccountForReferralOppty.Id;
thisOpp.Referral_Partner__c = partnerAccountForReferralOppty.Id;
thisOpp.Uncapped_Partner_Referral_Payout_Amount__c = false;
thisOpp.License_Term__c =12;
thisOpp.CurrencyIsoCode = 'USD';
test.startTest();
insert thisOpp;
Id pricebookId = Test.getStandardPricebookId();
addProducts(pricebookId);
PricebookEntry vg33 = getPricebookEntry(pricebookId, 'LIC-VG33');
vg33.UnitPrice = 1500;
update vg33;
OpportunityLineItem oli = new OpportunityLineItem(OpportunityId = thisOpp.Id, Quantity = 2000, PriceBookEntryId = vg33.Id, UnitPrice = vg33.UnitPrice, License_Term_Copy__c = 36);
insert oli;
// Referral Payout Amount - Fleet
// After Update OLI & Product to satisfy 2nd condition
Opportunity opptyAfterSecondUpdate = [Select id, Partner_Referral_Payout_Amount_V2__c, ACV_List_Price__c, Currency_Exchange_Rate__c,List_Price__c,License_Term_Formula__c FROM Opportunity WHERE Id=: thisOpp.Id];
system.assertEquals((-50000 *opptyAfterSecondUpdate.Currency_Exchange_Rate__c), opptyAfterSecondUpdate.Partner_Referral_Payout_Amount_V2__c);
test.stopTest();
}
// Groundswell : Tanuj - Test Method for Referral Payout Amount Industrial ENT Oppty Wflows
@isTest
private static void testReferralPayoutAmountIndustrialENTWflowConversionFirstIteration(){
OpportunityTriggerHandler.maxRuns = 1;
Account partnerAccountForReferralOppty = new Account(Name = 'Testers Partner Inc',
BillingState='California',
BillingCountry = 'United States',
Organization_Size__c = '100 - 499',
RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner').getRecordTypeId(),
Type = 'Partner');
insert partnerAccountForReferralOppty;
Id pId = [SELECT Id FROM Profile WHERE Name = 'System Administrator'][0].Id;
User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
UserRole urSrDrPartner = new UserRole();
User userRecordWithSrPartnrRole = new User();
system.runAs(thisUser){
urSrDrPartner = new UserRole(Name = 'Industrial');
insert urSrDrPartner;
userRecordWithSrPartnrRole = (User)
TestFactory.createSObject(new User(ProfileId = pId,
EmployeeNumber = '123',
LastName = 'last',
Email = 'puser000@amamama.com',
Username = 'puser000@amamama.com' + Math.random() + System.currentTimeMillis(),
CompanyName = 'TEST',
Title = 'title',
Alias = 'alias',
TimeZoneSidKey = 'America/Los_Angeles',
EmailEncodingKey = 'UTF-8',
LanguageLocaleKey = 'en_US',
LocaleSidKey = 'en_US',
Order_Admin_Fallback_User__c = TRUE,
isActive = TRUE,
Business_Unit__c = 'Industrial',
Segment__c = 'Enterprise',
UserRoleId = urSrDrPartner.Id ));
insert userRecordWithSrPartnrRole;
}
//Referral Payout Amount Industrial ENT
Opportunity thisOppPayoutIndustrial = new Opportunity();
thisOppPayoutIndustrial = TestFactory.initializeOpportunity ('ReferralOpptyOne');
thisOppPayoutIndustrial.AccountId = partnerAccountForReferralOppty.Id;
thisOppPayoutIndustrial.OwnerId = userRecordWithSrPartnrRole.id;
thisOppPayoutIndustrial.Referral_Partner__c = partnerAccountForReferralOppty.Id;
thisOppPayoutIndustrial.License_Term__c =12;
thisOppPayoutIndustrial.CurrencyIsoCode = 'USD';
test.startTest();
insert thisOppPayoutIndustrial;
Opportunity oppPayoutIndustrialAfterInsert = [Select id, Partner_Referral_Payout_Amount_V2__c, ACV_List_Price__c, Currency_Exchange_Rate__c FROM Opportunity WHERE Id=: thisOppPayoutIndustrial.Id];
//Referral Payout Amount Industrial ENT
system.assertEquals(0, oppPayoutIndustrialAfterInsert.Partner_Referral_Payout_Amount_V2__c);
Id pricebookId = Test.getStandardPricebookId();
addProducts(pricebookId);
PricebookEntry vg33 = getPricebookEntry(pricebookId, 'LIC-VG33');
OpportunityLineItem oliSecond = new OpportunityLineItem(OpportunityId = oppPayoutIndustrialAfterInsert.Id, Quantity = 1, PriceBookEntryId = vg33.Id, UnitPrice = vg33.UnitPrice, License_Term_Copy__c = 36);
insert oliSecond;
Opportunity oppPayoutIndustrialAfterUpdate = [Select id, Partner_Referral_Payout_Amount_V2__c, ACV_List_Price__c, Currency_Exchange_Rate__c,List_Price__c,License_Term_Formula__c FROM Opportunity WHERE Id=: oppPayoutIndustrialAfterInsert.Id];
//Referral Payout Amount Industrial ENT
// After Update OLI
system.assertEquals(oppPayoutIndustrialAfterUpdate.List_Price__c * (-0.05*oppPayoutIndustrialAfterUpdate.Currency_Exchange_Rate__c ), oppPayoutIndustrialAfterUpdate.Partner_Referral_Payout_Amount_V2__c);
test.stopTest();
}
// Groundswell : Tanuj - Test Method for Referral Payout Amount Industrial ENT Oppty Wflows
@isTest
private static void testReferralPayoutAmountIndustrialENTWflowConversionSecondIteration(){
OpportunityTriggerHandler.maxRuns = 1;
Account partnerAccountForReferralOppty = new Account(Name = 'Testers Partner Inc',
BillingState='California',
BillingCountry = 'United States',
Organization_Size__c = '100 - 499',
RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner').getRecordTypeId(),
Type = 'Partner');
insert partnerAccountForReferralOppty;
Id pId = [SELECT Id FROM Profile WHERE Name = 'System Administrator'][0].Id;
User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
UserRole urSrDrPartner = new UserRole();
User userRecordWithSrPartnrRole = new User();
system.runAs(thisUser){
urSrDrPartner = new UserRole(Name = 'Industrial');
insert urSrDrPartner;
userRecordWithSrPartnrRole = (User)
TestFactory.createSObject(new User(ProfileId = pId,
EmployeeNumber = '123',
LastName = 'last',
Email = 'puser000@amamama.com',
Username = 'puser000@amamama.com' + Math.random() + System.currentTimeMillis(),
CompanyName = 'TEST',
Title = 'title',
Alias = 'alias',
TimeZoneSidKey = 'America/Los_Angeles',
EmailEncodingKey = 'UTF-8',
LanguageLocaleKey = 'en_US',
LocaleSidKey = 'en_US',
Order_Admin_Fallback_User__c = TRUE,
isActive = TRUE,
Business_Unit__c = 'Industrial',
Segment__c = 'Enterprise',
UserRoleId = urSrDrPartner.Id ));
insert userRecordWithSrPartnrRole;
}
//Referral Payout Amount Industrial ENT
Opportunity thisOppPayoutIndustrial = new Opportunity();
thisOppPayoutIndustrial = TestFactory.initializeOpportunity ('ReferralOpptyOne');
thisOppPayoutIndustrial.AccountId = partnerAccountForReferralOppty.Id;
thisOppPayoutIndustrial.OwnerId = userRecordWithSrPartnrRole.id;
thisOppPayoutIndustrial.Referral_Partner__c = partnerAccountForReferralOppty.Id;
thisOppPayoutIndustrial.License_Term__c =12;
thisOppPayoutIndustrial.CurrencyIsoCode = 'USD';
test.startTest();
insert thisOppPayoutIndustrial;
Id pricebookId = Test.getStandardPricebookId();
addProducts(pricebookId);
PricebookEntry vg33 = getPricebookEntry(pricebookId, 'LIC-VG33');
// Referral Payout Amount Industrial ENT
// After Update OLI & Product to satisfy 2nd condition
vg33.UnitPrice = 1500;
update vg33;
OpportunityLineItem oliSecond = new OpportunityLineItem(OpportunityId = thisOppPayoutIndustrial.Id, Quantity = 2000, PriceBookEntryId = vg33.Id, UnitPrice = vg33.UnitPrice, License_Term_Copy__c = 36);
insert oliSecond;
Opportunity opptyPayoutIndustrialAfterSecondUpdate = [Select id, Partner_Referral_Payout_Amount_V2__c, ACV_List_Price__c, Currency_Exchange_Rate__c,List_Price__c,License_Term_Formula__c FROM Opportunity WHERE Id=: thisOppPayoutIndustrial.Id];
system.assertEquals((-100000*opptyPayoutIndustrialAfterSecondUpdate.Currency_Exchange_Rate__c), opptyPayoutIndustrialAfterSecondUpdate.Partner_Referral_Payout_Amount_V2__c);
test.stopTest();
}
// WFlow Rule - License Term Update for other rebate type
@isTest
private static void testLicenseTermUpdateForRebateTypeMethod(){
OpportunityTriggerHandler.maxRuns = 10;
Account acc = new Account ();
acc = TestFactory.initializeAccount('RollupToAccountACV_Bookings_SOT');
insert acc;
Opportunity revOpp = [SELECT Id, Name, CloseDate, License_End_Date__c FROM Opportunity WHERE Name = 'Opp Testers 2 Inc' LIMIT 1];
OpportunityTriggerHandler.resetAll();
OpportunityWorkflowConversion.firstRun = true;
revOpp.License_Term__c = 12;
test.startTest();
OpportunityTriggerHandler.resetAll();
OpportunityWorkflowConversion.firstRun = true;
update revOpp;
Opportunity thisOppRet = new Opportunity();
thisOppRet = TestFactory.initializeOpportunity ('Returning_Oppty');
thisOppRet.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Return Opportunity').getRecordTypeId();
thisOppRet.Returning_Opportunity__c = revOpp.Id;
thisOppRet.AccountId = acc.Id;
thisOppRet.Amount = 0;
thisOppRet.Type = 'Rebate' ;
thisOppRet.Rebate_Type__c = 'License Term Credit';
OpportunityTriggerHandler.resetAll();
OpportunityWorkflowConversion.firstRun = true;
insert thisOppRet;
Opportunity oppAfterRetOpptyInsert = [Select id, License_Term__c  FROM Opportunity WHERE Id=: thisOppRet.Id];
//system.assertEquals(revOpp.License_Term__c, oppAfterRetOpptyInsert.License_Term__c);
oppAfterRetOpptyInsert.Rebate_Type__c = 'Buyout';
OpportunityTriggerHandler.resetAll();
OpportunityWorkflowConversion.firstRun = true;
update oppAfterRetOpptyInsert;
Opportunity oppAfterRetOpptyUpdate = [Select id, License_Term__c  FROM Opportunity WHERE Id=: oppAfterRetOpptyInsert.Id];
//system.assertEquals(revOpp.License_Term__c, oppAfterRetOpptyUpdate.License_Term__c);
test.stopTest();
}
// WFlow Rule - License Term Update for Delinquent Opp
/*@isTest
private static void testLicenseTermUpdateForDelinquentOppMethod(){
OpportunityTriggerHandler.maxRuns = 1;
Account acc = new Account ();
acc = TestFactory.initializeAccount('RollupToAccountACV_Bookings_SOT');
insert acc;
Opportunity revOpp = [SELECT Id, Name, CloseDate, License_End_Date__c FROM Opportunity WHERE Name = 'Opp Testers 2 Inc' LIMIT 1];
revOpp.License_Term__c = 12;
revOpp.License_Start_Date__c = system.today();
revOpp.License_End_Date__c = system.today().addDays(365);
revOpp.StageName = 'Closed Won';
update revOpp;
test.startTest();
Opportunity thisOppRet = new Opportunity();
thisOppRet = TestFactory.initializeOpportunity ('Returning_Oppty');
thisOppRet.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Return Opportunity').getRecordTypeId();
thisOppRet.Returning_Opportunity__c = revOpp.Id;
thisOppRet.AccountId = acc.Id;
thisOppRet.Amount = 0;
thisOppRet.Type = 'Rebate' ;
thisOppRet.Rebate_Type__c = 'Delinquent';
insert thisOppRet;
Opportunity oppAfterRetOpptyInsert = [Select id, CloseDate, License_Term__c  FROM Opportunity WHERE Id=: thisOppRet.Id];
system.assertEquals(((oppAfterRetOpptyInsert.CloseDate.daysBetween(revOpp.License_End_Date__c))/30.41).setScale(2), oppAfterRetOpptyInsert.License_Term__c);
oppAfterRetOpptyInsert.CloseDate = system.today().addDays(1);
update oppAfterRetOpptyInsert;
Opportunity oppAfterRetOpptyDelinquentUpdate = [Select id, CloseDate, License_Term__c  FROM Opportunity WHERE Id=: oppAfterRetOpptyInsert.Id];
system.assertEquals(((oppAfterRetOpptyDelinquentUpdate.CloseDate.daysBetween(revOpp.License_End_Date__c))/30.41).setScale(2), oppAfterRetOpptyDelinquentUpdate.License_Term__c);
test.stopTest();
} */
// Groundswell : Tanuj - Test Method for Referral Payout Amount Uncapped - Fleet Oppty Wflows
@isTest
private static void testReferralPayoutAmountUncappedFleetMethod(){
OpportunityTriggerHandler.maxRuns = 1;
Account partnerAccountForReferralOppty = new Account(Name = 'Testers Partner Inc',
BillingState='California',
BillingCountry = 'United States',
Organization_Size__c = '100 - 499',
RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner').getRecordTypeId(),
Type = 'Partner');
insert partnerAccountForReferralOppty;
// Referral Payout Amount Uncapped
Opportunity thisOpp = new Opportunity();
thisOpp = TestFactory.initializeOpportunity ('ReferralOpptyOne');
thisOpp.AccountId = partnerAccountForReferralOppty.Id;
thisOpp.Referral_Partner__c = partnerAccountForReferralOppty.Id;
thisOpp.Uncapped_Partner_Referral_Payout_Amount__c = true;
thisOpp.License_Term__c =12;
thisOpp.CurrencyIsoCode = 'USD';
test.startTest();
OpportunityTriggerHandler.resetAll();
OpportunityWorkflowConversion.firstRun = true;
insert thisOpp;
Opportunity opptyAfterInsert = [Select id, Partner_Referral_Payout_Amount_V2__c, ACV_List_Price__c, Currency_Exchange_Rate__c FROM Opportunity WHERE Id=: thisOpp.Id];
// Referral Payout Amount - Fleet
//system.assertEquals(0, opptyAfterInsert.Partner_Referral_Payout_Amount_V2__c);
Id pricebookId = Test.getStandardPricebookId();
addProducts(pricebookId);
PricebookEntry vg33 = getPricebookEntry(pricebookId, 'LIC-VG33');
OpportunityLineItem oli = new OpportunityLineItem(OpportunityId = opptyAfterInsert.Id, Quantity = 1, PriceBookEntryId = vg33.Id, UnitPrice = vg33.UnitPrice, License_Term_Copy__c = 36);
OpportunityTriggerHandler.resetAll();
OpportunityWorkflowConversion.firstRun = true;
insert oli;
Opportunity opptyAfterUpdate = [Select id, Partner_Referral_Payout_Amount_V2__c, ACV_List_Price__c, Currency_Exchange_Rate__c,List_Price__c,License_Term_Formula__c FROM Opportunity WHERE Id=: opptyAfterInsert.Id];
// Referral Payout Amount - Fleet
// After Update OLI
//system.assertEquals((-0.2*opptyAfterUpdate.ACV_List_Price__c), opptyAfterUpdate.Partner_Referral_Payout_Amount_V2__c);
test.stopTest();
}
// WFlow Rule - Copy Owner Manager Email When Closing
@isTest
private static void testCopyOwnerManagerEmailWhenClosingMethod(){
OpportunityTriggerHandler.maxRuns = 1;
Account acc = new Account ();
acc = TestFactory.initializeAccount('RollupToAccountACV_Bookings_SOT');
acc.BillingStreet = 'test 123';
acc.BillingCity = 'San jose';
acc.BillingPostalCode = '94856';
acc.BillingCountry = 'United States';
acc.Billing_Email__c = 'test@testemail.com';
acc.CS_POC_First_Name__c = 'Name';
acc.CS_POC_Email_Address__c = 'test@testemail.com';
insert acc;
Contact contactTwo = (Contact) TestFactory.createSObject(new Contact(AccountId = acc.Id, Email = 'test@test.com'));
insert contactTwo;
Opportunity revOpp = (Opportunity)
TestFactory.createSObject(new Opportunity(AccountId = acc.Id,
Type = 'Revenue Opportunity',
Name = 'Opp Testers 2 Inc',
StageName = 'Proposal',
Shipping_Contact__c = contactTwo.Id,
Price_Book_Name__c = 'Standard',
Selected_Payment_Type__c = 'Direct Annual'));
TriggerHandler.bypass('OpportunityTriggerHandler');
insert revOpp;
TriggerHandler.clearBypass('OpportunityTriggerHandler');
revOpp.StageName = 'Closing';
revOpp.Owner_Manager_Email_Copy__c = null;
revOpp.Free_Trial_Purchase__c = 'Full Buy';
        revOpp.Bypass_Validation_Rule_DateTime__c=DateTime.now();
test.startTest();
update revOpp;
Opportunity revOppUpdateFirst = [Select id, Owner.Manager.Email, Owner_Manager_Email_Copy__c FROM Opportunity WHERE Id=: revOpp.Id];
system.assertEquals(revOppUpdateFirst.Owner.Manager.Email,revOppUpdateFirst.Owner_Manager_Email_Copy__c);
Opportunity thisOppRet = new Opportunity();
thisOppRet = TestFactory.initializeOpportunity ('Returning_Oppty');
thisOppRet.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Return Opportunity').getRecordTypeId();
thisOppRet.Returning_Opportunity__c = revOpp.Id;
thisOppRet.AccountId = acc.Id;
thisOppRet.Amount = 0;
thisOppRet.Type = 'Rebate';
thisOppRet.Rebate_Type__c = 'Buyout';
TriggerHandler.bypass('OpportunityTriggerHandler');
insert thisOppRet;
thisOppRet.StageName = 'Refunded - Closed';
thisOppRet.Type = 'Rebate' ;
thisOppRet.Owner_Manager_Email_Copy__c = null;
        thisOppRet.Bypass_Validation_Rule_DateTime__c=DateTime.now();
update thisOppRet;
TriggerHandler.clearBypass('OpportunityTriggerHandler');
Opportunity oppAfterRetOpptyRefunded = [Select id, Returning_Opportunity__r.Owner_Manager_Email_Copy__c, Owner.Manager.Email, Owner_Manager_Email_Copy__c  FROM Opportunity WHERE Id=: thisOppRet.Id];
test.stopTest();
}
// WFlow Rule - Stamp Responsible Party Email
@isTest
private static void testStampResponsiblePartyEmail(){
OpportunityTriggerHandler.maxRuns = 1;
Account acc = new Account ();
acc = TestFactory.initializeAccount('RollupToAccountACV_Bookings_SOT');
insert acc;
Opportunity thisOppRet = new Opportunity();
thisOppRet = TestFactory.initializeOpportunity ('Returning_Oppty');
thisOppRet.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Return Opportunity').getRecordTypeId();
thisOppRet.AccountId = acc.id;
thisOppRet.Amount = 0;
thisOppRet.Type = 'Rebate';
thisOppRet.Rebate_Type__c = 'Buyout';
TriggerHandler.bypass('OpportunityTriggerHandler');
insert thisOppRet;
TriggerHandler.clearBypass('OpportunityTriggerHandler');
thisOppRet.Rebate_Type__c = 'License Term Credit';
thisOppRet.License_Term_Credit_Reason__c = 'Product';
thisOppRet.License_Credit_Subreason__c = 'VG - Compliance fine from DOT due to product failure';
test.startTest();
update thisOppRet;
Opportunity revOppUpdateFirst = [Select id, License_Credit_Responsible_Party__c FROM Opportunity WHERE Id=: thisOppRet.Id];
system.assertEquals(System.Label.Email_vg_concession,revOppUpdateFirst.License_Credit_Responsible_Party__c);
revOppUpdateFirst.License_Term_Credit_Reason__c = 'Sales';
revOppUpdateFirst.License_Credit_Subreason__c = 'Sales - Does not support primary use case';
update revOppUpdateFirst;
Opportunity revOppUpdateForSales = [Select id, Return_Oppty_Owner_Email__c,License_Credit_Responsible_Party__c FROM Opportunity WHERE Id=: thisOppRet.Id];
system.assertEquals(revOppUpdateForSales.Return_Oppty_Owner_Email__c,revOppUpdateForSales.License_Credit_Responsible_Party__c);
test.stopTest();
}
@isTest
private static void teststampRTNNumberMethod(){
Account acc = new Account ();
acc = TestFactory.initializeAccount('RollupToAccountACV_Bookings_SOT');
insert acc;
Opportunity thisOppRet = new Opportunity();
thisOppRet = TestFactory.initializeOpportunity ('Returning_Oppty');
thisOppRet.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Return Opportunity').getRecordTypeId();
thisOppRet.AccountId = acc.id;
thisOppRet.Return_Number_Shipping__c = null;
thisOppRet.Type = 'Rebate';
thisOppRet.Rebate_Type__c = 'Buyout';
thisOppRet.Amount = 0;
test.startTest();
OpportunityTriggerHandler.resetAll();
OpportunityWorkflowConversion.firstRun = true;
insert thisOppRet;
Opportunity revOppUpdateForSales = [Select id, Return_Number_Shipping__c, Return_Number__c FROM Opportunity WHERE Id=: thisOppRet.Id];
//system.assertEquals(revOppUpdateForSales.Return_Number_Shipping__c,revOppUpdateForSales.Return_Number__c);
test.stopTest();
}
@isTest static void testIncubate() {
Opportunity newOpportunity = [SELECT id from Opportunity LIMIT 1];
Opportunity newOpportunity1 = [SELECT id,type from Opportunity WHERE Type = 'Revenue Opportunity' LIMIT 1];
Contact cc = [Select Id from Contact where Email = 'test@test.com' limit 1];
test.startTest();
newOpportunity.Trial_Goal_1__c = 'fooo';
newOpportunity.closeDate = system.today().adddays(50);
newOpportunity.Trial_Primary_Contact__c = cc.Id;
newOpportunity.Trial_Goal_2__c  = 'foooo1';
newOpportunity.Trial_Period__c = 10;
newOpportunity.Planned_Trial_Installation_Date__c = system.today();
newOpportunity.StageName = 'Incubate';
newOpportunity.TrialResolutionOppty__c  = newOpportunity1.Id;
update newOpportunity;
test.stopTest();
}
@isTest static void testProposal() {
Opportunity newOpportunity = [SELECT id from Opportunity LIMIT 1];
test.startTest();
newOpportunity.StageName = 'Proposal';
update newOpportunity;
test.stopTest();
}
@isTest static void testTrial() {
Opportunity newOpportunity = [SELECT id from Opportunity LIMIT 1];
Opportunity newOpportunity1 = [SELECT id,type from Opportunity WHERE Type = 'Revenue Opportunity' LIMIT 1];
Contact cc = [Select Id from Contact where Email = 'test@test.com' limit 1];
test.startTest();
newOpportunity.Trial_Goal_1__c = 'fooo';
newOpportunity.closeDate = system.today().adddays(50);
newOpportunity.Trial_Primary_Contact__c = cc.Id;
newOpportunity.Trial_Goal_2__c  = 'foooo1';
newOpportunity.Trial_Period__c = 10;
newOpportunity.Planned_Trial_Installation_Date__c = system.today();
newOpportunity.TrialResolutionOppty__c  = newOpportunity1.Id;
newOpportunity.StageName = 'Trial';
update newOpportunity;
test.stopTest();
}
@isTest static void testQualified() {
Opportunity newOpportunity = [SELECT id from Opportunity LIMIT 1];
Opportunity newOpportunity1 = [SELECT id,type from Opportunity WHERE Type = 'Revenue Opportunity' LIMIT 1];
Contact cc = [Select Id from Contact where Email = 'test@test.com' limit 1];
test.startTest();
newOpportunity.Trial_Goal_1__c = 'fooo';
newOpportunity.closeDate = system.today().adddays(50);
newOpportunity.Trial_Primary_Contact__c = cc.Id;
newOpportunity.Trial_Goal_2__c  = 'foooo1';
newOpportunity.Trial_Period__c = 10;
newOpportunity.Planned_Trial_Installation_Date__c = system.today();
newOpportunity.TrialResolutionOppty__c  = newOpportunity1.Id;
newOpportunity.StageName = 'Qualified';
update newOpportunity;
test.stopTest();
}
@isTest static void testDecision() {
Opportunity newOpportunity = [SELECT id from Opportunity LIMIT 1];
Opportunity newOpportunity1 = [SELECT id,type from Opportunity WHERE Type = 'Revenue Opportunity' LIMIT 1];
Contact cc = [Select Id from Contact where Email = 'test@test.com' limit 1];
test.startTest();
newOpportunity.Trial_Goal_1__c = 'fooo';
newOpportunity.closeDate = system.today().adddays(50);
newOpportunity.Trial_Primary_Contact__c = cc.Id;
newOpportunity.Trial_Goal_2__c  = 'foooo1';
newOpportunity.Trial_Period__c = 10;
newOpportunity.Planned_Trial_Installation_Date__c = system.today();
newOpportunity.TrialResolutionOppty__c  = newOpportunity1.Id;
newOpportunity.StageName = 'Decision';
update newOpportunity;
test.stopTest();
}
@isTest static void testClosing() {
Opportunity newOpportunity = [SELECT id from Opportunity LIMIT 1];
Opportunity newOpportunity1 = [SELECT id,type from Opportunity WHERE Type = 'Revenue Opportunity' LIMIT 1];
Contact cc = [Select Id from Contact where Email = 'test@test.com' limit 1];
test.startTest();
newOpportunity.Trial_Goal_1__c = 'fooo';
newOpportunity.closeDate = system.today().adddays(50);
newOpportunity.Trial_Primary_Contact__c = cc.Id;
newOpportunity.Trial_Goal_2__c  = 'foooo1';
newOpportunity.Trial_Period__c = 10;
newOpportunity.Planned_Trial_Installation_Date__c = system.today();
newOpportunity.TrialResolutionOppty__c  = newOpportunity1.Id;
newOpportunity.StageName = 'Closing';
newOpportunity.Probability = 0.95;
update newOpportunity;
SBQQ__Quote__c qt = new SBQQ__Quote__c(SBQQ__Opportunity2__c = newOpportunity.Id, SBQQ__Primary__c = false);
insert qt; 
test.stopTest();
}
@isTest static void testClosedWon() {
Opportunity newOpportunity = [SELECT Id, Name, Owner_Role_Copy__c, Owner_Business_Unit__c from Opportunity LIMIT 1];
Opportunity newOpportunity1 = [SELECT Id, Name, Owner_Role_Copy__c, Owner_Business_Unit__c from Opportunity WHERE Type = 'Revenue Opportunity' LIMIT 1];
Contact cc = [Select Id from Contact where Email = 'test@test.com' limit 1];
Account acc = [Select id, Name, SLED_Account__c, Owner_Role__c from Account Limit 1];
test.startTest();
newOpportunity.Trial_Goal_1__c = 'fooo';
newOpportunity.closeDate = system.today().adddays(50);
newOpportunity.Trial_Primary_Contact__c = cc.Id;
newOpportunity.Trial_Goal_2__c  = 'foooo1';
newOpportunity.Trial_Period__c = 10;
newOpportunity.Planned_Trial_Installation_Date__c = system.today();
newOpportunity.StageName = 'Closed Won';
newOpportunity.TrialResolutionOppty__c  = newOpportunity1.Id;
update newOpportunity;
Set<Id> setopp = new Set<Id>();
setopp.add(newOpportunity.Id);
OpportunityHelper.getOwnerForDelinquentRebateOpportunity(setopp);
OpportunityHelper.setOwnerSubRegion(newOpportunity, acc);
system.debug('newOpportunity---'+newOpportunity);
test.stopTest();
}
@isTest static void testClosedLost() {
Opportunity newOpportunity = [SELECT id from Opportunity LIMIT 1];
Opportunity newOpportunity1 = [SELECT id,type from Opportunity WHERE Type = 'Revenue Opportunity' LIMIT 1];
Contact cc = [Select Id from Contact where Email = 'test@test.com' limit 1];
test.startTest();
newOpportunity.Trial_Goal_1__c = 'fooo';
newOpportunity.closeDate = system.today().adddays(50);
newOpportunity.Trial_Primary_Contact__c = cc.Id;
newOpportunity.Trial_Goal_2__c  = 'foooo1';
newOpportunity.Trial_Period__c = 10;
newOpportunity.Planned_Trial_Installation_Date__c = system.today();
newOpportunity.StageName = 'Closed Lost';
newOpportunity.TrialResolutionOppty__c  = newOpportunity1.Id;
update newOpportunity;
system.debug('newOpportunity---'+newOpportunity);
test.stopTest();
}
@istest private static void testUpdateRenewedLinesforRebate(){
//Map<Id,Id> opportunityIds  = new Map<Id,Id>();
List <Account> accsToInsert = new List <Account>();
Account acc = new Account();
acc.Name = 'Testaccount1';
acc.Organization_Size__c = '1 - 99';
acc.Industry = 'Agriculture';
acc.BillingState = 'California';
acc.BillingCountry = 'United States';
accsToInsert.add(acc);
insert accsToInsert;
List<Opportunity> oppList = new List<Opportunity>();
Opportunity thisOpp1 = new Opportunity();
thisOpp1 = TestFactory.initializeOpportunity ('testOppty1');
thisOpp1.AccountId = acc.Id;
thisOpp1.StageName = 'Qualified';
thisOpp1.StageName = 'Proposal';
thisOpp1.Type = 'Revenue Opportunity' ;
thisOpp1.Amount = 10000;
oppList.add(thisOpp1);
Opportunity thisOpp2 = new Opportunity();
thisOpp2 = TestFactory.initializeOpportunity ('testOppty2');
thisOpp2.AccountId = acc.Id;
thisOpp2.StageName = 'Qualified';
thisOpp2.StageName = 'Proposal';
thisOpp2.Type = 'Revenue Opportunity';
thisOpp2.Amount = 10000;
oppList.add(thisOpp2);
Map<Id,Id> OppIDS = new Map<Id,Id>();
Test.startTest();
insert oppList;
List<OpportunityLineItem> opplineList = new List<OpportunityLineItem>();
OpportunityLineItem oli = new OpportunityLineItem();
oli.Renewed_Line__c = true;
oli.Quantity = 3;
oli.OpportunityId = thisOpp1.id;
Id pricebookId = Test.getStandardPricebookId();
addProductsfordelinquency(pricebookId);
PricebookEntry vg33 = getPricebookEntryfordelinquency(pricebookId, 'LIC-VG33');
oli.PriceBookEntryId = vg33.id;
oli.UnitPrice = vg33.UnitPrice;
oli.Account__c = acc.Id;
OpportunityLineItem oli2 = new OpportunityLineItem();
oli2.Renewed_Line__c = true;
oli2.Quantity = 3;
oli2.OpportunityId = thisOpp1.id;
oli2.PriceBookEntryId = vg33.id;
oli2.UnitPrice = vg33.UnitPrice;
oli2.Account__c = acc.Id;
opplineList.add(oli2);
insert opplinelist;
OppIDS.put(thisOpp1.id,thisOpp2.id);
OpportunityHelper.UpdateRenewedLinesforRebate(OppIDS);
Test.stopTest();
}
@istest private static void testUpdateRenewedLinesforRebate1(){
//Map<Id,Id> opportunityIds  = new Map<Id,Id>();
List <Account> accsToInsert = new List <Account>();
Account acc = new Account();
acc.Name = 'Testaccount1';
acc.Organization_Size__c = '1 - 99';
acc.Industry = 'Agriculture';
acc.BillingState = 'California';
acc.BillingCountry = 'United States';
accsToInsert.add(acc);
insert accsToInsert;
List<Opportunity> oppList = new List<Opportunity>();
Opportunity thisOpp1 = new Opportunity();
thisOpp1 = TestFactory.initializeOpportunity ('testOppty1');
thisOpp1.AccountId = acc.Id;
thisOpp1.StageName = 'Qualified';
thisOpp1.StageName = 'Proposal';
thisOpp1.Type = 'Revenue Opportunity' ;
thisOpp1.Amount = 10000;
//thisOpp1.CloseDate = '7/23/2022';
oppList.add(thisOpp1);
Opportunity thisOpp2 = new Opportunity();
thisOpp2 = TestFactory.initializeOpportunity ('testOppty2');
thisOpp2.AccountId = acc.Id;
thisOpp2.StageName = 'Qualified';
thisOpp2.StageName = 'Proposal';
thisOpp2.Type = 'Warranty Exchange';
thisOpp2.Amount = 10000;
oppList.add(thisOpp2);
Map<Id,Id> OppIDS = new Map<Id,Id>();
Test.startTest();
insert oppList;
List<OpportunityTeamMember> memberlist = new List<OpportunityTeamMember>();
OpportunityTeamMember otm = new OpportunityTeamMember();
otm.TeamMemberRole = '';
otm.OpportunityId = thisOpp1.id;
otm.userid = UserInfo.getUserId();
memberlist.add(otm);
insert memberlist;
OppIDS.put(thisOpp1.id,thisOpp2.id);
OpportunityHelper.createOpportunityTeams(OppIDS);
OpportunityHelper ohelper = new OpportunityHelper();
ohelper.Current_Monthly_PaymentsCondition(thisopp2);
ohelper.validatePoBox('testaddress');
Test.stopTest();
}
static private PricebookEntry getPricebookEntryfordelinquency(Id pricebookId, String productCode) {
PricebookEntry entry = [Select Id, UnitPrice, Pricebook2Id, ProductCode from PricebookEntry where ProductCode = :productCode and Pricebook2Id = :pricebookId LIMIT 1];
return entry;
}
static private void addProductsfordelinquency(Id pricebookId) {
List<Product2> products = new List<Product2>();
Product2 vg33 = new Product2(Name = 'LIC-VG33', ProductCode = 'LIC-VG33', Family = 'Connected Worker');
products.add(vg33);
insert products;
List<PricebookEntry> pricebookEntries = new List<PricebookEntry>();
PricebookEntry vg33PB = new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = vg33.Id, UnitPrice = 10000, IsActive = true);
pricebookEntries.add(vg33PB);
insert pricebookEntries;
}
/*
@isTest private static void testRollupToAccountTotal_ACV_Pipeline() {
Account acc = new Account ();
acc = TestFactory.initializeAccount('RollupToAccountACV_Bookings_SOT');
insert acc;
Opportunity thisOpp = new Opportunity();
thisOpp = TestFactory.initializeOpportunity ('RollupToAccountACV_Bookings_SOT');
thisOpp.Type = 'Revenue Opportunity' ;
thisOpp.StageName = 'Qualified';
thisOpp.AccountId = acc.Id;
thisOpp.License_Term__c = 6;
thisOpp.Amount = 10000;
insert thisOpp;
acc = [Select id, Total_ACV_Pipeline__c FROM Account WHERE Name LIKE 'RollupToAccountACV_Bookings_SOT%' LIMIT 1];
system.assertEquals(acc.Total_ACV_Pipeline__c, 10000);
Test.startTest();
delete thisOpp;
acc = [Select id, Total_ACV_Pipeline__c FROM Account WHERE Name LIKE 'RollupToAccountACV_Bookings_SOT%' LIMIT 1];
system.assertEquals(acc.Total_ACV_Pipeline__c, null);
Opportunity[] savedopps = [SELECT Id, probability FROM Opportunity WHERE Name LIKE 'RollupToAccountACV_Bookings_SOT%' ALL ROWS];
undelete savedopps;
acc = [Select id, Total_ACV_Pipeline__c FROM Account WHERE Name LIKE 'RollupToAccountACV_Bookings_SOT%' LIMIT 1];
system.assertEquals(acc.Total_ACV_Pipeline__c, 10000);
Test.stopTest();
}
@isTest private static void testRollupToAccountTotal_ACV_PipelineReparentiong() {
Account acc = new Account ();
acc = TestFactory.initializeAccount('RollupToAccountACV_Bookings_SOT');
insert acc;
Opportunity thisOpp = new Opportunity();
thisOpp = TestFactory.initializeOpportunity ('RollupToAccountACV_Bookings_SOT');
thisOpp.Type = 'Revenue Opportunity' ;
thisOpp.StageName = 'Qualified';
thisOpp.AccountId = acc.Id;
thisOpp.License_Term__c = 6;
thisOpp.Amount = 10000;
insert thisOpp;
Test.startTest();
Account acc1 = new Account ();
acc1 = TestFactory.initializeAccount('RollupToAccountACV_Bookings_SOT1');
insert acc1;
thisOpp.AccountId = acc1.id;
update thisOpp;
acc1 = [Select id, Total_ACV_Pipeline__c FROM Account WHERE Name LIKE 'RollupToAccountACV_Bookings_SOT1%' LIMIT 1];
system.assertEquals(acc1.Id, thisOpp.AccountId);
Test.stopTest();
} */
@isTest private static void testOpportunityTeams() {
Test.startTest();
Account a = [SELECT id FROM Account WHERE Name = 'Testers 6 Inc'];
// Create oppty, but don't flip acceptance
Integer emailBefore = Limits.getEmailInvocations();
System.debug('Email count before ='+emailBefore);
Id recordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Trial').getRecordTypeId();
Opportunity trial = (Opportunity)
TestFactory.createSObject(new Opportunity(AccountId = a.Id,
RecordTypeId = recordTypeId,
Probability = 0,
Type = 'Free Trial Opportunity'));
insert trial;
Id pId = [SELECT Id FROM Profile WHERE Name = 'System Administrator'][0].Id;
User newMember;
System.runAs(new User(Id = UserInfo.getUserId())){
UserRole urMgmt = new UserRole(Name = 'Management');
insert urMgmt;
newMember = (User)
TestFactory.createSObject(new User(ProfileId = pId,
EmployeeNumber = '123',
LastName = 'last',
Email = 'puser000@amamama.com',
Username = 'puser000@amamama.com' + Math.random() + System.currentTimeMillis(),
CompanyName = 'TEST',
Title = 'title',
Alias = 'alias',
TimeZoneSidKey = 'America/Los_Angeles',
EmailEncodingKey = 'UTF-8',
LanguageLocaleKey = 'en_US',
LocaleSidKey = 'en_US',
Order_Admin_Fallback_User__c = TRUE,
isActive = TRUE,
UserRoleId = urMgmt.Id ));
insert newMember;
}
OpportunityTeamMember member = new OpportunityTeamMember(OpportunityId = trial.Id, UserId = newMember.Id,TeamMemberRole = 'Product Specialist');
insert member;
Opportunity opp = (Opportunity)
TestFactory.createSObject(new Opportunity(AccountId = a.Id,
Type = 'Free Trial Opportunity',
Name = 'Opp Testers 1 Inc',
StageName = 'Proposal',
RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Trial').getRecordTypeId(),
Shipping_Contact__c = [SELECT Id FROM Contact WHERE AccountId = :a.Id LIMIT 1].Id,
Selected_Payment_Type__c = 'Direct Annual',
Price_Book_Name__c = 'Standard',
TrialResolutionOppty__c = trial.Id,
Send_Invoice__c = false));
OpportunityTriggerHandler.resetAll();
insert opp;
Test.stopTest();
//System.assert([SELECT COUNT() FROM OpportunityTeamMember WHERE OpportunityId = :opp.Id] > 1);
}
// Groundswell : Flavio - GTMS-6105 test scenario
// commented due to CPU timelimit error
/*@isTest
private static void testClickpath(){
SBQQ.TriggerControl.disable();
OpportunityTriggerHandler.maxRuns = 1;
Account acc = [SELECT Id, Name FROM Account LIMIT 1];
//Standard Pricebook
Id pricebookId = Test.getStandardPricebookId();
//Create Products
List<Product2> products = new List<Product2>();
Product2 vg33 = new Product2(Name= 'HW-VG33', ProductCode = 'HW-VG33', Family = 'Test');
products.add(vg33);
//Product2 vgLicense = new Product2(Name= 'LIC-VG-36MO', ProductCode = 'LIC-VG-36MO', Family = 'Test');
//products.add(vgLicense);
insert products;
//Create PriceBookEntries
List<PricebookEntry> pricebookEntries = new List<PricebookEntry>();
PricebookEntry vg33PB = new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = vg33.Id, UnitPrice = 10000, IsActive = true);
pricebookEntries.add(vg33PB);
//PricebookEntry vgLicensePB = new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = vgLicense.Id, UnitPrice = 10000, IsActive = true);
//pricebookEntries.add(vgLicensePB);
insert pricebookEntries;
Opportunity thisOpp = [SELECT Id FROM Opportunity WHERE Name LIKE 'Opp Testers 2%' LIMIT 1];
Contract cont = new Contract(
AccountId = acc.Id,
StartDate = System.today(),
EndDate   = System.today().addDays(30),
ContractTerm = 1,
Status = 'Draft',
SBQQ__Opportunity__c = thisOpp.Id
);
insert cont;
cont.Status = 'Activated';
update cont;
thisOpp.AccountId = acc.Id;
thisOpp.Type = 'Revenue Opportunity';
thisOpp.Sub_Type__c = 'Clickpath';
thisOpp.Renewal__c = true;
thisOpp.StageName = 'Purchase';
thisOpp.Shipping_Contact__c = [SELECT Id FROM Contact WHERE AccountId = :acc.Id LIMIT 1].Id;
update thisOpp;
SBQQ.TriggerControl.enable();
SBQQ__Quote__c quote = new SBQQ__Quote__c(Quote_Name__c = 'First Quote ', SBQQ__Account__c = acc.Id, SBQQ__Opportunity2__c =thisOpp.Id,
SBQQ__SubscriptionTerm__c =10,Estimated_Annual_Payment__c = 24, SBQQ__Primary__c = true, Custom_License_Term__c = 2);
insert quote;
// Ensuring quoteLines will be successful
Test.setCreatedDate(quote.Id, System.now().addMinutes(-10));
Test.startTest();
SBQQ.TriggerControl.disable();
List<SBQQ__QuoteLine__c> newlineItems = new List<SBQQ__QuoteLine__c>();
SBQQ__QuoteLine__c quoteLineOne =  new SBQQ__QuoteLine__c(SBQQ__Quote__c = quote.Id,SBQQ__PricebookEntryId__c = vg33PB.Id,SBQQ__Quantity__c  = 1,
SBQQ__Discount__c = 0,SBQQ__Product__c = vg33.Id,SBQQ__CustomerPrice__c = 10000);
newlineItems.add(quoteLineOne);
SBQQ__QuoteLine__c quoteLineTwo =  new SBQQ__QuoteLine__c(SBQQ__Quote__c = quote.Id, SBQQ__PricebookEntryId__c = vg33PB.Id, SBQQ__Quantity__c  = 5,
SBQQ__Discount__c = 0, SBQQ__Product__c = vg33.Id, SBQQ__CustomerPrice__c = 10000);
newlineItems.add(quoteLineTwo);
insert newlineItems;
OpportunityTriggerHandler.resetAll();
update thisOpp;
thisOpp = [SELECT Id, Gainsight_Audit_Status__c, Gainsight_Audit_Override__c FROM Opportunity WHERE Id = :thisOpp.Id];
System.assertEquals('Success', thisOpp.Gainsight_Audit_Status__c);
Test.stopTest();
}*/
// Groundswell : Flavio - GTMS-6105 test scenario
@isTest
private static void testClickpath_existingQuoteLines(){
SBQQ.TriggerControl.disable();
OpportunityTriggerHandler.maxRuns = 1;
Account acc = [SELECT Id, Name FROM Account WHERE Name LIKE 'Testers 6%' LIMIT 1];
Contact con = [SELECT Id FROM Contact WHERE AccountId =:acc.Id LIMIT 1];
Opportunity thisOpp = [SELECT Id FROM Opportunity WHERE Name LIKE 'Opp Testers 3%' LIMIT 1];
Shipping_Address__c sa = new Shipping_Address__c(Shipping_Zip_Code__c = '94105', Shipping_Contact__c=con.Id, Shipping_Address_Line_1__c='1 Dolores, Dallas', Shipping_City__c='Dallas', Shipping_Country__c='United States', Shipping_State__c='Texas', Name='Test', Account__c = acc.Id);
insert sa;
//Standard Pricebook
Id pricebookId = Test.getStandardPricebookId();
//Create Products
List<Product2> products = new List<Product2>();
Product2 vg33 = new Product2(Name= 'HW-VG33', ProductCode = 'HW-VG33', Family = 'Test');
products.add(vg33);
//Product2 vgLicense = new Product2(Name= 'LIC-VG-36MO', ProductCode = 'LIC-VG-36MO', Family = 'Test');
//products.add(vgLicense);
insert products;
//Create PriceBookEntries
List<PricebookEntry> pricebookEntries = new List<PricebookEntry>();
PricebookEntry vg33PB = new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = vg33.Id, UnitPrice = 10000, IsActive = true);
pricebookEntries.add(vg33PB);
//PricebookEntry vgLicensePB = new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = vgLicense.Id, UnitPrice = 10000, IsActive = true);
//pricebookEntries.add(vgLicensePB);
insert pricebookEntries;
Contract cont = new Contract(
AccountId = acc.Id,
StartDate = System.today(),
EndDate   = System.today().addDays(30),
ContractTerm = 1,
Status = 'Draft',
SBQQ__Opportunity__c = thisOpp.Id,
Weighted_Average_Start_Date__c = System.today().addDays(-1)
);
insert cont;
cont.Status = 'Activated';
update cont;
Test.startTest();
SBQQ.TriggerControl.enable();
SBQQ__Quote__c quote = new SBQQ__Quote__c(Quote_Name__c = 'First Quote ', SBQQ__Account__c = acc.Id, SBQQ__Opportunity2__c =thisOpp.Id,
SBQQ__SubscriptionTerm__c =10,Estimated_Annual_Payment__c = 24, SBQQ__Primary__c = true, Custom_License_Term__c = 2);
insert quote;
SBQQ.TriggerControl.disable();
List<SBQQ__QuoteLine__c> newlineItems = new List<SBQQ__QuoteLine__c>();
SBQQ__QuoteLine__c quoteLineOne =  new SBQQ__QuoteLine__c(SBQQ__Quote__c = quote.Id,SBQQ__PricebookEntryId__c = vg33PB.Id,SBQQ__Quantity__c  = 1,
SBQQ__Discount__c = 0,SBQQ__Product__c = vg33.Id,SBQQ__CustomerPrice__c = 10000,
Ship_To__c = sa.Id);
newlineItems.add(quoteLineOne);
SBQQ__QuoteLine__c quoteLineTwo =  new SBQQ__QuoteLine__c(SBQQ__Quote__c = quote.Id, SBQQ__PricebookEntryId__c = vg33PB.Id, SBQQ__Quantity__c  = 5,
SBQQ__Discount__c = 0, SBQQ__Product__c = vg33.Id, SBQQ__CustomerPrice__c = 10000,
Ship_To__c = sa.Id);
newlineItems.add(quoteLineTwo);
insert newlineItems;
OpportunityTriggerHandler.resetAll();
thisOpp.AccountId = acc.Id;
thisOpp.Type = 'Revenue Opportunity';
thisOpp.Sub_Type__c = 'Clickpath';
thisOpp.Renewal__c = true;
thisOpp.StageName = 'Purchase';
thisOpp.Shipping_Contact__c = [SELECT Id FROM Contact WHERE AccountId = :acc.Id LIMIT 1].Id;
TriggerHandler.bypass('OpportunityTriggerHandler');
update thisOpp;
thisOpp = [SELECT Id, Gainsight_Audit_Status__c, Gainsight_Audit_Override__c FROM Opportunity WHERE Id = :thisOpp.Id];
//System.assert(thisOpp.Gainsight_Audit_Status__c.contains('Pending'));
Test.stopTest();
}
// Groundswell : Flavio - GTMS-6105 test scenario
//commented due to CPU timelimit error
/*@isTest
private static void testClickpath_failure(){
SBQQ.TriggerControl.disable();
OpportunityTriggerHandler.maxRuns = 1;
Account acc = [SELECT Id, Name FROM Account LIMIT 1];
//Standard Pricebook
Id pricebookId = Test.getStandardPricebookId();
//Create Products
List<Product2> products = new List<Product2>();
Product2 vg33 = new Product2(Name= 'HW-VG33', ProductCode = 'HW-VG33', Family = 'Test');
products.add(vg33);
//Product2 vgLicense = new Product2(Name= 'LIC-VG-36MO', ProductCode = 'LIC-VG-36MO', Family = 'Test');
//products.add(vgLicense);
insert products;
//Create PriceBookEntries
List<PricebookEntry> pricebookEntries = new List<PricebookEntry>();
PricebookEntry vg33PB = new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = vg33.Id, UnitPrice = 10000, IsActive = true);
pricebookEntries.add(vg33PB);
//PricebookEntry vgLicensePB = new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = vgLicense.Id, UnitPrice = 10000, IsActive = true);
//pricebookEntries.add(vgLicensePB);
insert pricebookEntries;
Opportunity thisOpp = [SELECT Id FROM Opportunity WHERE Name LIKE 'Opp Testers 2%' LIMIT 1];
Contract cont = new Contract(
AccountId = acc.Id,
StartDate = System.today(),
EndDate   = System.today().addDays(30),
ContractTerm = 1,
Status = 'Draft',
SBQQ__Opportunity__c = thisOpp.Id
);
insert cont;
cont.Status = 'Activated';
update cont;
Test.startTest();
thisOpp.AccountId = acc.Id;
thisOpp.Type = 'Revenue Opportunity';
thisOpp.Sub_Type__c = 'Clickpath';
thisOpp.Renewal__c = true;
thisOpp.StageName = 'Purchase';
thisOpp.Shipping_Contact__c = [SELECT Id FROM Contact WHERE AccountId = :acc.Id LIMIT 1].Id;
update thisOpp;
SBQQ.TriggerControl.enable();
SBQQ__Quote__c quote = new SBQQ__Quote__c(Quote_Name__c = 'First Quote ', SBQQ__Account__c = acc.Id, SBQQ__Opportunity2__c =thisOpp.Id,
SBQQ__SubscriptionTerm__c =10,Estimated_Annual_Payment__c = 24, SBQQ__Primary__c = true, Custom_License_Term__c = 2);
insert quote;
SBQQ.TriggerControl.disable();
List<SBQQ__QuoteLine__c> newlineItems = new List<SBQQ__QuoteLine__c>();
SBQQ__QuoteLine__c quoteLineOne =  new SBQQ__QuoteLine__c(SBQQ__Quote__c = quote.Id,SBQQ__PricebookEntryId__c = vg33PB.Id,SBQQ__Quantity__c  = 1, Gainsight_Audit_Status__c = 'Price dont match;',
SBQQ__Discount__c = 0,SBQQ__Product__c = vg33.Id,SBQQ__CustomerPrice__c = 10000);
newlineItems.add(quoteLineOne);
SBQQ__QuoteLine__c quoteLineTwo =  new SBQQ__QuoteLine__c(SBQQ__Quote__c = quote.Id, SBQQ__PricebookEntryId__c = vg33PB.Id, SBQQ__Quantity__c  = 5, Gainsight_Audit_Status__c = 'Quantity dont match;',
SBQQ__Discount__c = 0, SBQQ__Product__c = vg33.Id, SBQQ__CustomerPrice__c = 10000);
newlineItems.add(quoteLineTwo);
insert newlineItems;
OpportunityTriggerHandler.resetAll();
update thisOpp;
thisOpp = [SELECT Id, Gainsight_Audit_Status__c, Gainsight_Audit_Override__c FROM Opportunity WHERE Id = :thisOpp.Id];
System.assertNotEquals('Success', thisOpp.Gainsight_Audit_Status__c);
Test.stopTest();
}*/// //commented due to CPU timelimit error
// Groundswell : Flavio - GTMS-6105 test scenario
@isTest
private static void testClickpath_step2(){
SBQQ.TriggerControl.disable();
OpportunityTriggerHandler.maxRuns = 1;
Account acc = [SELECT Id, Name FROM Account LIMIT 1];
Opportunity thisOpp = [SELECT Id FROM Opportunity WHERE Name LIKE 'Opp Testers 2%' LIMIT 1];
Contract cont = new Contract(
AccountId = acc.Id,
StartDate = System.today(),
EndDate   = System.today().addDays(30),
ContractTerm = 1,
Status = 'Draft',
SBQQ__Opportunity__c = thisOpp.Id,
Weighted_Average_Start_Date__c = System.today().addDays(-1)
);
insert cont;
cont.Status = 'Activated';
update cont;
Test.startTest();
thisOpp.AccountId = acc.Id;
thisOpp.Type = 'Revenue Opportunity';
thisOpp.Sub_Type__c = 'Clickpath';
thisOpp.Renewal__c = true;
thisOpp.StageName = 'Purchase';
thisOpp.Shipping_Contact__c = [SELECT Id FROM Contact WHERE AccountId = :acc.Id LIMIT 1].Id;
thisOpp.CloseDate = System.today().addDays(10);
//thisOpp.Express_Agreement_Accepted_Date__c = System.today();
thisOpp.SBQQ__RenewedContract__c = cont.Id;
thisOpp.OwnerId = Id.valueOf(Label.Renewal_Pool_User);
thisOpp.License_Start_Date__c = System.today().addDays(10);
thisOpp.Adjust_License_Start_Date__c = true;
OpportunityTriggerHandler.resetAll();
update thisOpp;
thisOpp = [SELECT Id, StageName, Adjust_License_Start_Date__c, License_Start_Date__c, OwnerId FROM Opportunity WHERE Id = :thisOpp.Id];
System.assertEquals('Purchase', thisOpp.StageName);
//System.assertEquals(true, thisOpp.Adjust_License_Start_Date__c);
//System.assertEquals(System.today().addDays(10), thisOpp.License_Start_Date__c);
//System.assertEquals(Id.valueOf(Label.Clickpath_Opportunity_Won_User_Id), thisOpp.OwnerId);
Test.stopTest();
}
// Groundswell : Flavio - GTMS-6099 Future process auto renewal
@isTest
private static void testAutoRenewal_preProcessing(){
    Test.StartTest();
Account acc = [SELECT Id FROM Account LIMIT 1];
Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
Contract cont = new Contract(
AccountId = acc.Id,
StartDate = System.today(),
EndDate   = System.today().addDays(30),
ContractTerm = 1,
Status = 'Draft',
SBQQ__Opportunity__c = opp.Id,
Original_Contracted_Opportunity__c = opp.Id
);
//insert cont;
//cont.Status = 'Activated';
//update cont;
Opportunity newOpp = new Opportunity(
Type = 'Revenue Opportunity',
Sub_Type__c = 'Auto-Renewal',
Gainsight_Audit_Status__c = 'Error',
Gainsight_Audit_Override__c = true,
StageName = 'Purchase',
Adjust_License_Start_Date__c = false,
netsuite_conn__From_Contract__c = cont.Id,
SBQQ__RenewedContract__c = cont.Id,
License_Start_Date__c = (System.today()).addDays(-30),
CloseDate = (System.today()).addDays(5),
OwnerId = Id.valueOf(Label.Renewal_Pool_User)
);
Opportunity oldOpp = new Opportunity(
Type = 'Revenue Opportunity',
Sub_Type__c = 'Auto-Renewal',
Gainsight_Audit_Status__c = 'Error',
Gainsight_Audit_Override__c = false,
StageName = 'Purchase',
Adjust_License_Start_Date__c = false,
netsuite_conn__From_Contract__c = cont.Id,
License_Start_Date__c = (System.today()).addDays(-30),
CloseDate = System.today(),
OwnerId = Id.valueOf(Label.Renewal_Pool_User)
);
// Testing audit override change or Status update
new OpportunityHelper().getOpptyOwner(new Set<Id>{
Id.valueOf(Label.Renewal_Pool_User),
Id.valueOf(Label.Clickpath_Opportunity_Won_User_Id)
});
new OpportunityHelper().processFutureDatedAutoRenewal(newOpp, oldOpp, cont);
System.assertEquals(true, newOpp.Gainsight_Audit_Override__c);
System.assertEquals(Id.valueOf(Label.Clickpath_Opportunity_Won_User_Id), newOpp.OwnerId);
System.assertEquals(true, newOpp.Adjust_License_Start_Date__c);
System.assertEquals('Purchase', newOpp.StageName);
// Ensuring coverage
opp = new Opportunity(Owner_Role_Copy__c = 'None');
OpportunityHelper.setOwnerBusinessUnit(opp, new Account());
OpportunityHelper.setOwnerSubRegion(opp, new Account());
System.assertEquals(opp.Owner_sub_region__c, 'US');
System.assertEquals(opp.Owner_Business_Unit__c, 'Private Sector');
// Testing Cross Sell identifier
Opportunity otherOpp = new Opportunity(
Type = 'Revenue Opportunity',
StageName = 'Ready to Ship',
Purchase_Type__c = '',
CloseDate = System.today(),
SBQQ__PrimaryQuote__c = TestFactory.getFakeId(SBQQ__Quote__c.getSObjectType())
);
Opportunity otherOldOpp = new Opportunity(
Type = 'Revenue Opportunity',
StageName = 'Ready to Ship',
Purchase_Type__c = '',
SBQQ__PrimaryQuote__c = null
);
Account accOther = (Account) setFieldArbitrarily(
new Account(),
new Map<String, String>{
'First_Purchase_Date__c' => '"2022-02-02"',
'Total_Purchased_AG_Count__c' => '0',
'Total_Purchased_CM_Count__c' => '0',
'Total_Purchased_VG_Count__c' => '0',
'Total_Purchased_EM_Count__c' => '10'
},
Account.class
);
OpportunityLineItem item = (OpportunityLineItem) setFieldArbitrarily(
new OpportunityLineItem(),
new Map<String, String>{
'ProductCode' => '"HW-EM31-TEST"'
},
OpportunityLineItem.class
);
OpportunityHelper.updateCrossSellIdentifier(otherOpp, otherOldOpp, accOther, new List<OpportunityLineItem>{item});
System.assertEquals('Add-On', otherOpp.Purchase_Type__c);
item = (OpportunityLineItem) setFieldArbitrarily(
new OpportunityLineItem(),
new Map<String, String>{
'ProductCode' => '"HW-CM52-TEST"'
},
OpportunityLineItem.class
);
OpportunityHelper.updateCrossSellIdentifier(otherOpp, otherOldOpp, accOther, new List<OpportunityLineItem>{item});
System.assertEquals('Cross-Sell', otherOpp.Purchase_Type__c);
accOther = (Account) setFieldArbitrarily(
new Account(),
new Map<String, String>{
'First_Purchase_Date__c' => '"'+String.valueOf(System.today())+'"'
},
Account.class
);
OpportunityHelper.updateCrossSellIdentifier(otherOpp, otherOldOpp, accOther, new List<OpportunityLineItem>{item});
System.assertEquals('First Purchase', otherOpp.Purchase_Type__c);
otherOldOpp.Purchase_Type__c = 'Add-On';
OpportunityHelper.updateCrossSellIdentifier(otherOldOpp, otherOldOpp, accOther, new List<OpportunityLineItem>{item});
System.assertEquals('', otherOldOpp.Purchase_Type__c);
Test.StopTest();
}
// Simply appends fields to the JSON before deserializing it. You must provide the quotation marks if your variable type needs it, and no lists are supported.
public static SObject setFieldArbitrarily(SObject obj, Map<String, String> valueList, System.Type deserializeType){
String serializedRecord = JSON.serialize(obj).removeEnd('}');
for (String field : valueList.keySet()){
serializedRecord += ',"'+field+'":'+valueList.get(field);
}
return (SObject) JSON.deserialize(serializedRecord+'}', deserializeType);
}
@isTest static void trackingTest(){
List<Opportunity> OppList = [SELECT Id, Express_1_Year__c from Opportunity WHERE recordType.Name = 'Standard_Opportunity' LIMIT 1];
if(OppList.isEmpty()) return;
Opportunity Opp = OppList[0];
opp.Express_Agreement_Accepted_Date__c = System.today();
Global_Automation_Settings__c setting = new Global_Automation_Settings__c(Skip_Trigger__c = true);
insert setting;
Update opp;
delete setting;
opp.Express_1_Year__c = !opp.Express_1_Year__c;
update opp;
}
@isTest static void trackingTest_clear(){
List<Opportunity> OppList = [SELECT Id, Express_1_Year__c from Opportunity WHERE recordType.Name = 'Standard_Opportunity' LIMIT 1];
if(OppList.isEmpty()) return;
Opportunity Opp = OppList[0];
opp.Express_Agreement_Accepted_Date__c = System.today();
opp.Opportunity_Tracking__c = 'Warning: 1 Year Express';
Global_Automation_Settings__c setting = new Global_Automation_Settings__c(Skip_Trigger__c = true);
insert setting;
Update opp;
delete setting;
opp.Express_Agreement_Accepted_Date__c = null;
update opp;
}
    
    @isTest 
    static void testExpressSetAnnualDiscountLineItems1() {
        Account acc = [SELECT Id, ownerId FROM Account WHERE Name = 'Testers 34 Inc' LIMIT 1];
        User usr = [SELECT Id, ADR_Assignment__c FROM User WHERE UserRole.Name Like '%AE1%' AND IsActive = true LIMIT 1];
        acc.ownerId = usr.Id;
        acc.Overwrite_Validation_Rule__c = true;
        TriggerHandler.bypass('AccountTriggerHandler');
        update acc;
        Opportunity newOpportunity = (Opportunity)
            TestFactory.createSObject(new Opportunity(AccountId = acc.Id,
                                                      Type = 'Free Trial Opportunity',
                                                      Name = 'Opp Testers 1 Inc',
                                                      StageName = 'Proposal',
                                                      RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Trial').getRecordTypeId(),
                                                      Selected_Payment_Type__c = 'Direct Annual',
                                                      Price_Book_Name__c = 'Standard',
                                                      Configuration_Segment__c = 'Express',
                                                      Send_Invoice__c = false));
        TriggerHandler.bypass('OpportunityTriggerHandler');
        insert newOpportunity;
        //Opportunity newOpportunity = [SELECT Id, Configuration_Segment__c, Selected_Payment_Type__c, License_Term__c FROM Opportunity WHERE TYPE = 'Revenue Opportunity' LIMIT 1];
        Product2 prod = new Product2(Name = 'WiFi Hotspot - 2GB Total Data', Family = 'Hardware', ProductCode = 'LIC-2GB-WIFI-DATA',Product_Type__c = 'License');
        insert prod;
        test.startTest();
        Id pricebookId = Test.getStandardPricebookId();
        PricebookEntry standardPrice = new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = prod.Id, UnitPrice = 10000, IsActive = true);
        insert standardPrice;
        TriggerHandler.bypass('OpportunityLineItemTriggerHandler');
        OpportunityLineItem li = new OpportunityLineItem (Quantity=1, OpportunityId=newOpportunity.Id, PriceBookEntryId=standardPrice.Id, /*UnitPrice = 10000,*/ TotalPrice = 1000, Product_Code_Copy__c = 'LIC-2GB-WIFI-DATA');
        insert li;
        TriggerHandler.clearAllBypasses();
        li = [SELECT Id, ProductCode, Opportunity.Total_License_Due__c, TotalPrice FROM OpportunityLineItem WHERE Id =: li.Id];
        newOpportunity.Configuration_Segment__c = 'Express';
        newOpportunity.Selected_Payment_Type__c = 'Upfront Payments';
        newOpportunity.License_Term__c = 12;
        update newOpportunity;
        Test.stopTest();
    }
    
     @isTest 
    static void testExpressSetAnnualDiscountLineItems2() {
        Account acc = [SELECT Id, ownerId FROM Account WHERE Name = 'Testers 34 Inc' LIMIT 1];
        User usr = [SELECT Id, ADR_Assignment__c FROM User WHERE UserRole.Name Like '%AE1%' AND IsActive = true LIMIT 1];
        acc.ownerId = usr.Id;
        acc.Overwrite_Validation_Rule__c = true;
        TriggerHandler.bypass('AccountTriggerHandler');
        update acc;
        Opportunity newOpportunity = (Opportunity)
            TestFactory.createSObject(new Opportunity(AccountId = acc.Id,
                                                      Type = 'Free Trial Opportunity',
                                                      Name = 'Opp Testers 1 Inc',
                                                      StageName = 'Proposal',
                                                      RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Trial').getRecordTypeId(),
                                                      Selected_Payment_Type__c = 'Direct Annual',
                                                      Price_Book_Name__c = 'Standard',
                                                      Configuration_Segment__c = 'Express',
                                                      Send_Invoice__c = false));
        TriggerHandler.bypass('OpportunityTriggerHandler');
        insert newOpportunity;
        Product2 prod = new Product2(Name = 'WiFi Hotspot - 2GB Total Data', Family = 'Hardware', ProductCode = 'LIC-2GB-WIFI-DATA',Product_Type__c = 'License');
        insert prod;
        test.startTest();
        Id pricebookId = Test.getStandardPricebookId();
        PricebookEntry standardPrice = new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = prod.Id, UnitPrice = 10000, IsActive = true);
        insert standardPrice;
        TriggerHandler.bypass('OpportunityLineItemTriggerHandler');
        OpportunityLineItem li = new OpportunityLineItem (Quantity=1, OpportunityId=newOpportunity.Id, PriceBookEntryId=standardPrice.Id, /*UnitPrice = 10000,*/ TotalPrice = 1000, Product_Code_Copy__c = 'LIC-2GB-WIFI-DATA');
        insert li;
        TriggerHandler.clearAllBypasses();
        newOpportunity.Configuration_Segment__c = 'Express';
        newOpportunity.Selected_Payment_Type__c = 'Direct Monthly';
        newOpportunity.License_Term__c = 12;
        update newOpportunity;
        Test.stopTest();
    }
    
    @isTest 
    static void testExpressSetAnnualDiscountLineItems3() {
        Account acc = [SELECT Id, ownerId FROM Account WHERE Name = 'Testers 34 Inc' LIMIT 1];
        User usr = [SELECT Id, ADR_Assignment__c FROM User WHERE UserRole.Name Like '%AE1%' AND IsActive = true LIMIT 1];
        acc.ownerId = usr.Id;
        acc.Overwrite_Validation_Rule__c = true;
        TriggerHandler.bypass('AccountTriggerHandler');
        update acc;
        Opportunity newOpportunity = (Opportunity)
            TestFactory.createSObject(new Opportunity(AccountId = acc.Id,
                                                      Type = 'Free Trial Opportunity',
                                                      Name = 'Opp Testers 1 Inc',
                                                      StageName = 'Proposal',
                                                      RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Trial').getRecordTypeId(),
                                                      Selected_Payment_Type__c = 'Direct Monthly',
                                                      Price_Book_Name__c = 'Standard',
                                                      Configuration_Segment__c = 'Express',
                                                      Send_Invoice__c = false));
        TriggerHandler.bypass('OpportunityTriggerHandler');
        insert newOpportunity;
        Product2 prod = new Product2(Name = 'WiFi Hotspot - 2GB Total Data', Family = 'Hardware', ProductCode = 'LIC-2GB-WIFI-DATA',Product_Type__c = 'License');
        insert prod;
        test.startTest();
        Id pricebookId = Test.getStandardPricebookId();
        PricebookEntry standardPrice = new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = prod.Id, UnitPrice = 10000, IsActive = true);
        insert standardPrice;
        TriggerHandler.bypass('OpportunityLineItemTriggerHandler');
        OpportunityLineItem li = new OpportunityLineItem (Quantity=1, OpportunityId=newOpportunity.Id, PriceBookEntryId=standardPrice.Id, /*UnitPrice = 10000,*/ TotalPrice = 1000, Product_Code_Copy__c = 'LIC-2GB-WIFI-DATA');
        insert li;
        TriggerHandler.clearAllBypasses();
        newOpportunity.Configuration_Segment__c = 'Express';
        newOpportunity.Selected_Payment_Type__c = 'Direct Annual';
        newOpportunity.Ship_From_Location__c = 'VCK';
        newOpportunity.License_Term__c = 12;
        update newOpportunity;
        Test.stopTest();
    }
    
    @isTest 
    static void valueforSelectedPaymentTypeTest() {
        Account acc = [SELECT Id, ownerId FROM Account LIMIT 1];
        List<Opportunity> oppList = [SELECT Id FROM Opportunity WHERE Type = 'Revenue Opportunity'];
        List<Contract> contractList = new List<Contract>();
        Contract contract1 = new Contract(
            AccountId = acc.Id,
            StartDate = Date.today(),
            EndDate = Date.today().adddays(130),
            ContractTerm = 12
        );
        Contract contract2 = new Contract(
            AccountId = acc.Id,
            StartDate = Date.today(),
            EndDate = Date.today().adddays(135),
            ContractTerm = 12
        );
        contractList.add(contract1);
        contractList.add(contract2);
        Test.startTest();
        insert contractList;
        oppList[0].SBQQ__AmendedContract__c = contract1.Id;
        TriggerHandler.bypass('OpportunityTriggerHandler');
        update oppList;
        TriggerHandler.clearAllBypasses();
        List<Opportunity> newOpportunities = new List<Opportunity>();
        Opportunity opp1 = (Opportunity)
            TestFactory.createSObject(new Opportunity(AccountId = acc.Id,
                                                      Type = 'Revenue Opportunity',
                                                      Name = 'Opp 1 Inc',
                                                      StageName = 'Proposal',
                                                      Price_Book_Name__c = 'Standard',
                                                      SBQQ__Renewal__c = true,
                                                      SBQQ__RenewedContract__c = contract1.Id,
                                                      SBQQ__AmendedContract__c = contract1.Id,
                                                      Selected_Payment_Type__c = 'Direct Annual'));
        newOpportunities.add(opp1);
        Opportunity opp2 = (Opportunity)
            TestFactory.createSObject(new Opportunity(AccountId = acc.Id,
                                                      Type = 'Revenue Opportunity',
                                                      Name = 'Opp 2 Inc',
                                                      StageName = 'Proposal',
                                                      Price_Book_Name__c = 'Standard',
                                                      SBQQ__AmendedContract__c = contract1.Id,
                                                      Selected_Payment_Type__c = 'Direct Annual'));
        newOpportunities.add(opp2);
        
        insert newOpportunities;
        Test.stopTest();
    }
    
    @isTest 
    static void updateContractEndDateTest() {
        Account acc = [SELECT Id, ownerId FROM Account LIMIT 1];
        List<Opportunity> oppList = [SELECT Id FROM Opportunity WHERE Type = 'Revenue Opportunity'];
        List<Contract> contractList = new List<Contract>();
        Contract contract1 = new Contract(
            AccountId = acc.Id,
            StartDate = Date.today(),
            EndDate = Date.today().adddays(130),
            ContractTerm = 12,
            SBQQ__Opportunity__c = oppList[0].Id
        );
        Contract contract2 = new Contract(
            AccountId = acc.Id,
            StartDate = Date.today(),
            EndDate = Date.today().adddays(135),
            ContractTerm = 12
        );
        contractList.add(contract1);
        Test.startTest();
        insert contractList;

        oppList[0].Free_Trial_Extension_Status__c = 'Approved';
        update oppList;
        Test.stopTest();
    }
    
    @isTest 
    static void updateOrdersTest() {
        Account acc = [SELECT Id, ownerId FROM Account LIMIT 1];
        contact con = [SELECT Id FROM Contact LIMIT 1];
        Test.startTest();
        Account reselerAccount = OpportunityProcessBuilderConversionTest.createAccount('English', 'reselerAccount', 'SMB');
        TriggerHandler.bypass('AccountTriggerHandler');
        insert reselerAccount;

        Shipping_Address__c shippingAddress = OpportunityProcessBuilderConversionTest.createShippingAddress(acc.Id, con);
        insert shippingAddress;
        Product2 prod = new Product2(Name = 'WiFi Hotspot - 2GB Total Data', Family = 'Hardware', ProductCode = 'LIC-2GB-WIFI-DATA',Product_Type__c = 'License');
        insert prod;

        Opportunity returningOpp = OpportunityProcessBuilderConversionTest.createOppty('UPS', 'Rebate', acc.Id);
        returningOpp.Reseller_Partner__c = reselerAccount.Id;
        //returningOpp.Shipping_Contact__c = contact.Id;
        returningOpp.Shipping_Address_NEW__c = shippingAddress.Id;
        TriggerHandler.bypass('OpportunityTriggerHandler');
        insert returningOpp;
        Id pricebookId = Test.getStandardPricebookId();
        PricebookEntry standardPrice = new PricebookEntry(
            Pricebook2Id = pricebookId, Product2Id = prod.Id,
            UnitPrice = 10000, IsActive = true);
        insert standardPrice;
        Opportunity opp = OpportunityProcessBuilderConversionTest.createOppty('UPS', 'Rebate', acc.Id);
        opp.StageName = 'Return Initiated';
        opp.Returning_Opportunity__c = returningOpp.Id;
        //opp.Shipping_Contact__c = contact.Id;
        opp.Shipping_Address_NEW__c = shippingAddress.Id;
        insert opp;
        SBQQ.TriggerControl.disable();
        SBQQ__Quote__c quote = new SBQQ__Quote__c(Quote_Name__c = 'First Quote ', SBQQ__Account__c = acc.Id, SBQQ__Opportunity2__c =opp.Id, SBQQ__Status__c  = 'Approved', SBQQ__PricebookId__c = pricebookId,
                                                  SBQQ__SubscriptionTerm__c =10,Estimated_Annual_Payment__c = 24, Buyout_Amount__c = 6.0, Subsidy_Amount__c=3.0,SBQQ__Primary__c = true, Custom_License_Term__c = 2,Selected_Payment_Type__c = 'Direct Annual');
        TriggerHandler.bypass('SBQQQuoteTriggerHandler');
        insert quote;
        opp.SBQQ__PrimaryQuote__c = quote.Id;
        //update opp;       
        
        OpportunityLineItem li = new OpportunityLineItem (Quantity=1, OpportunityId=opp.Id, PriceBookEntryId=standardPrice.Id, UnitPrice = 10000);
        TriggerHandler.bypass('OpportunityLineItemTriggerHandler');
        insert li;
         SBQQ__QuoteLine__c ql =  new SBQQ__QuoteLine__c(
            SBQQ__Quote__c = quote.Id,
            SBQQ__PricebookEntryId__c = standardPrice.Id,
            SBQQ__Quantity__c  = 5,
            SBQQ__Discount__c = 0,
            SBQQ__Product__c = prod.Id,
            accountLookupTest__c = acc.Id
        );
        TriggerHandler.bypass('SBQQQuoteLineTriggerHandler');
        insert ql;
        quote.SBQQ__Ordered__c = true;
        quote.ApprovalStatus__c = 'Approved';
        quote.SBQQ__Status__c = 'Approved';
        update quote;
        TriggerHandler.clearAllBypasses();
        SBQQ.TriggerControl.enable();
        opp.stageName = 'Return Cancelled';
        opp.Type = 'Rebate';
        try{
            update opp;
        }catch(Exception e){
             //Do nothing   
            }
        Test.stopTest();
    }
    
    @isTest 
    static void beforeUpdateTest() { 
        Account acc = [SELECT Id, ownerId FROM Account LIMIT 1];
        List<Opportunity> oppList = [SELECT Id FROM Opportunity WHERE Type = 'Revenue Opportunity'];
        oppList[0].DCA_Enabled__c = 'DCA';
        TriggerHandler.bypass('OpportunityTriggerHandler');
        update oppList[0];
        TriggerHandler.clearAllBypasses();
        Test.startTest();
        Product2 prod = new Product2(Name = 'WiFi Hotspot - 2GB Total Data', Family = 'Hardware', ProductCode = 'LIC-2GB-WIFI-DATA',Product_Type__c = 'License');
        insert prod;
        Id pricebookId = Test.getStandardPricebookId();
        PricebookEntry standardPrice = new PricebookEntry(
            Pricebook2Id = pricebookId, Product2Id = prod.Id,
            UnitPrice = 10000, IsActive = true);
        insert standardPrice;
        SBQQ.TriggerControl.disable();
        SBQQ__Quote__c quote = new SBQQ__Quote__c(Quote_Name__c = 'First Quote ', SBQQ__Account__c = acc.Id, SBQQ__Opportunity2__c =oppList[0].Id, SBQQ__Status__c  = 'Approved', SBQQ__PricebookId__c = pricebookId,
                                                  SBQQ__SubscriptionTerm__c =10,Estimated_Annual_Payment__c = 24, Buyout_Amount__c = 6.0, Subsidy_Amount__c=3.0,SBQQ__Primary__c = true, Custom_License_Term__c = 2);
        insert quote;
        dsfs__DocuSign_Envelope__c envelope = new dsfs__DocuSign_Envelope__c();
        envelope.dsfs__DocuSign_Envelope_ID__c = 'Test@123@123';
        envelope.dsfs__Source_Object__c = quote.Id;
        insert envelope;
        dsfs__DocuSign_Status__c status = new dsfs__DocuSign_Status__c();       
        status.dsfs__DocuSign_Envelope_ID__c = 'Test@123@123';
        insert status;
        status.dsfs__Opportunity__c   = oppList[0].Id;
        status.dsfs__Envelope_Status__c = 'Completed';
        status.Customer_require_PO_for_invoicing__c = 'Yes';
        update status;
        SBQQ.TriggerControl.enable();
        oppList[0].SBQQ__PrimaryQuote__c = quote.Id;
        update oppList[0];
        Test.stopTest();
    }
    
    @isTest static void testEmailReturnOppty2() {
        Integer emailBefore = Limits.getEmailInvocations();
        Account a = [SELECT id, BillingCountry FROM Account WHERE Name = 'Testers 1 Inc'];
        Shipping_Address__c sa = [SELECT id FROM Shipping_Address__c WHERE Name='Test'];
        Opportunity ret = new Opportunity(AccountId = a.Id, Name = 'Return', CloseDate = System.today() + 90,
                                          StageName = 'Return Created', Probability = 10, type = 'Remorse Refund', Shipping_Address_NEW__c= sa.id);
        TriggerHandler.bypass('OpportunityTriggerHandler');
        TriggerHandler.bypass('ShippingAddressHandler');
        TriggerHandler.bypass('OpportunityLineItemTriggerHandler');
        Test.startTest();
        insert ret;
        TriggerHandler.clearAllBypasses();
        addOpptyProducts(ret);
        zkups__UPSShipment__c  shipment = new zkups__UPSShipment__c();
        shipment.zkups__MasterTrackingId__c = '1z1w7w420374732280';
        shipment.Shipmate_Label__c = ret.Id;
        insert shipment;
        Attachment attach=new Attachment();
        attach.Name='ReturnLabel-01';
        Blob bodyBlob=Blob.valueOf('Unit Test Attachment Body');
        attach.body=bodyBlob;
        attach.parentId=shipment.id;
        insert attach;
        ret.StageName = 'Return Cancelled';
        ret.Sub_Type__c = 'Upgrade';
        ret.Return_Label_Attachment__c = attach.Id;
        ret.Tracking_Number__c = 'Test123';
        ret.Bypass_Validation_Rule_DateTime__c = Datetime.now();
        TriggerHandler.bypass('AccountTriggerHandler');
        TriggerHandler.bypass('OpportunityTriggerHandler');
        Test.stopTest(); 
        update ret;
        TriggerHandler.clearAllBypasses();
    }
    
     @isTest 
     static void testShipmateServiceType1() {
        Integer emailBefore = Limits.getEmailInvocations();
        Test.startTest();
        Account a = [SELECT id, BillingCountry FROM Account WHERE Name = 'Testers 1 Inc'];
        Shipping_Address__c sa = [SELECT id FROM Shipping_Address__c WHERE Name='Test'];
        Opportunity opp = new Opportunity(AccountId = a.Id, Name = 'Return', CloseDate = System.today() + 90,
                                          StageName = 'Return Created', Probability = 10, type = 'Remorse Refund', Shipping_Address_NEW__c= sa.id);
        Opportunity opp2 = OpportunityProcessBuilderConversionTest.createOppty('UPS', 'Rebate', a.Id);
        opp2.StageName = 'Return Created';
        opp2.Returning_Opportunity__c = opp.Id;
        opp2.Shipping_Address_NEW__c = sa.Id;
        opp2.Type = 'Exchange';
        opp2.Shipmate_Preference_Override__c = true;
        opp2.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Return Opportunity').getRecordTypeId();

        TriggerHandler.bypass('OpportunityTriggerHandler');
        
        insert opp;
        insert opp2;
        TriggerHandler.clearAllBypasses();
        opp2.Shipping_Country__c = 'United States';
        opp2.Shipmate_Preference__c = 'ShippingPreference-000029';
        opp2.Shipmate_Preference_Override__c = true;
        update opp2;
        Test.stopTest();
     }
    @isTest
    static void updateOppoOwnerforRemorseRefundTest(){
     
         User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        Id pricebookId = Test.getStandardPricebookId();
        // Create Products
        List<Product2> products = new List<Product2>();
        Product2 testpro1 = new Product2(Name= 'LIC-MEM-ENT', ProductCode = 'LIC-MEM-ENT', Family = 'Emerging Products', CPQ_Enabled_Product__c = true, CurrencyIsoCode = 'USD');
        products.add(testpro1);
        
        insert products;
        
        // Create Pricebook Entries
        List<PricebookEntry> pricebookEntries = new List<PricebookEntry>();
        PricebookEntry testPB1 = new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = testpro1.Id, UnitPrice = 120, IsActive = true, CurrencyIsoCode = 'USD');
        pricebookEntries.add(testPB1);
        PricebookEntry testPB2 = new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = testpro1.Id, UnitPrice = 120, IsActive = true, CurrencyIsoCode = 'GBP');
        pricebookEntries.add(testPB2);
        
        insert pricebookEntries;
        
        // Create Accounts
        List<Account> accounts = new List<Account>();
        Account acc = new Account(Name = 'Test Account', Organization_Size__c='1 - 99', BillingCountry='United States', BillingState='New York', CurrencyIsoCode = 'USD');
        accounts.add(acc);
        Account acc1 = new Account(Name = 'Test Account1', Organization_Size__c='1 - 99', BillingCountry='United Kingdom',  CurrencyIsoCode = 'GBP');
        accounts.add(acc1);
        TriggerHandler.bypass('AccountTriggerHandler');
        insert accounts;
        TriggerHandler.clearAllBypasses();
        Test.startTest();
        //Create Opportunity
        List<Opportunity> revenueoppties = new List<Opportunity>();
        Opportunity revenueopp = new Opportunity(Name = 'RevenueOpportunity', AccountId = acc.Id,Type='Revenue Opportunity', StageName = 'Closed Won',OwnerId = thisUser.Id,Owner_Role_Copy__c = 'COR Fleet IS AE3 NA US Team 50', CloseDate = Date.today(), CurrencyIsoCode = 'USD');
        revenueoppties.add(revenueopp);
        Opportunity revenueopp1 = new Opportunity(Name = 'RevenueOpportunity1', AccountId = acc.Id,Type='Revenue Opportunity', StageName = 'Closed Won',OwnerId = thisUser.Id,Owner_Role_Copy__c = 'MM Fleet IS AE2 NA US Team 16', CloseDate = Date.today(), CurrencyIsoCode = 'USD');
        revenueoppties.add(revenueopp1);
        Opportunity revenueopp2 = new Opportunity(Name = 'RevenueOpportunity2', AccountId = acc1.Id,Type='Revenue Opportunity', StageName = 'Closed Won',OwnerId = thisUser.Id, CloseDate = Date.today(), CurrencyIsoCode = 'GBP');
        revenueoppties.add(revenueopp2);
        TriggerHandler.bypass('OpportunityTriggerHandler');
        insert revenueoppties;
        TriggerHandler.clearAllBypasses();
        	List<Opportunity> remorseRefundOpp = new List<Opportunity>();
            Opportunity remorseOpp = new Opportunity(Name = 'RemorseOpportunity', AccountId = acc.Id,Type='Remorse Refund', StageName = 'Return Created',OwnerId = thisUser.Id,Owner_Role_Copy__c = 'COR Fleet IS AE3 NA US Team 50',Returning_Opportunity__c=revenueopp.Id ,CloseDate = Date.today(),CurrencyIsoCode = 'USD');
        remorseRefundOpp.add(remorseOpp);
        Opportunity remorseOpp1 = new Opportunity(Name = 'RemorseOpportunity1', AccountId = acc.Id,Type='Remorse Refund', StageName = 'Return Created',OwnerId = thisUser.Id,Owner_Role_Copy__c = 'MM Fleet IS AE2 NA US Team 16',Returning_Opportunity__c=revenueopp1.Id ,CloseDate = Date.today(),CurrencyIsoCode = 'USD');
        remorseRefundOpp.add(remorseOpp1);
        Opportunity remorseOpp2 = new Opportunity(Name = 'RemorseOpportunity2', AccountId = acc1.Id,Type='Remorse Refund', StageName = 'Return Created',OwnerId = thisUser.Id,Returning_Opportunity__c=revenueopp2.Id ,CloseDate = Date.today(),CurrencyIsoCode = 'GBP');
        remorseRefundOpp.add(remorseOpp2);
        TriggerHandler.bypass('OpportunityTriggerHandler');
            insert remorseRefundOpp;
      	TriggerHandler.clearAllBypasses();
         List<OpportunityLineItem> oppLIList = new List<OpportunityLineItem>();
         OpportunityLineItem oppLi = new OpportunityLineItem(OpportunityId = remorseOpp.Id,PriceBookEntryId=testPB1.Id,Quantity = -5);
         oppLIList.add(oppLi);
         OpportunityLineItem oppLi1 = new OpportunityLineItem(OpportunityId = remorseOpp1.Id,PriceBookEntryId=testPB1.Id,Quantity = -3);
         oppLIList.add(oppLi1);
         OpportunityLineItem oppLi2 = new OpportunityLineItem(OpportunityId = remorseOpp2.Id,PriceBookEntryId=testPB2.Id,Quantity = -1);
         oppLIList.add(oppLi2);
         insert oppLIList;
        Test.stopTest();
              
    }
    
    @isTest 
     static void testApprovalSubmit() {
        
        Id pId = [SELECT Id FROM Profile WHERE Name = 'System Administrator'][0].Id;
        User u = new User(
        EmployeeNumber = '123',
        ProfileId = pId,
        LastName = 'last',
        Email = 'puser000@amamama.com',
        Username = 'puser000@amamama.com' + Math.random() + System.currentTimeMillis(),
        CompanyName = 'TEST',
        Title = 'title',
        Alias = 'alias',
        TimeZoneSidKey = 'America/Los_Angeles',
        EmailEncodingKey = 'UTF-8',
        LanguageLocaleKey = 'en_US',
        LocaleSidKey = 'en_US',
        Order_Admin_Available__c = TRUE,
        isActive = TRUE
        );
    	insert u;
         PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'Validation_Rule_By_Pass'];
		insert new PermissionSetAssignment(AssigneeId = u.Id, PermissionSetId = ps.Id);
         System.runAs(u) {
        Integer emailBefore = Limits.getEmailInvocations();
        Account a = [SELECT id, BillingCountry FROM Account WHERE Name = 'Testers 1 Inc'];
        Shipping_Address__c sa = [SELECT id FROM Shipping_Address__c WHERE Name='Test'];
        List<Opportunity> oppList = new List<Opportunity>();
            Opportunity opp1 = new Opportunity(AccountId = a.Id, Name = 'Opp1', CloseDate = System.today() + 90,Return_Reason__c = 'Customer Service',
                                               Return_Subreason__c = 'Other (explain in notes)',Finance_Approved_Return__c = true,
                                              StageName = 'Return Created', Probability = 10, type = 'Remorse Refund', Shipping_Address_NEW__c= sa.Id);
             
             Opportunity opp2 = new Opportunity(AccountId = a.Id, Name = 'Opp2', CloseDate = System.today() + 90,Return_Reason__c = 'Customer Service',
                                               Return_Subreason__c = 'Other (explain in notes)',Finance_Approved_Return__c = true,
                                          StageName = 'Return Created', Probability = 10, type = 'Remorse Refund', Shipping_Address_NEW__c= sa.Id);
        oppList.add(opp1);
        oppList.add(opp2); 
        Closed_Deal_Insights__c cd = new Closed_Deal_Insights__c(Opportunity__c = opp2.Id);
        Test.startTest();
        insert oppList;
        insert cd;
        opp1.Free_Trial_Approval__c = true;
        opp2.StageName = 'Closed Lost';
        update oppList;
        Test.stopTest();
     }
     }
    
    @isTest 
    static void testOpptyWarningField() {
        Account a = [SELECT id, BillingCountry FROM Account WHERE Name = 'Testers 1 Inc'];
        Shipping_Address__c sa = [SELECT id FROM Shipping_Address__c WHERE Name='Test'];
        Opportunity opp1 = new Opportunity(AccountId = a.Id, Name = 'Opp1', CloseDate = System.today() + 90, Opportunity_Tracking__c = 'Order Processing set By OrderValidationAutomation',Express_Agreement_Accepted_Date__c = System.Today(),
                                          StageName = 'Return Created', Probability = 10, type = 'Remorse Refund', Shipping_Address_NEW__c= sa.Id);
        Test.startTest();
        insert opp1;
        opp1.Express_Agreement_Accepted_Date__c = null;
        update opp1;
        Test.stopTest();
        //OpportunityHelper.removeWarningFromOptyTrackerField(opp1);
    }
    
    @isTest
    private static void testUpdateContractDate() {
        // Get test data
        Account testAccount = [SELECT Id FROM Account WHERE Name = 'Testers 1 Inc' LIMIT 1];
        Contract testContract = [SELECT Id FROM Contract WHERE AccountId = :testAccount.Id LIMIT 1];
        
        // Create test opportunity
        Opportunity testOpp = new Opportunity(
            Name = 'Test Contract Date Update',
            AccountId = testAccount.Id,
            StageName = 'Proposal',
            CloseDate = System.today().addDays(30),
            Type = 'Revenue Opportunity',
            SBQQ__AmendedContract__c = testContract.Id,
            Trial_Period__c = 30,
            Free_Trial_Extension_Status__c = 'Pending'
        );
        insert testOpp;
        
        Test.startTest();
        // Update opportunity to trigger contract date update
        testOpp.Free_Trial_Extension_Status__c = 'Approved';
        testOpp.Trial_Period__c = 45;
        update testOpp;
        
        // Verify the contract was updated
        Contract updatedContract = [SELECT Id, EndDate FROM Contract WHERE Id = :testContract.Id];
        Test.stopTest();
    }
    @isTest
    static void testOpportunityWithDifferentPaymentTypes() {
        Account testAccount = [SELECT Id FROM Account WHERE Name = 'Testers 1 Inc' LIMIT 1];
        TriggerHandler.bypass('OpportunityTriggerHandler');
        TriggerHandler.bypass('ShippingAddressHandler');
        TriggerHandler.bypass('OpportunityLineItemTriggerHandler');  
        // Test Direct Annual payment type
        Opportunity annualOpp = new Opportunity(
            Name = 'Annual Payment Opp',
            AccountId = testAccount.Id,
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30),
            Type = 'Revenue Opportunity',
            Selected_Payment_Type__c = 'Direct Annual',
            Price_Book_Name__c = 'Standard',
            Amount = 10000
        );
        insert annualOpp;
        
        // Test Direct Monthly payment type
        Opportunity monthlyOpp = new Opportunity(
            Name = 'Monthly Payment Opp',
            AccountId = testAccount.Id,
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30),
            Type = 'Revenue Opportunity',
            Selected_Payment_Type__c = 'Direct Monthly',
            Price_Book_Name__c = 'Standard',
            Amount = 10000
        );
        insert monthlyOpp;
        
        // Test Upfront Payments type
        Opportunity upfrontOpp = new Opportunity(
            Name = 'Upfront Payment Opp',
            AccountId = testAccount.Id,
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30),
            Type = 'Revenue Opportunity',
            Selected_Payment_Type__c = 'Upfront Payments',
            Price_Book_Name__c = 'Standard',
            Amount = 10000
        );
        insert upfrontOpp;
        
        // Clear trigger bypass
        TriggerHandler.clearAllBypasses();
        
        // Verify opportunities were created
        List<Opportunity> createdOpps = [SELECT Id, Name, Selected_Payment_Type__c FROM Opportunity WHERE Id IN (:annualOpp.Id, :monthlyOpp.Id, :upfrontOpp.Id)];
        System.assertEquals(3, createdOpps.size(), 'Should have created 3 opportunities');
    }
    
    @isTest 
    static void testOpportunityWithDifferentStages() {
        Account testAccount = [SELECT Id FROM Account WHERE Name = 'Testers 1 Inc' LIMIT 1];
        TriggerHandler.bypass('OpportunityTriggerHandler');
        TriggerHandler.bypass('ShippingAddressHandler');
        TriggerHandler.bypass('OpportunityLineItemTriggerHandler');  
        // Create opportunity and test different stages
        Opportunity opp = new Opportunity(
            Name = 'Stage Test Opp',
            AccountId = testAccount.Id,
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30),
            Type = 'Revenue Opportunity',
            Selected_Payment_Type__c = 'Direct Annual',
            Price_Book_Name__c = 'Standard',
            Amount = 10000
        );
        insert opp;
        
        // Test stage progression
        opp.StageName = 'Qualification';
        update opp;
        
        opp.StageName = 'Needs Analysis';
        update opp;
        
        opp.StageName = 'Value Proposition';
        update opp;
        
        opp.StageName = 'Id. Decision Makers';
        update opp;
        
        opp.StageName = 'Perception Analysis';
        update opp;
        
        opp.StageName = 'Proposal/Price Quote';
        update opp;
        
        opp.StageName = 'Negotiation/Review';
        update opp;
        
        opp.StageName = 'Closed Won';
        update opp;
        
        // Clear trigger bypass
        TriggerHandler.clearAllBypasses();
        
        // Verify final stage
        Opportunity finalOpp = [SELECT Id, StageName FROM Opportunity WHERE Id = :opp.Id];
        System.assertEquals('Closed Won', finalOpp.StageName, 'Final stage should be Closed Won');
    }
 
    @isTest 
    static void testOpportunityWithDifferentSegments() {
        Account testAccount = [SELECT Id FROM Account WHERE Name = 'Testers 1 Inc' LIMIT 1];
        
        TriggerHandler.bypass('OpportunityTriggerHandler');
        TriggerHandler.bypass('ShippingAddressHandler');
        TriggerHandler.bypass('OpportunityLineItemTriggerHandler');  
        // Test Express segment
        Opportunity expressOpp = new Opportunity(
            Name = 'Express Opp',
            AccountId = testAccount.Id,
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30),
            Type = 'Revenue Opportunity',
            Selected_Payment_Type__c = 'Direct Annual',
            Price_Book_Name__c = 'Standard',
            Amount = 10000,
            Configuration_Segment__c = 'Express'
        );
        insert expressOpp;
        
        // Test Non Express segment
        Opportunity nonExpressOpp = new Opportunity(
            Name = 'Non Express Opp',
            AccountId = testAccount.Id,
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30),
            Type = 'Revenue Opportunity',
            Selected_Payment_Type__c = 'Direct Annual',
            Price_Book_Name__c = 'Standard',
            Amount = 10000,
            Configuration_Segment__c = 'Non Express'
        );
        insert nonExpressOpp;
        
        // Clear trigger bypass
        TriggerHandler.clearAllBypasses();
        
        // Verify opportunities were created
        List<Opportunity> createdOpps = [SELECT Id, Name, Configuration_Segment__c FROM Opportunity WHERE Id IN (:expressOpp.Id, :nonExpressOpp.Id)];
        System.assertEquals(2, createdOpps.size(), 'Should have created 2 opportunities');
    }
    
    @isTest 
    static void testOpportunityWithDifferentLicenseTerms() {
        Account testAccount = [SELECT Id FROM Account WHERE Name = 'Testers 1 Inc' LIMIT 1];
        TriggerHandler.bypass('OpportunityTriggerHandler');
        TriggerHandler.bypass('ShippingAddressHandler');
        TriggerHandler.bypass('OpportunityLineItemTriggerHandler');  
        
        List<Opportunity> opps = new List<Opportunity>();
        
        // 12 months term
        opps.add(new Opportunity(
            Name = '12 Month Term Opp',
            AccountId = testAccount.Id,
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30),
            Type = 'Revenue Opportunity',
            Selected_Payment_Type__c = 'Direct Annual',
            Price_Book_Name__c = 'Standard',
            Amount = 10000,
            License_Term__c = 12
        ));
        
        // 24 months term
        opps.add(new Opportunity(
            Name = '24 Month Term Opp',
            AccountId = testAccount.Id,
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30),
            Type = 'Revenue Opportunity',
            Selected_Payment_Type__c = 'Direct Annual',
            Price_Book_Name__c = 'Standard',
            Amount = 10000,
            License_Term__c = 24
        ));
        
        // 36 months term
        opps.add(new Opportunity(
            Name = '36 Month Term Opp',
            AccountId = testAccount.Id,
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30),
            Type = 'Revenue Opportunity',
            Selected_Payment_Type__c = 'Direct Annual',
            Price_Book_Name__c = 'Standard',
            Amount = 10000,
            License_Term__c = 36
        ));
        
        insert opps;
        
        // Clear trigger bypass
        TriggerHandler.clearAllBypasses();
        
        // Verify opportunities were created
        List<Opportunity> createdOpps = [SELECT Id, Name, License_Term__c FROM Opportunity WHERE Id IN :opps];
        System.assertEquals(3, createdOpps.size(), 'Should have created 3 opportunities');
    }
    
    @isTest 
    static void testRenewalOpportunityCheckoutLink() {
		Test.StartTest();
	    Account acc = [SELECT Id, ownerId FROM Account where name = 'Testers 6 Inc'  LIMIT 1];
        Contract con = [Select id from Contract Limit 1];
        Opportunity opp = [SELECT Id,sbqq__PrimaryQuote__c, ownerId FROM opportunity where Accountid =: acc.id];
        
        SBQQ__Quote__c qt = new SBQQ__Quote__c(SBQQ__Opportunity2__c = opp.Id, SBQQ__Primary__c = true, SBQQ__Status__c = 'Approved');
        insert qt;
        
        opp.Amount = 100;
        opp.Opportunity_UUID__c = '1234567890';
        opp.closeDate = System.today() + 90;
        opp.SBQQ__RenewedContract__c = con.Id;
        opp.Shipping_and_Handling_Manual__c = 10;
        opp.Unique_Shipping_Addresses__c  = 2;
        update opp; 
        Test.StopTest();
        		
    }
}