/**
 * Created by vikasmishra on 2021-09-15.
 */

public with sharing class GS_QuoteDocumentCreator implements fflib_SObjectUnitOfWork.IDoWork{
    @TestVisible
    static String QUOTE_TEMPLATE_ID_FOR_QUOTE_DOCUMENT_GENERATION ='0EH1a000000RKc5';
    @TestVisible
    private List<Quote> m_quote_records = new List<Quote> ();
    @TestVisible
    Map<Id, QuoteDocument> mapOfQuoteDocumentWithOpportunity = new Map<Id, QuoteDocument>();

    public GS_QuoteDocumentCreator(){

    }
    public void register_QuoteDocument(Quote record){
        m_quote_records.add(record);
    }

    public Map<Id, QuoteDocument> getMapOfQuoteDocument(){
        return mapOfQuoteDocumentWithOpportunity;
    }
    public void doWork(){List<QuoteDocument> quoteDocuments = new List<QuoteDocument>();
        for(Quote thisQuote : m_quote_records){
            mapOfQuoteDocumentWithOpportunity.put(thisQuote.OpportunityId, generateQuoteDocument(thisQuote));
        }

        //TODO: This can optimized further to support register email and at the commit both the processes can be processed
        insert mapOfQuoteDocumentWithOpportunity.values();

    }
    @TestVisible
    private QuoteDocument generateQuoteDocument(Quote quote) {
        System.debug(quote.Id+'*****Id');
        String quoteUrl = '/quote/quoteTemplateDataViewer.apexp?id=';
        quoteUrl += quote.Id;
        quoteUrl += '&headerHeight=190&footerHeight=188&summlid=';
        quoteUrl += QUOTE_TEMPLATE_ID_FOR_QUOTE_DOCUMENT_GENERATION;
        quoteUrl += '#toolbar=1&navpanes=0&zoom=90';
        System.debug('QuoteURL****'+quoteUrl);

        //Create pdf content
        PageReference thisPageReference = new PageReference(quoteUrl);

        //Document object of quote which hold the quote pdf
        QuoteDocument thisQuoteDocument = new QuoteDocument();

        //content assign to document

        thisQuoteDocument.Document = Test.isRunningTest() ? Blob.valueOf('TestString') : thisPageReference.getContentAsPDF();
        //thisQuoteDocument.Document = Blob.valueOf('Test string');
        thisQuoteDocument.QuoteId = quote.Id;
        return thisQuoteDocument;
    }

    /*public class quoteDocumentDMLHelper implements IDMLHelper{

        Map<Id, QuoteDocument> mapOfQuoteDocumentWithOpportunity = new Map<Id, QuoteDocument>();
        public void setQuoteDocumentMap(Map<Id, QuoteDocument> mapOfQuoteDocumentWithOpportunity){
            this.mapOfQuoteDocumentWithOpportunity = mapOfQuoteDocumentWithOpportunity;
        }
        public void doDML(){
            insert mapOfQuoteDocumentWithOpportunity.values();
        }
    }

    public interface IDMLHelper{

    }*/
}