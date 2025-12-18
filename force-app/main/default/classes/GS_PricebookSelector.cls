/**
* Created By : Groundswell - Suman Kundu
* @Date September 16, 2021
*
* @description : This class will be responsible for handling all Pricebook related queries / SOQLs
* SFA-10
*
**/
public inherited sharing class GS_PricebookSelector extends GS_SObjectBaseSelector {
    public GS_PricebookSelector(Boolean checkFatalError){
        super(checkFatalError);
    }
     
    public GS_PricebookSelector checkFatalError(){
        return (GS_PricebookSelector) super.validateFatalError();
    }

    /**
     * Return the PriceBook2 by Id with the required fields
     * @param Set<id> pricebookIds
     */
    public Map<Id, Pricebook2> getPricebookById(Set<Id> pricebookIds){
        if (pricebookIds.size() == 0) {
            return null;
        }
        return new Map<Id, Pricebook2>([SELECT Id, Name FROM Pricebook2 WHERE Id IN :pricebookIds]);
    }
}