PROJECT 4 - BUILDING A SERVERLESS BLOG

This is the 4th project (2nd of intermediate level ) trying to serve CCFS like the previous three,  refer to other repositories 
Idea of this project is to build a serveless blog with AWS Lambda utilising S3 for front end, Lambda for backend, store data in dynamoDB and connect with AWS API gateway. 

Front end will use re-act and store all its data in S3 bucket. We want to be able to retrieve blog posts, manage new comments, handle new submissions etc. We also aim to use some authentication with cognito.

We also wish to set up a CICD pipeline/workflow with Github Actions  

This project overall was not a success but I will re-attempt it again as this already my second attempt. I wish to get it right but i'll leave this version on here

Despite the challenges I faced, I still ended up with;

A working serverless blog, Frontend/backend integration, CloudFront distribution, DynamoDB storage


# CCFS Blog - Infrastructure Management

## Cost Control Measures
- Manual deployment trigger only
- Limited AWS regions for CloudFront
- DynamoDB auto-scaling with upper limits
- Lambda function memory and timeout constraints
- S3 lifecycle rules for old versions
- CloudWatch alarms for cost monitoring

## Deployment Instructions

### Manual Deployments
1. Infrastructure changes:
   ```bash
   terraform plan    # Review changes
   terraform apply   # Apply after review
   ```

2. Frontend only updates:
   ```bash
   cd my-blog
   npm run build
   aws s3 sync build/ s3://my-serverless-blog --delete
   aws cloudfront create-invalidation --distribution-id <ID> --paths "/*"
   ```

### GitHub Actions
1. Go to Actions tab
2. Select "Deploy CCFS Blog"
3. Click "Run workflow"
4. Choose deployment options:
   - Deploy infrastructure (use carefully)
   - Deploy frontend only (for content updates)

## Best Practices
1. Always review terraform plan output
2. Monitor AWS costs daily
3. Use frontend-only deployments for content updates
4. Keep infrastructure changes controlled and reviewed

## Cost Monitoring
1. Check CloudWatch alarms
2. Review AWS Cost Explorer regularly
3. Set up AWS Budget alerts
