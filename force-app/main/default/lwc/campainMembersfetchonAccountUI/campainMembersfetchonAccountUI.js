import { LightningElement, api, track, wire } from 'lwc';
import { getRelatedListRecords } from 'lightning/uiRelatedListApi';
import { NavigationMixin, CurrentPageReference } from 'lightning/navigation';
import { deleteRecord } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

const RELATED_LIST_ID = 'Campaign_Members__r';
const DISPLAY_LIMIT = 10;
const TAB_API_NAME = 'Campaign_Engagement';

const ROW_ACTIONS = [
  { label: 'Edit', name: 'edit' },
  { label: 'Delete', name: 'delete' }
];

const FIELDS = [
  'CampaignMember.Id',
  'CampaignMember.Name',
  'CampaignMember.ContactId',
  'CampaignMember.Campaign_Name__c',
  'CampaignMember.Campaign_Type__c',
  'CampaignMember.Status',
  'CampaignMember.Campaign_Interaction_Date__c',
  'CampaignMember.Master_Campaign_Name__c',
  'CampaignMember.CreatedDate'
];

export default class CampaignEngagement extends NavigationMixin(LightningElement) {
  // reactive recordId setter so we can reload when it changes
  _recordId;
  @api
  get recordId() { return this._recordId; }
  set recordId(v) {
    if (v && v !== this._recordId) {
      this._recordId = v;
      this.loadAll();
    }
  }

  @track rows = [];
  @track isLoading = false;
  @track selectedRowIds = [];

  isFullPage = false;
  totalCount = 0;

  // pagination drivers
  pageToken;              // reactive param for @wire
  _accumulating = false;  // are we fetching pages?
  _all = [];              // accumulated raw records (UI API payload mapped)

  columns = [
    { label: 'Campaign Name', fieldName: 'campaignName' },
    { label: 'Name', fieldName: 'contactUrl', type: 'url', typeAttributes: { label: { fieldName: 'name' } } },
    { label: 'Campaign Type', fieldName: 'campaignType' },
    { label: 'Status', fieldName: 'status' },
    { label: 'Campaign Interaction Date', fieldName: 'interactionDate', type: 'date' },
    { type: 'action', typeAttributes: { rowActions: ROW_ACTIONS }, initialWidth: 60 }
  ];

  get headerTitle() {
    const countLabel = this.isFullPage
      ? `${this.totalCount}`
      : (this.totalCount > DISPLAY_LIMIT ? `${DISPLAY_LIMIT}+` : `${this.totalCount}`);
    return `Campaign Engagement (${countLabel})`;
  }

  @wire(CurrentPageReference)
  setPageRef(pageRef) {
    const rid = pageRef?.state?.c__recordId;
    if (rid && rid !== this._recordId) this.recordId = rid;
    this.isFullPage = pageRef?.state?.c__mode === 'full';
  }

  // Wire adapter with reactive pageToken so we can paginate
  @wire(getRelatedListRecords, {
    parentRecordId: '$_recordId',
    relatedListId: RELATED_LIST_ID,
    fields: FIELDS,
    pageSize: 200,
    pageToken: '$pageToken'
  })
  wiredRelatedList({ data, error }) {
    if (!this._accumulating) return; // only handle during loadAll()

    if (error) {
      this._accumulating = false;
      this.isLoading = false;
      this.rows = [];
      this.totalCount = 0;
      // You could surface a toast if desired
      return;
    }

    if (data) {
      // map page
      const page = (data.records || []).map(r => {
        const f = r.fields;
        return {
          id: r.id,
          name: f.Name?.value || '',
          campaignName: f.Campaign_Name__c?.value || '',
          campaignType: f.Campaign_Type__c?.value || '',
          status: f.Status?.value || '',
          interactionDate: f.Campaign_Interaction_Date__c?.value || f.CreatedDate?.value,
          masterName: f.Master_Campaign_Name__c?.value || '',
          contactUrl: f.ContactId?.value ? `/lightning/r/Contact/${f.ContactId.value}/view` : null
        };
      });
      this._all = this._all.concat(page);

      // keep paging until no next token
      if (data.nextPageToken) {
        this.pageToken = data.nextPageToken; // triggers the next @wire call
        return;
      }

      // finalize when no more pages
      this._accumulating = false;
      const filteredSorted = this._all
        .filter(r => r.masterName !== '(Master) Operational') // exact match like SOQL
        .sort((a, b) => new Date(b.interactionDate || 0) - new Date(a.interactionDate || 0));

      this.totalCount = filteredSorted.length;
      this.rows = this.isFullPage ? filteredSorted : filteredSorted.slice(0, DISPLAY_LIMIT);
      this.isLoading = false;
    }
  }

  // starts a fresh full fetch
  async loadAll() {
    if (!this._recordId) return;
    this.isLoading = true;
    this._all = [];
    this.rows = [];
    this.totalCount = 0;
    this._accumulating = true;
    this.pageToken = undefined; // first page
  }

  async handleRefresh() {
    await this.loadAll();
  }

  handleRowSelection(event) {
    this.selectedRowIds = (event.detail.selectedRows || []).map(r => r.id);
  }

  handleRowAction(event) {
    const action = event.detail.action?.name;
    const row = event.detail.row;
    if (!action || !row?.id) return;

    if (action === 'edit') {
      this[NavigationMixin.Navigate]({
        type: 'standard__recordPage',
        attributes: { recordId: row.id, objectApiName: 'CampaignMember', actionName: 'edit' }
      });
    } else if (action === 'delete') {
      this.deleteRow(row.id);
    }
  }

  async deleteRow(recordId) {
    try {
      await deleteRecord(recordId);
      this.dispatchEvent(new ShowToastEvent({ title: 'Deleted', message: 'Campaign Member deleted', variant: 'success' }));
      await this.loadAll();
    } catch (e) {
      this.dispatchEvent(new ShowToastEvent({ title: 'Delete failed', message: e?.body?.message || e.message, variant: 'error' }));
    }
  }

  handleViewAll() {
    this[NavigationMixin.Navigate]({
      type: 'standard__navItemPage',
      attributes: { apiName: TAB_API_NAME },
      state: { c__recordId: this._recordId, c__mode: 'full' }
    });
  }

  scrollLeft() {
    const scroller = this.template.querySelector('.rl-table');
    if (scroller) scroller.scrollBy({ left: -300, behavior: 'smooth' });
  }
  scrollRight() {
    const scroller = this.template.querySelector('.rl-table');
    if (scroller) scroller.scrollBy({ left: 300, behavior: 'smooth' });
  }
}