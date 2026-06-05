# Copilot Studio Agent 创建逐步指南

> **目标**：在 Microsoft Copilot Studio 中创建 NMI Demo 的 4 个智能体并完成编排
> **预计时间**：首次 60–90 分钟（4 个 agent × 15 分钟 + 编排 + 测试）
> **前置条件**：见下方"环境准备"
> **配套文件**：[../agents/orchestrator-system-prompt.md](../agents/orchestrator-system-prompt.md)、[../agents/translator-system-prompt.md](../agents/translator-system-prompt.md)、[../agents/writer-system-prompt.md](../agents/writer-system-prompt.md)、[../agents/compliance-system-prompt.md](../agents/compliance-system-prompt.md)

---

## 0. 环境准备（5 分钟）

### 0.1 许可与环境

| 项 | 要求 | 说明 |
|---|---|---|
| Microsoft 365 账号 | 工作/学校账号 | hansen_gzb@hotmail.com 是个人账号，**Copilot Studio 通常需要工作账号** |
| Copilot Studio 许可 | Copilot Studio User License 或 M365 Copilot 试用 | https://aka.ms/copilotstudio |
| Power Platform 环境 | 建议新建 `NMI-Demo` 环境，区域选 **United States** | https://admin.powerplatform.microsoft.com → 环境 → 新建 |
| Generative Orchestration | 在环境中启用（默认 Preview 开启） | Copilot Studio → Settings → Generative AI |

> ⚠️ 如果你只有个人账号，可先到 [Microsoft 365 开发者计划](https://developer.microsoft.com/microsoft-365/dev-program) 申请免费 90 天 E5 沙盒。

### 0.2 取 Azure 端点（任务 #1 azd up 跑完后做）

```powershell
cd "c:\Users\qhuang\Desktop\VScode\New NMI"
azd env get-values > .azure-endpoints.txt
```

需要记下这 5 个值，**后面建 agent 时反复用**：

| 变量名 | 用途 |
|---|---|
| `AZURE_AISEARCH_ENDPOINT` | Translator / Writer 检索术语库 + 知识库 |
| `AZURE_OPENAI_ENDPOINT` | 各 Agent 用 GPT-4o（已通过 Copilot Studio 默认通道，可不直接配） |
| `AZURE_COSMOS_ENDPOINT` | 读 writing_instructions / writing_rules |
| `AZURE_FUNCTION_PUBMED_URL` | PubMed 检索（Writer + Compliance 用） |
| `AZURE_FUNCTION_DOCPROC_URL` | PDF 解析（Translator 用） |
| `AZURE_STORAGE_ENDPOINT` | 上传 PDF / 下载 docx |

---

## 1. 进入 Copilot Studio

1. 浏览器打开 [https://copilotstudio.microsoft.com](https://copilotstudio.microsoft.com)
2. 右上角确认在 **NMI-Demo** 环境（不在就切过去）
3. 左侧导航：**Agents** → **+ New agent** → **Skip to configure**（不要走 Conversational 向导）

---

## 2. 创建 4 个 Agent

### 2.1 顺序与命名

**建议顺序**：先建 3 个子 Agent，再建 Orchestrator（这样 Orchestrator 配置时可以选已经存在的子 Agent 作为 connected agents）。

| # | 名称（**必须严格一致**，Orchestrator 委派会按名称识别） | Description（给 Orchestrator 看的） |
|---|---|---|
| 1 | `NMI Translator` | 医学文档翻译，支持术语库锁定、PDF 解析、docx 输出 |
| 2 | `NMI Writer` | 医学内容生成，按写作模板撰稿，引用真实 PubMed 文献 |
| 3 | `NMI Compliance` | 合规审查，规则审查 + 事实核对，输出结构化 findings |
| 4 | `NMI Orchestrator` | 主入口，意图识别 + 任务路由 + 结果汇总 |

### 2.2 每个 Agent 的通用 5 步

**第 1 步 — Basics**
- Name：照上表
- Description：照上表
- Icon：可选

**第 2 步 — Instructions**
- 打开对应的 `agents/<role>-system-prompt.md` 文件
- 复制 ```` ``` ```` 代码块里的全部内容（不要包括 markdown 标题）
- 粘贴到 Copilot Studio 的 **Instructions** 字段

**第 3 步 — Knowledge**（仅 Translator / Writer 需要）
- **+ Add knowledge** → **Azure AI Search**
- Service URL：`<AZURE_AISEARCH_ENDPOINT>`
- Authentication：**Managed Identity**（如未支持，临时用 admin key，**Demo 后必须删**）
- 索引：
  - Translator：`glossary-cn` + `reference-store`
  - Writer：`reference-store` + `knowledge-pubmed`

**第 4 步 — Actions / Tools**（关键，下表分 Agent 列出）

详见各 Agent 的 [§3 Actions 详表](#3-每个-agent-的-actions-配置)。

**第 5 步 — Publish**
- 右上角 **Publish** → 选 **Demo Web Channel** + **Microsoft 365 Copilot** 两个 channel
- 等"已发布"绿色横幅出现

---

## 3. 每个 Agent 的 Actions 配置

### 3.1 NMI Translator

| Action 名 | 类型 | 端点/参数 | 输入参数 | 输出 |
|---|---|---|---|---|
| `parse_pdf` | HTTP（Power Automate Flow 包） | POST `<AZURE_FUNCTION_DOCPROC_URL>/api/parse` | `blobUrl: string` | `paragraphs: string[]`, `structure: object` |
| `lookup_glossary` | Azure AI Search Action | 索引 `glossary-cn` | `query: string` | `terms: {source, target}[]` |
| `translate_with_lock` | Prompt（内置 GPT-4o） | 见下方 Prompt 模板 | `text: string`, `lockedTerms: object[]` | `translated: string` |
| `compose_docx` | HTTP | POST `<AZURE_FUNCTION_DOCPROC_URL>/api/compose` | `paragraphs: string[]`, `originalStructure: object` | `docxUrl: string` |

**`translate_with_lock` Prompt 模板**（贴到 Copilot Studio Prompt action）：

```
你是一个医学翻译引擎。把以下文本翻译为目标语言。
严格遵守锁定术语映射，禁止使用任何变体。

锁定术语（JSON）：
{lockedTerms}

待翻译文本：
{text}

只输出翻译结果，不要解释。
```

### 3.2 NMI Writer

| Action 名 | 类型 | 端点/参数 | 输入 | 输出 |
|---|---|---|---|---|
| `load_writing_instruction` | Cosmos DB（HTTP via Function 或 直连） | GET `<AZURE_COSMOS_ENDPOINT>/dbs/nmi/colls/writing_instructions/docs/{id}` | `instructionId: string` | `template: object` |
| `search_pubmed` | HTTP | POST `<AZURE_FUNCTION_PUBMED_URL>/api/search` | `query: string`, `recentYears: number` | `papers: {pmid, title, abstract, year, authors}[]` |
| `search_internal_kb` | Azure AI Search | 索引 `reference-store` | `query: string` | `chunks: {content, source}[]` |
| `compose_with_citations` | Prompt（内置 GPT-4o） | 见 Writer prompt 文件 | `topic`, `template`, `papers`, `chunks` | `markdown: string`, `references: object[]` |

### 3.3 NMI Compliance

| Action 名 | 类型 | 端点/参数 | 输入 | 输出 |
|---|---|---|---|---|
| `load_rule_set` | Cosmos DB | GET `.../writing_rules/docs/{rulesetId}` | `rulesetId: string` | `rules: object[]` |
| `extract_factual_claims` | Prompt（GPT-4o） | 抽取数字声明 | `text: string` | `claims: {span, claim, type}[]` |
| `verify_claim_pubmed` | HTTP | POST `<AZURE_FUNCTION_PUBMED_URL>/api/verify` | `claim: string` | `evidence: object`, `match: bool` |
| `rule_check` | Prompt（GPT-4o，循环每条规则） | 见 Compliance prompt 文件 | `text`, `rule` | `violation: object \| null` |
| `merge_findings` | Prompt（GPT-4o） | 合并并打分 | `ruleFindings`, `factFindings` | `findings: object[]` |

### 3.4 NMI Orchestrator

**不需要 Knowledge**。**Actions 只有"connected agents"**：

1. Settings → **Generative orchestration** → ON
2. **Tools** → **+ Add tool** → **Agent** → 依次添加：
   - `NMI Translator`
   - `NMI Writer`
   - `NMI Compliance`
3. 每个子 Agent 添加时，Description 字段照抄第 2.1 节表格里的描述（Orchestrator 靠这个判断什么时候委派）。

---

## 4. 配置 Word/M365 Copilot 入口（声明式扩展）

### 4.1 在 Copilot Studio 内发布到 M365

1. 打开 **NMI Orchestrator** → **Channels** → **Microsoft 365 Copilot**
2. 点 **Turn on**
3. 复制生成的 **App ID**（GUID）

### 4.2 让管理员审批（**让客户的 M365 管理员做**）

1. 管理员到 [Microsoft 365 管理中心](https://admin.microsoft.com) → 集成应用 → 待审批
2. 找到 `NMI Orchestrator` → **Approve** → 分配给 Demo 用户（你自己）

### 4.3 在 Word 里验证

1. Word → 右上角 Copilot 图标 → 侧边栏出现
2. 顶部下拉 → 切到 **NMI Orchestrator**
3. 输入 `你好` → 应收到 Orchestrator 的欢迎语

✅ 此时 Demo 入口就绪。

---

## 5. 端到端测试（必做，10 分钟）

在 Copilot Studio 自带的 **Test panel** 里逐项跑：

| # | 输入 | 期望委派给 | 期望结果关键字 |
|---|---|---|---|
| T1 | `你好` | 不委派 | 自我介绍 + 3 个能力 |
| T2 | `写一段关于司美格鲁肽用于 NASH 的最新进展，引用近 2 年 PubMed 文献` | Writer | 4 段式段落 + `[1][2]` 角标 + References 列表 |
| T3 | `把这段翻译成中文：Semaglutide significantly reduced HbA1c by 1.8% ...` | Translator | "司美格鲁肽显著降低 HbA1c 1.8%..." + HbA1c **不**译成糖化血红蛋白 |
| T4 | 粘贴 `demo-data/samples/compliance-test-paragraph.md` 内容 + `审查这段合规性` | Compliance | 至少 5 条 findings，含 1 条 critical（off-label），1 条事实错误（50% vs 26%） |
| T5 | `写一段并帮我检查合规` | Writer → Compliance 串行 | 先出段落，再出 findings |

每条不过就回到对应 Agent 的 Instructions / Actions 重排。

---

## 6. 常见坑

| 症状 | 原因 | 解法 |
|---|---|---|
| Orchestrator 不委派，自己回答 | Generative Orchestration 没开 / 子 Agent description 写得模糊 | Settings 打开开关；子 Agent description 加关键词（"翻译" "写" "审查"） |
| Action 调用 403 | Managed Identity 没分到角色 | 回到 `azd env get-values` 看 `AZURE_PRINCIPAL_ID`，对照 [../infra/modules/rbac.bicep](../infra/modules/rbac.bicep) 检查 |
| Translator 把 HbA1c 译成"糖化血红蛋白" | 没把 `lockedTerms` 真传到 prompt | 用 Test panel 的 "View trace"，看 `translate_with_lock` 的 input |
| Compliance 漏掉事实错误 | `extract_factual_claims` 没识别到数字 | 提示词加 "**所有包含百分比、HR、p 值、剂量、人数的句子都算**" |
| Word 里看不到 NMI Orchestrator | 管理员未审批 / 没分配许可 | 走 §4.2 |

---

## 7. 检查清单（建完后逐项打勾）

- [ ] 4 个 Agent 名称严格匹配 `NMI Orchestrator / Translator / Writer / Compliance`
- [ ] Orchestrator 已加 3 个 connected agents
- [ ] Translator 接入 `glossary-cn`、`reference-store`
- [ ] Writer 接入 `reference-store`、`search_pubmed` Action
- [ ] Compliance 接入 `load_rule_set`、`extract_factual_claims`、`verify_claim_pubmed`
- [ ] 5 条端到端测试全部通过
- [ ] M365 管理员审批 → Word 侧边栏出现 NMI
- [ ] 演示账号的 Word 文档 `司美格鲁肽研究综述（草稿）.docx` 已准备好
- [ ] `compliance-test-paragraph.md` 中文段落已准备好（剪贴板可粘贴）
- [ ] `abstract-semaglutide-nash.pdf` 已生成（从 [../demo-data/samples/abstract-semaglutide-nash.md](../demo-data/samples/abstract-semaglutide-nash.md) 导出）

---

✅ 全部勾选后，进入 [dry-run-companion.md](dry-run-companion.md) 做最后排练。
