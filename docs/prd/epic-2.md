# Epic 2: Event Discovery (Guest Flow)

## Overview
Implement event discovery functionality that allows guests to find and explore events through multiple discovery mechanisms.

## Description
- "For You" feed powered by mood, friend graph, and location
- Map view and trending events view
- Private invite tab for invitation-only events

## Stories

### Story 2.1: Personalized "For You" Event Feed
**As a** guest user,
**I want** to see a personalized "For You" feed of events,
**so that** I can discover events that match my interests and social connections.

**Acceptance Criteria:**
1. Feed displays events based on user's mood preferences
2. Feed prioritizes events from user's friend network
3. Feed considers user's location for relevant local events
4. Events are displayed in a scrollable, card-based interface
5. Each event card shows key information (title, date, location, host)
6. User can tap on event cards to view full event details
7. Feed refreshes with new content when user pulls to refresh

### Story 2.2: Map View for Event Discovery
**As a** guest user,
**I want** to view events on a map interface,
**so that** I can discover events happening near my location.

**Acceptance Criteria:**
1. Map displays user's current location
2. Events are shown as pins/markers on the map
3. Event markers show basic info when tapped (title, time)
4. User can zoom in/out and navigate around the map
5. Map clusters nearby events for better visibility
6. User can tap event markers to view full event details
7. Map automatically updates with new events in the visible area

### Story 2.3: Trending Events View
**As a** guest user,
**I want** to see trending and popular events,
**so that** I can discover what's popular and happening in my area.

**Acceptance Criteria:**
1. Trending view displays most popular events
2. Events are ranked by engagement metrics (RSVPs, views, shares)
3. Trending list refreshes regularly with current popular events
4. User can scroll through trending events list
5. Each event shows popularity indicators (number of attendees)
6. User can tap on trending events to view full details
7. Trending view includes time-based filters (today, this week, this month)

### Story 2.4: Private Invite Tab
**As a** guest user,
**I want** to access a dedicated tab for private invitation-only events,
**so that** I can view and respond to exclusive event invitations.

**Acceptance Criteria:**
1. Private invite tab shows only invitation-only events
2. Tab displays events where user has been specifically invited
3. User can see invitation status (pending, accepted, declined)
4. User can accept or decline private event invitations
5. Private events show limited information until invitation is accepted
6. Invitation notifications appear in this tab
7. Tab is empty if user has no private invitations 