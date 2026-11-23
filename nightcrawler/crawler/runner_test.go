package crawler_test

import (
	"context"
	"errors"
	"strings"
	"testing"

	"github.com/PuerkitoBio/goquery"

	"github.com/erivelto/read-tracker/nightcrawler/crawler"
	"github.com/erivelto/read-tracker/nightcrawler/repository"
)

// fakeTitleSource is a test double for the crawlable-title reader.
type fakeTitleSource struct {
	titles []repository.TrackedTitle
	err    error
}

func (f *fakeTitleSource) FindCrawlable(_ context.Context) ([]repository.TrackedTitle, error) {
	if f.err != nil {
		return nil, f.err
	}
	return f.titles, nil
}

// fakeNotifier records the notifications the runner emits.
type fakeNotifier struct {
	calls []notificationCall
}

type notificationCall struct {
	name    string
	chapter float64
}

func (f *fakeNotifier) Notify(name string, chapter float64) {
	f.calls = append(f.calls, notificationCall{name: name, chapter: chapter})
}

// page builds a document from HTML, standing in for a fetched page.
func page(t *testing.T, html string) *goquery.Document {
	t.Helper()
	doc, err := goquery.NewDocumentFromReader(strings.NewReader(html))
	if err != nil {
		t.Fatalf("parse fixture: %v", err)
	}
	return doc
}

func TestRunner_NotifiesOnlyWhenANewerChapterExists(t *testing.T) {
	t.Parallel()

	tests := []struct {
		name         string
		chapter      float64
		html         string
		wantNotified bool
		wantChapter  float64
	}{
		{
			name:         "newer chapter is notified",
			chapter:      100,
			html:         `<ul id="chapters-list"><li><a>Chapter 105</a></li><li><a>Chapter 104</a></li></ul>`,
			wantNotified: true,
			wantChapter:  105,
		},
		{
			name:         "same chapter is not notified",
			chapter:      105,
			html:         `<ul id="chapters-list"><li><a>Chapter 105</a></li></ul>`,
			wantNotified: false,
		},
		{
			name:         "older chapter is not notified",
			chapter:      110,
			html:         `<ul id="chapters-list"><li><a>Chapter 105</a></li></ul>`,
			wantNotified: false,
		},
		{
			name:         "decimal chapter is notified",
			chapter:      104.5,
			html:         `<ul id="chapters-list"><li><a>Chapter 105.5</a></li></ul>`,
			wantNotified: true,
			wantChapter:  105.5,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			t.Parallel()

			notifier := &fakeNotifier{}
			runner := crawler.Runner{
				Ctx: context.Background(),
				Titles: &fakeTitleSource{titles: []repository.TrackedTitle{
					{Name: "Berserk", Link: "https://example.com/berserk", Selector: "#chapters-list a", Chapter: tt.chapter},
				}},
				Notifier: notifier,
				Fetch: func(_ string) *goquery.Document {
					return page(t, tt.html)
				},
			}

			runner.Run()

			if !tt.wantNotified {
				if len(notifier.calls) != 0 {
					t.Fatalf("expected no notification, got %+v", notifier.calls)
				}
				return
			}
			if len(notifier.calls) != 1 {
				t.Fatalf("expected one notification, got %d: %+v", len(notifier.calls), notifier.calls)
			}
			if got := notifier.calls[0]; got.chapter != tt.wantChapter || got.name != "Berserk" {
				t.Errorf("notification = %+v, want Berserk %v", got, tt.wantChapter)
			}
		})
	}
}

func TestRunner_SkipsTitlesWithoutChapters(t *testing.T) {
	t.Parallel()

	notifier := &fakeNotifier{}
	runner := crawler.Runner{
		Ctx: context.Background(),
		Titles: &fakeTitleSource{titles: []repository.TrackedTitle{
			{Name: "Berserk", Link: "https://example.com/berserk", Selector: "#chapters-list a", Chapter: 100},
		}},
		Notifier: notifier,
		Fetch: func(_ string) *goquery.Document {
			return page(t, `<div>no chapters here</div>`)
		},
	}

	runner.Run()

	if len(notifier.calls) != 0 {
		t.Fatalf("expected no notification for a page without chapters, got %+v", notifier.calls)
	}
}

func TestRunner_ReturnsWhenTitlesCannotBeRead(t *testing.T) {
	t.Parallel()

	notifier := &fakeNotifier{}
	fetched := false
	runner := crawler.Runner{
		Ctx:      context.Background(),
		Titles:   &fakeTitleSource{err: errors.New("db down")},
		Notifier: notifier,
		Fetch: func(_ string) *goquery.Document {
			fetched = true
			return nil
		},
	}

	runner.Run()

	if fetched {
		t.Error("expected no fetch when the title query fails")
	}
	if len(notifier.calls) != 0 {
		t.Errorf("expected no notification, got %+v", notifier.calls)
	}
}
