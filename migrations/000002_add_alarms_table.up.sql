-- Add alarms table for tracking system alarms

CREATE TABLE IF NOT EXISTS app.alarms (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    equipment_id UUID REFERENCES app.equipment(id) ON DELETE CASCADE,
    alarm_name VARCHAR(255) NOT NULL,
    alarm_priority VARCHAR(50) DEFAULT 'medium',
    alarm_state VARCHAR(50) DEFAULT 'active',
    message TEXT,
    acknowledged BOOLEAN DEFAULT FALSE,
    acknowledged_by VARCHAR(255),
    acknowledged_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    cleared_at TIMESTAMP
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_alarms_equipment_id ON app.alarms(equipment_id);
CREATE INDEX IF NOT EXISTS idx_alarms_state ON app.alarms(alarm_state);
CREATE INDEX IF NOT EXISTS idx_alarms_priority ON app.alarms(alarm_priority);
CREATE INDEX IF NOT EXISTS idx_alarms_acknowledged ON app.alarms(acknowledged);

-- Add comments
COMMENT ON TABLE app.alarms IS 'Stores alarm history and current alarms for equipment';
COMMENT ON COLUMN app.alarms.alarm_priority IS 'Priority levels: critical, high, medium, low';
COMMENT ON COLUMN app.alarms.alarm_state IS 'Alarm states: active, cleared, shelved';
