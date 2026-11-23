package crawler

import (
	"context"
	"log"
	"net/http"
	"regexp"
	"strconv"
	"strings"
	"sync"

	"github.com/PuerkitoBio/goquery"

	"github.com/erivelto/read-tracker/nightcrawler/repository"
)

// TitleSource provides the titles to crawl.
type TitleSource interface {
	FindCrawlable(ctx context.Context) ([]repository.TrackedTitle, error)
}

// Notifier reports a chapter newer than the one the reader last reached.
type Notifier interface {
	Notify(titleName string, chapter float64)
}

// PageFetcher retrieves one page. It returns nil when the page cannot be fetched, which the
// caller treats as "nothing to do" for that title.
type PageFetcher func(url string) *goquery.Document

type Runner struct {
	Ctx      context.Context
	Titles   TitleSource
	Notifier Notifier
	Fetch    PageFetcher
}

// Run crawls every crawlable title and notifies the ones that released something newer than the
// reader's current chapter.
func (r Runner) Run() {
	titles, err := r.Titles.FindCrawlable(r.Ctx)
	if err != nil {
		log.Printf("fetch crawlable titles: %v", err)
		return
	}

	var wg sync.WaitGroup
	ch := make(chan result, len(titles))

	sem := make(chan struct{}, 10) // Max 10 concurrent requests
	for _, t := range titles {
		wg.Add(1)
		go func(t repository.TrackedTitle) {
			sem <- struct{}{}
			defer func() { <-sem }()
			extractChapters(t, r.Fetch, &wg, ch)
		}(t)
	}

	wg.Wait()
	close(ch)

	for result := range ch {
		latest, ok := result.latestChapter()
		if ok && latest > result.title.Chapter {
			r.Notifier.Notify(result.title.Name, latest)
		}
	}
}

type result struct {
	title    repository.TrackedTitle
	chapters []float64
}

// latestChapter returns the highest chapter found on the page. A page with no parseable chapter
// has no latest chapter, which is reported rather than panicking on an empty slice.
func (r result) latestChapter() (float64, bool) {
	if len(r.chapters) == 0 {
		return 0, false
	}
	latest := r.chapters[0]
	for _, chapter := range r.chapters[1:] {
		if chapter > latest {
			latest = chapter
		}
	}
	return latest, true
}

func extractChapters(title repository.TrackedTitle, fetch PageFetcher, wg *sync.WaitGroup, ch chan<- result) {
	defer wg.Done()
	page := fetch(title.Link)
	if page == nil {
		return
	}
	chapters := []float64{}
	page.Find(title.Selector).Each(func(_ int, s *goquery.Selection) {
		text := strings.TrimSpace(s.Text())
		chapter, ok := extractChapterNumber(text)
		if ok {
			chapters = append(chapters, chapter)
		}
	})
	ch <- result{title: title, chapters: chapters}
}

// FetchPage retrieves and parses a page. It returns nil on any failure, so one unreachable site
// does not stop the run.
func FetchPage(url string) *goquery.Document {
	client := &http.Client{}

	req, err := http.NewRequest(http.MethodGet, url, nil)
	if err != nil {
		log.Printf("Error creating request: %v", err)
		return nil
	}

	req.Header.Set("Accept",
		"text/html,application/xhtml+xml,application/xml;q=0.9,image/jxl,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7")

	req.Header.Set("User-Agent",
		"Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/157.0.0.0 Safari/537.36")

	resp, err := client.Do(req)
	if err != nil {
		log.Printf("Error fetching %s: %v", url, err)
		return nil
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		log.Printf("HTTP error fetching %s: %s", url, resp.Status)
		return nil
	}

	doc, err := goquery.NewDocumentFromReader(resp.Body)
	if err != nil {
		log.Printf("Error parsing %s: %v", url, err)
		return nil
	}

	return doc
}

func extractChapterNumber(raw string) (float64, bool) {
	// Matches integer or decimal chapter numbers like 222 or 222.5
	re := regexp.MustCompile(`(\d+(?:\.\d+)?)`)
	match := re.FindStringSubmatch(raw)
	if len(match) < 2 {
		return 0, false
	}
	num, err := strconv.ParseFloat(match[1], 64)
	if err != nil {
		return 0, false
	}
	return num, true
}
