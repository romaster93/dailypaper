//  SampleData.swift
//  Exact content transcribed from the handoff prototype (data-dc-script + spec).
//  In a production app these come from a paper-source API (arXiv / Semantic Scholar)
//  and an on-demand translation API — here they are bundled fixtures.

import Foundation

enum SampleData {

    static let allInterests = [
        "머신러닝", "자연어처리", "컴퓨터비전", "HCI",
        "강화학습", "그래프 학습", "로보틱스", "생성모델",
        "정보검색", "음성·오디오", "추천시스템", "최적화"
    ]

    static let defaultInterests: Set<String> = ["자연어처리", "HCI", "생성모델"]

    static let feedFilters = ["전체", "자연어처리", "생성모델", "HCI"]

    // MARK: Feed papers

    static let feed: [Paper] = [
        Paper(
            id: "rag-grounded-consistency",
            venue: "ACL 2026",
            venueDetail: "ACL 2026 · LONG PAPER",
            matchScore: 96,
            filterCategory: "자연어처리",
            feedTitle: "Grounded Consistency in RAG: Decoding for Citation Faithfulness",
            authorsShort: "J. Kim, R. Alvarez +3",
            feedAbstract: "We optimize consistency between generated text and evidence documents directly at decoding time, cutting citation errors by 42% across four QA benchmarks.",
            tags: ["#검색증강", "#LLM"],
            detailTitleEN: "Grounded Consistency in Retrieval-Augmented Generation: Decoding for Higher Citation Faithfulness",
            detailTitleKO: "검색 증강 생성의 근거 정합성: 인용 신뢰도를 높이는 디코딩",
            authorsEN: "Jiwon Kim, Rafael Alvarez, Mei Chen, +2 others",
            authorsKO: "김지원, 라파엘 알바레즈, 메이 첸 외 2명",
            abstractEN: "We propose a method that directly optimizes the consistency between model-generated sentences and their supporting documents at the decoding stage. By estimating in real time how well each token is grounded in the evidence, we penalize poorly-supported candidates. Across four QA benchmarks, our approach reduces citation errors by 42% on average while preserving answer quality.",
            abstractKO: "대규모 언어모델이 생성한 문장과 근거 문서 간의 정합성을 디코딩 단계에서 직접 최적화하는 방법을 제안한다. 각 토큰이 근거 문서에 얼마나 뒷받침되는지를 실시간으로 추정해, 정합성이 낮은 후보에 페널티를 부여한다. 네 개의 QA 벤치마크에서 인용 오류를 평균 42% 줄이면서도 응답 품질은 유지했다.",
            detailTags: ["#검색증강", "#LLM", "#인용신뢰도", "#디코딩"],
            year: "2026",
            citations: 14,
            readMinutes: 12,
            reason: LocalizedString("회원님이 저장한 **‘RAG 인용 신뢰도’** 논문과 방법론이 유사하고, 자주 읽는 ACL 계열이에요.", "Similar in method to **“RAG citation faithfulness,”** a paper you saved — and from ACL, which you read often.")
        ),
        Paper(
            id: "reading-flows",
            venue: "CHI 2026",
            venueDetail: "CHI 2026 · FULL PAPER",
            matchScore: 92,
            filterCategory: "HCI",
            feedTitle: "Reading Flows for Researchers: How Peripheral Summaries Shape Comprehension",
            authorsShort: "S. Lee, M. Chen +2",
            feedAbstract: "Placing key summaries in the reader's peripheral vision reduced paragraph revisits and improved comprehension accuracy on long papers.",
            tags: ["#HCI", "#읽기경험"],
            detailTitleEN: "Reading Flows for Researchers: How Peripheral Summaries Shape Comprehension of Long Papers",
            detailTitleKO: "연구자를 위한 읽기 흐름: 주변부 요약이 긴 논문의 이해도에 미치는 영향",
            authorsEN: "Soo Lee, Ming Chen, +2 others",
            authorsKO: "이수, 밍 첸 외 2명",
            abstractEN: "We study how the spatial placement of summaries affects reading comprehension for researchers working through long papers. By positioning key takeaways in the reader's peripheral vision rather than inline, we observe fewer paragraph revisits and a steadier reading pace. In a study with 48 graduate students, peripheral summaries improved comprehension accuracy by 11% without increasing total reading time.",
            abstractKO: "긴 논문을 읽는 연구자를 대상으로, 요약의 공간적 배치가 이해도에 어떤 영향을 주는지 살펴본다. 핵심 요점을 본문 안이 아니라 독자의 주변 시야에 배치하자, 문단을 다시 읽는 횟수가 줄고 읽기 속도가 안정되었다. 대학원생 48명을 대상으로 한 실험에서 주변부 요약은 전체 읽기 시간을 늘리지 않으면서 이해 정확도를 11% 높였다.",
            detailTags: ["#HCI", "#읽기경험", "#요약", "#가독성"],
            year: "2026",
            citations: 6,
            readMinutes: 9,
            reason: LocalizedString("회원님이 저장한 **읽기 경험** 관련 논문과 주제가 맞닿아 있고, 자주 읽는 CHI 계열이에요.", "Overlaps with the **reading-experience** papers you saved, and it’s from CHI, which you read often.")
        ),
        Paper(
            id: "diffusion-trajectory-reuse",
            venue: "NeurIPS 2025",
            venueDetail: "NeurIPS 2025 · POSTER",
            matchScore: 89,
            filterCategory: "생성모델",
            feedTitle: "Low-Cost Fine-Tuning by Reusing Diffusion Sampling Trajectories",
            authorsShort: "H. Park +4",
            feedAbstract: "Caching a pretrained diffusion model's sampling trajectories enables domain fine-tuning at one-seventh of the compute.",
            tags: ["#생성모델", "#효율화"],
            detailTitleEN: "Low-Cost Domain Fine-Tuning by Reusing Pretrained Diffusion Sampling Trajectories",
            detailTitleKO: "사전학습 디퓨전 샘플링 궤적 재사용을 통한 저비용 도메인 미세조정",
            authorsEN: "Hyun Park, and 4 others",
            authorsKO: "박현 외 4명",
            abstractEN: "Fine-tuning large diffusion models for new domains is expensive because it typically requires regenerating sampling trajectories from scratch. We show that caching a pretrained model's intermediate sampling trajectories and reusing them during adaptation preserves generation quality. This cuts the compute needed for domain fine-tuning to roughly one-seventh, making customization practical on a single GPU.",
            abstractKO: "새로운 도메인에 맞춰 대규모 디퓨전 모델을 미세조정하는 일은, 보통 샘플링 궤적을 처음부터 다시 생성해야 하기 때문에 비용이 크다. 사전학습된 모델의 중간 샘플링 궤적을 캐시해 적응 과정에서 재사용하면 생성 품질이 유지됨을 보인다. 이를 통해 도메인 미세조정에 필요한 연산량을 약 7분의 1로 줄여, 단일 GPU에서도 맞춤화가 가능해진다.",
            detailTags: ["#생성모델", "#효율화", "#디퓨전", "#미세조정"],
            year: "2025",
            citations: 21,
            readMinutes: 15,
            reason: LocalizedString("회원님이 자주 읽는 **생성모델 효율화** 주제와 방법론이 가깝고, 저장한 디퓨전 논문과 이어져요.", "Close to the **generative-efficiency** topics you read often, and it follows the diffusion paper you saved.")
        )
    ]

    // MARK: Library datasets (탭: 읽을 목록 / 저장됨 / 완료)
    // Each row carries a full Paper, so tapping any row opens the detail screen.

    static let toRead: [LibraryItem] = [
        LibraryItem(paper: libEMNLP, relativeDate: LocalizedString("2일 전", "2 days ago"), progress: 62),
        LibraryItem(paper: libICLR,  relativeDate: LocalizedString("4일 전", "4 days ago"), progress: 28),
        LibraryItem(paper: libTACL,  relativeDate: LocalizedString("1주 전", "1 week ago"), progress: nil),
        LibraryItem(paper: libCVPR,  relativeDate: LocalizedString("1주 전", "1 week ago"), progress: nil)
    ]

    static let saved: [LibraryItem] = [
        LibraryItem(paper: feed[0], relativeDate: LocalizedString("오늘", "Today"),    progress: nil),
        LibraryItem(paper: feed[1], relativeDate: LocalizedString("1일 전", "1 day ago"), progress: nil),
        LibraryItem(paper: feed[2], relativeDate: LocalizedString("3일 전", "3 days ago"), progress: nil)
    ]

    static let done: [LibraryItem] = [
        LibraryItem(paper: libNAACL, relativeDate: LocalizedString("5일 전", "5 days ago"), progress: 100),
        LibraryItem(paper: libICML,  relativeDate: LocalizedString("1주 전", "1 week ago"), progress: 100)
    ]

    /// Every known paper — used to resolve saved/read IDs back to full records.
    static var catalog: [Paper] { feed + [libEMNLP, libICLR, libTACL, libCVPR, libNAACL, libICML] }

    // Full records for library-only papers (not in today's feed).
    private static let libEMNLP = Paper(
        id: "emnlp-factuality-kg", venue: "EMNLP 2025", venueDetail: "EMNLP 2025 · LONG PAPER",
        matchScore: 88, filterCategory: "자연어처리",
        feedTitle: "Evaluating the Factuality of Long-Form Summaries with Knowledge Graphs",
        authorsShort: "M. Ito, K. Rao +2",
        feedAbstract: "We build knowledge graphs from source documents to measure the factual consistency of long-form summaries, catching errors that n-gram metrics miss.",
        tags: ["#사실성", "#요약"],
        detailTitleEN: "Evaluating the Factuality of Long-Form Summaries with Knowledge Graphs",
        detailTitleKO: "지식 그래프로 장문 요약의 사실성 평가하기",
        authorsEN: "Mina Ito, Karthik Rao, +2 others", authorsKO: "미나 이토, 카르틱 라오 외 2명",
        abstractEN: "We propose a factuality metric for long-form summaries that builds a knowledge graph from the source document and checks whether each summary claim is supported by a path in the graph. Compared to n-gram and entailment baselines, our metric better localizes hallucinated relations and correlates more strongly with human factuality judgments across three benchmarks.",
        abstractKO: "장문 요약의 사실성을 평가하기 위해, 원본 문서에서 지식 그래프를 구성하고 요약의 각 주장이 그래프 상의 경로로 뒷받침되는지 확인하는 지표를 제안한다. n-그램·함의 기반 기준선과 비교해, 제안 지표는 환각된 관계를 더 정확히 짚어내고 세 개의 벤치마크에서 사람의 사실성 판단과 더 강하게 상관했다.",
        detailTags: ["#사실성", "#요약", "#지식그래프", "#평가"],
        year: "2025", citations: 9, readMinutes: 11,
        reason: LocalizedString("회원님이 저장한 **요약 사실성** 논문과 방법이 맞닿아 있어요.", "In line with the **summary-factuality** papers you saved.")
    )
    private static let libICLR = Paper(
        id: "iclr-representation-collapse", venue: "ICLR 2026", venueDetail: "ICLR 2026 · POSTER",
        matchScore: 84, filterCategory: "머신러닝",
        feedTitle: "Mitigating Representation Collapse in Contrastive Learning on Small Data",
        authorsShort: "L. Fabbri +3",
        feedAbstract: "A volume-preserving regularizer prevents representation collapse when contrastive learning is applied to small datasets.",
        tags: ["#대조학습", "#표현학습"],
        detailTitleEN: "Mitigating Representation Collapse in Contrastive Learning on Small Data",
        detailTitleKO: "소규모 데이터에서 대조 학습의 표현 붕괴 완화",
        authorsEN: "Luca Fabbri, and 3 others", authorsKO: "루카 파브리 외 3명",
        abstractEN: "Contrastive learning on small datasets often collapses to low-rank representations that discard useful structure. We introduce a lightweight volume-preserving regularizer that maintains the effective dimensionality of the feature space during training. On four low-data benchmarks it improves downstream accuracy while adding negligible compute.",
        abstractKO: "소규모 데이터에서 대조 학습은 유용한 구조를 잃고 저계급 표현으로 붕괴하는 경우가 많다. 학습 중 특징 공간의 유효 차원을 유지하는 가벼운 부피 보존 정규화를 제안한다. 네 개의 저데이터 벤치마크에서 연산 부담을 거의 늘리지 않으면서 다운스트림 정확도를 높였다.",
        detailTags: ["#대조학습", "#표현학습", "#정규화", "#저데이터"],
        year: "2026", citations: 3, readMinutes: 10,
        reason: LocalizedString("자주 읽으시는 **표현 학습** 주제와 이어지는 최신 ICLR 논문이에요.", "A recent ICLR paper that follows the **representation-learning** topics you read often.")
    )
    private static let libTACL = Paper(
        id: "tacl-anchor-crosslingual", venue: "TACL 2025", venueDetail: "TACL 2025",
        matchScore: 82, filterCategory: "자연어처리",
        feedTitle: "Anchor Selection for Cross-Lingual Alignment of Multilingual Embeddings",
        authorsShort: "N. Haddad +1",
        feedAbstract: "Choosing anchor words by mutual information improves cross-lingual embedding alignment, especially for low-resource languages.",
        tags: ["#다국어", "#임베딩"],
        detailTitleEN: "Anchor Selection for Cross-Lingual Alignment of Multilingual Embeddings",
        detailTitleKO: "다국어 임베딩의 교차언어 정렬을 위한 앵커 선택",
        authorsEN: "Nour Haddad, and 1 other", authorsKO: "누르 하다드 외 1명",
        abstractEN: "Cross-lingual embedding alignment is sensitive to the anchor words used to learn the mapping. We propose selecting anchors by mutual information between languages rather than by frequency, which yields more stable alignments for low-resource languages and improves bilingual lexicon induction by up to 6 points.",
        abstractKO: "교차언어 임베딩 정렬은 매핑 학습에 쓰는 앵커 단어 선택에 민감하다. 빈도 대신 언어 간 상호정보량으로 앵커를 고르는 방법을 제안하며, 저자원 언어에서 더 안정적인 정렬을 얻고 이중언어 사전 추출을 최대 6점 향상시켰다.",
        detailTags: ["#다국어", "#임베딩", "#정렬", "#저자원"],
        year: "2025", citations: 5, readMinutes: 8,
        reason: LocalizedString("**다국어 임베딩**은 회원님이 관심 표시한 분야와 겹쳐요.", "**Multilingual embeddings** overlap with the fields you flagged.")
    )
    private static let libCVPR = Paper(
        id: "cvpr-video-diffusion-temporal", venue: "CVPR 2025", venueDetail: "CVPR 2025 · HIGHLIGHT",
        matchScore: 80, filterCategory: "컴퓨터비전",
        feedTitle: "Temporal Consistency Regularization for Video Diffusion Models",
        authorsShort: "Y. Sato +5",
        feedAbstract: "A temporal consistency loss reduces flicker in video diffusion outputs without retraining the base model.",
        tags: ["#비디오", "#디퓨전"],
        detailTitleEN: "Temporal Consistency Regularization for Video Diffusion Models",
        detailTitleKO: "비디오 디퓨전 모델을 위한 시간적 일관성 정규화",
        authorsEN: "Yuki Sato, and 5 others", authorsKO: "유키 사토 외 5명",
        abstractEN: "Video diffusion models often produce temporally inconsistent frames that flicker over time. We add a temporal consistency regularizer that aligns predicted noise across adjacent frames, cutting perceptible flicker by a third while preserving per-frame fidelity. The method is a drop-in loss requiring no changes to the base architecture.",
        abstractKO: "비디오 디퓨전 모델은 시간에 따라 깜빡이는, 시간적으로 일관되지 않은 프레임을 만들곤 한다. 인접 프레임 간 예측 노이즈를 정렬하는 시간적 일관성 정규화를 추가해, 프레임별 충실도를 유지하면서 지각되는 깜빡임을 3분의 1로 줄였다. 기본 구조 변경 없이 손실만 추가하면 되는 방식이다.",
        detailTags: ["#비디오", "#디퓨전", "#일관성", "#생성"],
        year: "2025", citations: 12, readMinutes: 13,
        reason: LocalizedString("저장하신 **디퓨전** 논문과 계열이 같아요.", "Same line as the **diffusion** paper you saved.")
    )
    private static let libNAACL = Paper(
        id: "naacl-retrieval-calibration", venue: "NAACL 2025", venueDetail: "NAACL 2025 · LONG PAPER",
        matchScore: 90, filterCategory: "자연어처리",
        feedTitle: "Retrieval Calibration for Faithful Question Answering",
        authorsShort: "D. Wolf +2",
        feedAbstract: "Calibrating retrieval confidence lets a QA model abstain when evidence is weak, improving faithfulness.",
        tags: ["#검색증강", "#QA"],
        detailTitleEN: "Retrieval Calibration for Faithful Question Answering",
        detailTitleKO: "충실한 질의응답을 위한 검색 신뢰도 보정",
        authorsEN: "David Wolf, and 2 others", authorsKO: "다비드 볼프 외 2명",
        abstractEN: "We calibrate the confidence of a retriever so a question-answering model can abstain when the supporting evidence is weak. Calibrated abstention reduces confidently-wrong answers by 31% on open-domain QA while keeping answer coverage high, making the system more faithful in high-stakes settings.",
        abstractKO: "검색기의 신뢰도를 보정해, 근거가 약할 때 질의응답 모델이 답변을 보류할 수 있게 한다. 보정된 보류는 오픈도메인 QA에서 자신 있게 틀린 답을 31% 줄이면서도 답변 커버리지를 높게 유지해, 위험도가 큰 상황에서 더 충실한 시스템을 만든다.",
        detailTags: ["#검색증강", "#QA", "#신뢰도", "#보정"],
        year: "2025", citations: 18, readMinutes: 12,
        reason: LocalizedString("자주 읽으시는 **RAG/QA 신뢰도** 주제의 핵심 논문이에요.", "A key paper on the **RAG/QA faithfulness** topics you read often.")
    )
    private static let libICML = Paper(
        id: "icml-sparse-mixtures-attention", venue: "ICML 2025", venueDetail: "ICML 2025 · POSTER",
        matchScore: 86, filterCategory: "머신러닝",
        feedTitle: "Sparse Mixtures for Efficient Long-Context Attention",
        authorsShort: "R. Costa +4",
        feedAbstract: "Routing tokens to a small set of attention experts cuts long-context compute while matching dense-attention quality.",
        tags: ["#효율화", "#어텐션"],
        detailTitleEN: "Sparse Mixtures for Efficient Long-Context Attention",
        detailTitleKO: "효율적인 장문맥 어텐션을 위한 희소 혼합",
        authorsEN: "Rui Costa, and 4 others", authorsKO: "후이 코스타 외 4명",
        abstractEN: "Long-context attention is expensive because every token attends to every other. We route each query to a small set of attention experts, each covering a slice of the context, cutting attention compute by 4x at 32k tokens while matching dense-attention quality on long-document benchmarks.",
        abstractKO: "장문맥 어텐션은 모든 토큰이 서로를 참조해 비용이 크다. 각 쿼리를 문맥의 일부를 담당하는 소수의 어텐션 전문가로 라우팅해, 32k 토큰에서 어텐션 연산을 4배 줄이면서도 장문서 벤치마크에서 밀집 어텐션 품질에 필적했다.",
        detailTags: ["#효율화", "#어텐션", "#장문맥", "#MoE"],
        year: "2025", citations: 24, readMinutes: 14,
        reason: LocalizedString("**효율화** 계열로, 자주 읽으시는 주제와 잘 맞아요.", "An **efficiency** paper that fits the topics you read often.")
    )

    // 주간 요약은 고정 샘플이 아니라 실제 저장/읽음 상태에서 파생된다 (AppState.weekly*).
}
