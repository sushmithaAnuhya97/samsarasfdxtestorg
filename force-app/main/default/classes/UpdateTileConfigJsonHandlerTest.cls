@IsTest
public class UpdateTileConfigJsonHandlerTest {
    @testSetup static void setup() {
        Schema.DescribeSObjectResult sObjDesc = Actions__c.sObjectType.getDescribe();
        Map<String, Schema.RecordTypeInfo> recTypes = sObjDesc.getRecordTypeInfosByDeveloperName();
        System.debug('>>>>>> recordTypes : '+recTypes);
        Actions__c action = new Actions__c(RecordTypeId=recTypes.get('Welcome_Mat').getRecordTypeId(),
                                                                           Name='Test Welcome Mat',
                                                                           Object__c='Home',
                                                                           Page_Type__c='Home');
        insert action;
    }
    public static testmethod void testUpdateJsonConfig(){
        Actions__c action = [select Id,Name,Welcome_Mat_Tile_Config__c from Actions__c limit 1];
        System.assertEquals(null, action.Welcome_Mat_Tile_Config__c,'1:Tile Config JSON is not null');
        Welcome_Mat_Tile__c tile = new Welcome_Mat_Tile__c(Title__c='Test',
                                                                                           Body__c='Test',
                                                                                           Link__c='http://www.test.com',
                                                                                           Icon__c='action:approval',
                                                                                           Action__c=action.Id);
        insert tile;
        action = [select Id,Name,Welcome_Mat_Tile_Config__c from Actions__c limit 1];
        //System.assert(action.Welcome_Mat_Tile_Config__c!=null, '2:Tile Config JSON JSON is null');
        String expectJson = '[{"title":"Test","sldsIcon":"action:approval","linkUrl":"http://www.test.com","bodyText":"Test"}]';
        //System.assertEquals(expectJson,action.Welcome_Mat_Tile_Config__c, '3:Tile Config JSON not matching');
    }
    
    public static testmethod void testUpdateJsonConfigMultiple(){
        Actions__c action = [select Id,Name,Welcome_Mat_Tile_Config__c from Actions__c limit 1];
        System.assertEquals(null, action.Welcome_Mat_Tile_Config__c,'4:Tile Config JSON is not null');
        Welcome_Mat_Tile__c tile = new Welcome_Mat_Tile__c(Title__c='Test',
                                                                                           Body__c='Test',
                                                                                           Link__c='http://www.test.com',
                                                                                           Icon__c='action:approval',
                                                                                           Action__c=action.Id);
        insert tile;
        tile = new Welcome_Mat_Tile__c(Title__c='Test2',
                                                       Body__c='Test2',
                                                       Link__c='http://www.test.com',
                                                       Icon__c='action:approval',
                                                       Action__c=action.Id);
        insert tile;
        action = [select Id,Name,Welcome_Mat_Tile_Config__c from Actions__c limit 1];
        //System.assert(action.Welcome_Mat_Tile_Config__c!=null, '5:Tile Config JSON is null');
        String expectJson = '[{"title":"Test","sldsIcon":"action:approval","linkUrl":"http://www.test.com","bodyText":"Test"},{"title":"Test2","sldsIcon":"action:approval","linkUrl":"http://www.test.com","bodyText":"Test2"}]';
        system.debug('6: JSON =  '+action.Welcome_Mat_Tile_Config__c);
        //System.assertEquals(expectJson,action.Welcome_Mat_Tile_Config__c, '6:Tile Config JSON not matching');
    }
    
    public static testmethod void testUpdateJsonConfigDelete(){
        Actions__c action = [select Id,Name,Welcome_Mat_Tile_Config__c from Actions__c limit 1];
        System.assertEquals(null, action.Welcome_Mat_Tile_Config__c,'4:Tile Config JSON is not null');
        Welcome_Mat_Tile__c tile = new Welcome_Mat_Tile__c(Title__c='Test',
                                                                                           Body__c='Test',
                                                                                           Link__c='http://www.test.com',
                                                                                           Icon__c='action:approval',
                                                                                           Action__c=action.Id);
        insert tile;
        tile = new Welcome_Mat_Tile__c(Title__c='Test2',
                                                       Body__c='Test2',
                                                       Link__c='http://www.test.com',
                                                       Icon__c='action:approval',
                                                       Action__c=action.Id);
        insert tile;
        action = [select Id,Name,Welcome_Mat_Tile_Config__c from Actions__c limit 1];
        //System.assert(action.Welcome_Mat_Tile_Config__c!=null, '5:Tile Config JSON is null');
        String expectJson = '[{"title":"Test","sldsIcon":"action:approval","linkUrl":"http://www.test.com","bodyText":"Test"},{"title":"Test2","sldsIcon":"action:approval","linkUrl":"http://www.test.com","bodyText":"Test2"}]';
        system.debug('6: JSON =  '+action.Welcome_Mat_Tile_Config__c);
        //System.assertEquals(expectJson,action.Welcome_Mat_Tile_Config__c, '6:Tile Config JSON not matching');
        delete tile;
        action = [select Id,Name,Welcome_Mat_Tile_Config__c from Actions__c limit 1];
        expectJson = '[{"title":"Test","sldsIcon":"action:approval","linkUrl":"http://www.test.com","bodyText":"Test"}]';
        system.debug('7: JSON =  '+action.Welcome_Mat_Tile_Config__c);
        //System.assertEquals(expectJson,action.Welcome_Mat_Tile_Config__c, '7:After Delete Tile Config JSON not matching');
    }
}