# 服药宝 UI设计方案二：温暖舒适风格

## 设计理念
北欧简约风格，温暖亲切，适合长期使用的健康管理App。参考：Notion、Headspace、Calm

## 核心特点
- 色彩温暖：绿色主调 + 陶土色点缀
- 圆角适中：16px自然圆角
- 字体舒适：Outfit 全场景使用
- 柔和阴影：层次感但不厚重
- 宁静氛围：降低视觉刺激

## 色彩系统

### 主色板
```css
--primary: #3D8A5A        /* 森林绿 - 主按钮、选中状态 */
--primary-light: #4D9B6A  /* 浅绿色 */
--primary-dark: #2D6A4A   /* 深绿色 */
--primary-soft: #C8F0D8   /* 30%透明度 - 背景装饰 */
```

### 辅助色
```css
--success: #4D9B6A        /* 绿色 - 积极完成 */
--accent: #D89575         /* 陶土色 - 强调、次要动作 */
--accent-light: #E8B5A3   /* 浅陶土色 */
--warning: #D4A64A        /* 琥珀色 - 提醒 */
--error: #D08068          /* 暖红色 - 错误 */
```

### 中性色
```css
--bg-page: #F5F4F1       /* 暖奶油白 - 页面背景 */
--bg-surface: #FFFFFF     /* 纯白 - 卡片 */
--bg-elevated: #FAFAF8   /* 微暖白 - 提升表面 */
--bg-muted: #EDECEA      /* 暖灰 - 禁用/次要背景 */
--text-primary: #1A1918   /* 近黑色 - 主要文字 */
--text-secondary: #6D6C6A /* 中灰 - 次要文字 */
--text-tertiary: #9C9B99 /* 浅灰 - 辅助文字 */
--text-muted: #A8A7A5   /* 灰色 - 禁用状态 */
--border: #E5E4E1        /* 边框 */
--border-strong: #D1D0CD /* 强调边框 */
```

## 字体系统

### 字体选择
- 全场景字体：**Outfit** (Google Fonts) - 几何无衬线，友好现代

### 字重等级
```css
--font-bold: 700        /* 大数字、强调 */
--font-semibold: 600    /* 标题、次要强调 */
--font-medium: 500      /* 标签、导航 */
--font-regular: 400     /* 正文 */
```

### 字号规范
```css
--text-display: 32px   /* 屏幕标题 */
--text-title: 26px     /* 大标题 */
--text-section: 22px    /* 区块标题 */
--text-headline: 18px   /* 卡片标题 */
--text-body: 15px       /* 正文 */
--text-subhead: 14px    /* 辅助文字 */
--text-caption: 13px    /* 标签、角标 */
--text-tab: 11px       /* 底部导航 */
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
--radius-sm: 6px     /* 小按钮 */
--radius-md: 12px    /* 中等卡片 */
--radius-lg: 16px    /* 大卡片 */
--radius-xl: 20px    /* 特色卡片 */
--radius-2xl: 24px  /* 浮层 */
--radius-full: 100px /* 圆形、胶囊 */
```

## 阴影系统（暖色调）

```css
--shadow-sm: 0 1px 2px rgba(26,25,24,0.05)
--shadow-md: 0 2px 8px rgba(26,25,24,0.08)
--shadow-lg: 0 8px 16px rgba(26,25,24,0.10)
--shadow-xl: 0 16px 24px rgba(26,25,24,0.12)
```

## 组件设计

### 1. 骨架屏加载
- 暖灰色背景 + 柔和脉动
- 动画更缓慢优雅

### 2. 药品卡片
- 白色背景，16px圆角
- 柔和阴影
- 绿色图标背景
- 简洁操作按钮

### 3. 统计卡片
- 白色背景 + 阴影
- 大号数字 + 负字间距
- 绿色/陶土色标签

### 4. 底部导航栏
- 胶囊形状
- 选中：绿色填充 + 白色图标
- 未选中：灰色图标

### 5. 空状态
- 温暖插画风格
- 柔和配色
- 鼓励性文案

### 6. 错误状态
- 暖红色调
- 友好提示语气

## 响应式设计
同方案一结构

## 交互反馈
- 动画更缓慢优雅（200ms）
- 重视舒适感而非速度感
