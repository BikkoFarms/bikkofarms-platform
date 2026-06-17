# Skill Manual: Database Design & Migration

Standards for structuring, updating, and querying our relational database system.

---

## 🎯 Purpose
Maintain database referential integrity, avoid locks during production migration scripts, and achieve high query execution speeds for agricultural logs, user records, and lending accounts.

---

## 💡 Best Practices

* **Migration Integrity:** Maintain a linear, incremental history of migration scripts. Never modify an already deployed database migration file; always write a new migration.
* **Foreign Key Constraints:** Ensure all relational tables define explicit foreign keys with correct deletion policies (`ON DELETE CASCADE` or `ON DELETE SET NULL`).
* **Transactional Locks:** Wrap critical operations containing multiple DB inserts or updates (e.g. loan approval and balance updates) in explicit SQL transactions.
* **UUID Keys:** Use UUIDs (v4) for user IDs, loan IDs, and public tokens to prevent incremental enumeration attacks.

---

## 🛑 Constraints

* **No Production DDL modifications manually:** All schema alterations must go through migration files.
* **Index All Foreign Keys:** Every foreign key column must have an index to ensure joint query speed.
* **Unique Constraints for Logical Keys:** Check double registrations (e.g., a phone number cannot be linked to more than one active farmer profile).

---

## 📐 Code Conventions

* **Linear Migration Naming:** Prefix migration scripts with timestamp formats: `YYYYMMDDHHMMSS_migration_name.sql` (or Prisma/Drizzle conventions).
* **Connection Pool Settings:** Enforce connection pool sizes (`min: 2`, `max: 20`) to prevent crashing the DB cluster during peak traffic loads.

---

## ⚠️ Common Pitfalls

* **Default-less Nullable Columns:** Declaring string fields without defaults, causing database values to toggle unpredictably between `NULL` and empty strings `""`.
* **Locking Entire Tables:** Performing massive updates/alterations on live tables during peak hours without using safe strategies (e.g. creating indexes `CONCURRENTLY` in raw SQL).

---

## ✅ Acceptance Criteria

1. **Successful Rollback:** Every migration contains a valid rollback routine (up and down blocks).
2. **Schema Uniformity:** Development, staging, and production schemas are verified identical.
3. **Optimized execution plans:** No core transaction queries trigger full-table scans.
