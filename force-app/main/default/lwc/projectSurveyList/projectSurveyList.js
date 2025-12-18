import { LightningElement, track, wire } from 'lwc';
import getProjects from '@salesforce/apex/GetPSAProject.getProjects';
import updateBVSSurvey from '@salesforce/apex/GetPSAProject.updateBVSSurvey';
import getUserProfileName from '@salesforce/apex/GetPSAProject.getUserProfileName';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';
import { NavigationMixin } from 'lightning/navigation';

export default class ProjectSurveyList extends NavigationMixin(LightningElement) {
    @track projects;
    @track selectedRecordIds = [];
    @track selectedSurvey = '';
    @track surveyType = '';
    @track surveyLable = '';
    @track editBVS = false;
    @track editServices = false;
    @track viewSurveys = false;
    @track isAdmin = false;
    @track columns = [];
    @track showSurveyStatus = false;
    wiredResult;

    SurveyTypes = [
        { label: 'BVS Survey', value: 'Update BVS' },
        { label: 'TSM Survey', value: 'Update TSM' },
        { label: 'Services Survey', value: 'Update Services' }
    ];

    SalesOpsSurveyTypes = [
        { label: 'BVS Survey', value: 'Update BVS' },
        { label: 'TSM Survey', value: 'Update TSM' }
    ];

    SurveyOptions = [
        { label: 'Survey Sent', value: 'Survey Sent' },
        { label: 'Cancelled', value: 'Cancelled' }
    ];

    navigateToProjectObjectHome() {
        this[NavigationMixin.Navigate]({
            type: 'standard__objectPage',
            attributes: {
                objectApiName: 'pse__proj__c',
                actionName: 'list'
            }
        });
    }

    @wire(getUserProfileName)
    wiredProfile({ error, data }) {
        if (data) {
            this.setEditPermissions(data);
        } else if (error) {
            console.error('Error fetching profile:', error);
        }
    }

    setEditPermissions(profile) {
        if (profile === 'Sales Ops Profile') {
            this.editBVS = true;
            this.surveyLable = 'Select Survey Status';
            this.surveyType = '';
            this.showSurveyStatus = false;
            this.columns = [
                { label: 'Project Id', fieldName: 'parentUrl', type: 'url',
                  typeAttributes: { label: { fieldName: 'ParentId' }, target: '_self' } },
                { label: 'Project Name', fieldName: 'parentName' },
                { label: 'BVS Survey', fieldName: 'parentBVS' },
                { label: 'TSM Survey', fieldName: 'parentTSM' },
                { label: 'Engagement Type', fieldName: 'parentType' },
                { label: 'Stage', fieldName: 'parentStage' }
            ];
        } else if (profile === 'Samsara CSM' || profile === 'Samsara CSM Management') {
            this.editServices = true;
            this.surveyLable = 'Select Services Survey Status';
            this.surveyType = 'Update Services';
            this.columns = [
                { label: 'Project Id', fieldName: 'parentUrl', type: 'url',
                  typeAttributes: { label: { fieldName: 'ParentId' }, target: '_self' } },
                { label: 'Project Name', fieldName: 'parentName' },
                { label: 'Services Survey', fieldName: 'parentServices' },
                { label: 'Engagement Type', fieldName: 'parentType' },
                { label: 'Stage', fieldName: 'parentStage' }
            ];
        } else {
            if (profile === 'System Administrator') this.isAdmin = true;
            this.viewSurveys = true;
            this.columns = [
                { label: 'Project Id', fieldName: 'parentUrl', type: 'url',
                  typeAttributes: { label: { fieldName: 'ParentId' }, target: '_self' } },
                { label: 'Project Name', fieldName: 'parentName' },
                { label: 'BVS Survey', fieldName: 'parentBVS' },
                { label: 'TSM Survey', fieldName: 'parentTSM' },
                { label: 'Services Survey', fieldName: 'parentServices' },
                { label: 'Engagement Type', fieldName: 'parentType' },
                { label: 'Stage', fieldName: 'parentStage' }
            ];
        }
    }

    @wire(getProjects)
    wiredProjects(result) {
        this.wiredResult = result;
        if (result.data) {
            this.projects = result.data.map(rec => ({
                ...rec,
                parentName: rec.Parent?.Name || '',
                parentBVS: rec.Parent?.BVS_Survey__c || '',
                parentTSM: rec.Parent?.TSM_survey__c || '',
                parentServices: rec.Parent?.Services_Survey__c || '',
                parentType: rec.Parent?.Engagement_Type__c || '',
                parentStage: rec.Parent?.pse__Stage__c || '',
                parentUrl: '/' + rec.ParentId
            }));
        } else if (result.error) {
            this.showToast('Error', result.error.body.message, 'error');
        }
    }

    handleRowSelection(event) {
        this.selectedRecordIds = event.detail.selectedRows.map(row => row.ParentId);
    }

    updateSurveyType(event) {
        this.surveyType = event.detail.value;

        if (this.surveyType === 'Update BVS') {
            this.surveyLable = 'Select: BVS Survey: Status';
        } else if (this.surveyType === 'Update TSM') {
            this.surveyLable = 'Select: TSM Survey: Status';
        } else if (this.surveyType === 'Update Services') {
            this.surveyLable = 'Select: Services Survey: Status';
        }

        this.showSurveyStatus = !!this.surveyType;
        this.selectedSurvey = '';
    }

    handleSurveyChange(event) {
        this.selectedSurvey = event.detail.value;
    }

    async handleUpdateClick() {
        if (!this.selectedRecordIds.length || !this.selectedSurvey) {
            this.showToast('Error', 'Please select at least one project and survey status.', 'error');
            return;
        }

        try {
            await updateBVSSurvey({
                projectIds: this.selectedRecordIds,
                selectedSurvey: this.selectedSurvey,
                surveyType: this.surveyType
            });
            this.showToast('Success', 'Survey updated successfully.', 'success');
            await refreshApex(this.wiredResult);
        } catch (error) {
            this.showToast('Error updating survey', error.body?.message || error.message, 'error');
        }
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }

    get filteredProjects() {
        if (!this.projects || !this.projects.length) {
            return [];
        }

        // Sales Ops filtering
        if (this.editBVS) {
            if (!this.surveyType) return [];
            if (this.surveyType === 'Update BVS') {
                return this.projects.filter(p => p.parentBVS === 'Ready to Send');
            }
            if (this.surveyType === 'Update TSM') {
                return this.projects.filter(p => p.parentTSM === 'Ready to Send');
            }
        }

        // Admin filtering
        if (this.isAdmin) {
            if (!this.surveyType) return [];
            if (this.surveyType === 'Update BVS') {
                return this.projects.filter(p => p.parentBVS === 'Ready to Send');
            }
            if (this.surveyType === 'Update TSM') {
                return this.projects.filter(p => p.parentTSM === 'Ready to Send');
            }
            if (this.surveyType === 'Update Services') {
                return this.projects.filter(p => p.parentServices === 'Ready to Send');
            }
        }

        // Other profiles → return all
        return this.projects;
    }
}