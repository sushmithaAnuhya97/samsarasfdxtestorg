/**
 * Created by vikasmishra on 2021-08-16.
 */

public with sharing class SamsaraAuditToggleMdtSelector {

    public Samsara_Audit_Toggle__mdt getInstanceBYDeveloperName(String developerName){
        return Samsara_Audit_Toggle__mdt.getInstance(developerName);
    }
}