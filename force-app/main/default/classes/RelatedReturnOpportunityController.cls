/* ClassName - RelatedReturnOpportunityController
 * Author - devansh.pathak@samsara.com
 * Functionality - This class is called from Related_Opportunity_Flow to update owner and copy fields
 *                 on Return Opportunity from linked Revenue Opportunity
 * JIRA: GTMS-29334 
 *
 */
public class RelatedReturnOpportunityController {
    
    public Class RelatedReturnWrapper {
        @InvocableVariable 
        public List<String> oppIds; //This will contain return opportunity Id and revenue opportunity Id
    }
    
    @invocableMethod(label = 'CopyFieldsUpdate' description = 'Update copy fields on return opportunity based on swap')
    public static void updateCopyFieldsOnReturn(List<RelatedReturnWrapper> oppIdWrpList) {
        Set<Id> oppIdSet = new Set<Id>();
        
        If(!oppIdWrpList.isEmpty() && oppIdWrpList[0] != null && !oppIdWrpList[0].oppIds.isEmpty()) {
            for (String oppRecId : oppIdWrpList[0].oppIds) {
                If(oppRecId != '' && oppRecId != null) {
                    oppIdSet.add((Id)oppRecId);
                }
            }         

            List<Opportunity> oppDataList = new List<Opportunity>();
            If(!oppIdSet.isEmpty()) {
                oppDataList = [SELECT Id, Type, Rebate_Type__c, Returning_Opportunity__c, ownerId, Owner_Role_Copy__c, 
                                Owner_Manager_Name_Copy__c, Owner_Manager_Role_Copy__c, Owner_Manager_Email_Copy__c, 
                                Owner_Director_Name_Copy__c, Owner_Director_Role_Copy__c, Owner_Director_Email_Copy__c, 
                                Owner_AVP_Name_Copy__c, Owner_AVP_Role_Copy__c
                                FROM Opportunity
                                WHERE Id IN:oppIdSet];
            }
            
            
            Opportunity revenueOpp;
            Opportunity returnOpp;
            
            For(Opportunity oppRec : oppDataList) {
                If(oppRec.type == 'Revenue Opportunity') {
                    revenueOpp = oppRec;
                } else if(oppRec.type == 'Remorse Refund') {
                    returnOpp = oppRec;
                }
            }
            Try {
                Opportunity oldOpp = new Opportunity();
                
                If(revenueOpp != null && returnOpp != null) 
                {
                    //Assign return opportunity owner based on linked revenue opportunity
                    Opportunity updateRetunOpp = ReturnOwnerCopyDataUtility.updateCopyFields(returnOpp, oldOpp, revenueOpp, null, true);
                    //Assign return opportunity copy fields based on linked revenue opportunity
                    updateRetunOpp.ownerId = ReturnOwnerCopyDataUtility.getOwnerForDelinquentRebateOpportunity(new Set<Id>{revenueOpp.Id}).get(revenueOpp.Id);
                    
                    //Setting bypassForCopyDataMechanism as true, so return copy fields are not updated again through OpportunityHelperContext once owner is changed
                    OpportunityTriggerHandlerContext.bypassForCopyDataMechanism = true;
                    update updateRetunOpp;
                }
            } Catch(Exception ex) {
                System.debug('ex.getMessage() ----> ' + ex.getMessage());
                LOGGER.atError().setCLassName('RelatedReturnOpportunityController').setMethod('updateCopyFieldsOnReturn').setRecordId(returnOpp.Id).setExceptionOrMessage(ex.getMessage());
                
                Logger.setFunctionalityType('Copy Fields Update'); 
                Logger.insertMasterLogs(); 
                
            }
        }
    }
}