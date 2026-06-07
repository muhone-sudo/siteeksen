package audit

import (
	"context"
	"encoding/json"

	"github.com/jackc/pgx/v5/pgxpool"
)

// LogAction audit_logs tablosuna bir kayıt ekler.
// userID, resourceID boş string olabilir (sistem aksiyonları veya kaynak ID bilinmiyorsa) — bu durumda NULL yazılır.
// oldValues/newValues nil olabilir; verilirse JSONB olarak saklanır.
func LogAction(ctx context.Context, pool *pgxpool.Pool, userID, userIP, userAgent, action, resourceType, resourceID string, oldValues, newValues interface{}) error {
	if pool == nil {
		return nil
	}

	oldJSON, err := marshalOrNil(oldValues)
	if err != nil {
		return err
	}
	newJSON, err := marshalOrNil(newValues)
	if err != nil {
		return err
	}

	query := `
		INSERT INTO audit_logs (user_id, user_ip, user_agent, action, resource_type, resource_id, old_values, new_values)
		VALUES (NULLIF($1, '')::uuid, NULLIF($2, '')::inet, NULLIF($3, ''), $4, $5, NULLIF($6, '')::uuid, $7, $8)
	`
	_, err = pool.Exec(ctx, query, userID, userIP, userAgent, action, resourceType, resourceID, oldJSON, newJSON)
	return err
}

func marshalOrNil(v interface{}) ([]byte, error) {
	if v == nil {
		return nil, nil
	}
	return json.Marshal(v)
}
