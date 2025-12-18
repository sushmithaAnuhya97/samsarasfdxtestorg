public without sharing class TemplateSelectionHelper {

    public static Map<String, Id> getTemplates(String type){

        Map<String, Id> langugeTemplateIdMap = new Map<String, Id>();      
        List<Email_Template__mdt> templateCustomData = [SELECT Language__c, Template_Id__c from Email_Template__mdt where Type__c =: type];

        for(Email_Template__mdt template : templateCustomData){
            langugeTemplateIdMap.put(template.Language__c, template.Template_Id__c);
        }

        return langugeTemplateIdMap;
    }

}