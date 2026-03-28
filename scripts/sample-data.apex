// Run this in Developer Console → Execute Anonymous
// Creates 3 demo employees with different burnout profiles

List<EmployeeActivity__c> activities = new List<EmployeeActivity__c>();

// RED RISK — Leila Novak (critically burned out)
activities.add(new EmployeeActivity__c(
    Employee_Name__c    = 'Leila Novak',
    Weekly_Hours__c     = 67,
    Overdue_Tasks__c    = 13,
    Weekend_Logins__c   = 4,
    After_Hours_Emails__c = 18,
    Missed_Breaks__c    = 7
));

// AMBER RISK — Florence Stein (early warning signs)
activities.add(new EmployeeActivity__c(
    Employee_Name__c    = 'Florence Stein',
    Weekly_Hours__c     = 52,
    Overdue_Tasks__c    = 5,
    Weekend_Logins__c   = 2,
    After_Hours_Emails__c = 8,
    Missed_Breaks__c    = 3
));

// GREEN RISK — Shane Marin (perfectly healthy)
activities.add(new EmployeeActivity__c(
    Employee_Name__c    = 'Shane Marin',
    Weekly_Hours__c     = 38,
    Overdue_Tasks__c    = 0,
    Weekend_Logins__c   = 0,
    After_Hours_Emails__c = 2,
    Missed_Breaks__c    = 0
));

insert activities;

System.debug('✅ Created ' + activities.size() + ' demo employee records:');
for (EmployeeActivity__c a : activities) {
    System.debug('   → ' + a.Employee_Name__c + ' (ID: ' + a.Id + ')');
}
