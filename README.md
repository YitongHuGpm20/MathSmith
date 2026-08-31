# MathSmith | 数锻

> A data-driven educational math game about understanding the process, not just entering the answer.
> 一款关注解题过程，而非只判断最终答案的数据驱动数学教育游戏。

MathSmith is a bilingual Godot portfolio project designed and developed by **Yitong Hu**. It demonstrates educational game design, technical design, UI/UX implementation, deterministic learning systems, adaptive practice, content-authoring tools, and milestone-based production.

《数锻》是由 **Yitong Hu** 设计并开发的 Godot 双语作品集项目，集中展示教育游戏设计、技术设计、UI/UX 实现、确定性学习系统、自适应练习、内容创作工具与里程碑式项目管理能力。

| Project | Details |
| --- | --- |
| **Status / 状态** | M1–M7 implemented / M1–M7 已完成 |
| **Engine / 引擎** | Godot 4.7.1 |
| **Resolution / 分辨率** | 1920 × 1080, responsive canvas |
| **Languages / 语言** | English / 简体中文 |
| **Content / 内容** | 12 Levels, 90 authored Questions / 12 个关卡、90 道题 |
| **Development / 开发周期** | 10 active development days across three weeks / 三周跨度、10 个实际开发日 |
| **Role / 职责** | Educational Game Technical Designer, Game Designer, Developer, Project Planner |

---

## Demo & Portfolio | 演示与作品集

### Play Online | 在线试玩

[Play MathSmith on itch.io / 在 itch.io 试玩《数锻》](https://bugondesk.itch.io/mathsmith)

### M1–M7 Development Video | M1–M7 里程碑开发合辑

- [Watch on YouTube / 在 YouTube 观看](https://youtu.be/JnWfYu5qoms)
- [Download the video / 下载视频文件](Docs/Recordings/MathSmith_Demo_Milestone1-7.mp4)

The video shows how MathSmith evolved from a Step Ordering prototype into a bilingual learning product with three core interactions, progression, replay modes, analytics, teacher tools, and a guided Tutor.

视频展示《数锻》如何从步骤排序原型，逐步发展为包含三种核心玩法、成长循环、重复游玩、学习分析、教师工具与引导式 Tutor 的双语教育游戏。

### Portfolio Presentation | 项目演示文稿

- [Download PowerPoint / 下载 PPT](Docs/Presentation/MathSmith.pptx)
- [View Online / 在线查看](https://docs.google.com/presentation/d/1pEMtKXkR5GvK5Gaz90E30Xhha7ux3LYvIaGfRUnblSA/edit?usp=sharing)

---

## Project Overview | 项目概览

Most math exercises evaluate only the final answer. MathSmith turns the reasoning between a Question and its answer into the playable experience.

多数数学练习只评价最终结果。《数锻》将题目与答案之间的推理过程转化为可交互的游戏体验。

~~~text
Choose Content → Rebuild the Process → Receive Feedback
→ Earn Score and Stars → Review Mistakes → Practice Adaptively → Replay

选择内容 → 重建解题过程 → 获得反馈
→ 获取分数与星级 → 复习错题 → 自适应练习 → 重复挑战
~~~

### Design Goals | 设计目标

- Make intermediate mathematical reasoning playable. / 让中间推理步骤成为玩家操作。
- Present readable, school-appropriate solution processes. / 使用清晰、符合课堂习惯的解题过程。
- Reuse one content source across multiple gameplay modes. / 让同一内容源支持多种玩法。
- Connect feedback, progression, review, analytics, and replay. / 连接反馈、成长、复习、分析与重复游玩。
- Keep learning logic deterministic and testable. / 保持学习逻辑确定且可测试。

---

## My Role | 我的职责

- Educational Game Technical Design / 教育游戏技术设计
- Gameplay and System Design / 玩法与系统设计
- Mathematical Content Architecture / 数学内容架构
- UI/UX Design and Implementation / UI/UX 设计与实现
- Data-Driven Tool Development / 数据驱动工具开发
- Playtest Planning and Manual Validation / 试玩规划与人工验证
- Milestone Scope and Production Planning / 里程碑范围与制作规划
- Code Architecture and Refactoring / 代码架构与重构

AI-assisted development accelerated implementation and iteration. Feature direction, educational rules, milestone scope, manual playtesting, validation, and final design ownership remained human-directed.

项目使用 AI 辅助开发加速实现与迭代；功能方向、教育规则、里程碑范围、人工试玩、验证判断与最终设计决策均由开发者主导。

---

## Core Gameplay | 核心玩法

### 1. Step Ordering | 步骤排序

Drag complete solution steps into the correct order.
拖动完整解题步骤，将其排列为正确顺序。

### 2. Multiple-Choice Ordering | 选择式排序

Choose the correct next step from deterministic distractors.
从规则生成的干扰项中选择正确的下一步。

### 3. Fill in the Process | 过程填空

Complete missing values inside a generated solution process.
填写解题过程中的缺失数值。

All three interactions share expressions, generated steps, Skill Tags, scoring, Hints, and feedback.

三种玩法共用表达式、生成步骤、技能标签、计分、Hint 与反馈框架。

---

## Learning Loop | 学习循环

### Progressive Error Feedback | 渐进式错误反馈

| Attempt | Feedback | 尝试 | 反馈 |
| --- | --- | --- | --- |
| First | Generic retry | 第一次 | 通用重试 |
| Second | Directional feedback | 第二次 | 方向性反馈 |
| Third+ | Contextual rule explanation | 第三次及以后 | 对应规则解释 |

Players have time to self-correct before receiving explicit support. Player-requested Hints remain separate and limited.

玩家会先获得自主纠错机会，再逐步得到更多信息；主动请求的 Hint 是独立且有限的资源。

### Progression | 成长

- Question and Level scores / 题目与关卡分数
- One-to-three-star ratings / 一至三星评价
- Best-star Level Cards / 关卡卡片最高星级
- Limited Hints / 限量提示
- Completion and failure states / 完成与失败状态
- Versioned local save / 版本化本地存档

### Mistake Book | 错题本

Saved mistakes include the answer, explanation, source Level, Skill Tags, and complete correct process.

错题记录包含答案、讲解、来源关卡、技能标签与完整正确过程。

### Replay Modes | 重复游玩

- **Mistake Practice / 错题练习:** randomized saved mistakes
- **Zen Mode / 禅模式:** three-minute mixed practice
- **Survival Mode / 生存模式:** three lives, no time limit

---

## M1–M7 Development | M1–M7 开发历程

MathSmith was built through vertical milestones. Every milestone preserved a complete playable flow.

《数锻》采用纵向里程碑开发，每个里程碑都保留完整可玩的玩家流程。

| Milestone | English | 中文 |
| --- | --- | --- |
| **M1 — Core Prototype** | JSON content, Step Ordering, drag-and-drop, Check, Hint, Level progression | JSON 内容、步骤排序、拖拽、Check、Hint、关卡流程 |
| **M2 — Structure & UI** | Home, Lobby, Level Cards, multi-Level flow, unified UI, icons, SFX | Home、Lobby、关卡卡片、多关卡流程、统一 UI、图标与音效 |
| **M3 — Gameplay Expansion** | Multiple-Choice Ordering, Fill in the Process, Progressive Feedback, search, filters | 选择式排序、过程填空、渐进反馈、搜索与筛选 |
| **M4 — Learning Loop** | Scores, stars, limited Hints, save, localization, Mistake Book, Zen, Survival | 分数、星级、限量 Hint、存档、本地化、错题本、禅模式与生存模式 |
| **M5 — Learning Analytics** | Telemetry, History, Skill Mastery, behavior patterns, recommendations, adaptation | 行为遥测、历史、熟练度、行为模式、推荐与自适应 |
| **M6 — Content Authoring** | Teacher login, CSV import, validation, preview, visual editing, export | 教师登录、CSV 导入、验证、预览、可视化编辑与导出 |
| **M7 — Smart Tutor & Polish** | Contextual Tutor, Course-aware guidance, localization, UI polish, Splash Screen | 情境 Tutor、课程感知引导、本地化、UI 打磨与启动画面 |

---

## Analytics & Adaptive Learning | 学习分析与自适应

M5 records structured behavior without runtime generative AI:

M5 在不使用运行时生成式 AI 的情况下记录结构化行为：

- First-action and total solve time / 首次操作与总解题时间
- Drag, reorder, selection, input, Check, and Hint events / 拖拽、换位、选择、填写、Check 与 Hint 事件
- Incorrect attempts and completion outcome / 错误次数与完成结果
- Mode-specific metrics / 各玩法独立指标
- Player Question History / 玩家题目历史
- Progressive Skill Mastery / 渐进式技能熟练度
- Rule-based behavior patterns / 规则驱动行为模式
- Weak-Skill recommendations / 弱项学习推荐
- Weighted adaptive selection / 加权自适应选题
- Developer analytics overlay / 开发者分析面板

Mastery grows progressively instead of giving new players artificially high percentages from small samples.

熟练度采用渐进成长模型，避免新玩家因样本过少获得虚高数据。

---

## Teacher Content Pipeline | 教师内容创作流程

M6 allows teachers and content designers to create playable content without editing gameplay code.

M6 允许教师与内容设计者在不修改游戏代码的情况下创建可玩内容。

~~~text
Author → Validate → Preview → Play → Revise → Export
创作 → 验证 → 预览 → 试玩 → 修改 → 导出
~~~

### CSV Course Workspace | CSV 课程工作区

- Separate Level and Question rows / 分离关卡与题目数据
- Blocking Errors and non-blocking Warnings / 阻断错误与非阻断警告
- Safe import and replacement / 安全导入与替换
- Imported Course preview / 导入课程预览

### MathSmith Studio | 数锻工作室

- Create and edit Courses, Levels, and Questions / 创建与编辑课程、关卡和题目
- Duplicate, reorder, and delete content / 复制、排序与删除内容
- Normalize expression formatting / 自动规范表达式
- Accept x or * for multiplication / 乘法支持 x 或 *
- Live validation and generated solution preview / 实时验证与解题步骤预览
- Question and Level preview / 题目与关卡预览
- Validated CSV export / 导出已验证 CSV

Core Curriculum, Imported Course, and Studio Course maintain independent content and player records.

核心课程、导入课程与 Studio 课程拥有相互独立的内容及玩家记录。

> The Teacher Tool uses **teacher** as a visible demo password. It is not production authentication.
>
> Teacher Tool 使用 **teacher** 作为公开演示密码，不属于正式身份验证系统。

- [Authoring Guide / 创作指南](Authoring/README.md)
- [CSV Schema / CSV 结构](Authoring/SCHEMA.md)
- [Course Template / 课程模板](Authoring/MathSmith_Course_Template.csv)
- [Example Course / 示例课程](Authoring/MathSmith_Course_Example.csv)

---

## Guided Smart Tutor | 引导式智能导师

M7 connects existing deterministic systems through a floating, option-based Tutor.

M7 通过悬浮式选项 Tutor，将已有确定性学习系统连接为统一引导体验。

- Available across Home, Lobby, gameplay, summaries, Mistake Book, and Courses
  可在 Home、Lobby、游戏、结算、错题本与不同课程中使用
- Reads current Course, Level, Question, score, mistakes, History, and Mastery
  读取当前课程、关卡、题目、分数、错误、历史与熟练度
- Provides contextual explanations and navigation actions
  提供情境解释与导航操作
- Uses Course-scoped Core, Imported, or Studio data
  根据核心、导入或 Studio 课程使用对应数据
- Avoids revealing answers before the correct learning state
  避免在不合适的阶段提前泄露答案
- Supports English and Simplified Chinese / 支持英文与简体中文

The Tutor presents guidance from validated structured systems. It does not replace mathematical validation, adaptive weighting, saving, or progression.

Tutor 呈现已有结构化系统提供的引导，不替代数学验证、自适应权重、存档或成长系统。

- [Tutor Architecture / Tutor 架构](Docs/M7_Tutor_Architecture.md)
- [Manual Validation / 人工验证](Docs/M7_Tutor_Validation.md)

---

## Mathematical Content Pipeline | 数学内容管线

~~~text
Authored Expression
		↓
ExpressionParser
		↓
StepGenerator
		↓
Human-Readable Solution Process
		↓
Step Ordering | Multiple-Choice Ordering | Fill in the Process
~~~

The generator supports make-ten strategies, place-value decomposition, regrouping, partial products, division decomposition, parentheses, precedence, and multi-step reduction.

生成器支持凑十、数位分解、重新组合、部分积、除法拆分、括号、运算顺序与多步化简。

Rules avoid unnecessary + 0, single-value parentheses, filler steps, large reasoning jumps, and excessive mental calculation.

规则会避免不必要的 + 0、单个数字括号、填充步骤、过大的推理跳跃与单步中过量口算。

---

## Technical Architecture | 技术架构

~~~text
MathSmith/
├── Assets/                 Icons, logo, and SFX
├── Authoring/              CSV templates, examples, and schema
├── Data/                   Core curriculum JSON
├── Docs/                   Presentation, video, and Tutor documents
├── Localization/           English and Simplified Chinese
├── Scenes/                 Screens and reusable scenes
├── Scripts/
│   ├── Gameplay/           Sessions, progress, save, and game flow
│   ├── Learning/           Telemetry, History, Mastery, patterns, adaptation
│   ├── Math/               Parsing, Step generation, and distractors
│   ├── UIComponents/       Shared UI behavior
│   └── UIScreens/          Screen-level presentation
└── Themes/                 Shared visual styling
~~~

### Architecture Principles | 架构原则

- Content is the source of truth / 内容是唯一数据源
- Content and presentation are separated / 内容与表现分离
- Mathematical logic and UI are separated / 数学逻辑与 UI 分离
- Shared systems support multiple gameplay modes / 共用系统支持多种玩法
- Managers have focused responsibilities / Manager 按职责拆分
- Save data is versioned and migrated / 存档带版本并支持迁移
- Course data is isolated by source / 课程数据按来源隔离
- Replay does not overwrite structured progress / 重复游玩不覆盖标准进度
- Mathematical feedback is deterministic / 数学反馈保持确定性

---

## Key Design Finding | 核心设计发现

### Mathematically Correct Is Not Always Pedagogically Useful

### 数学正确不等于教学有效

Early solutions could reach the correct answer while containing unnatural decomposition, redundant transformations, excessive mental arithmetic, or reasoning jumps.

早期生成结果虽然答案正确，却可能包含不自然的拆分、冗余转换、过量口算或推理跳跃。

The goal changed from producing a target number of steps to producing the minimum number of meaningful, readable steps.

因此，生成目标从“达到指定步骤数量”调整为“生成最少且有意义、可读的解题步骤”。

~~~text
Plan → Build → Playtest → Observe → Classify → Fix Systemically → Validate
规划 → 实现 → 试玩 → 观察 → 分类 → 系统性修复 → 验证
~~~

---

## UI/UX | UI/UX

- Unified dark navy visual language / 统一黑蓝视觉风格
- Local Lucide SVG icons / 本地 Lucide SVG 图标
- Kenney UI sound effects / Kenney UI 音效
- Responsive 1920 × 1080 layout / 响应式布局
- Consistent cards, buttons, popups, and states / 统一卡片、按钮、弹窗与状态
- Distinct navigation actions / 跳转操作使用独立视觉标记
- English and Simplified Chinese UI / 英文与简体中文 UI
- Personal-logo Splash Screen / 个人 Logo 启动画面

---

## Save Data | 本地存档

MathSmith stores versioned player data at:

《数锻》将版本化玩家数据保存在：

~~~text
user://mathsmith_save.json
~~~

The Save stores settings, language, Course state, progress, scores, stars, mistakes, replay records, History, Mastery, and authored content.

存档包含设置、语言、课程状态、进度、分数、星级、错题、重复游玩记录、历史、熟练度与创作内容。

Interrupted Levels do not save partial progress. Teacher previews do not write player learning records.

中途退出的关卡不会保存部分进度；教师预览不会写入玩家学习记录。

---

## Running the Project | 运行项目

1. Install Godot 4.7.1 or a compatible Godot 4.x version. / 安装兼容的 Godot 4.x。
2. Clone this repository. / 克隆仓库。
3. Import **project.godot** in Godot Project Manager. / 导入 **project.godot**。
4. Run the project. The Splash Screen transitions to Home. / 运行项目，启动画面会进入 Home。

~~~bash
git clone https://github.com/YitongHuGpm20/MathSmith.git
~~~

### Controls | 操作

- **Mouse / 鼠标:** navigate, select, drag, and enter values
- **Check:** validate the current answer
- **Hint:** request limited assistance
- **Next:** advance after completion
- **Tutor Bubble / Tutor 泡泡:** open or close contextual guidance

---

## Credits | 致谢

- **Design & Development / 设计与开发:** Yitong Hu
- **Sound Effects / 音效:** [kenney.nl](https://kenney.nl/)
- **Icons / 图标:** [lucide.dev](https://lucide.dev/)
- **Engine / 引擎:** [Godot](https://godotengine.org/)

---

## License | 许可

MathSmith's software source code, Scenes, Themes, and project configuration are
open source under the [MIT License](LICENSE).

《数锻》的程序源代码、Scenes、Themes 与项目配置以
[MIT License](LICENSE) 正式开源。

Authored curriculum content, localization content, portfolio documents,
recordings, the MathSmith / 数锻 identity, and Yitong Hu's personal Logo are
excluded from the MIT License and remain Copyright (c) 2026 Yitong Hu. All
rights reserved.

原创课程内容、本地化内容、作品集文档、录屏、MathSmith / 数锻品牌及
Yitong Hu 的个人 Logo 不属于 MIT 授权范围，版权归 Yitong Hu 所有。

Lucide icons, Kenney audio, Godot Engine components, and other third-party
materials remain subject to their original licenses. See
[Third-Party Notices](THIRD_PARTY_NOTICES.md) for details.

Lucide 图标、Kenney 音效、Godot Engine 组件及其他第三方资源继续遵循其
原始许可证，详情见[第三方声明](THIRD_PARTY_NOTICES.md)。
