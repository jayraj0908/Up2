# Scalability Notes

- PostgreSQL via Supabase scales horizontally with read replicas
- Real-time feeds use CDC + optional rate limits for active events
- Media offloaded to object storage (no DB bloat)
- Stripe ensures PCI compliance and financial auditability 