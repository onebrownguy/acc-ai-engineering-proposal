-- =====================================================
-- ACC AI Implementation Steering Committee Database
-- PostgreSQL/Supabase Schema
-- Version: 1.0
-- Created: October 13, 2025
-- =====================================================

-- Enable UUID extension for unique identifiers
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- =====================================================
-- TABLE: members
-- Stores all committee member information
-- =====================================================
CREATE TABLE members (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    department VARCHAR(255),
    role_title VARCHAR(255),
    member_type VARCHAR(50) CHECK (member_type IN ('faculty', 'staff', 'student', 'administrator', 'external')),
    status VARCHAR(20) DEFAULT 'active' CHECK (status IN ('active', 'inactive', 'on_leave')),
    expertise_areas TEXT[], -- Array of expertise keywords
    join_date DATE DEFAULT CURRENT_DATE,
    contact_phone VARCHAR(20),
    office_location VARCHAR(255),
    preferred_pronouns VARCHAR(50),
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Index for faster searches
CREATE INDEX idx_members_email ON members(email);
CREATE INDEX idx_members_status ON members(status);
CREATE INDEX idx_members_member_type ON members(member_type);

-- =====================================================
-- TABLE: subcommittees
-- The four main subcommittees
-- =====================================================
CREATE TABLE subcommittees (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(255) NOT NULL UNIQUE,
    slug VARCHAR(100) NOT NULL UNIQUE,
    description TEXT,
    chair_id UUID REFERENCES members(id) ON DELETE SET NULL,
    co_chair_id UUID REFERENCES members(id) ON DELETE SET NULL,
    status VARCHAR(20) DEFAULT 'active' CHECK (status IN ('active', 'inactive', 'archived')),
    formed_date DATE DEFAULT CURRENT_DATE,
    meeting_schedule VARCHAR(255), -- e.g., "Second Tuesday of each month"
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Insert the four subcommittees
INSERT INTO subcommittees (name, slug, description, status, formed_date) VALUES
('Policy Development and Risk Management', 'policy-risk', 'Focuses on governance, compliance, and ethical use of AI', 'active', CURRENT_DATE),
('Institutional Innovation', 'innovation', 'Aims to integrate AI into operations, research, and service', 'active', CURRENT_DATE),
('Educational Framework', 'educational-framework', 'Addresses AI in curricula, pedagogy, and digital literacy', 'active', CURRENT_DATE),
('Implementation and Communication', 'implementation-communication', 'Manages change management, messaging, and rollout strategy', 'active', CURRENT_DATE);

-- =====================================================
-- TABLE: subcommittee_members
-- Many-to-many relationship between members and subcommittees
-- =====================================================
CREATE TABLE subcommittee_members (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    member_id UUID NOT NULL REFERENCES members(id) ON DELETE CASCADE,
    subcommittee_id UUID NOT NULL REFERENCES subcommittees(id) ON DELETE CASCADE,
    role VARCHAR(50) DEFAULT 'member' CHECK (role IN ('chair', 'co-chair', 'member', 'advisor')),
    joined_date DATE DEFAULT CURRENT_DATE,
    left_date DATE,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(member_id, subcommittee_id)
);

CREATE INDEX idx_subcommittee_members_member ON subcommittee_members(member_id);
CREATE INDEX idx_subcommittee_members_subcommittee ON subcommittee_members(subcommittee_id);

-- =====================================================
-- TABLE: charge_suggestions
-- Stores all charge suggestions from members
-- =====================================================
CREATE TABLE charge_suggestions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    member_id UUID REFERENCES members(id) ON DELETE SET NULL,
    title VARCHAR(500) NOT NULL,
    content TEXT NOT NULL,
    submission_date TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    status VARCHAR(30) DEFAULT 'submitted' CHECK (status IN ('draft', 'submitted', 'under_review', 'approved', 'rejected', 'incorporated')),
    priority VARCHAR(20) CHECK (priority IN ('low', 'medium', 'high', 'critical')),
    category VARCHAR(100), -- e.g., 'governance', 'training', 'compliance'
    subcommittee_id UUID REFERENCES subcommittees(id) ON DELETE SET NULL,
    approved_by UUID REFERENCES members(id) ON DELETE SET NULL,
    approval_date TIMESTAMP WITH TIME ZONE,
    implementation_notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_charge_suggestions_member ON charge_suggestions(member_id);
CREATE INDEX idx_charge_suggestions_status ON charge_suggestions(status);
CREATE INDEX idx_charge_suggestions_subcommittee ON charge_suggestions(subcommittee_id);

-- =====================================================
-- TABLE: themes
-- Common themes extracted from charge suggestions
-- =====================================================
CREATE TABLE themes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(255) NOT NULL UNIQUE,
    description TEXT,
    category VARCHAR(100), -- e.g., 'governance', 'education', 'technology'
    priority VARCHAR(20) CHECK (priority IN ('low', 'medium', 'high', 'critical')),
    occurrence_count INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Insert initial themes from analysis
INSERT INTO themes (name, description, category, priority, occurrence_count) VALUES
('Governance & Policy', 'Development of AI governance frameworks and institutional policies', 'governance', 'critical', 12),
('AI Literacy & Training', 'Training programs and professional development for all stakeholders', 'education', 'high', 11),
('Academic Integrity', 'Policies and tools for maintaining academic honesty', 'education', 'high', 7),
('Data Privacy & FERPA', 'Compliance with data protection and student privacy regulations', 'compliance', 'critical', 4),
('Student Success & Equity', 'Ensuring equitable access and positive learning outcomes', 'equity', 'high', 5),
('Operational Efficiency', 'Using AI to improve administrative and operational processes', 'operations', 'medium', 3);

-- =====================================================
-- TABLE: charge_suggestion_themes
-- Many-to-many relationship between charge suggestions and themes
-- =====================================================
CREATE TABLE charge_suggestion_themes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    charge_suggestion_id UUID NOT NULL REFERENCES charge_suggestions(id) ON DELETE CASCADE,
    theme_id UUID NOT NULL REFERENCES themes(id) ON DELETE CASCADE,
    relevance_score INTEGER CHECK (relevance_score BETWEEN 1 AND 10),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(charge_suggestion_id, theme_id)
);

-- =====================================================
-- TABLE: deliverables
-- Tracks major deliverables and their progress
-- =====================================================
CREATE TABLE deliverables (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    title VARCHAR(500) NOT NULL,
    description TEXT,
    subcommittee_id UUID REFERENCES subcommittees(id) ON DELETE SET NULL,
    owner_id UUID REFERENCES members(id) ON DELETE SET NULL,
    status VARCHAR(30) DEFAULT 'not_started' CHECK (status IN ('not_started', 'planning', 'in_progress', 'review', 'completed', 'on_hold', 'cancelled')),
    priority VARCHAR(20) CHECK (priority IN ('low', 'medium', 'high', 'critical')),
    start_date DATE,
    due_date DATE,
    completion_date DATE,
    estimated_hours DECIMAL(10,2),
    actual_hours DECIMAL(10,2),
    dependencies TEXT, -- Comma-separated list of deliverable IDs or descriptions
    success_criteria TEXT,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_deliverables_status ON deliverables(status);
CREATE INDEX idx_deliverables_due_date ON deliverables(due_date);
CREATE INDEX idx_deliverables_subcommittee ON deliverables(subcommittee_id);

-- =====================================================
-- TABLE: action_items
-- Specific tasks that need to be completed
-- =====================================================
CREATE TABLE action_items (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    title VARCHAR(500) NOT NULL,
    description TEXT,
    deliverable_id UUID REFERENCES deliverables(id) ON DELETE CASCADE,
    assigned_to UUID REFERENCES members(id) ON DELETE SET NULL,
    created_by UUID REFERENCES members(id) ON DELETE SET NULL,
    status VARCHAR(30) DEFAULT 'open' CHECK (status IN ('open', 'in_progress', 'blocked', 'completed', 'cancelled')),
    priority VARCHAR(20) CHECK (priority IN ('low', 'medium', 'high', 'urgent')),
    due_date DATE,
    completion_date DATE,
    estimated_hours DECIMAL(10,2),
    actual_hours DECIMAL(10,2),
    blockers TEXT, -- Description of what's blocking progress
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_action_items_assigned_to ON action_items(assigned_to);
CREATE INDEX idx_action_items_status ON action_items(status);
CREATE INDEX idx_action_items_due_date ON action_items(due_date);

-- =====================================================
-- TABLE: milestones
-- Key dates and milestones for the committee
-- =====================================================
CREATE TABLE milestones (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    title VARCHAR(500) NOT NULL,
    description TEXT,
    target_date DATE NOT NULL,
    actual_date DATE,
    milestone_type VARCHAR(50) CHECK (milestone_type IN ('deadline', 'meeting', 'presentation', 'review', 'launch', 'other')),
    status VARCHAR(30) DEFAULT 'upcoming' CHECK (status IN ('upcoming', 'on_track', 'at_risk', 'missed', 'completed')),
    criticality VARCHAR(20) CHECK (criticality IN ('low', 'medium', 'high', 'critical')),
    related_deliverable_id UUID REFERENCES deliverables(id) ON DELETE SET NULL,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_milestones_target_date ON milestones(target_date);
CREATE INDEX idx_milestones_status ON milestones(status);

-- Insert key milestones
INSERT INTO milestones (title, target_date, milestone_type, status, criticality, description) VALUES
('Initial Charge Submissions Due', '2024-10-04', 'deadline', 'completed', 'critical', 'All committee members submit 2-3 bullet points for draft charge suggestions'),
('Review Colleagues Responses Deadline', '2024-10-17', 'deadline', 'on_track', 'high', 'Review all colleague responses before next committee meeting'),
('First Steering Committee Meeting', '2024-10-17', 'meeting', 'upcoming', 'high', 'Initial steering committee gathering to discuss charge suggestions'),
('Subcommittee Formation Complete', '2024-11-01', 'deadline', 'upcoming', 'high', 'All four subcommittees formed with assigned chairs and members'),
('AI Governance Framework Draft', '2024-12-15', 'deadline', 'upcoming', 'critical', 'Complete draft of AI governance framework for review'),
('Preliminary Recommendations Due', '2025-01-31', 'deadline', 'upcoming', 'high', 'All subcommittees submit preliminary recommendations'),
('Stakeholder Feedback Period', '2025-02-28', 'review', 'upcoming', 'medium', 'Collect and incorporate stakeholder feedback on recommendations'),
('Final Framework Presentation', '2025-04-15', 'presentation', 'upcoming', 'critical', 'Present final AI implementation framework to ACC leadership');

-- =====================================================
-- TABLE: meetings
-- Record of all committee and subcommittee meetings
-- =====================================================
CREATE TABLE meetings (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    title VARCHAR(500) NOT NULL,
    meeting_type VARCHAR(50) CHECK (meeting_type IN ('full_committee', 'subcommittee', 'working_group', 'stakeholder', 'other')),
    subcommittee_id UUID REFERENCES subcommittees(id) ON DELETE SET NULL,
    meeting_date DATE NOT NULL,
    start_time TIME,
    end_time TIME,
    location VARCHAR(255), -- Physical location or virtual meeting link
    agenda TEXT,
    notes TEXT,
    decisions_made TEXT,
    action_items_created TEXT,
    attendee_count INTEGER,
    recording_url TEXT,
    document_links TEXT[], -- Array of document URLs
    next_meeting_date DATE,
    status VARCHAR(30) DEFAULT 'scheduled' CHECK (status IN ('scheduled', 'in_progress', 'completed', 'cancelled', 'rescheduled')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_meetings_date ON meetings(meeting_date);
CREATE INDEX idx_meetings_subcommittee ON meetings(subcommittee_id);

-- =====================================================
-- TABLE: meeting_attendees
-- Tracks who attended which meetings
-- =====================================================
CREATE TABLE meeting_attendees (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    meeting_id UUID NOT NULL REFERENCES meetings(id) ON DELETE CASCADE,
    member_id UUID NOT NULL REFERENCES members(id) ON DELETE CASCADE,
    attendance_status VARCHAR(30) CHECK (attendance_status IN ('present', 'absent', 'excused', 'late')),
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(meeting_id, member_id)
);

-- =====================================================
-- TABLE: documents
-- Repository of all committee documents
-- =====================================================
CREATE TABLE documents (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    title VARCHAR(500) NOT NULL,
    description TEXT,
    document_type VARCHAR(50) CHECK (document_type IN ('policy', 'procedure', 'report', 'presentation', 'survey', 'analysis', 'meeting_notes', 'other')),
    file_url TEXT,
    file_size_kb INTEGER,
    subcommittee_id UUID REFERENCES subcommittees(id) ON DELETE SET NULL,
    uploaded_by UUID REFERENCES members(id) ON DELETE SET NULL,
    version VARCHAR(20),
    status VARCHAR(30) CHECK (status IN ('draft', 'review', 'approved', 'archived')),
    tags TEXT[], -- Array of tags for easier searching
    upload_date TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    last_modified TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_documents_type ON documents(document_type);
CREATE INDEX idx_documents_subcommittee ON documents(subcommittee_id);
CREATE INDEX idx_documents_status ON documents(status);

-- =====================================================
-- TABLE: feedback
-- Stakeholder feedback collection
-- =====================================================
CREATE TABLE feedback (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    feedback_type VARCHAR(50) CHECK (feedback_type IN ('survey', 'focus_group', 'comment', 'suggestion', 'concern', 'other')),
    stakeholder_type VARCHAR(50) CHECK (stakeholder_type IN ('student', 'faculty', 'staff', 'administrator', 'external', 'anonymous')),
    member_id UUID REFERENCES members(id) ON DELETE SET NULL, -- NULL if anonymous
    subject VARCHAR(500),
    content TEXT NOT NULL,
    sentiment VARCHAR(20) CHECK (sentiment IN ('positive', 'neutral', 'negative', 'mixed')),
    related_theme_id UUID REFERENCES themes(id) ON DELETE SET NULL,
    status VARCHAR(30) DEFAULT 'new' CHECK (status IN ('new', 'reviewed', 'addressed', 'archived')),
    response TEXT,
    responded_by UUID REFERENCES members(id) ON DELETE SET NULL,
    response_date TIMESTAMP WITH TIME ZONE,
    submission_date TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_feedback_type ON feedback(feedback_type);
CREATE INDEX idx_feedback_stakeholder_type ON feedback(stakeholder_type);
CREATE INDEX idx_feedback_status ON feedback(status);

-- =====================================================
-- VIEWS: Useful queries as views
-- =====================================================

-- Active members with their subcommittee assignments
CREATE VIEW v_active_members_subcommittees AS
SELECT
    m.id as member_id,
    m.first_name,
    m.last_name,
    m.email,
    m.department,
    m.member_type,
    s.name as subcommittee_name,
    sm.role as subcommittee_role
FROM members m
LEFT JOIN subcommittee_members sm ON m.id = sm.member_id AND sm.is_active = true
LEFT JOIN subcommittees s ON sm.subcommittee_id = s.id
WHERE m.status = 'active'
ORDER BY m.last_name, m.first_name;

-- Upcoming deadlines and milestones
CREATE VIEW v_upcoming_deadlines AS
SELECT
    title,
    target_date,
    milestone_type,
    status,
    criticality,
    EXTRACT(DAY FROM (target_date - CURRENT_DATE)) as days_until_due
FROM milestones
WHERE status IN ('upcoming', 'on_track', 'at_risk')
AND target_date >= CURRENT_DATE
ORDER BY target_date;

-- Action items by assignee
CREATE VIEW v_action_items_by_member AS
SELECT
    m.first_name,
    m.last_name,
    m.email,
    ai.title as action_item,
    ai.status,
    ai.priority,
    ai.due_date,
    d.title as deliverable
FROM action_items ai
JOIN members m ON ai.assigned_to = m.id
LEFT JOIN deliverables d ON ai.deliverable_id = d.id
WHERE ai.status IN ('open', 'in_progress', 'blocked')
ORDER BY ai.priority DESC, ai.due_date;

-- Charge suggestion summary by theme
CREATE VIEW v_charge_suggestions_by_theme AS
SELECT
    t.name as theme,
    t.category,
    COUNT(cst.charge_suggestion_id) as suggestion_count,
    t.priority as theme_priority
FROM themes t
LEFT JOIN charge_suggestion_themes cst ON t.id = cst.theme_id
GROUP BY t.id, t.name, t.category, t.priority
ORDER BY suggestion_count DESC;

-- Subcommittee progress dashboard
CREATE VIEW v_subcommittee_progress AS
SELECT
    s.name as subcommittee,
    COUNT(DISTINCT sm.member_id) as member_count,
    COUNT(DISTINCT d.id) as total_deliverables,
    COUNT(DISTINCT CASE WHEN d.status = 'completed' THEN d.id END) as completed_deliverables,
    COUNT(DISTINCT CASE WHEN d.status = 'in_progress' THEN d.id END) as in_progress_deliverables,
    COUNT(DISTINCT ai.id) as total_action_items,
    COUNT(DISTINCT CASE WHEN ai.status = 'completed' THEN ai.id END) as completed_action_items
FROM subcommittees s
LEFT JOIN subcommittee_members sm ON s.id = sm.subcommittee_id AND sm.is_active = true
LEFT JOIN deliverables d ON s.id = d.subcommittee_id
LEFT JOIN action_items ai ON d.id = ai.deliverable_id
WHERE s.status = 'active'
GROUP BY s.id, s.name;

-- =====================================================
-- FUNCTIONS: Useful database functions
-- =====================================================

-- Function to update the updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Apply the trigger to all relevant tables
CREATE TRIGGER update_members_updated_at BEFORE UPDATE ON members FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_subcommittees_updated_at BEFORE UPDATE ON subcommittees FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_charge_suggestions_updated_at BEFORE UPDATE ON charge_suggestions FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_deliverables_updated_at BEFORE UPDATE ON deliverables FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_action_items_updated_at BEFORE UPDATE ON action_items FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_milestones_updated_at BEFORE UPDATE ON milestones FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_meetings_updated_at BEFORE UPDATE ON meetings FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_documents_updated_at BEFORE UPDATE ON documents FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- =====================================================
-- SAMPLE QUERIES FOR COMMON USE CASES
-- =====================================================

-- Query 1: Find all members who haven't submitted charge suggestions
-- SELECT m.first_name, m.last_name, m.email
-- FROM members m
-- LEFT JOIN charge_suggestions cs ON m.id = cs.member_id
-- WHERE cs.id IS NULL AND m.status = 'active'
-- ORDER BY m.last_name;

-- Query 2: Get all high-priority action items due this week
-- SELECT ai.title, m.first_name, m.last_name, ai.due_date, ai.status
-- FROM action_items ai
-- JOIN members m ON ai.assigned_to = m.id
-- WHERE ai.priority IN ('high', 'urgent')
-- AND ai.due_date BETWEEN CURRENT_DATE AND CURRENT_DATE + INTERVAL '7 days'
-- AND ai.status NOT IN ('completed', 'cancelled')
-- ORDER BY ai.due_date;

-- Query 3: Subcommittee member roster with contact info
-- SELECT s.name as subcommittee, m.first_name, m.last_name, m.email, m.contact_phone, sm.role
-- FROM subcommittees s
-- JOIN subcommittee_members sm ON s.id = sm.subcommittee_id
-- JOIN members m ON sm.member_id = m.id
-- WHERE sm.is_active = true
-- ORDER BY s.name, sm.role DESC, m.last_name;

-- Query 4: Meeting attendance summary
-- SELECT m.first_name, m.last_name,
--        COUNT(ma.meeting_id) as meetings_attended,
--        COUNT(CASE WHEN ma.attendance_status = 'absent' THEN 1 END) as meetings_missed
-- FROM members m
-- LEFT JOIN meeting_attendees ma ON m.id = ma.member_id
-- GROUP BY m.id, m.first_name, m.last_name
-- ORDER BY meetings_attended DESC;

-- =====================================================
-- NOTES FOR IMPLEMENTATION
-- =====================================================

-- 1. Row Level Security (RLS) Setup:
--    Enable RLS on all tables and create appropriate policies
--    based on user roles (admin, chair, member, read-only)

-- 2. Backup Strategy:
--    Set up automated daily backups of the database
--    Use pg_dump or Supabase built-in backup features

-- 3. Data Privacy:
--    Ensure FERPA compliance - encrypt sensitive student data
--    Consider anonymization for survey/feedback data

-- 4. API Integration:
--    Use Supabase auto-generated REST API or GraphQL
--    Create serverless functions for complex operations

-- 5. Frontend Integration:
--    Connect Next.js or React frontend using Supabase client
--    Implement real-time subscriptions for collaborative features

-- =====================================================
-- END OF SCHEMA
-- =====================================================
