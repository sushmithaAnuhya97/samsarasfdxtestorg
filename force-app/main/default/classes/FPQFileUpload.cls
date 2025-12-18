public without sharing class FPQFileUpload {
    @AuraEnabled
    public static Boolean checkAlreadyUploaded(Id parentId){
        Finance_Partner_Quote__c fpq = new Finance_Partner_Quote__c();
        fpq = [Select Id,Documents_Uploaded__c from Finance_Partner_Quote__c where Id =: parentId limit 1];
        if(fpq.Documents_Uploaded__c == true){
            return true;
        }
        else{
            return false;
        }
    }
    
   @AuraEnabled
    public static Id saveFile(Id parentId, String fileName, String base64Data, String contentType, String fileId) {
        // check if fileId id ''(Always blank in first chunk), then call the saveTheFile method,
        //  which is save the check data and return the attachemnt Id after insert,
        //  next time (in else) we are call the appentTOFile() method
        //   for update the attachment with remains chunks
        if (fileId == '') {
            fileId = saveTheFile(parentId, fileName, base64Data, contentType);
        } else {
            appendToFile(fileId, base64Data);
        }
         Finance_Partner_Quote__c fpq = new Finance_Partner_Quote__c();
        fpq = [Select Id,Documents_Uploaded__c from Finance_Partner_Quote__c where Id =: parentId limit 1];
        fpq.Documents_Uploaded__c = true;
        fpq.Financing_Decision__c = 'Pending - Under Partner Review';
        update fpq;
        return Id.valueOf(fileId);
    }
    
    public static Id saveTheFile(Id parentId, String fileName, String base64Data, String contentType) {
        base64Data = EncodingUtil.urlDecode(base64Data, 'UTF-8');
        
        Attachment oAttachment = new Attachment();
        oAttachment.parentId = parentId;
        
        oAttachment.Body = EncodingUtil.base64Decode(base64Data);
        oAttachment.Name = fileName;
        oAttachment.ContentType = contentType;
        
        insert oAttachment;        
        return oAttachment.Id;
    }
    
    @testVisible
    private static void appendToFile(Id fileId, String base64Data) {
        base64Data = EncodingUtil.urlDecode(base64Data, 'UTF-8');        
        Attachment a = [
            SELECT Id, Body
            FROM Attachment
            WHERE Id = : fileId
        ];
        
        String existingBody = EncodingUtil.base64Encode(a.Body);        
        a.Body = EncodingUtil.base64Decode(existingBody + base64Data);        
        update a;
    }
}