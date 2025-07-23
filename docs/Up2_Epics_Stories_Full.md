
# Up2 — Unified Feature Development Plan (Epics & Stories)

This document contains all current Epics and Stories aligned with Supabase integration, dual UX roles (User vs Host), and Cursor development workflow.

---

## 🎨 Epic I: UI Polish & DICE-Style Aesthetics

**Goal:** Create a premium Gen-Z experience with liquid glass, blur overlays, and animated transitions.

**Story 1.1 – Implement modern UI polish**
- Blur overlays on locked tabs for logged-out users
- Glassmorphism applied to cards and modals (Home, Explore, Events)
- Animated tab bar transitions with bounce effect
- Map toggle view (flat vs heatmap pin view)
- Tinder-style card gestures for "Suggested Events"
- Sticky ticket CTA on event scroll
- On-scroll nav collapse + blur
- Bottom sheet popups: Event info, Checkout

---

## 🔐 Epic II: Soft-Gated Access & Role-Based Onboarding

**Goal:** Let users explore the app without login, then choose a role post-authentication.

**Story 2.1 – Implement soft-gated access and role-based onboarding**
- Allow guest access to Home and Explore tabs
- Blur Friends, Profile, Event Detail, RSVP unless logged in
- Tap restricted tab/button → open login/signup modal
- After login/signup, ask: "Continue as User or Host?"
- Save role in `profiles` table:
    - `is_curator: false` for User
    - `is_curator: true` for Host
- Onboarding flows:
    - User: phone verification → password → genre tags
    - Host: email → password → venue/event selector → redirected to Edit Profile

---

## 🎟 Epic III: Ticketing, RSVP & Checkout (User)

**Goal:** Allow logged-in users to view events, RSVP, and purchase tickets.

**Story 3.1 – Connect Supabase RSVP and ticket checkout**
- Tap “Buy Ticket” CTA on event page
- Load ticket tiers from `ticket_tiers` table
- Quantity selection: + / –
- Enter promo code (optional)
- Summary checkout sheet: title, total, fees
- Purchase creates entry in `tickets` table tied to `auth.uid()`
- QR code is generated and shown under Profile > My Tickets

---

## 👥 Epic IV: Friends, Invites & Guestlist

**Goal:** Build the social layer and guestlist approval logic.

**Story 4.1 – Add friend system, RSVP sharing, and guestlist**
- Create `friends` table: pending/accepted status logic
- Friends tab:
    - News (friend RSVPs, challenges)
    - Friends list + “Quick Message”
    - Requests (pending actions)
- Show bubbles on event cards for mutuals attending
- Invite friends: generate shareable link
- Submit guestlist request:
    - Host must approve
    - Stored in `guestlist_requests`

---

## 🛠 Epic V: Host Tools, Event Management & Analytics

**Goal:** Give hosts the ability to create and manage events, tickets, media, and metrics.

**Story 5.1 – Build out host dashboard and event management**
- Host Create Event screen:
    - Title, flyer (upload), date, location, description
    - Select tags (genre, style, vibe)
    - Ticketing panel: add/edit `ticket_tiers`
    - Guestlist settings: deadline, manual approval toggle
    - Notification settings (reminder options)
- Dashboard:
    - Orders from `tickets`
    - Guestlist management: approve/reject
    - Upload event gallery to Supabase Storage
    - Analytics chart:
        - RSVPs
        - Tickets sold
        - Views / Page visits
        - Impressions

---

## ✅ Epic VI: QR Check-in, Tickets & Event Entry

**Goal:** Create a reliable entry system for event hosts and users.

**Story 6.1 – Ticket scan and event access verification**
- QR assigned to each ticket (unique ID per user/event)
- Host dashboard “Scan Mode”:
    - Camera scanner → validate `tickets`
    - Show attendee details + ticket tier
    - Mark as Checked-In (Supabase flag)
- Manual check-in toggle
- Regenerate QR from Profile > My Tickets
- Host view: list all checked-in attendees

---

## 🧱 Database Schema Assumptions

Ensure Supabase has the following tables:
- `users`, `profiles` (already active)
- `events`, `ticket_tiers`, `tickets`
- `guestlist_requests`, `friends`
- `event_gallery`, `notifications`, `promo_codes` (optional for V2)

---

## 🧪 Dev Instructions (Cursor)

- Use `SupabaseManager.shared.client` for all read/write actions
- Store `auth.uid()` in `host_id`, `user_id`, `created_by`, etc.
- Replace all mock data (`MockEvents`, `DashboardData`, etc.)
- Feed, Profile, Dashboard views should be connected to real data
- Use async/await structure and Supabase `.select().eq().execute()` pattern

---

Project is fully aligned with current Up2 architecture.
No new duplicate services or files required.
Use role-based views to adjust TabView and dashboards accordingly.
