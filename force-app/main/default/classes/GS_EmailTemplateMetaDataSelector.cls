/**
 * Created by vikasmishra on 2021-09-15.
 */

public with sharing class GS_EmailTemplateMetaDataSelector extends GS_SObjectBaseSelector{

    public GS_EmailTemplateMetaDataSelector(Boolean checkFatalError){
        super(checkFatalError);
    }

    public GS_EmailTemplateMetaDataSelector checkFatalError(){
        return (GS_EmailTemplateMetaDataSelector) super.validateFatalError();
    }

    public List<Email_Template__mdt> getEmailTemplatesMdtByType (String type){
        return [SELECT Language__c, Template_Id__c FROM Email_Template__mdt WHERE Type__c =: type];
    }

}