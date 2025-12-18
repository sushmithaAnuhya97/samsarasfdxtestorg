public class DNBI_VIAB_RAT{
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

	public class DataDepthDetail {
		public String DataDepthIndicator;
		public List<String> AssessmentText;
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
		public DNBViabilityRating DNBViabilityRating;
	}

	public class OrganizationSizeDetail {
		public String OrganizationSizeCategoryText;
		public List<String> AssessmentText;
	}

	public class Product {
		public String DNBProductID;
		public Organization Organization;
		public ArchiveDetail ArchiveDetail;
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

	public class OrderProductResponse {
		public String ServiceVersionNumber;
		public TransactionDetail TransactionDetail;
		public TransactionResult TransactionResult;
		public OrderProductResponseDetail OrderProductResponseDetail;
	}

	public class SubjectHeader {
		public String DUNSNumber;
	}

	public class ViabilityScore {
		public Double ClassScore;
		public FamilyTreeMemberRoleText RiskLevelDescription;
		public Double BadRate;
		public Double ClassScoreIncidencePercentage;
		public Double OverallBadRate;
	}

	public class TransactionDetail {
		public String ServiceTransactionID;
		public String TransactionTimestamp;
	}

	public class YearsInBusinessDetail {
		public String YearsInBusinessCategoryText;
		public List<String> AssessmentText;
	}

	public class DNBViabilityRating {
		public String DNBViabilityRating;
		public ViabilityScore ViabilityScore;
		public PortfolioComparisonScore PortfolioComparisonScore;
		public DataDepthDetail DataDepthDetail;
		public OrganizationProfileDetail OrganizationProfileDetail;
	}

	public class TransactionResult {
		public String SeverityText;
		public String ResultID;
		public String ResultText;
	}

	public class PortfolioComparisonScore {
		public Double ClassScore;
		public FamilyTreeMemberRoleText RiskLevelDescription;
		public Double BadRate;
		public Double ClassScoreIncidencePercentage;
		public FamilyTreeMemberRoleText ModelSegmentDescription;
		public Double SegmentBadRate;
	}

	public class Telecommunication {
		public List<TelephoneNumber> TelephoneNumber;
	}

	public class OrganizationPrimaryName {
		public OrganizationName OrganizationName;
	}

	public class ArchiveDetail {
		public Double PortfolioAssetID;
	}

	public class TradeDataAvailabilityDetail {
		public Boolean TradeDataAvailableIndicator;
		public List<String> AssessmentText;
	}

	public class InquiryDetail {
		public String DUNSNumber;
		public String CountryISOAlpha2Code;
	}

	public class FamilyTreeMemberRole {
		public FamilyTreeMemberRoleText FamilyTreeMemberRoleText;
	}

	public class OrganizationName_Z {
		public List<OrganizationPrimaryName> OrganizationPrimaryName;
	}

	public class Location {
		public List<PrimaryAddress> PrimaryAddress;
	}

	public class OrganizationProfileDetail {
		public String OrganizationProfileRating;
		public Boolean FinancialDataAvailableIndicator;
		public TradeDataAvailabilityDetail TradeDataAvailabilityDetail;
		public OrganizationSizeDetail OrganizationSizeDetail;
		public YearsInBusinessDetail YearsInBusinessDetail;
	}

	
	public static DNBI_VIAB_RAT parse(String json) {
		return (DNBI_VIAB_RAT) System.JSON.deserialize(json, DNBI_VIAB_RAT.class);
	}
}