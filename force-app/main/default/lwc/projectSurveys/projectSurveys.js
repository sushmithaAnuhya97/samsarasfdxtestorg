import { LightningElement, track, wire } from 'lwc';
import getProjects from '@salesforce/apex/GetPSAProject.getProjects';
import updateBVSSurvey from '@salesforce/apex/GetPSAProject.updateBVSSurvey';
import getUserProfileName from '@salesforce/apex/GetPSAProject.getUserProfileName';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';
import { NavigationMixin } from 'lightning/navigation';

export default class projectSurveys extends NavigationMixin(LightningElement) {
    @track projects;
    @track selectedRecordIds = [];
    @track selectedSurvey = '';
    @track surveyTypes;
    @track surveyType = '';
    @track surveyLable = '';
    @track editBVS = false;
    @track editServices = false;
    @track viewSurveys = false;
    @track flag = true;
    @track columns = [];

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
            if (data === 'System Administrator') {
                this.surveyTypes = [
                    { label: 'BVS Survey', value: 'Update BVS' },
                    { label: 'TSM Survey', value: 'Update TSM' },
                    { label: 'Services Survey', value: 'Update Services' }
                ]; 
                this.viewSurveys = true;
            }
            else if(data  === 'Sales Ops Profile'){
                this.surveyTypes = [
                    { label: 'BVS Survey', value: 'Update BVS' },
                    { label: 'TSM Survey', value: 'Update TSM' }
                ]; 
                this.viewSurveys = true;
            }
            else if(data  === 'Samsara CSM' || data === 'Samsara CSM Management'){
                this.surveyTypes = [
                    { label: 'Services Survey', value: 'Update Services' }
                ]; 
                this.viewSurveys = true;
            }
        } else if (error) {
            console.error('Error fetching profile:', error);
        }
    }

    handleRowSelection(event) {
        this.selectedRecordIds = event.detail.selectedRows.map(row => row.ParentId);
    }

    async updateSurveyType(eventOrValue){
        let surveyTypeValue = (typeof eventOrValue === 'string') ? eventOrValue : eventOrValue.detail.value;
        this.surveyType = surveyTypeValue;
        this.projects = [];
        try{
            const data = await getProjects({ surveyType: this.surveyType });
        
            if(this.surveyType == 'Update BVS'){
            this.surveyLable = 'Select: BVS Survey: Status';
         
            this.projects = data.map(rec => ({
                ...rec,
                parentName: rec.Parent?.Name || '',
                parentBVS: rec.Parent?.BVS_Survey__c || '',
                parentType: rec.Parent?.Engagement_Type__c || '',
                parentStage: rec.Parent?.pse__Stage__c || '',
                parentCreditedHours: rec.Parent?.pse__Credited_Non_Billable_Internal_Hours__c || '',
                parentEndDate: rec.Parent?.pse__End_Date__c || '',
                parentUrl: '/' + rec.ParentId
            }));
            this.columns = [
                { label: 'Project Id', fieldName: 'parentUrl', type: 'url',
                  typeAttributes: {
                    label: { 
                        fieldName: 'ParentId' 
                    },
                    target: '_self'
                }},
                { label: 'Project Name', fieldName: 'parentName' },
                { label: 'BVS Survey', fieldName: 'parentBVS' },
                { label: 'Engagement Type', fieldName: 'parentType' },
                { label: 'Stage', fieldName: 'parentStage' },
                { label: 'Credited Hours', fieldName: 'parentCreditedHours' },
                { label: 'End Date', fieldName: 'parentEndDate' }
            ];
            
            this.flag = false;
            }
            else if(this.surveyType == 'Update Services'){
            this.surveyLable = 'Select: Services Survey: Status';
         
            this.projects = data.map(rec => ({
                ...rec,
                parentName: rec.Parent?.Name || '',
                parentServices: rec.Parent?.Services_Survey__c || '',
                parentType: rec.Parent?.Engagement_Type__c || '',
                parentStage: rec.Parent?.pse__Stage__c || '',
                parentEndDate: rec.Parent?.pse__End_Date__c || '',
                parentUrl: '/' + rec.ParentId
            }));
            this.columns = [
                { label: 'Project Id', fieldName: 'parentUrl', type: 'url',
                  typeAttributes: {
                    label: { 
                        fieldName: 'ParentId' 
                    },
                    target: '_self'
                }},
                { label: 'Project Name', fieldName: 'parentName' },
                { label: 'Services Survey', fieldName: 'parentServices' },
                { label: 'Engagement Type', fieldName: 'parentType' },
                { label: 'Stage', fieldName: 'parentStage' },
                { label: 'End Date', fieldName: 'parentEndDate' }
            ];
            
            this.flag = false;
            }
            else if(this.surveyType == 'Update TSM'){
            this.surveyLable = 'Select: TSM Survey: Status';
        
            this.projects = data.map(rec => ({
                ...rec,
                parentName: rec.Parent?.Name || '',
                parentTSM: rec.Parent?.TSM_survey__c || '',    
                parentStage: rec.Parent?.pse__Stage__c || '',                
                parentTSMProjectType: rec.Parent?.TSM_Project_Type__c || '',
                parentGroupName: rec.Parent?.pse__Group__r?.Name || '',
                parentCreditedHours: rec.Parent?.pse__Credited_Non_Billable_Internal_Hours__c || '',
                parentEndDate: rec.Parent?.pse__End_Date__c || '',
                parentUrl: '/' + rec.ParentId
            }));
            this.columns = [
                { label: 'Project Id', fieldName: 'parentUrl', type: 'url',
                  typeAttributes: { label: { fieldName: 'ParentId' }, target: '_self' } },
                { label: 'Project Name', fieldName: 'parentName' },
                { label: 'TSM Survey', fieldName: 'parentTSM' },
                { label: 'Stage', fieldName: 'parentStage' },
                { label: 'TSM Project Type', fieldName: 'parentTSMProjectType' },
                { label: 'Group Name', fieldName: 'parentGroupName' },
                { label: 'Credited Hours', fieldName: 'parentCreditedHours' },
                { label: 'End Date', fieldName: 'parentEndDate' }
            ];
            
            this.flag = false;
            }
        } catch(error) {
            //this.wiredResult = { error };
            this.showToast('Error', error.body.message, 'error');
        };      
      
    }

    handleSurveyChange(event) {
        debugger;
        this.selectedSurvey = event.detail.value;
    }

    async handleUpdateClick() {
        if (!this.selectedSurvey || this.selectedRecordIds.length === 0) {
            this.showToast('Warning', 'Select records and BVS/Services Survey before updating.', 'warning');
            return;
        }
        try{
            await updateBVSSurvey({ projectIds: this.selectedRecordIds, selectedSurvey: this.selectedSurvey, surveyType: this.surveyType });            
            this.showToast('Success', 'Only valid records with "Ready to Send" were updated.', 'success');                
            await this.updateSurveyType(this.surveyType);
                                    
        } catch(error) {
            this.showToast('Error updating records', error.body.message, 'error');
        } finally{        
            this.flag = true;
            this.surveyType = '';
        }
    }

    showToast(title, message, variant) {
        this.dispatchEvent(
            new ShowToastEvent({
                title,
                message,
                variant,
            }),
        );
    }
}