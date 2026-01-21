#!/bin/bash
set -e

DB_CONTAINER="postgres"
DB_NAME="flow"
API_URL="http://localhost:8081"
SECRET_ID="0123456789abcdef"

echo "=== 1. Setting up Test Data in DB '$DB_NAME' ==="

# Adding the location column if missing
docker exec -i $DB_CONTAINER psql -U postgres -d $DB_NAME -c "
DO \$\$
BEGIN
    BEGIN
        ALTER TABLE user_schedule ADD COLUMN location text;
    EXCEPTION
        WHEN duplicate_column THEN RAISE NOTICE 'column location already exists in user_schedule';
    END;
END \$\$;"

# Insert test data
docker exec -i $DB_CONTAINER psql -U postgres -d $DB_NAME <<EOF
-- Create Test User
INSERT INTO "user" (secret_id, first_name, last_name, join_source)
VALUES ('$SECRET_ID', 'Test', 'User', 'email')
ON CONFLICT (secret_id) DO NOTHING;

DELETE FROM section_meeting WHERE section_id = 1;

INSERT INTO section_meeting (
    section_id, location, start_date, end_date, start_seconds, end_seconds, days,
    is_cancelled, is_closed, is_tba
)
VALUES (
    1, 'RCH 301', '2025-09-01', '2025-12-20', 36000, 39600, '{"M", "W", "F"}',
    false, false, false
);


INSERT INTO user_schedule (user_id, section_id)
SELECT id, 1 FROM "user" WHERE secret_id = '$SECRET_ID'
ON CONFLICT DO NOTHING;
EOF

echo "=== 2. Downloading Calendar ==="
curl -f "$API_URL/calendar/$SECRET_ID.ics" -o test_output.ics

echo ""
echo "=== DONE ==="
echo "Check the test_output.ics file generated."
