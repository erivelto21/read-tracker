package repository

import (
	"context"
	"fmt"

	"go.mongodb.org/mongo-driver/v2/bson"
	"go.mongodb.org/mongo-driver/v2/mongo"
)

// TrackedTitle is the subset of a tracker title the crawler needs: where to look, what to look
// for, and the chapter the reader last reached.
type TrackedTitle struct {
	Name     string  `bson:"name"`
	Link     string  `bson:"link"`
	Selector string  `bson:"selector"`
	Chapter  float64 `bson:"chapter"`
}

type MongoTitleRepository struct {
	collection *mongo.Collection
}

func NewMongoTitleRepository(col *mongo.Collection) *MongoTitleRepository {
	return &MongoTitleRepository{collection: col}
}

// crawlableTypes are the only title types with chapter releases. Books are read by page and
// articles are a single URL, so neither has a chapter list to crawl.
var crawlableTypes = []string{"manga", "manhua", "novel"}

// FindCrawlable returns the titles that have everything a crawl needs: a crawlable type, a link
// to the chapter list, and a selector to read it with.
func (r *MongoTitleRepository) FindCrawlable(ctx context.Context) ([]TrackedTitle, error) {
	cursor, err := r.collection.Find(ctx, bson.M{
		"type":     bson.M{"$in": crawlableTypes},
		"link":     bson.M{"$exists": true, "$nin": []any{nil, ""}},
		"selector": bson.M{"$exists": true, "$nin": []any{nil, ""}},
	})
	if err != nil {
		return nil, fmt.Errorf("repository.FindCrawlable: %w", err)
	}

	titles := make([]TrackedTitle, 0)
	if err := cursor.All(ctx, &titles); err != nil {
		return nil, fmt.Errorf("repository.FindCrawlable: %w", err)
	}
	return titles, nil
}
