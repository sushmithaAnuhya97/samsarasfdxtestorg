trigger AssignCustomerNumber on Account (before insert) {
    String chars = '23456789ABCDEFGHJKMNPRSTUVWXYZ';
    
    for (Account a : Trigger.new) {
         String sam = 'C'; //All SAM numbers start with C
        
         for (Integer i=0;i<9; i++) { //generate 9 characters in addition to the beginning C
             Integer charPos = Math.floor(Math.random() * chars.length()).intValue(); 
             sam = sam + chars.substring(charPos,charPos+1);
         }
         a.sam_number_undecorated__c = sam;
    }
}