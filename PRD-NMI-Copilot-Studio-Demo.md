# PRD：New Medical Insights (NMI) — Copilot Studio 多智能体 Demo

> **版本**：v0.2（面向客户/管理层演示）
> **日期**：2026-05-13
> **作者**：（待填）
> **状态**：构思 / 评审中
> **演示对象**：**客户决策层 & 管理层**（业务价值导向）
> **参考来源**：既有医学内容生成平台（NMI）功能需求整理

---

## 0. 执行摘要（Executive Summary）

**一句话**：把既有的医学内容生成平台（NMI），用 **Microsoft Copilot Studio 多智能体 + Azure AI Foundry** 重构为一个 **嵌入 Word/Teams 即用即得** 的医学 AI 助手 Demo，8 分钟现场跑通 3 个高价值场景。

**为什么是 Microsoft（给管理层的 3 个理由）**：
1. **零摩擦集成**：医学撰稿人 90% 时间在 **Word** 里，Copilot Studio agent 通过 **Microsoft 365 Copilot 声明式扩展**直接出现在 Word 侧边栏，**不用切换工具**。
2. **企业级合规与身份**：**Microsoft Entra ID + Purview + Key Vault** 一站式满足医疗行业的合规、审计与数据驻留要求。
3. **多智能体可视化编排**：**Copilot Studio** 提供低代码/无代码画布，业务团队可参与 agent 调整，**降低 IT 改造门槛**。

**Demo 现场看点**：
| # | 场景 | 业务价值 | 时长 |
|---|---|---|---|
| A | 医学段落生成 + PubMed 引用 → 一键插入 Word | 医学撰稿效率提升 **5–10×** | 2.5 min |
| B | 英文 PDF 临床摘要 → 中文 docx（术语锁定） | 翻译成本降低 **60%+**，术语一致性 ≥95% | 2.5 min |
| C | 段落粘贴 → 规则+事实并行审查 | 合规审稿周期从天级缩短到分钟级 | 2 min |

**关键差异化（vs 传统自研方案）**：
- 原版需要专门的 Web 应用 + Word add-in 自研；本方案 **Web + Word + Teams 三端原生入口零额外开发**。
- 传统方案用分散的后端函数拼接业务流；本方案用 **Copilot Studio 多智能体** 显式建模，业务可读、可演进。

---

## 1. 背景与目标

### 1.1 背景
**New Medical Insights (NMI)** 是面向医疗/生命科学行业的 GenAI 内容生成中心，提供：
- 医学翻译（文本 / PDF / Word，支持术语库与样例库）
- 医学写作助手（段落生成、文章生成、改写、翻译、总结、续写、引用）
- 规则审查 & 事实审查（Beta）
- Microsoft Office Word 插件
- 客制化能力：术语库、样例库、写作指令、写作规则
- 知识库连接器：PubMed、Google Scholar、企业内部知识库

### 1.2 目标
在 **Microsoft 技术栈** 上重构 NMI，并采用 **Copilot Studio 多智能体（multi-agent orchestration）** 架构，先交付一个**可演示、端到端可跑通**的简化 Demo，验证：
1. 多智能体协同（Orchestrator + 专业子智能体）的可行性与体验。
2. Microsoft 原生服务（Azure AI Foundry / Translator / AI Search / Entra ID）构建端到端医学内容生成能力的可行性。
3. 与 Microsoft 365（Word / Teams / SharePoint）的原生集成优势。

### 1.3 非目标（Demo 阶段不做）
- 完整的多租户、计费、配额体系
- 大规模术语库（>10 万条）的导入与查询性能调优
- 企业级 SSO 之外的复杂身份场景
- 完整 REST OpenAPI 对外开放
- 自研 Office Word Add-in（**改用 M365 Copilot 声明式扩展**）
- Azure China 部署（仅 Global Azure）

---

## 2. 目标用户与典型场景

### 2.1 目标用户
| 角色 | 描述 | Demo 关注度 |
|---|---|---|
| 医学撰稿人 / Medical Writer | 撰写综述、临床研究报告、市场材料 | ⭐⭐⭐ 主 |
| 医学翻译 / 本地化专员 | 翻译临床/法规/产品文档 | ⭐⭐⭐ 主 |
| 医学顾问 / MSL | 快速检索文献、生成讨论稿 | ⭐⭐ |
| 合规/审稿人 | 规则与事实双重审查 | ⭐ |
| 知识库管理员 | 管理术语库/样例库/写作规则 | ⭐（Demo 只读演示） |

### 2.2 Demo 核心场景（3 个，端到端打通）
1. **场景 A — 医学段落生成（带引用）**：用户在 Web 聊天界面输入 "请帮我写一段关于司美格鲁肽用于 NASH 的最新进展，引用 PubMed 近 2 年文献"。系统返回带角标引用的段落，可一键插入 Word。
2. **场景 B — 医学文档翻译**：用户上传一份英文临床研究摘要 PDF，选择术语库 "WHODrug-CN"，目标语言中文，系统调用术语对齐 + LLM 后返回译文 Word 文件。
3. **场景 C — 写作合规审查（Rule + Fact）**：用户粘贴一段已写好的中文药品介绍，系统并行调用规则审查（FDA/NMPA 警语规范）与事实审查（对照引用文献），返回高亮的修改建议清单。

---

## 3. 多智能体架构（Copilot Studio）

### 3.1 智能体拓扑

```
┌──────────────────────────────────────────────────┐
│           NMI Orchestrator Agent (主)             │
│  - 用户意图识别 / 任务路由 / 上下文聚合 / 结果汇总  │
└──────┬──────────────┬───────────────┬────────────┘
       │              │               │
       ▼              ▼               ▼
 ┌───────────┐  ┌──────────────┐  ┌──────────────┐
 │ Translator │  │   Writer    │  │  Compliance  │
 │   Agent    │  │   Agent     │  │   Agent      │
 │  (翻译)    │  │ (写作/检索)  │  │ (规则/事实)   │
 └─────┬─────┘  └──────┬──────┘  └──────┬───────┘
       │                │                │
       ▼                ▼                ▼
  Tools/Skills        Tools           Tools
  - Translator API    - PubMed        - Rule KB
  - Glossary Lookup   - AI Search KB  - Citation Verify
  - Doc Intel (OCR)   - Bing/Scholar  - LLM Judge
                      - LLM (Foundry)
```

### 3.2 各智能体职责

#### 3.2.1 Orchestrator Agent（主）
- **角色定位**：用户唯一入口（Web 聊天 + Word 内嵌）。
- **能力**：意图分类、参数抽取、调用子智能体（agent-to-agent）、流式汇总输出、引用归并。
- **实现**：Copilot Studio 主 agent + Generative Orchestration（启用大模型推理路由）。
- **关键指令（System prompt 摘要）**：
  - 严格使用医学专业用语；对临床声明保持谨慎；不杜撰文献。
  - 当用户请求涉及翻译 → 委派 Translator Agent。
  - 当用户请求涉及写作/检索 → 委派 Writer Agent。
  - 当用户提供已有文本要求审查 → 委派 Compliance Agent。

#### 3.2.2 Translator Agent
- **核心能力**：文本与文档（PDF / Word / TXT）医学翻译；术语库与样例库注入。
- **输入**：源文本或文件 URL、源语言、目标语言、术语库 ID、样例库 ID。
- **关键动作（Actions / Tools）**：
  | Tool | 类型 | 说明 |
  |---|---|---|
  | `translate.text` | Azure AI Translator | 机翻基线 |
  | `translate.llm-refine` | Azure AI Foundry (GPT-4o / Claude on Foundry) | LLM 精修 + 术语锁定 |
  | `glossary.lookup` | Azure AI Search (vector + keyword) | 术语库召回 |
  | `reference.match` | Azure AI Search | 样例库相似度检索 |
  | `doc.parse` | Azure AI Document Intelligence | PDF/Word 结构化解析 |
  | `doc.render` | Custom Function (docx 模板回填) | 保留原格式输出 |
- **输出**：译文文本，或译文 Word 文件 URL。

#### 3.2.3 Writer Agent
- **核心能力**：段落生成、文章生成、改写、翻译片段、总结、续写；强制 citation。
- **关键动作**：
  | Tool | 说明 |
  |---|---|
  | `pubmed.search` | 自定义 HTTP connector，调用 NCBI E-utilities |
  | `scholar.search` | Bing Web Grounding / SerpAPI（Demo 用 Bing） |
  | `kb.search` | Azure AI Search（企业内部知识库索引） |
  | `instruction.load` | 加载用户写作指令模板（来自 Dataverse） |
  | `llm.compose` | Azure AI Foundry 调用模型生成 |
  | `citation.format` | 角标/参考列表格式化 |
- **可配置项（Demo 预置 1-2 个）**：
  - 写作指令模板：`临床研究叙述性综述`
  - 知识库连接器：`PubMed`、`Bing Search`

#### 3.2.4 Compliance Agent
- **核心能力**：规则审查（rule-checking）+ 事实审查（fact-checking）。
- **关键动作**：
  | Tool | 说明 |
  |---|---|
  | `rule.evaluate` | 调 LLM 按预置规则集（YAML/JSON）逐条判定 |
  | `fact.evidence-lookup` | 在用户提供的引用 / KB 中找证据 |
  | `fact.verify` | LLM-as-judge 给出 High/Moderate/Low 可信度 |
- **输出**：JSON 数组（每条 finding 含 `text_span`、`rule_id`、`reason`、`suggestion`、`confidence`）。

#### 3.2.5 （可选）Admin Agent — Demo 不实现 UI，仅文档说明
管理术语库 / 样例库 / 写作指令 / 写作规则的 CRUD。

---

## 4. Microsoft 技术栈

| 能力 | Microsoft 服务 |
|---|---|
| 前端托管 | Azure Front Door + Azure Static Web Apps |
| 身份 | **Microsoft Entra ID**（Demo 用单租户） |
| API 网关 | Azure API Management（Demo 可省略，直接 Functions） |
| API 处理 | **Azure Functions**（HTTP + Service Bus 触发） |
| 容器化服务 | **Azure Container Apps**（部署自定义 connector） |
| 关系数据库 | Azure Database for PostgreSQL Flexible Server |
| NoSQL | **Azure Cosmos DB**（任务状态） |
| 对象存储 | Azure Blob Storage |
| 消息队列 | **Azure Service Bus**（队列+主题） |
| 密钥管理 | **Azure Key Vault** |
| 全文/向量搜索 | **Azure AI Search**（hybrid + semantic ranker） |
| LLM | **Azure AI Foundry**（GPT-4o / GPT-5 / Claude on Foundry / DeepSeek） |
| 翻译 | **Azure AI Translator** |
| 文档解析 | **Azure AI Document Intelligence** |
| 多智能体编排 | **Microsoft Copilot Studio**（multi-agent） |
| Word 集成 | **Microsoft 365 Copilot Extension**（声明式 agent in Word） |
| 监控 | **Application Insights** + Azure Monitor |
| CI/CD | CodePipeline | GitHub Actions + Azure Developer CLI (azd) |

---

## 5. 功能需求（Demo 范围）

### 5.1 必做（P0）
- [ ] FR-1：Orchestrator Agent 可在 Copilot Studio Web 测试通道中对话。
- [ ] FR-2：场景 A — 段落生成，含 PubMed 检索 + 引用 + 一键复制结果。
- [ ] FR-3：场景 B — PDF 翻译（英→中），术语库锁定，输出可下载 docx。
- [ ] FR-4：场景 C — 粘贴段落 → 规则+事实并行审查 → 返回 JSON+人类可读列表。
- [ ] FR-5：Word 中通过 **Microsoft 365 Copilot 声明式扩展**（Declarative Agent）唤起 Orchestrator Agent，至少完成"在 Word 内生成段落并插入"动作。
- [ ] FR-6：Entra ID 单点登录（仅 Demo 租户内用户可用）。
- [ ] FR-7：1 个预置术语库（200 条 demo 数据，CSV 导入 AI Search）。
- [ ] FR-8：1 个预置写作指令模板（"临床研究叙述性综述"）。

### 5.2 应做（P1）
- [ ] FR-9：流式输出（streaming）显示 LLM 生成过程。
- [ ] FR-10：引用悬浮预览（点击角标显示文献摘要）。
- [ ] FR-11：审查结果支持 Accept / Copy / Ignore（仅前端状态）。
- [ ] FR-12：Application Insights 端到端 trace。

### 5.3 可选（P2，演示视效）
- [ ] FR-13：Teams 中也可调用该 Agent。
- [ ] FR-14：样例库（Reference Store）参与翻译，演示风格一致性。
- [ ] FR-15：管理员页面（极简）查看任务列表。

### 5.4 明确不做（Out of Scope）
- 自定义 LLM 部署（DeepSeek / Llama 自托管）
- 大词汇表（>2 千条）UI 编辑器
- 公开 REST API 与 API Key 管理
- 完整审计日志与多角色 RBAC
- 跨区域容灾

---

## 6. 关键 UX 流程

### 6.1 场景 A：段落生成
```
用户(Web/Word): "写一段关于司美格鲁肽用于 NASH 的最新进展，引用 PubMed 近 2 年文献"
   │
   ▼
Orchestrator: 识别意图=写作 → 委派 Writer Agent
   │
   ▼
Writer Agent:
   1. instruction.load("临床研究叙述性综述")
   2. pubmed.search(query="semaglutide NASH", date_filter="last 2y", max=10)
   3. llm.compose(prompt=指令+检索结果+用户问题, model=gpt-4o)
   4. citation.format → 在段落中插入 [1][2]，并附参考文献列表
   │
   ▼
Orchestrator → 返回用户：段落 + 引用列表 + "插入 Word" 按钮
```

### 6.2 场景 B：文档翻译
```
用户: 上传 abstract.pdf，选择"英→中"，术语库="WHODrug-CN-Demo"
   │
   ▼
Orchestrator → Translator Agent
   │
   ▼
Translator Agent:
   1. doc.parse(abstract.pdf) → 结构化段落
   2. glossary.lookup(每段，命中术语锁定)
   3. translate.llm-refine(分段调用 GPT-4o，传入锁定术语)
   4. doc.render(回填到 docx 模板)
   │
   ▼
Orchestrator → 返回下载链接 abstract_zh.docx
```

### 6.3 场景 C：合规审查
```
用户粘贴: "<某药品介绍段落>"
   │
   ▼
Orchestrator → Compliance Agent（并行触发）
   │
   ├─▶ rule.evaluate(text, ruleset="FDA警语规范-Demo")
   └─▶ fact.verify(text, references=用户上传或自动检索)
   │
   ▼
Orchestrator → 返回结构化 findings：
   - Rule findings: 3 条（红色高亮）
   - Fact findings: 1 条高风险，2 条已核实
```

---

## 7. 数据 & 知识源（Demo 预置）

| 资源 | 数量 | 存储 | 备注 |
|---|---|---|---|
| 术语库 "WHODrug-CN-Demo" | 200 条 | Azure AI Search index | CSV 导入 |
| 样例库 "Clinical-Abstract-Demo" | 50 对 | Azure AI Search index | 中英对照 |
| 写作指令 "临床研究叙述性综述" | 1 条 | Cosmos DB | 含 User-facing + Detail guideline + Output sample |
| 写作规则 "FDA警语规范-Demo" | 5 条 | Cosmos DB | 含 compliant / non-compliant 例子 |
| PubMed 连接器 | - | Azure Function | 调 NCBI E-utilities |
| Bing 搜索连接器 | - | Bing Grounding | Foundry 内置 |

---

## 8. 非功能性需求（Demo 级）

| 维度 | 要求 |
|---|---|
| 响应延迟 | 段落生成 P95 ≤ 20s；翻译 1 页 PDF ≤ 30s |
| 并发 | 同时 5 个用户、10 个任务 |
| 可用性 | Demo 期间工作时段可用即可 |
| 安全 | Entra ID 登录；Key Vault 保管所有密钥；HTTPS-only；Private Endpoint（AI Search / Foundry） |
| 合规 | 不存储患者 PHI 数据；Demo 数据全部为**合成假数据**（详见 `demo-data/`） |
| 成本上限 | Demo 月度 Azure 消耗 ≤ $300（视模型用量） |
| 可观测 | App Insights 全链路 trace + Foundry 内置 evaluation |

---

## 9. 里程碑与交付物

| 阶段 | 时长 | 关键交付 |
|---|---|---|
| M0 — 设计评审 | 第 1 周 | 本 PRD 通过；多智能体拓扑确认 |
| M1 — 基础设施 | 第 2 周 | Entra/Foundry/AI Search/Storage 资源就绪（azd 一键起） |
| M2 — 单 Agent | 第 3 周 | Translator Agent 端到端打通（场景 B） |
| M3 — 多 Agent | 第 4 周 | Writer + Orchestrator 联调（场景 A） |
| M4 — 审查 + Word | 第 5 周 | Compliance Agent + Word 内嵌（场景 C + FR-5） |
| M5 — 演示打磨 | 第 6 周 | 端到端 dry-run、脚本化 Demo、监控大盘 |

---

## 10. 风险与待决问题

| # | 风险 / 问题 | 缓解 / 决策点 |
|---|---|---|
| R1 | Copilot Studio 多智能体的 agent-to-agent handoff 是否支持流式与中间状态？ | 早期 PoC 验证；如不支持，由 Orchestrator 自行调用工具而非子 agent。 |
| R2 | PubMed E-utilities QPS 限制 | 注册 NCBI API Key；Demo 期间做客户端缓存。 |
| R3 | Word 端集成路径 | **已决策**：采用 M365 Copilot 声明式扩展（Declarative Agent），不开发自研 add-in。 |
| R4 | 引用准确性（防幻觉） | 强制 citation-required prompt + Compliance Agent 兜底 fact-check。 |
| R5 | 术语库在 Translator 提示词中的注入策略（全量 vs 召回 top-K） | 命中召回 top-20 注入；命中数过多时分段调用。 |
| R6 | 声明式扩展能力边界（文件上传、流式输出） | 早期 PoC 验证；超出能力时降级到 Web 通道演示。 |
| Q1 | 输出 docx 是否必须保留原 PDF 的复杂表格？ | Demo 接受"段落级保留 + 简单表格"；复杂表格降级为纯文本。 |
| Q2 | 谁来管理预置术语库与写作规则的数据？ | Demo 由开发团队预置；产品化阶段需 Admin 端。 |
| Q3 | 客户演示是否需要白标 / 客户 logo？ | 待客户经理确认，默认使用通用 NMI 品牌。 |

---

## 11. 附录

### A. 功能清单与 Demo 状态
| NMI 功能 | Demo 中状态 | 备注 |
|---|---|---|
| 医学翻译（文本） | ✅ P0 | Translator Agent |
| 医学翻译（PDF/Word） | ✅ P0 | 场景 B |
| Medical Writer - Generate Paragraph | ✅ P0 | 场景 A |
| Medical Writer - Generate Article | ⏸ P2 | 通过多次段落组合可模拟 |
| Paraphrase / Translate / Summarize / Continue | ⏸ P1 | Writer Agent 内置 skill，UI 视情况 |
| Rule-checking | ✅ P0 | 场景 C |
| Fact-checking | ✅ P0 | 场景 C |
| Glossary（术语库） | ✅ P0 | 预置 1 个 |
| Reference Store（样例库） | ⏸ P1 | 预置 1 个 |
| Writing Instruction | ✅ P0 | 预置 1 个 |
| Writing Rule | ✅ P0 | 预置 1 个 |
| Connectors | ✅ P0 | PubMed + Bing |
| Office Word 插件 | ✅ P0（用 **M365 Copilot 声明式扩展** 替代自研 add-in） | FR-5 |
| 登录认证 | ✅ P0（Entra ID） | FR-6 |
| REST API 对外 | ❌ 不做 | Out of scope |

### B. 演示脚本（建议 8 分钟，面向客户/管理层）

**演示前提**：演示用 Microsoft 365 + Azure 租户、Demo 假数据已预置、3 个场景已彩排。

| 时间 | 内容 | 重点台词 |
|---|---|---|
| 0:00–0:30 | 开场：行业痛点 + 解决方案定位 | "医学撰稿、翻译、合规审查 3 个高耗时环节，今天用一个 AI 助手在 Word 里全部解决。" |
| 0:30–3:00 | **场景 A — Word 中生成段落** | 打开 Word → 调出 Copilot 侧边栏 → 输入主题 → 看到引用 → 一键插入 |
| 3:00–5:30 | **场景 B — PDF 文档翻译** | 切到 Copilot 聊天 → 拖入 PDF → 选术语库 → 下载中文 docx |
| 5:30–7:30 | **场景 C — 合规审查** | 粘贴段落 → 并行审查 → 高亮风险 → 一键采纳建议 |
| 7:30–8:00 | 收尾：**架构一页纸 + ROI 与路线图** | "6 周即可交付 Demo；3 个月完成生产化首期" |

### C. Demo 假数据清单（详见仓库 `demo-data/` 目录）
| 文件 | 用途 |
|---|---|
| `demo-data/glossary-WHODrug-CN-Demo.csv` | 50 条中英医学术语对照 |
| `demo-data/reference-store-Clinical-Abstract-Demo.csv` | 15 条中英临床摘要句对 |
| `demo-data/writing-instructions/clinical-narrative-review.md` | 1 个写作指令模板 |
| `demo-data/writing-rules/fda-warning-rules.json` | 5 条规则（含合规/不合规示例） |
| `demo-data/samples/abstract-semaglutide-nash.md` | 场景 B 用英文摘要原稿 |
| `demo-data/samples/compliance-test-paragraph.md` | 场景 C 用含问题的中文段落 |

---

> **下一步**：请评审本 PRD 的 Demo 范围与多智能体拓扑；确认 M0 评审通过后，将启动 M1 基础设施搭建（推荐用 `azd` + Bicep 一键 provisioning）。
