# Proje Talimatları

*Token tasarrufu yaparak bu projeyi yürüt. Bana uzun açıklama yapma. Yaptıklarını hepsini de özellikle istenmedikçe detaylıca yazma. Sadece çok kısa ve net ne yaptığını ya da ne yapılacağını yaz.

*Her oturum açıldığında ve her promttan sonra oluşturduğun md, walkthrough.md (geçmişte ne yapıldığını, nelerin test edilip doğrulandığını anlamak için) ve aşağıda belirttiğim dosyalarının içlerindeki en son tamamlanan konuyu ya da maddeyi oku.
 tasks/roadmap.md
 tasks/lessons.md
 tasks/todo.md
 tasks/changelog.md

*aşağıdaki md dosyaları için de hem tamamlanmamış konuyu ya da maddeyi hem de yapılacak konuyu ya da maddeyi oku.
 tasks/todo.md
 tasks/roadmap.md

 *bu md doyaları en başta oluşturulmamışsa ya da boşsa, oluştur ve içerisini doldur.

*Kesinlikle varsayım yapma. Doğrulanabilir ya da doğrulanmış gerçek methodları dene. Gerçekçi davran. Bilmediğin, anlamadığın ya da bulamadığın şeyler için bana sor, ne yapılacağına beraber karar verelim.

*Çalıştığın tüm konularda, projelerde ya da çalışmalarda dünya çapında uzman olmak için bir ustalık yol haritası oluştur. Bu yol haritasını tasks/roadmap.md yaz. Oluşturduğun md dosyalarından ilgili olanlarında yazdıkların tamamlandıkça ilgili maddeleri ya da konuları tamamlandı olarak işaretle.

*En iyi %1'in kullandığı ama pek paylaşmadığı teknikleri, gizli kaynakları ve alışılbadık yaklaşımları dahil et.

*Infinite Loop Prevention:* Eğer bir sorunu çözerken birkaç denemede başarılı olamazsanız (sonsuz döngü), durun ve durumu kullanıcıya bildirin. Birlikte karar verilecektir.

*Yaptığın her çalışmada şu şekilde çalış; işi savsaklama, üşenme, verilen görevi eksik yapma, tam yapi. verilen görevin eksiğini yapma. yaptığın çalışmayı tam yap, sadece örnekleri çalışır şekilde oluşturup kalanını çalışmayacak şekilde bırakma.

## Workflow Orchestration
### 1. Plan Mode Default
- Enter plan mode for ANY non-trivial task (3+ steps or architectural decisions)
- If something goes sideways, STOP and re-plan immediately
- Use plan mode for verification steps, not just building
- Write detailed specs upfront to reduce ambiguity

### 2. Subagent Strategy
- Use subagents liberally to keep main context window clean
- Offload research, exploration, and parallel analysis to subagents
- For complex problems, throw more compute at it via subagents
- One task per subagent for focused execution

### 3. Self-Improvement Loop
- After ANY correction from the user: update tasks/lessons.md with the pattern
- Write rules for yourself that prevent the same mistake
- Ruthlessly iterate on these lessons until mistake rate drops
- Review lessons at session start for relevant project

### 4. Verification Before Done
- Never mark a task complete without proving it works
- Diff behavior between main and your changes when relevant
- Ask yourself: "Would a staff engineer approve this?"
- Run tests, check logs, demonstrate correctness

### 5. Demand Elegance (Balanced)
- For non-trivial changes: pause and ask "is there a more elegant way?"
- If a fix feels hacky: "Knowing everything I know now, implement the elegant solution"
- Skip this for simple, obvious fixes -- don't over-engineer
- Challenge your own work before presenting it

### 6. Autonomous Bug Fixing
- When given a bug report: just fix it. Don't ask for hand-holding
- Point at logs, errors, failing tests -- then resolve them
- Zero context switching required from the user
- Go fix failing CI tests without being told how

## Task Management

1. Plan First: Write plan to tasks/todo.md with checkable items
2. Verify Plan: Check in before starting implementation
3. Track Progress: Mark items complete as you go
4. Explain Changes: High-level summary at each step
5. Document Results: Add review section to tasks/todo.md
6. Capture Lessons: Update tasks/lessons.md after corrections

## Core Principles

- Simplicity First: Make every change as simple as possible. Impact minimal code.
- No Laziness: Find root causes. No temporary fixes. Senior developer standards.
- Minimal Impact: Only touch what's necessary. No side effects with new bugs.
