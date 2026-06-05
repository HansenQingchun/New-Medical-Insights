# 部署占位：PubMed Connector Function

这是 `azd` 编排所需的占位项目。当前 Demo 阶段使用 Bicep 仅 provision 基础设施；
PubMed 连接器的实际 Python 代码（HTTP-triggered Azure Function）由后续迭代提供。

## 计划接口

`POST /api/search`

请求：
```json
{
  "query": "semaglutide NASH",
  "date_filter": "last_2y",
  "publication_type": ["Randomized Controlled Trial", "Meta-Analysis"],
  "max_results": 10
}
```

返回：
```json
{
  "results": [
    {
      "pmid": "39256xxxx",
      "title": "...",
      "authors": "...",
      "journal": "...",
      "year": 2025,
      "abstract": "...",
      "doi": "10.xxxx/xxxx"
    }
  ],
  "total": 10
}
```

## 部署占位说明

`azure.yaml` 中已声明此服务。若现在执行 `azd up`，Functions 会以空骨架部署，
不会影响基础设施 provisioning 流程。
