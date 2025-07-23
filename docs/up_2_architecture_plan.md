**Architecture Plan: Up2 iOS App**

---

**Overview**  
This document outlines the technical architecture for Up2, a real-time nightlife social platform built natively for iOS. Up2 allows users to host and attend events, discover parties via AI recommendations, and engage through chats, invites, and media sharing. The backend is fully serverless and scalable using modern tools like Supabase, Stripe, and real-time APIs.

---

**Tech Stack**
- **Frontend:** Swift (iOS native)
- **Backend:** Node.js (tRPC or REST API via Next.js API routes)
- **Hosting:** Vercel or Fly.io
- **Database:** Supabase (PostgreSQL with RLS)
- **Auth:** Supabase Auth or Clerk
- **Real-Time:** Supabase Realtime (Postgres CDC) or Pusher Channels
- **Payments:** Stripe Connect
- **Storage:** Supabase Storage or Cloudflare R2
- **Search & AI Discovery:** PGVector + Supabase or Typesense

---

**Core Services**

1. **Authentication & Profiles**
   - Email/SMS signup & login
   - Social login optional
   - RLS rules enforce user-specific access

2. **Event Service**
   - Create/edit/delete event
   - Public or private flag
   - Guestlist control (auto/manual approval)
   - Embedded ticketing (capacity, price, promo code)
   - Event status (active, ended, cancelled)

3. **User Discovery Engine**
   - Mood tag input
   - AI scoring: vibe match, location, friend attendance
   - Returns ranked list of recommended events

4. **Ticketing & Payments**
   - Stripe Connect accounts per host
   - Commission logic built in
   - Guest charged only after approval (for private events)
   - Webhook-based transaction confirmation

5. **Media & Social Feed**
   - Event-specific media bucket
   - Images/videos with metadata (user, tags, timestamp)
   - Feed queries by event ID or user profile

6. **Chat & Notifications**
   - Real-time chat for each event (unlocked 24h before start)
   - Push notifications for invites, approval, ticket changes
   - PubSub or presence sync via Supabase Realtime

---

**Database Schema (Core Entities)**
- **Users**: id, name, handle, avatar, vibe_tags[], bio
- **Events**: id, host_id, title, vibe, date, location, capacity, price, is_private, media_refs[]
- **Tickets**: id, user_id, event_id, status (requested/approved/paid), price, promo_used
- **Chats**: id, event_id, message, sender_id, timestamp
- **Media**: id, uploader_id, event_id, type (image/video), tags[], url

---

**Security & Moderation**
- RLS ensures guests can only see events they’re approved for
- Media flagged via user reports (manual review at MVP)
- Event host block/report tools

---

**Scalability Notes**
- PostgreSQL via Supabase scales horizontally with read replicas
- Real-time feeds use CDC + optional rate limits for active events
- Media offloaded to object storage (no DB bloat)
- Stripe ensures PCI compliance and financial auditability

---

**Next Steps**
- Finalize DB schema in Supabase and test rules
- Scaffold API layer (tRPC or REST)
- Integrate Stripe Connect with approval-based charge logic
- Set up local + staging environments for dev workflow

