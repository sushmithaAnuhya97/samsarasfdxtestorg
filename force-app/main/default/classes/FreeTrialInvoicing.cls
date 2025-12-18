public class FreeTrialInvoicing {

	@Future(callout=true)
	public static void sendEmail(String quote_Id, String opId, String custId, String repEmail, String custEmail, String owaID, String emailTemplateId) {
    
        //Id of Quote record.
        String QuoteID = quote_Id;
        
        //Id of quote Template
        String templateID = '0EH1a000000RKc5';
        

        String quoteUrl = '/quote/quoteTemplateDataViewer.apexp?id=';
        quoteUrl +=QuoteID;
        quoteUrl +='&headerHeight=190&footerHeight=188&summlid=';
        quoteUrl +=templateID;
        quoteUrl +='#toolbar=1&navpanes=0&zoom=90';
        
        //Create pdf content
        PageReference pg = new PageReference(quoteUrl);
        
        //Document object of quote which hold the quote pdf
        QuoteDocument quotedoc = new QuoteDocument(); 
        
        //Get the content of Pdf.
        Blob b;
        if (Test.IsRunningTest()) b=Blob.valueOf('UNIT.TEST');
        else b=pg.getContentAsPDF();

        
        //content assign to document
        quotedoc.Document = b;
        
        //assign quote id where pdf should attach
        quotedoc.QuoteId = QuoteID;

        System.debug(LoggingLevel.INFO, 'quotedoc: ' + quotedoc);
        
        //insert the quotdoc
        insert quotedoc;
        
        Messaging.EmailFileAttachment attach = new Messaging.EmailFileAttachment();
        attach.setContentType('application/pdf');
        attach.setFileName('SamsaraTrialInvoice.pdf');
        attach.setInline(false);
        attach.Body = b;
        
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setUseSignature(false);
        mail.setTemplateId(emailTemplateId);
        mail.setTargetObjectId(custId);
        mail.setWhatId(opId);
        
        //in case the contact doesn't have email associated, we send email to billing email
        if (custEmail <> Null) {
            List<String> customerEmail = new String[1];
            customerEmail[0] = custEmail;
            mail.setToAddresses(customerEmail);
        }

        mail.setOrgWideEmailAddressId(owaID);

        if (repEmail <> Null){
            mail.setCcAddresses(new String[] {repEmail,'trials@samsara.com'});
        }

        mail.setFileAttachments(new Messaging.EmailFileAttachment[] { attach }); 
        mail.saveAsActivity = false;
        // Send the email
        if (!Test.IsRunningTest()) {
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
        }
    }

}