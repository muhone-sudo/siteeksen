package listcap

import "testing"

func TestTrim(t *testing.T) {
	items := make([]int, Default+1)
	out, cut := Trim(items, Default)
	if len(out) != Default || !cut {
		t.Fatalf("tavan+1: %d %v", len(out), cut)
	}
	out, cut = Trim(items[:Default], Default)
	if len(out) != Default || cut {
		t.Fatalf("tam tavan kesilmiş sayıldı: %d %v", len(out), cut)
	}
	if out, cut = Trim([]int{}, Default); len(out) != 0 || cut {
		t.Fatal("boş liste")
	}
}
