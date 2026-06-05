# NMI Demo — Infrastructure as Code (azd + Bicep)

> 一键 provision 全部 Azure 资源，供 Copilot Studio 多智能体 Demo 使用。

---

## 1. 部署什么？

| 类别 | 资源 | 用途 |
|---|---|---|
| 监控 | Log Analytics + Application Insights | 全链路 trace |
| 身份 | User-Assigned Managed Identity | Functions & Copilot Studio actions 的统一身份 |
| 存储 | Storage Account（含 3 个 container） | uploads / outputs / demo-data |
| 密钥 | Key Vault | NCBI API key、第三方密钥 |
| 数据 | Cosmos DB SQL（serverless，含 3 个 container） | writing_instructions / writing_rules / task_state |
| 检索 | Azure AI Search (Basic) | 术语库 + 样例库 + 企业 KB |
| AI | Azure AI Foundry / AI Services | GPT-4o + text-embedding-3-large 部署 |
| 运行时 | Azure Functions (Flex Consumption) | PubMed Connector + Document Processor |
| RBAC | 一组角色分配 | 数据平面零密钥，managed identity 直接访问 |

**安全默认值**：
- 所有数据平面 **禁用本地密钥认证**（`disableLocalAuth = true`），只能用 Entra ID。
- Storage / KV / Cosmos / Search 全部走 RBAC。
- HTTPS-only，TLS 1.2。

---

## 2. 前置条件

| 工具 | 安装 |
|---|---|
| Azure Developer CLI (azd) | `winget install Microsoft.Azd` 或 [下载页](https://aka.ms/azd-install) |
| Azure CLI | `winget install Microsoft.AzureCLI` |
| Bicep CLI | `az bicep install` |
| Azure 订阅 | 需要 `Owner` 或 `Contributor + User Access Administrator` 权限（因为要分配 RBAC） |
| AI Foundry 配额 | 目标区域至少 30k TPM 的 GPT-4o 配额 |

**推荐区域**：`eastus`、`eastus2`、`swedencentral`、`westus3`（GPT-4o 与 Flex Consumption 都已 GA）

---

## 3. 一键部署

```powershell
# 1. 登录
az login
azd auth login

# 2. 初始化环境
azd env new nmi-demo

# 3. 设置参数（一次性，azd 会记住）
azd env set AZURE_LOCATION eastus2
azd env set AZURE_PRINCIPAL_ID (az ad signed-in-user show --query id -o tsv)

# 可选：调整模型与容量
azd env set NMI_CHAT_MODEL gpt-4o
azd env set NMI_CHAT_MODEL_CAPACITY 30

# 4. 部署
azd up
```

`azd up` 会：
1. 创建资源组 `rg-nmi-demo`
2. 部署所有 Bicep 模块（约 8–12 分钟）
3. 部署 2 个 Function App 的代码骨架
4. 输出连接信息到 `.azure/nmi-demo/.env`

---

## 4. 部署后任务（Demo 准备清单）

```powershell
# 1. 将 Demo 数据上传到 Blob
az storage blob upload-batch `
  --account-name (azd env get-value AZURE_STORAGE_ACCOUNT) `
  --destination demo-data `
  --source ../demo-data `
  --auth-mode login

# 2. 创建 AI Search 索引（术语库 + 样例库）
#    见 demo-data/README.md 步骤 1

# 3. 写入 Cosmos DB 数据
#    见 demo-data/README.md 步骤 2

# 4. 把 NCBI API Key 存入 Key Vault
az keyvault secret set `
  --vault-name (azd env get-value AZURE_KEY_VAULT_NAME) `
  --name ncbi-api-key `
  --value '<your-ncbi-api-key>'

# 5. 在 Copilot Studio 中创建 4 个 Agent
#    见 agents/*.md
```

---

## 5. 目录结构

```
infra/
├── main.bicep                  # 主入口（resourceGroup scope）
├── main.parameters.json        # azd 注入的参数
├── bicepconfig.json            # Bicep linter 配置
└── modules/
    ├── monitoring.bicep        # Log Analytics + App Insights
    ├── identity.bicep          # User-Assigned Managed Identity
    ├── storage.bicep           # Storage Account + 3 containers
    ├── keyvault.bicep          # Key Vault (RBAC mode)
    ├── cosmos.bicep            # Cosmos DB SQL + 3 containers
    ├── aisearch.bicep          # AI Search (Basic, AAD-only)
    ├── aifoundry.bicep         # AI Services + GPT-4o + embedding
    ├── functionapp.bicep       # Flex Consumption plan + 2 Function Apps
    └── rbac.bicep              # 全部角色分配
azure.yaml                      # azd 服务定义
services/
├── pubmed-connector/           # Function 占位
└── doc-processor/              # Function 占位
```

---

## 6. 常见问题

### Q1：部署失败 "InsufficientQuota"？
A：目标区域 GPT-4o 配额不足。在 `azd env set NMI_CHAT_MODEL_CAPACITY 10` 把容量降到 10k TPM，或切换区域：`azd env set AZURE_LOCATION swedencentral`。

### Q2：RBAC 分配失败 "AuthorizationFailed"？
A：当前用户没有 `Microsoft.Authorization/roleAssignments/write` 权限。需要订阅 `Owner` 或 `User Access Administrator` 角色。

### Q3：Cosmos `sqlRoleAssignments` 失败？
A：通常是 `principalId` 缺失。执行：
```powershell
azd env set AZURE_PRINCIPAL_ID (az ad signed-in-user show --query id -o tsv)
azd provision
```

### Q4：如何彻底删除全部资源？
```powershell
azd down --force --purge
```
`--purge` 会立刻清空 Key Vault 与 Cosmos 软删除（节省 7 天等待期）。

---

## 7. 成本预估（demo 月度，30 天）

| 资源 | SKU | 估算 |
|---|---|---|
| Log Analytics | Pay-as-you-go (~1GB/mo) | ~$2 |
| App Insights | 包含在 Log Analytics 计费 | $0 |
| Storage | Standard_LRS, ~5GB | ~$0.50 |
| Key Vault | Standard, 少量 op | <$1 |
| Cosmos DB | Serverless, 100k RU/月 | ~$3 |
| AI Search | Basic | **~$75** |
| AI Foundry GPT-4o | Standard, 1M input + 0.5M output tokens | ~$10 |
| Function (Flex) | 空闲 | <$1 |
| **总计** | | **~$90/月** |

> 💡 演示后建议执行 `azd down` 释放资源；或把 AI Search 改为 `free` SKU 进一步降本（限 1 索引、50 MB）。

---

## 8. 下一步

部署完成后，请按顺序：
1. 上传 Demo 数据 → 见 [`demo-data/README.md`](../demo-data/README.md)
2. 创建 Copilot Studio agents → 见 [`agents/`](../agents/)
3. 演示前 dry-run → 见 [`docs/demo-script-8min.md`](../docs/demo-script-8min.md)
