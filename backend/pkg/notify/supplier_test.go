package notify

import (
	"errors"
	"testing"
)

// Bildirim ya bir siteye ya bir tedarikçi hesabına aittir (077).
func TestValidateSiteOrSupplier(t *testing.T) {
	base := Message{Recipient: "u", Body: "b", Channel: ChannelInApp}
	both := base
	both.PropertyID, both.SupplierAccountID = "p", "s"
	if err := validate(&both); !errors.Is(err, ErrBothScopes) {
		t.Fatalf("ikisi birden: %v", err)
	}
	sup := base
	sup.SupplierAccountID = "s"
	if err := validate(&sup); err != nil {
		t.Fatalf("yalnız tedarikçi geçerli olmalıydı: %v", err)
	}
}
