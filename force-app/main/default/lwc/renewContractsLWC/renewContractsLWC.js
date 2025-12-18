import { LightningElement,track,wire } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import LightningConfirm from 'lightning/confirm';
import getAccountAndActiveContracts from '@salesforce/apex/RenewContractsLWC.getAccountAndActiveContracts';
import renewContracts from '@salesforce/apex/RenewContractsLWC.renewContracts';
import getQuarterPeriod from '@salesforce/apex/RenewContractsLWC.getQuarterPeriod';
import getFiscalYears from '@salesforce/apex/RenewContractsLWC.getFiscalYears';
import getCurrentQuarterAndYear from '@salesforce/apex/RenewContractsLWC.getCurrentQuarterAndYear';
import isSystemAdministrator from '@salesforce/apex/RenewContractsLWC.isSystemAdministrator';
export default class RenewContractsLWC extends LightningElement {
    accid;
    showError=false;
    errorMessage='';
    pageTitle='';
    closeDateSortIcon = 'utility:arrowdown'; 
    isSortedDesc = true; 
    @track isLoading = false; 

    @track isSystemAdministrator = false;
    @track showFilterControls = true;
    @track toggleFilterLabel = 'Show Filters';
    @track selectedQuarter;
    @track selectedYear;
    @track allContracts = [];
    @track currentYear;
    @track allFiscalYears = [];
    @track yearOptions = [];      
    currentFiscalYearName;        
    currentQuarter;Number;      
    @track currentQuarter;

    quarterOptions = [
        { label: 'Q1', value: '1' },
        { label: 'Q2', value: '2' },
        { label: 'Q3', value: '3' },
        { label: 'Q4', value: '4' }
    ];


   get dynamicQuarterOptions() {
        let quarters = [...this.quarterOptions]; // [{label:'Q1', value:'1'}, ...]
        if (this.isSystemAdministrator) {
            quarters.push({ label: 'Show All', value: 'showAll' });
            return quarters;
        }

        // Normal users
        const selectedYearName = this.selectedYear;
        const currentYearName = this.currentFiscalYearName;

        const selectedIdx = this.getFiscalYearIndexByName(selectedYearName);
        const currentIdx = this.getFiscalYearIndexByName(currentYearName);

        if (selectedIdx < 0 || currentIdx < 0) return []; // defensively hide until data lands

        if (selectedIdx === currentIdx) {
            // current FY: show current & future quarters only
            return quarters.filter(q => parseInt(q.value, 10) >= this.currentQuarter);
        } else if (selectedIdx < currentIdx) {
            // past FY (shouldn't appear for normal users anyway)
            return [];
        }
        // future FY: show all quarters
        return quarters;
    }


    // Getter to check if there are contracts to display in table (1 or more)
    get hasActiveContracts() {
        return this.activeContracts && this.activeContracts.length > 0;
    }

    // Getter to check if there are sufficient contracts for renewal (need at least 2)
    get hasSufficientContracts() {
        return this.activeContracts && this.activeContracts.length >= 2;
    }

    // Getter to show "No records found" message when 0 contracts
    get showNoRecordsMessage() {
        return !this.isLoading && !this.showError && this.activeContracts && 
               this.activeContracts.length === 0;
    }

    // Getter to show warning when only 1 contract
    get showInsufficientContractsWarning() {
        return !this.isLoading && !this.showError && this.activeContracts && 
               this.activeContracts.length === 1;
    }

    // Getter to check if "Show All" is selected
    get isShowAllSelected() {
        return this.selectedQuarter === 'showAll';
    }

    @wire(isSystemAdministrator)
    wiredIsSystemAdministrator({ error, data }) {
        if (data) {
            this.isSystemAdministrator = data;
            this.showFilterControls = true;
        } else if (error) {
            console.error('Error checking System Administrator status:', error);
            this.isSystemAdministrator = false;
            this.showFilterControls = true;
        }
    }

    @wire(getFiscalYears, { accId: '$accid' })
    wiredFiscalYears({ error, data }) {
        if (data) {
            // data is List<FiscalYearDTO> with { name, startDate, endDate }
            this.allFiscalYears = data.map(fy => ({
                name: fy.name,
                // normalize to real Date for comparisons
                startDate: new Date(fy.startDate),
                endDate: new Date(fy.endDate)
            }));
            this.filterYearOptions();
        } else if (error) {
            console.error('Error fetching fiscal years:', error);
            this.yearOptions = [];
            this.allFiscalYears = [];
        }
    }

    filterYearOptions() {
        if (!this.allFiscalYears?.length || !this.currentFiscalYearName) {
            this.yearOptions = [];
            return;
        }

        const currentIdx = this.getFiscalYearIndexByName(this.currentFiscalYearName);
        if (currentIdx < 0) {
            this.yearOptions = [];
            return;
        }

        if (this.isSystemAdministrator) {
            const yearsWithContracts = this.getYearsWithContracts(); // Set of FY names
            this.yearOptions = this.allFiscalYears
                .filter((fy, idx) => idx >= currentIdx || yearsWithContracts.has(fy.name))
                .map(fy => ({ label: fy.name, value: fy.name }));
        } else {
            this.yearOptions = this.allFiscalYears
                .filter((fy, idx) => idx >= currentIdx)
                .map(fy => ({ label: fy.name, value: fy.name }));
        }
    }


    getYearsWithContracts() {
        const years = new Set();
        if (this.allContracts?.length && this.allFiscalYears?.length) {
            for (const contract of this.allContracts) {
                const end = contract?.c?.EndDate ? new Date(contract.c.EndDate) : null;
                if (!end) continue;
                const fy = this.allFiscalYears.find(fy => end >= fy.startDate && end <= fy.endDate);
                if (fy) years.add(fy.name);
            }
        }
        return years; // Set of FY names
    }


    @wire(getCurrentQuarterAndYear)
    wiredPeriod({ data, error }) {
        if (data) {
            this.currentQuarter = parseInt(data.quarter, 10); 
            // IMPORTANT: use the fiscal year name as-is (e.g., "FY2026")
            this.currentFiscalYearName = data.year;

            // Re-filter now that we know current FY
            this.filterYearOptions();

            if (this.isSystemAdministrator) {
                this.selectedQuarter = 'showAll';
                this.selectedYear = 'none';
            } else {
                this.selectedQuarter = data.quarter;     // "1".."4"
                this.selectedYear = data.year;           // "FY2026"
            }

            if (this.allContracts && this.allContracts.length > 0) {
                this.filterContractsByQuarterYear();
            }
        } else if (error) {
            console.error('Error fetching current quarter/year:', error);
            // Fallback: pick the last FY (most recent) as current
            if (this.allFiscalYears.length) {
                const last = this.allFiscalYears[this.allFiscalYears.length - 1];
                this.currentFiscalYearName = last.name;
            }
            if (this.isSystemAdministrator) {
            this.selectedQuarter = 'showAll';
            this.selectedYear = 'none';
            } else {
                this.selectedQuarter = '1';
                this.selectedYear = this.currentFiscalYearName || 'none';
            }
        }
    }

    getFiscalYearIndexByName(name) {
        return this.allFiscalYears.findIndex(fy => fy.name === name);
    }
 
    @wire(CurrentPageReference)
    currentPageReference;
    @wire(getAccountAndActiveContracts, { accId: '$accid' })
    wiredAccountData({ error, data }) {
        console.log('data===',JSON.stringify(data));
        
        if (data) {
            console.log('inside if 1====');
            this.isLoading = true; // Show spinner while processing
    
            if (data.errorMessage) {
                console.log('inside if 2====');
                this.pageTitle='Renew Contracts for '+data.accountName;
                this.errorMessage = data.errorMessage;
                this.activeContracts = null;
                this.showError=true;
                this.isLoading = false; // Hide spinner
                console.log('inside if errorMessage===='+this.errorMessage);
            } else {
                console.log('inside else====');
                this.pageTitle='Renew Contracts for '+data.accountName;
                this.allContracts = JSON.parse(JSON.stringify(data.activeContracts));;
                console.log('this.allContracts====',JSON.stringify(this.allContracts));
                this.showError=false;
                this.errorMessage='';
                
                // Re-filter year options now that we have contracts
                this.filterYearOptions();
                
                // For System Administrators, show all contracts sorted by closest end date
                if (this.isSystemAdministrator && !this.showFilterControls) {
                    this.sortContractsByClosestEndDate();
                } else {
                    // Apply initial filter based on default quarter/year (spinner handled in filterContractsByQuarterYear)
                    this.filterContractsByQuarterYear();
                }
            }
        } else if (error) {
            console.error('Error retrieving Account and Active Contracts:', error);
            this.activeContracts = null;
            this.errorMessage = 'An error occurred while retrieving data.';
            this.showError=true;
            this.isLoading = false; // Hide spinner
        }
    }


    sortContractsByClosestEndDate() {
        if (this.allContracts && this.allContracts.length > 0) {
            const today = new Date();
            this.activeContracts = JSON.parse(JSON.stringify(this.allContracts));
            this.activeContracts.sort((a, b) => {
                const aEndDate = new Date(a.c.EndDate);
                const bEndDate = new Date(b.c.EndDate);
                const aDiff = Math.abs(aEndDate - today);
                const bDiff = Math.abs(bEndDate - today);
                return aDiff - bDiff; 
            });
        }
        this.isLoading = false;
    }

    // Handle Quarter and Year Change
    handleQuarterChange(event) {
        this.selectedQuarter = event.detail.value;
        console.log('selectedQuarter==='+this.selectedQuarter);
        if (this.selectedQuarter === 'showAll') {
            // When "Show All" is selected, set year to "none" and show all contracts
            this.selectedYear = 'none';
            this.showAllContracts();
        } else {
            // Regular quarter selected, apply normal filtering
            this.filterContractsByQuarterYear();
        }
    }

    handleYearChange(event) {
        this.selectedYear = event.detail.value;
        console.log('selectedYear==='+this.selectedYear);
        // If "Show All" is selected and user changes year, revert to normal filtering
        if (this.selectedQuarter === 'showAll' && this.selectedYear !== 'none') {
            this.selectedQuarter = '1'; // Default to Q1
            this.filterContractsByQuarterYear();
        } else if (this.selectedQuarter !== 'showAll') {
            this.filterContractsByQuarterYear();
        }
    }

     // Method to show all contracts (admin view)
    showAllContracts() {
        if (this.allContracts && this.allContracts.length > 0) {
            this.isLoading = true;
            this.activeContracts = JSON.parse(JSON.stringify(this.allContracts));
            this.sortContractsByClosestEndDate();
            this.isLoading = false;
        }
    }

    // Fetch Period Start/End Date and Filter Contracts Dynamically
    filterContractsByQuarterYear() {
        // If "Show All" is selected, show all contracts
        if (this.selectedQuarter === 'showAll') {
            this.showAllContracts();
            return;
        }
        // If quarter/year not set yet, or no contracts loaded, just show all contracts
        if (!this.selectedQuarter || !this.selectedYear || !this.allContracts || this.allContracts.length === 0) {
            if (this.allContracts && this.allContracts.length > 0) {
                this.activeContracts = JSON.parse(JSON.stringify(this.allContracts));
            }
            this.isLoading = false; // Hide spinner
            return;
        }

        this.isLoading = true; // Show spinner during filtering
        getQuarterPeriod({
            quarterNumber: parseInt(this.selectedQuarter, 10),
            fiscalYearName: this.selectedYear
        })
            .then(period => {
                if (period && period.StartDate && period.EndDate) {
                    const startDate = new Date(period.StartDate);
                    const endDate = new Date(period.EndDate);
                    let allContractsCopy = JSON.parse(JSON.stringify(this.allContracts));
                    this.activeContracts = allContractsCopy.filter(c => {
                        const cEnd = new Date(c.c.EndDate);
                        // Filter contracts that end within the selected quarter
                        return cEnd >= startDate && cEnd <= endDate;
                    });
                    if (this.activeContracts.length === 0) {
                        console.log('No matches found for selected quarter/year');
                    }
                    console.log('Filtered activeContracts===', JSON.stringify(this.activeContracts));
                } else {
                    this.activeContracts = JSON.parse(JSON.stringify(this.allContracts));
                }
                this.isLoading = false; // Hide spinner
            })
            .catch(error => {
                console.error('Error fetching period:', error);
                this.activeContracts = JSON.parse(JSON.stringify(this.allContracts));
                this.isLoading = false; // Hide spinner
            });
    }


    sortColumn(event) {
        const fieldName = event.currentTarget.dataset.field;
        // Only sort if there are contracts to sort
        if (fieldName && this.activeContracts && this.activeContracts.length > 0) {
            this.isSortedDesc = !this.isSortedDesc;
            this.showError=false;
            this.errorMessage='';
            this.activeContracts = [...this.activeContracts].sort((a, b) => {
                const aValue = a.c[fieldName];
                const bValue = b.c[fieldName];
         
                if (!aValue && !bValue) return 0; 
                if (!aValue) return 1; 
                if (!bValue) return -1;  
                return this.sortData(aValue, bValue, this.isSortedDesc);
            });
            this.updateSortIcon();
        }
        // If no contracts, do nothing - the "no records found" message is already shown
    }
    sortData(a, b, isDescending) {
        const comparison = a > b ? 1 : a < b ? -1 : 0;
        return isDescending ? comparison * -1 : comparison;
    }

    updateSortIcon() {
        this.closeDateSortIcon = this.isSortedDesc ? 'utility:arrowdown' : 'utility:arrowup';
    }



    connectedCallback() {

        if (!document.getElementById('custom-alert-override-style')) {
            const style = document.createElement('style');
            style.id = 'custom-alert-override-style';
            
            style.innerText = `
                /* Apply width to the alert div */
                .slds-notify.slds-notify_alert.slds-alert_warning.slds-m-horizontal_medium.slds-m-bottom_small {
                    width: 97.8% !important;
                }

                /* Add margin-left: 5px to combobox form elements */
                .slds-size_small.slds-form-element {
                    margin-left: 13px !important;
                }
            `;
            
            document.head.appendChild(style);
        }

        if ( this.currentPageReference.state.c__accid ) {
            console.log( 'c__accid Param value is ' + this.currentPageReference.state.c__accid );
            this.accid = this.currentPageReference.state.c__accid;
            if(this.accid==undefined || this.accid==''){
                console.log('invalid acc id====');
                this.showError=true;
                this.errorMessage='Invalid account, please select a valid account to proceed.';
            }
            else{
                console.log('valid acc id====');
                this.showError=false;
                this.errorMessage='';
            }            
        }
        else if(this.accid==undefined || this.accid==''){
            console.log('invalid acc id====');
            this.showError=true;
            this.errorMessage='Invalid account, please select a valid account to proceed.';
        }        
    }  
    renderedCallback() {

    }  
    handleGoBack(){
        if(this.accid!==undefined && this.accid!==''){
            window.location='/'+this.accid;
        }
        else{
            history.back();
        }
        
    }
    handleMasterContractSelection(event) {
        
        const contractId = event.target.value;
        const isMasterSelected = event.target.checked;
        let updatedActiveContracts = JSON.parse(JSON.stringify(this.activeContracts));
        updatedActiveContracts= updatedActiveContracts.map(contract => {
            if(contract.c.Id === contractId){
                contract.isMasterSelected = isMasterSelected;
            }
            else{
                contract.isMasterSelected=false;
            }
            return contract;
        });
        this.activeContracts=updatedActiveContracts;
    }
    handleChildContractSelection(event) {
        const contractId = event.target.value;
        const isChildSelected = event.target.checked;
        let updatedActiveContracts = JSON.parse(JSON.stringify(this.activeContracts));
        updatedActiveContracts = updatedActiveContracts.map(contract => {
            if(contract.c.Id === contractId){
                contract.isChildSelected =  isChildSelected;
            }
            return contract;
        });
        this.activeContracts=updatedActiveContracts;
    }    
    async handleRenew() {
        if(this.isLoading){
            return;
        }
        console.log('handleRemew==='+JSON.stringify(this.activeContracts));
        const selectedChildContracts = this.activeContracts.filter((contract) => contract.isChildSelected);
        
        // Validate at least 2 contracts are selected
        if (selectedChildContracts.length === 0) {
            this.showToast('Error', 'No contracts selected. Please select at least 2 contracts for consolidation.', 'error');
            return;
        }
        
        if (selectedChildContracts.length < 2) {
            this.showToast('Error', 'At least 2 contracts must be selected for consolidation.', 'error');
            return;
        }
        
        const selectedMasterContracts = this.activeContracts.filter((contract) => contract.isMasterSelected);
        if (selectedMasterContracts.length === 0) {
            this.showToast('Error', 'No master contract selected', 'error');
            return;
        }
         const masterContract = selectedMasterContracts[0];
        if (!masterContract.isChildSelected) {
            this.showToast('Error', 'The master contract must also be selected using the checkbox.', 'error');
            return;
        }

        // Check if user is not a System Administrator and not all contracts are selected
        console.log('isSystemAdministrator:', this.isSystemAdministrator);
        console.log('Total contracts:', this.activeContracts.length);
        console.log('Selected contracts:', selectedChildContracts.length);
        
        if (!this.isSystemAdministrator) {
            const totalContracts = this.activeContracts.length;
            const selectedContracts = selectedChildContracts.length;
            const unselectedCount = totalContracts - selectedContracts;
            
            console.log('Unselected count:', unselectedCount);

            if (unselectedCount > 0) {
                console.log('Opening confirmation dialog...');
                const result = await LightningConfirm.open({
                    message: `${unselectedCount} contract${unselectedCount > 1 ? 's were' : ' is'} not selected for consolidation. Do you want to continue consolidating only the selected contracts?`,
                    label: 'Confirm Selection',
                    theme: 'warning'
                });

                console.log('Confirmation result:', result);
                
                // result is true if user clicked "OK", false if "Cancel"
                if (!result) {
                    // User clicked "Cancel" (Select More) - stay on page
                    return;
                }
                // User clicked "OK" (Proceed) - continue with renewal
            }
        }

        this.isLoading = true;

        // Proceed with renewal
        renewContracts({ accountId:this.accid,selectedChildContracts: selectedChildContracts,selectedMasterContracts:selectedMasterContracts })
            .then((result) => {
                if(result.indexOf('Saved successfully')>-1){
                    this.showToast('Success', result, 'success');
                    setTimeout(() => {
                        this.handleGoBack();
                      }, "5000");
                }
                else{
                    this.showToast('Error', result, 'error');
                    this.isLoading = false;
                }
                
            })
            .catch((error) => {
                this.showToast('Error', error.body.message, 'error');
                this.isLoading = false;
            });
    }

    showToast(title, message, variant) {
        const toastEvent = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant
        });
        this.dispatchEvent(toastEvent);
    }         
}