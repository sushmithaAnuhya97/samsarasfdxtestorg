trigger CaseAssignToRoundRobin on Case (after insert) {
     for(Case c: Trigger.new){                               
            //List <Case> currentcase = [Select Id, OwnerId, Round_Robined__c from Case where Id =:c.Id];  
            Case copyOfc = new Case(ID=c.id);                
            Date d = System.today();
            Datetime dt = (DateTime)d;
            String CaseDay = dt.format('EEEE');                        
         if(c.Case_Account_Priority__c != 's0' && c.Case_Account_Priority__c != 's1'){
          
           
              if(c.Origin == 'Email' || c.Origin == 'Dashboard'){ 
               if(c.Reason != 'Feedback' ){             
                List<User> users = New List<User>();
                users = [Select Id, Support_Round_Robin__c, Support_Round_Robin_Timestamp__c, Number_of_Cases_today__c from User where Support_Round_Robin__c = True order by Support_Round_Robin_Timestamp__c LIMIT 1];
                List <Account> relatedAccount = [Select Id, Support_Escalation__c, Support_Escalation_Owner__c from Account where Id =: c.AccountId];
                
                if(relatedAccount.size()>0){
                  if(relatedAccount[0].Support_Escalation__c == true){
                    if(relatedAccount[0].Support_Escalation_Owner__c != null){
                      copyOfc.OwnerId =  relatedAccount[0].Support_Escalation_Owner__c;
                      update copyOfc; 
                    } else {
                       if(users.size() > 0){
                    //Decimal casenumber = users[0].Number_of_Cases_today__c;                
                        copyOfc.OwnerId =  users[0].Id;
                        users[0].Number_of_Cases_today__c = users[0].Number_of_Cases_today__c + 1;
                        copyOfc.Round_Robined__c = True;
                        users[0].Support_Round_Robin_Timestamp__c = system.now();
                        update copyOfc;                  
                        update users[0];    
                       }else {
                          copyOfc.OwnerId = '00G1a000000fXCL';
                          copyOfc.Round_Robined__c = False;
                          update copyOfc;   
                        }
                      }
                    
                   }else {
                
                     if(users.size() > 0){
                    //Decimal casenumber = users[0].Number_of_Cases_today__c;                
                        copyOfc.OwnerId =  users[0].Id;
                        users[0].Number_of_Cases_today__c = users[0].Number_of_Cases_today__c + 1;
                        copyOfc.Round_Robined__c = True;
                        users[0].Support_Round_Robin_Timestamp__c = system.now();
                        update copyOfc;                  
                        update users[0];  
                    }else {
                      copyOfc.OwnerId = '00G1a000000fXCL';
                      copyOfc.Round_Robined__c = False;
                      update copyOfc;   
                     }
                   }                                                        
                }
               }           
              }          
            }            
           }
          }