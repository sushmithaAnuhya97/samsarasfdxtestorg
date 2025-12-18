//GTMS-3772: Lavanya : . Updated the code in "FlowAccountFinder" class to add an escape character if the name contains "single quote". Used "escapeSingleQuotes" method.
//GTMS-7844: Ranadheer : Updated the code in "FlowAccountFinder" class to add an escape character if the BillingCity contains "single quote". Used "escapeSingleQuotes" method.
//GTMS-7844: Ranadheer : Updated the code in "FlowAccountFinder" class. As Alternative Domains in Account object is text field, Whenever user provides input in wrong format Duplicate check flow is failing.
public class FlowAccountFinder {
    @InvocableMethod(label='Search for Accounts by Name' description='Returns a list of matching accounts given a string.')
    public static List<List<Account>> searchForAccounts(List<List<Account>> a){
        List<List<SObject>> results = new List<List<Account>>();
        List<String> nameSearch = parseAccountName(a[0][0].Name);
        List<String> domainSearch = parseDomainNames(a[0][0]);
        List<String> phoneSearch = parsePhoneNumber(a[0][0].Phone);
        List<String> addressSearch = parseAddress(a[0][0]);
        String sosl_query = 'FIND \'';
        String soql_query = 'Account (Name,Account_Owner__c,Account_with_Owner__c,Account_Assignment_Date__c,Status__c,Id,Website,Domain_Name__c,Phone,DUNS_Number__c,BillingStreet,BillingState,BillingCity,BillingCountry,OwnerId,RecordTypeId';
        String soql_optional = '';
        String soql_required = '';
        //search Account name in SOSL Query
        if(nameSearch.size()>0){
            for(Integer i=0;i<nameSearch.size();i++){
                String name = String.escapeSingleQuotes(nameSearch[i]); 
                if(i>0){
                    sosl_query+=' OR ';
                }
                sosl_query += name;
            }
        }
        //search Domain Names in SOSL query
        if(domainSearch.size()>0){
            if(nameSearch.size()>0){
                sosl_query+= ' OR ';
            }
            for(Integer i=0;i<domainSearch.size();i++){
                if(i>0){
                    sosl_query+=' OR ';
                }
                sosl_query += domainSearch[i];
            }
        }
        //search normalized phone number in SOSL query
        if(phoneSearch.size()>0){
            if(nameSearch.size()>0 || domainSearch.size()>0){
                sosl_query+= ' OR ';
            }
            sosl_query += phoneSearch[(phoneSearch.size()-1)];
        }
        sosl_query += '\' IN ALL FIELDS RETURNING ';
        //require recordTypeId to match to avoid linking Industrial and CW.
        if(!String.isBlank(a[0][0].RecordTypeId)){
            if(soql_required.length()>0){
                soql_required += ' AND ';
            }
            soql_required += 'RecordTypeId=\''+a[0][0].RecordTypeId+'\'';
        }
        //require accountID not to match to avoid returning the same account
        if(!String.isBlank(a[0][0].Id)){
            //if multiple account records are passed, exclude their ID from the results
            if(a[0].size()>1){
                List<string> acct_ids = new List<string>();
                for(Account acct :a[0]){
                    acct_ids.add(acct.Id);
                }
                if(acct_ids.size()>0){
                    if(soql_required.length()>0){
                        soql_required += ' AND ';
                    }
                    soql_required += 'Id NOT IN :acct_ids';
                }
            }
            else{ //if one account record is passed, exclude the ID from the results
                if(soql_required.length()>0){
                    soql_required += ' AND ';
                }
                soql_required += 'Id!=\''+a[0][0].RecordTypeId+'\'';
            }
        }
        
        //use phone number chunks to filter results
        if(phoneSearch.size()>0){
            if(soql_optional.length()>0){
                soql_optional+= ' OR ';
            }
            soql_optional+='(Phone!=\'\' AND (';
            for(Integer i=0;i<phoneSearch.size();i++){
                if(i>0){
                    soql_optional+=' OR ';
                }
                soql_optional += 'Phone LIKE \'%'+phoneSearch[i]+'%\'';
            }
            soql_optional += ')) OR Phone=\'\'';
        }
        if(addressSearch.size()>0){
            if(soql_optional.length()>0){
                soql_optional+= ' OR ';
            }
            soql_optional += 'BillingStreet LIKE :addressSearch OR BillingStreet=\'\'';
        }
        if(!String.isBlank(a[0][0].BillingState)){
            if(soql_optional.length()>0){
                soql_optional+= ' OR ';
            }
            soql_optional += 'BillingState=\''+a[0][0].BillingState+'\' OR BillingState=\'\'';
        }
        if(!String.isBlank(a[0][0].BillingCity) && safeSearch(a[0][0].BillingCity)){
            if(soql_optional.length()>0){
                soql_optional+= ' OR ';
            }
            //Added logic to escape Single quotes as per Ticket : GTMS-7844
            soql_optional += 'BillingCity LIKE \'%'+String.escapeSingleQuotes(a[0][0].BillingCity)+'%\'';
        }
        if(!String.isBlank(a[0][0].BillingPostalCode)){
            if(soql_optional.length()>0){
                soql_optional+= ' OR ';
            }
            soql_optional += 'BillingPostalCode LIKE \'%'+a[0][0].BillingPostalCode+'%\'';
        }
        if(!String.isBlank(a[0][0].DUNS_Number__c) && safeSearch(a[0][0].DUNS_Number__c)){
            if(soql_optional.length()>0){
                soql_optional+= ' OR ';
            }
            soql_optional += 'DUNS_Number__c = \''+a[0][0].DUNS_Number__c+'\'';
            soql_optional += 'OR DUNS_Number__c = \'\'';
        }
        if(!String.isBlank(a[0][0].BillingCountry)){
            if(soql_optional.length()>0){
                soql_optional+= ' OR ';
            }
            soql_optional += 'BillingCountry=\''+a[0][0].BillingCountry+'\'';
        }
        if(soql_optional.length()>0 || soql_required.length()>0){
            soql_query += ' WHERE ';
            if(soql_required.length()>0){
                soql_query += soql_required;
                if(soql_optional.length()>0){
                    soql_query += ' AND ('+soql_optional+')';
                }
            }
            else{
                soql_query += soql_optional;
            }
        }
        sosl_query += soql_query +') WITH HIGHLIGHT LIMIT 10';
        System.debug(sosl_query);
        results = search.query(sosl_query);
        //repair null blank fields
        Account a2 = new Account();
        for(Integer i=0;i<results[0].size();i++){
            a2 = (Account)results[0][i];
            if(String.isBlank(a2.Website)){a2.Website='';}
            if(String.isBlank(a2.Domain_Name__c)){a2.Domain_Name__c='';}
            if(String.isBlank(a2.BillingStreet)){a2.BillingStreet='';}
            if(String.isBlank(a2.BillingCity)){a2.BillingCity='';}
            if(String.isBlank(a2.BillingState)){a2.BillingState='';}
            if(String.isBlank(a2.Phone)){a2.Phone='';}
            if(String.isBlank(a2.DUNS_Number__c)){a2.DUNS_Number__c='';}
            results[0][i] = a2;
        }
        return results;
    }
    
    private static List<String> parseAccountName(String accountName){
        List<String> names = new List<String>();
        if(!String.isBlank(accountName)){
            for (String fragment : accountName.split(' ')){
                fragment = fragment.replaceFirst('/[^0-9A-Za-z]/','');
                if(fragment.length()>2 && safeSearch(fragment)){
                    names.add(fragment);
                }
            }
            if(safeSearch(accountName)){
                names.add(accountName);
            }
        }
        return names;
    }
    
    private static List<String> parseDomainNames(Account a){
        List<String> domains = new List<String>();
        String cd = '';
        if(!String.isBlank(a.Website)){
            domains.add(a.Website);
            String websiteDomain = a.Website.replaceFirst('^(https?://)?(www\\.)?', '').split('/')[0];
            domains.add(websiteDomain);
        }
        if(!String.isBlank(a.Domain_Name__c)){
            domains.add(a.Domain_Name__c);
        }
        if(!String.isBlank(a.Alternative_Domains__c)){
            //Added below logic as Alternative Domains is text field, Whenever user provides input in wrong format
            //Duplicate check flow is failing. Ticket:GTMS-7844
            String S = a.Alternative_Domains__c;
            S=S.replace('[','');
            S=S.replace(']','');
            S=S.replace('"','');
            List<String> altDomains = S.split(',');
            String finalString ='[';
            for(String ad: altDomains){
                if(finalString!='['){
                    finalString +=',';
                }
                finalString += '"'+ad+'"'; 
            }
            finalString +=']';
            JSONParser parser = JSON.createParser(finalString);
            while(parser.nextToken() != null){
                if(parser.getCurrentToken() == JSONToken.START_ARRAY){
                    while(parser.nextToken()!=null){
                        if(parser.getCurrentToken() == JSONToken.VALUE_STRING){
                            cd = parser.getText();
                            if(safeSearch(cd)){
                                domains.add(cd);
                            }
                        }
                    }
                }
            }
        }
        return domains;
    }
    
    private static List<String> parsePhoneNumber(String phoneNumber){
        List<String> chunkNumbers = new List<String>();
        String normalizedNum = '';
        if(!String.isBlank(phoneNumber)){
            for(String chunk : phoneNumber.splitByCharacterTypeCamelCase()){
                if(chunk.isNumeric()){
                    chunkNumbers.add(chunk);
                    normalizedNum += chunk;
                }
            }
            chunkNumbers.add(normalizedNum);
        }
        return chunkNumbers;
    }
    
    private static List<String> parseAddress(Account a){
        List<String> addressSearch = new List<String>();
        if(!String.isBlank(a.BillingStreet)){
            for(String chunk : a.BillingStreet.splitByCharacterTypeCamelCase()){
                if(chunk.length()>1 && safeSearch(chunk)){
                    addressSearch.add(chunk+'%');
                }
            }
        }
        return addressSearch;
    }
    //safeSearch class prevents injection + filters unuseful search terms
    private static boolean safeSearch(String s){
        List<String> bad_terms = new List<string>{'insert','update','delete','select','find','name','phone','where','like','group','order','null','with','limit','offset','tra','ran','ons','truc','inc','ing','tio','str','ion','constru','ort','kin','ser','nst','tru','ans','por','ric','con','tran','ruck','nsp','llc','omp','tion','corpo','ica','cons','corpor','rac','struct','construc','ice','serv','vic','servi','servic','vice','trucki','ervice','mpa','ent','ate','ris','res','trans','nds','ati','port','nte','nco','ist','lan','sport','transp','transpo','transpor','ntr','cont','transporta','pres','eri','contr','ine','gis','service','tor','est','lec','ele','struc','ill','const','truck','construct','ass','and','constructi','tat','orp','tri','king','ond','cor','ers','cking','lin','truckin','transport','trucking','ste','contrac','tin','transportati','rib','arm','rpr','com','enterp','ect','far','dis','ech','ess','act','cti','rat','solu','ces','tic','pre','log','sti','trac','distri','ver','electr','tract','corpora','ree','ain','ices','services','lli','car','tem','tern','ora','rica','tric','pin','logi','ast','press','manag','ting','lum','sto','landsc','unt','ite','gist','logisti','cav','ust','ove','contra','ontrac','son','pera','amer','ton','nic','distr','ber','qui','igh','int','nce','constr','corporat','pec','enter','corp','comp','struction','constructio','fre','construction','har','gre','anc','men','tal','cre','sta','vin','cou','pan','rta','towi','compa','compan','ise','scho','incor','choo','hea','par','cap','uni','ery','land','porta','ard','vir','farm','all','the','transportat','transportatio','erp','any','rise','ner','hol','transportation','indu','nta','ren','env','enterpris','ompany','company','distribu','envir','pro','uti','rol','aut','iti','tow','ame','bin','alle','art','ape','mec','eat','cto','cent','sal','supp','exp','spe','wes','her','cha','age','rie','eme','produ','sin','ret','ling','cia','capin','win','elec','edi','coo','ake','chan','tro','per','erg','wor','ics','man','der','sol','elect','cal','ant','roo','rag','sch','ctr','our','rms','xpress','arms','ind','condit','sys','ark','eld','mar','ven','farms','stem','syst','syste','mil','cho','out','electri','eli','logistic','lla','trib','expres','bro','contract','eric','ies','arri','express','tur','sout','nica','ari','liv','logistics','ins','ustr','ale','anic','eas','bul','cen','dist','cit','air','vat','este','tec','rec','managem','mechani','met','sup','ameri','che','are','wing','merica','for','imo','mon','rth','stora','equ','han','ron','ene','coa','ros','ria','equi','electric','lands','bui','inco','nor','war','les','quip','nde','gro','owi','ions','ore','ger','dsc','gin','mat','nort','soluti','solutio','internati','landscap','erc','city','mai','towin','oop','towing','lit','soc','era','rce','carri','foo','auto','hau','rea','asso','lim','lor','roth','other','schoo','den','ted','nat','ding','cava','rai','rother','brot','enterprise','tre','eck','avi','mic','eta','mun','ean','shi','gra','ble','resto','count','alt','ses','iona','nne','mas','operati','rod','lea','manuf','onc','ppl','hil','pla','oper','enviro','oto','vall','one','ert','coope','ail','cyc','west','nes','ral','woo','col','eel','prot','tar','ach','contracto','rate','enterprises','bri','prod','eve','wre','line','roc','was','hom','rts','cla','rid','mech','ord','stat','over','own','school','ndi','eal','but','tan','associat','hip','ring','ian','stor','suppl','hit','bra','can','eci','roup','commun','gree','las','ply','ctu','pai','tate','group','mbi','sig','gen','nation','she','ggi','nve','ping','scape','wel','mate','county','wer','cle','supply','distribut','bing','ves','plum','plumb','sion','unit','spec','oti','ali','system','associ','fin','llin','api','associa','flo'};
        return bad_terms.contains(s)==false;
    }
}