-- Initial database schema for Ignition
-- This migration creates the basic tables needed for the application

-- Create extension for UUID support (if not exists)
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Create schema for application data
CREATE SCHEMA IF NOT EXISTS app;

-- Example: Equipment table
CREATE TABLE IF NOT EXISTS app.equipment (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(255) NOT NULL,
    description TEXT,
    location VARCHAR(255),
    status VARCHAR(50) DEFAULT 'active',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Example: Sensor data table
CREATE TABLE IF NOT EXISTS app.sensor_data (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    equipment_id UUID REFERENCES app.equipment(id) ON DELETE CASCADE,
    sensor_name VARCHAR(255) NOT NULL,
    value NUMERIC(10, 2),
    unit VARCHAR(50),
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    quality VARCHAR(50) DEFAULT 'good'
);

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_equipment_status ON app.equipment(status);
CREATE INDEX IF NOT EXISTS idx_sensor_data_timestamp ON app.sensor_data(timestamp);
CREATE INDEX IF NOT EXISTS idx_sensor_data_equipment_id ON app.sensor_data(equipment_id);

-- Create function to update updated_at timestamp
CREATE OR REPLACE FUNCTION app.update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Create trigger for equipment table
CREATE TRIGGER update_equipment_updated_at
    BEFORE UPDATE ON app.equipment
    FOR EACH ROW
    EXECUTE FUNCTION app.update_updated_at_column();
