/****************************************************************************************************************
 * @Test class: FlexAccountCancelReplaceControllerTest
* Date      	- Project#     - Developer/ Company      	   - Description
* ---------------------------------------------------------------------------------------------------------------
* 01/06/2025    - Flex         - Anas Siddiquee/ Accenture 	   - Message wrapper for amendment request								
*/

public with sharing class FlexAmendContractsMsg {
    @AuraEnabled public List<String> contractIds {get; set;}
    @AuraEnabled public String startDate {get; set;}
    @AuraEnabled public String accountId {get; set;}
    @AuraEnabled public Integer termLength {get; set;}
    @AuraEnabled public Boolean isRebook {get; set;}
    @AuraEnabled public String endDate {get; set;}
    public Boolean originalAccountFlag {get; set;}
    // @AuraEnabled
    // public String quoteLineData {get; set;}
    @AuraEnabled
    public List<ProductWrapper> quoteLineData {get; set;}
    @AuraEnabled
    public String configData {get; set;}
    @AuraEnabled
    public String selectedContracts {get; set;}
}