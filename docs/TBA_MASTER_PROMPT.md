# MASTER PROJECT PROMPT — TRILLION BYTES ACADEMY

**Project Name:** Trillion Bytes Academy (TBA)

**Architecture in one line:** Flutter client → REST/JSON API (Go) → MariaDB. No GraphQL. No other datastore.

## Vision

Build a unified, scalable educational platform for the Indian education system where students, competitive exam aspirants, college students, job seekers, and IT professionals can prepare for exams, learn new skills, practice daily, access educational materials, and track their learning progress.

The platform should become a daily learning companion for Indian students.

Core motto: **Learn Every Day. Practice Every Day. Improve Every Day.**

---

## 1. Target Audience

Build the platform for the entire Indian education and career ecosystem.

### School Education
- Class 1 to Class 12
- CBSE, ICSE, State Boards (including Tamil Nadu State Board and other Indian state boards)
- 10th and 12th public examinations
- NCERT syllabus
- Subject-wise learning, chapter-wise notes
- Previous-year examination papers, practice questions, model examinations

### Competitive Government Exams

**UPSC** — Civil Services, IAS, IPS, IFS, Prelims, Mains, Optional subjects, Current affairs, General Studies

**TNPSC** — Group 1, Group 2, Group 2A, Group 4, VAO / relevant recruitment, Tamil eligibility tests, General Tamil, General Studies, Aptitude, Current affairs, Previous-year questions

**SSC** — CGL, CHSL, MTS, GD, CPO

**Banking** — IBPS PO, IBPS Clerk, SBI PO, SBI Clerk, RBI exams, Banking aptitude, Reasoning, Quantitative aptitude, English

**Railway** — RRB NTPC, RRB Group D, ALP, other Railway recruitment examinations

**Defence** — NDA, CDS, AFCAT, Agniveer, other eligible defence examinations

**Other** — State government exams, Police recruitment, Teaching eligibility exams (CTET, TET), NEET, JEE, CUET, GATE, CAT, CLAT, other entrance examinations

The system must be flexible enough to add new exams, categories, subjects, and syllabus structures **without changing the application's core code** (all catalog data is rows in MariaDB, managed from the admin panel).

---

## 2. Professional Courses

**CMA** — Foundation, Intermediate, Final; subject-wise preparation, syllabus tracking, revision plans, MCQs, practice problems, mock tests, previous examination papers, formula notes, accounting practice, exam preparation tracker

**CA** — Foundation, Intermediate, Final

**CS** — CSEET, CS Executive, CS Professional

**Other** — ACCA, CFA, CPA, MBA entrance, financial certifications, Accounting, Taxation, GST, Finance, Auditing

---

## 3. Engineering and College Education

**Branches:** Computer Science Engineering, Information Technology, AI & Data Science, AI & Machine Learning, Electronics and Communication, Electrical, Mechanical, Civil, Chemical, other branches.

**Features:** University syllabus, semester-wise subjects, unit-wise topics, notes, PDF materials, question banks, previous-year university questions, lab preparation, viva questions, assignments, MCQs, short/long-answer questions, important questions, revision materials.

Support different Indian universities and curriculum versions through configurable **university → regulation → semester → subject** data.

---

## 4. IT, Software Development and Technology Academy

**Programming:** C, C++, Java, Python, JavaScript, TypeScript, Go, Rust, PHP, Dart

**Frontend:** HTML, CSS, JavaScript, React, Vue, Angular, Next.js, Flutter Web, UI/UX, Responsive design

**Backend:** Node.js, Go, Python, Java Spring Boot, .NET, REST API design, WebSockets, Authentication, Microservices

**Mobile:** Flutter, Android, iOS, React Native

**Database:** SQL, MySQL, MariaDB, PostgreSQL, MongoDB, Redis, Database design, Query optimization
*(These are teaching topics only. The TBA platform itself runs on MariaDB alone.)*

**Cloud and DevOps:** AWS, Azure, Google Cloud, Docker, Kubernetes, Linux, CI/CD, Git, GitHub, Networking, Deployment

**Cybersecurity:** Networking fundamentals, Security fundamentals, Ethical cybersecurity education, Linux security, Web security, OWASP, Defensive security, Security certifications

---

## 5. AI Academy

**Topics:** AI fundamentals, Machine Learning, Deep Learning, Neural Networks, NLP, Computer Vision, Generative AI, Large Language Models, RAG, AI Agents, Prompt Engineering, AI Automation, Local AI, Ollama, AI API integration, AI application development

**Practical courses:** Build an AI chatbot, AI resume analyzer, AI job search assistant, RAG applications, AI agents; integrate AI into Flutter and Go applications; create AI automation workflows; build AI SaaS products.

Levels: Beginner, Intermediate, Advanced. Provide practical projects, exercises, quizzes, code examples, and learning milestones.

---

## 6. Main App Concept — Daily Preparation

The main screen must **not** look like a traditional content library. It is a personalized daily preparation dashboard.

After registration, the user selects: education level, course, exam, board, university, subject, career goal, preferred language, daily available study time, exam date (optional), skill level. Generate a personalized learning plan.

**Daily Dashboard shows:** today's study plan, daily question challenge, recommended lesson, revision reminder, current streak, daily study target, completed topics, remaining tasks, upcoming examination, daily quiz, weak subjects, progress percentage, weekly learning statistics.

Example:

> Today's preparation
> 1. Study Polity — 30 minutes
> 2. Learn 20 new questions — 20 minutes
> 3. Revise yesterday's topics — 15 minutes
> 4. Complete daily mock test — 15 minutes

Users can modify daily goals according to their available time.

---

## 7. Question Bank System

Hierarchy: **Education Category → Exam → Board/University → Subject → Topic → Chapter → Year → Question**

**Question types:** MCQ, single correct, multiple correct, True/False, fill in the blanks, match the following, numerical, short answer, long answer, coding, interview, essay.

**Every question supports:** text, image, attachment, options, correct answer, detailed explanation, subject, topic, chapter, difficulty, exam name, exam year, source, language, tags, verified status.

**Practice modes:** topic-wise, chapter-wise, subject-wise, exam-wise, year-wise, random, difficult, previously incorrect, bookmarked.

---

## 8. Previous-Year Question Papers

Collections for TNPSC, UPSC, SSC, Banking, Railway, State government exams, NEET, JEE, GATE, Board examinations, Engineering university examinations, CMA, CA, and others.

Organize by **Exam → Year → Paper → Subject → Questions**.

**Features:** download PDF where legally available, view papers in-app, interactive practice, timed exam mode, answer keys, explanations, score calculation, mistake review, bookmarks.

Build the content-import system to support PDFs, documents, spreadsheets, images, and manually entered questions.

Where legally permissible, use publicly released examination papers and official sources. Respect copyrights and terms of use. Do not scrape copyrighted books or proprietary coaching materials without permission.

**Never falsely label generated questions as previous-year questions.** Every question carries exactly one origin label:
1. Official Previous-Year Questions
2. Verified Previous-Year Questions
3. Model Questions
4. AI-Generated Practice Questions
5. Admin-Created Questions

---

## 9. PDF Learning Library

**Categories:** Syllabus, Textbooks, Notes, Study materials, Previous-year papers, Model papers, Formula sheets, Revision notes, Government notifications, IT documentation, Course materials.

**Features:** PDF reader, bookmark pages, offline download, search, highlight, personal notes, text extraction where supported, document categorization, admin upload, access control, user-uploaded documents.

Users can upload their own PDF and optionally use AI to generate summaries, notes, flashcards, MCQs, Q&A sets, important topics, and chapter-wise explanations. AI answers must be grounded in the uploaded document and clearly flag uncertainty.

---

## 10. AI Learning Assistant

Available throughout the app. Capabilities: explain concepts, answer educational questions, explain MCQ answers, summarize PDFs, generate notes / flashcards / practice questions, create daily schedules and revision plans, explain and debug educational code, analyze weak topics, suggest next topics.

The assistant respects the user's selected course and level (TNPSC Group 4 → Tamil Nadu exam-focused; CMA → accounting and professional-exam-focused; Class 10 → school-level, not university-level).

**Provider-agnostic:** configurable OpenAI-compatible APIs, other commercial providers, local LLMs, Ollama, and any configurable endpoint/model. Never hardcode one provider. Provide AI usage limits, credits, cost tracking, and subscription restrictions (stored in MariaDB).

---

## 11. Quiz and Mock Examination System

Timed exams, untimed practice, configurable negative marking, exam-specific marking schemes, random selection, navigation, answer saving, submit, automatic scoring, detailed results, answer review, ranking where appropriate, difficulty-based and topic-based tests, daily quizzes, weekly challenges.

**Results dashboard:** total score, correct / incorrect / unanswered, accuracy %, time spent, subject and topic performance, weak areas, improvement over previous tests. Exam configurations are fully customizable.

---

## 12. Progress Tracking

Track daily / weekly / monthly study time, topics completed, syllabus completion, quiz scores, accuracy, streak, revision activity, exam performance, weak subjects, learning progress. Provide charts and insights such as:

- "You improved your accuracy in General Science from 52% to 71% this week."
- "Your weakest topic is Indian Constitution — Fundamental Rights."
- "Complete 25 questions today to achieve your weekly goal."

**All insights are computed from real user activity (SQL aggregates). No fake motivational statistics.**

---

## 13. Revision System

Spaced repetition scheduled from learning date, previous score, question difficulty, user confidence, incorrect answers, and revision history. Intervals are configurable.

Provide: today's revision list, due revision topics, flashcard review, incorrect-question revision, weak-topic revision. Users mark concepts as Easy / Medium / Difficult / Need revision.

---

## 14. Languages

Initial: English, Tamil, Telugu, Hindi. Architecture supports more Indian languages later.

Separate settings for app UI language, course language, question language, explanation language. Support language-specific questions and translations. Do not assume all subjects have translated content.

---

## 15. Gamification

Useful and non-distracting: daily streak, study points, XP, badges, achievements, daily and weekly challenges, course completion achievements, study milestones. Examples: 7-Day Streak, 100 Questions Completed, First Mock Test, 100 Hours of Learning, Complete a Full Subject.

No addictive design or meaningless notifications. Prioritize real educational progress.

---

## 16. Notifications

User-configurable: daily study reminders, revision reminders, exam countdown alerts, daily quiz, course updates, new study material, weekly progress reports. Custom schedules; users can disable all notifications.

---

## 17. Admin Panel

Web-based admin dashboard. Roles: Super Admin, Content Admin, Course Admin, Question Admin, Moderator.

**Course management:** categories, exams, boards, universities, courses, subjects, chapters, topics, syllabus configuration.

**Question management:** add, bulk import (CSV, Excel, PDF, question papers), edit answers, add explanations, categorize, mark verified, detect duplicates.

**PDF management:** upload, categorize, manage access, update, delete outdated, copyright/source info.

**User management:** users, subscriptions, reports, progress where appropriate, block abusive users.

**Analytics:** registered / active / daily active users, enrollments, quiz attempts, question usage, revenue, subscription stats, popular courses, content gaps.

---

## 18. Content Import and Automation

**Sources:** manual entry, CSV, Excel, JSON, PDF, OCR documents, images, official/public examination papers, authorized content providers.

**Workflow:** upload → identify document type → extract text → detect subject → detect chapters → extract questions → extract options → extract answers where available → generate explanations if requested → detect duplicates → review → approve → publish.

Runs as background jobs from a MariaDB-backed job table. AI must not auto-publish unverified answers for high-stakes exam content. Track source metadata for every imported question.

---

## 19. Subscription and Monetization

**Free:** basic syllabus tracking, limited daily questions, limited courses, daily quiz, basic progress dashboard, selected free PDFs.

**Premium:** unlimited practice within fair use, full question banks, mock exams, advanced analytics, AI assistant, PDF AI analysis, revision system, personalized plans, premium materials, offline access.

**One-time purchases:** exam preparation packs, courses, premium materials, mock test packages.

**Institutional (future):** schools, colleges, coaching institutes, training centers, corporate IT training.

Subscription plans, prices, limits and entitlements are configuration rows. **Do not hardcode prices.**

---

## 20. Technology Stack

**Frontend — Flutter** for Android, iOS, Web, and responsive desktop web. Reusable UI components, one consistent design system. The API client is generated from the OpenAPI spec.

**Backend — Go (Golang)**, modular monolith (packages: auth, users, catalog, questions, exams, progress, revision, documents, ai, billing, admin, jobs).

**API — REST/JSON only. GraphQL is not used anywhere.**
- Versioned under `/api/v1`, documented with an OpenAPI 3 spec (source of truth for client generation and request validation).
- Cursor or page-based pagination; `?fields=` and `?include=` parameters for low-bandwidth clients.
- Consistent error envelope; idempotency keys for payment and submit endpoints.
- File uploads (multipart), downloads (signed URLs), auth callbacks, webhooks and `/healthz` are ordinary REST endpoints.
- Real-time needs (e.g. exam timers) are handled client-side with server-validated deadlines; polling or SSE if ever needed.

**Database — MariaDB 10.6+ is the only datastore.** No Redis, PostgreSQL, MongoDB or other store in the platform.
- `database/sql` with `sqlc` (or `sqlx`); parameterized/prepared statements only.
- Versioned SQL migrations (`golang-migrate` or `goose`).
- InnoDB, utf8mb4, foreign keys and indexes on all relationships.
- `JSON` columns for flexible per-exam config and marking schemes; `FULLTEXT` indexes for search.
- MariaDB replaces cache/queue infrastructure:
  - Refresh tokens: hashed, rotated, in a table.
  - Rate limiting: in-process limiter, plus per-user quota tables (e.g. AI usage).
  - Background jobs: a `jobs` table using `SELECT … FOR UPDATE SKIP LOCKED`.
  - Caching: small in-memory TTL cache inside the Go process for hot read-only catalog data.
  - Leaderboards / analytics: SQL aggregates, with summary tables refreshed by jobs where needed.

**Storage — abstracted interface** with local disk (dev), VPS disk, and S3-compatible object storage (AWS S3 optional later). Only metadata and keys are stored in MariaDB. Files are served via authenticated or short-lived signed URLs, never unrestricted public URLs.

**Authentication:** email/password (argon2id or bcrypt), OTP where configured, Google login, short-lived JWT access token, rotating refresh token, role-based access control as middleware.

**Deployment:** VPS, Docker, Docker Compose (`app`, `mariadb`, `nginx`), Nginx reverse proxy, HTTPS, environment-based config, automated `mariadb-dump` backups, structured logging, health monitoring. Must run on a low-cost VPS and scale to cloud later.

---

## 21. Database Architecture (MariaDB)

Design modular, normalized tables with foreign keys and indexes for:

- Users, user profiles, roles, permissions, refresh tokens
- Education categories, boards, universities, regulations, exams, exam versions
- Courses, syllabus (versioned), subjects, chapters, topics, lessons, course enrollment
- Questions, question options, answers, explanations, question tags, question sources, question translations
- Previous-year papers
- Documents, PDF library, file objects, user bookmarks, user notes
- Study sessions, study plans, daily tasks
- Quiz attempts, exam attempts, exam results
- Revision schedules, flashcards, user progress
- Achievements, notifications
- Subscription plans, subscriptions, payments
- AI providers, AI usage
- Content reports, content import jobs, generic background `jobs`
- Rate-limit / quota counters
- Admin audit logs

Support content versioning where the syllabus changes over time (e.g. `syllabus_version_id` on subjects/topics and `effective_from` / `effective_to`).

---

## 22. Application UI

Clean, minimal, fast, student-friendly, modern, accessible, responsive, low-bandwidth friendly. Avoid cluttering the dashboard.

**Main navigation:**
1. **Home** — greeting, daily plan, streak, continue learning, daily quiz, upcoming exam, progress summary
2. **Explore** — School, Competitive exams, Professional courses, Engineering, IT, AI, Programming, Skill development
3. **Practice** — Question bank, daily challenge, mock tests, PYQs, weak topics, revision
4. **My Learning** — enrolled courses, progress, notes, bookmarks, PDFs, study history
5. **Profile** — education profile, goal, language, study time, notifications, subscription, settings

---

## 23. Security and Privacy

Secure password hashing; JWT security; refresh-token rotation; authorization (RBAC); rate limiting; request validation against the OpenAPI schema; file type/size validation and upload limits; secure file access; SQL injection protection (prepared statements only); audit logs; backup and restore procedures; privacy policy; terms and conditions; user data export; account deletion.

Educational documents are never exposed through unrestricted public URLs unless intentionally public.

---

## 24. MVP Development Strategy

Do not populate every exam and course at launch. Build a scalable platform and release progressively.

> Note: the original prompt was cut off inside Phase 1. The Phase 1 list below is completed from the rest of the spec; adjust as needed.

### Phase 1 — Academy Core (MVP)
- Registration/login (email/password, JWT + refresh rotation)
- Education profile and exam/course selection
- Personalized dashboard and daily study plan
- Course hierarchy and syllabus tracker
- Question bank and MCQ practice
- Quiz scoring
- Progress tracking
- Basic admin panel: catalog, question entry, CSV import
- Docker Compose deployment with MariaDB, backups, health check

### Phase 2 — Exams and Revision
- Mock examination engine (timed, negative marking)
- PYQ section with origin labels
- Spaced-repetition revision and flashcards
- Streaks, XP, achievements
- Notifications
- Freemium subscription system

### Phase 3 — Library and AI
- PDF library, reader, notes, offline download
- Content-import pipeline (PDF/OCR/Excel, duplicate detection, review queue)
- AI assistant with configurable providers, usage limits, cost tracking
- PDF AI features (summaries, flashcards, MCQs)

### Phase 4 — Expansion
- Multilingual content (Tamil, Telugu, Hindi)
- IT Academy and AI Academy course content
- Engineering university content
- Advanced analytics, course purchases, institutional accounts
