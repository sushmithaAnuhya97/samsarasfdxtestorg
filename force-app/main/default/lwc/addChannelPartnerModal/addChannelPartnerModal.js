import { LightningElement, api, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { FlowNavigationNextEvent, FlowNavigationBackEvent } from 'lightning/flowSupport';
import { CurrentPageReference } from 'lightning/navigation';
import { CloseActionScreenEvent } from 'lightning/actions';
import { NavigationMixin } from 'lightning/navigation';

import getActivePartners from '@salesforce/apex/ChannelPartnerController.getActivePartners';
import getPartnerPrograms from '@salesforce/apex/ChannelPartnerController.getPartnerPrograms';
import getPartnerContacts from '@salesforce/apex/ChannelPartnerController.getPartnerContacts';
import createChannelRelationship from '@salesforce/apex/ChannelPartnerController.createChannelRelationship';
import { refreshView } from 'lightning/navigation'; // Import refreshView from navigation
import getActivePartnerAccountIds from '@salesforce/apex/ChannelPartnerController.getActivePartnerAccountIds';

export default class AddChannelPartnerModal extends NavigationMixin(LightningElement) {
    @track selectedPartnerId;
    @track selectedProgramId;
    @track selectedContactId;
    @track selectedConId;
    @track partnerEngagementType;
    @track salesProgramType;
    @track productType;
    @track numberOfUnits;
    @track isClosed = false;
    @track isLoading = false;
    @track IsSubsidyProgram = false;
    @track partners = [];
    @track programs = [];
    @track contacts = [];
    @track programsType = {};
    @track programsContact = {};
    @track engagementTypeOptions = [{ label: 'Partner Sourced', value: 'Partner Sourced' }, { label: 'Partner Influenced', value: 'Partner Influenced' }];
    @track productTypes = [
        { label: 'CM33', value: 'CM33' },
        { label: 'CM34', value: 'CM34' }
    ];
    @track isResellerTransacting;
    @track yesNoOptions = [
        { label: 'Yes', value: 'Yes' },
        { label: 'No', value: 'No' }
    ];
    @track opportunityName;
    @track opportunityStage;
    @track customerAccountName;
    @track oppRecordTypeName;
    @track selectedSystemIntegratorId;
    @track ServiceAmount;
    @track isPartner = true;
    @track isIndustrialOpportunity = false;
    @track isChannelRelationshipExist = false;
    @track isPartnerNotExist = false;
    @track isSystemsIntegratorsValue;
    @track isSystemsIntegrators = false;
    @track isReseller = false;
    @track isResellerContact = false;
    @track isSelectOneOption = false;
    @api wireRecordId; //this will hold the current record id fetched from pagereference
    @api isFlow = false; //this will be used to check if the component is used in flow or not
    @track filter;
    @track partnerFilter = {
        criteria: [
            {
                fieldPath: 'RecordType.DeveloperName',
                operator: 'eq',
                value: 'Partner',
            },
        ],
    };

    @wire(getActivePartnerAccountIds)
    wiredAccountIds({ error, data }) {
        if (data) {
            this.filter = {
                criteria: [
                    {
                        fieldPath: 'RecordType.DeveloperName',
                        operator: 'eq',
                        value: 'Partner',
                    },
                    {
                        fieldPath: 'Partner_Status__c',
                        operator: 'eq',
                        value: 'Transacting Partner',
                    },
                    {
                        fieldPath: 'Id',
                        operator: 'in',
                        value: data
                    }
                ],
                filterLogic: '1 AND 2 AND 3',
            };
        } else if (error) {
            console.error('Error fetching account IDs:', error);
        }
    }

    @wire(CurrentPageReference)
    getStateParameters(currentPageReference) {
        if (currentPageReference) {
            console.log('currentPageReference ', currentPageReference);
            //it gets executed before the connected callback and avilable to use
            if (this.wireRecordId === undefined) {
                this.wireRecordId = currentPageReference.state.recordId;
                console.log('this.wireRecordId', this.wireRecordId);
            }

        }
    }

    connectedCallback() {
        this.loadOpportunityDetails();
    }

    handleResellerTransactingChange(event) {
        this.isResellerTransacting = event.detail.value;
        if (this.isResellerTransacting === 'Yes') {
            this.isPartner = true;
        } else {
            this.isPartner = false;
        }
    }
    handleSystemsIntegratorChange(event) {
        this.isSystemsIntegratorsValue = event.detail.value;
        if (this.isSystemsIntegratorsValue === 'Yes') {
            this.isSystemsIntegrators = true;
        } else {
            this.isSystemsIntegrators = false;
        }
    }
    loadOpportunityDetails() {
        console.log('loadOpportunityDetails', this.wireRecordId);
        this.isLoading = true;
        // Load opportunity and customer account details for display
        getActivePartners({ opportunityId: this.wireRecordId })
            .then(result => {
                console.log('partners result', result);
                this.opportunityName = result.opportunityName;
                this.opportunityStage = result.currStageName;
                this.isClosed = result.isClosed;
                this.customerAccountName = result.customerAccountName;
                this.oppRecordTypeName = result.oppRecordTypeName;
                this.partners = result.partners.map(partner => ({ label: partner.Name, value: partner.Id }));
                if (this.oppRecordTypeName === 'Industrial_Opportunity') {
                    this.isIndustrialOpportunity = true;
                    this.isPartner = false;
                }
                this.isLoading = false;
            })
            .catch(error => {
                this.handleError(error);
            });
        console.log('partners', this.partners);
        console.log('programs', this.opportunityName);
        console.log('customerAccountName', this.customerAccountName);
        console.log('opportunityStage', this.opportunityStage);
        console.log('oppRecordTypeName', this.oppRecordTypeName);
        console.log('isClosed', this.isClosed);
    }

    handlePartnerChange(event) {
        this.selectedPartnerId = event.detail.recordId;
        this.selectedProgramId = null;
        this.selectedContactId = null;
        this.loadPartnerPrograms();
        this.loadPartnerContacts();
    }

    handleProgramChange(event) {
        this.selectedProgramId = event.detail.value;
        this.salesProgramType = this.getValueByKeySalesPrograms(this.selectedProgramId);
        this.selectedContactId = this.getValueByKeyProgramsContact(this.selectedProgramId);
        console.log('selectedContactId', this.selectedContactId);
        console.log('salesProgramType', this.salesProgramType);
        console.log('selectedProgramId', this.selectedProgramId);
        if (this.salesProgramType === 'Subsidy') {
            this.IsSubsidyProgram = true;
        } else {
            this.IsSubsidyProgram = false;
        }
    }

    handleContactChange(event) {
        this.selectedContactId = event.detail.value;
    }

    handleEngagementTypeChange(event) {
        this.partnerEngagementType = event.detail.value;
    }

    handleProductTypeChange(event) {
        this.productType = event.detail.value;
    }

    handleNumberOfUnitsChange(event) {
        this.numberOfUnits = event.detail.value;
    }

    loadPartnerPrograms() {
        if (this.selectedPartnerId) {
            this.isLoading = true;
            getPartnerPrograms({ partnerId: this.selectedPartnerId })
                .then(result => {
                    console.log('Programs result', result);
                    this.programs = result.map(program => ({ label: program.Partner_Program__r.Name, value: program.Partner_Program__c }));
                    // Populate programsType
                    result.forEach(programType => {
                        this.addKeyValuePairSalesPrograms(programType.Partner_Program__c, programType.SalesProgramType__c);
                    });

                    // Populate programsContact
                    result.forEach(programContact => {
                        this.addKeyValuePairProgramsContact(programContact.Partner_Program__c, programContact.Partner_Contact__c);
                    });

                    console.log('Programs', JSON.stringify(this.programs));
                    console.log('ProgramsType', JSON.stringify(this.programsType));
                    console.log('ProgramsContact', JSON.stringify(this.programsContact));
                    this.isLoading = false;
                })
                .catch(error => {
                    this.handleError(error);
                });
        }

    }

    loadPartnerContacts() {
        if (this.selectedPartnerId) {
            this.isLoading = true;
            getPartnerContacts({ partnerId: this.selectedPartnerId })
                .then(result => {
                    console.log('contacts result', result);
                    this.contacts = result.map(contact => ({ label: contact.Name, value: contact.Id }));
                    this.isLoading = false;
                })
                .catch(error => {
                    this.handleError(error);
                });
        }
    }

    handleSystemIntegratorChange(event) {
        this.selectedSystemIntegratorId = event.detail.recordId;
    }

    handleServiceAmountChange(event) {
        this.ServiceAmount = event.detail.value;
    }

    saveChannelRelationship() {
        if (!this.validateInputs()) return;

        this.isLoading = true;
        if (this.isResellerTransacting === 'No' && this.isSystemsIntegratorsValue === 'No') {
            this.isSelectOneOption = true;
            this.isLoading = false;
            return;
        }
        createChannelRelationship({
            opportunityId: this.wireRecordId,
            partnerId: this.selectedPartnerId,
            programId: this.selectedProgramId,
            contactId: this.selectedContactId,
            engagementType: this.partnerEngagementType,
            programType: this.salesProgramType,
            productType: this.productType,
            numberOfUnits: this.numberOfUnits,
            systemIntegratorsId: this.selectedSystemIntegratorId,
            serviceAmount: this.ServiceAmount,
            isPartner: this.isPartner
        })
            .then(result => {
                console.log('CreateChannelRelationship result', result);
                this.isLoading = false;
                this.isChannelRelationshipExist = false;
                if (result === 'Channel Relationship already exists') {
                    this.isChannelRelationshipExist = true;
                    return;
                } else if (result === 'Not find the partner') {
                    this.isPartnerNotExist = true;
                    return;
                } else {
                    if (this.isFlow === true) {
                        // Navigate to the next step in the Flow
                        const nextEvent = new FlowNavigationNextEvent();
                        this.dispatchEvent(nextEvent);
                    } else {
                        // Close the modal
                        this.closeQuickAction();
                    }
                    this.dispatchEvent(new ShowToastEvent({
                        title: 'Success',
                        message: 'Channel Partner added successfully',
                        variant: 'success'
                    }));
                }
            })
            .catch(error => {
                console.log('error', error);
                this.handleError(error);
            });
    }

    validateInputs() {
        // Validate all required fields are selected
        const allValid = [...this.template.querySelectorAll('lightning-record-picker,lightning-combobox,lightning-input')]
            .reduce((validSoFar, inputField) => {
                inputField.reportValidity();
                return validSoFar && inputField.checkValidity();
            }, true);
        return allValid;
    }

    handleError(error) {
        this.isLoading = false;
        this.dispatchEvent(new ShowToastEvent({
            title: 'Error',
            message: error.body ? error.body.message : 'Unknown error',
            variant: 'error'
        }));
    }
    closeQuickAction() {
        this.dispatchEvent(new CloseActionScreenEvent());

    }
    handleBack() {
        const backEvent = new FlowNavigationBackEvent();
        this.dispatchEvent(backEvent);
    }
    refreshPage() {
        // Reloads the current page by navigating to it again
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.wireRecordId,   // Record ID of the current page
                objectApiName: 'Opportunity',  // Object name of the current record
                actionName: 'view'         // Action to perform (view)
            }
        });
    }
    handleAction() {
        // Perform your action logic here
        // After action is complete, refresh the page
        this.refreshPage();
    }

    // Function to add key-value pairs dynamically
    addKeyValuePairSalesPrograms(key, value) {
        this.programsType[key] = value;
    }

    // Function to get value by key
    getValueByKeySalesPrograms(key) {
        return this.programsType[key];
    }

    // Function to add key-value pairs dynamically
    addKeyValuePairProgramsContact(key, value) {
        this.programsContact[key] = value;
    }

    // Function to get value by key
    getValueByKeyProgramsContact(key) {
        return this.programsContact[key];
    }

}