/* 
 * Test Class : QuoteSavePETests
 * Class Created: 07/14/21 - @author: Satya
 * ************************************************************************
 * 7/14/21 Satya - (GTMS-3187) Calculate Equipment bookings on AG product line level based on type of cable
 * 07/07/2022 Siddharth Kumar Mishra - (GTMS-6068) Optimising quoteSaveEventDispatch() by removing nested loop to decrease execution times
 * */
public class QuoteSavePEHelper {
    
    public static Map<Id, List<SBQQ__QuoteLine__c>> quoteLineOptions = new Map<Id, List<SBQQ__QuoteLine__c>>();
    public static List<SBQQ__QuoteLine__c> lstBundles = new List<SBQQ__QuoteLine__c>();
    public static List<String> prodCodes = new List<String>();
    
    public static void quoteSaveEventDispatch(List<Quote_Save__e> newQuoteEventList) {
        prodCodes = System.Label.Connected_Equipment_Product_Codes.split(',');
        //System.debug('********* quoteSaveEventDispatch *******');
        Set<Id> quoteIds = new Set<Id>();
        List<Opportunity> oppsToUpdate = new List<Opportunity>();
        List<SBQQ__QuoteLine__c> quoteLines = new List<SBQQ__QuoteLine__c>();
        
        for(Quote_Save__e qs : newQuoteEventList) {
            quoteIds.add(qs.Quote_Id__c);
        }

        //GTMS-6068
        List<SBQQ__QuoteLine__c> quoteLineList = [SELECT Id, Name, Total_Annual_Price__c, SBQQ__ProductCode__c, SBQQ__Product__r.Sub_Family__c, SBQQ__Quantity__c, 
                                                  SBQQ__Product__r.Product_Type__c, SBQQ__Product__r.ProductCode, SBQQ__RequiredBy__c, SBQQ__Quote__r.id, 
                                                  SBQQ__Quote__r.SBQQ__Opportunity2__c, SBQQ__Quote__r.SBQQ__LineItemCount__c
                                                  FROM SBQQ__QuoteLine__c where SBQQ__Quote__c IN :quoteIds];
        //GTMS-6068
        if(!quoteLineList.isEmpty())
        {
            lstBundles = new List<SBQQ__QuoteLine__c>();
            quoteLineOptions = new Map<Id, List<SBQQ__QuoteLine__c>>();
            //GTMS-6068
            for(SBQQ__QuoteLine__c ql:quoteLineList)
            {                
                if(ql.SBQQ__Product__r.Product_Type__c == 'Bundle') 
                {
                    lstBundles.add(ql);
                }
                else if(quoteLineOptions.containsKey(ql.SBQQ__RequiredBy__c)) 
                {
                    quoteLineOptions.get(ql.SBQQ__RequiredBy__c).add(ql);
                }
                else {
                    List<SBQQ__QuoteLine__c> qlLst = new List<SBQQ__QuoteLine__c>{ql};
                        quoteLineOptions.put(ql.SBQQ__RequiredBy__c, qlLst);
                }                
            }
            Double rollupAmount = 0;
            Map<Id,Double> oppEquipmentBookings = new Map<Id,Double>();
            //GTMS-6068
            for(SBQQ__QuoteLine__c line : lstBundles)
            {
                List<SBQQ__QuoteLine__c> lines = quoteLineOptions.get(line.Id);
                if(line.SBQQ__Product__r.Sub_Family__c == 'Connected Equipment') 
                {
                    Double bundleCommission = getBundleLicensePrice(lines);
                    System.debug('***** bundleCommission CE*******' + bundleCommission);
                    rollupAmount = rollupAmount == 0 ? bundleCommission : bundleCommission + rollupAmount;
                }
                else 
                {
                    Double bundleCommission = calculateCableBasedCommission(lines);
                    System.debug('***** bundleCommission Non CE*******' + bundleCommission);
                    rollupAmount = rollupAmount == 0 ? bundleCommission : bundleCommission + rollupAmount;
                }
                if(!oppEquipmentBookings.containsKey(line.SBQQ__Quote__r.SBQQ__Opportunity2__c))
                    oppEquipmentBookings.put(line.SBQQ__Quote__r.SBQQ__Opportunity2__c,rollupAmount);
                else 
                    oppEquipmentBookings.put(line.SBQQ__Quote__r.SBQQ__Opportunity2__c, oppEquipmentBookings.get(line.SBQQ__Quote__r.SBQQ__Opportunity2__c) + rollupAmount);
            }
            
            //GTMS-6068
            if(!oppEquipmentBookings.keySet().isEmpty())
            {
                for(id i : oppEquipmentBookings.keySet())
                    oppsToUpdate.add(new Opportunity(Id = i, Equipment_Bookings_ACV__c = oppEquipmentBookings.get(i)));

              Update oppsToUpdate;  
            }
        }
    }
    
    public static Double getBundleLicensePrice(List<SBQQ__QuoteLine__c> lines) {
        System.debug('**** getBundleLicensePrice ***** lines ******* ' + lines);
        Double amount  = 0;
        for(SBQQ__QuoteLine__c ln : lines) {
            if(ln.SBQQ__Product__r.Sub_Family__c != 'Connected Equipment') {
                amount = calculateCableBasedCommission(lines);
                break;
            }
            if(ln.SBQQ__Product__r.Product_Type__c == 'License'){
                amount += ln.Total_Annual_Price__c;
            }
        }
        return amount;
    }
    
    public static Double calculateCableBasedCommission(List<SBQQ__QuoteLine__c> lines) {
        System.debug('**** calculateCableBasedCommission ***** lines ******* ' + lines);
        Double amount  = 0;
        decimal cableCount = 0;
        decimal commissionCablesCount = 0;
        if (lines != null && lines.size() > 0) {
            for(SBQQ__QuoteLine__c ln : lines) {
                if(ln.SBQQ__Product__r.Product_Type__c == 'Cable') {
                    cableCount += ln.SBQQ__Quantity__c;
                }
                if(ln.SBQQ__Product__r.Product_Type__c == 'Cable' && prodCodes.contains(ln.SBQQ__Product__r.ProductCode)){
                    commissionCablesCount += ln.SBQQ__Quantity__c;
                }
                if(ln.SBQQ__Product__r.Product_Type__c == 'License') {
                    amount += ln.Total_Annual_Price__c;
                }
            }
        }
        system.debug('******* cableCount ******' + cableCount);
        system.debug('******* commissionCablesCount ******' + commissionCablesCount);
        system.debug('******* amount ******' + amount);
        
        if(amount != 0 && cableCount != 0 && commissionCablesCount != 0) {
            return amount*(commissionCablesCount/cableCount);
        }
        else
            return 0;
    }
}