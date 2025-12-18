trigger IssueJIRACommentsUpdate on Issue__c (after update) {

    if (Trigger.isUpdate){
    List<Case> CaseList = new List<Case>();
    for (Issue__c iss: Trigger.new)
    {
        if(Trigger.oldMap.get( iss.Id ).JIRA_Public_Comments__c!= Trigger.newMap.get( iss.Id ).JIRA_Public_Comments__c)
        {
           List<Case> associatedCases=[SELECT Id, Issue_PM_Talk_Track__c, Related_Issue__c FROM Case WHERE Related_Issue__c = :iss.Id];
                       
           if(associatedCases.size() > 0){
                for(Case casemember : associatedCases){
                 CaseList.add(casemember); 
                 }
                 
                 for (Case casememberfinal : CaseList){
                      casememberfinal.Issue_PM_Talk_Track__c = iss.JIRA_Public_Comments__c;
                  }
                  update CaseList;
            }
          }
      }
    }
  }