# language: en
Feature: Browse and manage the vacancy catalogue
  As a job seeker or administrator
  I want to view and manage vacancies
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

  Scenario: Persist an approved update to an existing vacancy
    Given the system has vacancy "Java Developer" from portal "LinkedIn"
    And Parsing&AIConnector approved an updated canonical vacancy
    When Vacancies Market processes `CatalogueChangeRequested` with mutation type "update"
    Then the vacancy is updated
    And the `updated_at` field changes
    And the vacancy version increases

  Scenario: Reject a stale catalogue-change request
    Given the system has vacancy "Java Developer" at version 4
    And `CatalogueChangeRequested` contains expected version 3
    When Vacancies Market processes the command
    Then the catalogue is unchanged
    And the command is rejected as retryable

  Scenario: Assign interviewer to vacancy
    Given I am authenticated as administrator
    And employer "TechCorp" has vacancy "Java Developer"
    And employer has interviewer "Ivan Ivanov"
    When the administrator links the interviewer to the vacancy
    Then event `InterviewerAssigned` is published
    And the interviewer appears on the vacancy card

  Scenario: Create a new vacancy with new employer and requirement
    Given Parsing&AIConnector approved a new canonical vacancy with new employer "NewCorp"
    And the vacancy has requirement "PHP"
    When Vacancies Market processes `CatalogueChangeRequested` with mutation type "create"
    Then the employer "NewCorp" is created
    And the requirement "PHP" is created
    And the vacancy is created with version 1
    And event `EmployerImported` is published
    And event `VacancyImported` is published

  Scenario: Create a vacancy with existing employer
    Given employer "TechCorp" exists
    And Parsing&AIConnector approved a new canonical vacancy with employer "TechCorp"
    When Vacancies Market processes `CatalogueChangeRequested` with mutation type "create"
    Then the vacancy is created and linked to "TechCorp"
    And event `VacancyImported` is published

  Scenario: Prevent creating vacancy with empty title
    Given Parsing&AIConnector sends a create command with empty title
    When Vacancies Market processes the command
    Then the command is rejected with `VacancyTitleEmptyException`

  Scenario: Prevent creating vacancy without external URLs
    Given Parsing&AIConnector sends a create command with empty external_urls
    When Vacancies Market processes the command
    Then the command is rejected with `VacancyExternalUrlsEmptyException`

  Scenario: Prevent assigning interviewer to vacancy of different employer
    Given employer "TechCorp" has vacancy "Java Developer"
    And interviewer "Ivan Ivanov" belongs to employer "SoftDev"
    When an attempt is made to assign Ivan to Java Developer
    Then the assignment is rejected with `InterviewerVacancyEmployerMismatchException`
    And event `InterviewerAssigned` is not published

  Scenario: Prevent duplicate assignment of interviewer to same vacancy
    Given employer "TechCorp" has vacancy "Java Developer"
    And interviewer "Ivan Ivanov" belongs to "TechCorp"
    And Ivan is already assigned to Java Developer
    When an attempt is made to assign Ivan again
    Then the assignment is rejected with `InterviewerAlreadyAssignedException`

  Scenario: Unassign interviewer from vacancy
    Given employer "TechCorp" has vacancy "Java Developer"
    And interviewer "Ivan Ivanov" is assigned to Java Developer
    When the administrator unassigns Ivan from Java Developer
    Then the assignment is marked inactive
    And the interviewer no longer appears on the vacancy card

  Scenario: Soft delete interviewer prevents new assignments
    Given interviewer "Ivan Ivanov" exists and is active
    When the interviewer is soft deleted
    Then the interviewer is inactive
    And any attempt to assign to a vacancy throws `InterviewerIsNotActiveException`

  Scenario: Close vacancy
    Given a vacancy "Java Developer" is open
    When the vacancy is closed
    Then the vacancy status becomes "closed"
    And the `closed_at` timestamp is set
    And event `VacancyClosed` is published

  Scenario: Prevent closing already closed vacancy
    Given a vacancy "Java Developer" is already closed
    When an attempt is made to close it again
    Then it is rejected with `VacancyAlreadyClosedException`

  Scenario: Reopen closed vacancy
    Given a vacancy "Java Developer" is closed
    When the vacancy is reopened
    Then the status becomes "open"
    And the `closed_at` is removed
    And event `VacancyUpdated` is published

  Scenario: Prevent reopening an open vacancy
    Given a vacancy "Java Developer" is open
    When an attempt is made to reopen it
    Then it is rejected with `VacancyAlreadyOpenException`

  Scenario: Merge duplicate vacancies
    Given two vacancies "Java Dev 1" and "Java Dev 2" exist
    And Parsing&AIConnector approves merging them into "Java Dev 1"
    When Vacancies Market processes `CatalogueChangeRequested` with mutation type "merge"
    Then "Java Dev 1" is updated with data from "Java Dev 2"
    And "Java Dev 2" is closed
    And event `VacancyMerged` is published

  Scenario: Reject merge with empty merge list
    Given Parsing&AIConnector sends a merge command with empty merge_ids
    When Vacancies Market processes the command
    Then the command is rejected with `MergeListEmptyException`

  Scenario: Assign vacancy to a job
    Given a vacancy "Java Developer" exists
    And a job "Software Engineer" exists
    When the vacancy is assigned to the job
    Then the job appears in the vacancy's job list
    And the vacancy version increases

  Scenario: Prevent assigning vacancy to same job twice
    Given vacancy "Java Developer" is already assigned to job "Software Engineer"
    When an attempt is made to assign again
    Then it is rejected with `JobAlreadyAssignedException`

  Scenario: Unassign vacancy from job
    Given vacancy "Java Developer" is assigned to job "Software Engineer"
    When the vacancy is unassigned from the job
    Then the job is removed from vacancy's job list
    And the vacancy version increases

  Scenario: Prevent unassigning from job not assigned
    Given vacancy "Java Developer" is not assigned to job "Backend Engineer"
    When an attempt is made to unassign from that job
    Then it is rejected with `JobNotAssignedException`

  Scenario: Update vacancy details
    Given a vacancy "Java Developer" exists with version 5
    And Parsing&AIConnector sends an update command with new title "Senior Java Developer" and expected_version 5
    When Vacancies Market processes the command
    Then the vacancy title is updated
    And the version becomes 6
    And event `VacancyUpdated` is published

  Scenario: Reject update with version mismatch
    Given a vacancy "Java Developer" exists with version 5
    And Parsing&AIConnector sends an update command with expected_version 4
    When Vacancies Market processes the command
    Then the command is rejected with `VersionConflictException`
    And the vacancy remains unchanged

  Scenario: Add a requirement to a vacancy
    Given a vacancy "Java Developer" exists
    And a requirement "MySQL" exists
    When the requirement is added to the vacancy
    Then the requirement appears in the vacancy's requirements list
    And the vacancy version increases

  Scenario: Prevent adding duplicate requirement to vacancy
    Given vacancy "Java Developer" already has requirement "MySQL"
    When an attempt is made to add "MySQL" again
    Then it is rejected with `RequirementAlreadyAssignedException`

  Scenario: Remove a requirement from a vacancy
    Given vacancy "Java Developer" has requirement "MySQL"
    When the requirement is removed from the vacancy
    Then the requirement is no longer in the vacancy's requirements list
    And the vacancy version increases

  Scenario: Prevent removing non-existent requirement from vacancy
    Given vacancy "Java Developer" does not have requirement "MongoDB"
    When an attempt is made to remove "MongoDB"
    Then it is rejected with `RequirementNotAssignedException`

  Scenario: Update employer details
    Given employer "TechCorp" exists with title "Old TechCorp"
    When the employer details are updated with title "New TechCorp"
    Then the employer title is updated
    And the version is incremented

  Scenario: Prevent updating employer with empty title
    Given employer "TechCorp" exists
    When an attempt is made to update title to empty string
    Then it is rejected with `EmployerTitleEmptyException`

  Scenario: Update interviewer profile
    Given interviewer "Ivan Ivanov" exists with position "Junior"
    When the interviewer profile is updated with position "Senior"
    Then the position is updated
    And the version is incremented

  Scenario: Prevent updating interviewer with empty full name
    Given interviewer "Ivan Ivanov" exists
    When an attempt is made to update full name to empty string
    Then it is rejected with `InterviewerFullNameEmptyException`

  Scenario: Ensure requirement uniqueness
    Given a requirement "PHP" already exists
    When an attempt is made to create a new requirement with title "PHP"
    Then it is rejected with `RequirementAlreadyExistsException`

  Scenario: Update requirement
    Given a requirement "PHP" exists with description "Old"
    When the requirement is updated with description "New"
    Then the description is updated

  Scenario: Prevent creating requirement with empty title
    When an attempt is made to create a requirement with empty title
    Then it is rejected with `RequirementTitleEmptyException`

  Scenario: Soft delete job
    Given a job "Software Engineer" exists
    When the job is soft deleted
    Then the job is marked as deleted
    And the version is incremented
    # Note: actual removal check is done at application layer

  Scenario: Add a requirement to a job
    Given a job "Software Engineer" exists
    And a requirement "PHP" exists
    When the requirement is added to the job
    Then the requirement is associated with the job
    And the job version increases

  Scenario: Prevent adding duplicate requirement to job
    Given job "Software Engineer" already has requirement "PHP"
    When an attempt is made to add "PHP" again
    Then it is rejected with `RequirementAlreadyAssignedException`

  Scenario: Remove requirement from job
    Given job "Software Engineer" has requirement "PHP"
    When the requirement is removed from the job
    Then the requirement is no longer associated with the job
    And the job version increases

  Scenario: Prevent removing non-existent requirement from job
    Given job "Software Engineer" does not have requirement "Java"
    When an attempt is made to remove "Java"
    Then it is rejected with `RequirementNotAssignedException`