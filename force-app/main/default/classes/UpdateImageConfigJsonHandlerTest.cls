@IsTest
public class UpdateImageConfigJsonHandlerTest {
    @testSetup static void setup() {
        Schema.DescribeSObjectResult sObjDesc = Actions__c.sObjectType.getDescribe();
        Map<String, Schema.RecordTypeInfo> recTypes = sObjDesc.getRecordTypeInfosByDeveloperName();
        System.debug('>>>>>> recordTypes : '+recTypes);
        Actions__c action = new Actions__c(RecordTypeId=recTypes.get('Image_Carousel').getRecordTypeId(),
                                           Name='Test Image Carousel',
                                           Object__c='Home',
                                           Page_Type__c='Home');
        insert action;
    }
    public static testmethod void testUpdateJsonConfig(){
        Actions__c action = [select Id,Name,Image_Carousel_Config__c from Actions__c limit 1];
        System.assertEquals(null, action.Image_Carousel_Config__c,'Image JSON is not null');
        Carousel_Image__c img = new Carousel_Image__c(Name='Test',
                                                      Description__c='Test',
                                                      Image_Url__c='Test',
                                                      Actions__c=action.Id);
        insert img;
        action = [select Id,Name,Image_Carousel_Config__c from Actions__c limit 1];
        //System.assert(action.Image_Carousel_Config__c!=null, 'Image JSON is null');
        String expectJson = '[{"imgSrc":"Test","cardTitle":"Test","cardDescription":"Test"}]';
        //System.assertEquals(expectJson,action.Image_Carousel_Config__c, 'Image JSON not matching');
    }
    
    public static testmethod void testUpdateJsonConfigMultiple(){
        Actions__c action = [select Id,Name,Image_Carousel_Config__c from Actions__c limit 1];
        System.assertEquals(null, action.Image_Carousel_Config__c,'Image JSON is not null');
        Carousel_Image__c img = new Carousel_Image__c(Name='Test',
                                                      Description__c='Test',
                                                      Image_Url__c='Test',
                                                      Actions__c=action.Id);
        insert img;
        img = new Carousel_Image__c(Name='Test2',
                                    Description__c='Test2',
                                    Image_Url__c='Test2',
                                    Actions__c=action.Id);
        insert img;
        action = [select Id,Name,Image_Carousel_Config__c from Actions__c limit 1];
        //System.assert(action.Image_Carousel_Config__c!=null, 'Image JSON is null');
        String expectJson = '[{"imgSrc":"Test","cardTitle":"Test","cardDescription":"Test"},{"imgSrc":"Test2","cardTitle":"Test2","cardDescription":"Test2"}]';
        //System.assertEquals(expectJson,action.Image_Carousel_Config__c, 'Image JSON not matching');
    }
    
    public static testmethod void testUpdateJsonConfigDelete(){
        Actions__c action = [select Id,Name,Image_Carousel_Config__c from Actions__c limit 1];
        System.assertEquals(null, action.Image_Carousel_Config__c,'Image JSON is not null');
        Carousel_Image__c img = new Carousel_Image__c(Name='Test',
                                                      Description__c='Test',
                                                      Image_Url__c='Test',
                                                      Actions__c=action.Id);
        insert img;
        img = new Carousel_Image__c(Name='Test2',
                                    Description__c='Test2',
                                    Image_Url__c='Test2',
                                    Actions__c=action.Id);
        insert img;
        action = [select Id,Name,Image_Carousel_Config__c from Actions__c limit 1];
        //System.assert(action.Image_Carousel_Config__c!=null, 'Image JSON is null');
        String expectJson = '[{"imgSrc":"Test","cardTitle":"Test","cardDescription":"Test"},{"imgSrc":"Test2","cardTitle":"Test2","cardDescription":"Test2"}]';
        //System.assertEquals(expectJson,action.Image_Carousel_Config__c, 'Image JSON not matching');

        delete img;
        action = [select Id,Name,Image_Carousel_Config__c from Actions__c limit 1];
        //System.assert(action.Image_Carousel_Config__c!=null, 'Image JSON is null');
        expectJson = '[{"imgSrc":"Test","cardTitle":"Test","cardDescription":"Test"}]';
        //System.assertEquals(expectJson,action.Image_Carousel_Config__c, 'Image JSON not matching');

    }

}