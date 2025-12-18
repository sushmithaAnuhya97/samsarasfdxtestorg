import { LightningElement, api, wire } from "lwc";
import invokeADRIncentiveBatchFromLWC from "@salesforce/apex/ADRIncentiveBatch.invokeADRIncentiveBatchFromLWC";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { CloseActionScreenEvent } from "lightning/actions";
import { gql, graphql } from "lightning/uiGraphQLApi";
import Id from "@salesforce/user/Id";
import { CurrentPageReference } from 'lightning/navigation';
import { loadStyle } from 'lightning/platformResourceLoader';
import hideClose from '@salesforce/resourceUrl/LWCQALit';
// custom Labels
import timeWarning from '@salesforce/label/c.ADR_Incentive_LWC_Time_Warning';
import fiscalDateWarning from '@salesforce/label/c.ADR_Incentive_LWC_Fiscal_Date_Warning';
import automationWarning from '@salesforce/label/c.ADR_Incentive_LWC_Automation_Settings_Warning';
import batchExe from '@salesforce/label/c.ADR_Incentive_LWC_Batch_Job_Execution_Info';
import genericError from '@salesforce/label/c.ADR_Incentive_LWC_Generic_error';

export default class RunADRIncentiveBatchCMP extends LightningElement {
	dateProcessed = false;
	recordIdFtech = false;
	fiscalMonthData;
	isLoading = true;

	userId = Id;
	recordId;
	//Custom Labels variabels
	timeBufferWarning = timeWarning;
	fisaclMonthEndDateWarning = fiscalDateWarning;
	automationSettingWarning = automationWarning;
	batchJobExecInfo = batchExe;
	genericErrorStatus= genericError;
	// to load custom styles and remove Quick action close button 
	connectedCallback(){
        loadStyle(this, hideClose);
    }

	@wire(CurrentPageReference)
    getStateParameters(currentPageReference) {
        if (currentPageReference) {
            this.recordId = currentPageReference.state.recordId; 
			this.recordIdFtech = true;
        }
    }

	//Get Period Data and check if the current date is in EOM
	@wire(graphql, {
		query: gql`
			query fiscalMonth {
				uiapi {
					query {
						Period(
							where: {
								and: [
									{
										or: [
											{ EndDate: { eq: { literal: TODAY } } }
											{ EndDate: { eq: { literal: TOMORROW } } }
										]
									}
									{ Type: { eq: "Month" } }
								]
							}
						) {
							edges {
								node {
									EndDate {
										value
									}
								}
							}
						}
					}
				}
			}
		`,
	})
	graphqlQueryResult({ data, errors }) {
		if (data) {
			this.fiscalMonthData = data.uiapi.query.Period.edges.map((edge) => edge.node);
			this.dateProcessed = true;
		} else if(errors) {
			this.showError('Fiscal Month Data',errors);
			this.closeQuickAction();
		}
		
		
		if(this.dateProcessed && this.recordIdFtech){
			this.processData();
		}
	}


	processData() {
		this.isLoading = false;
		if (this.fiscalMonthData?.length!=1) {
			this.showToast("Warning", this.fisaclMonthEndDateWarning , "warning");
			this.closeQuickAction();
		} else if (this.fiscalMonthData) {
			this.runBatchJob();	
		}else{
			this.showError('Fiscal Month Data',errors);
		}
	}
	
	runBatchJob() {
		invokeADRIncentiveBatchFromLWC({
			userId: this.userId,
			initiatedByAgent: true,
			recordId: this.recordId
		}) .then((result) => {
			this.jobStatus = result
			if(this.jobStatus){
				this.showToast("Info",this.batchJobExecInfo,"info");
				this.closeQuickAction();
			}else if(!this.jobStatus){
				this.showToast("Warning","Recalculation Transfer points is in progress ","warning");
				this.closeQuickAction();
			}else{
				this.showToast('Error', this.genericErrorStatus, 'error');
				this.closeQuickAction();
			}
		}).catch((error) => {
			this.showError('invoke batch',error.body.message);
		}).finally(() => this.closeQuickAction());
	}

	showError(description, errorMessage){
			this.showToast('Error', this.genericErrorStatus, 'error');
			console.log(`Failed to ${description}-->${errorMessage}`);
	}

	showToast(title, message, variant) {
		const event = new ShowToastEvent({
			title,
			message,
			variant,
		});
		this.dispatchEvent(event);
	}

	closeQuickAction() {
			this.dispatchEvent(new CloseActionScreenEvent());
	}
}