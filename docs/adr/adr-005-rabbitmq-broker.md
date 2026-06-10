# ADR-005: Choosing RabbitMQ as the Message Broker

## Context

Microservices of AIJobResearcher exchange asynchronous events (VacancyImported,
ReplyCreated, etc.). We need a message broker that guarantees delivery,
scalability, and supports all used technologies (PHP, Python, Go).

## Decision

We use **RabbitMQ** with mirrored queues and persistent messages. Events are
published to `topic` or `direct` exchanges. Each service has queues with delivery
confirmation and dead‑letter configuration.

## Why this decision

- Sufficient performance for 20k RPS (peak load).
- Easy setup and operation (runs in Docker Compose, ready Helm charts).
- Support for dead letter queues (DLQ) for unprocessed messages.
- Native clients for PHP (Laravel), Python (Celery, aio-pika), Go (amqp091).
- Persistent messages ensure messages are not lost when the broker restarts.

## Alternatives

- **Apache Kafka** – higher performance, but more complex to set up and requires
  ZooKeeper/KRaft; overkill for current load.
- **Redis Pub/Sub** – does not support persistence or dead letter, less reliable.
- **AWS SQS** – vendor lock‑in, not suitable for an enterprise demo.

## Consequences

- Need to monitor queue depth and processing delays (metric
  `rabbitmq_queue_messages`).
- If load grows, we may switch to Kafka (architecture remains event‑driven).
- Messages that cannot be processed after several retries go to DLQ with an alert.

## Related artifacts

- ADR-011 (Outbox Pattern).
- Section "Service communication" in `architecture-overview.md`.
- Kubernetes manifests for RabbitMQ in `deploy/k8s/`.
