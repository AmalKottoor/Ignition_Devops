-- Rollback script for alarms table

-- Drop indexes
DROP INDEX IF EXISTS app.idx_alarms_acknowledged;
DROP INDEX IF EXISTS app.idx_alarms_priority;
DROP INDEX IF EXISTS app.idx_alarms_state;
DROP INDEX IF EXISTS app.idx_alarms_equipment_id;

-- Drop table
DROP TABLE IF EXISTS app.alarms;
