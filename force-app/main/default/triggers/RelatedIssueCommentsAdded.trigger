trigger RelatedIssueCommentsAdded on Issue__c (after update) {

    if (Trigger.isUpdate){
    List<Case> CaseList = new List<Case>();
    for (Issue__c iss: Trigger.new)
    {
   // if(checkRecursive.runOnce(iss.Id)){
        if(Trigger.oldMap.get( iss.Id ).Dev_comments_update_count__c != Trigger.newMap.get( iss.Id ).Dev_comments_update_count__c)
        {
           List<Case> associatedCases=[SELECT Id, Related_Issue_comments_update__c, Related_Issue__c FROM Case WHERE Related_Issue__c = :iss.Id];
                       
           if(associatedCases.size() > 0){
                for(Case casemember : associatedCases){
                 CaseList.add(casemember); 
                 }
               
                  for (Case casememberfinal : CaseList){
                      if(casememberfinal.Related_Issue_comments_update__c == null){
                          casememberfinal.Related_Issue_comments_update__c = 1;
                      }else{
                        casememberfinal.Related_Issue_comments_update__c += 1;
                       } 
                  }
                  update CaseList;
               }
            }
         }
      }
    }
  // }