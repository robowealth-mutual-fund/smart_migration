[
  {
    "create": "page_views",
    "validator": {
      "$jsonSchema": {
        "bsonType": "object",
        "required": ["userId", "page", "timestamp"],
        "properties": {
          "userId": {
            "bsonType": "string"
          },
          "sessionId": {
            "bsonType": "string"
          },
          "page": {
            "bsonType": "string"
          },
          "referrer": {
            "bsonType": "string"
          },
          "userAgent": {
            "bsonType": "string"
          },
          "timestamp": {
            "bsonType": "date"
          },
          "duration": {
            "bsonType": "int"
          }
        }
      }
    }
  }
]
