@isTest
public class TestFactory {

    public static SObject createSObject(SObject sObj) {
        // Check what type of object we are creating and add any defaults that are needed.
        String objectName = String.valueOf(sObj.getSObjectType());
        // Construct the default values class. Salesforce doesn't allow '__' in class names
        String defaultClassName = 'TestFactory.' + objectName.replaceAll('__(c|C)$|__', '') + 'Defaults';
        // If there is a class that exists for the default values, then use them
        if (Type.forName(defaultClassName) != null) {
            sObj = createSObject(sObj, defaultClassName);
        }
        return sObj;
    }

    public static SObject createSObject(SObject sObj, Boolean doInsert) {
        SObject retObject = createSObject(sObj);
        if (doInsert) {
            insert retObject;
        }
        return retObject;
    }

    public static SObject createSObject(SObject sObj, String defaultClassName) {
        // Create an instance of the defaults class so we can get the Map of field defaults
        Type t = Type.forName(defaultClassName);
        if (t == null) {
            Throw new TestFactoryException('Invalid defaults class.');
        }
        FieldDefaults defaults = (FieldDefaults) t.newInstance();
        addFieldDefaults(sObj, defaults.getFieldDefaults());
        return sObj;
    }

    public static SObject createSObject(SObject sObj, String defaultClassName, Boolean doInsert) {
        SObject retObject = createSObject(sObj, defaultClassName);
        if (doInsert) {
            insert retObject;
        }
        return retObject;
    }

    public static SObject[] createSObjectList(Sobject sObj, Integer numberOfObjects) {
        return createSObjectList(sObj, numberOfObjects, (String) null);
    }

    public static SObject[] createSObjectList(SObject sObj, Integer numberOfObjects, Boolean doInsert) {
        SObject[] retList = createSObjectList(sObj, numberOfObjects, (String) null);
        if (doInsert) {
            insert retList;
        }
        return retList;
    }

    public static SObject[] createSObjectList(SObject sObj, Integer numberOfObjects, String defaultClassName, Boolean doInsert) {
        SObject[] retList = createSObjectList(sObj, numberOfObjects, defaultClassName);
        if (doInsert) {
            insert retList;
        }
        return retList;
    }

    public static SObject[] createSObjectList(Sobject sObj, Integer numberOfObjects, String defaultClassName) {
        SObject[] sObjs = new SObject[]{
        };
        SObject newObj;

        // Get one copy of the object
        if (defaultClassName == null) {
            newObj = createSObject(sObj);
        } else {
            newObj = createSObject(sObj, defaultClassName);
        }

        // Get the name field for the object
        String nameField = nameFieldMap.get(String.valueOf(sObj.getSObjectType()));
        if (nameField == null) {
            nameField = 'Name';
        }

        // Clone the object the number of times requested. Increment the name field so each record is unique
        for (Integer i = 0; i < numberOfObjects; i++) {
            SObject clonedSObj = newObj.clone(false, true);
            clonedSObj.put(nameField, (String) clonedSObj.get(nameField) + ' ' + i);
            sObjs.add(clonedSObj);
        }
        return sObjs;
    }

    private static void addFieldDefaults(SObject sObj, Map<Schema.SObjectField, Object> defaults) {
        // Loop through the map of fields and if they weren't specifically assigned, fill them.
        Map<String, Object> populatedFields = sObj.getPopulatedFieldsAsMap();
        for (Schema.SObjectField field : defaults.keySet()) {
            if (!populatedFields.containsKey(String.valueOf(field))) {
                sObj.put(field, defaults.get(field));
            }
        }
    }

    // When we create a list of SObjects, we need to
    private static Map<String, String> nameFieldMap = new Map<String, String>{
            'Contact' => 'LastName',
            'Case' => 'Subject'
    };

    public class TestFactoryException extends Exception {
    }

    // Use the FieldDefaults interface to set up values you want to default in for all objects.
    public interface FieldDefaults {
        Map<Schema.SObjectField, Object> getFieldDefaults();
    }

    // To specify defaults for objects, use the naming convention [ObjectName]Defaults.
    // For custom objects, omit the __c from the Object Name

    public class AccountDefaults implements FieldDefaults {
        public Map<Schema.SObjectField, Object> getFieldDefaults() {
            return new Map<Schema.SObjectField, Object>{
                    Account.Name => 'Test Account',
                    Account.Organization_Size__c => '100 - 499',
                    Account.BillingCountry => 'United States',
                    Account.BillingState => 'California'
            };
        }
    }

    public class ContactDefaults implements FieldDefaults {
        public Map<Schema.SObjectField, Object> getFieldDefaults() {
            return new Map<Schema.SObjectField, Object>{
                    Contact.FirstName => 'First',
                    Contact.LastName => 'Last',
                    Contact.Email => 'test@test.com'
            };
        }
    }

    public class OpportunityDefaults implements FieldDefaults {
        public Map<Schema.SObjectField, Object> getFieldDefaults() {
            return new Map<Schema.SObjectField, Object>{
                    Opportunity.Name => 'Test Opportunity - ' + generateRandomString(5),
                    Opportunity.StageName => 'Incubate',
                    Opportunity.Amount => 10000.00,
                    Opportunity.CloseDate => System.today()
            };
        }
    }

    public class CaseDefaults implements FieldDefaults {
        public Map<Schema.SObjectField, Object> getFieldDefaults() {
            return new Map<Schema.SObjectField, Object>{
                    Case.Subject => 'Test Case'
            };
        }
    }

    public class Pricebook2Defaults implements FieldDefaults {
        public Map<Schema.SObjectField, Object> getFieldDefaults() {
            return new Map<Schema.SObjectField, Object>{
                    Pricebook2.Name => 'Samsara Standard',
                    Pricebook2.IsActive => TRUE
            };
        }
    }

    public class Product2Defaults implements FieldDefaults {
        public Map<Schema.SObjectField, Object> getFieldDefaults() {
            return new Map<Schema.SObjectField, Object>{
                    Product2.Name => 'Test Product',
                    Product2.ProductCode => String.join(new List<String>{
                            TestFactory.generateRandomString(4),
                            TestFactory.generateRandomString(4),
                            TestFactory.generateRandomString(4)
                    }, '-')
            };
        }
    }

    public class PricebookEntryDefaults implements FieldDefaults {
        public Map<Schema.SObjectField, Object> getFieldDefaults() {
            return new Map<Schema.SObjectField, Object>{
                    PricebookEntry.UnitPrice => 100.00,
                    PricebookEntry.IsActive => true,
                    PricebookEntry.Pricebook2Id => Test.getStandardPricebookId()
            };
        }
    }

    public class OpportunityLineItemDefaults implements FieldDefaults {
        public Map<Schema.SObjectField, Object> getFieldDefaults() {
            return new Map<Schema.SObjectField, Object>{
                    OpportunityLineItem.UnitPrice => 100.00,
                    OpportunityLineItem.Quantity => 1
            };
        }
    }

    public class QuotaDefaults implements FieldDefaults {
        public Map<Schema.SObjectField, Object> getFieldDefaults() {
            return new Map<Schema.SObjectField, Object>{
                    Quota__c.Role_at_Start_of_Fiscal_Period__c => 'My Role',
                    Quota__c.User__c => UserInfo.getUserId(),
                    Quota__c.CurrencyIsoCode => 'USD',
                    Quota__c.Quota__c => 8000,
                    Quota__c.Quota_Period_End_Date__c => Date.Today() + 4,
                    Quota__c.Quota_Period_Start_Date__c => Date.Today() - 4,
                    Quota__c.Fiscal_Period_End_Date__c => Date.Today() + 4,
                    Quota__c.Fiscal_Period_Start_Date__c => Date.Today() - 4,
                    Quota__c.Quota_Period__c => 'Test',
                    Quota__c.Fiscal_Period__c => 'Test'
            };
        }
    }

    /**
    * @author Groundswell - Vikasm - vikas@gscloudsolutions.com
    * @date 2020-08-26
    * Not yet deployed for Production
    */
    public static Account initializeAccount(String prefix) {
        Map<Schema.SObjectField, Object> accountDefaultFieldmap = new Map<Schema.SObjectField, Object>();
        AccountDefaults accountdefault = new AccountDefaults();
        accountDefaultFieldmap = accountdefault.getFieldDefaults();
        Account thisAccount = new Account();
        thisAccount.Name = prefix + ' ' + String.valueOf(accountDefaultFieldmap.get(Account.Name));
        thisAccount.Organization_Size__c = (String) accountDefaultFieldmap.get(Account.Organization_Size__c);
        thisAccount.BillingCountry = (String) accountDefaultFieldmap.get(Account.BillingCountry);
        thisAccount.BillingState = (String) accountDefaultFieldmap.get(Account.BillingState);
        return thisAccount;
    }

    /**
    * @author Groundswell - Vikasm - vikas@gscloudsolutions.com
    * @date 2020-08-26
    * Not yet deployed for Production
    */
    public static Opportunity initializeOpportunity(String Prefix) {
        Map<Schema.SObjectField, Object> opportunityDefaultFieldmap = new Map<Schema.SObjectField, Object>();
        OpportunityDefaults OpportunityDefaults = new OpportunityDefaults();
        opportunityDefaultFieldmap = OpportunityDefaults.getFieldDefaults();
        Opportunity thisOpportunity = new Opportunity();
        thisOpportunity.Name = prefix + ' ' + String.valueOf(opportunityDefaultFieldmap.get(Opportunity.Name));
        thisOpportunity.StageName = String.valueOf(opportunityDefaultFieldmap.get(Opportunity.StageName));
        thisOpportunity.Amount = (Decimal) opportunityDefaultFieldmap.get(Opportunity.Amount);
        thisOpportunity.CloseDate = (Date) opportunityDefaultFieldmap.get(Opportunity.CloseDate);
        return thisOpportunity;
    }

    /**
    * @author Groundswell - Vikasm - vikas@gscloudsolutions.com
    * @date 2020-08-26
    * Not yet deployed for Production
    */
    public static Contact initializeContact(String prefix) {
        Map<Schema.SObjectField, Object> contactDefaultFieldmap = new Map<Schema.SObjectField, Object>();
        ContactDefaults contactDefaults = new ContactDefaults();
        contactDefaultFieldmap = contactDefaults.getFieldDefaults();
        Contact thisContact = new Contact();
        thisContact.FirstName = prefix + ' ' + String.valueOf(contactDefaultFieldmap.get(Contact.FirstName));
        thisContact.LastName = (String) contactDefaultFieldmap.get(Contact.LastName);
        thisContact.Email = (String) contactDefaultFieldmap.get(Contact.Email);
        return thisContact;
    }

    private static String generateRandomString(Integer len) {
        final String chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmnopqrstuvwxyz';
        String randStr = '';
        while (randStr.length() < len) {
            Long randomLong = Crypto.getRandomLong();
            // Convert to positive Integer safely
            Integer idx = Math.mod(Math.abs(randomLong.intValue()), chars.length());
            randStr += chars.substring(idx, idx + 1);
        }
        return randStr;
    }

    private static Integer fakeIdCount = 1;
    public static Id getFakeId(Schema.SObjectType sot) {
        String result = String.valueOf(fakeIdCount++);
        String generatedId = sot.getDescribe().getKeyPrefix() +
                '0'.repeat(12 - result.length()) + result;
        return Id.valueOf(generatedId);
    }
}