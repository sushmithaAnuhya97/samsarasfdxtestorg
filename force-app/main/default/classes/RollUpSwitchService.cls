/**
 * @author Groundswell - Vikasm - vikas@gscloudsolutions.com
 * @date 2020-09-03
 * @lastModified 2020-09-08
 */
public with sharing class RollUpSwitchService 
{
    
 public static List<Rollup_Switch__mdt> rollUpList{
        get{
            if(rollUpList == null){
               rollUpList  = Rollup_Switch__mdt.getAll()?.values(); 
                if(rollUpList == null){
                   rollUpList = new List<Rollup_Switch__mdt>(); 
                }
            } 

            return rollUpList;
        }
        set{ rollUpList = value; }
    }   
   public static Map<String,Rollup_Switch__mdt> getRollupSwitchMetadata(String parentObject, String ChildObject)
   {
        
        Map<String,Rollup_Switch__mdt> mapOFRollupFieldVsMetadata = new  Map<String,Rollup_Switch__mdt> ();
       
         for(Rollup_Switch__mdt rollupSwitchMdt:rollUpList)                                          
        {
            if(rollupSwitchMdt.Active__c == true && rollupSwitchMdt.MasterLabel == parentObject && rollupSwitchMdt.Child_Object__c == ChildObject ){
                  mapOFRollupFieldVsMetadata.put(rollupSwitchMdt.Aggregate_Result_Field__c, rollupSwitchMdt);   
            }

        }

        return mapOFRollupFieldVsMetadata;
   } 
}