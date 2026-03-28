/**
 * ScheduleManagerMeeting
 *
 * Invocable Apex action used by the Burnout Prevention Agent.
 * Called ONLY when risk level is Red (enforced by Agent Script's
 * deterministic IF conditions — the LLM cannot override this).
 *
 * Creates:
 * 1. A confidential calendar Event for the manager
 * 2. A high-priority Task assigned to the manager
 *
 * The employee is NOT notified about the meeting creation.
 */
public with sharing class ScheduleManagerMeeting {

    public class MeetingRequest {
        @InvocableVariable(required=true description='The record ID of the EmployeeActivity__c')
        public Id employeeActivityId;

        @InvocableVariable(required=true description='The employee name for the meeting subject')
        public String employeeName;
    }

    public class MeetingResult {
        @InvocableVariable(description='The ID of the created Task')
        public Id taskId;

        @InvocableVariable(description='The ID of the created Event')
        public Id eventId;

        @InvocableVariable(description='Confirmation message')
        public String message;
    }

    @InvocableMethod(
        label='Schedule Manager Meeting'
        description='Creates a confidential manager meeting and high-priority task for Red-risk employees.'
    )
    public static List<MeetingResult> schedule(List<MeetingRequest> requests) {
        List<MeetingResult> results = new List<MeetingResult>();
        List<Task> tasksToInsert = new List<Task>();
        List<Event> eventsToInsert = new List<Event>();

        for (MeetingRequest req : requests) {
            // Create high-priority Task for the manager
            Task managerTask = new Task(
                Subject = 'CONFIDENTIAL: Wellbeing Check-in — ' + req.employeeName,
                Description = 'The Burnout Prevention Agent has identified ' + req.employeeName
                            + ' as Red risk. Please schedule a private, supportive 1:1 conversation. '
                            + 'Do NOT reference the burnout score or this system to the employee.',
                Priority = 'High',
                Status = 'Not Started',
                ActivityDate = Date.today().addDays(2),
                WhatId = req.employeeActivityId
            );
            tasksToInsert.add(managerTask);

            // Create confidential calendar Event
            Event meetingEvent = new Event(
                Subject = 'CONFIDENTIAL: 1:1 Check-in — ' + req.employeeName,
                Description = 'Auto-scheduled by Burnout Prevention Agent. '
                            + 'This is a confidential wellbeing check-in. '
                            + 'Approach with empathy — do not mention scores or automated detection.',
                StartDateTime = DateTime.now().addDays(2).addHours(10),
                EndDateTime = DateTime.now().addDays(2).addHours(10).addMinutes(30),
                WhatId = req.employeeActivityId
            );
            eventsToInsert.add(meetingEvent);
        }

        // Bulk insert
        if (!tasksToInsert.isEmpty()) {
            insert tasksToInsert;
        }
        if (!eventsToInsert.isEmpty()) {
            insert eventsToInsert;
        }

        // Build results
        for (Integer i = 0; i < requests.size(); i++) {
            MeetingResult result = new MeetingResult();
            result.taskId = tasksToInsert[i].Id;
            result.eventId = eventsToInsert[i].Id;
            result.message = 'Manager meeting and task created for ' + requests[i].employeeName;
            results.add(result);
        }

        return results;
    }
}
