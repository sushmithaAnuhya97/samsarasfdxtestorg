public Class checkRecursive{
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
    private static set<string> instanceMap = new set<string>();
    private static set<string> triggerMap = new set<string>();
    public static boolean runOnce(String instanceId, String triggerName){
        if(!instanceMap.contains(instanceId) && !triggerMap.contains(triggerName)){
         instanceMap.add(instanceId);
         triggerMap.add(triggerName);
         return true;
        }else{
            return false;
        }
    }
}