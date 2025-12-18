public with sharing class SolutionPackPackager
{
                
    /************************************************************************************************************************ 
    The code BELOW here is for creating a documents package from existing Conga Solutions   
    ************************************************************************************************************************/
    
    public List<APXTConga4__Conga_Solution_Query__c> queries;
    public List<APXTConga4__Conga_Solution_Report__c> reports;
    public List<APXTConga4__Conga_Solution_Template__c> templates;
    public List<APXTConga4__Conga_Solution_Email_Template__c> emailTemplates;
    public List<APXTConga4__Conga_Solution_Parameter__c> parameters;
    public List<APXTConga4__Conga_Solution_Parameter__c> Qvars;
    public List<APXTConga4__Conga_Merge_Query__c> qvarQueries;   
    @TestVisible APXTConga4__Conga_Solution__c temp;
    public List<string> results;
    public Id selectedSolution { get; set; }
    @TestVisible private Map<Id, APXTConga4__Conga_Solution__c> solutionMap;
    @TestVisible private List<Folder> Folders;
    private List<Document> docsToInsert;
    public Boolean displaySolutionData { get; set; }
    public String pageMessage { get; set; }
    private Boolean canSeeCreateTemplateStoreButton = false;
    private Id SolutionFolderId
    {
        get
        {
            System.Debug('***************** selectedSolution: ' + selectedSolution);
            if (temp ==  null) 
            {
                temp = solutionMap.get(selectedSolution);
                System.Debug(temp.Name);
                System.Debug(temp.APXTConga4__Master_Object_Type__c);
            }
            
            System.Debug('***************** temp: ' + temp);
            if (Folders == null)
            {
                Folders = [SELECT Id FROM Folder WHERE Name = :temp.Name +  ' (' + temp.APXTConga4__Master_Object_Type__c + ')' AND NameSpacePrefix NOT IN ('APXTConga4', 'ffaci')];    
            }                
            System.Debug('***************** Folders: ' + Folders);
            return Folders.size() == 1 ? Folders[0].Id : null;
        }
    }
    
    public SolutionPackPackager() 
    {
        Map<String,String> qspMap = ApexPages.currentPage().getParameters();
            pageMessage = qspMap.get('message');
            
        if(pageMessage != 'null' && pageMessage != null)
        {            
            ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.CONFIRM, pageMessage));                    
        }            
            
        List<APXTConga4__Conga_Template__c> validCongaTemplateRecords = [SELECT Id, Name, APXTConga4__Template_Group__c, APXTConga4__Name__c FROM APXTConga4__Conga_Template__c WHERE (((APXTConga4__Template_Group__c != null OR APXTConga4__Template_Group__c != '') AND APXTConga4__Description__c = 'For Conga eMigrator') AND Id NOT IN (SELECT APXTConga4__Conga_Template__c FROM APXTConga4__Conga_Solution_Template__c))];
        List<APXTConga4__Conga_Email_Template__c> validCongaCETRecords = [SELECT Id, Name, APXTConga4__Template_Group__c, APXTConga4__Name__c FROM APXTConga4__Conga_Email_Template__c WHERE (((APXTConga4__Template_Group__c != null OR APXTConga4__Template_Group__c != '') AND APXTConga4__Description__c = 'For Conga eMigrator') AND Id NOT IN (SELECT APXTConga4__Conga_Email_Template__c FROM APXTConga4__Conga_Solution_Email_Template__c))];
        if(validCongaTemplateRecords.size() > 0 || validCongaCETRecords.size() > 0)
        {
            canSeeCreateTemplateStoreButton = true;
        }
        
        docsToInsert = new List<Document>();
        GetSolutions();
    }
    
    public List<SelectOption> GetSolutions() 
    {
        List<SelectOption> options = new List<SelectOption>();
        List<APXTConga4__Conga_Solution__c> solutions = [SELECT Id, Name, APXTConga4__Master_Object_Type__c FROM APXTConga4__Conga_Solution__c];
        solutionMap = new Map<Id, APXTConga4__Conga_Solution__c>(solutions);

        for(APXTConga4__Conga_Solution__c c :solutions)
        {
            options.add(new SelectOption(c.Id, c.Name + ' (' + c.APXTConga4__Master_Object_Type__c + ')'));
        }
        // cannot add the blank option by index unless list already have values;
        if (options.size() > 0)
        {
            APXTConga4.SelectOptionSorter.doSort(options, APXTConga4.SelectOptionSorter.FieldToSort.Label);
                options.add(0, new SelectOption('', '--Select--'));
        }
        else
            options.add(new SelectOption('', '--Select--'));
        
        return options;
    }
    
    public PageReference ShowSolutionData()
    {
        displaySolutionData = selectedSolution != null;
        return null;
    }
      
    public PageReference CreateDocumentsPackage()
    {        
        string friendlyName;
        System.debug('******************* solutionMap in CreateDocumentsPackage:' + solutionMap);
         
        /*if (selectedSolution != null && SolutionFolderId != null && solutionMap != null && !solutionMap.isEmpty())
        {           
            friendlyName = solutionMap.Get(selectedSolution).Name + ' (' + solutionMap.get(selectedSolution).APXTConga4__Master_Object_Type__c + ')';    
        }*/        
        
        // make sure user selected a solution
        if (selectedSolution == null)
        {
            ApexPages.Message err = new ApexPages.Message(ApexPages.Severity.ERROR, 'You must select a Conga Solution.');
            ApexPages.addMessage(err);
            return null;
        }                
        
        // make sure Solution folder has been Created AND it doesn't have our docs already
        if (SolutionFolderId == null)
        {
            friendlyName = solutionMap.Get(selectedSolution).Name + ' (' + solutionMap.get(selectedSolution).APXTConga4__Master_Object_Type__c + ')';
            ApexPages.Message err = new ApexPages.Message(ApexPages.Severity.ERROR, 'Unable to locate a Document Folder that corresponds to your Conga Solution. Create a Document Folder with the same name as your Conga Solution: "' + friendlyName + '" and refresh this page.');
            ApexPages.addMessage(err);
            return null;
        }
        else
        {
            List<Document> currentDocs = [SELECT Name FROM Document WHERE FolderId = :SolutionFolderId];
            if (currentDocs.size() > 0)
            {
                ApexPages.Message err = new ApexPages.Message(ApexPages.Severity.ERROR, 'The selected Document Folder contains at least one Document. The Document Folder must be empty prior to assembling the Conga Solution components.');
                ApexPages.addMessage(err);
                return null;
            }
        }
        System.debug('**************** made it to here');
        
        CreateQueryDoc();
        CreateTemplateDoc();
        CreateReportDoc();
        CreateParameterDoc();
        CreateQvarDoc();
        CreateEmailTemplateDoc();
        
        insert docsToInsert;
        
        // refresh the page with a success message included, but the SelectOption back to default --Select--
        string solutionFolderString = string.valueOf(SolutionFolderId);
        PageReference SPPPage = new PageReference('/apex/SolutionPackPackager?message=Conga Solution components have been assembled in a Document Folder (' + solutionFolderString.substring(0,15) + ').');
        SPPPage.setRedirect(true);                
        return SPPPage;
    }
    
    public List<string> GetQueries()
    {
        System.debug('***************** selectedSolution in GetQueries method: ' + selectedSolution);
        
        queries = [
            SELECT APXTConga4__Alias__c, APXTConga4__Conga_Query__r.APXTConga4__Name__c, APXTConga4__Conga_Query__r.APXTConga4__Query__c, APXTConga4__pv0__c, APXTConga4__pv1__c, APXTConga4__pv2__c
            FROM APXTConga4__Conga_Solution_Query__c
            WHERE APXTConga4__Conga_Solution__c = :selectedSolution];
        
        results = new List<string>();
        for(APXTConga4__Conga_Solution_Query__c solutionQuery :queries)
        {
            results.add('Conga Query name: ' + solutionQuery.APXTConga4__Conga_Query__r.APXTConga4__Name__c);
            if (string.isNotBlank(solutionQuery.APXTConga4__Alias__c))
                results.add('    Query Alias: ' + solutionQuery.APXTConga4__Alias__c);
            if (string.isNotBlank(solutionQuery.APXTConga4__Conga_Query__r.APXTConga4__Query__c))
                results.add('    SOQL Statement: ' + solutionQuery.APXTConga4__Conga_Query__r.APXTConga4__Query__c);
        }
        return results;
    }
    
    public List<string> GetQvars()
    {
        Qvars = [SELECT APXTConga4__Name__c, APXTConga4__Value__c FROM APXTConga4__Conga_Solution_Parameter__c WHERE APXTConga4__Conga_Solution__c = :selectedSolution ORDER BY APXTConga4__Name__c ASC];
        
        List<String> qvarQueryIds = new List<String>();
        results = new List<string>();
        
        for(APXTConga4__Conga_Solution_Parameter__c solutionParameter : Qvars)
        {
            if (String.isNotBlank(solutionParameter.APXTConga4__Name__c) && solutionParameter.APXTConga4__Name__c.startsWithIgnoreCase('qvar') && !solutionParameter.APXTConga4__Name__c.containsIgnoreCase('format'))
            {
                results.add(solutionParameter.APXTConga4__Name__c + '=' + solutionParameter.APXTConga4__Value__c);
                
                if(!solutionParameter.APXTConga4__Value__c.containsIgnoreCase('?pv'))
                {
                    qvarQueryIds.add(solutionParameter.APXTConga4__Value__c);
                }
                else
                {
                    qvarQueryIds.add(solutionParameter.APXTConga4__Value__c.subString(0,15));
                }                
            }            
        }        
        System.debug('***************** qvarQueryIds after for loop in GetQvars: ' + qvarQueryIds);
        
        if (qvarQueryIds.size() > 0)
        {        
            qvarQueries = [SELECT Name, APXTConga4__Name__c, Id, APXTConga4__Query__c FROM APXTConga4__Conga_Merge_Query__c WHERE ID = :qvarQueryIds];
        }
        System.debug('***************** qvarQueries after for loop in GetQvars: ' + qvarQueries);        
        
        return results;
    }    
    
    public List<string> GetTemplates()
    {
        templates = [
            SELECT  APXTConga4__Conga_Template__c, APXTConga4__Template_Name__c, APXTConga4__Conga_Template__r.Id, APXTConga4__Conga_Template__r.APXTConga4__Template_Group__c, APXTConga4__Sort_Order__c, APXTConga4__Output_File_Name__c
            FROM APXTConga4__Conga_Solution_Template__c
            WHERE APXTConga4__Conga_Solution__c = :selectedSolution
                ORDER BY APXTConga4__Sort_Order__c];
        
        results = new List<string>();
        for(APXTConga4__Conga_Solution_Template__c solutionTemplate : templates)
        {
            Attachment a = GetAttachment(solutionTemplate.APXTConga4__Conga_Template__c);
            results.add('Conga Template Name: ' + solutionTemplate.APXTConga4__Template_Name__c);
            if (string.isNotBlank(solutionTemplate.APXTConga4__Conga_Template__r.APXTConga4__Template_Group__c))
                results.add('    Conga Template Group: ' + solutionTemplate.APXTConga4__Conga_Template__r.APXTConga4__Template_Group__c);
            //results.add('    Conga Template Group: ' + solutionTemplate.APXTConga4__Template_Name__c);
        }
        return results;
    }
    
    public List<string> GetReports()
    {
        reports = [
            SELECT APXTConga4__Alias__c, APXTConga4__Report_Name__c, APXTConga4__Report_Id__c, APXTConga4__pv0__c, APXTConga4__pv1__c, APXTConga4__pv2__c
            FROM APXTConga4__Conga_Solution_Report__c
            WHERE APXTConga4__Conga_Solution__c = :selectedSolution];
        
        results = new List<string>();
        for(APXTConga4__Conga_Solution_Report__c solutionReport :reports)
        {
            results.add('Report Name: ' +solutionReport.APXTConga4__Report_Name__c);
            if (string.isNotBlank(solutionReport.APXTConga4__Alias__c))
                results.add('    Report Alias: ' + solutionReport.APXTConga4__Alias__c);
            if (string.isNotBlank(solutionReport.APXTConga4__pv0__c))
                results.add('    Report pv0: ' + solutionReport.APXTConga4__pv0__c);
            if (string.isNotBlank(solutionReport.APXTConga4__pv1__c))
                results.add('    Report pv1: ' + solutionReport.APXTConga4__pv1__c);
            if (string.isNotBlank(solutionReport.APXTConga4__pv2__c))
                results.add('    Report pv2: ' + solutionReport.APXTConga4__pv2__c);
        }
        return results;
    }
    
    public List<string> GetEmailTemplates()
    {
        emailTemplates = [
            SELECT APXTConga4__Conga_Email_Template__c,  APXTConga4__Comments__c,
            APXTConga4__Conga_Email_Template__r.APXTConga4__Name__c,
            APXTConga4__Conga_Email_Template__r.APXTConga4__Template_Group__c,
            APXTConga4__Conga_Email_Template__r.APXTConga4__Subject__c,
            APXTConga4__Conga_Email_Template__r.APXTConga4__Is_Body_Attachment__c
            FROM APXTConga4__Conga_Solution_Email_Template__c
            WHERE APXTConga4__Conga_Solution__c = :selectedSolution];
        
        results = new List<string>();
        // only one email template allowed on a solution;
        if (emailTemplates.size() > 0)
        {
            results.add('Conga Email Template Name: ' + emailTemplates[0].APXTConga4__Conga_Email_Template__r.APXTConga4__Name__c); 
            if (string.isNotBlank(emailTemplates[0].APXTConga4__Conga_Email_Template__r.APXTConga4__Template_Group__c))
                results.add('    Conga Email Template Group: ' + emailTemplates[0].APXTConga4__Conga_Email_Template__r.APXTConga4__Template_Group__c);
            if (string.isNotBlank(emailTemplates[0].APXTConga4__Conga_Email_Template__r.APXTConga4__Subject__c))
                results.add('    Conga Email Subject: ' + emailTemplates[0].APXTConga4__Conga_Email_Template__r.APXTConga4__Subject__c);
            if (string.isNotBlank(emailTemplates[0].APXTConga4__Comments__c))
                results.add('    Conga Email Template Comments: ' + emailTemplates[0].APXTConga4__Comments__c); 
        }
        return results;
    }
    
    public List<string> GetParameters()
    {
        parameters = [SELECT APXTConga4__Name__c, APXTConga4__Value__c FROM APXTConga4__Conga_Solution_Parameter__c WHERE APXTConga4__Conga_Solution__c = :selectedSolution];
        
        results = new List<string>();
        for(APXTConga4__Conga_Solution_Parameter__c solutionParameter : parameters)
        {
            if (String.isNotBlank(solutionParameter.APXTConga4__Name__c) &&
            !solutionParameter.APXTConga4__Name__c.EqualsIgnoreCase('qvar0id') &&
            !solutionParameter.APXTConga4__Name__c.EqualsIgnoreCase('qvar1id') &&
            !solutionParameter.APXTConga4__Name__c.EqualsIgnoreCase('qvar2id') &&
            !solutionParameter.APXTConga4__Name__c.EqualsIgnoreCase('qvar3id') &&
            !solutionParameter.APXTConga4__Name__c.EqualsIgnoreCase('qvar4id') &&
            !solutionParameter.APXTConga4__Name__c.EqualsIgnoreCase('qvar5id'))
            {
                results.add(solutionParameter.APXTConga4__Name__c + '=' + solutionParameter.APXTConga4__Value__c);
            }
        }
        return results;
    }
    
    private void CreateQueryDoc()
    {
        System.debug('***************** queries in CreateQueryDoc method: ' + queries);
        
        if (queries == null || queries.size() == 0)
            return;
        
        string content = '';
        for(APXTConga4__Conga_Solution_Query__c solutionQuery : queries)
        {
            if(solutionQuery.APXTConga4__Conga_Query__r.APXTConga4__Name__c.containsIgnoreCase('[') && solutionQuery.APXTConga4__Conga_Query__r.APXTConga4__Name__c.containsIgnoreCase(']'))
            {
                Integer openSquareBracketLocation = solutionQuery.APXTConga4__Conga_Query__r.APXTConga4__Name__c.IndexOf('[');
                Integer closeSquareBracketLocation = solutionQuery.APXTConga4__Conga_Query__r.APXTConga4__Name__c.IndexOf(']');
                if(openSquareBracketLocation != 0)
                {
                    content += solutionQuery.APXTConga4__Conga_Query__r.APXTConga4__Name__c.subString(0,(openSquareBracketLocation - 1)) + ' [' + solutionQuery.APXTConga4__Alias__c + '] ';
                }
                else
                {
                    content += solutionQuery.APXTConga4__Conga_Query__r.APXTConga4__Name__c.subString((closeSquareBracketLocation + 1), (solutionQuery.APXTConga4__Conga_Query__r.APXTConga4__Name__c.Length())) + ' [' + solutionQuery.APXTConga4__Alias__c + '] ';
                }
            }
            else
            {
                content += solutionQuery.APXTConga4__Conga_Query__r.APXTConga4__Name__c + ' [' + solutionQuery.APXTConga4__Alias__c + '] ';
            }
            
            string soql = solutionQuery.APXTConga4__Conga_Query__r.APXTConga4__Query__c;
            if (!soql.containsIgnoreCase('pv0') && !soql.containsIgnoreCase('pv1') && !soql.containsIgnoreCase('pv2'))
                content += soql;
            else
            {
                 if (soql.containsIgnoreCase('pv0') && string.isNotBlank(solutionQuery.APXTConga4__pv0__c))
                        soql = soql.replace('{pv0}', solutionQuery.APXTConga4__pv0__c);
                
                if (soql.containsIgnoreCase('pv1') && string.isNotBlank(solutionQuery.APXTConga4__pv1__c))
                        soql = soql.replace('{pv1}', +  solutionQuery.APXTConga4__pv1__c);
                
                if (soql.containsIgnoreCase('pv2') && string.isNotBlank(solutionQuery.APXTConga4__pv2__c))
                        soql = soql.replace('{pv2}', +  solutionQuery.APXTConga4__pv2__c);
                
                content += soql;
            }
            content += ';\n';
        }
        Document doc = MakeDocument('Queries.txt', 'application/text', 'Queries', blob.valueOf(content));
        docsToInsert.add(doc);
    }
    
    private void CreateQvarDoc()
    {
        System.debug('********************* Qvars in CreateQvarDoc method: ' + Qvars);
        System.debug('********************* qvarQueries in CreateQvarDoc method: ' + qvarQueries);
        
        if (qvarQueries == null || qvarQueries.size() == 0)
            return;
            
        //if (qvarQueries.size() == 0)
            //return;   
        
        List<APXTConga4__Conga_Solution_Parameter__c> qvarParams = [SELECT APXTConga4__Name__c, APXTConga4__Value__c FROM APXTConga4__Conga_Solution_Parameter__c WHERE APXTConga4__Conga_Solution__c = :selectedSolution AND APXTConga4__Name__c LIKE 'qvar%Id' ORDER BY APXTConga4__Name__c ASC];
        System.debug('********************* qvarParams in CreateQvarDoc method: ' + qvarParams);
        
        List<String> qvarQueryIdsFromParams = new List<String>();
        
        for(APXTConga4__Conga_Solution_Parameter__c CSQvarParam : qvarParams)
        {
            if(CSQvarParam.APXTConga4__Value__c.Length() >= 15)
            {
                qvarQueryIdsFromParams.add(CSQvarParam.APXTConga4__Value__c.subString(0,15));                
            }
        }
        
        Map<String,String> queryMap = new Map<String,String>();
        qvarQueries.Clear();
        qvarQueries = [SELECT Name, APXTConga4__Name__c, Id, APXTConga4__Query__c FROM APXTConga4__Conga_Merge_Query__c WHERE ID = :qvarQueryIdsFromParams];
                  
        for (APXTConga4__Conga_Merge_Query__c qvarQuery : qvarQueries)  
        {
            String fifteenCharId = (String) qvarQuery.Id;
            queryMap.put(fifteenCharId.SubString(0,15), qvarQuery.APXTConga4__Query__c);
        } 
        System.debug('***************** queryMap in CreateQvarDoc: ' + queryMap);
         
        string content = ''; 
        
        for(APXTConga4__Conga_Solution_Parameter__c CSQvarParam : qvarParams)
        {
            if(CSQvarParam.APXTConga4__Value__c.Length() >= 15)
            {
                if(CSQvarParam.APXTConga4__Value__c.Length() <= 18)
                {
                    System.debug('***************** This Qvar did not have a pv to deal with');                                           
                    content += '[' + CSQvarParam.APXTConga4__Name__c.subString(0,5).toUpperCase() + '] ' + queryMap.get(CSQvarParam.APXTConga4__Value__c) + ';';                    
                }
                else
                {
                    System.debug('***************** This Qvar has at least one pv to deal with');                                           

                    if(CSQvarParam.APXTConga4__Value__c.containsIgnoreCase('?pv0=') && !CSQvarParam.APXTConga4__Value__c.containsIgnoreCase('~'))
                    {            
                        System.debug('***************** This Qvar has only a pv0 to deal with');                                           
                        
                        String queryId = CSQvarParam.APXTConga4__Value__c.subString(0,15);                        
                        String querySyntax = queryMap.get(queryId);
                        //Integer paramValueTotalLength = CSQvarParam.APXTConga4__Value__c.Length();                                                
                        
                        Integer pv0Location = CSQvarParam.APXTConga4__Value__c.IndexOf('?pv0=');
                        Integer startOfpv0Value = pv0Location + 5;

                        String pv0Value = CSQvarParam.APXTConga4__Value__c.subString(startOfpv0Value);
                            System.debug('***************** pv0Value: ' + pv0Value);                                                                   
                        
                        content += '[' + CSQvarParam.APXTConga4__Name__c.subString(0,5).toUpperCase() + '] ' + querySyntax.replace('{pv0}', pv0Value) + ';';
                    }
                    else if(CSQvarParam.APXTConga4__Value__c.containsIgnoreCase('?pv0=') && CSQvarParam.APXTConga4__Value__c.containsIgnoreCase('~pv1=') && !CSQvarParam.APXTConga4__Value__c.containsIgnoreCase('~pv2='))
                    {            
                        System.debug('***************** This Qvar has a pv0 and a pv1, but no pv2, to deal with');                                           
                        
                        String queryId = CSQvarParam.APXTConga4__Value__c.subString(0,15);                        
                        String querySyntax = queryMap.get(queryId);
                                                
                        Integer pv0Location = CSQvarParam.APXTConga4__Value__c.IndexOf('?pv0=');
                        Integer startOfpv0Value = pv0Location + 5;
                        Integer pv1Location = CSQvarParam.APXTConga4__Value__c.IndexOf('~pv1=');
                        Integer startOfpv1Value = pv1Location + 5;                               
                        
                        String pv0Value = CSQvarParam.APXTConga4__Value__c.subString(startOfpv0Value, pv1Location);
                            System.debug('***************** pv0Value: ' + pv0Value);                            
                                                                 
                        String pv1Value = CSQvarParam.APXTConga4__Value__c.subString(startOfpv1Value);
                            System.debug('***************** pv1Value: ' + pv1Value);                                                                   
                        
                        content += '[' + CSQvarParam.APXTConga4__Name__c.subString(0,5).toUpperCase() + '] ' + querySyntax.replace('{pv0}', pv0Value).replace('{pv1}', pv1Value) + ';';
                    }
                    else if(CSQvarParam.APXTConga4__Value__c.containsIgnoreCase('?pv0=') && CSQvarParam.APXTConga4__Value__c.containsIgnoreCase('~pv1=') && CSQvarParam.APXTConga4__Value__c.containsIgnoreCase('~pv2='))
                    {            
                        System.debug('***************** This Qvar has a pv0 and a pv1, but no pv2, to deal with');                                           
                        
                        String queryId = CSQvarParam.APXTConga4__Value__c.subString(0,15);                        
                        String querySyntax = queryMap.get(queryId);
                                                
                        Integer pv0Location = CSQvarParam.APXTConga4__Value__c.IndexOf('?pv0=');
                        Integer startOfpv0Value = pv0Location + 5;
                        Integer pv1Location = CSQvarParam.APXTConga4__Value__c.IndexOf('~pv1=');
                        Integer startOfpv1Value = pv1Location + 5;      
                        Integer pv2Location = CSQvarParam.APXTConga4__Value__c.IndexOf('~pv2=');
                        Integer startOfpv2Value = pv2Location + 5;                                                    
                        
                        String pv0Value = CSQvarParam.APXTConga4__Value__c.subString(startOfpv0Value, pv1Location);
                            System.debug('***************** pv0Value: ' + pv0Value);                                                                                             
                        String pv1Value = CSQvarParam.APXTConga4__Value__c.subString(startOfpv1Value, pv2Location);
                            System.debug('***************** pv1Value: ' + pv1Value);     
                        String pv2Value = CSQvarParam.APXTConga4__Value__c.subString(startOfpv2Value);
                            System.debug('***************** pv2Value: ' + pv2Value);     
                                                                                                                                                                                                            
                        content += '[' + CSQvarParam.APXTConga4__Name__c.subString(0,5).toUpperCase() + '] ' + querySyntax.replace('{pv0}', pv0Value).replace('{pv1}', pv1Value).replace('{pv2}', pv2Value) + ';';
                    }                                       
                }
                content += '\n';
            }
        }
        System.debug('***************** content in CreateQvarDoc at the end of the method: ' + content);                       
        Document doc = MakeDocument('Qvars.txt', 'application/text', 'Qvars', blob.valueOf(content));  
        docsToInsert.add(doc);          
    }
    
    private void CreateTemplateDoc()
    {
        if (templates == null || templates.size() == 0)
            return;
            
        integer counter = 1;
        for(APXTConga4__Conga_Solution_Template__c solutionTemplate : templates)
        {
            Attachment a = GetAttachment(solutionTemplate.APXTConga4__Conga_Template__c);
            if(a.Id != null)                
            {
                Document doc = MakeDocument(solutionTemplate.APXTConga4__Template_Name__c, a.ContentType, 'FT' + counter + '_SPT', a.Body);
                //doc.DeveloperName = 'FT' + counter + '_SPT' + datetime.now().getTime();
                doc.Type = a.Name.substring(a.Name.LastIndexOf('.') + 1);
                doc.Keywords = solutionTemplate.APXTConga4__Output_File_Name__c;
                doc.Description = solutionTemplate.APXTConga4__Conga_Template__r.APXTConga4__Template_Group__c;
                docsToInsert.add(doc);
            }
            counter++;
        }
    }
    
    private void CreateReportDoc()
    {
        if (reports == null || reports.size() == 0)
            return;
        
        List<string> reportIds = new List<string>();
        for(APXTConga4__Conga_Solution_Report__c csr : reports)
        {
            reportIds.add(csr.APXTConga4__Report_Id__c);
        }
        List<Report> actualReports = [SELECT DeveloperName, Id FROM Report WHERE Id = :reportIds];
        Map<Id, Report> reportMap = new Map<Id, Report>(actualReports);
        
        string content = '';
        for(APXTConga4__Conga_Solution_Report__c solutionReport : reports)
        {
            content += '[' + solutionReport.APXTConga4__Alias__c + ']' + reportMap.get(solutionReport.APXTConga4__Report_Id__c).DeveloperName;
            if (string.isNotBlank(solutionReport.APXTConga4__pv0__c) || string.isNotBlank(solutionReport.APXTConga4__pv1__c) || string.isNotBlank(solutionReport.APXTConga4__pv2__c))
                content += '?';
            if (string.isNotBlank(solutionReport.APXTConga4__pv0__c))
                content += 'pv0=' + solutionReport.APXTConga4__pv0__c;
            if (string.isNotBlank(solutionReport.APXTConga4__pv1__c))
            {
                if (string.isNotBlank(solutionReport.APXTConga4__pv0__c))
                        content += '~pv1=' + solutionReport.APXTConga4__pv1__c;
                else
                    content += 'pv1=' + solutionReport.APXTConga4__pv1__c;
            }
            if (string.isNotBlank(solutionReport.APXTConga4__pv2__c))
            {
                if (string.isNotBlank(solutionReport.APXTConga4__pv0__c) || string.isNotBlank(solutionReport.APXTConga4__pv1__c))
                        content += '~pv2=' + solutionReport.APXTConga4__pv2__c;
                else
                    content += 'pv2=' + solutionReport.APXTConga4__pv2__c;
            }
            content += ',\n';
        }
        Document doc = MakeDocument('Reports.txt', 'application/text', 'Reports', blob.valueOf(content));
        docsToInsert.add(doc);
    }
    
    private void CreateParameterDoc()
    {
        if (parameters == null || parameters.size() == 0)
            return;
        
        string content = '';
        for(APXTConga4__Conga_Solution_Parameter__c solutionParameter : parameters)
        {
            if (String.isNotBlank(solutionParameter.APXTConga4__Name__c) &&
            !solutionParameter.APXTConga4__Name__c.EqualsIgnoreCase('qvar0id') &&
            !solutionParameter.APXTConga4__Name__c.EqualsIgnoreCase('qvar1id') &&
            !solutionParameter.APXTConga4__Name__c.EqualsIgnoreCase('qvar2id') &&
            !solutionParameter.APXTConga4__Name__c.EqualsIgnoreCase('qvar3id') &&
            !solutionParameter.APXTConga4__Name__c.EqualsIgnoreCase('qvar4id') &&
            !solutionParameter.APXTConga4__Name__c.EqualsIgnoreCase('qvar5id'))
            {
                content += '&' + solutionParameter.APXTConga4__Name__c + '=' + solutionParameter.APXTConga4__Value__c + '\n';
            }
        }
        Document doc = MakeDocument('Parameters.txt', 'application/text', 'Parameters', blob.valueOf(content));
        docsToInsert.add(doc);
    }
    
    private void CreateEmailTemplateDoc()
    {
        if (emailTemplates != null && emailTemplates.size() > 0)
        {
            // having the template as an attachment is a requirement, so we check that first; if it's not there, do nothing;
            if (!emailTemplates[0].APXTConga4__Conga_Email_Template__r.APXTConga4__Is_Body_Attachment__c)
                return;
            
            // Get attachment
            Attachment a = GetAttachment(emailTemplates[0].APXTConga4__Conga_Email_Template__c);
            System.debug('********************** Attachment a in CreateEmailTemplateDoc: ' + a);
            if(a.Id != null)
            {
                Document doc = MakeDocument(emailTemplates[0].APXTConga4__Conga_Email_Template__r.APXTConga4__Name__c, a.ContentType, 'CET', a.Body);
                //doc.DeveloperName = 'CET_' + datetime.now().getTime();
                doc.Type = 'html';
                doc.Description = emailTemplates[0].APXTConga4__Conga_Email_Template__r.APXTConga4__Subject__c;
                doc.Keywords = emailTemplates[0].APXTConga4__Conga_Email_Template__r.APXTConga4__Template_Group__c;
                docsToInsert.add(doc);
            }
        }
    }
    
    private Attachment GetAttachment(Id objectId)
    {
        List<Attachment> a = [
            SELECT Body, Name, ContentType
            FROM Attachment 
            WHERE ParentId = :objectId
            ORDER BY CreatedDate DESC LIMIT 1];
        
        if (a.size() > 0)
            return a[0];
        else return new Attachment();
    }
    
    private Document MakeDocument(string docName, string contentType, string devName, blob content)
    {
        Document doc = new Document(
            Name = docName, 
            ContentType = contentType, 
            Body = content, 
            FolderId = SolutionFolderId,
            DeveloperName = devName + '_' + datetime.now().getTime());
        
        return doc;
    }
    
    
    /************************************************************************************************************************ 
    The code BELOW here is for mass packaging Conga Templates in the case where a SP utilizes a "Template Group" architecture
    Templates are not always linked to Solutions - Template Grouping is being used to "select templates" for each Solution  
    ************************************************************************************************************************/
    
    public PageReference createTemplateStore()
    {            
        String nowFormatted = String.valueOf(System.Now()).replace('-', '_').replace(':', '_').replace(' ', '_');
        List<Folder> fList = [SELECT Id FROM Folder WHERE DeveloperName = 'CongaSP_Templates_Folder' AND NameSpacePrefix NOT IN ('APXTConga4', 'ffaci') LIMIT 1];
        
        Map<Id, String> nonLinkedTemplateGroupMap = new Map<Id, String>();
        Map<Id, String> nonLinkedTemplateNameMap = new Map<Id, String>();        
        List<Id> congaTemplateRecordIds = new List<Id>();
        List<Document> templateGroupDocuments = new List<Document>();
        
        Map<Id, String> nonLinkedCETTemplateGroupMap = new Map<Id, String>();
        Map<Id, String> nonLinkedCETTemplateNameMap = new Map<Id, String>();
        Map<Id, String> nonLinkedCETSubject = new Map<Id, String>();                   
        List<Id> congaCETTemplateRecordIds = new List<Id>();
        List<Document> CETTemplateGroupDocuments = new List<Document>();
        
        if(fList == null || fList.size() == 0)
        {
            ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.FATAL, 'The required Document Folder cannot be located. Be sure a folder with the precise DeveloperName of \"CongaSP_Templates_Folder\" exists and is accessible.'));
            return null;
        }
        
        List<Document> docs = [SELECT Id FROM Document WHERE FolderID = :fList[0].Id LIMIT 2000];
        if(docs.size() > 0)
        {
            if(docs.size() == 1)
            {
                ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.FATAL, '\"CongaSP_Templates_Folder\" must be empty of Documents. There is currently 1 Document in the Document Folder. (' + fList[0].Id + ')'));
            }
            else
            {
                ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.FATAL, '\"CongaSP_Templates_Folder\" must be empty of Documents. There are currently ' + docs.size() + ' Documents in the Document Folder. (' + fList[0].Id + ')'));
            }
            return null;            
        }
            
        //Grabbing the Conga Template records that are a Conga Solution Template and have a Template Group and the correct Description value
        for (APXTConga4__Conga_Template__c ct : [SELECT Id, Name, APXTConga4__Template_Group__c, APXTConga4__Name__c FROM APXTConga4__Conga_Template__c WHERE (((APXTConga4__Template_Group__c != null OR APXTConga4__Template_Group__c != '') AND APXTConga4__Description__c = 'For Conga eMigrator') AND Id NOT IN (SELECT APXTConga4__Conga_Template__c FROM APXTConga4__Conga_Solution_Template__c))])
        {
            nonLinkedTemplateGroupMap.put(ct.Id, ct.APXTConga4__Template_Group__c); 
            nonLinkedTemplateNameMap.put(ct.Id, ct.APXTConga4__Name__c); 
            congaTemplateRecordIds.add(ct.Id);           
        }  
        
        Integer i = 0;       
        for(Attachment a: [SELECT Id, ContentType, Name, Body, ParentId FROM Attachment WHERE ParentId = :congaTemplateRecordIds])
        {
            Document d = new Document();
                d.FolderId = fList[0].Id;
                d.Body = a.Body;
                d.Type = a.Name.subString(a.Name.LastIndexOf('.') + 1, a.Name.Length());
                d.ContentType = a.ContentType;                
                d.Description = nonLinkedTemplateGroupMap.get(a.ParentId);
                d.Name = nonLinkedTemplateNameMap.get(a.ParentId);
                d.DeveloperName = 'Mass_Template_Batch_FT' + i + '_SPT_' + nowFormatted;
            
            templateGroupDocuments.add(d);
            i++;
        }
        
        //Grabbing the Conga Email Template records that are a Conga Solution Email Template and have a Template Group and the correct Description value
        for (APXTConga4__Conga_Email_Template__c cet : [SELECT Id, Name, APXTConga4__Template_Group__c, APXTConga4__Name__c, APXTConga4__Subject__c FROM APXTConga4__Conga_Email_Template__c WHERE (((APXTConga4__Template_Group__c != null OR APXTConga4__Template_Group__c != '') AND APXTConga4__Description__c = 'For Conga eMigrator') AND Id NOT IN (SELECT APXTConga4__Conga_Email_Template__c FROM APXTConga4__Conga_Solution_Email_Template__c))])
        {
            nonLinkedCETTemplateGroupMap.put(cet.Id, cet.APXTConga4__Template_Group__c); 
            nonLinkedCETTemplateNameMap.put(cet.Id, cet.APXTConga4__Name__c);
            nonLinkedCETSubject.put(cet.Id, cet.APXTConga4__Subject__c);
            congaCETTemplateRecordIds.add(cet.Id);           
        } 
        
        i = 0;       
        for(Attachment a: [SELECT Id, ContentType, Name, Body, ParentId FROM Attachment WHERE ParentId = :congaCETTemplateRecordIds])
        {
            Document d = new Document();
                d.FolderId = fList[0].Id;
                d.Body = a.Body;
                d.Type = a.Name.subString(a.Name.LastIndexOf('.') + 1, a.Name.Length());
                //d.Type = 'html';
                d.ContentType = 'text/html';                
                d.Description = nonLinkedCETSubject.get(a.ParentId);
                d.Keywords = nonLinkedCETTemplateGroupMap.get(a.ParentId);
                d.Name = nonLinkedCETTemplateNameMap.get(a.ParentId);
                d.DeveloperName = 'Mass_Batch_CET_' + i + '_' + nowFormatted;
            
            CETTemplateGroupDocuments.add(d);
            i++;
        } 

        if(templateGroupDocuments.size() == 0 && CETTemplateGroupDocuments.size() == 0)
        {
            ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.FATAL, 'No valid Conga Template records found.'));
            return null;     
        }        
        else
        {        
            try{
                database.insert(templateGroupDocuments);
                database.insert(CETTemplateGroupDocuments);
            }
            catch (Exception ex)
            {
                ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Make sure that the Recycle Bin has been emptied of any Documents referenced below.'));
                //ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.FATAL, '' + ex.getMessage()));
                return null;                
            }
            
            PageReference SPPPage = new PageReference('/apex/SolutionPackPackager?message=Non-linked Conga Templates and/or Conga Email Templates have been assembled in the \"CongaSP_Templates_Folder.\" (' + fList[0].Id + ')');
            SPPPage.setRedirect(true);                    
            return SPPPage;
            
            //return null;
            //SMPage.setRedirect(true);
            //return docFolder;
        }
    } 
    
    public Boolean getCanSeeCreateTemplateStoreButton()
    {
        return canSeeCreateTemplateStoreButton;
    }     
    
}