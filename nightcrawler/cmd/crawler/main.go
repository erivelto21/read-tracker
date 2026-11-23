package main

import (
	"context"
	"log/slog"
	"os"
	"time"

	"go.mongodb.org/mongo-driver/v2/mongo"
	"go.mongodb.org/mongo-driver/v2/mongo/options"

	"github.com/erivelto/read-tracker/nightcrawler/config"
	"github.com/erivelto/read-tracker/nightcrawler/crawler"
	"github.com/erivelto/read-tracker/nightcrawler/notification"
	"github.com/erivelto/read-tracker/nightcrawler/repository"
)

func main() {
	logger := slog.New(slog.NewJSONHandler(os.Stdout, nil))

	cfg, err := config.Load()
	if err != nil {
		logger.Error("failed to load config", "error", err)
		os.Exit(1)
	}

	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	client, err := mongo.Connect(options.Client().ApplyURI(cfg.MongoURI))
	if err != nil {
		logger.Error("failed to connect to MongoDB", "error", err)
		os.Exit(1)
	}
	defer func() {
		if err = client.Disconnect(context.Background()); err != nil {
			logger.Error("failed to disconnect from MongoDB", "error", err)
		}
	}()

	if err = client.Ping(ctx, nil); err != nil {
		logger.Error("MongoDB ping failed", "error", err)
		os.Exit(1)
	}

	titlesCol := client.Database(cfg.DBName).Collection("titles")
	titleRepo := repository.NewMongoTitleRepository(titlesCol)
	notificationGateway := notification.Gateway{}
	runner := crawler.Runner{Ctx: ctx, TitleRepository: titleRepo, NotificationGateway: &notificationGateway}
	runner.Run()
}
