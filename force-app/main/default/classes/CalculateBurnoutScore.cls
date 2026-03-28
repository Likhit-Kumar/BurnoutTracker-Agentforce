/**
 * CalculateBurnoutScore
 *
 * Invocable Apex action used by the Burnout Prevention Agent.
 * Takes an EmployeeActivity__c record ID, runs a weighted scoring algorithm
 * across 5 work-pattern signals, creates a WellbeingScore__c record,
 * and returns the risk level (Red / Amber / Green).
 *
 * This is the DETERMINISTIC layer — no LLM involvement.
 * The agent calls this action first in every assessment chain.
 */
public with sharing class CalculateBurnoutScore {

    // Weights for each burnout signal (tuned for balanced sensitivity)
    private static final Decimal WEIGHT_HOURS        = 0.30;
    private static final Decimal WEIGHT_OVERDUE       = 0.25;
    private static final Decimal WEIGHT_WEEKENDS      = 0.20;
    private static final Decimal WEIGHT_AFTER_HOURS   = 0.15;
    private static final Decimal WEIGHT_MISSED_BREAKS = 0.10;

    // Thresholds for risk classification
    private static final Decimal RED_THRESHOLD   = 70.0;
    private static final Decimal AMBER_THRESHOLD = 40.0;

    public class BurnoutRequest {
        @InvocableVariable(required=true description='The record ID of the EmployeeActivity__c to assess')
        public Id employeeActivityId;
    }

    public class BurnoutResult {
        @InvocableVariable(description='The calculated risk level: Red, Amber, or Green')
        public String riskLevel;

        @InvocableVariable(description='The numerical burnout score (0-100)')
        public Decimal score;

        @InvocableVariable(description='The employee name from the activity record')
        public String employeeName;

        @InvocableVariable(description='The ID of the created WellbeingScore__c record')
        public Id wellbeingScoreId;
    }

    @InvocableMethod(
        label='Calculate Burnout Score'
        description='Calculates a weighted burnout score from employee activity data and creates a WellbeingScore record.'
    )
    public static List<BurnoutResult> calculate(List<BurnoutRequest> requests) {
        List<BurnoutResult> results = new List<BurnoutResult>();

        // Collect all activity IDs
        Set<Id> activityIds = new Set<Id>();
        for (BurnoutRequest req : requests) {
            activityIds.add(req.employeeActivityId);
        }

        // Query all activity records
        Map<Id, EmployeeActivity__c> activities = new Map<Id, EmployeeActivity__c>([
            SELECT Id, Employee_Name__c, Weekly_Hours__c, Overdue_Tasks__c,
                   Weekend_Logins__c, After_Hours_Emails__c, Missed_Breaks__c
            FROM EmployeeActivity__c
            WHERE Id IN :activityIds
        ]);

        List<WellbeingScore__c> scoresToInsert = new List<WellbeingScore__c>();
        List<BurnoutResult> resultsList = new List<BurnoutResult>();

        for (BurnoutRequest req : requests) {
            EmployeeActivity__c activity = activities.get(req.employeeActivityId);
            BurnoutResult result = new BurnoutResult();

            if (activity == null) {
                result.riskLevel = 'Green';
                result.score = 0;
                result.employeeName = 'Unknown';
                resultsList.add(result);
                continue;
            }

            // Normalize each signal to a 0-100 scale
            Decimal hoursScore       = normalizeHours(activity.Weekly_Hours__c);
            Decimal overdueScore     = normalizeOverdue(activity.Overdue_Tasks__c);
            Decimal weekendScore     = normalizeWeekends(activity.Weekend_Logins__c);
            Decimal afterHoursScore  = normalizeAfterHours(activity.After_Hours_Emails__c);
            Decimal missedBreakScore = normalizeMissedBreaks(activity.Missed_Breaks__c);

            // Calculate weighted total
            Decimal totalScore = (hoursScore * WEIGHT_HOURS)
                               + (overdueScore * WEIGHT_OVERDUE)
                               + (weekendScore * WEIGHT_WEEKENDS)
                               + (afterHoursScore * WEIGHT_AFTER_HOURS)
                               + (missedBreakScore * WEIGHT_MISSED_BREAKS);

            totalScore = totalScore.setScale(1, RoundingMode.HALF_UP);

            // Classify risk level
            String riskLevel;
            if (totalScore >= RED_THRESHOLD) {
                riskLevel = 'Red';
            } else if (totalScore >= AMBER_THRESHOLD) {
                riskLevel = 'Amber';
            } else {
                riskLevel = 'Green';
            }

            // Create WellbeingScore record
            WellbeingScore__c ws = new WellbeingScore__c(
                Score__c = totalScore,
                Risk_Level__c = riskLevel,
                Employee_Activity__c = activity.Id
            );
            scoresToInsert.add(ws);

            result.riskLevel = riskLevel;
            result.score = totalScore;
            result.employeeName = activity.Employee_Name__c;
            resultsList.add(result);
        }

        // Bulk insert wellbeing scores
        if (!scoresToInsert.isEmpty()) {
            insert scoresToInsert;

            // Map back the IDs to results
            for (Integer i = 0; i < resultsList.size(); i++) {
                if (i < scoresToInsert.size()) {
                    resultsList[i].wellbeingScoreId = scoresToInsert[i].Id;
                }
            }
        }

        return resultsList;
    }

    // --- Normalization helpers (map raw values to 0-100 scale) ---

    private static Decimal normalizeHours(Decimal hours) {
        // 40 hrs = 0 risk, 80+ hrs = 100 risk
        if (hours == null || hours <= 40) return 0;
        if (hours >= 80) return 100;
        return ((hours - 40) / 40) * 100;
    }

    private static Decimal normalizeOverdue(Decimal overdue) {
        // 0 = 0 risk, 15+ = 100 risk
        if (overdue == null || overdue <= 0) return 0;
        if (overdue >= 15) return 100;
        return (overdue / 15) * 100;
    }

    private static Decimal normalizeWeekends(Decimal weekends) {
        // 0 = 0 risk, 4+ = 100 risk
        if (weekends == null || weekends <= 0) return 0;
        if (weekends >= 4) return 100;
        return (weekends / 4) * 100;
    }

    private static Decimal normalizeAfterHours(Decimal emails) {
        // 0 = 0 risk, 20+ = 100 risk
        if (emails == null || emails <= 0) return 0;
        if (emails >= 20) return 100;
        return (emails / 20) * 100;
    }

    private static Decimal normalizeMissedBreaks(Decimal breaks) {
        // 0 = 0 risk, 10+ = 100 risk
        if (breaks == null || breaks <= 0) return 0;
        if (breaks >= 10) return 100;
        return (breaks / 10) * 100;
    }
}
