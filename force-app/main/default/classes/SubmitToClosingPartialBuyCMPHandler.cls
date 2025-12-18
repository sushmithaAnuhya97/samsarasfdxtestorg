public without sharing class SubmitToClosingPartialBuyCMPHandler {
    	
     @AuraEnabled
    public static String saveCSVToOpportunity(String csvData, String opportunityId) {
        try {
            // Create ContentVersion
            String fileName = Label.Submit_To_Closing_Partial_Buy_CSV_File_Name;
            ContentVersion contentVersion = new ContentVersion();
            contentVersion.Title = fileName;
            contentVersion.PathOnClient = fileName;
            contentVersion.VersionData = EncodingUtil.base64Decode(csvData);
            insert contentVersion;

            // Query ContentDocumentId
            ContentDocumentLink contentDocumentLink = new ContentDocumentLink();
            contentDocumentLink.ContentDocumentId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :contentVersion.Id].ContentDocumentId;
            contentDocumentLink.LinkedEntityId = opportunityId;
            contentDocumentLink.ShareType = 'V'; // Viewer access
            insert contentDocumentLink;

            return 'SUCCESS';
        } catch (Exception ex) {
            throw new AuraHandledException('Error saving CSV to Opportunity: ' + ex.getMessage());
        }
    }
    
      @AuraEnabled(cacheable=true)
    public static String getDocument(String opportunityId) {
        try {
            String fileName = Label.Submit_To_Closing_Partial_Buy_CSV_File_Name;
            
            List<ContentDocumentLink> documentLinks = [
                SELECT ContentDocumentId 
                FROM ContentDocumentLink 
                WHERE LinkedEntityId = :opportunityId 
                AND ContentDocument.Title = :fileName
            ];
            
            // If a document exists, retrieve the ContentDocument record
            if (!documentLinks.isEmpty()) {
                Id contentDocumentId = documentLinks[0].ContentDocumentId;
                ContentDocument document = [SELECT Id, Title, ContentSize, CreatedDate 
                                            FROM ContentDocument 
                                            WHERE Id = :contentDocumentId LIMIT 1];
                
                // Fetch the ContentVersion (which contains the file content)
                ContentVersion contentVersion = [
                    SELECT VersionData, Title
                    FROM ContentVersion
                    WHERE ContentDocumentId = :contentDocumentId
                    LIMIT 1
                ];

                // Convert the VersionData (Blob) to Base64 string
                String base64Content = EncodingUtil.base64Encode(contentVersion.VersionData);
                return base64Content;
            } else {
                return null; // Return null if no document found
            }
        } catch (Exception ex) {
            throw new AuraHandledException('Error retrieving document: ' + ex.getMessage());
        }
    }
        
    @AuraEnabled
    public static Boolean deleteDocument(String opportunityId) {
        try {
            String fileName = Label.Submit_To_Closing_Partial_Buy_CSV_File_Name;
    
            // Query ContentDocumentLink and related ContentDocument
            List<ContentDocumentLink> documentLinks = [
                SELECT Id, ContentDocumentId 
                FROM ContentDocumentLink 
                WHERE LinkedEntityId = :opportunityId 
                AND ContentDocument.Title = :fileName
            ];
    
            if (!documentLinks.isEmpty()) {
                List<ContentDocument> documentsToDelete = new List<ContentDocument>();
    
                for (ContentDocumentLink docLink : documentLinks) {
                    documentsToDelete.add(new ContentDocument(Id = docLink.ContentDocumentId));
                }
    
                delete documentsToDelete;
    
                return true; // Return true if the document is successfully deleted
            } else {
                return false; // No document found to delete
            }
        } catch (Exception ex) {
            throw new AuraHandledException('Error deleting document: ' + ex.getMessage());
        }
    }
    

}