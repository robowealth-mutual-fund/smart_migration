- create: reviews
  validator:
    $jsonSchema:
        bsonType: object
        properties:
            comment:
                bsonType: string
                description: Review comment
            createdAt:
                bsonType: date
                description: Creation timestamp
            helpful:
                bsonType: int
                description: Number of helpful votes
                minimum: 0
            productId:
                bsonType: string
                description: Product ID
            rating:
                bsonType: int
                description: Rating from 1-5
                maximum: 5
                minimum: 1
            updatedAt:
                bsonType: date
                description: Update timestamp
            userId:
                bsonType: string
                description: User ID
        required:
            - productId
            - userId
            - rating
            - createdAt
