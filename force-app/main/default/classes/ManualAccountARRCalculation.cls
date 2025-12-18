/**********************************************************************
Name: ManualAccountARRCalculation
Test Class: UpdateAccountARRBatchTest
-----------------------------------------------------------------------
History  
GTMS-28100 	Kshitij	06/12/25	Intial Development 
***********************************************************************/ 
global class ManualAccountARRCalculation {

    @InvocableMethod(Label='Manual AccountARR Calculation')
    public static List<ManualARRResponse> calculateARR(List<ManualARRRequest> request) {
        List<ManualARRResponse> response = new List<ManualARRResponse>();
        ManualARRResponse responseRecord = new ManualARRResponse();
        string accountId = request[0].accountId;
        Date todayDate = Date.today();
        LIST<Opportunity> oppList = [SELECT Id, Name, Type, StageName, SBQQ__Renewal__c, SBQQ__AmendedContract__c,  
                                     License_Start_Date__c, License_End_Date__c, ACV_Bookings_USD__c, 
                                     Returning_Opportunity_18_Digit_ID__c, Returning_Opportunity__r.License_End_Date__c,  
                                     Returning_Opportunity__r.StageName, AccountId, Account.Customer_ARR__c, Rebate_Type__c,
                                     Returning_Opportunity__r.License_Start_Date__c
                                     FROM Opportunity  
                                     WHERE AccountId = :accountId  AND 
                                     ( 
                                         (StageName = 'Closed Won'  
                                          AND ACV_Bookings_USD__c != null  
                                          AND (License_Start_Date__c <= :todayDate AND License_End_Date__c >= :todayDate )
                                         )  
                                         OR 
                                         ( 
                                             StageName = 'Refunded - Closed' AND 
                                             ACV_Bookings_USD__c != null  AND
                                             Returning_Opportunity__r.StageName = 'Closed Won' AND 										
                                             (
                                                 Returning_Opportunity__r.License_Start_Date__c <= :todayDate AND
                                                 Returning_Opportunity__r.License_End_Date__c >= :todayDate
                                             ) 
                                         ) 
                                     )
                                    ];

            Decimal totalACV = AccountARRCalculationBatch.calculateTotalACV(oppList,todayDate);

        	responseRecord.totalARR = totalACV;
        

        
        response.add(responseRecord);
        return response;
    }
    
    public class ManualARRRequest {
        @InvocableVariable public String accountId;
    }
    
    public class ManualARRResponse {
        @InvocableVariable public Decimal totalARR;
       
    }
    
     public static void calulateActiveACVOnOpportunityClosed(List<Opportunity> newOppList, Map<Id, Opportunity> oldOppMap) {
        string accountId = '';
        for(Opportunity opp : newOppList){
            Opportunity oldOpp = oldOppMap.get(opp.Id);
            if(opp.StageName == 'Closed Won'  && opp.StageName != oldOpp.StageName && opp.License_Start_Date__c != null && opp.License_Start_Date__c < opp.LastStageChangeDate.date()){
                accountId = opp.AccountId;
            }
        }
        
        if(string.isNotBlank(accountId)){
            Database.executeBatch(new AccountARRCalculationBatch(new Set<Id>{accountId}),Integer.valueOf(Label.ARRBatchSize));
        }
	}
    
}