package repository

import (
	"context"
	"fmt"

	"go.mongodb.org/mongo-driver/v2/bson"
	"go.mongodb.org/mongo-driver/v2/mongo"
	"go.mongodb.org/mongo-driver/v2/mongo/options"
)

type MongoTitleRepository struct {
	collection *mongo.Collection
}

func NewMongoTitleRepository(col *mongo.Collection) *MongoTitleRepository {
	return &MongoTitleRepository{collection: col}
}

type chapterRow struct {
	Link    *string  `bson:"link,omitempty"`
	Chapter *float64 `bson:"chapter"`
}

func (r *MongoTitleRepository) FetchChapterMap(ctx context.Context) (map[string]float64, error) {
	opts := options.Find().SetProjection(bson.D{
		{Key: "_id", Value: 0},
		{Key: "link", Value: 1},
		{Key: "chapter", Value: 1},
	})

	cursor, err := r.collection.Find(ctx, bson.D{}, opts)
	if err != nil {
		return nil, err
	}
	defer cursor.Close(ctx)

	var rows []chapterRow
	if err := cursor.All(ctx, &rows); err != nil {
		return nil, fmt.Errorf("repository.FetchChapterMap: %w", err)
	}

	result := make(map[string]float64, len(rows))
	for _, row := range rows {
		result[*row.Link] = *row.Chapter
	}

	return result, nil
}
