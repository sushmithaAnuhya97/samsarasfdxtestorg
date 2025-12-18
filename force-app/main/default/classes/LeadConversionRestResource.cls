/**********************************************************************
Name: LeadConversionRestResource
Purpose: REST API endpoint to accept payload from Notre Dame for lead conversion processing.
         Handles lead conversion, deal registration, partner account updates, and comprehensive logging.

History  

VERSION     AUTHOR               DATE               DETAIL                       
1.0         Vikas Mishra         2021-Jun-17        INITIAL DEVELOPMENT 
1.1         Vijaychandra         2024-Aug-05        Added Partner Application H2 project support (GTMS-22483)
1.2         Azra Khan            2025-Oct-09        Added Samsara logging framework integration for Notre Dame payload tracking

***********************************************************************/

/**
 * @description : This class will be used to accept payload from
 * Notre Dame to handle lead conversion. It will receive a payload
 * with following structure [
 * { "leadId": "XXXXXXXXXXXXXXXXXLeadId",
 * "status": "success",
 * "accountId": "XXXXXXXXXXXXXXXXXAccountId",
  * "ContactId":"XXXXXXXXXXXXXXXXXContactId",
  * errorMessage": "" }
  * ]
 */
@RestResource(UrlMapping='/v1/lead-processing')
global without sharing class LeadConversionRestResource {
    @TestVisible
    static LeadConversionRestResourceHelper.IHelper thisRestResourceHelper = new LeadConversionRestResourceHelper();
    static final String ADMIN_LOGIN_PORTAL_PROFILE_NAME = 'Samsara Partner Community Login License Admin';

    /**
     * @description Processes incoming payload from Notre Dame for lead conversion
     * Logs all payload details and individual lead processing results using Samsara logging framework
     * Handles lead conversion, deal registration, and partner account updates
     */
    @HttpPost
    global static void doPost()
    {
        RestResponse response = new RestResponse() ;
        response.addHeader('Content-type','application/json');
        String webhookPayload = RestContext.request.requestBody.toString();
        
        try {
            // Log the incoming payload for debugging and monitoring
            Logger.atInfo()
                .setClassName('LeadConversionRestResource')
                .setMethod('doPost')
                .setExceptionOrMessage('Notre Dame Payload Received - Size: ' + webhookPayload.length() + ' characters. Payload: ' + webhookPayload);
            
            // Parse payload to extract Lead IDs for individual lead tracking
            List<LeadConversionRestResourceHelper.Payload> parsedPayload = new LeadConversionRestResourceHelper.Payload().parse(webhookPayload);
            
            // Log each lead in the payload with success/failure status
            for(LeadConversionRestResourceHelper.Payload payloadItem : parsedPayload) {
                String payloadDetails = 'Status: ' + payloadItem.status + 
                                    ', Account ID: ' + payloadItem.accountId + 
                                    ', Contact ID: ' + payloadItem.contactId + 
                                    ', Error Message: ' + payloadItem.errorMessage;
                
                if(String.isNotBlank(payloadItem.status) && payloadItem.status.toLowerCase().contains('success')) {
                    Logger.atInfo()
                        .setClassName('LeadConversionRestResource')
                        .setMethod('doPost')
                        .setRecordId(payloadItem.leadId)
                        .setExceptionOrMessage('SUCCESS PAYLOAD - ' + payloadDetails);
                } else {
                    Logger.atError()
                        .setClassName('LeadConversionRestResource')
                        .setMethod('doPost')
                        .setRecordId(payloadItem.leadId)
                        .setExceptionOrMessage('FAILED PAYLOAD - ' + payloadDetails);
                }
            }
            
            // Process the payload through the helper chain
            thisRestResourceHelper.setPayLoadString(webhookPayload)
                    .processPayloadForConversion()
                	.processDealRegistration()
                    .updateConvertedAccountAsPartner()
                    .create_PA_PR_Creation()
                	.processLeadConversionError();//8/5/24 Vijaychandra (GTMS-22483): calling new method as part of partner application project
                    //.doProcessUserProvisioning(ADMIN_LOGIN_PORTAL_PROFILE_NAME);////8/5/24 Vijaychandra (GTMS-22483): commented method calling as part of partner application project
    		
            // Log successful processing completion
            Logger.atInfo()
                .setClassName('LeadConversionRestResource')
                .setMethod('doPost')
                .setExceptionOrMessage('Notre Dame payload processed successfully - ' + parsedPayload.size() + ' leads processed');
                
        } catch (Exception e) {
            // Log any errors during processing for troubleshooting
            Logger.atError()
                .setClassName('LeadConversionRestResource')
                .setMethod('doPost')
                .setExceptionOrMessage(e);
        } finally {
            // Always insert logs to Samsara logging framework
            Logger.insertMasterLogs();
        }
    }
}