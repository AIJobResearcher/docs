# language: en
Feature: Parse portals and AI recommendations
  As a system and a job seeker
  I want to import vacancies and get AI recommendations
  So that data is up‑to‑date and search is effective

  Scenario: Successful incremental import
    Given portal "LinkedIn" is available
    And the system last parse date was 24 hours ago
    When incremental parsing runs on schedule
    Then Parsing&AIConnector receives new vacancies from the portal
    And event `VacancyImported` is published for each new vacancy
    And metric `parsing_success_rate` increases

  Scenario: Detected change of portal structure
    Given the parser configuration for portal "Djinni" expects 20 elements per page
    When only 5 elements are found during parsing
    Then parsing stops
    And event `ParsingFailed` is published
    And the administrator is notified

  Scenario: Generate AI recommendation for vacancies
    Given I am authenticated as a job seeker
    And I have a profile with skills ["PHP", "Symfony"]
    When I send POST request to `/api/v1/ai/recommendations` with body:
      """
      {
        "type": "vacancy",
        "context": "I am looking for a PHP developer job"
      }
      """
    Then response status is 202
    And within 3 seconds I receive a recommendation with a list of vacancies

  Scenario: OpenAI budget exceeded
    Given OpenAIProvider is used
    And the token limit is exhausted
    When a request for recommendation is received
    Then the system switches to OllamaAIProvider
    And event `AITokenBudgetExceeded` is published
    And the user receives a response from the local model

  Scenario: Generate AI summary for KnowledgeCenter
    Given KnowledgeCenter requests a summary on topic "SOLID principles"
    When command `AIConspectRequested` is sent
    Then Parsing&AIConnector generates a summary
    And event `AIConspectGenerated` is published