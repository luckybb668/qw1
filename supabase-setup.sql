-- HotWeb3.io Supabase Database Setup
-- Run this SQL in your Supabase SQL editor to set up the database schema

-- Enable necessary extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Create custom types
CREATE TYPE project_status AS ENUM ('active', 'new', 'trending', 'rising');

-- Create projects table
CREATE TABLE IF NOT EXISTS projects (
    id TEXT PRIMARY KEY DEFAULT uuid_generate_v4()::text,
    name TEXT NOT NULL,
    logo TEXT NOT NULL,
    intro TEXT NOT NULL,
    description TEXT NOT NULL,
    categories TEXT[] NOT NULL DEFAULT '{}',
    chains TEXT[] NOT NULL DEFAULT '{}',
    twitter_url TEXT,
    telegram_url TEXT,
    discord_url TEXT,
    website_url TEXT,
    heat_score INTEGER NOT NULL DEFAULT 0,
    source_platform TEXT NOT NULL DEFAULT 'manual',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    market_cap TEXT,
    volume_24h TEXT,
    price_change_24h DECIMAL,
    followers JSONB,
    tags TEXT[] DEFAULT '{}',
    status project_status DEFAULT 'active'
);

-- Create sectors table
CREATE TABLE IF NOT EXISTS sectors (
    id TEXT PRIMARY KEY DEFAULT uuid_generate_v4()::text,
    name TEXT NOT NULL UNIQUE,
    heat_score INTEGER NOT NULL DEFAULT 0,
    project_count INTEGER NOT NULL DEFAULT 0,
    color TEXT NOT NULL DEFAULT 'crypto-blue',
    change_24h DECIMAL NOT NULL DEFAULT 0,
    description TEXT NOT NULL,
    top_projects TEXT[] DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create heat_history table for tracking heat score changes
CREATE TABLE IF NOT EXISTS heat_history (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    project_id TEXT NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
    heat_score INTEGER NOT NULL,
    recorded_at TIMESTAMPTZ DEFAULT NOW(),
    metadata JSONB
);

-- Create twitter_metrics table for storing Twitter data
CREATE TABLE IF NOT EXISTS twitter_metrics (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    project_id TEXT NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
    followers_count INTEGER NOT NULL DEFAULT 0,
    mentions_24h INTEGER NOT NULL DEFAULT 0,
    engagement_rate DECIMAL NOT NULL DEFAULT 0,
    recorded_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_projects_heat_score ON projects(heat_score DESC);
CREATE INDEX IF NOT EXISTS idx_projects_status ON projects(status);
CREATE INDEX IF NOT EXISTS idx_projects_categories ON projects USING GIN(categories);
CREATE INDEX IF NOT EXISTS idx_projects_chains ON projects USING GIN(chains);
CREATE INDEX IF NOT EXISTS idx_projects_updated_at ON projects(updated_at DESC);

CREATE INDEX IF NOT EXISTS idx_sectors_heat_score ON sectors(heat_score DESC);
CREATE INDEX IF NOT EXISTS idx_sectors_name ON sectors(name);

CREATE INDEX IF NOT EXISTS idx_heat_history_project_id ON heat_history(project_id);
CREATE INDEX IF NOT EXISTS idx_heat_history_recorded_at ON heat_history(recorded_at DESC);

CREATE INDEX IF NOT EXISTS idx_twitter_metrics_project_id ON twitter_metrics(project_id);
CREATE INDEX IF NOT EXISTS idx_twitter_metrics_recorded_at ON twitter_metrics(recorded_at DESC);

-- Create functions for automatic timestamp updates
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Create triggers for automatic timestamp updates
CREATE TRIGGER update_projects_updated_at BEFORE UPDATE ON projects
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_sectors_updated_at BEFORE UPDATE ON sectors
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Create function to update sector statistics
CREATE OR REPLACE FUNCTION update_sector_stats()
RETURNS TRIGGER AS $$
BEGIN
    -- Update project count and heat score for affected sectors
    WITH sector_stats AS (
        SELECT 
            unnest(categories) as sector_name,
            COUNT(*) as project_count,
            AVG(heat_score)::INTEGER as avg_heat_score
        FROM projects 
        WHERE status = 'active'
        GROUP BY unnest(categories)
    )
    UPDATE sectors 
    SET 
        project_count = sector_stats.project_count,
        heat_score = sector_stats.avg_heat_score,
        updated_at = NOW()
    FROM sector_stats 
    WHERE sectors.name = sector_stats.sector_name;
    
    RETURN NULL;
END;
$$ language 'plpgsql';

-- Create trigger to automatically update sector stats when projects change
CREATE TRIGGER update_sector_stats_trigger 
    AFTER INSERT OR UPDATE OR DELETE ON projects
    FOR EACH STATEMENT EXECUTE FUNCTION update_sector_stats();

-- Create function to record heat score history
CREATE OR REPLACE FUNCTION record_heat_score_change()
RETURNS TRIGGER AS $$
BEGIN
    -- Only record if heat_score actually changed
    IF OLD.heat_score IS DISTINCT FROM NEW.heat_score THEN
        INSERT INTO heat_history (project_id, heat_score, metadata)
        VALUES (
            NEW.id, 
            NEW.heat_score,
            jsonb_build_object(
                'previous_score', OLD.heat_score,
                'change', NEW.heat_score - OLD.heat_score,
                'source', 'automatic'
            )
        );
    END IF;
    
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Create trigger to record heat score changes
CREATE TRIGGER record_heat_score_change_trigger 
    AFTER UPDATE ON projects
    FOR EACH ROW EXECUTE FUNCTION record_heat_score_change();

-- Enable Row Level Security (RLS)
ALTER TABLE projects ENABLE ROW LEVEL SECURITY;
ALTER TABLE sectors ENABLE ROW LEVEL SECURITY;
ALTER TABLE heat_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE twitter_metrics ENABLE ROW LEVEL SECURITY;

-- Create policies for public read access (no authentication required)
CREATE POLICY "Public read access for projects" ON projects FOR SELECT USING (true);
CREATE POLICY "Public read access for sectors" ON sectors FOR SELECT USING (true);
CREATE POLICY "Public read access for heat_history" ON heat_history FOR SELECT USING (true);
CREATE POLICY "Public read access for twitter_metrics" ON twitter_metrics FOR SELECT USING (true);

-- Create policies for service role access (for API updates)
CREATE POLICY "Service role full access for projects" ON projects FOR ALL USING (auth.role() = 'service_role');
CREATE POLICY "Service role full access for sectors" ON sectors FOR ALL USING (auth.role() = 'service_role');
CREATE POLICY "Service role full access for heat_history" ON heat_history FOR ALL USING (auth.role() = 'service_role');
CREATE POLICY "Service role full access for twitter_metrics" ON twitter_metrics FOR ALL USING (auth.role() = 'service_role');

-- Insert initial sector data
INSERT INTO sectors (id, name, heat_score, project_count, color, change_24h, description) VALUES
('ai', 'AI', 45600, 12, 'crypto-purple', 15.4, 'Artificial Intelligence and Machine Learning projects'),
('depin', 'DePIN', 38200, 8, 'crypto-blue', 8.7, 'Decentralized Physical Infrastructure Networks'),
('socialfi', 'SocialFi', 35900, 15, 'crypto-green', 22.1, 'Social Finance and Decentralized Social Networks'),
('defi', 'DeFi', 42100, 45, 'crypto-orange', 5.3, 'Decentralized Finance protocols and applications'),
('zk', 'ZK', 28500, 7, 'crypto-red', -2.1, 'Zero-Knowledge proof technology and applications'),
('layer2', 'Layer2', 31200, 18, 'crypto-blue', 12.8, 'Layer 2 scaling solutions for Ethereum'),
('nft', 'NFT', 15600, 22, 'crypto-purple', -5.2, 'Non-Fungible Tokens and digital collectibles'),
('gamefi', 'GameFi', 19800, 13, 'crypto-green', 7.9, 'Gaming and Play-to-Earn applications'),
('memecoin', 'Memecoin', 52300, 35, 'crypto-orange', 45.6, 'Community-driven meme cryptocurrencies'),
('infrastructure', 'Infrastructure', 25400, 9, 'crypto-blue', 3.2, 'Blockchain infrastructure and developer tools')
ON CONFLICT (name) DO UPDATE SET
    heat_score = EXCLUDED.heat_score,
    change_24h = EXCLUDED.change_24h,
    description = EXCLUDED.description,
    updated_at = NOW();

-- Create view for project analytics
CREATE OR REPLACE VIEW project_analytics AS
SELECT 
    p.*,
    COALESCE(tm.followers_count, 0) as twitter_followers,
    COALESCE(tm.mentions_24h, 0) as twitter_mentions_24h,
    COALESCE(tm.engagement_rate, 0) as twitter_engagement_rate,
    (
        SELECT COUNT(*) 
        FROM heat_history h 
        WHERE h.project_id = p.id 
        AND h.recorded_at > NOW() - INTERVAL '24 hours'
    ) as heat_changes_24h
FROM projects p
LEFT JOIN LATERAL (
    SELECT followers_count, mentions_24h, engagement_rate
    FROM twitter_metrics tm
    WHERE tm.project_id = p.id
    ORDER BY tm.recorded_at DESC
    LIMIT 1
) tm ON true;

-- Create view for trending projects
CREATE OR REPLACE VIEW trending_projects AS
SELECT 
    *,
    ROW_NUMBER() OVER (ORDER BY heat_score DESC, updated_at DESC) as rank
FROM project_analytics
WHERE status = 'trending'
ORDER BY heat_score DESC;

-- Create function to get sector leaderboard
CREATE OR REPLACE FUNCTION get_sector_leaderboard(time_period TEXT DEFAULT '24h')
RETURNS TABLE (
    sector_name TEXT,
    current_heat_score INTEGER,
    project_count BIGINT,
    avg_change_24h DECIMAL,
    top_project_name TEXT
) 
LANGUAGE SQL
AS $$
    SELECT 
        s.name,
        s.heat_score,
        s.project_count::BIGINT,
        s.change_24h,
        (
            SELECT p.name 
            FROM projects p 
            WHERE s.name = ANY(p.categories)
            ORDER BY p.heat_score DESC 
            LIMIT 1
        ) as top_project_name
    FROM sectors s
    ORDER BY s.heat_score DESC;
$$;

-- Grant usage permissions
GRANT USAGE ON SCHEMA public TO anon, authenticated;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO anon, authenticated;
GRANT ALL ON ALL TABLES IN SCHEMA public TO service_role;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO anon, authenticated, service_role;

-- Success message
SELECT 'HotWeb3.io database setup completed successfully!' as message;
