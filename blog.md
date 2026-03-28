# Agentforce Scripts: Hybrid Reasoning, Action Chaining, and What It Actually Looks Like in Practice

**Salesforce gave agents a scripting language. I tested it by building something that matters.**

---

If you've been following the Salesforce ecosystem lately, you've probably heard the buzz around **Agentforce** — Salesforce's AI agent platform. But buried inside that buzz is something genuinely powerful that doesn't get talked about enough: **Agent Script**.

Agent Script is a high-level, declarative scripting language designed specifically for controlling Agentforce agents. It lets you combine **deterministic business logic** (IF conditions, guaranteed action sequences, hard rules) with **generative AI reasoning** (LLM-powered natural language, contextual responses, empathetic communication) — all inside one agent.

Salesforce calls this **hybrid reasoning**. And after spending time building with it, I think it's the most important feature Agentforce has shipped.

In this post, I'll walk through the key Agentforce features — what they do, how they work together — and show how I put them to the test by building an Employee Burnout Prevention Agent for the Agent Script Quest.

---

## What Is Agent Script and Why Should You Care?

Before Agent Script, building Agentforce agents meant configuring topics and actions, then hoping the LLM would reason through them correctly. The LLM was both the brain and the decision-maker. That works for simple use cases, but the moment you need **guaranteed behaviour** — "if this condition is true, you MUST do this, no exceptions" — you were stuck. LLMs are probabilistic. Business rules are not.

Agent Script changes this entirely.

It's a compiled language that generates an **Agent Graph** specification consumed by the **Atlas Reasoning Engine**. You write instructions that blend two layers:

1. **Deterministic layer** — IF/ELSE conditions, action calls, variable assignments. These execute exactly as written. The LLM cannot override them.
2. **Generative layer** — Prompts that let the LLM generate natural language responses, adapt tone, personalise messages. The LLM gets creative freedom here.

The result: agents that are **predictable where it matters** and **human where it counts**.

This isn't a theoretical concept. The [Agent Script Recipes library](https://developer.salesforce.com/sample-apps/agent-script-recipes) on Salesforce Developers provides working patterns for multi-action chaining, conditional routing, variable passing, and more. These recipes are what inspired me to go further and apply them to a real-world use case.

---

## The Agentforce Features — Explained

Let me break down each feature I explored and what it brings to the table.

### 1. Agentforce Builder — Canvas View

When you open an agent in Agentforce Builder, you land in **Canvas view**. This is the visual layer — it summarises your Agent Script into easily understandable blocks that you can expand to see the underlying script.

What makes Canvas view useful:
- You get a bird's-eye view of your agent's structure — topics, actions, and how they connect
- Type `/` to quickly add expressions for common patterns (if-else conditionals, loops)
- Type `@` to add resources like topics, actions, and variables
- Non-technical stakeholders can read and review agent logic without touching code

Canvas view is the **communication layer**. It's how you show your team what the agent does without drowning them in script syntax.

### 2. Agentforce Builder — Script View

Switch to **Script view**, and you're looking at what's happening under the hood — the actual Agent Script instructions that drive the agent's reasoning.

Script view is a code editor interface where you can:
- Write Agent Script directly with full syntax support
- Make fast, precise changes
- Dig into error messages when things break
- See the deterministic and generative layers side by side

The critical thing: **Canvas view and Script view are always in sync**. Edit in one, and it reflects in the other. This means you can prototype visually in Canvas and fine-tune in Script — or vice versa.

### 3. Agent Script — Hybrid Reasoning

This is the core. Agent Script enables what Salesforce officially calls **hybrid reasoning** — the configurable Atlas Reasoning Engine balancing LLM creativity with structured business logic.

Here's what this looks like conceptually:

```
// DETERMINISTIC LAYER — Hard rules. Non-negotiable.
IF riskLevel == "Red":
    CALL Schedule_Manager_Meeting
    CALL Create_HR_Alert

IF riskLevel == "Amber":
    // No escalation. Period.

IF riskLevel == "Green":
    // No escalation. Just acknowledgement.

// GENERATIVE LAYER — LLM takes over.
GENERATE a personalised, empathetic message
- Use the employee's first name
- Reference their situation without exposing internal scores
- Speak like a caring colleague, not a system notification
```

The IF conditions are **business rule guarantees**. The LLM cannot skip them, reinterpret them, or override them. They fire deterministically, every single time.

The message generation below is pure LLM. It gets creative freedom to write something warm, contextual, and human.

**Hard rules in code. Warmth in language.** That's hybrid reasoning.

### 4. Action Chaining

[Action chaining](https://developer.salesforce.com/docs/ai/agentforce/guide/ascript-patterns-action-chaining.html) is one of the most practical patterns from the Agent Script documentation. It enables multiple actions in a **guaranteed sequence** — reliable multi-step workflows without relying on the LLM to remember multiple steps.

There are several ways to chain actions:

- **Sequential instructions** — Actions run deterministically before LLM reasoning occurs
- **Variable passing** — Store the output of one action in a variable, use it as input to the next action
- **Reasoning actions** — Define a follow-up action that automatically fires when the LLM calls a primary action
- **Conditional chaining** — Chain actions based on the results of previous actions
- **Transitions with actions** — Run an action and then automatically transition to another topic

The key benefit: the **sequence is guaranteed**. Action A always runs before Action B. Action B only fires if Action A's output meets a condition. No ambiguity.

### 5. Conditional Routing

Conditional routing controls when actions fire and when topics transition, based on state and variables. In Agent Script, you write IF conditions that evaluate action outputs and route the agent's behaviour accordingly.

This isn't just "if X then do Y." It's full control over the entire agent response:
- Which actions fire
- Which actions are blocked
- What tone the LLM takes in its response
- Whether the agent escalates, stays quiet, or celebrates

Three different inputs can produce three completely different agent behaviours — all governed by the same script.

### 6. Apex Invocable Actions

Agent Script doesn't do computation itself — it orchestrates. The actual logic lives in **Apex Invocable classes** that the agent calls as actions.

This is a clean separation of concerns:
- **Apex** handles the math, the data operations, the record creation
- **Agent Script** handles the decision-making, sequencing, and routing
- **The LLM** handles the human communication

Each Apex action is an `@InvocableMethod` class that takes typed inputs and returns typed outputs. Agent Script stores those outputs in variables and uses them to drive conditional logic.

### 7. Preview Panel

Inside Agentforce Builder, there's a **Conversation Preview** panel where you can test your agent in real-time without deploying anything. Type a message, and the agent processes it live — firing actions, evaluating conditions, generating responses.

This is the fastest feedback loop for agent development. Write script, test immediately, iterate.

### 8. Trace Panel

This is arguably the most underrated feature in the entire builder.

Click the **Trace** link under any agent response, and you get a step-by-step breakdown of every reasoning step the agent took:

```
Step 1 — Topic classified as "Assess Wellbeing"
Step 2 — Calculate Burnout Score action called → returned "Red"
Step 3 — Schedule Manager Meeting action triggered
Step 4 — Create HR Alert action triggered
Step 5 — LLM generated personalised message
```

Every action call. Every condition evaluation. Every LLM generation step. Full transparency.

In enterprise contexts — especially anything touching HR, compliance, or finance — being able to prove **why** the agent did what it did isn't optional. The Trace panel gives you that audit trail out of the box.

### 9. The Atlas Reasoning Engine

Under the hood, Agent Script compiles into an **Agent Graph** consumed by the Atlas Reasoning Engine. This engine is now **configurable** — you can balance the creativity of LLMs with the certainty of structured business logic.

The Atlas Reasoning Engine handles:
- Reflective loops
- Multi-topic coordination
- Multi-agent coordination
- Action sequencing exactly as defined in your script

This isn't prompt-and-pray. It's a structured execution environment where deterministic and generative reasoning coexist by design.

---

## Putting It All Together: The Burnout Prevention Agent

To test these features end-to-end, I built an **Employee Burnout Prevention Agent** for the Salesforce Agent Script Quest. The idea: an autonomous AI agent that monitors employee work patterns, detects burnout risk, and intervenes with the right action — without any human prompt.

I was directly inspired by the multi-action chaining and conditional routing patterns from the [Agent Script Recipes library](https://developer.salesforce.com/sample-apps/agent-script-recipes) — and pushed them into a real-world HR use case.

### The Data Model

Three custom objects:

**EmployeeActivity__c**
Stores work pattern data — weekly hours, overdue tasks, weekend logins, after-hours emails, missed breaks. This is the input layer.

**WellbeingScore__c**
Agent's calculated output — burnout score and risk level (Red / Amber / Green). Internal only. Employees never see this.

**HR_Alert__c**
Confidential record created only for Red-risk employees. The employee never sees this. HR gets visibility without creating stigma.

### The Apex Actions

**Calculate Burnout Score** — Weighted algorithm scoring 5 signals (login hours, overdue tasks, weekend logins, after-hours emails, missed breaks) and outputs a risk level. *Fires always — first in the chain.*

**Schedule Manager Meeting** — Creates a confidential calendar event and a high-priority task for the employee's manager. *Fires for Red risk only.*

**Create HR Alert** — Creates a silent, confidential `HR_Alert__c` record. *Fires for Red risk only.*

The scoring algorithm is pure deterministic Apex — no LLM decides someone's risk level. That's a business rule, not a creative task.

### The Agent Script Structure

One topic: **Assess Wellbeing**. I deliberately kept it single-topic because the power here is in the action chaining and conditional logic, not in complex topic routing.

The script uses:
- **Action chaining** — Calculate Score runs first, its output (risk level) is stored in a variable, that variable feeds into conditional logic for the next actions
- **Conditional routing** — Red triggers all three actions + urgent message. Amber triggers only the score + gentle check-in. Green triggers only the score + positive reinforcement.
- **Hybrid reasoning** — Deterministic IF conditions for action routing, LLM generation for empathetic employee messages

### Three Tests, Three Completely Different Outcomes

I tested with three demo employees, each representing a different burnout profile:

**Leila Novak — Red Risk (67 hours/week, 13 overdue tasks, 4 weekend logins)**

What the Trace panel showed:
```
Topic → Assess Wellbeing
Action → Calculate Burnout Score → Red
Action → Schedule Manager Meeting → Triggered
Action → Create HR Alert → Triggered
LLM → Generated warm, personal message
```

What Leila sees: A warm, personal message with no scores, no clinical language — just genuine care.
What gets created silently: WellbeingScore (Red), HR Alert (confidential), Manager Task (high priority), Calendar Event (1:1 meeting).

All in under 10 seconds. Leila didn't ask for help. Her manager didn't notice. Nobody typed anything.

**Florence Stein — Amber Risk (52 hours/week, some weekend activity)**

Trace panel: Only the scoring action fired. No meeting. No HR alert. The deterministic rules correctly blocked escalation. Florence received a gentle, empathetic check-in — proportionate and intelligent.

**Shane Marin — Green Risk (38 hours/week, zero weekend logins)**

Trace panel: Just the scoring action. No escalations. A positive, warm acknowledgement of healthy work habits.

Three employees. Three completely different, perfectly proportionate responses. All autonomous.

---

## Why Not Just Use Apex and Flows?

Fair question. You could absolutely build a scoring engine, conditional record creation, and template emails with Apex and Flows alone. But here's what you'd lose:

**The messages would be dead.** A template email saying "Your burnout score is Amber, please take care" is clinical, impersonal, and gets ignored. The LLM writes messages that feel like they come from a real person. Every message is different. Every message is tailored to the individual.

**The logic would be fragile.** Hard-coding every conditional path in a Flow means every new risk factor requires a new Flow version. Agent Script's conditional routing is declarative and readable — the entire decision tree in one screen.

**There would be no transparency.** The Trace panel gives you an audit trail of every decision. In an HR context, proving *why* the agent escalated (or didn't) is a legal requirement in many jurisdictions. Flows don't give you that reasoning chain.

Hybrid reasoning isn't about replacing Flows — it's about handling use cases where you need **both guaranteed behaviour and human-quality communication** in the same workflow.

---

## What I Took Away from Building with Agent Script

**Start with one topic.** Don't over-engineer the topic structure. The power is in actions and conditional logic, not in topic routing complexity.

**Let Apex handle the math, let the LLM handle the humans.** Scoring algorithms should be deterministic. Messages to real people should be generative. Don't mix these up.

**The Trace panel is non-negotiable for enterprise use.** If you can't explain why the agent did something, you can't ship it. Build with traceability from day one.

**Study the Agent Script Recipes before building from scratch.** The multi-action chaining and conditional routing patterns saved me hours. Start there, then adapt.

**Design for dignity.** If your agent touches anything sensitive — HR, health, performance — never expose internal scores to the people being assessed. The system should feel like a caring colleague, not a surveillance tool.

---

## The Bigger Picture

Agentforce isn't just a chatbot platform with better branding. Agent Script, hybrid reasoning, the Atlas Reasoning Engine, action chaining, conditional routing — these are infrastructure for building agents that enterprises can actually trust.

The Burnout Prevention Agent is one use case. But the same patterns — deterministic business rules + generative communication + full traceability — apply to:
- **Sales**: Lead scoring with personalised outreach
- **Support**: Ticket triage with empathetic customer responses
- **Finance**: Compliance checks with contextual explanations
- **Operations**: Anomaly detection with proportionate escalation

The tools are here. The recipes are documented. The builder makes it accessible.

If you're in the Salesforce ecosystem and you haven't explored Agent Script yet — now is the time.

---

*I'm Likhit, based out of Tamil Nadu, India. I built the Employee Burnout Prevention Agent for the Salesforce Agent Script Quest. You can find the demo recording on [X/Twitter](https://x.com/likhitVP).*

---

**Tags:** `#Salesforce` `#Agentforce` `#AgentScript` `#HybridReasoning` `#AI` `#AtlasReasoningEngine` `#AgentforceBuilder` `#ActionChaining` `#HRTech` `#BurnoutPrevention`

---

*References:*
- [Introducing Hybrid Reasoning with Agent Script — Salesforce Developers Blog](https://developer.salesforce.com/blogs/2025/10/introducing-hybrid-reasoning-with-agent-script)
- [Agent Script Decoded: Language Fundamentals — Salesforce Developers Blog](https://developer.salesforce.com/blogs/2026/02/agent-script-decoded-intro-to-agent-script-language-fundamentals)
- [Action Chaining Patterns — Agentforce Developer Guide](https://developer.salesforce.com/docs/ai/agentforce/guide/ascript-patterns-action-chaining.html)
- [Agent Script Recipes — Salesforce Developers](https://developer.salesforce.com/sample-apps/agent-script-recipes)
- [Agent Script Documentation — Agentforce Developer Guide](https://developer.salesforce.com/docs/ai/agentforce/guide/agent-script.html)
- [Build With Confidence: Inside the New Agentforce Builder — Salesforce Admins](https://admin.salesforce.com/blog/2026/build-with-confidence-inside-the-new-agentforce-builder)
- [How Does Agent Script Give Admins More Control? — Salesforce Admins Podcast](https://admin.salesforce.com/blog/2026/how-does-agent-script-give-admins-more-control-podcast)
- [Agentforce 360 Announcements — Salesforce](https://www.salesforce.com/agentforce/what-is-new/?bc=OTH)
