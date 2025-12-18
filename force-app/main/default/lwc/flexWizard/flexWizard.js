import { LightningElement, wire,track,api } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';
import amendContracts from '@salesforce/apex/FlexAccountCancelReplaceController.flexAmendContracts';
import getAmendmentOpportunities from '@salesforce/apex/flex_OpenAmendmentOpportunityController.getAmendmentOpportunities';
import getDefaultPricebookId from '@salesforce/apex/FlexContractConsolidation.getDefaultPricebookId';
const FIELDS = ['Account.Name', 'Account.P_P_Pilot_Customer__c'];
import getSubscriptionsByProductAndAddress from '@salesforce/apex/FlexContractConsolidation.getSubscriptionsByProductAndAddress';
import reinitiateProcess from '@salesforce/apex/FlexCancelReplaceHelper.reinitiateProcess';
import hasPermissionSet from '@salesforce/apex/FlexCancelReplaceHelper.hasPermissionSet'
export default class FlexWizard extends NavigationMixin(LightningElement) {
    @api accountId;
    baseURL =window.location.origin;
    @track currentStep = 1;
    @track selectedContracts = [];
    @track hasProLicenseProduct = false;
    @track controlCenterConfigId;
    @track contractsWithOpenAmends = [];
    @track selectedProducts = [];
    @track selectedUpgrades = [];
    @track isLoading = true;
    @track configData;
    @track account = {};
    @track isSubmittedSuccess = false;
    @track isSubmittedFailed = false;
    @track isStartDateEmpty = false;
    @track userSelectedTermMonths;
    @track selectedConfig;
    @track amendmentOpportunities = [];
    @track cachedStartDate;
    @track cachedBookingType;
    @track disableNextBtn;
    @track hasErrorForQuantity ;
    @track hasErrorForProduct ;
    @track pnpBoolean = false;
    @track subscriptionData ;
    @track cachedSubscriptionData;
    @track subscriptionDataNew;
    @track ineligibleProductList;
    // @track selectedContractIds;
    @track finalConfirmationScreenJson;
    @track priceBookId;
    @track screenOneToggleOffData;
    @track screenOneToggleOnData;
    @track tempIds;
    @track pnpOneData;
    @track pnpTwoData;
    @track toggleButton ;
    @track ineligibleBannerBoolean ;
    @track overrideContractsIds;
    @track disableSubmitButton = false;
    pnpBoolean1 = false;
    steps = [];
    hasReinitiateAccess = false;
    showCnrReinitiatePopup = false;
    disableBackButton = false;

    handleReInitiateTrigger()
    {
        this.showCnrReinitiatePopup = true;
    }
    get showReinitiateButton()
    {
        return this.isStepOne && this.hasReinitiateAccess;
    }
    handleGroupSelected(event) {
        const groupId = event.detail.groupId;
        console.log('Received Group ID from child:', groupId);

        reinitiateProcess({ groupId })
        .then((result) => {
            console.log('Apex result:', result);
            const configDataObject = JSON.parse(result.configData);
            const selectedContractsObject = JSON.parse(result.selectedContracts);
            this.userSelectedTermMonths = configDataObject.termMonths;
            this.configData = configDataObject;
            this.finalConfirmationScreenJson = result.quoteLineData;
            this.currentStep = this.pnpBoolean1 ? 5 : 4;
            this.selectedContracts = selectedContractsObject;
            this.disableBackButton = true;
            this.closeReinitiateCnrPopup();
        })
        .catch((error) => {
            console.error('Error from Apex:', error);
            // Optionally show toast here
        });
    }
    closeReinitiateCnrPopup() {
        this.showCnrReinitiatePopup = false;
    }

    handleOverrideContractIds(event){
        // this.contractIds = 
        try {
            console.log('overridden contractIds  ', event.detail.overrideContractIds);
        
        // this.selectedContracts = event.detail.overrideContractIds.split(',');
        this.overrideContractsIds =event.detail.overrideContractIds.split(',');
        } catch (error) {
            console.log('Error in wizard ',error.message);
            
        }
        
    }



    // pnp screen One persist logic - manglesh 
    handlePnpOneDataDispatchOne(event){
        this.pnpOneData = event.detail.pnpOneData;
        this.pnpTwoData = undefined;
        this.toggleButton = event.detail.toggle;
        console.log('TTMM handlePnpOneData: test', JSON.stringify(this.pnpOneData));
    }
    handlePnpTwoDataFromSelectAllDispatch(event){
        this.pnpTwoData = event.detail.pnpTwoData;
        console.log('asdadsa TTMM handlePnpTwoData:', JSON.stringify(this.pnpTwoData));
    }
    
    

    handleBannerChange(event){
        this.ineligibleBannerBoolean = event.detail.ineligibleToProductSelection;
        console.log('TTMM handleBannerChange:', JSON.stringify(this.ineligibleBannerBoolean));

    }
    
    handlePnpOneToggleDispatch(event){
        console.log('toggle test',event.detail.toggle);
        this.pnpOneData = event.detail.pnpOneData;
        this.toggleButton = event.detail.toggle;
    }

    handleScreenOneToggleOffData(event){
        this.screenOneToggleOffData = event.detail.subscriptionDataWhenToggleOff;
        console.log('TTMM handleScreenOneToggleOffData:', JSON.stringify(this.screenOneToggleOffData));
    }

    
    handleScreenOneToggleOnData(event){
        this.screenOneToggleOnData = event.detail.subscriptionDataWhenToggleOn;
        console.log('TTMM handleScreenOneToggleOn Data:', JSON.stringify(this.screenOneToggleOnData));
    }


    handleCurrentScreen(event)
    {
        console.log('event.detail.ineligibleToProductSelection',event.detail.ineligibleToProductSelection);
        
        const tempIds = event.detail.tempIds;
        this.ineligibleBannerBoolean = event.detail.ineligibleToProductSelection;
        this.tempIds = tempIds;
        this.subscriptionData = this.template.querySelector('c-flex-product-replacement-info').subscriptionData;
        console.log('tempIds: legacy', JSON.stringify(this.tempIds), this.ineligibleBannerBoolean);
        
    }

    handlePnpCurrentScreen(event){
        const tempIds = event.detail.tempIds;
        
        this.tempIds = tempIds;
        this.subscriptionData = this.template.querySelector('c-flex-pn-p-license-upgrade').subscriptionData;
        console.log('tempIds: pnp', JSON.stringify(this.tempIds),this.ineligibleBannerBoolean );
    }

    @wire(getRecord, { recordId: '$accountId', fields: FIELDS })
    handleAccountData({ errors, data }) {
        if (data) {
            this.account = { data };  // Store the data for the getters to use
            this.pnpBoolean1 = data.fields.P_P_Pilot_Customer__c.value;
            console.log('TTMM account:', this.pnpBoolean1);
            this.steps = this.pnpBoolean1 ? [
                { label: 'Contract Selection', value: 1 },
                { label: 'Replacement Opportunity Info', value: 2 },
                { label: 'Product Mapping', value: 3 },
                { label: 'Hardware Upgrade', value: 4 },
                { label: 'Verify and Submit', value: 5 }
            ] : [
                { label: 'Contract Selection', value: 1 },
                { label: 'Replacement Opportunity Info', value: 2 },
                { label: 'Product Mapping', value: 3 },
                { label: 'Verify and Submit', value: 4 }
            ];
            this.updateStepClasses();
        } else if (errors) {
            this.account = { errors };  // Store the errors for the getters to use
            console.error('Error fetching account data:', errors);
        }
    }
    
    // @track steps = this.pnpBoolean1 == true ? [
    //     { label: 'Contract Selection', value: 1 },
    //     { label: 'Replacement Opportunity Info', value: 2 },
    //     { label: 'Product Mapping', value: 3 },
    //     { label: 'Hardware Upgrade', value: 4 },
    //     { label: 'Verify and Submit', value: 5 }
    // ] : [
    //     { label: 'Contract Selection', value: 1 },
    //     { label: 'Replacement Opportunity Info', value: 2 },
    //     { label: 'Product Mapping', value: 3 },
    //     { label: 'Verify and Submit', value: 4 }
    // ];
    get contractsWithOpenAmendsSize(){
        return this.contractsWithOpenAmends.length;
    }
    get accountName() {
        return this.account.data ? this.account.data.fields.Name.value : '';   
    }
    get accountPilotCustomer() {
        this.pnpBoolean = this.pnpBoolean1;
        // this.pnpBoolean = this.pnpBoolean1;
        // console.log('TTMM accountPilotCustomer:', this.pnpBoolean1);
        // this.steps = this.pnpBoolean1 == true ? [
        //     { label: 'Contract Selection', value: 1 },
        //     { label: 'Replacement Opportunity Info', value: 2 },
        //     { label: 'Product Mapping', value: 3 },
        //     { label: 'Hardware Upgrade', value: 4 },
        //     { label: 'Verify and Submit', value: 5 }
        // ] : [
        //     { label: 'Contract Selection', value: 1 },
        //     { label: 'Replacement Opportunity Info', value: 2 },
        //     { label: 'Product Mapping', value: 3 },
        //     { label: 'Verify and Submit', value: 4 }
        // ];
        
        return this.account.data? this.account.data.fields.P_P_Pilot_Customer__c.value :'';
    }
    get selectedProductIds() {
        return this.selectedProducts.map(product => product.id);
    }

    get isStepOne() { return this.currentStep === 1; }
    get isStepTwo() { return this.currentStep === 2; }
    get isStepThree() { return this.currentStep === 3; }
    get isStepThreeA() { return this.currentStep === 3; }
    get isStepThreeB() { return this.currentStep === 4; }
    get isStepFour() {  
        console.log('is step four called');
        return this.account.data && !this.pnpBoolean1?this.currentStep === 4 :this.currentStep === 5 }
    get isFirstStep() { return this.currentStep === 1; }
    get isLastStep() { 
        // Ensure we're using the correct last step based on the flow type
        const lastStep = this.pnpBoolean1 ? 5 : 4;
        return this.currentStep === lastStep;
    }
    get isSubmitted() { 
        // Ensure we're using the correct submitted step based on the flow type
        const submittedStep = this.pnpBoolean1 ? 6 : 5;
        return this.currentStep === submittedStep;
    }
    get showSelectedContracts() { 
        // Use the correct step numbers based on the flow type
        const submittedStep = this.pnpBoolean1 ? 6 : 5;
        return this.currentStep != 1 && this.currentStep != submittedStep;
    }
    get showOppInfo() { 
        // Use the correct step numbers based on the flow type
        const lastStep = this.pnpBoolean1 ? 5 : 4;
        const submittedStep = this.pnpBoolean1 ? 6 : 5;
        return this.currentStep != 1 && this.currentStep != 2 && this.currentStep != lastStep && this.currentStep != submittedStep;
    }
    get isNextDisabled() { return (this.isStartDateEmpty || (this.contractsWithOpenAmends && this.contractsWithOpenAmends.length > 0)) ? true : false; }
    get nextButtonLabel() { return this.isLastStep ? 'Submit' : 'Next'; }
    get backButtonLabel() { return this.isFirstStep ? 'Cancel' : 'Back'; }

    handlePnpStepOneSubscriptionData(event){
        if(this.pnpBoolean1){    
            // this.subscriptionData = event.detail.subscriptionData;
        }
    }
    handleStartDateChange(event) {
        this.cachedStartDate = event.detail.startDate;
    }
    handleBooinTypeChange(event){
        this.cachedBookingType = event.detail.bookingType;   
    }


    
    checkUserPermissionSet(permissionSetName) {
        hasPermissionSet({ permissionSetName: permissionSetName })
            .then(result => {
                // Store result in reactive variable
                this.hasReinitiateAccess = result;
                console.log('Has ' + permissionSetName + ' permission: ' + this.hasReinitiateAccess);
            })
            .catch(error => {
                console.error('Error checking permission:', error);
            });
    }

    connectedCallback() {
        this.checkUserPermissionSet('Flex_CnR_Reinitiate_Access');
        // Ensure currentStep is initialized
        if (this.currentStep === undefined || this.currentStep === null) {
            this.currentStep = 1;
        }
        
        console.log('TTMM pnpBoolean1:', this.pnpBoolean1);
        console.log('TTMM connectedCallback - currentStep:', this.currentStep);
        this.updateStepClasses();
        getDefaultPricebookId()
            .then(result => {
                this.priceBookId = result;
            })
            .catch(error => {
                console.error('Error loading pricebook ID:', error);
            });
    }

    handleProductSelectionChange(event){
        this.subscriptionDataNew = event.detail;
    }    
    isDateEmpty = false;
    isDateError = false;
    handleDateEmpty(event) { this.isDateEmpty = event.detail; }
    handleDateError(event) { this.isDateError = event.detail; }
    handleComponentLoad() { this.isLoading = false; }   

    updateStepClasses() {
        // Ensure currentStep is always defined
        if (this.currentStep === undefined || this.currentStep === null) {
            this.currentStep = 1;
        }
        
        console.log('TTMM updateStepClasses - currentStep:', this.currentStep);
        
        if(this.account.data && this.pnpBoolean1 && this.currentStep === 4){
            // Special case handling
        } else {
            this.steps = this.steps.map(step => ({
                ...step,
                className: this.getStepClassName(step.value)
            }));
        }
    }
    
    get contractIds() {
        if (this.selectedContracts) {    
            if (this.overrideContractsIds !== undefined) {
                return JSON.parse(JSON.stringify(this.overrideContractsIds));
            } else {
                console.log('contractIdss getter called');
                // this.selectedContractIds = this.selectedContracts.map(sc => sc.Id);
                return [...this.selectedContracts.map(sc => sc.Id)];
            }        
        }
        return [];        
    }
    getStepClassName(stepValue) {
        let baseClasses = 'slds-path__item';
        if (stepValue < this.currentStep) { baseClasses += ' slds-is-complete'; } 
        else if (stepValue === this.currentStep) { baseClasses += ' slds-is-current slds-is-active'; } 
        else { baseClasses += ' slds-is-incomplete'; }
        return baseClasses;
    }

    validateSkuHierarchy(subscriptionData) {
        console.log('TTMM validateSkuHierarchy - selectedConfig:', JSON.stringify(this.selectedConfig));
        console.log('TTMM validateSkuHierarchy - Bypass_SKU_Hierarchy_Validation__c value:', this.selectedConfig?.Bypass_SKU_Hierarchy_Validation__c);
        console.log('TTMM validateSkuHierarchy - Bypass_SKU_Hierarchy_Validation__c type:', typeof this.selectedConfig?.Bypass_SKU_Hierarchy_Validation__c);
        
        // Check if SKU hierarchy validation is bypassed in Control Center Config
        if (this.selectedConfig?.Bypass_SKU_Hierarchy_Validation__c) {
            console.log('TTMM validateSkuHierarchy - Bypassing SKU validation due to config setting');
            return { isValid: true };
        }

        // Extract products that will proceed to next screen (both selected and auto-proceeding)
        const proceedingProducts = subscriptionData.reduce((acc, parent) => {
            // Check if parent product is selected or auto-proceeding
            if (parent.pnpOneProductDetails?.selectedProductId) {
                // Selected product case
                const selectedProduct = parent.availableProducts?.find(p => p.Id === parent.pnpOneProductDetails.selectedProductId);
                if (selectedProduct) {
                    acc.push({...selectedProduct, parentId: parent.productId});
                }
            } else if (!parent.pnpOneProductDetails?.togglePnp) {
                // Auto-proceeding case when toggle is off
                const originalProduct = parent.availableProducts?.find(p => p.Id === parent.productId);
                if (originalProduct) {
                    acc.push({...originalProduct, parentId: parent.productId});
                }
            }
            
            // Check products in subscription wrappers
            if (parent.subscriptionWrappers) {
                parent.subscriptionWrappers.forEach(wrapper => {
                    if (wrapper.pnpOneProductDetails?.selectedProductId) {
                        // Selected product case
                        const selectedProduct = wrapper.availableProducts?.find(p => p.Id === wrapper.pnpOneProductDetails.selectedProductId);
                        if (selectedProduct) {
                            acc.push({...selectedProduct, parentId: parent.productId});
                        }
                    } else if (!wrapper.pnpOneProductDetails?.togglePnp) {
                        // Auto-proceeding case when toggle is off
                        const originalProduct = wrapper.availableProducts?.find(p => p.Id === wrapper.productId);
                        if (originalProduct) {
                            acc.push({...originalProduct, parentId: parent.productId});
                        }
                    }
                });
            }
            return acc;
        }, []);

        console.log('TTMM proceedingProducts', proceedingProducts);

        // Group products by family and check their hierarchies
        const safetyProducts = proceedingProducts.filter(product => 
            product.Family === 'Safety' && 
            product.License_Type__c === 'Tier'
        );
        
        const telematicsProducts = proceedingProducts.filter(product => 
            product.Family === 'Telematics' && 
            product.License_Type__c === 'Tier'
        );

        console.log('TTMM safetyProducts', safetyProducts);
        console.log('TTMM telematicsProducts', telematicsProducts);

        let validationErrors = [];

        // Check Safety products hierarchy
        if (safetyProducts.length > 1) {
            // Get all unique SKU hierarchies
            const safetyHierarchies = new Set(safetyProducts.map(p => p.Flex_SKU_Hierarchy__c));
            console.log('TTMM safetyHierarchies', safetyHierarchies);

            // If there's more than one hierarchy level, check if they're all at the same level
            if (safetyHierarchies.size > 1) {
                // Get the maximum hierarchy level
                const maxHierarchy = Math.max(...safetyHierarchies);
                
                // Check if all products are at the maximum hierarchy level
                const productsNotAtMaxHierarchy = safetyProducts.filter(p => p.Flex_SKU_Hierarchy__c !== maxHierarchy);
                
                if (productsNotAtMaxHierarchy.length > 0) {
                    validationErrors.push({
                        type: 'Safety',
                        message: 'Safety products must be on the same hierarchy level',
                        bannerMessage: 'The License hierarchy across upgraded "Safety" products is not correct. If there more than one Safety products they all have to be on the same hierarchy: either Essential, Premier or Enterprise',
                        products: productsNotAtMaxHierarchy.map(p => ({
                            id: p.Id,
                            name: p.Name,
                            hierarchy: p.Flex_SKU_Hierarchy__c,
                            parentId: p.parentId
                        }))
                    });
                }
            }
        }

        // Check Telematics products hierarchy
        if (telematicsProducts.length > 1) {
            // Get all unique SKU hierarchies
            const telematicsHierarchies = new Set(telematicsProducts.map(p => p.Flex_SKU_Hierarchy__c));
            console.log('TTMM telematicsHierarchies', telematicsHierarchies);

            // If there's more than one hierarchy level, check if they're all at the same level
            if (telematicsHierarchies.size > 1) {
                // Get the maximum hierarchy level
                const maxHierarchy = Math.max(...telematicsHierarchies);
                
                // Check if all products are at the maximum hierarchy level
                const productsNotAtMaxHierarchy = telematicsProducts.filter(p => p.Flex_SKU_Hierarchy__c !== maxHierarchy);
                
                if (productsNotAtMaxHierarchy.length > 0) {
                    validationErrors.push({
                        type: 'Telematics',
                        message: 'Telematics products must be on the same hierarchy level',
                        bannerMessage: 'The License hierarchy across upgraded "Telematics" products is not correct. If there are more than one Telematics products they all have to be on the same hierarchy: either Essential, Essential-Plus, Premier or Enterprise',
                        products: productsNotAtMaxHierarchy.map(p => ({
                            id: p.Id,
                            name: p.Name,
                            hierarchy: p.Flex_SKU_Hierarchy__c,
                            parentId: p.parentId
                        }))
                    });
                }
            }
        }

        if (validationErrors.length > 0) {
            return { 
                isValid: false, 
                errors: validationErrors
            };
        }

        return { isValid: true };
    }

    async handleNext() {
        // Ensure currentStep is defined
        if (this.currentStep === undefined || this.currentStep === null) {
            this.currentStep = 1;
        }
        
        const flexAdminOverrideCard = this.template.querySelector('c-flex-admin-override-card');
        if (flexAdminOverrideCard) {
            const jsonData = flexAdminOverrideCard.jsonData;
            console.log('Fetched jsonData from flexAdminOverrideCard:', jsonData,flexAdminOverrideCard);
        }

        console.log('TTMM handleNext - currentStep before:', this.currentStep);
        
        if (!this.isStepOne && this.currentStep > 1) {
            if (this.isDateEmpty) {
                // this.showToast('Error', 'Please select an Opportunity Close Date.', 'error');
                // return;
            }
            if (this.isDateError) {
                this.showToast('Error', 'Opportunity Close Date cannot be greater than End Date.', 'error');
                return;
            }
            if (this.configData?.startDate) {
                const selectedDate = new Date(this.configData.startDate + 'T00:00:00');
                const today = new Date();
                today.setHours(0, 0, 0, 0);
                if (selectedDate < today) {
                    this.showToast('Error', 'Opportunity Close Date cannot be in the past', 'error');
                    return;
                }
            }
            if (this.isStepThreeA && this.pnpBoolean1) {
                try {
                    this.isLoading = true;

                    if(this.pnpOneData){
                        this.subscriptionData = JSON.parse(JSON.stringify(this.pnpOneData));
                    }
                    console.log('TTMM sub data at handle next ',JSON.stringify(this.subscriptionData));
                    console.log('TTMM pnpOne data at handle next ',JSON.stringify(this.pnpOneData));

                    // Validate SKU hierarchy before proceeding
                    const hierarchyValidation = this.validateSkuHierarchy(this.subscriptionData);
                    console.log('TTMM hierarchyValidation',JSON.stringify(hierarchyValidation));
                    if (!hierarchyValidation.isValid) {
                        // Get the PnP component and pass the validation errors
                        const pnpComponent = this.template.querySelector('c-flex-pn-p-license-upgrade');
                        if (pnpComponent) {
                            pnpComponent.setValidationErrors(hierarchyValidation.errors);
                        }
                        
                        this.showToast('Error', hierarchyValidation.errors[0].bannerMessage, 'error');
                        this.isLoading = false;
                        return;
                    }

                    this.subscriptionData = this.subscriptionData.map((parent, index) => {
                        let availableProducts = parent.availableProducts || [];
                        const singleProductInProductOptionsBoolean = availableProducts.length >= 1;
                        const originalProduct = singleProductInProductOptionsBoolean ? availableProducts.find((data)=> data.Id === parent.productId ):[]
                        return {
                            ...parent,
                            productLink: `${this.baseURL}/${parent.productId}`,
                            isExpanded: true,
                            pnpOneProductDetails: {
                                
                                togglePnp: this.togglePnP,
                                selectedProductId: !parent.pnpOneProductDetails.selectedProductId? singleProductInProductOptionsBoolean ? originalProduct.Id : '':parent.pnpOneProductDetails.selectedProductId,
                                selectedProductName:!parent.pnpOneProductDetails.selectedProductName? singleProductInProductOptionsBoolean ? originalProduct.Name : '':parent.pnpOneProductDetails.selectedProductName,
                                selectedProductCode:!parent.pnpOneProductDetails.selectedProductCode? singleProductInProductOptionsBoolean ? `SKU: ${originalProduct.ProductCode}` : '':parent.pnpOneProductDetails.selectedProductCode,
                                selectedProductUrl: !parent.pnpOneProductDetails.selectedProductUrl?singleProductInProductOptionsBoolean ? `${this.baseURL}/${originalProduct.Id}` : '':parent.pnpOneProductDetails.selectedProductUrl
                            },
                            rowNumber: index + 1,
                            expandSymbol: 'utility:dash',
                            isSelectedForReplacement: false,
                            disableInputControls: true,
                            replacementQuantity: '',
                            availableProducts: availableProducts,
                            availableProductOptions: this.convertProductsToOptions(availableProducts),
                            singleProductInProductOptionsBoolean: singleProductInProductOptionsBoolean,
                            subscriptionWrappers: (parent.subscriptionWrappers || []).map(child => {
                                const childAvailableProducts = child.availableProducts || []; 
                                const childSingleProductInProductOptionsBoolean = childAvailableProducts.length >= 1;
                                const originalProduct = singleProductInProductOptionsBoolean ? availableProducts.find((data)=> data.Id === child.productId ):[]
                                return {
                                    ...child,
                                    pnpOneProductDetails: {
                                        togglePnp: this.togglePnP,
                                        selectedProductId: !child.pnpOneProductDetails.selectedProductId?childSingleProductInProductOptionsBoolean ? originalProduct.Id : '':child.pnpOneProductDetails.selectedProductId,
                                        selectedProductName: !child.pnpOneProductDetails.selectedProductName?childSingleProductInProductOptionsBoolean ? originalProduct.Name : '':child.pnpOneProductDetails.selectedProductName,
                                        selectedProductCode:!child.pnpOneProductDetails.selectedProductCode? childSingleProductInProductOptionsBoolean ? originalProduct.ProductCode : '':child.pnpOneProductDetails.selectedProductCode,
                                        selectedProductUrl: !child.pnpOneProductDetails.selectedProductUrl?childSingleProductInProductOptionsBoolean ? `${this.baseURL}/${originalProduct.Id}` : '':child.pnpOneProductDetails.selectedProductUrl
                                    },
                                    uniqueId: child.productId + '-' + child.shippingAddressId,
                                    isSelectedForReplacement: false,
                                    isProductNotReplaceable: true,
                                    disableInputControls: true,
                                    shippingAddressLink: `${this.baseURL}/${child.shippingAddressId}`,
                                    replacementQuantity: '',
                                    availableProducts: childAvailableProducts,
                                    availableProductOptions: this.convertProductsToOptions(childAvailableProducts),
                                    singleProductInProductOptionsBoolean: childSingleProductInProductOptionsBoolean
                                };
                            })
                        };
                    });

                    console.log('TTMM subscriptionData handlenext ',JSON.stringify(this.subscriptionData));

                    let hasUnselectedProducts = true;
                    const pnpComponent = this.template.querySelector('c-flex-pn-p-license-upgrade');
                    if (pnpComponent) {
                        const togglePnP = pnpComponent.togglePnPValue;

                        if (togglePnP) {
                            hasUnselectedProducts = this.subscriptionData.some(data =>
                                !data.pnpOneProductDetails.selectedProductId ||
                                data.pnpOneProductDetails.selectedProductName === 'Select License Upgrade Product'
                            );

                            if (hasUnselectedProducts) {
                                this.showToast('Error', 'Please select a License Upgrade Product for each item to continue.', 'error');
                            }
                        }
                    }
                    if (pnpComponent.togglePnPValue) {
                        if (!hasUnselectedProducts) {
                            let productIds = this.subscriptionData.map(wrapper => wrapper.pnpOneProductDetails.selectedProductId);
                            console.log('TTMM override contract ids ', this.contractIds);
                            console.log('TTDD productIds:', JSON.stringify(productIds));
                            
                            

                           
                            if(this.pnpTwoData === undefined){
                                const result = await getSubscriptionsByProductAndAddress({
                                    contractIdList: this.contractIds,
                                    priceBookId: this.priceBookId,
                                    accountPilotCustomer: this.pnpBoolean1,
                                    togglePnP: false,
                                    productIdsFromPnpOne: productIds
                                });
                                console.log('TTDD result:', JSON.stringify(result));

                                this.subscriptionData.forEach(wrapper => {
                                    const matchingResult = result.find(result => result.productId === wrapper.pnpOneProductDetails.selectedProductId);
                                    wrapper.availableProducts = matchingResult?.availableProducts;
                                    wrapper.availableProductOptions = matchingResult?.availableProducts.map(product => ({
                                        label: product.Name,
                                        value: product.Id
                                    }));
                                    wrapper.subscriptionWrappers.forEach(detail => {
                                        detail.availableProducts = matchingResult?.availableProducts;
                                        detail.availableProductOptions = matchingResult?.availableProducts.map(product => ({
                                            label: product.Name,
                                            value: product.Id
                                        }));

                                        return detail;
                                    });
                                    return wrapper;
                                });

                            }else{
                                this.subscriptionData = [...this.pnpTwoData]
                            }
                            
                        }
                    } else {
                        this.subscriptionData = this.subscriptionData.map((parent) => {
                            return {
                                ...parent,
                                pnpOneProductDetails: {
                                    selectedProductId: parent.pnpOneProductDetails.selectedProductId ? parent.pnpOneProductDetails.selectedProductId : parent.productId,
                                    selectedProductName: parent.pnpOneProductDetails.selectedProductName ? parent.pnpOneProductDetails.selectedProductName : parent.productName,
                                    selectedProductCode: parent.pnpOneProductDetails.defaultHardwareCode ? parent.pnpOneProductDetails.defaultHardwareCode : parent.defaultHardwareCode,
                                    defaultHardwareCodeURL : `${this.baseURL}/${parent.defaultHardware}`,
                                    defaultHardwareId: parent.defaultHardware,
                                    selectedProductUrl: parent.pnpOneProductDetails.selectedProductUrl ? parent.pnpOneProductDetails.selectedProductUrl : `${this.baseURL}/${parent.productId}`
                                },
                                subscriptionWrappers: parent.subscriptionWrappers.map(child => {
                                    return {
                                        ...child,
                                        pnpOneProductDetails: {
                                            selectedProductId: child.pnpOneProductDetails.selectedProductId ? child.pnpOneProductDetails.selectedProductId : child.productId,
                                            selectedProductName: child.pnpOneProductDetails.selectedProductName ? child.pnpOneProductDetails.selectedProductName : child.productName,
                                            selectedProductCode: child.pnpOneProductDetails.defaultHardwareCode ? child.pnpOneProductDetails.defaultHardwareCode : child.defaultHardwareCode,
                                            defaultHardwareCodeURL : `${this.baseURL}/${child.defaultHardware}`,
                                            defaultHardwareId: child.defaultHardware,

                                            selectedProductUrl: child.pnpOneProductDetails.selectedProductUrl ? child.pnpOneProductDetails.selectedProductUrl : `${this.baseURL}/${child.productId}`,
                                        },
                                    };
                                })
                            };
                        });

                        let productIds = this.subscriptionData.map(wrapper => wrapper.pnpOneProductDetails.selectedProductId);
                        console.log('TTMM override contract ids two ', this.contractIds);
                        console.log('TTDD productIds:', JSON.stringify(productIds));

                        if(this.pnpTwoData === undefined){
                            const result = await getSubscriptionsByProductAndAddress({
                                contractIdList: this.contractIds,
                                priceBookId: this.priceBookId,
                                accountPilotCustomer: this.pnpBoolean1,
                                togglePnP: false,
                                productIdsFromPnpOne: productIds
                            });
                            console.log('TTDD result: else', JSON.stringify(result));

                            this.subscriptionData.forEach(wrapper => {
                                const matchingResult = result.find(result => result.productId === wrapper.pnpOneProductDetails.selectedProductId);
                                wrapper.availableProducts = matchingResult?.availableProducts?matchingResult?.availableProducts:[];
                                wrapper.availableProductOptions = matchingResult?.availableProducts?matchingResult?.availableProducts.map(product => ({
                                    label: product.Name,
                                    value: product.Id
                                })) :[];
                                wrapper.subscriptionWrappers.forEach(detail => {
                                    detail.availableProducts = matchingResult?.availableProducts?matchingResult?.availableProducts:[];
                                    detail.availableProductOptions = matchingResult?.availableProducts?matchingResult?.availableProducts.map(product => ({
                                        label: product.Name,
                                        value: product.Id
                                    })):[];

                                    return detail;
                                });
                                return wrapper;
                            });

                        }else{
                            this.subscriptionData = [...this.pnpTwoData];
                        }
                    }

                    this.pnpTwoData =[...this.subscriptionData];
                   
                } catch (error) {
                    this.errorMessage = error.message;    
                    console.log('TTMM error loading ',error.message);
                    
                } finally {
                    this.isLoading = false;
                }
            }
        }
        if (this.validateCurrentStep()) {
            if (this.isLastStep) {
                this.isLoading = true;
                await this.handleSubmit();
            } else {
                // Use the correct maximum step based on whether it's a PnP or legacy flow
                const maxStep = this.pnpBoolean1 ? 5 : 4;
                if (this.currentStep < maxStep) {
                    this.currentStep++;
                    console.log('TTMM handleNext - currentStep after increment:', this.currentStep);
                    this.updateStepClasses();
                }
            }
        }
    }

    convertProductsToOptions(products) {

        const productsArray = products || [];
        if (!Array.isArray(productsArray)) {
            return [];
        }
        const options = productsArray
            .filter(product => product && product.Name && product.Id)
            .map(product => ({
                label: product.Name,
                value: product.Id
            }));
        return options;
    }
    handleGoToAccount() {
            this[NavigationMixin.Navigate]({
                type: 'standard__recordPage',
                attributes: {
                    recordId: this.accountId,
                    objectApiName: 'Account',
                    actionName: 'view'
                }
            }, true); 
    }
    handleBack() {
        // Ensure currentStep is defined
        if (this.currentStep === undefined || this.currentStep === null) {
            this.currentStep = 1;
        }
        
        console.log('TTMM handleBack - currentStep before:', this.currentStep);

        if(this.isStepThreeB && this.pnpBoolean1){
            const pnpComponent = this.template.querySelector('c-flex-pn-p-license-upgrade');
            this.pnpOneData = this.pnpOneData.map(parent => {
                return {
                    ...parent,
                    validationMessage:'',
                    hasValidationError: false
                };
            });
            
        }

        
        if (this.isFirstStep && this.accountId) {
            this[NavigationMixin.Navigate]({
                type: 'standard__recordPage',
                attributes: {
                    recordId: this.accountId,
                    objectApiName: 'Account',
                    actionName: 'view'
                }
            }, true);
        } else if (this.currentStep > 1) {
            if(this.template.querySelector('c-flex-product-replacement-info')!=null){
                this.ineligibleProductList = this.template.querySelector('c-flex-product-replacement-info').
                ineligibleProductList;
                this.subscriptionData = this.template.querySelector('c-flex-product-replacement-info').subscriptionData;
            }
            this.currentStep--;
            console.log('TTMM handleBack - currentStep after decrement:', this.currentStep);
            this.updateStepClasses();
        }
        if (this.isStepOne) {
            this.contractsWithOpenAmends = [];
        }              
    }
    
    createSubscriptionJSON(subscriptionData, ineligibleProductList) {
        const parentProducts = subscriptionData.map(parent => {
            const allSelected = parent.replaceProduct || false;
            const shipToAddresses = parent.subscriptionWrappers.map(child => {
                const isSelectedForPartialUpgrade = child.replaceProduct || false;
                let upgradeProduct = null;
                if (isSelectedForPartialUpgrade && child.selectedProductId) {
                    upgradeProduct = {
                        selectedProductId: child.selectedProductId,
                        selectedProductName: child.selectedProductName,
                        productCode: child.ProductCode ,
                        upgradeQuantity: allSelected ? child.quantity : child.quantityToReplace,
                        remainingOriginalQuantity: allSelected ? null : child.quantity - child.quantityToReplace
                    };
                }
                return {
                    addressId: child.shippingAddressId,
                    quantity: child.quantity,
                    isSelectedForPartialUpgrade,
                    upgradeProduct, 
                };
            });
            return {
                productId: parent.productId,
                productName: parent.productName, 
                originalTotalQuantity: parent.totalQuantity,
                allSelected,
                upgradeProductId: parent.selectedProductId || null,
                upgradeProductName: parent.selectedProductName || null,
                shipToAddresses
            };
        });
          if (ineligibleProductList && ineligibleProductList.length > 0) {
            ineligibleProductList.forEach(ineligibleProduct => {
                parentProducts.push({
                    productId: ineligibleProduct.productId,
                    productName: ineligibleProduct.productName,
                    originalTotalQuantity: ineligibleProduct.totalQuantity,
                    isIneligible: true,
                    shipToAddresses: ineligibleProduct.subscriptionWrappers.map(wrapper => ({
                        addressId: wrapper.shippingAddressId,
                        addressName: wrapper.shippingAddressName,
                        quantity: wrapper.quantity,
                    }))
                });
            });
        }
        return {
            parentProducts
        };
    }
    validationForStepThree() {
        
        this.subscriptionData = JSON.parse(JSON.stringify(this.subscriptionData));
        let hasError = false;

            for (let i = 0; i < this.subscriptionData.length; i++) {
                const parent = this.subscriptionData[i];
                if (parent.replaceProduct) {  
                    if (!parent.selectedProductId || !parent.selectedProductName) {
                        parent.errorClassForProduct = 'error-class';
                        parent.errorClassForProduct = 'error-class';
                        hasError = true;
                    }
                } else {
                    for (let j = 0; j < parent.subscriptionWrappers.length; j++) {
                        const detail = parent.subscriptionWrappers[j];
                        if (detail.replaceProduct) {
                            console.log('TTMM quantity to replace ', JSON.stringify(detail.quantityToReplace));
                            if (!detail.selectedProductId || !detail.selectedProductName || detail.quantityToReplace === null || detail.quantityToReplace > detail.quantity || detail.quantityToReplace <= 0) {                                
                                detail.errorClassForProduct = 'error-class';
                                detail.checkboxClass = 'error-class';
                                hasError = true;
                            }
                        }
                    }
                }
            }
            this.subscriptionData = [...this.subscriptionData];
            return !hasError;
    }
    
    @api
    confirmationScreenJSON() {
    if (this.template.querySelector('c-flex-pn-p-license-upgrade')) { 
        const screenOneData = this.subscriptionData.map(parent => {
            let selectedUpgradeProduct = null;
            if (parent.pnpOneProductDetails?.selectedProductId && 
                parent.pnpOneProductDetails?.selectedProductName &&
                parent.pnpOneProductDetails.selectedProductId !== parent.productId) {
                selectedUpgradeProduct = {
                    productId: parent.pnpOneProductDetails.selectedProductId,
                    productName: parent.pnpOneProductDetails.selectedProductName,
                    productCode: parent.pnpOneProductDetails.defaultHardwareCode?parent.pnpOneProductDetails.defaultHardwareCode : 'None',
                    defaultHardwareCodeURL : parent.pnpOneProductDetails.defaultHardwareCode?`${this.baseURL}/${ parent.pnpOneProductDetails.defaultHardware}`: 'None',
                    defaultHardwareId: parent.pnpOneProductDetails.defaultHardwareCode?parent.pnpOneProductDetails.defaultHardware: 'None',
                    isPlatformProduct: parent.pnpOneProductDetails.isPlatformProduct
                };
            }
            return {
                originalProductId: parent.productId,
                originalProductName: parent.productName,
                originalProductCode: parent.productCode,
                originalTotalQuantity: parent.totalQuantity,
                licenseType: parent.licenseType,
                isPlatformUpgradeEnabled: parent.pnpOneProductDetails.togglePnp,
                addressDetails: parent.subscriptionWrappers.map(child => {
                    return {
                        shippingAddressId: child.shippingAddressId,
                        quantity: child.quantity,
                        licenseType: child.licenseType,
                        selectedUpgradeProduct: selectedUpgradeProduct
                    };
                })
            };
        });
        return screenOneData;
        }

    if (this.template.querySelector('c-flex-product-replacement-info')) { 
        console.log('TTDD pnp Two data', JSON.stringify(this.pnpTwoData));
        
        
        if( this.pnpTwoData){
            this.subscriptionData = JSON.parse(JSON.stringify(this.pnpTwoData));
        }else{
            this.subscriptionData = this.template.querySelector('c-flex-product-replacement-info').subscriptionData;
        }
        

        this.ineligibleProductList = this.template.querySelector('c-flex-product-replacement-info').ineligibleProductList;
        console.log('subd 2 data',JSON.stringify(this.subscriptionData) );
        console.log('subd 2  ineligible list data',JSON.stringify(this.ineligibleProductList) );

        
        const combinedData = this.subscriptionData.map(parent => {
        const allSelected = parent.replaceProduct || false;
        let selectedUpgradeProduct = null;
        if (parent.pnpOneProductDetails?.selectedProductId && 
            parent.pnpOneProductDetails?.selectedProductName &&
            parent.pnpOneProductDetails.selectedProductId !== parent.productId) {
            selectedUpgradeProduct = {
                productId: parent.pnpOneProductDetails.selectedProductId,
                productName: parent.pnpOneProductDetails.selectedProductName,
                productCode : parent.defaultHardwareCode?parent.defaultHardwareCode : 'None',
                defaultHardwareCodeURL :  parent.defaultHardwareCode?`${this.baseURL}/${parent.defaultHardware}`: 'None',
                defaultHardwareId: parent.defaultHardware?parent.defaultHardware: 'None',
                isPlatformProduct: parent.pnpOneProductDetails.isPlatformProduct
            };
        }
        const screenOneData = {
            originalProductId: parent.productId,
            originalProductName: parent.productName, 
            originalProductCode: parent.defaultHardwareCode?parent.defaultHardwareCode : 'None',
            defaultHardwareCodeURL :  parent.defaultHardwareCode?`${this.baseURL}/${  parent.defaultHardware}`: 'None',
            defaultHardwareId: parent.defaultHardware?parent.defaultHardware: 'None',
            originalTotalQuantity: parent.totalQuantity,
            isPlatformUpgradeEnabled: parent.pnpOneProductDetails? parent.pnpOneProductDetails.togglePnp : null,
            platformUpgradeScreenDetails: parent.pnpOneProductDetails ? parent.subscriptionWrappers.map(child => {
                return {
                    shippingAddressId: child.shippingAddressId,
                    shippingAddressName: child.shippingAddressName,
                    quantity: child.quantity,
                    selectedUpgradeProduct: selectedUpgradeProduct
                };
            }) : null
           
        };
        const screenTwoData = {
            productId: selectedUpgradeProduct?.productId || parent.productId,
            productName: selectedUpgradeProduct?.productName || parent.productName,
            productCode:  parent.defaultHardwareCode?parent.defaultHardwareCode : 'None',
            defaultHardwareCodeURL :  parent.defaultHardwareCode?`${this.baseURL}/${  parent.defaultHardware}`: 'None',
            defaultHardwareId: parent.defaultHardware?parent.defaultHardware: 'None',

            originalTotalQuantity: parent.totalQuantity,
            allSelected,            
            shipToAddresses: parent.subscriptionWrappers.map(child => {
                const isSelectedUpgrade = child.replaceProduct || false;
                let upgradeProduct = null;
                
                if (isSelectedUpgrade && (child.selectedProductId || child.pnpOneProductDetails?.selectedProductId)) {
                    upgradeProduct = {
                        productId: child.selectedProductId || child.pnpOneProductDetails?.selectedProductId,
                        productName: child.selectedProductName || child.pnpOneProductDetails?.selectedProductName,
                        productCode: child.selectedProductCode?child.selectedProductCode : 'None',
                        defaultHardwareCodeURL :  child.selectedProductHardwareId?`${this.baseURL}/${child.selectedProductHardwareId}`: 'None',
                        defaultHardwareId: child.selectedProductHardwareId?child.selectedProductHardwareId : 'None',

                        upgradeQuantity: allSelected ? child.quantity : child.quantityToReplace,
                        remainingQuantity: allSelected ? null : child.quantity - child.quantityToReplace
                    };
                } else if (allSelected) {
                    upgradeProduct = {
                        productId: parent.selectedProductId || selectedUpgradeProduct?.productId,
                        productName: parent.selectedProductName || selectedUpgradeProduct?.productName,
                        productCode : parent.selectedProductCode ,
                        defaultHardwareCodeURL : parent.selectedProductHardwareId?`${this.baseURL}/${parent.selectedProductHardwareId}`: 'None',
                        defaultHardwareId: parent.selectedProductHardwareId?parent.selectedProductHardwareId : 'None',

                        upgradeQuantity: child.quantity,
                        remainingQuantity: null
                    };
                }
        
                return {
                    addressId: child.shippingAddressId,
                    addressName:child.shippingAddressName,
                    quantity: child.quantity,
                    averageMonthlyUnitPrice: child.averageMonthlyUnitPrice,
                    isSelectedUpgrade,
                    upgradeProduct
                };
            })
        };
        


        return {
            ...screenOneData,
            finalScreenDetails: screenTwoData,
           
        };
    });


    if( !this.pnpBoolean1){
        console.log('GMK sub data ', JSON.stringify(this.subscriptionData));
        console.log('GMK pnpTwpdta data ', JSON.stringify(this.pnpTwoData));

        
        this.pnpOneData = [...this.subscriptionData]
    }

    this.pnpOneData.forEach(parent => {
        const allSelected = parent.replaceProduct || false;
        let selectedUpgradeProduct = null;
        if (parent.pnpOneProductDetails?.selectedProductId && 
            parent.pnpOneProductDetails?.selectedProductName &&
            parent.pnpOneProductDetails.selectedProductId !== parent.productId) {
            selectedUpgradeProduct = {
                productId: parent.pnpOneProductDetails.selectedProductId,
                productName: parent.pnpOneProductDetails.selectedProductName,
                productCode : parent.defaultHardwareCode?parent.defaultHardwareCode : 'None',
                defaultHardwareCodeURL :  parent.defaultHardwareCode?`${this.baseURL}/${parent.defaultHardware}`: 'None',
                defaultHardwareId: parent.defaultHardware?parent.defaultHardware: 'None',
                isPlatformProduct: parent.pnpOneProductDetails.isPlatformProduct
            };
        }
        const screenOneData = {
            originalProductId: parent.productId,
            originalProductName: parent.productName, 
            originalProductCode: parent.defaultHardwareCode?parent.defaultHardwareCode : 'None',
            defaultHardwareCodeURL :  parent.defaultHardwareCode?`${this.baseURL}/${  parent.defaultHardware}`: 'None',
            defaultHardwareId: parent.defaultHardware?parent.defaultHardware: 'None',
            originalTotalQuantity: parent.totalQuantity,
            isPlatformUpgradeEnabled: parent.pnpOneProductDetails? parent.pnpOneProductDetails.togglePnp : null,
            platformUpgradeScreenDetails: parent.pnpOneProductDetails ? parent.subscriptionWrappers.map(child => {
                return {
                    shippingAddressId: child.shippingAddressId,
                    shippingAddressName: child.shippingAddressName,
                    quantity: child.quantity,
                    selectedUpgradeProduct: selectedUpgradeProduct
                };
            }) : null
           
        };
        const screenTwoData = {
            productId: selectedUpgradeProduct?.productId || parent.productId,
            productName: selectedUpgradeProduct?.productName || parent.productName,
            productCode:  parent.defaultHardwareCode?parent.defaultHardwareCode : 'None',
            defaultHardwareCodeURL :  parent.defaultHardwareCode?`${this.baseURL}/${  parent.defaultHardware}`: 'None',
            defaultHardwareId: parent.defaultHardware?parent.defaultHardware: 'None',

            originalTotalQuantity: parent.totalQuantity,
            allSelected,            
            shipToAddresses: parent.subscriptionWrappers.map(child => {
                const isSelectedUpgrade = child.replaceProduct || false;
                let upgradeProduct = null;
                
                if (isSelectedUpgrade && (child.selectedProductId || child.pnpOneProductDetails?.selectedProductId)) {
                    upgradeProduct = {
                        productId: child.selectedProductId || child.pnpOneProductDetails?.selectedProductId,
                        productName: child.selectedProductName || child.pnpOneProductDetails?.selectedProductName,
                        productCode: child.selectedProductCode?child.selectedProductCode : 'None',
                        defaultHardwareCodeURL :  child.selectedProductHardwareId?`${this.baseURL}/${child.selectedProductHardwareId}`: 'None',
                        defaultHardwareId: child.selectedProductHardwareId?child.selectedProductHardwareId : 'None',

                        upgradeQuantity: allSelected ? child.quantity : child.quantityToReplace,
                        remainingQuantity: allSelected ? null : child.quantity - child.quantityToReplace
                    };
                } else if (allSelected) {
                    upgradeProduct = {
                        productId: parent.selectedProductId || selectedUpgradeProduct?.productId,
                        productName: parent.selectedProductName || selectedUpgradeProduct?.productName,
                        productCode : parent.selectedProductCode ,
                        defaultHardwareCodeURL : parent.selectedProductHardwareId?`${this.baseURL}/${parent.selectedProductHardwareId}`: 'None',
                        defaultHardwareId: parent.selectedProductHardwareId?parent.selectedProductHardwareId : 'None',

                        upgradeQuantity: child.quantity,
                        remainingQuantity: null
                    };
                }
        
                return {
                    addressId: child.shippingAddressId,
                    addressName:child.shippingAddressName,
                    quantity: child.quantity,
                    averageMonthlyUnitPrice: child.averageMonthlyUnitPrice,
                    isSelectedUpgrade,
                    upgradeProduct
                };
            })
        };
        

        if (!combinedData.some(data => data.originalProductId === screenOneData.originalProductId)) {
            combinedData.push({
                ...screenOneData,
                finalScreenDetails: screenTwoData,
            });
        }
        
    });

    console.log('TTDD this.ineligibleProductList ', JSON.stringify(this.ineligibleProductList));
    console.log('TTDD this.combinedData  ', JSON.stringify(combinedData ));
    
    if( !this.pnpBoolean1){

        



        if (this.ineligibleProductList && this.ineligibleProductList.length > 0) {
            this.ineligibleProductList.forEach(ineligibleProduct => {
                const screenOneData = {
                    originalProductId: ineligibleProduct.productId,
                    originalProductName: ineligibleProduct.productName, 
                    originalProductCode: ineligibleProduct.productCode?ineligibleProduct.productCode : 'None',
                    defaultHardwareCodeURL :  ineligibleProduct.productCode?`${this.baseURL}/${  ineligibleProduct.productCode}`: 'None',
                    defaultHardwareId:ineligibleProduct.productCode?ineligibleProduct.productCode: 'None',
                    originalTotalQuantity: ineligibleProduct.totalQuantity,
                    platformUpgradeScreenDetails: null
                   
                };

                const screenTwoData = {
                    productId: ineligibleProduct.productId,
                    productName: ineligibleProduct.productName,
                    productCode: ineligibleProduct.productCode?ineligibleProduct.productCode : 'None',
                    defaultHardwareCodeURL :  ineligibleProduct.productCode?`${this.baseURL}/${  ineligibleProduct.productCode}`: 'None',
                    defaultHardwareId: ineligibleProduct.productCode?ineligibleProduct.productCode: 'None',
        
                    originalTotalQuantity: ineligibleProduct.totalQuantity,
                              
                    shipToAddresses: ineligibleProduct.subscriptionWrappers.map(child => {
                        const isSelectedUpgrade =false;
                        let upgradeProduct = null;
                        return {
                            addressId: child.shippingAddressId,
                            addressName:child.shippingAddressName,
                            quantity: child.quantity,
                            averageMonthlyUnitPrice: child.averageMonthlyUnitPrice,
                            isSelectedUpgrade,
                            upgradeProduct
                        };
                    })
                };


                combinedData.push({
                    ...screenOneData,
                    finalScreenDetails: screenTwoData,
                }
                    
            );
            });
        }

    }
    console.log('TTDD this.combinedData  with ineleigible ', JSON.stringify(combinedData ));

    return combinedData;
    }

console.error('Neither PnP License Upgrade nor Product Replacement components found');
return null; 
}
@track subscriptionJSON;
    validateCurrentStep() {

        if (this.isStepOne) {
            if (!this.selectedContracts || this.selectedContracts.length === 0) {
                this.showToast('Error', 'Please select a contract to proceed', 'error');
                return false;
            }

            if (!this.selectedConfig?.Allow_Non_Co_termed_Contract_Selection__c) {
                const endDates = new Set(this.selectedContracts.map(contract => contract.EndDate));
                if (endDates.size > 1) {
                    this.showToast('Error', 'All selected contracts must have the same end date', 'error');
                    return false;
                }
            }
          
            getAmendmentOpportunities({lstContractIds: this.contractIds})
                .then(result => {
                    this.amendmentOpportunities = result;
                    this.contractsWithOpenAmends = this.selectedContracts.filter(contract => 
                        this.amendmentOpportunities.some(opp => opp.SBQQ__AmendedContract__c === contract.Id)
                    );
                })
                .catch(error => {
                    console.error('Error getting amendment opportunities:', error);
                });
        }

            if(this.isStepThree && !this.pnpBoolean1){
               
                this.subscriptionData = this.template.querySelector('c-flex-product-replacement-info').subscriptionData;
                this.ineligibleProductList = this.template.querySelector('c-flex-product-replacement-info').
                ineligibleProductList;
                const finalData = this.createSubscriptionJSON(this.subscriptionData, this.ineligibleProductList);
                this.finalConfirmationScreenJson = this.confirmationScreenJSON();
                if (!this.validationForStepThree()) {
                    this.showToast('Error', 'Please ensure that the upgrade product(s) are selected and the quantities are valid.', 'error');
                    return false;   
                }
            }
            else if( this.isStepThreeA && this.pnpBoolean1){
                if( this.pnpOneData){
                    this.subscriptionData = JSON.parse(JSON.stringify(this.pnpOneData));
                }
                console.log('TTMM sub data at validate steps ',JSON.stringify(this.subscriptionData));
                console.log('TTMM pnpOne data at validate steps ',JSON.stringify(this.pnpOneData));
                
                const pnpComponent = this.template.querySelector('c-flex-pn-p-license-upgrade');
                if (pnpComponent) {
                    const togglePnP = pnpComponent.togglePnPValue;
                    
                    if (togglePnP) {
                        
                        const hasUnselectedProducts = this.subscriptionData.some(data => 
                            !data.pnpOneProductDetails.selectedProductId || 
                            data.pnpOneProductDetails.selectedProductName === 'Select License Upgrade Product'
                        );
                        
                        if (hasUnselectedProducts) {
                            this.showToast('Error', 'Please select a License Upgrade Product for each item to continue.', 'error');
                            return false;
                        }
                    }
                }
            }
            else if( this.isStepThreeB && this.pnpBoolean1){                 
                this.finalConfirmationScreenJson = this.confirmationScreenJSON();
                if (!this.validationForStepThree()) {
                    this.showToast('Error',`Ensure a valid quantity and Hardware Upgrade Product for items with 'Select All' or 'Upgrade Product?' checked.`, 'error');
                    return false;
                }
            }
          return true;
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }

    handleContractSelection(event) {
        if(event.detail.selectedRows){
            this.selectedContracts = event.detail.selectedRows;
            this.overrideContractsIds = event.detail.selectedRows.map(contract => contract.Id);
        }
        if(event.detail.selectedConfig){
            console.log('TTMM handleContractSelection - selectedConfig:', JSON.stringify(event.detail.selectedConfig));
            console.log('TTMM handleContractSelection - Bypass_SKU_Hierarchy_Validation__c value:', event.detail.selectedConfig.Bypass_SKU_Hierarchy_Validation__c);
            this.selectedConfig = event.detail.selectedConfig;
            this.controlCenterConfigId = event.detail.selectedConfig.Id;
        }
    }

    handleProductSelection(event) {
        this.selectedProducts = event.detail;
    }

    handleUpgradeSelection(event) {
        this.selectedUpgrades = event.detail;
    }
    async handleSubmit() {
        console.log('handleSubmit - currentStep before : ', this.currentStep);
        try {

            // Remove elements with ineligibleProductId populated from finalConfirmationScreenJson
            // this.finalConfirmationScreenJson = this.finalConfirmationScreenJson.filter(item => !item.ineligibleProductId);


            console.log('Final Confirmation Screen Data : ', JSON.stringify(this.finalConfirmationScreenJson));
            console.log('configData : ', this.configData);
            console.log('selectedContracts stringify : ', JSON.stringify(this.selectedContracts));
            console.log('contractIds stringify : ', JSON.stringify(this.contractIds));
            this.disableSubmitButton= true;
            let parameterObject = {
                contractIds: this.contractIds,
                startDate: this.configData.startDate,
                termLength:  this.configData.termMonths,
                accountId: this.accountId,
                isRebook: this.configData.isRebook,
                endDate: this.configData.endDate,
                //quoteLineData: JSON.stringify(this.finalConfirmationScreenJson)
                quoteLineData: this.finalConfirmationScreenJson,
                configData : JSON.stringify(this.configData),
                selectedContracts : JSON.stringify(this.selectedContracts)
            };
            console.log('final JSON data ',parameterObject);
            console.log('parameterObject stringify ' + JSON.stringify(parameterObject));
            
            amendContracts({ amendContracts: parameterObject })
            .then(result => {
                this.isLoading = false;
                this.disableSubmitButton = false;
      
                if (!result?.success) {
                    this.isSubmittedSuccess = false;
                    this.isSubmittedFailed = true;
                   
                    this.errorMessage = result?.errorMessage || 'Unknown error occurred';
                } else {
                    this.isSubmittedSuccess = true;
                    // Set the current step to the submitted state without incrementing
                    if (this.pnpBoolean1) {
                        this.currentStep = 6;
                    } else {
                        this.currentStep = 5;
                    }
                    console.log('TTMM handleSubmit - currentStep after success:', this.currentStep);
                }
            })
            .catch(error => {
                console.error('Error in handleSubmit:', error);
                this.isLoading = false;
                this.disableSubmitButton = false;
                this.isSubmittedSuccess = false;
                this.isSubmittedFailed = true;
                this.errorMessage = error.message;
            });

        } catch (error) {
            console.error('Unexpected error in handleSubmit:', error);
            this.isLoading = false;
            this.disableSubmitButton = false;
            this.isSubmittedSuccess = false;
            this.isSubmittedFailed = true;
            this.errorMessage = error.message;
        }
    }

    
    handleFieldValidation(event) {
        this.subscriptionData = event.detail.subscriptionData;
        this.cachedSubscriptionData  = event.detail.subscriptionData;
        
    }

    handleConfigChange(event) {
        const configDataA = JSON.parse(JSON.stringify(event.detail));
        console.log('TTMM handleConfigChange - Full config data:', JSON.stringify(configDataA));
        console.log('TTMM handleConfigChange - Bypass_SKU_Hierarchy_Validation__c value:', configDataA.configRecord?.fields?.Bypass_SKU_Hierarchy_Validation__c?.value);
        
        if (!configDataA.closeDate) {
            configDataA.closeDate = '';
        }
        this.configData = configDataA;
        
        // Set the selectedConfig with the config record data
        if (configDataA.configRecord) {
            this.selectedConfig = {
                ...this.selectedConfig,
                Bypass_SKU_Hierarchy_Validation__c: configDataA.configRecord.fields.Bypass_SKU_Hierarchy_Validation__c?.value
            };
            console.log('TTMM handleConfigChange - Updated selectedConfig:', JSON.stringify(this.selectedConfig));
        }
        
        if (configDataA.termMonths) {
            this.userSelectedTermMonths = configDataA.termMonths;
        }
        console.log('test handleconfigchange', this.configData);
    }
    get showBookingToggle() {
        return this.configData?.configRecord?.fields?.Enable_Cancel_Book__c?.value && 
               this.configData?.configRecord?.fields?.Enable_Cancel_Rebook__c?.value;
    }

    get showTermField() {
        return this.configData?.configRecord?.fields?.Enable_Cancel_Book__c?.value &&
               this.configData?.configRecord?.fields?.Enable_Term_Overwrite__c?.value &&
               !this.configData?.isRebook;
    }    

    handleStepClick(event) {
        console.log('Step clicked event:', event);
        console.log('Step clicked dataset:', event.currentTarget.dataset);
        const targetStep = parseInt(event.currentTarget.dataset.step);
        console.log('Target step:', targetStep);
        console.log('Current step:', this.currentStep);
        
        // Only allow navigation to steps that have been completed or the current step
        if (targetStep <= this.currentStep) {
            console.log('Navigating to step:', targetStep);
            this.currentStep = targetStep;
            this.updateStepClasses();
        } else {
            console.log('Cannot navigate to future step:', targetStep);
            this.showToast('Warning', 'You can only navigate to steps you have already completed', 'warning');
        }
    }
}