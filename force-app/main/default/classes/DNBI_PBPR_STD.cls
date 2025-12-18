public class DNBI_PBPR_STD{
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

	public class ScoreCommentary {
		public FamilyTreeMemberRoleText CommentaryText;
	}

	public class Organization {
		public SubjectHeader SubjectHeader;
		public Telecommunication Telecommunication;
		public Location Location;
		public OrganizationName_Z OrganizationName;
		public OrganizationDetail OrganizationDetail;
		public Assessment Assessment;
	}

	public OrderProductResponse OrderProductResponse;

	public class StreetAddressLine {
		public String LineText;
	}

	public class Assessment {
		public List<CommercialCreditScore> CommercialCreditScore;
		public List<CommercialCreditScoreNorms> CommercialCreditScoreNorms;
		public List<FinancialStressScore> FinancialStressScore;
		public DNBCreditLimitRecommendation DNBCreditLimitRecommendation;
		public List<SupplierEvaluationRiskScore> SupplierEvaluationRiskScore;
		public List<String> AssessmentSummaryText;
	}

	public class Product {
		public String DNBProductID;
		public Organization Organization;
	}

	public class FamilyTreeMemberRoleText {
		public Double DNBCodeValue;
		public String Dollars;
	}

	public class OrganizationDetail {
		public List<FamilyTreeMemberRole> FamilyTreeMemberRole;
	}

	public class TelephoneNumber {
		public String TelecommunicationNumber;
		public String InternationalDialingCode;
	}

	public class OrderProductResponseDetail {
		public InquiryDetail InquiryDetail;
		public Product Product;
	}

	public class CommercialCreditScoreNorms {
		public List<RiskIncidencePercentageIndustryNorm> RiskIncidencePercentageIndustryNorm;
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

	public class TransactionDetail {
		public String ServiceTransactionID;
		public String TransactionTimestamp;
	}

	public class TransactionResult {
		public String SeverityText;
		public String ResultID;
		public String ResultText;
	}

	public class MaximumRecommendedLimitAmount {
		public String CurrencyISOAlpha3Code;
		public String UnitOfSize;
		public Integer Dollars;
	}

	public class SupplierEvaluationRiskScore {
		public String RiskScore;
		public List<ScoreCommentary> ScoreCommentary;
	}

	public class DNBCreditLimitRecommendation {
		public MaximumRecommendedLimitAmount MaximumRecommendedLimitAmount;
	}

	public class Telecommunication {
		public List<TelephoneNumber> TelephoneNumber;
	}

	public class CommercialCreditScore {
		public Double RawScore;
		public String ClassScore;
		public Integer NationalPercentile;
		public Double RiskIncidencePercentage;
		public List<ScoreCommentary> ScoreCommentary;
		public OrganizationName ScoreDate;
		public String RiskIncidenceMinimumRangeRawScore;
		public String RiskIncidenceMaximumRangeRawScore;
	}

	public class OrganizationPrimaryName {
		public OrganizationName OrganizationName;
	}

	public class InquiryDetail {
		public String DUNSNumber;
		public String CountryISOAlpha2Code;
	}

	public class FinancialStressScore {
		public Double RawScore;
		public String ClassScore;
		public Integer NationalPercentile;
		public Double RiskIncidencePercentage;
		public List<ScoreCommentary> ScoreCommentary;
		public OrganizationName ScoreDate;
	}

	public class FamilyTreeMemberRole {
		public FamilyTreeMemberRoleText FamilyTreeMemberRoleText;
	}

	public class OrganizationName_Z {
		public List<OrganizationPrimaryName> OrganizationPrimaryName;
	}

	public class RiskIncidencePercentageIndustryNorm {
		public Double MedianValue;
	}

	public class Location {
		public List<PrimaryAddress> PrimaryAddress;
	}

	
	public static DNBI_PBPR_STD parse(String json) {
		return (DNBI_PBPR_STD) System.JSON.deserialize(json, DNBI_PBPR_STD.class);
	}
}