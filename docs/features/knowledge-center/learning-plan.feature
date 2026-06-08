# language: en
Feature: Create learning plan and skill development
  As a job seeker
  I want to get a personal learning plan and development recommendations
  To fill gaps and increase chances of employment

  Scenario: Automatically create track when desired job is added
    Given I have a job seeker profile with skills ["PHP", "Laravel"]
    And I add a desired job "Senior Go Developer" with requirements ["Go", "Concurrency", "gRPC"]
    When the system processes this event
    Then a new LearningTrack is created
    And the track contains items: "Go basics", "Concurrency in Go", "gRPC for microservices"
    And event `LearningTrackCreated` is published

  Scenario: Track progress over a track
    Given I have an active track with three items
    When I mark the first item as "completed"
    Then track progress becomes 33%
    And event `ProgressUpdated` is published

  Scenario: Get development recommendations based on interview results
    Given I have completed an interview with negative feedback on topic "Docker"
    When the system analyses the `MeetCompleted` event
    Then a development recommendation "Learn Docker Compose and orchestration" is created
    And event `DevelopmentRecommendationGenerated` is published

  Scenario: Request AI summary via learning interface
    Given I am authenticated as a job seeker
    When I send GET request to `/api/v1/knowledge/conspect?topic=Kubernetes`
    Then response status is 202
    And within 5 seconds I receive a generated summary

  Scenario: Online help on technical interview (simplified)
    Given I am in "interview help" mode
    And I send a question "What is a pipeline in Jenkins?"
    Then the system returns a short answer based on the knowledge base