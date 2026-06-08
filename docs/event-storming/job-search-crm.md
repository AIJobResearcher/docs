# Event Storming: Job Search & CRM

## Commands (triggers)

- **RegisterResearcher** – job seeker registration
- **UpdateProfile** – update profile
- **AddDesiredJob** – add desired job
- **ApplyForVacancy** – apply to vacancy
- **WithdrawReply** – withdraw application
- **ScheduleMeet** – schedule meeting
- **CancelMeet** – cancel meeting
- **SendMessage** – send message
- **ExportData** – export data (GDPR)
- **DeleteAccount** – delete account (GDPR)

## Domain events

| Event | Published by | Description |
| --- | --- | --- |
| `ResearcherRegistered` | ResearcherCrm | New job seeker |
| `JobPreferencesUpdated` | ResearcherCrm | List of desired jobs updated |
| `ReplyCreated` | ResearcherCrm | Application created |
| `ReplyWithdrawn` | ResearcherCrm | Application withdrawn |
| `MeetScheduled` | ResearcherCrm | Meeting scheduled |
| `MeetCompleted` | ResearcherCrm | Meeting completed |
| `MeetCancelled` | ResearcherCrm | Meeting cancelled |
| `MessageSent` | ResearcherCrm | Message sent |
| `AccountDeleted` | ResearcherCrm | Account deleted (GDPR) |
| `DataExported` | ResearcherCrm | Data exported (GDPR) |

## Aggregates

- `Researcher` – root
- `Job` – desired job
- `Reply` – application
- `Meet` – meeting
- `Message` – message
- `AIRecommendation` – AI result

## Business rules (invariants)

- One application per vacancy.
- Withdraw only in `pending` status.
- Meeting possible only after `approved` application.
- Application immutable after `rejected`, `approved`, `withdrawn`.
