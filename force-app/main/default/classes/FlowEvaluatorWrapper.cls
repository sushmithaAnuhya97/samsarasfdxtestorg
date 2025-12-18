global with sharing class FlowEvaluatorWrapper {
    
    public class InputWrapper {
        @InvocableVariable(required=true)
        public Opportunity newOpp;
        @InvocableVariable(required = true)
        public Opportunity oldOpp;
    }
    
    public class OpportunityAlerts {
        @InvocableVariable(label='Email Alerts')
        public List<EmailAlert> emailAlerts = new List<EmailAlert>();
        @InvocableVariable public Boolean byPass = true;
    }
}