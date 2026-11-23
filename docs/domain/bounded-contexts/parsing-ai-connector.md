# Bounded Context: AI & Parsing (Parsing&AIConnector Service)

**Status:** accepted
**Date:** 2026-11-13
**Version:** 1.39

> **Related documentation:** [Glossary](../../glossary.md) |
> [Architecture Overview](../../architecture-overview.md) |
> [Domain Model](../domain-model.md) | [Context Map](../../context-map.md) |
> [OpenAPI](../../api/parsing-ai-connector/openapi.yaml) |
> [AI & RAG Pipeline](../ai-rag-pipeline.md) |
> [AsyncAPI](../../asyncapi/events.yaml) |
> [Technical Requirements](../../technical-requirements.md) |
> [README](../../README.md)
>
> **Related ADRs:** [ADR‑003: Using Python for the Parsing & AI
> Service](../../adr/adr-003-python-for-ai-parsing.md) |
> [ADR‑006: AI Model Integration
> Strategy](../../adr/adr-006-ai-integration.md) |
> [ADR‑007: External Portal Parsing
> Strategy](../../adr/adr-007-parsing-strategy.md) |
> [ADR‑010: Choosing Qdrant and the RAG
> Strategy](../../adr/adr-010-qdrant-rag.md) |
> [ADR‑015: Anti‑Corruption Layer](../../adr/adr-015-acl.md) |
> [ADR‑021: Context Communication](../../adr/adr-021-context-communication.md) |
> [ADR‑022: Parsing & AI Stack](../../adr/adr-022-parsing-ai-stack.md)

## 1. Ответственность

- **1.1** Обнаруживать на внешних порталах новые и изменённые вакансии,
  работодателей и интервьюеров и передавать их в Vacancies Market.
- **1.2** Владеть реестром Portal, сценариями парсинга и настройками
  подключений к порталам.

## 2. Бизнес-процессы и границы контекста

- **2.1 Мониторинг порталов:** отслеживать на подключённых порталах появление
  новых и изменение существующих вакансий, работодателей и интервьюеров.
- **2.2 Передача изменений:** публиковать событие `PortalRecordChanged` по
  каждой новой или изменённой записи для Vacancies Market, который применяет
  их к каталогу.
- **2.3 Границы контекста:** каталог вакансий (Vacancies Market) и данные
  соискателя (Job Search & CRM) — вне контекста; сервис передаёт изменения в
  Vacancies Market, но их данные не изменяет.

## 3. Пользовательские истории

- **3.1 Актуальный каталог:** соискатель видит в Vacancies Market актуальные
  вакансии, сведения о работодателях и интервьюерах, синхронизированные с
  порталами.
- **3.2 Подключение портала:** администратор добавляет Portal и сценарий
  парсинга, после чего портал начинает поставлять изменения в
  Vacancies Market.
- **3.3 Контроль парсинга:** администратор видит ошибки парсинга по порталам и
  исправляет сценарии, чтобы данные снова поступали в Vacancies Market.

## 4. Бизнес-инварианты

### 4.1 Portal

- **4.1.1** Portal нельзя удалить, пока на него ссылается сценарий парсинга.

### 4.2 PortalConnection

- **4.2.1** Настройки подключения хранят только ссылки на креденшлы, никогда
  — сами секреты.

### 4.3 Сценарий парсинга

- **4.3.1** Сценарий принадлежит ровно одному Portal.

### 4.4 Расписание

- **4.4.1** У сценария ровно одно расписание.
- **4.4.2** `interval_s` лежит в пределах от `min_interval_s` до
  `max_interval_s`.
- **4.4.3** У сценария не более одного активного `ParsingTask`.

### 4.5 Записи портала

- **4.5.1** Пара (`portal_id`, `entity_type`, `external_id`) уникальна.

## 5. Агрегаты и сущности

### 5.1 Portal (агрегат)

- **5.1.1 Поля:** `id`, `name`, `base_url`, `created_at`, `updated_at`.
- **5.1.2 Связи:** корень агрегата; содержит `PortalConnection` и
  `ParsingScenario`; на него ссылаются `ParsingTask` и `Source` в
  Vacancies Market по id.
- **5.1.3 Поведение:** `createPortal()`, `updatePortal()`, `deletePortal()` —
  удаление допустимо, только если нет сценариев.

### 5.2 PortalConnection (сущность, часть Portal)

- **5.2.1 Поля:** `id`, `portal_id`, `credential_ref` (имя переменной окружения
  с токеном), `enabled`.
- **5.2.2 Связи:** принадлежит `Portal`; используется его сценариями.
- **5.2.3 Поведение:** нет — хранит ссылку на креденшл, но не секрет.

### 5.3 ParsingScenario (сущность, часть Portal)

- **5.3.1 Поля:** `id`, `portal_id`, `connection_id`, `source_type`
  (rss/api/html), `config` (JSON — правила, селекторы и параметры обхода),
  `min_interval_s`, `max_interval_s`, `enabled`.
- **5.3.2 Связи:** принадлежит ровно одному `Portal` (4.3.1); ссылается на
  `PortalConnection`.
- **5.3.3 Поведение:** `enable()`, `disable()`.

### 5.4 ParsingSchedule (агрегат)

- **5.4.1 Поля:** `id`, `scenario_id`, `interval_s` (текущий), `empty_runs`,
  `cursor` (JSON — состояние обхода), `next_run_at`, `last_run_at`, `status`
  (active/paused/suspended), `attempts`, `backoff_until`.
- **5.4.2 Связи:** одно расписание на `ParsingScenario`; создаёт `ParsingTask`.
- **5.4.3 Поведение:** `scheduleNext()`, `suspend()`, `resume()`.

### 5.5 ParsingTask (агрегат)

- **5.5.1 Поля:** `id`, `scenario_id`, `started_at`, `finished_at`, `status`
  (pending/running/completed/failed), `records_seen`, `records_published`,
  `error_log`, `retry_count`.
- **5.5.2 Связи:** один запуск `ParsingScenario`; обновляет `PortalRecord` и
  публикует событие `PortalRecordChanged` для Vacancies Market.
- **5.5.3 Поведение:** `start()`, `complete()`, `fail()`.

### 5.6 PortalRecord (агрегат)

- **5.6.1 Поля:** `id`, `portal_id`, `entity_type`
  (vacancy/employer/interviewer), `external_id`, `external_url`,
  `content_hash`, `first_seen_at`, `last_seen_at`.
- **5.6.2 Связи:** одна запись портала, известная сервису; обновляется
  запуском `ParsingTask`; изменение публикуется событием.
- **5.6.3 Поведение:** `refresh()` обновляет `content_hash` и `last_seen_at`.

