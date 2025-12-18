public class AsyncCreateRenewalQuote implements Queueable {
    public Integer batchStep;
    public Set<string> contractIds ;
    
     public Map<Integer,Integer> getRenewalSteps{
        get{
            if(getRenewalSteps == null){
                getRenewalSteps = new Map<Integer,Integer>();
                List<RenewalQuoteCreationSteps__mdt> renewalSteps = RenewalQuoteCreationSteps__mdt.getAll()?.values();
                if(renewalSteps != null){
                    for(RenewalQuoteCreationSteps__mdt step:renewalSteps){
                        getRenewalSteps.put(Integer.valueOf(step.Order__c),Integer.ValueOf(step.Batch_Size__c));
                    } 
                }
                
                if(Test.isRunningTest()){
                    getRenewalSteps.put(1,10);
                    getRenewalSteps.put(2,10);
                    getRenewalSteps.put(3,10);
                    getRenewalSteps.put(4,1);
                    getRenewalSteps.put(5,1);
                   
                }
            } 
            return getRenewalSteps;
        }
        set{
            getRenewalSteps = value; 
        }
    }
    
    public AsyncCreateRenewalQuote(Integer batchStep,set<string> contractIds ){
        this.batchStep = batchStep+1;
        this.contractIds = contractIds;
     
        
    }
    public void execute(QueueableContext context) {
       DataBase.ExecuteBatch(new JobCreateRenewalQuote(batchStep,contractIds),getRenewalSteps.get(batchStep));       
    }
}