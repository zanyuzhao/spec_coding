-- SQLite 初始化脚本
-- 用于创建开发数据库表结构

-- 示例表：specs 存储 spec 文档信息
CREATE TABLE IF NOT EXISTS specs (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    status TEXT DEFAULT 'proposal',
    content TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 示例表：features 存储 feature 信息
CREATE TABLE IF NOT EXISTS features (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    spec_id INTEGER,
    description TEXT NOT NULL,
    category TEXT,
    passes BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (spec_id) REFERENCES specs(id)
);

-- 插入测试数据
INSERT INTO specs (name, status, content) VALUES
    ('test_spec', 'proposal', 'This is a test spec for MCP verification');

INSERT INTO features (spec_id, description, category, passes) VALUES
    (1, 'Test feature for MCP', 'test', FALSE);
