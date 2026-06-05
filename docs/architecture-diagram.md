# NMI on Microsoft — 端到端架构图

> **目标受众**：客户决策层 / 管理层 / 解决方案架构师
> **配套文件**：[../PRD-NMI-Copilot-Studio-Demo.md](../PRD-NMI-Copilot-Studio-Demo.md)

---

## 1. 一页纸全局架构图（推荐用于演示收尾）

```mermaid
flowchart TB
    subgraph UserChannels["🧑‍⚕️ 用户入口（零额外开发）"]
        Word["📝 Microsoft Word<br/>+ M365 Copilot 声明式扩展"]
        Teams["💬 Microsoft Teams<br/>+ Copilot Chat"]
        Web["🌐 Copilot Studio Web 通道<br/>(浏览器)"]
    end

    subgraph Identity["🔐 身份与合规"]
        Entra["Microsoft Entra ID<br/>SSO / 条件访问"]
        Purview["Microsoft Purview<br/>数据分类与审计"]
    end

    subgraph CopilotStudio["🎯 Microsoft Copilot Studio — 多智能体编排层"]
        Orchestrator["🧠 Orchestrator Agent<br/>意图识别 / 任务路由 / 结果汇总"]
        Translator["🌐 Translator Agent<br/>医学翻译"]
        Writer["✍️ Writer Agent<br/>写作 + 检索 + 引用"]
        Compliance["✅ Compliance Agent<br/>规则审查 + 事实审查"]
    end

    subgraph AzureAI["🤖 Azure AI 平台"]
        Foundry["Azure AI Foundry<br/>GPT-4o / GPT-5 / Claude on Foundry"]
        Translator_API["Azure AI Translator<br/>机翻基线"]
        DocIntel["Azure AI<br/>Document Intelligence<br/>PDF/Word 解析"]
        AISearch["Azure AI Search<br/>术语库 + 样例库 + KB<br/>(向量 + 混合检索)"]
    end

    subgraph DataLayer["💾 数据与运行时"]
        Functions["Azure Functions<br/>(Flex Consumption)<br/>自定义连接器"]
        Cosmos["Azure Cosmos DB<br/>写作指令 / 规则 / 任务状态"]
        Blob["Azure Blob Storage<br/>原文 / 译文 docx"]
        KeyVault["Azure Key Vault<br/>API 密钥 / 连接串"]
    end

    subgraph External["🌍 外部知识源"]
        PubMed["PubMed<br/>(NCBI E-utilities)"]
        Bing["Bing / Google Scholar"]
    end

    subgraph Observability["📊 可观测性"]
        AppInsights["Application Insights<br/>+ Azure Monitor"]
    end

    Word --> Entra
    Teams --> Entra
    Web --> Entra
    Entra --> Orchestrator

    Orchestrator -->|委派| Translator
    Orchestrator -->|委派| Writer
    Orchestrator -->|委派| Compliance

    Translator --> Translator_API
    Translator --> DocIntel
    Translator --> AISearch
    Translator --> Foundry

    Writer --> Foundry
    Writer --> AISearch
    Writer --> Functions
    Functions --> PubMed
    Functions --> Bing

    Compliance --> Foundry
    Compliance --> Cosmos
    Compliance --> AISearch

    Translator -.读写.-> Blob
    Writer -.读写.-> Cosmos
    Compliance -.读.-> Cosmos

    Foundry -.密钥.-> KeyVault
    Functions -.密钥.-> KeyVault

    CopilotStudio -.遥测.-> AppInsights
    AzureAI -.遥测.-> AppInsights
    DataLayer -.遥测.-> AppInsights
    AppInsights --> Purview

    classDef user fill:#0078D4,color:#fff,stroke:#005A9E
    classDef copilot fill:#7E57C2,color:#fff,stroke:#5E35B1
    classDef ai fill:#00BCD4,color:#fff,stroke:#0097A7
    classDef data fill:#FFA000,color:#fff,stroke:#FF6F00
    classDef sec fill:#43A047,color:#fff,stroke:#2E7D32
    classDef ext fill:#90A4AE,color:#fff,stroke:#546E7A

    class Word,Teams,Web user
    class Orchestrator,Translator,Writer,Compliance copilot
    class Foundry,Translator_API,DocIntel,AISearch ai
    class Functions,Cosmos,Blob,KeyVault data
    class Entra,Purview,AppInsights sec
    class PubMed,Bing ext
```

---

## 2. 用户旅程图：场景 A（Word 内生成段落）

```mermaid
sequenceDiagram
    autonumber
    actor U as 医学撰稿人
    participant W as Word + Copilot
    participant O as Orchestrator Agent
    participant Wr as Writer Agent
    participant F as Azure Function<br/>(PubMed Connector)
    participant AIF as Azure AI Foundry<br/>(GPT-4o)
    participant S as Azure AI Search

    U->>W: "写一段司美格鲁肽用于 NASH 的<br/>最新进展，引用近 2 年 PubMed 文献"
    W->>O: 转发用户意图 + Word 文档上下文
    O->>O: 识别意图 = 写作
    O->>Wr: handoff(主题, 时间范围, 模板="叙述性综述")

    par 并行检索
        Wr->>F: pubmed.search("semaglutide NASH", last_2y, top=10)
        F-->>Wr: 10 篇文献（标题 + 摘要 + DOI）
    and
        Wr->>S: kb.search(企业内部综述指南)
        S-->>Wr: top-3 相关知识
    end

    Wr->>AIF: compose(指令模板 + 文献 + 用户问题)
    AIF-->>Wr: 带角标的段落 + 参考列表
    Wr->>O: 返回结构化结果
    O->>W: 段落 + "插入 Word" 按钮
    U->>W: 点击插入 → 段落落入光标位置
```

---

## 3. 用户旅程图：场景 B（PDF 翻译 + 术语锁定）

```mermaid
sequenceDiagram
    autonumber
    actor U as 翻译专员
    participant C as Copilot 聊天
    participant O as Orchestrator
    participant T as Translator Agent
    participant DI as Document Intelligence
    participant S as AI Search<br/>(Glossary)
    participant AIF as AI Foundry
    participant B as Blob Storage

    U->>C: 上传 abstract.pdf<br/>选择"英→中"，术语库=WHODrug-CN
    C->>O: 翻译请求 + 文件引用
    O->>T: handoff(file, lang_pair, glossary_id)

    T->>DI: parse(abstract.pdf)
    DI-->>T: 结构化段落 + 版式信息

    loop 每个段落
        T->>S: glossary.lookup(段落文本, top_k=20)
        S-->>T: 命中术语对照
        T->>AIF: translate_with_glossary(段落, 术语锁定列表)
        AIF-->>T: 段落译文
    end

    T->>T: doc.render(译文 → docx 模板)
    T->>B: 上传 abstract_zh.docx
    B-->>T: 下载链接
    T->>O: 返回链接
    O->>C: "翻译完成 [下载 docx]"
    U->>B: 下载译文
```

---

## 4. 用户旅程图：场景 C（合规审查 — 规则 + 事实并行）

```mermaid
sequenceDiagram
    autonumber
    actor U as 合规审稿人
    participant C as Copilot 聊天
    participant O as Orchestrator
    participant Co as Compliance Agent
    participant CDB as Cosmos DB
    participant AIF as AI Foundry
    participant F as Function<br/>(PubMed)

    U->>C: 粘贴待审段落
    C->>O: 审查请求
    O->>Co: handoff(text, ruleset_id="fda-warning-demo")

    par 规则审查
        Co->>CDB: 加载 FDA-001 至 FDA-005
        CDB-->>Co: 5 条规则 + 示例
        Co->>AIF: rule.evaluate(text, rules)
        AIF-->>Co: findings[规则]
    and 事实审查
        Co->>F: 提取声明 → pubmed.search 找证据
        F-->>Co: 证据片段
        Co->>AIF: fact.verify(text, evidence)
        AIF-->>Co: findings[事实]
    end

    Co->>Co: 合并 + 按严重度排序
    Co->>O: 返回 JSON findings
    O->>C: 渲染高亮列表<br/>(Accept / Copy / Ignore)
    U->>C: 点击 Accept → 应用建议
```

---

## 5. 简化版（用于 PPT 单页）

```mermaid
flowchart LR
    User["👤 用户<br/>Word / Teams / Web"] --> Orch["🧠 NMI Orchestrator<br/>(Copilot Studio)"]
    Orch --> T["🌐 Translator"]
    Orch --> W["✍️ Writer"]
    Orch --> C["✅ Compliance"]
    T & W & C --> AI["🤖 Azure AI Foundry<br/>+ AI Search<br/>+ Translator<br/>+ Doc Intelligence"]
    AI --> Data["💾 Cosmos DB · Blob · Key Vault"]
    W -.-> Ext["🌍 PubMed · Bing"]

    classDef u fill:#0078D4,color:#fff
    classDef o fill:#7E57C2,color:#fff
    classDef a fill:#00BCD4,color:#fff
    classDef d fill:#FFA000,color:#fff
    classDef e fill:#90A4AE,color:#fff
    class User u
    class Orch,T,W,C o
    class AI a
    class Data d
    class Ext e
```

---

## 6. 如何使用本文件

- **VS Code 预览**：安装 "Markdown Preview Mermaid Support" 扩展，按 `Ctrl+Shift+V` 即可看图。
- **导出为 PNG/SVG**：使用 [https://mermaid.live](https://mermaid.live) 在线渲染 → 导出。
- **嵌入 PPT**：直接截图，或用 mermaid-cli (`mmdc`) 命令行导出 SVG。
- **嵌入 Word/Loop**：粘贴 PNG 图片即可。
