import { LightningElement, api, track } from 'lwc';
import { FlowNavigationNextEvent, FlowNavigationBackEvent } from 'lightning/flowSupport';
import updateOpportunity from '@salesforce/apex/SubmitToClosingController.updateOpportunity';
import updateAccount from '@salesforce/apex/SubmitToClosingController.updateAccount';

export default class OppotyReviewScreen extends LightningElement {
    @api account;
    @api opportunity;
    @api loggedInUser;
    @api userRole;
    @api userProfile;

    @track isEditing = false;
    @track showSpinner = false;
    @track showNotification = false;
    @track notificationMessage = '';
    @track notificationIcon = '';
    @track notificationIconVariant = '';
    @track notificationClass = '';
    @track hasLoadedData = false;

    originalAccount;
    originalOpportunity;

    // Billing Information Fields
    billingFields = [
        { label: 'Billing Street', fieldName: 'BillingStreet', required: true },
        { label: 'Billing City', fieldName: 'BillingCity', required: true },
        { label: 'Billing Country', fieldName: 'BillingCountry', required: true },
        { label: 'Billing Postal Code', fieldName: 'BillingPostalCode', required: true },
        { label: 'Billing Email', fieldName: 'Billing_Email__c', required: true }
    ];

    // Mexico-specific Fields
    mexicoFields = [
        { label: 'Razon Social', fieldName: 'Razon_Social_Legal_Company_Name__c', required: true },
        { label: 'Tipo RFC', fieldName: 'Tipo_de_RFC__c', required: true },
        { label: 'Regimen Fiscal', fieldName: 'Regimen_Fiscal_Receptor__c', required: true },
        { label: 'Regimen Capital', fieldName: 'Regimen_Capital__c', required: false }
    ];

    // Getter to check if we have all required data
    get hasRequiredData() {
        return this.account && 
               this.opportunity && 
               this.hasLoadedData;
    }

    // Helper to safely get field value
    getFieldValue(record, fieldPath) {
        if (!record) return null;
        
        const parts = fieldPath.split('.');
        let value = record;
        
        for (const part of parts) {
            if (value == null) return null;
            value = value[part];
        }
        
        return value;
    }

    // Getter for showing cable selection section
    get showCableSelectionSection() {
        return this.getFieldValue(this.loggedInUser, 'Region__c') === 'North America' &&
            this.getFieldValue(this.loggedInUser, 'Business_Unit__c') === 'Fleet' &&
            (this.getFieldValue(this.userRole, 'Name')?.includes('AE1') || 
             this.getFieldValue(this.userRole, 'Name')?.includes('AE2') || 
             this.getFieldValue(this.userRole, 'Name')?.includes('AE3')) &&
            (this.getFieldValue(this.opportunity, 'Type') === 'Revenue Opportunity' || 
             this.getFieldValue(this.opportunity, 'Type') === 'Free Trial Opportunity') &&
            !this.getFieldValue(this.opportunity, 'Name')?.includes('Webstore') &&
            this.getFieldValue(this.opportunity, 'VG_unit_count__c') > 0;
    }

    // Getter for showing free trial section
    get showFreeTrialSection() {
        return this.opportunity?.Type === 'Revenue Opportunity' &&
            !this.opportunity?.Owner_Role_Copy__c?.includes('AE1') &&
            !this.opportunity?.Owner_Role_Copy__c?.includes('Samsara Small Fleets') &&
            !this.opportunity?.Owner_Role_Copy__c?.includes('Renewal') &&
            !this.opportunity?.Name?.includes('Webstore') &&
            !this.opportunity?.Name?.includes('Evergreen');
    }

    // Getter for showing site details section
    get showSiteDetails() {
        return this.opportunity?.Sites_ACV_Bookings__c > 0;
    }

    // Getter for showing Mexico section
    get showMexicoSection() {
        return this.account?.BillingCountry === 'Mexico';
    }

    // Getter for missing billing fields
    get missingBillingFields() {
        return this.getMissingFields(this.billingFields);
    }

    // Getter for missing Mexico fields
    get missingMexicoFields() {
        return this.showMexicoSection ? this.getMissingFields(this.mexicoFields) : [];
    }

    // Getter for checking if opportunity is DCA enabled
    get isDCAEnabled() {
        return this.opportunity?.DCA_Enabled__c != null && 
               this.opportunity?.DCA_Enabled__c.startsWith('DCA') && 
               this.opportunity?.SBQQ__PrimaryQuote__c != null && 
               this.opportunity?.SBQQ__PrimaryQuote__r?.DCA_Validation__c === 'DCA';
    }

    // Getter for showing billing fields based on DCA status
    get showBillingFields() {
        return !this.isDCAEnabled;
    }

    // Getter for showing Mexico fields based on DCA status and billing country
    get showMexicoFields() {
        return this.showBillingFields && this.showMexicoSection;
    }

    // Getter for showing first purchase section
    get showFirstPurchaseSection() {
        return this.opportunity?.First_Purchase__c && 
               this.opportunity?.Owner_Role_Copy__c && 
               (this.opportunity.Owner_Role_Copy__c.includes('AE1') ||
                this.opportunity.Owner_Role_Copy__c.includes('AE2')) &&
               this.opportunity.Owner_Role_Copy__c.includes('Fleet');
    }

    // Getter for first purchase fields
    get firstPurchaseFields() {
        return [
            {
                fieldName: 'CS_POC_First_Name__c',
                required: true,
                label: 'CS POC First Name'
            },
            {
                fieldName: 'CS_POC_Email_Address__c',
                required: true,
                label: 'CS POC Email Address'
            }
        ];
    }

    // Getter for missing first purchase fields
    get missingFirstPurchaseFields() {
        if (!this.showFirstPurchaseSection) return [];
        
        return this.firstPurchaseFields.filter(field => {
            return field.required && !this.account[field.fieldName];
        }).map(field => field.label);
    }

    // All First Purchase fields to display in the section
    allFirstPurchaseFields = [
        { label: 'CS POC First Name', fieldName: 'CS_POC_First_Name__c', required: true },
        { label: 'CS POC Email Address', fieldName: 'CS_POC_Email_Address__c', required: true },
        { label: 'CS POC Phone#', fieldName: 'CS_POC_Phone__c', required: false },
        { label: 'Key Value Points', fieldName: 'Key_Value_Points__c', required: false }
    ];

    // Getter to determine if Regimen Capital is required based on Tipo de RFC
    get isRegimenCapitalRequired() {
        return this.account?.Tipo_de_RFC__c && this.account.Tipo_de_RFC__c !== 'Persona Fisica';
    }

    // Helper method to get missing fields
    getMissingFields(fields) {
        if (!this.account) return [];
        
        return fields.filter(field => {
            const value = this.account[field.fieldName];
            
            // Special handling for Regimen_Capital__c
            if (field.fieldName === 'Regimen_Capital__c') {
                // Only required if Tipo_de_RFC__c is not 'Persona Fisica'
                if (!this.isRegimenCapitalRequired) {
                    return false; // Not required for Persona Fisica
                }
                return !value || value === '';
            }
            
            // Normal required field check
            return field.required && (!value || value === '');
        }).map(field => field.label);
    }

    handleEdit() {
        this.isEditing = true;
    }

    handleCancel() {
        this.isEditing = false;
    }

    async handleSave() {
        this.showSpinner = true;
        try {
            // Get all the changed fields
            const accountChanges = this.getChangedAccountFields();
            const opportunityChanges = this.getChangedOpportunityFields();
            
            // Track updates to show correct notification
            let updatesPerformed = false;

            // Update Account if there are changes
            if (Object.keys(accountChanges).length > 0) {
                await updateAccount({
                    accountId: this.account.Id,
                    fields: accountChanges
                });
                this.originalAccount = JSON.parse(JSON.stringify(this.account));
                updatesPerformed = true;
            }

            // Update Opportunity if there are changes
            if (Object.keys(opportunityChanges).length > 0) {
                await updateOpportunity({
                    opportunityId: this.opportunity.Id,
                    fields: opportunityChanges
                });
                this.originalOpportunity = JSON.parse(JSON.stringify(this.opportunity));
                updatesPerformed = true;
            }

            // Show success message if updates were performed
            if (updatesPerformed) {
                this.showCustomNotification('success', 'Records updated successfully');
            } else {
                this.showCustomNotification('info', 'No changes detected');
            }
            
            this.isEditing = false;
            await this.refreshData();
        } catch (error) {
            console.error('Error saving changes:', error);
            this.showCustomNotification('error', error.message || 'Error saving changes');
        } finally {
            this.showSpinner = false;
        }
    }

    handleSuccess(event) {
        this.showSpinner = false;
        this.isEditing = false;
        this.showCustomNotification('success', 'Record updated successfully');
        
        // Get the updated record from the event
        const updatedRecord = event.detail.fields;
        
        // Update our local state
        if (event.target.getAttribute('object-api-name') === 'Account') {
            this.account = { ...this.account, ...updatedRecord };
            this.originalAccount = JSON.parse(JSON.stringify(this.account));
        } else if (event.target.getAttribute('object-api-name') === 'Opportunity') {
            this.opportunity = { ...this.opportunity, ...updatedRecord };
            this.originalOpportunity = JSON.parse(JSON.stringify(this.opportunity));
        }
        
        // Refresh the data
        this.refreshData();
    }

    handleError(event) {
        this.showSpinner = false;
        const errorMessage = event.detail.message || 'Error updating record';
        this.showCustomNotification('error', errorMessage);
    }

    handleSubmit() {
        this.showSpinner = true;
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

    async handleNext() {
        const accountChanged = this.hasAccountChanged();
        const opportunityChanged = this.hasOpportunityChanged();

        if (!accountChanged && !opportunityChanged) {
            // No changes, just move to next
            this.dispatchEvent(new FlowNavigationNextEvent());
            return;
        }

        this.showSpinner = true;
        try {
            if (accountChanged) {
                await updateAccount({
                    accountId: this.account.Id,
                    fields: this.getChangedAccountFields()
                });
            }
            if (opportunityChanged) {
                await updateOpportunity({
                    opportunityId: this.opportunity.Id,
                    fields: this.getChangedOpportunityFields()
                });
            }
            this.showCustomNotification('success', 'Records updated successfully');
        } catch (error) {
            this.showCustomNotification('error', error.body?.message || error.message);
            this.showSpinner = false;
            return;
        }
        this.showSpinner = false;
        this.dispatchEvent(new FlowNavigationNextEvent());
    }

    hasAccountChanged() {
        return this.getChangedAccountFields() && Object.keys(this.getChangedAccountFields()).length > 0;
    }
    hasOpportunityChanged() {
        return this.getChangedOpportunityFields() && Object.keys(this.getChangedOpportunityFields()).length > 0;
    }
    getChangedAccountFields() {
        const changed = {};
        // Compare all relevant fields (billing, first purchase, mexico, etc.)
        const fieldsToTrack = [
            // Billing Information
            'BillingStreet',
            'BillingCity',
            'BillingCountry',
            'BillingPostalCode',
            'Billing_Email__c',
            // Mexico Invoice Certification
            'Razon_Social_Legal_Company_Name__c',
            'Tipo_de_RFC__c',
            'Regimen_Fiscal_Receptor__c',
            'Regimen_Capital__c',
            // First Purchase Details
            'CS_POC_First_Name__c',
            'CS_POC_Email_Address__c',
            'CS_POC_Phone__c',
            'Key_Value_Points__c'
        ];

        // Only check fields relevant to the current context
        const relevantFields = fieldsToTrack.filter(field => {
            // Skip Mexico fields if not in Mexico
            if (['Razon_Social_Legal_Company_Name__c', 'Tipo_de_RFC__c', 'Regimen_Fiscal_Receptor__c', 'Regimen_Capital__c'].includes(field) 
                && !this.showMexicoSection) {
                return false;
            }
            
            // Skip First Purchase fields if not showing that section
            if (['CS_POC_First_Name__c', 'CS_POC_Email_Address__c', 'CS_POC_Phone__c', 'Key_Value_Points__c'].includes(field) 
                && !this.showFirstPurchaseSection) {
                return false;
            }
            
            return true;
        });

        // Check for changes in relevant fields
        relevantFields.forEach(fieldName => {
            const currentValue = this.account[fieldName];
            const originalValue = this.originalAccount[fieldName];
            
            // Handle null/undefined cases and string comparison
            if (String(currentValue || '') !== String(originalValue || '')) {
                changed[fieldName] = currentValue;
            }
        });

        return changed;
    }
    getChangedOpportunityFields() {
        const changed = {};
        // Compare all relevant fields (site deals, free trial, etc.)
        const fieldsToTrack = [
            // Free Trial Purchase Details
            'Free_Trial_Purchase__c',
            // Site Deals
            'Number_of_sites_sold__c',
            'Product_Version__c',
            'Deployment_Type__c',
            // Additional fields
            'VAT_Number__c',
            'OM_Review_Reason_Code__c',
            'CVS_Review__c'
        ];

        // Only check fields relevant to the current context
        const relevantFields = fieldsToTrack.filter(field => {
            // Skip Site Deal fields if not showing that section
            if (['Number_of_sites_sold__c', 'Product_Version__c', 'Deployment_Type__c'].includes(field) 
                && !this.showSiteDetails) {
                return false;
            }
            
            return true;
        });

        // Check for changes in relevant fields
        relevantFields.forEach(fieldName => {
            const currentValue = this.opportunity[fieldName];
            const originalValue = this.originalOpportunity[fieldName];
            
            // Handle null/undefined cases and string comparison
            if (String(currentValue || '') !== String(originalValue || '')) {
                changed[fieldName] = currentValue;
            }
        });

        return changed;
    }

    handleBack() {
        const navigateBackEvent = new FlowNavigationBackEvent();
        this.dispatchEvent(navigateBackEvent);
    }

    refreshData() {
        // Dispatch an event to refresh the data
        this.dispatchEvent(new CustomEvent('refresh'));
    }

    connectedCallback() {
        this.showSpinner = true;
        
        // Only proceed if we have both account and opportunity data
        if (this.account && this.opportunity) {
            try {
                // Store original data for change tracking
                this.originalAccount = JSON.parse(JSON.stringify(this.account));
                this.originalOpportunity = JSON.parse(JSON.stringify(this.opportunity));
                this.hasLoadedData = true;
                
                // Check for Mexico specific requirements
                if (this.showMexicoSection) {
                    this.checkAndUpdateVATNumber();
                }
            } catch (error) {
                console.error('Error in connectedCallback:', error);
                this.showCustomNotification('error', 'Error loading data: ' + error.message);
            }
        } else {
            console.error('OppotyReviewScreen: Missing required data - account or opportunity is undefined');
            this.showCustomNotification('error', 'Missing required data. Please complete the previous step first.');
            this.hasLoadedData = false;
        }
        
        this.showSpinner = false;
    }

    async checkAndUpdateVATNumber() {
        // Check if either account's billing country or opportunity's account billing country is Mexico
        const isMexicoAccount = (this.account?.BillingCountry === 'Mexico' || 
                               this.opportunity?.Account?.BillingCountry === 'Mexico');
        
        // Check if opportunity's shipping country is Mexico
        const isMexicoShipping = this.opportunity?.Shipping_Country__c === 'Mexico';
        
        // Check if opportunity type is Revenue Opportunity
        const isRevenueOpportunity = this.opportunity?.Type === 'Revenue Opportunity';
        
        // Check if account's VAT ID exists
        const hasVATId = this.account?.VATId__c != null;

        // Only proceed if all conditions are met
        if (isMexicoAccount && isMexicoShipping && isRevenueOpportunity && hasVATId) {
            try {
                this.showSpinner = true;
                
                // Update the opportunity with the VAT number from the account
                await updateOpportunity({
                    opportunityId: this.opportunity.Id,
                    fields: {
                        VAT_Number__c: this.account.VATId__c
                    }
                });

                // Update the local opportunity object
                this.opportunity = {
                    ...this.opportunity,
                    VAT_Number__c: this.account.VATId__c
                };

                this.showCustomNotification('success', 'VAT Number updated successfully');
            } catch (error) {
                console.error('Error updating VAT number:', error);
                this.showCustomNotification('error', 'Error updating VAT number: ' + (error.body?.message || error.message));
            } finally {
                this.showSpinner = false;
            }
        }
    }

    handleFieldChange(event) {
        const fieldName = event.target.fieldName;
        const value = event.target.value;
        
        // Determine if this is an Account field or Opportunity field
        if (this.account && fieldName in this.account) {
            // Update Account field
            this.account = { ...this.account, [fieldName]: value };
            
            // If this field is BillingCountry and value changes to/from Mexico, refresh Mexico fields visibility
            if (fieldName === 'BillingCountry') {
                // No need for additional processing - showMexicoFields getter will handle this automatically
            }
            
            // If Tipo_de_RFC__c field changes, handle Regimen_Capital__c field accordingly
            if (fieldName === 'Tipo_de_RFC__c') {
                if (value === 'Persona Fisica') {
                    // For Persona Fisica, Regimen_Capital__c should not be filled
                    // Clear the field if there was a value
                    if (this.account.Regimen_Capital__c) {
                        // Find the Regimen_Capital__c input field and clear it
                        const regimenCapitalField = this.template.querySelector('lightning-input-field[field-name="Regimen_Capital__c"]');
                        if (regimenCapitalField) {
                            regimenCapitalField.value = null;
                            // Also update our account object
                            this.account = { ...this.account, Regimen_Capital__c: null };
                        }
                    }
                } else {
                    // For any other value, Regimen_Capital__c is required
                    const regimenCapitalField = this.template.querySelector('lightning-input-field[field-name="Regimen_Capital__c"]');
                    if (regimenCapitalField) {
                        regimenCapitalField.required = true;
                    }
                }
            }
        } else if (this.opportunity && fieldName in this.opportunity) {
            // Update Opportunity field
            this.opportunity = { ...this.opportunity, [fieldName]: value };
            
            // If this is Sites_ACV_Bookings__c, we might need to adjust UI
            if (fieldName === 'Sites_ACV_Bookings__c') {
                // No need for additional processing - showSiteDetails getter will handle this automatically
            }
        }
    }
}