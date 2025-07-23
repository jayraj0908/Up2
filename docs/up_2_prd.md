**Product Requirements Document (PRD): Up2 iOS App**

---

**Overview**
Up2 is a Gen Z nightlife social app that allows users to discover, attend, and host public or private events in a single, real-time mobile platform. The product combines Instagram-like social interaction with the event-focused functionality of Partyful and Eventbrite. Up2 is user-first with a built-in hosting engine. Hosting and attending events are seamless roles any user can adopt.

---

**Goals**
- Enable users to discover and book events socially
- Empower any user to host events simply and securely
- Build real-time engagement around events (chat, media, invites)
- Monetize via commission on ticketed events and featured venue placements

---

**Core MVP Features**

1. **User Authentication & Profile**
   - Sign up / login with phone or email
   - Create a personal profile with avatar, vibe tags, event history

2. **Event Discovery (Guest Flow)**
   - "For You" feed powered by mood, friend graph, and location
   - Map view and trending events view
   - Private invite tab for invitation-only events

3. **Event Page**
   - Title, host info, date, location (hidden for private), vibe
   - Ticket price, capacity, promo code (optional)
   - Guestlist request + approval or instant purchase
   - In-event media (images/videos)

4. **Host Flow**
   - Fast event creation form
   - Manual or automatic guest approval toggle
   - Host dashboard with attendee list and analytics lite

5. **Payments & Ticketing**
   - Stripe or equivalent integration for ticket purchases
   - Commission logic and refund policy handling
   - Guests pay, but are only charged if approved (for private events)

6. **Real-Time Chat & Feed**
   - Event-specific group chat opens 24h before start
   - Feed of guest photos/videos with tag support (optional per event)

7. **Social Mechanics**
   - Invite friends via shareable link, username, or SMS
   - Profile tagging, event attendance history
   - Friend-based signal boosts in discovery

---

**User Stories**

*As a guest:*
- I want to browse events nearby based on my mood
- I want to know which of my friends are attending
- I want to request access or buy a ticket quickly
- I want to chat with others before the event starts
- I want to post and view pictures from events I attended

*As a host:*
- I want to create an event in under 2 minutes
- I want to approve or decline requests easily
- I want to control guest visibility and privacy
- I want to receive payments for ticketed events

---

**Out of Scope for MVP**
- Web version / Android app
- Pro host tools (multi-event dashboards, promo boosts)
- Advanced moderation or community reporting tools
- Brand collabs or sponsored events
- Deep venue network integration (beyond basic featured hosts)

---

**Edge Cases & Risk Mitigation**
- Double booking → prevent over-capacity with live ticket sync
- No-shows or refunds → define policies in ToS per event type
- Bad actors → user reports, content flagging, approval gating
- Event spam → rate limits or social graph validation for new hosts

---

**Next Steps**
- Finalize Figma flow and design system
- Begin backend infrastructure planning (auth, db, payments)
- Assign initial timeline for phased iOS build
- Prepare marketing language for early access / LA-only beta

