-- Rollback script for initial schema migration

-- Drop triggers
DROP TRIGGER IF EXISTS update_equipment_updated_at ON app.equipment;

-- Drop function
DROP FUNCTION IF EXISTS app.update_updated_at_column();

-- Drop indexes
DROP INDEX IF EXISTS app.idx_sensor_data_equipment_id;
DROP INDEX IF EXISTS app.idx_sensor_data_timestamp;
DROP INDEX IF EXISTS app.idx_equipment_status;

-- Drop tables (in reverse order of dependencies)
DROP TABLE IF EXISTS app.sensor_data;
DROP TABLE IF EXISTS app.equipment;

-- Drop schema
DROP SCHEMA IF EXISTS app CASCADE;
