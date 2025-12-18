public class EmailAlert {
    @AuraEnabled public String alertName   { get; set; }
    @AuraEnabled public List<String> recipient   = new List<String>();
    @AuraEnabled public String relRecordId { get; set; }
    @AuraEnabled public String templateId  { get; set; }
    @AuraEnabled public String ccAddress { get; set; }
    @AuraEnabled public String bccAddress { get; set; }
    @AuraEnabled public String fromAddress { get; set; }
    @AuraEnabled public String AlertType { get; set; }
    @AuraEnabled public String recipientId { get; set; }
    @AuraEnabled public String opportunityId{ get; set; }
    @AuraEnabled public String senderType { get; set; }
}