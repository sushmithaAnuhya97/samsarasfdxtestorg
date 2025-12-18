import { LightningElement, api, track } from 'lwc';
import getContractsGroupedByLogGroup from '@salesforce/apex/FlexCancelReplaceHelper.getContractsGroupedByLogGroup';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class FlexReinitiateCnrProcess extends LightningElement {
    @api accountId;
    @track groupedContracts = [];
    selectedGroupId;

    connectedCallback() {
        this.loadContracts();
    }

    async loadContracts() {
        try {
            const result = await getContractsGroupedByLogGroup({ recordId: this.accountId });
            this.groupedContracts = [];

            const formatDate = (dateStr) => {
                if (!dateStr) return '';
                const date = new Date(dateStr);
                return new Intl.DateTimeFormat('en-US', {
                    year: 'numeric',
                    month: 'long',
                    day: 'numeric'
                }).format(date);
            };

            for (let groupId in result) {
                const contracts = result[groupId].map(contract => ({
                    ...contract,
                    LastInitiatedDate: formatDate(contract.LastInitiatedDate),
                    StartDate: formatDate(contract.StartDate),
                    EndDate: formatDate(contract.EndDate)
                }));

                this.groupedContracts.push({
                    groupId,
                    isSelected: false,
                    contracts
                });
            }
        } catch (error) {
            console.error('Error loading contracts:', error);
            this.showToast('Error', 'Failed to load contracts', 'error');
            this.dispatchClose();
        }
    }

    handleGroupCheckboxChange(event) {
        const selectedGroupId = event.target.dataset.groupId;

        this.groupedContracts = this.groupedContracts.map(group => {
            return {
                ...group,
                isSelected: group.groupId === selectedGroupId
            };
        });

        this.selectedGroupId = selectedGroupId;
    }

    handleSubmit() {
        const selectedGroup = this.groupedContracts.find(g => g.isSelected);

        if (!selectedGroup) {
            this.showToast('Warning', 'Please select a contract group before submitting.', 'warning');
            return;
        }

        const groupId = selectedGroup.groupId;

        this.dispatchEvent(new CustomEvent('groupselected', {
            detail: { groupId },
            bubbles: true,
            composed: true
        }));

        this.dispatchClose();
    }

    handleCancel() {
        this.dispatchClose();
    }

    dispatchClose() {
        this.dispatchEvent(new CustomEvent('closepopup'));
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
}