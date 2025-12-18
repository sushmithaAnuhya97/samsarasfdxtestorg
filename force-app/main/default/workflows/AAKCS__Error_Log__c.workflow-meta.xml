<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <alerts>
        <fullName>AAKCS__New_Error_Notification</fullName>
        <description>New Error Notification</description>
        <protected>false</protected>
        <recipients>
            <type>creator</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>AAKCS__AAkonsult_Campaign_Status/AAKCS__Error_Log_Notification</template>
    </alerts>
    <rules>
        <fullName>AAKCS__Error Log Notification</fullName>
        <actions>
            <name>AAKCS__New_Error_Notification</name>
            <type>Alert</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>AAKCS__Error_Log__c.CreatedById</field>
            <operation>notEqual</operation>
        </criteriaItems>
        <description>Send Notification that a new error has been logged.</description>
        <triggerType>onCreateOnly</triggerType>
    </rules>
</Workflow>
