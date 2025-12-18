public with sharing class SolutionPackLandingPageController{

    public List<APXTConga4__Conga_Solution__c> createdSolutions = [SELECT Id, Name, APXTConga4__Master_Object_Type__c, APXTConga4__Sample_Record_Id__c, APXTConga4__Weblink_Id__c, APXTConga4__Button_Link_API_Name__c FROM APXTConga4__Conga_Solution__c WHERE Id != null AND CreatedDate = TODAY AND LastModifiedDate = TODAY AND APXTConga4__Weblink_Id__c = null ORDER BY APXTConga4__Master_Object_Type__c ASC, Id ASC];
    public Boolean canSeeButton = false;
    public Boolean canUnpackSolutions = true;
    public Boolean canSeeRecordLinks = false;
    public Boolean remoteSiteAdded {get;set;}
    public Boolean nonSolutionTemplatesUnpacked = false;
    private Organization orgType = [SELECT OrganizationType FROM Organization LIMIT 1];
    public List<eFolders> folders {get;set;}    
    
    public SolutionPackLandingPageController()
    {
        Map<String,String> qspMap = ApexPages.currentPage().getParameters();
            if(qspMap.get('nonSolutionTemplatesUnpacked') == 'true')
            {
                nonSolutionTemplatesUnpacked = true;
            }
        
        if(createdSolutions.size() >= 1)
        {
            canSeeButton = true;
        }
        List<Folder> massTemplateFolderCheck = [SELECT Id FROM Folder WHERE DeveloperName = 'CongaSP_Templates_Folder' AND NameSpacePrefix != 'ffaci' LIMIT 1];
        if(massTemplateFolderCheck.size() == 0)
        {
            nonSolutionTemplatesUnpacked = true;
        }
        else
        {
            List<Document> docsInMassTemplateFolder = [SELECT Id FROM Document WHERE FolderId = :massTemplateFolderCheck[0].Id];
            if (docsInMassTemplateFolder.size() == 0)
            {
                nonSolutionTemplatesUnpacked = true;
            }
        }
    }
    
    public List<APXTConga4__Conga_Solution__c> getCreatedSolutionRecords()
    {
        return createdSolutions;
    }
    
    public void createButtons()
    {
        canSeeButton = false;
        APXTConga4.ComposerSolutionExtension cse = new APXTConga4.ComposerSolutionExtension();
        
        for (APXTConga4__Conga_Solution__c cs : createdSolutions)
        {
           if (cs.APXTConga4__Master_Object_Type__c != 'APXTConga4__Composer_QuickMerge__c' && cs.APXTConga4__Master_Object_Type__c != 'Home Page')
           {
               try
               {
                   cse.createFullButtonString(cs);
               }
               catch (Exception ex)
               {
                   ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.FATAL, 'Something went wrong during the creation of the Composer Buttons.')); 
                   ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.FATAL, 'Navigate to the new Conga Solution records and create buttons individually for more information.'));
                   System.debug('************** Exception message in SolutionPackLandingPageController.createButtons: ' + ex.getMessage());                   
               }               
           }
        }
        canSeeRecordLinks = true;        
        database.update(cse.solutionRecordsToUpdate);
    }
        
    public Boolean getCanSeeButton()
    {
        return canSeeButton;
    }  
        
    public Boolean getCanUnpackSolutions()
    {
        if(createdSolutions.size() >= 1)
        {
            canUnpackSolutions = false;
        }   
        return canUnpackSolutions;
    }          
    
    public PageReference unpackSolutions()
    {        
        List<String> folderIds = new List<String>();
                
        for(eFolders ef : getDocumentFolders())
        {
            system.Debug('****************************** ef in SolutionPackLandingPageController.unpackSolutions: ' + ef);
            system.Debug('****************************** ef.isSelected in SolutionPackLandingPageController.unpackSolutions: ' + ef.isSelected);
            if(ef.isSelected == true)
            {
                folderIds.add(ef.folderId);
            }
        }
        system.Debug('********************** folderIds in SolutionPackLandingPageController.unpackSolutions: ' + folderIds);
        
        List<Folder> foldersToProcess = [SELECT Id, Name, DeveloperName FROM Folder WHERE Id IN :folderIds];        
        
        SolutionPackExtractController sp = new SolutionPackExtractController();
        sp.unpackSolutions(foldersToProcess);
        canUnpackSolutions = false;      
        
        String pageReturn = '';
        
        if (orgType.OrganizationType == 'Professional Edition')
        {
            canSeeRecordLinks = true;   
        }                                         
        
        if(nonSolutionTemplatesUnpacked == true)
        {
            pageReturn = '/apex/SolutionPackExtractor?nonSolutionTemplatesUnpacked=true';
        }
        else
        {
            nonSolutionTemplatesUnpacked = false;
            pageReturn = '/apex/SolutionPackExtractor';
        }

        PageReference p = new PageReference(pageReturn);
        p.setRedirect(true); 
        return p;                             
    }
    
    public Integer getCreatedSolutionsSize(){
        return createdSolutions.size();
    }
    
    public Boolean getCanSeeRecordLinks()
    {
        return canSeeRecordLinks;
    }
    
    public String getOrgType(){
        return orgType.OrganizationType;
    }
    
    public static String getNameSpaceVFServerURL()
    {
        return Url.getOrgDomainUrl().getHost();
    }
    
    /*    
    public static String getCongaOLogoURL()
    {
        List<Document> congaOLogoId = [SELECT Id FROM Document WHERE DeveloperName = 'Conga_O' and isDeleted = false]; 
        
        //The URL needed to use the Conga O logo that is part of the Composer package on the Composer Solution Manager pages
        //Avoid an error in the console about not using an https:// url to get that logo on to the pages       
        if(congaOLogoId.size() > 0)
        {
            return 'https://' + Url.getSalesforceBaseUrl().getHost().replace('visual','content') + '/servlet/servlet.ImageServer?id=' + congaOLogoId.get(0).Id + '&oid=' + UserInfo.getOrganizationId();
        }
        else
        {
            return '';
        }
    }
    */
    
    public List<eFolders> getDocumentFolders()
    {
        List<String> SMRecordNameandObject = New List<String>();
        
        for(APXTConga4__Conga_Solution__c csr : [SELECT ID, Name, APXTConga4__Master_Object_Type__c FROM APXTConga4__Conga_Solution__c LIMIT 2000])
        {
            SMRecordNameandObject.Add(csr.Name + ' (' + csr.APXTConga4__Master_Object_Type__c + ')');
        }
        
        if (folders == null)
        {
            folders = new List<eFolders>();
            for (Folder f: [SELECT ID, DeveloperName, NamespacePrefix, Name FROM Folder WHERE DeveloperName LIKE 'CongaSP_%' AND Type = 'Document' AND Name != :SMRecordNameandObject AND DeveloperName NOT IN ('CongaSP_Test_Document_Folder_Account', 'CongaSP_Example_Starter_Pack', 'CongaSP_Templates_Folder') AND NameSpacePrefix NOT IN ('APXTConga4', 'ffaci')])
            {
                eFolders ef = new eFolders(f.Name, f.Id, f.DeveloperName);
                folders.add(ef);    
            }
        }
        return folders;
    }
    
    public PageReference setRemoteSiteAdded()
    {
        remoteSiteAdded = true;
        return null;
    }    
    
    public PageReference unpackNonSolutionTemplates()
    {
        List<Folder> massTemplateFolder = [SELECT Id FROM Folder WHERE DeveloperName = 'CongaSP_Templates_Folder' LIMIT 1];
        if(massTemplateFolder.size() == 0)
        {
            ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Required Document Folder with the DeveloperName of \"CongaSP_Templates_Folder\" cannot be found.'));
        }
        else
        {
            System.debug('****************** massTemplateFolder in unpackNonSolutionTemplates method: ' + massTemplateFolder);
            SolutionPackExtractController.unpackTemplateGroupTemplates(massTemplateFolder[0]);
            nonSolutionTemplatesUnpacked = true;  
            ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.CONFIRM, 'Successfully extracted Non-Linked Conga Templates.'));                      
        }
        return null;    
    }
    
    public Boolean getNonSolutionTemplatesUnpackedValue()
    {
        return nonSolutionTemplatesUnpacked;
    }       
    
    public class eFolders{
        public Boolean isSelected {get;set;}
        public String folderName {get;set;}
        public String folderDevName {get;set;}
        public Id folderId {get;set;}
        
        public eFolders(String eFolderName, Id eFolderId, String eFolderDevName){
            folderName = eFolderName;
            isSelected = true;
            folderId = eFolderId;
            folderDevName = eFolderDevName;
        }        
    }

}