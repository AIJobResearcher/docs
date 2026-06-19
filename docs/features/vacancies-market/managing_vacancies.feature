# language: en
Feature: Manage vacancies
  As a job seeker or administrator
  I want to view, import and update vacancies
  So that the system contains up‑to‑date data for job search

  Scenario: Search vacancies with filter by employer
    Given the system has employer "TechCorp" with vacancy "Java Developer"
    And employer "SoftDev" with vacancy "Python Developer"
    When I send GET request to `/api/v1/vacancies?employer_id={id_TechCorp}&limit=20&offset=0`
    Then response status is 200
    And response body contains vacancy with title "Java Developer"
    And response body does not contain vacancy with title "Python Developer"

  Scenario: Pagination of vacancy list
    Given the system has 50 vacancies
    When I send GET request to `/api/v1/vacancies?limit=10&offset=0`
    Then response status is 200
    And response contains exactly 10 vacancies
    And header `X-Total-Count` is present with total count of vacancies

  Scenario: Administrator manually triggers full import
    Given I am authenticated as administrator
    And portal "LinkedIn" is available
    When I send POST request to `/api/v1/parsing/import?portal=linkedin&type=full`
    Then response status is 202
    And Parsing&AIConnector starts full scan

  Scenario: Update existing vacancy on re‑parse
    Given the system has vacancy "Java Developer" from portal "LinkedIn"
    And the vacancy description changed on the portal
    When incremental parsing runs
    Then the vacancy is updated
    And the `updated_at` field changes
    And the vacancy version increases

  Scenario: Assign interviewer to vacancy
    Given I am authenticated as administrator
    And employer "TechCorp" has vacancy "Java Developer"
    And employer has interviewer "Ivan Ivanov"
    When the administrator links the interviewer to the vacancy
    Then event `InterviewerAssigned` is published
    And the interviewer appears on the vacancy card