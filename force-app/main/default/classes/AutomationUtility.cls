//Test Class: UtilityTest
public class AutomationUtility {

    @InvocableMethod(label = 'Get Custom Label by DeveloperName in Flow' )
    public static List<string> getCustomLabelByDeveloperNameFromFlow(List<String> developerName){
        return new List<String>{Utility.getCustomLabelByDeveloperName(developerName[0])};
    }

    @AuraEnabled
    public static string getCustomLabelByDeveloperNameForCMP(String developerName){
        return Utility.getCustomLabelByDeveloperName(developerName);
    }
}