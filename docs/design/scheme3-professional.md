# 服药宝 UI设计方案三：专业技术风格

## 设计理念
杂志数据风，理性严谨，适合追求效率和专业感的用户。参考：经济学人数据可视化、Linear、Raycast

## 核心特点
- 色彩克制：青色主调 + 橙色点缀
- 细边框：1px边框，无阴影
- 字体混搭：衬线标题 + 等宽数据
- 信息密度：高效率数据展示
- 精确感：像素级对齐

## 色彩系统

### 主色板
```css
--primary: #0D6E6E        /* 深青色 - 主按钮、选中状态 */
--primary-light: #138B8B  /* 亮青色 */
--primary-dark: #0A5555   /* 深青色 */
--primary-soft: #0D6E6E10 /* 极淡青色 */
```

### 辅助色
```css
--success: #0D6E6A       /* 青色 - 完成 */
--accent: #E07B54        /* 橙色 - 强调、进行中 */
--accent-light: #F0A090 /* 浅橙色 */
--warning: #B8860B       /* 深金色 - 提醒 */
--error: #C53030         /* 深红色 - 错误 */
```

### 中性色
```css
--bg-page: #FAFAFA       /* 近白 - 页面背景 */
--bg-surface: #FFFFFF    /* 纯白 - 卡片 */
--bg-muted: #F0F0F0     /* 浅灰 - 禁用/次要 */
--bg-elevated: #F8F8F8  /* 微灰 - 提升表面 */
--text-primary: #1A1A1A  /* 近黑 - 主要文字 */
--text-secondary: #666666 /* 中灰 - 次要文字 */
--text-tertiary: #888888 /* 浅灰 - 辅助文字 */
--text-muted: #AAAAAA   /* 灰色 - 禁用 */
--text-subtle: #BBBBBB  /* 浅灰 - 次要元素 */
--border: #E5E5E5       /* 边框 */
--border-muted: #DDDDDD /* 弱边框 */
```

## 字体系统

### 字体选择
- 标题字体：**Newsreader** (衬线) - 优雅权威
- 数据字体：**JetBrains Mono** (等宽) - 精确专业
- 正文字体：**Inter** - 清晰易读

### 字重等级
```css
--font-bold: 700        /* 大数字、强调 */
--font-semibold: 600    /* 标签、按钮 */
--font-medium: 500      /* 标题、次要 */
--font-regular: 400     /* 正文 */
```

### 字号规范
```css
--text-display: 40px   /* 屏幕标题 - Newsreader */
--text-title: 32px     /* 大标题 - Newsreader */
--text-section: 24px   /* 区块标题 - Newsreader */
--text-headline: 18px   /* 卡片标题 - Newsreader */
--text-body: 15px       /* 正文 - Inter */
--text-subhead: 14px    /* 辅助文字 - Inter */
--text-data: 14px       /* 数据 - JetBrains Mono */
--text-caption: 12px    /* 标签 - Inter */
--text-label: 11px      /* 标签 - JetBrains Mono */
--text-tab: 10px       /* 底部导航 - Inter */
```

## 间距系统

```css
--space-xs: 4px
--space-sm: 8px
--space-md: 12px
--space-lg: 16px
--space-xl: 20px
--space-2xl: 24px
--space-3xl: 32px
```

## 圆角系统

```css
--radius-sm: 4px     /* 数据标签 */
--radius-md: 6px     /* 按钮、输入框 */
--radius-lg: 8px     /* 卡片 */
--radius-xl: 10px    /* 特色卡片 */
--radius-2xl: 12px   /* 主卡片 */
--radius-full: 32px  /* 底部导航胶囊 */
```

## 边框系统

```css
--border-default: 1px solid #E5E5E5
--border-strong: 1px solid #CCCCCC
--border-accent: 1px solid #0D6E6E
```

## 阴影系统（微弱）

```css
--shadow-tab: 0 2px 12px rgba(0,0,0,0.08)
--shadow-segment: 0 1px 2px rgba(0,0,0,0.10)
```

## 组件设计

### 1. 骨架屏加载
- 浅灰背景 + 细框风格
- 动画快速精准

### 2. 药品卡片
- 白色背景，1px细边框
- 青色左边框标识重要
- 衬线药品名
- 等宽时间显示

### 3. 统计卡片
- 1px边框
- JetBrains Mono大数字
- 青色/灰色标签
- 紧凑布局

### 4. 底部导航栏
- 胶囊形状，32px大圆角
- 浅阴影
- 青色选中
- 紧凑标签

### 5. 空状态
- 线框插画风格
- 简洁线条
- 理性引导

### 6. 错误状态
- 深红色调
- 精确错误代码
- 正式语气

## 响应式设计
同方案一结构

## 交互反馈
- 动画快速精准（100ms）
- 重视效率而非装饰
- 状态变化明显
