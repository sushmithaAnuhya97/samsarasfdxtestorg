/**
 * @author Groundswell - Vikasm - vikas@gscloudsolutions.com
 * @date 2020-09-02
 * @lastModified 2020-09-08
 */
public with sharing class RollupService 
{
   public static Decimal Sum (List<Sobject> recordList, String rollUpField)
   {
        Decimal sum = 0;
        for(Sobject record : recordList)
        {
            sum += record.get(rollUpField)!=null ? (Decimal)record.get(rollUpField) : 0 ;
        }

        return Sum;
   }

   public static decimal average (List<Sobject> recordList, String rollUpField)
   {
       Decimal average = 0;
        average = sum(recordList, rollUpField)/recordList.Size();
        return average;
   }

   public static decimal max (List<Sobject> recordList, String rollUpField)
   {
       Decimal max =0;
       integer recordCount = 0;
       for(Sobject record : recordList)
       {
           if(recordCount == 0 ) max = (Decimal) record.get(rollUpField);
            max = max > ((Decimal) record.get(rollUpField)) ? max : (Decimal) record.get(rollUpField);
            recordCount++;
       }
       return max;
   }

   public static decimal min (List<Sobject> recordList, String rollUpField)
   {
       Decimal min =0;
       integer i = 0;
       for(Sobject record : recordList)
       {
           if(i == 0 ) min = (Decimal) record.get(rollUpField);
            min = min < ((Decimal) record.get(rollUpField)) ? min : (Decimal) record.get(rollUpField);
            i++;
       }
       return min;
   }

   public static Sobject first (List<Sobject> recordList, String rollUpField)
   {
        Sobject firstRecord ;
        Datetime thresholdDateTime = system.now();
        integer recordCount = 0;
        for(Sobject record : recordList)
        {
            if (recordCount == 0) {
                firstRecord = record;
                thresholdDateTime = ((Datetime) record.get(rollUpField));
            }
            if (thresholdDateTime >= ((Datetime) record.get(rollUpField))) {
                thresholdDateTime = ((Datetime) record.get(rollUpField));
                firstRecord = record;
            }
            recordCount++;
        }
        return firstRecord;
   }

   public static Sobject last (List<Sobject> recordList, String rollUpField)
   {
       Sobject lastRecord ;
       Datetime thresholdDateTime ;
       integer recordCount = 0;
        for(Sobject record : recordList) {
            if (recordCount == 0) {
                lastRecord = record;
                thresholdDateTime = ((Datetime) record.get(rollUpField));
            }
            if (thresholdDateTime <= ((Datetime) record.get(rollUpField))) {
                thresholdDateTime = ((Datetime) record.get(rollUpField));
                lastRecord = record;
            }
            recordCount++;
        }
        return lastRecord;
   }

    public static String concatDistinct(List<Sobject> recordList, String rollUpField) {
        String concatValue = '';
        String coma = '';
        for (Sobject record : recordList) {
            if (!concatValue.contains((String) record.get(rollUpField)))
                concatValue += coma + (String) record.get(rollUpField);
            coma = ',';
        }

        return concatValue;
    }

    public static Decimal countDistinct(List<Sobject> recordList, String rollUpField) {
        set<String> distinctFieldValue = new set<String>();
        Decimal countDistinct = 0;
        for (Sobject record : recordList) {
            distinctFieldValue.add((String) record.get(rollUpField));
        }
        countDistinct = !distinctFieldValue.isEmpty() ? distinctFieldValue.size() : 0;

        return countDistinct;
    }
}