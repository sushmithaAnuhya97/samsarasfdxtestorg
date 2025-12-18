public class QuoteSavePETriggerHandler extends TriggerHandler {
	private List<Quote_Save__e> newQuoteEventList;
    @TestVisible
    static SamsaraLoggerService thisLoggerService = new SamsaraLoggerService();
	public QuoteSavePETriggerHandler() {
		this.newQuoteEventList = (List<Quote_Save__e>) Trigger.new;
    }
    
    public override void afterInsert(){
        System.debug(LoggingLevel.INFO, '*********** Hitting PE TriggerHandler **********');
        GS_SBQQQuoteServiceAsync.asyncContext = 'QuoteSavePE';
        try{
            QuoteSavePEHelper.quoteSaveEventDispatch(newQuoteEventList);
        }
        catch (Exception ex){
            handleExceptions(ex);
        }
        finally {
            thisLoggerService.logger.dispatch();
        }

    }

    /**
     * @description : Added by Vikasm to deal with the row lock issues
     * @param ex ; Exception received
     */
    @TestVisible
    private void handleExceptions(Exception ex){
        if(ex.getMessage().contains('UNABLE_TO_LOCK_ROW')){
            handleRowLockSituations();
        }
        else{
            thisLoggerService.logger.logError(
                    'Platform event failed to process QuoteSavePEHelper.quoteSaveEventDispatch',
                    new SamsaraLoggerObjectMVP(ex, newQuoteEventList)
            );
            System.debug('Platform event failed to process QuoteSavePEHelper.quoteSaveEventDispatch');
        }
    }

    /**
     * This method will be responsible for row lock situations.
     * will throw EventBus.RetryableException so that platform can kick its own retry mechanism
     */
    @TestVisible
    private void handleRowLockSituations(){
        if (EventBus.TriggerContext.currentContext().retries < 4) {
            // Condition isn't met, so try again later.
            throw new EventBus.RetryableException(
                    'Row Lock issue, so retrying the trigger again.');
        } else {
            System.debug('Trigger was retried enough times');
            // Trigger was retried enough times so give up and
            // resort to alternative action.
            // For example, send email to user.
        }
    }
}