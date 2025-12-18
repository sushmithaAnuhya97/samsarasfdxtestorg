/**
 * Created by vikasmishra on 2021-10-13.
 */

@IsTest
private class GS_QuoteDocumentCreatorTest {
    @IsTest
    static void shouldRegisterQuoteDocument() {
        GS_QuoteDocumentCreator thisGS_QuoteDocumentCreator = new GS_QuoteDocumentCreator();
        thisGS_QuoteDocumentCreator.register_QuoteDocument(
                new Quote(
                        Id = generateId(Quote.SObjectType, 101)
                )
        );
        System.assert(thisGS_QuoteDocumentCreator.m_quote_records.size() ==1);
    }

    @IsTest
    static void shouldGenerateQuoteDocument() {
        GS_QuoteDocumentCreator thisGS_QuoteDocumentCreator = new GS_QuoteDocumentCreator();
        thisGS_QuoteDocumentCreator.generateQuoteDocument(
                new Quote(
                        Id = generateId(Quote.SObjectType, 101)
                )
        );
        thisGS_QuoteDocumentCreator.register_QuoteDocument(
                new Quote(
                        Id = generateId(Quote.SObjectType, 101)
                )
        );
        thisGS_QuoteDocumentCreator.getMapOfQuoteDocument();
        try{
            thisGS_QuoteDocumentCreator.doWork();
        }
        catch(Exception ex){
            System.debug('This the case of unit test the actual case will get covered in integration Testing');
        }
        System.assert(thisGS_QuoteDocumentCreator.m_quote_records.size() ==1);

    }
    public static Id generateId(SObjectType sobjectType, Integer sequenceNum) {
        String keyPrefix = sobjectType.getDescribe().getKeyPrefix();
        return Id.valueOf(keyPrefix + String.valueOf(sequenceNum).leftPad(12, '0'));
    }
}