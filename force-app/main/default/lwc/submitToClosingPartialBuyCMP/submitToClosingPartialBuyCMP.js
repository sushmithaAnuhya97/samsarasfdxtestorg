/**
 * @description Free Trial: Capture Free Trial Decisions and Attach CSV to Revenue Opportunity
 * @developer Riyaz Shaik
 * @jira [GTMS-24357 , GTMS-25981]
 */

import { LightningElement, track, api, wire } from 'lwc';
import { gql, graphql } from 'lightning/uiGraphQLApi';
import { FlowNavigationNextEvent,FlowNavigationBackEvent  } from 'lightning/flowSupport';
import saveCSVToOpportunity from '@salesforce/apex/SubmitToClosingPartialBuyCMPHandler.saveCSVToOpportunity';
import getDocument from '@salesforce/apex/SubmitToClosingPartialBuyCMPHandler.getDocument';
import deleteDocument from '@salesforce/apex/SubmitToClosingPartialBuyCMPHandler.deleteDocument'; 	
import CSV_FILE_NAME from '@salesforce/label/c.Submit_To_Closing_Partial_Buy_CSV_File_Name';
import Submit_To_Closing_Partial_Buy_Help_Text from '@salesforce/label/c.Submit_To_Closing_Partial_Buy_Help_Text';

const columns = [
    { label: 'Trial Opportunity Name', fieldName: 'OpportunityId', type: 'url', target: '_blank', initialWidth: 250,
				typeAttributes: {tooltip:{fieldName: 'tooltip'}, label: { fieldName: 'Name' } }},

	{ label: 'Order Number', fieldName: 'OrderNumber',cellAttributes: {
		title: { fieldName: 'OrderNumber' }}, initialWidth: 150 },

    { label: 'Product Code', fieldName: 'ProductCode',cellAttributes: {
                title: { fieldName: 'ProductCode' }}, initialWidth: 125 },

    { label: 'Serial Number', fieldName: 'serialNumber', editable: true, iconName: 'utility:prompt_edit', cellAttributes: {
        title: { fieldName: 'serialNumber' }},initialWidth: 350 },

    { label: 'Trial Quantity', fieldName: 'trialQuantity', type: 'number', cellAttributes: {
        title: { fieldName: 'trialQuantity' }},initialWidth: 125 },

    { label: 'Buying Quantity', fieldName: 'buyingQuantity',type: 'number', iconName: 'utility:prompt_edit', editable: true, cellAttributes: {
        title: { fieldName: 'buyingQuantity' }},initialWidth: 175 },

    // { label: 'Remaining Quantity', fieldName: 'remainingQuantity', cellAttributes: {
    //     title: { fieldName: 'remainingQuantity' }},initialWidth: 125 },

    { label: 'Shipping Address', fieldName: 'ShippingAddress', cellAttributes: {
        title: { fieldName: 'ShippingAddress' }},initialWidth: 200 }
];

export default class SubmitToClosingPartialBuyCMP extends LightningElement {
    @api opptyId;
	@api allProductSerialNumbers;
    @api availableActions = []; // Initialize with empty array
	@api noDataMessage;
    columns = columns;
	tempDisplayData =[];
	@track displayData = [];
	@track draftValues = [];
	paresdCSVData = [];
	errors = {rows: {}};
	csvFileName = CSV_FILE_NAME;
	showSpinner = true;
	UrlMapId;

	documentExists;
	statusMsg;
	toastType = 'success'; 
	toastTitle = 'Success'; 
	showToast = false;

	wiredDocumentReady = false;
	wiredDataReady = false;

	readyToDeletDoc = false;
	helpTextLabel= Submit_To_Closing_Partial_Buy_Help_Text;


	get queryData() {
	    return {
	        opptyId: this.opptyId
	    };
	}

	// disable next button in flow, if we get row errors in table
	get isDisabled() {
	    return this.errors && this.errors.rows ?
	        Object.keys(this.errors.rows).length > 0 :
	        false;
	}

	// hide footer if next button is not available and reference to oppotySubmitToClosingFlow.js
	get showFooter() {
		return this.availableActions && this.availableActions.includes('NEXT');
	}


	// fetching Document if exits
	@wire(getDocument, { opportunityId: '$opptyId' })
    wiredDocument({ error, data }) {
        if (data) {
			console.log('dat-->'+JSON.stringify(data))
            this.documentExists = data;
            // this.wiredDocumentReady = true;
        } else if (error) {
            this.error = error.body ? error.body.message : 'Unknown error occurred.';
			console.log(this.error);
			
            // this.wiredDocumentReady = true;
        }
		if(this.opptyId) this.wiredDocumentReady = true;
		if (this.documentExists ==undefined || this.documentExists == null || this.documentExists == '') this.readyToDeletDoc= true;
        this.checkReadiness();	
    }

	// Fetch related OpportunityLineItems using GraphQL // replace {Opportunity:{StageName: {eq: "Trial"}}} to {Opportunity:{StageName: {eq: "Closed Won"}}}
	@wire(graphql, {
	    query: gql`
            query optyLines($opptyId: ID!) {
                uiapi {
                    query {
                        OpportunityLineItem(where: { and:[{Opportunity:{TrialResolutionOppty__c:{ eq: $opptyId }}}
															{Opportunity:{StageName: {eq: "Closed Won"}}}
															{or:[{ProductCode:{like:"HW%"}}
																{ProductCode:{like:"CBL%"}}
																{ProductCode:{like:"ACC%"}}]}] }) {
                            edges {
                                node {
                                    Id
                                    Oppty_Name__c {
                                        value
                                    }
									OpportunityId {
                                        value
                                    }
                                    ProductCode {
                                        value
                                    }
                                    Quantity {
                                        value
                                    }
                                    Ship_To_Address__c {
                                        value
                                    }
									Opportunity {
										Order_Number__c
											{
												value
											}
              
									}
                                }
                            }
                        }
                    }
                }
            }
        `,
	    variables: '$queryData',
	})
	fetchOpportunityLineItems({data, errors}) {
		if (data) {
			const lines = data.uiapi.query.OpportunityLineItem.edges.map((edge) => edge.node);
			if (lines.length === 0) {
				// Check if we're in a flow and 'Next' is available
				console.log('this.availableActions-before-> '+JSON.stringify(this.availableActions));
				if (Array.isArray(this.availableActions) && this.availableActions.includes('NEXT')) {
					console.log('this.availableActions-after->'+JSON.stringify(this.availableActions));
					this.dispatchEvent(new FlowNavigationNextEvent());
				} 
				this.showSpinner = false;
				return;
			}
				this.tempDisplayData = lines.map((line) => ({
					// Id: line.Id,
					// Name: line.Oppty_Name__c.value,
					// ProductCode: line.ProductCode.value,
					// OrderNumber : line.Opportunity.Order_Number__c.value,
					// serialNumber: '',
					// trialQuantity: line.Quantity.value,
					// buyingQuantity: line.Quantity.value,
					// //remainingQuantity: 0,
					// ShippingAddress : line.Ship_To_Address__c.value || '',
					// OpportunityId: `/${line.OpportunityId.value}`,
					// tooltip: `Navigate to Opportunity: ${line.Oppty_Name__c.value}`

					Id: line?.Id,
					Name: line?.Oppty_Name__c?.value || '',
					ProductCode: line?.ProductCode?.value || '',
					OrderNumber: line?.Opportunity?.Order_Number__c?.value || '',
					serialNumber: '',
					trialQuantity: line?.Quantity?.value || 0,
					buyingQuantity: line?.Quantity?.value || 0,
					ShippingAddress: line?.Ship_To_Address__c?.value || '',
					OpportunityId: line?.OpportunityId?.value ? `/${line.OpportunityId.value}` : '',
					tooltip: `Navigate to Opportunity: ${line?.Oppty_Name__c?.value || 'N/A'}`,
				}));
				this.wiredDataReady = true;
		} else if (errors) {
	        console.error('GraphQL Errors:', errors);
	        // Dispatch event with a more detailed error message
	        this.dispatchEvent(new CustomEvent('nodata', {
	            detail: {
	                message: 'Error loading trial products. Please try again.'
	            },
	            bubbles: true,
	            composed: true
	        }));
	    }
		this.checkReadiness();
	}

	// Checking if both wires are ready and execute logic when they are
	checkReadiness() {
		if (this.wiredDocumentReady && this.wiredDataReady) {
			this.displayData = this.tempDisplayData;
			console.log('Both wires are ready, proceeding with data manipulation.');
			if (this.documentExists && this.displayData) {
				this.parseCSVData(this.documentExists); // Process the document and display data
			}
			this.showSpinner = false; 
		} else if (!Array.isArray(this.availableActions) || !this.availableActions.includes('NEXT')) {
			// Make sure spinner is turned off if not in a flow with NEXT action
			this.showSpinner = false;
		}
	}

	//Cell change event in Lightning data table to store draft values and without saving in salesforce database. this changes only reflect in csv file
	handleCellChange(event) {
		console.log(`handleCellChange-->${JSON.stringify(event)}`);
		this.draftValues = event.detail.draftValues;
		const draftValue = this.draftValues[0];
		const modifiedRowId = draftValue.Id;
		const draftBuyingQuantity = draftValue.buyingQuantity;
		const draftSerialNumber = draftValue.serialNumber;

		const product = this.displayData.find((row) => row.Id === modifiedRowId);
		if (!product) {
			console.error(`Product with Id ${modifiedRowId} not found.`);
			return;
		}
		const trialQuantity = product.trialQuantity;
		this.readyToDeletDoc = true;
		
		if (Object.hasOwn(draftValue,'buyingQuantity')) {
			// Preventing negative values for buyingQuantity
			if (Number(draftBuyingQuantity) < 0) {
				const errorMessage = `Buying quantity must always be greater than zero.`;
				this.errors.rows[modifiedRowId] = {
                    title: 'Error',
					messages: [errorMessage],
					fieldNames: ['buyingQuantity'],
				};
				product.buyingQuantity = draftBuyingQuantity; // Preserve invalid value
			}
			// Checking if buyingQuantity exceeds trialQuantity
			else if (Number(draftBuyingQuantity) > trialQuantity) {
				const errorMessage = `Buying quantity ${draftBuyingQuantity} exceeds Trial quantity ${trialQuantity}!`;
				this.errors.rows[modifiedRowId] = {
                    title: 'Error',
					messages: [errorMessage],
					fieldNames: ['buyingQuantity'],
				};
				product.buyingQuantity = draftBuyingQuantity; // Preserve invalid value
			} else {
                // Removing error if buyingQuantity is valid
                if(this.errors.rows[modifiedRowId]) delete this.errors.rows[modifiedRowId];
				product.buyingQuantity = (trialQuantity == (trialQuantity - Number(draftBuyingQuantity))) ? 0 :draftBuyingQuantity;
				//product.remainingQuantity = trialQuantity - draftBuyingQuantity;
			}
		}

		if (Object.hasOwn(draftValue,'serialNumber')) {
			product.serialNumber = draftSerialNumber;
		}

		// Update serial numbers directly
		this.updateSerialNumbers();
	}

	//Updating Serial numbers in Opportunity
	updateSerialNumbers() {
		const serialNumbers = this.displayData
			.map((row) => row.serialNumber)
			.filter((serialNumber) => serialNumber)
			.join(',');
		this.allProductSerialNumbers = serialNumbers;
		// Update the opportunity with serial numbers if using in new UI submit to closing flow
		 this.getSerialNumbers();
	}
	//Generated CSV file and save it in opportunity related list Notes and Attachments
	saveCSVToOpportunity() {
	    const csvData = this.convertToCSV(this.displayData);
	    if (!csvData) {
	        this.displayToast('error', 'Error', 'No data available to save as CSV.');
	        return;
	    }
	    const base64CSV = btoa(unescape(encodeURIComponent(csvData))); // Base64 encode CSV
	    saveCSVToOpportunity({
	            csvData: base64CSV,
	            opportunityId: this.opptyId
	        })
	        .then((result) => {

	            if (result === 'SUCCESS') {
                    this.showSpinner = false;
	                this.displayToast(
	                    'success',
	                    'Success',
	                    'CSV file has been saved in Notes & Attachments.'
	                );

	                setTimeout(() => {
						console.log('this.availableActions-before-> '+JSON.stringify(this.availableActions));
						if (Array.isArray(this.availableActions) && this.availableActions.includes('NEXT')) {
							console.log('this.availableActions-after->'+JSON.stringify(this.availableActions));
							this.dispatchEvent(new FlowNavigationNextEvent());
						} else {
							this.showSpinner = false;
						}
	                }, 3000);
	            }
	        })
	        .catch((error) => {
	            this.displayToast(
	                'error',
	                'Error',
	                error?.body?.message || 'Failed to save CSV to Opportunity Notes & Attachments.'
	            );

	        })
	}
//---------------------------------------------------------------------Converting tabel data to CSV File ---------------------------------------------------//
		convertToCSV(data) {
			if (!data || !data.length) {
				return null;
			}

			// Columns to display in CSV file
			const columnLabelMapping = {
				Name: 'Opportunity Name',
				OrderNumber: 'Order Number',
				ProductCode: 'Product Code',
				serialNumber: 'Serial Number',
				trialQuantity: 'Trial Quantity',
				buyingQuantity: 'Buying Quantity',
				//remainingQuantity: 'Remaining Quantity',
				ShippingAddress: 'Shipping Address'
			};

			// Exclude unwanted fields from CSV like Id, OpportunityId, tooltip
			const excelModifiedData = data.map(({
				Id,
				OpportunityId,
				tooltip,
				...rest
			}) => ({ ...rest, Id })); // Temporarily include Id for URL construction

			// column headers using label mapping (exclude Id)
			const columnHeader = Object.keys(excelModifiedData[0])
				.filter(key => key !== 'Id') // Exclude Id from headers
				.map(key => columnLabelMapping[key] || key)
				.join(',');

			// Get the current Salesforce instance URL
			const salesforceInstanceUrl = window.location.origin; 

			// Process rows
			const rows = excelModifiedData.map(row => {
				return Object.keys(row)
					.filter(key => key !== 'Id') // Exclude Id from the row data
					.map(key => {
						let value = row[key];

						// Format ProductCode as a clickable URL using the Id
						if (key === 'ProductCode' && row.Id) {
							const recordUrl = `${salesforceInstanceUrl}/${row.Id}`;
							value = `=HYPERLINK("${recordUrl}", "${value}")`; 
						}

						// Handle string values to escape double quotes and wrap in double quotes
						if (typeof value === 'string') {
							return `"${value.replace(/"/g, '""')}"`;
						}

						return value; // Non-string values don't need escaping
					})
					.join(',');
			});

			return `${columnHeader}\n${rows.join('\n')}`;
		}
	
//---------------------------------------------------------------------Fire Actons etc ---------------------------------------------------//
	@api handleFinish() {
		console.log('handleFinish from parent-> '+JSON.stringify(this.availableActions));
		this.showSpinner = true;
		if(!this.readyToDeletDoc) {
			this.showSpinner = false;
			console.log('this.availableActions-before-> '+JSON.stringify(this.availableActions));
			if (Array.isArray(this.availableActions) && this.availableActions.includes('NEXT')) {
				console.log('this.availableActions-after->'+JSON.stringify(this.availableActions));
				this.dispatchEvent(new FlowNavigationNextEvent());
			} else {
				this.showSpinner = false;
			}
			return;
		} else {
			this.handleDeleteDocument();
			
		}
	}

	handlePrevious() {
	    this.showSpinner = true;
	    this.dispatchEvent(new FlowNavigationBackEvent());
	}

	// delete the old document from opportunity related list Notes and Attachments if user change the values in tabel
	handleDeleteDocument() {
	    this.showDeleteSpinner = true;
	    deleteDocument({
	            opportunityId: this.opptyId
	        })
	        .then(result => {
				this.saveCSVToOpportunity();
	        })
	        .catch(error => {
	            this.displayToast('error', 'Error', `Error deleting document: ${error.body.message}`);
				console.log('errors-->'+JSON.stringify(error));
	        });
	}


	// Reusable method to display toast. As this component is using in URL Button Quick action Standard Toast message will not work
	displayToast(type, title, message) {
	    this.toastType = type;
	    this.toastTitle = title;
	    this.statusMsg = message;
	    this.showToast = true;

	    setTimeout(() => {
	        this.showToast = false;
	    }, 3000);
	}

//---------------------------------------------------------------------Converting CSV data, to display data in data table ---------------------------------------------------//

	//! for clarity check example at end of the code
	// Map of CSV headers to field API names of Columns of data table
	headerMapping = {
		"Opportunity Name": "OpportunityId", 
		"Order Number" : "OrderNumber",
		"Product Code": "ProductCode",
		"Serial Number": "serialNumber",
		"Trial Quantity": "trialQuantity",
		"Buying Quantity": "buyingQuantity",
		//"Remaining Quantity": "remainingQuantity",
		"Shipping Address": "ShippingAddress"
	};
	
	parseCSVData(base64Content) { 
		// Decode the Base64 string into a readable CSV format
		const csvData = this.decodeBase64(base64Content);
	
		// Use a regular expression to handle commas inside quotes
		const rows = this.parseCSV(csvData);
	
		// Extract headers (first row)
		const headers = rows[0];
	
		// Parse the rest of the rows
		const parsedData = [];
		for (let i = 1; i < rows.length; i++) {
			const columns = rows[i];
			let rowData = {};
			for (let j = 0; j < columns.length; j++) {
				const header = headers[j];
				const fieldName = this.headerMapping[header];
				if (fieldName) {
					let value = columns[j];
	
					// Handle ProductCode field (remove HYPERLINK formula and extract the actual value)
					if (fieldName === 'ProductCode' && value.startsWith('=HYPERLINK(')) {
						// Extract the URL and display text from the HYPERLINK formula
						const hyperlinkRegex = /=HYPERLINK\("([^"]+)",\s*"([^"]+)"\)/;
						const match = value.match(hyperlinkRegex);
						if (match) {
							const url = match[1]; // Extract the URL
							const displayText = match[2]; // Extract the display text
							value = displayText; // Use the display text as the ProductCode value
					
							// Extract the 18-character Id from the URL
							const idRegex = /([a-zA-Z0-9]{18})/; // Match 18-character IDs
							const idMatch = url.match(idRegex);
							if (idMatch) {
								rowData['ProductId'] = idMatch[0]; // Store the extracted 18-character Id in a new field
							} else {
								console.warn('No 18-character ID found in the URL:', url);
							}
						}
					}
	
					rowData[fieldName] = value; // Map the header to the field name
				}
			}
			parsedData.push(rowData);
		}
	
		this.paresdCSVData = parsedData;
		console.log('this.paresdCSVData-->', JSON.stringify(this.paresdCSVData));
		if (this.paresdCSVData.length > 0 && this.displayData.length > 0) {
			this.mergeCSVDataWithDisplayData();
		}
	}
	
	// Decode Base64 content to a string
	decodeBase64(base64Str) {
		const decodedStr = atob(base64Str);
		return decodedStr;
	}

	
	
	// Parse CSV considering commas within quoted text
	parseCSV(csvData) {
		const rows = [];
		const regex = /(?:,|\n|^)("(?:(?:"")*[^"]*)*"|[^",\n]*|(?:\n|$))/g;
		const lines = csvData.split('\n');
	
		for (const line of lines) {
			const matches = [...line.matchAll(regex)];
			const row = matches.map(match => {
				let value = match[0].replace(/^,/, ''); // Remove leading comma
				if (value.startsWith('"') && value.endsWith('"')) {
					value = value.slice(1, -1).replace(/""/g, '"'); // Remove surrounding quotes and unescape double quotes
				}
				return value;
			});
			rows.push(row);
		}
		return rows;
	}
	//-------------------------------------------------merging the data with existing tabel------------------------------------------------------//
	mergeCSVDataWithDisplayData() {
		if (!this.paresdCSVData || this.paresdCSVData.length === 0) {
			console.warn('No parsed CSV data available to merge.');
			return;
		}
	
		// Create a map from the parsed CSV data for faster lookup by ProductId
		const csvDataMap = new Map(
			this.paresdCSVData.map(row => [
				`${(row.ProductId || '').trim()}`, // Use ProductId as the unique key
				row
			])
		);
	
		// Merge with display data
		this.displayData = this.displayData.map(row => {
			const normalizedId = (row.Id || '').trim(); // Use Id for comparison
			const csvRow = csvDataMap.get(normalizedId); // Lookup matching row in CSV data
	
			if (csvRow) {
				// Merge the CSV data into the existing row
				return {
					...row, // Keep existing row data
					serialNumber: csvRow.serialNumber || row.serialNumber, // Override serialNumber if present in CSV
					buyingQuantity: csvRow.buyingQuantity || row.buyingQuantity, // Override buyingQuantity if present in CSV
					//remainingQuantity: csvRow.remainingQuantity || row.remainingQuantity, // Uncomment if needed
				};
			} else {
				console.warn(`No matching row found for ProductId: ${normalizedId}`);
				return row; // Keep the original row if no match is found
			}
		});
	}
	
	get showNoDataMessage() {
        return !this.showSpinner && (!this.displayData || this.displayData.length === 0);
    }

    get showDataTable() {
        return !this.showSpinner && this.displayData && this.displayData.length > 0;
    }

    // Add public method to get serial numbers
    @api
    getSerialNumbers() {
        const serialNumbers = this.displayData
            .map((row) => row.serialNumber)
            .filter((serialNumber) => serialNumber)
            .join(',');
        return serialNumbers;
    }
}