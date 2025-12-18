import { LightningElement, track } from 'lwc';
import fetchApprovals from '@salesforce/apex/ItemsToApproveQuoteService.fetchApprovals';

const PAGE_SIZE = 20;
const AGE_SLA_DAYS = 3; // retained for internal decoration if needed; UI toggle removed

export default class ItemsToApproveQuote extends LightningElement {
  // reactive vars ---------------------------------------------------------
  @track records = [];
  @track totalRecords = 0;
  @track pageNumber = 1;
  @track totalPages = 1;
  @track searchKey = '';
  @track isLoading = false;
  @track ageFilterActive = false; // toggle removed from UI; left for potential future use

  // sort state ------------------------------------------------------------
  sortedBy = 'CreatedDate';
  sortedDirection = 'DESC';
  sortOption = 'dateDesc';
  get sortOptions() {
    return [
      { label: 'Date Submitted (newest first)', value: 'dateDesc' },
      { label: 'Date Submitted (oldest first)', value: 'dateAsc' },
      { label: 'Rule Name', value: 'rule' },
      { label: 'Stage', value: 'stage' },
      { label: 'Customer ARR (high to low)', value: 'arrDesc' },
    ];
  }

  // datatable column configuration ---------------------------------------
  columns = [
    {
      label: 'Action',
      type: 'url',
      fieldName: 'actionLink',
      typeAttributes: {
        label: 'Approve / Reject',
        target: '_blank',
      },
      sortable: false,
      initialWidth: 140,
    },
    { label: 'Quote', fieldName: 'relatedTo', type: 'text', sortable: true, initialWidth: 140 },
    {
      label: 'Approval #',
      fieldName: 'approvalLink',
      type: 'url',
      typeAttributes: { label: { fieldName: 'approvalName' }, target: '_blank' },
      sortable: true,
      initialWidth: 120,
    },
    { label: 'Approval Rule Name', fieldName: 'approvalRuleName', type: 'text', sortable: true, initialWidth: 200 },
    { label: 'Account Name', fieldName: 'accountName', type: 'text', sortable: true, initialWidth: 180 },
    {
      label: 'Opportunity Link',
      fieldName: 'opportunityLink',
      type: 'url',
      typeAttributes: { label: { fieldName: 'opportunityName' }, target: '_blank' },
      sortable: true,
      initialWidth: 200,
    },
    { label: 'Stage', fieldName: 'opportunityStage', type: 'text', sortable: true, initialWidth: 120 },
    { label: 'Close Date', fieldName: 'opportunityCloseDate', type: 'date', sortable: true, initialWidth: 140 },
    {
      label: 'Customer ARR ($)',
      fieldName: 'accountCustomerARR',
      type: 'currency',
      typeAttributes: { currencyCode: 'USD' },
      sortable: true,
      initialWidth: 120,
    },
    { label: 'Reason for Discount', fieldName: 'reasonForDiscount', type: 'text', sortable: false, wrapText: true, initialWidth: 420 },
    { label: 'Blended Discount (%)', fieldName: 'blendedDiscount', type: 'number', sortable: true, initialWidth: 180 },
    { label: 'License Term', fieldName: 'licenseTerm', type: 'text', sortable: true, initialWidth: 140 },
    { label: 'Sales Rep', fieldName: 'salesRep', type: 'text', sortable: true, initialWidth: 160 },
    { label: 'Most Recent Approver', fieldName: 'mostRecentApprover', type: 'text', sortable: true, initialWidth: 200 },
    { label: 'Date Submitted', fieldName: 'dateSubmitted', type: 'text', sortable: true, initialWidth: 160 },
  ];

  connectedCallback() {
    // restore preferences if needed later
    this.fetchData();
  }

  handleSortOptionChange(event) {
    this.sortOption = event.detail.value;
    switch (this.sortOption) {
      case 'dateDesc':
        this.sortedBy = 'CreatedDate';
        this.sortedDirection = 'DESC';
        break;
      case 'dateAsc':
        this.sortedBy = 'CreatedDate';
        this.sortedDirection = 'ASC';
        break;
      case 'rule':
        this.sortedBy = 'sbaa__Rule__r.Name';
        this.sortedDirection = 'ASC';
        break;
      case 'stage':
        this.sortedBy = 'Quote__r.SBQQ__Opportunity2__r.StageName';
        this.sortedDirection = 'ASC';
        break;
      case 'arrDesc':
        this.sortedBy = 'Quote__r.SBQQ__Account__r.Customer_ARR_Netsuite__c';
        this.sortedDirection = 'DESC';
        break;
      default:
        this.sortedBy = 'CreatedDate';
        this.sortedDirection = 'DESC';
    }
    this.pageNumber = 1;
    this.fetchData();
  }

  // aging filter UI removed; keep method in case wired elsewhere
  toggleAgeFilter = () => {
    this.ageFilterActive = !this.ageFilterActive;
    this.decorateRows();
  };

  // ---------------------------------------------------------------------
  //  Data Fetching
  // ---------------------------------------------------------------------
  fetchData() {
    this.isLoading = true;
    fetchApprovals({
      pageSize: PAGE_SIZE,
      pageNumber: this.pageNumber,
      sortBy: this.sortedBy,
      sortDirection: this.sortedDirection,
      searchKey: this.searchKey,
    })
      .then((result) => {
        this.totalRecords = result.totalRecords;
        this.totalPages = Math.ceil(this.totalRecords / PAGE_SIZE) || 1;

        // enrich records for custom layout
        this.records = (result.items || []).map((rec) => {
          return {
            ...rec,
            approveLink: `/apex/sbaa__Approve?id=${rec.processId}`,
            rejectLink: `/apex/sbaa__Reject?id=${rec.processId}`,
            approvalLink: `/${rec.recordId}`,
            quoteLink: rec.quoteId ? `/${rec.quoteId}` : null,
            opportunityLink: rec.opportunityId ? `/${rec.opportunityId}` : null,
            accountLink: rec.accountId ? `/${rec.accountId}` : null,
          };
        });

        this.decorateRows();
      })
      .catch((error) => {
        // eslint-disable-next-line no-console
        console.error('Error fetching approvals', error);
      })
      .finally(() => {
        this.isLoading = false;
      });
  }

  decorateRows() {
    const now = new Date().getTime();
    const dayMs = 24 * 60 * 60 * 1000;
    this.records = this.records
      .filter((r) => {
        if (!this.ageFilterActive) return true;
        if (!r.createdDate) return true;
        const ageDays = (now - new Date(r.createdDate).getTime()) / dayMs;
        return ageDays > AGE_SLA_DAYS;
      })
      .map((r) => {
        const ageDays = r.createdDate ? Math.floor((now - new Date(r.createdDate).getTime()) / dayMs) : null;
        const isAging = ageDays !== null && ageDays > AGE_SLA_DAYS;
        const discountClass = r.blendedDiscount < 0 ? 'slds-text-color_error' : '';
        let stageClass = 'slds-badge';
        const stageLower = (r.opportunityStage || '').toLowerCase();
        if (stageLower.includes('won')) stageClass = 'slds-badge slds-theme_success';
        else if (stageLower.includes('lost')) stageClass = 'slds-badge slds-theme_error';
        return {
          ...r,
          ageBadge: ageDays !== null ? `${ageDays}d` : null,
          ageBadgeClass: isAging ? 'slds-theme_error slds-m-left_x-small' : 'slds-theme_success slds-m-left_x-small',
          discountClass,
          stageClass,
        };
      });
  }

  // Approve/Reject actions (open pages in new tab)
  handleApprove(event) {
    const pid = event.currentTarget.dataset.id;
    window.open(`/apex/sbaa__Approve?id=${pid}`, '_blank');
  }
  handleReject(event) {
    const pid = event.currentTarget.dataset.id;
    window.open(`/apex/sbaa__Reject?id=${pid}`, '_blank');
  }

  // ---------------------------------------------------------------------
  //  Pagination helpers
  // ---------------------------------------------------------------------
  get disablePrevious() {
    return this.pageNumber <= 1;
  }

  get disableNext() {
    return this.pageNumber >= this.totalPages;
  }

  // Derived states that also respect loading
  get isPrevDisabled() {
    return this.isLoading || this.disablePrevious;
  }

  get isNextDisabled() {
    return this.isLoading || this.disableNext;
  }

  // Counts and ranges for footer
  get recordsOnPage() {
    return Array.isArray(this.records) ? this.records.length : 0;
  }
  get pageStart() {
    if (this.totalRecords === 0) return 0;
    return (this.pageNumber - 1) * PAGE_SIZE + 1;
    }
  get pageEnd() {
    return Math.min(this.pageNumber * PAGE_SIZE, this.totalRecords);
  }

  previousPage() {
    if (this.pageNumber > 1) {
      this.pageNumber--;
      this.fetchData();
      // reset scroll position to top of scroll container and page
      requestAnimationFrame(() => {
        const scroller = this.template.querySelector('.scroll-body');
        if (scroller) scroller.scrollTop = 0;
        window.scrollTo({ top: 0, behavior: 'auto' });
      });
    }
  }

  nextPage() {
    if (this.pageNumber < this.totalPages) {
      this.pageNumber++;
      this.fetchData();
      // reset scroll position to top of scroll container and page
      requestAnimationFrame(() => {
        const scroller = this.template.querySelector('.scroll-body');
        if (scroller) scroller.scrollTop = 0;
        window.scrollTo({ top: 0, behavior: 'auto' });
      });
    }
  }

  // ---------------------------------------------------------------------
  //  Search / Filter
  // ---------------------------------------------------------------------
  handleSearchInputChange(event) {
    this.searchKey = event.target.value;
  }

  handleSearchKeyPress(event) {
    if (event.keyCode === 13) {
      // Enter key pressed
      this.performSearch();
    }
  }

  handleSearchClick() {
    this.performSearch();
  }

  performSearch() {
    this.pageNumber = 1; // reset to first page
    this.fetchData();
  }
}