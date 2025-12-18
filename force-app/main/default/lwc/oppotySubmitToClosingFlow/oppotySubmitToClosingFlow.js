import { LightningElement, api, track } from 'lwc';
import { FlowNavigationNextEvent, FlowNavigationBackEvent } from 'lightning/flowSupport';
import updateAccount from '@salesforce/apex/SubmitToClosingController.updateAccount';
import updateOpportunity from '@salesforce/apex/SubmitToClosingController.updateOpportunity';
import getProductVersionOptions from '@salesforce/apex/SubmitToClosingController.getProductVersionOptions';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import FT_CONVERSION_SERIAL_NO_FIELD from '@salesforce/schema/Opportunity.FT_Conversion_Serial_No__c';

export default class OppotySubmitToClosingFlow extends LightningElement {
    @api account = {};
    @api opportunity = {};
    @api loggedInUser;
    @api userRole;
    @api userProfile;

    @track missingFields = {
        accountFields: [],
        opportunityFields: []
    };

    @track isMissingField = {};
    @track showForm = false;
    @track isLoading = false;
    @track sectionsToShow = {
        billing: false,
        firstPurchase: false,
        mexico: false,
        opportunity: false
    };

    @track missingFieldNames = [];

    @track showSiteDetails = false;
    @track siteFields = {
        numberOfSites: '',
        networkConfig: '',
        deploymentType: ''
    };

    // Network Configuration options
    @track networkConfigOptions = [
        { label: 'Standard', value: 'Standard' },
        { label: 'Advanced', value: 'Advanced' },
        { label: 'Enterprise', value: 'Enterprise' }
    ];

    // Deployment Type options - will be populated from Apex
    @track deploymentTypeOptions = [];
    @track productVersionOptions = [];

    @track freeTrialPurchaseValue;
    @track allSerialNumbers;
    @track hasTrialProducts = true;
    @track showNoDataMessage = false;
    @track hasErrors = false;
    @track errorMessage;

    @track showNotification = false;
    @track notificationMessage = '';
    @track notificationIcon = '';
    @track notificationIconVariant = '';
    @track notificationClass = '';
    notificationTimeout;

    @track partnerInvolved = null;

    @track allSerialNumbersFromChild;


    get showCableSelectionSection() {
        return this.opportunity?.VG_unit_count__c > 0;
    }

    get requireCableSelection() {
        return this.showCableSelectionSection &&
            !this.opportunity?.Cable_Selection_Method__c &&
            (this.opportunity?.StageName === 'Closing' || 
             this.opportunity?.StageName === 'Orders Processing');
    }

    get showAlternativeCableReason() {
        return this.opportunity?.Alternative_Cable_Selection__c === true;
    }

    get showFreeTrialSection() {
        return this.opportunity.Type === 'Revenue Opportunity' &&
            !this.opportunity.Owner_Role_Copy__c?.includes('AE1') &&
            !this.opportunity.Owner_Role_Copy__c?.includes('Samsara Small Fleets') &&
            !this.opportunity.Owner_Role_Copy__c?.includes('Renewal') &&
            !this.opportunity.Name?.includes('Webstore') &&
            !this.opportunity.Name?.includes('Evergreen');
    }

    get showPartialBuyComponent() {
        return this.showFreeTrialSection && this.freeTrialPurchaseValue === 'Partial Buy';
    }

    get freeTrialOptions() {
        return [
            { label: 'Full Buy', value: 'Full Buy' },
            { label: 'Partial Buy', value: 'Partial Buy' },
            { label: 'No Purchase', value: 'No Purchase' }
        ];
    }

    // Field definitions for the form
    billingFields = [
        { label: 'Billing Street', fieldName: 'BillingStreet', required: true },
        { label: 'Billing City', fieldName: 'BillingCity', required: true },
        { label: 'Billing Country', fieldName: 'BillingCountry', required: true },
        { label: 'Billing Postal Code', fieldName: 'BillingPostalCode', required: true },
        { label: 'Billing Email', fieldName: 'Billing_Email__c', required: true }
    ];

    firstPurchaseFields = [
        { label: 'CS POC First Name', fieldName: 'CS_POC_First_Name__c', required: true },
        { label: 'CS POC Email', fieldName: 'CS_POC_Email_Address__c', required: true },
        { label: 'CS POC Phone', fieldName: 'CS_POC_Phone__c', required: true },
        { label: 'Key Value Points', fieldName: 'Key_Value_Points__c', required: true }
    ];

    mexicoFields = [
        { label: 'Razon Social', fieldName: 'Razon_Social_Legal_Company_Name__c', required: true },
        { label: 'Tipo RFC', fieldName: 'Tipo_de_RFC__c', required: true },
        { label: 'Regimen Fiscal', fieldName: 'Regimen_Fiscal_Receptor__c', required: true },
        { label: 'Regimen Capital', fieldName: 'Regimen_Capital__c', required: false }
    ];

    opportunityFields = [
        { label: 'Alternative Cable Selection', fieldName: 'Alternative_Cable_Selection__c', required: true, type: 'Boolean' },
        { label: 'Cable Selection Method', fieldName: 'Cable_Selection_Method__c', required: true }
    ];

    connectedCallback() {
        // Initialize default values if not provided
        if (!this.account) {
            this.account = {};
        }
        if (!this.opportunity) {
            this.opportunity = {};
        }

        // Check if site details should be shown
        if (this.opportunity.Sites_ACV_Bookings__c > 0) {
            this.showSiteDetails = true;
            // We only need product version options
            this.fetchProductVersionOptions();
        }

        // Only proceed with initialization if we have valid IDs
        if (!this.account.Id || !this.opportunity.Id) {
            return;
        }
        
        this.initializeMissingFieldsAndSections();

        // Initialize Free Trial Purchase value
        if (this.opportunity.Free_Trial_Purchase__c) {
            this.freeTrialPurchaseValue = this.opportunity.Free_Trial_Purchase__c;
        }
    }

    // fetchDeploymentTypeOptions removed to use standard Salesforce field

    fetchProductVersionOptions() {
        getProductVersionOptions()
            .then(result => {
                this.productVersionOptions = result;
                console.log('Product version options loaded:', JSON.stringify(this.productVersionOptions));
            })
            .catch(error => {
                console.error('Error loading product version options:', error);
                this.showCustomNotification('error', 'Error loading product version options: ' + (error.body?.message || error.message));
            });
    }

    initializeMissingFieldsAndSections() {
        // Reset missing fields tracking
        this.isMissingField = {};
        
        const missingBillingFields = this.getMissingFields(this.billingFields);
        const missingFirstPurchaseFields = this.getMissingFields(this.firstPurchaseFields);
        const missingMexicoFields = this.account.BillingCountry === 'Mexico' ? 
            this.getMissingFields(this.mexicoFields) : [];

        // Only check opportunity fields if cable selection is required
        const missingOppFields = this.showCableSelectionSection ? 
            this.getMissingFields(this.opportunityFields, true) : [];

        // Update missing fields
        this.missingFields = {
            accountFields: [
                ...missingBillingFields,
                ...missingFirstPurchaseFields,
                ...missingMexicoFields
            ],
            opportunityFields: missingOppFields
        };

        // Update individual field tracking
        [...this.billingFields, ...this.firstPurchaseFields, ...this.mexicoFields].forEach(field => {
            const value = this.account[field.fieldName];
            this.isMissingField[field.fieldName] = !value || value === '' || value === undefined || value === null;
        });

        if (this.showCableSelectionSection) {
            this.opportunityFields.forEach(field => {
                const value = this.opportunity[field.fieldName];
                if (field.type === 'Boolean') {
                    this.isMissingField[field.fieldName] = value === undefined || value === null;
                } else {
                    this.isMissingField[field.fieldName] = !value || value === '' || value === undefined || value === null;
                }
            });
        }

        // Update section visibility
        this.sectionsToShow = {
            billing: missingBillingFields.length > 0,
            firstPurchase: missingFirstPurchaseFields.length > 0,
            mexico: missingMexicoFields.length > 0 && this.account.BillingCountry === 'Mexico',
            opportunity: this.showCableSelectionSection && missingOppFields.length > 0
        };

        // Show form if any section needs to be displayed
        this.showForm = this.missingFields.accountFields.length > 0 || 
                       this.missingFields.opportunityFields.length > 0;
    }

    handleFieldChange(event) {
        const field = event.target.dataset.field;
        const value = event.target.value;
        
        console.log(`Field ${field} changed to:`, value);
        
        // Handle Tipo_de_RFC__c changes to conditionally clear/require Regimen_Capital__c
        if (field === 'Tipo_de_RFC__c') {
            // Update the account object with the new value
            this.account = { ...this.account, [field]: value };
            
            // Get the Regimen_Capital__c field
            const regimenCapitalField = this.template.querySelector('lightning-input-field[data-field="Regimen_Capital__c"]');
            
            if (regimenCapitalField) {
                if (value === 'Persona Fisica') {
                    // If Persona Fisica, Regimen_Capital__c should be cleared and not required
                    regimenCapitalField.value = null;
                    regimenCapitalField.required = false;
                    
                    // Update the account object to clear the field
                    this.account = { ...this.account, Regimen_Capital__c: null };
                } else {
                    // For any other value, Regimen_Capital__c is required
                    regimenCapitalField.required = true;
                }
            }
        }
        
        // Track if this is a change for Site Details fields
        if (this.showSiteDetails && 
            ['Number_of_sites_sold__c', 'Product_Version__c', 'Deployment_Type__c'].includes(field)) {
            
            // Store the original value if not already set
            if (!event.target.originalValue) {
                // For Deployment_Type__c specifically - when using combobox
                if (field === 'Deployment_Type__c') {
                    event.target.originalValue = this.opportunity.Deployment_Type__c || '';
                } else {
                    event.target.originalValue = event.target.value || '';
                }
            }
            
            // Don't directly compare with opportunity values, as they might cause proxy errors
            const currentValue = event.target.value;
            const originalValue = event.target.originalValue || '';
            const isChanged = String(currentValue) !== String(originalValue);
            
            // Just mark the field as changed - no popup notification
            if (isChanged) {
                // Store the change locally instead of modifying the opportunity object
                event.target.dataset.changed = 'true';
            }
        }
        
        // Don't directly modify the opportunity, let the form handle it
        // Remove error styling if value is provided
        if (value) {
            event.target.classList.remove('slds-has-error');
            const errorDiv = event.target.parentElement.querySelector('.slds-form-element__help');
            if (errorDiv) {
                errorDiv.remove();
            }
        }
    }

    handleSiteFieldChange(event) {
        const field = event.target.dataset.field;
        const value = event.target.value;
        
        this.siteFields[field] = value;
        
        // Remove error styling if value is provided
        if (value) {
            event.target.classList.remove('slds-has-error');
            const errorDiv = event.target.parentElement.querySelector('.slds-form-element__help');
            if (errorDiv) {
                errorDiv.remove();
            }
        }
    }

    validateSiteFields() {
        let isValid = true;
        if (this.showSiteDetails) {
            const fields = ['numberOfSites', 'networkConfig', 'deploymentType'];
            fields.forEach(field => {
                if (!this.siteFields[field]) {
                    isValid = false;
                    const input = this.template.querySelector(`[data-field="${field}"]`);
                    if (input) {
                        input.classList.add('slds-has-error');
                        const errorDiv = document.createElement('div');
                        errorDiv.className = 'slds-form-element__help';
                        input.parentElement.appendChild(errorDiv);
                    }
                    const siteDetailsSection = this.template.querySelector('[data-id="SiteDetailsSection"]');
                    if (siteDetailsSection) {
                        const errorDiv = document.createElement('div');
                        errorDiv.className = 'slds-form-element__help';
                        siteDetailsSection.appendChild(errorDiv);
                    }
                }
            });
        }
        return isValid;
    }

    handleSiteDetailsSuccess(event) {
        // Update the local opportunity record with new values
        const fields = event.detail.fields;
        this.opportunity = { ...this.opportunity, ...fields };
        
        // Remove any error styling
        const form = this.template.querySelector('lightning-record-edit-form');
        if (form) {
            const inputs = form.querySelectorAll('lightning-input-field');
            inputs.forEach(input => {
                input.classList.remove('slds-has-error');
                const errorDiv = input.parentElement.querySelector('.slds-form-element__help');
                if (errorDiv) {
                    errorDiv.remove();
                }
            });
        }
    }

    handleSiteDetailsError(event) {
        console.error('Error updating site details:', event.detail);
        // Handle the error appropriately - show error message, etc.
        const errorMessage = event.detail.message || 'Error updating site details';
        this.dispatchEvent(
            new ShowToastEvent({
                title: 'Error',
                message: errorMessage,
                variant: 'error'
            })
        );
    }
    handleFreeTrialChange(event) {
        // Store value in local property instead of modifying opportunity
        this.freeTrialPurchaseValue = event.detail.value;
        
        // Track if this is a change from the original value
        const originalValue = this.opportunity?.Free_Trial_Purchase__c || '';
        const isChanged = this.freeTrialPurchaseValue !== originalValue;
        
        // Mark as changed but don't show notification
        if (isChanged) {
            event.target.dataset.changed = 'true';
        }
    }
    showCustomNotification(type, message) {
        // Clear any existing timeout
        if (this.notificationTimeout) {
            clearTimeout(this.notificationTimeout);
        }

        // Set notification properties based on type
        switch (type) {
            case 'success':
                this.notificationIcon = 'utility:success';
                this.notificationIconVariant = 'success';
                this.notificationClass = 'custom-notification notification-success';
                break;
            case 'error':
                this.notificationIcon = 'utility:error';
                this.notificationIconVariant = 'error';
                this.notificationClass = 'custom-notification notification-error';
                break;
            case 'warning':
                this.notificationIcon = 'utility:warning';
                this.notificationIconVariant = 'warning';
                this.notificationClass = 'custom-notification notification-warning';
                break;
            case 'info':
                this.notificationIcon = 'utility:info';
                this.notificationIconVariant = 'info';
                this.notificationClass = 'custom-notification notification-info';
                break;
        }

        this.notificationMessage = message;
        this.showNotification = true;

        // Auto-hide after 3 seconds
        this.notificationTimeout = setTimeout(() => {
            this.closeNotification();
        }, 3000);
    }

    closeNotification() {
        const notification = this.template.querySelector('.custom-notification');
        if (notification) {
            notification.classList.add('notification-exit');
            setTimeout(() => {
                this.showNotification = false;
            }, 300);
        } else {
            this.showNotification = false;
        }
    }

    async handleSubmit(event) {
        // Prevent default behavior only if event exists
        if (event) {
            event.preventDefault();
            event.stopPropagation();
        }
        
        this.showLoading();
        
        try {
            this.hasErrors = false;
            this.errorMessage = '';

            // Reset missing fields
            this.missingFieldNames = [];
            
            // Get all input fields
            const allFields = this.template.querySelectorAll('lightning-input-field');
            let hasAllValues = true;
            let formData = {};
            let missingFieldLabels = [];

            // Validate required fields
            allFields.forEach(field => {
                const fieldName = field.dataset.field;
                const fieldLabel = field.label || fieldName;
                const value = field.value??'';
                const isRequired = field.required;

                if (isRequired && (value === null || value === undefined || value === '')) {
                    hasAllValues = false;
                    this.missingFieldNames.push(fieldName);
                    missingFieldLabels.push(fieldLabel);
                    field.classList.add('slds-has-error');
                    
                    const errorDiv = document.createElement('div');
                    errorDiv.className = 'slds-form-element__help';
                    field.parentElement.appendChild(errorDiv);
                } else {
                    field.classList.remove('slds-has-error');
                    const errorDiv = field.parentElement.querySelector('.slds-form-element__help');
                    if (errorDiv) {
                        errorDiv.remove();
                    }
                    
                    if (value !== null && value !== undefined && value !== '') {
                        formData[fieldName] = value;
                    }
                }
            });

            // Validate site deals fields if site details are shown
            if (this.showSiteDetails) {
                const siteFields = ['Number_of_sites_sold__c', 'Product_Version__c', 'Deployment_Type__c'];
                const missingSiteFields = siteFields.filter(field => {
                    const fieldElement = this.template.querySelector(`[data-field="${field}"]`);
                    return fieldElement && fieldElement.required && !fieldElement.value;
                });

                if (missingSiteFields.length > 0) {
                    hasAllValues = false;
                    const siteFieldLabels = missingSiteFields.map(field => {
                        const fieldElement = this.template.querySelector(`[data-field="${field}"]`);
                        return fieldElement ? fieldElement.label : field;
                    });
                    missingFieldLabels.push(...siteFieldLabels);
                }
            }

            if (!hasAllValues) {
                throw new Error(`Please complete the following required fields: ${missingFieldLabels.join(', ')}`);
            }

            // Prepare update data
            const accountFields = {};
            const opportunityFields = {};

            Object.entries(formData).forEach(([fieldName, value]) => {
                if (this.isAccountField(fieldName)) {
                    accountFields[fieldName] = value;
                } else {
                    opportunityFields[fieldName] = value;
                }
            });

            // Add Free Trial Purchase value to opportunity fields if it exists
            if (this.freeTrialPurchaseValue) {
                opportunityFields['Free_Trial_Purchase__c'] = this.freeTrialPurchaseValue;
            }

            // Add site deals fields to opportunity fields if they exist
            if (this.showSiteDetails) {
                const siteFields = ['Number_of_sites_sold__c', 'Product_Version__c', 'Deployment_Type__c'];
                siteFields.forEach(field => {
                    const fieldElement = this.template.querySelector(`[data-field="${field}"]`);
                    if (fieldElement && fieldElement.value) {
                        opportunityFields[field] = fieldElement.value;
                    }
                });
            }

            // Check if we have any records to update
            const hasAccountUpdates = Object.keys(accountFields).length > 0;
            const hasOpportunityUpdates = Object.keys(opportunityFields).length > 0;

            // If no updates needed, proceed to next screen
            if (!hasAccountUpdates && !hasOpportunityUpdates) {
                // No updates needed, navigate directly
                this.hideLoading();
                this.dispatchEvent(new FlowNavigationNextEvent());
                return;
            }

            // Show processing notification
            this.showCustomNotification('info', 'Processing your request...');

            // Update records
            await this.updateRecords(accountFields, opportunityFields);

            // Show success notification briefly
            this.showCustomNotification('success', 'Records updated successfully');
            
            // Navigate to next screen after short delay to allow notification to be seen
            setTimeout(() => {
                this.hideLoading();
                // Explicitly navigate to next screen in flow
                this.dispatchEvent(new FlowNavigationNextEvent());
            }, 500);

        } catch (error) {
            console.error('Error in handleSubmit:', error);
            
            // Handle different types of errors
            let errorMessage = '';
            if (error.body) {
                // Handle Salesforce API errors
                errorMessage = error.body.message || error.body.pageErrors?.[0]?.message || 'An API error occurred';
            } else {
                // Handle validation and other errors
                errorMessage = error.message || 'An unexpected error occurred';
            }

            this.hasErrors = true;
            this.errorMessage = errorMessage;
            this.showCustomNotification('error', errorMessage);

            // If there are missing fields, scroll to the first one
            if (this.missingFieldNames.length > 0) {
                const firstMissingField = this.template.querySelector(`[data-field="${this.missingFieldNames[0]}"]`);
                if (firstMissingField) {
                    firstMissingField.scrollIntoView({ behavior: 'smooth', block: 'center' });
                }
            }
            this.hideLoading();
        }
    }
    @track noDataMessage = '';
    handleNoData(event) {
        this.noDataMessage = event.detail.message;
        this.hasTrialProducts = false; 
    }

    async updateRecords(accountFields, opportunityFields) {
        try {
            // Update Account if needed
            if (Object.keys(accountFields).length > 0) {
                try {
                    await updateAccount({
                        accountId: this.account.Id,
                        fields: accountFields
                    });
                } catch (error) {
                    console.error('Error updating Account:', error);
                    const errorMsg = error.body?.message || error.message || 'Unknown error updating Account';
                    throw new Error(`Account Update Error: ${errorMsg}`);
                }
            }

            // Update Opportunity if needed
            if (Object.keys(opportunityFields).length > 0) {
                try {
                    // Always include the serial numbers if present
                    if (this.allSerialNumbersFromChild) {
                        console.log('this.allSerialNumbersFromChild-> '+JSON.stringify(this.allSerialNumbersFromChild));
                    }

                    await updateOpportunity({
                        opportunityId: this.opportunity.Id,
                        fields: opportunityFields
                    });
                } catch (error) {
                    console.error('Error updating Opportunity:', error);
                    // Parse the error message for field-specific errors
                    let errorMsg = error.body?.message || error.message || 'Unknown error updating Opportunity';
                    // Check if the error contains field-specific errors
                    if (errorMsg.includes('Field:')) {
                        const fieldErrors = errorMsg.split('\n')
                            .filter(line => line.includes('Field:'))
                            .map(line => line.trim())
                            .join('\n');
                        errorMsg = `Opportunity Update Errors:\n${fieldErrors}`;
                    }
                    throw new Error(errorMsg);
                }
            }

        } catch (error) {
            console.error('Error during record updates:', error);
            throw error; // Re-throw to be handled by the calling function
        }
    }

    clearErrorStyles() {
        const allFields = this.template.querySelectorAll('lightning-input-field');
        allFields.forEach(field => {
            field.classList.remove('slds-has-error');
            const errorDiv = field.parentElement.querySelector('.slds-form-element__help');
            if (errorDiv) {
                errorDiv.remove();
            }
        });
    }

    handleAccountSuccess(event) {
        console.log('Account update success');
        this.hideLoading();
        this.checkAndNavigate();
    }

    handleAccountError(event) {
        console.error('Account update error:', event.detail);
        this.hideLoading();
        this.showCustomNotification('error', event.detail.message || 'Error updating account');
    }

    handleOpportunitySuccess(event) {
        console.log('Opportunity update success');
        this.hideLoading();
        this.checkAndNavigate();
    }

    handleOpportunityError(event) {
        console.error('Opportunity update error:', event.detail);
        this.hideLoading();
        this.showCustomNotification('error', event.detail.message || 'Error updating opportunity');
    }

    checkAndNavigate() {
        // Check if both forms have been submitted successfully
        const accountForm = this.template.querySelector('lightning-record-edit-form[data-id="accountForm"]');
        const opportunityForm = this.template.querySelector('lightning-record-edit-form[data-id="opportunityForm"]');

        // If both forms are submitted or not needed, navigate to next screen
        if ((!accountForm || accountForm.submitted) && 
            (!opportunityForm || opportunityForm.submitted)) {
            // Navigate directly to next screen
            this.dispatchEvent(new FlowNavigationNextEvent());
        }
    }

    isAccountField(fieldName) {
        const accountFields = [
            'BillingStreet', 'BillingCity', 'BillingCountry', 'BillingPostalCode',
            'Billing_Email__c', 'CS_POC_First_Name__c', 'CS_POC_Email_Address__c',
            'CS_POC_Phone__c', 'Key_Value_Points__c', 'Razon_Social_Legal_Company_Name__c',
            'Tipo_de_RFC__c', 'Regimen_Fiscal_Receptor__c', 'Regimen_Capital__c'
        ];
        return accountFields.includes(fieldName);
    }

    getMissingFields(fields, isOpportunity = false) {
        const record = isOpportunity ? this.opportunity : this.account;
        
        // Return all fields as missing if record is not properly initialized
        if (!record || !record.Id) {
            return fields.map(field => field.label);
        }

        return fields
            .filter(field => {
                const value = record[field.fieldName];
                
                // Special handling for Regimen_Capital__c
                if (field.fieldName === 'Regimen_Capital__c') {
                    // Only check if it's missing when Tipo_de_RFC__c is not 'Persona Fisica'
                    if (record.Tipo_de_RFC__c !== 'Persona Fisica') {
                        return value === undefined || value === null || value === '';
                    } else {
                        // For Persona Fisica, Regimen_Capital__c is not required
                        return false;
                    }
                }
                
                // For all other fields, check if they're required and missing
                return field.required && (value === undefined || value === null || value === '');
            })
            .map(field => field.label);
    }

    // Getters for section visibility - now using cached values
    get showBillingSection() {
        return this.sectionsToShow.billing;
    }

    get showFirstPurchaseSection() {
        return this.sectionsToShow.firstPurchase;
    }

    get showMexicoSection() {
        return this.sectionsToShow.mexico;
    }

    get showOpportunitySection() {
        return this.sectionsToShow.opportunity;
    }

    handleNext() {
        this.showLoading();

        // Check for changes in Free Trial and Site Details fields
        let hasValueChanges = false;
        const opportunityUpdates = {};

        // Check Free Trial Purchase value changes - use stored value
        if (this.showFreeTrialSection && this.freeTrialPurchaseValue) {
            const originalValue = this.opportunity?.Free_Trial_Purchase__c || '';
            if (this.freeTrialPurchaseValue !== originalValue) {
                opportunityUpdates.Free_Trial_Purchase__c = this.freeTrialPurchaseValue;
                hasValueChanges = true;
            }
        }

        if(this.showPartialBuyComponent){
            console.log('Partial Buy Component is visible');
            const childCmp = this.template.querySelector('c-submit-to-closing-partial-buy-c-m-p');
            console.log('Child Component found:', childCmp ? 'Yes' : 'No');
            
            if (childCmp) {
                // Get serial numbers from child component
                console.log('Attempting to get serial numbers from child component');
                const serialNumbers = childCmp.getSerialNumbers();
                console.log('Serial Numbers received:', serialNumbers);
                
                if (serialNumbers) {
                    console.log('Adding serial numbers to opportunity updates');
                    opportunityUpdates[FT_CONVERSION_SERIAL_NO_FIELD.fieldApiName] = serialNumbers;
                    hasValueChanges = true;
                    console.log('Updated opportunityUpdates:', JSON.stringify(opportunityUpdates));
                } else {
                    console.log('No serial numbers received from child component');
                }
                
                console.log('Calling handleFinish on child component');
                childCmp.handleFinish(); 
            }
        } else {
            console.log('Partial Buy Component is not visible');
        }

        // Check Site Details changes - use data-changed attribute
        if (this.showSiteDetails) {
            // Check all site fields the same way
            const siteFields = ['Number_of_sites_sold__c', 'Product_Version__c', 'Deployment_Type__c'];
            
            siteFields.forEach(field => {
                const fieldElement = this.template.querySelector(`[data-field="${field}"]`);
                if (fieldElement && fieldElement.value !== undefined) {
                    // Check if this field was marked as changed
                    if (fieldElement.dataset.changed === 'true') {
                        opportunityUpdates[field] = fieldElement.value;
                        hasValueChanges = true;
                    }
                }
            });
        }

        // Check if there are any required fields that need to be filled
        const missingFieldsCount = this.missingFields.accountFields.length + this.missingFields.opportunityFields.length;
        
        if (missingFieldsCount > 0) {
            // There are missing fields, call handleSubmit to validate and show errors
            this.hideLoading();
            this.handleSubmit();
        } else if (hasValueChanges) {
            // Values have changed but no missing required fields, save changes
            // Only show a saving notification, not before every change
            this.showCustomNotification('info', 'Saving changes...');
            
            console.log('Saving opportunity updates:', JSON.stringify(opportunityUpdates));
            
            // Update the opportunity with the changed values
            updateOpportunity({
                opportunityId: this.opportunity.Id,
                fields: opportunityUpdates
            })
            .then(() => {
                this.showCustomNotification('success', 'Changes saved successfully');
                // Short delay to allow notification to be seen
                setTimeout(() => {
                    this.hideLoading();
                    // Navigate to next screen
                    this.dispatchEvent(new FlowNavigationNextEvent());
                }, 500);
            })
            .catch(error => {
                console.error('Error updating values:', error);
                let errorMessage = '';
                if (error.body) {
                    errorMessage = error.body.message || error.body.pageErrors?.[0]?.message || 'An error occurred';
                } else {
                    errorMessage = error.message || 'An unexpected error occurred';
                }
                this.showCustomNotification('error', errorMessage);
                this.hideLoading();
            });
        } else {
            // Check if there are any site details fields that need validation
            if (this.showSiteDetails) {
                const siteFields = this.template.querySelectorAll('[data-field]');
                let hasEmptyRequiredFields = false;
                
                siteFields.forEach(field => {
                    if (field.required && !field.value) {
                        hasEmptyRequiredFields = true;
                        field.reportValidity();
                    }
                });
                
                if (hasEmptyRequiredFields) {
                    this.showCustomNotification('error', 'Please fill in all required fields');
                    this.hideLoading();
                    return;
                }
            }
            
            // No validation issues or changes, proceed with navigation
            this.hideLoading();
            console.log('Navigating to next screen');
            const navigateNextEvent = new FlowNavigationNextEvent();
            this.dispatchEvent(navigateNextEvent);
        }
    }

    handlePrevious() {
        console.log('Navigating back');
        const navigateBackEvent = new FlowNavigationBackEvent();
        this.dispatchEvent(navigateBackEvent);
    }

    renderedCallback() {
        // Defensive: Handle picklist values via form inputs instead of directly modifying objects
        try {
            // 1. Deployment_Type__c - Set field value via the form input
            if (this.showSiteDetails) {
                const deploymentField = this.template.querySelector('[data-field="Deployment_Type__c"]');
                if (deploymentField && !this.opportunity.Deployment_Type__c && this.deploymentTypeOptions.length > 0) {
                    deploymentField.value = this.deploymentTypeOptions[0].value;
                }
            }
            
            // 2. Network Configuration - Update safely through local property
            if (this.siteFields && this.networkConfigOptions && this.networkConfigOptions.length > 0) {
                const validNetworkConfigs = this.networkConfigOptions.map(opt => opt.value);
                if (!validNetworkConfigs.includes(this.siteFields.networkConfig)) {
                    // Create a new object to avoid modifying the original
                    this.siteFields = {
                        ...this.siteFields,
                        networkConfig: validNetworkConfigs[0]
                    };
                }
            }
            
            // 3. Free Trial Purchase - Set via form input
            if (this.freeTrialOptions && this.freeTrialOptions.length > 0) {
                const freeTrialField = this.template.querySelector('[name="freeTrialPurchase"]');
                if (freeTrialField && !this.opportunity.Free_Trial_Purchase__c) {
                    freeTrialField.value = this.freeTrialOptions[0].value;
                }
            }
            
            // 4. BillingCountry - Set via form input
            const billingCountryField = this.template.querySelector('[data-field="BillingCountry"]');
            if (billingCountryField && !this.account.BillingCountry) {
                // If we have options, set the first one
                if (billingCountryField.options && billingCountryField.options.length > 0) {
                    billingCountryField.value = billingCountryField.options[0].value;
                }
            }
        } catch (error) {
            console.error('Error in renderedCallback:', error);
            // Don't show error to user since this is defensive code
        }
    }

    // Getter to check if required fields are missing
    get hasRequiredFields() {
        return (this.missingFields.accountFields.length > 0 || 
                this.missingFields.opportunityFields.length > 0);
    }

    // Add a method to centrally manage loading state
    showLoading() {
        // Ensure any previous loading is cleared
        clearTimeout(this.loadingTimeout);
        this.isLoading = true;
    }
    
    hideLoading() {
        // Use a small timeout to prevent flickering if operations happen quickly
        clearTimeout(this.loadingTimeout);
        this.loadingTimeout = setTimeout(() => {
            this.isLoading = false;
        }, 100);
    }

    // Getter to determine if Regimen Capital is required based on Tipo de RFC
    get isRegimenCapitalRequired() {
        return this.account?.Tipo_de_RFC__c && this.account.Tipo_de_RFC__c !== 'Persona Fisica';
    }

    // Add this getter for partner info
    get isPartnerInfoPopulated() {
        const opp = this.opportunity;
    return opp &&
        !opp.Insurance_Partner__c &&
        !opp.Reseller__c &&
        !opp.Reseller_Partner__c &&
        !opp.Teaming_Partner_Account__c &&
        !opp.Referral_Partner__c;
    }

    get partnerInvolvedOptions() {
        return [
            { label: 'Yes', value: 'true' },
            { label: 'No', value: 'false' }
        ];
    }

    handlePartnerInvolvedChange(event) {
        this.partnerInvolved = event.detail.value;
    }

    @api
    get partnerInvolvedBoolean() {
        if (this.partnerInvolved === 'true') {
            return true;
        }
        if (this.partnerInvolved === 'false') {
            return false;
        }
        return null;
    }

    handleSerialNumbersUpdate(event) {
        this.allSerialNumbersFromChild = event.detail;
        console.log('Received serial numbers from child:', JSON.stringify(this.allSerialNumbersFromChild));
    }
}