[
  {
    "create": "product_catalog",
    "validator": {
      "$jsonSchema": {
        "bsonType": "object",
        "required": ["sku", "name", "price", "inventory"],
        "properties": {
          "sku": {
            "bsonType": "string",
            "description": "Product SKU (unique identifier)"
          },
          "name": {
            "bsonType": "string",
            "description": "Product name"
          },
          "description": {
            "bsonType": "string"
          },
          "price": {
            "bsonType": "number",
            "minimum": 0,
            "description": "Product price"
          },
          "category": {
            "bsonType": "string"
          },
          "tags": {
            "bsonType": "array",
            "items": {
              "bsonType": "string"
            }
          },
          "inventory": {
            "bsonType": "object",
            "required": ["quantity", "warehouse"],
            "properties": {
              "quantity": {
                "bsonType": "int",
                "minimum": 0
              },
              "warehouse": {
                "bsonType": "string"
              },
              "reserved": {
                "bsonType": "int",
                "minimum": 0
              }
            }
          },
          "images": {
            "bsonType": "array",
            "items": {
              "bsonType": "string"
            }
          },
          "specifications": {
            "bsonType": "object"
          },
          "isActive": {
            "bsonType": "bool"
          }
        }
      }
    }
  }
]
