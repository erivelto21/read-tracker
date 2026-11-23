package crawler

import "testing"

func TestExtractChapterNumber(t *testing.T) {
	t.Parallel()

	tests := []struct {
		name   string
		raw    string
		want   float64
		wantOK bool
	}{
		{name: "plain integer", raw: "Chapter 222", want: 222, wantOK: true},
		{name: "decimal chapter", raw: "Chapter 222.5", want: 222.5, wantOK: true},
		{name: "number without a label", raw: "87", want: 87, wantOK: true},
		{name: "leading zeros", raw: "Chapter 007", want: 7, wantOK: true},
		{name: "number inside surrounding text", raw: "Capítulo 105.5 - novo", want: 105.5, wantOK: true},
		{name: "empty text has no number", raw: "", wantOK: false},
		{name: "text without a number", raw: "Prologue", wantOK: false},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			t.Parallel()

			got, ok := extractChapterNumber(tt.raw)
			if ok != tt.wantOK {
				t.Fatalf("ok = %v, want %v", ok, tt.wantOK)
			}
			if ok && got != tt.want {
				t.Errorf("number = %v, want %v", got, tt.want)
			}
		})
	}
}
