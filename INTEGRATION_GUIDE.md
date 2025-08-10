# HotWeb3.io API Integration Guide

完整的Web3热度导航平台后端集成指南，包含Supabase数据库、Twitter API和缓存系统。

## 📋 概览

HotWeb3.io现在支持以下功能：
- ✅ **Supabase数据库** - 实时数据存储和同步
- ✅ **Twitter API集成** - 实时项目热度监测
- ✅ **智能缓存系统** - 性能优化和离线支持
- ✅ **实时更新** - WebSocket数据推送
- ✅ **安全架构** - 速率限制和数据保护

## 🚀 快速开始

### 1. Supabase数据库配置

#### 步骤1：创建Supabase项目
1. 访问 [supabase.com](https://supabase.com)
2. 创建新项目
3. 记录项目URL和API密钥

#### 步骤2：设置数据库
1. 在Supabase控制台中打开SQL编辑器
2. 运行项目根目录中的 `supabase-setup.sql` 文件
3. 确认所有表和函数创建成功

#### ��骤3：配置环境变量
```bash
# 复制环境变量模板
cp .env.example .env

# 编辑环境变量
VITE_SUPABASE_URL=https://your-project.supabase.co
VITE_SUPABASE_ANON_KEY=your-anon-key
```

### 2. Twitter API配置 (可选)

#### 步骤1：获取Twitter API访问权限
1. 访问 [developer.twitter.com](https://developer.twitter.com)
2. 申请开发者账户
3. 创建应用并获取Bearer Token

#### 步骤2：配置Twitter集成
```bash
# 添加到 .env 文件
VITE_TWITTER_BEARER_TOKEN=your-twitter-bearer-token
```

### 3. 启动应用

```bash
# 安装依赖
npm install

# 启动开发服务器
npm run dev
```

## 🗄️ 数据库架构

### 核心表结构

#### projects 表
存储所有Web3项目信息：
```sql
- id: 项目唯一标识
- name: 项目名称
- logo: 项目图标URL
- intro: 简短介绍
- description: 详细描述
- categories: 项目分类数组
- chains: 支持的区块链
- heat_score: 热度评分
- status: 项目状态 (active, new, trending, rising)
- market_cap: 市值
- volume_24h: 24小时交易量
- price_change_24h: 24小时价格变化
- followers: 社交媒体关注数 (JSON)
- twitter_url, telegram_url, etc: 社交媒体链接
```

#### sectors 表
存储行业板块信息：
```sql
- id: 板块标识
- name: 板块名称
- heat_score: 板块热度
- project_count: 项目数量
- change_24h: 24小时变化
- description: 板块描述
```

#### heat_history 表
记录热度变化历史：
```sql
- project_id: 项目ID
- heat_score: 热度分数
- recorded_at: 记录时间
- metadata: 变化元数据
```

### 实时更新机制
- 自动触发器更新时间戳
- 热度变化自动记录历史
- 板块统计自动重新计算

## 🔄 API服务层

### Enhanced API Service
使用`enhancedApiService`获取优化的数据：

```typescript
import { enhancedApiService } from '@/services/enhancedApiService';

// 获取所有项目（带缓存和Twitter增强）
const projects = await enhancedApiService.getProjects();

// 获取单个项目
const project = await enhancedApiService.getProject('project-id');

// 搜索项目
const results = await enhancedApiService.searchProjects('DeFi', {
  categories: ['DeFi'],
  chains: ['Ethereum']
});

// 获取所有板块
const sectors = await enhancedApiService.getSectors();
```

### 缓存策略
- **项目数据**: 2分钟缓存
- **板块数据**: 5分钟缓存  
- **Twitter数据**: 10分钟缓存
- **搜索结果**: 3分钟缓存

### Twitter增强
自动从Twitter API获取：
- 关注者数量
- 24小时提及次数
- 参与度评分
- 趋势分数

## 🔧 配置选项

### API服务配置
```typescript
const config = {
  useSupabase: true,      // 启用Supabase数据库
  useTwitter: true,       // 启用Twitter API
  useCaching: true,       // 启用智能缓存
  offlineMode: false,     // 离线模式（使用mock数据）
  realTimeUpdates: true   // 实时数据更新
};
```

### 缓存配置
```typescript
// 自定义缓存设置
const cacheConfig = {
  defaultTTL: 5 * 60 * 1000,  // 默认5分钟
  maxSize: 100,                // 最大缓存项数
  persistToStorage: true       // 持久化到localStorage
};
```

## 📊 数据流程

### 1. 项目数据更新流程
```
外部API → Twitter API → Supabase数据库 → 缓存层 → 前端组件
                              ↓
                         实时WebSocket推送
```

### 2. 热度计算算法
```typescript
// 综合热度分数计算
const finalHeatScore = (
  baseHeatScore * 0.7 +           // 基础热度70%
  twitterMetrics * 0.3            // Twitter指标30%
);
```

### 3. 实时更新机制
- Supabase实时订阅数据库变化
- Twitter API定期轮询获取最新指标
- 缓存智能失效和更新
- WebSocket推送前端更新

## 🛠️ 开发工具

### 缓存管理
```typescript
import { projectsCache, invalidateProjectCache } from '@/services/cacheService';

// 查看缓存统计
console.log(projectsCache.getStats());

// 手动清除缓存
invalidateProjectCache('project-id');

// 预热缓存
await warmProjectsCache();
```

### 调试模式
```typescript
// 获取服务统计信息
const stats = enhancedApiService.getServiceStats();
console.log('Service Stats:', stats);

// 启用离线模式进行测试
const offlineService = new EnhancedApiService({ 
  offlineMode: true 
});
```

## 📈 性能优化

### 缓存策略
- **分层缓存**: 内存 → localStorage → 数据库
- **智能失效**: 基于数据变化自动清除
- **预加载**: 关键数据提前加载

### 数据库优化
- **索引优化**: 热度评分、分类、时间戳
- **查询优化**: 使用视图和函数
- **分页支持**: 大数据集分批加载

### API调用优化
- **批量处理**: Twitter API批量请求
- **错误重试**: 指数退避重试机制
- **速率限制**: 自动限速保护

## 🔒 安全特性

### 数据安全
- **行级安全**: Supabase RLS策略
- **API密钥管理**: 环境变量隔离
- **输入验证**: 自动清理和验证

### 访问控制
- **公开读取**: 所有数据无需认证
- **服务端写入**: 仅API服务可写入
- **速率限制**: 防止滥用和攻击

## 🚀 部署���南

### 环境配置
```bash
# 生产环境
VITE_SUPABASE_URL=https://your-prod-project.supabase.co
VITE_SUPABASE_ANON_KEY=your-prod-anon-key
VITE_TWITTER_BEARER_TOKEN=your-prod-twitter-token
VITE_API_BASE_URL=https://api.hotweb3.io
```

### 构建和部署
```bash
# 构建生产版本
npm run build

# 部署到Netlify/Vercel
npm run deploy
```

## 📝 API接口文档

### 核心接口
详见 `API_REQUIREMENTS.md` 文件中的完整API规范。

### 实时数据接口
- **WebSocket**: `wss://api.hotweb3.io/ws`
- **事件类型**: `project_update`, `sector_update`, `heat_change`

## 🤝 贡献指南

### 添加新数据源
1. 在 `services/` 目录创建新的服务文件
2. 实现标准接口：`getData()`, `updateData()`, `subscribeUpdates()`
3. 在 `enhancedApiService.ts` 中集成新服务
4. 更新缓存策略和类型定义

### 扩展缓存功能
1. 在 `cacheService.ts` 中添加新的缓存实例
2. 定义缓存键和TTL策略
3. 实现缓存预热和失效逻辑

## 📞 支持

如需技术支持或有疑问：
- 查看项目文档: `README.md`, `API_REQUIREMENTS.md`
- 检查环境配置: `.env.example`
- 运行数据库设置: `supabase-setup.sql`

---

**HotWeb3.io** - 全球Web3热度导航平台 🔥
