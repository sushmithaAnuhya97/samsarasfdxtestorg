import { LightningElement, track, api } from 'lwc';

export default class MultiSelectPicklist extends LightningElement {

    // API Variables
    @api label = 'Search Options';
    @api options = [];
    @api value = [];
    @api disabled = false;
    @api required = false;
    @api selectionlimit = 10;
    
    // Setter for value to re-initialize when value changes
    set value(newValue) {
        this._value = newValue;
        if (this.options && this.options.length > 0) {
            this.initializeSelectedItems();
        }
    }
    
    get value() {
        return this._value;
    }

    // Track Variables
    @track allValues = []; // this will store end result or selected values from picklist
    @track selectedItems = []; // this will store selected items
    @track selectedObject = false;
    @track valuesVal = undefined;
    @track searchTerm = '';
    @track isOpen = false;
    @track itemcounts = 'None Selected';
    @track showselectall = false;
    @track errors;
    @track isTouching = false;

    // Expose isOpen as API property
    @api get isDropdownOpen() {
        return this.isOpen;
    }

    // Internal state variables
    mouse = false;
    focus = false;
    blurred = false;
    clickHandle = false;

    connectedCallback() {
        this._value = this.value || [];
        this.initializeOptions();
        this.initializeSelectedItems();
        this.addOutsideClickListener();
    }

    disconnectedCallback() {
        this.removeOutsideClickListener();
    }

    initializeOptions() {
        if (this.options && this.options.length > 0) {
            this.valuesVal = this.options.map(option => ({
                value: option.value,
                label: option.label
            }));
        }
    }

    initializeSelectedItems() {
        if (this._value && this._value.length > 0) {
            this.selectedItems = this.options.filter(option => this._value.includes(option.value));
            this.allValues = [...this._value];
            this.itemcounts = this.selectedItems.length > 0 ? `${this.selectedItems.length} options selected` : 'None Selected';
            this.selectedObject = this.selectedItems.length > 0;
        } else {
            this.selectedItems = [];
            this.allValues = [];
            this.itemcounts = 'None Selected';
            this.selectedObject = false;
        }
    }

    //this function is used to show the dropdown list
    get filteredResults() {
        if (this.valuesVal == undefined) {
            this.initializeOptions();
        }

        if (this.valuesVal != null && this.valuesVal.length != 0) {
            if (this.valuesVal) {
                const selectedProfileNames = this.selectedItems.map(profile => profile.value);
                return this.valuesVal.map(profile => {
                    //below logic is used to show check mark (✓) in dropdown checklist
                    const isChecked = selectedProfileNames.includes(profile.value);
                    return {
                        ...profile,
                        isChecked
                    };

                }).filter(profile =>
                    profile.label.toLowerCase().includes(this.searchTerm.toLowerCase())
                );
            } else {
                return [];
            }
        }
        return [];
    }

    get hasSelectedItems() {
        return this.selectedItems && this.selectedItems.length > 0;
    }

    get hasSelectedItemsAndClosed() {
        return this.hasSelectedItems && !this.isOpen;
    }

    get noResults() {
        return this.filteredResults.length === 0 && this.searchTerm.length > 0;
    }

    get activeDescendant() {
        return this.isOpen && this.filteredResults.length > 0 ? this.filteredResults[0].value : '';
    }

    //this function is used to filter/search the dropdown list based on user input
    handleSearch(event) {
        this.searchTerm = event.target.value;
        this.isOpen = true;
        this.mouse = false;
        this.focus = false;
        this.blurred = false;
        if (this.selectedItems.length != 0) {
            if (this.selectedItems.length >= this.selectionlimit) {
                this.isOpen = false;
            }
        }
    }

    //this function is used when user check/uncheck/selects (✓) an item in dropdown picklist
    handleSelection(event) {
        const selectedProfileId = event.target.value;
        const isChecked = event.target.checked;
        
        // Handle "All" selection logic
        if (selectedProfileId === 'All') {
            if (isChecked) {
                // If "All" is checked, clear all other selections
                this.selectedItems = [];
                this.allValues = [];
            } else {
                // If "All" is unchecked, this shouldn't happen normally
                return;
            }
        } else {
            // Handle individual item selection
            if (isChecked) {
                // If selecting an individual item, first remove "All" if it exists
                this.selectedItems = [...this.selectedItems.filter(profile => profile.value !== 'All')];
                this.allValues = [...this.allValues.filter(value => value !== 'All')];
                
                // Add the selected item
                const selectedProfile = this.valuesVal.find(profile => profile.value === selectedProfileId);
                if (selectedProfile && !this.selectedItems.some(item => item.value === selectedProfileId)) {
                    this.selectedItems = [...this.selectedItems, selectedProfile];
                    this.allValues = [...this.allValues, selectedProfileId];
                }
            } else {
                // If unchecking an individual item, remove it
                this.selectedItems = [...this.selectedItems.filter(profile => profile.value !== selectedProfileId)];
                this.allValues = [...this.allValues.filter(value => value !== selectedProfileId)];
                
                // If no items are selected, select "All"
                if (this.selectedItems.length === 0) {
                    const allProfile = this.valuesVal.find(profile => profile.value === 'All');
                    if (allProfile) {
                        this.selectedItems = [allProfile];
                        this.allValues = ['All'];
                    }
                }
            }
        }

        // Force immediate UI update to prevent race conditions
        this.updateUIState();
        
        // Dispatch change event
        this.dispatchChangeEvent();
    }

    // Helper method to update UI state immediately
    updateUIState() {
        this.itemcounts = this.selectedItems.length > 0 ? `${this.selectedItems.length} options selected` : 'None Selected';

        if (this.itemcounts == 'None Selected') {
            this.selectedObject = false;
        } else {
            this.selectedObject = true;
        }
    }

    // Method to close dropdown and trigger search
    closeDropdownAndSearch() {
        this.isOpen = false;
        // Dispatch a custom event to trigger search
        const searchEvent = new CustomEvent('searchtrigger', {
            detail: {
                reason: 'dropdown_closed'
            }
        });
        this.dispatchEvent(searchEvent);
    }

    // Handle option click for better UX
    handleOptionClick(event) {
        // Always prevent default and stop propagation
        event.preventDefault();
        event.stopPropagation();
        
        // Find the checkbox (whether clicking on it directly or on the list item)
        const checkbox = event.target.type === 'checkbox' 
            ? event.target 
            : event.currentTarget.querySelector('input[type="checkbox"]');
        
        if (checkbox) {
            // Toggle the checkbox state
            checkbox.checked = !checkbox.checked;
            
            // Create a synthetic event with the correct checked state
            const syntheticEvent = {
                target: {
                    value: checkbox.value,
                    checked: checkbox.checked
                }
            };
            
            // Update the component state directly
            this.handleSelection(syntheticEvent);
        }
        
        // Keep dropdown open after selection
        this.isOpen = true;
    }

    // Handle mobile touch start
    handleOptionTouchStart(event) {
        this.isTouching = true;
        event.preventDefault();
        event.stopPropagation();
    }

    // Handle mobile touch end
    handleOptionTouchEnd(event) {
        event.preventDefault();
        event.stopPropagation();
        
        // Toggle the checkbox
        const checkbox = event.currentTarget.querySelector('input[type="checkbox"]');
        if (checkbox) {
            checkbox.checked = !checkbox.checked;
            
            // Create a synthetic event with the correct checked state
            const syntheticEvent = {
                target: {
                    value: checkbox.value,
                    checked: checkbox.checked
                }
            };
            
            // Update the component state directly
            this.handleSelection(syntheticEvent);
        }
        
        // Keep dropdown open
        this.isOpen = true;
        
        // Reset touching flag after a delay
        setTimeout(() => {
            this.isTouching = false;
        }, 200);
    }

    // Handle container touch start
    handleContainerTouchStart(event) {
        this.isTouching = true;
        event.stopPropagation();
    }

    // Handle input touch start
    handleInputTouchStart(event) {
        this.isTouching = true;
        event.stopPropagation();
    }

    // Handle option hover for better UX
    handleOptionHover(event) {
        // Remove active class from all options
        this.template.querySelectorAll('.dropdown-item').forEach(item => {
            item.classList.remove('slds-is-focused');
        });
        // Add active class to hovered option
        event.currentTarget.classList.add('slds-is-focused');
    }

    // Handle dropdown mouse enter
    handleDropdownMouseEnter(event) {
        // Keep dropdown open when mouse enters
    }

    // Handle dropdown mouse leave - REMOVED
    // We only want to close on outside clicks, not mouse movement

    // Handle input click/focus to open dropdown
    clickhandler(event) {
        event.preventDefault();
        event.stopPropagation();
        if (!this.disabled) {
            this.isOpen = true;
            this.showselectall = true;
            this.filterOptions();
        }
    }

    // Handle mouse leave to close dropdown - REMOVED
    // We don't want to close on mouse leave, only on click outside

    // Handle input blur - no longer needed with outside click detection
    blurhandler(event) {
        // Do nothing - we use outside click detection instead
    }

    // Handle input focus
    focusHandler(event) {
        event.preventDefault();
        event.stopPropagation();
        if (!this.disabled) {
            this.isOpen = true;
            this.showselectall = true;
            this.filterOptions();
        }
    }

    // Filter options method
    filterOptions() {
        // This method is called to refresh the filtered results
        // The actual filtering is done in the getter
    }

    // Helper method to update UI state consistently
    updateUIState() {
        this.itemcounts = this.selectedItems.length > 0 ? `${this.selectedItems.length} options selected` : 'None Selected';
        this.selectedObject = this.selectedItems.length > 0;
    }

    //this function is invoked when user deselect/remove (✓) items from dropdown picklist
    handleRemove(event) {
        const valueRemoved = event.target.name;
        this.selectedItems = this.selectedItems.filter(profile => profile.value !== valueRemoved);
        this.allValues.splice(this.allValues.indexOf(valueRemoved), 1);
        
        // Use helper method for consistent UI updates
        this.updateUIState();
        this.errormessage();

        // Dispatch change event - parent will detect pill removal and trigger search
        this.dispatchChangeEvent();
    }

    //this function is used to deselect/uncheck (✓) all of the items in dropdown picklist
    handleclearall(event) {
        event.preventDefault();
        this.isOpen = false;
        this.selectedItems = [];
        this.allValues = [];
        this.searchTerm = '';
        this.selectionlimit = 10;
        
        // Use helper method for consistent UI updates
        this.updateUIState();
        this.errormessage();

        // Dispatch change event
        this.dispatchChangeEvent();
    }

    //this function is used to select/check (✓) all of the items in dropdown picklist
    selectall(event) {
        event.preventDefault();

        if (this.valuesVal == undefined) {
            this.initializeOptions();
        }
        this.selectedItems = this.valuesVal;
        this.selectionlimit = this.selectedItems.length + 1;
        this.allValues = [];
        this.valuesVal.map((value) => {
            for (let property in value) {
                if (property == 'value') {
                    this.allValues.push(`${value[property]}`);
                }
            }
        });
        
        // Use helper method for consistent UI updates
        this.updateUIState();
        this.errormessage();

        // Dispatch change event
        this.dispatchChangeEvent();
    }

    //this function is used to show the custom error message when user is trying to select picklist items more than selectionlimit passed by parent component  
    errormessage() {
        this.errors = {
            [this.label]: "Maximum of " + this.selectionlimit + " items can be selected",
        };
        this.template.querySelectorAll("lightning-input").forEach(item => {
            let label = item.label;
            if (label == this.label) {

                // if selected items list crosses selection limit, it will through custom error
                if (this.selectedItems.length >= this.selectionlimit) {
                    item.setCustomValidity(this.errors[label]);
                } else {
                    //else part will clear the error
                    item.setCustomValidity("");
                }
                item.reportValidity();
            }
        });
    }

    // Dispatch change event to parent component
    dispatchChangeEvent() {
        const changeEvent = new CustomEvent('valuechange', {
            detail: {
                value: this.selectedItems.map(item => item.value)
            }
        });
        this.dispatchEvent(changeEvent);
    }

    // Public method to set value programmatically
    @api
    setValue(value) {
        if (Array.isArray(value)) {
            this.selectedItems = this.options.filter(option => value.includes(option.value));
            this.allValues = [...value];
            this.itemcounts = this.selectedItems.length > 0 ? `${this.selectedItems.length} options selected` : 'None Selected';
            this.selectedObject = this.selectedItems.length > 0;
        }
    }

    // Public method to clear selection
    @api
    clearSelection() {
        this.handleclearall({ preventDefault: () => {} });
    }

    // Add outside click listener
    addOutsideClickListener() {
        this.outsideClickHandler = (event) => {
            // Don't close if clicking dropdown items or checkboxes
            if (event.target.closest('.dropdown-item') || 
                event.target.closest('.slds-checkbox') ||
                event.target.closest('.dropdown-container') ||
                event.target.closest('.multiselect-container')) {
                return;
            }
            
            // Close dropdown if clicking outside
            this.closeDropdownAndSearch();
        };
        
        this.outsideTouchHandler = (event) => {
            // Don't close if currently touching inside the component
            if (this.isTouching) {
                return;
            }
            
            // Don't close if touching dropdown items or checkboxes
            if (event.target.closest('.dropdown-item') || 
                event.target.closest('.slds-checkbox') ||
                event.target.closest('.dropdown-container') ||
                event.target.closest('.multiselect-container')) {
                return;
            }
            
            // Close dropdown if touching outside - add small delay for mobile
            setTimeout(() => {
                if (!this.isTouching) {
                    this.closeDropdownAndSearch();
                }
            }, 100);
        };
        
        // Add click listener for desktop
        document.addEventListener('click', this.outsideClickHandler);
        
        // Add touch listener for mobile - use touchend instead of touchstart
        document.addEventListener('touchend', this.outsideTouchHandler);
    }

    // Remove outside click listener
    removeOutsideClickListener() {
        if (this.outsideClickHandler) {
            document.removeEventListener('click', this.outsideClickHandler);
            this.outsideClickHandler = null;
        }
        
        if (this.outsideTouchHandler) {
            document.removeEventListener('touchend', this.outsideTouchHandler);
            this.outsideTouchHandler = null;
        }
    }
}