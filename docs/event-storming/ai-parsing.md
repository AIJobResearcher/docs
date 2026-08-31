# Event Storming: AI & Parsing

## Commands (triggers)

- **ParsePortal** – start parsing (scheduled)
- **RetryParsing** – retry parsing after failure
- **DeduplicateVacancyCandidate** – use normalized data and AI matching to
  select a catalogue mutation
- **RequestCatalogueChange** – request persistence of an approved mutation
- **GenerateRecommendation** – request AI recommendation
- **GenerateAIConspect** – request AI summary (from KnowledgeCenter)

## Domain events

| Event | Published by | Description |
| --- | --- | --- |
| `AITokenBudgetExceeded` | Parsing&AIConnector | OpenAI budget exceeded |
| `RecommendationGenerated` | Parsing&AIConnector | AI recommendation generated |
| `ParsingFailed` | Parsing&AIConnector | Error during parsing (alert) |
| `ExternalPortalUnreachable` | Parsing&AIConnector | Portal is unreachable during parsing |
| `ParsingSuspended` | Parsing&AIConnector | Parsing automatically suspended |

## Integration messages

| Message | Producer | Consumer | Description |
| --- | --- | --- | --- |
| `CatalogueChangeRequested` | Parsing&AIConnector | Vacancies Market | Approved create, update, merge or close request for atomic persistence. |

## Aggregates

- `ParsingTask` – parsing task
- `AIRecommendationTask` – recommendation generation task
- `AIModel` – AI model lookup
- `VacancyCandidate` – normalized source record and duplicate-resolution decision

## Business rules (invariants)

- All AI requests are cached (24h/7d).
- When OpenAI unavailable – fallback to Ollama or user message.
- Parsing respects `robots.txt` and `Crawl‑delay`.
- When parsing success <80% – automatic suspension for 30 minutes.
- Duplicate candidates and final catalogue mutations are selected here; the
  request contains confidence, rationale and the expected aggregate version.
