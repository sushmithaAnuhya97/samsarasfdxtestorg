@IsTest
public class SubmitToClosingPartialBuyCMPHandlerTest {
    @IsTest
    static void testSaveCSVToOpportunity() {
        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30)
        );
        insert opp;

        String csvData = 'Name,Amount,CloseDate\nTest Opp,1000,' + Date.today().format();
        String encodedCsvData = EncodingUtil.base64Encode(Blob.valueOf(csvData));

        Test.startTest();
        String result = SubmitToClosingPartialBuyCMPHandler.saveCSVToOpportunity(encodedCsvData, opp.Id);
        Test.stopTest();

        ContentVersion contentVersion = [
            SELECT Id, Title, ContentDocumentId
            FROM ContentVersion
            WHERE Title = :Label.Submit_To_Closing_Partial_Buy_CSV_File_Name
            LIMIT 1
        ];

        ContentDocumentLink contentDocumentLink = [
            SELECT Id, LinkedEntityId, ShareType
            FROM ContentDocumentLink
            WHERE LinkedEntityId = :opp.Id
            LIMIT 1
        ];
    }

    @IsTest
    static void testGetDocument() {
        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30)
        );
        insert opp;

        String fileName = Label.Submit_To_Closing_Partial_Buy_CSV_File_Name;
        ContentVersion contentVersion = new ContentVersion(
            Title = fileName,
            PathOnClient = fileName,
            VersionData = Blob.valueOf('Test Data')
        );
        insert contentVersion;

        ContentDocumentLink contentDocumentLink = new ContentDocumentLink(
            ContentDocumentId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :contentVersion.Id].ContentDocumentId,
            LinkedEntityId = opp.Id,
            ShareType = 'V'
        );
        insert contentDocumentLink;

        Test.startTest();
        String documentContent = SubmitToClosingPartialBuyCMPHandler.getDocument(opp.Id);
        Test.stopTest();

    }

    @IsTest
    static void testDeleteDocument() {
        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30)
        );
        insert opp;

        String fileName = Label.Submit_To_Closing_Partial_Buy_CSV_File_Name;
        ContentVersion contentVersion = new ContentVersion(
            Title = fileName,
            PathOnClient = fileName,
            VersionData = Blob.valueOf('Test Data')
        );
        insert contentVersion;

        ContentDocumentLink contentDocumentLink = new ContentDocumentLink(
            ContentDocumentId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :contentVersion.Id].ContentDocumentId,
            LinkedEntityId = opp.Id,
            ShareType = 'V'
        );
        insert contentDocumentLink;

        Test.startTest();
        Boolean deleted = SubmitToClosingPartialBuyCMPHandler.deleteDocument(opp.Id);
        Test.stopTest();

        List<ContentDocumentLink> remainingLinks = [
            SELECT Id
            FROM ContentDocumentLink
            WHERE LinkedEntityId = :opp.Id
        ];

        List<ContentDocument> remainingDocuments = [
            SELECT Id
            FROM ContentDocument
            WHERE Id = :contentDocumentLink.ContentDocumentId
        ];
    }
}