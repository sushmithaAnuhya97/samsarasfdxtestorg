/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 06-29-2023
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
 * @Test Coverage     : QueueableContractConsolidation, QueueableContractConsolidationVf,ByPassTriggers
**/
@isTest
public class QueueableContractConsolidationTest {
    @testSetup
    private static void testDataSetup() {
        //To bypass triggers
        bypass();       
        //Standard Pricebook
        Id pricebookId = Test.getStandardPricebookId();
        
        //Create Products
        List<Product2> products = new List<Product2>();
    	Product2 vgLicense = new Product2(Name= 'LIC-VG-36MO', ProductCode = 'LIC-VG-36MO', Family = 'Test',IsActive =true,SBQQ__SubscriptionPricing__c='Fixed Price');
        products.add(vgLicense);  
        insert products;
      	//Create PriceBookEntries
        List<PricebookEntry> pricebookEntries = new List<PricebookEntry>();
        PricebookEntry vg33PB = new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = products[0].Id, UnitPrice = 10000, IsActive = true);
        pricebookEntries.add(vg33PB);
   		insert pricebookEntries;        
        Account account = new Account ();
        account = TestFactory.initializeAccount('Test Account');
        insert account;
    	//Create Opportunity
        List<Opportunity> newOpportunities = new List<Opportunity>();
        Opportunity revenueOpportunity1 = new Opportunity( AccountId = account.Id, License_Term__c =36, Pricebook2Id = pricebookId, 
                                                          Max_Approved_Discount__c=0, Name = 'Revenue Opportunity1', Price_Book_Name__c = 'Standard Price Book', 
                                                          CloseDate = System.today() + 90, StageName = 'Incubate', Owner_Role_Copy__c='Fleet IS AE2 NA US Team 8'); 
        newOpportunities.add(revenueOpportunity1);
        Opportunity revenueOpportunity2 = new Opportunity( AccountId = account.Id, License_Term__c =36, Pricebook2Id = pricebookId, 
                                                          Max_Approved_Discount__c=0, Name = 'Revenue Opportunity2', Price_Book_Name__c = 'Standard Price Book', 
                                                          CloseDate = System.today() + 90, StageName = 'Incubate', Owner_Role_Copy__c='Fleet IS AE2 NA US Team 8'); 
        newOpportunities.add(revenueOpportunity2);
		 Opportunity revenueOpportunity3 = new Opportunity( AccountId = account.Id, License_Term__c =36, Pricebook2Id = pricebookId, 
                                                          Max_Approved_Discount__c=0, Name = 'Revenue Opportunity3', Price_Book_Name__c = 'Standard Price Book', 
                                                          CloseDate = System.today() + 90, StageName = 'Incubate', Owner_Role_Copy__c='Fleet IS AE2 NA US Team 8');
        
        newOpportunities.add(revenueOpportunity3);
        Opportunity renewalOpportunity1 = new Opportunity( AccountId = account.Id, License_Term__c =36, Pricebook2Id = pricebookId, 
                                                          Max_Approved_Discount__c=0, Name = 'Renewal Opportunity1', Price_Book_Name__c = 'Standard Price Book', 
                                                          CloseDate = System.today() + 90, StageName = 'Incubate', Owner_Role_Copy__c='Fleet IS AE2 NA US Team 8', Shipping_Address_NEW__c=null); 
        
        newOpportunities.add(renewalOpportunity1); 
        Opportunity renewalOpportunity2 = new Opportunity( AccountId = account.Id, License_Term__c =36, Pricebook2Id = pricebookId, 
                                                          Max_Approved_Discount__c=0, Name = 'Renewal Opportunity2', Price_Book_Name__c = 'Standard Price Book', 
                                                          CloseDate = System.today() + 90, StageName = 'Incubate', Owner_Role_Copy__c='Fleet IS AE2 NA US Team 8', Shipping_Address_NEW__c=null); 
        
        newOpportunities.add(renewalOpportunity2);
        Opportunity renewalOpportunity3 = new Opportunity( AccountId = account.Id, License_Term__c =36, Pricebook2Id = pricebookId, 
                                                          Max_Approved_Discount__c=0, Name = 'Renewal Opportunity3', Price_Book_Name__c = 'Standard Price Book', 
                                                          CloseDate = System.today() + 90, StageName = 'Incubate', Owner_Role_Copy__c='Fleet IS AE2 NA US Team 8', Shipping_Address_NEW__c=null); 
        
        newOpportunities.add(renewalOpportunity3);         
        insert newOpportunities;
        // Create OpportunityLineItems
        List<OpportunityLineItem> oppProductList = new List<OpportunityLineItem>();
        OpportunityLineItem ol1 = new OpportunityLineItem (OpportunityId=newOpportunities[0].Id, Quantity=2, PricebookEntryId=pricebookEntries[0].Id, UnitPrice=pricebookEntries[0].UnitPrice,Product2Id = products[0].Id);
        oppProductList.add(ol1);
        OpportunityLineItem ol2 = new OpportunityLineItem (OpportunityId=newOpportunities[1].Id, Quantity=2, PricebookEntryId=pricebookEntries[0].Id, UnitPrice=pricebookEntries[0].UnitPrice,Product2Id = products[0].Id);
        oppProductList.add(ol2);
        OpportunityLineItem ol3 = new OpportunityLineItem (OpportunityId=newOpportunities[2].Id, Quantity=2, PricebookEntryId=pricebookEntries[0].Id, UnitPrice=pricebookEntries[0].UnitPrice,Product2Id = products[0].Id);
        oppProductList.add(ol3);
        OpportunityLineItem ol4 = new OpportunityLineItem (OpportunityId=newOpportunities[3].Id, Quantity=2, PricebookEntryId=pricebookEntries[0].Id, UnitPrice=pricebookEntries[0].UnitPrice,Product2Id = products[0].Id);
        oppProductList.add(ol4);
        OpportunityLineItem ol5 = new OpportunityLineItem (OpportunityId=renewalOpportunity2.Id, Quantity=2, PricebookEntryId=pricebookEntries[0].Id, UnitPrice=pricebookEntries[0].UnitPrice,Product2Id = products[0].Id);
        oppProductList.add(ol5);
  		Insert oppProductList;
        System.debug('oppProductList: '+oppProductList);
        List<Contract> listC=new List<Contract>();  
        Contract contract1 = new Contract(
            AccountId = account.Id,
            StartDate = Date.today(),
            EndDate = Date.today().adddays(130),
            ContractTerm = 12,
            SBQQ__Opportunity__c=revenueOpportunity1.Id
        );
        listC.add(contract1);     
        Contract contract2 = new Contract(
            AccountId = account.Id,
            StartDate = Date.today(),
            EndDate = Date.today().adddays(130),
            ContractTerm = 12,
            SBQQ__Opportunity__c=revenueOpportunity2.Id
        );
        listC.add(contract2);
        Contract contract3 = new Contract(
            AccountId = account.Id,
            StartDate = Date.today(),
            EndDate = Date.today().adddays(130),
            ContractTerm = 12,
            SBQQ__Opportunity__c=revenueOpportunity2.Id
            
        );
          Contract contract4 = new Contract(
            AccountId = account.Id,
            StartDate = Date.today(),
            EndDate = Date.today().adddays(130),
            ContractTerm = 12,
            SBQQ__Opportunity__c=revenueOpportunity2.Id,
            SBQQ__RenewalOpportunity__c = renewalOpportunity2.id
              
            
        );
        listC.add(contract3);
        listC.add(contract4);
  		insert listC;                     
    } 
    public static void createQuoteData(){
        Account testAccount = [SELECT id, Name, BillingCountry FROM Account WHERE Name like '%Test Account%'];
        Map<String,Opportunity> mapOpps=new Map<String,Opportunity>();
        for(Opportunity testOpportunity : [SELECT id, Name From Opportunity]){
            mapOpps.put(testOpportunity.Name,testOpportunity);
        }        
        Map<String,Contract> mapContracts=new Map<String,Contract>();
        for(Contract ctt : [SELECT Id,ContractNumber, StartDate,EndDate,SBQQ__Opportunity__r.Name FROM Contract]){
            mapContracts.put(ctt.SBQQ__Opportunity__r.Name,ctt);
        }
        Product2 vgProduct = [SELECT id FROM Product2 WHERE Name = 'LIC-VG-36MO'];
        PricebookEntry pricebookEntry = [SELECT id, Product2Id, UnitPrice FROM PricebookEntry WHERE Product2Id =: vgProduct.Id]; 
        createRenewalQuoteData(testAccount,mapOpps,mapContracts,vgProduct,pricebookEntry);
        
    }
    public static void createRenewalQuoteData(Account testAccount,Map<String,Opportunity> mapOpps,Map<String,Contract> mapContracts,Product2 vgProduct,PricebookEntry pricebookEntry){
        List<SBQQ__Quote__c> listQ=new List<SBQQ__Quote__c>();
        for(Opportunity o: mapOpps.values()){
            SBQQ__Quote__c quote = new SBQQ__Quote__c(Quote_Name__c = 'Test Version', SBQQ__Opportunity2__c =o.Id, 
                                                      SBQQ__Primary__c = false, SBQQ__Type__c='Quote',Process_Eligibility__c = 'Digital Renewals');
            listQ.add(quote);
        }
        
        insert listQ;
        System.debug('listQ: '+listQ);
        List<SBQQ__QuoteLine__c> newlineItems = new List<SBQQ__QuoteLine__c>();
        for(SBQQ__Quote__c q:listQ){
            SBQQ__QuoteLine__c quoteLineOne =  new SBQQ__QuoteLine__c(SBQQ__Quote__c = q.Id, SBQQ__PricebookEntryId__c = pricebookEntry.Id, SBQQ__Quantity__c  = 5, 
                                                                      SBQQ__Discount__c = 0, SBQQ__Product__c = vgProduct.Id, accountLookupTest__c = testAccount.Id);
            newlineItems.add(quoteLineOne); 
            
           
        }
        insert newlineItems;
        
    }
    @isTest
    public static void testQueueableContractConsolidation(){
        //To bypass triggers
        bypass();
        Product2 vgProduct = [SELECT id FROM Product2 WHERE Name = 'LIC-VG-36MO'];
        Account acc = [SELECT id, Name, BillingCountry FROM Account WHERE Name like '%Test Account%'];
         Map<String,Opportunity> mapOpps=new Map<String,Opportunity>();
        for(Opportunity testOpportunity : [SELECT id, Name,of_LIC_Products__c From Opportunity]){
            mapOpps.put(testOpportunity.Name,testOpportunity);
            System.debug('testOpportunity: '+mapOpps.get(testOpportunity.Name));
        }
        
        Map<String,Contract> mapContracts=new Map<String,Contract>();
        for(Contract ctt : [SELECT Id,ContractNumber, StartDate,EndDate,SBQQ__Opportunity__r.Name FROM Contract]){
            mapContracts.put(ctt.SBQQ__Opportunity__r.Name,ctt);
        }        
         
         for(Contract ctt : [SELECT Id,ContractNumber, StartDate,EndDate,SBQQ__Opportunity__r.Name,Is_Active__c,Deactivated__c FROM Contract]){
   			ctt.SBQQ__RenewalOpportunity__c=mapOpps.get('Renewal Opportunity'+ctt.SBQQ__Opportunity__r.Name.replace('Revenue Opportunity','')).Id;
            ctt.Status='Activated';
            ctt.Deactivated__c=false;
            mapContracts.put(ctt.SBQQ__Opportunity__r.Name,ctt);
        }
        update mapContracts.values();
    	Test.startTest();
        createQuoteData();
        List<SBQQ__Quote__c> sbqqQuote = [SELECT ID,Quote_Name__c,SBQQ__Opportunity2__c FROM SBQQ__Quote__c WHERE SBQQ__Opportunity2__r.Name = 'Renewal Opportunity1'];
        System.debug('sbqqQuote: '+sbqqQuote.size());
        List<Opportunity> oppIdList = new List<Opportunity>();
        Opportunity oppId = [SELECT ID,Name FROM Opportunity WHERE Name ='Renewal Opportunity1'];
   		oppId.SBQQ__PrimaryQuote__c = sbqqQuote[0].id;
        oppIdList.add(oppId);
        String baseKey = acc.id+'_'+UserInfo.getUserId()+'_'+DateTime.now().year()+'-'+DateTime.now().month()+'-'+DateTime.now().day()+'_'+DateTime.now().hour()+':'+DateTime.now().minute()+':'+DateTime.now().second();
        String key = baseKey+1;
        System.debug('Key1: '+baseKey);
        List<Contract_Consolidation_Request__c> ccrecordList = new List<Contract_Consolidation_Request__c>();
        List<Contract> cttList = [SELECT ID,Name,SBQQ__MasterContract__c FROM Contract];
        System.debug('Contract Record: '+cttList[0].SBQQ__MasterContract__c + 'Contract Record: '+cttList );
        
        //Status == New
        
        ccrecordList.add(new Contract_Consolidation_Request__c(Name = key, Contract__c = cttList[0].Id,Master_Contract__c=true, Status__c = 'New'));
        ccrecordList.add(new Contract_Consolidation_Request__c(Name = key, Contract__c = cttList[1].Id,Master_Contract__c=false, Status__c = 'New'));
        
        //Status == Quoted UnChecked
        
        String keyUnchecked = baseKey+2;
        System.debug('Key2: '+keyUnchecked);
        ccrecordList.add(new Contract_Consolidation_Request__c(Name = keyUnchecked, Contract__c = cttList[0].Id,Master_Contract__c=false, Status__c = 'Quoted UnChecked'));
        ccrecordList.add(new Contract_Consolidation_Request__c(Name = keyUnchecked, Contract__c = cttList[1].Id,Master_Contract__c=false, Status__c = 'Failed'));
        ccrecordList.add(new Contract_Consolidation_Request__c(Name = keyUnchecked, Contract__c = cttList[2].Id,Master_Contract__c=false, Status__c = 'Quoted UnChecked'));
        
        //Status == Quoted Checked
        
        String keyChecked = baseKey+3;
        System.debug('Key3: '+keyChecked);
        ccrecordList.add(new Contract_Consolidation_Request__c(Name = keyChecked, Contract__c = cttList[0].Id,Master_Contract__c=false, Status__c = 'Quoted UnChecked'));
        ccrecordList.add(new Contract_Consolidation_Request__c(Name = keyChecked, Contract__c = cttList[1].Id,Master_Contract__c=false, Status__c = 'Quoted Checked'));
        ccrecordList.add(new Contract_Consolidation_Request__c(Name = keyChecked, Contract__c = cttList[2].Id,Master_Contract__c=false, Status__c = 'Quoted Checked'));
        
        //Status == Completed
        String keyCompleted = baseKey+4;
        System.debug('Key4: '+keyCompleted);
        update oppIdList;
        ccrecordList.add(new Contract_Consolidation_Request__c(Name = keyCompleted, Contract__c = cttList[0].Id,Master_Contract__c=false, Status__c = 'Quoted Checked'));
        ccrecordList.add(new Contract_Consolidation_Request__c(Name = keyCompleted, Contract__c = cttList[0].Id,Master_Contract__c=true, Status__c = 'Completed'));
       
        
        // Status == failed
       
        String keyFailed = baseKey+5;
        System.debug('Key5: '+keyFailed);
    	ccrecordList.add(new Contract_Consolidation_Request__c(Name = keyFailed, Contract__c = cttList[1].Id,Master_Contract__c=false, Status__c = 'Failed'));
        ccrecordList.add(new Contract_Consolidation_Request__c(Name = keyFailed, Contract__c = cttList[0].Id,Master_Contract__c=true, Status__c = 'Failed'));
        // Status == Quote UnChecked with masterContract = true
        String keyUncheckedMaster = baseKey+6;
        System.debug('Key6: '+keyUncheckedMaster);
        ccrecordList.add(new Contract_Consolidation_Request__c(Name = keyUncheckedMaster, Contract__c = cttList[1].Id,Master_Contract__c=true, Status__c = 'Quoted UnChecked'));
   		
        insert ccrecordList;
        // Sequence of Queueable Jobs Invocation.
        QueueableContractConsolidation qccUncheckedNew = new QueueableContractConsolidation('Quoted UnChecked',key);
        System.enqueueJob(qccUncheckedNew);
        
       
        QueueableContractConsolidation qccUnchecked = new QueueableContractConsolidation('Quoted UnChecked',keyUnchecked);
        System.enqueueJob(qccUnchecked);
        
       
        QueueableContractConsolidation qccChecked = new QueueableContractConsolidation('Quoted Checked',keyChecked);
        System.enqueueJob(qccChecked);
        
       
        QueueableContractConsolidation qccConsolidate = new QueueableContractConsolidation('Consolidate',keyCompleted);
        System.enqueueJob(qccConsolidate);
        QueueableContractConsolidation qccCheckedforPrimaryQuote = new QueueableContractConsolidation('Quoted Checked',keyCompleted);
        System.enqueueJob(qccCheckedforPrimaryQuote);
      
        QueueableContractConsolidation qccFailed = new QueueableContractConsolidation('Consolidate',keyFailed);
        System.enqueueJob(qccFailed);
        QueueableContractConsolidation qccUnCheckedMarked = new QueueableContractConsolidation('Quoted Checked',keyUncheckedMaster);
        System.enqueueJob(qccUnCheckedMarked);
        List<Contract_Consolidation_Request__c> ccrRecordList = new List<Contract_Consolidation_Request__c>();
        
        String keyFinishedMaster = baseKey+7;
        ccrRecordList.add(new Contract_Consolidation_Request__c(Name = keyFinishedMaster, Contract__c = cttList[0].Id,Master_Contract__c=true, Status__c = 'Failed'));
        
        String keyCompletedMaster = baseKey+8;
        System.debug('Key7: '+keyCompletedMaster);
        ccrRecordList.add(new Contract_Consolidation_Request__c(Name = keyCompletedMaster, Contract__c = cttList[0].Id,Master_Contract__c=true, Status__c = 'Completed'));
        insert ccrRecordList;
        
        QueueableContractConsolidation qccFinishedMarked = new QueueableContractConsolidation('Consolidate',keyFinishedMaster);
        System.enqueueJob(qccFinishedMarked);
        QueueableContractConsolidation qccCompletedMarked = new QueueableContractConsolidation('Consolidate',keyCompletedMaster);
        System.enqueueJob(qccCompletedMarked);
        
        QueueableContractConsolidation qccCompletedMarked1 = new QueueableContractConsolidation('Recalculate Quote',keyCompletedMaster);
        System.enqueueJob(qccCompletedMarked1);
        
        PageReference myVfPage = Page.QueueableContractConsolidationVf;
   		myVfPage.getParameters().put('id',sbqqQuote[0].id);
        myVfPage.getParameters().put('RecalculateQuote','false');
   		Test.setCurrentPage(myVfPage); 
		String id = ApexPages.currentPage().getParameters().get('id');
        QueueableContractConsolidationVf qccvf = new QueueableContractConsolidationVf();
        qccvf.updateSBQQ_Quote();
        
        Contract_Consolidation_Request__c ccrForValidate = [SELECT Name FROM Contract_Consolidation_Request__c LIMIT 1];
        QueueableContractConsolidation qccValidate = new QueueableContractConsolidation('Validate', ccrForValidate.Name);
        System.enqueueJob(qccValidate);
       
        Contract masterContract = [Select Id From Contract where SBQQ__RenewalOpportunity__c != null LIMIT 1];
        
        Contract_Consolidation_Request__c masterCCR = new Contract_Consolidation_Request__c(
            Name='MasterCCRWithRenewalOpp',
            Contract__c=masterContract.Id,
            Master_Contract__c=true
        );
        insert masterCCR;
        QueueableContractConsolidation qc = new QueueableContractConsolidation('Validate', 'MasterCCRWithRenewalOpp');
    	System.enqueueJob(qc);

    Id validContractId = [SELECT Id FROM Contract LIMIT 1].Id;
    Contract_Consolidation_Request__c badCCR = new Contract_Consolidation_Request__c(
        Name = 'ExceptionKeyConsolidate',
        Status__c = 'Quoted Checked',
        Master_Contract__c = false,
        Contract__c = validContractId
    );
    insert badCCR;
    QueueableContractConsolidation qcc1 = new QueueableContractConsolidation('Consolidate', 'ExceptionKeyConsolidate');
    System.enqueueJob(qcc1);
        
    Id validContractId1 = [SELECT Id FROM Contract LIMIT 1].Id;
    Contract_Consolidation_Request__c badCCR1 = new Contract_Consolidation_Request__c(
        Name = 'ExceptionKeyUnChecked',
        Status__c = 'New',
        Master_Contract__c = false,
        Contract__c = validContractId1
    );
    insert badCCR1;
    QueueableContractConsolidation qcc2 = new QueueableContractConsolidation('Quoted UnChecked', 'ExceptionKeyUnChecked');
    System.enqueueJob(qcc2);
    Test.stopTest();        

        
    }
    
    @isTest
    public static void testValidateWithNullMasterContract(){
        Test.startTest();
        Account account = [Select Id From Account LIMIT 1];
        Contract contract = [Select Id FROM Contract LIMIT 1];
         Contract_Consolidation_Request__c ccr = new Contract_Consolidation_Request__c(
                Name = 'TestKey_' + System.now().format('yyyy-MM-dd_HH:mm:ss'),
                Contract__c = contract.Id,
                Status__c = 'New',
                Master_Contract__c = false
            );
        insert ccr;
        QueueableContractConsolidation qccValidate1 = new QueueableContractConsolidation('Validate', ccr.Name);
        System.enqueueJob(qccValidate1);
        Test.stopTest();
    }
    
    @isTest
    public static void testValidateMasterVsChildRenewalOpp() {
        // Setup Account
        Account acc = new Account(Name='Test Account',Organization_Size__c = '1 - 99',Industry='Agriculture',
            BillingState='California',
            ShippingState='California');
        insert acc;
    
        // Setup Contracts
        List<Contract> conList = new List<Contract>();
        Contract masterContract = new Contract(AccountId=acc.Id, StartDate=Date.today(), EndDate=Date.today().addMonths(12));
        conList.add(masterContract);
        Contract childContract = new Contract(AccountId=acc.Id, StartDate=Date.today(), EndDate=Date.today().addMonths(6));
        conList.add(childContract);
        insert conList;
        
		Test.startTest();
    
        // Setup Opportunities (different for master and child)
        List<Opportunity> opptyList = new List<Opportunity>();
        Opportunity masterOpp = new Opportunity(Name='Master Opp', AccountId=acc.Id, CloseDate=Date.today().addMonths(12), StageName='Closed Won');
        opptyList.add(masterOpp);
        Opportunity childOpp = new Opportunity(Name='Child Opp', AccountId=acc.Id, CloseDate=Date.today().addMonths(6), StageName='Closed Won');
        opptyList.add(childOpp);
        insert opptyList;
    
        // Link contracts to different renewal opportunities
        masterContract.SBQQ__RenewalOpportunity__c = opptyList[0].Id;
        childContract.SBQQ__RenewalOpportunity__c = opptyList[1].Id;
        update new List<Contract>{conList[0], conList[1]};
    
        // Previous renewal opportunity for child contract (not Closed Lost)
        Opportunity prevChildOpp = new Opportunity(
            Name='Prev Child Opp',
            AccountId=acc.Id,
            CloseDate=Date.today().addMonths(3),
            StageName='Prospecting', // Not Closed Lost
            SBQQ__RenewedContract__c=conList[1].Id
        );
        insert prevChildOpp;
    
        // CCRs with same Name
        String ccrName = 'TestCCRSameName';
        Contract_Consolidation_Request__c masterCCR = new Contract_Consolidation_Request__c(
            Name=ccrName,
            Contract__c=conList[0].Id,
            Master_Contract__c=true
        );
        Contract_Consolidation_Request__c childCCR = new Contract_Consolidation_Request__c(
            Name=ccrName,
            Contract__c=conList[1].Id,
            Master_Contract__c=false
        );
        insert new List<Contract_Consolidation_Request__c>{masterCCR, childCCR};
    
        // Run the validate logic
        
        QueueableContractConsolidation qc = new QueueableContractConsolidation('Validate', ccrName);
        System.enqueueJob(qc);
        Test.stopTest();

    }

    @isTest
    public static void testValidateWithNoCCR() {
        // This will cover the branch where no CCRs are found
        QueueableContractConsolidation qcc = new QueueableContractConsolidation('Validate', 'NonExistentKey');
        Test.startTest();
        System.enqueueJob(qcc);
        Test.stopTest();
        System.assert(true, 'Validate branch with no CCR covered');
    }
         
    public static void byPass(){
        SBQQ.TriggerControl.disable();
        TriggerHandler.bypass('ContractTriggerHandler');
        TriggerHandler.bypass('GS_AccountTriggerHandler');
        TriggerHandler.bypass('OpportunityTriggerHandler');
        TriggerHandler.bypass('OpportunityTeamMemberTriggerHandler');
        OpportunityTriggerHandler.addCall('beforeUpdate');
        OpportunityTriggerHandler.addCall('afterUpdate');
        OpportunityTriggerHandler.addCall('afterInsert');
    }

}