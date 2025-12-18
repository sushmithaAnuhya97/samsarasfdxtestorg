public class PSAProject {
    @InvocableMethod
    public static List<Id> createProject(List<ProjectWrapper> projectWrappers) {
        List<pse__Proj__c> projectsToCreate = new List<pse__Proj__c>();
        List<Id> projectIds = new List<Id>();

        for (ProjectWrapper wrapper : projectWrappers) {
            pse__Proj__c project = new pse__Proj__c();
            project.Engagement_Type__c = wrapper.engagementType;
            project.Expected_End_Date__c = wrapper.expectedEndDate;
            project.Name = wrapper.name;
            project.pse__Account__c = wrapper.pseAccount;
            project.pse__End_Date__c = wrapper.pseEndDate;
            project.pse__Group__c = wrapper.pseGroup;
            project.pse__Opportunity__c = wrapper.pseOpportunity;
            project.pse__Project_Type__c = wrapper.pseProjectType;
            project.pse__Region__c = wrapper.pseRegion;
            project.pse__Start_Date__c = wrapper.pseStartDate;

            // Add logic for Cross-Sell engagement type if needed
            if (wrapper.engagementType == 'Cross-Sell') {
                // Handle Cross-Sell specific logic here
            }

            projectsToCreate.add(project);
        }

        if (!projectsToCreate.isEmpty()) {
            insert projectsToCreate;
            for (pse__Proj__c project : projectsToCreate) {
                projectIds.add(project.Id);
            }
        }

        return projectIds;
    }

    public class ProjectWrapper {
        @InvocableVariable
        public String engagementType;
        @InvocableVariable
        public Date expectedEndDate;
        @InvocableVariable
        public String name;
        @InvocableVariable
        public Id pseAccount;
        @InvocableVariable
        public Date pseEndDate;
        @InvocableVariable
        public Id pseGroup;
        @InvocableVariable
        public Id pseOpportunity;
        @InvocableVariable
        public String pseProjectType;
        @InvocableVariable
        public Id pseRegion;
        @InvocableVariable
        public Date pseStartDate;
    }
}