# Epic 6: Real-Time Chat & Feed

## Overview
Implement real-time communication and media sharing features for event attendees.

## Description
- Event-specific group chat opens 24h before start
- Feed of guest photos/videos with tag support (optional per event)

## Stories

### Story 6.1: Event-Specific Group Chat
**As a** confirmed event attendee,
**I want** to participate in event-specific group chat,
**so that** I can connect with other attendees and coordinate before the event.

**Acceptance Criteria:**
1. Group chat becomes available 24 hours before event start time
2. Only confirmed attendees can access the chat
3. Real-time messaging with immediate message delivery
4. Messages display sender name and timestamp
5. Chat supports text messages and emoji reactions
6. Chat history is preserved and searchable
7. Push notifications for new messages (with user controls)

### Story 6.2: Event Media Feed
**As a** event attendee,
**I want** to share and view photos/videos in an event feed,
**so that** I can capture and experience event moments with other attendees.

**Acceptance Criteria:**
1. Event feed is available during and after the event
2. Attendees can upload photos and videos to the feed
3. Media posts support text captions and descriptions
4. Feed displays media in chronological order
5. Users can like and comment on media posts
6. Feed is only accessible to confirmed attendees
7. Host can moderate and remove inappropriate content

### Story 6.3: Tagging & Social Features
**As a** event attendee,
**I want** to tag other attendees and use hashtags in the event feed,
**so that** I can connect content with people and create discoverable moments.

**Acceptance Criteria:**
1. Users can tag other attendees in photos and captions (@username)
2. Tagged users receive notifications about mentions
3. Support for event-specific hashtags (#eventhashtag)
4. Hashtag aggregation shows all posts with specific tags
5. Tag suggestions based on attendee list
6. Privacy controls for being tagged by others
7. Search functionality for tags and mentions

### Story 6.4: Optional Event Media Configuration
**As a** event host,
**I want** to control whether media sharing is enabled for my event,
**so that** I can maintain appropriate event atmosphere and privacy.

**Acceptance Criteria:**
1. Host can enable/disable media feed during event creation
2. Host can toggle media sharing on/off after event creation
3. Media sharing settings are clearly communicated to attendees
4. Host can moderate media content (approve/remove posts)
5. Host can set media sharing guidelines and rules
6. Disabled media events only show group chat functionality
7. Host receives notifications for new media posts when moderation is enabled 