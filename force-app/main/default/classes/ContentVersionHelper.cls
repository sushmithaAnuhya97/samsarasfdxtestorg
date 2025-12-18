public class ContentVersionHelper {
    private static List<Content_Version_Sync__e> contentEvents = new List<Content_Version_Sync__e>();

    public static void syncContentVersion(List<ContentVersion> contentVersions, Map<Id, ContentVersion > contentVersionsMap) {
        string startsWith = system.Label.ExtractResellerInfoFileStartsWith; 
        string fromObject = system.Label.ExtractResellerInfoFromObject;
        string docusignUser = system.Label.DocusignUser;
        for (ContentVersion cv : contentVersions) {
            string objIdentifier = null;
            string eventType=null;
            if (cv.FirstPublishLocationId!=null) {
                string fpLocation = cv.FirstPublishLocationId;
                objIdentifier = fpLocation.substring(0,3);
                
                eventType = (docusignUser.containsIgnoreCase(cv.FirstPublishLocationId)) ? 'Docusign Generated Form' : 'Vendor PO Attachment' ;
            }
            
            if (cv.ContentDocumentId!=null && cv.FirstPublishLocationId!=null && cv.Title!=null && objIdentifier!=null && startsWith!=null
                && cv.FileType!=null && cv.FileType.equalsIgnoreCase ('PDF')
                && ( (cv.Title.startsWithIgnoreCase(startsWith) && fromObject!=null && fromObject.containsIgnoreCase(objIdentifier))
                    //|| (!cv.Title.startsWithIgnoreCase('Certificate') && eventType=='Docusign Generated Form')
                    )
               ) 
            {
                contentEvents.add(new Content_Version_Sync__e(Content_Document_Id__c = cv.ContentDocumentId, Object_Id__c=cv.FirstPublishLocationId
                                                              , Event_Type__c=eventType));
            }
                
        }
        
        if(contentEvents.size() > 0){
            List<Database.SaveResult> results = EventBus.publish(contentEvents);
        }
    }
}