# Employee Burnout Prevention Agent

An autonomous Agentforce agent that monitors employee work patterns, detects burnout risk before anyone notices, and intervenes with the right action — without any human prompt.

Built with **Agentforce Scripts**, **Hybrid Reasoning**, and **Apex Invocable Actions** for the Salesforce Agent Script Quest.

---

## What It Does

The agent assesses employee work patterns and responds proportionately:

- **Red Risk** — Calculates burnout score + schedules a confidential manager meeting + creates a silent HR alert + sends a warm, empathetic message
- **Amber Risk** — Calculates burnout score + sends a gentle check-in message. No escalation.
- **Green Risk** — Calculates burnout score + sends positive reinforcement. No escalation.

The employee never sees their score. Alerts are confidential. Messages are LLM-generated and empathetic — not template emails.

---

## Architecture

```
┌─────────────────────────────────────────────────┐
│              Agentforce Agent                    │
│         Topic: "Assess Wellbeing"                │
│                                                  │
│  ┌──────────────────────────────────────────┐    │
│  │     DETERMINISTIC LAYER (Agent Script)   │    │
│  │                                          │    │
│  │  1. CALL CalculateBurnoutScore           │    │
│  │  2. IF Red → CALL ScheduleManagerMeeting │    │
│  │  3. IF Red → CALL CreateHRAlert          │    │
│  └──────────────────────────────────────────┘    │
│                                                  │
│  ┌──────────────────────────────────────────┐    │
│  │     GENERATIVE LAYER (LLM)              │    │
│  │                                          │    │
│  │  Generate warm, personalised message     │    │
│  │  tailored to risk level and employee     │    │
│  └──────────────────────────────────────────┘    │
└─────────────────────────────────────────────────┘
         │                │               │
         ▼                ▼               ▼
  EmployeeActivity__c  WellbeingScore__c  HR_Alert__c
     (input)           (internal score)   (confidential)
```

---

## Agentforce Features Used

- **Agentforce Builder** — Canvas View + Script View
- **Agent Script** — Hybrid reasoning (deterministic IF conditions + generative LLM messages)
- **Action Chaining** — Guaranteed sequential execution of Apex actions
- **Conditional Routing** — Risk-level-based action triggering
- **Apex Invocable Actions** — Three custom actions powering the agent
- **Preview Panel** — Real-time agent testing inside the builder
- **Trace Panel** — Full reasoning transparency and audit trail
- **Atlas Reasoning Engine** — Configurable hybrid reasoning backbone

---

## Setup from Scratch

### Prerequisites

- Salesforce org with **Agentforce** enabled (Developer Edition or Enterprise+)
- **Salesforce CLI** installed ([install guide](https://developer.salesforce.com/tools/salesforcecli))
- **Git** installed

### Step 1: Clone the Repo

```bash
git clone https://github.com/Likhit-Kumar/BurnoutTracker-Agentforce.git
cd BurnoutTracker-Agentforce
```

### Step 2: Authenticate Your Org

```bash
sf org login web --alias burnout-org --set-default
```

This opens a browser — log in to your Salesforce org.

### Step 3: Deploy the Metadata

```bash
sf project deploy start --target-org burnout-org
```

This deploys:
- 3 custom objects (`EmployeeActivity__c`, `WellbeingScore__c`, `HR_Alert__c`)
- 3 Apex classes (`CalculateBurnoutScore`, `ScheduleManagerMeeting`, `CreateHRAlert`)

### Step 4: Load Sample Data

Open **Developer Console** in your org (Setup gear icon > Developer Console), then:

1. Click **Debug > Open Execute Anonymous Window**
2. Paste the contents of `scripts/sample-data.apex`
3. Click **Execute**
4. Check the debug log — you'll see 3 employee record IDs

### Step 5: Configure the Agentforce Agent

1. Go to **Setup > Agentforce > Agents** and create a new agent
2. Add a topic: **Assess Wellbeing**
3. Under the topic, add these three actions (they'll appear as Apex Invocable Actions):
   - `Calculate Burnout Score`
   - `Schedule Manager Meeting`
   - `Create HR Alert`
4. Open **Script View** and add the reasoning instructions:

```
// Step 1: Always calculate the burnout score first
CALL Calculate Burnout Score with the provided EmployeeActivity record ID.
Store the returned riskLevel, score, and employeeName.

// Step 2: Conditional actions based on risk level
IF riskLevel == "Red":
    CALL Schedule Manager Meeting with the employeeActivityId and employeeName.
    CALL Create HR Alert with the employeeActivityId, employeeName, riskLevel, and score.

// Step 3: Generate an empathetic message (LLM handles this)
Based on the risk level, generate a warm and personalised message:
- For Red: Acknowledge their hard work, express genuine concern, encourage them
  to take a step back. Do NOT mention scores, systems, or automated detection.
- For Amber: Gently check in, suggest balance, keep it light and supportive.
- For Green: Positively reinforce their healthy work habits. Celebrate them.

Always use the employee's first name. Speak like a caring colleague.
Never mention burnout scores, risk levels, or that this was automated.
```

### Step 6: Test in Preview Panel

1. In Agentforce Builder, open the **Preview** panel (right side)
2. Type: `Assess burnout for record ID: <paste an EmployeeActivity ID>`
3. Check the **Trace** panel to see every reasoning step
4. Test all three employees — verify Red/Amber/Green get proportionate responses

---

## Custom Objects

**EmployeeActivity__c** — Input data

| Field | Type | Description |
|-------|------|-------------|
| `Employee_Name__c` | Text | Full name of the employee |
| `Weekly_Hours__c` | Number | Average hours worked per week |
| `Overdue_Tasks__c` | Number | Count of overdue tasks |
| `Weekend_Logins__c` | Number | Weekend login count |
| `After_Hours_Emails__c` | Number | Emails sent outside work hours |
| `Missed_Breaks__c` | Number | Scheduled breaks that were skipped |

**WellbeingScore__c** — Agent output (internal only)

| Field | Type | Description |
|-------|------|-------------|
| `Score__c` | Number | Burnout score 0-100 |
| `Risk_Level__c` | Picklist | Red / Amber / Green |
| `Employee_Activity__c` | Lookup | Link to the assessed activity record |

**HR_Alert__c** — Confidential alert (Red risk only)

| Field | Type | Description |
|-------|------|-------------|
| `Alert_Type__c` | Picklist | Alert classification |
| `Employee_Activity__c` | Lookup | Link to the activity record |
| `Confidential_Notes__c` | Long Text | Internal notes (never shown to employee) |

---

## Scoring Algorithm

The `CalculateBurnoutScore` class uses a weighted formula across 5 signals:

| Signal | Weight | 0 Risk | 100 Risk |
|--------|--------|--------|----------|
| Weekly Hours | 30% | 40 hrs or less | 80+ hrs |
| Overdue Tasks | 25% | 0 tasks | 15+ tasks |
| Weekend Logins | 20% | 0 logins | 4+ logins |
| After-Hours Emails | 15% | 0 emails | 20+ emails |
| Missed Breaks | 10% | 0 breaks missed | 10+ breaks |

**Risk thresholds:**
- Score >= 70 → **Red** (critical — full intervention)
- Score >= 40 → **Amber** (early warning — gentle check-in)
- Score < 40 → **Green** (healthy — positive reinforcement)

---

## Demo Employees

The sample data script creates three employees:

**Leila Novak** — Red Risk
67 hrs/week, 13 overdue tasks, 4 weekend logins, 18 after-hours emails, 7 missed breaks. Critically burned out. Agent triggers full intervention.

**Florence Stein** — Amber Risk
52 hrs/week, 5 overdue tasks, 2 weekend logins, 8 after-hours emails, 3 missed breaks. Early warning signs. Agent sends gentle check-in only.

**Shane Marin** — Green Risk
38 hrs/week, 0 overdue tasks, 0 weekend logins, 2 after-hours emails, 0 missed breaks. Healthy. Agent sends positive reinforcement.

---

## Project Structure

```
BurnoutTracker-Agentforce/
├── force-app/main/default/
│   ├── classes/
│   │   ├── CalculateBurnoutScore.cls          # Weighted scoring algorithm
│   │   ├── CalculateBurnoutScore.cls-meta.xml
│   │   ├── ScheduleManagerMeeting.cls         # Manager task + event creation
│   │   ├── ScheduleManagerMeeting.cls-meta.xml
│   │   ├── CreateHRAlert.cls                  # Confidential HR alert
│   │   └── CreateHRAlert.cls-meta.xml
│   └── objects/
│       ├── EmployeeActivity__c/               # Work pattern input data
│       ├── WellbeingScore__c/                 # Calculated score (internal)
│       └── HR_Alert__c/                       # Confidential alerts
├── scripts/
│   └── sample-data.apex                       # Demo employee data
├── sfdx-project.json
└── README.md
```

---

## Blog

Read the full technical breakdown: [Agentforce Scripts: Hybrid Reasoning, Action Chaining, and What It Actually Looks Like in Practice](#) *(https://medium.com/@likhitkumarvp/agentforce-scripts-hybrid-reasoning-action-chaining-and-what-it-actually-looks-like-in-practice-39fb193572d1)*

---

## Built By

**Likhit Kumar VP**
[X/Twitter](https://x.com/likhitVP)

Built for the Salesforce Agent Script Quest. Inspired by the [Agent Script Recipes](https://developer.salesforce.com/sample-apps/agent-script-recipes) library.

---

## License

MIT
