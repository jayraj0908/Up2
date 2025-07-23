# Core Services

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