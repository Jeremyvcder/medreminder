# 服药宝 UI设计方案一：明亮活力风格

## 设计理念
明亮活泼，现代感强，参考主流社交产品设计（Instagram、小红书风格），适合健康类App

## 核心特点
- 色彩明亮：紫色主调 + 青色 + 粉色点缀
- 圆角柔和：24px大圆角，卡片亲和力强
- 字体现代：Plus Jakarta Sans + Inter
- 骨架屏加载： shimmer动画效果
- 交互反馈：即时反馈，状态变化自然

## 色彩系统

### 主色板
```css
--primary: #8B5CF6        /* 紫色 - 主按钮、选中状态 */
--primary-light: #A78BFA  /* 浅紫色 - hover状态 */
--primary-dark: #7C3AED   /* 深紫色 - 按下状态 */
--primary-soft: #8B5CF620 /* 12%透明度 - 背景装饰 */
```

### 辅助色
```css
--success: #14B8A6        /* 青色 - 已完成、积极 */
--success-light: #5EEAD4  /* 浅青色 */
--warning: #F472B6        /* 粉色 - 提醒、待处理 */
--warning-light: #F9A8D4 /* 浅粉色 */
--error: #EF4444         /* 红色 - 错误、漏服 */
```

### 中性色
```css
--bg-page: #FFFFFF        /* 页面背景 */
--bg-surface: #F4F4F5     /* 卡片背景 */
--bg-elevated: #E4E4E7    /* 提升表面 */
--text-primary: #18181B   /* 主要文字 */
--text-secondary: #71717A /* 次要文字 */
--text-tertiary: #A1A1AA /* 辅助文字 */
--text-muted: #D4D4D8    /* 禁用状态 */
--border: #F4F4F5        /* 边框 */
```

## 字体系统

### 字体选择
- 标题字体：**Plus Jakarta Sans** (Google Fonts)
- 正文字体：**Inter** (系统默认)

### 字重等级
```css
--font-extrabold: 800   /* 大数字、强调指标 */
--font-bold: 700        /* 标题、卡头 */
--font-semibold: 600    /* 次要标题、按钮 */
--font-medium: 500      /* 标签、导航 */
--font-regular: 400     /* 正文、描述 */
```

### 字号规范
```css
--text-display: 34px   /* 屏幕标题 */
--text-title: 28px     /* 大标题 */
--text-section: 20px    /* 区块标题 */
--text-headline: 18px   /* 卡片标题 */
--text-body: 16px       /* 正文 */
--text-subhead: 14px    /* 辅助文字 */
--text-caption: 12px    /* 标签、角标 */
--text-tab: 11px       /* 底部导航 */
```

## 间距系统

```css
--space-xs: 4px   /* 紧凑元素 */
--space-sm: 8px   /* 元素间距 */
--space-md: 12px  /* 组件内间距 */
--space-lg: 16px  /* 组件间距 */
--space-xl: 20px  /* 区块间距 */
--space-2xl: 24px /* 大区块间距 */
--space-3xl: 32px /* 页面边距 */
```

## 圆角系统

```css
--radius-sm: 8px    /* 小按钮、输入框 */
--radius-md: 12px   /* 中等卡片 */
--radius-lg: 16px   /* 大卡片 */
--radius-xl: 20px   /* 特色卡片 */
--radius-2xl: 24px  /* 主卡片、浮层 */
--radius-full: 100px /* 圆形、胶囊 */
```

## 阴影系统

```css
--shadow-sm: 0 1px 2px rgba(0,0,0,0.05)
--shadow-md: 0 4px 6px rgba(0,0,0,0.07)
--shadow-lg: 0 10px 15px rgba(0,0,0,0.1)
--shadow-xl: 0 20px 25px rgba(0,0,0,0.15)
```

## 组件设计

### 1. 骨架屏加载
- 浅灰色背景 + shimmer动画
- 脉动效果：从左到右渐变移动
- 加载时间：300ms fade-in

### 2. 药品卡片
- 白色背景，24px圆角
- 顶部：药品图标(圆形,48px) + 名称 + 剂量
- 底部：操作按钮（已服/稍后/跳过）
- 右侧：提醒时间（紫色高亮）

### 3. 统计卡片
- 浅灰背景，横向排列
- 大数字 + 小标签
- 青色表示待服，紫色表示已完成

### 4. 底部导航栏
- 胶囊形状（pill-style）
- 选中：紫色填充 + 白色图标
- 未选中：灰色图标 + 透明背景

### 5. 空状态设计
- 插画图标 + 引导文字
- 明确的操作按钮
- 柔和的配色不过于刺眼

### 6. 错误状态设计
- 红色图标提示
- 简洁的错误描述
- 重试按钮明确可见

## 响应式设计

### 移动端 (< 600px)
- 单列布局
- 卡片宽度100%
- 底部导航固定

### 平板 (600px - 1200px)
- 双列布局（统计卡片）
- 侧边距增加
- 卡片圆角增加到28px

### 桌面端 (> 1200px)
- 最大宽度限制600px居中
- 保持移动端操作体验
- 两侧留白区域

## 交互反馈

### 按钮点击
- 按下：scale(0.98) + 变暗
- 释放：scale(1.0) + 恢复
- 动画时长：150ms ease-out

### 卡片操作
- 已服：绿色勾选动画
- 稍后：倒计时动画
- 跳过：淡出效果

### 骨架屏
- shimmer：从左到右移动
- 间隔：1.5s循环
- 渐变：20%白 -> 40%灰 -> 20%白
