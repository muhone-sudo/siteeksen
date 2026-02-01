package notification

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"net/http"
	"os"
	"time"

	"golang.org/x/oauth2/google"
)

// FCMClient - Firebase Cloud Messaging client
type FCMClient struct {
	projectID   string
	credentials []byte
	httpClient  *http.Client
}

// NewFCMClient - yeni FCM client oluştur
func NewFCMClient() (*FCMClient, error) {
	projectID := os.Getenv("FIREBASE_PROJECT_ID")
	credPath := os.Getenv("GOOGLE_APPLICATION_CREDENTIALS")

	var credentials []byte
	if credPath != "" {
		var err error
		credentials, err = os.ReadFile(credPath)
		if err != nil {
			return nil, fmt.Errorf("credentials okunamadı: %w", err)
		}
	}

	return &FCMClient{
		projectID:   projectID,
		credentials: credentials,
		httpClient:  &http.Client{Timeout: 30 * time.Second},
	}, nil
}

// FCMMessage - FCM mesaj yapısı
type FCMMessage struct {
	Message struct {
		Token        string            `json:"token,omitempty"`
		Topic        string            `json:"topic,omitempty"`
		Condition    string            `json:"condition,omitempty"`
		Notification *FCMNotification  `json:"notification,omitempty"`
		Data         map[string]string `json:"data,omitempty"`
		Android      *AndroidConfig    `json:"android,omitempty"`
		APNS         *APNSConfig       `json:"apns,omitempty"`
	} `json:"message"`
}

type FCMNotification struct {
	Title string `json:"title"`
	Body  string `json:"body"`
	Image string `json:"image,omitempty"`
}

type AndroidConfig struct {
	Priority     string                 `json:"priority,omitempty"`
	Notification *AndroidNotification   `json:"notification,omitempty"`
}

type AndroidNotification struct {
	Icon              string `json:"icon,omitempty"`
	Color             string `json:"color,omitempty"`
	ClickAction       string `json:"click_action,omitempty"`
	ChannelID         string `json:"channel_id,omitempty"`
	NotificationCount int    `json:"notification_count,omitempty"`
}

type APNSConfig struct {
	Headers map[string]string `json:"headers,omitempty"`
	Payload *APNSPayload      `json:"payload,omitempty"`
}

type APNSPayload struct {
	Aps *ApsPayload `json:"aps,omitempty"`
}

type ApsPayload struct {
	Alert            interface{} `json:"alert,omitempty"`
	Badge            int         `json:"badge,omitempty"`
	Sound            string      `json:"sound,omitempty"`
	ContentAvailable int         `json:"content-available,omitempty"`
	MutableContent   int         `json:"mutable-content,omitempty"`
}

// SendResponse - gönderim yanıtı
type SendResponse struct {
	Name         string `json:"name,omitempty"`
	Error        *FCMError `json:"error,omitempty"`
}

type FCMError struct {
	Code    int    `json:"code"`
	Message string `json:"message"`
	Status  string `json:"status"`
}

// getAccessToken - OAuth2 token al
func (c *FCMClient) getAccessToken(ctx context.Context) (string, error) {
	config, err := google.JWTConfigFromJSON(c.credentials, "https://www.googleapis.com/auth/firebase.messaging")
	if err != nil {
		return "", err
	}

	token, err := config.TokenSource(ctx).Token()
	if err != nil {
		return "", err
	}

	return token.AccessToken, nil
}

// SendToDevice - tek cihaza bildirim gönder
func (c *FCMClient) SendToDevice(ctx context.Context, token string, title, body string, data map[string]string) (*SendResponse, error) {
	msg := FCMMessage{}
	msg.Message.Token = token
	msg.Message.Notification = &FCMNotification{
		Title: title,
		Body:  body,
	}
	msg.Message.Data = data
	msg.Message.Android = &AndroidConfig{
		Priority: "high",
		Notification: &AndroidNotification{
			ChannelID: "siteeksen_default",
			Color:     "#2563EB",
		},
	}
	msg.Message.APNS = &APNSConfig{
		Headers: map[string]string{"apns-priority": "10"},
		Payload: &APNSPayload{
			Aps: &ApsPayload{
				Sound:          "default",
				MutableContent: 1,
			},
		},
	}

	return c.send(ctx, msg)
}

// SendToTopic - topic'e bildirim gönder
func (c *FCMClient) SendToTopic(ctx context.Context, topic string, title, body string, data map[string]string) (*SendResponse, error) {
	msg := FCMMessage{}
	msg.Message.Topic = topic
	msg.Message.Notification = &FCMNotification{
		Title: title,
		Body:  body,
	}
	msg.Message.Data = data

	return c.send(ctx, msg)
}

func (c *FCMClient) send(ctx context.Context, msg FCMMessage) (*SendResponse, error) {
	accessToken, err := c.getAccessToken(ctx)
	if err != nil {
		return nil, fmt.Errorf("token alınamadı: %w", err)
	}

	body, err := json.Marshal(msg)
	if err != nil {
		return nil, err
	}

	url := fmt.Sprintf("https://fcm.googleapis.com/v1/projects/%s/messages:send", c.projectID)

	req, err := http.NewRequestWithContext(ctx, "POST", url, bytes.NewBuffer(body))
	if err != nil {
		return nil, err
	}

	req.Header.Set("Authorization", "Bearer "+accessToken)
	req.Header.Set("Content-Type", "application/json")

	resp, err := c.httpClient.Do(req)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()

	var result SendResponse
	if err := json.NewDecoder(resp.Body).Decode(&result); err != nil {
		return nil, err
	}

	return &result, nil
}
