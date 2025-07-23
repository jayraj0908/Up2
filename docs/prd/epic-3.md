# Epic 3: Event Page

## Overview
Implement comprehensive event detail pages that display all event information and enable guest interaction.

## Description
- Title, host info, date, location (hidden for private), vibe
- Ticket price, capacity, promo code (optional)
- Guestlist request + approval or instant purchase
- In-event media (images/videos)

## Stories

### Story 3.1: Event Information Display
**As a** guest user,
**I want** to view complete event details on a dedicated event page,
**so that** I can understand all aspects of the event before deciding to attend.

**Acceptance Criteria:**
1. Event page displays event title prominently
2. Host information is shown with host profile link
3. Event date and time are clearly displayed
4. Location is shown (hidden for private events until approved)
5. Event vibe/mood tags are displayed
6. Event description and details are fully visible
7. Page layout is clean and easy to navigate

### Story 3.2: Ticketing Information & Pricing
**As a** guest user,
**I want** to see ticket pricing and capacity information,
**so that** I can understand the cost and availability before committing.

**Acceptance Criteria:**
1. Ticket price is clearly displayed (free events show "Free")
2. Event capacity and current attendance count are shown
3. Promo code entry field is available when applicable
4. Promo code validation provides immediate feedback
5. Final price calculation includes any discounts
6. Capacity warnings appear when event is nearly full
7. Sold out events display appropriate messaging

### Story 3.3: Guestlist Request & Approval System
**As a** guest user,
**I want** to request to join the guestlist or purchase tickets instantly,
**so that** I can secure my attendance at the event.

**Acceptance Criteria:**
1. User can submit guestlist request for approval-required events
2. User can instantly purchase tickets for open events
3. Request status is clearly communicated (pending, approved, denied)
4. User receives notifications about request status changes
5. Approved users can proceed to payment (if required)
6. Request includes user profile information for host review
7. Users can cancel pending requests

### Story 3.4: In-Event Media Gallery
**As a** guest user,
**I want** to view photos and videos from the event,
**so that** I can see what the event atmosphere is like.

**Acceptance Criteria:**
1. Event page displays media gallery section
2. Photos and videos are shown in a scrollable grid
3. User can tap media to view in full screen
4. Media includes timestamps and contributor information
5. Gallery updates in real-time during event
6. User can share media from the gallery
7. Appropriate content filtering is applied 