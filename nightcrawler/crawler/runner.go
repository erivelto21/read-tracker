package crawler

import (
	"context"
	"log"
	"net/http"
	"nightcrawler/notification"
	"nightcrawler/repository"
	"regexp"
	"strconv"
	"strings"
	"sync"

	"github.com/PuerkitoBio/goquery"
)

type Runner struct {
	Ctx                 context.Context
	TitleRepository     *repository.MongoTitleRepository
	NotificationGateway *notification.Gateway
}

func (r Runner) Run() {
	sources := []source{
		{name: "Swordmaster's Youngest Son", url: "", selector: "#chapters-list li a"},
		{name: "The Hero Returns", url: "", selector: "#chapters-list li a"},
	}
	var wg sync.WaitGroup
	ch := make(chan result, len(sources))

	sem := make(chan struct{}, 10) // Max 10 concurrent requests
	for _, s := range sources {
		wg.Add(1)
		go func(source source) {
			sem <- struct{}{}
			defer func() { <-sem }()
			extractChapters(source, &wg, ch)
		}(s)
	}

	// Wait for completion and close channel
	wg.Wait()
	close(ch)

	chapterMap, err := r.TitleRepository.FetchChapterMap(r.Ctx)
	if err != nil {
		log.Printf("fetch chapter map: %v", err)
		return
	}

	// Collect and notify results
	for result := range ch {
		last_release_ch := chapterMap[result.source.url]
		if result.latestChapter() > last_release_ch {
			r.NotificationGateway.Notify(result.source.name, result.latestChapter())
		}
	}
}

type result struct {
	source   source
	chapters []float64
}

func (r result) latestChapter() float64 {
	return r.chapters[0]
}

type source struct {
	name     string
	url      string
	selector string
}

func extractChapters(source source, wg *sync.WaitGroup, ch chan<- result) {
	defer wg.Done()
	page := fetchPage(source.url)
	if page == nil {
		return
	}
	chapters := []float64{}
	page.Find(source.selector).Each(func(i int, s *goquery.Selection) {
		text := strings.TrimSpace(s.Text())
		chapter, boo := extractChapterNumber(text)
		if boo {
			chapters = append(chapters, chapter)
		}
	})
	ch <- result{source: source, chapters: chapters}
}

func fetchPage(url string) *goquery.Document {
	resp, err := http.Get(url)
	if err != nil {
		log.Printf("Error fetching %s: %v", url, err)
		return nil
	}
	defer resp.Body.Close()
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
