# .ai/ — AI Engineering Operating System

This directory acts as the central intelligence repository and guidelines hub for AI agents (e.g. Claude, Antigravity, or other LLMs) working on BikkoChain. It contains guidelines, contexts, workflows, checklists, and templates to keep AI assistance high-quality, secure, consistent, and context-aware.

---

## 📂 Folder Overview

* **[context/](file:///c:/Users/user/Desktop/bikkofarms-platform/.ai/context/)**
  High-level product specs, roadmap, system architecture details, and project plans (e.g., product context, landing page plans).
* **[skills/](file:///c:/Users/user/Desktop/bikkofarms-platform/.ai/skills/)**
  Modular manuals outlining best practices, pitfalls, constraints, and coding conventions for specific modules (Next.js design, databases, USSD, WhatsApp, security, etc.).
* **[rules/](file:///c:/Users/user/Desktop/bikkofarms-platform/.ai/rules/)**
  Global directives that must govern all AI suggestions (e.g., TS usage, simplicity, security first).
* **[workflows/](file:///c:/Users/user/Desktop/bikkofarms-platform/.ai/workflows/)**
  Structured operating procedures for feature development, hotfixes, deployments, and architectural design changes.
* **[agents/](file:///c:/Users/user/Desktop/bikkofarms-platform/.ai/agents/)**
  Definition of specialized agent personas (Frontend, Backend, Blockchain, QA, DevOps) and their corresponding domain boundaries.
* **[checks/](file:///c:/Users/user/Desktop/bikkofarms-platform/.ai/checks/)**
  Systematic checklists (manual and automated) that must be passed before merging code.
* **[decisions/](file:///c:/Users/user/Desktop/bikkofarms-platform/.ai/decisions/)**
  Architectural Decision Records (ADRs) tracking design choices and technical rationales.
* **[templates/](file:///c:/Users/user/Desktop/bikkofarms-platform/.ai/templates/)**
  Boilerplate definitions for ADRs, skills, issues, etc.
* **[prompts/](file:///c:/Users/user/Desktop/bikkofarms-platform/.ai/prompts/)**
  Curated instructions/prompt fragments for code-reviews, feature planning, etc.

---

## 🤖 Instructions for AI Agents

Whenever you are triggered to write code or modify files:
1. **Initialize Context:** Read `CLAUDE.md` at the repository root and [.ai/rules/agent-rules.md](file:///c:/Users/user/Desktop/bikkofarms-platform/.ai/rules/agent-rules.md) to understand current coding boundaries.
2. **Consult Workflows:** Follow the relevant workflow in [.ai/workflows/](file:///c:/Users/user/Desktop/bikkofarms-platform/.ai/workflows/).
3. **Reference Specific Skills:** If writing UI, backend APIs, or USSD configurations, read the corresponding skill file under [.ai/skills/](file:///c:/Users/user/Desktop/bikkofarms-platform/.ai/skills/) to adopt correct design, testing, and implementation patterns.
4. **Assert Checklists:** Verify your output against [.ai/checks/](file:///c:/Users/user/Desktop/bikkofarms-platform/.ai/checks/) before submitting a PR proposal.
