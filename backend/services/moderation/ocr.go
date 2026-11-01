package main

import (
	"bytes"
	"context"
	"fmt"
	"os/exec"
	"strings"
	"time"
)

// OCR, görseldeki yazıyı Tesseract ile okur (servis kabında kurulu; OCR_COMMAND ile değiştirilebilir — doğrulamada
// Docker sarmalayıcısı). Görsel stdin'den verilir, metin stdout'tan okunur; dosya sistemine yazılmaz.
type OCR struct {
	Command string
	Langs   string
	Timeout time.Duration
}

func (o OCR) Read(ctx context.Context, image []byte) (string, error) {
	ctx, cancel := context.WithTimeout(ctx, o.Timeout)
	defer cancel()
	cmd := exec.CommandContext(ctx, o.Command, "stdin", "stdout", "-l", o.Langs, "--psm", "11")
	cmd.Stdin = bytes.NewReader(image)
	var out, errb bytes.Buffer
	cmd.Stdout, cmd.Stderr = &out, &errb
	if err := cmd.Run(); err != nil {
		return "", fmt.Errorf("OCR çalışmadı (%s): %v %s", o.Command, err, strings.TrimSpace(lastLine(errb.String())))
	}
	return strings.TrimSpace(out.String()), nil
}

func lastLine(s string) string {
	s = strings.TrimSpace(s)
	if i := strings.LastIndexByte(s, '\n'); i >= 0 {
		return s[i+1:]
	}
	return s
}
