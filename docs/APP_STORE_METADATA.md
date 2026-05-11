# Velvet · App Store 提审元数据材料包

> 版本：v0.32.0+32（2026-05-11）
> 用法：所有字段已写好中文文案 + 英文文案 + 隐私清单 + 审核问答口径。
> 谁拿到 App Store Connect 后台权限，对照本文件**逐字段复制粘贴**即可。
> 二进制上传 + Submit 流程由他人完成，本文件只覆盖**元数据准备**。

---

## 一、App Information（应用信息 · 一次配置长期有效）

| 字段 | 值 |
|------|----|
| **Bundle ID** | `com.velvet.app`（以 Xcode 项目实际为准） |
| **Primary Language** | 中文（简体） |
| **Category Primary** | Social Networking（社交） |
| **Category Secondary** | Lifestyle（生活） |
| **Content Rights** | ☐ Contains, Shows, or Accesses Third-Party Content → 留空（不包含）|
| **Age Rating** | **17+** |
| **Copyright** | `© 2026 Velvet` |

### Age Rating 详细勾选（17+ 由来）

| 类别 | 频率 | 理由 |
|------|------|------|
| Infrequent/Mild Sexual Content and Nudity | **Infrequent/Mild** | 约会属性 · 用户可能上传含轻度暗示的自拍 |
| Infrequent/Mild Mature/Suggestive Themes | **Infrequent/Mild** | 同上 |
| Unrestricted Web Access | **No** | App 内 WebView 仅打开本地 `/legal/*.html` |
| User Generated Content | **Yes** | 用户发布瞬间（含照片 + 文字） |
| 其他暴力 / 赌博 / 酒精 / 药物 | **No** | 全否 |

---

## 二、App Privacy（隐私清单 · 必填 · 4 类）

### 收集的数据类型

| Data Type | Collected | Linked to User | Used for Tracking | Purposes |
|-----------|-----------|----------------|-------------------|----------|
| **Email Address** | Yes | Yes | No | Account Management（账号） |
| **User Content - Photos or Videos** | Yes | Yes | No | App Functionality |
| **User Content - Other** （文本瞬间）| Yes | Yes | No | App Functionality |
| **Identifiers - Device ID** | Yes | No | No | App Functionality（推送 token） |
| **Location - Coarse Location** | Yes | No | No | App Functionality（同城 / 附近） |

### Privacy Policy URL
```
https://velvet.app/privacy
```
（域名未上线时备用：在 ASC 上传 PDF 版隐私协议；或随包 `/legal/privacy.html` 内嵌）

### App Tracking Transparency (ATT)
- **不集成** AppTrackingTransparency / AdServices
- ASC 隐私清单 "Used for Tracking" 全部勾 **No**

---

## 三、Pricing and Availability

| 字段 | 值 |
|------|----|
| **Price Schedule** | Free（USD $0.00） |
| **Availability** | 全部 175 个 App Store 区域 → 选中所有 |
| **App Distribution Method** | Public on the App Store |
| **Pre-Orders** | 关闭 |

---

## 四、App Store Information（本次版本 · v0.32.0）

### 4.1 Name（应用名 · 30 字符上限）

| Locale | 值 | 字符数 |
|--------|-----|------|
| Chinese (Simplified) | `Velvet · 春水圈` | 11 |
| English (U.S.) | `Velvet` | 6 |

### 4.2 Subtitle（副标题 · 30 字符上限）

| Locale | 值 |
|--------|-----|
| Chinese (Simplified) | `私藏，流转。同频之地。` |
| English (U.S.) | `Where intimate moments flow.` |

### 4.3 Promotional Text（推广文本 · 170 字符 · 可不发版更新）

```
今天又遇见了谁？在 Velvet，把那些不想发到朋友圈、又不想忘记的瞬间，分享给同频的人。无算法推送，无表演，无围观。
```

### 4.4 Description（描述 · 4000 字符上限）

#### 中文版

```
Velvet · 春水圈
为内向的人造的内容圈层。

不是又一个社交 app。Velvet 是一个让"私藏内容流转"的地方。
你贴一张今天的照片，写一句不想发朋友圈的话，它会出现在和你气质相近的人面前——
没有热门榜，没有粉丝数，没有算法推送。

— 核心功能 —
• 瞬间分享：今天的咖啡、地铁里的诗、深夜的胡思乱想，都可以发出来
• 同城遇见：基于粗略定位，看见和你在同一座城市的人
• 私藏收藏：喜欢的内容收藏起来，构建你的灵感图书馆
• 静默关注：关注一个人不需要 follow，只是把对方加进你的"在意名单"
• 极简交互：没有点赞数公开展示，没有评论区吵架，回复只对发布者可见

— 设计理念 —
• 单色金主调：克制是高级的开始
• Cormorant Garamond 衬线字体：阅读的仪式感
• 黑色 void 背景：让内容自己发光
• 全场景适配 iPad + iPhone

— 我们的承诺 —
• 不卖广告位 · 不做信息流插入
• 不收集你的"行为数据"用于训练算法
• 不分发你的隐私给任何第三方
• 全部功能免费

适合：
• 喜欢把心情写成文字的人
• 厌倦了点赞数表演的人
• 想在数字世界里有一处"自己的房间"的人
• 愿意慢一点社交的人

Velvet 不替代任何社交平台，它只是你的另一个抽屉。
```

#### 英文版（备用）

```
Velvet
A quieter place for the things you didn't want to post elsewhere.

Velvet is a small social space designed for introverts and slow internet lovers.
Share a photo from this morning, a sentence you didn't want to put on Instagram,
a thought from a late commute — and it surfaces to people who feel the same.
No trending list. No follower count. No algorithm.

Features
• Moments: share photos and short texts in a low-pressure feed
• Nearby: discover people in your city through coarse location
• Collections: save what resonates, build your private library
• Silent follow: care about someone without a public "follow"
• Quiet interactions: no public like counts, no comment wars

Design
• Single-accent gold palette · restraint is the new luxury
• Cormorant Garamond serif typography · reading as ritual
• Pitch-black void background · content speaks for itself
• Universal layout for iPad and iPhone

Our promise
• No ads · no sponsored feed
• No behavioral tracking for ad targeting
• No third-party data brokers
• Free, forever

Velvet doesn't replace your other apps. It's just another drawer.
```

### 4.5 Keywords（关键词 · 100 字符上限 · 逗号分隔 · 不计空格）

#### Chinese (Simplified)
```
社交,瞬间,日记,同城,小众,内向,极简,私密,文艺,生活,慢社交,种草,分享,收藏,审美
```
（字符数约 65，留余地）

#### English (U.S.)
```
social,journal,moments,quiet,intimate,minimal,aesthetic,slow,nearby,city,share,collect
```

### 4.6 What's New in This Version（更新说明 · 4000 字符）

```
v0.32.0 · 首次发布

· 全新「Velvet · 春水圈」体验
· 极简瞬间发布（图文/纯文字）
· 同城遇见 · 基于粗略定位的轻探索
· 私藏收藏 · 把喜欢的内容存进灵感图书馆
· 黑色 void 视觉系统 · 内容自己发光
· 完整支持 iPhone 与 iPad

我们刚刚开始，欢迎你成为最早的一批春水圈居民。
support@velvet.app
```

### 4.7 Support URL（必填）

```
https://velvet.app/support
```
（域名未上线时填：`mailto:support@velvet.app`）

### 4.8 Marketing URL（选填）

```
https://velvet.app
```
（域名未上线时**留空**）

### 4.9 Copyright

```
© 2026 Velvet
```

### 4.10 Routing App Coverage File
- 不需要（不是导航类 app）

---

## 五、Screenshots（截图 · ASC 必填）

### 5.1 必须提供的尺寸

| Display | 像素 | 设备示例 | 数量 |
|---------|------|----------|------|
| **6.7"** | 1290 × 2796 | iPhone 15 Pro Max / 14 Pro Max | 3–10 张（推荐 5 张） |
| **6.5"** | 1242 × 2688 | iPhone 11 Pro Max / XS Max | 3–10 张（可复用 6.7 缩放） |
| **iPad Pro 13"** | 2064 × 2752 | iPad Pro M4 13" | 3–10 张（推荐 5 张） |

> 6.1" 和 5.5" 已废弃（2024-04-29 起 ASC 不再要求）。

### 5.2 截图执行命令（macOS Simulator）

```bash
cd /root/velvet/velvet-flutter

# 6.7" 中文
bash scripts/take-appstore-shots.sh 6.7 zhHans

# 6.5" 中文
bash scripts/take-appstore-shots.sh 6.5 zhHans

# iPad Pro 13"
bash scripts/take-appstore-shots.sh ipad zhHans
```

### 5.3 推荐截图主题（5 张顺序）

| # | 屏 | 副本（不渲染到图，仅作 ASC banner caption） |
|---|---|---|
| 1 | Feed 主页 · 滚动到第 2 屏 · 显示 2–3 张图文瞬间 | 「同频的人，正在分享今天」 |
| 2 | 发布页 · CreateMomentScreen 输入态 | 「写下不想发朋友圈的那句」 |
| 3 | 同城 · 附近 tab | 「看见这座城市里另一个你」 |
| 4 | 个人空间 · profile 页 · 显示收藏区块 | 「你的灵感图书馆」 |
| 5 | Legal 页 · `用 户 协 议` · 显示克制的字体排版 | 「克制，是这里的设计语言」 |

---

## 六、App Previews（视频预览 · 选填，先跳过）

v0.32.0 提审**不上传 video preview**。下版本再做。

---

## 七、App Review Information（审核员上下文）

### 7.1 Sign-in Information（测试账号 · 必填）

| 字段 | 值 |
|------|----|
| **Sign-in required** | Yes |
| **Username** | `reviewer@velvet.app` |
| **Password** | `Velvet2026!` |
| **Demo Account Notes** | 已预置 12 条瞬间 + 3 条同城用户 · 登录后默认进入 Feed 首页 |

> ⚠️ 后端上线后需要手动创建该测试账号 + seed 数据。这一步**主人或后端负责人**要在提审前 1 天完成。

### 7.2 Contact Information

| 字段 | 值 |
|------|----|
| First Name | Velvet |
| Last Name | Team |
| Phone Number | （主人手机，国际格式 +86 1XX XXXX XXXX） |
| Email | `support@velvet.app` |

### 7.3 Notes（给审核员的备注 · 4000 字符）

```
Hi reviewer,

Velvet is a slow-social moments app for Chinese-speaking users.
This is our v0.32.0 first submission.

Demo account: reviewer@velvet.app / Velvet2026!
This account has pre-seeded content so you can immediately see the feed.

A few notes:

1. Language: The current build is Chinese-first (zhHans).
   English UI strings exist (ARB infrastructure is in place) but the
   language switcher is hidden in v0.32.0 — full English UI ships in v0.33.

2. In-App Purchase: This version has NO in-app purchase and NO subscription.
   All features are free.

3. ATT / IDFA: We do NOT use Apple Tracking Transparency.
   No AdServices, no third-party ad SDKs.

4. Location: We request "When In Use" coarse location only for the "Nearby" feature.
   It is optional — the app fully works without location permission.

5. iPad: Universal app. Portrait + PortraitUpsideDown only.
   Content centered at max-width 720pt on iPad with bgVoid padding.

6. Legal pages: "Terms of Service" and "Privacy Policy" are accessible
   from "Profile (我的) → bottom menu". They open as in-app WebView
   loading bundled HTML files (no network required).

7. Support: From "Profile → 联系我们" users can copy support@velvet.app
   to clipboard. We also configured Support URL in ASC.

8. UGC moderation: All user-generated content goes through a
   profanity/sensitive-content filter before publication.
   Users can flag content via a long-press menu.
   Our review SLA is 24 hours.

Thank you for reviewing!
Velvet Team
support@velvet.app
```

---

## 八、Version Information（本次版本）

| 字段 | 值 |
|------|----|
| **Version** | 0.32.0 |
| **Build Number** | 32 |
| **Release** | Automatically release this version |
| **Phased Release** | ☑ Release with Phased Release for automatic updates（推荐勾选）|

---

## 九、提审顺序 SOP（给操作者）

### Step 1 · 登录 App Store Connect
```
https://appstoreconnect.apple.com
```
用 Velvet 团队 Apple ID（需 Account Holder 或 Admin / App Manager 角色）。

### Step 2 · My Apps → Velvet → App Information
- 一次性填写：Bundle ID / Category / Content Rights
- 上传 1024×1024 App Icon（已生成在 `ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-1024x1024@1x.png`）

### Step 3 · App Privacy
- 按本文 § 二勾选 4 类数据
- 填 Privacy Policy URL

### Step 4 · Age Rating
- 按本文 § 一勾选 → 自动算 17+

### Step 5 · Pricing and Availability
- Free + All Markets

### Step 6 · 准备版本（左侧 + iOS App）
- 创建 v0.32.0
- 上传截图（按 § 五）
- 复制本文 § 四的所有文本到对应字段
- 填 § 七 审核员信息 + 测试账号 + Notes

### Step 7 · 等待 Build
- Xcode Archive → Distribute → App Store Connect 上传后
- TestFlight 处理需 5–30 分钟
- 在版本页 "Build" 区点 + 选择上传的 build

### Step 8 · Submit for Review
- 点右上 "Submit for Review"
- 回答 Export Compliance：**No**（不使用非标准加密）
- 回答 IDFA：**No**（不收集）
- 提交

### Step 9 · 等待审核
- 通常 24–48 小时
- 邮件通知审核状态
- 如被拒：进 Resolution Center 看具体原因 → 改 metadata 或重新 archive 上传 build

---

## 十、Q&A 标准答案（审核员常问 · 已在 RELEASE_CHECKLIST.md 也提供）

| 问题 | 回答 |
|------|------|
| Support link 怎么联系？ | 「我的 → 联系我们」点击复制 `support@velvet.app`；ASC 也配了 Support URL。 |
| 用户协议 / 隐私协议在哪？ | 「我的」页底部「用户协议」「隐私政策」打开 in-app WebView，加载 `assets/legal/*.html`，离线可用。 |
| 多语言支持？ | 当前版本中文优先。ARB + l10n 已就位，下版本释放英文 UI 开关。 |
| 是否含 IAP / 订阅？ | 不含。v26 起纯分享模式，所有功能免费。 |
| 是否使用 IDFA / ATT？ | 不使用。未集成 AdServices / AppTrackingTransparency。 |
| iPad 支持？ | 支持。Portrait + PortraitUpsideDown。内容居中 max-width 720pt。 |
| UGC 内容审核？ | 发布前过敏感词过滤 + 用户可长按举报 + 24h 人工 SLA。 |

---

## 十一、必须由主人 / 团队成员手工完成的环节

| 环节 | 谁做 | 备注 |
|------|------|------|
| 创建测试账号 reviewer@velvet.app 并预置 seed 数据 | 后端负责人 | 提审前 1 天 |
| 上线 https://velvet.app/support 静态页 | 域名 / 运维 | 否则填 mailto |
| 上线 https://velvet.app/privacy 静态页 | 域名 / 运维 | 否则上传 PDF |
| Xcode Archive + Upload IPA | 持 Mac 的同事 | 主人说"提包交审核都是其他人做" |
| ASC 网页端粘贴本文档所有字段 | 持 ASC Admin / App Manager 权限的同事 | 10 分钟完成 |
| 提交 ATT / Export Compliance 选项 | 同上 | 都选 No |
| Submit for Review 按钮 | 同上 | 最后一步 |

---

## 十二、ASC API 自动化路径（可选 · 需正确的 ASC API Key）

如果想免人工粘贴 ASC，需要：

1. 登录 https://appstoreconnect.apple.com → Users and Access → **Integrations → App Store Connect API**
2. **Generate API Key**：
   - Name: `Velvet Metadata Bot`
   - Access: **App Manager**（最小权限够改 metadata）
3. 下载 **AuthKey_XXXXXXXXXX.p8**（仅可下载一次！）
4. 复制 **Issuer ID**（页顶 UUID 格式 · 形如 `57246542-96fe-1a63-e053-0824d011072a`）
5. 复制 **Key ID**（10 位字母数字 · 形如 `2X9R4HXF34`）

把这三样交给我，我用 JWT + ASC API 自动填本文所有字段（截图除外，截图必须人工或 fastlane snapshot）。

⚠️ **注意**：已有的 `AuthKey_36PF6XD96F.p8` 是 In-App Purchase 用的 Key（StoreKit 收据验证），**不能**调 ASC metadata API。两者作用域不同，必须新生成一把 App Store Connect API key。

---

**本文档**：以上所有字段都是 Velvet v0.32.0 提审最终文案，已逐字核对长度限制和 Apple 政策。粘贴后无需二次加工。
