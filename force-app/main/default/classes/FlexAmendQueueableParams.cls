/*******************************************************************************************************************
 * @Test class: 
 * Date      	- Project#        - Developer/ Company      	   - Description
 * ------------------------------------------------------------------------------------------------------------------
 * 01/26/2025    - Flex C&R       - Anas Siddiquee/ Accenture 	   - Parameters for FlexAmendQueueable
 *											
 */
public class FlexAmendQueueableParams {
    public List<String> contractIdList;
    public Date startDate;
    public String replacementQuoteId;
    public String replacementOppId;
    public Integer currentIndex;
    public Set<Id> queueableJobIdSet;
    public List<Flex_Log__c> logRecordList;
    public Boolean isRebook;
    public Boolean originalAccountFlag;
    public Integer retryCount;
    public Boolean quoteRecalcStarted;

    private FlexAmendQueueableParams(Builder builder) {
        this.contractIdList = builder.contractIdList;
        this.startDate = builder.startDate;
        this.replacementQuoteId = builder.replacementQuoteId;
        this.replacementOppId = builder.replacementOppId;
        this.currentIndex = builder.currentIndex;
        this.queueableJobIdSet = builder.queueableJobIdSet;
        this.logRecordList = builder.logRecordList;
        this.isRebook = builder.isRebook;
        this.originalAccountFlag = builder.originalAccountFlag;
        this.retryCount = builder.retryCount;
        this.quoteRecalcStarted = builder.quoteRecalcStarted;
    }

    public FlexAmendQueueableParams next() {
        return new Builder()
            .withContractIdList(this.contractIdList)
            .withStartDate(this.startDate)
            .withReplacementQuoteId(this.replacementQuoteId)
            .withReplacementOppId(this.replacementOppId)
            .withCurrentIndex(this.currentIndex + 1)
            .withQueueableJobIdSet(this.queueableJobIdSet)
            .withLogRecordList(this.logRecordList)
            .withIsRebook(this.isRebook)
            .withOriginalAccountFlag(this.originalAccountFlag)
            .withRetryCount(this.retryCount)
            .withQuoteRecalcStarted(this.quoteRecalcStarted)
            .build();
    }

    public class Builder {
        private List<String> contractIdList;
        private Date startDate;
        private String replacementQuoteId;
        private String replacementOppId;
        private Integer currentIndex = 0;
        private Set<Id> queueableJobIdSet = new Set<Id>();
        private List<Flex_Log__c> logRecordList = new List<Flex_Log__c>();
        private Boolean isRebook;
        private Boolean originalAccountFlag;
        private Integer retryCount = 0;
        private Boolean quoteRecalcStarted;

        public Builder withContractIdList(List<String> contractIdList) {
            this.contractIdList = contractIdList;
            return this;
        }

        public Builder withStartDate(Date startDate) {
            this.startDate = startDate;
            return this;
        }

        public Builder withReplacementQuoteId(String replacementQuoteId) {
            this.replacementQuoteId = replacementQuoteId;
            return this;
        }

        public Builder withReplacementOppId(String replacementOppId) {
            this.replacementOppId = replacementOppId;
            return this;
        }

        public Builder withCurrentIndex(Integer currentIndex) {
            this.currentIndex = currentIndex;
            return this;
        }

        public Builder withQueueableJobIdSet(Set<Id> queueableJobIdSet) {
            this.queueableJobIdSet = queueableJobIdSet;
            return this;
        }

        public Builder withLogRecordList(List<Flex_Log__c> logRecordList) {
            this.logRecordList = logRecordList;
            return this;
        }

        public Builder withIsRebook(Boolean isRebook) {
            this.isRebook = isRebook;
            return this;
        }

        public Builder withOriginalAccountFlag(Boolean originalAccountFlag) {
            this.originalAccountFlag = originalAccountFlag;
            return this;
        }

        public Builder withRetryCount(Integer retryCount) {
            this.retryCount = retryCount;
            return this;
        }

        public Builder withQuoteRecalcStarted(Boolean quoteRecalcStarted) {
            this.quoteRecalcStarted = quoteRecalcStarted;
            return this;
        }

        public FlexAmendQueueableParams build() {
            return new FlexAmendQueueableParams(this);
        }
    }
}