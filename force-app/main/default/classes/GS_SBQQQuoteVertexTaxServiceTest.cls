@IsTest
public without sharing class GS_SBQQQuoteVertexTaxServiceTest {

    /* @TestSetup
    static void setup(){
        insert new Global_Automation_Settings__c(Allow_Handler_Selection__c = true);

        Id pricebookId = Test.getStandardPricebookId();
        Pricebook2 standardPricebook = new Pricebook2(
            Id = Test.getStandardPricebookId(),
            Name = 'Standard Price Book',
            IsActive = true
        );
        Update standardPricebook;
        
    } */

    private static Id addressId;
    private static SBQQ__Quote__c quote;
    private static SBQQ__Quote__c oldQuote;
    private static SBQQ__QuoteLine__c quoteLine;

    private static void createScenario(){
        addressId = TestFactory.getFakeId(Shipping_Address__c.SObjectType);
        quote = (SBQQ__Quote__c) TestFactory.createSObject(new SBQQ__Quote__c(
            Id = TestFactory.getFakeId(SBQQ__Quote__c.SObjectType),
            SBQQ__Account__c = TestFactory.getFakeId(Account.SObjectType),
            Shipping_Address_NEW__c = addressId,
            VertexCPQ__Tax_Amount__c = 10,
            SBQQ__LastSavedOn__c = System.now(),
            SBQQ__LastCalculatedOn__c = System.now()
        ));

        quoteLine = (SBQQ__QuoteLine__c) TestFactory.createSObject(new SBQQ__QuoteLine__c(
            Id = TestFactory.getFakeId(SBQQ__QuoteLine__c.SObjectType),
            SBQQ__Quote__c = quote.Id
        ));

        oldQuote = quote.clone(true);
        oldQuote.SBQQ__LastSavedOn__c = System.now().addHours(-1);

        GS_SBQQQuoteVertexTaxService.callVertexManually = true;
    }

    @IsTest
    static void VertexTax_success(){

        createScenario();
        
        quoteLine = (SBQQ__QuoteLine__c) setFieldArbitrarily(quoteLine, new Map<String, String>{'SBQQ__NetTotal__c' => '0.00'}, SBQQ__QuoteLine__c.class);
        
        Test.startTest();

        GS_SBQQQuoteVertexTaxService.TEST_OVERRIDE_QL_MAP = new Map<Id, List<SBQQ__QuoteLine__c>>{
            quote.Id => new List<SBQQ__QuoteLine__c>{quoteLine}
        };

        (new GS_SBQQQuoteVertexTaxService()).run(
            new Map<Id, SBQQ__Quote__c>{
                quote.Id => quote
            },
            new Map<Id, SBQQ__Quote__c>{
                oldQuote.Id => oldQuote
            },
            new Map<Id, SBQQ__Quote__c>()
        );

        System.assertEquals(PopulateTaxes.STATUS_TAX_CALCULATION_REFRESH, quote.Tax_Calculation_Status__c);
        System.assertEquals('', quote.VertexCPQ__Tax_Status__c);
        System.assertEquals(10, quote.VertexCPQ__Tax_Amount__c);
        Test.stopTest();
        // For coverage
        GS_SBQQQuoteVertexTaxService.callVertex();
    }

    @IsTest
    static void VertexTax_error(){

        createScenario();
        
        quote.Shipping_Address_NEW__c = null;

        Test.startTest();

        GS_SBQQQuoteVertexTaxService.TEST_OVERRIDE_QL_MAP = new Map<Id, List<SBQQ__QuoteLine__c>>{
            quote.Id => new List<SBQQ__QuoteLine__c>{quoteLine}
        };

        (new GS_SBQQQuoteVertexTaxService()).run(
            new Map<Id, SBQQ__Quote__c>{
                quote.Id => quote
            },
            new Map<Id, SBQQ__Quote__c>{
                oldQuote.Id => oldQuote
            },
            new Map<Id, SBQQ__Quote__c>()
        );

        String expectedErrorMessage =
            Label.Vertex_Missing_Shipping_Address_error
        +   GS_SBQQQuoteVertexTaxService.STATUS_VERTEX_ERROR_SEPARATOR
        +   Label.Vertex_Null_Line_Net_Total_error;
        
        System.assertEquals(PopulateTaxes.STATUS_TAX_CALCULATION_VALIDATION, quote.Tax_Calculation_Status__c);
        System.assertEquals(expectedErrorMessage, quote.VertexCPQ__Tax_Status__c);
        System.assertEquals(null, quote.VertexCPQ__Tax_Amount__c);
        Test.stopTest();
    }

    // This method is expected to be used only for strings, so no other types are supported
    public static SObject replaceFieldArbitrarily(SObject obj, Map<String, String> valueList, System.Type deserializeType){
        String serializedRecord = JSON.serialize(obj);
        for (String field : valueList.keySet()){
            serializedRecord = serializedRecord.replaceAll('"'+field+'"\\s*:\\s*"[^"]+"', '"'+field+'":"'+valueList.get(field)+'"');
        }

        return (SObject) JSON.deserialize(serializedRecord, deserializeType);
    }

    // Simply appends fields to the JSON before deserializing it. You must provide the quotation marks if your variable type needs it, and no lists are supported.
    public static SObject setFieldArbitrarily(SObject obj, Map<String, String> valueList, System.Type deserializeType){
        String serializedRecord = JSON.serialize(obj).removeEnd('}');
        for (String field : valueList.keySet()){
            serializedRecord += ',"'+field+'":'+valueList.get(field);
        }

        return (SObject) JSON.deserialize(serializedRecord+'}', deserializeType);
    }
}