@IsTest
public class BreadCrumbControllerTest {

    public static testmethod void testUrlMappingList(){
        Integer mappingCnt =[select count() from Url_Path_Mapping__mdt];
        BreadCrumbSettings settings = BreadCrumbController.initializeSettings();
        System.assertEquals(mappingCnt, settings.urlMappings.size(), 'Url Mapping count mismatch');
    }
}