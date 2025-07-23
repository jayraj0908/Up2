# Database Schema (Core Entities)

- **Users**: id, name, handle, avatar, vibe_tags[], bio
- **Events**: id, host_id, title, vibe, date, location, capacity, price, is_private, media_refs[]
- **Tickets**: id, user_id, event_id, status (requested/approved/paid), price, promo_used
- **Chats**: id, event_id, message, sender_id, timestamp
- **Media**: id, uploader_id, event_id, type (image/video), tags[], url 