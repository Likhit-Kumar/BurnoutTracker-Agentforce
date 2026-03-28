/**
 * CreateHRAlert
 *
 * Invocable Apex action used by the Burnout Prevention Agent.
 * Called ONLY when risk level is Red (enforced by Agent Script's
 * deterministic IF conditions — the LLM cannot override this).
 *
 * Creates a silent, confidential HR_Alert__c record.
 * The employee is NEVER notified about this alert.
 * HR gets visibility without creating stigma.
 */
public with sharing class CreateHRAlert {

    public class AlertRequest {
        @InvocableVariable(required=true description='The record ID of the EmployeeActivity__c')
        public Id employeeActivityId;

        @InvocableVariable(required=true description='The employee name')
        public String employeeName;

        @InvocableVariable(required=true description='The calculated risk level')
        public String riskLevel;

        @InvocableVariable(description='The numerical burnout score')
        public Decimal score;
    }

    public class AlertResult {
        @InvocableVariable(description='The ID of the created HR_Alert__c record')
        public Id alertId;

        @InvocableVariable(description='Confirmation message')
        public String message;
    }

    @InvocableMethod(
        label='Create HR Alert'
        description='Creates a confidential HR alert record for high-risk employees. The employee never sees this.'
    )
    public static List<AlertResult> createAlert(List<AlertRequest> requests) {
        List<AlertResult> results = new List<AlertResult>();
        List<HR_Alert__c> alertsToInsert = new List<HR_Alert__c>();

        for (AlertRequest req : requests) {
            HR_Alert__c alert = new HR_Alert__c(
                Employee_Activity__c = req.employeeActivityId,
                Alert_Type__c = 'Burnout Risk - ' + req.riskLevel,
                Confidential_Notes__c = 'AUTOMATED ALERT — Burnout Prevention Agent\n\n'
                    + 'Employee: ' + req.employeeName + '\n'
                    + 'Risk Level: ' + req.riskLevel + '\n'
                    + 'Burnout Score: ' + req.score + ' / 100\n\n'
                    + 'This alert was generated automatically based on work pattern analysis. '
                    + 'The employee has NOT been informed of this alert or their score. '
                    + 'A manager meeting has been scheduled. '
                    + 'Please follow up with appropriate support resources.'
            );
            alertsToInsert.add(alert);
        }

        if (!alertsToInsert.isEmpty()) {
            insert alertsToInsert;
        }

        for (Integer i = 0; i < requests.size(); i++) {
            AlertResult result = new AlertResult();
            result.alertId = alertsToInsert[i].Id;
            result.message = 'Confidential HR alert created for ' + requests[i].employeeName;
            results.add(result);
        }

        return results;
    }
}
