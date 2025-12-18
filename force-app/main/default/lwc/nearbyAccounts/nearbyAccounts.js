import { LightningElement, track } from 'lwc';
import getNearbyAccounts from '@salesforce/apex/NearbyAccountsController.getNearbyAccounts';
import getGooglePlaceSuggestions from '@salesforce/apex/NearbyAccountsController.getGooglePlaceSuggestions';
import getGooglePlaceDetails from '@salesforce/apex/NearbyAccountsController.getGooglePlaceDetails';
import createUserSession from '@salesforce/apex/NearbyAccountsController.createUserSession';
import addLogEntryToSession from '@salesforce/apex/NearbyAccountsController.addLogEntryToSession';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import formFactor from '@salesforce/client/formFactor';

export default class NearbyAccounts extends LightningElement {

    @track radius = 10; // Default value changed from 0.1 to 10
    @track allAccounts = []; // Store all accounts
    @track allAccountsUnfiltered = []; // Store all unfiltered accounts for filter dropdowns
    @track accounts = []; // Store paginated accounts
    @track mapMarkers = [];
    @track userLat = null; // Changed from default location to null
    @track userLon = null; // Changed from default location to null
    @track currentAddress = 'Loading...';
    @track error;
    @track sortedBy = 'Distance';
    @track sortedDirection = 'asc';
    @track pageSize = 20; // Changed to 20 records per page
    @track useCurrentLocation = false; // Default to using preset location
    @track mapZoomLevel = 14; // Default zoom level
    @track mapCenter = null; // Add map center tracking
    @track isLoading = false;
    @track isMapLoading = false;
    @track isTableLoading = false;
    
    // Pagination properties
    @track currentPage = 1;
    @track totalPages = 1;
    @track totalRecords = 0;
    @track startRecord = 0;
    @track endRecord = 0;

    @track address = '';
    @track segment = '';
    @track industry = '';
    @track csSentiment = '';

    @track cachedManualAddress = '';
    @track cachedManualCoordinates = null;

    segmentOptions = [ { label: 'All', value: 'All' } ];
    industryOptions = [ { label: 'All', value: 'All' } ];
    csSentimentOptions = [ { label: 'All', value: 'All' } ];

    @track showNavModal = false;
    @track selectedAccount = null;
    @track modalAccount = null; // Track the account that should be displayed in the modal

    columns = [
        {
            label: 'Name',
            fieldName: 'accountUrl',
            type: 'url',
            typeAttributes: {
                label: { fieldName: 'Name' },
                target: '_blank'
            },
            sortable: true,
            wrapText: true
        },
        {
            label: 'Address',
            fieldName: 'formattedAddress',
            type: 'text',
            sortable: true,
            wrapText: true
        },
        {
            label: 'Distance',
            fieldName: 'Distance',
            type: 'number',
            sortable: true,
            typeAttributes: {
                minimumFractionDigits: 2,
                maximumFractionDigits: 2
            },
            cellAttributes: { alignment: 'center' },
            wrapText: true
        },
        {
            label: 'Segment',
            fieldName: 'Segment__c',
            type: 'text',
            sortable: true,
            cellAttributes: { alignment: 'center' },
            wrapText: true
        },
        {
            label: 'Industry',
            fieldName: 'Industry',
            type: 'text',
            sortable: true,
            wrapText: true
        },
        {
            label: 'ARR',
            fieldName: 'Total_Parent_Account_Customer_ARR__c',
            type: 'currency',
            sortable: true,
            cellAttributes: { alignment: 'center' },
            wrapText: true
        },
        {
            label: 'Sentiment',
            fieldName: 'CSM_Health_Rating__c',
            type: 'text',
            sortable: true,
            cellAttributes: { alignment: 'center' },
            wrapText: true
        },
        {
            label: 'Total Pipeline',
            fieldName: 'Total_Pipeline__c',
            type: 'currency',
            sortable: true,
            cellAttributes: { alignment: 'center' },
            wrapText: true
        },
        {
            label: 'Owner',
            fieldName: 'OwnerName',
            type: 'text',
            sortable: true,
            wrapText: true
        },
        {
            label: 'Manager',
            fieldName: 'OwnerManagerName',
            type: 'text',
            sortable: true,
            wrapText: true
        },
        {
            label: 'Navigate',
            type: 'button',
            typeAttributes: {
                label: 'Navigate',
                name: 'navigate',
                variant: 'brand',
                disabled: { fieldName: 'disabledNav' }
            },
            wrapText: true
        }
    ];

    debounceTimeout;
    debounceDelay = 300; // ms

    @track searchError = null;
    searchTimeout;

    @track suggestions = [];
    @track suggestionError = null;

    @track isMobile = false;
    @track isLandscapeMode = false;

    @track locationStatus = '';
    @track locationStatusClass = '';

    @track accountTypeFilter = ['all_near_me'];
    accountTypeOptions = [
        { label: 'All accounts near me', value: 'all_near_me' },
        { label: 'All accounts with open pipeline', value: 'all_with_pipeline' },
        { label: 'All existing customers', value: 'all_customers' },
        { label: 'Existing customers with open pipeline', value: 'customers_with_pipeline' },
        { label: 'Existing customers without open pipeline', value: 'customers_without_pipeline' },
        { label: 'Prospect accounts with open pipeline', value: 'prospects_with_pipeline' },
        { label: 'Prospect accounts without pipeline', value: 'prospects_without_pipeline' }
    ];

    @track ownerFilter = [];
    @track ownerOptions = [];
    @track ownerDropdownOpen = false;

    @track deviceType = 'Unknown';
    @track sessionLogId = null;

    currentRequestId = 0;

    // Add new tracked properties for city and state filters if not already present
    @track city = '';
    @track state = '';
    
    // Track scroll position for mobile modal
    scrollPosition = undefined;
    viewportHeight = undefined;
    viewportWidth = undefined;
    modalTop = undefined;
    
    // Add property to store click position
    clickPosition = null;


    connectedCallback() {
        // console.log('Component initialized');
        this.detectDeviceType();
        // Create session log immediately when screen loads
        this.createSessionLog();
        this.currentAddress = 'Loading location...';
        if (navigator.geolocation) {
            navigator.geolocation.getCurrentPosition(
                (position) => {
                    const lat = position.coords.latitude;
                    const lon = position.coords.longitude;
                    this.initialGeoCoordinates = { lat, lon };
                    // If you want to auto-search on load, do it here:
                    // this.userLat = lat;
                    // this.userLon = lon;
                    // this.handleSearch(true, true);
                },
                () => {
                    this.initialGeoCoordinates = null;
                }
            );
        }
        // Only search if we have a valid location
        if (this.userLat && this.userLon) {
            this.handleSearch(true, true);
        }
        this.updateIsMobile();
        window.addEventListener('resize', this.updateIsMobile.bind(this));
    }

    disconnectedCallback() {
        // Clean up event listeners
        window.removeEventListener('resize', this.updateIsMobile.bind(this));
        
        // Clean up observers and intervals
        if (this.modalPositionObserver) {
            this.modalPositionObserver.disconnect();
            this.modalPositionObserver = null;
        }
        if (this.modalPositionCheckInterval) {
            clearInterval(this.modalPositionCheckInterval);
            this.modalPositionCheckInterval = null;
        }
        
        // Ensure scrolling is unblocked if modal is still open
        if (this.showNavModal) {
            this.unblockScrolling();
        }
    }

    renderedCallback() {
        if (this._hasRendered) return;
        this._hasRendered = true;

        // Ensure mobile detection is initialized
        this.updateIsMobile();

        this.template.addEventListener('click', (event) => {
            const input = this.template.querySelector('lightning-input');
            if (input && !input.contains(event.target)) {
                this.suggestions = [];
            }
        });
    }

    hideDropdown(event) {
        const cmpName = this.template.host.tagName;
        const clickedElementSrcName = event.target.tagName;
        const isClickedOutside = cmpName !== clickedElementSrcName;
        if (this.suggestions && isClickedOutside) {
            this.clearSearchResults();
        }
    }

    handleLocationToggle(event) {
        if (this.isLoading) return;
        this.useCurrentLocation = event.detail.checked;
        this.currentSearchRequestId++;
        const requestId = this.currentSearchRequestId;
        if (!this.useCurrentLocation) {
            this.locationStatus = '';
            this.locationStatusClass = '';
            if (this.cachedManualAddress && this.cachedManualCoordinates) {
                this.address = this.cachedManualAddress;
                this.userLat = this.cachedManualCoordinates.lat;
                this.userLon = this.cachedManualCoordinates.lon;
                this.currentAddress = this.cachedManualAddress;
                this.mapCenter = {
                    Latitude: this.userLat,
                    Longitude: this.userLon
                };
                this.accounts = [];
                this.mapMarkers = [];
                this.handleSearch(true, true);
            } else {
                this.userLat = null;
                this.userLon = null;
                this.currentAddress = '';
                this.mapCenter = null;
                this.accounts = [];
                this.mapMarkers = [];
            }
        } else {
            if (this.address && this.userLat && this.userLon) {
                this.cachedManualAddress = this.address;
                this.cachedManualCoordinates = { lat: this.userLat, lon: this.userLon };
            }
            this.currentAddress = 'Current Location';
            this.locationStatus = 'Detecting your location...';
            this.locationStatusClass = 'slds-text-color_weak';
            this.getUserLocation(requestId);
        }
        this.updateMapMarkers();
    }

    getUserLocation() {
        this.isMapLoading = true;
        this.isTableLoading = true;
        let didRespond = false;
        this.locationStatus = 'Detecting your location...';
        this.locationStatusClass = 'slds-text-color_weak';

        if (navigator.geolocation) {
            navigator.geolocation.getCurrentPosition(
                (position) => {
                    if (didRespond) return;
                    didRespond = true;
                    this.userLat = position.coords.latitude;
                    this.userLon = position.coords.longitude;
                    this.locationStatus = 'Using your current location';
                    this.locationStatusClass = 'slds-text-color_success';
                    
                    // Set map center to current location
                    this.mapCenter = {
                        Latitude: this.userLat,
                        Longitude: this.userLon
                    };
                    
                    // Add a marker for the current location
                    this.mapMarkers = [{
                        location: {
                            Latitude: this.userLat,
                            Longitude: this.userLon
                        },
                        title: 'Your Location',
                        description: 'Your current location',
                        icon: 'utility:user',
                        mapIcon: {
                            path: 'M12 2C8.13 2 5 5.13 5 9c0 5.25 7 13 7 13s7-7.75 7-13c0-3.87-3.13-7-7-7z M12 10a2 2 0 1 1 0-4 2 2 0 0 1 0 4z',
                            fillColor: '#1A73E8',
                            fillOpacity: 1,
                            strokeColor: '#0B53A0',
                            strokeWeight: 2,
                            scale: 2,
                            anchor: {x: 12, y: 22}
                        }
                    }];
                    
                    // Set zoom level for current location view
                    this.mapZoomLevel = 15;
                    this.currentAddress = 'Current Location';
                    this.handleSearch();
                },
                () => {
                    if (didRespond) return;
                    didRespond = true;
                    this.locationStatus = 'Using approximate location...';
                    this.locationStatusClass = 'slds-text-color_weak';
                    
                    // Fallback to IP-based geolocation
                    fetch('https://ipwho.is/')
                        .then(response => response.json())
                        .then(data => {
                            if (data.success && data.latitude && data.longitude) {
                                this.userLat = data.latitude;
                                this.userLon = data.longitude;
                                this.mapCenter = {
                                    Latitude: this.userLat,
                                    Longitude: this.userLon
                                };
                                this.currentAddress = 'Approximate Location';
                                this.mapMarkers = [{
                                    location: {
                                        Latitude: this.userLat,
                                        Longitude: this.userLon
                                    },
                                    title: 'Your Location',
                                    description: 'Approximate location',
                                    icon: 'utility:user',
                                    mapIcon: {
                                        path: 'M12 2C8.13 2 5 5.13 5 9c0 5.25 7 13 7 13s7-7.75 7-13c0-3.87-3.13-7-7-7z M12 10a2 2 0 1 1 0-4 2 2 0 0 1 0 4z',
                                        fillColor: '#1A73E8',
                                        fillOpacity: 1,
                                        strokeColor: '#0B53A0',
                                        strokeWeight: 2,
                                        scale: 2,
                                        anchor: {x: 12, y: 22}
                                    }
                                }];
                                this.mapZoomLevel = 15;
                                this.handleSearch();
                            }
                        })
                        .catch(() => {
                            this.userLat = null;
                            this.userLon = null;
                            this.mapCenter = null;
                            this.currentAddress = '';
                            this.mapMarkers = [];
                            this.handleSearch();
                        });
                },
                { enableHighAccuracy: true, timeout: 4000 }
            );

            // Set timeout for IP fallback
            setTimeout(() => {
                if (!didRespond) {
                    didRespond = true;
                    this.locationStatus = 'Using approximate location...';
                    this.locationStatusClass = 'slds-text-color_weak';
                    
                    // Fallback to IP-based geolocation
                    fetch('https://ipwho.is/')
                        .then(response => response.json())
                        .then(data => {
                            if (data.success && data.latitude && data.longitude) {
                                this.userLat = data.latitude;
                                this.userLon = data.longitude;
                                this.mapCenter = {
                                    Latitude: this.userLat,
                                    Longitude: this.userLon
                                };
                                this.currentAddress = 'Approximate Location';
                                this.mapMarkers = [{
                                    location: {
                                        Latitude: this.userLat,
                                        Longitude: this.userLon
                                    },
                                    title: 'Your Location',
                                    description: 'Approximate location',
                                    icon: 'utility:user',
                                    mapIcon: {
                                        path: 'M12 2C8.13 2 5 5.13 5 9c0 5.25 7 13 7 13s7-7.75 7-13c0-3.87-3.13-7-7-7z M12 10a2 2 0 1 1 0-4 2 2 0 0 1 0 4z',
                                        fillColor: '#1A73E8',
                                        fillOpacity: 1,
                                        strokeColor: '#0B53A0',
                                        strokeWeight: 2,
                                        scale: 2,
                                        anchor: {x: 12, y: 22}
                                    }
                                }];
                                this.mapZoomLevel = 15;
                                this.handleSearch();
                            }
                        })
                        .catch(() => {
                            this.userLat = null;
                            this.userLon = null;
                            this.mapCenter = null;
                            this.currentAddress = '';
                            this.mapMarkers = [];
                            this.handleSearch();
                        });
                }
            }, 4000);
        } else {
            this.locationStatus = 'Geolocation not supported';
            this.locationStatusClass = 'slds-text-color_weak';
            this.useCurrentLocation = false;
        }
    }

    handleSort(event) {
        const { fieldName, sortDirection } = event.detail;
        this.sortedBy = fieldName;
        this.sortedDirection = sortDirection;
        this.sortData(fieldName, sortDirection);
        // Ensure zoom recalculates after sorting
        this.calculateZoomLevel();
    }

    sortData(fieldName, direction) {
        if (!this.allAccounts || this.allAccounts.length === 0) {
            return;
        }

        const cloneData = [...this.allAccounts];
        cloneData.sort((a, b) => {
            let valueA = a[fieldName];
            let valueB = b[fieldName];

            if (fieldName === 'Distance') {
                // Ensure we're working with numbers for distance
                valueA = typeof valueA === 'number' ? valueA : parseFloat(valueA) || 0;
                valueB = typeof valueB === 'number' ? valueB : parseFloat(valueB) || 0;
                
            } else if (fieldName === 'AnnualRevenue' || fieldName === 'Total_Parent_Account_Customer_ARR__c') {
                valueA = parseFloat(valueA) || 0;
                valueB = parseFloat(valueB) || 0;
            } else if (fieldName === 'Name' || fieldName === 'formattedAddress') {
                valueA = (valueA || '').toLowerCase();
                valueB = (valueB || '').toLowerCase();
            }

            if (valueA === null) valueA = 0;
            if (valueB === null) valueB = 0;

            if (direction === 'asc') {
                return valueA > valueB ? 1 : -1;
            }
            return valueA < valueB ? 1 : -1;
        });

        this.allAccounts = cloneData;
        this.updatePagination();
    }

    handleSearch(showToastIfNoCoords = true, isLocationOrRadiusChange = false) {
        if (!this.userLat || !this.userLon) {
            this.isMapLoading = false;
            this.isTableLoading = false;
            return;
        }
        
        // Note: Removed "Search Initiated" logging to avoid duplicate entries
        // User actions are logged individually in their respective handlers
        
        this.isMapLoading = true;
        this.isTableLoading = true;
        this.currentRequestId++;
        const requestId = this.currentRequestId;
        let params = {
            userLat: this.userLat,
            userLon: this.userLon,
            radiusMiles: this.radius,
            deviceType: this.deviceType,
            formFactor: formFactor
        };
        if (this.segment && this.segment !== 'All') {
            params.segment = this.segment === '__NONE__' ? null : this.segment;
        }
        if (this.industry && this.industry !== 'All') {
            params.industry = this.industry === '__NONE__' ? null : this.industry;
        }
        if (this.csSentiment && this.csSentiment !== 'All') {
            params.csSentiment = this.csSentiment === '__NONE__' ? null : this.csSentiment;
        }
        if (this.accountTypeFilter && this.accountTypeFilter.length > 0) {
            // Ensure it's a proper array of strings
            params.accountTypeFilter = Array.isArray(this.accountTypeFilter) ? this.accountTypeFilter : [this.accountTypeFilter];
        }
        if (this.ownerFilter && this.ownerFilter.length > 0) {
            // Ensure it's a proper array of strings
            params.ownerFilter = Array.isArray(this.ownerFilter) ? this.ownerFilter : [this.ownerFilter];
        }
        if (this.city) params.city = this.city;
        if (this.state) params.state = this.state;
        getNearbyAccounts({ params })
            .then(result => {
                if (requestId !== this.currentRequestId) return; // Only process latest
                this.allAccounts = result.map(acc => ({
                    ...acc,
                    Distance: acc.distance,
                    formattedAddress: this.formatAddress(acc),
                    accountUrl: `/lightning/r/Account/${acc.Id}/view`,
                    OwnerId: acc.OwnerId,
                    OwnerName: acc.Owner ? acc.Owner.Name : '',
                    OwnerManagerName: acc.Owner && acc.Owner.Manager ? acc.Owner.Manager.Name : '',
                    googleMapsValue: acc.BillingLatitude && acc.BillingLongitude ? `${acc.BillingLatitude},${acc.BillingLongitude},google` : '',
                    appleMapsValue: acc.BillingLatitude && acc.BillingLongitude ? `${acc.BillingLatitude},${acc.BillingLongitude},apple` : '',
                    hasCoordinates: !!(acc.BillingLatitude && acc.BillingLongitude),
                    disabledNav: !(acc.BillingLatitude && acc.BillingLongitude)
                }));
                this.error = null;
                this.sortedBy = 'Distance';
                this.sortedDirection = 'asc';
                this.sortData(this.sortedBy, this.sortedDirection);
                this.initializePagination();
                // Always update filter options after search to get owners from all results
                this.updateFilterOptions();
            })
            .catch(error => {
                if (requestId !== this.currentRequestId) return;
                this.error = error.body ? error.body.message : error.message;
                this.allAccounts = [];
                this.showToast('Error', this.error, 'error');
            })
            .finally(() => {
                if (requestId !== this.currentRequestId) return;
                this.isMapLoading = false;
                this.isTableLoading = false;
            });
    }

    initializePagination() {
        this.totalRecords = this.allAccounts.length;
        this.totalPages = Math.max(1, Math.ceil(this.totalRecords / this.pageSize));
        this.currentPage = 1;
        this.updatePagination();
    }

    updatePagination() {
        if (!this.allAccounts || this.allAccounts.length === 0) {
            this.accounts = [];
            this.startRecord = 0;
            this.endRecord = 0;
            this.totalRecords = 0;
            this.totalPages = 1;
            this.currentPage = 1;
            // Always show user location marker on the map, even if no accounts
            this.mapMarkers = [];
            if (this.userLat && this.userLon) {
                this.mapMarkers.push({
                    location: {
                        Latitude: this.userLat,
                        Longitude: this.userLon
                    },
                    title: 'Your Location',
                    description: this.currentAddress,
                    icon: 'utility:user',
                    mapIcon: {
                        path: 'M12 2C8.13 2 5 5.13 5 9c0 5.25 7 13 7 13s7-7.75 7-13c0-3.87-3.13-7-7-7z M12 10a2 2 0 1 1 0-4 2 2 0 0 1 0 4z',
                        fillColor: '#1A73E8', // Blue
                        fillOpacity: 1,
                        strokeColor: '#0B53A0',
                        strokeWeight: 2,
                        scale: 2,
                        anchor: {x: 12, y: 22}
                    }
                });
            }
            return;
        }

        const start = (this.currentPage - 1) * this.pageSize;
        const end = Math.min(start + this.pageSize, this.totalRecords);
        this.accounts = this.allAccounts.slice(start, end);
        this.startRecord = this.totalRecords > 0 ? start + 1 : 0;
        this.endRecord = end;

        // Update map markers for current page
        this.updateMapMarkers();
    }

    // Helper method to determine pin color based on account conditions
    getAccountPinColor(account) {
        const hasARR = account.Total_Parent_Account_Customer_ARR__c > 0;
        const hasPipeline = account.Total_Pipeline__c > 0;
        
        if (hasARR && hasPipeline) {
            return { 
                fillColor: '#FF9800', 
                strokeColor: '#E68900', 
                label: 'Customer with Pipeline' 
            }; // Orange
        } else if (hasARR && !hasPipeline) {
            return { 
                fillColor: '#4CAF50', 
                strokeColor: '#388E3C', 
                label: 'Customer (No Pipeline)' 
            }; // Green
        } else if (!hasARR && hasPipeline) {
            return { 
                fillColor: '#2196F3', 
                strokeColor: '#1976D2', 
                label: 'Prospect with Pipeline' 
            }; // Blue
        } else {
            return { 
                fillColor: '#00BCD4', // Teal
                strokeColor: '#0097A7', // Teal
                label: 'Prospect (No Pipeline)' 
            }; // Teal
        }
    }



    updateMapMarkers() {
        // Create map markers only for accounts in current page
        this.mapMarkers = this.accounts.map(acc => {
            if (acc.Name === 'Your Location') {
                return {
                    location: {
                        Latitude: acc.BillingLatitude,
                        Longitude: acc.BillingLongitude
                    },
                    title: acc.Name,
                    description: `ARR: $${acc.Total_Parent_Account_Customer_ARR__c?.toLocaleString() || '0'}`,
                    icon: 'utility:user',
                    mapIcon: {
                        path: 'M12 2C8.13 2 5 5.13 5 9c0 5.25 7 13 7 13s7-7.75 7-13c0-3.87-3.13-7-7-7z M12 10a2 2 0 1 1 0-4 2 2 0 0 1 0 4z',
                        fillColor: '#1A73E8',
                        fillOpacity: 1,
                        strokeColor: '#0B53A0',
                        strokeWeight: 2,
                        scale: 2,
                        anchor: {x: 12, y: 22}
                    }
                };
            } else {
                const pinColor = this.getAccountPinColor(acc);
                return {
                    location: {
                        Latitude: acc.BillingLatitude,
                        Longitude: acc.BillingLongitude
                    },
                    title: acc.Name,
                    description: `<b>Account Owner:</b> ${acc.OwnerName || ''}<br><b>Manager:</b> ${acc.OwnerManagerName || ''}<br><b>ARR:</b> $${acc.Total_Parent_Account_Customer_ARR__c?.toLocaleString() || '0'}<br><b>Pipeline:</b> $${acc.Total_Pipeline__c?.toLocaleString() || '0'}`,
                    icon: 'standard:account',
                    mapIcon: {
                        path: 'M12 2C8.13 2 5 5.13 5 9c0 5.25 7 13 7 13s7-7.75 7-13c0-3.87-3.13-7-7-7z M12 10a2 2 0 1 1 0-4 2 2 0 0 1 0 4z',
                        fillColor: pinColor.fillColor,
                        fillOpacity: 1,
                        strokeColor: pinColor.strokeColor,
                        strokeWeight: 2,
                        scale: 1.5,
                        anchor: {x: 12, y: 22}
                    }
                };
            }
        });

        // Add user location marker with a different icon and color
        if (this.userLat && this.userLon) {
            this.mapMarkers.unshift({
                location: {
                    Latitude: this.userLat,
                    Longitude: this.userLon
                },
                title: 'Your Location',
                description: this.currentAddress,
                icon: 'utility:user',
                mapIcon: {
                    path: 'M12 2C8.13 2 5 5.13 5 9c0 5.25 7 13 7 13s7-7.75 7-13c0-3.87-3.13-7-7-7z M12 10a2 2 0 1 1 0-4 2 2 0 0 1 0 4z',
                    fillColor: '#1A73E8', // Blue
                    fillOpacity: 1,
                    strokeColor: '#0B53A0',
                    strokeWeight: 2,
                    scale: 2,
                    anchor: {x: 12, y: 22}
                }
            });
        }

        // Calculate appropriate zoom level based on marker distances
        this.calculateZoomLevel();

        // console.log('Updated map markers:', this.mapMarkers);
    }

    calculateZoomLevel() {
        if (this.mapMarkers.length <= 1) {
            if (this.mapMarkers.length === 1) {
                this.mapCenter = {
                    Latitude: this.mapMarkers[0].location.Latitude,
                    Longitude: this.mapMarkers[0].location.Longitude
                };
            }
            this.mapZoomLevel = 15;
            return;
        }

        // Find min/max lat/lon
        let minLat = Infinity, maxLat = -Infinity, minLon = Infinity, maxLon = -Infinity;
        this.mapMarkers.forEach(marker => {
            const lat = marker.location.Latitude;
            const lon = marker.location.Longitude;
            if (lat < minLat) minLat = lat;
            if (lat > maxLat) maxLat = lat;
            if (lon < minLon) minLon = lon;
            if (lon > maxLon) maxLon = lon;
        });

        // Calculate center point
        const centerLat = (minLat + maxLat) / 2;
        const centerLon = (minLon + maxLon) / 2;
        this.mapCenter = {
            Latitude: centerLat,
            Longitude: centerLon
        };

        // Calculate the maximum distance between any two markers (Haversine)
        let maxDistance = 0;
        for (let i = 0; i < this.mapMarkers.length; i++) {
            for (let j = i + 1; j < this.mapMarkers.length; j++) {
                const d = this.calculateDistance(
                    this.mapMarkers[i].location.Latitude,
                    this.mapMarkers[i].location.Longitude,
                    this.mapMarkers[j].location.Latitude,
                    this.mapMarkers[j].location.Longitude
                );
                if (d > maxDistance) maxDistance = d;
            }
        }

        // Map maxDistance (in miles) to zoom level
        if (maxDistance > 1000) {
            this.mapZoomLevel = 4;
        } else if (maxDistance > 500) {
            this.mapZoomLevel = 5;
        } else if (maxDistance > 200) {
            this.mapZoomLevel = 6;
        } else if (maxDistance > 100) {
            this.mapZoomLevel = 7;
        } else if (maxDistance > 50) {
            this.mapZoomLevel = 8;
        } else if (maxDistance > 25) {
            this.mapZoomLevel = 9;
        } else if (maxDistance > 10) {
            this.mapZoomLevel = 10;
        } else if (maxDistance > 5) {
            this.mapZoomLevel = 11;
        } else if (maxDistance > 2) {
            this.mapZoomLevel = 12;
        } else if (maxDistance > 1) {
            this.mapZoomLevel = 13;
        } else {
            this.mapZoomLevel = 14;
        }
    }

    calculateDistance(lat1, lon1, lat2, lon2) {
        // Haversine formula to calculate distance between two points
        const R = 3958.8; // Earth's radius in miles
        const dLat = this.toRad(lat2 - lat1);
        const dLon = this.toRad(lon2 - lon1);
        const a = 
            Math.sin(dLat/2) * Math.sin(dLat/2) +
            Math.cos(this.toRad(lat1)) * Math.cos(this.toRad(lat2)) * 
            Math.sin(dLon/2) * Math.sin(dLon/2);
        const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a));
        return R * c;
    }

    toRad(degrees) {
        return degrees * (Math.PI / 180);
    }

    handleFirst() {
        if (this.totalPages > 0) {
            this.currentPage = 1;
            this.updatePagination();
        }
    }

    handlePrevious() {
        if (this.currentPage > 1) {
            this.currentPage--;
            this.updatePagination();
        }
    }

    handleNext() {
        if (this.currentPage < this.totalPages) {
            this.currentPage++;
            this.updatePagination();
        }
    }

    handleLast() {
        if (this.totalPages > 0) {
            this.currentPage = this.totalPages;
            this.updatePagination();
        }
    }

    formatAddress(account) {
        const parts = [];
        if (account.BillingStreet) parts.push(account.BillingStreet);
        if (account.BillingCity) parts.push(account.BillingCity);
        if (account.BillingState) parts.push(account.BillingState);
        if (account.BillingPostalCode) parts.push(account.BillingPostalCode);
        if (account.BillingCountry) parts.push(account.BillingCountry);
        return parts.join(', ') || 'No address available';
    }

    get isFirstPage() {
        return this.currentPage === 1;
    }

    get isLastPage() {
        return this.currentPage === this.totalPages;
    }

    // Debounced search helper
    debouncedSearch() {
        clearTimeout(this.debounceTimeout);
        this.debounceTimeout = setTimeout(() => {
            this.handleSearch();
        }, this.debounceDelay);
    }

    // Update the handleSearchChange method
    handleSearchChange(event) {
        const value = event.detail.value;
        this.address = value; // Update address when user types
        this.suggestionError = null;

        if (value.length < 3) {
            this.suggestions = [];
            return;
        }

        clearTimeout(this.searchTimeout);
        this.searchTimeout = setTimeout(() => {
            getGooglePlaceSuggestions({ input: value })
                .then(result => {
                    let data;
                    try {
                        data = JSON.parse(result);
                    } catch (e) {
                        throw new Error('Invalid response from Google Places API');
                    }
                    if (data.status === 'OK') {
                        this.suggestions = data.predictions.map(suggestion => ({
                            place_id: suggestion.place_id,
                            description: suggestion.description
                        }));
                        this.suggestionError = null;
                    } else if (data.status === 'ZERO_RESULTS') {
                        this.suggestions = [];
                        this.suggestionError = 'No results found. Try a different search.';
                    } else {
                        throw new Error(data.error_message || 'Error fetching place suggestions');
                    }
                })
                .catch(error => {
                    this.suggestions = [];
                    this.suggestionError = 'Error searching address. Please try again later.';
                });
        }, this.debounceDelay);
    }

    showPickListOptions() {
        if (!this.suggestions.length && this.searchKey) {
            this.handleSearchChange({ detail: { value: this.searchKey } });
        }
    }

    clearSearchResults() {
        this.suggestions = [];
    }

    // Update the handleSuggestionClick method
    handleSuggestionClick(event) {
        const placeId = event.currentTarget.dataset.placeId;
        if (!placeId) return;

        // Find the selected suggestion by place_id
        const selectedSuggestion = this.suggestions.find(s => s.place_id === placeId);
        if (selectedSuggestion) {
            this.address = selectedSuggestion.description; // Set plain description in input
        }

        this.isMapLoading = true;
        this.isTableLoading = true;
        this.searchError = null;

        getGooglePlaceDetails({ placeId: placeId })
            .then(result => {
                let data;
                try {
                    data = JSON.parse(result);
                } catch (e) {
                    throw new Error('Invalid response from Google Places API');
                }

                if (data.status === 'OK') {
                    const resultObj = data.result;
                    this.address = resultObj.formatted_address; // Also update with formatted address if available
                    this.suggestions = [];
                    
                    if (resultObj.geometry && resultObj.geometry.location) {
                        this.userLat = resultObj.geometry.location.lat;
                        this.userLon = resultObj.geometry.location.lng;
                        this.currentAddress = resultObj.formatted_address;
                        this.useCurrentLocation = false;
                        this.cachedManualAddress = resultObj.formatted_address;
                        this.cachedManualCoordinates = { lat: this.userLat, lon: this.userLon };
                        this.mapCenter = {
                            Latitude: this.userLat,
                            Longitude: this.userLon
                        };
                        this.mapZoomLevel = 14;
                        this.mapMarkers = [{
                            location: {
                                Latitude: this.userLat,
                                Longitude: this.userLon
                            },
                            title: 'Selected Location',
                            description: this.currentAddress,
                            icon: 'utility:location',
                            mapIcon: {
                                path: 'M12 2C8.13 2 5 5.13 5 9c0 5.25 7 13 7 13s7-7.75 7-13c0-3.87-3.13-7-7-7z M12 10a2 2 0 1 1 0-4 2 2 0 0 1 0 4z',
                                fillColor: '#1A73E8',
                                fillOpacity: 1,
                                strokeColor: '#0B53A0',
                                strokeWeight: 2,
                                scale: 2,
                                anchor: {x: 12, y: 22}
                            }
                        }];
                        
                        // Log address selection
                        this.addLogEntryToSession('Address Selected', {
                            address: this.currentAddress,
                            coordinates: { lat: this.userLat, lon: this.userLon },
                            placeId: placeId
                        });
                        
                        this.handleSearch(true, true);
                    } else {
                        throw new Error('No location data found for this address');
                    }
                } else {
                    throw new Error(data.error_message || 'Error fetching place details');
                }
            })
            .catch(error => {
                this.searchError = error.message;
                this.showToast('Error', error.message, 'error');
            })
            .finally(() => {
                this.isMapLoading = false;
                this.isTableLoading = false;
            });
    }

    handleSegmentChange(event) {
        const oldValue = this.segment;
        this.segment = event.detail.value;
        
        // Log filter change before search
        this.addLogEntryToSession('Filter Change', {
            filterType: 'Segment',
            oldValue: oldValue,
            newValue: this.segment
        });
        
        this.isTableLoading = true;
        this.isMapLoading = true;
        this.handleSearch(true, false);
    }
    handleIndustryChange(event) {
        const oldValue = this.industry;
        this.industry = event.detail.value;
        
        // Log filter change before search
        this.addLogEntryToSession('Filter Change', {
            filterType: 'Industry',
            oldValue: oldValue,
            newValue: this.industry
        });
        
        this.isTableLoading = true;
        this.isMapLoading = true;
        this.handleSearch(true, false);
    }
    handleCsSentimentChange(event) {
        const oldValue = this.csSentiment;
        this.csSentiment = event.detail.value;
        
        // Log filter change before search
        this.addLogEntryToSession('Filter Change', {
            filterType: 'CS Sentiment',
            oldValue: oldValue,
            newValue: this.csSentiment
        });
        
        this.isTableLoading = true;
        this.isMapLoading = true;
        this.handleSearch(true, false);
    }

    // Reset all filters to default values and trigger search
    handleReset() {
        this.address = '';
        this.segment = 'All';
        this.industry = 'All';
        this.csSentiment = 'All';
        this.ownerFilter = [];
        this.radius = 10;
        this.useCurrentLocation = false;
        this.userLat = null;
        this.userLon = null;
        this.currentAddress = '';
        this.mapCenter = null;
        this.handleSearch(true, true);
    }

    updateFilterOptions() {
        const isBlankOrDash = v => !v || v.trim() === '' || v.trim() === '--';
        const segmentSet = new Set(this.allAccounts.map(acc => acc.Segment__c).filter(v => !isBlankOrDash(v)));
        const industrySet = new Set(this.allAccounts.map(acc => acc.Industry).filter(v => !isBlankOrDash(v)));
        const csSet = new Set(this.allAccounts.map(acc => acc.CSM_Health_Rating__c).filter(v => !isBlankOrDash(v)));
        // Create a map of OwnerId to OwnerName for unique owners
        const ownerMap = new Map();
        console.log('Building owner map from allAccounts:', this.allAccounts.length, 'accounts');
        this.allAccounts.forEach(acc => {
            console.log('Account:', acc.Name, 'OwnerId:', acc.OwnerId, 'OwnerName:', acc.OwnerName);
            if (acc.OwnerId && acc.OwnerName) {
                ownerMap.set(acc.OwnerId, acc.OwnerName);
            }
        });
        console.log('Owner map created with', ownerMap.size, 'owners:', Array.from(ownerMap.entries()));
        const hasNullSegment = this.allAccounts.some(acc => isBlankOrDash(acc.Segment__c));
        const hasNullIndustry = this.allAccounts.some(acc => isBlankOrDash(acc.Industry));
        const hasNullSentiment = this.allAccounts.some(acc => isBlankOrDash(acc.CSM_Health_Rating__c));
        const hasNullOwner = this.allAccounts.some(acc => !acc.OwnerId || isBlankOrDash(acc.OwnerName));
        // Helper to sort options alphabetically, keeping 'All' at top and '-' at bottom if present
        function sortOptions(options) {
            const all = options.find(opt => opt.value === 'All');
            const none = options.find(opt => opt.value === '__NONE__');
            const rest = options.filter(opt => opt.value !== 'All' && opt.value !== '__NONE__')
                .sort((a, b) => a.label.localeCompare(b.label));
            const result = [];
            if (all) result.push(all);
            result.push(...rest);
            if (none) result.push(none);
            return result;
        }
        
        // Helper to sort segment options in descending order (Z-A), keeping 'All' at top and '-' at bottom if present
        function sortSegmentOptions(options) {
            const all = options.find(opt => opt.value === 'All');
            const none = options.find(opt => opt.value === '__NONE__');
            const rest = options.filter(opt => opt.value !== 'All' && opt.value !== '__NONE__')
                .sort((a, b) => b.label.localeCompare(a.label)); // Reverse sort for descending order
            const result = [];
            if (all) result.push(all);
            result.push(...rest);
            if (none) result.push(none);
            return result;
        }
        this.segmentOptions = sortSegmentOptions([
            { label: 'All', value: 'All' },
            ...Array.from(segmentSet).map(seg => ({ label: seg, value: seg })),
            ...(hasNullSegment ? [{ label: '-', value: '__NONE__' }] : [])
        ]);
        this.industryOptions = sortOptions([
            { label: 'All', value: 'All' },
            ...Array.from(industrySet).map(ind => ({ label: ind, value: ind })),
            ...(hasNullIndustry ? [{ label: '-', value: '__NONE__' }] : [])
        ]);
        this.csSentimentOptions = sortOptions([
            { label: 'All', value: 'All' },
            ...Array.from(csSet).map(cs => ({ label: cs, value: cs })),
            ...(hasNullSentiment ? [{ label: '-', value: '__NONE__' }] : [])
        ]);
        this.ownerOptions = sortOptions([
            { label: 'All', value: 'All' },
            ...Array.from(ownerMap.entries()).map(([ownerId, ownerName]) => ({ label: ownerName, value: ownerId })),
            ...(hasNullOwner ? [{ label: '-', value: '__NONE__' }] : [])
        ]);
        console.log('Final owner options:', this.ownerOptions);
        let shouldTriggerSearch = false;
        if (!this.segmentOptions.some(opt => opt.value === this.segment)) {
            this.segment = 'All';
            shouldTriggerSearch = true;
        }
        if (!this.industryOptions.some(opt => opt.value === this.industry)) {
            this.industry = 'All';
            shouldTriggerSearch = true;
        }
        if (!this.csSentimentOptions.some(opt => opt.value === this.csSentiment)) {
            this.csSentiment = 'All';
            shouldTriggerSearch = true;
        }
        // Reset owner filter if it has invalid selections (same logic as other filters)
        if (this.ownerFilter && this.ownerFilter.length > 0) {
            // Check if any selected owner is still valid in the new options
            const hasValidSelection = this.ownerOptions && this.ownerOptions.some(opt => this.ownerFilter.includes(opt.value));
            if (!hasValidSelection) {
                // Clear owner filter if no valid selections remain
                this.ownerFilter = [];
                shouldTriggerSearch = true;
            }
        }
        if (shouldTriggerSearch) {
            this.handleSearch();
        }
    }

    // Handler to open navigation links
    handleNavigate(event) {
        try {
            let acc = null;
            
            // Check if this is a mobile button click (has data-account-id)
            if (event && event.target && event.target.dataset && event.target.dataset.accountId) {
                const accountId = event.target.dataset.accountId;
                acc = this.accounts.find(a => a.Id === accountId);
                // console.log('Mobile button click - looking for account ID:', accountId);
            }
            // Fallback to old method for backward compatibility
            else if (event && event.target && event.target.value) {
                acc = this.accounts.find(a => a.googleMapsValue === event.target.value);
                // console.log('Legacy method - looking for googleMapsValue:', event.target.value);
            }
            // Check for row action from datatable
            else if (event && event.detail && event.detail.row) {
                acc = event.detail.row;
                // console.log('Row action from datatable');
            }
            
            if (acc) {
                this.selectedAccount = acc;
                this.modalAccount = acc; // Set the modal account as well
                // console.log('handleNavigate: Selected account:', acc.Name, 'ID:', acc.Id);
            } else {
                // console.error('handleNavigate: No account found for event:', event);
                return;
            }
            
            // Store click position for mobile positioning
            if (this.isMobile) {
                this.clickPosition = {
                    x: event.clientX || 0,
                    y: event.clientY || 0
                };
            }
            
            // Store current scroll position BEFORE opening modal
            this.scrollPosition = window.scrollY || window.pageYOffset || document.documentElement.scrollTop || document.body.scrollTop || 0;
            // console.log('Stored scroll position before modal open:', this.scrollPosition);
            
            // Open modal first
            this.showNavModal = true;
            
            // On mobile, handle positioning after modal is rendered
            if (this.isMobile) {
                this.waitForModalAndPosition();
            } else {
                // For desktop, just block scrolling normally
                this.blockScrolling();
            }
        } catch (e) {
            // eslint-disable-next-line no-console
            // console.error('Error in handleNavigate:', e, event);
        }
    }

     handleRowAction(event) {
        const action = event.detail.action;
        const row = event.detail.row;
        if (action.name === 'navigate') {
            this.selectedAccount = row;
            this.modalAccount = row; // Set the modal account as well
            // console.log('handleRowAction: Selected account:', row.Name, 'ID:', row.Id);
            
            // Store current scroll position BEFORE opening modal
            this.scrollPosition = window.scrollY || window.pageYOffset || document.documentElement.scrollTop || document.body.scrollTop || 0;
            // console.log('Stored scroll position before modal open:', this.scrollPosition);
            
            // Open modal first
            this.showNavModal = true;
            
            // On mobile, handle positioning after modal is rendered
            if (this.isMobile) {
                this.waitForModalAndPosition();
            } else {
                // For desktop, just block scrolling normally
                this.blockScrolling();
            }
        }
    }


    handleGoogleMaps(event) {
        try {
            const account = this.modalAccount || this.selectedAccount;
            if (!account) return;
            const from = (this.userLat && this.userLon) ? `${this.userLat},${this.userLon}` : '';
            const to = (account.BillingLatitude && account.BillingLongitude)
                ? `${account.BillingLatitude},${account.BillingLongitude}` : '';
            let url = '';
            if (to) {
                url = from ? `https://www.google.com/maps/dir/?api=1&origin=${from}&destination=${to}` : `https://www.google.com/maps/dir/?api=1&destination=${to}`;
                if (/Mobi|Android/i.test(navigator.userAgent)) {
                    window.location.href = url;
                } else {
                    window.open(url, '_blank');
                }
            }
        } catch (e) {
            // eslint-disable-next-line no-console
            // console.error('Error in handleGoogleMaps:', e, this.selectedAccount);
        }
    }
    
    handleAppleMaps(event) {
        try {
            const account = this.modalAccount || this.selectedAccount;
            if (!account) return;
            const from = (this.userLat && this.userLon) ? `${this.userLat},${this.userLon}` : '';
            const to = (account.BillingLatitude && account.BillingLongitude)
                ? `${account.BillingLatitude},${account.BillingLongitude}` : '';
            let url = '';
            if (to) {
                url = from ? `https://maps.apple.com/?saddr=${from}&daddr=${to}` : `https://maps.apple.com/?daddr=${to}`;
                if (/Mobi|Android/i.test(navigator.userAgent)) {
                    window.location.href = url;
                } else {
                    window.open(url, '_blank');
                }
            }
        } catch (e) {
            // eslint-disable-next-line no-console
            // console.error('Error in handleAppleMaps:', e, this.selectedAccount);
        }
    }
    closeNavModal() {
        // console.log('Closing modal, current selectedAccount:', this.selectedAccount ? this.selectedAccount.Name : 'null');
        // console.log('Closing modal, current modalAccount:', this.modalAccount ? this.modalAccount.Name : 'null');
        this.showNavModal = false;
        this.modalAccount = null; // Clear modal account
        this.clickPosition = null; // Clear click position
        
        // Reset all modal styles and remove custom classes
        setTimeout(() => {
            const modal = this.template.querySelector('section.slds-modal.slds-fade-in-open');
            if (modal) {
                // Remove mobile positioning class
                modal.classList.remove('mobile-modal-positioned');
                
                // Reset any inline styles that might have been applied
                modal.style.removeProperty('position');
                modal.style.removeProperty('top');
                modal.style.removeProperty('left');
                modal.style.removeProperty('right');
                modal.style.removeProperty('bottom');
                modal.style.removeProperty('zIndex');
                modal.style.removeProperty('margin');
                modal.style.removeProperty('display');
                modal.style.removeProperty('alignItems');
                modal.style.removeProperty('justifyContent');
                modal.style.removeProperty('transform');
                modal.style.removeProperty('paddingTop');
            }
            
            // Also reset backdrop styles
            const backdrop = this.template.querySelector('.slds-backdrop.slds-backdrop_open');
            if (backdrop) {
                backdrop.style.removeProperty('position');
                backdrop.style.removeProperty('top');
                backdrop.style.removeProperty('left');
                backdrop.style.removeProperty('right');
                backdrop.style.removeProperty('bottom');
                backdrop.style.removeProperty('width');
                backdrop.style.removeProperty('height');
                backdrop.style.removeProperty('minWidth');
                backdrop.style.removeProperty('minHeight');
                backdrop.style.removeProperty('maxWidth');
                backdrop.style.removeProperty('maxHeight');
                backdrop.style.removeProperty('zIndex');
                backdrop.style.removeProperty('margin');
                backdrop.style.removeProperty('padding');
                backdrop.style.removeProperty('border');
                backdrop.style.removeProperty('outline');
                backdrop.style.removeProperty('boxSizing');
                backdrop.style.removeProperty('pointerEvents');
            }
            
            // Clean up observers and intervals
            if (this.modalPositionObserver) {
                this.modalPositionObserver.disconnect();
                this.modalPositionObserver = null;
            }
            if (this.modalPositionCheckInterval) {
                clearInterval(this.modalPositionCheckInterval);
                this.modalPositionCheckInterval = null;
            }
            
            this.unblockScrolling(); // Unblock scrolling when modal closes
        }, 10);
    }

    handleMobileModalOpen() {
        if (this.isMobile) {
            // console.log('Mobile detected, applying mobile modal styles...');
            // console.log('Current selectedAccount in handleMobileModalOpen:', this.selectedAccount ? this.selectedAccount.Name : 'null');
            
            // Use the stored scroll position instead of current position
            const targetScrollPosition = this.scrollPosition || 0;
            // console.log('Target scroll position for modal:', targetScrollPosition);
            
            // Block scrolling AFTER modal is positioned
            this.blockScrolling();
            
            // Use a longer delay to ensure modal is fully rendered
            setTimeout(() => {
                const modal = this.template.querySelector('section.slds-modal.slds-fade-in-open');
                const backdrop = this.template.querySelector('.slds-backdrop.slds-backdrop_open');
                // console.log('Modal element found:', modal);
                // console.log('Backdrop element found:', backdrop);
                
                if (modal) {
                    // First, restore the scroll position to where it was when button was clicked
                    window.scrollTo(0, targetScrollPosition);
                    document.documentElement.scrollTop = targetScrollPosition;
                    document.body.scrollTop = targetScrollPosition;
                    
                    // Force remove any existing top positioning from CSS
                    modal.style.removeProperty('top');
                    
                    // Set CSS custom property for top positioning
                    const topPosition = Math.max(0, targetScrollPosition);
                    modal.style.setProperty('--modal-top', `${topPosition}px`);
                    
                    // Position modal in the viewport at the stored scroll position
                    modal.style.setProperty('position', 'fixed', 'important');
                    modal.style.setProperty('top', `${topPosition}px`, 'important');
                    modal.style.setProperty('left', '0', 'important');
                    modal.style.setProperty('right', '0', 'important');
                    modal.style.setProperty('bottom', '0', 'important');
                    modal.style.setProperty('display', 'flex', 'important');
                    modal.style.setProperty('alignItems', 'flex-start', 'important');
                    modal.style.setProperty('justifyContent', 'center', 'important');
                    modal.style.setProperty('zIndex', '9999', 'important');
                    modal.style.setProperty('paddingTop', '20px', 'important');
                    
                    // Ensure backdrop covers the entire screen
                    if (backdrop) {
                        backdrop.style.setProperty('position', 'fixed', 'important');
                        backdrop.style.setProperty('top', '0', 'important');
                        backdrop.style.setProperty('left', '0', 'important');
                        backdrop.style.setProperty('right', '0', 'important');
                        backdrop.style.setProperty('bottom', '0', 'important');
                        backdrop.style.setProperty('width', '100vw', 'important');
                        backdrop.style.setProperty('height', '100vh', 'important');
                        backdrop.style.setProperty('minWidth', '100vw', 'important');
                        backdrop.style.setProperty('minHeight', '100vh', 'important');
                        backdrop.style.setProperty('maxWidth', '100vw', 'important');
                        backdrop.style.setProperty('maxHeight', '100vh', 'important');
                        backdrop.style.setProperty('zIndex', '9998', 'important');
                        backdrop.style.setProperty('margin', '0', 'important');
                        backdrop.style.setProperty('padding', '0', 'important');
                        backdrop.style.setProperty('border', 'none', 'important');
                        backdrop.style.setProperty('outline', 'none', 'important');
                        backdrop.style.setProperty('boxSizing', 'border-box', 'important');
                        backdrop.style.setProperty('pointerEvents', 'auto', 'important');
                    }
                    
                    // Add class for mobile styling
                    modal.classList.add('mobile-modal-positioned');
                    
                    // console.log('Modal positioned in viewport at scroll position:', targetScrollPosition);
                    // console.log('Applied modal styles:', {
                    //     position: modal.style.position,
                    //     top: modal.style.top,
                    //     left: modal.style.left,
                    //     right: modal.style.right,
                    //     bottom: modal.style.bottom,
                    //     zIndex: modal.style.zIndex
                    // });
                    
                    // Set up a MutationObserver to ensure positioning stays correct
                    this.setupModalPositionObserver(modal, topPosition);
                    
                    // Check if mobile styles are applied
                    this.checkMobileStyles();
                } else {
                    // console.error('Modal element not found!');
                }
            }, 200); // Increased delay to ensure modal is fully rendered
        } else {
            // console.log('Desktop detected, using default modal behavior');
        }
    }
    
    blockScrolling() {
        // Don't store scroll position here - it's already stored before modal opens
        
        // Use a less aggressive approach that doesn't change visual position
        document.body.style.overflow = 'hidden';
        document.documentElement.style.overflow = 'hidden';
        
        // Add modal-open class for CSS control
        document.body.classList.add('modal-open');
        document.documentElement.classList.add('modal-open');
        
        // Prevent touch scrolling on mobile without changing position
        document.body.style.touchAction = 'none';
        document.documentElement.style.touchAction = 'none';
        
        // console.log('Scrolling blocked using non-position-changing method');
    }
    
    unblockScrolling() {
        // Restore scroll position and remove blocking styles
        if (this.scrollPosition !== undefined) {
            const savedPosition = this.scrollPosition;
            
            // Remove all blocking styles from body
            document.body.style.overflow = '';
            document.body.style.touchAction = '';
            
            // Remove all blocking styles from html
            document.documentElement.style.overflow = '';
            document.documentElement.style.touchAction = '';
            
            // Remove modal-open class
            document.body.classList.remove('modal-open');
            document.documentElement.classList.remove('modal-open');
            
            // Restore scroll position with multiple attempts to ensure it works
            setTimeout(() => {
                // Try multiple scroll restoration methods
                window.scrollTo(0, savedPosition);
                document.documentElement.scrollTop = savedPosition;
                document.body.scrollTop = savedPosition;
                
                // Double-check and correct if needed
                setTimeout(() => {
                    const currentScroll = window.scrollY || window.pageYOffset || document.documentElement.scrollTop || document.body.scrollTop || 0;
                    if (Math.abs(currentScroll - savedPosition) > 10) {
                        // console.log('Scroll position correction needed:', currentScroll, '->', savedPosition);
                        window.scrollTo(0, savedPosition);
                    }
                }, 50);
                
                // console.log('Scrolling unblocked, restored position:', savedPosition);
            }, 10);
            
            this.scrollPosition = undefined;
        }
    }
    
    checkMobileStyles() {
        setTimeout(() => {
            const modal = this.template.querySelector('section.slds-modal.slds-fade-in-open');
            const container = this.template.querySelector('.slds-modal__container');
            
            if (modal && container) {
                const modalStyles = window.getComputedStyle(modal);
                const containerStyles = window.getComputedStyle(container);
                
                // console.log('Modal computed styles:', {
                //     position: modalStyles.position,
                //     top: modalStyles.top,
                //     width: containerStyles.width,
                //     maxWidth: containerStyles.maxWidth,
                //     height: containerStyles.height,
                //     maxHeight: containerStyles.maxHeight,
                //     hasMobileClass: modal.classList.contains('mobile-modal-positioned')
                // });
            }
        }, 200);
    }
    
    setupModalPositionObserver(modal, targetTopPosition) {
        // Create a MutationObserver to watch for style changes
        const observer = new MutationObserver((mutations) => {
            mutations.forEach((mutation) => {
                if (mutation.type === 'attributes' && mutation.attributeName === 'style') {
                    const currentTop = modal.style.top;
                    const computedTop = window.getComputedStyle(modal).top;
                    
                    // If the top position has been changed by CSS, restore it
                    if (currentTop !== `${targetTopPosition}px` && computedTop !== `${targetTopPosition}px`) {
                        // console.log('Modal position was changed, restoring to:', targetTopPosition);
                        modal.style.setProperty('top', `${targetTopPosition}px`, 'important');
                        modal.style.setProperty('--modal-top', `${targetTopPosition}px`);
                    }
                }
            });
        });
        
        // Start observing the modal for style changes
        observer.observe(modal, {
            attributes: true,
            attributeFilter: ['style']
        });
        
        // Store the observer reference for cleanup
        this.modalPositionObserver = observer;
        
        // Also set up a periodic check as backup
        this.modalPositionCheckInterval = setInterval(() => {
            const currentTop = window.getComputedStyle(modal).top;
            if (currentTop !== `${targetTopPosition}px`) {
                // console.log('Periodic check: Modal position incorrect, fixing to:', targetTopPosition);
                modal.style.setProperty('top', `${targetTopPosition}px`, 'important');
                modal.style.setProperty('--modal-top', `${targetTopPosition}px`);
            }
        }, 100);
    }

    handleRadiusChange(event) {
        let value = event.detail.value;
        const oldValue = this.radius;
        
        if (value === "" || value === null) {
            this.radius = "";
            return;
        }
        if (!isNaN(value) && Number(value) > 0) {
            this.radius = Number(value);
            
            // Log filter change before search
            this.addLogEntryToSession('Filter Change', {
                filterType: 'Radius',
                oldValue: oldValue,
                newValue: this.radius
            });
            
            this.isTableLoading = true;
            this.isMapLoading = true;
            this.handleSearch(true, true);
        }
    }

    get showInitialNote() {
        return !this.userLat && !this.userLon && (!this.accounts || this.accounts.length === 0);
    }

    get mapContainerClass() {
        return this.isLandscapeMode ? 'map-container landscape-mode' : 'map-container';
    }

    get landscapeToggleIcon() {
        return this.isLandscapeMode ? 'utility:collapse_all' : 'utility:expand_all';
    }

    get landscapeToggleAltText() {
        return this.isLandscapeMode ? 'Exit Landscape Mode' : 'Enter Landscape Mode';
    }
    
    // Add a getter to track selected account changes
    get selectedAccountName() {
        return this.modalAccount ? this.modalAccount.Name : (this.selectedAccount ? this.selectedAccount.Name : 'No Account Selected');
    }

    showToast(title, message, variant) {
        const evt = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant
        });
        this.dispatchEvent(evt);
    }

    updateIsMobile() {
        const wasMobile = this.isMobile;
        this.isMobile = window.innerWidth <= 600;
        
        // Reset landscape mode when switching from mobile to desktop
        if (wasMobile && !this.isMobile) {
            this.isLandscapeMode = false;
        }
    }

    handleAccountTypeFilterChange(event) {
        const oldValue = this.accountTypeFilter ? [...this.accountTypeFilter] : [];
        // Ensure we get a proper array
        this.accountTypeFilter = Array.isArray(event.detail.value) ? event.detail.value : [event.detail.value];
        
        // Log filter change
        this.addLogEntryToSession('Filter Change', {
            filterType: 'Account Type',
            oldValue: oldValue,
            newValue: this.accountTypeFilter
        });
        
        // Check if this is a pill removal (fewer items than before)
        const isPillRemoval = this.accountTypeFilter.length < oldValue.length;
        
        if (isPillRemoval) {
            // Search immediately on pill removal
        this.handleSearch(true, true);
        } else {
            // For selections, also search immediately to update owner filters
            this.handleSearch(true, true);
        }
    }

    handleOwnerFilterChange(event) {
        const oldValue = this.ownerFilter ? [...this.ownerFilter] : [];
        // Ensure we get a proper array
        this.ownerFilter = Array.isArray(event.detail.value) ? event.detail.value : [event.detail.value];
        
        // Log filter change
        this.addLogEntryToSession('Filter Change', {
            filterType: 'Owner',
            oldValue: oldValue,
            newValue: this.ownerFilter
        });
        
        // Check if this is a pill removal (fewer items than before)
        const isPillRemoval = this.ownerFilter.length < oldValue.length;
        
        if (isPillRemoval) {
            // Search immediately on pill removal
            this.handleSearch(true, true);
        }
        // For selections, don't search immediately - wait for dropdown to close
    }

    handleAccountTypeSearchTrigger(event) {
        // Search when dropdown closes
        this.handleSearch(true, true);
    }

    handleOwnerSearchTrigger(event) {
        // Search when dropdown closes
        this.ownerDropdownOpen = false;
        this.handleSearch(true, true);
    }

    handleOwnerDropdownOpen(event) {
        // Track when dropdown opens
        this.ownerDropdownOpen = true;
    }

    toggleLandscapeMode() {
        this.isLandscapeMode = !this.isLandscapeMode;
        // Force a re-render of the map to adjust to new dimensions
        setTimeout(() => {
            this.calculateZoomLevel();
        }, 100);
    }

    // Add this new method to robustly wait for the modal to be rendered before positioning
    waitForModalAndPosition() {
        const tryPosition = (attempts = 0) => {
            const modal = this.template.querySelector('section.slds-modal.slds-fade-in-open');
            if (modal) {
                // console.log('Modal found, current selectedAccount:', this.selectedAccount ? this.selectedAccount.Name : 'null');
                
                // Double-check that we still have the correct account selected
                if (!this.selectedAccount) {
                    // console.error('selectedAccount is null when modal is found!');
                    return;
                }
                
                this.handleMobileModalOpen();
            } else if (attempts < 10) {
                setTimeout(() => tryPosition(attempts + 1), 50);
            } else {
                // console.warn('Modal did not appear after waiting.');
            }
        };
        tryPosition();
    }

    // Device detection method
    detectDeviceType() {
        if (formFactor === 'Large') {
            this.deviceType = 'Desktop';
        } else if (formFactor === 'Medium') {
            this.deviceType = 'Tablet';
        } else if (formFactor === 'Small') {
            this.deviceType = 'Mobile';
        } else {
            this.deviceType = 'Unknown';
        }
    }

    // Create session log
    createSessionLog() {
        const sessionData = {
            deviceType: this.deviceType,
            formFactor: formFactor,
            userAgent: navigator.userAgent,
            timestamp: new Date().toISOString()
        };
        
        createUserSession({ sessionData: sessionData })
            .then(logId => {
                this.sessionLogId = logId;
                console.log('Session log created with ID:', logId);
            })
            .catch(error => {
                console.error('Error creating session log:', error);
            });
    }

    // Helper method to add log entries
    addLogEntryToSession(action, details) {
        if (this.sessionLogId) {
            addLogEntryToSession({ 
                sessionLogId: this.sessionLogId,
                action: action, 
                details: details 
            }).catch(error => {
                console.error('Error adding log entry:', error);
            });
        } else {
            console.warn('Session log ID not available, skipping log entry');
        }
    }
}