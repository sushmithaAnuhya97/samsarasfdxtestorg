public class ExpressCheckout {
    class ExpressCheckoutException extends Exception {
    }

    public class EmailParameters {
        public Id quote_Id;
        public Id contactId;
        public String repEmail;
        public String typeOfPayment;
        public Boolean isOneYear;
        public Boolean isCameraOnly;
        public String country;
        public String custEmail;
        public String language;

        public EmailParameters(
                Id quote_Id,
                Id contactId,
                String repEmail,
                String typeOfPayment,
                Boolean isOneYear,
                Boolean isCameraOnly,
                String country,
                String custEmail,
                String language
        ) {
            this.quote_Id = quote_Id;
            this.contactId = contactId;
            this.repEmail = repEmail;
            this.typeOfPayment = typeOfPayment;
            this.isOneYear = isOneYear;
            this.isCameraOnly = isCameraOnly;
            this.country = country;
            this.custEmail = custEmail;
            this.language = language;
        }
    }

    public Map<String, Id> expressCheckOutLangugeTemplateIdMap;
    public List<QuoteDocument> quoteDocumentsToInsert;
    public List<Messaging.SingleEmailMessage> emailsToSend;
    public OrgWideEmailAddress noReplyAddress;

    public ExpressCheckout() {
        this.expressCheckOutLangugeTemplateIdMap = TemplateSelectionHelper.getTemplates('Express Agreement');
        this.quoteDocumentsToInsert = new List<QuoteDocument>();
        this.emailsToSend = new List<Messaging.SingleEmailMessage>();
        this.noReplyAddress = [SELECT Id, Address, DisplayName FROM OrgWideEmailAddress WHERE DisplayName = 'no-reply' LIMIT 1];
    }

    public Messaging.SingleEmailMessage constructEmail(EmailParameters params) {
        //Id of Quote record.
        Id QuoteID = params.quote_Id;

        //Id of quote Template
        Id templateID = getQuoteTemplateId(params.isCameraOnly, params.country, params.typeOfPayment);
        //This Url create the pdf for quote
        String quoteUrl = '/quote/quoteTemplateDataViewer.apexp?id=';
        quoteUrl += QuoteID;
        quoteUrl += '&headerHeight=190&footerHeight=188&summlid=';
        quoteUrl += templateID ;
        quoteUrl += '#toolbar=1&navpanes=0&zoom=90';

        //Create pdf content
        PageReference pg = new PageReference(quoteUrl) ;

        //Document object of quote which hold the quote pdf
        QuoteDocument quotedoc = new QuoteDocument();

        //Get the content of Pdf.
        Blob b;
        if (Test.IsRunningTest()) {
            b = Blob.valueOf('UNIT.TEST');
        } else {
            b = pg.getContentAsPDF() ;
        }

        //content assign to document
        quotedoc.Document = b;

        //assign quote id where pdf should attach
        quotedoc.QuoteId = QuoteID ;

        //insert the quotdoc
        this.quoteDocumentsToInsert.add(quoteDoc);

        Messaging.EmailFileAttachment attach = new Messaging.EmailFileAttachment();
        attach.setContentType('application/pdf');
        attach.setFileName('SamsaraAgreement.pdf');
        attach.setInline(false);
        attach.Body = b;

        Id expressTemplateId;
        if ((!String.isBlank(params.language)) && (this.expressCheckOutLangugeTemplateIdMap.containsKey(params.language))) {
            expressTemplateId = this.expressCheckOutLangugeTemplateIdMap.get(params.language);
        } else {
            expressTemplateId = this.expressCheckOutLangugeTemplateIdMap.get('English');
        }

        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        //EmailTemplate et = [Select Id from EmailTemplate where Name = 'Express Agreement Email'];
        try {
            mail.setTemplateId(expressTemplateId);
        } catch (System.NullPointerException e) {
            system.debug('The assignment of template Id failed with the error message ' + e);
        }
        //system.debug('ET' +et.Id);
        mail.setTargetObjectId(params.contactId);

        //in case the contact doesn't have email associated, we send email to billing email
        if (params.custEmail != null) {
            mail.setToAddresses(new List<String>{
                    params.custEmail
            });
        }

        if (this.noReplyAddress != null) {
            mail.setOrgWideEmailAddressId(this.noReplyAddress.Id);
        }

        if (String.isNotBlank(params.repEmail)) {
            mail.setCcAddresses(new List<String>{
                    params.repEmail
            });
        }

        mail.setFileAttachments(new Messaging.EmailFileAttachment[]{
                attach
        });

        return mail;
    }

    @TestVisible
    private static String constructCmdtName(Boolean isCameraOnly, String country, String typeOfPayment) {
        final String CAMERA = 'Camera';
        final String SEPARATOR = '_';
        final List<String> EXPECTED_PAYMENT_TYPES = new List<String>{
                'Direct Annual', 'Upfront Payments'
        };
        final Map<String, String> paymentKeyUpdated = new Map<String, String>{'Direct Annual' => 'Annual Payments', 'UpfrontPayments' => 'Upfront Payment'};

        String paymentKey;
        if (EXPECTED_PAYMENT_TYPES.contains(typeOfPayment)) {
            paymentKey = paymentKeyUpdated.get(typeOfPayment);
        } else {
            paymentKey = 'ELSE';
        }
        String key = '';
        if (isCameraOnly) {
            key = CAMERA + SEPARATOR;
        }
        key += String.join(new List<String>{
                country.replace(' ', ''),
                paymentKey.replace(' ', '')
        }, SEPARATOR);

        return key;
    }


    /**
    * @author Groundswell - Henry Zhao - henry@gscloudsolutions.com
    * @date 2/7/2020
    *
    * @description Retrieves the quote template ID given the following naming convention:
    * {IS_CAMERA_ONLY}_COUNTRY_{TYPE_OF_PAYMENT | ELSE}
    * If the type of payment is within our expected payment types, we use that as Key.
    * If the type of payment is not expected, we use ELSE as the Key.
    */
    private static Id getQuoteTemplateId(Boolean isCameraOnly, String country, String typeOfPayment) {
        String key = constructCmdtName(isCameraOnly, country, typeOfPayment);
        Express_Checkout_Quote_Template_Map__c found = Express_Checkout_Quote_Template_Map__c.getValues(key);
        if (found == null || found.Quote_Template_Id__c == null) {
            throw new ExpressCheckoutException('Custom setting not set correctly for ' + key);
        }
        return Id.valueOf(found.Quote_Template_Id__c);
    }

    @Future(callout=true)
    public static void sendBulkEmailFuture(String paramsString) {
        sendBulkEmail(paramsString);
    }

    public static void sendBulkEmail(String paramsString) {
        ExpressCheckout service = new ExpressCheckout();
        List<EmailParameters> params = (List<EmailParameters>) JSON.deserialize(paramsString, List<EmailParameters>.class);

        for (EmailParameters param : params) {
            service.emailsToSend.add(service.constructEmail(param));
        }
//        if (!Test.isRunningTest()) {
        insert service.quoteDocumentsToInsert;
        System.debug(LoggingLevel.INFO, '##### ExpressCheckout -> sendBulkEmail -> sending email');
        Messaging.sendEmail(service.emailsToSend);
//        }
    }
}