/**
 * Created by vikasmishra on 2021-08-16.
 */

public virtual class GS_SObjectBaseSelector {
    protected Boolean checkFatalError = false;
    @TestVisible
    protected GS_SObjectBaseSelector(Boolean checkFatalError){
        this.checkFatalError = checkFatalError;
    }
     @TestVisible
    protected GS_SObjectBaseSelector validateFatalError() {
        if (!checkFatalError) {
            return this;
        }
        else{
            if (Limits.getQueries() == Limits.getLimitQueries() ) {
                System.debug('Fatal Error Soql '+Limits.getLimitQueries());
                throw new BaseSelectorSelectorException(Limits.getLimitQueries()+' reached');
            }
            if (Limits.getQueryRows() == Limits.getLimitQueryRows()) {
                System.debug('Fatal Error Soql '+Limits.getLimitQueryRows());
                throw new BaseSelectorSelectorException('Soql '+Limits.getLimitQueryRows());
            }
        }
        return this;
    }

    public class BaseSelectorSelectorException extends Exception { }

}