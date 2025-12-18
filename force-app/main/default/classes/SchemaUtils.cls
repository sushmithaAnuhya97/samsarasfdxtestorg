public without sharing class SchemaUtils {
    
    private static Map<String, Schema.SObjectType> globalDescribeCache;

    public static Map<String, Schema.SObjectType> getGlobalDescribe(){
        if (globalDescribeCache == null) globalDescribeCache = Schema.getGlobalDescribe();
        return globalDescribeCache;
    }
}