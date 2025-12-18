import { LightningElement, api, track } from "lwc";
import { NavigationMixin } from "lightning/navigation";
import { deepCopy } from "c/bringgUtils";
import getLookupService from "@salesforce/apex/LWCBringgMigrationActions.make";
// used for refresh record page data
// import { RefreshEvent } from 'lightning/refresh';
// usage: this.dispatchEvent(new RefreshEvent());

const SEARCH_DELAY = 300; // Wait 300 ms after user stops typing then, peform search

const KEY_ARROW_UP = 38;
const KEY_ARROW_DOWN = 40;
const KEY_ENTER = 13;

const VARIANT_LABEL_STACKED = "label-stacked";
const VARIANT_LABEL_INLINE = "label-inline";
const VARIANT_LABEL_HIDDEN = "label-hidden";

/*
	Info:
		offline records
		no records (if online)
		initialValue - null or not
		internal:
			_selectedRecord
			_records
			ignore event to parent if no _selected or search
*/

export default class BringgLookup extends NavigationMixin(LightningElement) {
  // Public properties
  @api variant = VARIANT_LABEL_STACKED;
  @api label = "";
  @api required = false;
  @api disabled = false;
  @api placeholder = "";
  @api scrollAfterNItems = null;
  @api newRecordOptions = [];
  @api minSearchTermLength = 2;
  @api useDefault = false;
  @api recordLimit = 50;

  @track hasRendered = false;
  @track uiInputRendered = true;
  @track isModalOpen = false;

  // new options
  @api fieldValueName = "Id";
  @api fieldLabelName = "label";
  @api iconName = "standard:account";
  @api modalLabel = "Select";
  @api objectType;
  @api filters;
  @api additionalFields; // TODO
  // TODO: move to @api
  // 	objectType: objectType,
  // 	search: search,
  // 	filters: ctrl.filters,
  // 	sort: ctrl.sort,
  // 	limit: ctrl.limit,
  // 	listColumns: ctrl.listColumns,
  // 	additionalFields: additionalFields,
  // 	nameField: ctrl.nameField,

  // offline records
  _isOfflineMode = false; // will be true if _offlineRecords is not empty
  _offlineRecords = [];
  // internal holders
  _value;
  _selectedRecord;
  _records = [];
  _columns = [];
  // modal data
  _modalSearch = "";

  // list-columns="['label', 'value']"
  // list-column-headers="{label: 'Label', value: 'Value'}"

  // Template properties
  searchResultsLocalState = [];
  loading = true;

  // Private properties
  _errors = [];
  _hasFocus = false;
  _isDirty = false;
  _searchTerm = "";
  _cleanSearchTerm;
  _cancelBlur = false;
  _searchThrottlingTimeout;
  _searchResults = [];
  _defaultSearchResults = [];

  _focusedResultIndex = null;

  // PUBLIC FUNCTIONS AND GETTERS/SETTERS
  @api
  set initial(initialValue) {
    if (initialValue && !this._value) {
      this._value = initialValue;
      this.setOfflineRecords();
      this.processSelection(false);
    } else {
      this._value = initialValue;
      this.processSelection(false);
    }
  }

  get initial() {
    return this._value;
  }

  @api
  set offlineRecords(records) {
    debugger;
    if (records) {
      this._offlineRecords = Array.isArray(records) ? records : [records];
      this.setOfflineRecords();
      this.processSelection(false);
      // this.loading = false;
    }
  }

  get offlineRecords() {
    return this._offlineRecords;
  }

  @api
  set columns(cols) {
    if (cols) {
      this._columns = Array.isArray(cols) ? cols : [cols];
      // this._columns.push(...colsLocal);
      // generate keyIdx
      // var idx = 1;
      // colsLocal.forEach(col => {
      // 	var newCol = deepCopy(col);
      // 	newCol.keyIdx = idx;
      // 	idx++;
      // 	this._columns.push(newCol);
      // });
    }
  }

  get columns() {
    return this._columns;
  }

  @api
  set errors(value) {
    this._errors = value;
    // Blur component if errors are passed
    if (this._errors?.length > 0) {
      this.blur();
    }
  }

  get errors() {
    return this._errors;
  }

  findParentRow(element) {
    if (element.tagName === "TR") return element;
    return this.findParentRow(element.parentElement);
  }

  renderedCallback() {
    if (this.hasRendered) {
      return;
    }
    this.getRecordName();
    // const table = this.template.querySelector('tbody');
    // table.addEventListener(
    // 	'click',
    // 	(e) => {
    // 		const parentRow = this.findParentRow(e.target);
    // 		if (parentRow && parentRow.getAttribute('data-key')) {
    // 			this.handleRowClick(parentRow.getAttribute('data-key'));
    // 		}
    // 	}
    // );
    this.hasRendered = true;
  }

  disconnectedCallback() {
    // window.removeEventListener('message', this.messageHandler);
  }

  @api
  setSearchResults(results) {
    // Clone results before modifying them to avoid Locker restriction
    let resultsLocal = JSON.parse(JSON.stringify(results));
  }

  @api
  setRecords(records) {
    // Reset the spinner
    // TODO
    // this.loading = false; // true
    // Clone results before modifying them to avoid Locker restriction
    let resultsLocal = JSON.parse(JSON.stringify(records));
    console.log(resultsLocal);
    this._records = [];
    this._records.push(...resultsLocal);
  }

  @api
  getSelectedRecord() {
    return this._selectedRecord;
  }

  hasSelectedRecord() {
    return this._selectedRecord != null;
  }

  @api
  setDefaultResults(results) {
    this._defaultSearchResults = [...results];
    if (this._searchResults.length === 0) {
      this.setSearchResults(this._defaultSearchResults);
    }
  }

  @api
  blur() {
    this.template.querySelector("input")?.blur();
  }

  // INTERNAL FUNCTIONS

  handleInputDebounced(event) {
    // Apply search throttling (prevents search if user is still typing)
    if (this._searchThrottlingTimeout) {
      clearTimeout(this._searchThrottlingTimeout);
    }
    this._searchTerm = event.target.value;
    // eslint-disable-next-line @lwc/lwc/no-async-operation
    this._searchThrottlingTimeout = setTimeout(() => {
      // Display spinner until results are returned
      this.handleReceiveRecords(this._searchTerm);
      // const searchEvent = new CustomEvent('search', {
      // 	detail: {
      // 		searchTerm: this._cleanSearchTerm,
      // 		rawSearchTerm: newSearchTerm,
      // 		selectedIds: this._curSelection.map((element) => element.id)
      // 	}
      // });
      // this.dispatchEvent(searchEvent);
      this._searchThrottlingTimeout = null;
    }, SEARCH_DELAY);
  }

  handleReceiveRecords(searchTerm) {
    this.loading = true;
    // if offline - use find (TODO: save old results?)
    // if not - use callout inside
    this.getRecords(searchTerm);
  }

  handleLoadInitialDataIfRequired() {
    // load data if required
    if (!this._isOfflineMode && !this.hasRecords) {
      this.handleReceiveRecords();
    } else {
      this.loading = false;
    }
  }

  handleModalInput(event) {
    this._modalSearch = event.target.value;
  }

  handleModalSearch(event) {
    this.handleReceiveRecords(this._modalSearch);
  }

  handleModalClear(event) {
    this._modalSearch = "";
    this.handleReceiveRecords(this._modalSearch);
  }

  getRecords(searchTerm) {
    if (this._isOfflineMode) {
      var filteredRecords = [];
      var recAddedCount = 1;
      this._offlineRecords.forEach((rec) => {
        var recCopy = deepCopy(rec);
        if (recAddedCount <= this.recordLimit) {
          if (!searchTerm || searchTerm == "") {
            filteredRecords.push(recCopy);
            recAddedCount++;
          } else {
            var alreadyAdded = false;
            this.columns.forEach((column) => {
              if (
                column &&
                column.value &&
                recCopy[column.value] &&
                recCopy[column.value]
                  .toLowerCase()
                  .indexOf(searchTerm.toLowerCase()) != -1
              ) {
                if (!alreadyAdded) {
                  filteredRecords.push(recCopy);
                  alreadyAdded = true;
                  recAddedCount++;
                }
              }
            });
          }
        }
      });
      // console.log('filteredRecords', filteredRecords);
      this.setRecords(filteredRecords);
      this.loading = false;
    } else {
      // collect list columns
      var localColumns = [];
      this.columns.forEach((column) => {
        if (column && column.value) {
          localColumns.push(column.value);
        }
      });
      // callout
      var dataParams = {
        objectType: this.objectType,
        filters: this.filters, // [{field:"fieldName", equalsTo:"value"}]
        search: searchTerm,
        sort: null, // {field: "fieldName", type: "ASC"}
        limit: parseInt(this.recordLimit),
        listColumns: localColumns,
        additionalFields: this.additionalFields
      };
      console.log("dataParams", JSON.parse(JSON.stringify(dataParams)));
      getLookupService({
        action: "getRecords",
        params: JSON.parse(JSON.stringify(dataParams))
      })
        .then((result) => {
          console.log("getRecords result", result);
          if (result && result.records) {
            this.setRecords(result.records);
          }
          this.loading = false;
        })
        .catch((error) => {
          console.log("getRecords error", error);
          this.loading = false;
        });
    }
  }

  getRecordName() {
    if (
      !this._isOfflineMode &&
      this.hasValue &&
      this.objectType &&
      this.columns &&
      !this._selectedRecord
    ) {
      var ids = [];
      ids.push(this._value);
      var localColumns = [];
      this.columns.forEach((column) => {
        if (column && column.value) {
          localColumns.push(column.value);
        }
      });
      var dataParams = {
        objectType: this.objectType,
        fields: localColumns,
        ids: ids
      };
      console.log("dataParams", JSON.parse(JSON.stringify(dataParams)));
      getLookupService({
        action: "getObjectsMap",
        params: JSON.parse(JSON.stringify(dataParams))
      })
        .then((result) => {
          console.log("getObjectsMap result", result);
          if (result && result.recordsMap) {
            this._selectedRecord = result.recordsMap[this._value];
            if (this._selectedRecord) {
              this.setRecords([this._selectedRecord]);
              this.processSelection(false);
            }
          }
        })
        .catch((error) => {
          console.log("getObjectsMap error", error);
          // this.loading = false;
        });
    }
  }

  isSelectionAllowed() {
    return !this.hasSelectedRecord();
  }

  hasSelection() {
    return false;
  }

  get hasValue() {
    return this._value;
  }

  get hasSelected() {
    return this.hasValue || this.hasSelectedRecord();
  }

  get hasRecords() {
    console.log("hasRecords", this._records?.length > 0);
    return this._records?.length > 0;
  }

  isOfflineMode() {
    return this._offlineRecords?.length > 0;
  }

  setOfflineRecords() {
    if (this._offlineRecords?.length > 0) {
      this.setRecords([...this._offlineRecords]);
      this._isOfflineMode = true;
    }
  }

  processSelection(isUserInteraction) {
    // Reset search
    this._cleanSearchTerm = "";
    this._searchTerm = "";
    // TODO: check value inside records
    // Indicate that component was interacted with
    this._isDirty = isUserInteraction;
    console.log("hasValue", this.hasValue);
    // Blur input after single select lookup selection
    if (this.hasRecords && !isUserInteraction) {
      if (this.hasValue) {
        this._records.forEach((rec) => {
          var val = rec[this.fieldValueName];
          if (val == this._value) {
            this._selectedRecord = rec;
          }
        });
      } else {
        if (this.useDefault) {
          this._selectedRecord = this._records[0];
        } else {
          this._selectedRecord = null;
        }
      }
    }
    this.uiInputRendered = !this.hasSelectedRecord();

    // If selection was changed by user, notify parent components
    if (isUserInteraction) {
      const val = this._selectedRecord
        ? this._selectedRecord[this.fieldValueName]
        : null;
      this.dispatchEvent(
        new CustomEvent("change", {
          detail: {
            value: val,
            fieldName: this.fieldValueName,
            record: this._selectedRecord
          }
        })
      );
    }
  }

  // EVENT HANDLING

  // handleInput(event) {
  // 	console.log('handleInput', event.target.value);
  // 	// Prevent action if selection is not allowed
  // 	if (!this.isSelectionAllowed()) {
  // 		console.log('handleInput return');
  // 		return;
  // 	}
  // 	this.updateSearchTerm(event.target.value);
  // }

  // handleKeyDown(event) {
  // 	console.log('handleKeyDown');
  // 	if (this._focusedResultIndex === null) {
  // 		this._focusedResultIndex = -1;
  // 	}
  // 	if (event.keyCode === KEY_ARROW_DOWN) {
  // 		// If we hit 'down', select the next item, or cycle over.
  // 		this._focusedResultIndex++;
  // 		if (this._focusedResultIndex >= this._searchResults.length) {
  // 			this._focusedResultIndex = 0;
  // 		}
  // 		event.preventDefault();
  // 	} else if (event.keyCode === KEY_ARROW_UP) {
  // 		// If we hit 'up', select the previous item, or cycle over.
  // 		this._focusedResultIndex--;
  // 		if (this._focusedResultIndex < 0) {
  // 			this._focusedResultIndex = this._searchResults.length - 1;
  // 		}
  // 		event.preventDefault();
  // 	} else if (event.keyCode === KEY_ENTER && this._hasFocus && this._focusedResultIndex >= 0) {
  // 		// If the user presses enter, and the box is open, and we have used arrows,
  // 		// treat this just like a click on the listbox item
  // 		const selectedId = this._searchResults[this._focusedResultIndex].id;
  // 		this.template.querySelector(`[data-recordid="${selectedId}"]`).click();
  // 		event.preventDefault();
  // 	}
  // }

  // handleRowClick(recordKey) {
  // 	console.log('handleRowClick', recordKey);
  // 	if (recordKey !== null && this.hasRecords) {
  // 		const selectedRecord = this._records.find((result) => result.Id === recordKey);
  // 		if (!selectedRecord) {
  // 			return;
  // 		}
  // 		this._selectedRecord = selectedRecord;
  // 		this._value = selectedRecord ? this._selectedRecord[this.fieldValueName]: null;
  // 		this.processSelection(true);
  // 	}
  // }

  handleLineClick(event) {
    const recordKey = event.currentTarget.dataset.key;
    console.log("handleLineClick", recordKey);
    if (recordKey !== null && recordKey !== undefined && this.hasRecords) {
      const selectedRecord = this._records.find(
        (result) => result.Id === recordKey
      );
      if (!selectedRecord) {
        return;
      }
      this._selectedRecord = selectedRecord;
      this._value = this._selectedRecord
        ? this._selectedRecord[this.fieldValueName]
        : null;
      this.processSelection(true);
      this._hasFocus = false;
      // close modal
      if (this.isModalOpen) {
        this.handleCloseModal();
      }
    }
  }

  handleComboboxMouseDown(event) {
    const mainButton = 0;
    if (event.button === mainButton) {
      this._cancelBlur = true;
    }
  }

  handleComboboxMouseUp() {
    this._cancelBlur = false;
    // Re-focus to text input for the next blur event
    this.template.querySelector("input").focus();
  }

  handleFocus() {
    console.log("handleFocus", this._isOfflineMode);
    // Prevent action if selection is not allowed
    if (!this.isSelectionAllowed()) {
      console.log("handleFocus return");
      return;
    }
    this._hasFocus = true;
    this._focusedResultIndex = null;
    this.handleLoadInitialDataIfRequired();
  }

  handleBlur() {
    console.log("handleBlur");
    // Prevent action if selection is either not allowed or cancelled
    if (!this.isSelectionAllowed() || this._cancelBlur) {
      console.log("handleBlur return");
      return;
    }
    this._hasFocus = false;
  }

  handleOpenModal() {
    console.log("handleOpenModal");
    this.isModalOpen = true;
    setTimeout(() => {
      this.handleLoadInitialDataIfRequired();
      this.template.querySelector(".modalSearch").focus();
    });
  }

  handleCloseModal() {
    console.log("handleOpenModal");
    this.isModalOpen = false;
    this._modalSearch = "";
  }

  handleClearSelection() {
    console.log("handleClearSelection");
    this._value = null;
    this._selectedRecord = null;
    this._hasFocus = false;
    this.getRecords(null);

    // Process selection update
    this.processSelection(true);
  }

  handleNewRecordClick(event) {
    const objectApiName = event.currentTarget.dataset.sobject;
    const selection = this.newRecordOptions.find(
      (option) => option.value === objectApiName
    );

    const preNavigateCallback = selection.preNavigateCallback
      ? selection.preNavigateCallback
      : () => Promise.resolve();
    preNavigateCallback(selection).then(() => {
      this[NavigationMixin.Navigate]({
        type: "standard__objectPage",
        attributes: {
          objectApiName,
          actionName: "new"
        },
        state: {
          defaultFieldValues: selection.defaults
        }
      });
    });
  }

  // STYLE EXPRESSIONS

  get isListboxOpen() {
    const isSearchTermValid =
      this._cleanSearchTerm &&
      this._cleanSearchTerm.length >= this.minSearchTermLength;
    // return (
    // 	this._hasFocus &&
    // 	this.isSelectionAllowed() &&
    // 	(isSearchTermValid || this.hasRecords || this.newRecordOptions?.length > 0)
    // );
    return this._hasFocus && this.isSelectionAllowed();
  }

  get getFormElementClass() {
    return this.variant === VARIANT_LABEL_INLINE
      ? "slds-form-element slds-form-element_horizontal"
      : "slds-form-element";
  }

  get getLabelClass() {
    return this.variant === VARIANT_LABEL_HIDDEN
      ? "slds-form-element__label slds-assistive-text"
      : "slds-form-element__label";
  }

  get getContainerClass() {
    let css = "slds-combobox_container ";
    if (this._errors.length > 0) {
      css += "has-custom-error";
    }
    return css;
  }

  get getDropdownClass() {
    let css =
      "slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click ";
    if (this.isListboxOpen) {
      css += "slds-is-open";
    }
    return css;
  }

  get getComboboxClass() {
    let css =
      "slds-combobox__form-element slds-input-has-icon slds-input-has-icon_right";
    // css += this.hasValue() ? 'slds-input-has-icon_left-right' : 'slds-input-has-icon_right';
    return css;
  }

  get getInputClass() {
    let css = "slds-input slds-combobox__input has-custom-height ";
    if (this._hasFocus && this.hasRecords) {
      css += "slds-has-focus ";
    }
    if (
      this._errors.length > 0 ||
      (this._isDirty && this.required && !this.hasValue)
    ) {
      css += "has-custom-error ";
    }

    css +=
      "slds-combobox__input-value " +
      (this.hasValue ? "has-custom-border" : "");
    return css;
  }

  get getSearchIconClass() {
    let css = "slds-input__icon slds-input__icon_right ";
    css += this.hasValue ? "slds-hide" : "";
    return css;
  }

  get getSelectIconClass() {
    return (
      "slds-combobox__input-entity-icon " + (this.hasValue ? "" : "slds-hide")
    );
  }

  get getLookupValue() {
    if (this.hasSelectedRecord()) {
      return this._selectedRecord[this.fieldLabelName];
    } else {
      if (this._searchTerm) {
        return this._searchTerm;
      }
      return "";
    }
  }

  get getListboxClass() {
    return (
      "slds-dropdown " +
      (this.scrollAfterNItems
        ? `slds-dropdown_length-with-icon-${this.scrollAfterNItems} `
        : "") +
      "slds-dropdown_fluid" // + ' lookup-field__dropdown'
    );
  }

  get getDropdownRecordsClass() {
    return "slds-dropdown slds-dropdown--left slds-p-vertical--none lookup-field__dropdown";
  }

  // get getDropdownStyle() {

  // }

  get isInputReadonly() {
    return this.hasValue;
  }
}