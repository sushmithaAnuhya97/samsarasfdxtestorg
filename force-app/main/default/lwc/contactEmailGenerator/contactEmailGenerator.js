import { LightningElement, api, track, wire } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import generateEmailForContact from '@salesforce/apex/ContactEmailGeneratorController.generateEmailForContact';
import getLastLogStatus from '@salesforce/apex/ContactEmailGeneratorController.getLastLogStatus';
import getGongDetails from '@salesforce/apex/ContactEmailGeneratorController.getGongDetails';
import validateContactForSmartFlow from '@salesforce/apex/ContactEmailGeneratorController.validateContactForSmartFlow';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

// Import Contact fields for LDS
import CONTACT_EMAIL from '@salesforce/schema/Contact.Email';
import CONTACT_SALES_EMAIL_OPT_OUT from '@salesforce/schema/Contact.Sales_Email_Opt_Out__c';
import CONTACT_HAS_OPTED_OUT_OF_EMAIL from '@salesforce/schema/Contact.HasOptedOutOfEmail';
import CONTACT_OWNER_MATCHES_ACCOUNT_OWNER from '@salesforce/schema/Contact.Contact_Owner_Matches_Account_Owner__c';
import CONTACT_OWNER_NAME from '@salesforce/schema/Contact.Owner_Name__c';

export default class ContactEmailGenerator extends LightningElement {
        @api recordId; // Contact record ID
    @track isGenerating = false;
    @track currentStep = 'idle';
    @track gongUrl = '';
    @track errorMessage = '';
    @track hasError = false;
    @track showSuccessIcon = false;
    @track currentStatus = 'ready'; // Track current status: ready, processing, completed
    @track mainMessage = 'Click to generate AI-powered email for the contact.';
    @track canGenerateEmail = true; // Track if Generate Email button should be enabled
    @track logStatusMessage = ''; // Track the log status message
    @track lastSyncInfo = null; // Track last sync information
    @track gongSettings;
    @track tooltipMessage = 'Click to generate AI-powered email for the contact.'; // Track tooltip message
    @track contactValidationPassed = true; // Track contact validation result
    @track logStatusPassed = true; // Track log status result
    @track validationMessage = ''; // Track validation message to display
    @track validationDetails = []; // Track validation details for bullet points
    @track isLogInProgress = false; // Track if log status is in progress
    @track logStatusPollingInterval = null; // Track log status polling interval
    @track generatedUser ;
    

    // LDS wire to automatically detect Contact field changes
    @wire(getRecord, { recordId: '$recordId', fields: [
        CONTACT_EMAIL,
        CONTACT_SALES_EMAIL_OPT_OUT,
        CONTACT_HAS_OPTED_OUT_OF_EMAIL,
        CONTACT_OWNER_MATCHES_ACCOUNT_OWNER,
        CONTACT_OWNER_NAME
    ]})
    wiredContact({ error, data }) {
        if (data) {
            console.log('Contact data updated via LDS:', data);
            // Re-validate when Contact fields change
            this.checkContactValidation();
        } else if (error) {
            console.error('Error loading contact data:', error);
        }
    }

    // Track previous validation state to detect changes
    previousValidationState = null;
    




    // Lifecycle hook to process wired data
    connectedCallback() {
        console.log('=== AI Email Generator Initialized ===');
        console.log('@api recordId:', this.recordId);
        console.log('Component ready for AI processing');

        getGongDetails()
        .then(result => {
            this.gongSettings = result;
        })
        .catch(error => {
            this.error = error;
        });

        
        // Initialize AI-specific features
        this.initializeAIFeatures();
        
        // Check contact validation first
        this.checkContactValidation();
        
        // Check last log status to determine button state
        this.checkLastLogStatus();
        
        // Start lightweight polling for log status changes
        this.startLogStatusPolling();
    }
    
    // Clean up when component is destroyed
    disconnectedCallback() {
        console.log('Component disconnecting - cleaning up...');
        this.stopLogStatusPolling();
        this.stopMockProgression();
    }
    
    initializeAIFeatures() {
        // Add any AI-specific initialization here
        // This could include checking AI service status, loading models, etc.
        console.log('AI features initialized');
    }

    /**
     * Check contact validation for Smart Flow generation
     */
    async checkContactValidation() {
        try {
            if (!this.recordId) {
                console.log('No recordId available for validation check');
                return;
            }

            console.log('Checking validation status for contact:', this.recordId);
            const validation = await validateContactForSmartFlow({ contactId: this.recordId });
            
            console.log('Validation result:', validation);
            console.log('Validation details:', validation.validationDetails);
            
            // Update contact validation result
            this.contactValidationPassed = validation.canGenerate;
            this.tooltipMessage = validation.tooltipMessage;
            this.validationMessage = validation.canGenerate ? '' : validation.tooltipMessage;
            this.validationDetails = validation.validationDetails || [];
            
            // If validation failed and we have details, use the main message only
            if (!validation.canGenerate && this.validationDetails.length > 0) {
                console.log('into 129 validation');
                this.validationMessage = validation.tooltipMessage; // This should be "Smart Flow unavailable"
            }
            
            console.log('Updated validation state:', {
                contactValidationPassed: this.contactValidationPassed,
                validationMessage: this.validationMessage,
                validationDetails: this.validationDetails,
                hasValidationDetails: this.hasValidationDetails
            });
            
            console.log('Contact validation result:', {
                canGenerate: validation.canGenerate,
                tooltipMessage: validation.tooltipMessage,
                contactValidationPassed: this.contactValidationPassed
            });
            
            // Update overall button state
            this.updateButtonState();
            
        } catch (error) {
            console.error('Error validating contact:', error);
            this.contactValidationPassed = false;
            this.tooltipMessage = 'Unable to validate contact';
            this.validationMessage = 'Unable to validate contact';
            this.validationDetails = [];
            this.updateButtonState();
        }
    }


    

    async checkLastLogStatus() {
        try {
            if (!this.recordId) {
                console.log('No recordId available for log status check');
                return;
            }

            console.log('Checking last log status for contact:', this.recordId);
            const logStatus = await getLastLogStatus({ contactId: this.recordId });
            
            console.log('Log status result:', logStatus);
            
            this.logStatusPassed = logStatus.canGenerate;
            this.logStatusMessage = logStatus.message;
            
            // Update status text based on log status
            if (logStatus.lastLogStatus) {
                const lastLog = logStatus.lastLogStatus;
                console.log('Last log status details:', lastLog);
                console.log('Level:', lastLog.level, 'Exception Type:', lastLog.exceptionType);
                this.generatedUser = lastLog.createdUser;
                
                if (lastLog.level === 'INFO' && lastLog.exceptionType === 'Completed') {
                    console.log('Setting status to completed');
                    this.currentStatus = 'completed';
                    this.isLogInProgress = false; // Completed, so not in progress
                    // this.currentStep = 'completed'; // Set step but won't show progress bar due to showProgress logic

                    // Clear any previous errors
                    this.clearError();

                    // Show completion message first
                    this.mainMessage = 'The Flow will be visible in Gong Engage within one hour.';
                    
                    // Stop polling since log is completed
                    this.stopLogStatusPolling();

                    // Only set lastSyncInfo for completed logs
                    console.log('Setting lastSyncInfo for completed log with date:', lastLog.createdDate);
                    this.lastSyncInfo = {
                        date: lastLog.createdDate,
                        level: lastLog.level,
                        exceptionType: lastLog.exceptionType,
                        user : lastLog.createdUser
                    };
                    
                    // After 3 seconds, change to default message
                    setTimeout(() => {
                        this.mainMessage = 'Click to generate AI-powered email for the contact.';
                    }, 3000);
                    this.updateButtonState();

                } else if (lastLog.level === 'ERROR') {
                    console.log('Setting status to error');
                    this.currentStatus = 'error';
                    this.isLogInProgress = false; // Error, so not in progress
                    // this.currentStep = 'idle';
                    
                    // Update main message to default message
                    this.mainMessage = 'Click to generate AI-powered email for the contact.';
                    
                    // Stop polling since log is errored
                    this.stopLogStatusPolling();
                    
                    // Set lastSyncInfo for error logs (so user knows what failed)
                    console.log('Setting lastSyncInfo for error log with date:', lastLog.createdDate);
                    this.lastSyncInfo = {
                        date: lastLog.createdDate,
                        level: lastLog.level,
                        exceptionType: lastLog.exceptionType,
                        user : lastLog.createdUser
                    };
                    this.updateButtonState();

                } else {
                    console.log('Setting status to processing - NOT setting lastSyncInfo');
                    // In progress - show completion message and disable button
                    //this.currentStatus = 'processing'; // Set to processing to show blue dot
                    this.isGenerating = false; // Don't show progress bar, just completion message
                    this.isLogInProgress = true; // Mark log as in progress
                    this.canGenerateEmail = false;
                    
                    // Only show processing message if contact validation passed
                    // If contact validation failed, keep showing the validation message
                    if (this.contactValidationPassed) {
                        this.mainMessage = 'The Flow will be visible in Gong Engage within one hour.';
                        this.validationMessage = ''; // Clear validation message to hide validation card
                        this.validationDetails = []; // Clear validation details
                    }
                    
                    // Clear any previous errors since we're processing successfully
                    this.clearError();
                    
                    // Stop any existing mock progression
                    this.stopMockProgression();
                    
                    // Don't set lastSyncInfo for in-progress logs
                    //this.lastSyncInfo = null;
                
                    //In case of in-Progress logs also, we are showing them as completed from UI
                    this.currentStatus = 'completed';
                    this.lastSyncInfo = {
                        date: lastLog.createdDate,
                        level: 'INFO',
                        exceptionType: 'Completed',
                        user : lastLog.createdUser
                    };
                    
                }
            } else {
                console.log('No lastLogStatus found, setting to ready');
                this.currentStatus = 'ready';
                this.isLogInProgress = false; // No logs, so not in progress
                this.mainMessage = 'Click to generate AI-powered email for the contact.';
                this.lastSyncInfo = null;
                
                // Clear any previous errors since there are no logs
                this.clearError();
                this.updateButtonState();

            }
            
        } catch (error) {
            console.error('Error checking last log status:', error);
            // Default to allowing generation if there's an error checking
            this.canGenerateEmail = true;
            this.logStatusMessage = 'Unable to check previous status';
            this.mainMessage = 'Click to generate AI-powered email for the contact.';
        }
        
        // Update button state after all log status processing is complete
    }
    


    // Constructor to see if component is being created
    constructor() {
        super();
        console.log('=== LWC CONSTRUCTOR CALLED ===');
        console.log('Component being created');
    }
    



    // Enhanced progress steps for the AI UI
    progressSteps = [
        { 
            key: 'thinking', 
            label: 'AI Thinking', 
            description: 'Analyzing context',
            icon: 'utility:search' 
        },
        { 
            key: 'preparing', 
            label: 'Data Prep', 
            description: 'Gathering insights',
            icon: 'utility:data_mapping' 
        },
        { 
            key: 'analyzing', 
            label: 'Deep Research', 
            description: 'Processing intelligence',
            icon: 'utility:light_bulb' 
        },
        { 
            key: 'generating', 
            label: 'Smart Flow Generation', 
            description: 'Crafting content',
            icon: 'utility:email' 
        },
        { 
            key: 'completed', 
            label: 'Complete', 
            description: 'Ready to review',
            icon: 'utility:success' 
        }
    ];
    
    get showProgress() {
        // Only show progress bar if currently processing (not on page refresh for completed/error states)
        const shouldShow = this.currentStep !== 'idle' && this.currentStatus === 'processing';
        console.log('showProgress check - currentStep:', this.currentStep, 'currentStatus:', this.currentStatus, 'shouldShow:', shouldShow);
        return shouldShow;
    }
    
    get currentStepIndex() {
        return this.progressSteps.findIndex(step => step.key === this.currentStep);
    }
    
    get progressStepsWithStatus() {
        return this.progressSteps.map((step, index) => ({
            ...step,
            isCompleted: index < this.currentStepIndex || this.currentStep === 'completed',
            isCurrent: index === this.currentStepIndex && this.currentStep !== 'completed',
            isPending: index > this.currentStepIndex && this.currentStep !== 'completed',
            status: this.getStepStatus(index)
        }));
    }

    getStepStatus(index) {
        if (index < this.currentStepIndex || this.currentStep === 'completed') {
            return 'completed';
        } else if (index === this.currentStepIndex && this.currentStep !== 'completed') {
            return 'current';
        } else {
            return 'pending';
        }
    }
    

    

    
    get isLaunchGongDisabled() {
        // Disable Launch Gong button until Smart Flow generation is completed
        return this.currentStatus !== 'completed';
    }
    
    get progressPercentage() {
        if (this.currentStep === 'idle') return 0;
        if (this.currentStep === 'completed') return 100;
        const currentIndex = this.progressSteps.findIndex(step => step.key === this.currentStep);
        return Math.round(((currentIndex + 1) / this.progressSteps.length) * 100);
    }
    
    get progressBarStyle() {
        const percentage = this.progressPercentage || 0;
        return `width: ${percentage}%`;
    }

    // Getter for status text based on current status
    get statusText() {
        switch(this.currentStatus) {
            case 'ready': return 'AI Ready';
            case 'processing': return 'Processing...';
            case 'completed': return 'Generation Complete';
            case 'error': return 'Error';
            default: return 'AI Ready';
        }
    }

    get buttonDisabled() {
        return this.isGenerating || !this.canGenerateEmail;
    }

    /**
     * Update button state based on both contact validation and log status
     */
    updateButtonState() {
        // Button is enabled only if BOTH validations pass AND not currently generating AND log not in progress
        this.canGenerateEmail = this.contactValidationPassed && this.logStatusPassed && !this.isGenerating && !this.isLogInProgress;
        
        console.log('Updating button state:', {
            contactValidationPassed: this.contactValidationPassed,
            logStatusPassed: this.logStatusPassed,
            isGenerating: this.isGenerating,
            isLogInProgress: this.isLogInProgress,
            canGenerateEmail: this.canGenerateEmail,
            tooltipMessage: this.tooltipMessage
        });
        
        // If contact validation failed, use its message
        if (!this.contactValidationPassed) {
            // Keep the validation message from contact validation
            console.log('Contact validation failed, keeping validation message:', this.validationMessage);
            return;
        }
        
        // If log status failed, use its message
        console.log('logStatusPassed-->'+this.logStatusPassed);
        if (!this.logStatusPassed) {
            this.validationMessage = this.logStatusMessage;
            console.log('Log status failed, updating validation message to:', this.validationMessage);
        } else {
            // Both validations passed, clear validation message
            this.validationMessage = '';
        }
    }

    get showLastSyncInfo() {
        return this.lastSyncInfo !== null;
    }

    get buttonTooltip() {
        console.log('Button tooltip requested:', this.tooltipMessage);
        return this.tooltipMessage || 'Click to generate AI-powered email for the contact.';
    }

    get showValidationMessage() {
        console.log('generate email***'+this.canGenerateEmail);
        console.log('Validation message:', this.validationMessage);
        return !this.canGenerateEmail && this.validationMessage !== '';
    }

    get hasValidationDetails() {
        return this.validationDetails && this.validationDetails.length > 0;
    }

    /**
     * Manually refresh validation (useful for testing or manual triggers)
     */
    refreshValidation() {
        console.log('Manually refreshing validation...');
        this.checkContactValidation();
    }

    get lastSyncMessage() {
        if (!this.lastSyncInfo) return null;
        
        const { level, exceptionType, date, user } = this.lastSyncInfo;
        
        if (level === 'INFO' && exceptionType === 'Completed') {
            return {
                icon: 'utility:success',
                variant: 'success',
                text: `Last Smart Flow generated on ${this.formatDate(date)} - by ${user}`,
                isSuccess: true,
                isError: false,
                isInProgress: false
            };
        } else if (level === 'ERROR') {
            return {
                icon: 'utility:error',
                variant: 'error',
                text: `Last Smart Flow update failed on ${this.formatDate(date)} - You can try again`,
                isSuccess: false,
                isError: true,
                isInProgress: false
            };
        } else {
            return {
                icon: 'utility:spinner',
                variant: 'brand',
                text: `Smart Flow generation in progress since ${this.formatDate(date)}`,
                isSuccess: false,
                isError: false,
                isInProgress: true
            };
        }
    }

    formatDate(dateString) {
        if (!dateString) return '';
        
        try {
            console.log('=== Date Formatting Debug ===');
            console.log('Original dateString from Apex:', dateString);
            
            const date = new Date(dateString);
            const userTimezone = Intl.DateTimeFormat().resolvedOptions().timeZone;
            
            console.log('Parsed date object:', date);
            console.log('User timezone:', userTimezone);
            console.log('Date in UTC:', date.toISOString());
            
            const formattedDate = date.toLocaleDateString('en-US', {
                year: 'numeric',
                month: 'long',
                day: 'numeric',
                hour: 'numeric',
                minute: '2-digit',
                hour12: true,
                timeZone: userTimezone
            });
            
            console.log('Final formatted date:', formattedDate);
            console.log('===============================');
            
            return formattedDate;
        } catch (error) {
            console.error('Error formatting date:', error);
            return dateString;
        }
    }


    
    async handleGenerateEmail() {
        if (!this.recordId) {
            this.showToast('Error', 'No Contact record found', 'error');
            return;
        }
        
        // Show toast message to inform user they can navigate away
        this.showToast('Smart Flow process started', 'You may continue navigating to other pages while the current process completes in the background.', 'info');
        
        this.isGenerating = true;
        this.currentStatus = 'processing';
        this.mainMessage = 'Deep research in progress';
        
        // Start mock progression with static steps
        this.startMockProgression();
        
        try {
            // Call the Workato service - it will create Samsara logs internally
            const result = await generateEmailForContact({ contactId: this.recordId });
            
            // For mock progression, we don't need to monitor real status
            // The mock progression will handle the UI updates
            console.log('Workato service called successfully:', result);
            
        } catch (error) {
            // Stop mock progression on error
            this.stopMockProgression();
            this.currentStatus = 'error';
            this.hasError = true;
            this.errorMessage = error.body?.message || 'Smart Flow failed';
            this.isGenerating = false; // Set to false on error
            this.checkLastLogStatus(); // Recheck log status
        }
    }
    
    handleLaunchGong() {
        // Navigate to Gong URL from configuration
        const gongUrl = this.gongSettings.gongUrl;
        
        // Open Gong Engage in new tab
        window.open(gongUrl, '_blank');
    }
    
    
    
    
    clearError() {
        this.hasError = false;
        this.errorMessage = '';
    }
    
    handleAssistantClick() {
        // Handle AI assistant interactions
        this.showToast('AI Assistant', 'AI assistant ready to help!', 'info');
    }
    

    
    // Enhanced error handling with better UX
    handleEnhancedError(error) {
        this.hasError = true;
        this.errorMessage = error.body?.message || error.message || 'An unexpected error occurred';
        this.currentStep = 'idle';
        this.isGenerating = false;
        
        // Add haptic feedback for mobile
        if (navigator.vibrate) {
            navigator.vibrate(200);
        }
    }
    
    
    


    /**
     * Start lightweight polling for log status changes (not progression steps)
     */
    startLogStatusPolling() {
        // Only poll if not already polling and not in mock progression
        if (this.logStatusPollingInterval || this.isGenerating) {
            return;
        }
        
        console.log('Starting log status polling...');
        this.logStatusPollingInterval = setInterval(async () => {
            try {
                console.log('Polling log status...');
                await this.checkLastLogStatus();
            } catch (error) {
                console.error('Error polling log status:', error);
            }
        }, 5000); // Poll every 5 seconds
    }
    
    /**
     * Stop log status polling
     */
    stopLogStatusPolling() {
        if (this.logStatusPollingInterval) {
            console.log('Stopping log status polling...');
            clearInterval(this.logStatusPollingInterval);
            this.logStatusPollingInterval = null;
        }
    }

    /**
     * Start mock progression through static steps with 0.5-second intervals
     */
    startMockProgression() {
        // Stop log status polling during mock progression
        this.stopLogStatusPolling();
        
        const steps = ['thinking', 'preparing', 'analyzing', 'generating', 'completed'];
        let currentIndex = 0;

        //Clear lastsync info during mock progression
        this.lastSyncInfo = null;
        
        const progressStep = () => {
            if (currentIndex < steps.length && this.isGenerating) {
                this.currentStep = steps[currentIndex];
                console.log(`Mock progression: ${this.currentStep}`);
                currentIndex++;
                
                if (currentIndex < steps.length) {
                    // Continue to next step after 2 seconds
                    this.mockProgressionTimeout = setTimeout(progressStep, 2000);
                } else {
                    // All steps completed
                    this.currentStep = 'completed';
                    this.currentStatus = 'completed';
                    this.mainMessage = 'The Flow will be visible in Gong Engage within one hour.';
                    this.isGenerating = false;
                    this.isLogInProgress = true; // Keep button disabled after completion
                    this.showToast('Success', 'Smart Flow generation complete', 'success');
                    this.checkLastLogStatus();
                    
                }
            }
        };
        
        // Start the progression
        progressStep();
    }

    /**
     * Stop any existing mock progression
     */
    stopMockProgression() {
        // Clear any existing timeouts
        if (this.mockProgressionTimeout) {
            clearTimeout(this.mockProgressionTimeout);
            this.mockProgressionTimeout = null;
        }
        
        // Reset progression state
        this.isGenerating = false;
        this.currentStep = 'idle';
        
        // Restart log status polling after mock progression stops
        this.startLogStatusPolling();
    }

    /**
     * Utility method for delays
     */
    delay(ms) {
        return new Promise(resolve => setTimeout(resolve, ms));
    }
    

    

    
    showToast(title, message, variant) {
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant
        });
        this.dispatchEvent(event);
    }


}