public Class checkRecursiveDomain{
    /*
    private static boolean run = true;
    public static boolean runOnce(){
    if(run){
     run=false;
     return true;
    }else{
        return run;
    }
    }
    public static void setFalse(){
        run = true;
    }
    */
    private static set<string> myset = new set<string>();
    public static boolean runOnce(String contactId){
        if(!myset.contains(contactId)){
         myset.add(contactId);
         return true;
        }else{
            return false;
        }
    }
}