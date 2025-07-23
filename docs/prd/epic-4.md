# Epic 4: Host Flow

## Overview
Implement comprehensive event hosting capabilities that allow users to create, manage, and monitor their events.

## Description
- Fast event creation form
- Manual or automatic guest approval toggle
- Host dashboard with attendee list and analytics lite

## Stories

### Story 4.1: Fast Event Creation Form
**As a** host user,
**I want** to quickly create new events through a streamlined form,
**so that** I can set up events efficiently and start inviting guests.

**Acceptance Criteria:**
1. Event creation form is accessible from main navigation
2. Form includes all essential fields (title, date, time, location, description)
3. Form validates required fields before submission
4. Host can set event vibe/mood tags
5. Host can set ticket pricing (free or paid)
6. Host can set event capacity limits
7. Event is created and immediately available for sharing

### Story 4.2: Guest Approval Settings
**As a** host user,
**I want** to configure how guests can join my event,
**so that** I can control who attends my event.

**Acceptance Criteria:**
1. Host can toggle between manual and automatic guest approval
2. Manual approval requires host review of each guest request
3. Automatic approval allows instant event access for guests
4. Host can change approval settings after event creation
5. Approval settings are clearly communicated to potential guests
6. Host receives notifications for pending approval requests
7. Host can approve/deny individual guest requests

### Story 4.3: Host Dashboard Overview
**As a** host user,
**I want** to access a comprehensive dashboard for my events,
**so that** I can monitor and manage all aspects of my hosted events.

**Acceptance Criteria:**
1. Dashboard displays list of all host's events (past and upcoming)
2. Each event shows key metrics (attendees, revenue, status)
3. Host can quickly navigate to individual event management pages
4. Dashboard shows overall hosting statistics
5. Quick action buttons for common tasks (edit event, message guests)
6. Dashboard refreshes with real-time data
7. Dashboard is accessible from main navigation

### Story 4.4: Attendee List Management
**As a** host user,
**I want** to view and manage my event's attendee list,
**so that** I can track who is coming and communicate with guests.

**Acceptance Criteria:**
1. Attendee list shows all confirmed guests
2. List displays guest profiles and attendance status
3. Host can search and filter attendee list
4. Host can send messages to individual guests or groups
5. Host can remove guests from the event if needed
6. List shows payment status for paid events
7. Attendee list exports for external use

### Story 4.5: Analytics Lite
**As a** host user,
**I want** to view basic analytics about my events,
**so that** I can understand event performance and guest engagement.

**Acceptance Criteria:**
1. Analytics show event views and engagement metrics
2. Revenue tracking for paid events
3. Guest demographics and attendance patterns
4. Event timeline showing key milestones
5. Comparison metrics across multiple events
6. Simple charts and visualizations for key data
7. Export functionality for analytics data 