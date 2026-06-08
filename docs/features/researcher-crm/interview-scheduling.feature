# language: en
Feature: Manage profile, applications and meetings
  As a job seeker
  I want to manage my profile, applications and meetings
  To effectively manage the job search process

  Scenario: Register a new job seeker
    Given I am a guest
    When I send POST request to `/api/v1/researchers` with data:
      """
      {
        "full_name": "Petr Petrov",
        "email": "petr@example.com",
        "resume_link": "https://example.com/resume.pdf"
      }
      """
    Then response status is 201
    And a Researcher with that email is created in the system
    And event `ResearcherRegistered` is published

  Scenario: Add a desired job
    Given I am authenticated as a job seeker
    When I send POST request to `/api/v1/jobs` with body:
      """
      {
        "title": "Senior Go Developer",
        "priority": 1,
        "criteria": {
          "salary_min": 3000,
          "remote": true
        }
      }
      """
    Then response status is 201
    And event `JobPreferencesUpdated` is published

  Scenario: Successfully schedule a meeting
    Given I am authenticated as job seeker with ID "res-123"
    And I have an approved application for vacancy "vac-456"
    And interviewer "int-789" is available at the given time
    When I send POST request to `/api/v1/interviews/schedule` with body:
      """
      {
        "vacancy_id": "vac-456",
        "interviewer_id": "int-789",
        "planned_datetime": "2025-06-15T10:00:00Z"
      }
      """
    Then response status is 202
    And event `MeetScheduled` appears in RabbitMQ
    And invitation is sent to Google Calendar

  Scenario: Attempt to schedule without an approved application
    Given I have an application for a vacancy with status "pending"
    When I try to schedule a meeting
    Then response status is 400
    And error message contains "Application must be approved before scheduling an interview"

  Scenario: Withdraw an application
    Given I have an application for a vacancy in status "pending"
    When I send DELETE request to `/api/v1/replies/{reply_id}`
    Then response status is 204
    And the application changes to status "withdrawn"
    And event `ReplyWithdrawn` is published

  Scenario: Cancel a meeting
    Given I have a scheduled meeting
    When I send DELETE request to `/api/v1/meets/{meet_id}`
    Then response status is 204
    And the meeting changes to status "cancelled"
    And event `MeetCancelled` is published

  Scenario: Export data (GDPR)
    Given I am authenticated as a job seeker
    When I send GET request to `/api/v1/researchers/{id}/export`
    Then response status is 200
    And the response body contains all my personal data in JSON format

  Scenario: Delete account (GDPR)
    Given I am authenticated as a job seeker
    When I send DELETE request to `/api/v1/researchers/{id}`
    Then response status is 204
    And all my personal data is deleted
    And event `AccountDeleted` is published