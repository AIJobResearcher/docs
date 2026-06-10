# Event Storming: AI & Parsing

## Commands (triggers)

- **ParsePortal** – start parsing (scheduled)
- **RetryParsing** – retry parsing after failure
- **GenerateRecommendation** – request AI recommendation
- **GenerateAIConspect** – request AI summary (from KnowledgeCenter)

## Domain events

| Event | Published by | Description |
| --- | --- | --- |
| `AITokenBudgetExceeded` | Parsing&AIConnector | OpenAI budget exceeded |
| `RecommendationGenerated` | Parsing&AIConnector | AI recommendation generated |
| `ParsingFailed` | Parsing&AIConnector | Error during parsing (alert) |
| `ParsingSuspended` | Parsing&AIConnector | Parsing automatically suspended |

## Aggregates

- `ParsingTask` – parsing task
- `AIRecommendationTask` – recommendation generation task
- `AIModel` – AI model lookup

## Business rules (invariants)

- All AI requests are cached (24h/7d).
- When OpenAI unavailable – fallback to Ollama or user message.
- Parsing respects `robots.txt` and `Crawl‑delay`.
- When parsing success <80% – automatic suspension for 30 minutes.
