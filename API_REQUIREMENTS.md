# HotWeb3.io API 需求文档

## 🔗 **需要接入的API接口**

### **1. 基础统计API**
```
GET /api/statistics
```
**返回数据格式：**
```json
{
  "success": true,
  "data": {
    "total_projects": 605,
    "active_sectors": 77,
    "today_trending": 87,
    "total_users": 601,
    "total_heat_score": 152000,
    "most_active_sector": "Memecoin",
    "avg_heat_score": 2500,
    "last_updated": "2024-01-20T10:30:00Z"
  }
}
```

### **2. 热门项目API**
```
GET /api/trending?time_period=24h&limit=10&sector=DeFi&sort_by=heat_score
```
**返回数据格式：**
```json
{
  "success": true,
  "data": {
    "projects": [
      {
        "id": "proj_001",
        "name": "Friend.Tech",
        "description": "Decentralized social trading platform",
        "logo_url": "https://example.com/logo.jpg",
        "heat_score": 20400,
        "categories": ["SocialFi", "DeFi"],
        "chains": ["Base"],
        "social_links": {
          "website": "https://friend.tech",
          "twitter": "https://twitter.com/friendtech",
          "telegram": "https://t.me/friendtech",
          "discord": "https://discord.gg/friendtech"
        },
        "market_data": {
          "market_cap": "$150M",
          "volume_24h": "$12.5M",
          "price_change_24h": 15.4
        },
        "followers": {
          "twitter": 250000,
          "telegram": 45000,
          "discord": 35000
        },
        "status": "trending",
        "created_at": "2024-01-15T00:00:00Z"
      }
    ],
    "total_count": 156,
    "time_period": "24h",
    "last_updated": "2024-01-20T10:30:00Z"
  }
}
```

### **3. 板块热度图API**
```
GET /api/sectors?time_period=24h
```
**返回数据格式：**
```json
{
  "success": true,
  "data": {
    "sectors": [
      {
        "id": "memecoin",
        "name": "Memecoin",
        "heat_score": 52300,
        "project_count": 35,
        "description": "Community-driven meme cryptocurrencies",
        "change_24h": 45.6,
        "color": "orange",
        "top_projects": [
          {
            "name": "Dogecoin",
            "heat_score": 15600,
            "logo_url": "https://example.com/doge.jpg"
          }
        ]
      }
    ],
    "time_period": "24h",
    "last_updated": "2024-01-20T10:30:00Z"
  }
}
```

### **4. 项目搜索API**
```
GET /api/search?q=defi&sectors=DeFi,NFT&chains=Ethereum&limit=20&offset=0
```
**返回数据格式：**
```json
{
  "success": true,
  "data": {
    "projects": [...], // 同trending projects格式
    "total_count": 45,
    "facets": {
      "sectors": [
        {"name": "DeFi", "count": 25},
        {"name": "NFT", "count": 12}
      ],
      "chains": [
        {"name": "Ethereum", "count": 30},
        {"name": "Solana", "count": 15}
      ]
    },
    "pagination": {
      "limit": 20,
      "offset": 0,
      "has_more": true
    }
  }
}
```

### **5. 项目详情API**
```
GET /api/project/{project_id}
```
**返回数据格式：**
```json
{
  "success": true,
  "data": {
    "project": {
      // 完整项目信息，同trending格式但包含更多字段
      "description_full": "详细描述...",
      "whitepaper_url": "https://example.com/wp.pdf",
      "team": [...],
      "investors": [...],
      "roadmap": [...]
    },
    "comments": [
      {
        "id": "comment_001",
        "user_name": "CryptoAnalyst",
        "comment": "Great project with strong fundamentals",
        "rating": 5,
        "created_at": "2024-01-15T10:30:00Z"
      }
    ],
    "average_rating": 4.5,
    "total_comments": 156,
    "gpt_analysis": {
      "summary": "Friend.Tech is a promising SocialFi project...",
      "strengths": ["Active community", "Innovation", "Strong backing"],
      "risks": ["Market volatility", "Regulatory uncertainty"],
      "market_potential": "high",
      "confidence_score": 0.85,
      "generated_at": "2024-01-20T10:30:00Z"
    }
  }
}
```

### **6. 市场数据API（外部整合）**
```
GET /api/market-data?symbols=BTC,ETH,SOL
```

### **7. 用户相关API**
```
POST /api/user/favorite/{project_id}  // 收藏/取消收藏
GET /api/user/favorites               // 获取收藏列表
POST /api/user/subscribe-alerts       // 订阅提醒
GET /api/user/api-usage              // API使用统计
```

### **8. 实时数据WebSocket**
```
wss://api.hotweb3.io/ws
```
**消息格式：**
```json
{
  "type": "heat_update",
  "payload": {
    "project_id": "proj_001",
    "new_heat_score": 21500,
    "change": 1100
  }
}
```

---

## 🔒 **安全要求规范**

### **1. 认证与授权**
- **API Key认证**：格式 `hw3_{32位随机字符}`
- **JWT Token**：访问token(15分钟) + 刷新token(7天)
- **请求签名**：HMAC-SHA256签名防篡改
- **IP白名单**：可选的IP限制功能

### **2. 速率限制**
- **免费用户**：100请求/分钟，1000请求/小时
- **付费用户**：1000请求/分钟，10000请求/小时
- **WebSocket**：每连接最多订阅20个频道

### **3. 数据安全**
- **HTTPS强制**：所有API必须使用HTTPS
- **敏感数据加密**：用户信息、API密钥等加密存储
- **SQL注入防护**：参数化查询，输入验证
- **XSS防护**：输出编码，CSP头设置

### **4. 监控与日志**
- **请求日志**：记录所有API调用
- **错误监控**：Sentry集成错误追踪
- **性能监控**：响应时间、成功率统计
- **安全日志**：异常活动检测和记录

### **5. 错误处理**
```json
{
  "success": false,
  "error": "Rate limit exceeded",
  "error_code": "RATE_LIMIT_EXCEEDED",
  "message": "请求过于频繁，请稍后再试",
  "details": {
    "limit": 100,
    "window": "1 minute",
    "reset_time": "2024-01-20T10:31:00Z"
  }
}
```

---

## 🚀 **部署和运维要求**

### **1. 基础设施**
- **CDN加速**：静态资源和API响应缓存
- **负载均衡**：多实例部署，自动故障转移
- **数据备份**：每日自动备份，异地存储
- **SSL证书**：通配符证书，自动续期

### **2. 缓存策略**
- **Redis缓存**：热门数据5分钟缓存
- **静态资源**：24小时CDN缓存
- **API响应**：GET请求1分钟缓存
- **WebSocket**：实时数据不缓存

### **3. 扩展性考虑**
- **水平扩展**：支持多实例部署
- **数据库分片**：按项目ID分片存储
- **异步处理**：队列处理重计算任务
- **微服务架构**：API网关 + 微服务拆分

---

## 📊 **数据更新策略**

### **1. 实时数据（WebSocket推送）**
- 项目热度变化 > 10%时推送
- 新项目上线推送
- 重大市场事件推送

### **2. 定时更新**
- **每5分钟**：热度分数重计算
- **每15分钟**：市场数据更新
- **每小时**：板块排名更新
- **每日**：新项目抓取和分析

### **3. 数据源整合**
- **社交媒体**：Twitter API, Telegram Bot
- **链上数据**：Moralis, Alchemy, QuickNode
- **市场数据**：CoinGecko, CoinMarketCap
- **项目信息**：GitHub, 官网爬虫, GPT分析

---

## 🔧 **开发���测试要求**

### **1. API文档**
- **Swagger/OpenAPI**：完整的API文档
- **Postman集合**：测试用例集合
- **SDK支持**：JavaScript, Python, Go

### **2. 测试覆盖**
- **单元测试**：>90%代码覆盖率
- **集成测试**：API端到端测试
- **性能测试**：压力测试和基准测试
- **安全测试**：漏洞扫描和渗透测试

### **3. 监控告警**
- **可用性监控**：99.9%可用性目标
- **响应时间**：95%请求<200ms
- **错误率**：<0.1%错误率
- **自动告警**：异常情况邮件/短信通知

---

## 💡 **核心功能补充建议**

### **1. AI智能分析**
- GPT项目风险评估
- 趋势预测算法
- 异常检测系统
- 智能推荐引擎

### **2. 社区功能**
- 用户评论和评分
- 专家分析师认证
- 项目方官方认证
- 社区投票和治理

### **3. 高级功能**
- 价格提醒和通知
- 投资组合跟踪
- 数据导出和API
- 白标解决方案

### **4. 变现模式**
- Pro订阅服务
- API访问费用
- 广告和推广
- 数据授权和咨询

这个完整的API需求和安全规范将确保HotWeb3.io成为一个安全、可靠、高性能的Web3数据平台。
