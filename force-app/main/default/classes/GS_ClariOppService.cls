/**
 * Created by fcontini on 2021-09-21.
 */

public with sharing class GS_ClariOppService {

    public void createClariOpp(List<Opportunity> oppList){
        List<Clari_Opp__c> clariOppList = new List<Clari_Opp__c>();
        for (Opportunity opp : oppList)
            clariOppList.add(new Clari_Opp__c(Opportunity__c = opp.Id));
        DMLWrapper.doInsert(clariOppList);
    }
}