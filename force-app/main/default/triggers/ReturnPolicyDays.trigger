trigger ReturnPolicyDays on Case (after insert) {
     for(Case c: Trigger.new){                               
        if(c.OwnerId == '00G1a000001jnoW'){
              
            Case copyOfc = new Case(ID=c.id);                
            List<Opportunity> Oppty = New List<Opportunity>();
            Oppty = [Select Id, Owner.Email, CloseDate, Order_Number__c from Opportunity where Order_Number__c = :c.Subject.RIGHT(8)];
            Date casedate = System.Today();
            if (Oppty.size()>0){
              //copyofc.Return_Policy_Days_Left__c = 30 - (casedate - Oppty[0].CloseDate);
              copyofc.Return_Policy_Days_Left__c = Oppty[0].CloseDate.daysBetween(casedate);
              copyofc.Return_Oppty_Owner_Email__c = Oppty[0].Owner.Email;
              update copyOfc;
            }
         }
      }
 }