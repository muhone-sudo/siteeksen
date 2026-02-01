package encryption

import (
	"crypto/aes"
	"crypto/cipher"
	"crypto/rand"
	"crypto/sha256"
	"encoding/base64"
	"errors"
	"io"
)

// Service AES-256 şifreleme servisi
type Service struct {
	key []byte
}

// NewService yeni şifreleme servisi oluşturur
func NewService(keyBase64 string) (*Service, error) {
	key, err := base64.StdEncoding.DecodeString(keyBase64)
	if err != nil {
		return nil, errors.New("geçersiz base64 anahtar")
	}
	if len(key) != 32 {
		return nil, errors.New("anahtar 32 byte (256 bit) olmalı")
	}
	return &Service{key: key}, nil
}

// Encrypt metni AES-256-GCM ile şifreler
func (s *Service) Encrypt(plaintext string) (string, error) {
	block, err := aes.NewCipher(s.key)
	if err != nil {
		return "", err
	}

	gcm, err := cipher.NewGCM(block)
	if err != nil {
		return "", err
	}

	nonce := make([]byte, gcm.NonceSize())
	if _, err := io.ReadFull(rand.Reader, nonce); err != nil {
		return "", err
	}

	ciphertext := gcm.Seal(nonce, nonce, []byte(plaintext), nil)
	return base64.StdEncoding.EncodeToString(ciphertext), nil
}

// Decrypt şifreli metni çözer
func (s *Service) Decrypt(ciphertext string) (string, error) {
	data, err := base64.StdEncoding.DecodeString(ciphertext)
	if err != nil {
		return "", err
	}

	block, err := aes.NewCipher(s.key)
	if err != nil {
		return "", err
	}

	gcm, err := cipher.NewGCM(block)
	if err != nil {
		return "", err
	}

	nonceSize := gcm.NonceSize()
	if len(data) < nonceSize {
		return "", errors.New("şifreli veri çok kısa")
	}

	nonce, ciphertextBytes := data[:nonceSize], data[nonceSize:]
	plaintext, err := gcm.Open(nil, nonce, ciphertextBytes, nil)
	if err != nil {
		return "", err
	}

	return string(plaintext), nil
}

// Hash SHA-256 hash oluşturur (arama için)
func Hash(data string) string {
	hash := sha256.Sum256([]byte(data))
	return base64.StdEncoding.EncodeToString(hash[:])
}

// MaskTCKN TCKN'yi maskeler (****12345678)
func MaskTCKN(tckn string) string {
	if len(tckn) < 4 {
		return "****"
	}
	return "****" + tckn[len(tckn)-8:]
}
