package config

import (
	"os"
)

type Config struct {
	PostgresDSN string
	MongoURI    string
}

func LoadConfig() *Config {
	return &Config{
		PostgresDSN: os.Getenv("POSTGRES_DSN"),
		MongoURI:    os.Getenv("MONGO_URI"),
	}
}
