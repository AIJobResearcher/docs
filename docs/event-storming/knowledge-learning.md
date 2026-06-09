# Event Storming: Knowledge & Learning

## Commands (triggers)

- **CreateLearningTrack** – create track (automatically or manually)
- **AddTrackItem** – add item to track
- **MarkItemComplete** – mark item completed
- **SkipOptionalItem** – skip optional item
- **RequestAIConspect** – request AI summary (to AI & Parsing)

## Domain events

| Event | Published by | Description |
| --- | --- | --- |
| `LearningTrackCreated` | KnowledgeCenter | Track created |
| `LearningTrackCompleted` | KnowledgeCenter | Track completed |
| `ProgressUpdated` | KnowledgeCenter | Progress updated for an item |
| `DevelopmentRecommendationGenerated` | KnowledgeCenter | Development recommendation generated |
| `AIConspectGenerated` | Parsing&AIConnector | AI summary generated (returned to KnowledgeCenter) |

## Aggregates

- `LearningTrack` – root
- `TrackItem` – track item
- `Progress` – progress on item
- `Skill` – skill lookup

## Business rules (invariants)

- Track linked to a specific desired job (Job).
- Track items are linear (previous must be completed).
- Track progress = completed / total items.
- Skipping only for `is_optional` items.
