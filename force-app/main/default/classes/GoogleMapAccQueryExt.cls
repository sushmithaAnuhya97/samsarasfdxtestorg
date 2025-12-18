//GTMS-4274 The ‘Nearby References’ map on the Account to show values
global class GoogleMapAccQueryExt {
    public static List<Account> accResults { get; set; }

    public GoogleMapAccQueryExt(ApexPages.StandardController stdController) { }
    
    webservice static List<Account> getAccounts(String query) {
        accResults = Database.query(query + ' LIMIT 2000');
        return accResults;
    }
}