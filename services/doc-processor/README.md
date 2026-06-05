# 部署占位：Document Processor Function

这是 `azd` 编排所需的占位项目。负责调用 Azure AI Document Intelligence 解析
PDF / Word，并在翻译完成后用模板回填 docx。

## 计划接口

- `POST /api/parse` — 解析 PDF/Word 为段落数组
- `POST /api/render` — 将译文段落回填到 docx 模板，返回 Blob URL

## 部署占位说明

`azure.yaml` 中已声明此服务。若现在执行 `azd up`，Functions 会以空骨架部署，
不会影响基础设施 provisioning 流程。
