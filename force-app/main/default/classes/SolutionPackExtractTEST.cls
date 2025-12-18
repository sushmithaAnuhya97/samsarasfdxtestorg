@isTest (SeeAllData=True)
    
private class SolutionPackExtractTEST{

    private static testMethod void testSPLandingPageController(){               
        List<Folder> solutionPackFolders = [SELECT ID, DeveloperName, Name FROM Folder WHERE DeveloperName = 'CongaSP_Example_Starter_Pack' AND Type = 'Document'];
        Folder massTemplateStorageFolder = [SELECT ID, DeveloperName, Name FROM Folder WHERE DeveloperName = 'CongaSP_Templates_Folder' LIMIT 1];
        Folder massTemplateStorageFolder2 = [SELECT ID, DeveloperName, Name FROM Folder WHERE DeveloperName = 'CongaSP_Example_Starter_Pack' LIMIT 1];
        System.assertEquals(solutionPackFolders.size(), 1);        
        
        APXTConga4__Conga_Solution__c newTestCSR = new APXTConga4__Conga_Solution__c();
            newTestCSR.Name = 'Test SolMgr Record';
            newTestCSR.APXTConga4__Master_Object_Type__c = 'Opportunity';
            newTestCSR.APXTConga4__Master_Object_Type_Validator__c = 'Opportunity';
            database.insert(newTestCSR);
            
            SolutionPackLandingPageController splpc = new SolutionPackLandingPageController();
                splpc.getCreatedSolutionRecords();
                splpc.getCanSeeButton();
                splpc.getCanSeeRecordLinks();
                splpc.getCanUnpackSolutions();
                splpc.unpackSolutions();
                splpc.unpackNonSolutionTemplates();
                splpc.getNonSolutionTemplatesUnpackedValue();
                splpc.getCreatedSolutionsSize();
                splpc.getOrgType();
                splpc.setRemoteSiteAdded();

        SolutionPackLandingPageController.eFolders splpc2 = new SolutionPackLandingPageController.eFolders(massTemplateStorageFolder.Name, massTemplateStorageFolder.Id, massTemplateStorageFolder.DeveloperName);
                                
        SolutionPackLandingPageController.getNameSpaceVFServerURL();
        //SolutionPackLandingPageController.getCongaOLogoURL();
                
        APXTConga4__Conga_Solution__c csr = new APXTConga4__Conga_Solution__c();
        csr.Name = 'Example';
        csr.APXTConga4__Master_Object_Type__c = 'Case';
        csr.APXTConga4__Solution_Description__c = 'Created By Solution Pack';
        database.insert(csr);
        List<APXTConga4__Conga_Template__c> templates = new List<APXTConga4__Conga_Template__c>();
        APXTConga4__Conga_Template__c ct = new APXTConga4__Conga_Template__c();
        ct.APXTConga4__Name__c = 'Example Starter Pack';
        ct.APXTConga4__Description__c = 'Template Alias: [FileName]\nSort Order: 1';
        APXTConga4__Conga_Template__c ct2 = new APXTConga4__Conga_Template__c();
        ct2.APXTConga4__Name__c = 'Example Starter Pack cet_1';
        ct2.APXTConga4__Description__c = 'Template Alias: [FileName]\nSort Order: 1';
        templates.add(ct2);
        templates.add(ct);
        database.insert(templates);
        
        APXTConga4__Conga_Email_Template__c cet = new APXTConga4__Conga_Email_Template__c();
        cet.APXTConga4__Name__c = 'Email';
        cet.APXTConga4__Is_Body_Attachment__c = false;
        cet.APXTConga4__Subject__c = 'Proposal for {{OPPORTUNITY_NAME}}';
        cet.APXTConga4__Description__c = 'Created By Solution Pack for Composer Solution: ' + 'Example Starter Pack (Contact)';
        database.insert(cet);
        
        List<APXTConga4__Conga_Merge_Query__c> cmqList = new List<APXTConga4__Conga_Merge_Query__c>();
                
        APXTConga4__Conga_Merge_Query__c cmq = new APXTConga4__Conga_Merge_Query__c();
        cmq.APXTConga4__Name__c = 'Account Fields [AcctFields]';
        cmq.APXTConga4__Query__c = 'SELECT Name FROM Account'; 
        cmq.APXTConga4__Description__c = 'Created By Solution Pack for Composer Solution: ' + 'Example Starter Pack (Contact)';                 
        cmqList.add(cmq);
        
        APXTConga4__Conga_Merge_Query__c cmq1 = new APXTConga4__Conga_Merge_Query__c();
        cmq1.APXTConga4__Name__c = 'Contact Name 2 [ContactNames2]';
        cmq1.APXTConga4__Query__c = 'SELECT Name FROM Account';
        cmq1.APXTConga4__Description__c = 'Created By Solution Pack for Composer Solution: ' + 'Example Starter Pack (Contact)';                 
        cmqList.add(cmq1);
        
        //database.insert(cmqList);
        
        SolutionPackExtractController sp = new SolutionPackExtractController();
        sp.unpackSolutions(solutionPackFolders); 

        SolutionPackExtractController.unpackTemplateGroupTemplates(massTemplateStorageFolder2);
                
    }            

}