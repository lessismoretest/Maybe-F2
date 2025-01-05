# Maybe F2

<div align="center">
  <img src="Maybe F2/Assets.xcassets/AppIcon.appiconset/mac1024.png" alt="Maybe F2 图标" width="128" height="128">
</div>

Maybe F2 是一个基于 AI 的智能文件批量重命名工具，专为 macOS 设计。它能够根据文件内容（如图片）自动生成描述性的文件名，让文件管理更加智能和高效。

## 应用截图

<div align="center">
  <img src="./Maybe F2/Screenshots/screenshot-main.png" alt="主界面" width="800">
  <p><em>主界面 - 文件处理和预览</em></p>
  
  <img src="./Maybe F2/Screenshots/screenshot-settings.png" alt="设置界面" width="800">
  <p><em>设置界面 - API 配置和自定义选项</em></p>
</div>

## 功能特点

### 核心功能
- 🤖 AI 智能重命名：使用 Gemini AI 分析文件内容，生成描述性文件名
- 📁 批量处理：支持同时处理多个文件
- 🖼️ 文件预览：重命名前可预览新文件名
- ✅ 二步确认：生成名称和应用更改分两步操作，避免误操作
- 🔄 状态追踪：完整的文件处理状态管理（等待中、处理中、已完成、错误）

### 文件支持
- 📷 图片文件（jpg, jpeg, png, gif, webp, heic）
- 📄 PDF 文件
- 📝 文档（doc, docx, txt, rtf, pages, md）
- 🎥 视频文件（mp4, mov, avi, mkv）
- 🎵 音频文件（mp3, wav, aac, m4a）

### 用户界面
- 🎨 现代化 SwiftUI 界面设计
- 🌓 支持浅色/深色模式
- 👆 拖放操作支持
- 📊 文件类型分类与筛选
- 📝 可编辑的文件名预览
- ⚙️ 可自定义的设置面板

## 系统要求
- macOS 13.0 或更高版本
- 网络连接（用于 AI 服务）
- Gemini API 密钥

## 安装说明

1. 从 [Releases](https://github.com/yourusername/maybe-f2/releases) 下载最新版本
2. 将应用拖入 Applications 文件夹
3. 首次运行时需要在设置中配置 API 密钥

## 使用指南

### 基本使用流程
1. 打开应用后，将文件拖入窗口或点击选择文件
2. 选择需要重命名的文件
3. 点击"AI 重命名"生成新文件名
4. 确认无误后，点击"应用更改"完成重命名

### API 密钥配置
1. 点击左下角的设置按钮
2. 选择"AI 设置"标签
3. 输入你的 Gemini API 密钥
4. 点击保存

### 自定义提示词
可以在设置中为不同类型的文件配置自定义的 AI 提示词，以获得更符合需求的命名结果。

## 技术实现

### 项目结构
```
Maybe F2/
├── Models/           # 数据模型
│   ├── FileItem.swift    # 文件项模型
│   ├── ProcessStatus.swift
│   └── Settings.swift    # 设置模型
├── Views/            # UI 组件
│   ├── MainView.swift
│   ├── ControlPanelView.swift
│   ├── FileListView.swift
│   ├── DropZoneView.swift
│   └── SettingsView.swift
├── ViewModels/       # 视图模型
│   └── FileManagerViewModel.swift
├── Services/         # 服务层
│   └── AIService.swift    # AI 服务实现
└── Managers/         # 管理器
    └── SettingsManager.swift
```

### 核心技术特性
- **SwiftUI**: 使用最新的 SwiftUI 框架构建现代化用户界面
- **Gemini AI API**: 集成 Google Gemini API 进行智能图像分析和文本生成
- **异步处理**: 使用 Swift 的 async/await 进行异步操作
- **状态管理**: 完整的文件处理状态跟踪系统
- **图像处理**: 智能图像压缩和格式转换
- **错误处理**: 完善的错误处理和用户反馈机制

### 安全特性
- API 密钥安全存储
- 文件访问沙盒化
- 图像数据压缩和优化

## 隐私说明
- 应用需要访问选定文件夹的权限以进行重命名操作
- 图片分析在 Gemini API 服务器端进行
- 不会收集或存储用户的个人信息
- 所有文件处理都在本地完成，仅发送必要的数据到 AI 服务

## 开发者说明

### 开发环境
- Xcode 15+
- Swift 5.9+
- macOS 13.0+

### 构建步骤
1. 克隆仓库
2. 在 Xcode 中打开项目
3. 配置开发者证书
4. 构建并运行

### 贡献指南
欢迎提交 Pull Requests 和 Issues。在提交之前，请确保：
- 代码符合项目的编码规范
- 添加适当的测试
- 更新相关文档