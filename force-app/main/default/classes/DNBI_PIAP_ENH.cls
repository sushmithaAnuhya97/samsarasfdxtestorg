public class DNBI_PIAP_ENH{
	public class SummarizedPastDue {
		public Double DaysLowQuantity;
		public OpenFilingsAmount MonthlyAveragePastDueTotalAmount;
	}

	public class PaymentPeriodSummary {
		public String SummaryPeriod;
		public PaymentsWithHighCredit PaymentsWithHighCredit;
	}

	public class StreetAddressLine {
		public String LineText;
	}

	public class SatisfactoryPayments {
		public Double ExperienceCount;
	}

	public class Product {
		public String DNBProductID;
		public Double LanguageCode;
		public Organization Organization;
	}

	public class FamilyTreeMemberRoleText {
		public Double DNBCodeValue;
		public String Dollars;
	}

	public class OrganizationDetail {
		public List<FamilyTreeMemberRole> FamilyTreeMemberRole;
		public FamilyTreeMemberRoleText OperatingStatusText;
	}

	public class TelephoneNumber {
		public String TelecommunicationNumber;
		public Double InternationalDialingCode;
	}

	public class OrderProductResponseDetail {
		public InquiryDetail InquiryDetail;
		public Product Product;
		public InquiryReferenceDetail InquiryReferenceDetail;
	}

	public class OrderProductResponse {
		public String ServiceVersionNumber;
		public TransactionDetail TransactionDetail;
		public TransactionResult TransactionResult;
		public OrderProductResponseDetail OrderProductResponseDetail;
	}

	public class SubjectHeader {
		public String DUNSNumber;
	}

	public class DNBStandardRating {
		public String DNBStandardRating;
	}

	public class HighCreditMaximumAmount {
		public String CurrencyISOAlpha3Code;
		public Double Dollars;
	}

	public class FinancialStatementFilingSummary {
		public Double TotalFilingCount;
	}

	public class TransactionResult {
		public String SeverityText;
		public String ResultID;
		public String ResultText;
	}

	public class SummarizedPastDue_Z {
		public Double DaysLowQuantity;
		public Double DaysHighQuantity;
		public Double ExperiencesCount;
		public OpenFilingsAmount TotalAmount;
	}

	public class PurchaserDerivedData {
		public OrganizationName TradeDataYearMonth;
		public ThreeMonthsDataCoveragePayments ThreeMonthsDataCoveragePayments;
		public TwelveMonthsDataCoveragePayments TwelveMonthsDataCoveragePayments;
		public TwentyFourMonthsDataCoveragePayments TwentyFourMonthsDataCoveragePayments;
		public OneMonthDataCoveragePayments OneMonthDataCoveragePayments;
	}

	public class TwentyFourMonthsDataCoveragePayments {
		public List<PaymentPeriodSummary_Y> PaymentPeriodSummary;
		public Double CurrentAccountsCount;
		public OpenFilingsAmount CurrentTotalAmount;
		public Double SlowExperienceCount;
		public Double SlowNegativeExperienceCount;
		public List<SummarizedPastDue_Z> SummarizedPastDue;
	}

	public class LienInformation {
		public SuitSummary LienSummary;
	}

	public class TwelveMonthsDataCoveragePayments {
		public List<PaymentPeriodSummary_Z> PaymentPeriodSummary;
		public Double PastDueExperiencesCount;
		public List<SummarizedPastDue> SummarizedPastDue;
	}

	public class PaydexScoreIndustryNorms {
		public OrganizationName CalculationDate;
		public Double PaydexMedianQuartileScore;
		public String PaymentBehaviourText;
		public Integer PaymentBehaviourDaysQuantity;
	}

	public class SummarizedSlow {
		public Double DaysLowQuantity;
		public Double DaysHighQuantity;
		public Double SlowPercentage;
	}

	public class FamilyTreeMemberRole {
		public FamilyTreeMemberRoleText FamilyTreeMemberRoleText;
	}

	public class OrganizationName_Z {
		public List<OrganizationPrimaryName> OrganizationPrimaryName;
	}

	public class OrganizationName {
		public String Dollars;
	}

	public class PrimaryAddress {
		public List<StreetAddressLine> StreetAddressLine;
		public String PrimaryTownName;
		public String CountryISOAlpha2Code;
		public String TerritoryAbbreviatedName;
		public String PostalCode;
		public String TerritoryOfficialName;
	}

	public class SuitInformation {
		public List<SuitSummary> SuitSummary;
	}

	public class Organization {
		public SubjectHeader SubjectHeader;
		public Telecommunication Telecommunication;
		public Location Location;
		public Events Events;
		public OrganizationName_Z OrganizationName;
		public OrganizationDetail OrganizationDetail;
		public Assessment Assessment;
		public BusinessTrading BusinessTrading;
	}

	public OrderProductResponse OrderProductResponse;

	public class PaymentPeriodSummary_X {
		public String SummaryPeriod;
		public PaymentsWithHighCredit_X PaymentsWithHighCredit;
	}

	public class PaymentPeriodSummary_Y {
		public String SummaryPeriod;
		public PaymentsWithHighCredit_Y PaymentsWithHighCredit;
		public SatisfactoryPayments SatisfactoryPayments;
	}

	public class BusinessTrading {
		public Purchaser Purchaser;
		public PaydexScoreNorms PaydexScoreNorms;
	}

	public class PaymentPeriodSummary_Z {
		public String SummaryPeriod;
		public PaymentsWithHighCredit_Z PaymentsWithHighCredit;
	}

	public class Assessment {
		public DNBStandardRating DNBStandardRating;
		public FamilyTreeMemberRoleText HistoryRatingText;
		public FamilyTreeMemberRoleText FinancialConditionText;
	}

	public class FinancingStatementFilingInformation {
		public FinancialStatementFilingSummary FinancialStatementFilingSummary;
	}

	public class InquiryReferenceDetail {
		public List<String> CustomerReferenceText;
		public String CustomerBillingEndorsementText;
	}

	public class FinancingEvents {
		public Boolean SecuredFilingsIndicator;
		public FinancingStatementFilingInformation FinancingStatementFilingInformation;
	}

	public class ThreeMonthsDataCoveragePayments {
		public List<PaymentPeriodSummary> PaymentPeriodSummary;
		public Double AccountsCount;
		public Double PastDueExperiencesCount;
		public OpenFilingsAmount MonthlyAveragePastDueTotalAmount;
		public List<SummarizedPastDue> SummarizedPastDue;
	}

	public class OneMonthDataCoveragePayments {
		public OpenFilingsAmount OwedTotalMaximumAmount;
		public OpenFilingsAmount PastDueTotalMaximumAmount;
		public List<PaymentPeriodSummary_X> PaymentPeriodSummary;
		public Double SuppliersCount;
		public Double AccountsCount;
		public OpenFilingsAmount OwedTotalAmount;
		public Double CurrentAccountsCount;
		public OpenFilingsAmount CurrentTotalAmount;
		public List<SummarizedPastDue_Z> SummarizedPastDue;
	}

	public class LegalEvents {
		public Boolean SuitsIndicator;
		public Boolean LiensIndicator;
		public Boolean JudgmentIndicator;
		public SuitInformation SuitInformation;
		public LienInformation LienInformation;
		public JudgmentInformation JudgmentInformation;
		public Boolean ClaimsIndicator;
	}

	public class Events {
		public LegalEvents LegalEvents;
		public FinancingEvents FinancingEvents;
	}

	public class PaymentsWithHighCredit_Z {
		public OpenFilingsAmount HighCreditTotalAmount;
		public OpenFilingsAmount HighCreditMaximumAmount;
		public OpenFilingsAmount AverageHighCreditAmount;
	}

	public class PaymentsWithHighCredit_Y {
		public Double ExperienceCount;
		public HighCreditMaximumAmount HighCreditMaximumAmount;
		public OpenFilingsAmount AverageHighCreditAmount;
		public Double SlowExperienceCount;
		public List<SummarizedSlow_Z> SummarizedSlow;
		public Double PastDueTotalCount;
		public Double SlowNegativeExperienceCount;
		public OpenFilingsAmount PastDueTotalAmount;
	}

	public class PaymentsWithHighCredit_X {
		public OpenFilingsAmount HighCreditTotalAmount;
	}

	public class Purchaser {
		public CurrentPaydexScore CurrentPaydexScore;
		public PaydexScoreHistory PaydexScoreHistory;
		public List<PurchaserDerivedData> PurchaserDerivedData;
	}

	public class TransactionDetail {
		public String ApplicationTransactionID;
		public String ServiceTransactionID;
		public String TransactionTimestamp;
	}

	public class PaydexScoreHistory {
		public List<TwentyFourMonthsPaydex_Z> TwentyFourMonthsPaydex;
	}

	public class SummarizedSlow_Z {
		public Double DaysLowQuantity;
		public Double DaysHighQuantity;
		public Double SlowExperienceCount;
	}

	public class Telecommunication {
		public TelephoneNumber TelephoneNumber;
	}

	public class PaymentsWithHighCredit {
		public List<SummarizedSlow> SummarizedSlow;
	}

	public class OrganizationPrimaryName {
		public OrganizationName OrganizationName;
	}

	public class JudgmentInformation {
		public SuitSummary JudgmentSummary;
	}

	public class CurrentPaydexScore {
		public List<TwentyFourMonthsPaydex> TwentyFourMonthsPaydex;
	}

	public class OneMonthDataCoveragePayments_Y {
		public OpenFilingsAmount OwedTotalMaximumAmount;
		public OpenFilingsAmount PastDueTotalMaximumAmount;
		public List<PaymentPeriodSummary_Z> PaymentPeriodSummary;
		public Double SuppliersCount;
		public Double AccountsCount;
		public OpenFilingsAmount OwedTotalAmount;
		public Double CurrentAccountsCount;
		public OpenFilingsAmount CurrentTotalAmount;
	}

	public class OneMonthDataCoveragePayments_Z {
		public OpenFilingsAmount OwedTotalMaximumAmount;
		public OpenFilingsAmount PastDueTotalMaximumAmount;
		public List<PaymentPeriodSummary_Z> PaymentPeriodSummary;
		public Double SuppliersCount;
		public Double AccountsCount;
		public OpenFilingsAmount OwedTotalAmount;
		public Double CurrentAccountsCount;
		public OpenFilingsAmount CurrentTotalAmount;
		public List<SummarizedPastDue_Z> SummarizedPastDue;
	}

	public class InquiryDetail {
		public String DUNSNumber;
		public String CountryISOAlpha2Code;
	}

	public class SuitSummary {
		public Double OpenFilingsCount;
		public OpenFilingsAmount OpenFilingsAmount;
	}

	public class TwentyFourMonthsPaydex {
		public Integer PaydexScore;
		public OrganizationName PaydexDate;
		public String PaymentBehaviorText;
		public Integer PaymentBehaviorDaysQuantity;
		public Double TotalPaymentExperiencesUsedCount;
	}

	public class PaydexScoreNorms {
		public List<PaydexScoreIndustryNorms> PaydexScoreIndustryNorms;
	}

	public class OpenFilingsAmount {
		public Integer Dollars;
	}

	public class TwentyFourMonthsPaydex_Z {
		public Integer PaydexScore;
		public OrganizationName PaydexDate;
	}

	public class Location {
		public PrimaryAddress PrimaryAddress;
	}

	
	public static DNBI_PIAP_ENH parse(String json) {
		return (DNBI_PIAP_ENH) System.JSON.deserialize(json, DNBI_PIAP_ENH.class);
	}
}