// Structured CMA Intermediate Group 1 syllabus seed data.
//
// Kept entirely separate from UI and database code so it can be revised
// without touching application logic. Consumed once by SeedRepository.

class SeedTopic {
  const SeedTopic(this.title);
  final String title;
}

class SeedChapter {
  const SeedChapter(this.title, this.topics);
  final String title;
  final List<String> topics;
}

class SeedSubject {
  const SeedSubject({
    required this.code,
    required this.title,
    required this.paperNumber,
    required this.chapters,
  });

  final String code;
  final String title;
  final int paperNumber;
  final List<SeedChapter> chapters;
}

/// Full Group 1 syllabus. Papers 5-8.
const List<SeedSubject> kSyllabus = [
  SeedSubject(
    code: 'P5',
    title: 'Business Laws and Ethics',
    paperNumber: 5,
    chapters: [
      SeedChapter('Indian Contract Act, 1872', [
        'Essential elements of a valid contract',
        'Offer and acceptance',
        'Consideration',
        'Capacity to contract',
        'Free consent',
        'Void and voidable agreements',
        'Performance of contract',
        'Discharge of contract',
        'Breach of contract and remedies',
        'Quasi contracts',
        'Contingent contracts',
        'Indemnity and guarantee',
        'Bailment and pledge',
        'Agency',
      ]),
      SeedChapter('Sale of Goods Act, 1930', [
        'Contract of sale and agreement to sell',
        'Conditions and warranties',
        'Transfer of ownership and delivery',
        'Rights of an unpaid seller',
        'Auction sales',
      ]),
      SeedChapter('Negotiable Instruments Act, 1881', [
        'Definition and characteristics',
        'Promissory note, bill of exchange and cheque',
        'Holder and holder in due course',
        'Negotiation and endorsement',
        'Dishonour and noting/protest',
        'Presumptions and penalties (Section 138)',
      ]),
      SeedChapter('Companies Act, 2013', [
        'Types of companies',
        'Incorporation and MOA/AOA',
        'Prospectus and share capital',
        'Members and shareholders',
        'Directors and board meetings',
        'General meetings and resolutions',
        'Accounts and audit',
        'Winding up (overview)',
      ]),
      SeedChapter('Limited Liability Partnership Act, 2008', [
        'Nature and characteristics of LLP',
        'Incorporation of LLP',
        'Partners and their relations',
        'Extent and limitation of liability',
        'Conversion and winding up',
      ]),
      SeedChapter('Factories Act, 1948', [
        'Objectives and definitions',
        'Health, safety and welfare provisions',
        'Working hours of adults',
        'Employment of young persons and women',
        'Annual leave with wages',
      ]),
      SeedChapter('Payment of Gratuity Act, 1972', [
        'Applicability and definitions',
        'Eligibility and calculation of gratuity',
        'Forfeiture and nomination',
        'Recovery and penalties',
      ]),
      SeedChapter('Payment of Bonus Act, 1965', [
        'Applicability and eligibility',
        'Computation of gross profit and available surplus',
        'Minimum and maximum bonus',
        'Set-on and set-off of allocable surplus',
      ]),
      SeedChapter("Employees' Provident Funds and Misc. Provisions Act, 1952", [
        'Applicability and definitions',
        'Schemes under the Act',
        'Contributions and administration',
        'Penalties and offences',
      ]),
      SeedChapter('Code on Wages, 2019', [
        'Objective and coverage',
        'Minimum wages',
        'Payment of wages',
        'Payment of bonus provisions',
        'Advisory boards and inspector-cum-facilitator',
      ]),
      SeedChapter('Code on Social Security, 2020', [
        'Objective and coverage',
        'Social security organisations',
        'Gratuity, EPF and ESI provisions',
        'Maternity benefit and employee compensation',
        'Offences and penalties',
      ]),
      SeedChapter('Business Ethics', [
        'Meaning and scope of business ethics',
        'Ethics vs law vs morality',
        'Ethical dilemmas in business',
        'Values and norms',
      ]),
      SeedChapter('Ethical Principles', [
        'Utilitarianism',
        'Rights and duties',
        'Justice and fairness',
        'Virtue ethics',
      ]),
      SeedChapter('Corporate Governance', [
        'Concept and need for corporate governance',
        'Board structure and committees',
        'SEBI LODR requirements (overview)',
        'Stakeholder rights and disclosures',
      ]),
      SeedChapter('Corporate Social Responsibility', [
        'CSR concept and rationale',
        'Section 135 and CSR Rules',
        'CSR committee and reporting',
        'Permitted CSR activities',
      ]),
      SeedChapter('Ethical Decision Making', [
        'Framework for ethical decision making',
        'Role of professional codes of conduct',
        'Whistle-blowing',
        'Case studies',
      ]),
    ],
  ),
  SeedSubject(
    code: 'P6',
    title: 'Financial Accounting',
    paperNumber: 6,
    chapters: [
      SeedChapter('Accounting Fundamentals', [
        'Accounting concepts and conventions',
        'Double entry system',
        'Journal, ledger and trial balance',
        'Rectification of errors',
        'Bank reconciliation statement',
        'Depreciation accounting',
      ]),
      SeedChapter('Accounting Standards', [
        'AS 1 Disclosure of accounting policies',
        'AS 2 Valuation of inventories',
        'AS 9 Revenue recognition',
        'AS 10 Property, plant and equipment',
        'AS 11 Effects of changes in foreign exchange rates',
        'AS 12 Accounting for government grants',
      ]),
      SeedChapter('Financial Statements', [
        'Preparation of final accounts of sole traders',
        'Adjustments and closing entries',
        'Not-for-profit organisations',
        'Manufacturing accounts',
      ]),
      SeedChapter('Cash Flow Statement', [
        'Concept as per AS 3',
        'Operating activities',
        'Investing activities',
        'Financing activities',
      ]),
      SeedChapter('Consignment', [
        'Basic concepts and terminology',
        'Valuation of unsold stock',
        'Normal and abnormal loss',
        'Account sales and commission',
      ]),
      SeedChapter('Joint Ventures', [
        'Features of joint venture',
        'Separate set of books method',
        'Records in books of co-venturers',
        'Memorandum joint venture account',
      ]),
      SeedChapter('Branch Accounts', [
        'Dependent branch – debtors system',
        'Stock and debtors system',
        'Independent branch',
        'Foreign branch',
      ]),
      SeedChapter('Hire Purchase and Installment System', [
        'Hire purchase – calculation of interest',
        'Default and repossession',
        'Installment payment system',
        'Difference between the two systems',
      ]),
      SeedChapter('Bills of Exchange', [
        'Trade and accommodation bills',
        'Discounting, endorsement and dishonour',
        'Renewal of bills',
        'Insolvency of acceptor',
      ]),
      SeedChapter('Partnership Accounts', [
        'Admission of a partner',
        'Retirement and death of a partner',
        'Goodwill valuation',
        'Dissolution of firm and Garner v Murray',
        'Piecemeal distribution',
      ]),
      SeedChapter('Company Accounts', [
        'Issue of shares and forfeiture',
        'Issue and redemption of debentures',
        'Redemption of preference shares',
        'Buy-back of shares',
        'Profit prior to incorporation',
      ]),
      SeedChapter('Amalgamation and Internal Reconstruction', [
        'Amalgamation in the nature of merger and purchase',
        'Purchase consideration',
        'Accounting as per AS 14',
        'Internal reconstruction and capital reduction',
      ]),
      SeedChapter('Banking Company Accounts', [
        'Form and content of financial statements',
        'Rebate on bills discounted',
        'Non-performing assets and provisioning',
      ]),
      SeedChapter('Insurance Company Accounts', [
        'Life insurance – revenue account and balance sheet',
        'General insurance – revenue account',
        'Reserve for unexpired risk',
      ]),
    ],
  ),
  SeedSubject(
    code: 'P7',
    title: 'Direct and Indirect Taxation',
    paperNumber: 7,
    chapters: [
      SeedChapter('Direct Tax – Basic Concepts', [
        'Definitions and charge of income tax',
        'Assessment year and previous year',
        'Rates of tax and surcharge',
      ]),
      SeedChapter('Residential Status', [
        'Residential status of individuals',
        'Residential status of other persons',
        'Scope of total income / incidence of tax',
      ]),
      SeedChapter('Income from Salary', [
        'Basis of charge and allowances',
        'Perquisites and their valuation',
        'Retirement benefits',
        'Deductions from salary',
      ]),
      SeedChapter('Income from House Property', [
        'Annual value determination',
        'Deductions under section 24',
        'Self-occupied and let-out property',
        'Co-ownership and unrealised rent',
      ]),
      SeedChapter('Profits and Gains of Business or Profession', [
        'Admissible and inadmissible expenses',
        'Depreciation under the Income Tax Act',
        'Presumptive taxation',
        'Maintenance of books and audit',
      ]),
      SeedChapter('Capital Gains', [
        'Types of capital assets and transfer',
        'Computation of short and long term gains',
        'Indexation and exemptions (54 series)',
      ]),
      SeedChapter('Income from Other Sources', [
        'Chargeability and specific incomes',
        'Dividend and interest',
        'Gifts and deemed incomes',
      ]),
      SeedChapter('Clubbing, Set-off and Carry Forward', [
        'Clubbing of income',
        'Set-off within and across heads',
        'Carry forward of losses',
      ]),
      SeedChapter('Deductions and Total Income', [
        'Deductions under Chapter VI-A',
        'Computation of gross total income',
        'Computation of total income',
      ]),
      SeedChapter('Tax Liability, TDS and Returns', [
        'Computation of tax liability and rebate 87A',
        'TDS and TCS provisions',
        'Advance tax and interest 234A/B/C',
        'Return filing and due dates',
        'Tax planning vs avoidance vs evasion',
      ]),
      SeedChapter('Indirect Tax – GST Basics', [
        'Concept of GST and its features',
        'Constitutional framework',
        'GST Council and structure (CGST/SGST/IGST)',
      ]),
      SeedChapter('Supply under GST', [
        'Meaning and scope of supply',
        'Composite and mixed supply',
        'Schedule I, II and III',
      ]),
      SeedChapter('Levy, Time and Place of Supply', [
        'Levy and collection / composition scheme',
        'Reverse charge mechanism',
        'Time of supply of goods and services',
        'Place of supply of goods and services',
      ]),
      SeedChapter('Input Tax Credit', [
        'Eligibility and conditions for ITC',
        'Blocked credits (section 17(5))',
        'Apportionment and reversal of credit',
        'ITC on capital goods',
      ]),
      SeedChapter('Registration, Invoice and E-Way Bill', [
        'Persons liable for registration',
        'Procedure and amendment / cancellation',
        'Tax invoice, debit and credit notes',
        'E-way bill provisions',
      ]),
      SeedChapter('Payment, Returns and Assessment', [
        'Payment of tax and electronic ledgers',
        'GST returns and due dates',
        'Assessment types',
        'Audit under GST',
        'Refund under GST',
      ]),
      SeedChapter('Customs Basics', [
        'Types of customs duties',
        'Taxable event and valuation',
        'Import and export procedures (overview)',
      ]),
    ],
  ),
  SeedSubject(
    code: 'P8',
    title: 'Cost Accounting',
    paperNumber: 8,
    chapters: [
      SeedChapter('Introduction to Cost Accounting', [
        'Meaning, objectives and scope',
        'Cost accounting vs financial accounting',
        'Cost accounting standards (overview)',
        'Installation of a costing system',
      ]),
      SeedChapter('Cost Concepts and Classification', [
        'Elements of cost',
        'Classification by nature, function and behaviour',
        'Cost objects, cost units and cost centres',
      ]),
      SeedChapter('Material Cost', [
        'Purchase and store keeping',
        'Inventory control – EOQ and stock levels',
        'Pricing of material issues (FIFO, LIFO, weighted average)',
        'Material losses – waste, scrap, spoilage, defectives',
      ]),
      SeedChapter('Labour Cost', [
        'Time keeping and time booking',
        'Remuneration and incentive schemes',
        'Labour turnover',
        'Idle time and overtime',
      ]),
      SeedChapter('Overheads', [
        'Classification and codification',
        'Allocation, apportionment and absorption',
        'Machine hour rate',
        'Under and over absorption of overheads',
      ]),
      SeedChapter('Cost Sheet', [
        'Format and preparation of cost sheet',
        'Treatment of stocks',
        'Tenders and quotations',
      ]),
      SeedChapter('Job and Batch Costing', [
        'Job costing procedure',
        'Batch costing and economic batch quantity',
      ]),
      SeedChapter('Contract Costing', [
        'Features and terminology',
        'Profit on incomplete contracts',
        'Work certified and work uncertified',
        'Cost plus and escalation clause',
      ]),
      SeedChapter('Process Costing', [
        'Features and normal / abnormal loss and gain',
        'Equivalent production',
        'Inter-process profit',
      ]),
      SeedChapter('Joint Products and By-products', [
        'Apportionment of joint costs',
        'Treatment of by-products',
      ]),
      SeedChapter('Service Costing', [
        'Transport costing',
        'Hospital and hotel costing',
        'Power house costing',
      ]),
      SeedChapter('Marginal Costing', [
        'Marginal cost and contribution',
        'Cost-volume-profit analysis and break-even',
        'Decision making applications',
      ]),
      SeedChapter('Standard Costing and Variance Analysis', [
        'Setting of standards',
        'Material and labour variances',
        'Overhead variances',
        'Sales variances',
      ]),
      SeedChapter('Budgetary Control', [
        'Types of budgets',
        'Fixed and flexible budgets',
        'Zero-base budgeting',
        'Cash budget',
      ]),
      SeedChapter('Activity Based Costing and Cost Management', [
        'ABC concepts and cost drivers',
        'ABC vs traditional costing',
        'Cost reduction and cost control',
        'Target costing and life cycle costing',
      ]),
    ],
  ),
];

/// Master list of achievement definitions (code -> title/description).
class SeedAchievement {
  const SeedAchievement(this.code, this.title, this.description);
  final String code;
  final String title;
  final String description;
}

const List<SeedAchievement> kAchievements = [
  SeedAchievement('seven_day_warrior', '7 Day Warrior', 'Study every day for 7 days in a row.'),
  SeedAchievement('thirty_day_warrior', '30 Day Warrior', 'Maintain a 30-day study streak.'),
  SeedAchievement('target_master', 'Target Master', 'Hit your daily target on 20 days.'),
  SeedAchievement('time_master', 'Time Master', 'Log 100 hours of study time.'),
  SeedAchievement('subject_champion', 'Subject Champion', 'Complete every topic in a subject.'),
  SeedAchievement('hundred_topics', '100 Topics', 'Mark 100 topics as completed.'),
  SeedAchievement('hundred_hours', '100 Hours', 'Accumulate 100 hours of sessions.'),
  SeedAchievement('monthly_champion', 'Monthly Champion', 'Meet your monthly target.'),
  SeedAchievement('consistency_king', 'Consistency King', 'Study on 25 days within a month.'),
  SeedAchievement('cma_warrior', 'CMA Warrior', 'Log 300 hours across all subjects.'),
];
