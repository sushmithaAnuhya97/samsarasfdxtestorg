import { LightningElement, api, wire } from 'lwc';
import { NavigationMixin, CurrentPageReference } from 'lightning/navigation';
import { getRecord } from 'lightning/uiRecordApi';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import { getRelatedListRecords } from 'lightning/uiRelatedListApi';
import { refreshApex } from '@salesforce/apex';
import CUSTOMER_360_OBJECT from '@salesforce/schema/Customer_360__c';

// Child relationship on Customer_360__c.Account__c
const RELATED_LIST_ID = 'Customer_360__r';
// Optional: the app tab api name your “View All” uses
const VIEW_ALL_TAB_API = 'Customer360_Pricing';

const PRODUCT_PREFIX = 'LIC_';
const DISCOUNT_SUFFIX = '_Discount__c';
const MUP_SUFFIX = '_MUP__c';

const ROW_ACTIONS = [
  { label: 'View', name: 'view' }  
];

export default class AccountPreviousPricing extends NavigationMixin(LightningElement) {
  @api recordId;

  columns = [
    { label: 'Product', fieldName: 'product', type: 'text' },
    {
      label: 'Discount %',
      fieldName: 'discountPct',
      type: 'percent',
      typeAttributes: { maximumFractionDigits: 2 },
      cellAttributes: { alignment: 'center' }
    },
    {
      label: 'Monthly Unit Price',
      fieldName: 'mup',
      type: 'currency',
      cellAttributes: { alignment: 'center' }
    },
    { type: 'action', typeAttributes: { rowActions: ROW_ACTIONS }, initialWidth: 70 }
  ];

  get headerTitle() {    
    return `Customer 360 (${this.customer360Id ? 1 : 0})`;
  }

  isLoading = true;
  error;
  customer360Id;

  _relWire;
  _recWire;

  // Now keyed by cleaned label (group key), not API base
  fieldPairs = {};
  fieldsToFetch = [];
  qualifiedFields = [];
  rows = []; 

  // Support App Page: read recordId from URL state (e.g., View All navigation)
  @wire(CurrentPageReference)
  setRef(ref) {
    const rid = ref?.state?.c__recordId;
    if (rid && rid !== this.recordId) {
      this.recordId = rid;
      this.isLoading = true;
    }
  }

  connectedCallback() {
    if (!this.recordId) this.isLoading = false; // builder preview
  }

  // 1) Get latest Customer_360__c via relatedListId (no layout dependency)
  @wire(getRelatedListRecords, {
    parentRecordId: '$recordId',
    relatedListId: RELATED_LIST_ID,
    pageSize: 1,
    sortBy: ['LastModifiedDate'],
    sortOrder: 'DESC'
  })
  wiredRelated(value) {
    this._relWire = value;
    const { data, error } = value;
    if (error) { this.error = error; this.isLoading = false; return; }
    const first = data?.records?.[0];
    if (!first) { this.rows = []; this.customer360Id = undefined; this.isLoading = false; return; }
    this.customer360Id = first.id;
  }

  // Build a product label from the field's metadata label, stripping pricing qualifiers
  computeProductLabelFromFieldLabel(rawLabel) {
    if (!rawLabel) return null;

    let label = String(rawLabel).trim();

    // Remove a trailing "(...)" like "(%)" or "( % )"
    label = label.replace(/\s*\(\s*%?\s*\)\s*$/i, '');

    // Strip trailing pricing qualifier (with or without preceding hyphen/space/underscore)
    const stripOnce = s =>
      s.replace(/\s*[-–—_]*\s*(?:Discount|MUP|Monthly\s+Unit\s+Price|Unit\s+Price)\s*$/i, '');

    // Run twice to cover stacked qualifiers like "-MUP (%)"
    label = stripOnce(stripOnce(label));

    // Normalize hyphens and clean trailing delimiters
    label = label
      .replace(/\s*-\s*/g, '-')   // tighten spaces around hyphens
      .replace(/-{2,}/g, '-')     // collapse multiple hyphens
      .replace(/[-–—_\s]+$/g, '') // drop trailing hyphens/underscores/spaces
      .trim();

    return label || rawLabel;
  }

  // 2) Discover product fields dynamically
  @wire(getObjectInfo, { objectApiName: CUSTOMER_360_OBJECT })
  wiredInfo({ data, error }) {
    if (error) { this.error = error; this.isLoading = false; return; }
    if (!data) return;

    const fields = data.fields;

    // Group by cleaned label so Discount and MUP end up in the same row
    Object.keys(fields).forEach(api => {
      const isDiscount = api.startsWith(PRODUCT_PREFIX) && api.endsWith(DISCOUNT_SUFFIX);
      const isMup = api.startsWith(PRODUCT_PREFIX) && api.endsWith(MUP_SUFFIX);
      if (!isDiscount && !isMup) return;

      const fldMeta = fields[api];
      const rawLabel = fldMeta?.label;
      const cleanedLabel = this.computeProductLabelFromFieldLabel(rawLabel);

      // If we can't compute a usable label, fall back to API-derived key
      const apiBaseKey = api
        .slice(PRODUCT_PREFIX.length)
        .replace(DISCOUNT_SUFFIX, '')
        .replace(MUP_SUFFIX, '');

      // Use cleaned label (case-insensitive) as grouping key
      const groupKey = (cleanedLabel || apiBaseKey || api).toLowerCase();

      const pair = this.fieldPairs[groupKey] || {};
      if (!pair.label) {
        pair.label = cleanedLabel || apiBaseKey || rawLabel || api;
      }
      if (isDiscount) pair.discountField = api;
      if (isMup) pair.mupField = api;

      this.fieldPairs[groupKey] = pair;
    });

    this.fieldsToFetch = Object.values(this.fieldPairs)
      .flatMap(p => [p.discountField, p.mupField])
      .filter(Boolean);

    this.qualifiedFields = this.fieldsToFetch.map(api => `Customer_360__c.${api}`);
    if (!this.qualifiedFields.length) { this.rows = []; this.isLoading = false; }
  }

  // 3) Fetch values and build rows (one row per product)
  @wire(getRecord, { recordId: '$customer360Id', fields: '$qualifiedFields' })
  wiredRecord(value) {
    this._recWire = value;
    const { data, error } = value;
    if (error) { this.error = error; this.isLoading = false; return; }
    if (!data) return;

    const f = data.fields || {};
    this.rows = Object.values(this.fieldPairs)
      .map(p => {
        const d = p.discountField ? f[p.discountField]?.value : null;
        const m = p.mupField ? f[p.mupField]?.value : null;
        if (d == null && m == null) return null;
        return {
          id: `${this.customer360Id}_${p.label}`,
          recordId: this.customer360Id,
          product: p.label,
          discountPct: d == null ? null : d / 100,
          mup: m
        };
      })
      .filter(Boolean);

    this.isLoading = false;
  }

  // Header actions
  async handleRefresh() {
    this.isLoading = true;
    try {
      await Promise.all([
        this._relWire ? refreshApex(this._relWire) : 0,
        this._recWire ? refreshApex(this._recWire) : 0
      ]);
    } finally {
      this.isLoading = false;
    }
  }
  
  handleViewAll() {
    this[NavigationMixin.Navigate]({
      type: 'standard__navItemPage',
      attributes: { apiName: VIEW_ALL_TAB_API },
      state: { c__recordId: this.recordId, c__mode: 'full' }
    });
  }

  handleRowAction(event) {
    const recId = event.detail.row?.recordId;
    if (!recId) return;
    this[NavigationMixin.Navigate]({
      type: 'standard__recordPage',
      attributes: { recordId: recId, objectApiName: 'Customer_360__c', actionName: 'view' }
    });
  }
}