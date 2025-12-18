/*
 * Description:- This batch job is used to Amend Contract
 * 10/24/2022 - Rajesh  GTMS-9570 
 * 
 * 
 */
public class QuoteModel {
    public SBQQ__Quote__c record;
    public QuoteLineModel[] lineItems;
    public QuoteLineGroupModel[] lineItemGroups;
    public Integer nextKey;
    public Boolean applyAdditionalDiscountLast;
    public Boolean applyPartnerDiscountFirst;
    public Boolean channelDiscountsOffList;
    public Decimal customerTotal;
    public Decimal netTotal;
    public Decimal netNonSegmentTotal;
}