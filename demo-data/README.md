# Demo 假数据说明（README）

本目录包含 NMI Copilot Studio 多智能体 Demo 所需的全部预置数据。**全部数据为合成/虚构**，不含任何真实患者信息或专有商业数据，仅用于演示。

## 目录结构

```
demo-data/
├── README.md                                       # 本文件
├── glossary-WHODrug-CN-Demo.csv                    # 术语库（50 条中英医学术语）
├── reference-store-Clinical-Abstract-Demo.csv      # 样例库（15 条中英临床句对）
├── writing-instructions/
│   └── clinical-narrative-review.md                # 写作指令模板（叙述性综述）
├── writing-rules/
│   └── fda-warning-rules.json                      # 规则集（5 条 FDA/NMPA 警语规范）
└── samples/
    ├── abstract-semaglutide-nash.md                # 场景 B：待翻译英文摘要原稿
    └── compliance-test-paragraph.md                # 场景 C：待审查中文段落
```

## 各文件用途与映射

| 文件 | 加载到 | 用于演示 | 关联 Agent |
|---|---|---|---|
| `glossary-WHODrug-CN-Demo.csv` | Azure AI Search index `glossary-demo` | 场景 B（术语锁定） | Translator Agent |
| `reference-store-Clinical-Abstract-Demo.csv` | Azure AI Search index `reference-demo` | 场景 B（风格一致性） | Translator Agent |
| `writing-instructions/clinical-narrative-review.md` | Cosmos DB `writing_instructions` 集合 | 场景 A（写作模板） | Writer Agent |
| `writing-rules/fda-warning-rules.json` | Cosmos DB `writing_rules` 集合 | 场景 C（规则审查） | Compliance Agent |
| `samples/abstract-semaglutide-nash.md` | 由用户演示时另存为 PDF 上传 | 场景 B | Translator Agent |
| `samples/compliance-test-paragraph.md` | 由演示者复制粘贴到 Copilot 聊天框 | 场景 C | Compliance Agent |

## 加载到 Azure 的步骤（开发期）

1. **AI Search 索引**：使用 Azure portal 的 Import data 向导，将 2 个 CSV 上传为 Blob，分别建立 `glossary-demo` 和 `reference-demo` 索引。字段建议：
   - `glossary-demo`：`source_term` (key, searchable), `target_term` (retrievable), `abbreviation`, `domain`, `description`, 加 `source_term_vector` (text-embedding-3-large)。
   - `reference-demo`：`source_text` (searchable), `target_text` (retrievable), `domain`, 加 `source_text_vector`。

2. **Cosmos DB**：在 `nmi-demo` 数据库下创建 2 个集合 `writing_instructions`、`writing_rules`，分别 `az cosmosdb sql container create` 后用 `az cosmosdb sql ... item create` 导入。

3. **PDF 转换**：把 `samples/abstract-semaglutide-nash.md` 用任意 Markdown→PDF 工具导出为 `abstract-semaglutide-nash.pdf`，演示时用此 PDF。

## 数据合规声明

- 不含任何受保护健康信息（PHI / PII）。
- 不含任何真实试验注册号、真实临床数据或受试者标识。
- 所有引用文献为虚构，仅为演示引文格式而设。
- 仅供 Microsoft / 客户 / 合作伙伴在内部演示场景使用，**不得用于生产或外部发布**。
