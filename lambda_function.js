const AWS = require('aws-sdk');
const dynamoDB = new AWS.DynamoDB.DocumentClient();

exports.lambda_handler = async (event) => {
    console.log('Event:', JSON.stringify(event));
    
    const headers = {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': 'GET,POST,OPTIONS',
        'Access-Control-Allow-Headers': 'Content-Type',
        'Content-Type': 'application/json'
    };

    if (event.httpMethod === 'OPTIONS') {
        return {
            statusCode: 200,
            headers,
            body: JSON.stringify({ message: 'OK' })
        };
    }

    try {
        if (event.httpMethod === 'POST') {
            const body = JSON.parse(event.body);
            const item = {
                PostID: Date.now().toString(),
                title: body.title || '',
                content: body.content || '',
                author: body.author || 'Anonymous',
                dateCreated: new Date().toISOString(),
                comments: []
            };

            await dynamoDB.put({
                TableName: 'BlogPosts',
                Item: item
            }).promise();

            return {
                statusCode: 201,
                headers,
                body: JSON.stringify({
                    success: true,
                    post: item
                })
            };
        }

        // GET request - fetch posts with comments
        const result = await dynamoDB.scan({
            TableName: 'BlogPosts'
        }).promise();

        return {
            statusCode: 200,
            headers,
            body: JSON.stringify({
                success: true,
                posts: result.Items.sort((a, b) => 
                    new Date(b.dateCreated) - new Date(a.dateCreated)
                )
            })
        };
    } catch (error) {
        console.error('Error:', error);
        return {
            statusCode: 500,
            headers,
            body: JSON.stringify({
                success: false,
                error: error.message
            })
        };
    }
};