package store

import (
	"context"
	"encoding/json"
	"time"
)

// SupplierNotification, tedarikçinin uygulama içi bildirimidir (077 sitesiz kayıt).
type SupplierNotification struct {
	ID        string          `json:"id"`
	Topic     string          `json:"topic"`
	Subject   *string         `json:"subject"`
	Body      string          `json:"body"`
	Payload   json.RawMessage `json:"payload"`
	CreatedAt time.Time       `json:"created_at"`
	ReadAt    *time.Time      `json:"read_at"`
}

// SupplierNotifications, tedarikçinin son bildirimleri ve okunmamış sayısı.
func (s *Store) SupplierNotifications(ctx context.Context, accountID, userID string) ([]SupplierNotification, int, error) {
	rows, err := s.supplier(accountID).Query(ctx, `
		SELECT n.id, n.topic, n.subject, n.body, COALESCE(n.payload, '{}'), n.created_at, r.read_at
		FROM notifications n LEFT JOIN notification_reads r ON r.notification_id = n.id AND r.user_id = $2
		WHERE n.supplier_account_id = $1 AND n.recipient_user_id = $2 AND n.channel = 'IN_APP'
		ORDER BY n.created_at DESC LIMIT 100`, accountID, userID)
	if err != nil {
		return nil, 0, err
	}
	defer rows.Close()
	out := []SupplierNotification{}
	unread := 0
	for rows.Next() {
		var x SupplierNotification
		if err := rows.Scan(&x.ID, &x.Topic, &x.Subject, &x.Body, &x.Payload, &x.CreatedAt, &x.ReadAt); err != nil {
			return nil, 0, err
		}
		if x.ReadAt == nil {
			unread++
		}
		out = append(out, x)
	}
	return out, unread, rows.Err()
}

// MarkSupplierNotificationsRead, verilen (boşsa bütün) bildirimleri okundu sayar; okunan sayıyı döner.
func (s *Store) MarkSupplierNotificationsRead(ctx context.Context, accountID, userID string, ids []string) (int64, error) {
	tag, err := s.supplier(accountID).Exec(ctx, `
		INSERT INTO notification_reads (notification_id, user_id)
		SELECT n.id, $2 FROM notifications n
		WHERE n.supplier_account_id = $1 AND n.recipient_user_id = $2 AND n.channel = 'IN_APP'
		  AND (cardinality($3::uuid[]) = 0 OR n.id = ANY($3::uuid[]))
		ON CONFLICT DO NOTHING`, accountID, userID, ids)
	if err != nil {
		return 0, err
	}
	return tag.RowsAffected(), nil
}
