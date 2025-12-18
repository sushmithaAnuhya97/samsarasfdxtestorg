Public with sharing class SolutionPackExtractController{

    /*class variables for the components to add to SFDC*/
    
    //Get the Document Folders that should be included in the process (must start with CongaSP_ in the API Name of the folder)
    //public List<Folder> solutionPackFolders = [SELECT ID, DeveloperName, Name FROM Folder WHERE DeveloperName LIKE 'CongaSP_%' AND Type = 'Document' AND DeveloperName != 'CongaSP_Example_Document_Folder_Account' AND NameSpacePrefix NOT IN ('APXTConga4', 'ffaci')];
    public List<Folder> solutionPackFolders = new List<Folder>();      
        
    //Creating Lists of existing Composer records prior to insertting data from this process
    public List<APXTConga4__Conga_Solution__c> existingSolutions = [SELECT Id, Name, APXTConga4__Master_Object_Type__c FROM APXTConga4__Conga_Solution__c WHERE Id != null AND IsDeleted != true];    
    public List<APXTConga4__Conga_Template__c> existingTemplates = [SELECT Id, Name, APXTConga4__Name__c, APXTConga4__Description__c FROM APXTConga4__Conga_Template__c WHERE Id != null AND IsDeleted != true];
    public List<APXTConga4__Conga_Email_Template__c> existingCETs = [SELECT Id, APXTConga4__Name__c, APXTConga4__Subject__c FROM APXTConga4__Conga_Email_Template__c WHERE Id != null AND IsDeleted != true];
    public List<APXTConga4__Conga_Merge_Query__c> existingQueries = [SELECT Id, Name, APXTConga4__Name__c, APXTConga4__Query__c, APXTConga4__Description__c FROM APXTConga4__Conga_Merge_Query__c WHERE Id != null AND IsDeleted != true];      
    
    //Creating Sets for all existing records that might be in the system for Insert vs. update requirements 
    public Set<String> existingSolutionSet = new Set<String>();
    public Set<String> existingQueriesSet = new Set<String>(); 
    public Set<String> existingTemplatesSet = new Set<String>(); 
    public Set<String> existingCETSet = new Set<String>(); 
    
    //Creating maps of existing records in the system before creating more for Insert vs. update requirements
    public Map<String, APXTConga4__Conga_Solution__c> existingSolutionMap = new Map<String, APXTConga4__Conga_Solution__c>();    
    public Map<String, APXTConga4__Conga_Template__c> existingTemplateMap = new Map<String, APXTConga4__Conga_Template__c>();
    public Map<String, APXTConga4__Conga_Email_Template__c> existingCETMap = new Map<String, APXTConga4__Conga_Email_Template__c>();
    public Map<String, APXTConga4__Conga_Merge_Query__c> existingQueryMap = new Map<String, APXTConga4__Conga_Merge_Query__c>();    
    public Map<String, String> queryWithPVs = new Map<String, String>();
    public Map<String, String> queryWithPVsWithObject = new Map<String, String>();    
    public Map<String, Double> templateSorting = new Map<String, Double>();   
           
    //Lists of records to be insertted throughout the code to bulkify and reduce DML statements
    public List<APXTConga4__Conga_Solution__c> solutionPackSolutions = new List<APXTConga4__Conga_Solution__c>();
    public List<APXTConga4__Conga_Solution_Report__c> SolMgrReportsToInsert = new List<APXTConga4__Conga_Solution_Report__c>();
    public List<APXTConga4__Conga_Solution_Parameter__c> SolMgrParametersToInsert = new List<APXTConga4__Conga_Solution_Parameter__c>();
    public List<APXTConga4__Conga_Solution_Parameter__c> SolMgrQvarsToInsert = new List<APXTConga4__Conga_Solution_Parameter__c>();    
    
    //Map of the newly created Solution Records used to associate the child objects back to the new Sol Records (Name, Id is the mapping)
    public Map<String, Id> newSolutionRecords = new Map<String, Id>();
    public Map<String, Id> newSolutionRecordsWithObject = new Map<String, Id>(); 
    
    //Lists necessary to create new Template Records or update existing ones with a new attachment
    public List<APXTConga4__Conga_Template__c> solutionPackNewTemplates = new List<APXTConga4__Conga_Template__c>();
    public List<APXTConga4__Conga_Template__c> solutionPackUpdatedTemplates = new List<APXTConga4__Conga_Template__c>();
    
    //Lists necessary to create new CET Records or update existing ones with a new attachment    
    public List<APXTConga4__Conga_Email_Template__c> solutionPackNewCETs = new List<APXTConga4__Conga_Email_Template__c>();
    public List<APXTConga4__Conga_Email_Template__c> solutionPackUpdatedCETs = new List<APXTConga4__Conga_Email_Template__c>();    
    
    //Lists necessary to create new Query Records or update existing ones with a new SOQL Statement
    public List<APXTConga4__Conga_Merge_Query__c> solutionPackNewQueries = new List<APXTConga4__Conga_Merge_Query__c>();
    public List<APXTConga4__Conga_Merge_Query__c> solutionPackQueriesToUpdate = new List<APXTConga4__Conga_Merge_Query__c>();
    
    //List of attachments for inserts to save DML statement
    public List<Attachment> solutionPackAttachments = new List<Attachment>();
    
    //Setting a static Time value for use in the process for naming of new Solution records when an old record in the system has the same name
    public Datetime rightNow = DateTime.Now();  
    
    /*END OF CLASS VARIABLES*/      
    
    //default constructor
    public SolutionPackExtractController(){
    }
    
    //method to unpack the solution via the Unpack Solutions button on a VG page
    public void unpackSolutions(List<Folder> foldersToUnpack){
        //add the folders passed from the Extract controller to a List of Folders to unpack
        solutionPackFolders.addAll(foldersToUnpack);
    
        //create a Set and a Map or the existing Composer records and Solution records
        updateExistingRecordSets();
        updateExistingRecordMaps();
        
        //create the new Solution records based upon the included Document Folders and their contents
        createSolutionRecords();
        
        //create the Composer records from the documents in each of the Document Folders
        createComposerRecords();
        
        //create the Solution junction records for reports, queries, templates, CETs and parameters
        createSolMgrJunctionRecords();
        
        //Grab a sample record Id (the oldest record for that master object type) and set Sample Record Id with that value
        setSampleRecordIDs();    
        
        //Updating the 'Email' Solution Name for Adventace
        updateGlobalMergeSolMgrNames();                  
    }    
    
    //Make Solution records with the name being the folder name before a ( and trimmed
    //The Master object is the value btween the ( )    
    private void createSolutionRecords(){        
        for(Folder f : solutionPackFolders){                                      
            Integer i = f.Name.IndexOf('(');
            String objectType = f.Name.subString(i+1, f.Name.length()-1);
            String solutionName = f.Name.subString(0, i-1);            
            solutionName = solutionName.replace('_', ' ');        
            solutionName = solutionName.trim();                
            
            if(existingSolutionSet.contains(solutionName))
            {                                
                solutionName = solutionName + ' ' + (String) rightNow.format('dd-MMM-yyyy hh mm ss a');
            } 
            else 
            {
                solutionName = solutionName;
            }
            System.debug('******************** solutionName :' + solutionName);            
                                       
            APXTConga4__Conga_Solution__c cs = new APXTConga4__Conga_Solution__c();
            cs.Name = solutionName;
            cs.APXTConga4__Master_Object_Type__c = objectType;
            cs.APXTConga4__Solution_Description__c = 'Created By Solution Pack';
            solutionPackSolutions.add(cs);        
        }
        database.insert(solutionPackSolutions);
        
        for(APXTConga4__Conga_Solution__c cs : solutionPackSolutions)
        {
            newSolutionRecords.put(cs.Name, cs.Id);
            newSolutionRecordsWithObject.put(cs.Name + cs.APXTConga4__Master_Object_Type__c, cs.Id); 
        }                
    }

    private void createComposerRecords(){
        for(Folder f : solutionPackFolders){                        
            List<Document> docs = [SELECT Name, DeveloperName, Id, Body, ContentType, Description, Url, Type, Keywords FROM Document WHERE FolderId =:f.Id];
            System.debug('******************** Documents in Folder ' + f.DeveloperName + ' :' + docs);
            
            Integer i = f.Name.IndexOf('(');
                        
            String objectType = f.Name.subString(i+1, f.Name.length()-1);
            
            String solutionName = f.Name.subString(0, i-1);
            solutionName = solutionName.replace('_', ' ');        
            solutionName = solutionName.trim();
            System.debug('********************** solution Name in createComposerRecords: ' + solutionName);                
                        
            for(Document d : docs){
                if(d.DeveloperName.containsIgnoreCase('ft') && !d.DeveloperName.containsIgnoreCase('_CET'))
                {                                           
                    //Integer j = d.Name.IndexOf('Template');                                
                    //String templateName = d.Name.trim();
                    //templateName = templateName.replace('_', ' ');
                    //templateName = templateName.replace('Template', '').trim();
                    //String templateName = solutionName;
                    String templateName = d.Name.trim();
                    System.debug('******************** templateName after trim and replacements: ' + templateName);
                    
                    String sortOrderValue = '';
                    if(d.DeveloperName.contains('_SPT'))
                    {
                        sortOrderValue = d.DeveloperName.subString(d.DeveloperName.IndexOf('_SPT') - 1, d.DeveloperName.IndexOf('_SPT'));
                        System.debug('******************** sortOrderValue after cutting out the last _ and all that follows: ' + sortOrderValue);                        
                        sortOrderValue = sortOrderValue.subString(sortOrderValue.length()-1, sortOrderValue.length());
                        System.debug('******************** sortOrderValue after getting only last character where d.DeveloperName contained _SPT: ' + sortOrderValue);                                                
                    }
                    else
                    {
                        sortOrderValue = d.DeveloperName.subString(d.DeveloperName.length()-1, d.DeveloperName.length());
                        System.debug('******************** sortOrderValue if d.DeveloperName DID NOT contain _SPT: ' + sortOrderValue);                       
                    }
                    
                    if(sortOrderValue == '0')
                    {
                        sortOrderValue = '10';
                        System.debug('******************** sortOrderValue if last character = 0: ' + sortOrderValue);                                                                       
                    }

                    if(sortOrderValue != '0' && sortOrderValue != '1' && sortOrderValue != '2' && sortOrderValue != '3' && sortOrderValue != '4' && sortOrderValue != '5' && sortOrderValue != '6' && sortOrderValue != '7' && sortOrderValue != '8' && sortOrderValue != '9')
                    {
                        sortOrderValue = '1';
                    }     
                    System.debug('******************** sortOrderValue final value: ' + sortOrderValue);                                                                                                          
                    
                    //creating a map for later use to set correct sort order if multiple Templates are in a Solution
                    templateSorting.put(templateName, Double.ValueOf(sortOrderValue));
                                        
                    //This template doesn't exist in the system yet so make a new record and add the attachment to it                    
                    if(!existingTemplatesSet.contains(templateName))
                    {
                        APXTConga4__Conga_Template__c ct = new APXTConga4__Conga_Template__c();
                        ct.APXTConga4__Name__c = templateName ;
                        //ct.APXTConga4__Name__c = d.Name.subString(0, j-1);
                        
                        
                        //Check for an empty description. If not empty, it is the template group to put on the template
                        if(d.Description != null)
                        {
                            String templateGroup = d.Description.trim();
                            templateGroup = templateGroup.replace('[', '');
                            ct.APXTConga4__Template_Group__c = templateGroup.replace(']', '');
                            
                        }
                        
                        if(d.Keywords != null)
                        {
                            String templateAlias = d.Keywords.replace('[', '');
                            templateAlias = templateAlias.replace(']', '');
                            ct.APXTConga4__Description__c = 'Created By Solution Pack for Composer Solution: ' + solutionName + ' (' + objectType + ')' + '\nTemplate Alias: ' + templateAlias + '\nSort Order Value: ' + sortOrderValue;
                        }   
                        else 
                        {
                            ct.APXTConga4__Description__c = 'Created By Solution Pack for Composer Solution: ' + solutionName + ' (' + objectType + ')' + '\nSort Order Value: ' + sortOrderValue;              
                        }
                        //Have to do this insert in the for loop b/c I have to have the ID to create the attachment below
                        database.insert(ct);
                        
                        //Creating a List of the new Templates to create Conga Solution Template Records later
                        solutionPackNewTemplates.add(ct);
                        
                        //Adding the attachments to the new Template records via a List to save some DML Statements
                        Attachment a = new Attachment();
                        a.Name = d.Name + '.' + d.Type;
                        a.Body = d.body;
                        a.ContentType = d.ContentType;
                        a.ParentId = ct.Id;
                        solutionPackAttachments.add(a);
                    }
                    //This Template record (by name) is already in the system so just add the new attachment to it to update the Template
                    else if (existingTemplatesSet.contains(templateName))
                    {
                        APXTConga4__Conga_Template__c parentTemplateRecord = existingTemplateMap.get(templateName);
                        Attachment a = new Attachment(Name = d.Name + '.' + d.Type, Body = d.body, ContentType = d.ContentType, ParentId = parentTemplateRecord.Id);                        
                        solutionPackAttachments.add(a);   
                        solutionPackUpdatedTemplates.add(existingTemplateMap.get(templateName));                                                                                                   
                    }
                }
                else if(d.DeveloperName.containsIgnoreCase('cet_'))
                {
                    Blob CETBlob = d.body;
                    String parameters;
                    try {
                        parameters = CETBlob.toString();
                    } catch(Exception e) {
                        // If UTF-8 conversion fails, try to handle other encodings
                        try {
                            parameters = EncodingUtil.base64Encode(CETBlob);
                        } catch(Exception e2) {
                            parameters = ''; // Return empty string if blob cannot be converted
                        }
                    }
                    String CETName = d.Name.replace('Template', '');
                    CETName = CETName.replace('_CET', '');
                    CETName = CETName.replace('_', ' ').trim();
                    System.debug('************************** CETName: ' + CETName);
                    
                    if(existingCETSet.contains(CETName))
                    {
                        System.debug('************************** this CET is already in the system: ' + CETName);

                        APXTConga4__Conga_Email_Template__c cetRecord = existingCETMap.get(CETName);
                        cetRecord.APXTConga4__Subject__c = d.Description;
                        
                        if(d.Keywords != null)
                        {
                            String CETGroup = d.Keywords.replace('[', '');
                            cetRecord.APXTConga4__Template_Group__c = CETGroup.replace(']', '');                            
                        }
                        database.update(cetRecord);  
                                                
                        Attachment a = new Attachment();
                        a.Name = 'TemplateBody.' + d.Type;
                        a.Body = d.body;
                        a.ContentType = d.ContentType;
                        a.ParentId = cetRecord.Id;
                        solutionPackAttachments.add(a); 
                    }
                    else if(!existingCETSet.contains(CETName))
                    {
                        System.debug('************************** this CET is not in the system: ' + CETName);
                    
                        APXTConga4__Conga_Email_Template__c cet = new APXTConga4__Conga_Email_Template__c();
                        cet.APXTConga4__Name__c = CETName.trim();
                        cet.APXTConga4__Is_Body_Attachment__c = true;
                        cet.APXTConga4__Subject__c = d.Description;
                        cet.APXTConga4__Description__c = 'Created By Solution Pack for Composer Solution: ' + solutionName + ' (' + objectType + ')'; 
                        if(d.Keywords != null)
                        {
                            String CETGroup = d.Keywords.replace('[', '');
                            cet.APXTConga4__Template_Group__c = CETGroup.replace(']', '');                            
                        }
                        database.insert(cet);
                        solutionPackNewCETs.add(cet);
                                            
                        Attachment a = new Attachment(Name = 'TemplateBody.' + d.Type, Body = d.body, ContentType = d.ContentType, ParentId = cet.Id);                        
                        solutionPackAttachments.add(a);  
                    }                                                               
                } 
                else if(d.DeveloperName.containsIgnoreCase('queries'))
                {                    
                    Blob soqlBlob = d.body;
                    String SOQLStatements = soqlBlob.toString();
                    List<String> queriesToAdd = SOQLStatements.Split(';');
                    System.debug('********************* queriesToAdd in Doc Folder ' + f.Name + ': ' + queriesToAdd); 
                    System.debug('********************* solutionName in Doc Folder ' + f.Name + ': ' + solutionName);
                     
                    /*
                    Set<String> existingQueriesSet = new Set<String>();                    
                    for(APXTConga4__Conga_Merge_Query__c eq : existingQueries)
                    {
                        System.debug('********************* eq: ' + eq);                    
                        String eqName = eq.APXTConga4__Name__c;
                        eqName = eqName.replace('\n','');
                        eqName = eqName.replace('\n\n','');
                        eqName = eqName.trim();
                        System.debug('********************* eqName: ' + eqName); 
                        existingQueriesSet.add(eqName);                                           
                    }
                    */ 
                    System.debug('********************* existingQueriesSet in Doc Folder ' + f.Name + ': ' + solutionName + ': ' + existingQueriesSet);                    
                    
                    for(String qs : queriesToAdd)
                    {
                        System.debug('********************* qs: ' + qs);
                        qs = qs.replace('\n','');
                        qs = qs.replace('\n\n','');
                        qs = qs.trim();                                                 
                        System.debug('********************* qs after replacements and trim: ' + qs);                                                
                        
                        //Adding the Query to a map <Name, SOQL that came from the document>
                        //NAME - qs.subString(0, qs.IndexOf(']') + 1)
                        //SOQL - qs.subString(qs.IndexOf(']') + 2 , qs.Length()).trim()                        
                        try
                        {
                            queryWithPVs.put(qs.subString(0, qs.IndexOf(']') + 1), qs.subString(qs.IndexOf(']') + 2 , qs.Length()).trim()); 
                                System.debug('********************** queryWithPVs right after put: ' + queryWithPVs);                       
                        }
                        catch (Exception ex)
                        {
                            continue;
                        }
                        
                        //if(qs != '' && qs != '\n' && !existingQueriesSet.contains(qs.subString(0, qs.IndexOf(']') + 1) + 'Created By Solution Pack for Composer Solution: ' + solutionName))
                        
    // Removing to ability to update existing queries and treat all queries as new records to insert
    // JM, 06-May-2016
                        //if(qs != '' && qs != '\n' && !existingQueriesSet.contains(qs.subString(0, qs.IndexOf(']') + 1)))                          
                        //{
                            APXTConga4__Conga_Merge_Query__c cmq = new APXTConga4__Conga_Merge_Query__c();
                            cmq.APXTConga4__Name__c = qs.subString(0, qs.IndexOf(']') + 1);
                            if(qs.containsIgnoreCase('{!') || qs.containsIgnoreCase('{qvar'))
                            {
                                System.debug('***************** qs that contained either {! or {qvar and is a new Conga Query in the Org: ' + qs);
                                
                                Integer pvCounter = 0;
                                if (qs.containsIgnoreCase('{pv'))
                                {
                                    System.debug('***********************' + qs.subString(qs.lastIndexOf('{pv') + 3, qs.lastIndexOf('{pv') + 4));
                                    pvCounter = (Integer) Double.ValueOf(qs.subString(qs.lastIndexOf('{pv') + 3, qs.lastIndexOf('{pv') + 4)) + 1;
                                }
                                                                
                                String soqlStatement = qs.subString(qs.IndexOf(']') + 2 , qs.Length()).trim();
                                System.debug('*********************** soqlStatement from qs: ' + soqlStatement);
                                
                                //Pattern MERGEFIELD_REGEX = Pattern.compile('\\{!(.+?)\\}');
                                Pattern MERGEFIELD_REGEX = Pattern.compile('\\{(.+?)\\}');
                                Matcher patternMatcher = MERGEFIELD_REGEX.matcher(soqlStatement);                                
                                
                                while(patternMatcher.find())
                                {
                                    soqlStatement = soqlStatement.replace(patternMatcher.group(0), '{pv' + pvCounter + '}');
                                    pvCounter++;
                                }                                
                                //cmq.APXTConga4__Query__c = qs.subString(qs.IndexOf(']') + 2 , qs.Length()).trim();
                                System.debug('*********************** soqlStatement after patternMatcher replace loop: ' + soqlStatement);
                                  
                                cmq.APXTConga4__Query__c = soqlStatement;
                            }
                            else
                            {
                                cmq.APXTConga4__Query__c = qs.subString(qs.IndexOf(']') + 2 , qs.Length()).trim();
                            }
                            //cmq.APXTConga4__Description__c = 'Created By Solution Pack for Composer Solution: ' + solutionName;
                            cmq.APXTConga4__Description__c =  'Created By Solution Pack for Composer Solution: ' + solutionName + ' (' + objectType + ')';
                            solutionPackNewQueries.add(cmq);                       
                        //}    
                        //else if(qs != '' && qs != '\n' && existingQueriesSet.contains(qs.subString(0, qs.IndexOf(']') + 1) + 'Created By Solution Pack for Composer Solution: ' + solutionName))                    
                        
    // Pulled this out as part of the no update version on 09-May-2016
    // JM
                        /*else if(qs != '' && qs != '\n' && existingQueriesSet.contains(qs.subString(0, qs.IndexOf(']') + 1)))
                        {
                            APXTConga4__Conga_Merge_Query__c queryToUpdate = existingQueryMap.get(qs.subString(0, qs.IndexOf(']') + 1));
                            
                            if(qs.containsIgnoreCase('{!') || qs.containsIgnoreCase('{qvar'))
                            {
                                Integer pvCounter = 0;
                                if (qs.contains('{pv'))
                                {
                                    System.debug('***********************' + qs.subString(qs.lastIndexOf('{pv') + 3, qs.lastIndexOf('{pv') + 4));
                                    pvCounter = (Integer) Double.ValueOf(qs.subString(qs.lastIndexOf('{pv') + 3, qs.lastIndexOf('{pv') + 4)) + 1;
                                }
                                String soqlStatement = qs.subString(qs.IndexOf(']') + 2 , qs.Length()).trim();
                                //Pattern MERGEFIELD_REGEX = Pattern.compile('\\{!(.+?)\\}');
                                Pattern MERGEFIELD_REGEX = Pattern.compile('\\{(.+?)\\}');
                                Matcher patternMatcher = MERGEFIELD_REGEX.matcher(soqlStatement);                                
                                
                                while(patternMatcher.find())
                                {
                                    soqlStatement = soqlStatement.replace(patternMatcher.group(0), '{pv' + pvCounter + '}');
                                    pvCounter++;
                                }                                
                                //cmq.APXTConga4__Query__c = qs.subString(qs.IndexOf(']') + 2 , qs.Length()).trim();  
                                queryToUpdate.APXTConga4__Query__c = soqlStatement;
                            }
                            else
                            {
                                queryToUpdate.APXTConga4__Query__c = qs.subString(qs.IndexOf(']') + 2 , qs.Length()).trim();
                            }                                                        
                            
                            //queryToUpdate.APXTConga4__Description__c = 'Created By Solution Pack for Composer Solution: ' + solutionName + '\n Last updated on: ' + System.Now();                             
                            solutionPackQueriesToUpdate.add(queryToUpdate);
                        }*/
                    }
                    System.debug('********************* solutionPackQueriesToUpdate: ' + solutionPackQueriesToUpdate);                                                    
                }                                 
                else if(d.DeveloperName.containsIgnoreCase('reports'))
                {
                    Blob reportBlob = d.body;
                    String reports = reportBlob.toString();
                    List<String> reportList = reports.split(',');
                    System.debug('********************* reportList in Doc Folder ' + f.Name + ': ' + reportList); 
                    System.debug('********************* solutionName in Doc Folder ' + f.Name + ': ' + solutionName); 
                    
                    //Building a list of Report DeveloperNames to run through a query to get the IDs
                    List<String> reportNames = new List<String>();                    
                    for(String r: reportList)                   
                    {
                        if(r != '' && !r.contains('?'))                                
                        {
                            reportNames.add(r.subString(r.indexOf(']') + 1, r.Length()));
                            System.debug('********************* reportName: ' + r.subString(r.indexOf(']') + 1, r.Length()));                                                         
                        }
                        else if (r != '' && r.contains('?'))
                        {
                            reportNames.add(r.subString(r.indexOf(']') + 1, r.indexOf('?')));
                        }
                    }
                    System.debug('********************* reportNames in Doc Folder ' + f.Name + ': ' + reportNames); 
                    
                    //Here's the Query for the IDs
                    List<Report> SolMrgReports = [SELECT Id, Name, DeveloperName FROM Report WHERE DeveloperName = :reportNames];
                    System.debug('********************* SolMrgReports in Doc Folder ' + f.Name + ': ' + SolMrgReports );                     
                     
                    if(SolMrgReports.size() > 0)
                    {
                        //Make a Map so I can get the IDs by the DeveloperName in the below for Loop that makes the SolMgr Report records
                        Map<String, Id> reportMap = new Map<String, Id>();
                        for(Report smr : SolMrgReports)
                        {
                            reportMap.put(smr.DeveloperName, smr.Id);
                        }
                        System.debug('********************* reportMap in Doc Folder ' + f.Name + ': ' + reportMap);                                         
                        
                        String reportId = '';
                        String reportDevName = '';
                        String reportAlias = '';                        

                        //Using the map and the DeveloperName, use the loop below to make the records and add them to a List to add to SF                                        
                        for(String r: reportList)
                        {
                            System.debug('********************* r: ' + r);
                            r = r.replace('\n','');
                            r = r.replace('\r','');
                                                                                                         
                            if(r != '')
                            {
                                //System.debug('********************** string from indexof(]) to indexof(?) : ' + reportMap.get(r.subString(r.indexOf(']') + 1, r.indexOf('?'))));
                                
                                if(!r.contains('?'))
                                {
                                   reportId = reportMap.get(r.subString(r.indexOf(']') + 1, r.Length())); 
                                   reportDevName = r.subString(r.indexOf(']') + 1, r.Length()); 
                                }
                                else
                                {
                                    reportId = reportMap.get(r.subString(r.indexOf(']') + 1, r.indexOf('?')));
                                    reportDevName = r.subString(r.indexOf(']') + 1, r.indexOf('?'));                             
                                }
                                
                                reportAlias = r.subString(1, r.indexOf(']'));
                                reportAlias = reportAlias.replace('[','');
                                reportAlias = reportAlias.replace(']','');
                                reportAlias = reportAlias.replace('\n','');
                                reportAlias = reportAlias.replace('\r','');                                
                                
                                APXTConga4__Conga_Solution_Report__c csr = new APXTConga4__Conga_Solution_Report__c();
                                if(existingSolutionSet.contains(solutionName))
                                {
                                    csr.APXTConga4__Conga_Solution__c = newSolutionRecords.get(solutionName + ' ' + (String) rightNow.format('dd-MMM-yyyy hh mm ss a'));
                                }
                                else
                                {
                                    //csr.APXTConga4__Conga_Solution__c = newSolutionRecords.get(solutionName);    
                                    csr.APXTConga4__Conga_Solution__c = newSolutionRecordsWithObject.get(solutionName + objectType);    
                                }
                                csr.APXTConga4__Report_Id__c = reportId.subString(0,15);
                                csr.APXTConga4__Alias__c = reportAlias;
                                csr.APXTConga4__Report_Name__c = reportDevName;
                                
                                /****** pv value work ******/
                                if(r.endsWith('?pv0='))
                                {
                                   csr.APXTConga4__pv0__c = '+';
                                   csr.APXTConga4__pv1__c = '';
                                   csr.APXTConga4__pv2__c = '';
                                }  
                                else if(r.contains('?pv0=') && !r.contains('~'))
                                {
                                   csr.APXTConga4__pv0__c = r.subString(r.indexOf('?pv0=') + 5, r.length());
                                         
                                }
                                else if(r.contains('?pv0=') && r.contains('~pv1=') && r.contains('~pv2='))
                                {
                                   csr.APXTConga4__pv0__c = r.subString(r.indexOf('?pv0=') + 5, r.indexof('~pv1='));
                                   csr.APXTConga4__pv1__c = r.substring(r.indexOf('~pv1=') + 5, r.indexOf('~pv2='));
                                   csr.APXTConga4__pv2__c = r.subString(r.indexOf('~pv2=') + 5, r.length());
                                }                                
                                else if(r.contains('?pv0=') && r.contains('~pv1='))
                                {
                                   csr.APXTConga4__pv0__c = r.subString(r.indexOf('?pv0=') + 5, r.indexof('~pv1='));
                                   csr.APXTConga4__pv1__c = r.substring(r.indexOf('~pv1=') + 5, r.length());
                                }                                                                  
                                else if (!r.contains('?pv0'))
                                {
                                   csr.APXTConga4__pv0__c = '';
                                   csr.APXTConga4__pv1__c = '';
                                   csr.APXTConga4__pv2__c = '';
                                }                             
                                /*else
                                {
                                   csr.APXTConga4__pv0__c = '';
                                   csr.APXTConga4__pv1__c = '';
                                   csr.APXTConga4__pv2__c = '';
                                }*/
                                /****** end pv value work ******/
                                                                
                                //Adding the record to a list for later insert (bulkify)
                                SolMgrReportsToInsert.add(csr);
                            }
                        }
                    }    
                    System.debug('********************* SolMgrReportsToInsert in Doc Folder ' + f.Name + ': ' + SolMgrReportsToInsert);                                                                                                                                    
                }                                
                else if(d.DeveloperName.containsIgnoreCase('qvar'))
                {                    
                    Blob soqlBlob = d.body;
                    String SOQLStatements = soqlBlob.toString();
                    List<String> qvarsToAdd = SOQLStatements.Split(';');
                    System.debug('********************* qvarsToAdd in Doc Folder ' + f.Name + ': ' + qvarsToAdd); 
                    System.debug('********************* solutionName in Doc Folder ' + f.Name + ': ' + solutionName);                                     
                    
                    for(String qs : qvarsToAdd)
                    {
                        System.debug('********************* qs: ' + qs);
                        qs = qs.replace('\n','');
                        qs = qs.replace('\n\n','');
                        qs = qs.trim();                                                 
                        System.debug('********************* qs after replacements and trim in Qvars: ' + qs);                                                
                        
                        //Adding the Query to a map <Name, SOQL that came from the document>
                        //NAME - qs.subString(0, qs.IndexOf(']') + 1)
                            // Should be just [Qvar0], [Qvar1] etc...
                        //SOQL - qs.subString(qs.IndexOf(']') + 2 , qs.Length()).trim() 
                            // The actual SOQL statement will be the rest of of the string after the ]                       
                        try
                        {
                            queryWithPVs.put(qs.subString(0, qs.IndexOf(']') + 1), qs.subString(qs.IndexOf(']') + 2 , qs.Length()).trim());
                                System.debug('********************** queryWithPVs right after put: ' + queryWithPVs);   
                                
                            queryWithPVsWithObject.put(qs.subString(0, qs.IndexOf(']') + 1) + objectType, qs.subString(qs.IndexOf(']') + 2 , qs.Length()).trim());
                                System.debug('********************** queryWithPVsWithObject right after put: ' + queryWithPVsWithObject);                                  
                        }
                        catch (Exception ex)
                        {
                            continue;
                        }
                        
                        //if(qs != '' && qs != '\n' && !existingQueriesSet.contains(qs.subString(0, qs.IndexOf(']') + 1)))                          
                        if(qs != '' && qs != '\n')                        
                        {
                            APXTConga4__Conga_Merge_Query__c cmq = new APXTConga4__Conga_Merge_Query__c();
                            cmq.APXTConga4__Name__c = qs.subString(0, qs.IndexOf(']') + 1);
                            if(qs.contains('{!') || qs.containsIgnoreCase('{qvar'))
                            {
                                Integer pvCounter = 0;
                                if (qs.containsIgnoreCase('{pv'))
                                {
                                    System.debug('***********************' + qs.subString(qs.lastIndexOf('{pv') + 3, qs.lastIndexOf('{pv') + 4));
                                    pvCounter = (Integer) Double.ValueOf(qs.subString(qs.lastIndexOf('{pv') + 3, qs.lastIndexOf('{pv') + 4)) + 1;
                                }
                                String soqlStatement = qs.subString(qs.IndexOf(']') + 2 , qs.Length()).trim();
                                Pattern MERGEFIELD_REGEX = Pattern.compile('\\{(.+?)\\}');
                                Matcher patternMatcher = MERGEFIELD_REGEX.matcher(soqlStatement);                                
                                
                                while(patternMatcher.find())
                                {
                                    soqlStatement = soqlStatement.replace(patternMatcher.group(0), '{pv' + pvCounter + '}');
                                    pvCounter++;
                                }                                
                                //cmq.APXTConga4__Query__c = qs.subString(qs.IndexOf(']') + 2 , qs.Length()).trim();  
                                cmq.APXTConga4__Query__c = soqlStatement;
                            }
                            else
                            {
                                cmq.APXTConga4__Query__c = qs.subString(qs.IndexOf(']') + 2 , qs.Length()).trim();
                            }                            
                            //cmq.APXTConga4__Description__c = qs.subString(0, qs.IndexOf(']') + 1) + ' created By Solution Pack for Composer Solution: ' + solutionName; 
                            cmq.APXTConga4__Description__c = qs.subString(0, qs.IndexOf(']') + 1) + ' created By Solution Pack for Composer Solution: ' + solutionName + ' (' + objectType + ')'; 
                            solutionPackNewQueries.add(cmq);                       
                        }    
                        /********
                        else if(qs != '' && qs != '\n' && existingQueriesSet.contains(qs.subString(0, qs.IndexOf(']') + 1)))
                        {
                            APXTConga4__Conga_Merge_Query__c queryToUpdate = existingQueryMap.get(qs.subString(0, qs.IndexOf(']') + 1));
                            
                            if(qs.contains('{!'))
                            {
                                Integer pvCounter = 0;
                                if (qs.contains('{pv'))
                                {
                                    System.debug('***********************' + qs.subString(qs.lastIndexOf('{pv') + 3, qs.lastIndexOf('{pv') + 4));
                                    pvCounter = (Integer) Double.ValueOf(qs.subString(qs.lastIndexOf('{pv') + 3, qs.lastIndexOf('{pv') + 4)) + 1;
                                }
                                String soqlStatement = qs.subString(qs.IndexOf(']') + 2 , qs.Length()).trim();
                                Pattern MERGEFIELD_REGEX = Pattern.compile('\\{!(.+?)\\}');
                                Matcher patternMatcher = MERGEFIELD_REGEX.matcher(soqlStatement);                                
                                
                                while(patternMatcher.find())
                                {
                                    soqlStatement = soqlStatement.replace(patternMatcher.group(0), '{pv' + pvCounter + '}');
                                    pvCounter++;
                                }                                
                                //cmq.APXTConga4__Query__c = qs.subString(qs.IndexOf(']') + 2 , qs.Length()).trim();  
                                queryToUpdate.APXTConga4__Query__c = soqlStatement;
                            }
                            else
                            {
                                queryToUpdate.APXTConga4__Query__c = qs.subString(qs.IndexOf(']') + 2 , qs.Length()).trim();
                            }                                                        
                            
                            //queryToUpdate.APXTConga4__Description__c = 'Created By Solution Pack for Composer Solution: ' + solutionName + '\n Last updated on: ' + System.Now();                             
                            solutionPackQueriesToUpdate.add(queryToUpdate);
                        }
                        ********/
                    }
                    //System.debug('********************* solutionPackQueriesToUpdate: ' + solutionPackQueriesToUpdate);                                                    
                }   
                else if(d.DeveloperName.containsIgnoreCase('parameters'))
                {
                    Blob parameterBlob = d.body;
                    String parameters = parameterBlob.toString();
                    List<String> parameterList = parameters.split('&');
                    System.debug('********************* parameterList in Doc Folder ' + f.Name + ': ' + parameterList); 
                    System.debug('********************* solutionName in Doc Folder ' + f.Name + ': ' + solutionName); 
                    for(String ps : parameterList)
                    {
                        System.debug('********************* ps: ' + ps);
                        System.debug('********************* ps length: ' + ps.length());                                                 
                        if(ps != '')
                        {
                            if(ps.startsWithIgnoreCase('qvar') && ps.containsIgnoreCase('Id'))
                            {
                                // Don't do anythign here because is a QvarXId parameter that shouldn't ever be in here
                                // Picked up in the Qvar handler above
                            }
                            else 
                            {
                                APXTConga4__Conga_Solution_Parameter__c csp = new APXTConga4__Conga_Solution_Parameter__c();
                                if(existingSolutionSet.contains(solutionName))
                                {
                                    csp.APXTConga4__Conga_Solution__c = newSolutionRecords.get(solutionName + ' ' + (String) rightNow.format('dd-MMM-yyyy hh mm ss a'));
                                }
                                else
                                {
                                    //csp.APXTConga4__Conga_Solution__c = newSolutionRecords.get(solutionName);
                                    csp.APXTConga4__Conga_Solution__c = newSolutionRecordsWithObject.get(solutionName + objectType);  
                                }
                                csp.APXTConga4__Name__c = ps.subString(0,ps.IndexOf('='));
                                if (ps.subString(ps.IndexOf('=') + 1, ps.Length()) == 'null\n' || string.IsBlank(ps.subString(ps.IndexOf('=') + 1, ps.Length())))
                                {
                                    csp.APXTConga4__Value__c = '';
                                }
                                else
                                {
                                    csp.APXTConga4__Value__c = ps.subString(ps.IndexOf('=') + 1, ps.Length());                                
                                }
                                
                                //csp.APXTConga4__Value__c = ps.subString(ps.IndexOf('=') + 1, ps.Length());
                                SolMgrParametersToInsert.add(csp);
                                System.debug('********************* Parameter Name: ' + ps.subString(0,ps.IndexOf('='))); 
                                System.debug('********************* Parameter Value: ' + ps.subString(ps.IndexOf('=') + 1, ps.Length()));                         
                            }
                        }
                    }                    
                }                                       
            }
        }       

        //Done in lists where possible to Bulkify the code 
        database.insert(solutionPackAttachments);
        database.insert(solutionPackNewQueries);
        database.update(solutionPackQueriesToUpdate);
        database.insert(SolMgrParametersToInsert);
        database.insert(SolMgrReportsToInsert);
    }   
    
    private void createSolMgrJunctionRecords(){
        Integer colonIndex = 0;
        Integer openBracketIndex = 0;
        
        List<APXTConga4__Conga_Solution_Template__c> SolMgrTemplatesToInsert = new List<APXTConga4__Conga_Solution_Template__c>();
        System.debug('********************* SolMgrTemplatesToInsert in createSolutionRecordJunctions: ' + SolMgrTemplatesToInsert );
        
        List<APXTConga4__Conga_Solution_Query__c> SolMgrQueriesToInsert = new List<APXTConga4__Conga_Solution_Query__c>();
        System.debug('********************* SolMgrQueriesToInsert in createSolutionRecordJunctions: ' + SolMgrQueriesToInsert ); 
        
        List<APXTConga4__Conga_Solution_Email_Template__c> SolMgrCETsToInsert = new List<APXTConga4__Conga_Solution_Email_Template__c>();
        System.debug('********************* SolMgrCETsToInsert in createSolutionRecordJunctions: ' + SolMgrCETsToInsert); 
        
        String queryAlias = '';
        
        /****************Creating Conga Solution Query and QVAR Parameter Records****************/ 
        for(APXTConga4__Conga_Merge_Query__c cmq : solutionPackNewQueries){
            System.debug('********************* cmq.APXTConga4__Name__c.subString(0,5): ' + cmq.APXTConga4__Name__c.subString(0,5)); 
        
            if(!cmq.APXTConga4__Name__c.subString(0,5).equalsIgnoreCase('[qvar'))
            {
                queryAlias = cmq.APXTConga4__Name__c.subString(cmq.APXTConga4__Name__c.IndexOf('[') + 1, cmq.APXTConga4__Name__c.length()-1);
                queryAlias = queryAlias.replace('[','');
                queryAlias = queryAlias.replace(']','');
                queryAlias = queryAlias.replace('\n','');
                queryAlias = queryAlias.replace('\r','');
                          
                APXTConga4__Conga_Solution_Query__c csq = new APXTConga4__Conga_Solution_Query__c();
                csq.APXTConga4__Conga_Query__c = cmq.Id;
                if(existingSolutionSet.contains(cmq.APXTConga4__Description__c.subString(cmq.APXTConga4__Description__c.IndexOf(': ') + 2, cmq.APXTConga4__Description__c.length())))
                {                
                    csq.APXTConga4__Conga_Solution__c = newSolutionRecords.get(cmq.APXTConga4__Description__c.subString(cmq.APXTConga4__Description__c.IndexOf(': ') + 2, cmq.APXTConga4__Description__c.length()) + ' ' + (String) rightNow.format('dd-MMM-yyyy hh mm ss a'));
                        System.debug('****************************** Conga Solution Id if the system found duplicate solution name: ' + cmq.APXTConga4__Description__c.subString(cmq.APXTConga4__Description__c.IndexOf(': ') + 2, cmq.APXTConga4__Description__c.length()) + ' ' + (String) rightNow.format('dd-MMM-yyyy hh mm ss a'));
                }
                else
                {
                    csq.APXTConga4__Conga_Solution__c = newSolutionRecordsWithObject.get(cmq.APXTConga4__Description__c.subString(cmq.APXTConga4__Description__c.IndexOf(': ') + 2, cmq.APXTConga4__Description__c.length()).replace(' (' ,'').replace(')',''));
                    //csq.APXTConga4__Conga_Solution__c = newSolutionRecords.get(cmq.APXTConga4__Description__c.subString(cmq.APXTConga4__Description__c.IndexOf(': ') + 2, cmq.APXTConga4__Description__c.length()));
                        System.debug('****************************** Conga Solution Id if the system DID NOT find a duplicate solution name: ' + cmq.APXTConga4__Description__c.subString(cmq.APXTConga4__Description__c.IndexOf(': ') + 2, cmq.APXTConga4__Description__c.length()).replace(' (' ,'').replace(')',''));                
                }
                //csq.APXTConga4__Conga_Solution__c = newSolutionRecords.get(cmq.APXTConga4__Description__c.subString(cmq.APXTConga4__Description__c.IndexOf(': ') + 2, cmq.APXTConga4__Description__c.length()));
                csq.APXTConga4__Alias__c = queryAlias.trim();
                csq.APXTConga4__Comments__c = 'Created By Solution Pack';
                    System.debug('****************************** csq to insert before pv work: ' + csq);                                
                
                
                List<String> pvValuesNewQueries = new List<String>();
                
                if (cmq.APXTConga4__Query__c.containsIgnoreCase('{pv') || cmq.APXTConga4__Query__c.containsIgnoreCase('{qvar'))
                {
                    System.debug('******************** cmq.APXTConga4__Name__c: ' + cmq.APXTConga4__Name__c);                                             
                    System.debug('******************** queryWithPVs.get(cmq.APXTConga4__Name__c): ' + queryWithPVs.get(cmq.APXTConga4__Name__c));    
                    Pattern MERGEFIELD_REGEX = Pattern.compile('\\{(.+?)\\}');
                    Matcher patternMatcher = MERGEFIELD_REGEX.matcher(queryWithPVs.get(cmq.APXTConga4__Name__c));                                         
                    
                    while(patternMatcher.find())
                    {
                        pvValuesNewQueries.add(patternMatcher.group(0));
                    }
                    System.debug('******************** pvValuesNewQueries List: ' + pvValuesNewQueries);                                                                              
                }
                if (pvValuesNewQueries.size() != 0)
                {                    
                    if (cmq.APXTConga4__Query__c.contains('{pv0}'))
                    {                
                        System.debug('******************** pvValuesNewQueries.get(0): ' + pvValuesNewQueries.get(0));                                                                              
                        if(pvValuesNewQueries.get(0) == '{pv0}')
                        {
                            csq.APXTConga4__pv0__c = '';
                        }
                        else
                        {
                            csq.APXTConga4__pv0__c = pvValuesNewQueries.get(0);
                        }
                    }
                    if (cmq.APXTConga4__Query__c.contains('{pv1}'))
                    {
                        System.debug('******************** pvValuesNewQueries.get(1): ' + pvValuesNewQueries.get(1));                                                                              
                        if(pvValuesNewQueries.get(1) == '{pv1}')
                        {
                            csq.APXTConga4__pv1__c = '';
                        }
                        else
                        {
                            csq.APXTConga4__pv1__c = pvValuesNewQueries.get(1);
                        }
                    }                
                    if (cmq.APXTConga4__Query__c.contains('{pv2}'))
                    {
                        System.debug('******************** pvValuesNewQueries.get(2): ' + pvValuesNewQueries.get(2));                                                                              
                        if(pvValuesNewQueries.get(2) == '{pv2}')
                        {
                            csq.APXTConga4__pv2__c = '';
                        }
                        else
                        {
                            csq.APXTConga4__pv2__c = pvValuesNewQueries.get(2);
                        }
                    }
                }
                    System.debug('***************** csq before adding to the List: ' + csq);
                SolMgrQueriesToInsert.add(csq);
            }
            else if (cmq.APXTConga4__Name__c.subString(0,5).equalsIgnoreCase('[qvar'))
            {
                System.debug('***************** cmq if the Query is a Qvar [qvar: ' + cmq);
                System.debug('***************** cmq Name plus Id: ' + cmq.APXTConga4__Name__c.subString(1,6) + 'Id');   
                System.debug('****************************** newSolutionRecordsWithObject: ' + newSolutionRecordsWithObject);                             
                
                APXTConga4__Conga_Solution_Parameter__c csp = new APXTConga4__Conga_Solution_Parameter__c();
                csp.APXTConga4__Name__c = cmq.APXTConga4__Name__c.subString(1,6) + 'Id';                
                csp.APXTConga4__Comments__c = 'Created By Solution Pack';  
                String qvarString = cmq.Id;                              
                qvarString = qvarString.subString(0,15);
                System.debug('***************** qvarString after qvarString.subString(0,15): ' + qvarString);
                
                if(existingSolutionSet.contains(cmq.APXTConga4__Description__c.subString(cmq.APXTConga4__Description__c.IndexOf(': ') + 2, cmq.APXTConga4__Description__c.length())))
                {                
                    //csp.APXTConga4__Conga_Solution__c = newSolutionRecords.get(cmq.APXTConga4__Description__c.subString(cmq.APXTConga4__Description__c.IndexOf(': ') + 2, cmq.APXTConga4__Description__c.length()) + ' ' + (String) rightNow.format('dd-MMM-yyyy hh mm ss a'));
                    csp.APXTConga4__Conga_Solution__c = newSolutionRecords.get(cmq.APXTConga4__Description__c.subString(cmq.APXTConga4__Description__c.IndexOf(': ') + 2, cmq.APXTConga4__Description__c.length()) + ' ' + (String) rightNow.format('dd-MMM-yyyy hh mm ss a') + cmq.APXTConga4__Description__c.subString(cmq.APXTConga4__Description__c.LastIndexOf('(') + 1, cmq.APXTConga4__Description__c.length()-1));                    
                        System.debug('****************************** Conga Solution Id if the system found duplicate solution name: ' + cmq.APXTConga4__Description__c.subString(cmq.APXTConga4__Description__c.IndexOf(': ') + 2, cmq.APXTConga4__Description__c.length()) + ' ' + (String) rightNow.format('dd-MMM-yyyy hh mm ss a'));
                }
                else
                {
                    csp.APXTConga4__Conga_Solution__c = newSolutionRecordsWithObject.get(cmq.APXTConga4__Description__c.subString(cmq.APXTConga4__Description__c.IndexOf(': ') + 2, cmq.APXTConga4__Description__c.length()).replace(' (' ,'').replace(')',''));
                    //csp.APXTConga4__Conga_Solution__c = newSolutionRecords.get(cmq.APXTConga4__Description__c.subString(cmq.APXTConga4__Description__c.IndexOf(': ') + 2, cmq.APXTConga4__Description__c.length()));
                        System.debug('****************************** Conga Solution Name if the system DID NOT find a duplicate solution name: ' + cmq.APXTConga4__Description__c.subString(cmq.APXTConga4__Description__c.IndexOf(': ') + 2, cmq.APXTConga4__Description__c.length())); 
                        System.debug('****************************** Conga Solution ID if the system DID NOT find a duplicate solution name: ' + newSolutionRecordsWithObject.get(cmq.APXTConga4__Description__c.subString(cmq.APXTConga4__Description__c.IndexOf(': ') + 2, cmq.APXTConga4__Description__c.length()).replace(' (' ,'').replace(')','')));
                }                
                
                List<String> pvValuesNewQueries = new List<String>();                
                List<String> pvValuesNewQueriesWithObjectType = new List<String>();   
                
                String qvarName = cmq.APXTConga4__Name__c;                   
                String qvarMasterObjectType = cmq.APXTConga4__Description__c.subString(cmq.APXTConga4__Description__c.LastIndexOf('(') + 1, cmq.APXTConga4__Description__c.length()-1);
                        System.debug('******************** qvarName + qvarMasterObjectType: ' + qvarName + qvarMasterObjectType);                                               
                
                if (!cmq.APXTConga4__Query__c.contains('{pv'))
                {
                    csp.APXTConga4__Value__c = qvarString;
                    System.debug('***************** csp to insert if no pv found in the query: ' + csp);                    
                    database.insert(csp); 
                }
                if (cmq.APXTConga4__Query__c.containsIgnoreCase('{pv') || cmq.APXTConga4__Query__c.containsIgnoreCase('{qvar'))
                {
                    System.debug('******************** cmq.APXTConga4__Name__c: ' + cmq.APXTConga4__Name__c);                                             
                    System.debug('******************** queryWithPVs.get(cmq.APXTConga4__Name__c): ' + queryWithPVs.get(cmq.APXTConga4__Name__c));    
                    Pattern MERGEFIELD_REGEX = Pattern.compile('\\{(.+?)\\}');
                    //Matcher patternMatcher = MERGEFIELD_REGEX.matcher(queryWithPVs.get(cmq.APXTConga4__Name__c));                                         
                    Matcher patternMatcher = MERGEFIELD_REGEX.matcher(queryWithPVsWithObject.get(qvarName + qvarMasterObjectType)); 
                    
                    while(patternMatcher.find())
                    {
                        pvValuesNewQueries.add(patternMatcher.group(0));
                    }
                    System.debug('******************** pvValuesNewQueries List: ' + pvValuesNewQueries);                                                                              
                }
                if (pvValuesNewQueries.size() != 0)
                {
                    Integer pvCounter = 0;
                    Pattern MERGEFIELD_REGEX = Pattern.compile('\\{(.+?)\\}');
                    //Matcher patternMatcher = MERGEFIELD_REGEX.matcher(queryWithPVs.get(cmq.APXTConga4__Name__c)); 
                    Matcher patternMatcher = MERGEFIELD_REGEX.matcher(queryWithPVsWithObject.get(qvarName + qvarMasterObjectType));  
                    
                    System.debug('******************** queryWithPVs.get(cmq.APXTConga4__Name__c) for ' + cmq.APXTConga4__Name__c + ': ' + queryWithPVs.get(cmq.APXTConga4__Name__c)); 
                    System.debug('******************** queryWithPVsWithObject.get(qvarName + qvarMasterObjectType) for ' + qvarName + qvarMasterObjectType + ': ' + queryWithPVsWithObject.get(qvarName + qvarMasterObjectType));                                        
                    System.debug('******************** pvValuesNewQueries List: ' + pvValuesNewQueries);                                                                                                                                                  
                    System.debug('******************** qvarString before truing patternMatch approach: ' + qvarString);                                                                                                                                                  
                    
                    while(patternMatcher.find())
                    {
                        System.debug('****************** pvCounter comin into patternMatch.find(): ' + pvCounter);                        
                        System.debug('****************** patternMatcher trying to get good qvarString: ' + patternMatcher);
                        
                        if(pvCounter == 0)
                        {
                            qvarString = qvarString + '?pv0=' + pvValuesNewQueries.get(pvCounter);
                        }
                        else
                        {
                            qvarString = qvarString + '~pv' + pvCounter + '=' + pvValuesNewQueries.get(pvCounter);
                        }
                        
                        System.debug('****************** qvarString in patternMatcher approach : ' + qvarString);
                        
                        pvCounter++;
                        System.debug('****************** pvCounter after incrementing in patternMatch.find(): ' + pvCounter);                        
                    }   
                    
                    /*
                    if (cmq.APXTConga4__Query__c.contains('{pv0}'))
                    {                
                        System.debug('******************** pvValuesNewQueries.get(0): ' + pvValuesNewQueries.get(0));                                                                              
                        if(pvValuesNewQueries.get(0) == '{pv0}')
                        {
                            //csq.APXTConga4__pv0__c = '';
                        }
                        else
                        {
                            //csq.APXTConga4__pv0__c = pvValuesNewQueries.get(0);                            
                            qvarString += '?pv0=' + pvValuesNewQueries.get(0);
                        }
                        pvCounter++;
                    }
                    if (cmq.APXTConga4__Query__c.contains('{pv1}'))
                    {
                        System.debug('******************** pvValuesNewQueries.get(1): ' + pvValuesNewQueries.get(1));                                                                              
                        if(pvValuesNewQueries.get(1) == '{pv1}')
                        {
                            //csq.APXTConga4__pv1__c = '';
                        }
                        else
                        {
                            //csq.APXTConga4__pv1__c = pvValuesNewQueries.get(1);
                            qvarString += '~pv1=' + pvValuesNewQueries.get(1);
                        }
                        pvCounter++;
                    }                
                    if (cmq.APXTConga4__Query__c.contains('{pv2}'))
                    {
                        System.debug('******************** pvValuesNewQueries.get(2): ' + pvValuesNewQueries.get(2));                                                                              
                        if(pvValuesNewQueries.get(2) == '{pv2}')
                        {
                            //csq.APXTConga4__pv2__c = '';
                        }
                        else
                        {
                            //csq.APXTConga4__pv2__c = pvValuesNewQueries.get(2);
                            qvarString += '~pv2=' + pvValuesNewQueries.get(2);
                        }
                        pvCounter++;
                    }
                    */
                    csp.APXTConga4__Value__c = qvarString;
                    System.debug('***************** qvarString At the end: ' + qvarString);
                    System.debug('***************** csp to insert whern a pv is found in the query: ' + csp);
                    
                    SolMgrQvarsToInsert.add(csp);                    
                }                                               
            }                
        }        
        for(APXTConga4__Conga_Merge_Query__c updatedcmq : solutionPackQueriesToUpdate){
            queryAlias = updatedcmq.APXTConga4__Name__c.subString(updatedcmq.APXTConga4__Name__c.IndexOf('[') + 1, updatedcmq.APXTConga4__Name__c.length()-1);
            queryAlias = queryAlias.replace('[','');
            queryAlias = queryAlias.replace(']','');
            queryAlias = queryAlias.replace('\n','');
            queryAlias = queryAlias.replace('\r','');
                      
            APXTConga4__Conga_Solution_Query__c csq = new APXTConga4__Conga_Solution_Query__c();
            csq.APXTConga4__Conga_Query__c = updatedcmq.Id;
            if(existingSolutionSet.contains(updatedcmq.APXTConga4__Description__c.subString(updatedcmq.APXTConga4__Description__c.IndexOf(': ') + 2, updatedcmq.APXTConga4__Description__c.length())))
            {                
                csq.APXTConga4__Conga_Solution__c = newSolutionRecords.get(updatedcmq.APXTConga4__Description__c.subString(updatedcmq.APXTConga4__Description__c.IndexOf(': ') + 2, updatedcmq.APXTConga4__Description__c.length()) + ' ' + (String) rightNow.format('dd-MMM-yyyy hh mm ss a'));
                    System.debug('****************************** Conga Solution Id if the system found duplicate solution name: ' + updatedcmq.APXTConga4__Description__c.subString(updatedcmq.APXTConga4__Description__c.IndexOf(': ') + 2, updatedcmq.APXTConga4__Description__c.length()) + ' ' + (String) rightNow.format('dd-MMM-yyyy hh mm ss a'));
            }
            else
            {
                //csq.APXTConga4__Conga_Solution__c = newSolutionRecords.get(updatedcmq.APXTConga4__Description__c.subString(updatedcmq.APXTConga4__Description__c.IndexOf(': ') + 2, updatedcmq.APXTConga4__Description__c.length()));
                csq.APXTConga4__Conga_Solution__c = newSolutionRecordsWithObject.get(updatedcmq.APXTConga4__Description__c.subString(updatedcmq.APXTConga4__Description__c.IndexOf(': ') + 2, updatedcmq.APXTConga4__Description__c.length()).replace(' (' ,'').replace(')',''));                
                    System.debug('****************************** Conga Solution Id if the system DID NOT find a duplicate solution name: ' + updatedcmq.APXTConga4__Description__c.subString(updatedcmq.APXTConga4__Description__c.IndexOf(': ') + 2, updatedcmq.APXTConga4__Description__c.length()));                
            }
            //csq.APXTConga4__Conga_Solution__c = newSolutionRecords.get(updatedcmq.APXTConga4__Description__c.subString(updatedcmq.APXTConga4__Description__c.IndexOf(': ') + 2, updatedcmq.APXTConga4__Description__c.length()));            
            csq.APXTConga4__Alias__c = queryAlias.trim();
            csq.APXTConga4__Comments__c = 'Created By Solution Pack';
            
            List<String> pvValuesExistingQueries = new List<String>();
            
            if (updatedcmq.APXTConga4__Query__c.containsIgnoreCase('{pv') || updatedcmq.APXTConga4__Query__c.containsIgnoreCase('{qvar'))
            {
                System.debug('******************** updatedcmq.APXTConga4__Name__c: ' + updatedcmq.APXTConga4__Name__c);                                             
                System.debug('******************** queryWithPVs.get(updatedcmq.APXTConga4__Name__c): ' + queryWithPVs.get(updatedcmq.APXTConga4__Name__c));    
                Pattern MERGEFIELD_REGEX = Pattern.compile('\\{(.+?)\\}');
                Matcher patternMatcher = MERGEFIELD_REGEX.matcher(queryWithPVs.get(updatedcmq.APXTConga4__Name__c));                                         
                
                while(patternMatcher.find())
                {
                    pvValuesExistingQueries.add(patternMatcher.group(0));
                }
                System.debug('******************** pvValuesExistingQueries List: ' + pvValuesExistingQueries);                                                                              
            }
            
            if (pvValuesExistingQueries.size() != 0)
            {
                if (updatedcmq.APXTConga4__Query__c.contains('{pv0}'))
                {                
                    System.debug('******************** pvValuesExistingQueries.get(0): ' +  pvValuesExistingQueries.get(0));                                                                              
                    if(pvValuesExistingQueries.get(0) == '{pv0}')
                    {
                        csq.APXTConga4__pv0__c = '';
                    }
                    else
                    {
                        csq.APXTConga4__pv0__c = pvValuesExistingQueries.get(0);
                    }
                }
                if (updatedcmq.APXTConga4__Query__c.contains('{pv1}'))
                {
                    System.debug('******************** pvValuesExistingQueries.get(1): ' + pvValuesExistingQueries.get(1));                                                                              
                    if(pvValuesExistingQueries.get(1) == '{pv1}')
                    {
                        csq.APXTConga4__pv1__c = '';
                    }
                    else
                    {
                        csq.APXTConga4__pv1__c = pvValuesExistingQueries.get(1);
                    }
                }                
                if (updatedcmq.APXTConga4__Query__c.contains('{pv2}'))
                {
                    System.debug('******************** pvValuesExistingQueries.get(2): ' + pvValuesExistingQueries.get(2));                                                                              
                    if(pvValuesExistingQueries.get(2) == '{pv2}')
                    {
                        csq.APXTConga4__pv2__c = '';
                    }
                    else
                    {
                        csq.APXTConga4__pv2__c = pvValuesExistingQueries.get(2);
                    }
                }
            }
            
            SolMgrQueriesToInsert.add(csq);
        }              
        /****************END OF Conga Solution Query and QVAR Parameter Records****************/ 
                
        /****************Creating Conga Solution Template and Solution Email Template Records****************/
            /****** New Approach to fix sort order bug ******/
        
        for (APXTConga4__Conga_Solution__c sol : solutionPackSolutions)
        {                                   
            system.Debug('************************* sol.Name in part where we are creating CSET and CST records: ' + sol.Name);
            
            List<APXTConga4__Conga_Template__c> solTemplates = database.query('SELECT Id, Name, APXTConga4__Description__c, APXTConga4__Name__c FROM APXTConga4__Conga_Template__c WHERE APXTConga4__Description__c LIKE \'%' + sol.Name + '%\' AND APXTConga4__Description__c LIKE \'%' + sol.APXTConga4__Master_Object_Type__c + '%\' AND APXTConga4__Description__c != \'For Conga eMigrator\'');
            //List<APXTConga4__Conga_Template__c> solTemplates = database.query('SELECT Id, Name, APXTConga4__Description__c, APXTConga4__Name__c FROM APXTConga4__Conga_Template__c WHERE APXTConga4__Description__c LIKE \'%' + sol.Name + '%\' AND APXTConga4__Description__c != \'For Conga eMigrator\'');            
            for(APXTConga4__Conga_Template__c ct : solTemplates)
            {
                APXTConga4__Conga_Solution_Template__c cst = new APXTConga4__Conga_Solution_Template__c();
                cst.APXTConga4__Conga_Template__c = ct.Id;
                cst.APXTConga4__Conga_Solution__c = sol.Id;
                cst.APXTConga4__Sort_Order__c = Double.ValueOf(ct.APXTConga4__Description__c.substring(ct.APXTConga4__Description__c.length()-1,ct.APXTConga4__Description__c.length()));
                if(ct.APXTConga4__Description__c.contains('Template Alias: '))
                {
                    cst.APXTConga4__Output_File_Name__c = ct.APXTConga4__Description__c.substring(ct.APXTConga4__Description__c.indexOf('Template Alias: ') + 15, ct.APXTConga4__Description__c.indexOf('\nSort')); 
                }
                SolMgrTemplatesToInsert.add(cst);              
            }
            
            system.Debug('************************* SOQL about to run to get Conga Email Template Record: ' + 'SELECT Id, Name, APXTConga4__Description__c FROM APXTConga4__Conga_Email_Template__c WHERE APXTConga4__Description__c LIKE \'%' + sol.Name + '%\' AND APXTConga4__Description__c LIKE \'%' + sol.APXTConga4__Master_Object_Type__c + '%\' LIMIT 1');            
            try
            {
                APXTConga4__Conga_Email_Template__c cetToAssociate = database.query('SELECT Id, Name, APXTConga4__Description__c FROM APXTConga4__Conga_Email_Template__c WHERE APXTConga4__Description__c LIKE \'%' + sol.Name + '%\' AND APXTConga4__Description__c LIKE \'%' + sol.APXTConga4__Master_Object_Type__c + '%\' LIMIT 1');
    
                // Added a check for Adventace - I don't want to add a CET in this case at their request - hybrid Non-linked template requirement specific to their OEM needs
                if (cetToAssociate != null && sol.APXTConga4__Master_Object_Type__c != 'ADVSMS__Impacted_Job_Title__c')
                {
                    APXTConga4__Conga_Solution_Email_Template__c cset = new APXTConga4__Conga_Solution_Email_Template__c();
                    cset.APXTConga4__Conga_Solution__c = sol.Id;
                    cset.APXTConga4__Conga_Email_Template__c = cetToAssociate.Id;
                    SolMgrCETsToInsert.add(cset);
                }
            }
            catch (Exception ex)
            {
                continue;
            }
        }
        
        database.insert(SolMgrTemplatesToInsert);
        
        /************************************************/
        
        /*for(APXTConga4__Conga_Template__c ct : solutionPackNewTemplates){
            APXTConga4__Conga_Solution_Template__c cst = new APXTConga4__Conga_Solution_Template__c();
            cst.APXTConga4__Conga_Template__c = ct.Id; 
            if(existingSolutionSet.contains(ct.APXTConga4__Name__c))
            {
                cst.APXTConga4__Conga_Solution__c = newSolutionRecords.get(ct.APXTConga4__Name__c + ' ' + (String) rightNow.format('dd-MMM-yyyy hh mm ss a'));                
            }
            else
            {
                cst.APXTConga4__Conga_Solution__c = newSolutionRecords.get(ct.APXTConga4__Name__c);
            }  
            cst.APXTConga4__Sort_Order__c = Double.ValueOf(ct.APXTConga4__Description__c.substring(ct.APXTConga4__Description__c.length()-1,ct.APXTConga4__Description__c.length()));
            
            if(ct.APXTConga4__Description__c.contains('Template Alias: '))
            {
                cst.APXTConga4__Output_File_Name__c = ct.APXTConga4__Description__c.substring(ct.APXTConga4__Description__c.indexOf('Template Alias: ') + 15, ct.APXTConga4__Description__c.indexOf('\nSort')); 
            }
            
            System.debug('********************* ct.APXTConga4__Name__c in createSolutionRecordJunctions Template for loop: ' + ct.APXTConga4__Name__c);
            System.debug('********************* SolRecord map get call in createSolutionRecordJunctions Template for loop: ' + newSolutionRecords.get(ct.APXTConga4__Name__c));
                        
            SolMgrTemplatesToInsert.add(cst);            
        }
        
        for(APXTConga4__Conga_Template__c updatedTemplate : solutionPackUpdatedTemplates){
            
            System.debug('************************** solutionPackUpdatedTemplates: ' + solutionPackUpdatedTemplates);
            
            APXTConga4__Conga_Solution_Template__c cst = new APXTConga4__Conga_Solution_Template__c();
            cst.APXTConga4__Conga_Template__c = updatedTemplate.Id;
            if(existingSolutionSet.contains(updatedTemplate.APXTConga4__Name__c))
            {
                cst.APXTConga4__Conga_Solution__c = newSolutionRecords.get(updatedTemplate.APXTConga4__Name__c + ' ' + (String) rightNow.format('dd-MMM-yyyy hh mm ss a'));                
            }
            else
            {
                cst.APXTConga4__Conga_Solution__c = newSolutionRecords.get(updatedTemplate.APXTConga4__Name__c);
            }    
            cst.APXTConga4__Sort_Order__c = Double.ValueOf(updatedTemplate.APXTConga4__Description__c.substring(updatedTemplate.APXTConga4__Description__c.length()-1,updatedTemplate.APXTConga4__Description__c.length()));
            
            if(updatedTemplate.APXTConga4__Description__c.contains('Template Alias: '))
            {
                cst.APXTConga4__Output_File_Name__c = updatedTemplate.APXTConga4__Description__c.substring(updatedTemplate.APXTConga4__Description__c.indexOf('Template Alias: ') + 15, updatedTemplate.APXTConga4__Description__c.indexOf('\nSort')); 
            }
            
            System.debug('********************* updatedTemplate.APXTConga4__Name__c in createSolutionRecordJunctions Template for loop: ' + updatedTemplate.APXTConga4__Name__c);
                        
            SolMgrTemplatesToInsert.add(cst);            
        }*/                        
        /****************END OF Conga Solution Template Records****************/ 

        /****************Creating Conga Solution CET Records****************/         
        /*for(APXTConga4__Conga_Email_Template__c cet : solutionPackNewCETs){
            APXTConga4__Conga_Solution_Email_Template__c cset = new APXTConga4__Conga_Solution_Email_Template__c();
            cset.APXTConga4__Conga_Email_Template__c = cet.Id;

            if(existingSolutionSet.contains(cet.APXTConga4__Description__c.subString(cet.APXTConga4__Description__c.IndexOf(': ') + 2, cet.APXTConga4__Description__c.length())))
            {
                cset.APXTConga4__Conga_Solution__c = newSolutionRecords.get(cet.APXTConga4__Description__c.subString(cet.APXTConga4__Description__c.IndexOf(': ') + 2, cet.APXTConga4__Description__c.length()) + ' ' + (String) rightNow.format('dd-MMM-yyyy hh mm ss a'));                
            }
            else
            {
                cset.APXTConga4__Conga_Solution__c = newSolutionRecords.get(cet.APXTConga4__Description__c.subString(cet.APXTConga4__Description__c.IndexOf(': ') + 2, cet.APXTConga4__Description__c.length()));
            }
            //cset.APXTConga4__Conga_Solution__c =  newSolutionRecords.get(cet.APXTConga4__Description__c.subString(cet.APXTConga4__Description__c.IndexOf(': ') + 2, cet.APXTConga4__Description__c.length()));
            cset.APXTConga4__Comments__c = 'Created By Solution Pack';

            system.debug('********************** cset:' + cset);            
            SolMgrCETsToInsert.add(cset);
            
        }
        */
        /****************END OF Conga Solution CET Records****************/ 
                             
        //database.insert(SolMgrTemplatesToInsert);
        
        System.debug('****************************** SolMgrQvarsToInsert before insert: ' + SolMgrQvarsToInsert); 
        database.insert(SolMgrQvarsToInsert); 
        
        System.debug('****************************** SolMgrCETsToInsert before insert: ' + SolMgrCETsToInsert);                 
        database.insert(SolMgrCETsToInsert);

        System.debug('****************************** SolMgrQueriesToInsert before insert: ' + SolMgrQueriesToInsert); 
        database.insert(SolMgrQueriesToInsert);        
    }
    
    private void setSampleRecordIDs(){
        Set<String> masterObjects = new Set<String>();
        Map<String, String> sampleRecordMap = new Map<String, String>();
        List<APXTConga4__Conga_Solution__c> SolRecordsToUpdate = new List<APXTConga4__Conga_Solution__c>();
                
        for(APXTConga4__Conga_Solution__c newCSRecord: solutionPackSolutions)
        {
            if(newCSRecord.APXTConga4__Master_Object_Type__c != 'Home Page' && newCSRecord.APXTConga4__Master_Object_Type__c != 'APXTConga4__Composer_QuickMerge_Link__c')
            {
                masterObjects.add(newCSRecord.APXTConga4__Master_Object_Type__c);
            }            
        }
        
        String sampleRecordIdTrimmed = '';
        for(String masterObjectType : masterObjects)
        {
            try
            {
                List<SObject> sampleRecordId = database.Query('SELECT ID FROM ' + masterobjecttype + ' ORDER BY CreatedDate DESC LIMIT 1');
                if(sampleRecordId.size() != 0 && masterObjectType != 'Home Page' && masterObjectType != 'APXTConga4__Composer_QuickMerge_Link__c')
                {
                    sampleRecordIdTrimmed = (String) sampleRecordId.get(0).get('Id');
                    sampleRecordIdTrimmed = sampleRecordIdTrimmed.subString(0,15);
                    System.debug('********************* sampleRecordIdTrimmed: ' + sampleRecordIdTrimmed);                    
                    sampleRecordMap.put(masterObjectType, sampleRecordIdTrimmed);                
                }
            }
            catch(Exception ex)
            {
                // Exception here, either we couldn't update the Sol record or the Query against the master object type was bad
            }
        }
        
        for(APXTConga4__Conga_Solution__c newCSRecord: solutionPackSolutions)
        {
            if(masterObjects.contains(newCSRecord.APXTConga4__Master_Object_Type__c))
            {
                newCSRecord.APXTConga4__Sample_Record_Id__c = sampleRecordMap.get(newCSRecord.APXTConga4__Master_Object_Type__c);
                SolRecordsToUpdate.add(newCSRecord);
            }            
        }
        //System.debug('********************* SolRecordsToUpdate: ' + SolRecordsToUpdate);        
        database.update(SolRecordsToUpdate);
    }
    
    private void updateGlobalMergeSolMgrNames(){
        List<APXTConga4__Conga_Solution__c> SolutionsNamesToUpdate = new List<APXTConga4__Conga_Solution__c>();
        for(APXTConga4__Conga_Solution__c newCSRecord: solutionPackSolutions)
        {            
            if(newCSRecord.APXTConga4__Master_Object_Type__c == 'ADVSMS__Impacted_Job_Title__c' && newCSRecord.Name == 'Email')
            {
                newCSRecord.Name = 'Send Conga Email';
                SolutionsNamesToUpdate.add(newCSRecord);
            }                                       
        }
        database.update(SolutionsNamesToUpdate);        
    }
    
    
    private void updateExistingRecordSets(){
        String templateName = '';        
        String eqName = '';

        System.debug('********************* existingSolutions: ' + existingSolutions);        
        if(existingSolutions.size() != 0)
        {
            for(APXTConga4__Conga_Solution__c es : existingSolutions)
            {
                System.debug('********************* es: ' + es);
                existingSolutionSet.add(es.Name);
            }
            System.debug('********************* existingSolutionSet: ' + existingSolutionSet);                                        
        }

        System.debug('********************* existingTemplates: ' + existingTemplates);
        if(existingTemplates.size() != 0)        
        {
            for (APXTConga4__Conga_Template__c et : existingTemplates)
            {
                System.debug('********************* et: ' + et);                    
                templateName = et.APXTConga4__Name__c;
                existingTemplatesSet.add(templateName.trim());
            }
            System.debug('********************* existingTemplatesSet: ' + existingTemplatesSet);                                        
        }
        
        //System.debug('********************* existingCETs: ' + existingCETs);
        if(existingCETs.size() != 0)
        {  
            for(APXTConga4__Conga_Email_Template__c existingCET : existingCETs)
            {
                existingCETSet.add(existingCET.APXTConga4__Name__c);
            }
            System.debug('********************* existingCETSet: ' + existingCETSet);                            
        }
                    
        //System.debug('********************* existingQueries: ' + existingQueries);
        if(existingQueries.size() != 0)
        {
            for(APXTConga4__Conga_Merge_Query__c eq : existingQueries)
            {
                System.debug('********************* eq: ' + eq);                    
                eqName = eq.APXTConga4__Name__c;
                eqName = eqName.replace('\n','');
                eqName = eqName.replace('\n\n','');
                eqName = eqName.trim();
                System.debug('********************* eqName: ' + eqName); 
                existingQueriesSet.add(eqName);                                                                         
            }  
            System.debug('********************* existingQueriesSet: ' + existingQueriesSet);                
        }
                
    }
            
    public static void unpackTemplateGroupTemplates(Folder templateStorageFolder)
    {
        List<Document> documentsToProcess = [SELECT Id, Name, DeveloperName, ContentType, Body, Description, Type, Keywords FROM Document WHERE FolderId = :templateStorageFolder.Id];
        List<APXTConga4__Conga_Template__c> congaTemplatesToInsert = new List<APXTConga4__Conga_Template__c>();
        List<APXTConga4__Conga_Email_Template__c> CETsToInsert = new List<APXTConga4__Conga_Email_Template__c>();
        List<Attachment> templateAttachmentsToInsert = new List<Attachment>();
        Map<String, Document> fileDocMap = new Map<String, Document>();
        Map<String, Document> CETDocMap = new Map<String, Document>();
        
        System.debug('****************** documentsToProcess in unpackTemplateGroupTemplates Method: ' + documentsToProcess);
        
        for(Document D: documentsToProcess)
        {
            if((D.developerName.containsIgnoreCase('_FT') && D.developerName.containsIgnoreCase('_SPT_')) || Test.isRunningTest())
            {
              APXTConga4__Conga_Template__c ct = new APXTConga4__Conga_Template__c(APXTConga4__Name__c = D.Name, APXTConga4__Template_Group__c = D.Description, APXTConga4__Description__c = 'Created by a Conga Solution Pack');                                       
                congaTemplatesToInsert.add(ct);            
                fileDocMap.put(D.Name, D); 
            }
            if(D.developerName.containsIgnoreCase('_CET_'))
            {
                APXTConga4__Conga_Email_Template__c cet = new APXTConga4__Conga_Email_Template__c();
                    cet.APXTConga4__Name__c = D.Name;
                    cet.APXTConga4__Is_Body_Attachment__c = true;
                    cet.APXTConga4__Subject__c = D.Description;
                    cet.APXTConga4__Template_Group__c = D.Keywords;
                    cet.APXTConga4__Description__c = 'Created by a Conga Solution Pack'; 
                    
                CETsToInsert.add(cet);
                CETDocMap.put(D.Name, D);   
            }
        }
        if(congaTemplatesToInsert.size() > 0)
        {
            database.insert(congaTemplatesToInsert);
        }
        if(CETsToInsert.size() > 0)
        {
            database.insert(CETsToInsert);        
        }        
        
        for(APXTConga4__Conga_Template__c ct: congaTemplatesToInsert)
        {
            Attachment a = new Attachment();                
                a.ParentId = ct.Id;                
                a.Name = fileDocMap.get(ct.APXTConga4__Name__c).Name + '.' + fileDocMap.get(ct.APXTConga4__Name__c).Type;
                a.ContentType = fileDocMap.get(ct.APXTConga4__Name__c).ContentType;
                a.Body = fileDocMap.get(ct.APXTConga4__Name__c).Body;
                
            templateAttachmentsToInsert.add(a);
        }
        for(APXTConga4__Conga_Email_Template__c cet: CETsToInsert)
        {
            Attachment a = new Attachment(ParentId = cet.Id, Name = 'TemplateBody.html', ContentType = 'text/html', Body = CETDocMap.get(cet.APXTConga4__Name__c).Body);                                
            templateAttachmentsToInsert.add(a);
        }                
        
        database.insert(templateAttachmentsToInsert);        
        
    }
    
    private void updateExistingRecordMaps(){                                    
        if(existingQueries.size() != 0)
        {
            for(APXTConga4__Conga_Merge_Query__c existingQuery : existingQueries)
            {
                existingQueryMap.put(existingQuery.APXTConga4__Name__c, existingQuery);
                //existingQueryMap.put(existingQuery.APXTConga4__Name__c + existingQuery.APXTConga4__Description__c, existingQuery);
            }
            System.debug('******************** existingQueryMap: ' + existingQueryMap);                            
        }

        if(existingTemplates.size() != 0)
        {
            for(APXTConga4__Conga_Template__c existingTemplate : existingTemplates)
            {
                existingTemplateMap.put(existingTemplate.APXTConga4__Name__c, existingTemplate);
            }
            System.debug('******************** existingTemplateMap: ' + existingTemplateMap);                                    
        } 
        
        if(existingCETs.size() != 0)
        {
            for(APXTConga4__Conga_Email_Template__c existingCET : existingCETs)
            {
                existingCETMap.put(existingCET.APXTConga4__Name__c, existingCET);
            }
            System.debug('******************** existingCETMap: ' + existingCETMap);                    
        }        
                        
        if(existingSolutions.size() != 0)
        {
            for(APXTConga4__Conga_Solution__c existingSolution : existingSolutions)
            {
                existingSolutionMap.put(existingSolution.Name, existingSolution);
            }
            System.debug('******************** existingSolutionMap: ' + existingSolutionMap);                    
        }                        
    }    

}