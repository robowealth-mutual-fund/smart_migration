- create: profiles
  validator:
    $jsonSchema:
        bsonType: object
        properties:
            address:
                bsonType: object
                properties:
                    city:
                        bsonType: string
                    country:
                        bsonType: string
                    location:
                        bsonType: object
                        properties:
                            latitude:
                                bsonType: double
                                maximum: 90
                                minimum: -90
                            longitude:
                                bsonType: double
                                maximum: 180
                                minimum: -180
                    postalCode:
                        bsonType: string
                    state:
                        bsonType: string
                    street:
                        bsonType: string
            age:
                bsonType: int
                maximum: 150
                minimum: 0
            createdAt:
                bsonType: date
            email:
                bsonType: string
                description: Valid email address
                pattern: ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$
            gender:
                bsonType: string
                enum:
                    - male
                    - female
                    - other
                    - prefer_not_to_say
            isActive:
                bsonType: bool
            isVerified:
                bsonType: bool
            lastLoginAt:
                bsonType: date
            name:
                bsonType: object
                properties:
                    first:
                        bsonType: string
                        minLength: 1
                    last:
                        bsonType: string
                        minLength: 1
                    middle:
                        bsonType: string
                required:
                    - first
                    - last
            phone:
                bsonType: string
                pattern: ^[0-9]{10}$
            preferences:
                bsonType: object
                properties:
                    language:
                        bsonType: string
                    newsletter:
                        bsonType: bool
                    notifications:
                        bsonType: bool
                    theme:
                        bsonType: string
                        enum:
                            - light
                            - dark
                            - auto
            settings:
                bsonType: object
            socialLinks:
                bsonType: object
                properties:
                    facebook:
                        bsonType: string
                    instagram:
                        bsonType: string
                    linkedin:
                        bsonType: string
                    twitter:
                        bsonType: string
            tags:
                bsonType: array
                items:
                    bsonType: string
                uniqueItems: true
            updatedAt:
                bsonType: date
            userId:
                bsonType: objectId
                description: Reference to user account
        required:
            - userId
            - email
            - createdAt
