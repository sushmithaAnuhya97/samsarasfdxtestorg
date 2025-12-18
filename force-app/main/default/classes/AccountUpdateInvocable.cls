public class AccountUpdateInvocable {
    
    @InvocableMethod(label='Update Account' description='Update Account Fields - No. of Vehicles, Number of Powered Assets and Number of Unpowered Assets' )
    public static List<Account> updateAccountData(List<FlowInput> flowInputs) {
        
        List<Account> acctToUpdateList = new List<Account>();

        for(FlowInput flowInput : flowInputs) {
            Account acctRecordToUpdate = new Account();
            Boolean isChanged = false;

            acctRecordToUpdate.Id = flowInput.accountId;
            if(flowInput.numberOfVehicles != null) {
                acctRecordToUpdate.Number_of_Vehicles__c = flowInput.numberOfVehicles;
                isChanged = true;
            }
            if(flowInput.numberOfPoweredAssets != null) {
                acctRecordToUpdate.Number_of_Powered_Assets__c = flowInput.numberOfPoweredAssets;
                isChanged = true;
            }
            if(flowInput.numberOfUnpoweredAssets != null) {
                acctRecordToUpdate.Number_of_Unpowered_Assets__c = flowInput.numberOfUnpoweredAssets;
                isChanged = true;
            }
            if(isChanged) {
                acctToUpdateList.add(acctRecordToUpdate);
            }
        }
        if(!acctToUpdateList.isEmpty()) {
            update acctToUpdateList;

            List<Account> updatedAccount = [SELECT Id, Updated_Account_Size_Segment__c FROM Account WHERE Id = :acctToUpdateList[0].Id];
            return updatedAccount;
        }
        return null;
        
    }

    public class FlowInput {
      
        @InvocableVariable(label='accountId' required=true)
        public Id accountId;

        @InvocableVariable(label='Number of Vehicles')
        public Decimal numberOfVehicles;

        @InvocableVariable(label='Number of Powered Assets')
        public Decimal numberOfPoweredAssets;

        @InvocableVariable(label='Number of Unpowered Assets')
        public Decimal numberOfUnpoweredAssets;
    }
}