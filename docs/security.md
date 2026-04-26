#Rules for data access
## DB Table Rules
 - The following table outlines the access roles for the 3 roles. Data access will be further limited by a Postgres RLS policy matrix, which is below
 -
| Table/Resource         | team_admin | dispatcher | responder |
|------------------------|------------|------------|-----------|
| email_link_tokens      | backend    | backend    | backend   |
| web_push_subscriptions | SUD        | SUD        | SUD       |
| responses              | SIUD       | SIUD       | SIUD      |
| incidents              | SIUD       | SIU        | S         |
| incident_events        | backend    | backend    | backend   |
| push_deliveries        | backend    | backend    | backend   |
| email_code_tokens      | backend    | backend    | backend   |
| devices                | SUD        | SUD        | SUD       |
| delivery_events        | S          | S          |           |
| team_memberships       | SIUD       | S          | S         |
| users                  | SIUD       | SU         | SU        |
| teams                  | S          | S          | S         |

## Postgres RLS policy matrix
 - 
| Table/Resource         | team_admin                          | dispatcher                         | responder                                  |
|------------------------|-------------------------------------|------------------------------------|---------------------------------------------|
| web_push_subscriptions | own team / own user as needed       | own team / own user as needed      | own records only                            |
| responses              | rows for incidents in their team    | rows for incidents in their team   | rows for incidents in their team            |
| incidents              | incidents in their team             | incidents in their team            | incidents in their team, read-only          |
| devices                | own team / own user as needed       | own team / own user as needed      | own device rows only                        |
| delivery_events        | events for incidents in their team  | events for incidents in their team | none                                        |
| team_memberships       | memberships in their team           | memberships in their team, read    | memberships in their team, read             |
| users                  | users in their team                 | users in their team, read          | users in their team, read                   |
| teams                  | their team                          | their team                         | their team                                  |