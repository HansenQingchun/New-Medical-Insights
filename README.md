# New Medical Insights — Copilot Studio Multi-Agent DEMO

> Reconstructing a GenAI medical content platform on **Microsoft Copilot Studio + Azure AI Foundry**, embedded natively in **Word / Teams / Web** — run 3 high-value scenarios live in 8 minutes.

This repository is a **demo blueprint** for **New Medical Insights (NMI)** — a GenAI content-generation assistant for healthcare & life sciences — built as a **multi-agent solution on the Microsoft stack**. It ships the architecture, infrastructure-as-code, agent system prompts, demo data, and a runnable 8-minute demo script.

> ⚕️ Demonstration / proof-of-concept with simulated data. Not for clinical or production use.

## 🎯 Why Microsoft

1. **Zero-friction integration** — medical writers live in **Word**; a Copilot Studio agent appears in the Word side panel via an **M365 Copilot declarative extension** — no tool switching.
2. **Enterprise compliance & identity** — **Microsoft Entra ID + Purview + Key Vault** cover audit, governance, and data-residency needs.
3. **Visual multi-agent orchestration** — **Copilot Studio**'s low-code canvas lets business teams help shape the agents.

## 🧪 Demo Scenarios (end-to-end)

| # | Scenario | Business value | Time |
|---|----------|----------------|------|
| A | Medical paragraph generation + PubMed citations → one-click insert into Word | Writing efficiency **5–10×** | 2.5 min |
| B | English clinical-abstract PDF → Chinese `.docx` with locked terminology | Translation cost **−60%+**, term consistency ≥95% | 2.5 min |
| C | Paste a paragraph → parallel rule + fact compliance review | Review cycle: days → minutes | 2 min |

## 🤖 Multi-Agent Architecture

An **Orchestrator** agent routes user intent to specialized sub-agents:

- **Translator Agent** — medical translation (text / PDF / Word) with glossary & reference-store injection (Azure AI Translator + Foundry + AI Search + Document Intelligence).
- **Writer Agent** — paragraph/article generation, rewrite, summarize, with PubMed retrieval (Azure AI Search + Foundry).
- **Compliance Agent** — parallel rule review (FDA/NMPA warning rules) + fact-checking against cited literature.
- **Monitoring / Sales Assistant** — supporting analytics agent.

System prompts for every agent are in [`agents/`](agents/).

## 🏗️ Tech Stack

- **Microsoft Copilot Studio** (multi-agent, generative orchestration)
- **Azure AI Foundry** (chat models), **Azure AI Search**, **Azure AI Document Intelligence**, **Azure AI Translator**
- **Azure Functions** (Python) — `pubmed-connector`, `doc-processor`
- **Azure Cosmos DB**, **Storage**, **Key Vault**, **Managed Identity**, **Application Insights**
- **Bicep** IaC + **Azure Developer CLI (`azd`)**

## 🗂️ Repository Structure

```
.
├── PRD-NMI-Copilot-Studio-Demo.md   # Product Requirements Document (full)
├── azure.yaml                       # azd project (infra + Function services)
├── assistant-media.json             # Demo assistant media assets
├── agents/                          # Copilot Studio agent system prompts
│   ├── orchestrator-system-prompt.md
│   ├── translator-system-prompt.md
│   ├── writer-system-prompt.md
│   ├── compliance-system-prompt.md
│   └── monitoring-sales-system-prompt.md
├── demo-data/                       # Glossary, reference store, samples, rules
├── docs/                            # Architecture, setup guide, demo scripts, diagrams
├── infra/                           # Bicep modules (AI Foundry, Search, Cosmos, ...)
└── services/                        # Azure Function connectors (doc-processor, pubmed)
```

## 🚀 Getting Started

Provision the Azure infrastructure with the Azure Developer CLI:

```bash
azd auth login
azd up          # provisions infra/ and deploys services/
```

Then follow:
1. `demo-data/README.md` — upload demo data
2. `agents/*.md` — create the Copilot Studio agents
3. `docs/copilot-studio-setup-guide.md` — wire up the M365 Copilot declarative extension
4. `docs/demo-script-8min.md` — run the live demo

See [`docs/architecture-diagram.md`](docs/architecture-diagram.md) for the full architecture (Mermaid diagrams).

## 📄 Documentation

The complete PRD (background, agent topology, tools, data model, demo flow) is in `PRD-NMI-Copilot-Studio-Demo.md`.

---

> **Note on excluded files:** a legacy third-party product manual (`old MDI.pdf` / `.txt`) is not redistributable and is intentionally **not** included. Local Azure environment files under `.azure/` (subscription/tenant IDs, endpoints) are git-ignored.
