/**
* Created By : Groundswell - Tanuj Tyagi
* @Date August 09, 2021
*
* @description : This class will be responsible for handling all the CS Record Related Queries
* SFA-11
*
**/

public class GS_CS_RecordSelector extends GS_SObjectBaseSelector{
    
    public GS_CS_RecordSelector(boolean checkFatalError){
        super(checkFatalError);
    }
    
    public GS_CS_RecordSelector checkFatalError(){
        return (GS_CS_RecordSelector) super.validateFatalError();
    }
    
    public List<CS_Record__c> getCSRecordsByIds(List<Id>ids){
        List<CS_Record__c> csRecordList = new List<CS_Record__c>();
        csRecordList = [SELECT Id FROM CS_Record__c WHERE Id IN :ids];
        return csRecordList;
    }
    
    
    public List<CS_Record__c> getCSRecordsByAccountIds(List<Id>ids){
        List<CS_Record__c> csRecordList = new List<CS_Record__c>();
        csRecordList = [SELECT Id FROM CS_Record__c WHERE Account__c IN :ids];
        return csRecordList;
    }
    
    public class GSSelectorException extends Exception{ }
}