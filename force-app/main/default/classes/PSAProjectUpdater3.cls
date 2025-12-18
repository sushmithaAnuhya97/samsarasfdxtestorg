public class PSAProjectUpdater3 {
    @InvocableMethod(label='Update Project Records')
    public static void updateProjects(List<OpportunityIdWrapper> oppWrappers) {
        Set<Id> opportunityIds = new Set<Id>();
        for (OpportunityIdWrapper wrapper : oppWrappers) {
            opportunityIds.add(wrapper.oppId);
        }

        // Fetch Opportunities
        Map<Id, Opportunity> opps = new Map<Id, Opportunity>(
            [SELECT Id, StageName, Probability, CloseDate FROM Opportunity WHERE Id IN :opportunityIds]
        );

        // Fetch Projects
        List<pse__Proj__c> projectsToUpdate = [SELECT Id, pse__Opportunity__c, pse__Stage__c, Expected_End_Date__c, Booking_Date__c, pse__End_Date__c, Project_Level__c, Engagement_Type__c FROM pse__Proj__c WHERE pse__Opportunity__c IN :opportunityIds];

        for (pse__Proj__c project : projectsToUpdate) {
            Opportunity relatedOpp = opps.get(project.pse__Opportunity__c);

            if (relatedOpp == null) {
                System.debug('Opportunity is null for project ID: ' + project.Id);
                continue;
            }

            Date newEndDate = calculateNewEndDate(relatedOpp.CloseDate, project.Engagement_Type__c, project.Project_Level__c);
            project.pse__End_Date__c = newEndDate;
            project.Expected_End_Date__c = newEndDate;

            if (relatedOpp.Probability >= 90 && relatedOpp.Probability < 100) {
                project.pse__Stage__c = 'Ready for Staffing';
            }

            if (relatedOpp.StageName == 'Closed Won') {
                project.pse__Stage__c = 'Ready for Staffing';
                project.Booking_Date__c = Date.today();
            }

            System.debug('Project ID: ' + project.Id + ', End Date: ' + newEndDate + ', Expected End Date: ' + newEndDate + ', Stage: ' + project.pse__Stage__c + ', Booking Date: ' + project.Booking_Date__c);
        }

        try {
            update projectsToUpdate;
            System.debug('Projects updated successfully');
        } catch (Exception e) {
            System.debug('Error updating projects: ' + e.getMessage());
        }
    }

    private static Date calculateNewEndDate(Date closeDate, String engagementType, String projectLevel) {
        Integer daysToAdd = 0;
        if (engagementType == 'Initial Implementation') {
            if (projectLevel == 'Core' || projectLevel == 'PubSec' || projectLevel == 'Canada') {
                daysToAdd = 90;
            } else if (projectLevel == 'Select') {
                daysToAdd = 150;
            } else if (projectLevel == 'Strategic') {
                daysToAdd = 210;
            }
        } else if (engagementType == 'Upsell/Cross-sell') {
            if (projectLevel == 'Core' || projectLevel == 'PubSec' || projectLevel == 'Canada') {
                daysToAdd = 45;
            } else if (projectLevel == 'Select' || projectLevel == 'Strategic') {
                daysToAdd = 90;
            }
        }
        return closeDate.addDays(daysToAdd);
    }

    public class OpportunityIdWrapper {
        @InvocableVariable(label='Opportunity ID')
        public Id oppId;
    }
}