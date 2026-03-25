# Agents

## Overview
This document defines the roles, responsibilities, and system boundaries for MissionOut, a SAR alerting platform built web-first in Flutter with native mobile alert handling for reliability-critical behavior.

Core goal: reliable, auditable alert delivery with fast responder actions under stress.

## Technology Stack

### Frontend
- Flutter (Dart)
- Web as the primary starting platform
- Android and iOS as shared UI clients

### Native Mobile Alert Layer
- Android: Kotlin
- iOS: Swift
- Platform channels used to bridge Flutter UI with native alert behavior

### Backend
- FastAPI (Python)
- PostgreSQL for core relational state
- Redis for queues and short-lived operational state
- Celery for background jobs and escalation workflows

### Notification and Escalation
- FCM for Android push delivery
- APNs for iOS push delivery
- Twilio for SMS and voice fallback

## Human Roles

### 1. Responder
Receives alerts and submits availability or response intent.

Responsibilities:
- Receive mission alerts on mobile devices
- View incident details
- Respond with actions such as `Responding` or `Not Available`
- Keep device registration current

Requirements:
- Verified phone-based authentication
- Registered active device for mobile alerting

### 2. Dispatcher
Creates and sends incidents for operational response.

Responsibilities:
- Create incidents
- Set location, notes, and priority
- Trigger dispatch to the appropriate team
- Monitor acknowledgements as they arrive

Focus:
- Speed
- Accuracy
- Low-friction workflow during live incidents

### 3. Team Admin
Manages a single team only.

Responsibilities:
- Manage users within their own team
- Approve or revoke team access
- View team incidents, responses, and device health
- Configure team-level settings

Restrictions:
- Cannot view or manage other teams
- Cannot assign global permissions

### 4. Super Admin
Manages the full system across all teams.

Responsibilities:
- Create and manage teams
- View all incidents and responses
- Assign or revoke Team Admin roles
- Disable users or devices across the system
- Review global operational logs and analytics

Scope:
- All teams
- All users
- All incidents

## System Components

### 5. Web Client
Primary starting interface for early development and operational workflows.

Responsibilities:
- Display incidents and responses
- Support dispatcher workflows
- Support Team Admin and Super Admin workflows
- Provide responder visibility when web access is appropriate

Technology:
- Flutter web

### 6. Mobile Client
Shared responder application UI.

Responsibilities:
- Render incident and response screens
- Display history, status, and team information
- Hand off critical alert actions to native code
- Sync user actions with the backend

Technology:
- Flutter for shared UI
- Platform channels for native integration

### 7. Native Alert Handler
Owns the mission-critical mobile alert path.

Responsibilities:
- Receive push notifications from FCM or APNs
- Wake the device when permitted by the OS
- Launch full-screen alert UI
- Play looping alarm audio and vibration
- Capture immediate responder actions from the lock-screen experience

Requirements:
- Must function when the app is backgrounded or cold-started
- Must not depend on Flutter being active to begin the alert

### 8. API Server
System-of-record entry point for clients and workers.

Responsibilities:
- Authenticate users and devices
- Manage teams, memberships, incidents, and responses
- Register devices and track tokens
- Expose APIs for web and mobile clients
- Maintain authoritative system state

Technology:
- FastAPI
- PostgreSQL

### 9. Notification Worker
Handles first-line dispatch delivery.

Responsibilities:
- Fan out push notifications to registered devices
- Record delivery attempts
- Retry failed or unacknowledged dispatches according to policy

Technology:
- Celery
- Redis

### 10. Escalation Worker
Owns follow-up delivery when responders do not acknowledge in time.

Responsibilities:
- Check for pending acknowledgements
- Trigger follow-up pushes
- Send SMS or voice escalation through Twilio
- Escalate to backup responders or workflows as designed

Technology:
- Celery
- Redis
- Twilio

### 11. Device Registry
Tracks delivery targets and their health.

Responsibilities:
- Store push tokens and platform metadata
- Track `last_seen` and verification state
- Mark stale or inactive devices
- Provide valid targets for delivery workers

## Core Interaction Flow
1. Dispatcher creates an incident in the web or mobile UI.
2. API server stores the incident in PostgreSQL.
3. Notification worker fans out push notifications to target devices.
4. Native alert handler wakes the phone and starts the alarm experience.
5. Responder taps `Responding` or `Not Available`.
6. Mobile or web client sends the action to the API server.
7. API server updates response and delivery state.
8. Escalation worker retries or escalates for non-responders.

## Design Principles
- Reliability over convenience
- Push is one delivery layer, not the whole system
- Device-based targeting instead of user-only targeting
- Clear, auditable state for incidents, responses, and deliveries
- Minimal interaction during high-stress use
- Web-first for product iteration, native-first for alert reliability

## Notes
- Flutter is the shared UI layer across web and mobile.
- Android and iOS native code own the alarm and OS-level alert path.
- Team Admin and Super Admin are intentionally separate roles with different scopes.
- PostgreSQL is the source of truth for incidents, responses, teams, and permissions.
- Repository layout: `dispatcher/`, `responder/`, and `backend/` as top-level app folders.
