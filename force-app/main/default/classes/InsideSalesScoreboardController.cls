public class InsideSalesScoreboardController {
    
    public class InsideSalesScoreboardTeam{
        public String name {get;set;}
        public Map<Date, Decimal>weekSales {get;set;} //Date => amount
        public Map<Date, Boolean>weekWins {get;set;} //Date => true/false
        public Decimal total {get; set;}
        public List<TopAccount> TopAccounts {get;set;}
        public Integer TotalCQDeals {get; set;}
        public Boolean mostAccounts {get;set;} 
        
        public InsideSalesScoreboardTeam(String name,Decimal total) {
            this.name = name; 
            this.weekSales = new Map<Date, Decimal>();
            this.weekWins = new Map<Date,Boolean>();
            for (Date d : InsideSalesScoreboardController.CQWeeks) {
                this.weekSales.put(d, 0);
                this.weekWins.put(d, false);
            }
            this.total = total;
            this.TopAccounts = new List<TopAccount>();
            this.TotalCQDeals=0;     
            this.mostAccounts = false; 
        }
    }
    
    public class TopAccount {
        public String name {get;set;}
        public String rep {get; set;}
        public Decimal amount {get;set;}
        public String place {get; set;}
        
        public TopAccount (String name, String rep, Decimal amt, String place) {
            this.name = name;
            this.rep = rep;
            this.amount = amt;
            this.place = place;
        }
    }
    
    public Map<String, InsideSalesScoreboardTeam> TeamsLookup;
    public List<InsideSalesScoreboardTeam> InsideSalesScoreboardTeams {
        get {return TeamsLookup.values();}
    }   
    public Integer NumTeams {
        get {return TeamsLookup.keySet().size();}
    }

    public Integer sellingDaysLeft { get {
        return Integer.valueOf([SELECT BusDays_To_EOQ__c FROM Opportunity LIMIT 1].BusDays_To_EOQ__c);       
    }}
    public Date currentDate {get;set;}
        
    /**************************************
     * RESET SCOREBOARD TO NEW QUARTER HERE
     **************************************
    */
    private final String ScoreboardDateRangeCriteria = 'closeDate = THIS_FISCAL_QUARTER';                 //**SWAP THIS FOR THE NEXT LINE AFTER THE 4MONTH QUARTER
    private static final DateTime ScoreboardStartDate = DateTime.newInstance(2017,2,01);
    //private static final String StartDateQueryFormatted = InsideSalesScoreboardController.ScoreboardStartDate.year() + '-' + InsideSalesScoreboardController.ScoreboardStartDate.month() + '-' + InsideSalesScoreboardController.ScoreboardStartDate.day();
    private static final DateTime ScoreboardEndDate = DateTime.newInstance(2017,04,31);
    //private static final String EndDateQueryFormatted = InsideSalesScoreboardController.ScoreboardEndDate.year() + '-' + InsideSalesScoreboardController.ScoreboardEndDate.month() + '-' + InsideSalesScoreboardController.ScoreboardEndDate.day();
   //private final String ScoreboardDateRangeCriteria = 'closeDate >= ' + InsideSalesScoreboardController.ScoreboardStartDate.format('YYYY-MM-dd') + ' and closeDate <= ' + InsideSalesScoreboardController.ScoreboardEndDate.format('YYYY-MM-dd');
    
    public String CQName {get {return 'Q4';}}
    public List<Date> CQWeeks {get {return InsideSalesScoreboardController.CQWeeks;}}
    private static final List<Date> CQWeeks = new List<Date>{Date.newInstance(2017, 2, 6), //Sorted list of Monday-aligned "week start dates" that should head each column (corresponds to Opportunity.CloseDate_WeekStart__c)
                                                            Date.newInstance(2017, 2, 13),
                                                            Date.newInstance(2017, 2, 20),
                                                            Date.newInstance(2017, 2, 27),
                                                            Date.newInstance(2017, 3, 6),
                                                            Date.newInstance(2017, 3, 13),
                                                            Date.newInstance(2017, 3, 20),
                                                            Date.newInstance(2017, 3, 27),
                                                            Date.newInstance(2017, 4, 3),
                                                            Date.newInstance(2017, 4, 10),
                                                            Date.newInstance(2017, 4, 17),
                                                            Date.newInstance(2017, 4, 24)};
                                                                       
    public Boolean TodayIsBeforeStart{get {
        if (Date.today() < InsideSalesScoreboardController.ScoreboardStartDate)
            return true;
        else
            return false;
    }}
    
    public Boolean TodayIsAfterEnd{get {
        if (Date.today() > InsideSalesScoreboardController.ScoreboardEndDate)
            return true;
        else
            return false;        
    }}
                                                                   
    private String parseTeamNameFromDivision(String div) {
        //REMOVE THIS IF BLOCK IF NO COURTNEY TEAM
        if (div == 'ISD - West') {
            return 'West';
            //return 'West Ex. Court';
        }
        else if (div == 'ISD - East') {
            return 'East';
        }
        /////////////////////////////////////////////
        
        //Assumes division takes the form 'ISD - West' and parses out 'West'
        return div.right(div.length()-div.indexOf('-')-2);
    }
    
    public InsideSalesScoreboardController(Date curDate) {               
        this.currentDate = curDate; //Needed to support testing not just for "today()";
        
        /***************
         * MAIN SCOREBOARD INNINGS
         * *************
        */
        
        TeamsLookup = new Map<String, InsideSalesScoreboardTeam>(); // 'East' => team, 'West' => team, etc.
        AggregateResult[] groupedResults;
        String query='';
        
        //Get Teams and Quarter totals for the teams
        query = 'SELECT owner.manager.division, count(Id) amt ' +
                        'FROM Account where ' +
                        'First_Demo_Date__c = THIS_FISCAL_QUARTER AND ' +
                        //'WHERE RecordType.Name != \'Trial\' and probability >= 99 and ' +
                        //'owner.name != \'Courtney McGowan\' and ' + //REMOVE THIS LINE TO REMOVE COURTNEY TEAM
                        //this.ScoreboardDateRangeCriteria + ' and ' + 
                        'owner.manager.Division like \'%ISD%\' ' +
                        'GROUP BY owner.manager.division';
        
        groupedResults = Database.query(query);
        System.debug(query);
        for (AggregateResult ar : groupedResults) {
            TeamsLookup.put(parseTeamNameFromDivision((String)(ar.get('division'))), 
                            new InsideSalesScoreboardTeam(parseTeamNameFromDivision((String)(ar.get('division'))),
                                                          (Integer)(ar.get('amt'))));
        }
        
        /*
         * GET COURTNEY TEAM
         * 
        
        query = 'SELECT owner.manager.division, sum(amount) amt ' +
                        'FROM opportunity ' +
                        'WHERE RecordType.Name != \'Trial\' and probability >= 99 and ' +
                        'owner.name = \'Courtney McGowan\' and ' + 
                        this.ScoreboardDateRangeCriteria + ' and ' + 
                        'owner.manager.Division like \'%ISD%\' ' +
                        'GROUP BY owner.manager.division';
        
        groupedResults = Database.query(query);
        for (AggregateResult ar : groupedResults) {
            TeamsLookup.put('Courtney', 
                            new InsideSalesScoreboardTeam('Courtney',
                                                          (Decimal)(ar.get('amt'))));
        }
        
        */
        //Fill in by-week sales data for the teams
        query = 'SELECT owner.manager.division, FirstDemoDate_WeekStart__c, count(Id) amt ' +
                            'FROM Account Where ' +
                            'First_Demo_Date__c = THIS_FISCAL_QUARTER AND ' +
                            //'WHERE RecordType.Name != \'Trial\' and probability >= 99 and ' +
                            //'owner.name != \'Courtney McGowan\' and ' + //REMOVE THIS LINE TO REMOVE COURTNEY TEAM
                            //this.ScoreboardDateRangeCriteria + ' and ' + 
                            'owner.manager.Division like \'%ISD%\' ' +
                            'GROUP BY owner.manager.division, FirstDemoDate_WeekStart__c';
            
        groupedResults = Database.query(query);
        System.debug(groupedResults);
        for (AggregateResult ar : groupedResults) {
            InsideSalesScoreBoardTeam t = TeamsLookup.get(parseTeamNameFromDivision((String)(ar.get('division'))));
            t.weekSales.put((Date)(ar.get('FirstDemoDate_WeekStart__c')),((Integer)(ar.get('amt')))); //Assert: CloseDate_WeekStart__c values should all be in the set of CQWeeks List because we're pulling opptys from dates this quarter and CQWeeks enumerates all possible Mondays for closedwon opptys this q.
        }
        
        /*
        //Fill in by-week sales data for COURTNEY
        query = 'SELECT owner.manager.division, CloseDate_WeekStart__c, sum(amount) amt ' +
                            'FROM opportunity ' +
                            'WHERE RecordType.Name != \'Trial\' and probability >= 99 and ' +
                            //'owner.name = \'Courtney McGowan\' and ' + //REMOVE THIS LINE TO REMOVE COURTNEY TEAM
                            this.ScoreboardDateRangeCriteria + ' and ' + 
                            'owner.manager.Division like \'%ISD%\' ' +
                            'GROUP BY owner.manager.division, CloseDate_WeekStart__c';
            
        groupedResults = Database.query(query);
        for (AggregateResult ar : groupedResults) {
            InsideSalesScoreBoardTeam t = TeamsLookup.get('Courtney');
            t.weekSales.put((Date)(ar.get('CloseDate_WeekStart__c')),((Decimal)(ar.get('amt')))); //Assert: CloseDate_WeekStart__c values should all be in the set of CQWeeks List because we're pulling opptys from dates this quarter and CQWeeks enumerates all possible Mondays for closedwon opptys this q.
        }        
        */
        
        
        //Set monthly winners for past months
        if (!this.TodayIsBeforeStart) {
                
            for (Integer x=0; x<InsideSalesScoreboardController.CQWeeks.size()-2; x++) { //Skip last item; we'll cover it with special clause at end of loop
                Date curWeekStart = InsideSalesScoreboardController.CQWeeks[x];
                Date nextWeekStart = InsideSalesScoreboardController.CQWeeks[x+1];
                if (Date.today() >= nextWeekStart) {
                    //if we've started the week after this one, we can calc winner of this one
                    InsideSalesScoreboardTeam winner = null;
                    Decimal winningAmount = 0; //NEED TO DEAL WITH TIES -- MOST LIKELY IS 0-0. NEED TO NOT SHOW A WINNER SOMEHOW.
                    for (InsideSalesScoreboardTeam t : TeamsLookup.values()) {
                        //Check each team and record it as the winner if it's >= the existing winner
                        if (t.weekSales.get(curWeekStart) > winningAmount) {
                            winner = t;
                            winningAmount = t.weekSales.get(curWeekStart);
                        }
                    }
                    //Now we know who won this month, so set the month win flag
                    if (winner != null) //If everyone was zero so there was no winner, don't try to set one
                        winner.weekWins.put(curWeekStart, true);                    
                }
            }
            if (this.TodayIsAfterEnd) {//Verify we can calculate the winner of the last week as well
                Date finalWeekStart = InsideSalesScoreboardController.CQWeeks[InsideSalesScoreboardController.CQWeeks.size()-1];
                InsideSalesScoreboardTeam winner = null; 
                Decimal winningAmount = 0; //NEED TO DEAL WITH TIES -- UNLIKELY SINCE LAST WEEK OF CQ
                for (InsideSalesScoreboardTeam t : TeamsLookup.values()) {
                    //Check each team and record it as the winner if it's >= the existing winner
                    if (t.weekSales.get(finalWeekStart) >= winningAmount) {
                        winner = t;
                        winningAmount = t.weekSales.get(finalWeekStart);
                    }
                }
                //Now we know who won this month, so set the month win flag
                try{
                    winner.weekWins.put(finalWeekStart,true); 
                }
                 catch (System.NullPointerException e) {

                    System.debug('error');
        
                }
            }
        }
        
        
        /***************
         * SECONDARY SCOREBOARD LEADERBOARDS
         * *************
        
        
        List<String> places = new List<String>{'1','2','3','4','5'};
        
        //populate top 5 deals for each division
        for (String team : (Set<String>)(TeamsLookup.keySet())) { 
            Integer i=0;
            if (team != 'Courtney') {           
                
                //REMOVE IF REMOVING COURTNEY TEAM
                String sTeam;                         
                if (team == 'East')
                    sTeam = 'ISD - East';
                else
                    sTeam = 'ISD - West';
                //////////////////////////////////
                //
                //get top 5 for this division that we're populating
                query = 'SELECT owner.name isr, owner.manager.division div,  account.name acct, sum(amount) amt ' +
                    'FROM Opportunity ' +
                    'WHERE RecordType.Name != \'Trial\' and probability >= 99 and ' +
                    this.ScoreboardDateRangeCriteria + ' and ' + 
                    'owner.manager.Division like \'%' + sTeam + '%\' and ' + //CHANGE THIS LINE TO [if removing COURTNEY =TEAM]   'owner.manager.Division like \'%' + team + '%\' and ' +
                    'owner.name != \'Courtney McGowan\' and ' + //REMOVE THIS LINE TO REMOVE COURTNEY TEAM                
                    'owner.manager.Division like \'%ISD%\' ' +
                    'GROUP BY account.name,owner.name,owner.manager.division ' +
                    'ORDER BY sum(amount) DESC LIMIT 5';
                groupedResults = Database.query(query);
                
                for (AggregateResult ar : groupedResults) {
                    ((InsideSalesScoreboardTeam)(this.TeamsLookup.get(team))).TopAccounts.add(new TopAccount(               
                                                                                 prettyAccountName((String)(ar.get('acct'))),
                                                                                 (String)(ar.get('isr')),
                                                                                 (Decimal)(ar.get('amt')),
                                                                                 places[i++]));             
                }
            } else {
                //get top 5 for COURTNEY division
                query = 'SELECT owner.name isr, owner.manager.division div,  account.name acct, sum(amount) amt ' +
                    'FROM Opportunity ' +
                    'WHERE RecordType.Name != \'Trial\' and probability >= 99 and ' +
                    this.ScoreboardDateRangeCriteria + ' and ' + 
                    'owner.name = \'Courtney McGowan\' and ' + //REMOVE THIS LINE TO REMOVE COURTNEY TEAM                
                    'owner.manager.Division like \'%ISD%\' ' +
                    'GROUP BY account.name,owner.name,owner.manager.division ' +
                    'ORDER BY sum(amount) DESC LIMIT 5';
                groupedResults = Database.query(query);
                
                for (AggregateResult ar : groupedResults) {
                    ((InsideSalesScoreboardTeam)(this.TeamsLookup.get(team))).TopAccounts.add(new TopAccount(               
                                                                                 prettyAccountName((String)(ar.get('acct'))),
                                                                                 (String)(ar.get('isr')),
                                                                                 (Decimal)(ar.get('amt')),
                                                                                 places[i++]));             
                }                
            }
            
        }

        //Get total deals for each team and set a flag on the team with the most     
        query = 'SELECT owner.manager.division, COUNT_DISTINCT(account.name) NumDeals ' +
            'FROM Opportunity ' +
            'WHERE RecordType.Name != \'Trial\' and probability >= 99 and ' +
            this.ScoreboardDateRangeCriteria + ' and ' + 
            'owner.name != \'Courtney McGowan\' and ' + //REMOVE THIS LINE TO REMOVE COURTNEY TEAM   
            'owner.manager.Division like \'%ISD%\' ' +
            'GROUP BY owner.manager.division';
        groupedResults = Database.query(query);
        
        Integer winningDeals=0;
        InsideSalesScoreboardTeam winningTeam=null;
        
        for (AggregateResult ar : groupedResults) {
            InsideSalesScoreboardTeam team = (InsideSalesScoreboardTeam)(this.TeamsLookup.get(parseTeamNameFromDivision((String)(ar.get('division')))));
            team.TotalCQDeals = (Integer)(ar.get('NumDeals'));              
            if (team.TotalCQDeals >= winningDeals) {
                if (winningTeam == null) {
                    winningTeam = team;
                    winningDeals = team.TotalCQDeals;
                }
                else { //tie
                    winningTeam = null; //unset a winner because there's a tie, and increment winningDeals count so we can't find another tying entry and mark it won
                    winningDeals= team.TotalCQDeals+1;                
                }
            }
        }
        if (winningTeam != null) {
            winningTeam.MostAccounts = true;
        }


        //SET COURTNEY TOTAL DEALS
        //Get total deals for each team and set a flag on the team with the most     
        query = 'SELECT owner.manager.division, COUNT_DISTINCT(account.name) NumDeals ' +
            'FROM Opportunity ' +
            'WHERE RecordType.Name != \'Trial\' and probability >= 99 and ' +
            this.ScoreboardDateRangeCriteria + ' and ' + 
            'owner.name = \'Courtney McGowan\' and ' + //REMOVE THIS LINE TO REMOVE COURTNEY TEAM   
            'owner.manager.Division like \'%ISD%\' ' +
            'GROUP BY owner.manager.division';
        groupedResults = Database.query(query);
        
        for (AggregateResult ar : groupedResults) {
            InsideSalesScoreboardTeam team = (InsideSalesScoreboardTeam)(this.TeamsLookup.get('Courtney'));     
            team.TotalCQDeals = (Integer)(ar.get('NumDeals'));
        }
        */ 
    }
    
    private String prettyAccountName(String acctName) {
        Integer NAME_CHAR_LIMIT=15;
        if (acctName.length()<=NAME_CHAR_LIMIT)
            return acctName;
        else
            return acctName.left(NAME_CHAR_LIMIT-3) + '...';                    
    }
    
    public InsideSalesScoreboardController() {
        this(date.today());
    }
}