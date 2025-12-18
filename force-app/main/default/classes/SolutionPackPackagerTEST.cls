@isTest (seeAllData=true)
public class SolutionPackPackagerTEST 
{
    
    @isTest
    static void CreateDocumentsPackage()
    {
        SolutionPackPackager spController = new SolutionPackPackager();
        spController.selectedSolution = null;
        spController.ShowSolutionData();
        spController.GetQueries();
        spController.GetParameters();
        spController.GetTemplates();
        spController.GetReports();
        spController.GetQvars();
        spController.GetEmailTemplates();        
        spController.CreateDocumentsPackage();
        
        APXTConga4__Conga_Solution__c cs = new APXTConga4__Conga_Solution__c(Name = 'Test Document Folder', APXTConga4__Master_Object_Type__c = 'Account');
            database.insert(cs);
            System.debug('*********************** cs: ' + cs);
            
        //Create a Few Parameter Entries
        {
            List<APXTConga4__Conga_Solution_Parameter__c> testParameters = new List<APXTConga4__Conga_Solution_Parameter__c>();
            APXTConga4__Conga_Solution_Parameter__c csp1 = new APXTConga4__Conga_Solution_Parameter__c(APXTConga4__Name__c = 'FP0', APXTConga4__Value__c = '1', APXTConga4__Conga_Solution__c = cs.Id);
            testParameters.add(csp1);            
            APXTConga4__Conga_Solution_Parameter__c csp2 = new APXTConga4__Conga_Solution_Parameter__c(APXTConga4__Name__c = 'AC0', APXTConga4__Value__c = '1', APXTConga4__Conga_Solution__c = cs.Id);
            testParameters.add(csp2);  
            APXTConga4__Conga_Solution_Parameter__c csp3 = new APXTConga4__Conga_Solution_Parameter__c(APXTConga4__Name__c = 'Qvar0Format', APXTConga4__Value__c = '00010', APXTConga4__Conga_Solution__c = cs.Id);
            testParameters.add(csp3);                               
            database.insert(testParameters);
        }        
        
        //Create Template and Solution Template record for testing
        {    
            List<APXTConga4__Conga_Template__c> templatesToAdd = new List<APXTConga4__Conga_Template__c>();
            List<Attachment> AsToInsert = new List<Attachment>();
            
            APXTConga4__Conga_Template__c ct = new APXTConga4__Conga_Template__c(APXTConga4__Name__c = 'Dummy Template Record');
                templatesToAdd.add(ct);
            APXTConga4__Conga_Template__c ct2 = new APXTConga4__Conga_Template__c(APXTConga4__Name__c = 'Template Group Template', APXTConga4__Description__c = 'For Conga eMigrator', APXTConga4__Template_Group__c = 'TemplateGroup');
                templatesToAdd.add(ct2);   
                
            Database.insert(templatesToAdd); 
                
            Document templateDoc = [SELECT Id, Body, ContentType, Name FROM Document WHERE DeveloperName = 'Letter_File_ft1_SPT11547513' LIMIT 1];
            Attachment a = new Attachment(ParentId = ct.Id, Body = templateDoc.Body, ContentType = templateDoc.ContentType, IsPrivate = false, Name = templateDoc.Name);
                AsToInsert.add(a);
            Attachment a4 = new Attachment(ParentId = ct2.Id, Body = templateDoc.Body, ContentType = templateDoc.ContentType, IsPrivate = false, Name = templateDoc.Name);
                AsToInsert.add(a4);
                                    
            Database.insert(AsToInsert); 
                                     
            APXTConga4__Conga_Solution_Template__c cst = new APXTConga4__Conga_Solution_Template__c(APXTConga4__Conga_Solution__c = cs.Id, APXTConga4__Conga_Template__c = ct.Id);
                Database.insert(cst);
        }
             
        //Create CET and Solution CET record for testing        
        {
            List<APXTConga4__Conga_Email_Template__c> cetsToInsert = new List<APXTConga4__Conga_Email_Template__c>();
            List<Attachment> AsToInsert = new List<Attachment>();
            
            APXTConga4__Conga_Email_Template__c cet =  new APXTConga4__Conga_Email_Template__c(APXTConga4__Name__c = 'Dummy CET', APXTConga4__Is_Body_Attachment__c = true, APXTConga4__Subject__c = 'Subject');
                cetsToInsert.add(cet);
            APXTConga4__Conga_Email_Template__c cet2 =  new APXTConga4__Conga_Email_Template__c(APXTConga4__Name__c = 'Template Group CET', APXTConga4__Is_Body_Attachment__c = true, APXTConga4__Subject__c = 'Subject here', APXTConga4__Template_Group__c = 'CETTemplateGroup', APXTConga4__Description__c = 'For Conga eMigrator');
                cetsToInsert.add(cet2);
            
            Database.insert(cetsToInsert);    
                
            Document CETtemplateDoc = [SELECT Id, Body, ContentType, Name FROM Document WHERE DeveloperName = 'CET_Email_Template' LIMIT 1];
            Attachment a2 = new Attachment(ParentId = cet2.Id, Body = CETtemplateDoc.Body, ContentType = CETtemplateDoc.ContentType, IsPrivate = false, Name = CETtemplateDoc.Name);
                AsToInsert.add(a2);
            Attachment a3 = new Attachment(ParentId = cet.Id, Body = CETtemplateDoc.Body, ContentType = CETtemplateDoc.ContentType, IsPrivate = false, Name = CETtemplateDoc.Name);
                AsToInsert.add(a3);    
            
            Database.insert(AsToInsert);                                             
/***/                
            APXTConga4__Conga_Solution_Email_Template__c cset = new APXTConga4__Conga_Solution_Email_Template__c(APXTConga4__Conga_Solution__c = cs.Id, APXTConga4__Conga_Email_Template__c = cet.Id);
                Database.insert(cset);
        }
        
        //Create Query and Solution Query record for testing
        {        
            List<APXTConga4__Conga_Solution_Query__c> csqList = new List<APXTConga4__Conga_Solution_Query__c>();
            List<APXTConga4__Conga_Merge_Query__c> cmqList = new List<APXTConga4__Conga_Merge_Query__c>();
            
            APXTConga4__Conga_Merge_Query__c cmq = new APXTConga4__Conga_Merge_Query__c(APXTConga4__Name__c = 'Dummy Query', APXTConga4__Query__c = 'SELECT Id From Account');
                cmqList.add(cmq);
            APXTConga4__Conga_Merge_Query__c cmq1 = new APXTConga4__Conga_Merge_Query__c(APXTConga4__Name__c = 'Dummy Query 2', APXTConga4__Query__c = 'SELECT Id From Account WHERE Name = \'{pv0}\'');
                cmqList.add(cmq1);
            APXTConga4__Conga_Merge_Query__c cmq2 = new APXTConga4__Conga_Merge_Query__c(APXTConga4__Name__c = 'Dummy Query 3', APXTConga4__Query__c = 'SELECT Id From Account WHERE Name = \'{pv0}\' AND CreatedDate = \'{pv1)\'');
                cmqList.add(cmq2);
            APXTConga4__Conga_Merge_Query__c cmq3 = new APXTConga4__Conga_Merge_Query__c(APXTConga4__Name__c = 'Dummy Query 4', APXTConga4__Query__c = 'SELECT Id From Account WHERE Name = \'{pv0}\' AND CreatedDate = \'{pv1)\' AND Name != \'{pv2}\'');
                cmqList.add(cmq3);                
                                            
            Database.insert(cmqList);  
                              
            APXTConga4__Conga_Solution_Query__c csq1 = new APXTConga4__Conga_Solution_Query__c(APXTConga4__Conga_Solution__c = cs.Id, APXTConga4__Alias__c = 'QAlias101', APXTConga4__Conga_Query__c = cmq.Id);
                csqList.add(csq1);
            APXTConga4__Conga_Solution_Query__c csq2 = new APXTConga4__Conga_Solution_Query__c(APXTConga4__Conga_Solution__c = cs.Id, APXTConga4__Alias__c = 'QAlias102', APXTConga4__Conga_Query__c = cmq1.Id);
                csq2.APXTConga4__pv0__c = '+';
                csqList.add(csq2);  
            APXTConga4__Conga_Solution_Query__c csq3 = new APXTConga4__Conga_Solution_Query__c(APXTConga4__Conga_Solution__c = cs.Id, APXTConga4__Alias__c = 'QAlias103', APXTConga4__Conga_Query__c = cmq1.Id);
                csq3.APXTConga4__pv0__c = '{!Account.Id}';
                csqList.add(csq3); 
            APXTConga4__Conga_Solution_Query__c csq4 = new APXTConga4__Conga_Solution_Query__c(APXTConga4__Conga_Solution__c = cs.Id, APXTConga4__Alias__c = 'QAlias104', APXTConga4__Conga_Query__c = cmq2.Id);
                csq4.APXTConga4__pv0__c = '{!Account.Id}';
                csq4.APXTConga4__pv1__c = '{$User.Id}';                
                csqList.add(csq4);  
            APXTConga4__Conga_Solution_Query__c csq5 = new APXTConga4__Conga_Solution_Query__c(APXTConga4__Conga_Solution__c = cs.Id, APXTConga4__Alias__c = 'QAlias105', APXTConga4__Conga_Query__c = cmq3.Id);
                csq5.APXTConga4__pv0__c = '{!Account.Id}';
                csq5.APXTConga4__pv1__c = '{$User.Id}'; 
                csq5.APXTConga4__pv2__c = 'Some Text';                                
                csqList.add(csq5);                                                                           

            Database.insert(csqList);
        
        //Create a few QVar Entries
            List<APXTConga4__Conga_Solution_Parameter__c> testQvars = new List<APXTConga4__Conga_Solution_Parameter__c>();
            APXTConga4__Conga_Solution_Parameter__c qvp1 = new APXTConga4__Conga_Solution_Parameter__c(APXTConga4__Name__c = 'Qvar0Id', APXTConga4__Value__c = cmq.Id, APXTConga4__Conga_Solution__c = cs.Id);
            testQvars.add(qvp1 );            
            APXTConga4__Conga_Solution_Parameter__c qvp2 = new APXTConga4__Conga_Solution_Parameter__c(APXTConga4__Name__c = 'Qvar1Id', APXTConga4__Value__c = cmq1.Id + '?pv0={!Account.Id}', APXTConga4__Conga_Solution__c = cs.Id);
            testQvars.add(qvp2);   
            APXTConga4__Conga_Solution_Parameter__c qvp3 = new APXTConga4__Conga_Solution_Parameter__c(APXTConga4__Name__c = 'Qvar2Id', APXTConga4__Value__c = cmq2.Id + '?pv0={!Account.Id}~pv1={$User.Id}', APXTConga4__Conga_Solution__c = cs.Id);
            testQvars.add(qvp3);    
            APXTConga4__Conga_Solution_Parameter__c qvp4 = new APXTConga4__Conga_Solution_Parameter__c(APXTConga4__Name__c = 'Qvar3Id', APXTConga4__Value__c = cmq3.Id + '?pv0={!Account.Id}~pv1={$User.Id}~pv2=Text', APXTConga4__Conga_Solution__c = cs.Id);
            testQvars.add(qvp4);                                
            database.insert(testQvars);
        }            
                
        //Create Solution Report Record using the Report that is part of the package
        {
            //This is the report that is part of the package for testing purposes
            Report testReport = [SELECT Id, Name, DeveloperName FROM Report WHERE DeveloperName = 'CongaSP_This_Contacts_Activities'];
            List<APXTConga4__Conga_Solution_Report__c> csrList = new List<APXTConga4__Conga_Solution_Report__c >();
            
            APXTConga4__Conga_Solution_Report__c csr1 = new APXTConga4__Conga_Solution_Report__c(APXTConga4__Conga_Solution__c = cs.Id, APXTConga4__Alias__c = 'RA1', APXTConga4__Report_Id__c = testReport.Id, APXTConga4__Report_Name__c = testReport.Name);
                csrList.add(csr1);
            APXTConga4__Conga_Solution_Report__c csr5 = new APXTConga4__Conga_Solution_Report__c(APXTConga4__Conga_Solution__c = cs.Id, APXTConga4__Alias__c = 'RA5', APXTConga4__Report_Id__c = testReport.Id, APXTConga4__Report_Name__c = testReport.Name);
                csr5.APXTConga4__pv0__c = '+';
                csrList.add(csr5);                
            APXTConga4__Conga_Solution_Report__c csr2 = new APXTConga4__Conga_Solution_Report__c(APXTConga4__Conga_Solution__c = cs.Id, APXTConga4__Alias__c = 'RA2', APXTConga4__Report_Id__c = testReport.Id, APXTConga4__Report_Name__c = testReport.Name);
                csr2.APXTConga4__pv0__c = '{!Account.Id}';
                csrList.add(csr2);
            APXTConga4__Conga_Solution_Report__c csr3 = new APXTConga4__Conga_Solution_Report__c(APXTConga4__Conga_Solution__c = cs.Id, APXTConga4__Alias__c = 'RA3', APXTConga4__Report_Id__c = testReport.Id, APXTConga4__Report_Name__c = testReport.Name);
                csr3.APXTConga4__pv0__c = '{!Account.Id}';
                csr3.APXTConga4__pv1__c = '{!Contact.Id}';
                csrList.add(csr3);                
            APXTConga4__Conga_Solution_Report__c csr4 = new APXTConga4__Conga_Solution_Report__c(APXTConga4__Conga_Solution__c = cs.Id, APXTConga4__Alias__c = 'RA4', APXTConga4__Report_Id__c = testReport.Id, APXTConga4__Report_Name__c = testReport.Name);
                csr4.APXTConga4__pv0__c = '{!Account.Id}';
                csr4.APXTConga4__pv1__c = '{!Contact.Id}';
                csr4.APXTConga4__pv2__c = 'Text';
                csrList.add(csr4);                            
            Database.insert(csrList);
        }
        
        spController.temp = cs;            
        spController.selectedSolution = cs.Id;
        spController.Folders = [SELECT Id FROM Folder Where DeveloperName = 'CongaSP_Test_Document_Folder_Account'];                

        System.Debug('************************ Folders from Test Class: ' + spController.Folders);
        spController.ShowSolutionData();
        spController.GetQueries();
        spController.GetTemplates();
        spController.GetParameters();        
        spController.GetReports();
        spController.GetEmailTemplates();
        spController.GetQvars();
        spController.createTemplateStore();
        spController.getCanSeeCreateTemplateStoreButton();        
        spController.CreateDocumentsPackage();        
    } 
    
}