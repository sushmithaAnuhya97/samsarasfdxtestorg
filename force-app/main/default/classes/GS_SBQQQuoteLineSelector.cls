/**
* Created By : Groundswell - Suman Kundu
* @Date September 11, 2021
*
* @description : This class will be responsible for handling all Quote Line queries / SOQLs
* SFA-10
*
**/
public inherited sharing class GS_SBQQQuoteLineSelector extends GS_SObjectBaseSelector{

    public GS_SBQQQuoteLineSelector(Boolean checkFatalError){
        super(checkFatalError);
    }
     
    public GS_SBQQQuoteLineSelector checkFatalError(){
        return (GS_SBQQQuoteLineSelector) super.validateFatalError();
    }

    /**
     * Return the Quote by Id with the required fields
     * @param Set<id> quoteIds
     */
    public Map<Id, SBQQ__QuoteLine__c> getQuoteLinessByQuoteId(Set<Id> quoteIds){
        return new Map<Id, SBQQ__QuoteLine__c>([
            SELECT Id, SBQQ__Quote__c, Ship_To__c, Ship_From_Location__c, Original_FT_Oppty_Line_Item_SF_Id__c, 
            SBQQ__Quote__r.Shipping_Address_NEW__c, SBQQ__Quote__r.Ship_From_Location__c
            FROM SBQQ__QuoteLine__c
            WHERE SBQQ__Quote__c IN :quoteIds
        ]);
    }
}